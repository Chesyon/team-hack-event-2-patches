.nds
.include "symbols.asm"

.open "overlay11.bin", overlay11_start
    ; Top Screen actors
    .org DefaultActorTypeBranch
    .area 0x4
        b CheckSpecialActorType
    .endarea

    .org AfterAttributeBitfieldSwitchCase
    .area 0x4
        b ManipulateActorLayering
    .endarea
.close
