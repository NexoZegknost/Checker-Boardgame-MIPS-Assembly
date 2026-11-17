# Game options and the menus that change them.

.include "include/constants.inc"

.globl opt_view, opt_persp, opt_input, opt_opponent
.globl settings_menu

.eqv RULES_ROW   4              # line of the rule set in the settings menu
.eqv CUSTOM_ROW  6              # "Custom rules..." comes right after the option lines
.eqv CUSTOM_SET  5              # value of opt_rules that means "leave the rules alone"
.eqv RULE_VARS   8              # words in one preset row

.data
opt_view:       .word 0         # 0 = plain, 1 = framed with square numbers
opt_persp:      .word 0         # 0 = fixed, 1 = board turns, 2 = board and numbers turn
opt_input:      .word 0         # 0 = type both squares, 1 = choose from a list
opt_rules:      .word 0         # index into presets, or CUSTOM_SET
opt_opponent:   .word 0         # 0 = second player, 1-3 = computer plays Red (easy, medium, hard)

# The single rules. A preset is just a row of values for these, in this order.
rule_vars:
rule_board:     .word 0         # 0 = 8x8, 1 = 10x10 with 15 men, 2 = 10x10 with 20 men
# from here on the order is the order of the RULE_ bits
rule_must:      .word 0
rule_longest:   .word 0
rule_flying:    .word 0
rule_jump_back: .word 0
rule_move_back: .word 0
rule_crown:     .word 0
rule_remove:    .word 0

#                     board must long fly jback mback crown remove
presets:        .word 0,    0,   0,   0,  0,    0,    0,    0   # assignment
                .word 0,    1,   0,   0,  0,    0,    0,    0   # English
                .word 2,    1,   1,   1,  1,    0,    1,    1   # International
                .word 0,    1,   1,   1,  1,    0,    1,    1   # Brazilian
                .word 0,    1,   0,   1,  1,    0,    0,    1   # Russian

msg_choice:     .asciiz "> "
str_item:       .asciiz ") "

msg_settings:   .asciiz "\nSettings (pick a line to change it)\n"
msg_settings_f: .asciiz " 6) Custom rules...\n 0) Back\n"
msg_custom:     .asciiz "\nCustom rules (pick a line to change it)\n"
msg_custom_f:   .asciiz " 0) Back\n"

lbl_view:       .asciiz "Board style  : "
view_plain:     .asciiz "plain, as in the assignment"
view_framed:    .asciiz "framed, with square numbers"

lbl_persp:      .asciiz "Point of view: "
persp_fixed:    .asciiz "Black always at the bottom"
persp_turn:     .asciiz "board turns to the player to move"
persp_both:     .asciiz "board and square numbers turn to the player to move"

lbl_input:      .asciiz "Move entry   : "
input_type:     .asciiz "type the starting and landing squares"
input_list:     .asciiz "choose a piece, then a move from a list"

lbl_rules:      .asciiz "Rules        : "
rules_base:     .asciiz "assignment (capturing is optional)"
rules_english:  .asciiz "English draughts (capturing is mandatory)"
rules_intl:     .asciiz "International draughts (10x10, flying kings, longest capture)"
rules_brazil:   .asciiz "Brazilian draughts (International rules on 8x8)"
rules_russian:  .asciiz "Russian draughts (8x8, flying kings)"
rules_custom:   .asciiz "custom"

lbl_opponent:   .asciiz "Red is played: "
opp_human:      .asciiz "by a second player"
opp_easy:       .asciiz "by the computer, easy (random moves)"
opp_medium:     .asciiz "by the computer, medium"
opp_hard:       .asciiz "by the computer, hard (slow in MARS)"

lbl_board:      .asciiz "Board                : "
board_8:        .asciiz "8x8, 12 men each"
board_10_15:    .asciiz "10x10, 15 men each"
board_10_20:    .asciiz "10x10, 20 men each"
lbl_must:       .asciiz "Mandatory capture    : "
lbl_longest:    .asciiz "Longest capture first: "
lbl_flying:     .asciiz "Flying kings         : "
lbl_jump_back:  .asciiz "Men capture backwards: "
lbl_move_back:  .asciiz "Men move backwards   : "
lbl_crown:      .asciiz "A man is crowned     : "
crown_now:      .asciiz "as soon as it reaches the last row"
crown_late:     .asciiz "only if its move ends on the last row"
lbl_remove:     .asciiz "Jumped pieces go     : "
remove_now:     .asciiz "at once"
remove_late:    .asciiz "when the turn is over"
str_off:        .asciiz "off"
str_on:         .asciiz "on"

                .align 2
view_names:     .word view_plain, view_framed
persp_names:    .word persp_fixed, persp_turn, persp_both
input_names:    .word input_type, input_list
rules_names:    .word rules_base, rules_english, rules_intl, rules_brazil, rules_russian, rules_custom
opp_names:      .word opp_human, opp_easy, opp_medium, opp_hard
crown_names:    .word crown_now, crown_late
remove_names:   .word remove_now, remove_late
board_names:    .word board_8, board_10_15, board_10_20
onoff_names:    .word str_off, str_on

