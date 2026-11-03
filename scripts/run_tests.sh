#!/usr/bin/env bash
# Chạy toàn bộ test hồi quy: mỗi tests/<tên>.in được đưa vào stdin của chương
# trình, kết quả so với tests/<tên>.out.
#
# Dùng:   MARS_JAR=/đường/dẫn/Mars.jar ./scripts/run_tests.sh [tên_test ...]
# Mặc định MARS_JAR = tools/Mars.jar (không commit file này vào repo).
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARS_JAR="${MARS_JAR:-$ROOT/tools/Mars.jar}"
[[ -f "$MARS_JAR" ]] || { echo "Không thấy Mars.jar tại $MARS_JAR"; exit 2; }

# nc = không in bản quyền, sm = bắt đầu tại nhãn global 'main',
# p  = project mode: assemble mọi file .asm cùng thư mục với main.asm
# Chỉ so sánh stdout; stderr của Java (cảnh báo JVM) ghi vào tests/<tên>.err
run_mars() { (cd "$ROOT/src" && java -jar "$MARS_JAR" nc sm p main.asm 2>"$ROOT/tests/$1.err") | tr -d '\r'; }

cd "$ROOT/tests"
if [[ $# -gt 0 ]]; then tests=("$@"); else tests=(); for f in *.in; do tests+=("${f%.in}"); done; fi

pass=0; fail=0
for t in "${tests[@]}"; do
  actual="$(run_mars "$t" < "$t.in")"
  if diff -u <(printf '%s\n' "$(tr -d '\r' < "$t.out")") <(printf '%s\n' "$actual") > "$t.diff"; then
    echo "PASS  $t"; rm -f "$t.diff"; pass=$((pass+1))
  else
    echo "FAIL  $t  (xem tests/$t.diff)"; cat "$t.diff"; fail=$((fail+1))
  fi
done
echo "-----"; echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
