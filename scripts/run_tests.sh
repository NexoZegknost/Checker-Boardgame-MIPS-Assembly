#!/usr/bin/env bash
# Regression tests: every tests/<name>.in is piped into the game and the
# output is compared with tests/<name>.out.
#
#   MARS_JAR=/path/to/Mars.jar ./scripts/run_tests.sh [name ...]
#
# MARS_JAR defaults to tools/Mars.jar (not committed, see README).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARS_JAR="${MARS_JAR:-$ROOT/tools/Mars.jar}"
[[ -f "$MARS_JAR" ]] || { echo "Mars.jar not found at $MARS_JAR"; exit 2; }

# nc: no copyright banner, sm: start at main, p: assemble the whole directory.
# JVM chatter on stderr goes to tests/<name>.err so it does not break the diff.
# The timeout is there for inputs that end before the game does.
run_mars() {
  (cd "$ROOT/src" && timeout 300 java -jar "$MARS_JAR" nc sm p main.asm 2>"$ROOT/tests/$1.err") | tr -d '\r'
}

cd "$ROOT/tests"
if [[ $# -gt 0 ]]; then tests=("$@"); else tests=(); for f in *.in; do tests+=("${f%.in}"); done; fi

pass=0; fail=0
for t in "${tests[@]}"; do
  actual="$(run_mars "$t" < "$t.in")"
  if [[ "${UPDATE:-0}" == 1 ]]; then printf '%s\n' "$actual" > "$t.out"; echo "WROTE $t"; continue; fi
  if diff -u <(printf '%s\n' "$(tr -d '\r' < "$t.out")") <(printf '%s\n' "$actual") > "$t.diff"; then
    echo "PASS  $t"; rm -f "$t.diff"; pass=$((pass+1))
  else
    echo "FAIL  $t  (see tests/$t.diff)"; cat "$t.diff"; fail=$((fail+1))
  fi
done
echo "-----"; echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
