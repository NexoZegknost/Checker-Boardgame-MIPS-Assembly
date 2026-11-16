# Move log and take-back.
#
# The log keeps one word per step with the standard square numbers:
#   from | to << 8 | capture << 16 | colour << 24
# Take-back works on whole positions: the game stores one at the start of
# every turn and undo simply reloads an older one. log_len is part of the
# position, so the log shrinks back by itself.

.include "include/constants.inc"

.globl log_add, log_print
.globl undo_reset, undo_mark, undo_back

.eqv LOG_MAX   1024
.eqv UNDO_MAX  200

.data
msg_log_head:   .asciiz "Moves so far:\n"
msg_log_empty:  .asciiz "No moves have been played yet.\n"
str_dot:        .asciiz ". "
str_pad:        .asciiz "  "

                .align 2
undo_count:     .word 0
log_buf:        .space 4096             # LOG_MAX words
undo_stack:     .space 34400            # UNDO_MAX * STATE_BYTES

.text

# a0 = packed move that was just played, a1 = colour that played it
log_add:
        lw      $t0, log_len
        bge     $t0, LOG_MAX, la_done   # very long game, stop recording
        la      $t1, idx_to_sq
        andi    $t2, $a0, 0xff
        add     $t2, $t1, $t2
        lbu     $t2, 0($t2)
        srl     $t3, $a0, 8
        andi    $t3, $t3, 0xff
        add     $t3, $t1, $t3
        lbu     $t3, 0($t3)
        sll     $t3, $t3, 8
        or      $t2, $t2, $t3
        srl     $t3, $a0, 16
        sne     $t3, $t3, $zero
        sll     $t3, $t3, 16
        or      $t2, $t2, $t3
        sll     $t3, $a1, 24
        or      $t2, $t2, $t3

        la      $t1, log_buf
        sll     $t3, $t0, 2
        add     $t1, $t1, $t3
        sw      $t2, 0($t1)
        addi    $t0, $t0, 1
        sw      $t0, log_len
la_done:
        jr      $ra

# Prints the game so far, one turn per line. The jumps of a chain share a line:
#   7. Black 24x15 15x6
log_print:
        addi    $sp, $sp, -20
        sw      $ra, 16($sp)
        sw      $s0, 12($sp)
        sw      $s1, 8($sp)
        sw      $s2, 4($sp)
        sw      $s3, 0($sp)

        lw      $s1, log_len
        bnez    $s1, lp_start
        print_str(msg_log_empty)
        j       lp_ret
lp_start:
        print_str(msg_log_head)
        la      $s0, log_buf
        li      $s2, 0                  # colour of the previous entry
        li      $s3, 0                  # turn counter
lp_entry:
        lw      $t0, 0($s0)
        srl     $t1, $t0, 24
        beq     $t1, $s2, lp_same_turn
        move    $s2, $t1
        beqz    $s3, lp_number
        print_chr('\n')
lp_number:
        addi    $s3, $s3, 1
        bge     $s3, 100, lp_num_out
        print_chr(' ')
        bge     $s3, 10, lp_num_out
        print_chr(' ')
lp_num_out:
        print_num($s3)
        print_str(str_dot)
        move    $a0, $s2
        jal     print_side
        bne     $s2, RED, lp_same_turn
        print_str(str_pad)              # line Red up with Black
lp_same_turn:
        print_chr(' ')
        lw      $t0, 0($s0)
        andi    $a0, $t0, 0xff
        li      $v0, SYS_PRINT_INT
        syscall
        lw      $t0, 0($s0)
        srl     $t1, $t0, 16
        andi    $t1, $t1, 0xff
        li      $a0, '-'
        beqz    $t1, lp_sep
        li      $a0, 'x'
lp_sep:
        li      $v0, SYS_PRINT_CHAR
        syscall
        lw      $t0, 0($s0)
        srl     $a0, $t0, 8
        andi    $a0, $a0, 0xff
        li      $v0, SYS_PRINT_INT
        syscall

        addi    $s0, $s0, 4
        addi    $s1, $s1, -1
        bgtz    $s1, lp_entry
        print_chr('\n')
lp_ret:
        lw      $s3, 0($sp)
        lw      $s2, 4($sp)
        lw      $s1, 8($sp)
        lw      $s0, 12($sp)
        lw      $ra, 16($sp)
        addi    $sp, $sp, 20
        jr      $ra

undo_reset:
        sw      $zero, undo_count
        jr      $ra

# Remembers the current position as the start of a turn.
undo_mark:
        push    ($ra)
        lw      $t0, undo_count
        blt     $t0, UNDO_MAX, um_store

        # full: drop the oldest position by sliding everything down one slot
        la      $t1, undo_stack
        addi    $t2, $t1, STATE_BYTES
        li      $t3, UNDO_MAX
        addi    $t3, $t3, -1
        mul     $t3, $t3, STATE_WORDS
um_slide:
        lw      $t4, 0($t2)
        sw      $t4, 0($t1)
        addi    $t1, $t1, 4
        addi    $t2, $t2, 4
        addi    $t3, $t3, -1
        bgtz    $t3, um_slide
        li      $t0, UNDO_MAX
        addi    $t0, $t0, -1
um_store:
        addi    $t1, $t0, 1
        sw      $t1, undo_count
        mul     $t0, $t0, STATE_BYTES
        la      $a0, undo_stack
        add     $a0, $a0, $t0
        jal     state_save
        pop     ($ra)
        jr      $ra

# Goes back a0 marks; the newest mark is the start of the current turn, so
# 1 cancels a half-played chain and 2 gives the previous player the move again.
# The reloaded mark is taken off the stack too because the turn loop marks it again.
# v0 = 0 if there are not that many positions stored.
undo_back:
        push    ($ra)
        li      $v0, 0
        lw      $t0, undo_count
        blt     $t0, $a0, ub_done
        sub     $t0, $t0, $a0
        sw      $t0, undo_count
        mul     $t0, $t0, STATE_BYTES
        la      $a0, undo_stack
        add     $a0, $a0, $t0
        jal     state_load
        li      $v0, 1
ub_done:
        pop     ($ra)
        jr      $ra
