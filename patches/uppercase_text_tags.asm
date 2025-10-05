.nds
.include "symbols.asm"

.open "arm9.bin", arm9_start
    .org UppercaseNTagHook
    .area 0x4
        b HandleUppercaseNTagWrapper
    .endarea

    .org UppercaseVTagHook
	.area 0x4
        b HandleUppercaseVTagWrapper
	.endarea
.close