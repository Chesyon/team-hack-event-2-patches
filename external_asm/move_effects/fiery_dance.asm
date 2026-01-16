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
.definelabel MoveStartAddress, 0x2330134 ; if the rom is EU, use 0x2330B74 instead
.definelabel MoveJumpAddress, 0x23326CC ; if the rom is EU, use 0x233310C instead
.definelabel InitMove, 0x20137B8
.definelabel RaiseOffensiveStat, 0x231399C
.definelabel DungeonRandOutcome, 0x22EAB50

; JP rom will be added as soon as someone slaps me in the face with the addresses

.definelabel MaxSize, 0x2598

.create "./code_out.bin", 0x2330134
    .org MoveStartAddress
    .area MaxSize
    sub sp,sp,#0x18
	
	mov  r0,r9
	mov  r1,r4
	mov  r2,r8
	mov  r3,#0x100
	bl   DealDamage

	cmp  r0, #0
	beq  return ; dont increase sp atk if we didnt do damage!

	mov  r0, #50
	bl   DungeonRandOutcome
	cmp  r0, #0
	beq  return ; take the coin flip!

	mov  r0, r9
	mov  r1, r9
	mov  r2, #1
	mov  r3, #1
	bl   RaiseOffensiveStat
	
    return:
        add sp,sp,#0x18
        b   MoveJumpAddress
        .pool
    .endarea
.close