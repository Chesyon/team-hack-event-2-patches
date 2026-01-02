; ------------------------------------------------------------------------------------------
; Scrap Exclusive Item For Parts
; 
; Param 1: Slot ID to read the exclusive item data on.
; Param 2: Nothing
; Returns: 1 if the item is a 3-star exclusive item, 0 otherwise. item_Set slots 1-3 will be
; updated to contain random dusts/silks, depending on the number of stars.
; -------------------------------------------------------------------------------------------

.relativeinclude on
.nds
.arm

.definelabel MaxSize, 0x810

; Uncomment/comment the following labels depending on your version.

; For US
.include "lib/stdlib_us.asm"
.definelabel ProcStartAddress, 0x022E7248;
.definelabel ProcJumpAddress, 0x022E7AC0;
.definelabel SaveScriptVariableValue, 0x204B820;
.definelabel ItemAtTableIdx, 0x2065CF8;
.definelabel GetItemCategory, 0x200E808;
.definelabel GetExclusiveItemType, 0x200E760; 
.definelabel GetExclusiveItemParameter, 0x200E7E8;
.definelabel RandInt, 0x2002274;
.definelabel RandRange, 0x200228C;
.definelabel GetType, 0x2052A04;
.definelabel EditItemAtTableIdx, 0x02065CB4;


; File creation
.create "./code_out.bin", 0x022E7248
	.org ProcStartAddress
	.area MaxSize ; Define the size of the area
		push {r4-r6,r8-r11}
		mov r0, r7;
		sub sp, #0x4;
		mov r1, sp;
		bl ItemAtTableIdx
		ldrh r11, [sp,#0x0];
		mov r0, r11;
		bl GetItemCategory;
		cmp r0, #15;
		movne r0, #0;
		bne return;
		mov r0, r11;
		bl GetExclusiveItemType; // >=5: Pokemon, {1, 2, 5, 6,}: 1-Star, {3, 7}: 2-Star, Else 3-Star.
		mov r10, r0;
		mov r0, r11;
		bl GetExclusiveItemParameter; // type_id or monster_id
		mov r9, r0;
		cmp r10, #5;
		blt IsTypeExclusiveItem
		
		mov r0, r9;
		mov r1, #0;
		bl GetType
		mov r8, r0;
		mov r0, r9;
		mov r1, #1;
		bl GetType
		mov r6, r0;
		mov r0, #8;
		bl RandInt
		mov r1, #0;
		mov r2, #0;
		tst r0, #1;
		moveq r2, r6
		movne r2, r8
		cmp r10, #7;
		mov r4, #1;
		addgt r4, #1;
		addge r4, #1;
		movlt r0, #0;
		blt BeginTypeBitMask
		tst r0, #2;
		moveq r1, r6
		movne r1, r8
		cmp r10, #8;
		movlt r0, #0;
		blt BeginTypeBitMask
		tst r0, #4;
		moveq r0, r6
		movne r0, r8
		b BeginTypeBitMask;
	IsTypeExclusiveItem:
		mov r4, #1;
		cmp r10, #3;
		addgt r4, #1;
		movgt r0, r9;
		addge r4, #1;
		movle r0, #0;
		movge r1, r9;
		movlt r1, #0;
		mov r2, r9;
	BeginTypeBitMask:
		push {r0-r2}
		mov r0, #8
		bl RandInt
		mov r5, r0;
		pop {r0-r2}
		mov r6, #0xFB;
		add r6, #0xFB;
		add r0, r6, r0, lsl #2;
		add r1, r6, r1, lsl #2;
		add r2, r6, r2, lsl #2;
		tst r5, #1;
		addeq r0, #1;
		tst r5, #2;
		addeq r1, #1
		tst r5, #4;
		addeq r2, #1;
		mov r3, r2;
		push {r0, r1}
		sub sp, #0x4;
		mov r0, #100;
		bl RandInt
		cmp r0, #30;
		blt SkipRandomType1;
		mov r0, #1;
		mov r1, #18;
		bl RandRange
		add r3, r6, r0, lsl #2;
	SkipRandomType1:
		mov r0, #1;
		str r3, [sp, #0x0];
		mov r1, sp;
		bl EditItemAtTableIdx
		add sp, #0x4;
		pop {r0, r1}
		cmp r4, #2;
		blt success_return;
		mov r3, r1;
		push {r0}
		sub sp, #0x4;
		mov r0, #100;
		bl RandInt
		cmp r0, #30;
		blt SkipRandomType2;
		mov r0, #1;
		mov r1, #18;
		bl RandRange
		add r3, r6, r0, lsl #2;
	SkipRandomType2:
		mov r0, #2;
		str r3, [sp, #0x0];
		mov r1, sp;
		bl EditItemAtTableIdx
		add sp, #0x4;
		pop {r0}
		cmp r4, #3;
		blt success_return;
		mov r3, r0;
		mov r0, #100;
		bl RandInt
		cmp r0, #30;
		blt SkipRandomType3;
		mov r0, #1;
		mov r1, #18;
		bl RandRange
		add r3, r6, r0, lsl #2;
	SkipRandomType3:
		mov r0, #3;
		sub sp, #0x4;
		str r3, [sp, #0x0];
		mov r1, sp;
		bl EditItemAtTableIdx
		add sp, #0x4;
	success_return:
		mov r0, r4;
	return:
		add sp, #0x4;
		pop {r4-r6,r8-r11}
		b ProcJumpAddress
		.pool
	.endarea
.close