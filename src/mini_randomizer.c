#include <pmdsky.h>
#include <cot.h>

#define HUE_DEGREE_CLOSE_CUTOFF 15
#define ARE_HUES_CLOSE(h1, h2) (h1 <= (HUE_DEGREE_CLOSE_CUTOFF/2)) && \
                                  (h2 >= 360 - (HUE_DEGREE_CLOSE_CUTOFF/2))

// TODO: If you want this to be controlled in some way using scripting put
// a variable aside.
int randomizer_mode_seed = 0;

bool __attribute__((used)) IsGameInEnemyRandomizerMode() {
    return true;
    return LoadScriptVariableValueAtIndex(NULL, VAR_STATION_ITEM_STATIC, 0);
}

int CalculateHueFromRGB(struct rgba color) {
    if (color.r == color.g && color.r == color.b) {
        return 0;
    }
    
    int max;
    int min;
    int hue;
    if (color.r >= color.g && color.r >= color.b) {
        max = color.r;
        min = (color.g < color.b) ? color.g : color.b;
        hue = _s32_div_f( 60 * (color.g - color.b), max - min);
    } else if (color.g >= color.r && color.g >= color.b) {
        max = color.g;
        min = (color.r < color.b) ? color.r : color.b;
        hue = 120 + _s32_div_f( 60 * (color.b - color.r), max - min);
    } else {
        max = color.b;
        min = (color.r < color.g) ? color.r : color.g;
        hue = 240 + _s32_div_f( 60 * (color.r - color.g), max - min);
    }
    
    if (hue < 0) {
        hue += 360;
    }
    
    return hue;
}

// Inaccuracies from integer math and dividing by 256 instead of 255.
int CalculateLuminanceFromRGB(struct rgba color) {
    int max = color.r;
    int min = color.r;
    
    if (max < color.g) {
        max = color.g;
    } else if (min > color.g) {
        min = color.g;
    }
    
    if (max < color.b) {
        max = color.b;
    } else if (min > color.b) {
        min = color.b;
    }
    
    // Muliply by 100 so it's returned as a percent.
    return ((max * 100) + (min * 100)) >> 7;
}

struct hue_index {
    int16_t hue;
    uint8_t original_index;
    int8_t group;
};

struct hue_group_info {
    int size;
    int hue_sum;
};

struct hue_group_tracker {
    int num_groups;
    int valid_colors;
    int invalid_colors;
    struct hue_index *indexes;
    struct hue_group_info *group_info;
};

int CreateHueGroupsFromPalette(const struct rgba *palette, const int palette_size, struct hue_group_tracker *hgt, bool skip_first_color) {
    // You could input a check for palette size here; however, (assuming the check
    // for overlapping hues is at least 3) it should never make more than 127
    // (max number of int8_t) groups.
    
    int valid_colors = 0;
    int invalid_colors = 0;
    struct hue_index *indexes = hgt->indexes;
    // Calculate the hue and note original index for every color.
    int i = skip_first_color ? 1 : 0; // If skip_first_color... skip the first color.
    while (i < palette_size) {
        // If the color is black, gray or white, put it aside.
        if (palette[i].r == palette[i].g && palette[i].r == palette[i].b) {
            indexes[palette_size - invalid_colors - 1].hue = -1;
            indexes[palette_size - invalid_colors - 1].original_index = i;
            indexes[palette_size - invalid_colors - 1].group = -1;
            invalid_colors++;
        } else {
            indexes[valid_colors].hue = CalculateHueFromRGB(palette[i]);
            indexes[valid_colors].original_index = i;
            valid_colors++;
        }
        i++;
    }
    
    hgt->valid_colors = valid_colors;
    hgt->invalid_colors = invalid_colors;
    if (valid_colors == 0) {
        hgt->num_groups = 0;
        return 0; // This palette is all grayscale, no groups were made.
    }
    
    // Sort the hues to make the logic for making groups easier.
    for (int i = 1; i < valid_colors; i++) {
        for (int j = i; j > 0 && indexes[j - 1].hue > indexes[j].hue; j--) {
            struct hue_index temp = indexes[j];
            indexes[j] = indexes[j - 1];
            indexes[j - 1] = temp;
        }
    }
    
    // Make the groups for our hue. Groups are chains of hues that are not more than
    // a certain degree (defined by HUE_DEGREE_CLOSE_CUTOFF).
    int current_group_num = 0;
    struct hue_group_info *group_info = hgt->group_info;
    group_info[0].hue_sum = indexes[0].hue;
    int16_t previous_hue = indexes[0].hue;
    group_info[0].size = 1;
    indexes[0].group = 0;
    for (int i = 1; i < valid_colors; i++) {
        int16_t current_hue = indexes[i].hue;
        if (current_hue - previous_hue <= HUE_DEGREE_CLOSE_CUTOFF) { // The hues are 'close'.
            indexes[i].group = current_group_num;
            group_info[current_group_num].size++;
            group_info[current_group_num].hue_sum += current_hue;
        } else {                               // The hues are 'far'.
            current_group_num++;
            indexes[i].group = current_group_num;
            group_info[current_group_num].size = 1;
            group_info[current_group_num].hue_sum = current_hue;
        }
        previous_hue = current_hue;
    }
    
    // Since hue is 360 degrees, check if the last group and first group should
    // be combined since they are close.
    if (current_group_num > 1 && ARE_HUES_CLOSE(indexes[0].hue, previous_hue)) {
        int i = valid_colors - 1;
        while (indexes[i].group == current_group_num) {
            indexes[i].group = 0;
            i--;
        }
        group_info[0].size += group_info[current_group_num].size;
        group_info[0].hue_sum += group_info[current_group_num].hue_sum;
        current_group_num--;
    }
    
    int num_groups = current_group_num + 1;
    hgt->num_groups = num_groups;
    return num_groups;
}

