#include <pmdsky.h>
#include <cot.h>

// By HeckaBad, originally written for One More Wish

/* The move shortcuts patch is loosely based off of the move shortcuts patch
   https://github.com/Frostbyte0x70/EoS-asm-patches/blob/1e5ebe4a216a5d3e4c7c8dd480b33c850d3d083f/src/MoveShortcuts.asm
   by Frostbyte0x70 for feel and look but not implementation.
*/

/* Note: While the top screen is in Team Stat mode, it creates 0xC (12) different
   windows. This gives us 8 windows to work with. However, this implementation
   will be using 5. (One for each move and the set item).
*/

// Easily Change Box Layout
#define MOVE_BOX_WIDTH 12
#define MOVE_BOX_HEIGHT 3
#define MOVE_BOX_BUTTON_SYMBOL_HEIGHT 12 // Technically 11, but 12 for rounding reasons to make it look better.
#define MOVE_BOX_BUTTON_SYMBOL_WIDTH 11
#define MOVE_BOX_BUTTON_H_OFFSET 3
#define MOVE_BOX_BUTTON_V_OFFSET ((MOVE_BOX_HEIGHT * 8) - MOVE_BOX_BUTTON_SYMBOL_HEIGHT)/2
#define MOVE_BOX_NAME_H_OFFSET 18
#define MOVE_BOX_NAME_V_OFFSET 1
#define MOVE_BOX_PP_V_OFFSET 11

#define MOVE_SHORTCUT_DO_NOTHING 0
#define MOVE_SHORTCUT_CLOSED 1
#define MOVE_SHORTCUT_MOVE_USED 2
#define MOVE_SHORTCUT_ITEM_USED 3

// I don't think the second parameter is used since the function immediately
// clobbers r1. However, give it just in case.
extern void SetDisplayMode(int display_mode, int unusued);
extern int GetStringWidth(char* str);

typedef struct controller_status {
    bool a_button : 1;      // 0  - 0x0001
    bool b_button : 1;      // 1  - 0x0002
    bool select_button : 1; // 2  - 0x0004
    bool start_button : 1;  // 3  - 0x0008
    bool dpad_right : 1;    // 4  - 0x0010
    bool dpad_left : 1;     // 5  - 0x0020
    bool dpad_up : 1;       // 6  - 0x0040
    bool dpad_down : 1;     // 7  - 0x0080
    bool r_button : 1;      // 8  - 0x0100
    bool l_button : 1;      // 9  - 0x0200
    bool x_button : 1;      // 10 - 0x0400
    bool y_button : 1;      // 11 - 0x0800
    uint8_t unused : 4;     // Probably!
    bool a_button_tap : 1;      // 0  - 0x0001
    bool b_button_tap : 1;      // 1  - 0x0002
    bool select_button_tap : 1; // 2  - 0x0004
    bool start_button_tap : 1;  // 3  - 0x0008
    bool dpad_right_tap : 1;    // 4  - 0x0010
    bool dpad_left_tap : 1;     // 5  - 0x0020
    bool dpad_up_tap : 1;       // 6  - 0x0040
    bool dpad_down_tap : 1;     // 7  - 0x0080
    bool r_button_tap : 1;      // 8  - 0x0100
    bool l_button_tap : 1;      // 9  - 0x0200
    bool x_button_tap : 1;      // 10 - 0x0400
    bool y_button_tap : 1;      // 11 - 0x0800
    uint8_t unused_tap : 4;     // Probably!
} controller_status;
ASSERT_SIZE(controller_status, 0x4);
extern controller_status DUNGEON_CONTROLLER_STATUS;

// This struct is slightly different from touchscreen_status and has the order
// of the items 
typedef struct dungeon_touchscreen_status {
    // True if any contact is being made.
    bool touched : 1;     // 0x0001
    bool just_touched : 1; // 0x0002
    bool released : 1;    // 0x0004
    bool released_tap : 1; // 0x0008
    bool released_tap_double_tap_window_active : 1; // Maybe?
    bool released_double_tap : 1; // 0x0020
    bool tapped : 1;            // 0x0040
    bool double_tap : 1;         // 0x0080
    bool holding : 1;           // 0x0100
    bool double_tap_and_hold: 1;   // 0x0200
    bool single_tap_hold : 1;     // 0x0400
    bool double_tap_hold : 1;     // 0x0800
    bool long_hold : 1;          // 0x1000
    // This could very well be something else like the window to untouch to be
    // considered a tap to close?
    bool something_related_to_single_tap_hold : 1; // 0x2000
    bool single_tap_long_hold : 1; // 0x4000
    bool double_tap_long_hold : 1; // 0x8000
    undefined2 padding; // Probably.
    int pixel_position_x;      // 0x4
    int pixel_position_y;      // 0x8
    int last_pixel_position_x;  // 0xC
    int last_pixel_position_y;  // 0x10
    int first_pixel_position_x; // 0x14
    int first_pixel_position_y; // 0x18
    undefined4 field_0x1C;
    undefined4 field_0x20;
    undefined4 field_0x24;
    undefined4 field_0x28;
    // 0x2C: Stop the player from using the touchscreen to input into
    // a menu and accidentally cause the player to walk by holding the
    // touchscreen after the menu has closed.
    bool prevent_misinput;
    undefined field_0x2d;
    undefined field_0x2e;
    undefined field_0x2f;
} dungeon_touchscreen_status;
ASSERT_SIZE(dungeon_touchscreen_status, 0x30);
extern dungeon_touchscreen_status DUNGEON_TOUCHSCREEN_STATUS;

// TODO: To add touchscreen functionality for move shortcuts create a way to
// close the menu. Perhaps a box that can be tapped?
bool move_shortcuts_enabled = true;
bool move_box_displayed = false;

signed char move_box_right_id = -2;
signed char move_box_bottom_id = -2;
signed char move_box_left_id = -2;
signed char move_box_top_id = -2;

// How Move Shortcuts Looks In SkyTemple
struct window_params move_box_classic_layout = {
    .update = NULL,
    .x_offset = 0x2,
    .y_offset = 0x2,
    .width = 0x12,
    .height = 0xC,
    .screen = {.val = SCREEN_MAIN},
    .box_type = {.val = BOX_TYPE_NORMAL}
};

struct window_params move_box_top_layout = {
    .update = NULL,
    .x_offset = (32 - MOVE_BOX_WIDTH)/2,
    .y_offset = (24 - MOVE_BOX_HEIGHT*3)/2 - 2,
    .width = MOVE_BOX_WIDTH,
    .height = MOVE_BOX_HEIGHT,
    .screen = {.val = SCREEN_MAIN},
    .box_type = {.val = BOX_TYPE_NORMAL}
};

struct window_params move_box_right_layout = {
    .update = NULL,
    .x_offset = 32 - ((32 - MOVE_BOX_WIDTH*2)/3) - MOVE_BOX_WIDTH,
    .y_offset = (24 - MOVE_BOX_HEIGHT*3)/2 + MOVE_BOX_HEIGHT,
    .width = MOVE_BOX_WIDTH,
    .height = MOVE_BOX_HEIGHT,
    .screen = {.val = SCREEN_MAIN},
    .box_type = {.val = BOX_TYPE_NORMAL}
};

struct window_params move_box_bottom_layout = {
    .update = NULL,
    .x_offset = (32 - MOVE_BOX_WIDTH)/2,
    .y_offset = (24 - MOVE_BOX_HEIGHT*3)/2 + MOVE_BOX_HEIGHT*2 + 2,
    .width = MOVE_BOX_WIDTH,
    .height = MOVE_BOX_HEIGHT,
    .screen = {.val = SCREEN_MAIN},
    .box_type = {.val = BOX_TYPE_NORMAL}
};

struct window_params move_box_left_layout = {
    .update = NULL,
    .x_offset = (32 - MOVE_BOX_WIDTH*2)/3,
    .y_offset = (24 - MOVE_BOX_HEIGHT*3)/2 + MOVE_BOX_HEIGHT,
    .width = MOVE_BOX_WIDTH,
    .height = MOVE_BOX_HEIGHT,
    .screen = {.val = SCREEN_MAIN},
    .box_type = {.val = BOX_TYPE_NORMAL}
};

char* a_button_string = "[M:B2]";
char* b_button_string = "[M:B3]";
char* x_button_string = "[M:B4]";
char* y_button_string = "[M:B5]";
char* ginseng_string = "+%d";
char* pp_fraction_string = "[CS:%c]%2d/%2d[CR]";
char* move_display_string = "[CS:%c]%s[CR][CS:V]%s[CR]";

void DrawMoveInWindow(int idx, int x, int y, struct move *move) {
    if (move->f_exists == false) {
        return;
    }
    
    char *move_name_string = StringFromId(move->id.val + 0x1FEE);
    char move_buffer1[80];
    char move_buffer2[10];
    char color_tag;
    
    // These colors technically align with base game colors.
    if (move->f_disabled || move->f_sealed || move->pp == 0) {
        color_tag = 'W';
    } else {
        color_tag = 'M';
    }
    
    if (move->ginseng == 0) {
        move_buffer2[0] = '\0';
    } else {
        SprintfStatic(move_buffer2, ginseng_string, move->ginseng);
    }
    
    // Draw Move Name
    SprintfStatic(move_buffer1, move_display_string, color_tag, move_name_string, move_buffer2);
    DrawTextInWindow(idx, x, y, move_buffer1);
    // Draw Move PP
    int maxPp = GetMaxPp(move);
    if (move->pp <= maxPp/4) {
        color_tag = 'H'; // Pink
    } else if (move->pp <= maxPp/2) {
        color_tag = 'P'; // Dark Cream
    } else {
        color_tag = 'D'; // White
    }
    SprintfStatic(move_buffer1, pp_fraction_string, color_tag, move->pp, maxPp);
    int x_offset_pp = ((GetWindow(idx)->params.width * 8) - GetStringWidth(move_buffer1))/2;
    DrawTextInWindow(idx, x_offset_pp, y + MOVE_BOX_PP_V_OFFSET, move_buffer1);
}

void CreateMoveBoxesForMonster(struct monster *monster) {
    if(move_box_displayed) {
        return;
    }
    
    if (move_box_right_id == -2) {
        move_box_right_id = CreateTextBox(&move_box_right_layout, NULL);
        DrawTextInWindow(move_box_right_id, MOVE_BOX_BUTTON_H_OFFSET, MOVE_BOX_BUTTON_V_OFFSET, a_button_string);
        DrawMoveInWindow(move_box_right_id, MOVE_BOX_NAME_H_OFFSET, MOVE_BOX_NAME_V_OFFSET, &(monster->moves[0]));
        UpdateWindow(move_box_right_id);
    }
    if (move_box_bottom_id == -2) {
        move_box_bottom_id = CreateTextBox(&move_box_bottom_layout, NULL);
        DrawTextInWindow(move_box_bottom_id, MOVE_BOX_BUTTON_H_OFFSET, MOVE_BOX_BUTTON_V_OFFSET, b_button_string);
        DrawMoveInWindow(move_box_bottom_id, MOVE_BOX_NAME_H_OFFSET, MOVE_BOX_NAME_V_OFFSET, &(monster->moves[1]));
        UpdateWindow(move_box_bottom_id);
    }
    if (move_box_left_id == -2) {
        move_box_left_id = CreateTextBox(&move_box_left_layout, NULL);
        DrawTextInWindow(move_box_left_id, MOVE_BOX_BUTTON_H_OFFSET, MOVE_BOX_BUTTON_V_OFFSET, y_button_string);
        DrawMoveInWindow(move_box_left_id, MOVE_BOX_NAME_H_OFFSET, MOVE_BOX_NAME_V_OFFSET, &(monster->moves[2]));
        UpdateWindow(move_box_left_id);
    }
    if (move_box_top_id == -2) {
        move_box_top_id = CreateTextBox(&move_box_top_layout, NULL);
        DrawTextInWindow(move_box_top_id, MOVE_BOX_BUTTON_H_OFFSET, MOVE_BOX_BUTTON_V_OFFSET, x_button_string);
        DrawMoveInWindow(move_box_top_id, MOVE_BOX_NAME_H_OFFSET, MOVE_BOX_NAME_V_OFFSET, &(monster->moves[3]));
        UpdateWindow(move_box_top_id);
    }
    
    move_box_displayed = true;
}

void CloseMoveBoxes() {
    if(!move_box_displayed) {
        return;
    }
    
    if (move_box_right_id != -2) {
        CloseTextBox(move_box_right_id);
        move_box_right_id = -2;
    }
    
    if (move_box_bottom_id != -2) {
        CloseTextBox(move_box_bottom_id);
        move_box_bottom_id = -2;
    }
    
    if (move_box_left_id != -2) {
        CloseTextBox(move_box_left_id);
        move_box_left_id = -2;
    }
    
    if (move_box_top_id != -2) {
        CloseTextBox(move_box_top_id);
        move_box_top_id = -2;
    }
    
    move_box_displayed = false;
}

