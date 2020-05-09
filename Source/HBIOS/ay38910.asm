;======================================================================
;
;	AY-3-8910 / YM2149 SOUND DRIVER
;
;======================================================================
;
AY_RCSND	.EQU	0		; 0 = EB MODULE, 1=MF MODULE
;
#IF (AYMODE == AYMODE_SCG)
AY_RSEL		.EQU	$9A
AY_RDAT		.EQU	$9B
AY_RIN		.EQU	AY_RSEL
AY_ACR		.EQU	$9C
#ENDIF
;
#IF (AYMODE == AYMODE_N8)
AY_RSEL		.EQU	$9C
AY_RDAT		.EQU	$9D
AY_RIN		.EQU	AY_RSEL
AY_ACR		.EQU	N8_DEFACR
#ENDIF
;
#IF (AYMODE == AYMODE_RCZ80)	
AY_RSEL		.EQU	$D8
AY_RDAT		.EQU	$D0
AY_RIN		.EQU	AY_RSEL+AY_RCSND
#ENDIF
;
#IF (AYMODE == AYMODE_RCZ180)
AY_RSEL		.EQU	$68
AY_RDAT		.EQU	$60
AY_RIN		.EQU	AY_RSEL+AY_RCSND
#ENDIF
;
;======================================================================
;
;	REGISTERS
;
AY_R2CHBP	.EQU	$02
AY_R3CHBP	.EQU	$03
AY_R7ENAB	.EQU	$07
AY_R8AVOL	.EQU	$08
;
;======================================================================
;
;	DRIVER FUNCTION TABLE AND INSTANCE DATA
;
AY_FNTBL:
	.DW	AY_RESET
	.DW	AY_VOLUME
	.DW	AY_PERIOD
	.DW	AY_NOTE
	.DW	AY_PLAY
	.DW	AY_QUERY

#IF (($ - AY_FNTBL) != (SND_FNCNT * 2))
	.ECHO	"*** INVALID SND FUNCTION TABLE ***\n"
	!!!!!
#ENDIF
;
AY_IDAT	.EQU	0			; NO INSTANCE DATA ASSOCIATED WITH THIS DEVICE
;
;======================================================================
;
;	DEVICE CAPABILITIES AND CONFIGURATION
;
SBCV2004	.EQU	0		; USE SBC-V2-004 HALF CLOCK DIVIDER
;
AY_TONECNT	.EQU	3		; COUNT NUMBER OF TONE CHANNELS
AY_NOISECNT	.EQU	1		; COUNT NUMBER OF NOISE CHANNELS
;
AY_PHICLK	.EQU	3579545		; MSX NTSC COLOUR BURST FREQ = 315/88
;AY_PHICLK	.EQU	3500000		; ZX SPECTRUM 3.5MHZ
;AY_PHICLK	.EQU	4000000		; RETROBREW SCB-SCG 
AY_CLKDIV	.EQU	2
AY_CLK		.EQU	AY_PHICLK / AY_CLKDIV
AY_RATIO	.EQU	AY_CLK * 100 / 16
;
#INCLUDE "audio.inc"
;
;======================================================================
;
;	DRIVER INITIALIZATION (THERE IS NO PRE-INITIALIZATION)
;
;	ANNOUNCE DEVICE ON CONSOLE. ACTIVATE DEVICE IF REQUIRED.
;	SETUP FUNCTION TABLES. SETUP THE DEVICE.
;	ANNOUNCE DEVICE WITH BEEP. SET VOLUME OFF.
;	RETURN INITIALIZATION STATUS
;
AY38910_INIT:
	CALL	NEWLINE			; ANNOUNCE
	PRTS("AY: IO=0x$")
	LD	A,AY_RSEL
	CALL	PRTHEXBYTE
;
#IF ((AYMODE == AYMODE_SCG) | (AYMODE == AYMODE_N8))
	LD	A,$FF			; ACTIVATE DEVICEBIT 4 IS AY RESET CONTROL, BIT 3 IS ACTIVE LED
	OUT	(AY_ACR),A		; SET INIT AUX CONTROL REG
#ENDIF
;
	LD	DE,(AY_R2CHBP*256)+$55	; SIMPLE HARDWARE PROBE
	CALL	AY_WRTPSG		; WRITE AND 
	CALL	AY_RDPSG		; READ TO A
	LD	A,$55			; SOUND CHANNEL
	CP	E			; REGISTER
	JR	Z,AY_FND
