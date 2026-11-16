# Shared constants and a few small macros.
# Kept as .inc so MARS does not try to assemble it on its own.

# syscalls
.eqv SYS_PRINT_INT   1
.eqv SYS_PRINT_STR   4
.eqv SYS_READ_STR    8
.eqv SYS_EXIT        10
.eqv SYS_PRINT_CHAR  11

# what a board cell can hold (one byte per cell)
.eqv EMPTY       0
.eqv BLACK       1
.eqv RED         2
.eqv KING        4
.eqv WALL        8
.eqv COLOR_MASK  3

# result of parse_line
.eqv P_BAD       0
.eqv P_NUM       1
.eqv P_CMD       2

# the board array is sized for 10x10 plus a one-cell border
.eqv MAX_CELLS   144
.eqv MAX_SQUARES 50

.macro print_str (%label)
        la      $a0, %label
        li      $v0, SYS_PRINT_STR
        syscall
.end_macro

.macro print_chr (%c)
        li      $a0, %c
        li      $v0, SYS_PRINT_CHAR
        syscall
.end_macro

.macro print_num (%reg)
        move    $a0, %reg
        li      $v0, SYS_PRINT_INT
        syscall
.end_macro

.macro push (%reg)
        addi    $sp, $sp, -4
        sw      %reg, 0($sp)
.end_macro

.macro pop (%reg)
        lw      %reg, 0($sp)
        addi    $sp, $sp, 4
.end_macro
