# The game loop: whose turn it is, asking for moves, checking them.

.include "include/constants.inc"

.globl game_run

.data
msg_black_turn: .asciiz "Black's turn.\n"
msg_red_turn:   .asciiz "Red's turn.\n"
msg_ask_start:  .asciiz "Enter starting square: "
msg_ask_land:   .asciiz "Enter landing square: "
msg_invalid:    .asciiz "Not a valid move! Try again.\n"
msg_bye:        .asciiz "Game stopped.\n"
msg_cap_black:  .asciiz "Captured Black's piece.\n"
msg_cap_red:    .asciiz "Captured Red's piece.\n"
msg_chain:      .asciiz "Chaining possible.\n"
msg_black_out:  .asciiz "Black has no pieces left.\nRed wins!\n"
msg_red_out:    .asciiz "Red has no pieces left.\nBlack wins!\n"

                .align 2
move_buf:       .space 64

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

        # the side to move loses if all of its pieces are gone
        lw      $t0, turn
        lw      $t1, count_black
        la      $a0, msg_black_out
        beq     $t0, BLACK, g_check_out
        lw      $t1, count_red
        la      $a0, msg_red_out
g_check_out:
        bnez    $t1, g_announce
        li      $v0, SYS_PRINT_STR
        syscall
        j       g_leave

g_announce:
        lw      $t0, turn
        la      $a0, msg_black_turn
        beq     $t0, BLACK, g_say_turn
        la      $a0, msg_red_turn
g_say_turn:
        li      $v0, SYS_PRINT_STR
        syscall

g_ask:
        # both squares are read before anything is checked, like in the handout
        la      $a0, msg_ask_start
        jal     ask
        beq     $v0, P_CMD, g_command
        move    $s0, $v1
        la      $a0, msg_ask_land
        jal     ask
        beq     $v0, P_CMD, g_command
        move    $s1, $v1

        move    $a0, $s0
        jal     cell_of_sq
        beqz    $v0, g_invalid
        move    $s2, $v0
        move    $a0, $s1
        jal     cell_of_sq
        beqz    $v0, g_invalid
        move    $s3, $v0

        # the start square must hold one of the mover's pieces
        la      $t0, board
        add     $t0, $t0, $s2
        lbu     $t0, 0($t0)
        lw      $t1, turn
        and     $t0, $t0, $t1
        beqz    $t0, g_invalid

        move    $a0, $s2
        la      $a1, move_buf
        jal     gen_piece_moves
        move    $a0, $s3
        jal     find_landing
        beqz    $v0, g_invalid

g_play:
        lw      $s0, turn               # remember who moved for the message
        move    $a0, $v0
        jal     apply_step
        move    $s1, $v0
        andi    $t0, $s1, STEP_CAPTURE
        beqz    $t0, g_played
        la      $a0, msg_cap_red
        beq     $s0, BLACK, g_say_cap
        la      $a0, msg_cap_black
g_say_cap:
        li      $v0, SYS_PRINT_STR
        syscall
g_played:
        andi    $t0, $s1, STEP_CHAIN
        beqz    $t0, g_turn

        # the piece has to keep jumping, only the landing square is asked
        jal     display_board
        print_str(msg_chain)
g_chain_ask:
        la      $a0, msg_ask_land
        jal     ask
        beq     $v0, P_CMD, g_command
        move    $a0, $v1
        jal     cell_of_sq
        move    $s3, $v0
        lw      $a0, chain_piece
        la      $a1, move_buf
        jal     gen_captures
        move    $a0, $s3
        jal     find_landing
        bnez    $v0, g_play
        print_str(msg_invalid)
        j       g_chain_ask

g_invalid:
        print_str(msg_invalid)
        j       g_ask

g_command:
        ori     $v1, $v1, 0x20
        beq     $v1, 'q', g_quit
        lw      $t0, chain_piece
        beqz    $t0, g_invalid
        print_str(msg_invalid)
        j       g_chain_ask
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

# Looks through move_buf (v0 entries) for a move that lands on cell a0.
# v0 = that move, or 0 if there is none.
find_landing:
        la      $t0, move_buf
        move    $t1, $v0
        li      $v0, 0
fl_loop:
        beqz    $t1, fl_done
        lw      $t2, 0($t0)
        srl     $t3, $t2, 8
        andi    $t3, $t3, 0xff
        beq     $t3, $a0, fl_hit
        addi    $t0, $t0, 4
        addi    $t1, $t1, -1
        j       fl_loop
fl_hit:
        move    $v0, $t2
fl_done:
        jr      $ra
