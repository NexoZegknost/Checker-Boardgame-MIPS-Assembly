# Thiết kế kỹ thuật

Tài liệu này chốt các quyết định nền tảng trong M0. Thay đổi bất kỳ mục nào ở đây cần cả nhóm đồng ý qua PR.

## 1. Biểu diễn bàn cờ: mailbox có viền

Bàn `N×N` (N = 8, hoặc 10 cho luật mở rộng) được lưu trong mảng byte `board` kích thước `W×W` với `W = N + 2`. Hàng/cột ngoài cùng là viền `WALL`.

```
chỉ số ô:  idx = (r + 1) * W + (c + 1)      r, c tính từ 0, gốc ở góc TRÊN-TRÁI (phía Đỏ)
```

Lý do chọn mailbox:
- Đi ra ngoài bàn chỉ cần kiểm tra `board[idx] == WALL`, không phải so sánh hàng/cột.
- Đổi sang 10×10 chỉ cần đổi `N`, `W` (biến lúc chạy, không phải hằng số) và bảng tra ký hiệu.
- Bộ nhớ dành sẵn `MAX_CELLS = 144` byte cho trường hợp lớn nhất.

### Mã ô (1 byte, bit flags — `src/include/constants.inc`)

| Giá trị | Tên | In ra |
|---|---|---|
| `0x00` | `EMPTY` | `0` |
| `0x01` | `B_PAWN` (BLACK) | `b` |
| `0x02` | `R_PAWN` (RED) | `r` |
| `0x05` | `B_KING` (BLACK\|KING) | `B` |
| `0x06` | `R_KING` (RED\|KING) | `R` |
| `0x08` | `WALL` | — |

Kiểm tra nhanh bằng `andi`:
- quân của phe `p`: `(cell & p) != 0`
- quân đối phương: `(cell & (p ^ COLOR_MASK)) != 0`
- là vua: `(cell & KING) != 0`

## 2. Ký hiệu ô (notation)

Ô tối là ô có `(r + c)` lẻ. Với `H = N / 2` ô tối mỗi hàng, ô số `s` (bắt đầu từ 1, phe Đen ở dưới, Hình 10 của đề):

```
r = (s - 1) / H
k = (s - 1) % H
c = 2k + 1   nếu r chẵn
c = 2k       nếu r lẻ
```

Kiểm tra với 8×8: ô 1 = (0,1), ô 4 = (0,7) góc trên phải, ô 29 = (7,0) góc dưới trái. ✔

Hai bảng tra được sinh trong `board_init`:
- `sq_to_idx[s]` — ký hiệu → chỉ số mailbox
- `idx_to_sq[idx]` — chỉ số mailbox → ký hiệu (0 nếu không phải ô tối)

**Phối cảnh phe Đỏ (Q3):** xoay 180° ⇒ `s_red = N*N/2 + 1 - s` (8×8: `33 - s`, nên ô 4 thành 29 ở góc dưới trái của Đỏ, khớp Hình 11).

## 3. Hướng đi

| Hướng | Offset |
|---|---|
| Tây Bắc | `-W - 1` |
| Đông Bắc | `-W + 1` |
| Tây Nam | `+W - 1` |
| Đông Nam | `+W + 1` |

- Đen tiến = Bắc (offset âm), Đỏ tiến = Nam (offset dương).
- Quân thường chỉ dùng 2 hướng tiến; vua dùng cả 4.
- Hàng phong vua: Đen ở `r = 0`, Đỏ ở `r = N - 1`.

## 4. Biểu diễn nước đi

Mỗi nước là 1 word:

```
bit 31..24  cờ (bit0 = là nước ăn)
bit 23..16  idx bị ăn (0 nếu đi thường)
bit 15..8   idx đích
bit  7..0   idx xuất phát
```

`gen_moves(idx)` ghi danh sách nước vào `move_buf` và trả về số nước trong `$v0`. Hàm này dùng chung cho: kiểm tra hợp lệ (R10), ăn chuỗi (R4), liệt kê nước để chọn (Q4), phát hiện hết nước (Q6), bắt buộc ăn (A1), AI (A4).

## 5. Trạng thái game (`.data` trong `board.asm` / `rules.asm`)

| Biến | Kiểu | Ý nghĩa |
|---|---|---|
| `N`, `W` | word | kích thước bàn |
| `board` | byte[144] | mailbox |
| `turn` | word | `BLACK` hoặc `RED` |
| `count_black`, `count_red` | word | số quân còn lại |
| `chain_piece` | word | idx quân đang ăn chuỗi, `-1` nếu không |
| `rules` | word | bit flags luật: bắt buộc ăn, vua bay, quân thường ăn lùi… |
| `plies_no_progress` | word | đếm nước cho luật hòa (Q9) |

## 6. Module

| File | Trách nhiệm | Milestone |
|---|---|---|
| `main.asm` | điểm vào, menu, vòng lặp game | M0–M6 |
| `display.asm` | in bàn cờ, thông báo, xoay bàn | M1, M5 |
| `board.asm` | khởi tạo, bảng tra ký hiệu, đặt/xóa quân | M1 |
| `input.asm` | đọc số, kiểm tra phạm vi, chế độ nhập | M2, M6 |
| `movegen.asm` | `gen_moves`, `gen_captures`, `has_any_move` | M2, M3, M7 |
| `rules.asm` | áp dụng nước, phong vua, thắng/thua/hòa | M3, M4, M6 |
| `history.asm` | lịch sử nước đi, undo | M6 |
| `ai.asm` | đối thủ máy | M7 |

## 7. Quy ước viết mã

- Mỗi file bắt đầu bằng `.include "include/constants.inc"`; hằng số dùng chung chỉ đặt ở đó.
- Hàm dùng chéo module khai báo `.globl`; nhãn nội bộ đặt tiền tố tên hàm (`gen_moves_loop`).
- Header mỗi hàm: mô tả, Input, Output, thanh ghi bị đổi (xem `display_banner`).
- Quy ước gọi MIPS chuẩn: tham số `$a0–$a3`, trả về `$v0–$v1`; hàm nào gọi hàm khác hoặc dùng `$s*` phải lưu `$ra`/`$s*` lên stack và khôi phục trước `jr $ra`.
- Không dùng số ma thuật: dùng `.eqv` hoặc biến.
- Mỗi tính năng đi kèm ít nhất một test `tests/<milestone>_<tên>.in/.out`.
