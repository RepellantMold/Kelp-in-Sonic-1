;
;  DZ80 V3.4.1 Z80 Disassembly of z80nodata.bin
;  2007/09/18 15:48
;

;
;  Sonic 1 Z80 Driver disassembly by Puto.
;  Disassembly fixed, improved and integrated into SVN by Flamewing.
;  Should be assembled with AS (though it should be easily portable to other assemblers if necessary).
; ---Fuck that notice right there, going to use ASM68K with glory and many fasts. Made to work like magic by Natsumi---

	org	0				; z80 Align, handled by the build process
	include "sound/z80/LANG.ASM"		; include language macros
	z80prog 0				; also start a new z80 program

SEGAPCM =	$00E0				; give Sega PCM an arbitary value. Basically, just avoid getting optimized by Kosinski
SEGA_Pitch	equ 0Bh				; The pitch of the SEGA sound


z80_stack	equ 1FFCh
zDAC_Status	equ 1FFDh			; Bit 7 set if the driver is not accepting new samples, it is clear otherwise
zDAC_Sample	equ 1FFFh			; Sample to play, the 68K will move into this locatiton whatever sample that's supposed to be played.

zYM2612_A0	equ 4000h
zBankRegister	equ 6000h
zROMWindow	equ 8000h

Z80Driver_Start:
	di					; Disable interrupts. Interrupts will never be reenabled
	di					; for the z80, so that no code will be executed on V-Int.
	di					; This means that the sample loop is all the z80 does.
	ld	sp,z80_stack			; Initialize the stack pointer (unused throughout the driver)
	ld	ix,zYM2612_A0			; ix = Pointer to memory-mapped communication register with YM2612
	xor	a				; a=0
	ld	(zDAC_Status),a			; Disable DAC
	ld	(zDAC_Sample),a			; Clear sample
	;ld	a,SEGAPCM&$FF			; least significant bit from ROM bank ID
	;ld	(zBankRegister),a		; Latch it to bank register, initializing bank switch

	;ld	b,8				; Number of bits to latch to ROM bank
	;ld	a,SEGAPCM>>8			; Bank ID without the least significant bit

BankSwitchLoop:
	ld	(zBankRegister),a		; Latch another bit to bank register.
	rrca					; Move next bit into position
	djnz	BankSwitchLoop			; decrement and loop if not zero

	jr	CheckForSamples

; ===========================================================================
; JMan2050's DAC decode lookup table
; ===========================================================================
zDACDecodeTbl:
	db	   0,	 1,   2,   4,   8,  10h,  20h,  40h
	db	 80h,	-1,  -2,  -4,  -8, -10h, -20h, -40h

	if (*&$FF00)<>(zDACDecodeTbl&$FF00)
		inform 2,"zDACDecodeTbl was not properly aligned!"
	endif

CheckForSamples:
	ld	hl,zDAC_Sample			; Load the address of next sample.

WaitDACLoop:
	ld	a,(hl)				; a = next sample to play.
	zor	a				; Do we have a valid sample?
	jpp	WaitDACLoop			; Loop until we do

	zsub	81h				; Make 0-based index
	ld	(hl),a				; Store it back into sample index (i.e., mark it as being played)
	;cp	6				; Is the sample 87h or higher?
	;jrnc	Play_SegaPCM			; If yes, branch

	ld	de,0				; de = 0
	ld	iy,PCM_Table			; iy = pointer to PCM Table

	; Each entry on PCM table has 8 bytes in size, so multiply a by 8
	; Warning: do NOT play samples 84h-86h!
	sla	a
	sla	a
	sla	a
	ld	b,0				; b = 0
	ld	c,a				; c = a
	zadd	iy,bc				; iy = pointer to DAC sample entry
	ld	e,(iy+0)			; e = low byte of sample location
	ld	d,(iy+1)			; de = pointer location of DAC sample
	ld	c,(iy+2)			; c = low byte of sample size
	ld	b,(iy+3)			; bc = size of the DAC sample
	exx					; bc' = size of sample, de' = location of sample, hl' = pointer to zDAC_Sample
	ld	d,80h				; d = is an accumulator; this initializes it to 80h
	ld	hl,zDAC_Status			; hl = pointer to zDAC_Status
	ld	(hl),d				; Set flag to not accept driver input
	ld	(ix+0),2Bh			; Select enable/disable DAC register
	ld	e,2Ah				; Command to select DAC output register
	ld	c,(iy+4)			; c = pitch of the DAC sample
	ld	(ix+1),d			; Enable DAC
	ld	(hl),0				; Set flag to accept driver input
	; After the following exx, we have:
	; bc = size of sample, de = location of sample, hl = pointer to zDAC_Sample,
	; c' = pitch of sample, d' = PCM accumulator,
	; e' = command to select DAC output register, hl' = pointer to DAC status
	exx
	ld	h,(zDACDecodeTbl&0FF00h)>>8	; We set low byte of pointer below

