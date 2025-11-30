/* !file overlay11 */
OpcodeCheck = 0x022DDDD4;
GetParameterCount = 0x022DDD8C;
ScriptEngineReturnTwo = 0x022E246C;
ScriptMenuRequestDefaultCase = 0x022E60F0;
ScriptMenuRequestFinalize = 0x022E68AC;
ScriptMenuUpdateDefaultCase = 0x022E68F8;
ScriptMenuUpdateFinalize = 0x022E6E58;
IS_BASE_GAME_MENU_FINISHED = 0x02324C9C;
SPRITE_BANK_ID_SOMETHING_IDK = 0x20AFC50;
ANOTHER_SPRITE_RENDER_THING = 0x20AFC4C;
/* Chesyon's TM bullshit */
InitTreasureBagMenu = 0x2304AE0;
UpdateTreasureBagHook1 = 0x2307618;
UpdateTreasureBagHook2 = 0x2307630;
UpdateTreasureBagHook3 = 0x23078D8;
UpdateTreasureBagHook4 = 0x23078F0;
UpdateTreasureBagHook5 = 0x2307F84;
UpdateTreasureBagHook6 = 0x2307F90;
UpdateTreasureBagHook7 = 0x2308834;
TreasureBagFrameUpdateHook = 0x2304BA8;
IdfkWhatOverlayThisIs1 = 0x22BCD68;
IdfkWhatOverlayThisIs2 = 0x22BCDBC;
SomeTMFunc1 = 0x23090DC;
SomeTMFunc2 = 0x2309E24;
StupidBandaidFixHook = 0x2307FC0;
FunctionThatMakesMeAngry = 0x2308FEC;
InitTopGroundMenu = 0x2300D5C; /* Defined in a newer version of pmdsky-debug */


/* !file overlay29 */
ApplyMoveEffect = 0x0232E864;
ApplyMoveEffectHookAddr = 0x0232F8A4;
ApplyMoveEffectJumpAddr = 0x023326CC;
ApplyItemEffectHookAddr = 0x0231B9D8;
ApplyItemEffectJumpAddr = 0x0231CB14;
/* The following two symbols are from Marius' fix for ExtractMoveCode compatibility. NA offsets from Chesyon */
ApplyMoveEffectHookAddrExtracted = 0x232F8B0;
ApplyMoveEffectHookAddrExtractedOnSuccess = 0x23326CC;
/* Other ov29 addresses */
DeerlingSplitPersonalityHook = 0x234D01C;
DoNormalPersonality = 0x234D1D4;
RegenMonsterHP = 0x2311254;
/* Move Shortcut Hooks */
MoveShortcutsMainCheckHook = 0x22F11DC;         /* In SetLeaderAction */
MoveShortcutsMainCheckLoopUnhook = 0x22F1024;   /* In SetLeaderAction */
MoveShortcutsMainCheckNormalUnhook = 0x22F11E4; /* In SetLeaderAction */
MessageLogShortcutButtonOneCheck = 0x22F1E44;   /* In SetLeaderAction */
MessageLogShortcutButtonTwoCheck = 0x22F1E54;   /* In SetLeaderAction */
SaveFloorHook = 0x22DF670;

/* !file arm9 */
ShowKeyboardTypeCase3 = 0x02036914;
ShowKeyboardTypeDefaultCase = 0x02036A40;
ShowKeyboardReturn = 0x02036CAC;
PreprocessStringFromIdCallsite = 0x02039400;
CHANGE_GIRATINA_FORM_HOOK = 0x20585DC;
REVERT_GIRATINA_AND_SHAYMIN_FORM_HOOK = 0x2058678;
CALC_DAMAGE_FORM_OFFENSE_HOOK = 0x230C040;
CALC_DAMAGE_FORM_DEFENSE_HOOK = 0x230C134;
HOOK_DUNGEON_FORM_CHANGE_1 = 0x23110AC;
HOOK_DUNGEON_FORM_CHANGE_2 = 0x22FD764;
TRANSFORM_UNIT_HOOK = 0x20655B4;
TRANSFORM_ADVENTURE_HOOK = 0x20656A0;
TRANSFORM_MC1_HOOK = 0x20657A0;
TRANSFORM_MC2_HOOK = 0x20657B0;
TRANSFORM_MC3_HOOK = 0x20657C0;
TRANSFORM_APPOINT_HOOK = 0x20657D0;
TRANSFORM_HERO_HOOK = 0x20657E0;
TRANSFORM_PARTNER_HOOK = 0x20657F0;
CSOReturnValue = 0x202675C; /* EU: 0x2026A40 */
CreateDBoxStart = 0x0202F0B8;
LoadPortraitFinish = 0x204D9D8;
LoadPortraitReturn = 0x204DA0C;
/* For text_speed.c.*/
EnterHookTextSpeedWrapper = 0x2020ED0;
ExitHookTextSpeedWrapper = 0x2020ED4; /* May be unnecessary to return this way */
EnterHookTextLoop = 0x2020EE0;
ExitHookTextLoop = 0x2020EE4; /* May be unnecessary to return this way */
SomethingTextRelatedIdk = 0x2021EC8;
/* Uppercase text tags */
UppercaseUVTagHook = 0x2020FC8;
UppercaseTagCodeError = 0x2021A10;
AfterUppercaseTagIsFound = 0x2021AA0;


