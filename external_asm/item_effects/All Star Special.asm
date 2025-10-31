; ------------------------------------------------------------------------------
; Skycloud383 - 10/27/2025
;
; If the target is Deerling or Sawsbuck, fully restore
; HP and PP. Otherwise, do nothing.
; ------------------------------------------------------------------------------

.relativeinclude on
.nds
.arm
.definelabel MaxSize, 0xCC4
.include "lib/stdlib_us.asm"
.include "lib/dunlib_us.asm"
.definelabel ItemStartAddress, 0x0231BE50
.definelabel ItemJumpAddress, 0x0231CB14
.definelabel  TryRestoreHp, 0x231526C
.definelabel RestoreAllMovePP, 0x2317C20
.definelabel LogMessage, 0x234B508
.definelabel SubstitutePlaceholderStringTags, 0x22E2AD8
.create "./code_out.bin", 0x0231BE50
	.org ItemStartAddress
	.area MaxSize
		sub r13, r13, #0x4
		ldr r0, [r7, #0xB4]; retrieve the monster struct ptr from the entity
		ldrh r0, [r0, #0x4]; Load "half" (h) the monster_id_16 of the monster.
		ldr r1, =#1140
		cmp r0, r1;
		addne r1, #1; 1141
		cmpne r0, r1;
		addne r1, #1; 1142
		cmpne r0, r1;
		addne r1, #1; 1143
		cmpne r0, r1;
		addne r1, #58; 1201
		cmpne r0, r1;
		addne r1, #1; 1202
		cmpne r0, r1;
		addne r1, #1; 1203
		cmpne r0, r1;
		addne r1, #1; 1204
		cmpne r0, r1;
		bne IsNotDeerling;
		mov r0, r8
		mov r1, r7
		mov r2, #1000
		bl TryRestoreHp
		mov r0, r8;
		mov r1, r7;
		mov r2, #256;
		mov r3, #0;
		bl RestoreAllMovePP
		mov r0, #0;
		mov r1, r7;
		mov r2, #0;
		bl SubstitutePlaceholderStringTags;
		ldr r1, =ThisPieIsSoGoodICouldDie;
		mov r0, r8;
		mov r2, #1;
		bl LogMessage;
		b EndOfFunction;
		IsNotDeerling:
		mov r0, #0;
		mov r1, r7;
		mov r2, #0;
		bl SubstitutePlaceholderStringTags
		ldr r1, =ThisPieIsSoBadICouldDie;
		mov r0, r8;
		mov r2, #1;
		bl LogMessage;
		EndOfFunction:
		add r13, r13, #0x4
		b ItemJumpAddress
		.pool
		ThisPieIsSoGoodICouldDie:
		.asciiz "[string:0] thought that was amazing!"
		ThisPieIsSoBadICouldDie:
		.asciiz "[string:0] vows to never eat fast food again."
	.endarea
.close
