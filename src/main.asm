# Checkers for MARS - program entry.
# Assemble with "Assemble all files in directory" turned on.

.include "include/constants.inc"

.globl main

.text
main:
        jal     board_reset
        jal     display_board

        li      $v0, SYS_EXIT
        syscall
