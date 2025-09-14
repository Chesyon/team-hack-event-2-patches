

	// hook is located in HandleFaint at 0x22f7f44. the intent here was to have the fainted mon flashing as they explode
	
	// r10 holds the defender, r8 is the attacker
	// r7 holds the defender

	CheckIgnition:

	mov   r11, r11

	push  {r0-r6, r9-r12}

	mov   r0, r8
	mov   r1, #0x7c
	bl    AbilityIsActive
	cmp   r0, #0
	beq   IgnitionCheckEndPremature // successfully does this

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
	ldr   r1, =#317// flame from ember
	bl    PlayEffectAnimationEntityStandard // aint doing this

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
	bne   EndLoopI

	CauseDamage:

	mov   r0, #0
	str   r0, [r13, #+0xc]
   	mov   r0, #2
    	str   r0, [r13, #+0x0]
    	str   r0, [r13, #+0x4]
    	str   r0, [r13, #+0x8]
    	str   r0, [r13, #+0x10]
    	str   r0, [r13, #+0x14]
	
	ldr   r0, [r8, #0xb4]
	ldrb  r1, [r0, #0xA]
	add   r1, r1, #15

	mov   r0, r6
    	mov   r2, #0
	mov   r3, #0
    	bl    CalcDamageFixed

	CauseBurn: // or this

	mov   r0, r8
	mov   r1, r6
	mov   r2, #0
	mov   r3, #0
	str   r3, [r13, #0x0]
	bl    TryInflictBurnStatus	

	EndLoopI:
	add   r5, r5, #1
	cmp   r5, #8
	bne   TileCheckLoop

	pop   {r0-r6,r9-r12}
	add   r13, r13, #0x14
	b     UNK_BURT_UNHOOK_3

	IgnitionCheckEndPremature:

	pop   {r0-r6, r9-r12}
	bl    HandleFaint	
	b     UNK_BURT_UNHOOK_3

	RegeneratorAbility:
	
	ldr    r0, =DUNGEON_PTR
	ldr    r0, [r0, #0x0]

	push   {r1-r12}
	mov    r11, r11
	mov    r4, r0 // r0 previously contained the dungeon pointer at the point i hooked. in fact, it already did ldr r0, [r0] 
	push   {r0} // i dont think pushing a register deletes its value? better safe than sorry anyways
	mov    r5, #0
	
	CheckTeamLoop:

	add    r7, r4, r5, lsl #0x2
	add    r7, r7, #0x12000
	ldr    r0, [r7, #0x0B28]
	mov    r6, r0 // store the entity into r6 for later, as running r0 through entity is valid replaces it with 0 or 1
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
	cmp    r5, #0x4 // the first four entries to the table are all allies, so checking the is_allied_monster bit is pointless
	bne    CheckTeamLoop

	return:

	pop    {r0-r12}
	ldrb   r0, [r0, #0x748]
	b      UNK_BURT_UNHOOK_4

 	SapSipper:

 	mov   r11, r11
	  	
	bne   UNK_BURT_THING_1 ; // this is where water absorb heals HP, hooking in the spot i did accounts for both branches to 92f8 with one hook
	ldrb  r0, [r6, #0xc]
	cmp   r0, #0x5
	beq   UNK_BURT_THING_1 ; // basic water absorb stuff
	
	mov   r0, r8
	mov   r1, r7
	mov   r2, #0x7F
	mov   r3, #1
	bl    DefenderAbilityIsActive
	cmp   r0, #1
	bne   UNK_BURT_THING_2

	ldrb  r0, [r6, #0xc] ; // the moves type? i think?
	cmp   r0, #4
	bne   UNK_BURT_THING_2

	mov   r0, r8
	mov   r1, r7
	mov   r2, #0
	mov   r3, #1
	bl    BoostOffensiveStat

	mov   r0, #1
	strb  r0, [r6, #0x10] ; // probably some kind of immunity flag? god i hope so
	mov   r0, #0
	b     BURT_ExitPoint
