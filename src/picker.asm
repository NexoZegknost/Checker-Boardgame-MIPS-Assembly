# Helpers for the "choose from a list" way of entering moves.
# They all read legal_buf, so gen_legal has to run first.

.include "include/constants.inc"

.globl print_move, list_movable, list_moves, nth_move

.data
msg_movable:    .asciiz "Pieces that can move:"
msg_moves_for:  .asciiz "Moves for "
str_colon:      .asciiz ":\n"
str_item:       .asciiz ") "

.text

# Prints the packed move in a0 the way games are written down:
# 22-18 for a plain move, 22x15 for a jump.
print_move:
        addi    $sp, $sp, -8
        sw      $ra, 4($sp)
        sw      $s0, 0($sp)
        move    $s0, $a0
        andi    $a0, $s0, 0xff
        jal     sq_of_cell
        print_num($v0)
        srl     $t0, $s0, 16
        li      $a0, '-'
        beqz    $t0, pm_sep
        li      $a0, 'x'
pm_sep:
        li      $v0, SYS_PRINT_CHAR
        syscall
        srl     $a0, $s0, 8
        andi    $a0, $a0, 0xff
        jal     sq_of_cell
        print_num($v0)
        lw      $s0, 0($sp)
        lw      $ra, 4($sp)
        addi    $sp, $sp, 8
        jr      $ra

# One line with the squares of all pieces that have a legal move.
list_movable:
        addi    $sp, $sp, -8
        sw      $ra, 4($sp)
        sw      $s0, 0($sp)
        print_str(msg_movable)
        li      $s0, 1
lm_square:
        move    $a0, $s0
        jal     cell_of_sq
        move    $a0, $v0
        li      $a1, 1
        jal     nth_move
        beqz    $v0, lm_next
        print_chr(' ')
        print_num($s0)
lm_next:
        addi    $s0, $s0, 1
        lw      $t0, num_squares
        ble     $s0, $t0, lm_square
        print_chr('\n')
        lw      $s0, 0($sp)
        lw      $ra, 4($sp)
        addi    $sp, $sp, 8
        jr      $ra

# Numbered list of the legal moves of the piece on cell a0.
# v0 = how many there are.
list_moves:
        addi    $sp, $sp, -16
        sw      $ra, 12($sp)
        sw      $s0, 8($sp)
        sw      $s1, 4($sp)
        sw      $s2, 0($sp)
        move    $s0, $a0

        print_str(msg_moves_for)
        move    $a0, $s0
        jal     sq_of_cell
        print_num($v0)
        print_str(str_colon)

        li      $s1, 1
ls_next:
        move    $a0, $s0
        move    $a1, $s1
        jal     nth_move
        beqz    $v0, ls_done
        move    $s2, $v0
        print_chr(' ')
        print_num($s1)
        print_str(str_item)
        move    $a0, $s2
        jal     print_move
        print_chr('\n')
        addi    $s1, $s1, 1
        j       ls_next
ls_done:
        addi    $v0, $s1, -1
        lw      $s2, 0($sp)
        lw      $s1, 4($sp)
        lw      $s0, 8($sp)
        lw      $ra, 12($sp)
        addi    $sp, $sp, 16
        jr      $ra

# v0 = the a1-th (counting from 1) legal move that starts on cell a0,
# or 0 if the piece does not have that many.
nth_move:
        la      $t0, legal_buf
        lw      $t1, legal_count
        li      $v0, 0
nm_loop:
        beqz    $t1, nm_done
        lw      $t2, 0($t0)
        andi    $t3, $t2, 0xff
        bne     $t3, $a0, nm_skip
        addi    $a1, $a1, -1
        beqz    $a1, nm_hit
nm_skip:
        addi    $t0, $t0, 4
        addi    $t1, $t1, -1
        j       nm_loop
nm_hit:
        move    $v0, $t2
nm_done:
        jr      $ra
