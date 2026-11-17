# Position editor: put pieces on an empty board and play from there.

.include "include/constants.inc"

.globl editor_run

.data
msg_intro:      .ascii  "\nPosition editor (standard square numbers, Black at the bottom)\n"
                .ascii  "  b 14  black man      B 14  black king\n"
                .ascii  "  r 9   red man        R 9   red king\n"
                .ascii  "  x 14  empty a square c     clear the board\n"
                .ascii  "  s     starting position\n"
                .ascii  "  t     change the side to move\n"
                .asciiz "  p     play from here q     back to the menu\n"
msg_to_move:    .asciiz " to move.\n"
msg_prompt:     .asciiz "edit> "
msg_what:       .asciiz "Not an editor command, see the list above.\n"
msg_where:      .asciiz "That command needs a square number from 1 to "
msg_crowned:    .asciiz "A man cannot stand on its last row, use a king there.\n"

.text

editor_run:
        addi    $sp, $sp, -12
        sw      $ra, 8($sp)
        sw      $s0, 4($sp)
        sw      $s1, 0($sp)

        jal     board_clear
        print_str(msg_intro)
ed_show:
        # always drawn from Black's side so the numbers match what is typed
        sw      $zero, view_flip
        sw      $zero, num_flip
        jal     display_board
        lw      $a0, turn
        jal     print_side
        print_str(msg_to_move)
ed_ask:
        la      $a0, msg_prompt
        jal     prompt_line
        bne     $v0, P_CMD, ed_what
        move    $s0, $v1

        li      $s1, BLACK
        beq     $s0, 'b', ed_place
        li      $s1, RED
        beq     $s0, 'r', ed_place
        li      $s1, 5                  # BLACK | KING
        beq     $s0, 'B', ed_place
        li      $s1, 6                  # RED | KING
        beq     $s0, 'R', ed_place
        li      $s1, EMPTY
        ori     $s0, $s0, 0x20
        beq     $s0, 'x', ed_place

        beq     $s0, 'c', ed_clear
        beq     $s0, 's', ed_start
        beq     $s0, 't', ed_turn
        beq     $s0, 'p', ed_play
        beq     $s0, 'q', ed_leave
ed_what:
        print_str(msg_what)
        j       ed_ask

ed_place:
        lw      $a0, parse_arg
        jal     cell_of_sq
        bnez    $v0, ed_square_ok
        print_str(msg_where)
        lw      $a0, num_squares
        li      $v0, SYS_PRINT_INT
        syscall
        print_chr('.')
        print_chr('\n')
        j       ed_ask
ed_square_ok:
        # a man on the row where it would be crowned makes no sense
        lw      $t0, board_w
        bne     $s1, BLACK, ed_red_man
        sll     $t0, $t0, 1
        blt     $v0, $t0, ed_crowned
        j       ed_put
ed_red_man:
        bne     $s1, RED, ed_put
        lw      $t1, board_n
        mul     $t0, $t0, $t1
        bgt     $v0, $t0, ed_crowned
ed_put:
        la      $t0, board
        add     $t0, $t0, $v0
        sb      $s1, 0($t0)
        j       ed_show
ed_crowned:
        print_str(msg_crowned)
        j       ed_ask

ed_clear:
        lw      $s0, turn
        jal     board_clear
        sw      $s0, turn
        j       ed_show
ed_start:
        jal     board_reset
        j       ed_show
ed_turn:
        lw      $t0, turn
        xori    $t0, $t0, COLOR_MASK
        sw      $t0, turn
        j       ed_show

ed_play:
        jal     count_pieces
        jal     game_run
ed_leave:
        lw      $s1, 0($sp)
        lw      $s0, 4($sp)
        lw      $ra, 8($sp)
        addi    $sp, $sp, 12
        jr      $ra

# Recounts both sides after the board was edited by hand.
count_pieces:
        li      $t0, 0                  # black
        li      $t1, 0                  # red
        lw      $t2, num_squares
        la      $t3, sq_to_idx
        la      $t4, board
cp_loop:
        add     $t5, $t3, $t2
        lbu     $t5, 0($t5)
        add     $t5, $t4, $t5
        lbu     $t5, 0($t5)
        andi    $t6, $t5, BLACK
        add     $t0, $t0, $t6
        andi    $t6, $t5, RED
        srl     $t6, $t6, 1
        add     $t1, $t1, $t6
        addi    $t2, $t2, -1
        bgtz    $t2, cp_loop
        sw      $t0, count_black
        sw      $t1, count_red
        jr      $ra