/* ngl I don't remember which file these are from. Or if I use all of them. - Lappy */
UnknownFunction1 = 0x234B294;
UnknownFunction2 = 0x2304830;
TransformationVFX = 0x22E65F4;
UnknownFunction3 = 0x22F9EA0;
GetAppointedMemberIdx = 0x20568A4;


/* Fuck if I know */
UNK_BURT_HOOK_1 = 0x0230a8c4;
UNK_BURT_HOOK_2 = 0x0230a890;
UNK_BURT_HOOK_3 = 0x0230a8f0;
UNK_BURT_UNHOOK_3 = 0x230a8f4;
UNK_BURT_HOOK_4 = 0x22df998;
UNK_BURT_UNHOOK_4 = 0x22df9a4;

ME_STABBING_BURRITIO = 0x2304BAC; /* Burrito had this in an earlier version of the patch, with the label "idunno". :D */ /* damn i didnt know there was a patch for this - burrito */
BURT_PLAY_ANIMATION = 0x2304830;
BURT_ExitPoint = 0x230a918;

UNK_BURT_THING_1 = 0x23092d0;
UNK_BURT_THING_2 = 0x23092f8;

UNK_BURT_HOOK_5 = 0x23092C0;

KNOWN_BURT_HOOK_6 = 0x2332DA8;
IDontKnowMayItKO = 0x2332DAC;

OhGodWhyDidIblAllMyHooksBackThen = 0x02332B58;
BecauseIWasStupidThatsWhy = 0x02323c64;
AnywaysTheseAreHooksForPlotArmor = 0x023249A8;
ButTheyreItemEffectsNowForSomeReason = 0x02324A48;

UNK_ANON_HOOK_1 = 0x0238897C;
UNK_ANON_HOOK_2 = 0x023888A4;
EndHookQuickSave = 0x023888A8;

/* Undocumented functions/symbols */
SetDisplayMode = 0x22EA428; /* Used to hide the textbox and map. */
GetStringWidth = 0x20265A8;
DUNGEON_CONTROLLER_STATUS = 0x237C694;

/* Custom dungeon palette allocation */

/* !file overlay29 */
PaletteAllocatorFindEmpty = 0x022de968;
PALETTE_ALLOCATION_DATA = 0x02353534;

/* Changing a bit how tiles graphics are selected */
/* !file overlay29 */
DungeonTilePostPickHook = 0x0233699c;
DungeonTilePostPickHookFinalJump = 0x023369e8;

LiterallyWhereIsThisWhyDidINotJustUseLabelsForMyExitPoint = 0x2332b48;
IDoNotKnowIfTheHookIsInApplyDamageOrDealDamageUntilIOpenTheGhidra = 0x02332b44;

