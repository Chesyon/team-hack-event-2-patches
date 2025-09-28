#include <pmdsky.h>
#include <cot.h>

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

// This probably already exists but is undocumented, so we get my janky approach of converting to a double and using the documented double function for comparisons.
bool feq(float a, float b){
    return _deq(_f2d(a), _f2d(b));
}

bool fls(float a, float b){
    return _dls(_f2d(a), _f2d(b));
}

float max3(float a, float b, float c) {
    float max = fls(b, a) ? a : b;
    return fls(c, max) ? max : c;
}

float min3(float a, float b, float c) {
    float min = fls(a, b) ? a : b;
    return fls(min, c) ? min : c;
}

float fabs(float x){
    return fls(_fflt(0), x) ? x : _fsub(_fflt(0), x);
}

// this is bad but if it works it works
float fmod(float dividend, float divisor){
    float mod;
    // Handling negative values
    if (fls(dividend, _fflt(0))) mod = _fsub(_fflt(0), dividend);
    else mod = dividend;
    if (fls(divisor, _fflt(0))) divisor = _fsub(_fflt(0), divisor);

    while(fls(divisor, mod)){
        mod = _fsub(mod, divisor);
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

    delta = _fsub(max, min);
    if (feq(max, _fflt(0))) {
        // R = G = B = 0 => Black
        hsv.s = _fflt(0);
        hsv.h = _fflt(0);
        return hsv;
    }

    hsv.s = _fdiv(delta, max);

    if (feq(delta, _fflt(0))) {
        hsv.h = _fflt(0);
    } else if (feq(max, float_rgb.r)) {
        hsv.h = _fmul(_fflt(60), _fadd(_fdiv(_fsub(float_rgb.g, float_rgb.b), delta), _fflt(6)));
    } else if (feq(max, float_rgb.g)) {
        hsv.h = _fmul(_fflt(60), _fadd(_fdiv(_fsub(float_rgb.b, float_rgb.r), delta), _fflt(2)));
    } else {
        hsv.h = _fmul(_fflt(60), _fadd(_fdiv(_fsub(float_rgb.r, float_rgb.g), delta), _fflt(4)));
    }

    if (fls(hsv.h, _fflt(0)))
        
        hsv.h = _fadd(hsv.h, _fflt(360));

    return hsv;
}

// Convert HSV to floatRGB
floatRGB hsv_to_float_rgb(HSV hsv) {
    floatRGB float_rgb;
    float c = _fmul(hsv.v, hsv.s);
    float x = _fmul(c, _fsub(_fflt(1), fabs(_fsub(fmod(_fdiv(hsv.h, _fflt(60)), _fflt(2)), 1))));
    float m = _fsub(hsv.v, c);

    float r, g, b;

    if (fls(hsv.h, 60)) {
        r = c, g = x, b = 0;
    } else if (fls(hsv.h, _fflt(120))) {
        r = x, g = c, b = 0;
    } else if (fls(hsv.h, _fflt(180))) {
        r = 0, g = c, b = x;
    } else if (fls(hsv.h, _fflt(240))) {
        r = 0, g = x, b = c;
    } else if (fls(hsv.h, _fflt(300))) {
        r = x, g = 0, b = c;
    } else {
        r = c, g = 0, b = x;
    }

    float_rgb.r = _fadd(r, m);
    float_rgb.g = _fadd(g, m);
    float_rgb.b = _fadd(b, m);

    return float_rgb;
}

// Shift the hue of an floatRGB color
floatRGB shift_hue(floatRGB color, int hue_shift_degrees) {
    HSV hsv = float_rgb_to_hsv(color);
    hsv.h = fmod(_fadd(hsv.h, _fflt(hue_shift_degrees)), _fflt(360));
    if (fls(hsv.h, _fflt(0)))
        hsv.h = _fadd(hsv.h, _fflt(360));
    return hsv_to_float_rgb(hsv);
}

floatRGB rgb_to_float_rgb(struct rgb rgb){
    floatRGB output;
    output.r = _fdiv(_fflt(rgb.r), _fflt(255));
    output.g = _fdiv(_fflt(rgb.g), _fflt(255));
    output.b = _fdiv(_fflt(rgb.b), _fflt(255));
    return output;
}

struct rgb float_rgb_to_rgb(floatRGB float_rgb){
    struct rgb output;
    output.r = _ffix(_fmul(float_rgb.r, _fflt(255)));
    output.g = _ffix(_fmul(float_rgb.g, _fflt(255)));
    output.b = _ffix(_fmul(float_rgb.b, _fflt(255)));
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
