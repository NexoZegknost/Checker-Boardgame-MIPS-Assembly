# Carrying out moves on the board.

.include "include/constants.inc"

.globl apply_step

.text

# a0 = packed move. Moves the piece and passes the turn.
apply_step:
        andi    $t0, $a0, 0xff          # from
        srl     $t1, $a0, 8
        andi    $t1, $t1, 0xff          # to
        la      $t2, board
        add     $t3, $t2, $t0
        lbu     $t4, 0($t3)
        sb      $zero, 0($t3)
        add     $t3, $t2, $t1
        sb      $t4, 0($t3)

        lw      $t0, turn
        xori    $t0, $t0, COLOR_MASK
        sw      $t0, turn
        jr      $ra
