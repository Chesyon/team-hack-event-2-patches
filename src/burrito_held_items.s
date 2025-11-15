HasUnusedAbilityCrit:
		push {r4,r14}
		mov r4,r0
		mov r0,r7
		ldr r1,=#1260 // ID of the Goodra Doll
		bl ItemIsActive
		cmp r0,#1
		bne CheckFailedCrit
		mov r0, r7
		bl HasLowHealth
		cmp r0,#1
		ldreq r0,=100
		popeq {r4,r15}

	CheckFailedCrit:
		mov r0,r4
		bl GetMoveCritChance
		pop {r4,r15}
		
	HasUnusedAbilityAcc:
		push {r4,r5,r14}
		mov r4,r0
		mov r5,r1
		mov r0,r7
		ldr r1,=#1258 // ID of the Swablu Doll
		bl ItemIsActive
		cmp r0,#1
		bne CheckFailedAcc
		ldr r0, [r7, #0xb4]
		ldrh r1, [r0, #0x10]
		ldrh r2, [r0, #0x12]
		ldrh r3, [r0, #0x16]
		add r2, r2, r3
		lsl r1, #1
		cmp r1, r2
		ldrle r0,=125
		pople {r4,r5,r15}

	CheckFailedAcc:
		mov r0,r4
		mov r1,r5
		bl GetMoveAccuracyOrAiChance
		pop {r4,r5,r15}

	HasUnusedAbilityEffect1:
		push {r14}
		mov r0, r6
		ldr r1,=#1259 // ID of the Jardo Doll
		bl ItemIsActive
		cmp r0,#1
		bne CheckFailedEffect1
		mov r0,r6
		bl HasLowHealth
		cmp r0,#1
		moveq r4, #100
		popeq {r15}

	CheckFailedEffect1:
		mov r0,r6
		pop {r15}

	HasUnusedAbilityEffect2:
		push {r14}
		mov r0, r5
		ldr r1,=#1259 // Somehow, this is also the ID of the Jardo Doll
		bl ItemIsActive
		cmp r0,#1
		bne CheckFailedEffect2
		mov r0,r5
		bl HasLowHealth
		cmp r0,#1
		moveq r4, #100
		popeq {r15}

	CheckFailedEffect2:
		mov r0,r5
		pop {r15}
