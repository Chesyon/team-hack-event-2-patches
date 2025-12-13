.nds
.include "symbols.asm"

.open "overlay29.bin", overlay29_start
    .org EntropyAccuracyHook
    .area 0x4
        b EntropyAccuracyCheck
    .endarea

    .org EntropySecondaryEffectHook
    .area 0x4
        beq EntropySecondaryEffectCheck
    .endarea

    .org EntropyStatusDurationHook
    .area 0x4
        bl EntropyStatusDurationCheck
    .endarea

    .org ChaosTypeHook
    .area 0x4
        bl ChaosTypeCheck
    .endarea

    .org ChaosWeatherHook
    .area 0x4
        bl ChaosWeatherCheck
    .endarea

    .org ChaosExplosionHook 
    .area 0x4
        bl ChaosExplosionCheck
    .endarea
.close