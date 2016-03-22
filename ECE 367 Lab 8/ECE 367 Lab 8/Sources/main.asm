; Bob Becker
; ECE 367 - Microprocessor-Based Design
; Experiment  - LCD Display
; November 18, 2006
; Modified March 13, 2008
; Modified for 9S12 Jan 8, 2011
; Modified for 9S12 Oct, 14, 2011
; Note this code requires only the use of Port M 
; SPI ports should be connected to SIPO IC as usual
; PIN USAGE
; MOSI to SER on SIPO
; SCK to SCK on SIPO
; PM0 to RS on LCD
; PM1 to Enable 0n LCD
; PM3 to RCK on SIPO
; Define symbolic constants
 
Regbase	EQU	$0000		; Register block starts at $0000  
PortT	EQU	$0240
DDRT	EQU	$0242
RS	EQU	$01		; Register Select (RS) at PM0 (0 = command, 1= Data) 
ENABLE	EQU	$02                           ; LCD ENABLE at PM1
RCK	EQU	$08		; RCK connect to PM3
PortM          EQU            $0250
DDRM	EQU	$0252		
SPCR1          EQU            $00D8
SPCR2 	EQU	$00D9
SPIB           EQU            $00DA
SPSR           EQU            $00DB
SPDR           EQU            $00DD
INITRG	EQU	$0011
INITRM	EQU	$0010
INITEE	EQU	$0012
CLKSEL	EQU	$39
PLLCTL	EQU	$3A
CRGFLG	EQU	$37
SYNR	EQU	$34
REFDV	EQU	$35
COUNT	EQU	$3800		; We need a variable
; Begin code
; Initialize the NanoCore12:


; The main code begins here. Note the START Label
;
	ORG	$4000		; Beginning of Flash EEPROM
START	LDS	#$3E00		; Top of the Stack
	SEI			; Turn Off Interrupts
        movb	#$00, INITRG	; I/O and Control Registers Start at $0000
	movb	#$39, INITRM	; RAM ends at $3FFF
;
; We Need To Set Up The PLL So that the E-Clock = 24MHz
;
	bclr CLKSEL,$80 ; disengage PLL from system
	bset PLLCTL,$40 ; turn on PLL
	movb #$2,SYNR   ; set PLL multiplier
	movb #$0,REFDV  ; set  PLL divider
	nop		; No OP
	nop		; NO OP
plp 	brclr CRGFLG,$08,plp ; while (!(crg.crgflg.bit.lock==1))
	bset CLKSEL,$80 ; engage PLL
	CLI		; Turn ON Interrupts	
;
;  OK! PLL is up and running at 24MHz	
;
;  SPI Setup
;

               LDAA #$22
	STAA SPIB		; SPI clocks a 1/24 of E-Clock
               MOVB #$3B, DDRM               ; Setup PortM data direction 
;
; Setup for Master, enable, and high speed SPI
;
	LDAA #$50
               STAA SPCR1
	LDAA #$00
	STAA SPCR2                    ; No need for this since SPRC2 = $00 at RESET
;
; Done with SPI Setup
;
;
; Better Setup Control Lines too
;
;
               BSET PortM, RCK               ; Set RCK to Idle HIGH
               BCLR PortM, ENABLE            ; ENABLE to Idle LOW
;
;
; Done with Control Lines


; Better set up the LCD too!
;
               JSR InitLCD  	               ; Initialize the LCD
;
; Done with all setup stuff
;
; Main Program Stuff Begins Here
;
Loop0	LDX #String1	               ; Load base address of String1
Loop1	LDAA 0,X		; Load a character into ACMA
	BEQ Done1		; quit when if last character is $00 
	JSR Print		; and output the character
	INX		; let's go get the next character
	BRA Loop1

Done1	LDAA #$C0		; First line is done jump to line 2
	JSR Command

	LDX #String2	               ; Load base address of String2
Loop2	LDAA 0,X		; etc., etc.
	BEQ Done2	
	JSR Print	
	INX	
	BRA Loop2
 
Done2	JSR delay2		; Let's display the message a while 
	MOVB #$04,COUNT               ; Initialize a counter
A4	LDAA #$08		; Turn off display but keep memory values
	JSR Command	
	JSR delay3
	LDAA #$0C		; Turn on display. So, we Blinked!
	JSR Command
	JSR delay3
	DEC COUNT
	BNE A4		; Blink 4 times
	LDAA #$01		; Clear the display and send cursor home
	JSR Command
	JSR delay		; Clear needs more time so 3 delays		
	JSR delay
	JSR delay
	LDX #String2	               ; Let's Print the Strings in reverse order