;
	CALL	PRTSTRD \ .TEXT " NOT PRESENT$"
;
	LD	A,$FF			; UNSUCCESSFULL INIT		
	RET
;
AY_FND:	LD	IY, AY_IDAT		; SETUP FUNCTION TABLE
	LD	BC, AY_FNTBL		; POINTER TO INSTANCE DATA
	LD	DE, AY_IDAT		; BC := FUNCTION TABLE ADDRESS
	CALL	SND_ADDENT		; DE := INSTANCE DATA PTR
;
	CALL	AY_INIT			; SET DEFAULT CHIP CONFIGURATION
;
	LD	E,$07			; SET VOLUME TO 50%
	CALL	AY_SETV			; ON ALL CHANNELS
;
;	LD	DE,(AY_R2CHBP*256)+$55	; BEEP ON CHANNEL B (CENTER)
;	CALL	AY_WRTPSG		; R02 = $55 = 01010101
	LD	DE,(AY_R3CHBP*256)+$00
	CALL	AY_WRTPSG		; R03 = $00 = XXXX0000
;
	CALL	LDELAY			; HALF SECOND DELAY
;
	LD	E,$00			; SET VOLUME OFF
	CALL	AY_SETV			; ON ALL CHANNELS
;
	XOR	A			; SUCCESSFULL INIT
	RET
;
;======================================================================
;	INITIALIZE DEVICE
;======================================================================
;
AY_INIT:
	LD	DE,(AY_R7ENAB*256)+$F8	; SET MIXER CONTROL / IO ENABLE.  $F8 - 11 111 000
	CALL	AY_WRTPSG		; I/O PORTS = OUTPUT, NOISE CHANNEL C, B, A DISABLE, TONE CHANNEL C, B, A ENABLE
	RET
;
;======================================================================
;	SET VOLUME ALL CHANNELS
;======================================================================
;
AY_SETV:
	PUSH	BC
	LD	B,AY_TONECNT		; NUMBER OF CHANNELS
	LD	D,AY_R8AVOL		; BASE REGISTER FOR VOLUME
AY_SV:	CALL	AY_WRTPSG		; CYCLING THROUGH ALL CHANNELS
	INC	D
	DJNZ	AY_SV
	POP	BC
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - RESET
;
;	INITIALIZE DEVICE. SET VOLUME OFF. RESET VOLUME AND TONE VARIABLES.
;
;======================================================================
;
AY_RESET:
	AUDTRACE(AYT_INIT)
;
	PUSH	DE
	PUSH	HL
	CALL	AY_INIT			; SET DEFAULT CHIP CONFIGURATION
;
	AUDTRACE(AYT_VOLOFF)
	LD	E,0			; SET VOLUME OFF
	CALL	AY_SETV			; ON ALL CHANNELS
;
	XOR	A			; SIGNAL SUCCESS
	LD	(AY_PENDING_VOLUME),A	; SET VOLUME TO ZERO
	LD	H,A
	LD	L,A
	LD	(AY_PENDING_PERIOD),HL	; SET TONE PERIOD TO ZERO
;
	POP	HL
	POP	DE
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - VOLUME
;======================================================================
;
AY_VOLUME:
	AUDTRACE(AYT_VOL)
	AUDTRACE_L
	AUDTRACE_CR
	LD	A,L			; SAVE VOLUME
	LD	(AY_PENDING_VOLUME), A
;
	XOR	A			; SIGNAL SUCCESS
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - PERIOD
;======================================================================
;
AY_PERIOD:
	AUDTRACE(AYT_PERIOD)
	AUDTRACE_HL
	AUDTRACE_CR
;
	LD	A, H			; MAXIMUM TONE PERIOD IS 12-BITS
	AND	11110000B		; ALLOWED RANGE IS 0001-0FFF (4095)
	JR	NZ, AY_PERIOD1		; RETURN NZ IF NUMBER TOO LARGE
	LD	(AY_PENDING_PERIOD), HL	; SAVE AND RETURN SUCCESSFUL
	RET
;
AY_PERIOD1:
	LD	A, $FF			; REQUESTED PERIOD IS LARGER
	LD	(AY_PENDING_PERIOD), A	; THAN THE DEVICE CAN SUPPORT
	LD	(AY_PENDING_PERIOD+1), A; SO SET PERIOD TO FFFF
	RET				; AND RETURN FAILURE
