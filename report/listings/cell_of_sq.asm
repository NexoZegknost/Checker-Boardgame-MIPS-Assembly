cell_of_sq:
    li      $v0, 0
    blez    $a0, cs_done
    lw      $t0, num_squares
    bgt     $a0, $t0, cs_done
    lw      $t1, num_flip
    beqz    $t1, cs_lookup
    sub     $a0, $t0, $a0       # turning the board maps k to total + 1 - k
    addi    $a0, $a0, 1
cs_lookup:
    la      $t0, sq_to_idx
    add     $t0, $t0, $a0
    lbu     $v0, 0($t0)
cs_done:
