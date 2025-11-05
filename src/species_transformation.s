GroundCustomFormsChange:
		push {r1-r12,lr}
		mov r4, r0; // Dungeon ID
		ldr r5, =LegendaryDataTable;
	FormChangeLoopStart:
		ldrsh r0, [r5, #0x0];
		cmp r0, #0xA;
		addls pc, pc, r0, lsl #0x2;
		b ReturnFormsChange;
        b IncrementLoopCounter; // 0x0: Dont Change Form
		b IfSkyExclusiveDungeon; // 0x1: CheckSkyExclusiveDungeon
		b IfSpecificBagItem; // 0x2: If Specific Item In Bag
		b IfSpecificHeldItem; // 0x3: If Specific Item Held
		b IfHPAndOrLevel; // 0x4
		b IfInHourOrMonthRange; // 0x5
		b IfScriptVariable; // 0x6
        // Unused for now.
		b ReturnFormsChange; // 0x7
		b IfDeerlingScenMain; // 0x8
		b IfWishiwashiThreshold; // 0x9
		// I think this is redundant? gonna leave it alone just in case...
		b ReturnFormsChange; // 0xA
	IfSkyExclusiveDungeon: // Case 0x1
		mov r0, r4;
		bl IsSkyExclusiveDungeon;
		cmp r0, #0x1; // Is it SkyExclusive?
		bne IncrementLoopCounter;
		ldrh r0, [r5,#0x2];
		ldrh r1, [r5,#0x4];
		mov r2, #0xF;
		bl LoopThruTeam;
	IncrementLoopCounter:
		add r5, r5, #0x10;
		b FormChangeLoopStart;

	IfSpecificBagItem: // Case 0x2
		ldrh r11, [r5,#0x6];
		mov r0, r11;
		bl IsUnstickyItemInBag;
		cmp r0, #0x1;
		bne IncrementLoopCounter
		ldrh r0, [r5,#0x2];
		ldrh r1, [r5,#0x4];
		mov r2, #0xF;
		bl LoopThruTeam;
		b IncrementLoopCounter;

    IfSpecificHeldItem:
		ldrh r10, [r5,#0x0];
		ldrh r11, [r5,#0x6];
        mov r6, #0x0;
        mov r7, #0x0;
        HeldItemLoopBegin:
            mov r0, r6;
            bl GetActiveTeamMember
            cmp r0, #0x0;
            beq HeldItemLoopEnd
            ldrb r2, [r0,#0x3E] // Held Item data bitfield
            tst r2, #0xE; // Is it sticky, unpaid, or in a shop?
            bne HeldItemLoopEnd;
            ldrh r1, [r0,#0x42] // Item ID
            cmp r11, r1;
		    bne HeldItemLoopEnd
            mov r0, #0x1;
            add r7, r0, lsl r6;
        HeldItemLoopEnd:
            cmp r6, #0x3;
            addlt r6, #0x1;
            blt HeldItemLoopBegin;
		ldrh r0, [r5,#0x2];
		ldrh r1, [r5,#0x4];
        mov r2, r7;
        bl LoopThruTeam;
		b IncrementLoopCounter;
   
    HPTestAbove:
        cmp r1, r2; // If nonzero: Current >= (Max >> X)
        b HPTestResume
    LevelTestAbove:
        cmp r1, r9; // If Nonzero: Test for level >= value 
        b LevelTestResume

    IfHPAndOrLevel: // Case 0x4
        ldrb r0, [r5, #0x6];
        mov r11, r0, lsr #0x4; // Bitfield!
        and r10, r0, #0xF
        ldrb r9, [r5, #0x7]
        mov r6, #0x0;
        mov r7, #0x0;
        HPLevelLoopBegin:
            mov r0, r6;
            bl GetActiveTeamMember
            cmp r0, #0x0;
            beq HPLevelLoopEnd
            tst r11, #0x1; // Require HP?
            beq SkipHPCheck
            ldrh r1, [r0, #0xE]; // Current HP
            ldrh r2, [r0, #0x10]; // Max HP
            lsr r2, r10; // Max HP >> num_to_shift_by
            tst r11, #0x4; // Do Current >= (Max >> X) and not (Max >> X ) >= Current 
            bne HPTestAbove
            cmp r2, r1; // If Zero: (Max >> X) >= Current
        HPTestResume:
            blt HPLevelLoopEnd // If NOT...
        SkipHPCheck:
            tst r11, #0x2; // Require Level?
            bne SkipLevelCheck
            ldrb r1, [r0, #0x2]
            tst r11, #0x8; // Test for ABOVE level?
            bne LevelTestAbove;
            cmp r9, r1; // If Zero: Test for value >= level
        LevelTestResume:
            blt HPLevelLoopEnd
        SkipLevelCheck:
            mov r0, #0x1;
            add r7, r0, lsl r6;
        HPLevelLoopEnd:
            cmp r6, #0x3;
            addlt r6, #0x1;
            blt HPLevelLoopBegin;
		ldrh r0, [r5,#0x2];
		ldrh r1, [r5,#0x4];
        mov r2, r7;
        bl LoopThruTeam;
        b IncrementLoopCounter;

    IfInHourOrMonthRange:
        mov r0, r5;
        bl IsInSpecifiedDateRange;
        cmp r0, #0x1;
        bne IncrementLoopCounter;
		ldrh r0, [r5,#0x2];
		ldrh r1, [r5,#0x4];
        mov r2, #0xF;
        bl LoopThruTeam
        b IncrementLoopCounter;

    IfScriptVariable:
        mov r0, r5;
        bl IsScriptVariableValid
        cmp r0, #0x1;
        bne IncrementLoopCounter;
		ldrh r0, [r5,#0x2];
		ldrh r1, [r5,#0x4];
        mov r2, #0xF;
        bl LoopThruTeam
        b IncrementLoopCounter;
		
	IfDeerlingScenMain:
		mov r0, r5;
		bl IsScenarioMainValid
		cmp r0, #0x1;
        bne IncrementLoopCounter;
		ldrh r0, [r5,#0x2];
		ldrh r1, [r5,#0x4];
        mov r2, #0xF;
        bl LoopThruTeam
        b IncrementLoopCounter;
		
	IfWishiwashiThreshold:
		ldrh r9, [r5, #0x6];
        WishiwashiLoopBegin:
            bl GetActiveTeamMember
            cmp r0, #0x0;
            bne WishiwashiLoopEnd
            ldrh r1, [r0, #0xE]; // Current HP
            ldrh r2, [r0, #0x10]; // Max HP
            lsr r2, #0x1; // Max HP >> num_to_shift_by
            cmp r1, r2; // Current >= (Max >> X)
            blt WishiwashiLoopEnd; // If NOT...
            ldrb r1, [r0, #0x2]
            cmp r1, r9;
            blt WishiwashiLoopEnd
            mov r0, #0x1;
            add r7, r0, lsl r6;
        WishiwashiLoopEnd:
            cmp r6, #0x3;
            addlt r6, #0x1;
            blt WishiwashiLoopBegin;
		ldrh r0, [r5,#0x2];
		ldrh r1, [r5,#0x4];
        mov r2, r7;
        bl LoopThruTeam;
        b IncrementLoopCounter;
		
	ReturnFormsChange: // Default
		pop {r1-r12,pc};


GroundRevertTeamMember:
		push {r2-r12,lr}
		// r1 is usually -1, but it seems to be a bitfield for whether to do the shaymin/giratina Forme change.
		// Naturally, it makes sense to extend this to other kinds of form changes. Form type 0xNN will correspond to bit 0xNN
		mov r10, r1; // 
		// r0 will be the team member slot for this function
		bl GetActiveTeamMember
		cmp r0, #0x0;
		beq ReturnFormsRevert;
		mov r4, r0;
		ldr r5, =LegendaryDataTable;
		ldrsh r6, [r4, #0xc];
	FormsRevertLoopStart:
		mov r11, #0x1;
		ldrsh r0, [r5, #0x0];
		cmp r0, #0xA;
		bge ReturnFormsRevert;
		lsl r11, r0;
		tst r10, r11;
		beq SkipFormRevert;
		ldrh r7, [r5, #0x2];
		ldrh r8, [r5, #0x4];
		cmp r6, r8;
		streqh r7, [r4,#0xc];
	SkipFormRevert:
		add r5, #0x10;
		b FormsRevertLoopStart;
	ReturnFormsRevert:
		pop {r2-r12,pc};


LoopThruTeam: // For Ground Mode!
		push {r3-r12,lr};
		mov r9, r2;
		mov r7, r0; // Current Form to search for
		mov r8, r1; // New Form to replace
		mov r5, #0x0; // Loop counter
	BeginTeamLoop:
		mov r0, r5;
		bl GetActiveTeamMember
		cmp r0, #0x0;
		beq InvalidSlot
		ldrsh r1, [r0, #0xc];
		cmp r1, r7;
		bne InvalidSlot;
        mov r3, #0x1;
		tst r9, r3, lsl r5;
		bne InvalidSlot;
		strh r8, [r0, #0xc];
	InvalidSlot:
		cmp r5, #0x3; // check if we're at 0x3 yet
		addlt r5, #0x1; // if 0x2 or less, +=1 and loop.
		blt BeginTeamLoop
		pop {r3-r12,pc};

ApplyFormStatBoosts:
		push {r3-r12,lr};
        cmp r2, #0x0; // Is this handling offensive stats?
        moveq r11, #0x8; // Physical ATK
        movne r11, #0xA; // Physical DEF
		cmp r1, #0x0; // Is the move physical?
        addne r11, #0x1; // Use Special Atk/Def
		mov r10, r0; // monster struct
		ldr r9, =LegendaryDataTable; // Set to -1 so that we actually begin at 0.
	BeginStatLoop:
		ldrsh r0, [r9, #0x4]; // Final Form ID
        cmp r0, #0x0;
        blt ApplyFormStatReturn;
        ldrh r1, [r10, #0x4]; // Apparent monster id;
        cmp r0, r1;
        addeq r11, #0x4;
        beq ApplyStats;
        ldrsh r0, [r9, #0x2]; // Initial Form ID
        cmp r0, r1;
        beq ApplyStats;
    EndStatLoop:
        add r9, #0x10;
        bne BeginStatLoop;
    ApplyStats:
        mov r0, #0x0;
        ldrsb r0, [r9,r11];
        pop {r3-r12,pc};
    ApplyFormStatReturn:
        mov r0, #0x0;
		pop {r3-r12,pc};


ValidateSpeciesFormsWrapper1:
        popne {r3-r11, pc}; // Original Instruction
		bl LarvestaItemCheckFull
        mov r0, r10;
        mov r1, #0x1; // Do SFX
ValidateSpeciesForms:
        push {r2-r12,lr};
        mov r8, r1;
        push {r8};
        mov r5, r0; // Entity Struct
        ldr r6, [r5, #0xB4]
        ldr r9, =LegendaryDataTable;
    FindMatchingSpeciesLoop:
        ldrh r0, [r9, #0x0];
        cmp r0, #0xA;
        bge ValidateReturn;
        ldrh r0, [r6, #0x4]; // apparent_species
        ldrh r4, [r9, #0x2]; // initial_species
        cmp r0, r4;
        moveq r11, #0x0; // Initial Species
        beq SpeciesFound;
        ldrh r4, [r9, #0x4]; // final_species
        cmp r0, r4;
        moveq r11, #0x1; // Final Species
        beq SpeciesFound;
	ResumeSpeciesLoop:
        add r9, r9, #0x10;
        b FindMatchingSpeciesLoop
    SpeciesFound:
        ldrh r0, [r9,#0x0]; // case_id
        cmp r0, #0xA;
		addls pc, pc, r0, lsl #0x2;
        b ValidateReturn;
		b ValidateIgnore; // 0x0: Should always be ignored
        b ValidateTrue; // 0x1: Should always be true
		b ValidateBagItem; // 0x2: True if specified item in bag
		b ValidateHeldItem; // 0x3: True if specified item is held
		b ValidateHPAndLevel; // 0x4: Depends on HP and Level
        b ValidateHourMonthRange; // 0x5: Depends on Hour Range or Month Value
        b ValidateScriptVariable; // 0x6
        // Unused for now.
        b ValidateReturn; // 0x7
        b ValidateDeerlingScenMain; // 0x8
        b ValidateWishiwashiHP; // 0x9
        // May be unnecessary
        b ValidateReturn; // 0xA
	ValidateIgnore:
		mov r0, r11;
		b ValidationCondition;
    ValidateFalse:
        mov r0, #0x0;
        b ValidationCondition;
    ValidateTrue:
        mov r0, #0x1;
        b ValidationCondition;
    ValidateBagItem:
        ldrh r0, [r9,#0x6];
        mov r1, #0xE;
		bl IsUnstickyItemInBag;
        b ValidationCondition;
    ValidateHeldItem:
        ldrb r0, [r6,#0x62];
        tst r0,#0xE
        movne r0, #0x0;
        ldreqh r0, [r6,#0x66];
        ldreqh r1, [r9,#0x6];
        cmpeq r0, r1;
        beq ValidateTrue;
        bne ValidateFalse;
    ValidateHPAndLevel:
        ldrb r0, [r9, #0x6];
        mov r10, r0, lsr #0x4; // Bitfield!
        and r7, r0, #0xF
        ldrb r4, [r9, #0x7]
        tst r10, #0x1; // Require HP?
        beq ValidSkipHPCheck;
        ldrh r1, [r6, #0x10]; // Current HP
        ldrh r2, [r6, #0x12]; // Max HP
        lsr r2, r7; // Max HP >> num_to_shift_by
        tst r10, #0x4; // Do Current >= (Max >> X) and not (Max >> X ) >= Current 
        bne ValidHPTestAbove;
        cmp r2, r1; // If Zero: (Max >> X) >= Current
    ValidHPTestResume:
        blt ValidateFalse;
    ValidSkipHPCheck:
        tst r8, #0x2; // Require Level?
        beq ValidateTrue; // If zero: Skip level check!
        ldrb r1, [r6, #0xA]
        tst r8, #0x8; // Above level?
        bne ValidLevelTestAbove;
        cmp r4, r1; // If zero: value >= level
    ValidLevelTestResume:
        blt ValidateFalse
        b ValidateTrue;

    ValidHPTestAbove:
        cmp r1, r2; // If nonzero: Current >= (Max >> X)
        b ValidHPTestResume
    ValidLevelTestAbove:
        cmp r1, r9; // If Nonzero: Test for level >= value 
        b ValidLevelTestResume


    ValidateHourMonthRange:
        mov r0, r9;
        bl IsInSpecifiedDateRange
        b ValidationCondition

    ValidateScriptVariable:
        mov r0, r9;
        bl IsScriptVariableValid
        b ValidationCondition
		
	ValidateDeerlingScenMain:
		mov r0, r9;
		bl IsScenarioMainValid
		b ValidationCondition
	
	ValidateWishiwashiHP:
		ldrh r0, [r9, #0x6]
		ldrb r1, [r6, #0xA]
		cmp r1, r0;
		movlt r0, #0x0;
		blt ValidationCondition;
		cmp r11, #0x1; // Is this School or Solo?
		moveq r7, #0x2; // School: Check for >= Quarter
		movne r7, #0x1; // Solo: Check for >= Half
		ldrh r1, [r6, #0x10]; // Current HP
        ldrh r2, [r6, #0x12]; // Max HP
        lsr r2, r7; // Max HP >> num_to_shift_by
		cmp r1, r2; // Current >= Max>>X
		movlt r0, #0x0;
		movge r0, #0x1;
		b ValidationCondition;
		
    ValidationCondition:
        cmp r0, r11; // Should be true for final species, false otherwise. If NOT, then the species must change!
        beq ResumeSpeciesLoop;
        cmp r11, #0x1;
        ldreqh r1, [r9,#0x2];
        ldrneh r1, [r9,#0x4];
        mov r0, r5;
        bl ChangeSpeciesData
        pop {r8};
        cmp r8, #0x1;
        bne ValidateReturnSkipr8;
        mov r0, r5;
        bl TransformationVFX
		push {r8};
        b ResumeSpeciesLoop;
    ValidateReturn:
        pop {r8};
    ValidateReturnSkipr8:
        pop {r2-r12,pc};



ChangeSpeciesData:
        push {r2-r12,lr}
        mov r4,r1
        mov r5,r0
        ldr r6, [r5,#0xB4];
        mov r1,#1
        mov r0,r4; // new_species_id
        bl LoadMonsterSprite; // 
        mov r0,r4; // new_species_id
        bl DungeonGetSpriteIndex; // 
        strh r0, [r5,#+0xA8]; // entity->sprite_index
        strh r4, [r6,#+0x4]; // monster->apparent_species
        mov r0,r5; // entity_ptr;
        bl DetermineMonsterShadow; // 
        mov r0,r5; // entity_ptr;
        bl GetIdleAnimationId;
        mov r1,r0
        mov r0,r5
        bl UnknownFunction2;
        mov r7, #0x0;
    TypeAbilityLoopStart:
        mov r0, r4;
        mov r1, r7;
        bl GetType
        add r8, r7, #0x5E;
        strb r0, [r6, r8];
        mov r0, r4;
        mov r1, r7;
        bl GetAbility
        add r8, r7, #0x60;
        strb r0, [r6, r8];
        add r7, #0x1;
        cmp r7, #0x2;
        blt TypeAbilityLoopStart;
        mov r0, #1
        strb r0, [r6,#0xFF] ; // Force the type to not change again
        mov r0, r6;
        pop {r2-r12,pc}

    
IsUnstickyItemInBag:
        push {r1-r12,lr};
        mov r4, r0;
        mov r5, #0x0;
        mov r6, r5;
    BeginUnstickyLoop:
        cmp r5, #0x32;
        mov r0, #0x0;
        bge UnstickyReturn;
        mov r0, r5;
        bl GetItemAtIdx
        ldrb r1, [r0, #0x0];
        tst r1, #0xE;
        addne r5, #0x1;
        bne BeginUnstickyLoop;
        ldrh r1, [r0, #0x4];
        cmp r1, r4;
        addne r5, #0x1;
        bne BeginUnstickyLoop;
        mov r0, #0x1;
    UnstickyReturn:
        pop {r1-r12,pc};

ValidateSpeciesFormsWrapper2:
    push {lr};
    mov r0, r7;
    bl UnknownFunction3;
    mov r0, r7;
    mov r1, #0x0; // DONT do SFX
    bl ValidateSpeciesForms;
	bl LarvestaItemCheckDuringDungeon;
    pop {pc};


IsInSpecifiedDateRange:
        push {r1-r12,lr}
        mov r5, r0;
        sub sp, sp, #0x1C;
        add r0, sp, #0x1C;
        bl GetSystemClock;
        mov r6, r0;
        // bit 0: TRUE for months!
        // MONTHS: Remainder of bits: bool for Jan-Dec
        // HOURS: remainder of byte 1: Min Hour
        // HOURS: byte 2: Max Hour
        ldrh r11, [r5, #0x6];
        tst r11, #0x1;
        beq TryMonths
        ldrb r11, [r5, #0x6]; // 
        ldrb r10, [r5, #0x7]; // Max Hour
        lsr r11, #0x1; // Min Hour
        ldr r0, [r6, #0xC]; // Current Hour
        cmp r0, r11; // CurrentHour >= MinHour?
        cmpge r10, r0; // MaxHour >= CurrentHour?
        movge r0, #0x1; // Is in range!
        movlt r0, #0x0; // Is NOT in range!
        b DateRangeReturn
    TryMonths:
        ldr r0, [r6, #0x14];
        mov r1, #0x1;
        tst r11, r1, lsl r0;
        moveq r0, #0x1;
        movne r0, #0x0;
    DateRangeReturn:
        add sp, sp, #0x1C;
        pop {r1-r12,pc}

IsScriptVariableValid:
        push {r1-r12,lr}
        mov r5, r0;
        ldrb r11, [r5, #0x6];
        ldrb r10, [r5, #0x7]; // Value/Bit Index
        tst r11, #0x1; // Is this a bitfield?
        lsr r11, #0x1; // Script Variable ID
        bne NormalVariableValue;
        mov r0, #0x0;
        mov r1, r11;
        mov r2, r10;
        bl LoadScriptVariableValueAtIndex
        pop {r1-r12,pc}
    NormalVariableValue:
        mov r0, #0x0;
        mov r1, r11;
        bl LoadScriptVariableValue;
        cmp r0, r10;
        moveq r0, #0x1;
        movne r0, #0x0;
        pop {r1-r12,pc}

IsScenarioMainValid:
        push {r1-r12,lr}
        mov r5, r0;
        mov r0, #0x0;
        mov r1, #0x3;
        mov r2, #0x0;
        bl LoadScriptVariableValueAtIndex
		and r0, #0x3;
		ldrb r3, [r5, #0x6];
		cmp r0, r3;
		moveq r0, #0x1;
		movne r0, #0x0;
        pop {r1-r12,pc}



// r0: pointer to entity struct
// r1: Species ID to assign
// r2: Use Transformation VFX?
CallableDungeonModeFormChange:
        push {r3-r12,lr}
        mov r11, r2;
        mov r10, r1;
        mov r9, r0;
        // the existing values in r0 and r1 are what this function needs
        bl ChangeSpeciesData
        cmp r11, #0x1;
        bne CallableDungeonReturn;
        mov r0, r9;
        bl TransformationVFX
    CallableDungeonReturn:
        pop {r3-r12,pc}

TransformUnitAdventureActor:
    strh r1, [r5,#0x0];
    mov r0, r5;
    push {r3-r12,lr}
    mov r11, r2; // Mentry_ID
    ldr r4, =TEAM_MEMBER_TABLE_PTR;
    ldr r4, [r4]
    mov r6, #0x9800
    add r6, #0x70;
    ldr r4, [r4, r6];
    ldrh r7, [r4, #0x0];
    mov r1, #0x4;
    cmp r7, r11;
    subeq r1, #0x1;
    ldrneh r7, [r4, #0x2];
    cmpne r7, r11;
    subeq r1, #0x1;
    ldrneh r7, [r4, #0x4];
    cmpne r7, r11;
    subeq r1, #0x1;
    ldrneh r7, [r4, #0x6];
    cmpne r7, r11;
    subeq r1, #0x1;
    popne {r3-r12, pc}
    bl TryTransformActor
    pop {r3-r12,pc}


TryTransformActor:
        push {r2-r12,lr};
        mov r8, r1;
        mov r10, r0; // team table: monster_id_16[1]
        ldr r9, =LegendaryDataTable;
        ldrh r7, [r10]; // Current monster ID
        cmp r7, #0x0;
        beq LoopThruActorsEnd;
        FindMatchingActorLoop:
            ldrh r0, [r9, #0x0];
            cmp r0, #0xA;
            bge LoopThruActorsEnd;
            ldrh r0, [r9, #0x2]; // initial_species
            cmp r7, r0;
            beq ActorSpeciesFound;
        ActorIncrementLoopCounter:
            add r9, r9, #0x10;
            b FindMatchingActorLoop
        ActorSpeciesFound:
            mov r0, r8;
            bl GetActiveTeamMember
            mov r5, r0;
		    ldrsh r0, [r9, #0x0];
		    cmp r0, #0xA;
		    addls pc, pc, r0, lsl #0x2;
		    b ActorIncrementLoopCounter;
            b ActorIncrementLoopCounter; // 0x0: Dont Change Form
		    b ActorIncrementLoopCounter; // 0x1: CheckSkyExclusiveDungeon
		    b ActorSpecificBagItem; // 0x2: If Specific Item In Bag
		    b ActorSpecificHeldItem; // 0x3: If Specific Item Held
		    b ActorHPAndOrLevel; // 0x4
		    b ActorInHourOrMonthRange; // 0x5
		    b ActorScriptVariable; // 0x6
            // Unused for now.
		    b ActorIncrementLoopCounter; // 0x7
		    b ActorDeerlingScenMain; // 0x8
		    b ActorWishiwashiThreshold; // 0x9
		    // I think this is redundant? gonna leave it alone just in case...
		    b ActorIncrementLoopCounter; // 0xA
	    
        ActorSpecificBagItem: // Case 0x2
		    ldrh r4, [r9,#0x6];
		    mov r0, r4;
		    bl IsUnstickyItemInBag;
		    cmp r0, #0x1;
            bne ActorIncrementLoopCounter
        ActuallyReplaceActor:
            ldrh r0, [r9, #0x4]; // Final ID
            strh r0, [r10];
            b ActorIncrementLoopCounter;

        ActorSpecificHeldItem:
            ldrh r4, [r9, #0x6]; // Required Item
            ldrb r2, [r5,#0x3E] // Held Item data bitfield
            tst r2, #0xE; // Is it sticky, unpaid, or in a shop?
            bne ActorIncrementLoopCounter;
            ldrh r1, [r5,#0x42] // Item ID
            cmp r4, r1;
            beq ActuallyReplaceActor;
            b ActorIncrementLoopCounter
            
        ActorHPAndOrLevel: // Case 0x4
            ldrb r0, [r9, #0x6];
            mov r4, r0, lsr #0x4; // Bitfield!
            and r3, r0, #0xF
            tst r4, #0x1; // Require HP?
            beq ActorSkipHPCheck
            ldrh r1, [r5, #0xE]; // Current HP
            ldrh r2, [r5, #0x10]; // Max HP
            lsr r2, r3; // Max HP >> num_to_shift_by
            tst r4, #0x4; // Do Current >= (Max >> X) and not (Max >> X ) >= Current 
            bne ActorHPTestAbove
            cmp r2, r1; // If Zero: (Max >> X) >= Current
        ActorHPTestResume:
            blt ActorIncrementLoopCounter
        ActorSkipHPCheck:
            tst r4, #0x2; // Require Level?
            bne ActuallyReplaceActor
            ldrb r2, [r9, #0x7]; // Required Level
            ldrb r1, [r5, #0x2]
            tst r4, #0x8; // Test for ABOVE level?
            bne ActorLevelTestAbove;
            cmp r2, r1; // If Zero: Test for value >= level
        ActorLevelTestResume:
            blt ActorIncrementLoopCounter
            b ActuallyReplaceActor;
        ActorHPTestAbove:
            cmp r1, r2; // If nonzero: Current >= (Max >> X)
            b ActorHPTestResume
        ActorLevelTestAbove:
            cmp r1, r2; // If Nonzero: Test for level >= value 
            b ActorLevelTestResume

        ActorInHourOrMonthRange:
            mov r0, r9;
            bl IsInSpecifiedDateRange;
            cmp r0, #0x1;
            bne ActorIncrementLoopCounter;
            b ActuallyReplaceActor;

        ActorScriptVariable:
            mov r0, r9;
            bl IsScriptVariableValid
            cmp r0, #0x1;
            bne ActorIncrementLoopCounter
            b ActuallyReplaceActor;
		ActorDeerlingScenMain:
			mov r0, r9;
			bl IsScenarioMainValid
            cmp r0, #0x1;
            bne ActorIncrementLoopCounter
            b ActuallyReplaceActor;
			
		ActorWishiwashiThreshold:
			ldrh r1, [r5, #0xE]; // Current HP
			ldrh r2, [r5, #0x10]; // Max HP
			lsr r2, #0x1; // Max HP >> num_to_shift_by
			cmp r1, r2; // Current >= (Max >> X)
			blt ActorIncrementLoopCounter; // If NOT...
			ldrb r1, [r0, #0x2]
			ldrb r0, [r9, #0x6]
			cmp r0, r1;
			blt ActorIncrementLoopCounter
			b ActuallyReplaceActor;
			
    LoopThruActorsEnd:
        pop {r2-r12,pc};

TransformMC1Actor:
    push {lr}
    strh r0, [r5, #0x0];
    bl GetMainCharacter1MemberIdx;
    cmp r0, #0;
    poplt {pc};
    mov r1, r0;
    mov r0, r5;
    bl TryTransformActor
    pop {pc};

TransformMC2Actor:
    push {lr}
    strh r0, [r5, #0x0];
    bl GetMainCharacter2MemberIdx;
    cmp r0, #0;
    poplt {pc};
    mov r1, r0;
    mov r0, r5;
    bl TryTransformActor
    pop {pc};

TransformMC3Actor:
    push {lr}
    strh r0, [r5, #0x0];
    bl GetMainCharacter3MemberIdx;
    cmp r0, #0;
    poplt {pc};
    mov r1, r0;
    mov r0, r5;
    bl TryTransformActor
    pop {pc};


TransformAppointActor:
    push {lr}
    strh r0, [r5, #0x0];
    bl GetAppointedMemberIdx;
    cmp r0, #0;
    poplt {pc};
    mov r1, r0;
    mov r0, r5;
    bl TryTransformActor
    pop {pc};


TransformHeroActor:
    push {lr}
    strh r0, [r5, #0x0];
    bl GetHeroMemberIdx;
    cmp r0, #0;
    poplt {pc};
    mov r1, r0;
    mov r0, r5;
    bl TryTransformActor
    pop {pc};

TransformPartnerActor:
    push {lr}
    strh r0, [r5, #0x0];
    bl GetPartnerMemberIdx;
    cmp r0, #0;
    poplt {pc};
    mov r1, r0;
    mov r0, r5;
    bl TryTransformActor
    pop {pc};

// The data-table: format "#0xAAAA, #0xBBBB, #0xCCCC, #0xDDDD"
// #0xAAAA: The case_id to take. 0x0000 for SkyExclusive Dungeon, 0x0001 for Item In Bag, 0x0002 for Held Item, 0x000A for "end of the table".
// #0xBBBB: The species ID of the mon to search for in hex.
// #0xCCCC: The species ID of the mon to transform into, in hex.
// #0xDDDD: Currently, the item_id of the relevant item. May be used for other things if more cases are added. 
// #0xEE, 0xFF, 0xGG, 0xHH: ATK, SPA, DEF, and SPDEF stages to increase/decrease by if the pokemon is in that form.
LegendaryDataTable:
    // Deoxys Attack
        .hword 0x0000
        .hword 0x01A3
        .hword 0x01A3
        .hword 0x0000
        .byte 0x02
        .byte 0x02
        .byte 0xFE
        .byte 0xFE
        .byte 0x02
        .byte 0x02
        .byte 0xFE
        .byte 0xFE
    // Deoxys Defense
        .hword 0x0000
        .hword 0x01A4
        .hword 0x01A4
        .hword 0x0000
        .byte 0xFE
        .byte 0xFE
        .byte 0x02
        .byte 0x02
        .byte 0xFE
        .byte 0xFE
        .byte 0x02
        .byte 0x02
    // Deoxys Speed
        .hword 0x0000
        .hword 0x01A5
        .hword 0x01A5
        .hword 0x0000
        .byte 0xFE
        .byte 0xFE
        .byte 0xFE
        .byte 0xFE
        .byte 0xFE
        .byte 0xFE
        .byte 0xFE
        .byte 0xFE
    // Shaymin-Sky
        .hword 0x0000
        .hword 0x0216
        .hword 0x0217
        .hword 0x0000
        .byte 0x00
        .byte 0x00
        .byte 0x00
        .byte 0x00
        .byte 0x00
        .byte 0x00
        .byte 0x00
        .byte 0x00
    // Giratina
        .hword 0x0001
        .hword 0x0211
        .hword 0x0218
        .hword 0x0000
        .byte 0xFE
        .byte 0xFE
        .byte 0x02
        .byte 0x02
        .byte 0x02
        .byte 0x02
        .byte 0xFE
        .byte 0xFE
	// Deerling-Summer
		.hword 0x0008
		.hword 0x0474  // Deerling-Spring
		.hword 0x0475  // Deerling-Summer
		.hword 0x0001; // Value % 4 = 1
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
	// Deerling-Autumn
		.hword 0x0008
		.hword 0x0474  // Deerling-Spring
		.hword 0x0476; // Deerling-Autumn
		.hword 0x0002; // Value % 4 = 2
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
	// Deerling-Winter
		.hword 0x0008
		.hword 0x0474  // Deerling-Spring
		.hword 0x0477; // Deerling-Winter
		.hword 0x0003; // Value % 4 = 3
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
	// Deerling-Summer
		.hword 0x0008
		.hword 0x021C  // Deerling-Spring
		.hword 0x021D  // Deerling-Summer
		.hword 0x0001; // Value % 4 = 1
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
	// Deerling-Autumn
		.hword 0x0008
		.hword 0x021C  // Deerling-Spring
		.hword 0x021E; // Deerling-Autumn
		.hword 0x0002; // Value % 4 = 2
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
	// Deerling-Winter
		.hword 0x0008
		.hword 0x021C  // Deerling-Spring
		.hword 0x021F; // Deerling-Winter
		.hword 0x0003; // Value % 4 = 3
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
		.byte 0x00;
	// Wishiwashi
		.hword 0x0009
		.hword 0x021A // Wishiwashi-Solo
		.hword 0x021B // Wishiwashi-School
		.hword 0x0014
		.byte 0x00
		.byte 0x00
		.byte 0x00
		.byte 0x00
		// Universal +5 to all stat stages. Why not? 
		.byte 0x05
		.byte 0x05
		.byte 0x05
		.byte 0x05
    // Important ending value!
		.hword 0x000A
		.hword 0xFFFF
		.hword 0xFFFF
		.hword 0xFFFF
		.hword 0xFFFF
		.hword 0xFFFF
		.hword 0xFFFF
	.pool