void GrayscaleWanPalette(int wan_index) {
    struct wan_palettes *palettes = WAN_TABLE->sprites[wan_index].sprite_start->image_header->palettes;
    struct rgba *palette = palettes->palette_bytes;
    int palette_size = palettes->nb_color;
    
    for (int i = 0; i < palette_size; i++) {
        int red = palette[i].r;
        int green = palette[i].g;
        int blue = palette[i].b;
        
        // This color is already grayscale!
        if (red == green && red == blue) {
            continue;
        }
        
        int cx = (red + green + blue) / 3;
        
        palette[i].r = cx;
        palette[i].g = cx;
        palette[i].b = cx;
    }
}

void InvertWanPalette(int wan_index) {
    struct wan_palettes *palettes = WAN_TABLE->sprites[wan_index].sprite_start->image_header->palettes;
    struct rgba *palette = palettes->palette_bytes;
    int palette_size = palettes->nb_color;
    
    for (int i = 0; i < palette_size; i++) {
        int red = palette[i].r;
        int green = palette[i].g;
        int blue = palette[i].b;
        
        // This color is black or white and should not be inverted.
        if ((red == 0 || red == 255) && red == green && red == blue) {
            continue;
        }
        
        palette[i].r = red ^ 0xFF;
        palette[i].g = green ^ 0xFF;
        palette[i].b = blue ^ 0xFF;
    }
}

