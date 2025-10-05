.nds
.include "symbols.asm"

.open "arm9.bin", arm9_start
    .org EnterHookTextSpeedWrapper
	.area 0x4
        beq HookTextSpeedWrapper
	.endarea

	.org EnterHookTextLoop
	.area 0x4
        b HookTextLoop
	.endarea
.close