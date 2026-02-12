#include <pmdsky.h>
#include <cot.h>

bool __attribute__((used)) IsGameInMajorBossMode() {
    return LoadScriptVariableValueAtIndex(NULL, VAR_STATION_ITEM_STATIC, 2);
}

int16_t __attribute__((used)) TryHandleBossHp(int damage, struct entity *attacker, struct entity *defender) {
    struct monster *defender_monster = (struct monster*)defender->info;
    int current_hp = defender_monster->hp;
    int16_t new_hp = current_hp - damage;
    if (0 < new_hp) {
        return new_hp;
    }

    if (false == IsGameInMajorBossMode()) {
        return 0;
    }

    if (false == defender_monster->statuses.boss_flag) {
        return 0;
    }

    
    int phase = LoadScriptVariableValue(NULL, VAR_CRYSTAL_COLOR_03);
    switch (phase) {
        case 0:
            // If something is supposed to happen on death, put it here.
            return 0; // See Note 1*
        case 1:
            // TODO: Put something cool here on the last hp reset/phase?
            EndNegativeStatusConditionWrapper(defender, defender, true, false);

            // oh to hell with learning C
            // looks easy, i just cant be bothered to learn how to parse the stack as a parameter
            asm("sub sp, sp, #0x10");
            asm("mov r0, sp");
            asm("ldr r1, =#1293");
            asm("mov r2, #9");
            asm("bl InitPortraitDungeon");
            asm("mov r0, sp");
            asm("ldr r1, =#22696");
            asm("mov r2, #1");
            asm("bl DisplayMessage2");
            asm("add sp, sp, #0x10");
            break;
        case 2:
            EndNegativeStatusConditionWrapper(defender, defender, true, false);
            asm("sub sp, sp, #0x10");
            asm("mov r0, sp");
            asm("ldr r1, =#1293");
            asm("mov r2, #3");
            asm("bl InitPortraitDungeon");
            asm("mov r0, sp");
            asm("ldr r1, =#22695");
            asm("mov r2, #1");
            asm("bl DisplayMessage2");
            asm("add sp, sp, #0x10");
            break;
        case 3:
            EndNegativeStatusConditionWrapper(defender, defender, true, false);
            asm("sub sp, sp, #0x10");
            asm("mov r0, sp");
            asm("ldr r1, =#1293");
            asm("mov r2, #3");
            asm("bl InitPortraitDungeon");
            asm("mov r0, sp");
            asm("ldr r1, =#22694");
            asm("mov r2, #1");
            asm("bl DisplayMessage2");
            asm("add sp, sp, #0x10");
            break;
        default:
            EndNegativeStatusConditionWrapper(defender, defender, true, false);
            break;
    }
    SaveScriptVariableValue(NULL, VAR_CRYSTAL_COLOR_03, phase - 1);

    int boss_max_hp = defender_monster->max_hp_stat + defender_monster->max_hp_boost;
    if (999 < boss_max_hp) {
        boss_max_hp = 999;
    }
    // This check is just in case the total damage exceeds a single HP Bar/Phase. Extremely
    // unlikely, but not impossible.
    if (damage >= boss_max_hp + current_hp) {
        return 1;
    }

    return boss_max_hp + current_hp - damage;
}

void __attribute__((naked)) __attribute__((used)) BossHpCheckTrampoline() {
    // r0 has damage
    asm("mov   r1,r8"); // Attacker
    asm("mov   r2,r7"); // Defender
    asm("ldr   lr,=BossHPCheckUnhook");
    asm("b     TryHandleBossHp");
}

/*
Note 1: Technically, the boss may survive if they have Endure or
if they have been hit with false swipe even if we set the HP to 0.
*/
