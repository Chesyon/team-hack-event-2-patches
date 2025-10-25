#include <pmdsky.h>
#include <cot.h>

// ps: comments are about the default value
typedef enum PaletteAllocatorPool {
    PALETTE_POOL_FIRST=0 /* Alloc limited to the palette 0x0 */,
    PALETTE_POOL_PARTY=1 /* Alloc limited to 0x1B to 0x1E */,
    PALETTE_POOL_GENERAL=2 /* Alloc limited to 0x1 to 0x14 */
} PaletteAllocatorPool;

extern uint8_t* PALETTE_ALLOCATION_DATA [32]; // first half is for the vanilla palette (16 colors), second half is for the extended palette (256 colors, which consume 2 times more VRAM)
extern int PaletteAllocatorFindEmpty(enum PaletteAllocatorPool);

// Original from overlay_29::022de968 (US). Only override a specific call from party member allocation
// What this does is, if we try to allocate a palette for Wishiwashi, we return a palette from the standard rather than extended palette, halving the VRAM consumption.
// (The function responsible for allocating the monster VRAM will recognise that different palette)
// That mean that Washiwashi body size can be set to 2 rather than 4.
// (also, the game will mark the palette as used itself later)
// From an algorithmic point of view, this may fail, but it won’t, as the other monsters are allocated after the party.
int __attribute__((used)) PaletteAllocatorFindEmptyForPartyButModified(uint32_t monster_id) {

  if (monster_id == 538 || monster_id == 539) {
      for (int current = 1; current <= 0xF; current += 1) {
          if ((*PALETTE_ALLOCATION_DATA)[current] == 0) {
              return current;
          }
      }
  }

  return PaletteAllocatorFindEmpty(PALETTE_POOL_PARTY);
}
