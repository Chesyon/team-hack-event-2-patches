; r4 = Target
; r5 = Garbage Data
; r6 = Move ID
; r7 = ID of the item that called the move (for orbs. If the move is not for an orb, ignore this)
; r8 = Move Data
; r9 = User
; 10 = Unknown (usually 0 or 1, no clue on the context)

; NOTE: registers r4 through r9, r11 and r13/sp must remain unchanged by the time the code reaches `b MoveJumpAddress`
; if you need to use these registers, use push/pop commands
; push stores its current value and pop returns it to the value that was stored

.relativeinclude on
.nds
.arm

.definelabel MoveStartAddress, 0x2330134 ; if the rom is EU, use 0x2330B74 instead
.definelabel MoveJumpAddress, 0x23326CC ; if the rom is EU, use 0x233310C instead
.definelabel SubStringTags, 0x22E2AD8
.definelabel DungeonRandInt, 0x22EAA98
.definelabel FormatMoveString, 0x2013478
.definelabel YesNoMenu, 0x234D518
.definelabel GetMaxPp, 0x2013A50
.definelabel SubMoveTags, 0x0234B084
.definelabel InitMove, 0x20137B8
.definelabel GenerateItem, 0x023472C4
.definelabel AddItemToBagNoHeld, 0x0200F874
.definelabel LogMessageByIdWithPopup, 0x234B498
.definelabel GetDungeonSpriteIndex, 0x022F7388
.definelabel LoadMonsterSprite, 0x022F7654

; JP rom will be added as soon as someone slaps me in the face with the addresses

.definelabel MaxSize, 0x2598

.create "./code_out.bin", 0x2330134
    .org MoveStartAddress
    .area MaxSize
	sub sp, sp, #0x8

	push r5, r6, r7, r10

	mov r11, r11

	SetHpTo1:

	mov r0, #1
	strh r0, [r1, #0x10]
	strh r0, [r1, #0x12]
	mov r0, #0
	strh r0, [r1, #0x16]
	
	; this will be the targets move slot
	
	GetMoves:

	mov r0, #4
	bl  DungeonRandInt
	mov r5, r0 

	; and this, the targets

	mov r0, #4
	bl  DungeonRandInt
	mov r10, r0 

	; get the targets move

	ldr r0, [r4, #0xb4]
	lsl r5, #0x3
	add r5, r5, #0x124
	add r0, r0, r5
	mov r6, r0

	; now get the users

	ldr r0, [r9, #0xb4]
	lsl r10, #0x3
	add r10, r10, #0x124
	add r0, r0, r10
	mov r7, r0

	; reroll if volcarona attempts to learn nothing

	ldrh r0, [r6, #0x4]
	cmp  r0, #0
	beq  GetMoves

	; make sure the targets move isnt the "cant move" move

	ldr  r1, =#404
	cmp  r0, r1
	bne  ChangeTargetSprite

	mov  r0, r9
	ldr  r1, =#4145
	bl   LogMessageByIdWithPopup

	b    return

	; the expected result:
	; "[string:0]'s [move:1] will be replaced with [move:2]. Is this okay?"

	ChangeTargetSprite:

	ldr r1, [r4, #0xb4]
	ldrh r0, [r1, #0x4]
	mov r5, #0
	ldr r1, =#1286
	cmp  r0, r1
	ldreq r5, =#1276
	sub r1, r1, #1
	cmp  r0, r1
	ldreq r5, =#1282
	sub r1, r1, #1
	cmp  r0, r1
	ldreq r5, =#1275
	sub r1, r1, #1
	cmp  r0, r1
	ldreq r5, =#1274
	ldr r1, =#1237
	cmp r0, r1
	ldreq r5, =#1277
	ldr r1, =#636
	cmp r0, r1
	ldreq r5, =#1273
	ldr r1, =#20
	cmp r0, r1
	ldreq r5, =#1279
	ldr r1, =#1116
	cmp r0, r1
	ldreq r5, =#1280
	ldr r1, =#829
	cmp r0, r1
	ldreq r5, =#1281
	ldr r1, =#732
	cmp r0, r1
	ldreq r5, =#1278
	cmp r5, #0
	beq ReplaceMove

	mov  r0,#5 ; fade to white? zzz
	mov  r1,#0x2000
	mov  r2,#0 ; bottom screen
	bl   0x234C668 ; startdungeonfadewrapper

push r6
mov r6, #0

ShortWaitCheck:

	bl   0x22E9FE0 ; AdvanceFrame
	add  r6,r6,#1
	cmp  r6,#20
	blt  ShortWaitCheck
pop r6

	mov r0, r5
	mov r1, #1
	bl LoadMonsterSprite
	mov r0, r5
	bl GetDungeonSpriteIndex
	strh r0,[r4,#+0xA8]
	ldr r1,[r4,#+0xb4]
	strh r5,[r1,#+0x2]
	strh r5,[r1,#+0x4]
push r6
mov r6, #0

ldr r0, =#7435
bl 0x22EACCC

ShortWaitCheck2:

	bl   0x22E9FE0 ; AdvanceFrame
	add  r6,r6,#1
	cmp  r6,#100
	blt  ShortWaitCheck2
pop r6

	mov  r0,#4 ; fade in?
	mov  r1,#0x2000
	mov  r2,#0 ; bottom screen
	bl   0x234C668 ; startdungeonfadewrapper

	ReplaceMove:

	mov r0, #1
	ldrh r1, [r7, 0x4]
	bl  SubMoveTags

	mov r0, #2
	ldrh r1, [r6, 0x4]
	bl  SubMoveTags

	mov r0, #0
	mov r1, r9
	mov r2, #0
	bl  SubStringTags
	
	mov r0, #0
	ldr r1, =#4144
	mov r2, #0
	mov r3, #1
	bl  YesNoMenu

	mov  r0, r7
	ldrh r1, [r6, #0x4]
	bl   InitMove
	mov  r1, r0

	b    ChangeTarget

	ChangeTarget:
	
	ldr r0, [r4, #0xb4]
    	add r0, r0, #0x124
    	ldr r7, [r0]
	ldr r1, =#404
	bl  InitMove

	ldr r0, [r4, #0xb4]
    	add r0, r0, #0x124
	add r0, r0, #0x8
    	ldr r7, [r0]
	ldr r1, =#404
	bl  InitMove

	ldr r0, [r4, #0xb4]
    	add r0, r0, #0x124
	add r0, r0, #0x8
	add r0, r0, #0x8
    	ldr r7, [r0]
	ldr r1, =#404
	bl  InitMove

	ldr r0, [r4, #0xb4]
    	add r0, r0, #0x124
	add r0, r0, #0x8
	add r0, r0, #0x8
	add r0, r0, #0x8
    	ldr r7, [r0]
	ldr r1, =#404
	bl  InitMove	

	return:
        pop r5, r6, r7, r10
	add sp, sp, #0x8
        b   MoveJumpAddress
        .pool
    .endarea
.close