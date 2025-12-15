WhichToxicTable:
  push     {r14}
  push     {r0, r1, r2}
  mov      r0, #87
  bl       CheckDungeonId // found in larvesta_item_check.s
  cmp      r0, #1
  beq      WeAreInTheBeam
  cmp      r3, #0
  pop      {r0-r2}
  moveq    r2, #6
  movne    r1, #6
  pop    {r15}

WeAreInTheBeam:

  // r3 determines if we came from poison heal or poison damage

  cmp  r3, #0
  pop      {r0-r2}
  mov  r1, r6, lsl #1
  ldreqsh  r2, [r0, r1]
  ldrnesh  r1, [r0, r1]
  pop      {r15}
  
