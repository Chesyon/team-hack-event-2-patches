#include <pmdsky.h>
#include <cot.h>

#define ENTROPY_SCARF 113
#define ENTROPY_AMULET 181
#define ENTROPY_RIBBON 185

#define CHAOS_SCARF 114
#define CHAOS_AMULET 184
#define CHAOS_RIBBON 219

// Always Force Accuracy Checks To Pass
void __attribute__((naked)) __attribute__((used)) EntropyAccuracyCheck() {
    asm("beq EntropyAccuracyOnUnhook");
    asm("mov r0,r7");
    asm("mov r1,#113"); // Entropy Scarf
    asm("bl ItemIsActive");
    asm("cmp r0,#0x0");
    asm("ldreqb r0,[r9, #0xec]");
    asm("beq EntropyAccuracyOffUnhook");
    asm("b   EntropyAccuracyOnUnhook");
}

// Always Force Secondary Effects To Fail
void __attribute__((naked)) __attribute__((used)) EntropySecondaryEffectCheck() {
    asm("mov r0,r6");
    asm("mov r1,#181"); // Entropy Amulet
    asm("bl  ItemIsActive");
    asm("cmp r0,#0x0");
    asm("bne EntropySecondaryEffectOnUnhook");
    asm("mov r0,r5");
    asm("mov r1,#181"); // Entropy Amulet
    asm("bl  ItemIsActive");
    asm("cmp r0,#0x0");
    asm("bne EntropySecondaryEffectOnUnhook");
    asm("b   EntropySecondaryEffectOffUnhook");
}

// Force Status Duration
bool __attribute__((used)) EntropyStatusDurationCheck(struct entity *entity, enum ability_id ability) {
    if(ItemIsActive(entity, ENTROPY_RIBBON)) {
        return true;
    }

    return AbilityIsActiveVeneer(entity, ability);
}

// Random Changed Types
void __attribute__((used)) __attribute__((naked)) ChaosTypeCheck() {
    asm("push {lr}");
    asm("mov r0,r5");
    asm("bl EntityIsValid");
    asm("cmp r0,#0x0");
    asm("bleq ChaosTypeCheckReturn");
    asm("mov r0,r5");
    asm("mov r1,#114"); // Chaos Scarf
    asm("bl ItemIsActive");
    asm("cmp r0,#0x0");
    asm("popeq {lr}");
    asm("beq ChaosTypeOverwrittenFunction");
    asm("mov r0,#16");
    asm("bl DungeonRandInt");
    asm("add r0,r0,#1");
    asm("strb r0,[r4,#0x5E]");
    asm("mov r2,#0");
    asm("strb r2,[r4,#0x5F]");
    asm("mov r3,#1");
    asm("strb r10,[r4,#0xFF]");
    asm("ChaosTypeCheckReturn:");
    asm("pop {lr}");
    asm("b ChaosTypeOverwrittenFunction");
}

// Random Explosion
bool __attribute__((used)) ChaosExplosionCheck(struct entity *attacker, struct entity *defender) {
    if(false == IsMonster(attacker)) {
        return false;
    }
    if(ItemIsActive(attacker, CHAOS_AMULET)) {
        return true;
    }

    return DefenderAbilityIsActive(attacker, defender, ABILITY_AFTERMATH, true);
}

// Random Weather
int __attribute__((used)) ChaosWeatherCheck() {
    for (int i = 0; i < 4; i++) {
        struct entity *monster_entity = DUNGEON_PTR->entity_table.header.monster_slot_ptrs[i];
        if (EntityIsValid(monster_entity)) {
            if(ItemIsActive(monster_entity, CHAOS_RIBBON)) {
                return DungeonRandInt(8);
            }
        }
    }

    return DUNGEON_PTR->floor_properties.weather.val;
}
