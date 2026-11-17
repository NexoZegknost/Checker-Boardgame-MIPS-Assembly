# a0 = cell, a1 = piece. v0 = 1 if it is a man on its crowning row.
# Only touches $t5, $t6 and $v0.
reaches_crown_row:
    li      $v0, 0
    andi    $t5, $a1, KING
    bnez    $t5, rc_done
    lw      $t5, board_w
    andi    $t6, $a1, BLACK
    beqz    $t6, rc_red
    sll     $t5, $t5, 1
    slt     $v0, $a0, $t5
    jr      $ra
rc_red:
    lw      $t6, board_n
    mul     $t5, $t5, $t6
    sgt     $v0, $a0, $t5
