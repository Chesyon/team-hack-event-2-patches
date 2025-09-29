#include <pmdsky.h>
#include <cot.h>
#include "litwick.h"
#include "hsv.h"

#define LITWICK_SPECIES 584
#define LITWICK_ACTOR_LIST_IDX 396

enum litwick_mode{
    LITWICK_EEPY, // 0
    LITWICK_ENERGETIC, // 1
    LITWICK_CHILL, // 2
    LITWICK_STARTLED, // 3
    LITWICK_SPOOKY, // 4
};
enum litwick_mode current_litwick_mode;

int GetLitwickHueShift(){
    switch(current_litwick_mode){
        case LITWICK_EEPY:      return -50;
        case LITWICK_ENERGETIC: return 180;
        case LITWICK_CHILL:     return -110;
        case LITWICK_STARTLED:  return 130;
        default:                return 0;
    }
}

void SpSetLitwickSpritePalette(){
    // assign litwick mode based on system clock. this SP should ONLY be called when loading the room!
    struct system_clock clock; 
    GetSystemClock(&clock);
    if(clock.hour == 0 || clock.hour >= 20) current_litwick_mode = LITWICK_SPOOKY; 
    else if(clock.hour >= 1 && clock.hour < 5) current_litwick_mode = LITWICK_EEPY;
    else if(clock.hour < 10) current_litwick_mode = LITWICK_ENERGETIC;
    else if(clock.hour < 15) current_litwick_mode = LITWICK_CHILL;
    else current_litwick_mode = LITWICK_STARTLED;
    // Find litwick actor
    struct live_actor * live_actor_list_tmp = (GROUND_STATE_PTRS.actors)->actors;
    for(int i = 0; i < 24; i++){
        struct live_actor* actor = &(live_actor_list_tmp[i]);
        if(actor->entity.kind == LITWICK_ACTOR_LIST_IDX){
            // litwick actor found, get its palette info.
            struct animation_control * ctrl = &actor->animation.ctrl;
            int8_t render_bank_id_unlooked = ctrl->palette_bank;
            int render_bank_id = SPRITE_BANK_ID_SOMETHING_IDK[render_bank_id_unlooked];
            struct AnotherRenderAllocStuff* another_sprite_alloc_stuff = &ANOTHER_SPRITE_RENDER_THING->something_rndr[render_bank_id];
            ImportantPaletteRelatedStruct* imp_pal_rel_struct = another_sprite_alloc_stuff->pnt_at_byte_8;
            uint32_t* vanilla_palette_ptr = (uint32_t*) imp_pal_rel_struct->pal_1.rgba_palette;
            int palette_start_count = (ctrl->palette_pos_low & 0xf) << 4;
            // hueshift every color in the palette
            int hue_shift = GetLitwickHueShift();
            for(int i = 0; i < 16; i++){
                #define active_color vanilla_palette_ptr[palette_start_count + i]
                active_color = rgb_to_packed(
                    hueshift_rgb(
                        packed_to_rgb(active_color),
                        hue_shift
                    )
                );
            }
            imp_pal_rel_struct->pal_1.need_update = true;
            break;
        }
    }
}

// Returns the current litwick mode.
int SpGetLitwickMode(){
    return current_litwick_mode;
}

void __attribute((used)) KaomadoBufTamper(struct kaomado_buffer *buf, struct monster_id_16 monster_id){
    if(monster_id.val == LITWICK_SPECIES){
        int hue_shift = GetLitwickHueShift();
        for(int i = 0; i < 16; i++){
            struct rgb color = buf->palette[i];
            buf->palette[i] = hueshift_rgb(color, hue_shift);
        }
    }
}

// r0: TRUE
// r1-r3: DataTransferStop garbage
// r6: number of bytes put into buf by FileRead
// r9: kaomado_buffer *buf
// r10: portrait_params *params
void __attribute__((naked)) KaomadoBufTamperWrapper(){
    asm("mov   r0,r9"); // param 1: kaomado buffer *
    asm("ldrsh r1,[r10]"); // param 2: portrait_params->monster_id
    asm("bl KaomadoBufTamper");
    asm("mov   r0,#1"); // Restore return value for LoadPortrait
    asm("b LoadPortraitReturn"); // Original instruction
}
