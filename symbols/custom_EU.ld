/* !file overlay11 */
OpcodeCheck = 0x022DE714;
GetParameterCount = 0x022DE6CC;
ScriptEngineReturnTwo = 0x022E2DAC;
ScriptMenuRequestDefaultCase = 0x022E6A30;
ScriptMenuRequestFinalize = 0x022E71EC;
ScriptMenuUpdateDefaultCase = 0x022E7238;
ScriptMenuUpdateFinalize = 0x022E7798;
IS_BASE_GAME_MENU_FINISHED = 0x023257DC;

/* !file overlay29 */
ApplyMoveEffect = 0x0232F2A4;
ApplyMoveEffectHookAddr = 0x023302E4;
ApplyMoveEffectJumpAddr = 0x0233310C;
ApplyItemEffectHookAddr = 0x0231C438;
ApplyItemEffectJumpAddr = 0x0231D574;

/* Add your own symbols here... */

/* !file arm9 */
ShowKeyboardTypeCase3 = 0x02036C10;
ShowKeyboardTypeDefaultCase = 0x02036D3C;
ShowKeyboardReturn = 0x02036FA8;
PreprocessStringFromIdCallsite = 0x020396FC;

.definelabel CHANGE_GIRATINA_FORM_HOOK, 0x2058958;
.definelabel REVERT_GIRATINA_AND_SHAYMIN_FORM_HOOK, 0x20589F4;
.definelabel CALC_DAMAGE_FORM_OFFENSE_HOOK, 0x230CAB4; 
.definelabel CALC_DAMAGE_FORM_DEFENSE_HOOK, 0x230CBA8;
.definelabel HOOK_DUNGEON_FORM_CHANGE, 0x2311B0C;
.definelabel HOOK_DUNGEON_FORM_CHANGE_2, 0x22FE160;
/* I assume the UnknownFunctions aren't in pmdskydebug. I forget if I even use them or not lol */
// .definelabel IsSkyExclusiveDungeon, 0x2051A7C
// .definelabel GetActiveTeamMember, 0x2056708
// .definelabel GetItemAtIdx, 0x200F3F0
.definelabel UnknownFunction1, 0x234BE94
// .definelabel LoadMonsterSprite, 0x22F800C 
// .definelabel DungeonGetSpriteIndex, 0x22F7D40
// .definelabel DetermineMonsterShadow, 0x23055D8 
// .definelabel GetIdleAnimationID, 0x23054E0
.definelabel UnknownFunction2, 0x230525C
// .definelabel GetType, 0x2052D3C;
// .definelabel GetAbility, 0x2052D5C;
.definelabel TransformationVFX, 0x22E6FA4;
// .definelabel UnknownFunction3, 0x22FA8AC;