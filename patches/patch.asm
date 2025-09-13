// Replace the "GetMovePower" function with a custom one.
// Since a branch is inserted at the start of the function, the function is practically
// replaced with our own. The "b" instruction doesn't modify the link register, so
// execution will continue after the call to `GetMovePower` once our function returns.

.nds
.include "symbols.asm"

// Man idk if this is how to do this or not, Chesyon fixit! - Lappy
.open "arm9.bin", arm9_start
    ; Replace the function ChangeGiratinaFormIfSkyDungeon with a call to the custom function.
    .org CHANGE_GIRATINA_FORM_HOOK
    .area 0x8
        bl GroundCustomFormsChange
        pop r4-r8,pc;
    .endarea

    ; Replace the function RevertGiratinaAndShaymin with a call to the custom function.

    ; Check if the item was thrown with the pierce effect active and would normally fly off screen.
    .org REVERT_GIRATINA_AND_SHAYMIN_FORM_HOOK
    .area 0x8
        bl GroundRevertTeamMember
        pop r3-r5,pc;
    .endarea
	
	.org TRANSFORM_UNIT_HOOK
	.area 0x4
		bl TransformUnitAdventureActor;
	.endarea

	.org TRANSFORM_ADVENTURE_HOOK
	.area 0x4
		bl TransformUnitAdventureActor;
	.endarea	
	
	.org TRANSFORM_MC1_HOOK
	.area 0x4
		bl TransformMC1Actor;
	.endarea

	.org TRANSFORM_MC2_HOOK
	.area 0x4
		bl TransformMC2Actor;
	.endarea

	.org TRANSFORM_MC3_HOOK
	.area 0x4
		bl TransformMC3Actor;
	.endarea

	.org TRANSFORM_APPOINT_HOOK
	.area 0x4
		bl TransformAppointActor;
	.endarea

	.org TRANSFORM_HERO_HOOK
	.area 0x4
		bl TransformHeroActor;
	.endarea

	.org TRANSFORM_PARTNER_HOOK
	.area 0x4
		bl TransformPartnerActor;
	.endarea

.close


.open "overlay29.bin", overlay29_start
    .org CALC_DAMAGE_FORM_OFFENSE_HOOK
    .area 0x3C
        mov r0, r6;
        ldr r1, [sp, 0x18];
        mov r2, #0x0; // ATK
        bl ApplyFormStatBoosts;
        add r4, r0;
        nop;
        nop;
        nop;
        nop;
        nop;
        nop;
        nop;
        nop;
        nop;
        nop;
    .endarea

    .org CALC_DAMAGE_FORM_DEFENSE_HOOK
    .area 0x3C
        mov r0, r7;
        ldr r1, [sp, 0x18];
        mov r2, #0x1; // DEF
        bl ApplyFormStatBoosts;
        add r4, r0;
        nop;
        nop;
        nop;
        nop;
        nop;
        nop;
        nop;
        nop;
        nop;
        nop;
    .endarea

    .org HOOK_DUNGEON_FORM_CHANGE_1
    .area 0x4
        bl ValidateSpeciesFormsWrapper1
    .endarea

    .org HOOK_DUNGEON_FORM_CHANGE_2
    .area 0x4
        bl ValidateSpeciesFormsWrapper2
    .endarea

	.org UNK_BURT_HOOK_1
	.area 0x4
		bl HandleFaint
	.endarea

	.org UNK_BURT_HOOK_2
	.area 0x4
		bl CheckIgnition
	.endarea

	.org UNK_BURT_HOOK_3
	.area 0x4
		bl HandleFaint
	.endarea

	.org UNK_BURT_HOOK_4
	.area 0x4
		b RegeneratorAbility
	.endarea
.close
