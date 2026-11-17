# Copies the current position to the STATE_BYTES at a0.
state_save:
    la      $t0, state
    li      $t1, STATE_WORDS
ss_loop:
    lw      $t2, 0($t0)
    sw      $t2, 0($a0)
    addi    $t0, $t0, 4
    addi    $a0, $a0, 4
    addi    $t1, $t1, -1
    bgtz    $t1, ss_loop
    jr      $ra
