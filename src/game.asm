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
        jal     gen_simple
        la      $t0, move_buf
g_find:
        beqz    $v0, g_invalid
        lw      $a0, 0($t0)
        srl     $t1, $a0, 8
        andi    $t1, $t1, 0xff
        beq     $t1, $s3, g_play
        addi    $t0, $t0, 4
        addi    $v0, $v0, -1
        j       g_find
g_play:
        jal     apply_step
        j       g_turn

g_invalid:
        print_str(msg_invalid)
        j       g_ask

g_command:
        ori     $v1, $v1, 0x20
        bne     $v1, 'q', g_invalid
        print_str(msg_bye)

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
