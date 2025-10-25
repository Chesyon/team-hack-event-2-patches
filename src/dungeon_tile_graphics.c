#include <pmdsky.h>
#include <cot.h>

void test_adjacent_tile_for_pattern(bool* isPattern1, bool* isPattern2, int x, int y) {
    struct tile* this_tile = GetTileSafe(x, y);
    *isPattern1 = *isPattern1 || (this_tile->texture_id == DUNGEON_PTR->unknown_file_buffer_0x12162[0x2ff * 3 + 1]);
    *isPattern2 = *isPattern2 || (this_tile->texture_id == DUNGEON_PTR->unknown_file_buffer_0x12162[0x2ff * 3 + 2]);
}

bool can_use_tile_for_ground_pattern(int x, int y) {
    struct tile* this_tile = GetTileSafe(x, y);
    return (this_tile->terrain_type == TERRAIN_NORMAL) && (this_tile->texture_id == 0);
}

__attribute__((used)) void DungeonTilePostPickReplacementPart(int x, int y, uint32_t currently_picked_value) {
    unsigned int random_value = 0;
    struct tile* this_tile = GetTileSafe(x, y);
    if (!IsCurrentFixedRoomBossFight()) {
        if (DUNGEON_PTR->id.val == 7 && this_tile->terrain_type == TERRAIN_NORMAL) {
            if (this_tile->texture_id != 0) {
                return;
            }
            currently_picked_value = 0x2ff;
            // rely on the fact this is generated negative to positive (I think?)
            if (RandIntSafe(50) == 0 && x < 0x36 && y < 0x18 && can_use_tile_for_ground_pattern(x, y + 1) && can_use_tile_for_ground_pattern(x + 1, y) && can_use_tile_for_ground_pattern(x + 1, y + 1)) {
                this_tile->texture_id = DUNGEON_PTR->unknown_file_buffer_0x12162[0x2f5 * 3];
                GetTileSafe(x, y + 1)->texture_id = DUNGEON_PTR->unknown_file_buffer_0x12162[0x2d7 * 3];
                GetTileSafe(x + 1, y)->texture_id = DUNGEON_PTR->unknown_file_buffer_0x12162[0x25f * 3];
                GetTileSafe(x + 1, y + 1)->texture_id = DUNGEON_PTR->unknown_file_buffer_0x12162[0x27d * 3];
                return;
            } else if (RandIntSafe(10) >= 6) {
                bool has_adjacent_pattern_1 = false;
                bool has_adjacent_pattern_2 = false;
                test_adjacent_tile_for_pattern(&has_adjacent_pattern_1, &has_adjacent_pattern_2, x + 1, y);
                test_adjacent_tile_for_pattern(&has_adjacent_pattern_1, &has_adjacent_pattern_2, x - 1, y);
                test_adjacent_tile_for_pattern(&has_adjacent_pattern_1, &has_adjacent_pattern_2, x, y + 1);
                test_adjacent_tile_for_pattern(&has_adjacent_pattern_1, &has_adjacent_pattern_2, x, y - 1);
                if (has_adjacent_pattern_1 && !has_adjacent_pattern_2) {
                    random_value = 2;
                } else if (has_adjacent_pattern_2 && !has_adjacent_pattern_1) {
                    random_value = 1;
                } else {
                    random_value = RandIntSafe(2) + 1;
                }
            }

        } else {
            random_value = RandIntSafe(4);
            if (random_value >= 3) {
                random_value = 0;
            }
        }
    }
    this_tile->texture_id = DUNGEON_PTR->unknown_file_buffer_0x12162[currently_picked_value * 3 + random_value];
}
