// Sometimes when using snd_stream all sounds stop besides the last portion of snd_stream.
// snd_stream is doing as it was designed and letting the last portion of music it decoded
// loop just in case the cpu is under heavy load. However, sometimes the The Digital Sound
// Elements audio engine needs to be re-ticked. Why? I don't know. Additionally, support
// setting the snd_stream reload byte if for whatever reason it's needed. Note: for
// convenience the dungeon_mode hook has been placed into move_shortcuts.c

#include <pmdsky.h>
#include <cot.h>

extern bool JumperMagicAddr;
extern bool SndStreamReloadAddr;
extern uint32_t *GetPressedButtonsTweak(int controller, uint32_t *button_flags_ptr);
extern void FUN_022DC808_NA();

void __attribute__((used)) JumperGroundModeCheck() {
    uint32_t button_flags = 0x00000000;
    int controller = 0;
    GetPressedButtonsTweak(controller, &button_flags);

    // L Button (Hold)
    if(button_flags & 0x00000200) {
        // Select Button (Tap)
        if(button_flags & 0x0008) {
            JumperMagicAddr = true;
        }
        // Start Button (Tap)
        if(button_flags & 0x0004) {
            SndStreamReloadAddr = true;
        }
    }

    FUN_022DC808_NA();
}