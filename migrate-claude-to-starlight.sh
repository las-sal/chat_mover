#!/usr/bin/env bash
# migrate-claude-to-starlight.sh
#
# Run on the Mac (roamer). Moves Claude Code sessions, per-project memory,
# global Claude config, and project code to starlight, remapping
# /Users/sal/... paths to /home/sal/... so `claude --resume` finds them.
#
# Usage:
#   ./migrate-claude-to-starlight.sh --dry-run   # show the plan, change nothing
#   ./migrate-claude-to-starlight.sh             # do it (asks to confirm)
#
# Options:
#   --dry-run       Plan only: lists sessions, rsync -n for code, no remote changes
#   --skip-code     Don't sync project directories (sessions/config only)
#   --yes           Skip the confirmation prompt
#   --remote HOST   SSH host (default: starlight)
#
# Safe to re-run: never overwrites files that already exist on starlight,
# and backs up any existing ~/.claude there before touching it.

set -euo pipefail

# ---- settings -------------------------------------------------------------
REMOTE="starlight"
CODE_DIRS=("code")   # dirs under $HOME to sync; same layout is kept on starlight
EXCLUDES=(--exclude node_modules --exclude .venv --exclude venv \
          --exclude __pycache__ --exclude .DS_Store)
# ---------------------------------------------------------------------------

