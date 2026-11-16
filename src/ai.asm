# Computer opponent.
#
# Easy picks any legal step at random. Medium and hard look ahead with a
# plain negamax search and alpha-beta cut-offs; the only difference between
# them is the depth. Moves are tried on the real board and taken back with
# snap_push / snap_pop, so the search understands every rule set for free.

.include "include/constants.inc"

.globl ai_choose, ai_accepts_draw

.eqv SYS_RANDOM_BELOW 42
.eqv INFINITY     32000
.eqv LOST         30000         # score of a position where the mover has no move
.eqv MAN_VALUE    100
.eqv KING_VALUE   180
.eqv FLYER_VALUE  300           # a king that flies is worth a lot more
.eqv ROW_BONUS    3             # per row a man has advanced

.data
ai_best:        .word 0         # best move found by the last finished search call

.text

# Picks a step for the side to move. legal_buf must be up to date.
# v0 = the packed move.
ai_choose:
        push    ($ra)
        lw      $t0, opt_opponent
        bne     $t0, 1, ac_think

        lw      $a1, legal_count
        li      $a0, 0
        li      $v0, SYS_RANDOM_BELOW
        syscall
        sll     $a0, $a0, 2
        lw      $v0, legal_buf($a0)
        j       ac_done
ac_think:
        li      $a0, 2
        beq     $t0, 2, ac_search
        li      $a0, 4
ac_search:
        li      $a1, -INFINITY
        li      $a2, INFINITY
        jal     search
        lw      $v0, ai_best
ac_done:
        pop     ($ra)
        jr      $ra

# The human (always Black) has offered a draw.
# v0 = 1 if the computer takes it, which it does when it stands worse.
ai_accepts_draw:
        push    ($ra)
        jal     evaluate                # from the point of view of the side to move
        lw      $t0, turn
        beq     $t0, BLACK, ad_black
        neg     $v0, $v0
ad_black:
        sgt     $v0, $v0, $zero
        pop     ($ra)
        jr      $ra

# Negamax. a0 = turns left to look ahead, a1 = alpha, a2 = beta.
# v0 = value of the position for the side to move; the move that gets it is
# left in ai_best. A chain of jumps counts as one turn: while the same side
# keeps moving the depth and the window stay as they are.
search:
        addi    $sp, $sp, -40
        sw      $ra, 36($sp)
        sw      $fp, 32($sp)
        sw      $s0, 28($sp)
        sw      $s1, 24($sp)
        sw      $s2, 20($sp)
        sw      $s3, 16($sp)
        sw      $s4, 12($sp)
        sw      $s5, 8($sp)
        sw      $s6, 4($sp)
        sw      $s7, 0($sp)
        move    $fp, $sp
        move    $s0, $a0
        move    $s1, $a1
        move    $s2, $a2

        jal     gen_legal
        move    $s3, $v0
        bnez    $s3, se_alive
        # no move at all: lost, and losing later is a little less bad
        li      $v0, -LOST
        sub     $v0, $v0, $s0
        j       se_ret
se_alive:
        bgtz    $s0, se_expand
        jal     evaluate
        j       se_ret

se_expand:
        # the move list is global, keep our own copy on the stack
        sll     $t0, $s3, 2
        sub     $sp, $sp, $t0
        move    $s4, $sp
        la      $t1, legal_buf
        move    $t2, $s4
        move    $t3, $s3
se_copy:
        lw      $t4, 0($t1)
        sw      $t4, 0($t2)
        addi    $t1, $t1, 4
        addi    $t2, $t2, 4
        addi    $t3, $t3, -1
        bgtz    $t3, se_copy

        li      $s5, -INFINITY          # best value so far
        lw      $s6, 0($s4)             # and the move that gives it
        lw      $s7, turn
se_loop:
        jal     snap_push
        lw      $a0, 0($s4)
        jal     apply_step
        lw      $t0, turn
        bne     $t0, $s7, se_reply
        move    $a0, $s0
        move    $a1, $s1
        move    $a2, $s2
        jal     search
        j       se_scored
se_reply:
        addi    $a0, $s0, -1
        neg     $a1, $s2
        neg     $a2, $s1
        jal     search
        neg     $v0, $v0
se_scored:
        jal     snap_pop                # leaves v0 alone

        ble     $v0, $s5, se_next
        move    $s5, $v0
        lw      $s6, 0($s4)
        ble     $v0, $s1, se_next
        move    $s1, $v0
        bge     $s1, $s2, se_best       # the opponent will not allow this line
se_next:
        addi    $s4, $s4, 4
        addi    $s3, $s3, -1
        bgtz    $s3, se_loop
se_best:
        sw      $s6, ai_best
        move    $v0, $s5
se_ret:
        move    $sp, $fp
        lw      $s7, 0($sp)
        lw      $s6, 4($sp)
        lw      $s5, 8($sp)
        lw      $s4, 12($sp)
        lw      $s3, 16($sp)
        lw      $s2, 20($sp)
        lw      $s1, 24($sp)
        lw      $s0, 28($sp)
        lw      $fp, 32($sp)
        lw      $ra, 36($sp)
        addi    $sp, $sp, 40
        jr      $ra

# v0 = material balance seen from the side to move. Men count a bit more
# the closer they are to being crowned.
evaluate:
        lw      $t9, turn
        li      $t8, KING_VALUE
        lw      $t0, rule_flags
        andi    $t0, $t0, RULE_FLYING
        beqz    $t0, ev_start
        li      $t8, FLYER_VALUE
ev_start:
        li      $v0, 0
        lw      $t0, num_squares
        lw      $t7, board_w
        lw      $t6, board_n
ev_loop:
        la      $t1, sq_to_idx
        add     $t1, $t1, $t0
        lbu     $t1, 0($t1)             # cell
        la      $t2, board
        add     $t2, $t2, $t1
        lbu     $t2, 0($t2)             # piece
        beqz    $t2, ev_next
        andi    $t3, $t2, GHOST
        bnez    $t3, ev_next

        move    $t4, $t8
        andi    $t3, $t2, KING
        bnez    $t3, ev_add
        # rows walked so far: Black starts at the bottom, Red at the top
        div     $t1, $t7
        mflo    $t3
        addi    $t3, $t3, -1
        andi    $t5, $t2, BLACK
        beqz    $t5, ev_rows
        sub     $t3, $t6, $t3
        addi    $t3, $t3, -1
ev_rows:
        mul     $t3, $t3, ROW_BONUS
        addi    $t4, $t3, MAN_VALUE
ev_add:
        and     $t3, $t2, $t9
        bnez    $t3, ev_mine
        neg     $t4, $t4
ev_mine:
        add     $v0, $v0, $t4
ev_next:
        addi    $t0, $t0, -1
        bgtz    $t0, ev_loop
        jr      $ra
