; 
; ------------------------------------------------------------------------------
; By happylappy
; This move will instantly kill the user. However, it will also deal psychic
; type damage and confuse all enemies on the floor, as well as make the floor
; have a pink hue.
; ------------------------------------------------------------------------------


.relativeinclude on
.nds
.arm


.definelabel MaxSize, 0x2598
.definelabel MoveStartAddress, 0x02330134
.definelabel MoveJumpAddress, 0x023326CC
.definelabel LogMessageByIdWithPopup, 0x234B498
.definelabel GenerateItem, 0x023472C4
.definelabel InitItem, 0x0200CE9C
.definelabel GetMoneyCarried, 0x200ECFC
.definelabel SetMoneyCarried, 0x200ED1C
.definelabel AddItemToBagNoHeld, 0x0200F874
.definelabel InitPortraitDungeon, 0x234BAC0
.definelabel DisplayMessage2, 0x234D2AC

; Usable Variables: 
; r6 = Move ID
; r9 = User Monster Structure Pointer
; r4 = Target Monster Structure Pointer
; r8 = Move Data Structure Pointer (8 bytes: flags [4 bytes], move_id [2 bytes], pp_left [1 byte], boosts [1 byte])
; r7 = ID of the item that called this move (0 if the move effect isn't from an item)
; Returns: 
; r10 (bool) = ???
; Registers r4 to r9, r11 and r13 must remain unchanged after the execution of that code


; File creation
.create "./code_out.bin", 0x02330134 ; Change to the actual offset as this directive doesn't accept labels
    .org MoveStartAddress
    .area MaxSize ; Define the size of the area
        sub sp,sp,#0x8
        sub sp, #0x8;
        bl GetMoneyCarried
        cmp r0, #800;
        movle r0, #0;
        subgt r0, #800;
        bl SetMoneyCarried
        add r0, sp, #0x0
        mov r1, #105;
        mov r2, #0x0
        mov r3, #0x0
        bl GenerateItem
        mov r0, sp
        bl AddItemToBagNoHeld

        mov  r0,sp ; keep this one as-is
        ldr  r1,=#483 ; ID of the mon whose portrait should be displayed
        mov  r2,#14 ; ID of the portrait (eg. 1 is happy, 8 is teary eyed, 0 is neutral)
        bl   InitPortraitDungeon
        mov  r0,sp ; keep this one as-is
        mov  r1,#60 ; ID of the text string to display
        mov  r2,#0x1 ; uses message_Close() if true, message_CloseEnforce() if false
        bl   DisplayMessage2

        mov  r0, r9;
        mov  r1, #61 ; ID of the text string to display
        bl   LogMessageByIdWithPopup
        
        add sp, #0x8;
            b MoveJumpAddress
        .pool
    .endarea
.close