;
;======================================================================
;	SOUND DRIVER FUNCTION - NOTE
;======================================================================
;
AY_NOTE:
	AUDTRACE(AYT_NOTE)
	AUDTRACE_L
	AUDTRACE_CR
;
	PUSH	HL
	PUSH	DE
	LD	H,0
	ADD	HL, HL			; SHIFT RIGHT (MULT 2) -INDEX INTO AY3NOTETBL TABLE OF WORDS
;					; TEST IF HL IS LARGER THAN AY3NOTETBL SIZE
;	OR	A			; CLEAR CARRY FLAG
	LD	DE, SIZ_AY3NOTETBL
;	SBC	HL, DE
;	JR	NC, AY_NOTE1		; INCOMING HL DOES NOT MAP INTO AY3NOTETBL
;
;	ADD	HL, DE			; RESTORE HL
	LD	DE, AY3NOTETBL		; HL = AY3NOTETBL + HL
	ADD	HL, DE
;
	LD	A, (HL)			; RETRIEVE PERIOD COUNT FROM AY3NOTETBL
	INC	HL
	LD	H, (HL)
	LD	L, A
;
	CALL	AY_PERIOD		; APPLY NOTE PERIOD
	POP	DE
	POP	HL
	RET
;
AY_NOTE1:
	POP	DE
	POP	HL
	OR	$FF			; NOT IMPLEMENTED YET
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - PLAY
;	B = FUNCTION
;	C = AUDIO DEVICE
;	D = CHANNEL
;	A = EXIT STATUS
;======================================================================
;
AY_PLAY:
	AUDTRACE(AYT_PLAY)
	AUDTRACE_D
	AUDTRACE_CR
;
	LD	A, (AY_PENDING_PERIOD + 1)	; CHECK THE HIGH BYTE OF THE PERIOD
	INC	A
	JR	Z, AY_PLAY1		; PERIOD IS TOO LARGE, UNABLE TO PLAY
;
	PUSH	HL			
	PUSH	DE
	LD	A,D			; LIMIT CHANNEL 0-2
	AND	$3			; AND INDEX TO THE
	ADD	A,A			; CHANNEL REGISTER
	LD	D,A			; FOR THE TONE PERIOD
;
	AUDTRACE(AYT_REGWR)
	AUDTRACE_A
	AUDTRACE_CR
;
	LD	HL,AY_PENDING_PERIOD	; WRITE THE LOWER
	ld	E,(HL)			; 8-BITS OF THE TONE PERIOD
	CALL	AY_WRTPSG
	INC	D			; NEXT REGISTER
	INC	HL			; NEXT BYTE
	LD	E,(HL)			; WRITE THE UPPER
	CALL	AY_WRTPSG       	; 8-BITS OF THE TONE PERIOD
;
	POP	DE			; RECALL CHANNEL
	PUSH	DE			; SAVE CHANNEL
;
	LD	A,D			; LIMIT CHANNEL 0-2
	AND	$3			; AND INDEX TO THE
	ADD	A,AY_R8AVOL		; CHANNEL VOLUME
	LD	D,A			; REGISTER
;
	AUDTRACE(AYT_REGWR)
	AUDTRACE_A
	AUDTRACE_CR
;
	INC	HL			; NEXT BYTE
	LD	A,(HL)			; PENDING VOLUME
	RRCA				; MAP THE VOLUME
	RRCA				; FROM 00-FF
	RRCA				; TO 00-0F
	RRCA
	AND	$0F
	LD	E,A
	CALL	AY_WRTPSG		; SET VOL (E) IN CHANNEL REG (D)
;
	POP	DE			; RECALL CHANNEL
	POP	HL
;
	XOR	A			; SIGNAL SUCCESS
	RET
;
AY_PLAY1:
	PUSH	DE			; TURN VOLUME OFF TO STOP PLAYING
	LD	A,D			; LIMIT CHANNEL 0-2
	AND	$3			; AND INDEX TO THE
	ADD	A,AY_R8AVOL		; CHANNEL VOLUME
	LD	D,A			; REGISTER
	LD	E,0
	CALL	AY_WRTPSG		; SET VOL (E) IN CHANNEL REG (D)
	POP	DE
	OR	$FF			; SIGNAL FAILURE
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - QUERY AND SUBFUNCTIONS
;======================================================================
;
AY_QUERY:
	LD	A, E
	CP	BF_SNDQ_CHCNT		; SUB FUNCTION 01
	JR	Z, AY_QUERY_CHCNT
