#include <pmdsky.h>
#include <cot.h>

bool __attribute__((used)) IsGameInMajorBossMode() {
    return LoadScriptVariableValueAtIndex(NULL, VAR_STATION_ITEM_STATIC, 2);
}

int16_t __attribute__((used)) TryHandleBossHp(int damage, struct entity *attacker, struct entity *defender) {
    struct monster *defender_monster = (struct monster*)defender->info;
    int current_hp = defender_monster->hp;
    int16_t new_hp = current_hp - damage;
    if(new_hp > 0) {
        return new_hp;
    }

    if (false == IsGameInMajorBossMode()) {
        return new_hp;
    }

    if(false == defender_monster->statuses.boss_flag) {
        return new_hp;
    }

    bool reset_hp = true;
    int phase = LoadScriptVariableValue(NULL, VAR_CRYSTAL_COLOR_03);
    switch (phase) {
        case 0:
            // If something is supposed to happen on death, put it here.
            reset_hp = false;
            break;
        case 1:
            // TODO: Put something cool here on the last hp reset/phase?
        default:
            EndNegativeStatusConditionWrapper(defender, defender, false, false);
            break;
    }

    SaveScriptVariableValue(NULL, VAR_CRYSTAL_COLOR_03, phase - 1);

    if(false == reset_hp) {
        return new_hp;
    }

    int boss_max_hp = defender_monster->max_hp_stat + defender_monster->max_hp_boost;
    // This check is just in case the total damage exceeds a single HP Bar/Phase. Extremely
    // unlikely, but not impossible.
    if(damage >= boss_max_hp + current_hp) {
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