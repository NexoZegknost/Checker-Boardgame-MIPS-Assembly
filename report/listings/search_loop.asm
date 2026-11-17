se_loop:
    jal     snap_push
    lw      $a0, 0($s4)
    jal     apply_step
    lw      $t0, turn
    bne     $t0, $s7, se_reply
    move    $a0, $s0
    move    $a1, $s1
    move    $a2, $s2
    jal     search
    j       se_scored
se_reply:
    addi    $a0, $s0, -1
    neg     $a1, $s2
    neg     $a2, $s1
    jal     search
    neg     $v0, $v0
se_scored:
    jal     snap_pop        # leaves v0 alone

    ble     $v0, $s5, se_next
    move    $s5, $v0
    lw      $s6, 0($s4)
    ble     $v0, $s1, se_next
    move    $s1, $v0
    bge     $s1, $s2, se_best       # the opponent will not allow this line
se_next:
    addi    $s4, $s4, 4
    addi    $s3, $s3, -1
    bgtz    $s3, se_loop
se_best:
