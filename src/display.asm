# =============================================================================
# display.asm — Toàn bộ phần in ra terminal (bàn cờ, thông báo)
# =============================================================================
.include "include/constants.inc"

.globl display_banner

.data
banner_str:     .asciiz "=== Checkers (English draughts) - MARS MIPS ===\n"

.text
# -----------------------------------------------------------------------------
# display_banner — In dòng tiêu đề của game.
#   Input : không
#   Output: không
#   Đổi   : $a0, $v0
# -----------------------------------------------------------------------------
display_banner:
        la      $a0, banner_str
        li      $v0, SYS_PRINT_STR
        syscall
        jr      $ra
