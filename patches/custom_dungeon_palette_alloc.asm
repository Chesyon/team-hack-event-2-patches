.nds
.include "symbols.asm"

.open "overlay29.bin", overlay29_start
    .org 0x022e1d3c
    .area 0x4
        mov r0, r8
    .endarea
    .org 0x022e1d44
    .area 0x4
        bl PaletteAllocatorFindEmptyForPartyButModified
    .endarea
.close
