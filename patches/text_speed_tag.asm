.nds
.include "symbols.asm"

.open "arm9.bin", arm9_start
	.org vstag_EnterHookSpeed
	.area 0x4
		beq vstag_HookSpeed
	.endarea
	
	.org vstag_EnterHookLoop
	.area 0x4
		b vstag_HookLoop
	.endarea
	
	.org 0x02020FCC
	.area 0x4
		b vstag_HookVLetter
	.endarea
.close