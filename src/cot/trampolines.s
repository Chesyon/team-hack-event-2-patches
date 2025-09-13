.align 4
cotInternalTrampolineScriptSpecialProcessCall:
  // If the special process ID is >= 100, handle it as a custom special process
  cmp r1, #100
  bge cotInternalDispatchScriptSpecialProcessCall

  // Otherwise, restore the instruction we've replaced in the patch
  // and run the original function
  push	{r3, r4, r5, r6, r7, r8, r9, sl, fp, lr}
  b ScriptSpecialProcessCall+4

.align 4
cotInternalTrampolineApplyItemEffect:
  // Backup registers
  push {r0-r9, r11, r12}

  // Call the hook function
  mov r0, r8
  mov r1, r7
  mov r2, r6
  mov r3, r9
  bl cotInternalDispatchApplyItemEffect
  // Check if true was returned
  cmp r0, #1

  // Load saved registers
  popeq {r0-r9, r11, r12}

  // If yes, exit the original function
  beq ApplyItemEffectJumpAddr

  pop {r0-r9, r11, r12}

  // Restore the instruction that was replaced with the patch and call the original function
  cmp r0, #0
  b ApplyItemEffectHookAddr+4

// Custom trampoline by Marius for compatibility with ExtractMoveEffects. Ported to NA by Chesyon, so please ask him first if anything breaks!
.align 4
cotInternalTrampolineApplyMoveEffectExtracted:
  // register backup
  push {r0-r9, r11, r12}

  // TODO: check that move effect struct later

  ldr r10, =move_effect_input
  str r6, [r10] // move effect

  // unsure about item id...

  mov r0, #0
  str r0, [r10, #0x8] // out_dealt_damage



  // call the hook function
  mov r0, r10
  // attacker is r9
  // move is r8
  mov r1, r9 // attacker (I think)
  mov r2, r4 // defenser (I think)
  mov r3, r8 // move (I think)
  bl cotInternalDispatchApplyMoveEffect

  cmp r0, #1
  pop {r0-r9, r11, r12}

  // Not 100% sure r10 is the good output
  ldreq r10, =move_effect_input_out_dealt_damage
  beq ApplyMoveEffectHookAddrExtractedOnSuccess
  
  // the original replaced function
  stmdb  r13!,{r5,r7,r8}
  b ApplyMoveEffectHookAddrExtracted+4

.align 4
move_effect_input:
  .word 0
  .word 0
move_effect_input_out_dealt_damage:
  .word 0
