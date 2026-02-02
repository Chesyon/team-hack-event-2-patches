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

.include "lib/stdlib_us.asm"
.include "lib/dunlib_us.asm"
.definelabel MoveStartAddress, 0x2330134
.definelabel MoveJumpAddress, 0x23326CC
.definelabel TryInflictTerrifiedStatus, 0x2314E60
.definelabel DungeonRandOutcome, 0x22EAB20
.definelabel DungeonRandInt, 0x22EAA98
.definelabel SoundproofAbilityID, 0x3C ; 60
.definelabel SoundproofStrID, 0xEB9 ; 3769
.definelabel DUNGEON_PTR, 0x02353538
.definelabel TryInflictCringeStatus, 0x23143E8
.definelabel LowerOffensiveStat, 0x23135FC
.definelabel LowerSpeed, 0x2314954
.definelabel LowerDefensiveStat, 0x2313814
.definelabel TryWarp, 0x2320D08
.definelabel EntityIsValid, 0x22E0354
.definelabel TryInflictConfusedStatus, 0x2314F38
.definelabel EndBurnClassStatus, 0x23061A8
.definelabel CalcDamageFixed, 0x230D240
.definelabel AttackUp, 0x231399C
.definelabel LogMessageByIdWithPopupCheckUserTarget, 0x234B350
.definelabel FlashFireShouldActivate, 0x2313C74
.definelabel ActivateFlashFire, 0x2313CE4

; snuff out heals the targets burn, deals damage to the target, and then boosts the users attack by 1 stage
; NOTE: snuff out not KOing allies is not in this file, look inside snuff_out_no_ko.s for that

.definelabel MaxSize, 0x2598

.create "./code_out.bin", 0x2330134
    .org MoveStartAddress
    .area MaxSize

    	sub sp,sp,14h

	mov  r11, r11

	; does the target have burn?

	ldr  r0, [r4, #0xb4]
	ldrb r1, [r0, #0xbf]
	cmp  r1, #1
	bne  NotBurned

	; are the target and user on the same team? reduce damage if so

	ldrb  r1, [r0, #0x6]
	ldr   r0, [r9, #0xb4]
	ldrb  r0, [r0, #0x6]
	cmp   r1, r0
	moveq r3, #256
	beq   IsEnemy

	mov  r0, r9
	mov  r1, r4
	mov  r2, r8
	mov  r3, #128
	bl   DealDamage
	
	b    CheckFlashFire

	IsEnemy:

	mov  r0, r9
	mov  r1, r4
	mov  r2, r8
	bl   DealDamage

	CheckFlashFire:

	mov  r0, r9
	mov  r1, r9
	bl   FlashFireShouldActivate
	cmp  r0, #1
	beq  RaiseAttack

	mov  r0, r9
	mov  r1, r9
	bl   ActivateFlashFire
	b    WhoKnewLarvestaWasAFireExtinguisherAllAlong

	RaiseAttack:

	mov  r0, r9
	mov  r1, r9
	mov  r2, #0
	mov  r3, #1
	bl   AttackUp	

	WhoKnewLarvestaWasAFireExtinguisherAllAlong:

	mov  r0, r4
	bl   EntityIsValid
	cmp  r0, #1
	bne  return

	mov  r0, r9
	mov  r1, r4
	bl   EndBurnClassStatus

	b    return

	NotBurned:

	mov  r0, r9
	mov  r1, r4
	ldr  r2, =#3892
	bl   LogMessageByIdWithPopupCheckUserTarget

    return:
        add  sp,sp,14h
        b    MoveJumpAddress
	
        .pool
    .endarea

.close



