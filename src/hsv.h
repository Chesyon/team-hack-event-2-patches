#include <pmdsky.h>
#include <cot.h>

struct rgb hueshift_rgb(struct rgb color, int hue_shift_degrees);
uint32_t rgb_to_packed(struct rgb rgb);
struct rgb packed_to_rgb(uint32_t packed);