// r1: the ID of the used move
// r4: user's monster struct
// r5: whether or not the move can KO
// r6: ???
// r7: target's entity struct
// r8: user's entity struct

CanTheMoveKO:

cmp r0, r1
moveq r5, #1
beq IDontKnowMayItKO

ldr r0, =#413 // snuff out's ID
cmp r0, r1
movne r5, #0
bne IDontKnowMayItKO

ldr r0, [r7, #0xb4] // r7 is the target, r8 is the user and r4 is the user's monster struct, but nothing holds the target's monster struct????
ldrb r1, [r0, #0x6]
ldr r0, [r6, #0xb4]
ldrb r0, [r0, #0xb4]
cmp r1, r0
moveq r5, #1
movne r5, #0
b IDontKnowMayItKO