;
	CP	BF_SNDQ_VOLUME		; SUB FUNCTION 02
	JR	Z, AY_QUERY_VOLUME
;
	CP	BF_SNDQ_PERIOD		; SUB FUNCTION 03
	JR	Z, AY_QUERY_PERIOD
;
	CP	BF_SNDQ_DEV		; SUB FUNCTION 04
	JR	Z, AY_QUERY_DEV
;
	OR	$FF			; SIGNAL FAILURE
	RET
;
AY_QUERY_CHCNT:
	LD	B, AY_TONECNT		; RETURN NUMBER OF
	LD	C, AY_NOISECNT		; TONE AND NOISE
	XOR	A			; CHANNELS IN BC
	RET
;
AY_QUERY_PERIOD:
	LD	HL, (AY_PENDING_PERIOD)	; RETURN 16-BIT PERIOD
	XOR	A			; IN HL REGISTER
	RET
;
AY_QUERY_VOLUME:
	LD	A, (AY_PENDING_VOLUME)	; RETURN 8-BIT VOLUME
	LD	L, A			; IN L REGISTER
	XOR	A
	LD	H, A
	RET
;
AY_QUERY_DEV:
	LD	B, BF_SND_AY38910		; RETURN DEVICE IDENTIFIER
	LD	DE, (AY_RSEL*256)+AY_RDAT	; AND ADDRESS AND DATA PORT
	XOR	A
	RET
;
;======================================================================
;
; 	WRITE DATA IN E REGISTER TO DEVICE REGISTER D
;	INTERRUPTS DISABLE DURING WRITE. WRITE IN SLOW MODE IF Z180 CPU.
;
;======================================================================
;
AY_WRTPSG:
	HB_DI
#IF (SBCV2004)
	LD	A,8			; SBC-V2-004 CHANGE
	OUT	(112),A			; TO HALF CLOCK SPEED
#ENDIF
#IF (CPUFAM == CPU_Z180)
	IN0	A,(Z180_DCNTL)		; GET WAIT STATES
	PUSH	AF			; SAVE VALUE
	OR	%00110000		; FORCE SLOW OPERATION (I/O W/S=3)
	OUT0	(Z180_DCNTL),A		; AND UPDATE DCNTL
#ENDIF
	LD	A,D			; SELECT THE REGISTER WE
	OUT	(AY_RSEL),A		; WANT TO WRITE TO
	LD	A,E			; WRITE THE VALUE TO
	OUT	(AY_RDAT),A		; THE SELECTED REGISTER
#IF (CPUFAM == CPU_Z180)
	POP	AF			; GET SAVED DCNTL VALUE
	OUT0	(Z180_DCNTL),A		; AND RESTORE IT
#ENDIF
#IF (SBCV2004)
	LD	A,0			; SBC-V2-004 CHANGE TO
	OUT	(112),A			; NORMAL CLOCK SPEED
#ENDIF
	HB_EI
	RET

;
;======================================================================
;
;	READ FROM REGISTER D AND RETURN WITH RESULT IN E
;
AY_RDPSG:
	HB_DI
#IF (SBCV2004)
	LD	A,8			; SBC-V2-004 CHANGE
	OUT	(112),A			; TO HALF CLOCK SPEED
#ENDIF
#IF (CPUFAM == CPU_Z180)
	IN0	A,(Z180_DCNTL)		; GET WAIT STATES
	PUSH	AF			; SAVE VALUE
	OR	%00110000		; FORCE SLOW OPERATION (I/O W/S=3)
	OUT0	(Z180_DCNTL),A		; AND UPDATE DCNTL
#ENDIF
	LD	A,D			; SELECT THE REGISTER WE
	OUT	(AY_RSEL),A		; WANT TO READ
	IN	A,(AY_RIN)		; READ SELECTED REGISTER
	LD	E,A
#IF (CPUFAM == CPU_Z180)
	POP	AF			; GET SAVED DCNTL VALUE
	OUT0	(Z180_DCNTL),A		; AND RESTORE IT
#ENDIF
#IF (SBCV2004)
	LD	A,0			; SBC-V2-004 CHANGE TO
	OUT	(112),A			; NORMAL CLOCK SPEED
#ENDIF
	HB_EI
	RET
