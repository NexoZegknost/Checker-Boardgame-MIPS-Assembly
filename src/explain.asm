# Telling the player why an input was refused.

.include "include/constants.inc"

.globl explain_start, explain_landing

.data
msg_not_valid:  .asciiz "Not a valid move! "
msg_try_again:  .asciiz " Try again.\n"

why_number:     .asciiz "Type the number of a square."
why_no_square:  .asciiz "There is no square "
why_range:      .asciiz ", squares go from 1 to "
why_square:     .asciiz "Square "
why_empty:      .asciiz " is empty."
why_piece_on:   .asciiz "The piece on square "
why_belongs:    .asciiz " belongs to "
why_stuck:      .asciiz " has no move available."
why_occupied:   .asciiz " is already occupied."
why_diagonal:   .asciiz " is not on a diagonal from square "
why_forward:    .asciiz "A man can only move forward."
why_keep_on:    .asciiz "You must keep capturing with the piece on square "
why_nothing:    .asciiz "There is no piece to jump over."
why_own:        .asciiz "You cannot jump over your own piece."
why_far:        .asciiz " is too far away."
why_must_a:     .asciiz "You have to capture this turn and the piece on square "
why_must_b:     .asciiz " cannot."
why_must:       .asciiz "You have to capture when you can."
why_ghost:      .asciiz "That piece has already been captured this turn."
why_blocked:    .asciiz "Your own piece is in the way."
why_two:        .asciiz "You cannot jump over more than one piece at a time."
why_longest:    .asciiz "You have to play the capture that takes the most pieces."
why_land:       .asciiz "You have to land on a square from which the piece can keep capturing."
why_not_now:    .asciiz "That move is not allowed here."
str_dot:        .asciiz "."

                .align 2
own_jumps:      .space 160

.text

# a0 = starting square as typed, a1 = its parse_line kind.
# v0 = the cell, or 0 after printing why a move cannot start there.
explain_start:
        addi    $sp, $sp, -12
        sw      $ra, 8($sp)
        sw      $s0, 4($sp)
        sw      $s1, 0($sp)
        move    $s0, $a0

        bne     $a1, P_NUM, es_number
        jal     cell_of_sq
        move    $s1, $v0
        beqz    $s1, es_range

        la      $t0, board
        add     $t0, $t0, $s1
        lbu     $t0, 0($t0)
        beqz    $t0, es_empty
        lw      $t1, turn
        and     $t0, $t0, $t1
        beqz    $t0, es_theirs

        la      $t0, legal_buf
        lw      $t1, legal_count
es_scan:
        beqz    $t1, es_stuck
        lw      $t2, 0($t0)
        andi    $t2, $t2, 0xff
        beq     $t2, $s1, es_fine
        addi    $t0, $t0, 4
        addi    $t1, $t1, -1
        j       es_scan
es_fine:
        move    $v0, $s1
        j       es_ret

es_number:
        print_str(msg_not_valid)
        print_str(why_number)
        j       es_fail
es_range:
        print_str(msg_not_valid)
        move    $a0, $s0
        jal     say_no_square
        j       es_fail
es_empty:
        print_str(msg_not_valid)
        print_str(why_square)
        print_num($s0)
        print_str(why_empty)
        j       es_fail
es_theirs:
        print_str(msg_not_valid)
        print_str(why_piece_on)
        print_num($s0)
        print_str(why_belongs)
        lw      $a0, turn
        xori    $a0, $a0, COLOR_MASK
        jal     print_side
        print_str(str_dot)
        j       es_fail
es_stuck:
        print_str(msg_not_valid)
        jal     capture_forced
        beqz    $v0, es_blocked
        # it may well be able to jump, just not in a way the rules accept
        move    $a0, $s1
        la      $a1, own_jumps
        jal     gen_captures
        beqz    $v0, es_cannot
        la      $a0, why_longest
        lw      $t0, rule_flags
        andi    $t0, $t0, RULE_LONGEST
        bnez    $t0, es_other
        la      $a0, why_land
es_other:
        li      $v0, SYS_PRINT_STR
        syscall
        j       es_fail
es_cannot:
        print_str(why_must_a)
        print_num($s0)
        print_str(why_must_b)
        j       es_fail
es_blocked:
        print_str(why_piece_on)
        print_num($s0)
        print_str(why_stuck)
es_fail:
        print_str(msg_try_again)
        li      $v0, 0
es_ret:
        lw      $s1, 0($sp)
        lw      $s0, 4($sp)
        lw      $ra, 8($sp)
        addi    $sp, $sp, 12
        jr      $ra

# a0 = from cell, a1 = landing square as typed, a2 = its parse kind.
# The move is not legal; prints what is wrong with it.
explain_landing:
        addi    $sp, $sp, -24
        sw      $ra, 20($sp)
        sw      $s0, 16($sp)
        sw      $s1, 12($sp)
        sw      $s2, 8($sp)
        sw      $s3, 4($sp)
        sw      $s4, 0($sp)
        move    $s0, $a0                # from cell
        move    $s1, $a1                # typed number

        print_str(msg_not_valid)
        bne     $a2, P_NUM, el_number
        move    $a0, $s1
        jal     cell_of_sq
        move    $s2, $v0                # landing cell
        beqz    $s2, el_range

        la      $t0, board
        add     $t0, $t0, $s2
        lbu     $t0, 0($t0)
        bnez    $t0, el_occupied

        # row and column distance between the two cells
        lw      $t0, board_w
        div     $s0, $t0
        mflo    $t1
        mfhi    $t2
        div     $s2, $t0
        mflo    $t3
        mfhi    $t4
        sub     $s3, $t3, $t1           # rows, negative = towards Red's side
        sub     $t5, $t4, $t2
        abs     $s4, $s3
        abs     $t5, $t5
        bne     $s4, $t5, el_diagonal

        la      $t0, board
        add     $t0, $t0, $s0
        lbu     $t6, 0($t0)             # the piece that should move
        lw      $t7, rule_flags
        andi    $t0, $t6, KING
        beqz    $t0, el_man
        andi    $t0, $t7, RULE_FLYING
        bnez    $t0, el_flying
        j       el_distance
