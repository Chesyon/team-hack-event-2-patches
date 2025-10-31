; ------------------------------------------------------------------------------
; Skycloud383 - 10/27/2025
;
; Heal HP and belly by 33.
; ------------------------------------------------------------------------------

.relativeinclude on
.nds
.arm
.definelabel MaxSize, 0xCC4
.include "lib/stdlib_us.asm"
.include "lib/dunlib_us.asm"
.definelabel ItemStartAddress, 0x0231BE50
.definelabel ItemJumpAddress, 0x0231CB14
.definelabel TryRestoreHP, 0x231526C
.definelabel TryIncreaseBelly, 0x2316BB0
.create "./code_out.bin", 0x0231BE50
	.org ItemStartAddress
	.area MaxSize
		sub r13, r13, #0x4
		mov r2, #33
		mov r0, r8
		mov r1, r7
		bl TryRestoreHP
		mov r2, #33
		mov r1, r7
		mov r3, #05
		mov r0, #01
		str r0, [r13, 0]
		mov r0, r8
		bl TryIncreaseBelly
		add r13, r13, #0x4
		b ItemJumpAddress
		.pool
	.endarea
.close
