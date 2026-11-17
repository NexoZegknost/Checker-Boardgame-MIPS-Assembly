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
jump_score:     .space 1024

.text

# Non-capturing moves of the piece on cell a0, stored from a1 on.
# v0 = how many were written.
gen_simple:
        la      $t0, board
        add     $t1, $t0, $a0
        lbu     $t2, 0($t1)             # the piece
        la      $t3, dirs
        lw      $t8, rule_flags
        li      $v0, 0
        li      $t4, 0                  # direction 0..3
gs_loop:
        # men only walk forward: up for Black (dirs 0,1), down for Red (2,3)
        andi    $t5, $t2, KING
        bnez    $t5, gs_try
        andi    $t5, $t8, RULE_MOVE_BACK
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
gs_slide:
        add     $t7, $t0, $t6
        lbu     $t7, 0($t7)
        bnez    $t7, gs_next
        sll     $t7, $t6, 8
        or      $t7, $t7, $a0
        sw      $t7, 0($a1)
        addi    $a1, $a1, 4
        addi    $v0, $v0, 1
        # only a flying king goes on past the first square
        andi    $t7, $t2, KING
        beqz    $t7, gs_next
        andi    $t7, $t8, RULE_FLYING
        beqz    $t7, gs_next
        add     $t6, $t6, $t5
        j       gs_slide
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
        lw      $v1, rule_flags
        li      $a2, 0                  # 1 = this piece is a flying king
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
        add     $t6, $a0, $t5           # square being jumped
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
        andi    $t1, $t7, GHOST         # already jumped this turn
        bnez    $t1, gc_next
        add     $t9, $t6, $t5           # landing square
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
        move    $a0, $v0
        jal     filter_jumps
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
        bge     $s2, 2, gl_count
        la      $t0, legal_buf
        beq     $s0, $t0, gl_pass
        sub     $a0, $s0, $t0
        srl     $a0, $a0, 2
        jal     filter_jumps
        sll     $t0, $v0, 2
        la      $s0, legal_buf
        add     $s0, $s0, $t0
        # with mandatory capture the plain moves only count when nothing can jump
        lw      $t0, rule_flags
        andi    $t0, $t0, RULE_MUST_CAPTURE
        beqz    $t0, gl_pass
gl_count:

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

# Keeps the jumps the rules allow among the first a0 entries of legal_buf.
# v0 = how many are left.
filter_jumps:
        addi    $sp, $sp, -20
        sw      $ra, 16($sp)
        sw      $s0, 12($sp)
        sw      $s1, 8($sp)
        sw      $s2, 4($sp)
        sw      $s3, 0($sp)
        move    $s0, $a0
        beqz    $s0, fj_keep_all
        lw      $t0, rule_flags
        andi    $t1, $t0, RULE_LONGEST
        bnez    $t1, fj_longest
        andi    $t1, $t0, RULE_FLYING
        bnez    $t1, fj_landing
fj_keep_all:
        move    $v0, $s0
        j       fj_ret

        # longest capture rule: keep the jumps that start the longest chain
fj_longest:
        li      $s1, 0
        li      $s3, 0
fj_score:
        sll     $t0, $s1, 2
        lw      $a0, legal_buf($t0)
        jal     chain_len
        sll     $t0, $s1, 2
        sw      $v0, jump_score($t0)
        ble     $v0, $s3, fj_score_next
        move    $s3, $v0
fj_score_next:
        addi    $s1, $s1, 1
        blt     $s1, $s0, fj_score

        li      $s1, 0
        li      $s2, 0                  # kept so far
fj_pack:
        sll     $t0, $s1, 2
        lw      $t1, jump_score($t0)
        bne     $t1, $s3, fj_pack_next
        lw      $t1, legal_buf($t0)
        sll     $t2, $s2, 2
        sw      $t1, legal_buf($t2)
        addi    $s2, $s2, 1
fj_pack_next:
        addi    $s1, $s1, 1
        blt     $s1, $s0, fj_pack
        move    $v0, $s2
        j       fj_ret

        # Russian rule: a king must land where it can keep jumping, if it can
fj_landing:
        li      $s1, 0
fj_cont:
        sll     $t0, $s1, 2
        lw      $a0, legal_buf($t0)
        jal     jump_continues
        sll     $t0, $s1, 2
        sw      $v0, jump_score($t0)
        addi    $s1, $s1, 1
        blt     $s1, $s0, fj_cont

        # bit 1 = keep: it continues, or no other landing square does
        li      $s1, 0
fj_mark:
        sll     $t0, $s1, 2
        lw      $t1, jump_score($t0)
        bnez    $t1, fj_mark_keep
        lw      $t2, legal_buf($t0)
        li      $t3, 0x00ff00ff         # same piece jumping over the same victim
        and     $t2, $t2, $t3
        li      $t4, 0
fj_rival:
        sll     $t5, $t4, 2
        lw      $t6, legal_buf($t5)
        and     $t6, $t6, $t3
        bne     $t6, $t2, fj_rival_next
        lw      $t6, jump_score($t5)
        andi    $t6, $t6, 1
        bnez    $t6, fj_mark_next       # a better landing square exists
fj_rival_next:
        addi    $t4, $t4, 1
        blt     $t4, $s0, fj_rival
fj_mark_keep:
        ori     $t1, $t1, 2
        sw      $t1, jump_score($t0)
fj_mark_next:
        addi    $s1, $s1, 1
        blt     $s1, $s0, fj_mark

        li      $s1, 0
        li      $s2, 0
fj_pack2:
        sll     $t0, $s1, 2
        lw      $t1, jump_score($t0)
        andi    $t1, $t1, 2
        beqz    $t1, fj_pack2_next
        lw      $t1, legal_buf($t0)
        sll     $t2, $s2, 2
        sw      $t1, legal_buf($t2)
        addi    $s2, $s2, 1
fj_pack2_next:
        addi    $s1, $s1, 1
        blt     $s1, $s0, fj_pack2
        move    $v0, $s2
fj_ret:
        lw      $s3, 0($sp)
        lw      $s2, 4($sp)
        lw      $s1, 8($sp)
        lw      $s0, 12($sp)
        lw      $ra, 16($sp)
        addi    $sp, $sp, 20
        jr      $ra

# a0 = a jump. v0 = pieces taken by the longest chain starting with it.
chain_len:
        addi    $sp, $sp, -176          # 4 saved registers + room for 40 follow-ups
        sw      $ra, 172($sp)
        sw      $s0, 168($sp)
        sw      $s1, 164($sp)
        sw      $s2, 160($sp)
        move    $s2, $a0
        jal     snap_push
        move    $a0, $s2
        jal     apply_step
        li      $s0, 0                  # best follow-up so far
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

# a0 = a jump. v0 = 1 if the piece can jump again after it.
jump_continues:
        addi    $sp, $sp, -8
        sw      $ra, 4($sp)
        sw      $s0, 0($sp)
        move    $s0, $a0
        jal     snap_push
        move    $a0, $s0
        jal     apply_step
        andi    $s0, $v0, STEP_CHAIN
        jal     snap_pop
        sne     $v0, $s0, $zero
        lw      $s0, 0($sp)
        lw      $ra, 4($sp)
        addi    $sp, $sp, 8
        jr      $ra
