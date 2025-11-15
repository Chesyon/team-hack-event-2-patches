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

extern void InitTreasureBagMenu();

// Special process 103: Teaches Sandsear Storm to the leader. Returns 0 once learned, otherwise returns -1 (which loops the SP)
#define SANDSEAR_STORM_MOVE_ID 411
#define SANDSEAR_STORM_TM_ID 349
bool tm_started = false;
struct item item_0_backup;
static int SpLearnSandsearStorm(){
    if(tm_started){
        if(!GetPerformanceFlagWithChecks(58)){ // has the menu code disabled the flag?
            tm_started = false;
            memcpy(BAG_ITEMS_PTR, &item_0_backup, sizeof(struct item)); // restore item at slot 0 to what it was before we overwrote it with tm
            // we actually DON'T want to return here. we let it keep running down to the for loop where it'll ensure larvesta actually learned the move, and start the process over if not.
        }
        else return -1; // tm still running
    }
    int move_slot = 0;
    for (; move_slot < 4; move_slot++){
        if(TEAM_MEMBER_TABLE_PTR->members[0].moves[move_slot].id.val == SANDSEAR_STORM_MOVE_ID) break;
    }
    if(move_slot < 4) return 0; // move known
    else { // move not known
        tm_started = true;
        memcpy(&item_0_backup, BAG_ITEMS_PTR, sizeof(struct item)); // backup item at slot 0 in bag because we're about to overwrite it
        RemoveItem(0);
        struct item new_item;
        InitItem(&new_item, SANDSEAR_STORM_TM_ID, 0, false);
        AddItemToBagNoHeld(&new_item);
        SaveScriptVariableValueAtIndex(NULL, VAR_PERFORMANCE_PROGRESS_LIST, 58, 1);
        InitTreasureBagMenu();
        return -1;
    }
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
        // 101 and 102 are for Chesyon's litwick NPC. These could probably be custom script instructions, but then I'd have to learn how those work.
        // As to not bloat this file, these functions are in their own file (litwick.c).
        case 101:
            SpSetLitwickSpritePalette();
            return true;
        case 102:
            *return_val = SpGetLitwickMode();
            return true;
        case 103:
            *return_val = SpLearnSandsearStorm();
            return true;
        default:
            return false;
    }
}
