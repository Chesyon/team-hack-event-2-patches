#include <pmdsky.h>
#include <cot.h>

#define HUE_DEGREE_CLOSE_CUTOFF 10
#define ARE_HUES_CLOSE(h1, h2) (h1 <= (HUE_DEGREE_CLOSE_CUTOFF/2)) && \
                                  (h2 >= 360 - (HUE_DEGREE_CLOSE_CUTOFF/2))

// TODO: If you want this to be controlled in some way using scripting put
// a variable aside.
int randomizer_mode_seed = 0;

bool __attribute__((used)) IsGameInEnemyRandomizerMode() {
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

// Note: If someone wants to go over and modify the colors listed here,
// I would suggest making the darkest and lightest of each variant farther
// apart. Since some of the colors I picked for the high and low are close,
// the end product is a little mushy.
union rgba_hex type_swap_color_table[TYPE_NEUTRAL + 1][4][12] = {
    // Neutral
    {
        // Variant 0
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
        },
        // Variant 1
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
        },
        // Variant 2
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
        },
        // Variant 3
        {
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
            {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000}, {.hex = 0x00000000},
        }
    },
    // Normal
    {
        // Variant 0
        {
            {.hex = 0x773f0000}, {.hex = 0x7c410100}, {.hex = 0x87480500}, {.hex = 0x934e0800},
            {.hex = 0x9b520a00}, {.hex = 0xa6580e00}, {.hex = 0xae5c1000}, {.hex = 0xb25e1100},
            {.hex = 0xba631400}, {.hex = 0xc76a1800}, {.hex = 0xd06f1a00}, {.hex = 0xde771f00},
        },
        // Variant 1
        {
            {.hex = 0xd7bf6700}, {.hex = 0xdac46c00}, {.hex = 0xdec97100}, {.hex = 0xe1cd7500},
            {.hex = 0xe5d37b00}, {.hex = 0xe8d77f00}, {.hex = 0xebdc8400}, {.hex = 0xefe18900},
            {.hex = 0xf2e58d00}, {.hex = 0xf6ea9200}, {.hex = 0xf8ee9600}, {.hex = 0xfff79f00},
        },
        // Variant 2
        {
            {.hex = 0x47676f00}, {.hex = 0x4b6b7200}, {.hex = 0x57747b00}, {.hex = 0x5e7a8100},
            {.hex = 0x627d8400}, {.hex = 0x6a848a00}, {.hex = 0x748d9200}, {.hex = 0x7c939800},
            {.hex = 0x82989d00}, {.hex = 0x889da100}, {.hex = 0x8da1a500}, {.hex = 0x94a7ab00},
        },
        // Variant 3
        {
            {.hex = 0xe35c7a00}, {.hex = 0xe4617e00}, {.hex = 0xe6698500}, {.hex = 0xe9728d00},
            {.hex = 0xeb7a9400}, {.hex = 0xed849c00}, {.hex = 0xef8aa200}, {.hex = 0xf295ab00},
            {.hex = 0xf49db200}, {.hex = 0xf6a6ba00}, {.hex = 0xfbb7c900}, {.hex = 0xfec2d200},
        }
    },
    // Fire
    {
        // Variant 0
        {
            {.hex = 0x9F000000}, {.hex = 0xAD100000}, {.hex = 0xBB200000}, {.hex = 0xC92F0000},
            {.hex = 0xD73F0000}, {.hex = 0xE1511800}, {.hex = 0xEB633000}, {.hex = 0xF5754700},
            {.hex = 0xFF875F00}, {.hex = 0xFF997700}, {.hex = 0xFFAA8E00}, {.hex = 0xFFBCA600},
        },
        // Variant 1
        {
            {.hex = 0xA76F0000}, {.hex = 0xB5810000}, {.hex = 0xC3930000}, {.hex = 0xD1A50000},
            {.hex = 0xDFB70000}, {.hex = 0xE7C70000}, {.hex = 0xEFD70000}, {.hex = 0xF7E70000},
            {.hex = 0xFFF70000}, {.hex = 0xFFF82600}, {.hex = 0xFFFA4B00}, {.hex = 0xFFFB7100},
        },
        // Variant 2
        {
            {.hex = 0x773F0000}, {.hex = 0x8F4F1000}, {.hex = 0xA75F1F00}, {.hex = 0xC36B1F00},
            {.hex = 0xDF771F00}, {.hex = 0xD76B1700}, {.hex = 0xCF5F0F00}, {.hex = 0xE7670F00},
            {.hex = 0xFF6F0F00}, {.hex = 0xFF832B00}, {.hex = 0xFF974700}, {.hex = 0xFFC19100},
        },
        // Variant 3
        {
            {.hex = 0x414B8D00}, {.hex = 0x4E579400}, {.hex = 0x5A649A00}, {.hex = 0x6770A100},
            {.hex = 0x727CB400}, {.hex = 0x7C87C600}, {.hex = 0x8793D900}, {.hex = 0x959DD600},
            {.hex = 0xA2A6D200}, {.hex = 0xB0B0CF00}, {.hex = 0xB0B0CF00}, {.hex = 0xB0B0CF00},
        }
    },
    // Water
    {
        // Variant 0
        {
            {.hex = 0x07125800}, {.hex = 0x08156800}, {.hex = 0x09187700}, {.hex = 0x0a1b8700},
            {.hex = 0x0b1e9500}, {.hex = 0x0c209d00}, {.hex = 0x0c22a700}, {.hex = 0x0d25b700},
            {.hex = 0x0f29c700}, {.hex = 0x0f2bd200}, {.hex = 0x102cd500}, {.hex = 0x102cd500},
        },
        // Variant 1
        {
            {.hex = 0x06616100}, {.hex = 0x076c6c00}, {.hex = 0x07737300}, {.hex = 0x08777700},
            {.hex = 0x087b7b00}, {.hex = 0x09888800}, {.hex = 0x0a979700}, {.hex = 0x0ca7a700},
            {.hex = 0x0db8b800}, {.hex = 0x0fc8c800}, {.hex = 0x0fd0d000}, {.hex = 0x10d1d100},
        },
        // Variant 2
        {
            {.hex = 0x05264b00}, {.hex = 0x06356b00}, {.hex = 0x06397300}, {.hex = 0x063d7b00},
            {.hex = 0x06418300}, {.hex = 0x07458b00}, {.hex = 0x07499300}, {.hex = 0x074d9b00}, 
            {.hex = 0x0851a300}, {.hex = 0x0855ab00}, {.hex = 0x0859b300}, {.hex = 0x095ebc00},
        },
        // Variant 3
        {
            {.hex = 0x0a014b00}, {.hex = 0x0d035700}, {.hex = 0x0f046000}, {.hex = 0x12066800},
            {.hex = 0x16087800}, {.hex = 0x1b0b8800}, {.hex = 0x1e0d9400}, {.hex = 0x200f9c00},
            {.hex = 0x220fa000}, {.hex = 0x2411a800}, {.hex = 0x2813b700}, {.hex = 0x2c16c400},
        }
    },
    // Grass
    {
        // Variant 0
        {
            {.hex = 0x25540c00}, {.hex = 0x2c670d00}, {.hex = 0x32770e00}, {.hex = 0x38850f00},
            {.hex = 0x3b8d1000}, {.hex = 0x3e941000}, {.hex = 0x419b1100}, {.hex = 0x46a71200},
            {.hex = 0x4cb71300}, {.hex = 0x53c71400}, {.hex = 0x5bdd1600}, {.hex = 0x5bdd1600},
        },
        // Variant 1
        {
            {.hex = 0x1f6d2d00}, {.hex = 0x20722f00}, {.hex = 0x227a3200}, {.hex = 0x26883700},
            {.hex = 0x29963d00}, {.hex = 0x2b9e4000}, {.hex = 0x2ea74300}, {.hex = 0x30af4600},
            {.hex = 0x32b74a00}, {.hex = 0x35c34e00}, {.hex = 0x37cb5100}, {.hex = 0x39d15400},
        },
        // Variant 2
        {
            {.hex = 0x0b5c0000}, {.hex = 0x0b630000}, {.hex = 0x0c6b0000}, {.hex = 0x0e760000},
            {.hex = 0x0f820000}, {.hex = 0x108b0000}, {.hex = 0x12980000}, {.hex = 0x13a70000},
            {.hex = 0x15b70000}, {.hex = 0x17c80000}, {.hex = 0x19d80000}, {.hex = 0x1be20000},
        },
        // Variant 3
        {
            {.hex = 0x3b600a00}, {.hex = 0x426c0a00}, {.hex = 0x49770b00}, {.hex = 0x4e810c00},
            {.hex = 0x548a0d00}, {.hex = 0x5c960e00}, {.hex = 0x609e0e00}, {.hex = 0x66a70f00},
            {.hex = 0x6db31000}, {.hex = 0x72bb1000}, {.hex = 0x7bc81200}, {.hex = 0x7bc81200},
        }
    },
    // Electric
    {
        // Variant 0
        {
            {.hex = 0x998e2c00}, {.hex = 0x9d922c00}, {.hex = 0xa69a2d00}, {.hex = 0xaea12e00},
            {.hex = 0xb4a62f00}, {.hex = 0xbbad3000}, {.hex = 0xbfb03000}, {.hex = 0xc7b83100},
            {.hex = 0xd7c73400}, {.hex = 0xe8d63600}, {.hex = 0xf1de3700}, {.hex = 0xfeea3900},
        },
        // Variant 1
        {
            {.hex = 0x755b2300}, {.hex = 0x7d612400}, {.hex = 0x87692700}, {.hex = 0x98752a00},
            {.hex = 0xa37d2d00}, {.hex = 0xab832e00}, {.hex = 0xb68b3100}, {.hex = 0xbe913300},
            {.hex = 0xc7983500}, {.hex = 0xd09f3700}, {.hex = 0xd8a53800}, {.hex = 0xe2ac3b00},
        },
        // Variant 2
        {
            {.hex = 0x6a752000}, {.hex = 0x717d2200}, {.hex = 0x79862400}, {.hex = 0x818e2600},
            {.hex = 0x89972800}, {.hex = 0x98a82c00}, {.hex = 0xa2b32f00}, {.hex = 0xa9ba3100},
            {.hex = 0xb6c93400}, {.hex = 0xbed13600}, {.hex = 0xc5d93800}, {.hex = 0xcde23b00},
        },
        // Variant 3
        {
            {.hex = 0x544c2a00}, {.hex = 0x5c532d00}, {.hex = 0x665c3100}, {.hex = 0x6d623400},
            {.hex = 0x756a3800}, {.hex = 0x7d713c00}, {.hex = 0x83763e00}, {.hex = 0x8a7d4100},
            {.hex = 0x97894700}, {.hex = 0xa5964d00}, {.hex = 0xad9d5000}, {.hex = 0xbba95700},
        }
    },
    // Ice
    {
        // Variant 0
        {
            {.hex = 0x077c8600}, {.hex = 0x08828d00}, {.hex = 0x0a8a9500}, {.hex = 0x0c919d00},
            {.hex = 0x0e99a500}, {.hex = 0x0f9ea900}, {.hex = 0x10a1ad00}, {.hex = 0x11a5b200},
            {.hex = 0x12a9b500}, {.hex = 0x13adb900}, {.hex = 0x14b1be00}, {.hex = 0x16b7c400},
        },
        // Variant 1
        {
            {.hex = 0x06597200}, {.hex = 0x065f7800}, {.hex = 0x06627c00}, {.hex = 0x066a8700},
            {.hex = 0x06708f00}, {.hex = 0x06779700}, {.hex = 0x067ea100}, {.hex = 0x0685a900},
            {.hex = 0x068db300}, {.hex = 0x0693bb00}, {.hex = 0x079ac400}, {.hex = 0x079ac400},
        },
        // Variant 2
        {
            {.hex = 0x4a839300}, {.hex = 0x518c9d00}, {.hex = 0x5a96a800}, {.hex = 0x619fb000},
            {.hex = 0x67a6b900}, {.hex = 0x6daec100}, {.hex = 0x6fb0c300}, {.hex = 0x74b6ca00},
            {.hex = 0x7abed200}, {.hex = 0x7ec2d600}, {.hex = 0x82c7dc00}, {.hex = 0x87cde200},
        },
        // Variant 3
        {
            {.hex = 0x15366500}, {.hex = 0x1a3e7200}, {.hex = 0x1d437a00}, {.hex = 0x1f468100},
            {.hex = 0x224b8900}, {.hex = 0x27549700}, {.hex = 0x2c5ca400}, {.hex = 0x2f61ab00},
            {.hex = 0x3063ae00}, {.hex = 0x3368b700}, {.hex = 0x376ec100}, {.hex = 0x3870c400},
        }
    },
    // Fighting
    {
        // Variant 0
        {
            {.hex = 0xa75f1f00}, {.hex = 0xab652500}, {.hex = 0xb16d2c00}, {.hex = 0xb3702f00},
            {.hex = 0xb9783600}, {.hex = 0xbf813d00}, {.hex = 0xc4894500}, {.hex = 0xcb924d00},
            {.hex = 0xce975100}, {.hex = 0xd29c5600}, {.hex = 0xd7a35c00}, {.hex = 0xdeae6600},
        },
        // Variant 1
        {
            {.hex = 0x8f000000}, {.hex = 0x97060400}, {.hex = 0xa20e0a00}, {.hex = 0xa9120d00},
            {.hex = 0xae161000}, {.hex = 0xb51b1400}, {.hex = 0xbd211900}, {.hex = 0xc5261d00},
            {.hex = 0xcd2c2100}, {.hex = 0xd02f2300}, {.hex = 0xd8342700}, {.hex = 0xe73f2f00},
        },
        // Variant 2
        {
            {.hex = 0xdf3f0000}, {.hex = 0xe2440200}, {.hex = 0xe54a0600}, {.hex = 0xe74d0800},
            {.hex = 0xe84f0900}, {.hex = 0xea540b00}, {.hex = 0xee590e00}, {.hex = 0xf05e1100},
            {.hex = 0xf4631400}, {.hex = 0xf7691700}, {.hex = 0xf96d1900}, {.hex = 0xff771f00},
        },
        // Variant 3
        {
            {.hex = 0xa75f1f00}, {.hex = 0xac621f00}, {.hex = 0xb1661f00}, {.hex = 0xb5691f00},
            {.hex = 0xbb6d1f00}, {.hex = 0xbf701f00}, {.hex = 0xc4731f00}, {.hex = 0xc8771f00},
            {.hex = 0xcd7a1f00}, {.hex = 0xd27e1f00}, {.hex = 0xd6811f00}, {.hex = 0xdf871f00},
        }
    },
    // Poison
    {
        // Variant 0
        {
            {.hex = 0x873f8700}, {.hex = 0x8b438b00}, {.hex = 0x8f489000}, {.hex = 0x934c9400},
            {.hex = 0x9a549c00}, {.hex = 0x9e59a100}, {.hex = 0xa25da500}, {.hex = 0xaf6cb400},
            {.hex = 0xbd7ac200}, {.hex = 0xc17ec600}, {.hex = 0xd494dc00}, {.hex = 0xd494dc00},
        },
        // Variant 1
        {
            {.hex = 0x28880100}, {.hex = 0x33950c00}, {.hex = 0x3a9d1300}, {.hex = 0x3ea11600},
            {.hex = 0x42a71b00}, {.hex = 0x4fb52800}, {.hex = 0x5bc43400}, {.hex = 0x63cc3c00},
            {.hex = 0x6ed94600}, {.hex = 0x7ae75200}, {.hex = 0x84f25c00}, {.hex = 0x8fff6700},
        },
        // Variant 2
        {
            {.hex = 0x31313100}, {.hex = 0x43434300}, {.hex = 0x4c4c4c00}, {.hex = 0x53535300},
            {.hex = 0x5b5b5b00}, {.hex = 0x64646400}, {.hex = 0x6b6b6b00}, {.hex = 0x73737300},
            {.hex = 0x7c7c7c00}, {.hex = 0x83838300}, {.hex = 0x8b8b8b00}, {.hex = 0x94949400},
        },
        // Variant 3
        {
            {.hex = 0x5f175700}, {.hex = 0x631b5c00}, {.hex = 0x732d6e00}, {.hex = 0x813b7e00},
            {.hex = 0x843e8100}, {.hex = 0x924d9100}, {.hex = 0x9f5ca000}, {.hex = 0xa15ea200},
            {.hex = 0xaf6cb200}, {.hex = 0xbd7cc200}, {.hex = 0xc07fc500}, {.hex = 0xd493db00},
        }
    },
    // Ground
    {
        // Variant 0
        {
            {.hex = 0x773f0000}, {.hex = 0x773f0000}, {.hex = 0x7c420300}, {.hex = 0x8f4f0d00},
            {.hex = 0xa45c1700}, {.hex = 0xae631d00}, {.hex = 0xb96a2200}, {.hex = 0xcd762d00},
            {.hex = 0xdd813500}, {.hex = 0xe8883b00}, {.hex = 0xfb944500}, {.hex = 0xfb944500},
        },
        // Variant 1
        {
            {.hex = 0xa76f0000}, {.hex = 0xab760000}, {.hex = 0xb7870000}, {.hex = 0xbe920000},
            {.hex = 0xc39a0000}, {.hex = 0xcba70000}, {.hex = 0xd6b70000}, {.hex = 0xddc30000},
            {.hex = 0xe2cb0000}, {.hex = 0xead70000}, {.hex = 0xf5e80000}, {.hex = 0xfff60000},
        },
        // Variant 2
        {
            {.hex = 0x47676f00}, {.hex = 0x4b6a7200}, {.hex = 0x516e7600}, {.hex = 0x58747c00},
            {.hex = 0x5e788000}, {.hex = 0x647d8500}, {.hex = 0x74899100}, {.hex = 0x83959d00},
            {.hex = 0x8b9ba300}, {.hex = 0x99a6ae00}, {.hex = 0xaeb6be00}, {.hex = 0xaeb6be00},
        },
        // Variant 3
        {
            {.hex = 0xa75f1f00}, {.hex = 0xb0702d00}, {.hex = 0xbb823d00}, {.hex = 0xbe874100},
            {.hex = 0xc6954d00}, {.hex = 0xd0a65b00}, {.hex = 0xd9b66800}, {.hex = 0xdfc07000},
            {.hex = 0xe4c97800}, {.hex = 0xedd98500}, {.hex = 0xfbf19a00}, {.hex = 0xfbf19a00},
        }
    },
    // Flying
    {
        // Variant 0
        {
            {.hex = 0xafb7bf00}, {.hex = 0xb4bcc300}, {.hex = 0xbcc3c900}, {.hex = 0xc2c8ce00},
            {.hex = 0xc7cdd200}, {.hex = 0xcdd2d700}, {.hex = 0xd4d8dc00}, {.hex = 0xdadee100},
            {.hex = 0xdee1e400}, {.hex = 0xe6e8eb00}, {.hex = 0xedeff000}, {.hex = 0xf6f7f800},
        },
        // Variant 1
        {
            {.hex = 0x0268b800}, {.hex = 0x0d72be00}, {.hex = 0x0f74c000}, {.hex = 0x177ac400},
            {.hex = 0x1f80c800}, {.hex = 0x2f8ed200}, {.hex = 0x429ddc00}, {.hex = 0x46a1df00},
            {.hex = 0x54abe600}, {.hex = 0x66baf100}, {.hex = 0x79cafb00}, {.hex = 0x79cafb00},
        },
        // Variant 2
        {
            {.hex = 0x3f373f00}, {.hex = 0x40373f00}, {.hex = 0x443c4300}, {.hex = 0x544a5100},
            {.hex = 0x63585d00}, {.hex = 0x685d6200}, {.hex = 0x75696d00}, {.hex = 0x85787b00},
            {.hex = 0x8c7e8000}, {.hex = 0x97888900}, {.hex = 0xa6969600}, {.hex = 0xa6969600},
        },
        // Variant 3
        {
            {.hex = 0x773f0000}, {.hex = 0x7c410100}, {.hex = 0x87480500}, {.hex = 0x934e0800},
            {.hex = 0x9b520a00}, {.hex = 0xa6580e00}, {.hex = 0xae5c1000}, {.hex = 0xb25e1100},
            {.hex = 0xba631400}, {.hex = 0xc76a1800}, {.hex = 0xd06f1a00}, {.hex = 0xdc751e00},
        }
    },
    // Psychic
    {
        // Variant 0
        {
            {.hex = 0x8f67bf00}, {.hex = 0x9068bf00}, {.hex = 0x946cc100}, {.hex = 0x9b74c600},
            {.hex = 0xa37cca00}, {.hex = 0xb38dd300}, {.hex = 0xc29ddc00}, {.hex = 0xc6a2de00},
            {.hex = 0xd4b1e600}, {.hex = 0xe1beed00}, {.hex = 0xf4d3f800}, {.hex = 0xf4d3f800},
        },
        // Variant 1
        {
            {.hex = 0xa76f0000}, {.hex = 0xab760000}, {.hex = 0xb7880000}, {.hex = 0xbe920000},
            {.hex = 0xc39a0000}, {.hex = 0xcba70000}, {.hex = 0xd6b70000}, {.hex = 0xddc30000},
            {.hex = 0xe2cb0000}, {.hex = 0xead70000}, {.hex = 0xf5e70000}, {.hex = 0xfef60000},
        },
        // Variant 2
        {
            {.hex = 0x572f9f00}, {.hex = 0x572f9f00}, {.hex = 0x58309f00}, {.hex = 0x5c34a200},
            {.hex = 0x633ca700}, {.hex = 0x734db100}, {.hex = 0x825dbb00}, {.hex = 0x8662be00},
            {.hex = 0x9471c700}, {.hex = 0xa07fd000}, {.hex = 0xad8dd800}, {.hex = 0xad8dd800},
        },
        // Variant 3
        {
            {.hex = 0x97375f00}, {.hex = 0x9c396200}, {.hex = 0xa33d6700}, {.hex = 0xab426d00},
            {.hex = 0xb7487500}, {.hex = 0xc24e7d00}, {.hex = 0xcb538300}, {.hex = 0xd6598b00},
            {.hex = 0xe15f9200}, {.hex = 0xe9639800}, {.hex = 0xf2689e00}, {.hex = 0xfb6da400},
        }
    },
    // Bug
    {
        // Variant 0
        {
            {.hex = 0x2e8b0700}, {.hex = 0x44981c00}, {.hex = 0x4d9d2400}, {.hex = 0x58a42f00},
            {.hex = 0x65ab3a00}, {.hex = 0x75b54a00}, {.hex = 0x83bd5700}, {.hex = 0x95c86900},
            {.hex = 0xa7d27900}, {.hex = 0xb5db8700}, {.hex = 0xc7e59800}, {.hex = 0xd6efa600},
        },
        // Variant 1
        {
            {.hex = 0x572f9f00}, {.hex = 0x58309f00}, {.hex = 0x5c34a200}, {.hex = 0x633ba600},
            {.hex = 0x673fa800}, {.hex = 0x6b43aa00}, {.hex = 0x724aae00}, {.hex = 0x764eb000},
            {.hex = 0x7b53b400}, {.hex = 0x8159b700}, {.hex = 0x855db900}, {.hex = 0x8e66be00},
        },
        // Variant 2
        {
            {.hex = 0xa76f0000}, {.hex = 0xab760000}, {.hex = 0xb7880000}, {.hex = 0xbe920000},
            {.hex = 0xc39a0000}, {.hex = 0xcba70000}, {.hex = 0xd6b80000}, {.hex = 0xddc30000},
            {.hex = 0xe2cb0000}, {.hex = 0xead70000}, {.hex = 0xf5e80000}, {.hex = 0xfbf20000},
        },
        // Variant 3
        {
            {.hex = 0x773f0000}, {.hex = 0x7c420100}, {.hex = 0x88480500}, {.hex = 0x934e0800},
            {.hex = 0x9b520a00}, {.hex = 0xa5580e00}, {.hex = 0xad5c1000}, {.hex = 0xb15e1100},
            {.hex = 0xba631400}, {.hex = 0xc86a1800}, {.hex = 0xd06f1a00}, {.hex = 0xdb751e00},
        }
    },
    // Rock
    {
        // Variant 0
        {
            {.hex = 0x47676f00}, {.hex = 0x4c6a7200}, {.hex = 0x516e7600}, {.hex = 0x57737b00},
            {.hex = 0x5e798100}, {.hex = 0x637d8500}, {.hex = 0x73899100}, {.hex = 0x83959d00}, 
            {.hex = 0x8b9ca400}, {.hex = 0x98a5ad00}, {.hex = 0xa9b2ba00}, {.hex = 0xa9b2ba00},
        },
        // Variant 1
        {
            {.hex = 0xa75f1f00}, {.hex = 0xab652500}, {.hex = 0xb16d2c00}, {.hex = 0xb3702f00},
            {.hex = 0xb9783600}, {.hex = 0xbf813d00}, {.hex = 0xc4894500}, {.hex = 0xcb924d00},
            {.hex = 0xce975100}, {.hex = 0xd29c5600}, {.hex = 0xd7a35c00}, {.hex = 0xdead6500},
        },
        // Variant 2
        {
            {.hex = 0x212a3a00}, {.hex = 0x242e4100}, {.hex = 0x29344900}, {.hex = 0x2e3a5300},
            {.hex = 0x313e5900}, {.hex = 0x33415d00}, {.hex = 0x3a496a00}, {.hex = 0x43547a00},
            {.hex = 0x495c8500}, {.hex = 0x51669500}, {.hex = 0x5b72a700}, {.hex = 0x6078b000},
        },
        // Variant 3
        {
            {.hex = 0x53330c00}, {.hex = 0x623e1200}, {.hex = 0x724a1900}, {.hex = 0x7f542000},
            {.hex = 0x875a2300}, {.hex = 0x97662a00}, {.hex = 0xac763400}, {.hex = 0xbc823b00},
            {.hex = 0xc3873e00}, {.hex = 0xd3934500}, {.hex = 0xe19e4c00}, {.hex = 0xe3a04d00},
        }
    },
    // Ghost
    {
        // Variant 0
        {
            {.hex = 0x9f3f8700}, {.hex = 0xa4448b00}, {.hex = 0xac4c9300}, {.hex = 0xb5559b00},
            {.hex = 0xbd5da200}, {.hex = 0xc565aa00}, {.hex = 0xcd6db100}, {.hex = 0xd676b900},
            {.hex = 0xde7ec100}, {.hex = 0xe787c900}, {.hex = 0xef8fd000}, {.hex = 0xf999d900},
        },
        // Variant 1
        {
            {.hex = 0x572f9f00}, {.hex = 0x58309f00}, {.hex = 0x5c34a200}, {.hex = 0x633ca700},
            {.hex = 0x734db100}, {.hex = 0x825dbb00}, {.hex = 0x8662be00}, {.hex = 0x9471c700},
            {.hex = 0xa07fd000}, {.hex = 0xad8cd800}, {.hex = 0xad8cd800}, {.hex = 0xad8cd800},
        },
        // Variant 2
        {
            {.hex = 0x173f7f00}, {.hex = 0x1c438300}, {.hex = 0x244a8b00}, {.hex = 0x2b4f9100},
            {.hex = 0x2e519300}, {.hex = 0x35579a00}, {.hex = 0x3d5ea100}, {.hex = 0x4665aa00},
            {.hex = 0x4e6bb100}, {.hex = 0x526eb400}, {.hex = 0x5974bb00}, {.hex = 0x657dc500},
        },
        // Variant 3
        {
            {.hex = 0x38373d00}, {.hex = 0x3d3c4300}, {.hex = 0x403f4700}, {.hex = 0x43434b00},
            {.hex = 0x4b4b5400}, {.hex = 0x4f505900}, {.hex = 0x52535d00}, {.hex = 0x595a6500},
            {.hex = 0x5e616c00}, {.hex = 0x60636e00}, {.hex = 0x66697600}, {.hex = 0x66697600},
        }
    },
    // Dragon
    {
        // Variant 0
        {
            {.hex = 0x1b025c00}, {.hex = 0x1f085c00}, {.hex = 0x220c5c00}, {.hex = 0x26125c00},
            {.hex = 0x29165c00}, {.hex = 0x2d1b5c00}, {.hex = 0x301f5c00}, {.hex = 0x33245c00},
            {.hex = 0x37295c00}, {.hex = 0x392d5c00}, {.hex = 0x3e335c00}, {.hex = 0x3e335c00},
        },
        // Variant 1
        {
            {.hex = 0x1f024700}, {.hex = 0x21054700}, {.hex = 0x23094700}, {.hex = 0x260e4700},
            {.hex = 0x27104700}, {.hex = 0x28124700}, {.hex = 0x2a154700}, {.hex = 0x2d1a4700},
            {.hex = 0x2f1d4700}, {.hex = 0x31224700}, {.hex = 0x33244700}, {.hex = 0x34264700},
        },
        // Variant 2
        {
            {.hex = 0x6d071900}, {.hex = 0x6a091a00}, {.hex = 0x680c1c00}, {.hex = 0x660e1d00},
            {.hex = 0x65101f00}, {.hex = 0x64112000}, {.hex = 0x63122000}, {.hex = 0x61152200},
            {.hex = 0x5e192500}, {.hex = 0x5c1c2700}, {.hex = 0x5a1e2800}, {.hex = 0x58222b00},
        },
        // Variant 3
        {
            {.hex = 0x053c6900}, {.hex = 0x0a3e6900}, {.hex = 0x0c3f6900}, {.hex = 0x0e406900},
            {.hex = 0x13436a00}, {.hex = 0x1a466a00}, {.hex = 0x1e486b00}, {.hex = 0x234b6b00},
            {.hex = 0x2a4e6b00}, {.hex = 0x2e506c00}, {.hex = 0x34536c00}, {.hex = 0x38556d00},
        }
    },
    // Dark
    {
        // Variant 0
        {
            {.hex = 0x3f3f3f00}, {.hex = 0x40404000}, {.hex = 0x42424200}, {.hex = 0x46464600},
            {.hex = 0x4a4a4a00}, {.hex = 0x4e4e4e00}, {.hex = 0x52525200}, {.hex = 0x56565600},
            {.hex = 0x5a5a5a00}, {.hex = 0x5e5e5e00}, {.hex = 0x62626200}, {.hex = 0x66666600},
        },
        // Variant 1
        {
            {.hex = 0x373f8f00}, {.hex = 0x37408f00}, {.hex = 0x38408f00}, {.hex = 0x3c469200},
            {.hex = 0x414e9500}, {.hex = 0x47589a00}, {.hex = 0x4e629e00}, {.hex = 0x50649f00},
            {.hex = 0x546aa200}, {.hex = 0x5b76a700}, {.hex = 0x617eab00}, {.hex = 0x6686ae00},
        },
        // Variant 2
        {
            {.hex = 0x21192100}, {.hex = 0x231c2300}, {.hex = 0x251e2500}, {.hex = 0x27202700},
            {.hex = 0x2a242a00}, {.hex = 0x2e292e00}, {.hex = 0x312d3100}, {.hex = 0x35323500},
            {.hex = 0x39363900}, {.hex = 0x3d3b3d00}, {.hex = 0x403f4000}, {.hex = 0x45444500},
        },
        // Variant 3
        {
            {.hex = 0x4f182a00}, {.hex = 0x57172c00}, {.hex = 0x61172f00}, {.hex = 0x69173100},
            {.hex = 0x78163500}, {.hex = 0x87163a00}, {.hex = 0x95153e00}, {.hex = 0x9d154000},
            {.hex = 0xa7154300}, {.hex = 0xb8144800}, {.hex = 0xc8144d00}, {.hex = 0xd7145100},
        }
    },
    // Steel
    {
        // Variant 0
        {
            {.hex = 0x4f6e7500}, {.hex = 0x5e7a8100}, {.hex = 0x627d8400}, {.hex = 0x728b9000},
            {.hex = 0x83999d00}, {.hex = 0x889da200}, {.hex = 0x95a8ac00}, {.hex = 0xa7b7ba00},
            {.hex = 0xb0bec100}, {.hex = 0xb8c5c700}, {.hex = 0xcdd6d700}, {.hex = 0xcdd6d700},
        },
        // Variant 1
        {
            {.hex = 0x3e3e3e00}, {.hex = 0x44444400}, {.hex = 0x4c4c4c00}, {.hex = 0x53535300},
            {.hex = 0x5b5b5b00}, {.hex = 0x64646400}, {.hex = 0x6c6c6c00}, {.hex = 0x77777700},
            {.hex = 0x88888800}, {.hex = 0x98989800}, {.hex = 0xa7a7a700}, {.hex = 0xb5b5b500},
        },
        // Variant 2
        {
            {.hex = 0x506e7600}, {.hex = 0x627d8400}, {.hex = 0x728b9100}, {.hex = 0x82989d00},
            {.hex = 0x889da200}, {.hex = 0x95a8ac00}, {.hex = 0xa7b6ba00}, {.hex = 0xb0bec100},
            {.hex = 0xb9c5c800}, {.hex = 0xcbd4d600}, {.hex = 0xdce2e400}, {.hex = 0xf0f3f400},
        },
        // Variant 3
        {
            {.hex = 0x27262800}, {.hex = 0x2f2d3000}, {.hex = 0x312f3300}, {.hex = 0x37343a00},
            {.hex = 0x3e394200}, {.hex = 0x423d4700}, {.hex = 0x47414d00}, {.hex = 0x4c465300},
            {.hex = 0x534c5b00}, {.hex = 0x584f6000}, {.hex = 0x5c536400}, {.hex = 0x63596d00},
        }
    },
    // Fairy
    {
        // Variant 0
        {
            {.hex = 0x8e226b00}, {.hex = 0x92236e00}, {.hex = 0x9a257400}, {.hex = 0xa4297c00},
            {.hex = 0xac2b8200}, {.hex = 0xb42e8900}, {.hex = 0xbb308e00}, {.hex = 0xc7349800},
            {.hex = 0xd83aa500}, {.hex = 0xe33dad00}, {.hex = 0xe83fb100}, {.hex = 0xea40b300},
        },
        // Variant 1
        {
            {.hex = 0x86284b00}, {.hex = 0x8b294d00}, {.hex = 0x972c5400}, {.hex = 0xa32f5a00},
            {.hex = 0xaa305d00}, {.hex = 0xaf326100}, {.hex = 0xb8346500}, {.hex = 0xc5376c00},
            {.hex = 0xcd397000}, {.hex = 0xd83b7600}, {.hex = 0xe43e7c00}, {.hex = 0xea408000},
        },
        // Variant 2
        {
            {.hex = 0x710d2300}, {.hex = 0x7b0d2600}, {.hex = 0x870f2900}, {.hex = 0x910f2c00},
            {.hex = 0x98102e00}, {.hex = 0x9e113000}, {.hex = 0xa8113300}, {.hex = 0xb8133700},
            {.hex = 0xc7143c00}, {.hex = 0xd2153f00}, {.hex = 0xda164100}, {.hex = 0xe2174400},
        },
        // Variant 3
        {
            {.hex = 0x6d0f6300}, {.hex = 0x750f6a00}, {.hex = 0x7d107200}, {.hex = 0x86107a00},
            {.hex = 0x8e118100}, {.hex = 0x97118900}, {.hex = 0xa7139800}, {.hex = 0xb814a700},
            {.hex = 0xc915b600}, {.hex = 0xd115be00}, {.hex = 0xd916c500}, {.hex = 0xe217cd00},
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
        int color_iterator = _s32_div_f(12, luminance_entries - 1);
        if(color_iterator < 1) {
            color_iterator = 1;
        }
        for (int j = 0; j < luminance_entries; j++) {
            int original_index = original_indexes_lum[j];
            int replace_color_variant = (i + seed) & 0x3;
            enum type_id type_to_use;
            if(type_1 == TYPE_NONE || i == 0) {
                type_to_use = type_0;
            } else {
                if(((seed * i)) & 0x3) {
                    type_to_use = type_0;
                } else {
                    type_to_use = type_1;
                }
            }
            // TODO: Fix this. I put the colors in the wrong order. So... uhhh
            // it uses 11 MINUS color iterator instead.
            int next_index = 11 - color_iterator * j;
            if(next_index < 0) {
                next_index = 0;
            }
            struct rgba color = type_swap_color_table[type_to_use][replace_color_variant][11 - color_iterator * j].rgba;
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

void __attribute__((used)) ReseedRandomizer() {
    randomizer_mode_seed = DungeonRand16Bit() | (DungeonRand16Bit() << 16);
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

    if(monster_id == 1213) { // Ruffles
        return true;
    }

    if(monster_id == 553) { // Decoy
        return true;
    }

    return false;
}

enum type_id __attribute__((used)) GetRandomizedType(enum monster_id monster_id, int type_index) {\
    int rotate = monster_id % 32;
    enum type_id r_type_0 = ((((randomizer_mode_seed << rotate) | ((randomizer_mode_seed) >> (32 - rotate))) ^ monster_id) % TYPE_NEUTRAL) + 1;
    if(type_index == 0) {
        return r_type_0;
    }

    enum type_id r_type_1 = (((randomizer_mode_seed) ^ ((randomizer_mode_seed) >> (32 - rotate))) % TYPE_NEUTRAL) + 1;
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


int hue_type_list[TYPE_NEUTRAL + 1][3] = {
    // None
    {0, 0, 0},
    // TYPE_NORMAL
    {0, 0, 0},
    // TYPE_FIRE
    {4, 33, 50},
    // TYPE_WATER
    {191, 250, 170},
    // TYPE_GRASS
    {80, 133, 116},
    // TYPE_ELECTRIC
    {55, 55, 65},
    // TYPE_ICE
    {165, 200, 255},
    // TYPE_FIGHTING
    {30, 45, 38},
    // TYPE_POISON
    {278, 126, 290},
    // TYPE_GROUND
    {25, 355, 36},
    // TYPE_FLYING
    {180, 220, 190},
    // TYPE_PSYCHIC
    {300, 330, 315}, 
    // TYPE_BUG
    {100, 45, 33},
    // TYPE_ROCK
    {30, 30, 30},
    // TYPE_GHOST
    {265, 285, 300},
    // TYPE_DRAGON
    {240, 270, 211},
    // TYPE_DARK
    {0, 0, 0},
    // TYPE_STEEL
    {0, 0, 0},
    // TYPE_FAIRY
    {300, 280, 160},
};

void __attribute__((used)) RandomizePaletteForMonster(enum monster_id monster_id) {
    if(false == IsGameInEnemyRandomizerMode()) {
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
            if(method_randomness >= 64) {
                GrayscaleWanPalette(wan_index);
                return;
            }
        case TYPE_STEEL:
            if(method_randomness >= 64) {
                GrayscaleWanPalette(wan_index);
                return;
            }
        case TYPE_NEUTRAL:
            if(method_randomness <= 32) { // Pink!
                HueForceWanPalette(wan_index, 313, 280, 344);
                return;
            }
        case TYPE_DARK:
            if(method_randomness >= 96) {
                InvertWanPalette(wan_index);
                return;
            }
            if(method_randomness >= 64) {
                GrayscaleWanPalette(wan_index);
                InvertWanPalette(wan_index);
                return;
            }
    }

    // Swap the colors out.
    if(method_randomness < 64) {
        SwapTypeWanPalette(wan_index, r_type_0, r_type_1, ((randomizer_mode_seed << 7) | ((randomizer_mode_seed) >> (32 - 7))) - monster_id);
    }

    // Otherwise, use the prettiest looking function we have and shift palettes.
    int primary_hue_index = method_randomness % 3;
    enum type_id secondary_hue_index = (method_randomness >> 2) % 3;
    enum type_id tertiary_hue_index = (method_randomness >> 4) % 3;
    enum type_id tertiary_type_hue = r_type_1 == TYPE_NONE ? r_type_0 : r_type_1;
    HueForceWanPalette(wan_index, hue_type_list[r_type_0][primary_hue_index], hue_type_list[r_type_0][(secondary_hue_index + 1)], hue_type_list[tertiary_type_hue][tertiary_hue_index]);
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

void __attribute__((used)) RandomizeAttackPalette(int wan_index){
    if (false == IsGameInEnemyRandomizerMode()) {
        return;
    }

    if(wan_index == -1) {
        return;
    }

    struct wan_palettes *palettes_to = WAN_TABLE->sprites[wan_index].sprite_start->image_header->palettes;
    struct rgba *palette = palettes_to->palette_bytes;
    int palette_size = palettes_to->nb_color;

    int number_entries = DUNGEON_PTR->monster_spawn_entries_length;
    for (int i = 0; i < number_entries; i++){
        int monster_id = DUNGEON_PTR->spawn_entries[i].id.val;
        if(GetLoadedWanTableEntry(WAN_TABLE, PACK_ARCHIVE_M_ATTACK, GetSpriteIndex(monster_id)) == wan_index) {
            int wan_index_base = GetLoadedWanTableEntry(WAN_TABLE, PACK_ARCHIVE_MONSTER, GetSpriteIndex(monster_id));
            if(wan_index_base == -1) {
                return;
            }
            struct wan_palettes *palettes_from = WAN_TABLE->sprites[wan_index_base].sprite_start->image_header->palettes;
            struct rgba *palette_from = palettes_from->palette_bytes;
            for(int j = 0; j < palette_size; j++) {
                palette[j].r = palette_from[j].r;
                palette[j].g = palette_from[j].g;
                palette[j].b = palette_from[j].b;
            }
            return;
        }
    }
}

void __attribute__((naked)) __attribute__((used)) RandomizeAttackPaletteTrampoline(){
    asm("push {r2, r14}");
    asm("strh r0,[r1]"); // original instruction
    asm("bl RandomizeAttackPalette");
    asm("pop {r2, r15}"); // return
}