DRY_RUN=0; SKIP_CODE=0; ASSUME_YES=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=1 ;;
    --skip-code) SKIP_CODE=1 ;;
    --yes)       ASSUME_YES=1 ;;
    --remote)    REMOTE="$2"; shift ;;
    -h|--help)   sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[33m!!  %s\033[0m\n' "$*"; }
die()  { printf '\033[31mxx  %s\033[0m\n' "$*" >&2; exit 1; }
slugify() { printf '%s' "$1" | sed 's#[^A-Za-z0-9]#-#g'; }

# ---- preflight ------------------------------------------------------------
[[ -d "$HOME/.claude/projects" ]] || die "No ~/.claude/projects on this Mac; nothing to migrate."
command -v rsync >/dev/null || die "rsync not found."

say "Checking connection to $REMOTE"
REMOTE_HOME=$(ssh -o BatchMode=yes "$REMOTE" 'printf %s "$HOME"') \
  || die "Can't ssh to $REMOTE without a prompt. Run 'ssh $REMOTE' once so your key is loaded, then retry."
ssh -o BatchMode=yes "$REMOTE" 'command -v rsync >/dev/null && command -v python3 >/dev/null' \
  || die "$REMOTE needs rsync and python3 (sudo dnf install rsync python3)."

OLD_PREFIX=$(slugify "$HOME")
NEW_PREFIX=$(slugify "$REMOTE_HOME")
echo "   Mac home:       $HOME  (session prefix $OLD_PREFIX)"
echo "   starlight home: $REMOTE_HOME  (session prefix $NEW_PREFIX)"

if pgrep -x claude >/dev/null 2>&1; then
  warn "Claude Code is running on this Mac. Exit all sessions first so transcripts are complete."
fi

say "Session folders to migrate"
shopt -s nullglob
count=0
for d in "$HOME/.claude/projects/$OLD_PREFIX" "$HOME/.claude/projects/$OLD_PREFIX"-*; do
  [[ -d "$d" ]] || continue
  name=$(basename "$d")
  n=$(find "$d" -maxdepth 1 -name '*.jsonl' | wc -l | tr -d ' ')
  printf '   %-50s -> %s  (%s sessions)\n' "$name" "${NEW_PREFIX}${name#"$OLD_PREFIX"}" "$n"
  count=$((count + 1))
done
(( count > 0 )) || die "No session folders found for projects under $HOME."
echo "   (Sessions for projects outside $HOME are not migrated.)"

if (( ! DRY_RUN && ! ASSUME_YES )); then
  read -r -p $'\nProceed with migration to '"$REMOTE"'? [y/N] ' ans
  [[ "$ans" =~ ^[Yy]$ ]] || die "Aborted."
fi

# ---- 1. project code ------------------------------------------------------
RSYNC=(rsync -a -z)
(( DRY_RUN )) && RSYNC+=(-n -v)

if (( ! SKIP_CODE )); then
  for dir in "${CODE_DIRS[@]}"; do
    [[ -d "$HOME/$dir" ]] || { warn "$HOME/$dir not found, skipping"; continue; }
    say "Syncing ~/$dir -> $REMOTE:~/$dir  (dependency folders excluded; reinstall on Linux)"
    "${RSYNC[@]}" "${EXCLUDES[@]}" "$HOME/$dir/" "$REMOTE:$dir/"
  done
fi

# ---- 2. stage Claude data -------------------------------------------------
GLOBAL_ITEMS=()
for item in CLAUDE.md commands agents skills; do
  [[ -e "$HOME/.claude/$item" ]] && GLOBAL_ITEMS+=("$HOME/.claude/$item")
done

if (( DRY_RUN )); then
  say "Dry run: would stage on $REMOTE:~/claude-import"
  du -sh "$HOME/.claude/projects" | sed 's/^/   /'
  for i in "${GLOBAL_ITEMS[@]}"; do echo "   global: ${i#"$HOME"/}"; done
  [[ -f "$HOME/.claude/settings.json" ]] && echo "   settings.json -> staged for manual review only"
  say "Dry run complete. Nothing was changed."
  exit 0
fi

say "Staging Claude data on $REMOTE:~/claude-import"
ssh "$REMOTE" 'mkdir -p ~/claude-import/projects ~/claude-import/global'
rsync -a -z "$HOME/.claude/projects/" "$REMOTE:claude-import/projects/"
(( ${#GLOBAL_ITEMS[@]} )) && rsync -a -z "${GLOBAL_ITEMS[@]}" "$REMOTE:claude-import/global/"
[[ -f "$HOME/.claude/settings.json" ]] && \
  rsync -a "$HOME/.claude/settings.json" "$REMOTE:claude-import/mac-settings.json"

# ---- 3. import on starlight -----------------------------------------------
say "Importing on $REMOTE"
ssh "$REMOTE" bash -s -- "$OLD_PREFIX" "$NEW_PREFIX" "$HOME" "$REMOTE_HOME" <<'REMOTE_SCRIPT'
set -euo pipefail
OLD_PREFIX="$1"; NEW_PREFIX="$2"; OLD_HOME="$3"; NEW_HOME="$4"
STAGE="$HOME/claude-import"
DEST="$HOME/.claude/projects"
STAMP=$(date +%Y%m%d-%H%M%S)

# Back up any existing Claude data first
if [[ -d "$HOME/.claude" ]]; then
  tar -czf "$HOME/claude-backup-$STAMP.tar.gz" -C "$HOME" .claude
  echo "   Backed up existing ~/.claude -> ~/claude-backup-$STAMP.tar.gz"
fi
mkdir -p "$DEST"

# Raise the session cleanup window BEFORE Claude starts (default deletes >30 days)
python3 - "$HOME/.claude/settings.json" <<'PY'
import json, os, sys
p = sys.argv[1]
d = {}
try:
    if os.path.exists(p) and os.path.getsize(p) > 0:
        with open(p) as f:
            d = json.load(f)
except Exception as e:
    print(f"   WARNING: could not parse {p} ({e}); set cleanupPeriodDays by hand!")
    sys.exit(0)
if d.get("cleanupPeriodDays", 30) < 365:
    d["cleanupPeriodDays"] = 365
with open(p, "w") as f:
    json.dump(d, f, indent=2)
print(f"   cleanupPeriodDays = {d['cleanupPeriodDays']}  ({p})")
PY

rewrite_paths() {   # replace old home path with new one in any file that mentions it
  grep -rlF "$OLD_HOME/" "$@" 2>/dev/null | while IFS= read -r f; do
    sed -i "s#${OLD_HOME}/#${NEW_HOME}/#g" "$f"
  done || true
}

# Session folders: remap slug, copy without overwriting, fix paths inside
shopt -s nullglob
imported=0
for src in "$STAGE/projects/$OLD_PREFIX" "$STAGE/projects/$OLD_PREFIX"-*; do
  [[ -d "$src" ]] || continue
  name=$(basename "$src")
  new="${NEW_PREFIX}${name#"$OLD_PREFIX"}"
  mkdir -p "$DEST/$new"
  rsync -a --ignore-existing "$src/" "$DEST/$new/"
  rewrite_paths "$DEST/$new"
  n=$(find "$DEST/$new" -maxdepth 1 -name '*.jsonl' | wc -l)
  echo "   $new  ($n sessions)"
  imported=$((imported + 1))
done
echo "   Imported $imported project folder(s)."

# Global config: copy without overwriting, report conflicts
for item in "$STAGE"/global/*; do
  [[ -e "$item" ]] || continue
  base=$(basename "$item")
  if [[ -f "$item" && -e "$HOME/.claude/$base" ]]; then
    echo "   SKIPPED ~/.claude/$base (already exists); compare with $item"
  else
    rsync -a --ignore-existing "$item" "$HOME/.claude/"
    rewrite_paths "$HOME/.claude/$base"
    echo "   ~/.claude/$base"
  fi
done
REMOTE_SCRIPT

# ---- done -----------------------------------------------------------------
say "Done. Next steps on $REMOTE:"
cat <<EOF
   1. Review ~/claude-import/mac-settings.json and port any hooks/permissions by hand
      (Mac-specific paths and commands won't work on Linux).
   2. Reinstall dependencies in each project (npm install, uv sync, etc.).
   3. Sign in once if you haven't:  claude   (use your Max account)
   4. Resume:  cd ~/code/<project> && claude --resume
      First message: "We've moved to a Fedora Linux box; the project is now at
      $REMOTE_HOME/code/<project>. Reinstall dependencies and re-verify the build."
   5. When everything checks out:  rm -rf ~/claude-import   (keep the backup tarball)
EOF