// This works as intended, but not as expected. Since all sprites have 16 colors
// but some don't use those colors, this leads to results that are beyond terrible
// if unused colors get grouped with used colors in the palette.
/* void InvertAndReorderWanPalette(int wan_index) {
    struct wan_palettes *palettes = WAN_TABLE->sprites[wan_index].sprite_start->image_header->palettes;
    struct rgba *palette = palettes->palette_bytes;
    int palette_size = palettes->nb_color;
    struct hue_group_info group_info[palette_size];
    struct hue_index hue_indexes[palette_size];
    struct hue_group_tracker hgt;
    hgt.indexes = hue_indexes;
    hgt.group_info = group_info;
    
    int hue_num_groups = CreateHueGroupsFromPalette(palette, palette_size, &hgt, true);
    if (hue_num_groups <= 0) {
        return; // Palette is in grayscale.
    }
    
    int valid_colors = hgt.valid_colors;
    for (int i = 0; i < hue_num_groups; i++) {
        // Grab all the colors in this group.
        int luminance[palette_size];
        int original_indexes_lum[palette_size];
        int luminance_entries = 0;
        for (int j = 0; j < valid_colors; j++) {
            if (hue_indexes[j].group == i) {
                int original_index = hue_indexes[j].original_index;
                original_indexes_lum[luminance_entries] = original_index;
                luminance[luminance_entries] = CalculateLuminanceFromRGB(palette[original_index]);
                luminance_entries++;
            }
        }
        
        // Sort the colors in the group by luminance.
        for (int j = 1; j < luminance_entries; j++) {
            for (int k = j; k > 0 && luminance[k - 1] > luminance[k]; k--) {
                int temp_1 = original_indexes_lum[k];
                int temp_2 = luminance[k];
                original_indexes_lum[k] = original_indexes_lum[k - 1];
                luminance[k] = luminance[k - 1];
                original_indexes_lum[k - 1] = temp_1;
                luminance[k - 1] = temp_2;
            }
        }
        
        // Invert the colors and reverse the colors in the group.
        for (int j = 0; j < luminance_entries; j++) {
            int swapped_index = original_indexes_lum[luminance_entries - 1 - j];
            int original_index = original_indexes_lum[j];
            int red = palette[original_index].r;
            int green = palette[original_index].g;
            int blue = palette[original_index].b;
            palette[swapped_index].r = red ^ 0xFF;
            palette[swapped_index].g = green ^ 0xFF;
            palette[swapped_index].b = blue ^ 0xFF;
        }
    }
} */

