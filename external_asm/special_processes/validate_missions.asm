; ------------------------------------------------------------------------------------------
; Suspend Missions For Dungeon ID
; Suspends all missions the player has, and returns whether or not mission
; Param 1: 2 to skip checking the dungeon, 1 If Orb missions should be ignored, 0 otherwise. 
; Param 2: Nothing
; Additional Inputs: $DUNGEON_ENTER_INDEX as dungeon ID, but only if Param 1 isn't 2.
; Returns: Varies on Param 1:
;	- Param 1 is 1: 2 if no orb missions found, else 1 if any mission suspended, 0 otherwise.
;	- Otherwise: 1 if any mission was suspended, 0 otherwise
; -------------------------------------------------------------------------------------------
/*
	- Suspend non-orb missions for the ID in $DUNGEON_ENTER_INDEX!
	- Search for active orb missions for the ID in $DUNGEON_ENTER_INDEX!
	- Return 2 if no active orb missions are found.
	- Else return 1 if a mission was suspended.
	- Else return 0. 
*/
.relativeinclude on
.nds
.arm

.definelabel MaxSize, 0x810

; Uncomment/comment the following labels depending on your version.

; For US
.include "lib/stdlib_us.asm"
.definelabel ProcStartAddress, 0x022E7248
.definelabel ProcJumpAddress, 0x022E7AC0
.definelabel GetAcceptedMission, 0x205F0D8
.definelabel LoadScriptVariableValue, 0x204B4EC



; File creation
.create "./code_out.bin", 0x022E7248
	.org ProcStartAddress
	.area MaxSize ; Define the size of the area
		push {r4-r6,r8-r11};
		mov r1, #0x29; // $DUNGEON_ENTER_INDEX;
		bl LoadScriptVariableValue
		mov r4, r0;
		mov r6, #0;
		mov r8, #0;
		mov r9, #0;
		MissionLoopStart:
			mov r0, r6;
			bl GetAcceptedMission
			mov r11, r0;
			cmp r11, #0;
			beq return;
			cmp r7, #2;
			beq SkipOrbCheck
			ldrb r0, [r11, #4]; // Dungeon ID
			cmp r0, r4;
			bne MissionLoopEnd
			cmp r7, #1;
			bne SkipOrbCheck;
			ldrb r0, [r11, #1]; // Mission Type
			cmp r0, #0xC; // Orb Mission
			bne SkipOrbCheck;
			ldrb r0, [r11, #0]; // Mission Status
			cmp r0, #5; // Accepted?
			moveq r9, #1;
			b MissionLoopEnd
		SkipOrbCheck:
			ldrb r0, [r11, #0];
			cmp r0, #5;
			bne MissionLoopEnd
			mov r8, #1;
			mov r0, #4;
			strb r0, [r11, #0]
		MissionLoopEnd:
			add r6, #1;
			cmp r6, #8;
			blt MissionLoopStart
		mov r0, #0;
		cmp r8, #1;
		moveq r0, #1;
		cmp r7, #1;
		bne return;
		cmp r9, #1;
		movne r0, #2;
	return:
		pop {r4-r6,r8-r11};
		b ProcJumpAddress
		.pool
	.endarea
.close