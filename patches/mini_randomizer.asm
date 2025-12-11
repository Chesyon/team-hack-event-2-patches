.nds
.include "symbols.asm"

.open "arm9.bin", arm9_start
    .org GetTypeHook
    .area 0x4
        b GetRandomizedTypeTrampoline
    .endarea
.close

.open "overlay29.bin", overlay29_start
    .org RandomizeReseedHook
    .area 0x4
        bl ReseedRandomizer
    .endarea

    .org RandomizePalettesHook
    .area 0x4
        bl RandomizeSpawnlistPalettes
    .endarea

    .org RandomizeAttackPalettesHook
    .area 0x4
        bl RandomizeAttackPaletteTrampoline
    .endarea
.close