// Force a wan palette to use three specific hues.
void HueForceWanPalette(int wan_index, int primary_hue, int secondary_hue, int tertiary_hue) {
    struct wan_palettes *palettes = WAN_TABLE->sprites[wan_index].sprite_start->image_header->palettes;
    struct rgba *palette = palettes->palette_bytes;
    int palette_size = palettes->nb_color;
    struct hue_group_info group_info[palette_size];
    struct hue_index hue_indexes[palette_size];
    struct hue_group_tracker hgt;
    hgt.indexes = hue_indexes;
    hgt.group_info = group_info;
    
    int hue_num_groups = CreateHueGroupsFromPalette(palette, palette_size, &hgt, true);
    if (hue_num_groups <= 0) {
        return; // Palette is in grayscale.
    }
    
    // Find the two biggest groups.
    int biggest_group = -1;
    int biggest_group_size = 0;
    int second_biggest_group = -1;
    int second_biggest_group_size = 0;
    for (int i = 0; i < hue_num_groups; i++) {
        int current_group_size = group_info[i].size;
        if (current_group_size > biggest_group_size) {
            second_biggest_group = biggest_group;
            second_biggest_group_size = biggest_group_size;
            biggest_group = i;
            biggest_group_size = current_group_size;
        }
        else if (current_group_size > second_biggest_group_size) {
            second_biggest_group = i;
            second_biggest_group_size = current_group_size;
        }
    }
    
    // Based upon the following answer: https://stackoverflow.com/a/8510751
    // The below shifts are handled using a rotation matrix created from the
    // hue shift value applied to our rgb color vector.
    // The rotation matrix is:
    // [cos(hue) + (1.0 - cos(hue))/3, (1.0 - cos(hue))/3 - sqrt(1/3) * sin(hue), (1.0 - cos(hue))/3 + sqrt(1/3) * sin(hue)]
    // [(1.0 - cos(hue))/3 + sqrt(1/3) * sin(hue), cos(hue) + (1.0 - cos(hue))/3, (1.0 - cos(hue))/3 - sqrt(1/3) * sin(hue)]
    // [(1.0 - cos(hue))/3 - sqrt(1/3) * sin(hue), (1.0 - cos(hue))/3 + sqrt(1/3) * sin(hue), cos(hue) + (1.0 - cos(hue))/3]
    // However, everything is shifted 12 bits to the left since the TRIG_TABLE has
    // 12 fractional bits. Only at the very do I remove the fractional bits.
    // Q: Where does 2365 come from?
    // A: sqrt(1/3) << 12
    /* To make this slightly faster, I do not load from the matrix and instead
       just make note of the three values.
    matrix[0][0] = cosine + (0x1000 - cosine) / 3;
    matrix[1][1] = cosine + (0x1000 - cosine) / 3;
    matrix[2][2] = cosine + (0x1000 - cosine) / 3;
    matrix[0][1] = (0x1000 - cosine) / 3 - ((2365 * sine) >> 12);
    matrix[1][2] = (0x1000 - cosine) / 3 - ((2365 * sine) >> 12);
    matrix[2][0] = (0x1000 - cosine) / 3 - ((2365 * sine) >> 12);
    matrix[0][2] = (0x1000 - cosine) / 3 + ((2365 * sine) >> 12);
    matrix[1][0] = (0x1000 - cosine) / 3 + ((2365 * sine) >> 12);
    matrix[2][1] = (0x1000 - cosine) / 3 + ((2365 * sine) >> 12); */
    int valid_colors = hgt.valid_colors;
    // Hue shift the largest group of colors towards our desired hue.
    int primary_group_hue_shift = primary_hue - _s32_div_f(group_info[biggest_group].hue_sum, group_info[biggest_group].size);
    if (primary_group_hue_shift < 0) {
        primary_group_hue_shift = 360 + (primary_group_hue_shift % 360);
    }
    int cosine = (int)(TRIG_TABLE[0xFFF & ((primary_group_hue_shift * 4096)/360)].cos);
    int sine = (int)(TRIG_TABLE[0xFFF & ((primary_group_hue_shift * 4096)/360)].sin);
    int rotation_primary_0 = cosine + (0x1000 - cosine) / 3;
    int rotation_primary_1  = (0x1000 - cosine) / 3 - ((2365 * sine) >> 12);
    int rotation_primary_2  = (0x1000 - cosine) / 3 + ((2365 * sine) >> 12);
    int secondary_group_hue_shift;
    int rotation_secondary_0;
    int rotation_secondary_1;
    int rotation_secondary_2;
    if (second_biggest_group != -1) {
        secondary_group_hue_shift = secondary_hue - _s32_div_f(group_info[second_biggest_group].hue_sum, group_info[second_biggest_group].size);
        if (secondary_group_hue_shift < 0) {
            secondary_group_hue_shift = 360 + (secondary_group_hue_shift % 360);
        }
        cosine = (int)(TRIG_TABLE[0xFFF & ((secondary_group_hue_shift * 4096)/360)].cos);
        sine = (int)(TRIG_TABLE[0xFFF & ((secondary_group_hue_shift * 4096)/360)].sin);
        rotation_secondary_0 = cosine + (0x1000 - cosine) / 3;
        rotation_secondary_1  = (0x1000 - cosine) / 3 - ((2365 * sine) >> 12);
        rotation_secondary_2  = (0x1000 - cosine) / 3 + ((2365 * sine) >> 12);
    } else {
        rotation_secondary_0 = 0x1000;
        rotation_secondary_1  = 0;
        rotation_secondary_2  = 0;
    }
    for (int i = 0; i < valid_colors; i++) {
        // Get original colors.
        int original_index = hue_indexes[i].original_index;
        int red = palette[original_index].r;
        int green = palette[original_index].g;
        int blue = palette[original_index].b;
        // Calculate the new colors for each VALID hue shiftable color.
        int rx;
        int gx;
        int bx;
        int hue_shift;
        if (hue_indexes[i].group == biggest_group) {
            if (primary_hue < 0) {
                continue;
            }
            rx = ((red * rotation_primary_0) >> 12) + ((green * rotation_primary_1) >> 12) + ((blue * rotation_primary_2) >> 12);
            gx = ((red * rotation_primary_2) >> 12) + ((green * rotation_primary_0) >> 12) + ((blue * rotation_primary_1) >> 12);
            bx = ((red * rotation_primary_1) >> 12) + ((green * rotation_primary_2) >> 12) + ((blue * rotation_primary_0) >> 12);
            hue_shift = primary_group_hue_shift;
        } else if (hue_indexes[i].group == second_biggest_group) {
            if (secondary_hue < 0) {
                continue;
            }
            rx = ((red * rotation_secondary_0) >> 12) + ((green * rotation_secondary_1) >> 12) + ((blue * rotation_secondary_2) >> 12);
            gx = ((red * rotation_secondary_2) >> 12) + ((green * rotation_secondary_0) >> 12) + ((blue * rotation_secondary_1) >> 12);
            bx = ((red * rotation_secondary_1) >> 12) + ((green * rotation_secondary_2) >> 12) + ((blue * rotation_secondary_0) >> 12);
            hue_shift = secondary_group_hue_shift;
        } else if (tertiary_hue < 0){
            continue;
        } else {
            hue_shift = tertiary_hue - hue_indexes[i].hue;
            if (hue_shift < 0) {
                hue_shift = 360 + (hue_shift % 360);
            }
            cosine = (int)(TRIG_TABLE[0xFFF & (hue_shift * 4096)/360].cos);
            sine = (int)(TRIG_TABLE[0xFFF & (hue_shift * 4096)/360].sin);
            int rotation_0 = cosine + (0x1000 - cosine) / 3;
            int rotation_1  = (0x1000 - cosine) / 3 - ((2365 * sine) >> 12);
            int rotation_2  = (0x1000 - cosine) / 3 + ((2365 * sine) >> 12);
            rx = ((red * rotation_0) >> 12) + ((green * rotation_1) >> 12) + ((blue * rotation_2) >> 12);
            gx = ((red * rotation_2) >> 12) + ((green * rotation_0) >> 12) + ((blue * rotation_1) >> 12);
            bx = ((red * rotation_1) >> 12) + ((green * rotation_2) >> 12) + ((blue * rotation_0) >> 12);
        }
        // Manually try to correct some hue shifting weirdness. The exact
        // values choosen are arbitrary to attempt to fix the fact that
        // yellow is percieved brighter and blue/purple is percieved darker.
        // Currently, when shifting to yellow or from blue, try to counteract
        // this perception difference.
        if (hue_shift > 60) {
            if (blue > green + red) {
                gx -= blue >> 3;
                rx -= blue >> 3;
            } else if ((green + red) >> 1 > blue) {
                bx += (red >> 4) + (green >> 4);
            }
            if (bx > gx + rx) {
                gx += bx >> 3;
                rx += bx >> 3;
            } else if ((gx + rx) >> 1 > bx) {
                bx -= (rx >> 4) + (gx >> 4);
            }
        }
        // Clamp invalid values that may occur from the rotation.
        if (rx < 0) { rx = 0; }
        if (gx < 0) { gx = 0; }
        if (bx < 0) { bx = 0; }
        if (rx > 255) { rx = 255; }
        if (gx > 255) { gx = 255; }
        if (bx > 255) { bx = 255; }
        // Save those new values.
        palette[original_index].r = (uint8_t)rx;
        palette[original_index].g = (uint8_t)gx;
        palette[original_index].b = (uint8_t)bx;
    }
    
    return;
}

