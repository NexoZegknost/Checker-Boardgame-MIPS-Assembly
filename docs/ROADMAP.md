# Checkers MIPS — Roadmap dự án

Assignment CO2008 — *Checkers boardgame with MARS MIPS Assembly* (HCMUT, đề `CA_Assignment_261`).
Mục tiêu: hoàn thành **toàn bộ yêu cầu bắt buộc** (tối đa 9/10, Honors 8/10) **và các phần mở rộng** để lấy phần điểm còn lại.

---

## 1. Checklist yêu cầu từ đề

### 1.1 Bắt buộc (bare minimum — Mục 1 & 2 của đề)

| Mã | Yêu cầu | Nguồn |
|---|---|---|
| R1 | Bàn 8×8, chỉ 32 ô tối dùng được; mỗi bên 12 quân xếp như Hình 1. Đen (`b`) ở dưới, Đỏ (`r`) ở trên. **Đen đi trước**, hai bên luân phiên. | 1.2.1 |
| R2 | Quân thường (pawn) đi **chéo 1 ô về phía trước** vào ô trống. | 1.2.2 |
| R3 | Ăn quân: ô chéo phía trước có quân địch và ô ngay sau trống → nhảy qua, đáp ô sau, **xóa quân bị ăn**. | 1.2.3 |
| R4 | Ăn chuỗi: sau khi ăn, nếu còn ăn tiếp được thì **BẮT BUỘC** ăn tiếp, không giới hạn số lần. (Luật "bắt buộc ăn ở nước đầu" được bỏ qua trong bản tối thiểu.) | 1.2.3 |
| R5 | Phong vua khi tới hàng cuối (`R`/`B`). Vua đi/ăn **cả tiến lẫn lùi**, tầm vẫn 1 ô. Nếu được phong **trong lúc ăn** thì phong ngay và **được ăn lùi tiếp** trong cùng chuỗi (Hình 8). | 1.2.4 |
| R6 | Thắng khi đối thủ hết nước đi hợp lệ; **tối thiểu** phải phát hiện trường hợp đối thủ **hết quân** → thông báo người thắng → kết thúc. | 1.2.5 |
| R7 | Ký hiệu ô 1–32 (Hình 10, phe Đen ở dưới): ô 1–4 ở hàng trên cùng, 29 ở góc dưới trái, 4 ở góc trên phải. Nước đi ghi `a-b` (đi thường), `axb` (ăn). | 1.3 |
| R8 | **Mỗi lượt** in trạng thái bàn ra terminal MARS: `' '` ô không dùng, `r`/`b` quân thường, `R`/`B` vua, `0` ô trống. | 2.1 |
| R9 | Nhắc người chơi: `Black's turn.` / `Red's turn.`, `Enter starting square:`, `Enter landing square:`. | 2.2 |
| R10 | Kiểm tra hợp lệ: (a) ô xuất phát có quân? (b) quân thuộc người đang đi? (c) nước đi hợp lệ về hướng và ô đích trống? Sai → `Not a valid move! Try again.` và nhập lại. | 2.2 |
| R11 | Khi ăn: in `Captured <Color>'s piece.`, in lại bàn; nếu ăn chuỗi được → `Chaining possible.` rồi chỉ hỏi `Enter landing square:` (quân đang ăn giữ nguyên). | 2.2 |

> Những điểm đề không nói rõ nhưng nên xử lý: nhập số ngoài 1–32 hoặc không phải số; nhập ô đáp sai trong lúc ăn chuỗi (phải hỏi lại, không được bỏ chuỗi).

### 1.2 Mở rộng — Quality of Life (3.1)

| Mã | Tính năng |
|---|---|
| Q1 | Hiển thị bàn cờ đẹp hơn (khung, tọa độ, số ô in kèm, ký tự rõ ràng). |
| Q2 | Xoay bàn theo người đang đi (lượt Đỏ thì Đỏ ở dưới, "đi lên"). |
| Q3 | Ký hiệu ô theo người đang đi (với Đỏ, góc dưới trái cũng là 29 — Hình 11). |
| Q4 | Cách nhập khác: chọn quân → liệt kê mọi nước đi của quân đó → chọn theo số thứ tự; áp dụng cả khi ăn chuỗi. |
| Q5 | Thông báo lỗi chi tiết (ô trống, quân của đối thủ, sai hướng, ô đích bị chiếm, ngoài phạm vi, phải ăn tiếp…). |
| Q6 | Thắng khi đối thủ **bị chặn hết nước** (Hình 9). |
| Q7 | Đề nghị hòa: cả hai bên cùng đồng ý → kết thúc hòa. |
| Q8 | Chơi lại (restart) mà không thoát chương trình. |
| Q9 | Tự đề xuất (cần nêu lý do + cách cài đặt trong báo cáo): lịch sử nước đi theo ký hiệu chuẩn, undo, luật hòa sau N nước không ăn/không tiến, menu trợ giúp, đếm quân, chơi với máy… |

### 1.3 Mở rộng — Advanced rulesets (3.2)

