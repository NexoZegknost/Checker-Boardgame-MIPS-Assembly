# Console input. Lines are read as text and parsed here because the
# read-int syscall kills the program when the user types a letter.

.include "include/constants.inc"

.globl read_line, parse_line, parse_arg, prompt_line, prompt_number

.data
line_buf:       .space 64
parse_arg:      .word -1

.text

read_line:
        la      $a0, line_buf
        li      $a1, 64
        li      $v0, SYS_READ_STR
        syscall
        jr      $ra

# Prints the prompt in a0, reads a line and returns what parse_line says.
prompt_line:
        push    ($ra)
        li      $v0, SYS_PRINT_STR
        syscall
        jal     read_line
        jal     parse_line
        pop     ($ra)
        jr      $ra

# Same, for menus: v0 = the number typed, or -1 for anything else.
prompt_number:
        push    ($ra)
        jal     prompt_line
        beq     $v0, P_NUM, pn_ok
        li      $v1, -1
pn_ok:
        move    $v0, $v1
        pop     ($ra)
        jr      $ra

# Looks at the line from read_line.
#   v0 = P_NUM, v1 = the number            "17"
#   v0 = P_CMD, v1 = first letter          "q", "undo", "b 12"
#        a number after the word ends up in parse_arg (-1 if there is none)
#   v0 = P_BAD for anything else
parse_line:
        push    ($ra)
        li      $t9, -1
        sw      $t9, parse_arg
        la      $t0, line_buf
        jal     skip_blanks
        lbu     $t1, 0($t0)

        jal     is_digit
        bnez    $v0, pl_number

        # letters only, both cases
        ori     $t2, $t1, 0x20
        blt     $t2, 'a', pl_bad
        bgt     $t2, 'z', pl_bad
        move    $t8, $t1
pl_word:
        addi    $t0, $t0, 1
        lbu     $t1, 0($t0)
        ori     $t2, $t1, 0x20
        blt     $t2, 'a', pl_word_end
        ble     $t2, 'z', pl_word
pl_word_end:
        jal     skip_blanks
        lbu     $t1, 0($t0)
        jal     is_digit
        beqz    $v0, pl_cmd_tail
        jal     read_digits
        bltz    $v1, pl_bad
        sw      $v1, parse_arg
pl_cmd_tail:
        jal     at_line_end
        beqz    $v0, pl_bad
        li      $v0, P_CMD
        move    $v1, $t8
        j       pl_ret

pl_number:
        jal     read_digits
        bltz    $v1, pl_bad
        move    $t8, $v1
        jal     at_line_end
        beqz    $v0, pl_bad
        li      $v0, P_NUM
        move    $v1, $t8
        j       pl_ret
pl_bad:
        li      $v0, P_BAD
        li      $v1, 0
pl_ret:
        pop     ($ra)
        jr      $ra

# The helpers below walk the line through $t0 and leave $t8/$t9 alone.

skip_blanks:
        lbu     $t1, 0($t0)
        beq     $t1, ' ', sb_step
        beq     $t1, '\t', sb_step
        jr      $ra
sb_step:
        addi    $t0, $t0, 1
        j       skip_blanks

# v0 = 1 if $t1 holds '0'..'9'
is_digit:
        li      $v0, 0
        blt     $t1, '0', id_done
        bgt     $t1, '9', id_done
        li      $v0, 1
id_done:
        jr      $ra

# v1 = decimal number at $t0, or -1 if it is absurdly long
read_digits:
        li      $v1, 0
rd_loop:
        lbu     $t1, 0($t0)
        blt     $t1, '0', rd_done
        bgt     $t1, '9', rd_done
        mul     $v1, $v1, 10
        addi    $t1, $t1, -48
        add     $v1, $v1, $t1
        addi    $t0, $t0, 1
        ble     $v1, 9999, rd_loop
        li      $v1, -1
rd_done:
        jr      $ra

# v0 = 1 if only blanks are left on the line
at_line_end:
        lbu     $t1, 0($t0)
        addi    $t0, $t0, 1
        beq     $t1, ' ', at_line_end
        beq     $t1, '\t', at_line_end
        li      $v0, 1
        beqz    $t1, ale_done
        beq     $t1, '\n', ale_done
        beq     $t1, '\r', ale_done
        li      $v0, 0
ale_done:
        jr      $ra
