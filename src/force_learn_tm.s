/* This entire approach is absolutely HORRENDOUS, do NOT do this.
I originally thought reusing the existing code for learning TMs would be easier than adding a custom menu.
I was wrong.
You have to navigate through the entire bag to get to the TM menu. You can't skip any steps or everything implodes.
I probably should have given up and written a script menu as soon as I realized this, but sunk cost fallacy got the better of me.
This pretty much just conditionally forces the treasure bag to navigate straight to using the first item in the bag, and selects the first party member to use a TM on.
It works! For the most part! But again, DO NOT DO THIS APPROACH, it's ridiculously janky.
At least I got some good notes out of it! A lot of this treasure bag stuff was previously undocumented.
*/

HijackTreasureBag1:
    push  {r0,lr}
    mov   r0,#58
    bl    GetPerformanceFlagWithChecks
    cmp   r0,#0
    pop   {r0}
    movne r0,#0 // if flag is enabled, instead simply return 0 for idx.
    bleq  IdfkWhatOverlayThisIs1
    pop   {pc}

HijackTreasureBag2:
    push  {r0,lr}
    mov   r0,#58
    bl    GetPerformanceFlagWithChecks
    cmp   r0,#0
    pop   {r0}
    movne r0,#0 // if flag is enabled, instead simply return 0 for idx.
    bleq  IdfkWhatOverlayThisIs2
    pop   {pc}

HijackTreasureBag3:
    push  {r0,lr}
    mov   r0,#58
    bl    GetPerformanceFlagWithChecks
    cmp   r0,#0
    pop   {r0}
    movne r0,#0 // if flag is enabled, treat as if menu was closed.
    bleq  IsParentMenuActive
    pop   {pc}

HijackTreasureBag4:
    push  {r0,lr}
    mov   r0,#58
    bl    GetPerformanceFlagWithChecks
    cmp   r0,#0
    pop   {r0}
    movne r0,#7 // if flag is enabled, treat as if use was selected
    bleq  GetSimpleMenuResult
    pop   {pc}

HijackTreasureBag5:
    push  {lr}
    mov   r0,#58
    bl    GetPerformanceFlagWithChecks
    cmp   r0,#0
    // if flag is enabled, treat it as if SomeTMFunc1 returned 1. we can skip calling the function, and we know r0 already holds 1 from GetPerformanceFlagWithChecks.
    bleq  SomeTMFunc1
    pop   {pc}

HijackTreasureBag6:
    push  {lr}
    mov   r0,#58
    bl    GetPerformanceFlagWithChecks
    cmp   r0,#0
    movne r0,#0 // if flag is enabled, treat as if party index 0 was selected
    bleq  SomeTMFunc2
    pop   {pc}

HijackTreasureBag7:
    push  {r0,lr}
    mov   r0,#58
    bl    GetPerformanceFlagWithChecks
    cmp   r0,#0
    movne r1,#0x10 // if flag is enabled, next state should be exit state
    moveq r1,#0x0  // otherwise next state should be vanilla (0)
    pop   {r0,pc}

HijackTreasureBag8:
    push  {lr}
    mov   r0,#58
    bl    GetPerformanceFlagWithChecks
    cmp   r0,#0
    bleq  InitTopGroundMenu
    popeq {pc}
    mov   r0,#0
    mov   r1,#78
    mov   r2,#58
    mov   r3,#0
    bl    SaveScriptVariableValueAtIndex
    pop   {pc}

StupidBandaidFix: // This shouldn't work. I hate that it does.
    push  {r0,lr}
    mov   r0,#58
    bl    GetPerformanceFlagWithChecks
    cmp   r0,#0
    pop   {r1}
    strne r0,[r1]
    mov   r0,r1
    bl    FunctionThatMakesMeAngry
    pop   {pc}