el_man:
        # a black man goes up the board (rows decrease), a red one down
        andi    $t0, $t6, BLACK
        slt     $t1, $s3, $zero
        xor     $t0, $t0, $t1
        beqz    $t0, el_distance
        # going backwards is only fine where the rules allow it
        li      $t0, RULE_MOVE_BACK
        beq     $s4, 1, el_back_rule
        li      $t0, RULE_JUMP_BACK
        bne     $s4, 2, el_forward
el_back_rule:
        and     $t0, $t0, $t7
        beqz    $t0, el_forward

el_distance:
        beq     $s4, 1, el_step
        bgt     $s4, 2, el_far

        # two rows away: look at the square in between
        add     $t0, $s0, $s2
        srl     $t0, $t0, 1
        la      $t1, board
        add     $t1, $t1, $t0
        lbu     $t1, 0($t1)
        beqz    $t1, el_nothing
        andi    $t2, $t1, GHOST
        bnez    $t2, el_ghost
        lw      $t2, turn
        and     $t1, $t1, $t2
        bnez    $t1, el_own
        j       el_other_jump

el_flying:
        # walk from the king to the landing square and see what is in between
        sub     $t0, $s2, $s0
        div     $t0, $s4
        mflo    $t0                     # one diagonal step
        add     $t1, $s0, $t0
        li      $t3, 0                  # enemy pieces on the way
el_walk:
        beq     $t1, $s2, el_walked
        la      $t4, board
        add     $t4, $t4, $t1
        lbu     $t4, 0($t4)
        beqz    $t4, el_walk_next
        andi    $t5, $t4, GHOST
        bnez    $t5, el_ghost
        lw      $t5, turn
        and     $t5, $t4, $t5
        bnez    $t5, el_blocked
        addi    $t3, $t3, 1
el_walk_next:
        add     $t1, $t1, $t0
        j       el_walk
el_walked:
        beqz    $t3, el_step
        bgt     $t3, 1, el_two
        # a real jump, so one of the capture rules must be against it

el_other_jump:
        lw      $t0, rule_flags
        andi    $t1, $t0, RULE_LONGEST
        bnez    $t1, el_longest
        andi    $t1, $t0, RULE_FLYING
        beqz    $t1, el_not_now
        print_str(why_land)
        j       el_done
el_longest:
        print_str(why_longest)
        j       el_done
el_ghost:
        print_str(why_ghost)
        j       el_done
el_blocked:
        print_str(why_blocked)
        j       el_done
el_two:
        print_str(why_two)
        j       el_done

el_step:
        lw      $t0, chain_piece
        bnez    $t0, el_keep_on
        jal     capture_forced
        beqz    $v0, el_not_now
        print_str(why_must)
        j       el_done
el_keep_on:
        print_str(why_keep_on)
        move    $a0, $s0
        jal     sq_of_cell
        print_num($v0)
        print_str(str_dot)
        j       el_done

el_number:
        print_str(why_number)
        j       el_done
el_range:
        move    $a0, $s1
        jal     say_no_square
        j       el_done
el_occupied:
        print_str(why_square)
        print_num($s1)
        print_str(why_occupied)
        j       el_done
el_diagonal:
        print_str(why_square)
        print_num($s1)
        print_str(why_diagonal)
        move    $a0, $s0
        jal     sq_of_cell
        print_num($v0)
        print_str(str_dot)
        j       el_done
el_forward:
        print_str(why_forward)
        j       el_done
el_far:
        print_str(why_square)
        print_num($s1)
        print_str(why_far)
        j       el_done
el_nothing:
        print_str(why_nothing)
        j       el_done
el_own:
        print_str(why_own)
        j       el_done
el_not_now:
        print_str(why_not_now)
el_done:
        print_str(msg_try_again)
        lw      $s4, 0($sp)
        lw      $s3, 4($sp)
        lw      $s2, 8($sp)
        lw      $s1, 12($sp)
        lw      $s0, 16($sp)
        lw      $ra, 20($sp)
        addi    $sp, $sp, 24
        jr      $ra

# "There is no square 40, squares go from 1 to 32."
say_no_square:
        move    $t0, $a0
        print_str(why_no_square)
        print_num($t0)
        print_str(why_range)
        lw      $a0, num_squares
        li      $v0, SYS_PRINT_INT
        syscall
        print_str(str_dot)
        jr      $ra

# v0 = 1 if only jumps are legal right now (jumps come first in legal_buf)
capture_forced:
        li      $v0, 0
        lw      $t0, rule_flags
        andi    $t0, $t0, RULE_MUST_CAPTURE
        beqz    $t0, cf_done
        lw      $t0, legal_count
        beqz    $t0, cf_done
        lw      $t0, legal_buf
        srl     $t0, $t0, 16
        sne     $v0, $t0, $zero
cf_done:
        jr      $ra
