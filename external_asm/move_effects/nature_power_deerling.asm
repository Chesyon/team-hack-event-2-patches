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
.definelabel TryInflictConfusedStatus, 0x2314F38
.definelabel TryInflictLeechSeedStatus, 0x23157EC
.definelabel Randomize, 0x2324934 ; is actually called DungeonRandOutcomeUserTargetInteraction
.definelabel TryInflictBurnStatus, 0x2312338
.definelabel EntityIsValid, 0x022E0354
.definelabel LogMessage, 0x234B350
.definelabel MonsterIsType, 0x2301E50
.definelabel ActivateFlashFire, 0x2313CE4

; unified beatdown is a single strike in solo form, but 3 strikes in schooling form. for balancing reasons, the 3 strikes deal 40% of the original damage.

.definelabel MaxSize, 0x2598

.create "./code_out.bin", 0x2330134
    .org MoveStartAddress
    .area MaxSize

    	sub sp,sp,#4

	mov  r11, r11

	mov  r0, r9
	mov  r1, r4
	mov  r2, r8
	mov  r3, #0x100
	bl   DealDamage

	; check for deerling, default is spring so dont check that

	ldr   r0, [r9, #0xb4]
	ldrh  r1, [r0, #0x4]
	ldr   r2, =0x21D
	ldr   r3, =600
	cmp   r1, r2
	addne r2, r2, r3
	cmpne r1, r2
	beq   SummerDeerling
	ldr   r2, =0x21E
	cmp   r1, r2
	addne r2, r2, r3
	cmpne r1, r2
	beq   FallDeerling
	ldr   r2, =0x21F
	cmp   r1, r2
	addne r2, r2, r3
	cmpne r1, r2
	beq   WinterDeerling

	; additionally check for sawsbuck

	ldr   r2, =#1201
	add   r2, r2, #1
	cmp   r1, r2
	beq   SummerDeerling
	add   r2, r2, #1
	cmp   r1, r2
	beq   FallDeerling
	add   r2, r2, #1
	cmp   r1, r2
	beq   WinterDeerling

	SpringDeerling:

	; spring deerling applies leech seed to the opponent

	mov  r0, r9
	mov  r1, r4
	mov  r2, #0
	mov  r3, #0
	bl   TryInflictLeechSeedStatus
	b    return

	SummerDeerling:

	; summer deerling has a 10% chance to apply burn

	mov  r0, r9
	mov  r1, r4
	mov  r2, #10
	bl   Randomize
	cmp  r0, #0
	beq  return

	mov  r0, r9
	mov  r1, r4
	mov  r2, #0
	mov  r3, #0
	str  r3, [r13, #0x0]
	bl   TryInflictBurnStatus
	b    return

	FallDeerling:

	; fall deerling applies the flash fire effect to any fire type on the team

	push  r5-r8
	ldr   r8, =DUNGEON_PTR
	mov   r5, #0

	mov  r0,r9
	mov  r1,r4
	ldr  r2,=#3890
	bl   LogMessage
	
	FlashFireBoostLoop:
	ldr   r0, [r8, #0x0]
	add   r0, r0, r5, lsl 2h
	add   r0, r0, #0x12000
	ldr   r6, [r0, #0xB28]

	mov   r0, r6
	bl    EntityIsValid
	cmp   r0, #1
	bne   EndLoop

	mov   r0, r6
	mov   r1, #0x2
	bl    MonsterIsType
	cmp   r0, #1
	bne   EndLoop

	mov r0, r6
	mov r1, r6
	bl ActivateFlashFire

	EndLoop:
	add    r5, r5, #1
	cmp    r5, #4
	bne    FlashFireBoostLoop
	
	pop    r5-r8
	b      return
	
	WinterDeerling:

	; winter deerling has a 50% chance to lower speed

	mov  r0, r9
	mov  r1, r4
	mov  r2, #50
	bl   Randomize
	cmp  r0, #0
	beq  return
	
	mov  r0, r9
	mov  r1, r4
	mov  r2, #1
	mov  r3, #0
	bl   LowerSpeed
	b    return

    return:
        add  sp,sp,#4
        b    MoveJumpAddress
	
        .pool
    .endarea
.close
