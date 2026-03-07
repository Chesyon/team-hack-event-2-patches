.nds
.include "symbols.asm"

.open "overlay11.bin", overlay11_start
    .org JumperGroundModeHook
        // Replaces GetPressedButtons Call as a Wrapper
        bl JumperGroundModeCheck
.close