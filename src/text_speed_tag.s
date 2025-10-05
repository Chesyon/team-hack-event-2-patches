vstag_HookSpeed:
    ldr r0,[r4, #+0x64]
    ldr r1,=vstag_spd
    ldrh r1, [r1]
    mul r0,r1,r0
    ldr r1,=vstag_count
    ldrh r1, [r1]
    add r0,r0,r1
    ldr r1,=vstag_frac
    ldrh r1, [r1]
    bl _s32_div_f
    ldr r2,=vstag_count
    str r1,[r2]
    b vstag_ExitHookSpeed
vstag_HookLoop:
    ldr r0,[r4, #+0x80]
    cmp r0,#0x0
    bne vstag_ExitHookLoop
    // Here is the fun part
    mov r0,#0
    b vstag_Idk1
vstag_HookVLetter:
    ldr r0,[r13, #+0x70]
    ldr r1,=vstag_char_VS
    bl StrcmpTag
    cmp r0,#0x0
    beq vstag_second_test
    ldr r0,[r13, #+0x74]
    bl AtoiTag
    ldr r1,=vstag_spd
    strh r0, [r1]
    cmp r6,#2
    moveq r0,#1
    beq vstag_no_second_param
    ldr r0,[r13, #+0x78]
    bl AtoiTag
vstag_no_second_param:
    ldr r1,=vstag_frac
    strh r0, [r1]
    mov r0,#0
    ldr r1,=vstag_count
    str r0, [r1]
    str r0,[r4, #+0x80]
    b vstag_Idk2
vstag_second_test:
    ldr r0,[r13, #+0x70]
    ldr r1,=vstag_char_VR
    bl StrcmpTag
    cmp r0,#0x0
    beq vstag_Idk3
    mov r0,#0x1
    ldr r1,=vstag_spd
    strh r0, [r1]
    mov r0,#0x1
    ldr r1,=vstag_frac
    strh r0, [r1]
    mov r0,#0
    ldr r1,=vstag_count
    str r0, [r1]
    str r0,[r4, #+0x80]
    b vstag_Idk2
    .pool
vstag_spd:
    .hword 1 // BaseMultiplier
vstag_frac:
    .hword 1 // BaseFrac
vstag_count:
    .word 0x0
vstag_held:
    .hword 0
vstag_char_VS:
    .ascii "VS"
    .byte 0
vstag_char_VR:
    .ascii "VR"
    .byte 0