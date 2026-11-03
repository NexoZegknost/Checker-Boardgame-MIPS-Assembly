#!/usr/bin/env bash
# Tạo labels, milestones và issues cho repo Checkers MIPS.
# Yêu cầu: GitHub CLI (gh) đã đăng nhập: gh auth login
# Dùng:    ./setup_github.sh <owner>/<repo>
set -euo pipefail
REPO="${1:?Cách dùng: ./setup_github.sh <owner>/<repo>}"

# ---------- Labels ----------
label() { gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null; }
label "required"   "d73a4a" "Yêu cầu bắt buộc (R1-R11)"
label "qol"        "0e8a16" "Mở rộng Quality of Life (Q1-Q9)"
label "advanced"   "5319e7" "Mở rộng luật nâng cao (A1-A4)"
label "infra"      "c5def5" "Repo, script, CI"
label "design"     "fbca04" "Thiết kế, tài liệu kỹ thuật"
label "test"       "1d76db" "Kiểm thử"
label "report"     "f9d0c4" "Báo cáo, slide, demo"
echo "✓ labels"

# ---------- Milestones ----------
milestone() { # bỏ qua nếu milestone đã tồn tại
  gh api "repos/$REPO/milestones" -f title="$1" -f description="$2" >/dev/null 2>&1 || true
}
milestone "M0 - Khởi tạo & thiết kế"            "Repo, design doc, script chạy MARS, CI"
milestone "M1 - Bàn cờ & hiển thị (v0.1)"        "R1 R7 R8"
milestone "M2 - Nhập liệu & đi quân (v0.2)"      "R2 R9 R10"
milestone "M3 - Ăn quân, chuỗi, phong vua (v0.3)" "R3 R4 R5 R11"
milestone "M4 - Kết thúc ván / bản tối thiểu (v1.0)" "R6 + rà soát toàn bộ yêu cầu bắt buộc"
milestone "M5 - QoL I: giao diện & phản hồi (v1.1)"  "Q1 Q2 Q3 Q5 Q6"
milestone "M6 - QoL II: luồng chơi & tiện ích (v1.2)" "Q4 Q7 Q8 Q9"
milestone "M7 - Luật nâng cao (v2.0)"            "A1 A2 A3 A4"
milestone "M8 - Kiểm thử & làm sạch mã (v2.1)"   "Test hồi quy, review, thống kê lệnh"
milestone "M9 - Báo cáo & demo (v3.0)"           "Báo cáo LaTeX, slide, demo, nộp bài"
echo "✓ milestones"

# ---------- Issues ----------
issue() { # $1 milestone  $2 labels  $3 title  $4 body
  gh issue create --repo "$REPO" --milestone "$1" --label "$2" --title "$3" --body "$4" >/dev/null
  echo "  + $3"
}

M="M0 - Khởi tạo & thiết kế"
issue "$M" infra  "Khởi tạo cấu trúc repo, README, .gitignore" "Thư mục src/ tests/ scripts/ docs/ report/ theo ROADMAP."
issue "$M" design "Design doc: biểu diễn bàn mailbox, mã quân, bảng tra ký hiệu" "docs/design.md - mailbox (N+2)x(N+2) có WALL, offset 4 hướng chéo, sq_to_idx/idx_to_sq."
issue "$M" design "Sơ đồ module + quy ước gọi hàm & đặt nhãn" "Header hàm (mô tả/input/output/thanh ghi), lưu \$ra/\$s* trên stack, nhãn module_func_label."
issue "$M" infra  "Script chạy MARS dòng lệnh + khung test" "scripts/run_tests.sh: java -jar Mars.jar nc sm src/*.asm < tests/x.in, so sánh tests/x.out."
issue "$M" infra  "GitHub Actions chạy bộ test" "Cài Java, tải Mars.jar, chạy run_tests.sh trên mỗi PR."

M="M1 - Bàn cờ & hiển thị (v0.1)"
issue "$M" required "R1: board_init - bàn 8x8, 12 quân mỗi bên" "Đen dưới, Đỏ trên, theo Hình 1."
issue "$M" required "R7: bảng tra ký hiệu ô 1-32 <-> chỉ số mailbox" "29 góc dưới trái, 4 góc trên phải (Hình 10)."
issue "$M" required "R8: display_board đúng định dạng đề" "' ' ô không dùng, r/b quân, R/B vua, 0 ô trống; in mỗi lượt."
issue "$M" test     "Test hiển thị bàn khởi đầu và bàn có vua" ""