| Mã | Tính năng |
|---|---|
| A1 | Bắt buộc ăn khi có thể ăn (luật Anh đầy đủ). |
| A2 | Bàn 10×10 với 15 hoặc 20 quân mỗi bên. |
| A3 | Biến thể khác: vua bay (flying king), quân thường được ăn lùi ngay từ đầu (vd. International / Brazilian / Russian). |
| A4 | Tự đề xuất phần khó hơn (vd. luật ăn tối đa của International draughts, AI đối thủ). |

### 1.4 Quy định chung & tiêu chí chấm (Mục 4)

- Nhóm **≤ 3** người. Hình thức nộp (báo cáo, mã nguồn, demo, vấn đáp) do giảng viên thông báo riêng → **cần hỏi lại deadline & format**.
- Được dùng AI viết code nhưng **phải hiểu và tự thiết kế**; đạo văn → cả hai nhóm bị trừ điểm.
- Tiêu chí: chức năng · **dễ đọc** · **cấu trúc tổng thể** · hiểu MIPS · kỹ năng báo cáo/trình bày.

---

## 2. Quyết định thiết kế nền tảng (làm ở M0, ảnh hưởng mọi milestone sau)

1. **Biểu diễn bàn cờ có viền (mailbox)**: mảng byte `(N+2)×(N+2)` với viền `WALL`, giá trị ô: `EMPTY`, `B_PAWN`, `B_KING`, `R_PAWN`, `R_KING`, `WALL`. Kiểm tra biên chỉ còn 1 phép so sánh, và **cùng code chạy được cho 8×8 lẫn 10×10** (A2) bằng cách đọc `N` từ biến cấu hình.
2. **Bảng tra ký hiệu ↔ chỉ số**: `sq_to_idx[]`, `idx_to_sq[]` sinh lúc khởi tạo theo `N` → dễ đổi phối cảnh (Q3) và kích thước bàn.
3. **4 hướng chéo là hằng số offset** (`±(N+2) ± 1`); quân thường lọc theo hướng "tiến" của phe, vua dùng cả 4 → một hàm `gen_moves(piece_idx)` dùng chung cho kiểm tra hợp lệ, ăn chuỗi, liệt kê nước (Q4), phát hiện hết nước (Q6), bắt buộc ăn (A1) và AI.
4. **Cấu trúc mã**: nhiều file `.asm` (MARS: *Settings → Assemble all files in directory*), mỗi module một nhiệm vụ, quy ước gọi hàm MIPS chuẩn (`$a0–$a3`, `$v0–$v1`, lưu `$s*`/`$ra` trên stack).
5. **Kiểm thử tự động**: chạy MARS dòng lệnh `java -jar Mars.jar nc sm <files> < tests/xxx.in` rồi so với `tests/xxx.out`; chạy trong GitHub Actions.

```
checkers-mips/
├─ src/
│  ├─ main.asm        # vòng lặp game, menu
│  ├─ config.asm      # hằng số, biến luật chơi (N, ruleset, cờ bắt buộc ăn…)
│  ├─ board.asm       # khởi tạo, mailbox, bảng tra ký hiệu
│  ├─ display.asm     # in bàn cờ, xoay bàn, thông báo
│  ├─ input.asm       # đọc & kiểm tra số nhập
│  ├─ movegen.asm     # sinh nước đi, nước ăn, ăn chuỗi
│  ├─ rules.asm       # hợp lệ, phong vua, bắt buộc ăn, thắng/hòa
│  ├─ history.asm     # lịch sử nước đi, undo
│  └─ ai.asm          # (tùy chọn) đối thủ máy
├─ tests/             # *.in / *.out cho từng tình huống
├─ scripts/run_tests.sh
├─ docs/              # design doc, sơ đồ luồng, ảnh chụp màn hình
├─ report/            # báo cáo LaTeX
└─ README.md
```

---

## 3. Milestones

Mỗi milestone kết thúc bằng một **release tag**; mục *Done khi* là tiêu chí đóng milestone.

### M0 — Khởi tạo & thiết kế
*Done khi: repo có cấu trúc thư mục, design doc được cả nhóm duyệt, MARS chạy được `main.asm` rỗng qua script.*
- Tạo repo, README, `.gitignore`, labels, branch protection (PR + review).
- Viết `docs/design.md`: biểu diễn bàn, mã quân, bảng tra ký hiệu, sơ đồ module, quy ước gọi hàm, sơ đồ luồng game.
- Script chạy MARS dòng lệnh + khung test (`scripts/run_tests.sh`), GitHub Actions cài Java + Mars.jar.
- Quy ước code: header mỗi hàm (mô tả, input, output, thanh ghi bị thay đổi), đặt nhãn `module_func_label`.

### M1 — Bàn cờ & hiển thị · `v0.1` · R1 R7 R8
*Done khi: in đúng bàn khởi đầu như mục 2.1 của đề.*
- `board_init`: mailbox, đặt 12 quân mỗi bên.
- Bảng `sq_to_idx` / `idx_to_sq` cho ký hiệu 1–32.
- `display_board` đúng định dạng đề (`' '`, `r b R B 0`).
- Test: bàn khởi đầu; bàn dựng tay có vua.

