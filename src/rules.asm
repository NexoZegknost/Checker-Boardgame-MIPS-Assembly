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
        addi    $sp, $sp, -20
        sw      $ra, 16($sp)
        sw      $s0, 12($sp)
        sw      $s1, 8($sp)
        sw      $s2, 4($sp)
        sw      $s3, 0($sp)

        andi    $t0, $a0, 0xff          # from
        srl     $s0, $a0, 8
        andi    $s0, $s0, 0xff          # to
        srl     $s1, $a0, 16
        andi    $s1, $s1, 0xff          # jumped cell or 0
        li      $s2, 0
        lw      $s3, rule_flags

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
        # the jumped piece goes at once, or stays as a ghost until the turn ends
        add     $t3, $t2, $s1
        li      $t5, 0
        andi    $t6, $s3, RULE_REMOVE_LATE
        beqz    $t6, as_take
        lbu     $t5, 0($t3)
        ori     $t5, $t5, GHOST
as_take:
        sb      $t5, 0($t3)
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
        # in the middle of a capture some rule sets wait with the crown
        beqz    $s1, as_try_crown
        andi    $t5, $s3, RULE_CROWN_LATE
        bnez    $t5, as_place
as_try_crown:
        move    $a0, $s0
        move    $a1, $t4
        jal     reaches_crown_row
        beqz    $v0, as_place
        ori     $t4, $t4, KING
        ori     $s2, $s2, STEP_PROMOTED
as_place:
        la      $t2, board
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
        # a man whose capture stops on the last row is crowned now
        la      $t2, board
        add     $t3, $t2, $s0
        lbu     $t4, 0($t3)
        move    $a0, $s0
        move    $a1, $t4
        jal     reaches_crown_row
        beqz    $v0, as_ghosts
        ori     $t4, $t4, KING
        sb      $t4, 0($t3)
        ori     $s2, $s2, STEP_PROMOTED

as_ghosts:
        beqz    $s1, as_pass
        andi    $t5, $s3, RULE_REMOVE_LATE
        beqz    $t5, as_pass
        lw      $t0, num_squares
        la      $t1, sq_to_idx
as_sweep:
        add     $t5, $t1, $t0
        lbu     $t5, 0($t5)
        add     $t5, $t2, $t5
        lbu     $t6, 0($t5)
        andi    $t6, $t6, GHOST
        beqz    $t6, as_sweep_next
        sb      $zero, 0($t5)
as_sweep_next:
        addi    $t0, $t0, -1
        bgtz    $t0, as_sweep

as_pass:
        sw      $zero, chain_piece
        lw      $t0, turn
        xori    $t0, $t0, COLOR_MASK
        sw      $t0, turn
as_ret:
        move    $v0, $s2
        lw      $s3, 0($sp)
        lw      $s2, 4($sp)
        lw      $s1, 8($sp)
        lw      $s0, 12($sp)
        lw      $ra, 16($sp)
        addi    $sp, $sp, 20
        jr      $ra

# a0 = cell, a1 = piece. v0 = 1 if the piece is a man standing on the row
# where it gets crowned: the top row for Black, the bottom row for Red.
# Only touches $t5, $t6 and $v0.
reaches_crown_row:
        li      $v0, 0
        andi    $t5, $a1, KING
        bnez    $t5, rc_done
        lw      $t5, board_w
        andi    $t6, $a1, BLACK
        beqz    $t6, rc_red
        sll     $t5, $t5, 1
        slt     $v0, $a0, $t5
        jr      $ra
rc_red:
        lw      $t6, board_n
        mul     $t5, $t5, $t6
        sgt     $v0, $a0, $t5
rc_done:
        jr      $ra
