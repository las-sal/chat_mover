#!/usr/bin/env bash
# move-chat.sh
#
# Run on the Mac. Moves ONE project's Claude Code chat -- its sessions,
# per-session sidecars, memory and file history -- and the project's code to
# another machine, remapping this Mac's home path to the target's so
# `claude --resume` there picks the chat up.
#
# Usage:
#   ./move-chat.sh <project> --remote HOST [--skip-code] [--yes]
#
#   <project>       a folder under ~/code (e.g. home-env), or a path to a
#                   project folder under your home directory
#   --remote HOST   SSH host to move the chat to (required)
#   --skip-code     don't copy the project folder (e.g. you'll git clone it)
#   --yes           skip the confirmation prompt
#
# Never overwrites chat data, file history or code on the target and never
# changes anything on this Mac; re-running copies only files not yet there.

set -euo pipefail

EXCLUDES=(--exclude node_modules --exclude .venv --exclude venv \
          --exclude __pycache__ --exclude .DS_Store)

PROJECT_ARG=""; REMOTE=""; SKIP_CODE=0; ASSUME_YES=0

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; }
say()   { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
warn()  { printf '\033[33m!!  %s\033[0m\n' "$*"; }
die()   { printf '\033[31mxx  %s\033[0m\n' "$*" >&2; exit 1; }
slugify() { printf '%s' "$1" | sed 's#[^A-Za-z0-9]#-#g'; }
rq()    { printf '%q' "$1"; }   # quote one word for the remote shell

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote)    [[ $# -ge 2 ]] || { usage >&2; exit 1; }; REMOTE="$2"; shift ;;
    --skip-code) SKIP_CODE=1 ;;
    --yes)       ASSUME_YES=1 ;;
    -h|--help)   usage; exit 0 ;;
    -*)          echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)           [[ -z "$PROJECT_ARG" ]] || die "One project per run (got '$PROJECT_ARG' and '$1')."
                 PROJECT_ARG="$1" ;;
  esac
  shift
done
[[ -n "$PROJECT_ARG" && -n "$REMOTE" ]] || { usage >&2; exit 1; }

