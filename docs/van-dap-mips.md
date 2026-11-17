# Ôn vấn đáp: MIPS trong bài này

Các câu hỏi có thể gặp, kèm chỗ trong mã nguồn để chỉ ra khi trả lời.

## Quy ước gọi hàm và stack

**Hàm nhận tham số và trả kết quả thế nào?**
Tham số trong `$a0–$a3`, kết quả trong `$v0`, `$v1`. Ví dụ `gen_captures` nhận ô trong `$a0`, địa chỉ vùng ghi trong `$a1`, trả số nước trong `$v0`.

**Vì sao phải lưu `$ra`?**
`jal` ghi địa chỉ quay về vào `$ra`. Hàm nào còn gọi hàm khác sẽ làm mất giá trị đó, nên phải cất `$ra` lên stack ở đầu hàm và lấy lại trước `jr $ra`. Hàm lá như `cell_of_sq` không cần.

**Khác nhau giữa `$t` và `$s`?**
`$t` có thể bị hàm được gọi thay đổi, `$s` thì hàm được gọi phải giữ nguyên. Vì vậy giá trị cần sống qua một lệnh `jal` được để trong `$s`, và hàm dùng `$s` nào thì cất `$s` đó. Xem phần đầu và cuối `apply_step`.

**Stack lớn lên theo chiều nào? Khung stack của một hàm gồm gì?**
Stack đi xuống: cấp chỗ bằng `addi $sp, $sp, -N`, trả lại bằng `+N`. `chain_len` cấp 176 byte: 16 byte cho `$ra`, `$s0–$s2` và 160 byte làm mảng cục bộ chứa các nước ăn tiếp theo.

**Đệ quy hoạt động ra sao?**
Mỗi lần gọi `chain_len` có khung stack riêng nên các biến cục bộ không đè lên nhau. Độ sâu đệ quy bằng số quân ăn được trong một chuỗi.

**`$fp` dùng làm gì?**
Trong `search` (`ai.asm`), số nước đi cần chép lên stack chỉ biết lúc chạy, nên `$sp` bị trừ một lượng thay đổi. `$fp` giữ vị trí đáy khung để cuối hàm lấy lại `$sp` bằng `move $sp, $fp`.

## Bộ nhớ và dữ liệu

**Truy cập một phần tử mảng byte thế nào?**
Địa chỉ = địa chỉ đầu mảng + chỉ số: `la $t0, board`, `add $t1, $t0, $a0`, `lbu $t2, 0($t1)`. Dùng `lbu` vì chỉ số ô có thể tới 143, lớn hơn 127; `lb` sẽ mở rộng dấu thành số âm.

**Còn mảng word?**
Chỉ số phải nhân 4: `sll $t0, $s1, 2` rồi `lw $a0, legal_buf($t0)`.

**`.align 2` để làm gì?**
`lw`/`sw` yêu cầu địa chỉ chia hết cho 4. Một vùng `.space` đặt sau các chuỗi `.asciiz` có thể rơi vào địa chỉ lẻ, MARS sẽ báo *address not aligned on word boundary*. Bài này từng gặp đúng lỗi đó ở vùng đệm nước đi.

**Vì sao mã hóa ô bằng bit?**
Để một lệnh `andi` trả lời được câu hỏi "có phải quân của bên này", "có phải vua". Ví dụ quân đối phương của bên `p` là `ô & (p ^ 3)`.

**Một nước đi lưu thế nào?**
Một word: byte 0 là ô đi, byte 1 là ô đến, byte 2 là ô bị ăn. Tách bằng `andi` và `srl`.

**`.eqv` khác gì nhãn dữ liệu?**
`.eqv` là thay thế văn bản lúc dịch, không chiếm bộ nhớ (`.eqv KING 4`). Nhãn dữ liệu là địa chỉ của một ô nhớ.

## Lệnh và giả lệnh

**`li`, `la`, `move`, `blt` có phải lệnh thật không?**
Là giả lệnh. MARS dịch `li` thành `addiu` hoặc `lui` + `ori`; `la` thành `lui` + `ori`; `move` thành `addu`; `blt` thành `slt` + `bne`. Xem cột *Basic* trong cửa sổ Execute.

**`j` khác `jal` khác `jr`?**
`j` nhảy tới nhãn. `jal` nhảy và ghi địa chỉ lệnh kế tiếp vào `$ra`. `jr $ra` nhảy tới địa chỉ trong thanh ghi, dùng để quay về.

**`div` cho kết quả ở đâu?**
Thương trong `LO`, dư trong `HI`, lấy bằng `mflo`, `mfhi`. `explain_landing` dùng để đổi chỉ số ô thành hàng và cột.

**Syscall dùng những mã nào?**
1 in số, 4 in chuỗi, 8 đọc chuỗi, 10 thoát, 11 in ký tự, 42 số ngẫu nhiên. Mã đặt trong `$v0`, tham số trong `$a0`, `$a1`.

**Vì sao không dùng syscall 5 để đọc số?**
Gõ chữ vào syscall 5 làm MARS dừng chương trình. Đọc chuỗi rồi tự đổi sang số (`read_digits` trong `input.asm`) thì kiểm soát được lỗi.

## Tổ chức chương trình

**Nhiều file ghép với nhau thế nào?**
MARS dịch mọi file `.asm` trong thư mục khi bật *Assemble all files in directory*. Nhãn muốn dùng ở file khác phải khai báo `.globl`. Hằng số chung nằm trong `include/constants.inc`, được `.include` vào từng file.

**Macro khác hàm ở đâu?**
Macro được chép nguyên văn vào chỗ gọi lúc dịch, không có `jal`. Bài chỉ dùng macro cho việc rất ngắn như `print_str`, `push`, `pop`.

**Thêm một biến thể luật mới cần sửa gì?**
Thêm một dòng vào bảng `presets` và một tên vào `rules_names` trong `settings.asm`. Nếu biến thể cần luật chưa có thì thêm một bit `RULE_...` và đọc bit đó ở `movegen.asm` hoặc `rules.asm`.
