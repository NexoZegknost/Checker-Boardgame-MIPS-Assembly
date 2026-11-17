# Jumps available to the piece on cell a0, stored from a1 on.
# v0 = how many were written.
gen_captures:
    la      $t0, board
    add     $t1, $t0, $a0
    lbu     $t2, 0($t1)
    andi    $t8, $t2, COLOR_MASK
    xori    $t8, $t8, COLOR_MASK    # the colour we can jump over
    la      $t3, dirs
    lw      $v1, rule_flags
    li      $a2, 0          # 1 = this piece is a flying king
    andi    $t1, $t2, KING
    beqz    $t1, gc_start
    andi    $t1, $v1, RULE_FLYING
    sne     $a2, $t1, $zero
gc_start:
    li      $v0, 0
    li      $t4, 0
gc_loop:
    andi    $t1, $t2, KING
    bnez    $t1, gc_try
    andi    $t1, $v1, RULE_JUMP_BACK
    bnez    $t1, gc_try
    srl     $t6, $t4, 1
    andi    $t1, $t2, BLACK
    xor     $t1, $t1, $t6
    beqz    $t1, gc_next
gc_try:
    sll     $t5, $t4, 2
    add     $t5, $t3, $t5
    lw      $t5, 0($t5)
    add     $t6, $a0, $t5       # square being jumped
    beqz    $a2, gc_victim
gc_approach:
    # a flying king may start its jump from further away
    add     $t7, $t0, $t6
    lbu     $t7, 0($t7)
    bnez    $t7, gc_victim
    add     $t6, $t6, $t5
    j       gc_approach
gc_victim:
    add     $t7, $t0, $t6
    lbu     $t7, 0($t7)
    and     $t1, $t7, $t8
    beqz    $t1, gc_next
    andi    $t1, $t7, GHOST     # already jumped this turn
    bnez    $t1, gc_next
    add     $t9, $t6, $t5       # landing square
gc_land:
    add     $t7, $t0, $t9
    lbu     $t7, 0($t7)
    bnez    $t7, gc_next
    sll     $t7, $t6, 16
    sll     $t1, $t9, 8
    or      $t7, $t7, $t1
    or      $t7, $t7, $a0
    sw      $t7, 0($a1)
    addi    $a1, $a1, 4
    addi    $v0, $v0, 1
    # and it may land on any free square behind the piece
    beqz    $a2, gc_next
    add     $t9, $t9, $t5
    j       gc_land
gc_next:
    addi    $t4, $t4, 1
    blt     $t4, 4, gc_loop
    jr      $ra
