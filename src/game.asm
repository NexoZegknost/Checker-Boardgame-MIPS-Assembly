# The game loop: whose turn it is, asking for moves, checking them.
# While a move is being asked the player can also type a command, see msg_help.

.include "include/constants.inc"

.globl game_run

.data
msg_turn:       .asciiz "'s turn.\n"
msg_ask_start:  .asciiz "Enter starting square: "
msg_ask_land:   .asciiz "Enter landing square: "
msg_unknown:    .asciiz "Unknown command.\n"
msg_bye:        .asciiz "Game stopped.\n"
msg_restart:    .asciiz "Starting over.\n"
msg_captured:   .asciiz "Captured "
msg_s_piece:    .asciiz "'s piece.\n"
msg_computer:   .asciiz "The computer plays "
str_end:        .asciiz ".\n"
msg_declined:   .asciiz "The computer wants to play on.\n"
msg_accepted:   .asciiz "The computer accepts the draw.\n"
msg_crowned:    .asciiz "'s man becomes a king.\n"
msg_chain:      .asciiz "Chaining possible.\n"
msg_no_pieces:  .asciiz " has no pieces left.\n"
msg_no_moves:   .asciiz " has no legal moves.\n"
msg_wins:       .asciiz " wins!\n"
msg_help:       .ascii  "Instead of a square you can type:\n"
                .ascii  "  h  show this help\n"
                .ascii  "  l  list the moves played so far\n"
                .ascii  "  u  take back the last move\n"
                .ascii  "  d  offer a draw, or accept the one on the table\n"
                .ascii  "  r  start the game over\n"
                .asciiz "  q  leave the game and go back to the menu\n"
msg_undone:     .asciiz "Took back the last move.\n"
msg_no_undo:    .asciiz "There is nothing to take back.\n"
msg_offers:     .asciiz " offers a draw. "
msg_can_accept: .asciiz " can accept by typing d.\n"
msg_agreed:     .asciiz "Both players agreed to a draw.\n"
msg_quiet_draw: .asciiz "40 moves each without a capture or a man moving: the game is a draw.\n"
msg_after:      .asciiz "Type l to see the moves of this game, or press Enter to continue: "

                .align 2
start_state:    .space STATE_BYTES

msg_pick:       .asciiz "Choose a piece: "
msg_other:      .asciiz " 0) choose another piece\n"
msg_choice:     .asciiz "Your choice: "
msg_bad_pick:   .asciiz "Please pick a number from the list.\n"

.text

game_run:
        addi    $sp, $sp, -24
        sw      $ra, 20($sp)
        sw      $s0, 16($sp)
        sw      $s1, 12($sp)
        sw      $s2, 8($sp)
        sw      $s3, 4($sp)
        sw      $s4, 0($sp)

        # the caller has set up the board; keep a copy for "start over"
        la      $a0, start_state
        jal     state_save
g_new:
        la      $a0, start_state
        jal     state_load
        jal     undo_reset
g_turn:
        jal     undo_mark
        jal     set_perspective
        jal     display_board
        jal     gen_legal
        bnez    $v0, g_check_draw

        # no legal move: the side to move has lost
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
        j       g_over

g_check_draw:
        lw      $t0, quiet_plies
        blt     $t0, DRAW_PLIES, g_announce
        print_str(msg_quiet_draw)
        j       g_over

g_announce:
        lw      $a0, turn
        jal     print_side
        print_str(msg_turn)

        # remind the player of a draw offer made by the other side
        lw      $t0, opt_opponent
        bnez    $t0, g_input
        lw      $t0, draw_offer
        lw      $t1, turn
        xori    $t2, $t1, COLOR_MASK
        and     $t0, $t0, $t2
        beqz    $t0, g_input
        move    $a0, $t2
        jal     print_side
        print_str(msg_offers)
        lw      $a0, turn
        jal     print_side
        print_str(msg_can_accept)

g_input:
        lw      $t0, opt_opponent
        beqz    $t0, g_human
        lw      $t0, turn
        bne     $t0, RED, g_human
        jal     ai_choose
        move    $s2, $v0
        print_str(msg_computer)
        move    $a0, $s2
        jal     print_move
        print_str(str_end)
        move    $v0, $s2
        j       g_play

g_human:
        # depends on the entry mode and on whether a chain is open
        lw      $t0, chain_piece
        lw      $t1, opt_input
        bnez    $t1, g_input_list
        bnez    $t0, g_chain_ask
        j       g_ask
g_input_list:
        move    $s2, $t0
        bnez    $t0, g_list
        j       g_pick

g_ask:
        la      $a0, msg_ask_start
        jal     prompt_line
        beq     $v0, P_CMD, g_command
        move    $a0, $v1
        move    $a1, $v0
        jal     explain_start
        beqz    $v0, g_ask
        move    $s2, $v0

        la      $a0, msg_ask_land
        jal     prompt_line
        beq     $v0, P_CMD, g_command
        move    $s3, $v1
        move    $s4, $v0
        move    $a0, $s3
        jal     cell_of_sq
        move    $a0, $s2
        move    $a1, $v0
        jal     find_move
        bnez    $v0, g_play
        move    $a0, $s2
        move    $a1, $s3
        move    $a2, $s4
        jal     explain_landing
        j       g_ask