union rgba_hex {
    struct rgba rgba;
    uint32_t hex;
};

union rgba_hex type_swap_color_table[TYPE_NEUTRAL + 1][4][12] = {
    // Neutral
    {
        // Variant 0
        {
            {.hex = 0x773f0000}, {.hex = 0x7c410100}, {.hex = 0x87480500}, {.hex = 0x934e0800},
            {.hex = 0x9b520a00}, {.hex = 0xa6580e00}, {.hex = 0xae5c1000}, {.hex = 0xb25e1100},
            {.hex = 0xba631400}, {.hex = 0xc76a1800}, {.hex = 0xd06f1a00}, {.hex = 0xde771f00}
        },
        // Variant 1
        {
            {.hex = 0xd7bf6700}, {.hex = 0xdac46c00}, {.hex = 0xdec97100}, {.hex = 0xe1cd7500},
            {.hex = 0xe5d37b00}, {.hex = 0xe8d77f00}, {.hex = 0xebdc8400}, {.hex = 0xefe18900},
            {.hex = 0xf2e58d00}, {.hex = 0xf6ea9200}, {.hex = 0xf8ee9600}, {.hex = 0xfff79f00}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Normal
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Fire
    {
        // Variant 0
        {
            {.hex = 0x9F000000}, {.hex = 0xAD100000}, {.hex = 0xBB200000}, {.hex = 0xC92F0000},
            {.hex = 0xD73F0000}, {.hex = 0xE1511800}, {.hex = 0xEB633000}, {.hex = 0xF5754700},
            {.hex = 0xFF875F00}, {.hex = 0xFF997700}, {.hex = 0xFFAA8E00}, {.hex = 0xFFBCA600}
        },
        // Variant 1
        {
            {.hex = 0xA76F0000}, {.hex = 0xB5810000}, {.hex = 0xC3930000}, {.hex = 0xD1A50000},
            {.hex = 0xDFB70000}, {.hex = 0xE7C70000}, {.hex = 0xEFD70000}, {.hex = 0xF7E70000},
            {.hex = 0xFFF70000}, {.hex = 0xFFF82600}, {.hex = 0xFFFA4B00}, {.hex = 0xFFFB7100}
        },
        // Variant 2
        {
            {.hex = 0x773F0000}, {.hex = 0x8F4F1000}, {.hex = 0xA75F1F00}, {.hex = 0xC36B1F00},
            {.hex = 0xDF771F00}, {.hex = 0xD76B1700}, {.hex = 0xCF5F0F00}, {.hex = 0xE7670F00},
            {.hex = 0xFF6F0F00}, {.hex = 0xFF832B00}, {.hex = 0xFF974700}, {.hex = 0xFFC19100}
        },
        // Variant 3
        {
            {.hex = 0x414B8D00}, {.hex = 0x4E579400}, {.hex = 0x5A649A00}, {.hex = 0x6770A100},
            {.hex = 0x727CB400}, {.hex = 0x7C87C600}, {.hex = 0x8793D900}, {.hex = 0x959DD600},
            {.hex = 0xA2A6D200}, {.hex = 0xB0B0CF00}, {.hex = 0xB0B0CF00}, {.hex = 0xB0B0CF00}
        }
    },
    // Water
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Grass
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Electric
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Ice
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Fighting
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Poison
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Ground
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Flying
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Psychic
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Bug
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Rock
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Ghost
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Dragon
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Dark
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Steel
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
    // Fairy
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}
        }
    },
};


