# Everything that draws the board on the Run I/O console.

.include "include/constants.inc"

.globl display_board, print_side

.data
# indexed by (cell & 7): empty, b, r, -, -, B, R
piece_chars:    .ascii "0br??BR?"
str_black:      .asciiz "Black"
str_red:        .asciiz "Red"

str_margin:     .asciiz "  "
str_border:     .asciiz "----+"
str_light:      .asciiz "    |"
str_score_b:    .asciiz "  Black: "
str_score_r:    .asciiz "   Red: "

.text

display_board:
        lw      $t0, opt_view
        bnez    $t0, display_framed
        # falls through to the plain board

# Board in the layout from the assignment handout:
# blank for light squares, 0 for an empty dark square, r/b men, R/B kings.
display_plain:
        addi    $sp, $sp, -16
        sw      $ra, 12($sp)
        sw      $s0, 8($sp)
        sw      $s1, 4($sp)
        sw      $s2, 0($sp)

        lw      $s2, board_n
        li      $s0, 0                  # row on screen
dp_row:
        li      $s1, 0                  # column on screen
dp_col:
        move    $a0, $s0
        move    $a1, $s1
        jal     screen_cell
        bnez    $v1, dp_dark

        # no trailing blank at the end of a row
        addi    $t3, $s2, -1
        beq     $s1, $t3, dp_next
        li      $t4, ' '
        j       dp_put
dp_dark:
        move    $a0, $v0
        jal     piece_char
        move    $t4, $v0
dp_put:
        beqz    $s1, dp_nosep
        print_chr(' ')
dp_nosep:
        move    $a0, $t4
        li      $v0, SYS_PRINT_CHAR
        syscall
dp_next:
        addi    $s1, $s1, 1
        blt     $s1, $s2, dp_col

        print_chr('\n')
        addi    $s0, $s0, 1
        blt     $s0, $s2, dp_row

        lw      $s2, 0($sp)
        lw      $s1, 4($sp)
        lw      $s0, 8($sp)
        lw      $ra, 12($sp)
        addi    $sp, $sp, 16
        jr      $ra

# Board with a frame, dark squares show their number:  | 9 r|    |10 .|
display_framed:
        addi    $sp, $sp, -20
        sw      $ra, 16($sp)
        sw      $s0, 12($sp)
        sw      $s1, 8($sp)
        sw      $s2, 4($sp)
        sw      $s3, 0($sp)

        lw      $s2, board_n
        li      $s0, 0
df_row:
        jal     frame_line
        print_str(str_margin)
        print_chr('|')
        li      $s1, 0
df_col:
        move    $a0, $s0
        move    $a1, $s1
        jal     screen_cell
        bnez    $v1, df_dark
        print_str(str_light)
        j       df_next
df_dark:
        move    $s3, $v0
        move    $a0, $s3
        jal     sq_of_cell
        move    $t0, $v0
        bge     $t0, 10, df_number
        print_chr(' ')
df_number:
        print_num($t0)
        print_chr(' ')
        move    $a0, $s3
        jal     piece_char
        bne     $v0, '0', df_piece
        li      $v0, '.'
df_piece:
        move    $a0, $v0
        li      $v0, SYS_PRINT_CHAR
        syscall
        print_chr('|')
df_next:
        addi    $s1, $s1, 1
        blt     $s1, $s2, df_col
        print_chr('\n')
        addi    $s0, $s0, 1
        blt     $s0, $s2, df_row

        jal     frame_line
        print_str(str_score_b)
        lw      $a0, count_black
        li      $v0, SYS_PRINT_INT
        syscall
        print_str(str_score_r)
        lw      $a0, count_red
        li      $v0, SYS_PRINT_INT
        syscall
        print_chr('\n')

        lw      $s3, 0($sp)
        lw      $s2, 4($sp)
        lw      $s1, 8($sp)
        lw      $s0, 12($sp)
        lw      $ra, 16($sp)
        addi    $sp, $sp, 20
        jr      $ra

# "  +----+----+ ... +" as wide as the board
frame_line:
        print_str(str_margin)
        print_chr('+')
        lw      $t0, board_n
fl_loop:
        print_str(str_border)
        addi    $t0, $t0, -1
        bgtz    $t0, fl_loop
        print_chr('\n')
        jr      $ra

# a0 = row, a1 = column on screen. v0 = cell shown there, v1 = 0 if light.
screen_cell:
        lw      $t0, view_flip
        beqz    $t0, sc_index
        lw      $t0, board_n
        addi    $t0, $t0, -1
        sub     $a0, $t0, $a0
        sub     $a1, $t0, $a1
sc_index:
        lw      $t0, board_w
        addi    $v0, $a0, 1
        mul     $v0, $v0, $t0
        add     $v0, $v0, $a1
        addi    $v0, $v0, 1
        la      $t0, idx_to_sq
        add     $t0, $t0, $v0
        lbu     $v1, 0($t0)
        jr      $ra

# a0 = cell, v0 = the character for what stands on it
piece_char:
        la      $t0, board
        add     $t0, $t0, $a0
        lbu     $t0, 0($t0)
        andi    $t1, $t0, GHOST
        bnez    $t1, pc_ghost
        andi    $t0, $t0, 7
        la      $t1, piece_chars
        add     $t1, $t1, $t0
        lbu     $v0, 0($t1)
        jr      $ra
pc_ghost:
        li      $v0, 'x'                # jumped, taken off at the end of the turn
        jr      $ra

# Prints "Black" or "Red" for the colour in a0.
print_side:
        move    $t0, $a0
        la      $a0, str_black
        beq     $t0, BLACK, ps_out
        la      $a0, str_red
ps_out:
        li      $v0, SYS_PRINT_STR
        syscall
        jr      $ra
