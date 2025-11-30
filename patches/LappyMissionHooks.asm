// All of the hooks necessary for treasure memos to work as envisioned.
.nds
.include "symbols.asm"

// arm9
.open "arm9.bin", arm9_start
	.org MISSION_MEMO_CROSSROADS_HOOK
	.area 0x4
		cmp r2, #0x10;
	.endarea

	.org MEMO_FIXED_ROOM_ID_HOOK
	.area 0x8
		mov r0, r8; 
		bl SelectPuzzleRoomId
	.endarea

	.org ALWAYS_GENERATE_MISSIONS
	.area 0x4
		nop; // Original Instruction: ldmiaeq sp!,{r3,r4,r5,r6,r7,r8,r9,r10,r11,pc}. Prevents a return if Performance Flag 3 is disabled, which I intend for it to be.
	.endarea

	.org MEMO_FIXED_ROOM_IDS
	.area 0x20
		// ROOM_SET_HOARD
			.byte 0x84;
			.byte 0x85;
			.byte 0x86;
			.byte 0x87;
			.byte 0x88;
			.byte 0x89;
			.byte 0x00;
			.byte 0x00;
		// PUZZLE_SET_OUTLAW
			.byte 0x8A; 
			.byte 0x8B; 
			.byte 0x8C; 
			.byte 0x8D;
			.byte 0x8E; 
			.byte 0x8F; 
			.byte 0x90; 
			.byte 0x00;
		// Unused Space
		.word 0x00000000; .word 0x00000000;
		.word 0x00000000; .word 0x00000000;
	.endarea

	.org MISSION_REWARD_MEMO_TWEAK
	.area 0x4
		bl CheckIfMemoCompleteReward
	.endarea

	.org OOPS
	.area 0x4
		cmp r4, #0xFF;
	.endarea

	.org MISSION_REWARD_GENERATION_HOOK
	.area 0x4
		b SetTreasureMemoMissionRewards
	.endarea

	.org MISSION_MEMO_SHOW_DUNGEON_NAME
	.area 0x4
		cmp r0, #0x10; // Should never be true!
	.endarea

	.org MISSION_MEMO_SHOW_MISSION_REWARD
	.area 0xC
		mov r0, #2000;
		str r0, [r9, #0x20]; amount_money = 2000
		nop
	.endarea

	.org MISSION_MEMO_HIDE_MISSION_RANK_1
	.area 0xC
		// If prior condition Or...
		ldrneb r0, [r1, #0x1]; // mission_type
		cmpne r0, #0xC; // Is Memo mission Type
		cmpne r0, #0xE; // Or is 7 treasure mission Type
	.endarea

	.org MISSION_MEMO_HIDE_MISSION_RANK_2
	.area 0xC
		// If prior condition Or...
		ldrneb r0, [r1, #0x1]; // mission_type
		cmpne r0, #0xC; // Is Memo mission Type
		cmpne r0, #0xE; // Or is 7 treasure mission Type
	.endarea
.close

// ov_29
.open "overlay29.bin", overlay29_start
	.org FLOOR_CHECK_FIXED_ROOM_HOOK
	.area 0x4;
		bl PuzzleStartSwapBag	/* cmp r0, #0 Original Instruction */
	.endarea;

	.org EXIT_DUNGEON_FLOOR_HOOK
	.area 0x4;
		bl RevertPuzzleTeamWrapper;
	.endarea

	.org MEMO_PRINT_STRING_HOOK
	.area 0x10;
		bl PrintPuzzleEntryDialogue;
		nop;
		nop;
		nop;
	.endarea

	.org TWEAK_MEMO_ITEM_CHECK
	.area 0x4;
		ldrh r1, [r5, #0x4]; // Formerly #0x2, for quantity. My treasure memo missions will NOT be in treasure boxes!
	.endarea

	.org TWEAK_MEMO_ITEM_SPAWN
	.area 0x8;
		orr r2, r1, #0x88; // Now the item will be sticky when placed, ensuring it cannot be used until obtained properly.
		mov r0, r3; // Formerly ldr r1, =#0x181. Now treasure memo missions spawn the item itself, not a Deluxe Box containing the item!
	.endarea

	.org MEMO_MISSION_EXIT_HOOK
	.area 0x4;
		bl CheckClearedPuzzleFloor;
	.endarea

	.org MAKE_DUNGEON_ROSY_HOOK
	.area 0x4;
		bl CheckFloorRosiness;
	.endarea

	.org SPAWN_ITEM_HOOK
	.area 0x4;
		bl MaybeSpawnRosyItem;
	.endarea;

	.org DESTROY_ITEM_HOOK
	.area 0x4;
		bl MaybeDestroyRosyItem;
	.endarea;

	.org DECREMENT_ROSINESS_HOOK
	.area 0x4;
		bl DecrementRosyTurnsWrapper;
	.endarea

	.org DECREMENT_WIND_HOOK
	.area 0x4;
		bl ReduceWindByMoreHook;
	.endarea

	.org ROSY_WIND_MESSAGE_HOOK
	.area 0x4;
		bl PlayRosyWindMessages;
	.endarea

	.org ROSY_WIND_DEATH_HOOK
	.area 0x4;
		bl SubRosyDeathMessage;
	.endarea

	.org MISSION_MEMO_SPAWN_OUTLAW_HOOK
	.area 0x4;
		bl TrySpawnMemoOutlaw;
	.endarea

	.org HANDLE_PARTY_SWAP_SPRITES_HOOK
	.area 0x4;
		bl RevertSwappedParty;
	.endarea

	.org DISAMBIGUATE_MEMO_FROM_CHAMBER_HOOK
	.area 0x8;
		bl DisambiguateMemoMission;
		cmp r0, r1;
	.endarea

	.org MISSION_OBJECTIVE_MEMO_HOOK
	.area 0x4;
		cmp r0, #0x10;
	.endarea

	.org IS_ACTUALLY_DESTINATION_FLOOR_WITH_ITEM
	.area 0x4;
		bl IsActuallyDestinationFloorWithItem;
	.endarea

	.org SPAWN_MISSION_ITEM_FLOOR_HOOK
	.area 0x4;
		bl GenerateItemWithProperFlags;
	.endarea;


	.org OOPS2;
	.area 0x4;
		b OOPS3;
	.endarea

	.org MEMO_TWEAK_MISSION_DEST_INFO_HOOK
	.area 0x10;
		mov r0, r9;
		mov r1, r7;
		bl TweakMemoDestinationInfo
		nop;
	.endarea

	.org IS_ACTUALLY_FLEEING_OUTLAW_HOOK;
	.area 0x4;
		bl IsActuallyDestinationFloorWithFleeingOutlaw
	.endarea
.close

// ov_26
	.open "overlay26.bin", overlay26_start
		.org MISSION_MEMO_GUILD_POINTS_HOOK
		.area 0x4
			// r4 = mission points, should be zero. 
			mov r4, #0;
		.endarea
	.close