/* Hooks & Instruction Changes */
MEMO_FIXED_ROOM_ID_HOOK = 0x205DF48; /* 0x205E2C4 EU */
MEMO_PRINT_STRING_HOOK = 0x234A120; /* 0x234AD2C EU */
FLOOR_CHECK_FIXED_ROOM_HOOK = 0x233A930; /* 0x233B514 EU */
HANDLE_PARTY_SWAP_SPRITES_HOOK = 0x22F71E8; /* 0x22F7BA0 EU */
EXIT_DUNGEON_FLOOR_HOOK = 0x22ECE9C; /* 0x22ED84C EU */
TWEAK_MEMO_ITEM_CHECK = 0x2348D8C; /* 0x234998C EU */
TWEAK_MEMO_ITEM_SPAWN = 0x2343598; /* 0x234417C EU */
MEMO_MISSION_EXIT_HOOK = 0x2348A24; /* 0x2349624 EU */
ALWAYS_GENERATE_MISSIONS = 0x205E600; /* 0x205E97C EU */
MAKE_DUNGEON_ROSY_HOOK = 0x2334E80; /* 0x23358C0 EU */
MISSION_REWARD_MEMO_TWEAK = 0x205F28C; /* 0x205F608 EU */
MISSION_MEMO_GUILD_POINTS_HOOK = 0x238A4C8; /* 0x238B008 EU */
MISSION_REWARD_GENERATION_HOOK = 0x206338C; /* 0x2063708 EU: Hook location for editing mission rewards! */
MISSION_MEMO_SHOW_DUNGEON_NAME = 0x2062060; /* 0x20623DC EU: cmp r0, #0xF: Must return FALSE to show dungeon name! */
MISSION_MEMO_SHOW_MISSION_REWARD = 0x20617E0; /* 0x2061B5C EU: (+0x4) cmp r0, #0xF: Would skip reward display if true! */
MISSION_MEMO_HIDE_MISSION_RANK_1 = 0x020616D0; /* 0x2061A54 EU: cmp r0, #0xE: Return true to conceal mission rank + pts */
MISSION_MEMO_HIDE_MISSION_RANK_2 = 0x02060D54; /* 0x20610D0 EU: cmp r0, #0xE: Return true to conceal mission rank in title! */
MISSION_MEMO_SPAWN_OUTLAW_HOOK = 0x22FD2F4; /* 0x22FDCF0 EU: Hook location for spawning a monster, which might be an outlaw. */
MEMO_FIXED_ROOM_IDS = 0x20A1958; /* Size #0x20, NULL terminated! */
DISAMBIGUATE_MEMO_FROM_CHAMBER_HOOK = 0x2348E30; /* 0x2349A30 EU */
MISSION_MEMO_CROSSROADS_HOOK = 0x205EDDC; /* 0x205F158 EU */
MISSION_OBJECTIVE_MEMO_HOOK = 0x234F5E4; /* 0x23501F0 EU */
MEMO_TWEAK_MISSION_DEST_INFO_HOOK = 0x234876C; /* 0x234936C EU */
IS_ACTUALLY_FLEEING_OUTLAW_HOOK = 0x234AD18; /* 0x234B918 EU */
SPAWN_ITEM_HOOK = 0x2345570; /* 0x2346158 EU */
DESTROY_ITEM_HOOK = 0x2345704; /* 0x23462F0 EU */
DECREMENT_ROSINESS_HOOK = 0x22ECB4C; /* 0x22ED4FC EU */
DECREMENT_WIND_HOOK = 0x22ECB84; /* 0x22ED534 EU */
SPAWN_MISSION_ITEM_FLOOR_HOOK = 0x2344E10; /* 0x23459F4 EU */
IS_ACTUALLY_DESTINATION_FLOOR_WITH_ITEM = 0x2344C60; /* 0x2345844 EU */
ROSY_WIND_MESSAGE_HOOK = 0x22EC9C0; /* 0x22ED370 EU */
ROSY_WIND_DEATH_HOOK = 0x22ECACC; /* 0x22ED724 EU */
BAG_ORB_TRASH_HOOK_1 = 0x2307784; /* 0x2308120 EU */
BAG_ORB_TRASH_HOOK_2 = 0x23077C8; /* 0x2308164 EU */
MAGNET_RISE_TURN_RANGE = 0x22C4780; /* 0x22C50D8 EU */
ALLOW_ALL_NATURAL_SLEEP = 0x02307E04; /* 0x2308830 EU */
/* Data */
MISSION_REWARD_DIALOGUE_SEQS = 0x238AE26; /* 0x238B960 EU */
THE_ORB_ITEM_ID = 353; /* TODO Change to actual item ID! */
ROSY_BGM_ID = 195;

/* Text Strings */
LARVESTA_PUZZLE_STRING_1_1 = 15279;
LARVESTA_PUZZLE_STRING_1_2 = 15280;
LARVESTA_PUZZLE_STRING_1_3 = 15281;
LARVESTA_PUZZLE_STRING_1_4 = 15282;
LARVESTA_PUZZLE_STRING_1_5 = 15283;
LARVESTA_PUZZLE_STRING_2 = 15284;
LARVESTA_PUZZLE_STRING_3 = 15285;
LARVESTA_PUZZLE_STRING_GENERIC = 15286;
MEMO_MISSION_COMPLETE_STRING_1 = 15287;
LARVESTA_PUZZLE_STRING_C1 = 15288;

ROSY_WIND_250 = 15335;
/*
ROSY_WIND_150 = 15336;
ROSY_WIND_50 = 15337;
ROSY_WIND_0 = 15338;
*/

/* This leaves lots of strings (15289 thru 15334) for the mission stuff. */

/* Functions */

InitMonsterStatsAtLevel = 0x02055B78; /* 0x02055ef4 */
AssignSpecialEpisodePC = 0x2048AC4; /* 0x2048DE0 EU */
RollRandomMissionitem = 0x20630A4; /* 0x2063420 EU */
SelectRandomFixedRoomInRange = 0x2060084; /* 0x2060400 EU */
SetMessageLogPreprocessorArgsStringToName = 0x234B0CC; /* https://github.com/UsernameFodder/pmdsky-debug/blob/468c7e5e3d20e27b4374b7a4f2c3f11a5a917e6c/symbols/overlay29.yml#L9108 */
ApplyPartyChange = 0x2057464; /* 0x20577E0 EU */
InitDestinationOutlaws = 0x23497C8; /* 0x234A3C8 EU */
RetrieveCurrentBGM = 0x22EAEF0; /* 0x22EB8A0 EU */

OOPS2 = 0x22FEBAC;
// OOPS = 0x205F29C; /* 0x205F608 EU */

/* Unused but useful offsets
	CALL_EXIT_TRACKER_HOOK = 0x22DFBC4; 0x22E0500 EU
	TREASURE_BOX_ITEM_ID = 0x2344534 EU
	// Chatot's ID for dialogue???	0x238B0A0 EU 
	// Mission reward type for treasure memo missions: 0x238B02C EU
	// Mission Reward Dialogue Stuff: 0x238B028 EU
	// 0x22E1E6C (????)
	// 0x23490A0 [EU]
	// 0x2061E04 EU: Conditions for displaying mission objective. Useless to me.
	// Guild Display Money Multiplier: 0x0203daec EU

*/