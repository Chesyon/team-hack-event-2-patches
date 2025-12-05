; ------------------------------------------------------------------------------
; Set Monster Entry Special Attack
; Sets a Chimecho Assembly member's Special Attack stat! Slot 0 is the player, 1 is the partner, and 5+ are recruitables.
; If you are using this on current party members, call Irdkwia's "Remove Party" process before this one!
; Param 1: ent_id
; Param 2: new_value
; Returns: Nothing
; ------------------------------------------------------------------------------

.relativeinclude on
.nds
.arm

.definelabel MaxSize, 0x810

; Uncomment/comment the following labels depending on your version.

; For US
.include "lib/stdlib_us.asm"
.definelabel ProcStartAddress, 0x022E7248
.definelabel ProcJumpAddress, 0x022E7AC0
.definelabel AssemblyPointer, 0x20B0A48

; For EU
;.include "lib/stdlib_eu.asm"
;.definelabel ProcStartAddress, 0x022E7B88
;.definelabel ProcJumpAddress, 0x022E8400
;.definelabel AssemblyPointer, 0x20B138C


; File creation
.create "./code_out.bin", 0x022E7248 ; For EU: 0x022E7B88
	.org ProcStartAddress
	.area MaxSize ; Define the size of the area
		push {r4-r6,r8-r11}
		ldr r11,=AssemblyPointer
		ldr r11,[r11, #0x0]; // "Larvesta" Slot!
		cmp r7, #1;
		bne SkipStats
		ldrh r0, [r11, #0xA]; // Max HP
		add r0, #30;
		ldr r1, =#999
		cmp r0, r1;
		movgt r0, r1;
		strh r0, [r11, #0xA]
		ldrb r0, [r11, #0xC]
		add r0, #15;
		cmp r0, #255;
		movge r0, #255;
		strb r0, [r11, #0xC]
		ldrb r0, [r11, #0xD]
		add r0, #15;
		cmp r0, #255;
		movge r0, #255;
		strb r0, [r11, #0xD]
		ldrb r0, [r11, #0xE]
		add r0, #15;
		cmp r0, #255;
		movge r0, #255;
		strb r0, [r11, #0xE]
		ldrb r0, [r11, #0xF]
		add r0, #15;
		cmp r0, #255;
		movge r0, #255;
		strb r0, [r11, #0xF]
	SkipStats:
		mov r8, #0x24;
		mov r4, #0;
	MoveLoopStart:
		ldrh r0, [r11, r8]
		ldr r1, =#411; // Sandsear Storm
		cmp r0, r1;
		bne MoveLoopEnd;
		mov r0, #240; // Heat Wave
		strh r0, [r11, r8]
	MoveLoopEnd:
		add r4, #1;
		add r8, #0x6;
		cmp r4, #4;
		blt MoveLoopStart;
		pop {r4-r6,r8-r11}
		b ProcJumpAddress
		.pool
	.endarea
.close