void SwapTypeWanPalette(int wan_index, enum type_id type_0, enum type_id type_1, int seed) {
    struct wan_palettes *palettes = WAN_TABLE->sprites[wan_index].sprite_start->image_header->palettes;
    struct rgba *palette = palettes->palette_bytes;
    int palette_size = palettes->nb_color;
    struct hue_group_info group_info[palette_size];
    struct hue_index hue_indexes[palette_size];
    struct hue_group_tracker hgt;
    hgt.indexes = hue_indexes;
    hgt.group_info = group_info;
    
    int hue_num_groups = CreateHueGroupsFromPalette(palette, palette_size, &hgt, true);
    if (hue_num_groups <= 0) {
        return; // Palette is in grayscale.
    }
    
    int valid_colors = hgt.valid_colors;
    for (int i = 0; i < hue_num_groups; i++) {
        // Grab all the colors in this group.
        int luminance[palette_size];
        int original_indexes_lum[palette_size];
        int luminance_entries = 0;
        for (int j = 0; j < valid_colors; j++) {
            if (hue_indexes[j].group == i) {
                int original_index = hue_indexes[j].original_index;
                original_indexes_lum[luminance_entries] = original_index;
                luminance[luminance_entries] = CalculateLuminanceFromRGB(palette[original_index]);
                luminance_entries++;
            }
        }
        
        // Sort the colors in the group by luminance.
        for (int j = 1; j < luminance_entries; j++) {
            for (int k = j; k > 0 && luminance[k - 1] > luminance[k]; k--) {
                int temp_1 = original_indexes_lum[k];
                int temp_2 = luminance[k];
                original_indexes_lum[k] = original_indexes_lum[k - 1];
                luminance[k] = luminance[k - 1];
                original_indexes_lum[k - 1] = temp_1;
                luminance[k - 1] = temp_2;
            }
        }
        
        // Replace the colors with predetermined palettes.
        for (int j = 0; j < luminance_entries; j++) {
            int original_index = original_indexes_lum[j];
            int replace_color_variant = (i + seed) & 0x3;
            int color_iterator = _s32_div_f(12, luminance_entries);
            enum type_id type_to_use;
            if(type_1 == TYPE_NONE) {
                type_to_use = type_0;
            } else {
                if(seed & 0x1) {
                    type_to_use = type_0;
                } else {
                    type_to_use = type_1;
                }
            }
            type_to_use = TYPE_FIRE; // TODO: Remove this when done.
            struct rgba color = type_swap_color_table[TYPE_FIRE][replace_color_variant][color_iterator * j].rgba;
            // TODO: Fix this. I'm too lazy to fix this.
            palette[original_index].r = color.a;
            palette[original_index].g = color.b;
            palette[original_index].b = color.g;
        }
    }
}

