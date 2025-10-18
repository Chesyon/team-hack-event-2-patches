	CheckIgnition:

	push  {r0-r7, r9-r12}

	mov   r0, r8
	mov   r1, #0x7c
	bl    AbilityIsActive
	cmp   r0, #0
	beq   IgnitionCheckEndPremature

	PunchHimSoHardHeExplodes:

	mov   r0, #0
	mov   r1, r7
	mov   r2, #0
	bl    SubstitutePlaceholderStringTags

	mov   r0, r8
	mov   r1, r7
	ldr   r2, =#3889
	bl    LogMessageByIdWithPopupCheckUserTarget

	mov   r0, r7
	ldr   r1, =#317
	bl    PlayEffectAnimationEntityStandard

	ldrh  r10, [r7, #0x4]
	ldrh  r11, [r7, #0x6]

	mov   r0,r7
	mov   r1,r5
	mov   r2,r8
	bl    HandleFaint

	SurroundingTilesSetupLoop:

	ldr   r4,=DIRECTIONS_XY 
	sub   r13, r13, #0x14
	mov   r5, #0

	TileCheckLoop:

	mov   r11, r11

	mov   r1, r5, lsl #0x2
	add   r0, r4, r5, lsl #0x2

	ldrsh r3, [r4,r1]
	mov   r12, r10
	ldrsh r1, [r0,#0x2]
	mov   r2, r11

	add   r0, r12, r3
	add   r1, r2, r1
	bl    GetTile

	ldr   r0, [r0,#+0xC]
	mov   r6, r0
	bl    EntityIsValid
	cmp   r0, #1
	bne   EndLoopI

	ldr   r9, [r6,#0xb4]
	ldrb  r9, [r9,#0x6]
	cmp   r9, #1
	movne r0, #5
	bne   DoRng
	
	CheckImmunities:

	mov   r0, r6
	mov   r1, #115
	bl    AbilityIsActive
	cmp   r0, #1
	beq   EndLoopI

	mov   r0, r6
	mov   r1, #72
	bl    AbilityIsActive
	cmp   r0, #1
	bne   CheckFireType

	mov   r0, r6
	mov   r1, r6
	bl    ActivateFlashFire

	CheckFireType:

	ldr    r0, [r6, #0xb4]
	ldrb   r1, [r0, #0x5e]
	cmp    r1, #2
	ldrneb r1, [r0, #0x5f]
	cmpne  r1, #2
	beq    EndLoopI

	CalcTotalDamage: 

	ldr   r0, [r8, #0xb4]
	ldrb  r1, [r0, #0xA]
	add   r1, r1, #15

	mov   r7, r1

	mov   r0, r8
	mov   r1, r6
	mov   r2, #2
	bl    GetTypeMatchupBothTypes
	cmp   r0, #4
	addls r15, r0, lsl #0x3
	nop
	ldr   r0, =#128
	b     CheckWeather
	ldr   r0, =#179
	b     CheckWeather
	ldr   r0, =#256
	b     CheckWeather
	ldr   r0, =#358
	b     CheckWeather
	
	CheckWeather:

	mul   r7, r0
	lsr   r7, #8

	mov   r0, r6
	bl    GetApparentWeather
	cmp   r0, #1
	ldreq r0, =#384
	cmpne r0, #4
	ldreq r0, =#192
	ldrne r0, =#256

	mul   r7, r0
	lsr   r7, #8

	CheckFilterAndSolidRockForSomeReasonEvenThoughNoMonWeakToFireHasEitherOfTheseAbilitiesExceptMegaAggronWhoIsntEvenInTheHack:

	mov   r0, r8
	mov   r1, r6
	mov   r2, #2
	bl    GetTypeMatchupBothTypes
	cmp   r0, #3
	bne   FinalAbilityCheck

	mov   r0, r6
	mov   r1, #110
	bl    AbilityIsActive
	cmp   r0, #1
	ldreq r0, =#192

	mov   r0, r6
	mov   r1, #108
	bl    AbilityIsActive
	cmp   r0, #1
	ldreq r0, =#192
	ldrne r0, =#256

	mul   r7, r0
	lsr   r7, #8

	FinalAbilityCheck:

	mov   r0, r6
	mov   r1, #66
	bl    AbilityIsActive
	cmp   r0, #1
	lsreq r7, #1
	
	mov   r0, r6
	mov   r1, #95
	bl    AbilityIsActive
	cmp   r0, #1
	lsreq r7, #1

	InflictDamage:

	mov   r0, #0
	str   r0, [r13, #+0xc]
   	mov   r0, #2
    	str   r0, [r13, #+0x0]
    	str   r0, [r13, #+0x4]
    	str   r0, [r13, #+0x8]
    	str   r0, [r13, #+0x10]
    	str   r0, [r13, #+0x14]

	mov   r0, r6
	mov   r1, r7
    	mov   r2, #0
    	mov   r3, #0
    	bl    CalcRecoilDamageFixed

	BurnChance:

	mov   r0, r8
	mov   r1, r6
	mov   r2, #2
	bl    GetTypeMatchupBothTypes
	cmp   r0, #4
	addls r15, r0, lsl #0x3
	nop
	mov   r0, #0
	b     EndLoopI
	mov   r0, #5
	b     DoRng
	mov   r0, #2
	b     DoRng
	nop
	b     CauseBurn

	DoRng: 

	bl    DungeonRandInt
	cmp   r0, #0
	bne   EndLoopI

	CauseBurn: 

	mov   r0, r6
	mov   r1, r6
	mov   r2, #0
	mov   r3, #0
	str   r3, [r13, #+0x0]
	bl    TryInflictBurnStatus
	
	EndLoopI:
	add   r5, r5, #1
	cmp   r5, #8
	bne   TileCheckLoop

	pop   {r0-r7,r9-r12}
	add   r13, r13, #0x14
	b     UNK_BURT_UNHOOK_3

	IgnitionCheckEndPremature:

	pop   {r0-r7, r9-r12}
	bl    HandleFaint	
	b     UNK_BURT_UNHOOK_3

	RegeneratorAbility:
	
	ldr    r0, =DUNGEON_PTR
	ldr    r0, [r0, #0x0]

	push   {r1-r12}
	mov    r4, r0
	push   {r0}
	mov    r5, #0
	
	CheckTeamLoop:

	add    r7, r4, r5, lsl #0x2
	add    r7, r7, #0x12000
	ldr    r0, [r7, #0x0B28]
	mov    r6, r0
	bl     EntityIsValid
	cmp    r0, #1
	bne    EndLoopR

	mov    r0, r6
	mov    r1, #0x7E
	bl     AbilityIsActive
	cmp    r0, #1
	bne    EndLoopR

	RegeneratorFound:

	mov    r0, r6
	mov    r1, r6
	ldr    r2, =999
	bl     TryRestoreHp

	EndLoopR:

	add    r5, r5, #0x1
	cmp    r5, #0x4
	bne    CheckTeamLoop

	return:

	pop    {r0-r12}
	ldrb   r0, [r0, #0x748]
	b      UNK_BURT_UNHOOK_4

 	SapSipper:
	  	
	movne r1, #1
	ldrb  r0, [r6, #0xc]
	cmp   r0, #0x5
	moveq r2, #1
	cmp   r1, #1
	cmpeq r2, #1
	beq   UNK_BURT_THING_1
	
	mov   r0, r8
	mov   r1, r7
	mov   r2, #0x7F
	mov   r3, #1
	bl    DefenderAbilityIsActive
	cmp   r0, #1
	bne   UNK_BURT_THING_2

	ldrb  r0, [r6, #0xc]
	cmp   r0, #4
	bne   UNK_BURT_THING_2

	mov   r0, r8
	mov   r1, r7
	mov   r2, #0
	mov   r3, #1
	bl    BoostOffensiveStat

	mov   r0, #1
	strb  r0, [r6, #0x10]
	mov   r0, #0
	b     BURT_ExitPoint
