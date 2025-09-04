/* Not gonna troubleshoot why this wont read custom_EU.ld. */


CustomFormsChange:
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
		// Unused for now.
		b IfHPAndOrLevel; // 0x4
		b ReturnFormsChange; // 0x5
		b ReturnFormsChange; // 0x6
		b ReturnFormsChange; // 0x7
		b ReturnFormsChange; // 0x8
		b IfBurtPermitsIt; // 0x9
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
            bl GetActiveTeamMember
            cmp r0, #0x0;
            bne HeldItemLoopEnd
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

    IfHPAndOrLevel: // Case 0x4
        ldrb r0, [r5, #0x6];
        mov r11, r0, lsr #0x4; // Bitfield!
        and r10, r0, #0xF
        ldrb r9, [r5, #0x7]
        /* 
		 bit 0: RequireHP
         bit 1: RequireLevel
         bit 2: Current >= Max
         bit 3: OncePerFloor (Ignore for this Part!)
		*/
        mov r6, #0x0;
        mov r7, #0x0;
        HPLevelLoopBegin:
            bl GetActiveTeamMember
            cmp r0, #0x0;
            bne HPLevelLoopEnd
            tst r11, #0x1; // Require HP?
            bne SkipHPCheck
            ldrh r1, [r0, #0xE]; // Current HP
            ldrh r2, [r0, #0x10]; // Max HP
            lsr r2, r10; // Max HP >> num_to_shift_by
            tst r11, #0x4; // Do Current >= (Max >> X) and not (Max >> X ) >= Current 
            cmpeq r1, r2; // Current >= (Max >> X)
            cmpne r2, r1; // (Max >> X) >= Current
            blt HPLevelLoopEnd // If NOT...
        SkipHPCheck:
            tst r11, #0x2; // Require Level?
            bne SkipLevelCheck
            ldrb r1, [r0, #0x2]
            cmp r1, r9;
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
	IfBurtPermitsIt:
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


CustomFormsRevertTeamMember:
		push {r2-r12,lr}
		// r1 is usually -1, but it seems to be a bitfield for whether to do the shaymin/giratina Forme change.
		// Naturally, it makes sense to extend this to other kinds of form changes. Form type 0xNN will correspond to bit 0xNN
		mov r10, r1; 
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
        ldrh r4, [r9, #0x2]; //  initial_species
        cmp r0, r4;
        moveq r11, #0x0; // Initial Species
        beq SpeciesFound;
        ldrh r4, [r9, #0x4]; // final_species
        cmp r0, r4;
        moveq r11, #0x1; // Final Species
        beq SpeciesFound;
        add r9, r9, #0x10;
        b FindMatchingSpeciesLoop
    SpeciesFound:
        ldrh r0, [r9,#0x0]; // case_id
        cmp r0, #0xA;
		addls pc, pc, r0, lsl #0x2;
        b ValidateReturn;
		b ValidateFalse; // 0x0: Should always be false
        b ValidateTrue; // 0x1: Should always be true
		b ValidateBagItem; // 0x2: True if specified item in bag
		b ValidateHeldItem; // 0x3: True if specified item is held
		b ValidateHPAndLevel; // 0x4: Depends on HP and Level
        b ValidateReturn; // 0x5
        b ValidateReturn; // 0x6
        b ValidateReturn; // 0x7
        b ValidateReturn; // 0x8
        b ValidateWishiwashiHP; // 0x9
        // May be unnecessary
        b ValidateReturn; // 0xA
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
        moveq r0, #1;
        movne r0, #0;
    ValidateHPAndLevel:
        ldrb r0, [r9, #0x6];
        mov r10, r0, lsr #0x4; // Bitfield!
        and r7, r0, #0xF
        /* 
		 bit 0: RequireHP
         bit 1: RequireLevel
         bit 2: Current >= Max
         bit 3: OncePerFloor (Ignore for this Part!)
		*/
        tst r10, #0x1; // Require HP?
        bne ValidSkipHPCheck;
        ldrh r1, [r6, #0x10]; // Current HP
        ldrh r2, [r6, #0x12]; // Max HP
        lsr r2, r7; // Max HP >> num_to_shift_by
        tst r10, #0x4; // Do Current >= (Max >> X) and not (Max >> X ) >= Current 
        cmpeq r1, r2; // Current >= (Max >> X)
        cmpne r2, r1; // (Max >> X) >= Current
        movlt r0, #0x0; // If NOT...
        blt ValidationCondition;
    ValidSkipHPCheck:
        tst r8, #0x2; // Require Level?
        bne ApplyStats
        ldrb r1, [r6, #0xA]
        cmp r1, r4;
        movlt r0, #0x0;
        blt ValidationCondition
        tst r10,#0x8; // Is OncePerFloor?
        bne SkipOncePerFloor;
        pop {r8};
        cmp r8, #0x0; // Is This Happening At Start Of Floor?
        push {r8};
        movne r0, #0x0; // Go to Base Form!
        bne ValidationCondition;
    SkipOncePerFloor:
        mov r0, #0x1;
        b ValidationCondition;

	ValidateWishiwashiHP:
		ldrh r0, [r9, #0x6]
		ldrb r1, [r6, #0xA]
		cmp r0, r1;
		cmp r11, #0x1; // Is this School or Solo?
		moveq r7, #0x2; // School: Check for >= Quarter
		movne r7, #0x1; // Solo: Check for >= Half
		ldrh r1, [r6, #0x10]; // Current HP
        ldrh r2, [r6, #0x12]; // Max HP
        lsr r2, r7; // Max HP >> num_to_shift_by
		cmp r1, r2; // Current >= Max>>X
		movne r0, #0x0;
		moveq r0, #0x1;
		b ValidationCondition;
		
    ValidationCondition:
        cmp r0, r11; // Should be true for final species, false otherwise. If NOT, then the species must change!
        beq ValidateReturn;
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
        b ValidateReturnSkipr8;
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
        bl LoadMonsterSprite; 
        mov r0,r4; // new_species_id
        bl DungeonGetSpriteIndex; 
        strh r0, [r5,#+0xA8]; // entity->sprite_index
        strh r4, [r6,#+0x4]; // monster->apparent_species
        mov r0,r5; // entity_ptr;
        bl DetermineMonsterShadow; 
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
        strb r0, [r6,#0xFF]; // Force the type to not change again
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
    pop {pc};
	
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
	// Wishiwashi
		.hword 0x0009
		// TODO: Actually make this the ID of Wishiwashi-Solo
		.hword 0x0218
		// TODO: Actually make this the ID of Wishiwashi-School
		.hword 0x0219
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