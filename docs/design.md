# Thiết kế

Tài liệu này mô tả cách chương trình được tổ chức, đủ để đọc mã nguồn mà không bị lạc.

## 1. Bàn cờ

Bàn `n×n` (n = 8 hoặc 10) nằm trong một mảng byte `(n+2)×(n+2)`, vòng ngoài cùng là `WALL`:

```
chỉ số ô = (hàng + 1) * w + (cột + 1),  w = n + 2,  hàng 0 là hàng cuối của Đỏ
```

Nhờ vòng `WALL`, bước ra ngoài bàn chỉ là đọc phải một ô khác 0, không cần so sánh hàng/cột. Bốn hướng chéo là bốn hằng số cộng vào chỉ số (`dirs`): `-(w+1)`, `-(w-1)`, `w-1`, `w+1`. Đen tiến lên bằng hai hướng đầu, Đỏ tiến xuống bằng hai hướng sau.

Mỗi ô là một byte ghép từ các bit:

| Bit | Tên | Ý nghĩa |
|---|---|---|
| 0x01 | `BLACK` | quân Đen |
| 0x02 | `RED` | quân Đỏ |
| 0x04 | `KING` | là vua |
| 0x08 | `WALL` | viền |
| 0x10 | `GHOST` | đã bị ăn trong lượt này nhưng chưa nhấc khỏi bàn |

"Có phải quân của phe p" là `ô & p`, "có phải quân đối phương" là `ô & (p ^ 3)`.

## 2. Số ô

Ô tối là ô có `hàng + cột` lẻ, được đánh số từ 1 theo từng hàng, từ trên xuống. `board_clear` dựng hai bảng tra `sq_to_idx` và `idx_to_sq` theo `n`, nên cùng một đoạn mã dùng cho 32 ô lẫn 50 ô.

Người chơi luôn gõ và nhìn thấy số ô qua hai hàm `cell_of_sq` / `sq_of_cell`. Khi bật tùy chọn xoay cả số ô và đang là lượt Đỏ, hai hàm này đổi `k` thành `tổng + 1 − k` (xoay bàn 180°). Biên bản ván đấu luôn ghi theo số ô chuẩn.

## 3. Nước đi

Một bước đi là một word:

```
bit 0..7    ô xuất phát
bit 8..15   ô đáp
bit 16..23  ô bị nhảy qua (0 nếu là nước đi thường)
```

Một lượt ăn chuỗi gồm nhiều bước, mỗi bước một word.

- `gen_simple`, `gen_captures`: nước đi thường / nước ăn của **một** quân.
- `gen_legal`: mọi bước hợp lệ của bên đang đi, ghi vào `legal_buf`. Nước ăn được sinh trước. Nếu đang ăn chuỗi (`chain_piece ≠ 0`) thì chỉ còn nước ăn của quân đó.
- `filter_jumps`: bỏ những nước ăn mà bộ luật không cho (luật ăn nhiều nhất, luật chọn ô đáp của vua bay).

Mọi chỗ cần biết "nước này có hợp lệ không" đều tra trong `legal_buf`: kiểm tra nước người chơi gõ, liệt kê nước để chọn, phát hiện bị chặn hết nước, và cả máy.

`apply_step` thực hiện một bước và trả về các bit `STEP_CAPTURE`, `STEP_PROMOTED`, `STEP_CHAIN`. Nếu quân vừa ăn còn ăn tiếp được thì lượt chưa đổi và `chain_piece` trỏ tới quân đó.

## 4. Thế cờ và việc "thử rồi trả lại"

Tất cả những gì thay đổi trong một ván nằm liền nhau từ nhãn `state` đến `state_end` (bàn cờ, lượt, quân đang ăn chuỗi, số quân, bộ đếm hòa, độ dài biên bản, lời cầu hòa): 172 byte. `state_save` / `state_load` chép nguyên khối này. Ba tính năng dùng chung cơ chế đó:

- **Đi lại**: đầu mỗi lượt lưu một bản vào `undo_stack`; `u` nạp lại bản cũ.
- **Chơi lại**: nạp bản lưu lúc ván bắt đầu.
- **Thử nước đi**: `snap_push` → `apply_step` → xem kết quả → `snap_pop`. Luật ăn nhiều nhất (`chain_len`) và máy (`search`) đều làm vậy, nên chúng không cần hiểu riêng từng luật.

## 5. Bộ luật

`rule_flags` là một word, mỗi bit một luật (`RULE_MUST_CAPTURE`, `RULE_LONGEST`, `RULE_FLYING`, `RULE_JUMP_BACK`, `RULE_MOVE_BACK`, `RULE_CROWN_LATE`, `RULE_REMOVE_LATE`). Tất cả bằng 0 là luật của đề. Kích thước bàn và số hàng quân cũng lấy từ bộ luật.

Một bộ luật có sẵn chỉ là một dòng trong bảng `presets` của `settings.asm`. Thêm biến thể mới nghĩa là thêm một dòng vào bảng và một tên vào menu.

## 6. Máy

Mức dễ chọn ngẫu nhiên một bước hợp lệ. Hai mức còn lại dùng negamax có cắt tỉa alpha-beta, sâu 2 hoặc 4 lượt. Hàm lượng giá đếm quân (quân thường 100, vua 180, vua bay 300) cộng một ít điểm cho quân thường đã tiến gần hàng phong vua. Một chuỗi ăn được tính là một lượt: khi cùng một bên còn đi tiếp, độ sâu giữ nguyên.

## 7. Số lệnh thực thi

Đo bằng tùy chọn `ic` của MARS khi chạy dòng lệnh:

| Việc | Số lệnh (xấp xỉ) |
|---|---|
| Khởi động, in menu và bàn cờ đầu tiên | 9 000 |
| Một lượt của người chơi (kiểm tra, đi, in lại bàn) | 6 000 |
| Một nước của máy, mức trung bình | 96 000 |
| Một nước của máy, mức khó | 950 000 |
| Cả một ván 43 nước (test `m4_full_game`) | 256 000 |

## 8. Quy ước viết mã

- Mỗi file một việc; hàm dùng ngoài file khai báo `.globl` ở đầu file.
- Hằng số và macro dùng chung chỉ nằm trong `src/include/constants.inc`.
- Tham số trong `$a0–$a3`, kết quả trong `$v0–$v1`. Hàm nào gọi hàm khác thì lưu `$ra` và các `$s` nó dùng lên stack.
- Nhãn nội bộ mang tiền tố viết tắt của hàm (`gl_` trong `gen_legal`, `as_` trong `apply_step`).
- Vùng nhớ đọc/ghi theo word luôn có `.align 2` phía trước.