void HueShiftWanPalette(int wan_index, int shift) {
    if (shift < 0) {
        shift = 360 + (shift % 360);
    }
    
    // Based upon the following answer: https://stackoverflow.com/a/8510751
    // The below shifts are handled using a rotation matrix created from the
    // hue shift value applied to our rgb color vector.
    // The rotation matrix is:
    // [cos(hue) + (1.0 - cos(hue))/3, (1.0 - cos(hue))/3 - sqrt(1/3) * sin(hue), (1.0 - cos(hue))/3 + sqrt(1/3) * sin(hue)]
    // [(1.0 - cos(hue))/3 + sqrt(1/3) * sin(hue), cos(hue) + (1.0 - cos(hue))/3, (1.0 - cos(hue))/3 - sqrt(1/3) * sin(hue)]
    // [(1.0 - cos(hue))/3 - sqrt(1/3) * sin(hue), (1.0 - cos(hue))/3 + sqrt(1/3) * sin(hue), cos(hue) + (1.0 - cos(hue))/3]
    // However, everything is shifted 12 bits to the left since the TRIG_TABLE has
    // 12 fractional bits. Only at the very do I remove the fractional bits.
    // Q: Where does 2365 come from?
    // A: sqrt(1/3) << 12
    int cosine = (int)(TRIG_TABLE[0xFFF & (shift * 4096)/360].cos);
    int sine = (int)(TRIG_TABLE[0xFFF & (shift * 4096)/360].sin);
    int matrix[3][3];
    matrix[0][0] = cosine + (0x1000 - cosine) / 3;
    matrix[1][1] = cosine + (0x1000 - cosine) / 3;
    matrix[2][2] = cosine + (0x1000 - cosine) / 3;
    matrix[0][1] = (0x1000 - cosine) / 3 - ((2365 * sine) >> 12);
    matrix[1][2] = (0x1000 - cosine) / 3 - ((2365 * sine) >> 12);
    matrix[2][0] = (0x1000 - cosine) / 3 - ((2365 * sine) >> 12);
    matrix[0][2] = (0x1000 - cosine) / 3 + ((2365 * sine) >> 12);
    matrix[1][0] = (0x1000 - cosine) / 3 + ((2365 * sine) >> 12);
    matrix[2][1] = (0x1000 - cosine) / 3 + ((2365 * sine) >> 12);
    
    struct wan_palettes *palettes = WAN_TABLE->sprites[wan_index].sprite_start->image_header->palettes;
    struct rgba *palette = palettes->palette_bytes;
    int num_colors = palettes->nb_color;
    for (int i = 0; i < num_colors; i++) {
        int red = palette[i].r;
        int green = palette[i].g;
        int blue = palette[i].b;
        
        if (red == green && green == blue) {
            continue; // Skip this color.
        }
        
        // Calculate the new colors.
        int rx = ((red * matrix[0][0]) >> 12) + ((green * matrix[0][1]) >> 12) + ((blue * matrix[0][2]) >> 12);
        int gx = ((red * matrix[1][0]) >> 12) + ((green * matrix[1][1]) >> 12) + ((blue * matrix[1][2]) >> 12);
        int bx = ((red * matrix[2][0]) >> 12) + ((green * matrix[2][1]) >> 12) + ((blue * matrix[2][2]) >> 12);
        
        // Clamp invalid values after rotating our cube.
        if (rx < 0) {
            rx = 0;
        }
        if (gx < 0) {
            gx = 0;
        }
        if (bx < 0) {
            bx = 0;
        }
        if (rx > 255) {
            rx = 255;
        }
        if (gx > 255) {
            gx = 255;
        }
        if (bx > 255) {
            bx = 255;
        }
        
        palette[i].r = (uint8_t)rx;
        palette[i].g = (uint8_t)gx;
        palette[i].b = (uint8_t)bx;
    }
}

bool __attribute__((used)) ReseedRandomizer() {
    randomizer_mode_seed = DungeonRand16Bit() || (DungeonRand16Bit() << 16);
    DetermineAllTilesWalkableNeighbors(); // original instruction
}

