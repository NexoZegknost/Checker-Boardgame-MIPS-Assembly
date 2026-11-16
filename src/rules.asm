# Carrying out moves on the board.

.include "include/constants.inc"

.globl apply_step, rule_flags

.data
                .align 2
rule_flags:     .word 0
scratch_moves:  .space 160

.text

# a0 = packed move (see movegen.asm).
# Plays one step: a plain move or a single jump. After a jump the same piece
# has to go on if it can, in that case the turn does not change and
# chain_piece says which piece is stuck jumping.
# v0 = STEP_* bits describing what happened.
apply_step:
        addi    $sp, $sp, -16
        sw      $ra, 12($sp)
        sw      $s0, 8($sp)
        sw      $s1, 4($sp)
        sw      $s2, 0($sp)

        andi    $t0, $a0, 0xff          # from
        srl     $s0, $a0, 8
        andi    $s0, $s0, 0xff          # to
        srl     $s1, $a0, 16
        andi    $s1, $s1, 0xff          # jumped cell or 0
        li      $s2, 0

        la      $t2, board
        add     $t3, $t2, $t0
        lbu     $t4, 0($t3)             # the moving piece
        sb      $zero, 0($t3)

        # the draw counter restarts on a capture or when a man moves
        andi    $t5, $t4, KING
        beqz    $t5, as_progress
        bnez    $s1, as_progress
        lw      $t5, quiet_plies
        addi    $t5, $t5, 1
        sw      $t5, quiet_plies
        j       as_moved
as_progress:
        sw      $zero, quiet_plies
as_moved:
        beqz    $s1, as_promote
        add     $t3, $t2, $s1
        sb      $zero, 0($t3)
        ori     $s2, $s2, STEP_CAPTURE
        la      $t5, count_red
        andi    $t6, $t4, BLACK
        bnez    $t6, as_count
        la      $t5, count_black
as_count:
        lw      $t6, 0($t5)
        addi    $t6, $t6, -1
        sw      $t6, 0($t5)

as_promote:
        andi    $t5, $t4, KING
        bnez    $t5, as_place
        # Black crowns on the top row, Red on the bottom one
        lw      $t5, board_w
        andi    $t6, $t4, BLACK
        beqz    $t6, as_red_row
        sll     $t5, $t5, 1
        bge     $s0, $t5, as_place
        j       as_crown
as_red_row:
        lw      $t6, board_n
        mul     $t5, $t5, $t6
        ble     $s0, $t5, as_place
as_crown:
        ori     $t4, $t4, KING
        ori     $s2, $s2, STEP_PROMOTED
as_place:
        add     $t3, $t2, $s0
        sb      $t4, 0($t3)

        # a fresh king keeps jumping too, so this comes after the crowning
        beqz    $s1, as_end_turn
        move    $a0, $s0
        la      $a1, scratch_moves
        jal     gen_captures
        beqz    $v0, as_end_turn
        sw      $s0, chain_piece
        ori     $s2, $s2, STEP_CHAIN
        j       as_ret

as_end_turn:
        sw      $zero, chain_piece
        lw      $t0, turn
        xori    $t0, $t0, COLOR_MASK
        sw      $t0, turn
as_ret:
        move    $v0, $s2
        lw      $s2, 0($sp)
        lw      $s1, 4($sp)
        lw      $s0, 8($sp)
        lw      $ra, 12($sp)
        addi    $sp, $sp, 16
        jr      $ra
