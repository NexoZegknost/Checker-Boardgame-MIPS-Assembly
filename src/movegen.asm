# Move generation.
# A move is packed into one word: from | to << 8 | captured << 16
# (all three are cell indexes, captured is 0 for a plain move).

.include "include/constants.inc"

.globl gen_simple, gen_captures, gen_legal
.globl legal_buf, legal_count

.data
                .align 2
legal_buf:      .space 1024
legal_count:    .word 0

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

# Jumps available to the piece on cell a0, stored from a1 on.
# v0 = how many were written.
gen_captures:
        la      $t0, board
        add     $t1, $t0, $a0
        lbu     $t2, 0($t1)
        andi    $t8, $t2, COLOR_MASK
        xori    $t8, $t8, COLOR_MASK    # the colour we can jump over
        la      $t3, dirs
        li      $v0, 0
        li      $t4, 0
gc_loop:
        andi    $t5, $t2, KING
        bnez    $t5, gc_try
        srl     $t6, $t4, 1
        andi    $t5, $t2, BLACK
        xor     $t5, $t5, $t6
        beqz    $t5, gc_next
gc_try:
        sll     $t5, $t4, 2
        add     $t5, $t3, $t5
        lw      $t5, 0($t5)
        add     $t6, $a0, $t5           # square being jumped
        add     $t7, $t0, $t6
        lbu     $t7, 0($t7)
        and     $t7, $t7, $t8
        beqz    $t7, gc_next
        add     $t9, $t6, $t5           # landing square
        add     $t7, $t0, $t9
        lbu     $t7, 0($t7)
        bnez    $t7, gc_next
        sll     $t7, $t6, 16
        sll     $t9, $t9, 8
        or      $t7, $t7, $t9
        or      $t7, $t7, $a0
        sw      $t7, 0($a1)
        addi    $a1, $a1, 4
        addi    $v0, $v0, 1
gc_next:
        addi    $t4, $t4, 1
        blt     $t4, 4, gc_loop
        jr      $ra

# Fills legal_buf with every step the side to move may play.
# While a chain is open that is just the jumps of chain_piece.
# v0 = legal_count = number of moves.
gen_legal:
        addi    $sp, $sp, -16
        sw      $ra, 12($sp)
        sw      $s0, 8($sp)
        sw      $s1, 4($sp)
        sw      $s2, 0($sp)

        la      $s0, legal_buf          # next free slot
        lw      $a0, chain_piece
        beqz    $a0, gl_all
        move    $a1, $s0
        jal     gen_captures
        j       gl_done

gl_all:
        li      $s2, 0                  # first pass jumps, second pass plain moves
gl_pass:
        li      $s1, 1
gl_square:
        la      $t0, sq_to_idx
        add     $t0, $t0, $s1
        lbu     $a0, 0($t0)
        la      $t1, board
        add     $t1, $t1, $a0
        lbu     $t1, 0($t1)
        lw      $t2, turn
        and     $t1, $t1, $t2
        beqz    $t1, gl_next
        move    $a1, $s0
        beqz    $s2, gl_jumps
        jal     gen_simple
        j       gl_stored
gl_jumps:
        jal     gen_captures
gl_stored:
        sll     $t0, $v0, 2
        add     $s0, $s0, $t0
gl_next:
        addi    $s1, $s1, 1
        lw      $t0, num_squares
        ble     $s1, $t0, gl_square
        addi    $s2, $s2, 1
        blt     $s2, 2, gl_pass

        la      $t0, legal_buf
        sub     $v0, $s0, $t0
        srl     $v0, $v0, 2
gl_done:
        sw      $v0, legal_count
        lw      $s2, 0($sp)
        lw      $s1, 4($sp)
        lw      $s0, 8($sp)
        lw      $ra, 12($sp)
        addi    $sp, $sp, 16
        jr      $ra
