.nds
.include "symbols.asm"

.open "overlay11.bin", overlay11_start
    .org MENU_START_HOOK // Menu Start 0x022e60f0
    .area 0x4
        b MenuStartHook
    .endarea

    .org MENU_END_HOOK // Menu End 0x022e68f8
    .area 0x4
        b MenuEndHook
    .endarea
.close