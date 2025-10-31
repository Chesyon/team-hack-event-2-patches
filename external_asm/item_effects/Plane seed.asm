; ------------------------------------------------------------------------------
; Skycloud383 - 10/27/2025
;
; Inflict the slip status, increase belly by 5, and restore 1 PP to all moves.
; ------------------------------------------------------------------------------

.relativeinclude on
.nds
.arm
.definelabel MaxSize, 0xCC4
.include "lib/stdlib_us.asm"
.include "lib/dunlib_us.asm"
.definelabel ItemStartAddress, 0x0231BE50
.definelabel ItemJumpAddress, 0x0231CB14
.definelabel TryInflictSlipStatus, 0x2317A0C
.definelabel RestoreAllMovePP, 0x2317C20
.definelabel TryIncreaseBelly, 0x2316BB0
.create "./code_out.bin", 0x0231BE50
	.org ItemStartAddress
	.area MaxSize
		sub r13, r13, #0x4
		mov r1 , r7
		mov r0, r8
		bl TryInflictSlipStatus
		mov r2, #5
		mov r1, r7
		mov r3, #00
		mov r0, #00
		str r0, [r13, 0]
		mov r0, r8
		bl TryIncreaseBelly
		mov r0, r8
		mov r1, r7
		mov r2, 1
		mov r3, 0
		bl RestoreAllMovePP
		add r13, r13, #0x4
		b ItemJumpAddress
		.pool
	.endarea
.close