Loop3	LDAA 0,X		; There is a better way to do this with much less
	BEQ Done3		; code using subroutines. Right?
	JSR Print	
	INX 	
	BRA Loop3

Done3	LDAA #$C0
	JSR Command
                    
	LDX #String1
Loop4	LDAA 0,X
	BEQ Done4	
	JSR Print	
	INX 
	BRA Loop4

Done4          JSR delay2
	MOVB #$04,COUNT
A5	LDAA #$08		; Turn off display but keep memory values
	JSR Command	
	JSR delay3
	LDAA #$0C		; Turn on display. So, we Blinked!
	JSR Command
	JSR delay3
	DEC COUNT
	BNE A5
	MOVB #$04,COUNT
BA	LDAA #$1C		; Let's shift the display right 4 spaces
	JSR Command
	JSR delay		; This command needs more time
	JSR delay
	DEC COUNT
	BNE BA
	JSR delay2
	MOVB #$04,COUNT
BAA	LDAA #$18		; Let's shift the display left 4 spaces
	JSR Command
	JSR delay
	JSR delay
	DEC COUNT
	BNE BAA
	JSR delay2
	LDAA #$01		; Clear the display
	JSR Command
	JSR delay		; Clear needs more time
	JSR delay
	JSR delay

	JMP Loop0		; repeat all of the above

String1	FCC "ECE 367    "	; Create a String
	DC.B $00
String2	FCC "Fall 2012 "	; 
	DC.B $00

;
;Read the fine manual!
;

InitLCD	JSR delay3		
	LDAA #$30		; Could be $38 too.
	JSR Command
	JSR delay3		; need extra delay at startup
	LDAA #$30		; see data sheet. This is way
	JSR Command		; too much delay
	JSR delay3
	LDAA #$30
	JSR Command
	LDAA #$38		; Use 8 - words (command or data) and
	JSR Command		; and both lines of the LCD
	LDAA #$0C		; Turn on the display
	JSR Command
	LDAA #$01		; clear the display and put the cursor
	JSR Command		; in home position (DD RAM address 00)
	JSR delay		; clear command needs more time
	JSR delay		; to execute
	JSR delay
	RTS 
Command	
spi_a:	BRCLR SPSR,$20,spi_a 	; Wait for register empty flag (SPIEF)
	STAA SPDR		; Output command  via SPI to SIPO
CKFLG1         BRCLR SPSR,$80, CKFLG1        ; Wait for SPI Flag
	LDAA SPDR
               NOP                           ; Wait
               BCLR PortM, RCK               ; Pulse RCK
	NOP
	NOP
               BSET PortM, RCK               ; Command now available for LCD
	BCLR PortM, RS                ; RS = 0 for commands
	NOP
	NOP		; Probably do not need to wait
	NOP		; but we will, just in case ...
	BSET PortM, ENABLE	; Fire ENABLE
	NOP	               ; Maybe we will wait here too ...
	NOP
	BCLR PortM, ENABLE	; ENABLE off
	JSR delay
	RTS

Print	
spi_b:	BRCLR SPSR,$20,spi_b
 	STAA SPDR		; Output data via SPI to SIPO
CKFLG2         BRCLR SPSR, $80, CKFLG2       ; Wait for SPI Flag
	LDAA SPDR
               NOP                           ; Wait
               BCLR PortM, RCK               ; Pulse RCK
               NOP
	NOP
               BSET PortM, RCK               ; Data now available for LCD
               BSET PortM, RS	               ; RS = 1 for data
	NOP
	NOP
	BSET PortM, ENABLE
	NOP
	NOP
	BCLR PortM, ENABLE
	JSR delay
	RTS
;; The above two subroutines could be one! Only difference is RS value.
	
; Subroutine to delay the controller

delay
	LDY #8000	               ; Command Delay routine. Way to long. Overkill!
A2:	DEY		; But we do need to wait for the LCD controller
	BNE A2	               ; to do it's thing.  How much time is this
	RTS                           ; anyway?

delay2
	LDY #$F000	               ; Long Delay routine.  Adjust as needed. 
	PSHA		; Save ACMA (do we need to?)
A3:	LDAA #$8F                     ; Makes the delay even longer! (Nested loop.)
AB:	DECA
	BNE AB	               ; 
	DEY
	BNE A3	               ; 
	PULA		; Get ACMA back
	RTS

delay3         LDAA #$0F
AA6:	LDY #$FFFF	               ; Blink Delay routine. 
A6:	DEY		; 
	BNE A6
	DECA
	BNE AA6	               ; 
	RTS

; End of code
; Define Power-On Reset Interrupt Vector

	ORG $FFFE	               ; $FFFE, $FFFF = Power-On Reset Int. Vector Location
	FDB START	               ; Specify instruction to execute on power up