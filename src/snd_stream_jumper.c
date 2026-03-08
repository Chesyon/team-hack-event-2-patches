// Sometimes when using snd_stream all sounds stop besides the last portion of snd_stream.
// snd_stream is doing as it was designed and letting the last portion of music it decoded
// loop just in case the cpu is under heavy load. However, sometimes the The Digital Sound
// Elements audio engine needs to be re-ticked. Why? I don't know. Additionally, support
// setting the snd_stream reload byte if for whatever reason it's needed. Note: for
// convenience the dungeon_mode hook has been placed into move_shortcuts.c

#include <pmdsky.h>
#include <cot.h>

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

extern bool JumperMagicAddr;
extern bool SndStreamReloadAddr;
extern bool SndStreamPlayingAddr;
extern bool *GetPressedButtonsTweak(int controller, struct controller_status* controller_status);
extern void FUN_022DC808_NA();

bool reload_lockout = false;
bool jumper_lockout = false;

void __attribute__((used)) JumperGroundModeCheck() {
    FUN_022DC808_NA(); // Original Instruction
    if(false == SndStreamPlayingAddr) {
        return;
    }

    struct controller_status controller_status = {};
    int controller = 0;
    GetPressedButtonsTweak(controller, &controller_status);

    // L Button (Hold)
    if(controller_status.l_button) {
        // Start Button (Hold)
        if(controller_status.start_button && !jumper_lockout) {
            JumperMagicAddr = true;
            jumper_lockout = true;
        }
        // Select Button (Hold)
        if(controller_status.select_button && !reload_lockout) {
            SndStreamReloadAddr = true;
            reload_lockout = true;
        }
    } else {
        reload_lockout = false;
        jumper_lockout = false;
    }
}