bool __attribute__((used)) MonsterIgnoresRandomizer(enum monster_id monster_id) {
    if ( // Deerling :(
        monster_id == 0x474 || monster_id == 0x475 || monster_id == 0x476 || monster_id == 0x477 ||
        monster_id == 0x21C || monster_id == 0x21D || monster_id == 0x21E || monster_id == 0x21F
    ) {
        return true;
    }

    if(monster_id == 537 || monster_id == 1137) { // Larvesta
        return true;
    }

    if(monster_id == 1237 || monster_id == 1238) { // Volcarona
        return true;
    }

    if(monster_id == 0x21A || monster_id == 0x21B) { // Wishiwashi
        return true;
    }


    return false;
}

enum type_id __attribute__((used)) GetRandomizedType(enum monster_id monster_id, int type_index) {\
    int rotate = monster_id % 32;
    enum type_id r_type_0 = (((randomizer_mode_seed << rotate) | ((randomizer_mode_seed) >> (32 - rotate))) ^ monster_id) % TYPE_NEUTRAL;
    if(type_index == 0) {
        return r_type_0;
    }

    enum type_id r_type_1 = ((randomizer_mode_seed) ^ ((randomizer_mode_seed) >> (32 - rotate))) % TYPE_NEUTRAL;
    if(r_type_0 == r_type_1) {
        return TYPE_NONE;
    }
    return r_type_1;
}

void __attribute__((naked)) __attribute__((used)) GetRandomizedTypeTrampoline(enum monster_id) {
    asm("push {r0,r1,r2,r3,lr}");
    asm("bl  IsGameInEnemyRandomizerMode");
    asm("cmp r0,#0x1");
    asm("pop {r0,r1,r2,r3,lr}");
    asm("beq GetRandomizedType");
    asm("mov r2,#0x44"); // original instruction
    asm("b   GetTypeUnhook");

}

void __attribute__((used)) RandomizePaletteForMonster(enum monster_id monster_id) {
    if(!IsGameInEnemyRandomizerMode()) {
        return;
    }

    if(MonsterIgnoresRandomizer(monster_id)) {
        return;
    }

    int wan_index = GetLoadedWanTableEntry(WAN_TABLE, PACK_ARCHIVE_MONSTER, GetSpriteIndex(monster_id));
    if(wan_index == -1) {
        return;
    }

    enum type_id r_type_0 = GetRandomizedType(monster_id, 0);
    enum type_id r_type_1 = GetRandomizedType(monster_id, 1);
    int method_randomness = ((randomizer_mode_seed * monster_id) ^ randomizer_mode_seed ^ monster_id) & 0x7F;

    // Handle any special cases here.
    switch(r_type_0) {
        default:
            break;
        case TYPE_NORMAL:
            if(method_randomness <= 32) {
                GrayscaleWanPalette(wan_index);
                return;
            }
        case TYPE_STEEL:
            if(method_randomness <= 16) {
                GrayscaleWanPalette(wan_index);
                return;
            }
        case TYPE_NEUTRAL:
            if(method_randomness <= 32) { // Pink!
                HueForceWanPalette(wan_index, 313, 280, 344);
                return;
            }
        case TYPE_DARK:
            if(method_randomness <= 8) {
                InvertWanPalette(wan_index);
                // return; fall through to the next case on purpose
            }
            if(method_randomness <= 16) {
                GrayscaleWanPalette(wan_index);
                InvertWanPalette(wan_index);
                return;
            }
    }

    if(method_randomness < 84) {
        SwapTypeWanPalette(wan_index, r_type_0, r_type_1, ((randomizer_mode_seed << 7) | ((randomizer_mode_seed) >> (32 - 7))) - monster_id);
    }
}

void __attribute__((used)) RandomizeSpawnlistPalettes() {
    if (false == IsGameInEnemyRandomizerMode()) {
        return;
    }

    int number_entries = DUNGEON_PTR->monster_spawn_entries_length;
    for (int i = 0; i < number_entries; i++){
        RandomizePaletteForMonster(DUNGEON_PTR->spawn_entries[i].id.val);
    }
    CountItemsOnFloorForAcuteSniffer(); // original instruction
}

// TODO: