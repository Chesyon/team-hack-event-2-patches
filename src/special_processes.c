#include <pmdsky.h>
#include <cot.h>
#include "litwick.h"

// Special process 100: Disable text drop shadow. If the first parameter is 0, drop shadow will be disabled. Otherwise, drop shadow will be enabled. Default: enabled.
// Code from One More Wish. Code written by Chesyon, using research from Adex.
// I'm not particularly worried about offsets here. I've checked the decomp and DrawChar is (almost) identical between NA and EU (with two minor one-instruction differences, neither of which affect function size).
// Oh right I should probably explain what this is doing. There are a couple `mov[condition] rX,#0x13` instructions throughout the DrawChar function. Replacing the #0x13s with #0x0s causes drop shadow to not render (I don't know WHY. Ask Adex.) This SP changes that code on the fly by writing either 0x0 or 0x13 to all those instructions based on the input parameter. Very janky but it's fast and gets the job done!
static void __attribute__((naked)) SpToggleDropShadow(bool enable){
    asm("cmp r0,#0");
    asm("movne r0,#0x13");
    asm("ldr r1,=0x202693C"); // EU: 0x2026C20
    asm("strb r0,[r1]");
    asm("add r1,r1,#0x54");
    asm("strb r0,[r1]");
    asm("add r1,r1,#0x48");
    asm("strb r0,[r1]");
    asm("add r1,r1,#0x44");
    asm("strb r0,[r1]");
    asm("add r1,r1,#0x98");
    asm("strb r0,[r1]");
    asm("bx lr");
}

// Called for special process IDs 100 and greater.
//
// Set return_val to the return value that should be passed back to the game's script engine. Return true,
// if the special process was handled.
bool CustomScriptSpecialProcessCall(undefined4* unknown, uint32_t special_process_id, short arg1, short arg2, int* return_val) {
    switch (special_process_id) {
        case 100:
            SpToggleDropShadow(arg1);
            return true;
        // 101-103 are for Chesyon's litwick NPC. These could probably be custom script instructions, but then I'd have to learn how those work.
        // As to not bloat this file, these functions are in their own file (litwick.c).
        case 101:
            SpSetLitwickSpritePalette();
            return true;
        case 102:
            *return_val = SpGetLitwickMode();
            return true;
        default:
            return false;
    }
}
