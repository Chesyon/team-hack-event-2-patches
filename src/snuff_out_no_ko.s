CanTheMoveKO:

cmp r0, r1
moveq r5, #1
beq IDontKnowMayItKO

ldr r0, =#413 // snuff out's ID
cmp r0, r1
bne IDontKnowMayItKO

ldr r0, [r7, #0xb4] // r7 is the target, r8 is the user and r4 is the user's monster struct, but nothing holds the target's monster struct????
ldrb r1, [r0, #0x6]
cmp r1, #0
moveq r5, #1
movne r5, #0
b IDontKnowMayItKO
