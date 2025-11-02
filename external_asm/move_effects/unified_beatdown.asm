; r4 = Target
; r5 = Garbage Data
; r6 = Move ID
; r7 = ID of the item that called the move (for orbs. If the move is not for an orb, ignore this)
; r8 = Move Data
; r9 = User
; 10 = Unknown (usually 0 or 1, no clue on the context)

; NOTE: registers r4 through r9, r11 and r13/sp must remain unchanged by the time the code reaches `b MoveJumpAddress`
; if you need to use these registers, use push/pop commands
; push stores its current value and pop returns it to the value that was stored

.relativeinclude on
.nds
.arm

.include "lib/stdlib_us.asm"
.include "lib/dunlib_us.asm"
.definelabel MoveStartAddress, 0x2330134
.definelabel MoveJumpAddress, 0x23326CC
.definelabel TryInflictTerrifiedStatus, 0x2314E60
.definelabel DungeonRandOutcome, 0x22EAB20
.definelabel DungeonRandInt, 0x22EAA98
.definelabel SoundproofAbilityID, 0x3C ; 60
.definelabel SoundproofStrID, 0xEB9 ; 3769
.definelabel DUNGEON_PTR, 0x02353538
.definelabel TryInflictCringeStatus, 0x23143E8
.definelabel LowerOffensiveStat, 0x23135FC
.definelabel LowerSpeed, 0x2314954
.definelabel LowerDefensiveStat, 0x2313814
.definelabel TryWarp, 0x2320D08
.definelabel EntityIsValid, 0x22E0354
.definelabel TryInflictConfusedStatus, 0x2314F38

; unified beatdown is a single strike in solo form, but 3 strikes in schooling form. for balancing reasons, the 3 strikes deal 40% of the original damage.

.definelabel MaxSize, 0x2598

.create "./code_out.bin", 0x2330134
    .org MoveStartAddress
    .area MaxSize

    	sub sp,sp,#4

	ldr  r0, [r9, #0xb4]
	ldrh r1, [r0, #0x4] ; note that im using apparent ID instead of ID. this is because apparent ID is what should change for form changing mons like wishiwashi
	ldr  r2, =539 ; note: change this to 0x219 later. its set to charmanders ID for testing
	cmp  r1, r2
	beq  TripleStrike

	mov  r0,r9
	mov  r1,r4
	mov  r2,r8
	mov  r3,#0x100
	bl   DealDamage

	b    return

	TripleStrike:

	mov  r0,r9
	mov  r1,r4
	mov  r2,r8
	mov  r3,#0x66
	bl   DealDamage

	mov  r0, r4
	bl   EntityIsValid
	cmp  r0, #1
	bne  return

	mov  r0,r9
	mov  r1,r4
	mov  r2,r8
	mov  r3,#0x66
	bl   DealDamage

	mov  r0, r4
	bl   EntityIsValid
	cmp  r0, #1
	bne  return

	mov  r0,r9
	mov  r1,r4
	mov  r2,r8
	mov  r3,#0x66
	bl   DealDamage


    return:
        add  sp,sp,#4
        b    MoveJumpAddress
	
        .pool
    .endarea

.close
