.align
.global GetNbPuzzleFloorsEntered
.global GetNbOrbsObtained
.global GetNbOrbsGiven
.global ReadBagSwapByte
.global IncrementNbPuzzleFloorsEntered
.global IncrementNbOrbsObtained
.global IncrementNbOrbsGiven
.global WriteBagSwapByte
.global RemoveOneOrbFromBags
.global GetRosyTurnCount





.align
// r0 = level 1 ground monster about to be leveled up into an escort client
// r1 = level the ground monster should be leveled to
// r2 = do
MakeThePresidentBuff:
	strb r12, [r3, #0x1D]
	push {r2-r12,lr}
	sub sp, #0x4;
	mov r11, r1; // int level
	mov r10, r0; // struct ground_monster

	mov r2, #1;
	str r2, [sp,#0x0];
	mov r0, #0;
	mov r1, #2;
	mov r2, sp;
	mov r3, #87;
	bl GetMissionByTypeAndDungeon
	ldrh r2, =#502;
	cmp r0, #-1;
	beq SkipClientAdjustments;
	ldrh r0, [r10, #0x4];
	cmp r0, r2;
		moveq r11, #50;
		ldreq r0, [r10, #0xC]; // All Stats Except HP
		ldreq r1, =#0x201B201B;
		addeq r0, r1;
		streq r0, [r10, #0xC];
		ldreqh r0, [r10, #0xA];
		addeq r0, #43;
		streqh r0, [r10, #0xA];
SkipClientAdjustments:
	mov r1, r11;
	mov r0, r10;
	add sp, #0x4;
pop {r2-r12, pc}

.pool
ModifiedExploreNewDungeonCheck:
   push {r14}
   cmp r1, #0x3;
   ldreqb r0, [r4, #0x2]
   cmp r0, #0x3;
   popeq {r15}
   cmp r1, #0x2;
   ldreqb r0, [r4, #0x2]
   cmp r0, #0x1;
   ldreqh r0, [r4, #0xE]
   ldr r1, =#0x1F6;
   cmpeq r0, r1;
   ldreqh r0, [r4, #0x10]
   ldreq r1, =#0x429;
   pop {r15}


ModifiedExploreNewDungeonCheckTheSecond:
   push {r7, r14}
   mov r7, r0;
   ldreqb r0, [r4, #0x2]
   cmp r0, #0x1;
   ldreqh r0, [r4, #0xE]
   ldr r1, =#0x1F6;
   cmpeq r0, r1;
   ldreqh r0, [r4, #0x10]
   ldreq r1, =#0x429;
   movne r0, r7
   moveq r0, #0;
   cmp r0, #1;
   pop {r7, r15}


UpdatedSleepCheck:
	// Runs the same code, except it actually does the comparison now. This will prevent sleeping mons from remaining asleep...
	push {r1-r12,lr};
	bl CheckIfSleeping
	cmp r0, #1;
	pop {r1-r12,pc}

RevertSwappedParty:
	push {r0-r8,lr};
	// We need to revert here, because immediately after is when the team is allocated their monster sprites!
	bl RevertPuzzleBagAndTeam
	mov r9, #0x0;
	pop {r0-r8,pc};

TryPreventOrbFromBeingTrashed:
	push {r0,r3,r4,lr}; // r4 is being pushed only because it saves an instruction lmao!
	add r3, sp, #0x480
	ldr r0, =#353;
	ldrsh r2, [r2, #0x4e]
	cmp r0, r2;
	movne r2, #0;
	popne {r0,r3,r4,pc}
	orr r1, r1, #0x200;
	mov r2, r3;
	ldr r0, =TRASH_ITEM_MENU_OPTION_BYTES;
	str r0, [r2, #0x60]
	pop {r0,r3,r4,pc};

TRASH_ITEM_MENU_OPTION_BYTES:
	.byte 0x0;
	.byte 0x3;
	.byte 0x0;
	.byte 0x0;
	.word 0x00000000;

.align
InitRosyFloorFields:
	push {r0-r12,lr}
	ldr r9, =DUNGEON_PTR;
	ldr r9, [r9];
	add r9, #0xEE00;
	mov r0, #0;
	strb r0, [r9,#0xE5]
	strb r0, [r9,#0xE6]
	strb r0, [r9,#0xE7]
	pop {r0-r12,pc}


AttemptActivateWeatherBecauseRosy:
	push {r2-r12,lr}
	mov r11, r0;
	mov r10, r1;
	bl GetFloorRosiness
	mov r4, #0;
	bl GetRosyItemCount
	cmp r0, #0;
	orrgt r4, #1;
	bl GetRosyTurnCount
	cmp r0, #0;
	orrgt r4, #1;
	bl GetFloorRosiness;
	cmp r0, r4;
	popeq {r2-r12,pc}
	mov r0, r11;
	mov r1, r10;
	bl TryActivateWeather
	pop {r2-r12,pc}

SetRosyItemCount:
	push {r1-r12,lr}
	ldr r9, =DUNGEON_PTR;
	ldr r9, [r9];
	add r9, #0xEE00;
	strb r0, [r9,#0xE5]
	pop {r1-r12,pc}

GetRosyItemCount:
	push {r1-r12,lr}
	ldr r9, =DUNGEON_PTR;
	ldr r9, [r9];
	add r9, #0xEE00;
	ldrb r0, [r9,#0xE5]
	pop {r1-r12,pc}

IncrementRosyItemCount:
	push {r0, lr}
	bl GetRosyItemCount
	cmp r0, #0xFF;
	addlt r0, #1;
	bl SetRosyItemCount
	pop {r0, pc}

DecrementRosyItemCount:
	push {r0, lr}
	bl GetRosyItemCount
	cmp r0, #0x0;
	subgt r0, #1;
	bl SetRosyItemCount
	pop {r0, pc}

SetRosyTurnCount:
	push {r1-r12,lr}
	ldr r9, =DUNGEON_PTR;
	ldr r9, [r9];
	add r9, #0xEE00;
	strb r0, [r9,#0xE6]
	pop {r1-r12,pc}

GetRosyTurnCount:
	push {r1-r12,lr}
	ldr r9, =DUNGEON_PTR;
	ldr r9, [r9];
	add r9, #0xEE00;
	ldrb r0, [r9,#0xE6]
	pop {r1-r12,pc}

DecrementRosyTurnCount:
	push {r1-r12,lr}
	bl GetRosyTurnCount;
	cmp r0, #0;
	subgt r0, #1;
	bl SetRosyTurnCount;
	pop {r1-r12, pc}

GetFloorRosiness:
	push {r1-r12,lr}
	ldr r9, =DUNGEON_PTR;
	ldr r9, [r9];
	add r9, #0xEE00;
	ldrb r0, [r9,#0xE7]
	pop {r1-r12,pc}

SetFloorRosiness:
	push {r1-r12,lr}
	ldr r9, =DUNGEON_PTR;
	ldr r9, [r9];
	add r9, #0xEE00;
	strb r0, [r9,#0xE7]
	pop {r1-r12,pc}

ToggleRosyMusic:
	push {r1-r12,lr}
	mov r11, r0;
	cmp r11, #2;
	movne r0, #212;
	bne SetRosyMusic;
	ldr r10, =DUNGEON_PTR
	ldr r10, [r10]
	add r10, #0x4000;
	ldrh r0, [r10, #0xD6]; // dungeon_generation_struct->music_table_idx
	bl MusicTableIdxToMusicId;
	SetRosyMusic:
		bl ChangeDungeonMusic;
	pop {r1-r12,pc}
.pool
UpdateAndRetrieveFloorRosiness:
	push {r1-r12,lr}
	mov r10, r0;
	mov r4, #0;
	bl GetRosyItemCount
	cmp r0, #0;
	orrgt r4, #1;
	bl GetRosyTurnCount
	cmp r0, #0;
	orrgt r4, #1;
	bl GetFloorRosiness;
	cmp r0, r4;
	moveq r9, r0;
	addne r9, r4, #2
	beq FloorRosinessReturn;
	mov r0, r9;
	bl ToggleRosyMusic;
	ldr r0, =#2062
	cmp r9, #2;
	addeq r0, #1;
	bl PlaySeByIdVolumeWrapper
	mov r5, #0;
	RosySFXInLoop:
		mov r0, #0;
		bl AdvanceFrame
		add r5, #1;
		cmp r5, #0x30;
		blt RosySFXInLoop;
	and r0, r9, #1;
	bl SetFloorRosiness;
	FloorRosinessReturn:
		tst r9, #1;
		moveq r0, r10; // if 0 or 2, weather_id is NOT rosy!
		movne r0, #8; // If 1 or 3, weather_id is rosy!
		pop {r1-r12,pc}; // 0 or 1, exit!

CheckFloorRosiness:
		push {r1-r12,lr};
		// r0 = true weather_id
		bl UpdateAndRetrieveFloorRosiness
		bl GetWeatherColorTable;
		pop {r1-r12,pc};


MaybeDestroyRosyItem:
	mov r4, r0; // Original Instruction
	push {r1-r12,lr};
	ldrsh r0, [r0, #0x4];
	ldr r7, =THE_ORB_ITEM_ID
	cmp r0, r7;
	bne NotDestroyRosyItem;
	bl DecrementRosyItemCount;
	mov r0, #0;
	mov r1, #1;
	bl AttemptActivateWeatherBecauseRosy;
	mov r0, r7;
	NotDestroyRosyItem:
		pop {r1-r12,pc};

MaybeSpawnRosyItem:
	strh r0, [r1, #0x4]; // original instruction;
	push {r1-r12,lr};
	ldr r1, =THE_ORB_ITEM_ID
	cmp r0, r1;
	bne NotSpawnRosyItem;
	bl IncrementRosyItemCount;
	mov r0, #0;
	mov r1, #1;
	bl AttemptActivateWeatherBecauseRosy;
	NotSpawnRosyItem:
		pop {r1-r12,pc};

.pool

CheckClearedPuzzleFloor:
	CheckClearedPuzzleFloorStart:	
		push {lr}
		push {r1-r12};
		mov r11, r0;
		ldr r1, =#0xE43
		cmp r0, r1;
		bne CheckClearedPuzzleFloorOriginal;
		bl DecrementRosyItemCount; // For visual effect, remove the rosy effect early by decrementing early.
		mov r0, #0;
		mov r1, #1;
		bl AttemptActivateWeatherBecauseRosy; // Should remove the rosy filter from the floor, if no others are present!
		// Apparently incrementing again causes a desync. Maybe Despawning the item just fails if its a mission item?
		bl GetNbOrbsObtained;
		cmp r0, #0x0;
		bne CheckClearedPuzzleFloorIncrement;
		bl GetLeader
		ldr r1, =LARVESTA_PUZZLE_STRING_C1;
		mov r2, #2; // Happy Portrait
		bl DungeonPortraitStringSpecies;

	CheckClearedPuzzleFloorIncrement:
		mov r0, r11;
		pop {r1-r12}
		ldr r6, =#0xE24; // Original Instruction
		ldr r0, =MEMO_MISSION_COMPLETE_STRING_1
		pop {pc};
	CheckClearedPuzzleFloorOriginal:
		mov r0, r11;
		pop {r1-r12}
		ldr r6, =#0xE24; // Original Instruction
		pop {pc};

DecrementRosyTurnsWrapper:
	push {r1-r12,lr}
	bl DecrementRosyTurnCount
	mov r0, #0;
	mov r1, #1;
	bl GetRosyTurnCount
	cmp r0, #0;
	bne SkipActivatingWeather1;
	bl AttemptActivateWeatherBecauseRosy;
	SkipActivatingWeather1:
	bl GetLeader; // Original Instruction
	pop {r1-r12,pc}
	
ReduceWindByMoreHook:
	ldrsh r1,[r0,#0x84]; // original instruction
	push {r0,r2-r12,lr};
	mov r11, r1;
	bl GetFloorRosiness;
	cmp r0, #1;
	mov r1, r11;
	bne DontReduceWindMore;
	cmp r1, #2;
	movle r1, #1;
	subgt r1, #2;
DontReduceWindMore:
	pop {r0,r2-r12,pc}

AdvanceNFrames:
	push {r1-r12,lr}
	mov r11, r0;
	mov r5, #0;
	AdvanceFrameLoop:
		mov r0, #0;
		bl AdvanceFrame
		add r5, #1;
		cmp r5, r11;
	blt AdvanceFrameLoop;
	pop {r1-r12,pc}

PlayRosyWindMessages:
	mov r1, r6;
	mov r5, r2; // original instruction
	push {r0,r3-r12,lr}
	mov r11, r2; // wind "turn_limit_warning_tracker"
	mov r10, r1; // entity* 
	bl GetFloorRosiness;
	cmp r0, #1;
	popne {r0,r3-r12,pc}
	ldr r1, =ROSY_WIND_250;
	add r1, r11;
	mov r0, r10;
	bl LogMessageByIdWithPopupCheckUser;
	bl RetrieveCurrentBGM;
	mov r9, r0; // music_id to return to!
	mov r0, #0;
	bl ChangeDungeonMusic
	mov r0, #60;
	bl AdvanceNFrames
	add r6, r11, #1;
	ContinueSwirlAnimation:
		mov r0, r10;
		mov r1, #205;
		bl PlayEffectAnimationEntityStandard
		mov r0, #10;
		bl AdvanceNFrames
		sub r6, #1;
		cmp r6, #0;
		bgt ContinueSwirlAnimation;
	mov r0, r9;
	bl ChangeDungeonMusic
	RosyWindMessagesReturn:
		pop {r0,r3-r12,lr};
		add sp, sp, #0x8;
		pop {r4-r6,pc};

SubRosyDeathMessage:
	push {lr}
	push {r0,r2}
	bl GetFloorRosiness;
	cmp r0, #1;
	ldreq r1, =#563;
	pop {r0,r2};
	bl HandleFaint
	pop {pc}


PrintPuzzleEntryDialogue:
	PrintPuzzleEntryDialogueStart:
		push {r0-r12, lr}
		mov r0, #0xC;
		mov r1, #0x2;
		bl IsCurrentMissionTypeExact; // Is it a Treasure Memo subtype 2 (Fleeing Item-Bearing Outlaw?)
		mov r9, r0; // r9: IsOutlawMission?
		cmp r0, #1;
		ldr r0, =#3588;
		addeq r0, #1;
		bl DungeonPrintTextString;
		mov r0, #0xC;
		mov r1, #0x1;
		bl IsCurrentMissionTypeExact; // Is it a Treasure Memo subtype 1 (Find Orb On Floor?)
		orr r9, r0; // r9: IsLarvestaStrong?
		bl GetNbPuzzleFloorsEntered;
		cmp r0, #0x3;
		addls pc, pc, r0, lsl #0x2;
		b EnteredManyTimes
		b FirstTimeEntered
		b SecondTimeEntered
		b ThirdTimeEntered
	EnteredManyTimes:
		bl GetLeader
		ldr r1, =LARVESTA_PUZZLE_STRING_GENERIC;
		mov r2, #0; // Normal
		bl DungeonPortraitStringSpecies;
		b PrintPuzzleEntryDialogueReturn;
	FirstTimeEntered:
		bl GetLeader
		mov r6, r0;
		ldr r1, =LARVESTA_PUZZLE_STRING_1_1;
		mov r2, #0; // Normal
		bl DungeonPortraitStringSpecies;
		mov r0, r6;
		ldr r1, =LARVESTA_PUZZLE_STRING_1_2;
		mov r2, #12; // Surprised
		bl DungeonPortraitStringSpecies;
		mov r0, r6;
		cmp r9, #1;

		ldreq r1, =LARVESTA_PUZZLE_STRING_1_3;
		moveq r2, #1; // Happy

		ldrne r1, =LARVESTA_PUZZLE_STRING_1_4;
		movne r2, #3; // Angry
		bl DungeonPortraitStringSpecies;
		// Ugh, I dont like this.... 
		// All I have to do is grab the [M:T6][CS:I]Orb[CR], and get out.
		// How hard could it be, right?
		mov r0, r6;
		ldr r1, =LARVESTA_PUZZLE_STRING_1_5;
		mov r2, #4; // Worried
		bl DungeonPortraitStringSpecies;
		b PrintPuzzleEntryDialogueReturn;
	SecondTimeEntered:
		bl GetLeader
		ldr r1, =LARVESTA_PUZZLE_STRING_2;
		mov r2, #16; // Sigh
		bl DungeonPortraitStringSpecies;
		b PrintPuzzleEntryDialogueReturn;
	ThirdTimeEntered:
		bl GetLeader
		ldr r1, =LARVESTA_PUZZLE_STRING_3;
		mov r2, #16; // Sigh
		bl DungeonPortraitStringSpecies;
		b PrintPuzzleEntryDialogueReturn;		
	PrintPuzzleEntryDialogueReturn:
		bl IncrementNbPuzzleFloorsEntered;
		pop {r0-r12, pc}

// r0: Monster Pointer
// r1: Text String ID
DungeonPortraitStringSpecies:
	push {r3-r12,lr}
	sub sp,sp,#0x30;
	mov r6,r0
	ldr r4, [r6, #0xb4]
	ldrh r4, [r4, #0x2]
	mov r5,r1;
	mov r0,sp
	mov r1,r4
	bl InitPortraitDungeon
	mov r0,sp
	mov r1,#0x12
	bl SetPortraitLayout
	mov r1,r4
	mov r0,#0x1
	bl SetMessageLogPreprocessorArgsStringToName
	mov r0,sp
	mov r1,r5;
	mov r2,#0x1
	bl DisplayMessage
	add sp,sp,#0x30;
	pop {r3-r12,pc}


// r0: Text String ID
DungeonPrintTextString:
	push {r1-r12,lr}	
	mov r1, r0;
	mov r0,#0x0
	mov r2,#0x1
	bl DisplayMessage
	pop {r1-r12,pc}

GenerateItemWithProperFlags:
	push {r4-r12,lr};
	mov r5, r0;
	mov r4, r1;
	bl GenerateItem;
	ldr r1, =THE_ORB_ITEM_ID;
	cmp r4, r1;
	moveq r2, #0x89;
	streqb r2,[r5, #0];
	pop {r4-r12,pc}


IncrementNbPuzzleFloorsEntered:
	push {r0-r12,lr};
	ldr r1, =ADVENTURE_LOG_PTR;
	ldr r1, [r1]
	ldrb r0, [r1, #0x20];
	cmp r0, #0xFF;
	addlt r0, #1;
	strb r0, [r1, #0x20]
	pop {r0-r12,pc}

IncrementNbOrbsObtained:
	push {r0-r12,lr};
	ldr r1, =ADVENTURE_LOG_PTR
	ldr r1, [r1];
	ldrb r0, [r1, #0x21];
	cmp r0, #0xFF;
	addlt r0, #1;
	strb r0, [r1, #0x21]
	pop {r0-r12,pc}

IncrementNbOrbsGiven:
	push {r0-r12,lr};
	ldr r1, =ADVENTURE_LOG_PTR;
	ldr r1, [r1]
	ldrb r0, [r1, #0x22];
	cmp r0, #0xFF;
	addlt r0, #1;
	strb r0, [r1, #0x22]
	pop {r0-r12,pc}


GetNbPuzzleFloorsEntered:
	push {r1-r12,lr}
	ldr r1, =ADVENTURE_LOG_PTR;
	ldr r1, [r1]
	ldrb r0, [r1, #0x20];
	pop {r1-r12,pc}

GetNbOrbsObtained:
	push {r1-r12,lr}
	ldr r1, =ADVENTURE_LOG_PTR; 
	ldr r1, [r1]
	ldrb r0, [r1, #0x21];
	pop {r1-r12,pc}

GetNbOrbsGiven:
	push {r1-r12,lr}
	ldr r1, =ADVENTURE_LOG_PTR;
	ldr r1, [r1]
	ldrb r0, [r1, #0x22];
	pop {r1-r12,pc}


SelectPuzzleRoomId:
	PuzzleRoomIdSwitch:
		push {r1-r12, lr};
		mov r8, r0;
		ldrb r6, [r8, #0x2]; // subtype
		cmp r6, #0x3; // Treasure Hoard
		beq SelectTreasureHoardMemo;
		cmp r6, #0x2; // Fleeing Item-Bearing Outlaw
		beq SelectOutlawFleeMemo;
		cmp r6, #0x1; // Find Item on Vanilla Floor
		beq PuzzlesNoFixedRoom
		ldrb r0, [r8, #0x4]; // Dungeon ID
		cmp r0, #0x2; // DMV
		moveq r0, #0x73;
		beq PuzzleRoomIdReturn;
		cmp r0, #0x3; // Grimy Pit
		cmpne r0, #0x4; // Grimy Forest
		moveq r0, #0x74;
		beq PuzzleRoomIdReturn;
		cmp r0, #0x7; // The Shrine I dare not name
		moveq r0, #0x75;
		beq PuzzleRoomIdReturn;
		cmp r0, #10; // Waffle house
		moveq r0, #0x76; 
		beq PuzzleRoomIdReturn;
		cmp r0, #14; // Kurokami Shrine
		moveq r0, #0x77;
		beq PuzzleRoomIdReturn;
		cmp r0, #13; // Null Tunnels
		moveq r0, #0x78;
		beq PuzzleRoomIdReturn;
		cmp r0, #15; // Snowdrift Slope 
		moveq r0, #0x79;
		beq PuzzleRoomIdReturn;
		cmp r0, #17; // Thunderbolt Chasm
		cmpne r0, #18; // Thunderbolt Rift
		moveq r0, #0x7A;
		beq PuzzleRoomIdReturn;
		// These are all unused for now, we may find them homes in hub orb missions!
		cmp r0, #0x100;
		moveq r0, #0x7B;
		beq PuzzleRoomIdReturn;
		cmp r0, #0x100;
		moveq r0, #0x7C;
		beq PuzzleRoomIdReturn;
		cmp r0, #0x100;
		moveq r0, #0x7D;
		beq PuzzleRoomIdReturn;
		cmp r0, #0x100;
		moveq r0, #0x7E;
		beq PuzzleRoomIdReturn;
		cmp r0, #0x100;
		moveq r0, #0x7F;
		beq PuzzleRoomIdReturn;
		cmp r0, #0x100;
		moveq r0, #0x80;
		beq PuzzleRoomIdReturn;
		cmp r0, #0x100;
		moveq r0, #0x81;
		beq PuzzleRoomIdReturn;
		cmp r0, #0x100;
		moveq r0, #0x82;
		beq PuzzleRoomIdReturn;
		cmp r0, #0x100;
		moveq r0, #0x83;
		beq PuzzleRoomIdReturn;
	SelectTreasureHoardMemo:
		ldr r0, =MEMO_FIXED_ROOM_IDS; // bytes 8 thru 15 of MEMO_FIXED_ROOM_IDS;
		mvn r1, #0; // -1
		bl SelectRandomFixedRoomInRange
		b PuzzleRoomIdReturn;
	SelectOutlawFleeMemo:
		ldr r0, =MEMO_FIXED_ROOM_IDS; // bytes 0 thru 7 of MEMO_FIXED_ROOM_IDS;
		add r0, #0x8;
		mvn r1, #0; // -1
		bl SelectRandomFixedRoomInRange
		b PuzzleRoomIdReturn;
	PuzzlesNoFixedRoom:
		mov r0, #0x0; // No Fixed Room!
	PuzzleRoomIdReturn:
		pop {r1-r12, pc};

	PuzzleStartSwapBag:
		CheckForValidFixedRoom:
			push {lr};
			push {r1-r12};
			mov r11, r0; // Fixed Room ID	
			mov r0, #0xC;
			mov r1, #0x1;
			bl IsCurrentMissionTypeExact; // Is it a Treasure Memo subtype 1 (Find Orb On Floor?)
			cmp r0, #1;
			beq ActuallySwapTheBag;
			mov r0, r11;
			cmp r11, #0;
			beq NotMemoFixedRoom;
			// Check if the fixed room is right, and if so swap the bag!
			mov r1, #0x90; // Max Memo Fixed Room ID
			cmp r0, #0x73; // r0 >= #0x73 ? 
			cmpge r1, r0;  // #0x90 >= r0 ?
			blt NotMemoFixedRoom;
			// Add exceptions as needed for rooms that do not need bag swapping.
			mov r1, #0x90;
			cmp r0, #0x84; // Hoard or Outlaw, no bag swap!
			cmpge r1, r0;
			/*
				ldr r0, =DUNGEON_PTR
				ldr r0, [r0]
				ldr r1, =#0x286CE
				mov r2, #151;
				strh r2, [r0, r1];
			*/
			bge OnlySwapTheTeam;
		ActuallySwapTheBag:
			// Note: I need to remember if the bag has been swapped, and swap it back on normal gameplay!
			bl ReadBagSwapByte;
			tst r0, #1;
			bne OnlySwapTheTeam;
			mov r0, #0;
			mov r1, #1;
			bl MemoSwapBag;
			// Clear non-orbs from bag!
			bl ClearNonOrbsInBag
			bl ReadBagSwapByte;
			orr r0, #1;
			bl WriteBagSwapByte;
		OnlySwapTheTeam:
			bl ReadBagSwapByte;
			tst r0, #2;
			bne NotMemoFixedRoom;
			mov r0, #0;
			mov r1, #1;
			// bl SetActiveTeam
			bl MemoSwapParty;
			cmp r11, #0x8A; // For Outlaw Subtype, swap to a different SE slot!
			movge r0, #0x1;
			movlt r0, #0x0;
			cmp r11, #0;
			moveq r0, #1; // For No fixed room, AKA Find Item Subtype, swap to a different SE slot!
			bl InjectSpecialEpisodePC;
			bl ReadBagSwapByte;
			orr r0, #2;
			bl WriteBagSwapByte;
			b MemoFixedRoomExit;
		NotMemoFixedRoom:
			bl RevertPuzzleBagAndTeam
		MemoFixedRoomExit:
			bl InitRosyFloorFields
			mov r0, r11;
			pop {r1-r12};
			cmp r0, #0; // Original Instruction
			pop {pc};

RevertPuzzleTeamWrapper:
	RevertPuzzleTeamStart:
		sub sp, #0xBC; // Original instruction
		push {r0-r12,lr}
		mov r4, r0;
		bl EntityIsValid
		cmp r0, #0;
		popeq {r0-r12,pc};
		bl GetLeader
		cmp r0, r4;
		popne {r0-r12,pc};

		// Original Instruction
		bl RevertPuzzleBagAndTeam
		pop {r0-r12,pc};

RevertPuzzleBagAndTeam:
	push {r0-r12, lr}
	bl ReadBagSwapByte;
	tst r0, #1;
	beq NotMemoFixedRoomParty;
	// Clear non-orbs from the bag!
	bl ClearNonOrbsInBag
	// Revert the bag back to what it should be!
	mov r0, #1;
	mov r1, #0;
	bl MemoSwapBag
NotMemoFixedRoomParty:
	bl ReadBagSwapByte;
	tst r0, #2;
	beq ZeroBagSwapByte;
	// Revert the party back to what it should be!
	mov r0, #1;
	//bl SetActiveTeam
	mov r1, #0;
	bl MemoSwapParty
	// I have no idea why this needs to be here, but if it isnt consecutive missions dont work!
	bl RemoveActiveMembersFromSpecialEpisodeTeam
    ldr r0, =TEAM_MEMBER_TABLE_PTR
    ldr r0, [r0]
    mov r1, #0x9800;
    add r1, #0x77;
    ldrb r0, [r0, r1];
    bl ApplyPartyChange;
	
ZeroBagSwapByte:
	mov r0, #0;
	bl WriteBagSwapByte;
	pop {r0-r12,pc}


ReadBagSwapByte:
	push {r1-r12,lr};
	ldr r1, =ADVENTURE_LOG_PTR; // Check if the bag is swapped!
	ldr r1, [r1]
	ldrb r0, [r1, #0x23];
	pop {r1-r12,pc};

// r0: value to write!
WriteBagSwapByte:
	push {r1-r12,lr};
	ldr r1, =ADVENTURE_LOG_PTR; // Check if the bag is swapped!
	ldr r1, [r1]
	strb r0, [r1, #0x23];
	pop {r1-r12,pc};


InjectSpecialEpisodePC:
    push {r1-r12,lr}
    mov r4, r0; // SPECIAL_EPISODE_PC index
    bl RemoveActiveMembersFromMainTeam
    mov r3, #0x14;
    ldr r6, =SPECIAL_EPISODE_MAIN_CHARACTERS;
    mul r4, r3;
    add r6, r4; // Index into the SPECIAL_EPISODE_MAIN_CHARACTERS table
    mov r1, r6;
	mov r0, #2;
    bl AssignSpecialEpisodePC;
    // Update the active party
    ldr r0, =TEAM_MEMBER_TABLE_PTR
    ldr r0, [r0]
    mov r1, #0x9800;
    add r1, #0x77;
    ldrb r0, [r0, r1];
    bl ApplyPartyChange;
	ldrh r0, [r6, #0x0];
	mov r1, #1;
	bl LoadMonsterSprite;
    pop {r1-r12,pc}


// r0: bag ID #1
// r1: bag ID #2
// Will swap the contents of bag ID #1 and bag ID #2.
MemoSwapBag:
	push {r2-r12,lr};
	mov r7, r0;
	mov r6, r1;
	mov r0,#0
	cmp r7,#0
	blt retI
	cmp r7,#2
	bgt retI
	cmp r6,#0
	blt retI
	cmp r6,#2
	bgt retI
	mov r3,r6
	mov r12,#2
	both_team_clear1I:
		ldr r0,=BAG_ITEMS_PTR_MIRROR
		ldr r0,[r0]
		mov r1,#300
		mla r0,r1,r3,r0 ; // Compute correct location of a bag slot
		add r0,r0,#1
		mov r2,#0
	clear_held_loopI:
		strb r2,[r0],#6
		subs r1,r1,#6
		bne clear_held_loopI
		subs r12,r12,#1
		mov r3,r7
		bne both_team_clear1I

		sub r13,r13,#300
		ldr r1,=BAG_ITEMS_PTR_MIRROR
		ldr r1,[r1]
		mov r0,r13
		mov r2,#300
		mla r1,r2,r7,r1
		bl Memcpy32
		ldr r1,=BAG_ITEMS_PTR_MIRROR
		ldr r1,[r1]
		mov r2,#300
		mla r0,r2,r7,r1
		mla r1,r2,r6,r1
		bl Memcpy32
		ldr r1,=BAG_ITEMS_PTR_MIRROR
		ldr r1,[r1]
		mov r2,#300
		mla r0,r2,r6,r1
		mov r1,r13
		bl Memcpy32
		add r13,r13,#300
		push {r4,r5,r14}
		mov r12,#2
		// Massive thanks to Irdkwia!
	both_team_clear2I:
    		ldr r4,=TEAM_MEMBER_TABLE_PTR
    		ldr r4,[r4]
    		add r4,r4,#0x9300
    		add r4,r4,#0x6C ; // First team pointer
    		mov r1,#0x1A0
    		mla r4,r3,r1,r4 ; // Compute the correct location
    		mov r5,#0
	loop_clearI:
    		ldrb r0,[r4]
    		tst r0,#0x1
    		beq check_loop_clearI
    		add r0,r4,#0x3E ; // Item structure is at 0x3E
    		bl ItemZInit
	check_loop_clearI:
    		add r5,r5,#1
    		add r4,r4,#0x68
    		cmp r5,#4
    		blt loop_clearI
		subs r12,r12,#1
		mov r3,r6
		bne both_team_clear2I
    		pop {r4,r5,r14}
		mov r0, #1;
	retI:
		pop {r2-r12, pc};

MemoSwapParty:
	push {r2-r12,lr};
	push {r0-r3}
	mov r1, #0x4E; // PERFORMANCE_PROGRESS_LIST[62];
	mov r2, #62; 
	bl LoadScriptVariableValueAtIndex
	eor r3, r0, #1;
	mov r1, #0x4E; // PERFORMANCE_PROGRESS_LIST[62];
	mov r2, #62; 
	bl SaveScriptVariableValueAtIndex
	// bl 0x204B1D8
	// cmp r0, #1;
	// bne SkipSwitchingModeFromTopScreen
	mov r0, #2; // What mode might this be? Lets find out!
	bl ChangeTopScreenType
	SkipSwitchingModeFromTopScreen:
	pop {r0-r3}
	mov r7, r0;
	mov r6, r1;
		mov r0,#0
		cmp r7,#0
		blt retp
		cmp r7,#2
		bgt retp
		cmp r6,#0
		blt retp
		cmp r6,#2
		bgt retp
		mov r3,r6
		mov r12,#2
	both_team_clear1p:
		ldr r0,=BAG_ITEMS_PTR_MIRROR
		ldr r0,[r0]
		mov r1,#300
		mla r0,r1,r3,r0 ; // Compute correct location of a bag slot
		add r0,r0,#1
		mov r2,#0
	clear_held_loopp:
		strb r2,[r0],#6
		subs r1,r1,#6
		bne clear_held_loopp
		subs r12,r12,#1
		mov r3,r7
		bne both_team_clear1p

		; // Swapping the teams!

		sub r13,r13,#0x1A0
		ldr r1,=TEAM_MEMBER_TABLE_PTR
		ldr r1,[r1]
		add r1,r1,#0x9300
    		add r1,r1,#0x6C
		mov r0,r13
		mov r2,#0x1A0
		mla r1,r2,r7,r1
		bl Memcpy32
		ldr r1,=TEAM_MEMBER_TABLE_PTR
		ldr r1,[r1]
		add r1,r1,#0x9300
    		add r1,r1,#0x6C
		mov r2,#0x1A0
		mla r0,r2,r7,r1
		mla r1,r2,r6,r1
		bl Memcpy32
		ldr r1,=TEAM_MEMBER_TABLE_PTR
		ldr r1,[r1]
		add r1,r1,#0x9300
    		add r1,r1,#0x6C
		mov r2,#0x1A0
		mla r0,r2,r6,r1
		mov r1,r13
		bl Memcpy32
		add r13,r13,#0x1A0

	; // Clearing the held items of team members!

		push {r4,r5,r14}
		mov r12,#2
		; // Massive thanks to Irdkwia!
	both_team_clear2p:
    		ldr r4,=TEAM_MEMBER_TABLE_PTR
    		ldr r4,[r4]
    		add r4,r4,#0x9300
    		add r4,r4,#0x6C ; // First team pointer
    		mov r1,#0x1A0
    		mla r4,r3,r1,r4 ; // Compute the correct location
    		mov r5,#0
	loop_clearp:
    		ldrb r0,[r4]
    		tst r0,#0x1
    		beq check_loop_clearp
    		add r0,r4,#0x3E ; // Item structure is at 0x3E
    		bl ClearItem
	check_loop_clearp:
    		add r5,r5,#1
    		add r4,r4,#0x68
    		cmp r5,#4
    		blt loop_clearp
		subs r12,r12,#1
		mov r3,r6
		bne both_team_clear2p
    		pop {r4,r5,r14}
		
		ldr r1,=TEAM_MEMBER_TABLE_PTR
		ldr r1,[r1]
		add r1,r1,#0x9800
		add r1,r1,#0x56;
		mov r8, #0x0;
	swap_mentry_ids:
		mov r3, r8, lsl #1;
		add r3, r7, lsl #3;
		ldrh r0, [r1,r3]
		mov r2, #0;
		add r2, r8, lsl #1;
		add r2, r6, lsl #3;
		ldrh r4, [r1,r2]
		strh r4, [r1,r3];
		strh r0, [r1,r2];
		add r8, #0x1;
		cmp r8, #0x4;
		blt swap_mentry_ids
		mov r0,#1
	retp:
		pop {r2-r12, pc};


CheckIfMemoCompleteReward:
		mov r0, r5;
		push {r1-r12,lr}
		mov r11, r0;
		ldr r10, =THE_ORB_ITEM_ID;
		mov r0, r10;
		bl CountNbItemsOfTypeInBag
		mov r8, r0;
		mov r0, #0;
		mov r1, #1;
		bl MemoSwapBag;
		mov r0, r10;
		bl CountNbItemsOfTypeInBag
		add r8, r0;
		mov r0, #1;
		mov r1, #0;
		bl MemoSwapBag
		mov r0, r8;
		pop {r1-r12,pc};


RemoveOneOrbFromBags:
		push {r0-r12,lr}
		ldr r11, =BAG_ITEMS_PTR_MIRROR;
		ldr r11, [r11];
		ldr r10, =THE_ORB_ITEM_ID;
		mov r0, r10;
		bl CountNbItemsOfTypeInBag
		cmp r0, #1;
		beq RemoveOrbFromMainBag;
		mov r0, #0;
		mov r1, #1;
		bl MemoSwapBag;
		mov r0, r10;
		bl CountNbItemsOfTypeInBag
		mov r0, r10;
		bl RemoveItemNoHole
		mov r0, #1;
		mov r1, #0;
		bl MemoSwapBag
		pop {r0-r12,pc};
	
	RemoveOrbFromMainBag:
		mov r0, r10;
		bl RemoveItemNoHole
		pop {r0-r12,pc};




ClearNonOrbsInBag:
	push {r1-r12,lr}
	sub sp, #0x8;
	mov r0, sp;
	mov r5, r0;
	bl ItemZInit
	mov r0, #0x1;
	strb r0, [r5]
	ldr r0, =THE_ORB_ITEM_ID;
	strh r0, [r5, #0x4]; // Store the item ID
	bl CountNbItemsOfTypeInBag
	mov r8, r0;
	mov r7, r0;
	mov r0, #0;
	bl RemoveAllItemsStartingAt
	AddOrbBackToBagLoop:
		cmp r8, #0;
		beq ClearNonOrbsReturn
		mov r0, r5; // Item Struct
		bl AddItemToBagNoHeld
		sub r8, #1;
		b AddOrbBackToBagLoop
	ClearNonOrbsReturn:
		add sp, #0x8;
		mov r0, r7;
		pop {r1-r12,pc};




MemoMissionRewardInit:
	ldr r1, =MISSION_REWARD_DIALOGUE_SEQS;
	str r1, [r0, #0x94];
	push {r1-r12,lr}
	mov r11, r0; // mission_reward_data*
	mov r10, r1; // Player Cooperative?
	mov r1, #0x5C; // EVENT_LOCAL
	bl LoadScriptVariableValue
	mov r10, r0;
	cmp r0, #0x1;
	bne SkipIncrementOrbs;
	bl IncrementNbOrbsGiven;
SkipIncrementOrbs:
	bl GetNbOrbsGiven
	mov r4, r0; // # of orbs given
	bl GetNbOrbsObtained
	mov r5, r0; // # of orbs obtained
	mov r0, #1;
	str r0, [r11, #0x5c] // npc_count(?) = 1, makes everything smoother.
	add r0, #71; // 539, Wishiwashi's ID
	strh r0, [r11, #0x10]; // Target in mission ptr. Repurposed to be Wishiwashi for memo missions.
	cmp r10, #1;
	bne PlayerUncooperative;
	PlayerCooperative:
		ldr r1, [r11, #0x90]
		mov r0, #460; // 461, Cherrim's ID
		add r0, #1;
		strh r0, [r11, #0xE]; // Client in mission ptr. Cherrim.
		sub r1, r4, r5;
		mov r2, #250;
		mul r0, r1, r2;
		add r0, #2000;
		cmp r0, #0;
		movlt r0, #50;
		str r0, [r11,#0x68]; // amount_money
		mov r0, #1; // MONEY_AND_MORE
		strh r0, [r11,#0x62]; // mission_reward_type
		cmp r5, #0x1;
		ble CoopFirstReward;
		cmp r4, r5;
		bgt PreviouslyUncooperativeReward;
		AlwaysCooperativeReward:
			mov r0, #4;
			str r0, [r11, #0x6C]; // num_items_to_roll (Seems to include money)
			mov r0, #10;
			strh r0, [r11, #0x72]; // item_1 is valid
			strh r0, [r11, #0x78]; // item_2 is valid
			
			mov r0, r11;
			mov r1, #10; // ARREST_OUTLAW (+1 mission rank) Used by all.
			mov r2, #0x74; // reward_item_id_1
			bl RollRandomMissionitemWrapper
			mov r2, #0x7A; // reward_item_id_2
			bl RollRandomMissionitemWrapper
			mov r2, #0x80; // reward_item_id_3
			bl RollRandomMissionitemWrapper
			b RewardReturn;
		PreviouslyUncooperativeReward:
			mov r0, #3;
			str r0, [r11, #0x6C]; // num_items_to_roll (Seems to include money)
			mov r0, #10;
			strh r0, [r11, #0x72]; // item_1 is valid
			strh r0, [r11, #0x78]; // item_2 is valid

			mov r0, r11;
			mov r1, #0; // RESCUE_TARGET (+0 mission rank) Used by all.
			mov r2, #0x74; // reward_item_id_1
			bl RollRandomMissionitemWrapper
			mov r2, #0x7A; // reward_item_id_2
			bl RollRandomMissionitemWrapper
			b RewardReturn;
		CoopFirstReward:
			mov r0, #4;
			str r0, [r11, #0x6C]; // num_items_to_roll (Seems to include money)
			mov r0, #10;
			strh r0, [r11, #0x72]; // item_1 is valid
			strh r0, [r11, #0x78]; // item_2 is valid
			strh r0, [r11, #0x7E]; // item_3 is valid
			mov r0, r11;
			mov r1, #10; // ARREST_OUTLAW (+1 mission rank) Used by all.
			mov r2, #0x74; // reward_item_id_1
			bl RollRandomMissionitemWrapper
			mov r2, #0x7A; // reward_item_id_2
			bl RollRandomMissionitemWrapper
			mov r2, #0x80; // reward_item_id_3
			bl RollRandomMissionitemWrapper
			b RewardReturn;
	PlayerUncooperative:
		ldr r1, [r11, #0x90]
		mov r0, #460; // 460, Cherrim's Shaded ID
		strh r0, [r11, #0xE]; // Client in mission ptr. Cherrim.
		mov r0, #1; // $1, and MONEY_AND_MORE reward type.
		strh r0, [r11,#0x62]; // mission_reward_type
		str r0, [r11,#0x68]; // amount_money
		mov r0, #2;
		str r0, [r11, #0x6C]; // num_items_to_roll (Seems to include money)
		mov r0, #10;
		strh r0, [r11, #0x72]; // item_1 is valid
		mov r0, #105; // Reviser Seed
		strh r0, [r11, #0x74]; // item_1 will be a Reviser Seed
	RewardReturn:
		mov r0, r11;
		pop {r2-r12,pc}


RollRandomMissionitemWrapper:
	push {r3-r12,lr}
	mov r11, r0; 
	mov r10, r1;
	ldr r0, [r11, #0x90]; // mission_ptr
	add r0, #0x4; // dungeon_id_ptr;
	add r2, r2, r11; // reward_item_id_3
	bl RollRandomMissionitem;
	mov r0, r11;
	mov r1, r10;
	pop {r3-r12,pc}



SetTreasureMemoMissionRewards:
	ldrb r0, [r4, #0x1]; // Mission Type
	cmp r0, #0xC; // Treasure Memo
	bne SetTreasureMemoMissionRewardsReturn;
	mov r0, #1; // MONEY_AND_MORE
	strb r0, [r4, #0x16]; // reward_type_8
SetTreasureMemoMissionRewardsReturn:
	add sp, #0x4;
	pop {r3-r6, pc}


TweakMemoDestinationInfo:
	push {r2-r12,lr}
	mov r9, r0; // mission*
	mov r7, r1; // mission_destination_info*
	ldrb r0, [r9, #0xC];
	strb r0, [r7, #0x2E];
	ldrsh r0, [r9, #0x14];
	strh r0, [r7, #0x20];
	ldrb r0, [r9, #0x2]; // subtype
	cmp r0, #0x4
	addls pc, r0, lsl #2;
	destination_0: // Puzzle Subtype!
	destination_4: // Exists as a placeholder in the mission file.
	b destination_return;
	b destination_0;
	b destination_1;
	b destination_2;
	b destination_3;
	b destination_4;
	destination_1: // Find Item On Vanilla Floor Subtype
		mov r0, #1;
		strb r0, [r7, #0x2F]; // unk_item_tracker_1 is true!
		ldrsh r0, [r9,#0x14];
		strh r0, [r7,#0x1c]; // item_to_retrieve 
		b destination_return;
	destination_2: // Outlaw Subtype!
		mov r0, #0x64;
		strb r0, [r7, #0x34]; // Fleeing Outlaw!
		add r0, r7, #0x18
		add r1, r9, #0x10
		mov r2, #1
		bl InitDestinationOutlaws
		b destination_return;
	destination_3: // Hoard Subtype!
		mov r0, #0x96;
		ldrh r0, [r7, #0x3C]; // Wind turns at 150.
		// but it probably wont work...
		b destination_return;
	destination_return:
		pop {r2-r12,pc};

TrySpawnMemoOutlaw:
	push {r1-r3,r5-r11,lr};
	mov r11, r11;
	mov r0, #0xC;
	mov r1, #0x2;
	bl IsCurrentMissionTypeExact; // Is it a Treasure Memo subtype 2 (Fleeing Item-Bearing Outlaw?)
	cmp r0, #0x1;
	bne SpawnMemoOutlawReturn
	mov r0, #3; // Fleeing Outlaw!
	ldr r5, [r4, #0xB4]; // monster struct
	ldrb r1, [r5, #0xBC];
	cmp r1, #1;
	bne SpawnMemoOutlawReturn;
	strb r0, [r5, #0xBC]; // statuses.monster_behavior
	mov r0, #0x89; // Bitfield n' shit
	strb r0, [r5, #0x62];
	mov r0, #1;
	strh r0, [r5, #0x64];
	bl GetSpecialTargetItem;
	strh r0, [r5, #0x66];
	mov r0, #0x0;
	strb r0, [r5, #0x63];
	ldr r2, =DUNGEON_PTR;
	ldr r2, [r2]
	add r2, #0x760; // mission_destination*
	ldrh r0, [r2, #0xE]
	strh r0, [r5, #0x2]; // monster_id
	strh r0, [r5, #0x4]; // apparent_monster_id

	// TODO: Should be relatively easy to make the outlaw start sleeping. If we want to do this, we do it here!
SpawnMemoOutlawReturn:
	mov r0, r4;
	pop {r1-r3,r5-r11,pc};

CheckIfSleeping:
	push {r1-r12,lr}
	mov r0,r1
	bl IsMonsterSleeping
	cmp r0, #1;
	pop {r1-r12,pc}

DisambiguateMemoMission:
	ldrsh r0, [r5, #0x4]; // original instruction #1
	push {r2-r12,lr};
	cmp r0, r1;
	bne DisambiguateReturn;
	push {r0, r1};
	mov r0, #0xC;
	bl IsCurrentMissionType
	cmp r0, #1;
	pop {r0, r1};
	addeq r0, r1, #1;
DisambiguateReturn:
	pop {r2-r12,pc};

IsActuallyDestinationFloorWithFleeingOutlaw:
	push {r2-r12,lr}
	bl IsDestinationFloorWithFleeingOutlaw
	cmp r0, #0x1;
	popeq {r2-r12,pc};
	mov r0, #0xC;
	mov r1, #0x2;
	bl IsCurrentMissionTypeExact; // Is it a Treasure Memo subtype 2 (Fleeing Item-Bearing Outlaw?)
	pop {r2-r12,pc}

IsActuallyDestinationFloorWithItem:
	push {r2-r12,lr}
	bl IsDestinationFloorWithItem
	cmp r0, #0x1;
	popeq {r2-r12,pc};
	mov r0, #0xC;
	mov r1, #0x1;
	bl IsCurrentMissionTypeExact; // Is it a Treasure Memo subtype 2 (Fleeing Item-Bearing Outlaw?)
	pop {r2-r12,pc}

/* 
	PrepMissionRewardDialogue:
		push {r3-r5,r7-r12,lr}; // Not r6.
		strh r0, [r6, #0x0]; // case_id Speaker
		strh r2, [r6, #0x4]; // Text String ID
		mov r0, #0x218;
		cmp r1, #1;
		addeq r0, #0x3000;
		strh r0, [r6, #0x2]; // preprocessor_flags
		add r6, #0x6; // Reward_Dialogue_Data_2
		pop {r3-r5,r7-r12,pc}; // Not r6.
*/

/*
	Reward_Dialogue_Data_1:
		.hword 0x0003; 
		.hword 0x3218;
		.hword 0x0000;

	Reward_Dialogue_Data_2:
		.hword 0x0003;
		.hword 0x3218;
		.hword 0x0000;

	Reward_Dialogue_Data_3:
		.hword 0x0003;
		.hword 0x3218;
		.hword 0x0000;

	Reward_Dialogue_Data_4:
		.hword 0x0003;
		.hword 0x3218;
		.hword 0x0000;

	Reward_Dialogue_Data_5:
		.hword 0x0003;
		.hword 0x3218;
		.hword 0x0000;

	Reward_Dialogue_Data_6:
		.hword 0x00FF;
		.hword 0x0218;
		.hword 0x0000;

	// To ensure things actually end...
	.word 0x00000000;
*/
