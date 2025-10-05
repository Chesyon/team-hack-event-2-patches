.nds
.include "symbols.asm"

.open "arm9.bin", arm9_start
    .org UppercaseUVTagHook
	.area 0x8
        b HandleUppercaseUTagWrapper
        b HandleUppercaseVTagWrapper
	.endarea
.close