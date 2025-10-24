.nds
.include "symbols.asm"

.open "overlay29.bin", overlay29_start
    .org DungeonTilePostPickHook
    .area 0x4c
        mov r0, r9 ; x coordinate
        mov r1, r8 ; y coordinate
        mov r2, r10 ; currently picked tile number, without the randomness
        bl DungeonTilePostPickReplacementPart
        b DungeonTilePostPickHookFinalJump
    .endarea
.close
