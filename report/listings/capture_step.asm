as_moved:
    beqz    $s1, as_promote
    # the jumped piece goes at once, or stays as a ghost until the turn ends
    add     $t3, $t2, $s1
    li      $t5, 0
    andi    $t6, $s3, RULE_REMOVE_LATE
    beqz    $t6, as_take
    lbu     $t5, 0($t3)
    ori     $t5, $t5, GHOST
as_take:
    sb      $t5, 0($t3)
    ori     $s2, $s2, STEP_CAPTURE
    la      $t5, count_red
    andi    $t6, $t4, BLACK
    bnez    $t6, as_count
    la      $t5, count_black
as_count:
    lw      $t6, 0($t5)
    addi    $t6, $t6, -1
    sw      $t6, 0($t5)

