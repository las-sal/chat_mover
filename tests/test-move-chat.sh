#!/usr/bin/env bash
# tests/test-move-chat.sh
#
# Up-front test of move-chat.sh on this Mac, no second machine needed: fake
# `ssh` and `rsync` commands stand in for the remote, mapping HOST:path to a
# local "target home". Builds a throwaway source home with a chat, a prefix
# sibling, file history, a symlink and code, then checks the spec's scenarios.
#
# Usage: tests/test-move-chat.sh      (exit 0 = all checks passed)

set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd -P)/move-chat.sh"
T=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$1"; }
check() { local name="$1"; shift; if "$@"; then ok "$name"; else bad "$name"; fi; }
slugify() { printf '%s' "$1" | sed 's#[^A-Za-z0-9]#-#g'; }
snapshot() { (cd "$1" && find . -exec stat -f '%m %N' {} + | sort && find . -type f -exec shasum {} + | sort); }

# ---- fake remote: HOST:path -> $TARGET_HOME/path ---------------------------
mkdir -p "$T/bin"
cat > "$T/bin/ssh" <<'EOF'
#!/usr/bin/env bash
while [[ "$1" == -o ]]; do shift 2; done
shift                                   # host
cd "$TARGET_HOME" && HOME="$TARGET_HOME" exec bash -c "$*"
EOF
cat > "$T/bin/rsync" <<'EOF'
#!/usr/bin/env bash
args=()
for a in "$@"; do
  if [[ "$a" == fake:/* ]]; then a="${a#fake:}"
  elif [[ "$a" == fake:* ]]; then a="$TARGET_HOME/${a#fake:}"; fi
  args+=("$a")
done
exec /usr/bin/rsync "${args[@]}"
EOF
chmod +x "$T/bin/ssh" "$T/bin/rsync"

run() {   # run <target-home> <args...>  -> output in $T/out, status in $RC
  mkdir -p "$1"
  RC=0
  HOME="$SRC_HOME" TARGET_HOME="$1" PATH="$T/bin:$PATH" "$SCRIPT" "${@:2}" >"$T/out" 2>&1 || RC=$?
}
out_has() { grep -qF -- "$1" "$T/out"; }

# ---- source fixture --------------------------------------------------------
SRC_HOME="$T/src/Users/sal"; DST="$T/dst/home/sal"
mkdir -p "$SRC_HOME" "$DST"
PROJ="$SRC_HOME/code/home-env"
SLUG=$(slugify "$PROJ"); NEW_SLUG=$(slugify "$DST/code/home-env")
CHAT="$SRC_HOME/.claude/projects/$SLUG"
FH="$SRC_HOME/.claude/file-history"
mkdir -p "$PROJ/.git" "$PROJ/node_modules/x" "$PROJ/src" "$SRC_HOME/code/home-env-test" \
         "$CHAT/s1/subagents" "$CHAT/s1/tool-results" "$CHAT/memory" \
         "$SRC_HOME/.claude/projects/$SLUG-test" "$FH/s1" "$FH/s9" "$SRC_HOME/code/nochat"
echo "ref: refs/heads/main" > "$PROJ/.git/HEAD"
echo "mine" > "$PROJ/README.md"; echo "x" > "$PROJ/node_modules/x/i.js"
cat > "$CHAT/s1.jsonl" <<EOF
{"cwd":"$PROJ","sessionId":"s1"}
{"text":"memory at $SRC_HOME/.claude/projects/$SLUG/memory/MEMORY.md"}
{"text":"escaped $SRC_HOME\\n and other $SRC_HOME\\" end"}
{"text":"not mine: ${SRC_HOME}vador/notes"}
EOF
echo "{\"cwd\":\"$PROJ\",\"sessionId\":\"s2\"}" > "$CHAT/s2.jsonl"
echo "{\"cwd\":\"$PROJ\"}" > "$CHAT/s1/subagents/agent-a.jsonl"
echo "output from $PROJ/src" > "$CHAT/s1/tool-results/t.txt"
echo "- [x](x.md) — lives in $SRC_HOME/code/home-env" > "$CHAT/memory/MEMORY.md"
echo "outside file mentions $SRC_HOME/secret" > "$T/outside.txt"
ln -s "$T/outside.txt" "$CHAT/memory/link.md"
echo "snapshot of $SRC_HOME/code/home-env/README.md" > "$FH/s1/abc@v1"
echo "{\"cwd\":\"$SRC_HOME/code/home-env-test\"}" > "$SRC_HOME/.claude/projects/$SLUG-test/s9.jsonl"
echo "sibling" > "$FH/s9/x@v1"
OLD=$(date -v-40d +%Y%m%d%H%M)
find "$CHAT" "$FH" -exec touch -h -t "$OLD" {} +
mkdir -p "$DST/code/home-env"; echo "theirs" > "$DST/code/home-env/README.md"   # pre-existing code on target

SRC_BEFORE=$(snapshot "$CHAT"; snapshot "$FH"); OUTSIDE_BEFORE=$(shasum "$T/outside.txt")

echo "== 5.1 syntax"
check "bash -n move-chat.sh" bash -n "$SCRIPT"
if command -v shellcheck >/dev/null; then check "shellcheck" shellcheck "$SCRIPT"; else echo "  skip shellcheck (not installed)"; fi

echo "== move home-env (5.2 rewrite, contents, prefix sibling, code, settings)"
run "$DST" home-env --remote fake --yes
check "exit 0" test "$RC" -eq 0
D="$DST/.claude/projects/$NEW_SLUG"
check "confirmation names source chat dir"  out_has "Source chat:     ~/.claude/projects/$SLUG  (2 sessions, 1 with file history)"
check "confirmation names target chat dir"  out_has "Target chat:     fake:~/.claude/projects/$NEW_SLUG"
check "target slug dir created"             test -d "$D"
check "cwd rewritten"                       grep -qF "\"cwd\":\"$DST/code/home-env\"" "$D/s1.jsonl"
check "home+slug memory path rewritten"     grep -qF "$DST/.claude/projects/$NEW_SLUG/memory/MEMORY.md" "$D/s1.jsonl"
check "escaped \\n occurrence rewritten"     grep -qF "escaped $DST\\n" "$D/s1.jsonl"
check "escaped quote occurrence rewritten"  grep -qF "other $DST\\\" end" "$D/s1.jsonl"
check "partial name untouched"              grep -qF "${SRC_HOME}vador/notes" "$D/s1.jsonl"
check "no old home path left in transcript" bash -c "! grep -qF '$SRC_HOME/' '$D/s1.jsonl'"
check "subagent transcript rewritten"       grep -qF "$DST/code/home-env" "$D/s1/subagents/agent-a.jsonl"
check "tool-results rewritten"              grep -qF "$DST/code/home-env/src" "$D/s1/tool-results/t.txt"
check "memory rewritten"                    grep -qF "$DST/code/home-env" "$D/memory/MEMORY.md"
check "mtime kept on rewritten file"        test "$(stat -f %m "$D/s1.jsonl")" = "$(stat -f %m "$CHAT/s1.jsonl")"
check "symlink copied as link"              test -L "$D/memory/link.md"
check "symlink named in output"             out_has "memory/link.md"
check "symlink referent unchanged"          test "$(shasum "$T/outside.txt")" = "$OUTSIDE_BEFORE"
check "file-history copied verbatim"        cmp -s "$FH/s1/abc@v1" "$DST/.claude/file-history/s1/abc@v1"
check "prefix sibling chat not copied"      test ! -e "$DST/.claude/projects/$NEW_SLUG-test"
check "prefix sibling file-history not copied" test ! -e "$DST/.claude/file-history/s9"
check "code copied with .git"               test -f "$DST/code/home-env/.git/HEAD"
check "node_modules excluded"               test ! -e "$DST/code/home-env/node_modules"
check "existing target code kept"           grep -qx theirs "$DST/code/home-env/README.md"
check "cleanupPeriodDays = 40 + 365"        python3 -c "import json,sys; sys.exit(json.load(open('$DST/.claude/settings.json'))['cleanupPeriodDays'] != 405)"
check "source unchanged (contents + times)" test "$(snapshot "$CHAT"; snapshot "$FH")" = "$SRC_BEFORE"

echo "== re-run is a no-op (5.6 locally)"
DST_BEFORE=$(snapshot "$DST/.claude/projects"; snapshot "$DST/.claude/file-history"; snapshot "$DST/code")
run "$DST" home-env --remote fake --yes
check "exit 0" test "$RC" -eq 0
check "target chat, file history, code unchanged" \
  test "$(snapshot "$DST/.claude/projects"; snapshot "$DST/.claude/file-history"; snapshot "$DST/code")" = "$DST_BEFORE"

echo "== settings cases (5.7)"
S="$DST/.claude/settings.json"
echo '{"cleanupPeriodDays": 1000, "x": 1}' > "$S"; run "$DST" home-env --remote fake --yes --skip-code
check "larger window kept" python3 -c "import json,sys; d=json.load(open('$S')); sys.exit(not (d['cleanupPeriodDays']==1000 and d['x']==1))"
echo '{"cleanupPeriodDays": 30, "theme": "dark"}' > "$S"; run "$DST" home-env --remote fake --yes --skip-code
check "low window raised, other keys kept" python3 -c "import json,sys; d=json.load(open('$S')); sys.exit(not (d['cleanupPeriodDays']==405 and d['theme']=='dark'))"
echo '{not json' > "$S"; run "$DST" home-env --remote fake --yes --skip-code
check "invalid settings left unchanged" grep -qx '{not json' "$S"
check "invalid settings warned"        out_has "not valid JSON"
: > "$S"; run "$DST" home-env --remote fake --yes --skip-code
check "empty settings written" python3 -c "import json,sys; sys.exit(json.load(open('$S'))['cleanupPeriodDays'] != 405)"

echo "== --skip-code"
run "$T/dst2" home-env --remote fake --yes --skip-code
check "exit 0"                 test "$RC" -eq 0
check "no code copied"         test ! -e "$T/dst2/code"
check "confirmation says skipped" out_has "skipped (--skip-code)"
check "chat still copied"      test -d "$T/dst2/.claude/projects/$(slugify "$T/dst2/code/home-env")"

echo "== error paths (5.7)"
run "$T/dst3" nochat --remote fake --yes
check "unknown project: non-zero"   test "$RC" -ne 0
check "unknown project: names dir"  out_has "$SRC_HOME/.claude/projects/$(slugify "$SRC_HOME/code/nochat")"
mkdir -p "$T/elsewhere/proj"
run "$T/dst3" "$T/elsewhere/proj" --remote fake --yes --skip-code
check "outside home: non-zero"      test "$RC" -ne 0
check "error paths copied nothing"  test ! -e "$T/dst3/.claude"
mkdir -p "$T/dst4"; RC=0; echo n | HOME="$SRC_HOME" TARGET_HOME="$T/dst4" PATH="$T/bin:$PATH" "$SCRIPT" home-env --remote fake >"$T/out" 2>&1 || RC=$?
check "answer n: non-zero"          test "$RC" -ne 0
check "answer n: nothing copied"    test ! -e "$T/dst4/.claude"
run "$T/dst3" home-env
check "missing --remote: non-zero"  test "$RC" -ne 0

echo
echo "$PASS passed, $FAIL failed"
(( FAIL == 0 ))
