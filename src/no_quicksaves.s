
HookQuickSave:
		stmdb r13!,{r0,r1,r2,r3}
		mov r0,#0
		mov r1,#78
		mov r2,#62
		bl LoadScriptVariableAtIndex
		cmp r0,#0
		ldmia r13!,{r0,r1,r2,r3}
		bne UNK_ANON_HOOK ; 0x0238897C
		ldr r0,[r1, #+0x8]
		b EndHookQuickSave
