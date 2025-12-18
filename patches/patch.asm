.nds
.include "symbols.asm"

.open "arm9.bin", arm9_start
    ; Replace the function ChangeGiratinaFormIfSkyDungeon with a call to the custom function.
    .org CHANGE_GIRATINA_FORM_HOOK
    .area 0x8
        bl GroundCustomFormsChange
        pop r4-r8,pc
    .endarea

    ; Replace the function RevertGiratinaAndShaymin with a call to the custom function.

    ; Check if the item was thrown with the pierce effect active and would normally fly off screen.
    .org REVERT_GIRATINA_AND_SHAYMIN_FORM_HOOK
    .area 0x8
        bl GroundRevertTeamMember
        pop r3-r5,pc
    .endarea
	
	.org TRANSFORM_UNIT_HOOK
	.area 0x4
		bl TransformUnitAdventureActor
	.endarea

	.org TRANSFORM_ADVENTURE_HOOK
	.area 0x4
		bl TransformUnitAdventureActor
	.endarea	
	
	.org TRANSFORM_MC1_HOOK
	.area 0x4
		bl TransformMC1Actor
	.endarea

	.org TRANSFORM_MC2_HOOK
	.area 0x4
		bl TransformMC2Actor
	.endarea

	.org TRANSFORM_MC3_HOOK
	.area 0x4
		bl TransformMC3Actor
	.endarea

	.org TRANSFORM_APPOINT_HOOK
	.area 0x4
		bl TransformAppointActor
	.endarea

	.org TRANSFORM_HERO_HOOK
	.area 0x4
		bl TransformHeroActor
	.endarea

	.org TRANSFORM_PARTNER_HOOK
	.area 0x4
		bl TransformPartnerActor
	.endarea
	.org CreateDBoxStart
	.area 0x4
		bl DBoxFormatHook
	.endarea

	; original instruction: b LoadPortraitReturn
	.org LoadPortraitFinish
	.area 0x4
		b KaomadoBufTamperWrapper
 	.endarea

	.org IsNoLossPenaltyDungeon
	.area 0x10
		push {r1-r3,lr}
		mov r0, #60
		bl GetPerformanceFlagWithChecks
		pop {r1-r3,pc}
	.endarea
.close

.open "overlay10.bin", overlay10_start
	.org ToxicTable
	.area 0x60
		.pool
		.hword 0x1
		.halfword 0x1
		.halfword 0x1
		.halfword 0x1
		.hword 0x2
		.hword 0x2
		.hword 0x2
		.hword 0x2
		.halfword 0x3
		.hword 0x3
		.halfword 0x3
		.hword 0x3
		.hword 0x4
		.halfword 0x4
		.hword 0x4
		.hword 0x4
		.halfword 0x5
		.halfword 0x5
		.halfword 0x5
		.hword 0x5
		.halfword 0x6
		.halfword 0x6
		.hword 0x6
		.hword 0x6
		.hword 0x7
		.hword 0x7
		.hword 0x7
		.halfword 0x7
		.halfword 0x8
		.hword 0x8
	.endarea
.close

.open "overlay29.bin", overlay29_start
    .org CALC_DAMAGE_FORM_OFFENSE_HOOK
    .area 0x3C
        mov r0, r6
        ldr r1, [sp, 0x18]
        mov r2, #0x0; // ATK
        bl ApplyFormStatBoosts
        add r4, r0
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
    .endarea

    .org CALC_DAMAGE_FORM_DEFENSE_HOOK
    .area 0x3C
        mov r0, r7
        ldr r1, [sp, 0x18]
        mov r2, #0x1; // DEF
        bl ApplyFormStatBoosts
        add r4, r0
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
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
		b CheckIgnition
	.endarea

	.org UNK_BURT_HOOK_2
	.area 0x4
		b CheckIgnition ; apparently SOMEONE made these 3 into bls and also made the other two into HandleFaint. not naming any names here, but it confused me a good bit
	.endarea

	.org UNK_BURT_HOOK_3
	.area 0x4
		b CheckIgnition
	.endarea
	
	.org UNK_BURT_HOOK_4
	.area 0x4
		b RegeneratorAbility
	.endarea

	.org UNK_BURT_HOOK_5
	.area 0x4
		b SapSipper
	.endarea

	.org KNOWN_BURT_HOOK_6
	.area 0x18
		b     CanTheMoveKO
		mov r0, r8
		mov r1, r7
		mov r2, #0x2e
		mov r3, #0x1
	.endarea
	

	.org DeerlingSplitPersonalityHook
	.area 0x4
		beq DoNormalPersonality
	.endarea

	.org RegenMonsterHP
	.area 0x4
		bl ConditionalRegen
 	.endarea

	.org SaveFloorHook
	.area 0x4
		bl SaveFloor
	.endarea

	.org OhGodWhyDidIblAllMyHooksBackThen 
	.area 0x4
		bl HasUnusedAbilityCrit
	.endarea

	.org BecauseIWasStupidThatsWhy 
	.area 0x4
		bl HasUnusedAbilityAcc
	.endarea

	.org AnywaysTheseAreHooksForPlotArmor 
	.area 0x4
		bl HasUnusedAbilityEffect1
	.endarea

	.org ButTheyreItemEffectsNowForSomeReason 
	.area 0x4
		bl HasUnusedAbilityEffect2
	.endarea

	.org IDoNotKnowIfTheHookIsInApplyDamageOrDealDamageUntilIOpenTheGhidra 
	.area 0x4
		b  IsSpecialMove
	.endarea

	; DisableReviverReplacement by Adex
	.org CheckFixedRoomItem
	.area 0x4
		mov r0,#0
	.endarea

	.org UnnamedDungeonHookPoisonHeal
	.area 0x8
		mov r3, #0
		bl  WhichToxicTable
	.endarea

	.org UnnamedDungeonHookPoisonDamage
	.area 0x8
		mov r3, #1
		bl  WhichToxicTable
	.endarea

	.org SweeterScentEffect ; 0x2332dc8
	.area 0x4
		b   SweeterScent
	.endarea
	
	.org SweeterScentTextEffect ; 0x230e814
	.area 0x4
		b	SweeterScentText
	.endarea
	
	.org LongReachEffect ; 0x23087fc
	.area 0x4
		bl	LongReach
	.endarea
.close


.open "overlay31.bin", overlay31_start
	.org UNK_ANON_HOOK_2 ; 0x023888A4
	.area 0x4
		b HookQuickSave
	.endarea
.close
