# Everything that draws the board on the Run I/O console.

.include "include/constants.inc"

.globl display_board

.data
# indexed by (cell & 7): empty, b, r, -, -, B, R
piece_chars:    .ascii "0br??BR?"

.text

# Board in the layout from the assignment handout:
# blank for light squares, 0 for an empty dark square, r/b men, R/B kings.
display_board:
        addi    $sp, $sp, -16
        sw      $ra, 12($sp)
        sw      $s0, 8($sp)
        sw      $s1, 4($sp)
        sw      $s2, 0($sp)

        lw      $s2, board_n
        li      $s0, 0                  # row
db_row:
        li      $s1, 0                  # col
db_col:
        lw      $t0, board_w
        addi    $t1, $s0, 1
        mul     $t1, $t1, $t0
        add     $t1, $t1, $s1
        addi    $t1, $t1, 1

        la      $t2, idx_to_sq
        add     $t2, $t2, $t1
        lbu     $t2, 0($t2)
        bnez    $t2, db_dark

        # light square: skip it at the end of a row so there is no trailing blank
        addi    $t3, $s2, -1
        beq     $s1, $t3, db_next
        li      $t4, ' '
        j       db_put
db_dark:
        la      $t2, board
        add     $t2, $t2, $t1
        lbu     $t2, 0($t2)
        andi    $t2, $t2, 7
        la      $t3, piece_chars
        add     $t3, $t3, $t2
        lbu     $t4, 0($t3)
db_put:
        beqz    $s1, db_nosep
        print_chr(' ')
db_nosep:
        move    $a0, $t4
        li      $v0, SYS_PRINT_CHAR
        syscall
db_next:
        addi    $s1, $s1, 1
        blt     $s1, $s2, db_col

        print_chr('\n')
        addi    $s0, $s0, 1
        blt     $s0, $s2, db_row

        lw      $s2, 0($sp)
        lw      $s1, 4($sp)
        lw      $s0, 8($sp)
        lw      $ra, 12($sp)
        addi    $sp, $sp, 16
        jr      $ra
