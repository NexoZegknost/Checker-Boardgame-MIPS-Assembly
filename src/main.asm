# =============================================================================
# main.asm — Điểm vào chương trình và vòng lặp game
#
# Luồng dự kiến (hoàn thiện dần qua các milestone):
#   main
#    ├─ display_banner                     (M0)
#    ├─ board_init                         (M1)
#    └─ game_loop:
#         display_board                    (M1)
#         đọc nước đi + kiểm tra hợp lệ     (M2)
#         thực hiện nước đi / ăn chuỗi      (M2-M3)
#         kiểm tra kết thúc ván             (M4)
#         đổi lượt
# =============================================================================
.include "include/constants.inc"

.globl main

.text
main:
        jal     display_banner

        li      $v0, SYS_EXIT
        syscall
