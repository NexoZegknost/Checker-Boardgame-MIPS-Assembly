# Board storage and square numbering.
#
# The n x n board sits inside a (n+2) x (n+2) byte array whose outer ring is
# WALL, so stepping off the board never needs a row/column check.
# cell index = (row + 1) * w + (col + 1), row 0 is Red's back rank.

.include "include/constants.inc"

.globl board, turn, chain_piece, count_black, count_red
.globl board_n, board_w, men_rows, num_squares, dirs
.globl sq_to_idx, idx_to_sq, view_flip, num_flip
.globl board_clear, board_reset, cell_of_sq, sq_of_cell, set_perspective

.data
board:          .space MAX_CELLS
turn:           .word BLACK
chain_piece:    .word 0                 # cell of the piece that must keep jumping, 0 = none
count_black:    .word 0
count_red:      .word 0

board_n:        .word 8
board_w:        .word 10
men_rows:       .word 3
num_squares:    .word 32

# up-left, up-right, down-left, down-right (filled in by board_clear)
dirs:           .word -11, -9, 9, 11

# checkers notation <-> cell index, square numbers start at 1
sq_to_idx:      .space 52
idx_to_sq:      .space MAX_CELLS

# set at the start of every turn from the point-of-view option
                .align 2
view_flip:      .word 0                 # draw the board with Red at the bottom
num_flip:       .word 0                 # square numbers are counted from Red's side

.text

# Empty board for the current board_n, also rebuilds the lookup tables.
board_clear:
        lw      $t0, board_n
        addi    $t1, $t0, 2             # w
        sw      $t1, board_w
        mul     $t2, $t0, $t0
        srl     $t2, $t2, 1
        sw      $t2, num_squares

        la      $t3, dirs
        addi    $t4, $t1, 1
        neg     $t5, $t4
        sw      $t5, 0($t3)
        addi    $t5, $t5, 2
        sw      $t5, 4($t3)
        addi    $t5, $t1, -1
        sw      $t5, 8($t3)
        sw      $t4, 12($t3)

        la      $t3, board
        la      $t4, idx_to_sq
        li      $t5, 0
        li      $t6, WALL
bc_wall:
        add     $t7, $t3, $t5
        sb      $t6, 0($t7)
        add     $t7, $t4, $t5
        sb      $zero, 0($t7)
        addi    $t5, $t5, 1
        blt     $t5, MAX_CELLS, bc_wall

        li      $t5, 0                  # row
        li      $t8, 1                  # next square number
bc_row:
        li      $t6, 0                  # col
bc_col:
        addi    $t7, $t5, 1
        mul     $t7, $t7, $t1
        add     $t7, $t7, $t6
        addi    $t7, $t7, 1
        add     $t9, $t3, $t7
        sb      $zero, 0($t9)

        # only the dark squares (row + col odd) get a number
        add     $t9, $t5, $t6
        andi    $t9, $t9, 1
        beqz    $t9, bc_next
        la      $t9, sq_to_idx
        add     $t9, $t9, $t8
        sb      $t7, 0($t9)
        add     $t9, $t4, $t7
        sb      $t8, 0($t9)
        addi    $t8, $t8, 1
bc_next:
        addi    $t6, $t6, 1
        blt     $t6, $t0, bc_col
        addi    $t5, $t5, 1
        blt     $t5, $t0, bc_row

        li      $t0, BLACK
        sw      $t0, turn
        sw      $zero, chain_piece
        sw      $zero, count_black
        sw      $zero, count_red
        jr      $ra

# Starting position: Red on the low squares, Black mirrored at the bottom.
board_reset:
        push    ($ra)
        jal     board_clear

        lw      $t0, men_rows
        lw      $t1, board_n
        srl     $t1, $t1, 1
        mul     $t0, $t0, $t1           # men per side
        lw      $t2, num_squares
        la      $t3, sq_to_idx
        la      $t4, board
        li      $t5, 1
br_loop:
        add     $t6, $t3, $t5
        lbu     $t6, 0($t6)
        add     $t6, $t4, $t6
        li      $t7, RED
        sb      $t7, 0($t6)

        sub     $t6, $t2, $t5
        addi    $t6, $t6, 1
        add     $t6, $t3, $t6
        lbu     $t6, 0($t6)
        add     $t6, $t4, $t6
        li      $t7, BLACK
        sb      $t7, 0($t6)

        addi    $t5, $t5, 1
        ble     $t5, $t0, br_loop

        sw      $t0, count_black
        sw      $t0, count_red
        pop     ($ra)
        jr      $ra

# a0 = square number as typed by the player
# v0 = cell index, or 0 when the number is not on the board
cell_of_sq:
        li      $v0, 0
        blez    $a0, cs_done
        lw      $t0, num_squares
        bgt     $a0, $t0, cs_done
        lw      $t1, num_flip
        beqz    $t1, cs_lookup
        sub     $a0, $t0, $a0           # turning the board maps k to total + 1 - k
        addi    $a0, $a0, 1
cs_lookup:
        la      $t0, sq_to_idx
        add     $t0, $t0, $a0
        lbu     $v0, 0($t0)
cs_done:
        jr      $ra

# a0 = cell index, v0 = its square number as the player sees it
# (0 for a light square)
sq_of_cell:
        la      $t0, idx_to_sq
        add     $t0, $t0, $a0
        lbu     $v0, 0($t0)
        beqz    $v0, sc_done
        lw      $t1, num_flip
        beqz    $t1, sc_done
        lw      $t0, num_squares
        sub     $v0, $t0, $v0
        addi    $v0, $v0, 1
sc_done:
        jr      $ra

# Works out view_flip and num_flip for the side to move.
set_perspective:
        sw      $zero, view_flip
        sw      $zero, num_flip
        lw      $t0, turn
        bne     $t0, RED, sp_done
        lw      $t0, opt_persp
        beqz    $t0, sp_done
        li      $t1, 1
        sw      $t1, view_flip
        bne     $t0, 2, sp_done
        sw      $t1, num_flip
sp_done:
        jr      $ra