# one row per option: label, variable, how many values, names of the values
options:        .word lbl_view,  opt_view,  2, view_names
                .word lbl_persp, opt_persp, 3, persp_names
                .word lbl_input, opt_input, 2, input_names
                .word lbl_rules, opt_rules, 6, rules_names
                .word lbl_opponent, opt_opponent, 4, opp_names
options_end:

custom_rows:    .word lbl_board, rule_board, 3, board_names
                .word lbl_must,  rule_must,  2, onoff_names
                .word lbl_longest,   rule_longest,   2, onoff_names
                .word lbl_flying,    rule_flying,    2, onoff_names
                .word lbl_jump_back, rule_jump_back, 2, onoff_names
                .word lbl_move_back, rule_move_back, 2, onoff_names
                .word lbl_crown,     rule_crown,     2, crown_names
                .word lbl_remove,    rule_remove,    2, remove_names
custom_end:

# for run_menu: title, rows, end of rows, footer, highest valid choice
settings_desc:  .word msg_settings, options, options_end, msg_settings_f, CUSTOM_ROW
custom_desc:    .word msg_custom, custom_rows, custom_end, msg_custom_f, 8

.text

settings_menu:
        push    ($ra)
sm_again:
        la      $a0, settings_desc
        jal     run_menu
        beqz    $v0, sm_leave
        beq     $v0, CUSTOM_ROW, sm_custom
        bne     $v0, RULES_ROW, sm_again
        jal     load_preset
        j       sm_again
sm_custom:
        la      $a0, custom_desc
        jal     run_menu
        beqz    $v0, sm_again
        # no longer one of the presets
        li      $t0, CUSTOM_SET
        sw      $t0, opt_rules
        jal     rules_commit
        j       sm_custom
sm_leave:
        pop     ($ra)
        jr      $ra

# Shows the menu at a0. Picking an option line steps it to its next value.
# v0 = the number picked (0 = back).
run_menu:
        addi    $sp, $sp, -16
        sw      $ra, 12($sp)
        sw      $s0, 8($sp)
        sw      $s1, 4($sp)
        sw      $s2, 0($sp)
        move    $s2, $a0
rm_show:
        lw      $a0, 0($s2)
        li      $v0, SYS_PRINT_STR
        syscall
        lw      $s0, 4($s2)
        li      $s1, 1
rm_line:
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
        lw      $t0, 8($s2)
        blt     $s0, $t0, rm_line
        lw      $a0, 12($s2)
        li      $v0, SYS_PRINT_STR
        syscall

        la      $a0, msg_choice
        jal     prompt_number
        bltz    $v0, rm_show
        lw      $t0, 16($s2)
        bgt     $v0, $t0, rm_show
        beqz    $v0, rm_done
        bge     $v0, $s1, rm_done       # not an option line, the caller deals with it

        # step the chosen option to its next value, wrapping around
        addi    $t0, $v0, -1
        sll     $t0, $t0, 4
        lw      $t1, 4($s2)
        add     $t0, $t1, $t0
        lw      $t1, 4($t0)
        lw      $t2, 0($t1)
        addi    $t2, $t2, 1
        lw      $t3, 8($t0)
        blt     $t2, $t3, rm_store
        li      $t2, 0
rm_store:
        sw      $t2, 0($t1)
rm_done:
        lw      $s2, 0($sp)
        lw      $s1, 4($sp)
        lw      $s0, 8($sp)
        lw      $ra, 12($sp)
        addi    $sp, $sp, 16
        jr      $ra

# Copies the preset chosen in opt_rules into the single rules.
load_preset:
        push    ($ra)
        lw      $t0, opt_rules
        beq     $t0, CUSTOM_SET, lp_done
        mul     $t0, $t0, RULE_VARS
        sll     $t0, $t0, 2
        la      $t1, presets
        add     $t1, $t1, $t0
        la      $t2, rule_vars
        li      $t3, RULE_VARS
lp_copy:
        lw      $t4, 0($t1)
        sw      $t4, 0($t2)
        addi    $t1, $t1, 4
        addi    $t2, $t2, 4
        addi    $t3, $t3, -1
        bgtz    $t3, lp_copy
        jal     rules_commit
lp_done:
        pop     ($ra)
        jr      $ra

# single rules -> rule_flags, board_n, men_rows
rules_commit:
        li      $t0, 8
        li      $t1, 3
        lw      $t2, rule_board
        beqz    $t2, rc_board
        li      $t0, 10
        beq     $t2, 1, rc_board
        li      $t1, 4
rc_board:
        sw      $t0, board_n
        sw      $t1, men_rows

        # "longest capture first" makes no sense unless capturing is mandatory
        lw      $t0, rule_longest
        beqz    $t0, rc_pack
        sw      $t0, rule_must
rc_pack:
        # one bit per rule, in the order they are stored
        la      $t1, rule_must
        li      $t0, 0
        li      $t2, 1
rc_bit:
        lw      $t3, 0($t1)
        beqz    $t3, rc_next
        or      $t0, $t0, $t2
rc_next:
        addi    $t1, $t1, 4
        sll     $t2, $t2, 1
        ble     $t2, RULE_REMOVE_LATE, rc_bit
        sw      $t0, rule_flags
        jr      $ra
