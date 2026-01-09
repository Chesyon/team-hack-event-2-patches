#include <pmdsky.h>
#include <cot.h>


//Roar of Time variant that has the user Pounce in the direction it's facing. Put in Roar of Time slot (for forced Recharge) and is set to line of sight.
static bool MoveRoarOfTime(struct entity* user, struct entity* target, struct move* move) {
    if (!DealDamage(user, target, move, 0x100, ITEM_NOTHING)) {
        return false;
    }
    TryPounce(user, user, 8);
    return true;
}

bool CustomApplyMoveEffect(
    move_effect_input* data, struct entity* user, struct entity* target, struct move* move)
{
    switch (data->move_id)
    {
    case MOVE_ROAR_OF_TIME:
        data->out_dealt_damage = MoveRoarOfTime(user, target, move);
        return true;
    default:
        return false;
    }
}
