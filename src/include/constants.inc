# =============================================================================
# constants.inc — Hằng số dùng chung cho mọi module
# Dùng: .include "include/constants.inc"  (ở đầu mỗi file .asm trong src/)
# File đuôi .inc để MARS không assemble nó như một module riêng.
# =============================================================================

# ---------- Syscall MARS ----------
.eqv SYS_PRINT_INT     1
.eqv SYS_PRINT_STR     4
.eqv SYS_READ_INT      5
.eqv SYS_READ_STR      8
.eqv SYS_EXIT          10
.eqv SYS_PRINT_CHAR    11
.eqv SYS_READ_CHAR     12

# ---------- Mã ô / quân (bit flags, 1 byte mỗi ô) ----------
# bit0 = Đen, bit1 = Đỏ, bit2 = Vua, bit3 = Tường (viền mailbox)
.eqv EMPTY             0x00
.eqv BLACK             0x01
.eqv RED               0x02
.eqv KING              0x04
.eqv WALL              0x08
.eqv COLOR_MASK        0x03

.eqv B_PAWN            0x01     # BLACK
.eqv R_PAWN            0x02     # RED
.eqv B_KING            0x05     # BLACK | KING
.eqv R_KING            0x06     # RED   | KING

# ---------- Kích thước ----------
.eqv MAX_N             10       # bàn lớn nhất hỗ trợ (10x10)
.eqv MAX_W             12       # MAX_N + 2 (viền)
.eqv MAX_CELLS         144      # MAX_W * MAX_W
.eqv MAX_SQUARES       50       # số ô tối dùng được trên bàn 10x10