M="M2 - Nhập liệu & đi quân (v0.2)"
issue "$M" required "R9: prompt lượt + đọc ô xuất phát/ô đáp" "Black's turn. / Red's turn. / Enter starting square: / Enter landing square:"
issue "$M" required "R10: kiểm tra hợp lệ nước đi" "(a) có quân (b) đúng phe (c) đúng hướng & ô đích trống. Sai -> 'Not a valid move! Try again.'"
issue "$M" required "R2: gen_moves cho nước đi thường + đổi lượt" "Quân thường chỉ tiến; vua 4 hướng. Dùng chung cho các tính năng sau."
issue "$M" required "Chặn nhập ngoài 1-32 / không phải số" ""
issue "$M" test     "Test ví dụ 21->17 (hợp lệ) và 21->13 (không hợp lệ)" ""

M="M3 - Ăn quân, chuỗi, phong vua (v0.3)"
issue "$M" required "R3: sinh & thực hiện nước ăn, xóa quân bị ăn" "In 'Captured <Color>'s piece.'"
issue "$M" required "R4/R11: vòng lặp ăn chuỗi bắt buộc" "'Chaining possible.' -> chỉ hỏi ô đáp, khóa quân, không cho bỏ chuỗi."
issue "$M" required "R5: phong vua (kể cả giữa chuỗi -> ăn lùi tiếp)" "Hình 6-8."
issue "$M" test     "Test chuỗi 15x24 24x31 31x22 22x13 và log 9->18 của đề" ""

M="M4 - Kết thúc ván / bản tối thiểu (v1.0)"
issue "$M" required "R6: phát hiện hết quân, thông báo người thắng, kết thúc" ""
issue "$M" test     "Rà soát checklist R1-R11, chơi trọn một ván, tag v1.0" ""

M="M5 - QoL I: giao diện & phản hồi (v1.1)"
issue "$M" qol "Q1: hiển thị bàn đẹp hơn (khung, tọa độ, số ô)" ""
issue "$M" qol "Q2: xoay bàn theo người đang đi" ""
issue "$M" qol "Q3: ký hiệu ô theo phối cảnh người đang đi" "Với Đỏ, góc dưới trái cũng là 29 (Hình 11)."
issue "$M" qol "Q5: thông báo lỗi chi tiết theo nguyên nhân" "Ô trống / quân đối thủ / sai hướng / ô đích bị chiếm / ngoài phạm vi / phải ăn tiếp."
issue "$M" qol "Q6: thắng khi đối thủ bị chặn hết nước" "Hình 9 - dùng lại gen_moves."

M="M6 - QoL II: luồng chơi & tiện ích (v1.2)"
issue "$M" qol "Q4: chọn quân -> danh sách nước đi đánh số (cả khi ăn chuỗi)" ""
issue "$M" qol "Q7: đề nghị hòa (cả hai đồng ý)" ""
issue "$M" qol "Q8: menu chính + restart không thoát chương trình" ""
issue "$M" qol "Q9: lịch sử nước đi theo ký hiệu chuẩn + undo" "21-17, 15x24 24x31 ..."
issue "$M" qol "Q9: luật hòa sau N nước không ăn/không phong vua, lệnh help" "Ghi rõ lý do trong báo cáo."

M="M7 - Luật nâng cao (v2.0)"
issue "$M" advanced "A1: bắt buộc ăn (bật/tắt)" ""
issue "$M" advanced "A2: bàn 10x10 với 15/20 quân, ký hiệu 1-50" "Tham số hóa N."
issue "$M" advanced "A3: biến thể International / Brazilian / Russian" "Vua bay, quân thường ăn lùi."
issue "$M" advanced "A4: luật ăn nhiều nhất (International)" ""
issue "$M" advanced "A4: AI đối thủ (random -> greedy -> minimax nông)" ""
issue "$M" advanced "Menu chọn luật chơi" ""

M="M8 - Kiểm thử & làm sạch mã (v2.1)"
issue "$M" test "Bộ test hồi quy cho mọi R/Q/A + tình huống biên" ""
issue "$M" test "Review khả năng đọc, tách hàm dài, xóa code chết" ""
issue "$M" test "Thống kê lệnh (MARS Instruction Statistics) cho báo cáo" ""

M="M9 - Báo cáo & demo (v3.0)"
issue "$M" report "Báo cáo LaTeX: thiết kế, giải thích hàm MIPS, lý do & cách cài tính năng mở rộng" ""
issue "$M" report "Slide + kịch bản demo đi qua mọi tính năng" ""
issue "$M" report "Chuẩn bị câu hỏi vấn đáp về MIPS" "Stack frame, syscall, địa chỉ mảng, nhánh/nhảy."
issue "$M" report "Đóng gói bài nộp theo yêu cầu giảng viên" ""
echo "✓ issues — xong."
