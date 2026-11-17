# Kịch bản demo

Mỗi dòng là một chuỗi phím gõ lần lượt, sau mỗi mục cách nhau bởi dấu phẩy là một lần Enter. Các dòng nối tiếp nhau trong cùng một lần chạy, bắt đầu từ menu chính; tùy chọn đã bật ở dòng trước vẫn còn hiệu lực ở dòng sau.

## 1. Phần bắt buộc

| Trình bày | Gõ | Điều cần chỉ ra |
|---|---|---|
| Nước đi sai (ví dụ của đề) | `1`, `21`, `13` | Thông báo `Not a valid move!` và hỏi lại |
| Nước đi hợp lệ | `21`, `17` | Bàn in đúng mẫu đề, chuyển sang lượt Đỏ |
| Thoát ván | `q` | Về menu, chương trình không kết thúc |
| Ăn chuỗi (ví dụ mục 2.2 của đề) | `3`, `r 9`, `B 14`, `B 15`, `B 22`, `B 23`, `t`, `p`, `9`, `18` | `Captured Black's piece.`, `Chaining possible.`, chỉ hỏi ô đáp |
| Không bỏ chuỗi được | `17` | Bị từ chối, vẫn hỏi ô đáp |
| Kết thúc chuỗi | `27`, rồi `q` | Lượt chuyển cho Đen |
| Phong vua giữa chuỗi (hình 8 của đề) | `3`, `r 15`, `b 19`, `b 27`, `b 26`, `b 17`, `t`, `p`, `15`, `24`, `31`, `22`, `13` | Quân Đỏ thành `R` ở ô 31 rồi ăn lùi tiếp; cuối cùng `Red wins!` |

Sau `Red wins!` gõ `l` để xem biên bản, hoặc Enter.

## 2. Tiện ích

| Trình bày | Gõ | Điều cần chỉ ra |
|---|---|---|
| Bàn có khung | `2`, `1`, `0`, `1` | Mỗi ô tối có số ô |
| Xoay bàn và số ô | `q`, `2`, `2`, `2`, `0`, `1`, `21`, `17` | Tới lượt Đỏ bàn quay lại, ô góc dưới trái vẫn là 29 |
| Chọn từ danh sách | `q`, `2`, `3`, `0`, `1`, `22`, `2` | Danh sách quân đi được, danh sách nước của quân 22 |
| Thông báo lỗi | (đang ở kiểu danh sách thì đổi lại bằng `q`, `2`, `3`, `0`, `1`) `30`, rồi `21`, `18` | Nói rõ lý do |
| Trợ giúp, biên bản | `h`, `l` | |
| Đi lại | `21`, `17`, `u` | Bàn cờ trở lại như trước |
| Cầu hòa | `d`, `21`, `17`, `d`, rồi Enter | Đen mời, Đỏ nhận, ván hòa |
| Chơi lại | `1`, `21`, `17`, `r`, rồi `q` | Bàn về thế ban đầu |
| Bị chặn hết nước | `3`, `b 5`, `r 1`, `p`, rồi Enter | `Black has no legal moves.` |

Sau phần này bàn cờ vẫn ở kiểu có khung và xoay theo người đi. Muốn về mặc định thì vào `2` và gõ số dòng cho tới khi về giá trị đầu.

## 3. Luật nâng cao

| Trình bày | Gõ | Điều cần chỉ ra |
|---|---|---|
| Bắt buộc ăn (English) | `2`, `4`, `0`, rồi `3`, `b 18`, `r 14`, `b 30`, `p`, `30` | Quân 30 bị từ chối vì phải ăn; gõ `18`, `9` thì ăn được và thắng; Enter |
| Bàn 10×10 (International) | `2`, `4`, `0`, `1`, rồi `q` | Bàn 50 ô, 20 quân mỗi bên |
| Vua bay và ăn nhiều nhất (Brazilian) | `2`, `4`, `0`, rồi `3`, `B 29`, `r 22`, `r 10`, `R 1`, `p`, `29`, `18` | Bị từ chối: phải chọn chuỗi ăn 2 quân; gõ `29`, `15`, `6` thì được, quân bị ăn hiện `x`; `q` |
| Luật tùy chỉnh | `2`, `6`, xem rồi `0`, `0` | Bật tắt từng luật |
| Chơi với máy | `2`, `5`, `5`, `0`, `1`, `21`, `17` | Mức trung bình, `The computer plays ...` |

## 4. Mã nguồn

Nếu được hỏi về cách làm, mở lần lượt:

1. `src/include/constants.inc`: các bit của một ô và của bộ luật.
2. `src/board.asm`, hàm `board_clear`: mảng có viền và bảng tra số ô.
3. `src/movegen.asm`, hàm `gen_captures`: điều kiện ăn quân chỉ là hai lần đọc mảng.
4. `src/rules.asm`, hàm `apply_step`: thứ tự phong vua rồi mới kiểm tra ăn tiếp.
5. `src/movegen.asm`, hàm `chain_len`: đệ quy với mảng cục bộ trên stack.