# ---- 1. resolve the project and its chat ---------------------------------
if [[ "$PROJECT_ARG" == */* ]]; then dir="$PROJECT_ARG"; else dir="$HOME/code/$PROJECT_ARG"; fi
[[ -d "$dir" ]] || die "Project folder not found: $dir"
PROJECT=$(cd "$dir" && pwd -P)          # physical path, as Claude Code records cwd
OLD_HOME=$(cd "$HOME" && pwd -P)
case "$PROJECT" in
  "$OLD_HOME"/*) REL="${PROJECT#"$OLD_HOME"/}" ;;
  *) die "$PROJECT is not under your home ($OLD_HOME); only projects under home can be moved." ;;
esac
OLD_SLUG=$(slugify "$PROJECT")
SRC="$HOME/.claude/projects/$OLD_SLUG"
[[ -d "$SRC" ]] || die "No Claude chat for $PROJECT (expected $SRC)."

# ---- 2. preflight ---------------------------------------------------------
command -v rsync   >/dev/null || die "rsync not found on this Mac."
command -v python3 >/dev/null || die "python3 not found on this Mac (xcode-select --install)."
NEW_HOME=$(ssh -o BatchMode=yes "$REMOTE" 'printf %s "$HOME"') \
  || die "Can't ssh to $REMOTE without a prompt. Run 'ssh $REMOTE' once so your key is loaded, then retry."
# A shell startup file that prints for non-interactive ssh (e.g. a terminal-title
# trap) would corrupt NEW_HOME -- and every rewritten path -- and breaks rsync.
[[ "$NEW_HOME" =~ ^/[^[:cntrl:]]*$ ]] \
  || die "$REMOTE's shell prints extra output for non-interactive ssh commands (\$HOME came back as $(printf %q "$NEW_HOME")). This breaks rsync and the path rewrite. Make its startup files print only in interactive shells (wrap that code in: if [[ \$- == *i* ]]; then ... fi), then retry."
ssh -o BatchMode=yes "$REMOTE" 'command -v rsync >/dev/null' \
  || die "$REMOTE needs rsync (Fedora: sudo dnf install rsync)."
if pgrep -x claude >/dev/null 2>&1; then
  warn "Claude Code is running on this Mac; exit the chat's sessions first so transcripts are complete."
fi

NEW_PROJECT="$NEW_HOME/$REL"
NEW_SLUG=$(slugify "$NEW_PROJECT")

SESSIONS=(); FH_DIRS=()
for f in "$SRC"/*.jsonl; do
  [[ -f "$f" ]] || continue
  SESSIONS+=("$f")
  u=$(basename "$f" .jsonl)
  if [[ -d "$HOME/.claude/file-history/$u" ]]; then FH_DIRS+=("$HOME/.claude/file-history/$u"); fi
done

# ---- 3. confirm -----------------------------------------------------------
say "Moving one chat to $REMOTE"
echo "   Source chat:     ~/.claude/projects/$OLD_SLUG  (${#SESSIONS[@]} sessions, ${#FH_DIRS[@]} with file history)"
if ssh "$REMOTE" "test -d $(rq "$NEW_HOME/.claude/projects/$NEW_SLUG")"; then
  echo "   Target chat:     $REMOTE:~/.claude/projects/$NEW_SLUG  (already exists: only missing files will be added)"
else
  echo "   Target chat:     $REMOTE:~/.claude/projects/$NEW_SLUG"
fi
if (( SKIP_CODE )); then
  echo "   Code:            skipped (--skip-code)"
else
  echo "   Source project:  $PROJECT"
  echo "   Target project:  $REMOTE:$NEW_PROJECT"
fi
echo "   Files already on $REMOTE are never overwritten; a transcript that grew since an"
echo "   earlier move is not updated (delete the target's copy by hand to re-move it)."
if (( ! ASSUME_YES )); then
  read -r -p $'\nProceed? [y/N] ' ans || ans=""
  [[ "$ans" =~ ^[Yy]$ ]] || die "Aborted; nothing was copied."
fi

# ---- 4. stage and rewrite paths (on this Mac; the source is never touched) -
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
rsync -a "$SRC/" "$STAGE/$NEW_SLUG/"     # keeps file times; symlinks stay links

say "Rewriting $OLD_HOME -> $NEW_HOME and $OLD_SLUG -> $NEW_SLUG"
python3 - "$STAGE/$NEW_SLUG" "$OLD_HOME" "$NEW_HOME" "$OLD_SLUG" "$NEW_SLUG" <<'PY'
import os, re, sys
root, old_home, new_home, old_slug, new_slug = sys.argv[1:]
# old home only as a whole path segment: next byte is / " ' whitespace \ or end
home_re = re.compile(re.escape(old_home.encode()) + rb'(?=[/"\'\s\\]|$)')
new_home_b, old_slug_b, new_slug_b = new_home.encode(), old_slug.encode(), new_slug.encode()
changed, links = 0, []
for d, dirs, files in os.walk(root):          # does not descend into symlinked dirs
    for name in dirs + files:
        p = os.path.join(d, name)
        if os.path.islink(p):
            links.append(os.path.relpath(p, root))
    for name in files:
        p = os.path.join(d, name)
        if os.path.islink(p) or not os.path.isfile(p):
            continue                          # never open a link: it may point at the source
        with open(p, 'rb') as f:
            data = f.read()
        new = home_re.sub(lambda m: new_home_b, data).replace(old_slug_b, new_slug_b)
        if new != data:
            st = os.stat(p)
            with open(p, 'wb') as f:
                f.write(new)
            os.utime(p, ns=(st.st_atime_ns, st.st_mtime_ns))
            changed += 1
print(f"   Rewrote paths in {changed} file(s).")
for l in links:
    print(f"\033[33m!!  Symlink copied as a link, not rewritten (may dangle on the target): {l}\033[0m")
PY

# ---- 5. copy chat data and file history -----------------------------------
say "Copying chat data to $REMOTE"
mkdirs="$(rq "$NEW_HOME/.claude/projects") $(rq "$NEW_HOME/.claude/file-history")"
(( SKIP_CODE )) || mkdirs+=" $(rq "$(dirname "$NEW_PROJECT")")"
ssh "$REMOTE" "mkdir -p $mkdirs"
rsync -a -z --ignore-existing "$STAGE/$NEW_SLUG" "$REMOTE:.claude/projects/"
if (( ${#FH_DIRS[@]} )); then
  rsync -a -z --ignore-existing "${FH_DIRS[@]}" "$REMOTE:.claude/file-history/"
fi
echo "   ~/.claude/projects/$NEW_SLUG  (${#SESSIONS[@]} sessions)"
echo "   ~/.claude/file-history  (${#FH_DIRS[@]} session dirs)"

# ---- 6. keep the target from purging the moved sessions -------------------
# Claude Code deletes sessions idle longer than cleanupPeriodDays; the moved
# transcripts keep their original times, so cover the oldest one plus a year.
if (( ${#SESSIONS[@]} )); then
  needed=$(python3 -c 'import os,sys,time; print(int((time.time()-min(os.path.getmtime(p) for p in sys.argv[1:]))//86400)+365)' "${SESSIONS[@]}")
else
  needed=365
fi
# A missing file reads as empty; one that exists but can't be read is left alone.
if current=$(ssh "$REMOTE" 'f=~/.claude/settings.json; [ ! -e "$f" ] || cat "$f"'); then
  updated=$(printf '%s' "$current" | python3 -c '
import json, sys
needed, text = int(sys.argv[1]), sys.stdin.read()
try:
    d = json.loads(text) if text.strip() else {}
except ValueError:
    d = None
if not isinstance(d, dict):
    print("INVALID")
elif isinstance(d.get("cleanupPeriodDays"), (int, float)) and d["cleanupPeriodDays"] >= needed:
    print("UNCHANGED")
else:
    d["cleanupPeriodDays"] = needed
    print(json.dumps(d, indent=2))
' "$needed")
else
  updated=UNREADABLE
fi
case "$updated" in
  INVALID)   warn "$REMOTE:~/.claude/settings.json is not valid JSON; set \"cleanupPeriodDays\": $needed in it by hand!" ;;
  UNREADABLE) warn "Could not read $REMOTE:~/.claude/settings.json; left it unchanged. Set \"cleanupPeriodDays\": $needed in it by hand!" ;;
  UNCHANGED) echo "   cleanupPeriodDays already covers the moved sessions (needs >= $needed)." ;;
  *)         # written in place, so the file keeps its permissions and a symlink keeps its target
             printf '%s\n' "$updated" | ssh "$REMOTE" 'cat > ~/.claude/settings.json'
             echo "   cleanupPeriodDays = $needed  ($REMOTE:~/.claude/settings.json)" ;;
esac

# ---- 7. project code ------------------------------------------------------
if (( ! SKIP_CODE )); then
  say "Copying $PROJECT -> $REMOTE:$NEW_PROJECT  (dependency folders excluded)"
  rsync -a -z --ignore-existing "${EXCLUDES[@]}" "$PROJECT/" "$REMOTE:$(rq "$REL")/"
fi

# ---- done -----------------------------------------------------------------
say "Done. Next steps on $REMOTE:"
cat <<EOF
   1. cd $NEW_PROJECT && claude --resume   (trust the folder when asked)
   2. Reinstall dependencies if the project has any (npm install, uv sync, ...).
   3. Check the project's .claude/ and CLAUDE.md for paths still under $OLD_HOME.
EOF
