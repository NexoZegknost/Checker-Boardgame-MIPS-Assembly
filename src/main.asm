# Checkers for MARS - program entry and main menu.
# Assemble with "Assemble all files in directory" turned on.

.include "include/constants.inc"

.globl main

.data
msg_title:      .asciiz "=== Checkers ===\n"
msg_menu:       .asciiz "\n 1) New game\n 2) Settings\n 3) Set up a position\n 4) How to play\n 0) Quit\n"
msg_choice:     .asciiz "> "
msg_bad_choice: .asciiz "Please pick one of the numbers above.\n"
msg_goodbye:    .asciiz "Goodbye!\n"
msg_rules:      .ascii  "\nHow to play\n"
                .ascii  "- Black moves first, then the players take turns.\n"
                .ascii  "- A man moves one square diagonally forward onto an empty square.\n"
                .ascii  "- A piece captures by jumping over an enemy piece next to it and landing\n"
                .ascii  "  on the empty square right behind. If that piece can jump again from\n"
                .ascii  "  where it landed, it has to.\n"
                .ascii  "- A man that reaches the far row becomes a king (shown as B or R).\n"
                .ascii  "  Kings move and capture forwards and backwards.\n"
                .ascii  "- You win when your opponent has no pieces or no legal move left.\n"
                .ascii  "- The dark squares are numbered row by row from the top left; the\n"
                .ascii  "  framed board style in the settings shows the numbers.\n"
                .ascii  "- During a game type h to see the extra commands.\n"
                .ascii  "- These are the rules of the base game. The settings can make capturing\n"
                .asciiz "  mandatory or switch to a 10x10 board.\n"

.text
main:
        print_str(msg_title)
menu:
        print_str(msg_menu)
        la      $a0, msg_choice
        jal     prompt_number
        beq     $v0, 1, menu_play
        beq     $v0, 2, menu_settings
        beq     $v0, 3, menu_editor
        beq     $v0, 4, menu_rules
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

menu_editor:
        jal     editor_run
        j       menu

menu_rules:
        print_str(msg_rules)
        j       menu

menu_quit:
        print_str(msg_goodbye)
        li      $v0, SYS_EXIT
        syscall
