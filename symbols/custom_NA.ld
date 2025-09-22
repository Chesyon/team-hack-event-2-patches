/* !file overlay11 */
OpcodeCheck = 0x022DDDD4;
GetParameterCount = 0x022DDD8C;
ScriptEngineReturnTwo = 0x022E246C;
ScriptMenuRequestDefaultCase = 0x022E60F0;
ScriptMenuRequestFinalize = 0x022E68AC;
ScriptMenuUpdateDefaultCase = 0x022E68F8;
ScriptMenuUpdateFinalize = 0x022E6E58;
IS_BASE_GAME_MENU_FINISHED = 0x02324C9C;

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
/* Add your own symbols here... */

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

UNK_ANON_HOOK_1 = 0x0238897C;
UNK_ANON_HOOK_2 = 0x023888A4;
