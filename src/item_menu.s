.align

NewMenuStart:
	mvn	r3, #0
	push	{r4, r5, lr}
	ldr	r5, [pc, #204]
	cmp	r0, #80
	sub	sp, sp, #180
	strb	r3, [r5]
	beq	MENU_label_0
MENU_label_1:
	add	sp, sp, #180
	pop	{r4, r5, pc}
MENU_label_0:
	mov	r4, #0
	ldr	r1, [pc, #176]
	mov	r2, #152
	str	r4, [sp, #12]
	add	r0, sp, #24
	strh	r1, [sp, #12]
	mov	r1, r4
	str	r4, [sp, #16]
	str	r4, [sp, #8]
	strb	r3, [sp, #17]
	str	r4, [sp, #20]
	bl	memset
	ldr	r3, [pc, #136]
	strh	r3, [sp, #32]
	mov	r3, #16
	str	r3, [sp, #36]
	bl	GetCurrentBagCapacity
	cmp	r0, #0
	ble	MENU_label_1
	ldr	r3, [pc, #112]
	mov	r1, r4
	ldr	r2, [r3]
	mov	r3, r4
	ldr	lr, [pc, #100]
MENU_label_2:
	ldrb	r12, [r2]
	add	r2, r2, #6
	tst	r12, #1
	strneb	r3, [lr, r1]
	add	r3, r3, #1
	addne	r1, r1, #1
	cmp	r0, r3
	bne	MENU_label_2
	cmp	r1, #0
	beq	MENU_label_1
	cmp	r1, #8
	movlt	r12, r1
	movge	r12, #8
	str	r1, [sp]
	ldr	r3, [pc, #44]
	ldr	r1, [pc, #44]
	add	r2, sp, #24
	add	r0, sp, #8
	str	r12, [sp, #4]
	bl	CreateAdvancedMenu
	strb	r0, [r5]
	b	MENU_label_1
	.word	CUSTOM_MENU_ID
	.word	0x00000202
	.word	0x0000032f
	.word	BAG_ITEMS_PTR
	.word	ITEM_INDICES
	.word	ItemSetEntryFn
	.word	0x10001813

NewMenuEnd:
	push	{r4, r5, r6, r7, r8, r9, lr}
	ldr	r4, [pc, #220]
	sub	sp, sp, #12
	ldrb	r3, [r4]
	cmp	r3, #255
	beq	MENU_label_3
	cmp	r0, #80
	beq	MENU_label_4
MENU_label_5:
	mov	r0, #0
MENU_label_6:
	add	sp, sp, #12
	pop	{r4, r5, r6, r7, r8, r9, pc}
MENU_label_4:
	mov	r0, r3
	bl	IsAdvancedMenuActive
	subs	r5, r0, #0
	bne	MENU_label_5
	ldrb	r0, [r4]
	bl	GetAdvancedMenuResult
	mov	r3, r0
	ldrb	r0, [r4]
	mov	r4, r3
	bl	CloseAdvancedMenu
	cmp	r4, #0
	movlt	r0, #2
	blt	MENU_label_6
	ldr	r8, [pc, #132]
	ldrb	r0, [r8, r4]
	bl	GetItemAtIdx
	ldrh	r7, [r0, #4]
	ldrh	r9, [r0, #2]
	mov	r6, r0
	mov	r0, r7
	bl	GetItemCategoryVeneer
	mov	r3, r0
	mov	r2, r9
	mov	r0, r5
	mov	r5, r3
	add	r1, sp, #4
	strh	r7, [sp, #4]
	strh	r2, [sp, #6]
	bl	item_Set
	// Needs to be changed to not dupe stackables!
	cmp	r5, #1
	movls	r5, #1
	movhi	r5, #0
	cmp	r9, #1
	movls	r5, #0
	cmp	r5, #0
	beq	MENU_label_7
	ldrh	r3, [r6, #2]
	sub	r3, r3, #1
	strh	r3, [r6, #2]
MENU_label_8:
	mov	r0, #1
	b	MENU_label_6
MENU_label_3:
	mov	r0, r3
	add	sp, sp, #12
	pop	{r4, r5, r6, r7, r8, r9, pc}
MENU_label_7:
	ldrb	r0, [r8, r4]
	bl	RemoveItemNoHole
	b	MENU_label_8
	.word	CUSTOM_MENU_ID
	.word	ITEM_INDICES

MenuStartHook:
	mov	r0, r5
	bl	NewMenuStart
	b	MenuStartFinish

MenuEndHook:
	bl	NewMenuEnd
	str	r0, [r6]
	b	MenuEndFinish

ItemSetEntryFn:
	push	{r4, lr}
	ldr	r3, [pc, #48]
	sub	sp, sp, #8
	mov	r4, r0
	ldrb	r0, [r3, r1]
	bl	GetItemAtIdx
	mov	r3, #1
	mov	r1, r0
	ldr	r2, [pc, #24]
	mov	r0, r4
	str	r3, [sp]
	bl	GetItemNameAdvanced
	mov	r0, r4
	add	sp, sp, #8
	pop	{r4, pc}
	.word	ITEM_INDICES
	.word	0x02322b8c

CUSTOM_MENU_ID:
	.byte 0xFF
ITEM_INDICES:
	.fill 50, 0x0

.align