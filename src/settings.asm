# Game options and the menu that changes them.

.include "include/constants.inc"

.globl opt_view, opt_persp, opt_input
.globl settings_menu

.data
opt_view:       .word 0         # 0 = plain, 1 = framed with square numbers
opt_persp:      .word 0         # 0 = fixed, 1 = board turns, 2 = board and numbers turn
opt_input:      .word 0         # 0 = type both squares, 1 = choose from a list

msg_header:     .asciiz "\nSettings (pick a line to change it)\n"
msg_back:       .asciiz " 0) Back\n"
msg_choice:     .asciiz "> "
str_item:       .asciiz ") "

lbl_view:       .asciiz "Board style : "
view_plain:     .asciiz "plain, as in the assignment"
view_framed:    .asciiz "framed, with square numbers"

lbl_persp:      .asciiz "Point of view: "
persp_fixed:    .asciiz "Black always at the bottom"
persp_turn:     .asciiz "board turns to the player to move"
persp_both:     .asciiz "board and square numbers turn to the player to move"

lbl_input:      .asciiz "Move entry  : "
input_type:     .asciiz "type the starting and landing squares"
input_list:     .asciiz "choose a piece, then a move from a list"

                .align 2
view_names:     .word view_plain, view_framed
persp_names:    .word persp_fixed, persp_turn, persp_both
input_names:    .word input_type, input_list

# one row per option: label, variable, how many values, names of the values
options:        .word lbl_view,  opt_view,  2, view_names
                .word lbl_persp, opt_persp, 3, persp_names
                .word lbl_input, opt_input, 2, input_names
options_end:

.text

settings_menu:
        addi    $sp, $sp, -12
        sw      $ra, 8($sp)
        sw      $s0, 4($sp)
        sw      $s1, 0($sp)
sm_show:
        print_str(msg_header)
        la      $s0, options
        li      $s1, 1
sm_line:
        print_chr(' ')
        print_num($s1)
        print_str(str_item)
        lw      $a0, 0($s0)
        li      $v0, SYS_PRINT_STR
        syscall
        lw      $t0, 4($s0)
        lw      $t0, 0($t0)             # current value
        lw      $t1, 12($s0)
        sll     $t0, $t0, 2
        add     $t1, $t1, $t0
        lw      $a0, 0($t1)
        li      $v0, SYS_PRINT_STR
        syscall
        print_chr('\n')
        addi    $s0, $s0, 16
        addi    $s1, $s1, 1
        la      $t0, options_end
        blt     $s0, $t0, sm_line
        print_str(msg_back)

        la      $a0, msg_choice
        jal     prompt_number
        beqz    $v0, sm_done
        blez    $v0, sm_show
        bge     $v0, $s1, sm_show

        # step the chosen option to its next value, wrapping around
        addi    $v0, $v0, -1
        sll     $v0, $v0, 4
        la      $t0, options
        add     $t0, $t0, $v0
        lw      $t1, 4($t0)
        lw      $t2, 0($t1)
        addi    $t2, $t2, 1
        lw      $t3, 8($t0)
        blt     $t2, $t3, sm_store
        li      $t2, 0
sm_store:
        sw      $t2, 0($t1)
        j       sm_show
sm_done:
        lw      $s1, 0($sp)
        lw      $s0, 4($sp)
        lw      $ra, 8($sp)
        addi    $sp, $sp, 12
        jr      $ra
