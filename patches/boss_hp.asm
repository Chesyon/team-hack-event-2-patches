.nds
.include "symbols.asm"

.open "overlay29.bin", overlay29_start
    .org BossHPCheckHook
        b BossHpCheckTrampoline
.close