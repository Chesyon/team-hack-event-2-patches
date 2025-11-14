.nds
.include "symbols.asm"

; This sucks. See force_learn_tm.s for why.
.open "overlay11.bin", overlay11_start
	.org UpdateTreasureBagHook1
	.area 0x4
		bl HijackTreasureBag1
	.endarea

	.org UpdateTreasureBagHook2
	.area 0x4
		bl HijackTreasureBag2
	.endarea

	.org UpdateTreasureBagHook3
	.area 0x4
		bl HijackTreasureBag3
	.endarea

	.org UpdateTreasureBagHook4
	.area 0x4
		bl HijackTreasureBag4
 	.endarea

	.org UpdateTreasureBagHook5
	.area 0x4
		bl HijackTreasureBag5
 	.endarea

	.org UpdateTreasureBagHook6
	.area 0x4
		bl HijackTreasureBag6
 	.endarea

	.org UpdateTreasureBagHook7
	.area 0x4
		bl HijackTreasureBag7
 	.endarea

	.org TreasureBagFrameUpdateHook
	.area 0x4
		bl HijackTreasureBag8
 	.endarea

	.org StupidBandaidFixHook
	.area 0x4
		bl StupidBandaidFix
 	.endarea
.close