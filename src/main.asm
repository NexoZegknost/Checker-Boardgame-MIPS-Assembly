# Checkers for MARS - program entry and main menu.
# Assemble with "Assemble all files in directory" turned on.

.include "include/constants.inc"

.globl main

.data
msg_title:      .asciiz "=== Checkers ===\n"
msg_menu:       .asciiz "\n 1) New game\n 2) Settings\n 0) Quit\n"
msg_choice:     .asciiz "> "
msg_bad_choice: .asciiz "Please pick one of the numbers above.\n"
msg_goodbye:    .asciiz "Goodbye!\n"

.text
main:
        print_str(msg_title)
menu:
        print_str(msg_menu)
        la      $a0, msg_choice
        jal     prompt_number
        beq     $v0, 1, menu_play
        beq     $v0, 2, menu_settings
        beq     $v0, 0, menu_quit
        print_str(msg_bad_choice)
        j       menu

menu_play:
        jal     board_reset
        jal     game_run
        j       menu

menu_settings:
        jal     settings_menu
        j       menu

menu_quit:
        print_str(msg_goodbye)
        li      $v0, SYS_EXIT
        syscall
