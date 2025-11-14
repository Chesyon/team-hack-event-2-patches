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
