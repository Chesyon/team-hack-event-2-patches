

.nds
.include "symbols.asm"

.open "arm9.bin", arm9_start
.org GetAbilityString ; no ov36 needed here! this one is compiled poorly enough that we have just enough space to spare for the extra logic.
        .area 0x34
            cmp    r1,#0x7C
            ldrlth r2,[pc,#+0xC] ; // lt is technically not needed because it'd just get overwritten by AltOffsetName if the check passed, but loading twice would be redundant.
            ldrgeh r2,[pc,#+0xA] ; // =AltOffsetName
            add    r1,r1,r2
            mov    r2,#0x50
            b      CopyNStringFromId
            .hword 0x35DE; // StandardOffsetName: Original Ability Name Offset 
            .hword 0x579E; // AltOffsetName: String 22554 is for ability name 0x7C.
            .hword 0x365A; // StandardOffsetDesc: Original Ability Desc Offset
            .hword 0x5822; // AltOffsetDesc: String 22686 is for ability desc 0x7C.
        // GetAbilityDescStringId
            cmp    r0,#0x7c
            ldrlth r1,[pc,#-0x10] // =0x365C
            ldrgeh r1,[pc,#-0x12] // =AltOffsetDesc
            add    r0,r0,r1
            bx     lr
        .endarea
.close