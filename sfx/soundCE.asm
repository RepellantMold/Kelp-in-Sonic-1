ring2_Header:
	sHeaderInit
	sHeaderPatch	ring2_Patches
	sHeaderTick	$01
	sHeaderCh	$01
	sHeaderSFX	$80, $05, ring2_FM4, $F4, $05

ring2_FM4:
	sPatFM		$00
	sPan		spLeft
	dc.b nG5, $05, nG6, $10
	sStop

ring2_Patches:

	; Patch $00
	; $06
	; $37, $72, $77, $49,	$1F, $1F, $1F, $1F
	; $07, $0A, $07, $0D,	$00, $00, $00, $00
	; $10, $07, $10, $07,	$23, $00, $23, $00
	spAlgorithm	$05
	spFeedback	$00
	spDetune	$03, $07, $07, $04
	spMultiple	$07, $07, $02, $09
	spRateScale	$00, $00, $00, $00
	spAttackRt	$1F, $1F, $1F, $1F
	spAmpMod	$00, $00, $00, $00
	spSustainRt	$07, $07, $0A, $0D
	spSustainLv	$01, $01, $00, $00
	spDecayRt	$00, $00, $00, $00
	spReleaseRt	$00, $00, $07, $07
	spTotalLv	$23, $23, $00, $00