;
;======================================================================
;
AY_PENDING_PERIOD	.DW	0	; PENDING PERIOD (12 BITS)	; ORDER
AY_PENDING_VOLUME	.DB	0	; PENDING VOL (8 BITS)		; SIGNIFICANT
;
#IF AUDIOTRACE
AYT_INIT		.DB	"\r\nAY_INIT\r\n$"
AYT_VOLOFF		.DB	"\r\nAY_VOLUME OFF\r\n$"
AYT_VOL			.DB	"\r\nAY_VOLUME: $"
AYT_NOTE		.DB	"\r\nAY_NOTE: $"
AYT_PERIOD		.DB	"\r\nAY_PERIOD $"
AYT_PLAY		.DB	"\r\nAY_PLAY CH: $"
AYT_REGWR		.DB	"\r\nOUT AY-3-8910 $"
#ENDIF
;
;======================================================================
;	BBC MICRO QUARTER TONE FREQUENCY TABLE 
;======================================================================
;
AY3NOTETBL:
	.DW	AY_RATIO / 5827		; A#1	INDEX 0 = A#1 AS PER BBC MANUAL
;	.DW	AY_RATIO / 5912
;	.DW	AY_RATIO / 5998
;	.DW	AY_RATIO / 6085
	.DW	AY_RATIO / 6174		; B1	INDEX 1 = B1 AS PER BBC MANUAL
	.DW	AY_RATIO / 6263
	.DW	AY_RATIO / 6354
	.DW	AY_RATIO / 6447
	.DW	AY_RATIO / 6541		; C2
	.DW	AY_RATIO / 6636
	.DW	AY_RATIO / 6732
	.DW	AY_RATIO / 6830
	.DW	AY_RATIO / 6930		; C#2
	.DW	AY_RATIO / 7030
	.DW	AY_RATIO / 7133
	.DW	AY_RATIO / 7236
	.DW	AY_RATIO / 7342		; D2
	.DW	AY_RATIO / 7448
	.DW	AY_RATIO / 7557
	.DW	AY_RATIO / 7667
	.DW	AY_RATIO / 7778		; D#2
	.DW	AY_RATIO / 7891
	.DW	AY_RATIO / 8006
	.DW	AY_RATIO / 8123
	.DW	AY_RATIO / 8241		; E2
	.DW	AY_RATIO / 8361
	.DW	AY_RATIO / 8482
	.DW	AY_RATIO / 8606
	.DW	AY_RATIO / 8731 	; F2
	.DW	AY_RATIO / 8858
	.DW	AY_RATIO / 8987
	.DW	AY_RATIO / 9117
	.DW	AY_RATIO / 9250		; F#2
	.DW	AY_RATIO / 9384
	.DW	AY_RATIO / 9521
	.DW	AY_RATIO / 9659
	.DW	AY_RATIO / 9800 	; G2
	.DW	AY_RATIO / 9942
	.DW	AY_RATIO / 10087
	.DW	AY_RATIO / 10234
	.DW	AY_RATIO / 10383	; G#2
	.DW	AY_RATIO / 10534
	.DW	AY_RATIO / 10687
	.DW	AY_RATIO / 10842
	.DW	AY_RATIO / 11000	; A2
	.DW	AY_RATIO / 11160
	.DW	AY_RATIO / 11322
	.DW	AY_RATIO / 11487
	.DW	AY_RATIO / 11654	; A#2
	.DW	AY_RATIO / 11824
	.DW	AY_RATIO / 11996
	.DW	AY_RATIO / 12170
	.DW	AY_RATIO / 12347	; B2
	.DW	AY_RATIO / 12527
	.DW	AY_RATIO / 12709
	.DW	AY_RATIO / 12894
	.DW	AY_RATIO / 13081	; C3
	.DW	AY_RATIO / 13272
	.DW	AY_RATIO / 13465
	.DW	AY_RATIO / 13660
	.DW	AY_RATIO / 13859	; C#3
	.DW	AY_RATIO / 14061
	.DW	AY_RATIO / 14265
	.DW	AY_RATIO / 14473
	.DW	AY_RATIO / 14683	; D3
	.DW	AY_RATIO / 14897
	.DW	AY_RATIO / 15113
	.DW	AY_RATIO / 15333
	.DW	AY_RATIO / 15556	; D#3
	.DW	AY_RATIO / 15783
	.DW	AY_RATIO / 16012
	.DW	AY_RATIO / 16245
	.DW	AY_RATIO / 16481	; E3
	.DW	AY_RATIO / 16721
	.DW	AY_RATIO / 16964
	.DW	AY_RATIO / 17211
	.DW	AY_RATIO / 17461	; F3
	.DW	AY_RATIO / 17715
	.DW	AY_RATIO / 17973
	.DW	AY_RATIO / 18234
	.DW	AY_RATIO / 18500	; F#3
	.DW	AY_RATIO / 18769
	.DW	AY_RATIO / 19042
	.DW	AY_RATIO / 19319
	.DW	AY_RATIO / 19600	; G3
	.DW	AY_RATIO / 19885
	.DW	AY_RATIO / 20174
	.DW	AY_RATIO / 20468
	.DW	AY_RATIO / 20765	; G#3
	.DW	AY_RATIO / 21067
	.DW	AY_RATIO / 21374
	.DW	AY_RATIO / 21685
	.DW	AY_RATIO / 22000	; A3
	.DW	AY_RATIO / 22320
	.DW	AY_RATIO / 22645
	.DW	AY_RATIO / 22974
	.DW	AY_RATIO / 23308	; A#3
	.DW	AY_RATIO / 23647
	.DW	AY_RATIO / 23991
	.DW	AY_RATIO / 24340
	.DW	AY_RATIO / 24694	; B3
	.DW	AY_RATIO / 25053
	.DW	AY_RATIO / 25418
	.DW	AY_RATIO / 25787
	.DW	AY_RATIO / 26163	; C4
	.DW	AY_RATIO / 26543
	.DW	AY_RATIO / 26929
	.DW	AY_RATIO / 27321
	.DW	AY_RATIO / 27718	; C#4
	.DW	AY_RATIO / 28121
	.DW	AY_RATIO / 28530
	.DW	AY_RATIO / 28945
	.DW	AY_RATIO / 29366	; D4
	.DW	AY_RATIO / 29794
	.DW	AY_RATIO / 30227
	.DW	AY_RATIO / 30667
	.DW	AY_RATIO / 31113	; D#4
	.DW	AY_RATIO / 31565
	.DW	AY_RATIO / 32024
	.DW	AY_RATIO / 32490
	.DW	AY_RATIO / 32963	; E4
	.DW	AY_RATIO / 33442
	.DW	AY_RATIO / 33929
	.DW	AY_RATIO / 34422
	.DW	AY_RATIO / 34923	; F4
	.DW	AY_RATIO / 35431
	.DW	AY_RATIO / 35946
	.DW	AY_RATIO / 36469
	.DW	AY_RATIO / 36999	; F#4
	.DW	AY_RATIO / 37538
	.DW	AY_RATIO / 38084
	.DW	AY_RATIO / 38638
	.DW	AY_RATIO / 39200	; G4
	.DW	AY_RATIO / 39770
	.DW	AY_RATIO / 40348
	.DW	AY_RATIO / 40935
	.DW	AY_RATIO / 41530	; G#4
	.DW	AY_RATIO / 42135
	.DW	AY_RATIO / 42747
	.DW	AY_RATIO / 43369
	.DW	AY_RATIO / 44000	; A4
	.DW	AY_RATIO / 44640
	.DW	AY_RATIO / 45289
	.DW	AY_RATIO / 45948
	.DW	AY_RATIO / 46616	; A#4
	.DW	AY_RATIO / 47294
	.DW	AY_RATIO / 47982
	.DW	AY_RATIO / 48680
	.DW	AY_RATIO / 49388	; B4
	.DW	AY_RATIO / 50107
	.DW	AY_RATIO / 50836
	.DW	AY_RATIO / 51575
	.DW	AY_RATIO / 52325	; C5
	.DW	AY_RATIO / 53086
	.DW	AY_RATIO / 53858
	.DW	AY_RATIO / 54642
	.DW	AY_RATIO / 55437	; C#5
	.DW	AY_RATIO / 56243
	.DW	AY_RATIO / 57061
	.DW	AY_RATIO / 57891
	.DW	AY_RATIO / 58733	; D5
	.DW	AY_RATIO / 59587
	.DW	AY_RATIO / 60454
	.DW	AY_RATIO / 61333
	.DW	AY_RATIO / 62225	; D#5
	.DW	AY_RATIO / 63130
	.DW	AY_RATIO / 64049
	.DW	AY_RATIO / 64980
	.DW	AY_RATIO / 65926	; E5
	.DW	AY_RATIO / 66884
	.DW	AY_RATIO / 67857
	.DW	AY_RATIO / 68844
	.DW	AY_RATIO / 69846	; F5
	.DW	AY_RATIO / 70862
	.DW	AY_RATIO / 71892
	.DW	AY_RATIO / 72938
	.DW	AY_RATIO / 73999	; F#5
	.DW	AY_RATIO / 75075
	.DW	AY_RATIO / 76167
	.DW	AY_RATIO / 77275
	.DW	AY_RATIO / 78399	; G5
	.DW	AY_RATIO / 79539
	.DW	AY_RATIO / 80696
	.DW	AY_RATIO / 81870
	.DW	AY_RATIO / 83061	; G#5
	.DW	AY_RATIO / 84269
	.DW	AY_RATIO / 85495
	.DW	AY_RATIO / 86738
	.DW	AY_RATIO / 88000	; # A5
	.DW	AY_RATIO / 89280
	.DW	AY_RATIO / 90579
	.DW	AY_RATIO / 91896
	.DW	AY_RATIO / 93233	; A#5
	.DW	AY_RATIO / 94589
	.DW	AY_RATIO / 95965
	.DW	AY_RATIO / 97361
	.DW	AY_RATIO / 98777	; B5
	.DW	AY_RATIO / 100213
	.DW	AY_RATIO / 101671
	.DW	AY_RATIO / 103150
	.DW	AY_RATIO / 104650	; C6
	.DW	AY_RATIO / 106172
	.DW	AY_RATIO / 107717
	.DW	AY_RATIO / 109283
	.DW	AY_RATIO / 110873	; C#6
	.DW	AY_RATIO / 112486
	.DW	AY_RATIO / 114122
	.DW	AY_RATIO / 115782
	.DW	AY_RATIO / 117466	; D6
	.DW	AY_RATIO / 119174
	.DW	AY_RATIO / 120908
	.DW	AY_RATIO / 122667
	.DW	AY_RATIO / 124451	; D#6
	.DW	AY_RATIO / 126261
	.DW	AY_RATIO / 128097
	.DW	AY_RATIO / 129961
	.DW	AY_RATIO / 131851	; E6
	.DW	AY_RATIO / 133769
	.DW	AY_RATIO / 135715
	.DW	AY_RATIO / 137689
	.DW	AY_RATIO / 139691	; F6
	.DW	AY_RATIO / 141723
	.DW	AY_RATIO / 143785
	.DW	AY_RATIO / 145876
	.DW	AY_RATIO / 147998	; F#6
	.DW	AY_RATIO / 150150
	.DW	AY_RATIO / 152334
	.DW	AY_RATIO / 154550
	.DW	AY_RATIO / 156798	; G6
	.DW	AY_RATIO / 159079
	.DW	AY_RATIO / 161393
	.DW	AY_RATIO / 163740
	.DW	AY_RATIO / 166122	; G#6
	.DW	AY_RATIO / 168538
	.DW	AY_RATIO / 170990
	.DW	AY_RATIO / 173477
	.DW	AY_RATIO / 176000	; A6
	.DW	AY_RATIO / 178560
	.DW	AY_RATIO / 181157
	.DW	AY_RATIO / 183792
	.DW	AY_RATIO / 186466	; A#6
	.DW	AY_RATIO / 189178
	.DW	AY_RATIO / 191929
	.DW	AY_RATIO / 194721
	.DW	AY_RATIO / 197553	; B6
	.DW	AY_RATIO / 200427
	.DW	AY_RATIO / 203342
	.DW	AY_RATIO / 206300
	.DW	AY_RATIO / 209300	; C7
	.DW	AY_RATIO / 212345
	.DW	AY_RATIO / 215433
	.DW	AY_RATIO / 218567
	.DW	AY_RATIO / 221746	; C#7
	.DW	AY_RATIO / 224971
	.DW	AY_RATIO / 228244
	.DW	AY_RATIO / 231564
	.DW	AY_RATIO / 234932	; D7
	.DW	AY_RATIO / 238349
	.DW	AY_RATIO / 241816

SIZ_AY3NOTETBL	.EQU	$ - AY3NOTETBL
		.ECHO	"AY-3-8910 approx "
		.ECHO	SIZ_AY3NOTETBL / 2 / 4 / 12
		.ECHO	" Octaves.  Last note index supported: "

		.ECHO SIZ_AY3NOTETBL / 2
		.ECHO "\n"
