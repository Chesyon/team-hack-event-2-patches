#include <pmdsky.h>
#include <cot.h>
#include "actor.h"
#include "palette.h"
#include "hsv.h"

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


enum litwick_mode{
    LITWICK_EEPY,
    LITWICK_ENERGETIC,
    LITWICK_CHILL,
    LITWICK_STARTLED,
    LITWICK_SPOOKY,
};
enum litwick_mode current_litwick_mode;

static int GetLitwickHueShift(){
    switch(current_litwick_mode){
        case LITWICK_EEPY:      return -50;
        case LITWICK_ENERGETIC: return 180;
        case LITWICK_CHILL:     return -110;
        case LITWICK_STARTLED:  return 130;
        default:                return 0;
    }
}

static void SpSetLitwickSpritePalette(){
    // get litwick mode based on system clock. this SP should ONLY be called when loading the room!
    struct system_clock clock; 
    GetSystemClock(&clock);
    if(clock.hour >= 1 && clock.hour < 5) current_litwick_mode = LITWICK_EEPY;
    else if(clock.hour < 10) current_litwick_mode = LITWICK_ENERGETIC;
    else if(clock.hour < 15) current_litwick_mode = LITWICK_CHILL;
    else if(clock.hour < 20) current_litwick_mode = LITWICK_STARTLED;
    else current_litwick_mode = LITWICK_SPOOKY;
    // Find litwick actor
    struct live_actor_custom * live_actor_list_tmp = ((struct live_actor_list_custom*)(GROUND_STATE_PTRS.actors))->actors;
    for(int i = 0; i < 24; i++){
        struct live_actor_custom* actor = &(live_actor_list_tmp[i]);
        if(actor->height != 0){ // TODO: find a better way to do this that won't break if anyone else changes an NPC's height before running this SP.
            // litwick actor found, get its palette info.
            struct AnimationSub * animation_sub = &actor->animation.sub_content;
            int render_bank_id_unlooked = animation_sub->field56_0x7a;
            int render_bank_id = SPRITE_BANK_ID_SOMETHING_IDK[render_bank_id_unlooked];
            struct AnotherRenderAllocStuff* another_sprite_alloc_stuff = &ANOTHER_SPRITE_RENDER_THING->something_rndr[render_bank_id];
            ImportantPaletteRelatedStruct* imp_pal_rel_struct = another_sprite_alloc_stuff->pnt_at_byte_8;
            uint32_t* vanilla_palette_ptr = (uint32_t*) imp_pal_rel_struct->pal_1.rgba_palette;
            int palette_start_count = (animation_sub->field29_0x41 & 0xf) << 4;
            // hueshift every color in the palette
            for(int i = 0; i < 16; i++){
                #define active_color vanilla_palette_ptr[palette_start_count + i]
                active_color = rgb_to_packed(
                    hueshift_rgb(
                        packed_to_rgb(active_color),
                        GetLitwickHueShift()
                    )
                );
            }
            imp_pal_rel_struct->pal_1.need_update = true;
            break;
        }
    }
}

static void SpSetLitwickPortraitPalette(){
    // TODO: the whole function
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
        case 101:
            SpSetLitwickSpritePalette();
            return true;
        case 102:
            SpSetLitwickPortraitPalette();
            return true;
        default:
            return false;
    }
}