// TODO: Stench check.
int __attribute__((used)) TryHandleMoveShortcuts(struct entity *leader) {
    // Check if L is being pressed. If not return.
    if(DUNGEON_CONTROLLER_STATUS.l_button == false) {
        return MOVE_SHORTCUT_DO_NOTHING;
    }
    
    struct monster *leader_monster = (struct monster*)leader->info;
    
    // If the leader is terrified, prevent move inputs.
    if(leader_monster->statuses.terrified != 0) {
        PlaySeByIdVolume(16131, 256);
        return MOVE_SHORTCUT_DO_NOTHING;
    }
    
    // Hide message log + minimap.
    SetDisplayMode(4, 0);
    if(DUNGEON_PTR->display_data.team_menu_or_grid) {
        // In case the player does something like press Y + L.
        HideTileGrid();
    }
    
    // These frame advances appear to be needed to properly hide/close message
    // log windows. Otherwise, they may glitch with some of the info from our
    // new windows for a frame. Another option is to create our new windows
    // before closing the old ones. However, this causes them to overlap for
    // a moment instead.
    AdvanceFrame(0xF);
    AdvanceFrame(0xF);
    
    CreateMoveBoxesForMonster(leader_monster);
    
    // This is a do while loop because we check controller status above. We do
    // not need to check again since we already know that it is pressed.
    do {
        // Grab all inputs.
        bool r_button = DUNGEON_CONTROLLER_STATUS.r_button_tap;
        bool a_button = DUNGEON_CONTROLLER_STATUS.a_button_tap;
        bool b_button = DUNGEON_CONTROLLER_STATUS.b_button_tap;
        bool y_button = DUNGEON_CONTROLLER_STATUS.y_button_tap;
        bool x_button = DUNGEON_CONTROLLER_STATUS.x_button_tap;

        // If multiple inputs are tapped at the same time, do nothing.
        int32_t ambiguous_input = (r_button + a_button + b_button + y_button + x_button) > 1;
        if(ambiguous_input) {
            AdvanceFrame(0xF);
            continue;
        }

        // Try to throw the set item.
        if (r_button) {
            int equipped_item_index = GetEquippedThrowableItem();
            if (MonsterHasEmbargoStatus(leader)) {
                PlaySeByIdVolume(16131, 256); // Embargo
            } else if (equipped_item_index < 0) {
                PlaySeByIdVolume(16131, 256); // Item Not Set
            } else {
                DUNGEON_PTR->prevent_misinputs = false;
                SetLeaderActionFields(ACTION_THROW_ITEM_PLAYER);
                leader_monster->action.action_parameters[0].action_use_idx = equipped_item_index + 1;
                leader_monster->action.action_parameters[0].item_pos.x = 0;
                leader_monster->action.action_parameters[0].item_pos.y = 0;
                CloseMoveBoxes();
                AdvanceFrame(0xF);
                AdvanceFrame(0xF);
                SetDisplayMode(0, 0);
                AdvanceFrame(0);
                return MOVE_SHORTCUT_ITEM_USED;
            }
        }

        // Check for a move to use.
        int move_to_use_index;
        if (a_button) {
            move_to_use_index = 0;
        } else if (b_button) {
            move_to_use_index = 1;
        } else if (y_button) {
            move_to_use_index = 2;
        } else if (x_button) {
            move_to_use_index = 3;
        } else {
            move_to_use_index = -1;
        }
        
        // Attempt to use move associated with the above combination.
        if(move_to_use_index > -1) {
            if(leader_monster->moves[move_to_use_index].f_exists) {
                struct move *move_to_use = &(leader_monster->moves[move_to_use_index]);
                if(move_to_use->f_disabled || move_to_use->f_sealed || move_to_use->f_subsequent_in_link_chain || move_to_use->pp == 0) {
                    PlaySeByIdVolume(16131, 256);
                } else {
                    DUNGEON_PTR->prevent_misinputs = false;
                    SetActionUseMovePlayer(&leader_monster->action, GetTeamMemberIndex(leader), move_to_use_index);
                    CloseMoveBoxes();
                    AdvanceFrame(0xF);
                    AdvanceFrame(0xF);
                    SetDisplayMode(0, 0);
                    AdvanceFrame(0);
                    return MOVE_SHORTCUT_MOVE_USED;
                }
            }
        }
        
        AdvanceFrame(0xF);
        
    } while (DUNGEON_CONTROLLER_STATUS.l_button);

    CloseMoveBoxes();
    AdvanceFrame(0xF);
    AdvanceFrame(0xF);
    SetDisplayMode(0, 0);
    return MOVE_SHORTCUT_CLOSED;
}

void __attribute__((naked)) __attribute__((used)) TryHandleMoveShortcutsTrampoline() {
    asm("mov   r0,r6"); // Pass the leader to the function.
    asm("bl    TryHandleMoveShortcuts");
    asm("cmp   r0,#0x1");
    asm("blt   MoveShortcutsMainCheckNormalUnhook");
    asm("beq   MoveShortcutsMainCheckLoopUnhook");
    asm("add   sp,sp,#0xDC");
    asm("ldmia sp!,{r4,r5,r6,r7,r8,r9,r10,r11,pc}");
}