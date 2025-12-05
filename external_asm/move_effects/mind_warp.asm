; 
; ------------------------------------------------------------------------------
; By happylappy
; This move will instantly kill the user. However, it will also deal psychic
; type damage and confuse all enemies on the floor, as well as make the floor
; have a pink hue.
; ------------------------------------------------------------------------------


.relativeinclude on
.nds
.arm


.definelabel MaxSize, 0x2598
.definelabel MoveStartAddress, 0x02330134
.definelabel MoveJumpAddress, 0x023326CC
.definelabel ApplyDamageAndEffectsWrapper, 0x230D11C
.definelabel DungeonRandInt, 0x22EAA98
.definelabel LogMessageByIdWithPopupCheckUserTarget, 0x234B350
.definelabel UpdateStatusIconFlags, 0x22E3AB4
.definelabel DUNGEON_PTR, 0x2353538
.definelabel TryActivateWeather, 0x23354C4;

; Usable Variables: 
; r6 = Move ID
; r9 = User Monster Structure Pointer
; r4 = Target Monster Structure Pointer
; r8 = Move Data Structure Pointer (8 bytes: flags [4 bytes], move_id [2 bytes], pp_left [1 byte], boosts [1 byte])
; r7 = ID of the item that called this move (0 if the move effect isn't from an item)
; Returns: 
; r10 (bool) = ???
; Registers r4 to r9, r11 and r13 must remain unchanged after the execution of that code


; File creation
.create "./code_out.bin", 0x02330134 ; Change to the actual offset as this directive doesn't accept labels
    .org MoveStartAddress
    .area MaxSize ; Define the size of the area
        sub sp,sp,#0x20
        cmp r4, r9;
        bne TargetIsNotUser;
            mov r0, r4;
            ldr r1, =#9999; Instakill damage
            mov r2, #0; // damage_message recoil
            ldr r3, =#563; // turned into a friend
            bl ApplyDamageAndEffectsWrapper

            b return;
        TargetIsNotUser:
            mov r0, #0x50;
            bl DungeonRandInt;
            add r1, r0, #20; // 20 + Rand(80) damage
            mov r0, r4;
            mov r2, #0; // damage_message recoil
            ldr r3, =#563; // turned into a friend
            bl ApplyDamageAndEffectsWrapper

            mov r3, #0xA9; // statuses offset
            mov r0, #3;
            bl DungeonRandInt; // leaves r3 intact!
            cmp r0, #1;
            addlt r3, #0x27; // cringe_class offset
            movlt r0, #0x7; // cringe status options excluding status_none 
            addeq r3, #0x14; // sleep_class offset
            moveq r0, #0x5; // sleep status options excluding status_none 
            addgt r3, #0x48; // blinker_class offset
            movgt r0, #0x4; // blinker status options excluding status_none 
            bl DungeonRandInt; // leaves r3 intact!
            add r0, #1; // ensure status_none is not counted.
            add r3, r0, lsl #0x8; // status option
            mov r0, #0x7; // status duration
            bl DungeonRandInt; // leaves r3 intact!
            add r0, #0x3; // 3 turns minimum, 10 turns maximum
            add r3, r0, lsl #0x10; // status duration

            mov r2, #0xD00;
            sub r0, r3, #0x100;
            and r0, #0xFF00;
            and r1, r3, #0xFF;
            cmp r1, #1;
            blt CringeClassMessage;
            beq SleepClassMessage;
            bgt BlinkerClassMessage;

    
        CringeClassMessage:
            cmp r0, #0x700;
            addls pc, r0, lsr #0x6;
            b DoMentalStatus;
            add r2, #4;
            sub r2, #26;
            sub r2, #43;
            sub r2, #6;
            sub r2, #12;
            add r2, #59;
            add r2, #26;
            b DoMentalStatus;

        SleepClassMessage:
            cmp r0, #0x500;
            addls pc, r0, lsr #0x6
            b DoMentalStatus;
            sub r2, #17;
            add r2, #9;
            add r2, #8;
            sub r2, #11;
            add r2, #15;
            b DoMentalStatus;

        BlinkerClassMessage:
            cmp r0, #0x400;
            addls pc, r0, lsr #0x6
            b DoMentalStatus;
            sub r2, #2;
            sub r2, #2;
            sub r2, #4;
            add r2, #60;

        DoMentalStatus:
            mov r0, r9;
            mov r1, r4;
            push {r5-r7}
            and r5, r3, #0xFF; // status_offset
            mov r6, r3, lsr #0x8; // status_id + status_duration * 256
            ldr r7, [r4, #0xB4]; // monster_ptr
            strb r6, [r7, r5];
            add r5, #1;
            lsr r6, #0x8;
            strb r6, [r7, r5];
            mov r0, r9;
            mov r1, r4;
            bl LogMessageByIdWithPopupCheckUserTarget
            mov r0, r4;
            bl UpdateStatusIconFlags
            pop {r5-r7}
        return:
            add sp,sp,#0x20
            // Increment the RosyTurnCounter by 1 per affected entity.
	        ldr r1, =DUNGEON_PTR;
	        ldr r1, [r1];
	        add r1, #0xEE00;
	        ldrb r0, [r1,#0xE6]
            cmp r0, #255;
            addlt r0, #1;
            strb r0, [r1,#0xE6];
	        bne MoveJumpAddress
            mov r0, #0;
	        mov r1, #1;
	        bl TryActivateWeather;
            b MoveJumpAddress
        .pool
    .endarea
.close