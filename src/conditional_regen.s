.align
// Probably could have hooked around 0x23110EC [NA], since that spot handles checks that would block regen anyways, but this works too so I'm just gonna leave it.
ConditionalRegen:
    push  {r0,r1,r2,lr}
    mov   r0,#59
    bl    GetPerformanceFlagWithChecks
    cmp   r0,#0
    pop   {r0,r1}
    addeq r1,r1,#1
    pop   {r2,pc}