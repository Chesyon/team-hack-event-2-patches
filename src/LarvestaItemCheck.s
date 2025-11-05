.global LarvestaItemCheckFull


LarvestaItemCheckDuringDungeon:
    push {lr}

    // hook this where you intended to

    mov r0, #1360
    mov r1, #15 // replace with actual dungeon ID!
    bl LarvestaItemCheckFull
    cmp r0, #1
    popeq {pc}

    bl GetLeader
    mov r1, =IdSayWhyDoTheGoodDieYoungButEvenIfHesYoungLarvestaWouldStillGoToHell
    bl LogMessageWithPopup

    bl LarvestaIsDead
    pop {pc}


LarvestaItemCheckFull:
    // r0: ID of the item to search for
    // r1: ID of the dungeon
    // return: whether or not the larvesta item could be found in the bag, dungeon, or entity's held items                '

    push {r2-r12,lr}
    mov r4, r0
    mov r5, r1
    mov r0, r1
    bl CheckDungeonId
    cmp r0, #1;
    beq LarvestaItemCheckFullReturn;
    mov r0, r4
    bl LarvestaItemCheckEntities
    cmp r0, #1;
    beq LarvestaItemCheckFullReturn;
    mov r0, r4
    bl IsItemInBag;
    cmp r0, #1;
    beq LarvestaItemCheckFullReturn;
    mov r0, #0
    pop {r1-r12,pc}
LarvestaItemCheckFullReturn:
    mov r0, #1
    pop {r2-r12,pc}

LarvestaIsDead:
    push {r0-r12,lr};
    bl GetLeader
    mov r1, r0;
    mov r2, #0;
    mov r3, #0;
    bl DoMoveEscape
    pop {r0-r12,pc}

LarvestaItemCheckEntities:
    // r0: item to search for
    // return: whether or not the item was found
    push {r1-r12,lr}
    ldr r11, =DUNGEON_PTR
    ldr r11, [r11]
    add r10, r11, #0x12C00;
    add r10, #0x1CC; // entity_table
    mov r9, r0; // Larvesta Item_ID
    mov r8, #0; // False until item found
    mov r7, #0; // Loop counter
LarvestaItemCheckLoopStart:
    ldr r0, [r10, #0x0]; enum entity_type
    cmp r0, #4;
    bge LarvestaItemCheckLoopEnd;
    cmp r0, #2;
    movgt r6, #0;
    ldrgt r1, [r10, #0xB4];
    bgt LarvestaItemCheckItemStruct; // Floor Item
    cmplt r0, #0;
    beq LarvestaItemCheckLoopEnd; // Trap or Nothing!
    // Pokemon!
    ldr r6, [r10, #0xB4]; // monster_ptr
    add r1, r6, #0x62; held_item item struct!
    b LarvestaItemCheckItemStruct
LarvestaItemCheckLoopEnd:
    add r7, #1;
    add r10, #0xB8; // size of an entity struct!
    cmp r7, #150; 
    blt LarvestaItemCheckLoopStart
    mov r0, r8;
pop {r1-r12,pc}

LarvestaItemCheckItemStruct:
    ldrb r0, [r1, #0x0];
    tst r0, #1; // is r0 & 1 == 0 ?
    beq LarvestaItemCheckLoopEnd
    ldrh r0, [r1, #0x4];
    cmp r0, r9
    moveq r8, #1;
    cmpne r6, #0;
    bne LarvestaItemCheckLoopEnd;
    sub sp, #0x4;
    mov r0, #0;
    str r0, [sp, #0x0];
    mov r0, r10; // user is target
    mov r1, r10; // the target of the move
    mov r2, #0; // Go away Special Episode 3
    mov r3, #0; // Sawk used Rock Smash
    bl TryInflictBurnStatus
    add sp, #0x4;
    b LarvestaItemCheckLoopEnd;

LarvestaItemCheckStartNewFloor:

    // hook this in 0x22df998, ldr r0, =DUNGEON_PTR is the instruction that would be replaced

    push {lr}

    mov r0, #1360
    bl IsItemInBag
    cmp r0, #1
    ldrne r0, =DUNGEON_PTR
    popne pc

    bl GetLeader
    mov r1, =WhyCantWeJustLeaveHimBehind
    bl LogMessageWithPopup
    
    bl LarvestaIsDead

    ldr r0, =DUNGEON_PTR
    pop {pc}

// r0: the dungeon ID to search for
// return: if the dungeon IDs match
CheckDungeonId:
    push {r14}
    ldr r2, =DUNGEON_PTR
    ldr r2, [r2]
    ldr r1, =#0x700
    add r2, r2, r1
    ldrb r1, [r2, #0x48]
    cmp r1, r0
    moveq r0, #1
    movne r0, #0
    pop {r15}

GetWishiwashiForm:
    ; no params
    ; return: 1 if wishiwashi is in its school form, 0 if wishiwashi is in its solo form, or 2 if wishiwashi could not be found
    push {r4-r12, r14}
	ldr   r8, =DUNGEON_PTR
	mov   r5, #0
	
	FindWishiwashi:
	ldr   r0, [r8, #0x0]
	add   r0, r0, r5, lsl 2h
	add   r0, r0, #0x12000
	ldr   r6, [r0, #0xB28]

	mov   r0, r6
	bl    EntityIsValid
	cmp   r0, #1
	bne   EndLoop

    ldr   r0, [r6, #0xb4]
    ldr   r2, =#538
    ldr   r3, =#1138
    ldrh  r1, [r0, #0x2] // get the targets ID
    cmp   r1, r2
    cmpne r1, r3
    bne   EndLoop
    add   r2, #1
    add   r3, #1
    ldrh  r1, [r0, #0x4] // get the targets apparent ID
    cmp   r1, r2
    cmpne r1, r3
    moveq r0, #1
    popeq {r4-r12, r15}
    mov r0, #0
    pop {r4-r12, r15}


    EndLoop:
    add r5, #1
    cmp r5, #4
    bne FindWishiwashi
    mov r0, #2
    pop {r4-r12, r15}
    

.pool
    IdSayWhyDoTheGoodDieYoungButEvenIfHesYoungLarvestaWouldStillGoToHell:
    .asciiz "Oh no! [CS:Z]Larvesta[CR] was defeated!"
    WhyCantWeJustLeaveHimBehind:
    .asciiz "...Huh? Where did [CS:Z]Larvesta[CR] go?[C][CS:Z]Larvesta[CR] used the [M:I1][CS:G]Escape Orb[CR]!"