PlayPCMLoop:
	ld	a,(de)				; a = byte from DAC sample
	zand	0F0h				; Get upper nibble
	; Shift-right 4 times to rotate the nibble into place
	rrca
	rrca
	rrca
	rrca
	zadd	a,zDACDecodeTbl&0FFh		; Add in low byte of offset into decode table
	ld	l,a				; hl = pointer to nibble entry in JMan2050 table
	ld	a,(hl)				; a = JMan2050 entry for current nibble
	; After the following exx, we have:
	; bc' = size of sample, de' = location of sample, hl' = pointer to nibble entry in JMan2050 table,
	; c = pitch of sample, d = PCM accumulator,
	; e = command to select DAC output register, hl = pointer to DAC status
	exx
	zadd	a,d				; Add accumulator value...
	ld	d,a				; ... then store value back into accumulator
	ld	(hl),l				; Set flag to not accept driver input (l = FFh)
	ld	(ix+0),e			; Select DAC output register
	ld	(ix+1),d			; Send current data
	ld	(hl),h				; Set flag to accept driver input (h = 1Fh)

	ld	b,c				; b = sample pitch
	djnz	*				; Pitch loop

	; After the following exx, we have:
	; bc = size of sample, de = location of sample, hl = pointer to nibble entry in JMan2050 table,
	; c' = pitch of sample, d' = PCM accumulator,
	; e' = command to select DAC output register, hl' = pointer to DAC status
	exx
	ld	a,(de)				; a = byte from DAC sample
	zand	0Fh				; Want only lower nibble now
	zadd	a,zDACDecodeTbl&0FFh		; Add in low byte of offset into decode table
	ld	l,a				; hl = pointer to nibble entry in JMan2050 table
	ld	a,(hl)				; a = JMan2050 entry for current nibble
	; After the following exx, we have:
	; bc' = size of sample, de' = location of sample, hl' = pointer to nibble entry in JMan2050 table,
	; c = pitch of sample, d = PCM accumulator,
	; e = command to select DAC output register, hl = pointer to DAC status
	exx
	zadd	a,d				; Add accumulator value...
	ld	d,a				; ... then store value back into accumulator
	ld	(hl),l				; Set flag to not accept driver input (l = FFh)
	ld	(ix+0),e			; Select DAC output register
	ld	(ix+1),d			; Send current data
	ld	(hl),h				; Set flag to accept driver input (h = 1Fh)

	ld	b,c				; b = sample pitch
	djnz	*				; Pitch loop

	; After the following exx, we have:
	; bc = size of sample, de = location of sample, hl = pointer to nibble entry in JMan2050 table,
	; c' = pitch of sample, d' = PCM accumulator,
	; e' = command to select DAC output register, hl' = pointer to DAC status
	exx
	ld	a,(zDAC_Sample)			; a = sample we're playing (minus 81h)
	bit	7,a				; Test bit 7 of register a
	jpnz	CheckForSamples		; If it is set, we need to get a new sample

	inc	de				; Point to next byte of DAC sample
	dec	bc				; Decrement remaining bytes on DAC sample
	ld	a,c				; a = low byte of remainig bytes
	zor	b				; Are there any bytes left?
	jpnz	PlayPCMLoop			; If yes, keep playing sample

	jp	CheckForSamples			; Sample is done; wait for new samples

;
; Table referencing the three PCM samples
;
; As documented by jman2050, first two bytes are a pointer to the sample, third and fourth are the sample size, fifth is the pitch, 6-8 are unused.
;

PCM_Table:
	dw	DAC_Sample1	; Kick sample
	dw	(DAC_Sample1_End-DAC_Sample1)
	dw	0017h		; Pitch = 17h
	dw	0000h

	dw	DAC_Sample2	; Snare sample
	dw	(DAC_Sample2_End-DAC_Sample2)
	dw	0001h		; Pitch = 1h
	dw	0000h

	dw	DAC_Sample3	; Timpani sample
	dw	(Dac_Sample3_End-DAC_Sample3)
Sample3_Pitch:
	dw	001Bh		; Pitch = 1Bh
	dw	0000h

DAC_Sample1:	incbin "sound/z80/DAC1.bin"
DAC_Sample1_End:

DAC_Sample2:	incbin "sound/z80/DAC2.bin"
DAC_Sample2_End:

DAC_Sample3:	incbin "sound/z80/DAC3.bin"
DAC_Sample3_End:

EndOfDriver:
	if *>z80_stack
		inform 2,"The sound driver, including samples, may at most be $\$z80_stack bytes, but is currently $\$* bytes in size."
	else
		inform 0,"Uncompressed driver size: $\$* bytes."
	endif

		inform 0,"The timpani pitch byte is %s or alternatively, in 68K notation, %h","Sample3_Pitch",Sample3_Pitch+$A00000
		inform 0,"Remember to set that in loc_71CAC."
	z80prog
	end

