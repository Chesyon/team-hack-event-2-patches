.nds
.include "symbols.asm"

.open "arm9.bin", arm9_start]
    ; change [CS:O] to make text black
    .org CSOReturnValue
    .area 0x1
        .byte 0x8E
    .endarea
.close
