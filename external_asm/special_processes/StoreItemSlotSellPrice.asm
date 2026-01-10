; ------------------------------------------------------------------------------------------
; Store Item Slot Sell Price
; Returns the actual sell price in the item_Set() slot specified in the $CONDITION variable.
; Param 1: Slot ID to check the sell price for!
; Param 2: Nothing
; Returns: Nothing, but $CONDITION will contain the sell price for the specified item.
;		   Note: $CONDITION will be zero if the item can't be sold.
; -------------------------------------------------------------------------------------------

.relativeinclude on
.nds
.arm

.definelabel MaxSize, 0x810

; Uncomment/comment the following labels depending on your version.

; For US
.include "lib/stdlib_us.asm"
.definelabel ProcStartAddress, 0x022E7248
.definelabel ProcJumpAddress, 0x022E7AC0
.definelabel SaveScriptVariableValue, 0x204B820
.definelabel GetItemSellPrice, 0x200E9D8
.definelabel ItemAtTableIdx, 0x2065CF8;
.definelabel IsShoppableItem, 0x200CCE0;
.definelabel IsThrownItem, 0x200CB10;

; File creation
.create "./code_out.bin", 0x022E7248
	.org ProcStartAddress
	.area MaxSize ; Define the size of the area
		push {r8}
		sub sp, #0x4;
		mov r0, r7;
		mov r1, sp;
		bl ItemAtTableIdx
		ldrh r0, [sp, #0x0]
		bl IsShoppableItem
		cmp r0, #1;
		movne r2, #0;
		bne return;
		ldrh r0, [sp, #0x0]
		bl GetItemSellPrice
		mov r8, r0;
		ldrh r0, [sp, #0x0]
		bl IsThrownItem; // Stick and Stones will have their sell price multiplied by the item count. Treasure Boxes will not!
		cmp r0, #1;
		movne r2, r8;
		bne return;
		ldrh r0, [sp, #0x2];
		mul r2, r0, r8;
	return:
		mov r1, #1;
		bl SaveScriptVariableValue
		add sp, #0x4;
		pop {r8}
		b ProcJumpAddress
		.pool
	.endarea
.close