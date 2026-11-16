# Move generation.
# A move is packed into one word: from | to << 8 | captured << 16
# (all three are cell indexes, captured is 0 for a plain move).

.include "include/constants.inc"

.globl gen_simple

.text

# Non-capturing moves of the piece on cell a0, stored from a1 on.
# v0 = how many were written.
gen_simple:
        la      $t0, board
        add     $t1, $t0, $a0
        lbu     $t2, 0($t1)             # the piece
        la      $t3, dirs
        li      $v0, 0
        li      $t4, 0                  # direction 0..3
gs_loop:
        # men only walk forward: up for Black (dirs 0,1), down for Red (2,3)
        andi    $t5, $t2, KING
        bnez    $t5, gs_try
        srl     $t6, $t4, 1
        andi    $t5, $t2, BLACK
        xor     $t5, $t5, $t6
        beqz    $t5, gs_next
gs_try:
        sll     $t5, $t4, 2
        add     $t5, $t3, $t5
        lw      $t5, 0($t5)
        add     $t6, $a0, $t5
        add     $t7, $t0, $t6
        lbu     $t7, 0($t7)
        bnez    $t7, gs_next
        sll     $t7, $t6, 8
        or      $t7, $t7, $a0
        sw      $t7, 0($a1)
        addi    $a1, $a1, 4
        addi    $v0, $v0, 1
gs_next:
        addi    $t4, $t4, 1
        blt     $t4, 4, gs_loop
        jr      $ra
