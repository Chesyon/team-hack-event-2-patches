; ------------------------------------------------------------------------------
; Skycloud383 - 10/27/2025
;
; Decrease the user's belly by 30.
; ------------------------------------------------------------------------------

.relativeinclude on
.nds
.arm
.definelabel MaxSize, 0xCC4
.include "lib/stdlib_us.asm"
.include "lib/dunlib_us.asm"
.definelabel ItemStartAddress, 0x0231BE50
.definelabel ItemJumpAddress, 0x0231CB14
.definelabel TryDecreaseBelly, 0x23168D8
.create "./code_out.bin", 0x0231BE50
	.org ItemStartAddress
	.area MaxSize
		sub r13, r13, #0x4
		mov r3, #0
		mov r2, #30
		mov r1 , r7
		mov r0, r8
		bl TryDecreaseBelly
		add r13, r13, #0x4
		b ItemJumpAddress
		.pool
	.endarea
.close
