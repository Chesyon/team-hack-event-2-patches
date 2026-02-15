Cease:
    push  {lr}
    mov   r4, r2                  // original instruction
    ldr   r0,[r1,#0xb4]           // monster pointer of user
    ldrh  r0,[r0,#0x2]            // species of user
    ldr   r1,=#1237
    cmp   r0,r1
    popne {pc}                    // if species != target, return to standard control flow
    mov   r1,#0x16
    bl    LoadScriptVariableValue // load CRYSTAL_COLOR_02
    cmp   r0,#10
    poplt {pc}                    // is less than 10 -> return to standard control flow
    // force function to return false
    pop   {r0}                    // just fixing the stack after we pushed lr at the start
    mov   r0,#0
    pop   {r4,r5,r6,r7,r8,pc}     // end function
    .pool
