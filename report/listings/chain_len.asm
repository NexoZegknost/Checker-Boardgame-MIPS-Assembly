# a0 = a jump. v0 = pieces taken by the longest chain starting with it.
chain_len:
    addi    $sp, $sp, -176      # 4 saved registers + room for 40 follow-ups
    sw      $ra, 172($sp)
    sw      $s0, 168($sp)
    sw      $s1, 164($sp)
    sw      $s2, 160($sp)
    move    $s2, $a0
    jal     snap_push
    move    $a0, $s2
    jal     apply_step
    li      $s0, 0          # best follow-up so far
    andi    $t0, $v0, STEP_CHAIN
    beqz    $t0, cl_done
    lw      $a0, chain_piece
    move    $a1, $sp
    jal     gen_captures
    move    $s1, $v0
    move    $s2, $sp
cl_loop:
    lw      $a0, 0($s2)
    jal     chain_len
    ble     $v0, $s0, cl_next
    move    $s0, $v0
cl_next:
    addi    $s2, $s2, 4
    addi    $s1, $s1, -1
    bgtz    $s1, cl_loop
cl_done:
    jal     snap_pop
    addi    $v0, $s0, 1
    lw      $s2, 160($sp)
    lw      $s1, 164($sp)
    lw      $s0, 168($sp)
    lw      $ra, 172($sp)
    addi    $sp, $sp, 176
    jr      $ra
