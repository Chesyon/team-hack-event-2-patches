// Handles custom uppercase text tags.
#include <pmdsky.h>
#include <cot.h>
#include "text_speed.h"

// basic util functions that are used by every handler wrapper. having these as functions saves 5 instructions per wrapper.
void __attribute__((naked)) LoadUppercaseTagParameters(){
    asm("ldr r0,[r13,#0x70]");
    asm("ldr r1,[r13,#0x74]");
    asm("ldr r2,[r13,#0x78]");
    asm("mov r3,r6");
    asm("bx  lr");
}

void __attribute((naked)) ReturnFromUppercaseTag(){
    asm("cmp r0,#0");
    asm("beq UppercaseTagCodeError");
    asm("b AfterUppercaseTagIsFound");
}

/*
    Handles various possible text tags for the character 'N'. Currently, the new text tags include:
        - No texts tags exist currently. Feel free to add your own!

    Returns whether a valid text tag was parsed or not.
*/
bool __attribute__((used)) HandleUppercaseNTag(const char* tag_string, const char* tag_string_param1, const char* tag_string_param2, int tag_param_count)
{
    // Demonstration of the syntax for adding an uppercase tag, in this case, one named "NOPE".
    /*if(StrcmpTag(tag_string, "NOPE"))
    {
        CardPullOut();
        return true;
    }*/
    return false;
}

void __attribute__((naked)) HandleUppercaseNTagWrapper()
{
    asm("bl LoadUppercaseTagParameters");
    asm("bl HandleUppercaseNTag");
    asm("b  ReturnFromUppercaseTag");
}

/*
    Handles various possible text tags for the character 'V'. Currently, the new text tags include:
        - "VS:X:Y", sets the text speed to X/Y of the vanilla speed. If Y is not given (VS:X), Y is treated as 1.
        - "VR", identical to "VS:1". Restores text speed to vanilla.

    Returns whether a valid text tag was parsed or not.
*/
bool __attribute__((used)) HandleUppercaseVTag(const char* tag_string, const char* tag_string_param1, const char* tag_string_param2, int tag_param_count)
{
    if(StrcmpTag(tag_string, "VS"))
    {
        if(tag_param_count == 2) text_frac = 1;
        else if(tag_param_count == 3) text_frac = AtoiTag(tag_string_param2);
        else return false;
        text_mult = AtoiTag(tag_string_param1);
        text_count = 0;
        return true;
    }
    else if(StrcmpTag(tag_string, "VR")){
        text_mult = 1;
        text_frac = 1;
        text_count = 0;
        return true;
    }
    return false;
}

void __attribute__((naked)) HandleUppercaseVTagWrapper()
{
    asm("bl LoadUppercaseTagParameters");
    asm("bl HandleUppercaseVTag");
    asm("b  ReturnFromUppercaseTag");
}