### M2 — Nhập liệu & đi quân thường · `v0.2` · R2 R9 R10
*Done khi: hai người chơi đi quân thường luân phiên, nước sai bị từ chối và hỏi lại.*
- Prompt lượt + đọc ô xuất phát/ô đáp, chặn ngoài 1–32.
- Kiểm tra 3 điều kiện R10; in `Not a valid move! Try again.`
- `gen_moves` cho nước đi thường (hướng theo phe; vua 4 hướng).
- Đổi lượt, in lại bàn mỗi lượt.
- Test: ví dụ `21 → 17` và `21 → 13` của đề.

### M3 — Ăn quân, ăn chuỗi, phong vua · `v0.3` · R3 R4 R5 R11
*Done khi: tái hiện đúng các ví dụ Hình 3–8 và đoạn log mục 2.2 (`9 → 18`, `Chaining possible.`).*
- Sinh nước ăn; thực hiện ăn, xóa quân, in `Captured … piece.`
- Vòng lặp ăn chuỗi bắt buộc: chỉ hỏi ô đáp, khóa quân đang ăn, không cho bỏ chuỗi.
- Phong vua khi tới hàng cuối, kể cả giữa chuỗi → ăn lùi tiếp.
- Test: chuỗi `15x24 24x31 31x22 22x13` (Hình 8); ăn chuỗi 3+ lần; phong vua bằng đi thường `5-1`.

### M4 — Kết thúc ván · **`v1.0` bản tối thiểu (9/10)** · R6
*Done khi: chơi trọn một ván từ đầu tới khi một bên hết quân; mọi test R1–R11 xanh.*
- Đếm quân mỗi bên; hết quân → thông báo người thắng, kết thúc.
- Rà soát toàn bộ checklist R1–R11, sửa lỗi, đóng băng nhánh `v1.0`.

### M5 — QoL I: giao diện & phản hồi · `v1.1` · Q1 Q2 Q3 Q5 Q6
- Q1 bàn có khung, tọa độ, chú thích, (tùy chọn) bảng số ô kế bên.
- Q2 xoay bàn theo người đang đi; Q3 đổi ký hiệu theo phối cảnh (bật/tắt trong menu).
- Q5 mã lỗi cho từng nguyên nhân + thông báo riêng.
- Q6 hết nước đi → thua (dùng lại `gen_moves`).

### M6 — QoL II: luồng chơi & tiện ích · `v1.2` · Q4 Q7 Q8 Q9
- Q4 chế độ chọn quân → danh sách nước đi đánh số (cả khi ăn chuỗi); cho phép chọn chế độ nhập cũ/mới.
- Q7 đề nghị hòa (cả hai đồng ý); Q8 restart không thoát chương trình; menu chính.
- Q9 lịch sử nước đi theo ký hiệu chuẩn (`21-17`, `15x24 24x31`), in khi kết thúc; undo; luật hòa sau N nước không ăn/không phong vua; lệnh `help`.

### M7 — Luật nâng cao · `v2.0` · A1 A2 A3 A4
- A1 bắt buộc ăn (tùy chọn bật/tắt): nếu có nước ăn thì chỉ chấp nhận nước ăn, báo lỗi riêng.
- A2 bàn 10×10, 15 hoặc 20 quân (tham số hóa `N`, số hàng quân, bảng ký hiệu 1–50).
- A3 biến thể: International (10×10, vua bay, quân thường ăn lùi), Brazilian (8×8 luật International), Russian (phong vua giữa chuỗi + vua bay).
- A4 (thách thức): luật **ăn nhiều nhất** của International; **AI đối thủ** (ngẫu nhiên → tham lam → minimax độ sâu nhỏ).
- Menu chọn luật chơi lúc bắt đầu.

### M8 — Kiểm thử, tối ưu & làm sạch mã · `v2.1`
- Bộ test hồi quy cho mọi R/Q/A; test tình huống biên (chặn hết nước, chuỗi dài, phong vua giữa chuỗi, nhập rác).
- Review khả năng đọc: chú thích, tên nhãn, tách hàm dài, xóa code chết.
- Đo số lệnh/kích thước (MARS *Instruction Statistics*) để đưa vào báo cáo.

### M9 — Báo cáo & demo · `v3.0` (bản nộp)
- Báo cáo LaTeX: giới thiệu luật, thiết kế dữ liệu, sơ đồ module/luồng, giải thích các hàm MIPS chính, **lý do + cách cài từng tính năng mở rộng**, kết quả test, ảnh chụp, phân công.
- Slide + kịch bản demo (ván mẫu chạy qua mọi tính năng); chuẩn bị câu hỏi vấn đáp về MIPS (stack frame, syscall, địa chỉ mảng, nhánh/nhảy).
- Đóng gói bài nộp theo yêu cầu giảng viên.

---

## 4. Thứ tự phụ thuộc

```
M0 → M1 → M2 → M3 → M4 (v1.0)
                       ├→ M5 ─┐
                       ├→ M6 ─┼→ M8 → M9
                       └→ M7 ─┘
```
M5, M6, M7 có thể làm song song khi nhóm có 3 người, vì đều dựa trên `gen_moves` và mailbox đã xong ở M2–M3.
