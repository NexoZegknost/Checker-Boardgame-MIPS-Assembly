# try a move and take it back: snap_push before, snap_pop after
snap_push:
    lw      $a0, snap_top
    addi    $t0, $a0, STATE_BYTES
    sw      $t0, snap_top
    j       state_save