g_play:
        lw      $s0, turn               # who is moving, apply_step may pass the turn
        move    $s2, $v0
        move    $a0, $s2
        jal     apply_step
        move    $s1, $v0
        move    $a0, $s2
        move    $a1, $s0
        jal     log_add
        andi    $t0, $s1, STEP_CAPTURE
        beqz    $t0, g_played
        print_str(msg_captured)
        xori    $a0, $s0, COLOR_MASK
        jal     print_side
        print_str(msg_s_piece)
g_played:
        andi    $t0, $s1, STEP_PROMOTED
        beqz    $t0, g_next
        move    $a0, $s0
        jal     print_side
        print_str(msg_crowned)
g_next:
        andi    $t0, $s1, STEP_CHAIN
        bnez    $t0, g_chain
        # turn over: only the mover's own draw offer stays on the table
        lw      $t0, draw_offer
        and     $t0, $t0, $s0
        sw      $t0, draw_offer
        j       g_turn
g_chain:

        # the piece has to keep jumping, only the landing square is asked
        jal     display_board
        print_str(msg_chain)
        jal     gen_legal
        j       g_input

g_chain_ask:
        la      $a0, msg_ask_land
        jal     prompt_line
        beq     $v0, P_CMD, g_command
        move    $s3, $v1
        move    $s4, $v0
        move    $a0, $s3
        jal     cell_of_sq
        lw      $a0, chain_piece
        move    $a1, $v0
        jal     find_move
        bnez    $v0, g_play
        lw      $a0, chain_piece
        move    $a1, $s3
        move    $a2, $s4
        jal     explain_landing
        j       g_chain_ask

g_command:
        ori     $v1, $v1, 0x20
        beq     $v1, 'q', g_quit
        beq     $v1, 'r', g_restart
        beq     $v1, 'h', g_help
        beq     $v1, 'l', g_log
        beq     $v1, 'u', g_undo
        beq     $v1, 'd', g_draw
        print_str(msg_unknown)
        j       g_input
g_help:
        print_str(msg_help)
        j       g_input
g_log:
        jal     log_print
        j       g_input
g_undo:
        # 1 = just the open chain, 2 = last move, 3 = also the computer's reply
        li      $a0, 1
        lw      $t0, chain_piece
        bnez    $t0, g_undo_go
        li      $a0, 2
        lw      $t0, opt_opponent
        beqz    $t0, g_undo_go
        li      $a0, 3
g_undo_go:
        jal     undo_back
        bnez    $v0, g_undo_ok
        print_str(msg_no_undo)
        j       g_input
g_undo_ok:
        print_str(msg_undone)
        j       g_turn
g_draw:
        lw      $t0, opt_opponent
        beqz    $t0, g_draw_human
        jal     ai_accepts_draw
        bnez    $v0, g_draw_taken
        print_str(msg_declined)
        j       g_input
g_draw_taken:
        print_str(msg_accepted)
        j       g_over
g_draw_human:
        lw      $s0, turn
        lw      $t0, draw_offer
        xori    $t1, $s0, COLOR_MASK
        and     $t1, $t0, $t1
        bnez    $t1, g_draw_agreed
        or      $t0, $t0, $s0
        sw      $t0, draw_offer
        move    $a0, $s0
        jal     print_side
        print_str(msg_offers)
        xori    $a0, $s0, COLOR_MASK
        jal     print_side
        print_str(msg_can_accept)
        j       g_input
g_draw_agreed:
        print_str(msg_agreed)
        j       g_over
g_restart:
        print_str(msg_restart)
        j       g_new
g_quit:
        print_str(msg_bye)
        j       g_leave

g_over:
        la      $a0, msg_after
        jal     prompt_line
        bne     $v0, P_CMD, g_leave
        ori     $v1, $v1, 0x20
        bne     $v1, 'l', g_leave
        jal     log_print
g_leave:
        lw      $s4, 0($sp)
        lw      $s3, 4($sp)
        lw      $s2, 8($sp)
        lw      $s1, 12($sp)
        lw      $s0, 16($sp)
        lw      $ra, 20($sp)
        addi    $sp, $sp, 24
        jr      $ra

# list entry: first the piece, then one of its moves by number
g_pick:
        jal     list_movable
        la      $a0, msg_pick
        jal     prompt_line
        beq     $v0, P_CMD, g_command
        move    $a0, $v1
        move    $a1, $v0
        jal     explain_start
        beqz    $v0, g_pick
        move    $s2, $v0
g_list:
        move    $a0, $s2
        jal     list_moves
        move    $s3, $v0
        lw      $t0, chain_piece
        bnez    $t0, g_list_ask         # no way back while a chain is open
        print_str(msg_other)
g_list_ask:
        la      $a0, msg_choice
        jal     prompt_line
        beq     $v0, P_CMD, g_command
        bne     $v0, P_NUM, g_list_bad
        bgt     $v1, $s3, g_list_bad
        bnez    $v1, g_list_take
        lw      $t0, chain_piece
        beqz    $t0, g_pick
g_list_bad:
        print_str(msg_bad_pick)
        j       g_list
g_list_take:
        move    $a0, $s2
        move    $a1, $v1
        jal     nth_move
        j       g_play

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
