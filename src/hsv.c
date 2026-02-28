#include <pmdsky.h>
#include <cot.h>
#include "floats.h"

// lord forgive me for i have sinned

// Structure to hold floatRGB values
typedef struct {
    float r; // 0 to 1
    float g;
    float b;
} floatRGB;

// Structure to hold HSV values
typedef struct {
    float h; // 0 to 360
    float s; // 0 to 1
    float v; // 0 to 1
} HSV;

float max3(float a, float b, float c) {
    float max = a > b ? a : b;
    return max > c ? max : c;
}

float min3(float a, float b, float c) {
    float min = a < b ? a : b;
    return min < c ? min : c;
}

float fabs(float x){
    return 0 < x ? x : 0 - x;
}

// this is bad but if it works it works
float fmod(float dividend, float divisor){
    float mod;
    mod = fabs(dividend);
    divisor = fabs(divisor);

    while(divisor < mod){
        mod -= divisor;
    }
    return mod;
}

// Convert floatRGB to HSV
HSV float_rgb_to_hsv(floatRGB float_rgb) {
    HSV hsv;
    float min, max, delta;
    min = min3(float_rgb.r, float_rgb.g, float_rgb.b);
    max = max3(float_rgb.r, float_rgb.g, float_rgb.b);
    hsv.v = max; // Value

    delta = max - min;
    if (max == 0) {
        // R = G = B = 0 => Black
        hsv.s = 0;
        hsv.h = 0;
        return hsv;
    }

    hsv.s = delta / max;
    if (delta == 0) {
        hsv.h = 0;
    } else if (max == float_rgb.r) {
        hsv.h = 60 * (((float_rgb.g - float_rgb.b) / delta) + 6);
    } else if (max == float_rgb.g) {
        hsv.h = 60 * (((float_rgb.b - float_rgb.r) / delta) + 2);
    } else {
        hsv.h = 60 * (((float_rgb.r - float_rgb.g) / delta) + 4);
    }

    if (hsv.h < 0)
        
        hsv.h += 360;

    return hsv;
}

// Convert HSV to floatRGB
floatRGB hsv_to_float_rgb(HSV hsv) {
    floatRGB float_rgb;
    float c = hsv.v * hsv.s;
    float x = c * (1 - fabs(fmod(hsv.h / 60, 2) - 1));
    float m = hsv.v - c;

    float r, g, b;

    if (hsv.h == hsv.s){
        return float_rgb;
    }
    if (hsv.h < 60) {
        r = c, g = x, b = 0;
    } else if (hsv.h < 120) {
        r = x, g = c, b = 0;
    } else if (hsv.h < 180) {
        r = 0, g = c, b = x;
    } else if (hsv.h < 240) {
        r = 0, g = x, b = c;
    } else if (hsv.h < 300) {
        r = x, g = 0, b = c;
    } else {
        r = c, g = 0, b = x;
    }

    float_rgb.r = r + m;
    float_rgb.g = g + m;
    float_rgb.b = b + m;

    return float_rgb;
}

// Shift the hue of an floatRGB color
floatRGB shift_hue(floatRGB color, int hue_shift_degrees) {
    HSV hsv = float_rgb_to_hsv(color);
    hsv.h = fmod(hsv.h + hue_shift_degrees, 360);
    if (hsv.h < 0)
        hsv.h += 360;
    return hsv_to_float_rgb(hsv);
}

floatRGB rgb_to_float_rgb(struct rgb rgb){
    floatRGB output;
    output.r = (float)(rgb.r) / 255;
    output.g = (float)(rgb.g) / 255;
    output.b = (float)(rgb.b) / 255;
    return output;
}

struct rgb float_rgb_to_rgb(floatRGB float_rgb){
    struct rgb output;
    output.r = float_rgb.r * 255;
    output.g = float_rgb.g * 255;
    output.b = float_rgb.b * 255;
    return output;
}

uint32_t rgb_to_packed(struct rgb rgb){
    return 0x80000000 +
    (rgb.b << 16) +
    (rgb.g << 8) +
    rgb.r;
}

struct rgb packed_to_rgb(uint32_t packed){
    struct rgb output;
    output.r = packed & 0xFF;
    output.g = (packed >> 8) & 0xFF;
    output.b = (packed >> 16) & 0xFF;
    return output;
}

struct rgb hueshift_rgb(struct rgb color, int hue_shift_degrees){
    return float_rgb_to_rgb(
        shift_hue(
            rgb_to_float_rgb(color), 
            hue_shift_degrees
        )
    );
}
