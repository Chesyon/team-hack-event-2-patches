; ------------------------------------------------------------------------------
; Decay Monster Stats
; Sets Volcarona 2's stats and level to decay from that of Volcarona 1 to Larvesta.
; Param 1: N, being the fraction of the stat delta to add from volcarona to larvesta.
; Param 2: 1 if Larvesta's data should be copied over, 0 otherwise.
; Returns: Probably nothing
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
.definelabel Copy4BytesArray, 0x0200330C

; File creation
.create "./code_out.bin", 0x022E7248 ; For EU: 0x022E7B88
	.org ProcStartAddress
	.area MaxSize ; Define the size of the area
		cmp r6, #1;
		bne SkipAssignment;
		push {r6,r7}
		mov r7, #9;
		mov r6, #0;
		ldr r0,=AssemblyPointer
		ldr r1,[r0]
		mov r2,#0x44
		mla r1,r7,r2,r1
		ldr r0,[r0]
		mla r0,r6,r2,r0
		bl Copy4BytesArray
		pop {r6, r7}
	SkipAssignment:
		mov r0, r7;
		mov r2, r7; // num_days
		ldr r1,=AssemblyPointer
		ldr r10,[r1] // slot 0
		mov r0, #0x220; // slot 9
		add r9, r10, r0;
		add r8, r9, #0x44; // slot 8
		
		// Species (Most likely make volcarona)
		ldrh r0, [r8, #0x4]; // volc_max
		strh r0, [r10, #0x4]; // volc_decay
		
		// Level
		ldrb r0, [r9, #0x1]; // larv_true
		ldrb r1, [r8, #0x1]; // volc_max
		bl TakeStatDelta
		strb r0, [r10, #0x1]; // volc_decay
		
		// IQ
		ldrh r0, [r9, #0x8]; // larv_true
		ldrh r1, [r8, #0x8]; // volc_max
		bl TakeStatDelta
		strh r0, [r10, #0x8]; // volc_decay

		// HP
		ldrh r0, [r9, #0xA]; // larv_true
		ldrh r1, [r8, #0xA]; // volc_max
		bl TakeStatDelta
		strh r0, [r10, #0xA]; // volc_decay

		// ATK
		ldrb r0, [r9, #0xC]; // larv_true
		ldrb r1, [r8, #0xC]; // volc_max
		bl TakeStatDelta
		strb r0, [r10, #0xC]; // volc_decay

		// SPA
		ldrb r0, [r9, #0xD]; // larv_true
		ldrb r1, [r8, #0xD]; // volc_max
		bl TakeStatDelta
		strb r0, [r10, #0xD]; // volc_decay

		// DEF
		ldrb r0, [r9, #0xE]; // larv_true
		ldrb r1, [r8, #0xE]; // volc_max
		bl TakeStatDelta
		strb r0, [r10, #0xE]; // volc_decay

		// SPDEF
		ldrb r0, [r9, #0xF]; // larv_true
		ldrb r1, [r8, #0xF]; // volc_max
		bl TakeStatDelta
		strb r0, [r10, #0xF]; // volc_decay
		
		b ProcJumpAddress

	// r0: larv_true, out: volc_decay 
	// r1: volc_max
	// r2: num_days

	TakeStatDelta:
		/* 
			volc_max - larv_true = Y
			larv_true + Y >> num_days = volc_decay
		*/
		push {lr}
		cmp r1, r0; // cmp volc_max, larv_true
		pople {pc}
		cmp r2, #3;
		popgt {pc}
		sub r1, r1, r0;
		add r0, r1, lsr r2;
		pop {pc}

		.pool
	.endarea
.close
