DBoxFormatHook:
	push {r4,r5,r14}
	mov r4,r0
	mov r0,#0
	mov r1,#0x4E;
	mov r2,#63; // Flag 63 is for Custom Dialogue Boxes
	bl LoadScriptVariableValueAtIndex
	cmp r0,#0x1
	movne r0,r4
	movne r6,r0
	popne {r4,r5,r15}
	ldr r4,=NEW_DBOX_FORMATS
	add r4,r4,#4
	mov r5,#0
var_loop:
	mov r0,#0
	mov r1,#5
	mov r2,r5
	bl LoadScriptVariableValueAtIndex
	strb r0,[r4],#+0x1
	cmp r5,#6
	addlt r5,r5,#1
	blt var_loop
	ldr r0,=NEW_DBOX_FORMATS
	mov r6,r0 ; // Original instruction
	pop {r4,r5,r15}

.pool
NEW_DBOX_FORMATS:
	; // First four bytes are the function to update stuff
	.byte 0x88
	.byte 0xF4
	.byte 0x02
	.byte 0x02
	.byte 0x0 ; //  X offset
	.byte 0x5 ; // Y offset
	.byte 0xF ; // Width
	.byte 0x12 ; // Height
	.byte 0x0 ; // Screen
	.byte 0xFA ; // Frame Type (0xFA for blank)
	.fill 0x10, 0x0 ; // .fill 0x6, 0x0
.align
