;
;==================================================================================================
;   ROMWBW DEFAULT BUILD SETTINGS FOR RCBUS Z80
;==================================================================================================
;
; THIS FILE DEFINES THE DEFAULT CONFIGURATION SETTINGS FOR THE PLATFORM
; INDICATED ABOVE.  THESE SETTINGS DEFINE THE OFFICIAL BUILD FOR THIS
; PLATFORM AS DISTRIBUTED IN ROMWBW RELEASES.
;
; ROMWBW USES CASCADING CONFIGURATION FILES AS INDICATED BELOW:
;
; cfg_MASTER.asm			- MASTER: CONFIGURATION FILE DEFINES ALL POSSIBLE ROMWBW SETTINGS
; |
; +-> cfg_<platform>.asm		- PLATFORM: DEFAULT SETTINGS FOR SPECIFIC PLATFORM
;     |
;     +-> Config/<plt>_std.asm		- BUILD: SETTINGS FOR EACH OFFICIAL DIST BUILD
;         |
;         +-> Config/<plt>_<cust>.asm	- USER: CUSTOM USER BUILD SETTINGS
;
; THE TOP (MASTER CONFIGURATION) FILE DEFINES ALL POSSIBLE ROMWBW
; CONFIGURATION SETTINGS. EACH FILE BELOW THE MASTER CONFIGURATION FILE
; INHERITS THE CUMULATIVE SETTINGS OF THE FILES ABOVE IT AND MAY
; OVERRIDE THESE SETTINGS AS DESIRED.
;
; OTHER THAN THE TOP MASTER FILE, EACH FILE MUST "#INCLUDE" ITS PARENT
; FILE (SEE #INCLUDE STATEMENT BELOW).  THE TOP TWO FILES SHOULD NOT BE
; MODIFIED.
;
; TO CUSTOMIZE YOUR BUILD SETTINGS YOU SHOULD MODIFY THIS FILE, THE
; DEFAULT BUILD SETTINGS (Config/<platform>_std.asm) OR PREFERABLY
; CREATE AN OPTIONAL CUSTOM USER SETTINGS FILE THAT INCLUDES THE DEFAULT
; BUILD SETTINGS FILE (SEE EXAMPLE Config/SBC_user.asm).
;
; BY CREATING A CUSTOM USER SETTINGS FILE, YOU ARE LESS LIKELY TO BE
; IMPACTED BY FUTURE CHANGES BECAUSE YOU WILL BE INHERITING MOST
; OF YOUR SETTINGS WHICH WILL BE UPDATED BY AUTHORS AS ROMWBW EVOLVES.
;
; PLEASE REFER TO THE CUSTOM BUILD INSTRUCTIONS (README.TXT) IN THE
; SOURCE DIRECTORY (TWO DIRECTORIES ABOVE THIS ONE).
;
; *** WARNING: ASIDE FROM THE MASTER CONFIGURATION FILE, YOU MUST USE
; ".SET" TO OVERRIDE SETTINGS.  THE ASSEMBLER WILL ERROR IF YOU ATTEMPT
; TO USE ".EQU" BECAUSE IT WON'T LET YOU REDEFINE A SETTING WITH ".EQU".
;
#DEFINE	BOOT_DEFAULT	"H"		; DEFAULT BOOT LOADER CMD FOR EMPTY CMD LINE
#DEFINE AUTO_CMD	""		; AUTO CMD WHEN BOOT_TIMEOUT IS ENABLED
;
#INCLUDE "cfg_RCZ80.asm"
;
CPUOSC		.SET	7372800		; CPU OSC FREQ IN MHZ
;
FPLED_ENABLE	.SET	TRUE		; FP: ENABLES FRONT PANEL LEDS
FPSW_ENABLE	.SET	TRUE		; FP: ENABLES FRONT PANEL SWITCHES
CRTACT		.SET	FALSE		; ACTIVATE CRT (VDU,CVDU,PROPIO,ETC) AT STARTUP
VDAEMU_SERKBD	.SET	0		; VDA EMULATION: SERIAL KBD UNIT #, OR $FF FOR HW KBD
;
DSRTCENABLE	.SET	TRUE		; DSRTC: ENABLE DS-1302 CLOCK DRIVER (DSRTC.ASM)
RP5RTCENABLE	.SET	FALSE		; RP5C01 RTC BASED CLOCK (RP5RTC.ASM)
;
DUARTENABLE	.SET	FALSE		; DUART: ENABLE 2681/2692 SERIAL DRIVER (DUART.ASM)
UARTENABLE	.SET	TRUE		; UART: ENABLE 8250/16550-LIKE SERIAL DRIVER (UART.ASM)
ACIAENABLE	.SET	TRUE		; ACIA: ENABLE MOTOROLA 6850 ACIA DRIVER (ACIA.ASM)
SIOENABLE	.SET	TRUE		; SIO: ENABLE ZILOG SIO SERIAL DRIVER (SIO.ASM)
;
TMSENABLE	.SET	FALSE		; TMS: ENABLE TMS9918 VIDEO/KBD DRIVER (TMS.ASM)
TMSMODE		.SET	TMSMODE_MSX	; TMS: DRIVER MODE: TMSMODE_[SCG|N8|MSX|MSXKBD|MSXMKY|MBC|COLECO|DUO|NABU]
TMS80COLS	.SET	FALSE		; TMS: ENABLE 80 COLUMN SCREEN, REQUIRES V9958
TMSTIMENABLE	.SET	FALSE		; TMS: ENABLE TIMER INTERRUPTS (REQUIRES IM1)
VRCENABLE	.SET	FALSE		; VRC: ENABLE VGARC VIDEO/KBD DRIVER (VRC.ASM)
EFENABLE	.SET	FALSE		; EF: ENABLE EF9345 VIDEO DRIVER (EF.ASM)
;
FDENABLE	.SET	TRUE		; FD: ENABLE FLOPPY DISK DRIVER (FD.ASM)
FDMODE		.SET	FDMODE_RCWDC	; FD: DRIVER MODE: FDMODE_[DIO|ZETA|ZETA2|DIDE|N8|DIO3|RCSMC|RCWDC|DYNO|EPFDC|MBC]
;
IDEENABLE	.SET	TRUE		; IDE: ENABLE IDE DISK DRIVER (IDE.ASM)
;
PPIDEENABLE	.SET	TRUE		; PPIDE: ENABLE PARALLEL PORT IDE DISK DRIVER (PPIDE.ASM)
;
SDENABLE	.SET	TRUE		; SD: ENABLE SD CARD DISK DRIVER (SD.ASM)
SDMODE		.SET	SDMODE_PIO	; SD: DRIVER MODE: SDMODE_[JUHA|N8|CSIO|PPI|UART|DSD|MK4|SC|MT|USR|PIO|Z80R|EPITX|FZ80]
SDCNT		.SET	1		; SD: NUMBER OF SD CARD DEVICES (1-2), FOR DSD/SC/MT ONLY
;
PRPENABLE	.SET	FALSE		; PRP: ENABLE ECB PROPELLER IO BOARD DRIVER (PRP.ASM)
;
LPTENABLE	.SET	FALSE		; LPT: ENABLE CENTRONICS PRINTER DRIVER (LPT.ASM)
;
IMMENABLE	.SET	FALSE		; IMM: ENABLE IMM DISK DRIVER (IMM.ASM)
;
SN76489ENABLE	.SET	FALSE		; SN: ENABLE SN76489 SOUND DRIVER
;
AY38910ENABLE	.SET	FALSE		; AY: ENABLE AY-3-8910 / YM2149 SOUND DRIVER
AYMODE		.SET	AYMODE_RCZ80	; AY: DRIVER MODE: AYMODE_[SCG|N8|RCZ80|RCZ180|MSX|LINC|MBC|DUO|NABU]
AY_FORCE	.SET	FALSE		; AY: BYPASS AUTO-DETECT, FORCED PRESENT
