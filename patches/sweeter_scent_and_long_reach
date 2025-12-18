// code made by Xenia/oceansodaz

SweeterScent:
    bne SweeterSkemp
    mov r0, #1
    bl  CheckDungeonId
    cmp r0, #1
    beq SweeterSkemp
    b   SweeterScentExit ; 0x2332dfc

SweeterScentText:
	mov r0, r6
	mov r1, 0x2E
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
	b	SweetScentVFXExit ; 0x230e828

LongReach:
	push {r1-r9,r11,r12,lr}
	bl abs
	cmp r0, #1
	popgt {r1-r9,r11,r12,pc}
	mov r0, r10
	mov r1, 0x81
	bl  AbilityIsActive
	cmp r0, #0
	moveq r0, #1
   	movne r0, #2
	pop {r1-r9,r11,r12,pc}
