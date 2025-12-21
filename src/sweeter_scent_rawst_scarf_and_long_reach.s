// code made by Xenia/oceansodaz

SweeterScent:
    bne SweeterSkemp
    mov r0, #27
    bl  CheckDungeonId
    cmp r0, #1
    beq SweeterSkemp
    b   SweeterScentExit

SweeterScentText:
	mov r0, r6
	mov r1, #0x2E
	bl	AbilityIsActive
	cmp r0, #1
	ldreq r1, =#0xC5D
	beq SweetTEnd
	mov r0, r6
	ldr r1, =#2598
	bl	LogMessageByIdWithPopup
	
SweeterScentVFX:
	mov r0, r6
	mov r1, #12
	bl	PlayEffectAnimationEntityStandard
	b	SweetScentVFXExit

LongReach:
	push {r1-r9,r11,r12,lr}
	bl abs
	cmp r0, #1
	popgt {r1-r9,r11,r12,pc}
	mov r0, r10
	mov r1, #0x81
	bl  AbilityIsActive
	cmp r0, #0
	moveq r0, #1
   	movne r0, #2
	pop {r1-r9,r11,r12,pc}

IsRawstScarfActive:
    push {lr} // r14
    cmp r0, #0 // Is safeguard NOT active?
    popne {pc} // If no, game runs as normal
    // How does ItemIsActive work?
    mov r0, r9 // Should contain an entity pointer, in this case it is the target in TryInflictBurnStatus
    mov r1, #198 // Should contain an unused item ID, preferably not higher than 255
    bl ItemIsActive
    cmp r0, #0 // Checks if the item is NOT active.
    movne r0, #1 // If no, pretend safeguard is active
    moveq r0, #0 // If yes, game runs as normal
    pop {pc} // r15