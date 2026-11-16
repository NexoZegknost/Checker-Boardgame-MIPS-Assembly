# The game loop: whose turn it is, asking for moves, checking them.

.include "include/constants.inc"

.globl game_run

.data
msg_turn:       .asciiz "'s turn.\n"
msg_ask_start:  .asciiz "Enter starting square: "
msg_ask_land:   .asciiz "Enter landing square: "
msg_invalid:    .asciiz "Not a valid move! Try again.\n"
msg_bye:        .asciiz "Game stopped.\n"
msg_captured:   .asciiz "Captured "
msg_s_piece:    .asciiz "'s piece.\n"
msg_chain:      .asciiz "Chaining possible.\n"
msg_no_pieces:  .asciiz " has no pieces left.\n"
msg_no_moves:   .asciiz " has no legal moves.\n"
msg_wins:       .asciiz " wins!\n"

.text

game_run:
        addi    $sp, $sp, -20
        sw      $ra, 16($sp)
        sw      $s0, 12($sp)
        sw      $s1, 8($sp)
        sw      $s2, 4($sp)
        sw      $s3, 0($sp)

        jal     board_reset
g_turn:
        jal     display_board
        jal     gen_legal
        bnez    $v0, g_announce

        # nothing to play: either everything was captured or the rest is stuck
        lw      $s0, turn
        move    $a0, $s0
        jal     print_side
        lw      $t0, count_black
        beq     $s0, BLACK, g_lost_why
        lw      $t0, count_red
g_lost_why:
        la      $a0, msg_no_pieces
        beqz    $t0, g_lost_say
        la      $a0, msg_no_moves
g_lost_say:
        li      $v0, SYS_PRINT_STR
        syscall
        xori    $a0, $s0, COLOR_MASK
        jal     print_side
        print_str(msg_wins)
        j       g_leave

g_announce:
        lw      $a0, turn
        jal     print_side
        print_str(msg_turn)

g_ask:
        # both squares are read before anything is checked, like in the handout
        la      $a0, msg_ask_start
        jal     ask
        beq     $v0, P_CMD, g_command
        move    $s2, $v1
        la      $a0, msg_ask_land
        jal     ask
        beq     $v0, P_CMD, g_command
        move    $s3, $v1

        move    $a0, $s2
        jal     cell_of_sq
        move    $s2, $v0
        move    $a0, $s3
        jal     cell_of_sq
        move    $a0, $s2
        move    $a1, $v0
        jal     find_move
        beqz    $v0, g_invalid

g_play:
        lw      $s0, turn               # remember who moved for the message
        move    $a0, $v0
        jal     apply_step
        move    $s1, $v0
        andi    $t0, $s1, STEP_CAPTURE
        beqz    $t0, g_played
        print_str(msg_captured)
        xori    $a0, $s0, COLOR_MASK
        jal     print_side
        print_str(msg_s_piece)
g_played:
        andi    $t0, $s1, STEP_CHAIN
        beqz    $t0, g_turn

        # the piece has to keep jumping, only the landing square is asked
        jal     display_board
        print_str(msg_chain)
        jal     gen_legal
g_chain_ask:
        la      $a0, msg_ask_land
        jal     ask
        beq     $v0, P_CMD, g_command
        move    $a0, $v1
        jal     cell_of_sq
        lw      $a0, chain_piece
        move    $a1, $v0
        jal     find_move
        bnez    $v0, g_play
        print_str(msg_invalid)
        j       g_chain_ask

g_invalid:
        print_str(msg_invalid)
        j       g_ask

g_command:
        ori     $v1, $v1, 0x20
        beq     $v1, 'q', g_quit
        print_str(msg_invalid)
g_reprompt:
        lw      $t0, chain_piece
        bnez    $t0, g_chain_ask
        j       g_ask
g_quit:
        print_str(msg_bye)
g_leave:
        lw      $s3, 0($sp)
        lw      $s2, 4($sp)
        lw      $s1, 8($sp)
        lw      $s0, 12($sp)
        lw      $ra, 16($sp)
        addi    $sp, $sp, 20
        jr      $ra

# Prints the prompt in a0, reads a line and returns what parse_line says.
# Bad input comes back as square 0, which is never valid.
ask:
        push    ($ra)
        li      $v0, SYS_PRINT_STR
        syscall
        jal     read_line
        jal     parse_line
        pop     ($ra)
        jr      $ra

# Looks in legal_buf for the move from cell a0 to cell a1.
# v0 = the packed move, or 0 if it is not legal.
find_move:
        la      $t0, legal_buf
        lw      $t1, legal_count
        sll     $t2, $a1, 8
        or      $t2, $t2, $a0
        li      $v0, 0
fm_loop:
        beqz    $t1, fm_done
        lw      $t3, 0($t0)
        andi    $t4, $t3, 0xffff
        beq     $t4, $t2, fm_hit
        addi    $t0, $t0, 4
        addi    $t1, $t1, -1
        j       fm_loop
fm_hit:
        move    $v0, $t3
fm_done:
        jr      $ra
