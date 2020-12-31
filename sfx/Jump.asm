Jump_Header:
	sHeaderInit
	sHeaderPatch	Jump_Patches
	sHeaderTick	$01
	sHeaderCh	$01
	sHeaderSFX	$80, $80, Jump_PSG1, $00+7, $00

Jump_PSG1:
	sVolEnvPSG	v08
	dc.b nF2, $05
	ssMod68k	$02, $01, $F8, $65
	dc.b nBb2, $0A
	sStop

Jump_Patches:
