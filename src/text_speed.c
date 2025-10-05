#include <pmdsky.h>
#include <cot.h>

uint16_t text_mult = 1;
uint16_t text_frac = 1;
uint16_t text_count = 0;

uint32_t __attribute__((used)) HookTextSpeed(int base_speed){
    unsigned long long div_result = _s32_div_f((base_speed * text_mult) + text_count, text_frac);
    text_count = div_result >> 32; // division remainder to text_count
    return div_result & 0xFFFFFFFF; // return quotient
}

void __attribute((naked)) HookTextSpeedWrapper(){
    asm("ldr r0,[r4, #+0x64]"); // original instruction
    asm("bl  HookTextSpeed");
    asm("b   ExitHookTextSpeedWrapper");
}

void __attribute__((naked)) HookTextLoop(){
    asm("ldr r0,[r4, #+0x80]");
    asm("cmp r0,#0x0");
    asm("bne ExitHookTextLoop");
    asm("mov r0,#0");
    asm("b   SomethingTextRelatedIdk");
}