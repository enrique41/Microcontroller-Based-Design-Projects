; University of Illinois at Chicago, Dept. of Electrical and Computer Engineering
; ECE 367 -Microprocessor-Based Design
; Semester: Spring 2013

; Experiment Title: Count Up/Down Timer Using The SPI Subsystem and LCD Display
; Experiment Description: This system is a timer that is capable of starting and 
;                         pausing operation, as well as reversing the count direction.
;                         It will count from 00 to 99 or 99 to 00 and when it reaches 00
;                         again, it will blink 3 times and then reset the system.  You 
;                         can enter number values on the keypad at any time to change the
;                         timing values.  All data displayed on LCD.                      
; Date: 3/15/2013
; Updated: 3/18/2013
; Version: 1
; Programmer: Mitchell Hedditch
; Lab Session: Tuesday 8AM-10:50AM 
                       

; Define symbolic constants 
REGBAS         EQU $0000                     ; REGISTER BLOCK STARTS AT $0000
PortA          EQU $0000                     ; PortA address (relative to Regbase i.e. offset)
DDRA           EQU $0002                     ; PortA Data Direction control register offset
PortM          EQU $0250                     ; PortM offset (actual address of PortM)
DDRM           EQU $0252                     ; PortM Data Direction control register offset
PortT          EQU $0240                     ; PortT offset (actual address of PortT)
DDRT           EQU $0242                     ; Actual Data Direction Register for PortT
PortE          EQU $0008                     ; PortE LABEL (XIRQ' INTERRUPT)
; TIMER SYMBOLIC CONSTANTS
TSCR1	EQU $0046                     ; TIMER SYSTEM CONTROL REGISTER - WITH FAST FLAGS
TSCR2	EQU $004D                     ; TIMER SYSTEM CONTROL REGISTER 2 - NO FAST FLAGS
TFLG1	EQU $004E                     ; TIMER INTERRUPT FLAG1 REGISTER
TFLG2          EQU $004F                     ; TIMER INTERRUPT FLAG2 REGISTER
TIOS	EQU $0040                     ; TIMER INTERRUPT OUTPUT COMPARE
TCNT	EQU $0044                     ; TIMER COUNTER REGISTER - 16 BIT, INPUT CAPTURE/OUTPUT COMPARE REQUIRED
TC0	EQU $0050                     ; TIME I/O COMPARE SELECT 0 REGISTER TO LOCATION $50 HEX
TC1	EQU $0052                     ; TIME I/O COMPARE SELECT 1 REGISTER TO LOCATION $52 HEX
TIE            EQU $004C                     ; TIMER TCi INTERRUPT ENABLE REGISTER
; INTERRUPT CONSTANTS
IRQCR          EQU $001E                     ; IRQ CONTROL REGISTER ADDRESS LABEL
; SERIAL COMMUNICATION INTERFACE
SPCR1          EQU $00D8
SPCR2          EQU $00D9
SPIB           EQU $00DA
SPSR           EQU $00DB
SPDR           EQU $00DD                     
ENABLE	EQU $02                       ; LCD ENABLE at PM1
RCK	EQU $08		; RCK connect to PM3
;UNKNOWN
INITRG         EQU $0011
INITRM         EQU $0010
PLLCTL	EQU $003A
; CLOCKS
CLKSEL	EQU $0039
CRGFLG	EQU $0037
SYNR	EQU $0034
REFDV	EQU $0035
COPCTL	EQU $003C                     ; COMPUTER OPERATING PROPERLY CONTROL LOCATION

TEST           EQU $3800                     ; DEFINE LOCATION FOR TEST BYTE STORAGE FOR DEBUGGING
SAVE_X         EQU $3802                     ; Defines location for the storage of the X index register
SAVE_Y         EQU $3804                     ; Defines location for the storage of the Y index register
DIR_FLAG       EQU $3806                     ; DEFINES LOCATION FOR STORAGE OF COUNTER DIRECTION FLAG
                                             ; FOR INTERRUPTS FLAG = 0->COUNT UP; 1->COUNT DOWN
PAUSE          EQU $3808                     ; DEFINES LOCATION FOR STORAGE OF START/PAUSE FLAG
                                             ; FLAG = 0->PAUSE; 1->COUNT
TMR_FLAG       EQU $3810                     ; DEFINES LOCATION FOR STORAGE OF TIMER FLAG
                                             ; FLAG= 0->NOTHING; 1->TIMER FIRED
INVALID_KEY    EQU $3812                     ; DEFINES LOCATION FOR STORAGE OF TIMER FLAG 2
                                             ; FLAG= 0->NOTHING; 1->TIMER FIRED
TIME_COUNT     EQU $3814                     ; MEM ADDRESS TO STORE TIME FOR SECONDS
XIRQ_FLAG      EQU $3816                     ; PAUSE FOR XIRQ (1 MSEC)
NUM_FLAG       EQU $3818                     ; A FLAG THAT GOES TO 1 IF A KEY IS PRESSED ON THE PAD
CUR_PAD_VAL    EQU $3820                     ; USED TO HOUSE THE VALUE FOR THE CURRENT KEYPAD ITERATION
COUNT_VAL      EQU $3822                     ; STORE THE COUNT VALUE HERE
CUR_COLUMN     EQU $3824                     ; STORAGE LOCATION FOR VARIABLE OF CURRENT COLUMN
RS        	EQU $01        	; REGISTER SELECT (RS) AT PM0 (0=COMMAND, 1=DATA)

;******************************************************************************************
; The ORG statment below is followed by variable definitions
; THIS IS THE BEGINNING SETUP CODE
;
	ORG	$3800	; Beginning of RAM for Variables
;
; The main code begins here. Note the START Label
;
	ORG	$4000	; Beginning of Flash EEPROM
START          LDS	#$3FC0	; Top of the Stack
	SEI		; Turn Off Interrupts
               MOVB	#$00, INITRG	; I/O and Control Registers Start at $0000
	MOVB	#$39, INITRM	; RAM ends at $3FFF
;
; We Need To Set Up The PLL So that the E-Clock = 24MHz
;
	BCLR CLKSEL,$80               ; disengage PLL from system
	BSET PLLCTL,$40               ; turn on PLL
	MOVB #$2,SYNR                 ; set PLL multiplier
	MOVB #$0,REFDV                ; set  PLL divider
	NOP		; No OP
	NOP		; NO OP
PLP 	BRCLR CRGFLG,$08,PLP          ; while (!(crg.crgflg.bit.lock==1))
	BSET CLKSEL,$80               ; engage PLL

	CLI		; TURN ON ALL INTERRUPTS
;
; End of  setup code. You will always need the above setup code for every experiment


;*****************************************************************************************
; Begin Code
;*****************************************************************************************
; Initialize the 68HC11

               LDY  #REGBAS                  ; Initialize register base address
                                             ; Note that Regbas = $0000 so now <Y> = $0000
               SEI                           ; TURN OFF INTERRUPTS
                                                           
; INITIALIZE ALL SYSTEM PORTS/INTERRUPTS/DDRS/FLAGS/ETC
               ; SETUP S BIT ON INTERRUPTS
               MOVB #$C0, IRQCR              ; TURN ON IRQ' INTERRUPT AND SET TO EDGE TRIGGERED
               ANDCC #$BF                    ; SET THE X-BIT TO USE XIRQ' AS A STANDARD INTERRUPT
        
               JSR INIT                      ; INITIALIZE ALL OF OUR VARIABLES, FLAGS, ETC.
               JSR InitLCD                   ; INITIALIZE THE LCD
               
               ; ALL VARIABLES ARE INITIALIZED SO WE'RE READY FOR INTERRUPTS
               CLI                           ; TURN ON INTERRUPTS
;***********************************
;
;      MAIN PROGRAM CODE IS HERE
;
;***********************************
               JSR DIRECTIONS                ; SHOW THE USER THE DIRECTIONS
               JSR DRAW_SCREEN               ; DRAW FIRST SCREEN FOR THE FIRST TIME
POLL:          MOVB #$00,INVALID_KEY         ; RESET INVALID KEY FLAG
               MOVB #$00,NUM_FLAG            ; CLEAR THE NUM FLAG TO WAIT FOR A NEW KEY
               JSR GET_KEY                   ; CHECK THE KEYPAD FOR A PRESSED VALUE
               BRCLR NUM_FLAG,$01,NO_KEY     ; IF NO KEY HAS BEEN PRESSED THEN MOVE ON THE THE NO_KEY LINE
               JSR BSPACE                    ; GO TO THE BSPACE SUB TO SEE IF USER PRESSED 'C'
               JSR CHECK_KEY                 ; CHECK TO SEE IF THE KEY IS VALID
               BRSET INVALID_KEY,$01,POLL    ; GO BACK AND POLL AGAIN IF WE'VE GOT A BAD KEY
               JSR LOAD_NUMBER               ; IF A NUMBER KEY HAS BEEN PRESSED THEN LOAD THE NEW NUMBER
               MOVB #$00,NUM_FLAG            ; CLEAR THE NUM FLAG TO WAIT FOR A NEW KEY
NO_KEY         BRSET PAUSE,$01,POLL          ; WAIT AT POLL WHILE THE IRQ' (PAUSE) INTERRUPT FLAG IS SET
               BRCLR PortE,$01,*             ; BRANCH HERE UNTIL THE XIRQ PORT IS HIGH AGAIN
               BRCLR TMR_FLAG,$01,POLL       ; IF THE TIME FLAG ISN'T SET BRANCH BACK TO POLL
               BRSET DIR_FLAG,$01,CDOWN      ; IF THE DIRECTION FLAG IS SET, THEN COUNT DOWN
               JSR COUNT_UP                  ; INCREMENT THE COUNT VALUE
               BRA UPDATE_DISP               ; BRANCE TO CONTINUE
CDOWN          JSR COUNT_DOWN                ; DECREMENT THE COUNT VALUE
UPDATE_DISP    JSR DRAW_SCREEN               ; LET'S UPDATE THE SCREEN AGAIN                                                           
               MOVB #$00,TMR_FLAG            ; CLEAR THE TIMER FLAG
               LDD COUNT_VAL                 ; LOAD THE COUNT VALUE INTO D
               CPD #$00                      ; CHECK TO SEE IF WE'RE AT ZERO
               BNE CONTINUE                  ; IF WE'RE NOT AT ZERO THEN CONTINUE
               JSR BLINK                     ; BLINK 3 TIMES IF WE'RE AT ZERO
               JSR INIT                      ; RESTART OUR SYSTEM AND REINITIATE ALL FLAGS/VALS
CONTINUE       JSR DRAW_SCREEN               ; LET'S UPDATE THE SCREEN JUST IN CASE                                                             
               BRA POLL                      ; GO BACK START PROCESSING AT POLL AGAIN!
;**********************************************************************************************
; PROGRAM INITIALIZATION
INIT:          ; SETUP THE DATA DIRECTON REGISTERS AND INITIALIZE PORT A & PORT T
               MOVB #$F0,DDRT                ; SET PortT PINS 4-7 TO OUTBOUND AND PINS 0-3 TO INBOUND
               MOVB #$00,PortT               ; SET ALL PortT PINS TO LOW
               
               ; SET UP SERIAL PROGRAM INTERFACE SYSTEM
               MOVB #$22,SPIB                ; SPI CLOCKS A 1/24 OF E-CLOCK
               MOVB #$3B,DDRM                ; SETUP PortM DATA DIRECTION
               MOVB #$50,SPCR1               ; ENABLE SPI AND SET MODE AS MASTER
               MOVB #$00,SPCR2               ; RESETS SPCR2 TO $00 (ALSO DOES AT RESET)
               BSET PortM,RCK                ; SET RCK TO IDLE HIGH
               BCLR PortM, ENABLE            ; ENABLE to Idle LOW
               
               ; SET UP TIMER COUNT INFORMATION AND PRESCALE INITIALIZE THE COUNTER
               MOVB #$06,TSCR2               ; CONFIGURE PRESCALE FACTOR 64
               MOVB #$01,TIOS                ; ENABLE OC0 FOR OUTPUT COMPARE
               MOVB #$90,TSCR1               ; ENABLE TCNT & FAST FLAGS CLEAR
               MOVB #$01,TIE                 ; ENABLE TC1 INTERRUPT
               LDD TCNT                      ; FIRST GET CURRENT TCNT
               ADDD #3750                    ; INCREMENT TCNT COUNT BY 3750 AND STORE INTO TC0
               STD TC0                       ; WE WILL HAVE A SUCCESSFUL COMPARE IN 375 CLICKS
               MOVB #$01,TFLG1               ; OF TCNT. BETTER BE SURE FLAG C0F IS CLEAR TO START
               
               ; INITIALIZE PROGRAM DEFINED VARIABLES
               MOVB #$01,PAUSE               ; INITIALIZE IN THE SYSTEM IN PAUSE MODE
               MOVB #$00,DIR_FLAG            ; INITIALIZE THE SYSTEM IN COUNT UP MODE
               MOVB #$00,TMR_FLAG            ; INITIALIZE THE TIMER FLAG TO LOW
               LDD #$0000                    ; INITIALIZE THE COUNT TO 0
               STD COUNT_VAL                 ; STORE THE COUNT VALUE OF D TO MEMORY
               MOVB #$00,TIME_COUNT          ; SET TIME_COUNT TO 0
               MOVB #$00,NUM_FLAG            ; SET NUM_FLAG TO 0 TO
               MOVB #$00,INVALID_KEY         ; RESET INVALID KEY FLAG
               
               ;SET UP INTRO TEXT TO LCD AND PAUSE HERE
               JSR DRAW_SCREEN               ; DURING RESTART, WE'LL NEED TO REDRAW SCREEN                                                             
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************               
; PURPOSE: TO RETRIEVE A PRESSED KEY FROM A MATRIX KEYBOARD, IF THIS ACTION HAPPENS, SET A FLAG
InitLCD:	JSR delay3		; WE NEED A SHORT DELAY HERE
	
	BCLR PortM,RS                 ; SEND A COMMAND
               LDAA #$30		; Could be $38 too, 2 LINES AND 5X7 MATRIX
	JSR LCD_INPUT                 ; OUTPUT CLEAR TO SIPO SERIALLY
               JSR delay3		; need extra delay at startup
	LDAA #$30		; Could be $38 too, 2 LINES AND 5X7 MATRIX
	JSR LCD_INPUT                 ; OUTPUT CLEAR TO SIPO SERIALLY
               JSR delay3                    ; WE NEED A SHORT DELAY HERE
	LDAA #$30                     ; Could be $38 too, 2 LINES AND 5X7 MATRIX
	JSR LCD_INPUT                 ; OUTPUT CLEAR TO SIPO SERIALLY
               JSR delay3
	
               LDAA #$38		; Use 8 - words (command or data) and
	JSR LCD_INPUT                 ; OUTPUT CLEAR TO SIPO SERIALLY
               JSR delay3                    ; NEED SHORT DELAY TO WAIT FOR COMMAND TO COMPLETE
	
               LDAA #$0C		; Turn on the display
	JSR LCD_INPUT                 ; OUTPUT CLEAR TO SIPO SERIALLY
               JSR delay3                    ; NEED SHORT DELAY TO WAIT FOR COMMAND TO COMPLETE
	
               LDAA #$01		; clear the display and put the cursor
	JSR LCD_INPUT                 ; OUTPUT CLEAR TO SIPO SERIALLY
               JSR delay		; clear command needs more time
	JSR delay		; to execute
	JSR delay                     ; NEED SHORT DELAY TO WAIT FOR COMMAND TO COMPLETE
	RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; PURPOSE: LOAD A BIT INTO THE LCD (RS = 0 for commands OR RS = 1 FOR PRINT)
LCD_INPUT:	
SPI_EF:	     BRCLR SPSR,$20,SPI_EF    	; WAIT FOR REGISTER EMPTY FLAG (SPIEF)
	          STAA SPDR		               ; OUTPUT COMMAND VIA SPI TO SIPO
CKFLG1         BRCLR SPSR,$80,CKFLG1         ; WAIT FOR SPI FLAG
	          LDAA SPDR                     ; LOAD FROM SPI TO CLEAR FLAG
               NOP                           ; WAIT
               BCLR PortM, RCK               ; PULSE RCK
	          NOP                           ; WAIT
	          NOP                           ; WAIT
               BSET PortM, RCK               ; COMMAND NOW AVAILABEL FOR LCD
	          NOP                           ; WAIT
	          NOP		                    ; PROBABLY DON'T NEED TO WAIT
	          NOP		                    ; BUT WE WILL, JUST IN CASE...
	          BSET PortM, ENABLE	          ; FIRE ENABLE
	          NOP	                         ; WE SHOULD WAIT AGAIN
	          NOP                           ; UNTIL IT'S FINISHED
	          BCLR PortM, ENABLE	          ; ENABLE OFF
	          JSR delay                     ; GIVE THE LCD TIME TO TAKE COMMAND IN
	          RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; PURPOSE: TO RETRIEVE A PRESSED KEY FROM A MATRIX KEYBOARD, IF THIS ACTION HAPPENS, SET A FLAG
;          AND STORE THE VALUE
GET_KEY:       LDX #KP_VALUE                 ; LOAD X WITH MEM ADDRESS FOR KP_VALUE                 
               STX CUR_PAD_VAL               ; STORE THE ADDRESS OF THE FIRST KEYPAD VALUE 
               LDX #ROW                      ; LOAD X WITH THE INITIAL VALUE AT THE ROW ADDRESS
               LDY #COLUMN                   ; LOAD Y WITH THE INITIAL VALUE AT THE COLUMN ADDRESS
               ; NOW WE BEGIN OUR LOOPING
NEXT_ROW       LDAA 1,X+                     ; LOAD ACCUM A WITH CURRENT ROW VALUE POST INCREMENT
NEXT_COLUMN    LDAB 1,Y+                     ; LOAD ACCUM Y WITH CURRENT COLUMN VALUE POST INCREMENT
               STAA PortT                    ; SET THE CURRENT ROW TO HIGH VALUE
               STAB CUR_COLUMN               ; STORE THE CURRENT COLUMN VALUE
               PSHA                          ; PUSH ONTO THE STACK OR IT WILL BE LOST
               PSHB                          ; PUSH B ONTO THE STACK OR IT WILL BE LOST
               NOP                           ; WAIT SOME TIME FOR PIN TO GO HI
               NOP                           ; WAIT SOME TIME FOR PIN TO GO HI
               NOP                           ; WAIT SOME TIME FOR PIN TO GO HI
               ABA                           ; ADD B TO A TO GET ALL PINS THAT SHOULD BE HIGH
               LDAB PortT                    ; LOAD THE VALUE IN PortT INTO ACCUM B
               CBA                           ; CHECK THE CURRENT BIT IN PortT TO OUR CURRENT COLUMN
               BEQ KEY_PRESSED               ; IF THE KEY IS PRESSED THEN MAKE IT SO!
               LDD CUR_PAD_VAL               ; LOAD THE CUR_PAD_VAL INTO D
               ADDD #1                       ; ADD 1 TO D
               STD CUR_PAD_VAL               ; STORE D BACK INTO THE PAD VALUE
               PULB                          ; GET B BACK FROM THE STACK FIRST
               PULA                          ; NOW RESTORE A FROM THE STACK
               CPY #COLUMN+4                 ; CHECK TO SEE IF WE'RE AT THE END OF THE COLUMNS
               BNE NEXT_COLUMN               ; IF NOT, THEN GO BACK AND TRY NEXT COLUMN
               LDY #COLUMN                   ; IF WE ARE THEN RESET THE COLUMNS
               CPX #ROW+4                    ; CHECK TO SEE IF WE'RE AT THE END OF THE ROWS
               BNE NEXT_ROW                  ; IF WE'RE NOT AT END OF ROWS, GO TO NEXT ROW
               RTS                           ; RETURN FROM THE SUBROUTINE IF WE'VE PROCESS ALL ROWS AND COLUMNS
KEY_PRESSED    PULB                          ; GET B BACK FROM THE STACK FIRST
               PULA                          ; NOW RESTORE A FROM THE STACK
               MOVB #$01,NUM_FLAG            ; SET NUM_FLAG SINCE A NUMBER WAS PRESSED
               JSR KEY_RELEASE               ; NOW WE NEED TO WAIT UNTIL THE KEYS ARE RELEASED                             
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; PURPOSE: WAIT UNTIL A PRESSED KEY IS RELEASED TO ELIMINATE BOUNCE AND DOUBLE PRESSING
KEY_RELEASE:   MOVB #$F0,PortT               ; SET ROWS 4,5,6,7 OF PortT TO HIGH
               NOP                           ; SHORT TIME WAITING FOR PINS TO GO HIGH
               BRCLR PortT,$0F,FINISH        ; WHEN COLUMN 1-4 (PM0-PM3) IS CLEAR THEN ALL KEYS
                                             ; HAVE BEEN RELEASED
               BRA KEY_RELEASE               ; BRANCH BACK TO KEY RELEASE
FINISH         RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; PURPOSE: TO CHECK AND MAKE SURE WE HAVE A VALID KEY PRESSED
CHECK_KEY:     LDX CUR_PAD_VAL               ; GET THE CURRENT KEYPAD VALUE ADDRESS
               LDAA X                        ; LOAD THE KEYPAD VALUE ADDRESS
               CMPA #$09                     ; WAS THIS KEY AN INVALID KEY?
               BGT INVALID                   ; IF IT WAS THEN SET THE FLAG
               RTS                           ; IF NOT RETURN FROM SUBROUTINE
INVALID        MOVB #$01,INVALID_KEY         ; SET THE INVALID KEY FLAG               
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; PURPOSE: THIS SUBROUTINE IS USED TO LOAD A NEW DIGIT INTO THE LCD AND THE COUNT VALUE
LOAD_NUMBER:   JSR PREP_VALS                 ; LETS LET THE PREP_VALS SUB SPLIT THE NUMBER
               TFR Y,X                       ; TRANSFER THE ONES VALUE INTO THE X INDEX
               LDD #$000A                    ; LOAD D WITH DECIMAL 10
               EMUL                          ; MULTIPLY THE TENS VALUE BY 10 AND PLACE IN D
               STD COUNT_VAL                 ; STORE OUR TENS VALUE INTO COUNT_VAL
               LDY CUR_PAD_VAL               ; LOAD THE EFFECTIVE ADDRESS INTO Y (NEW VALUE)
               LDAA #$00                     ; CLEAR A OUT BY WRITING ZEROS TO IT
               LDAB Y                        ; LOAD B WITH THE ADDRESS IN Y
               ADDD COUNT_VAL                ; ADD OUR KEYPAD VALUE TO THE TENS VALUE
               STD COUNT_VAL                 ; STORE THE NEW VALUE INTO COUNT_VAL
               JSR DRAW_SCREEN               ; MAKE SURE WE REDRAW THE SCREEN NOW
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; NOTE: DO NOT CHANGE THIS SUBROUTINE UNLESS YOU MODIFY LOAD_NUMBER!!
; PURPOSE: TAKE THE VALUE IN COUNT_VAL AND PARSE ITS ONES AND TENS DIGIT INTO THE X AND Y INDEX
;          FOR USE IN THE DISPLAYS
PREP_VALS:     LDD COUNT_VAL                 ; LOAD THE COUNT VALUE INTO D
               CPD #$000A                    ; COMPARE X TO 10
               LBLO UNDR_TEN                 ; IF IT'S LESS THEN 10 MAKE IT ZERO
               LDX #0010                     ; PLACE TEN IN D
               IDIV                          ; DIVIDE OUR NUMBER BY 10
               TFR D,Y                       ; TRANSFER THE REMAINDER INTO Y
               RTS                           ; RETURN FROM SUBROUTINE
UNDR_TEN       LDX 0                         ; LOAD ZERO INTO X
               TFR D,Y                       ; WE LEAVE Y AS IT IS               
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
BSPACE:        LDX CUR_PAD_VAL               ; GET THE KEY PRESSED VALUE ADDRESS
               LDAA X                        ; LOAD THE KEY VALUE
               CMPA #$0C                     ; WAS THIS KEY A 'C'?
               BNE NO_BSPC                   ; IF IT WAS THEN SET THE FLAG
               
               LDD COUNT_VAL                 ; LOAD THE COUNT VALUE INTO D
               CPD #$000A                    ; COMPARE X TO 10
               LBLO UNDR_TEN2                ; IF IT'S LESS THEN 10 MAKE IT ZERO
               LDX #0010                     ; PLACE TEN IN D
               IDIV                          ; DIVIDE OUR NUMBER BY 10
               BRA ST_CT                     ; GO TO STORE THE COUNT ST_CT
UNDR_TEN2      LDX 0                         ; LOAD ZERO INTO X
ST_CT          STX COUNT_VAL                 ; STORE OUR NEW COUNT VALUE
               
               BCLR PortM,RS                 ; SEND A COMMAND TO LCD
               LDAA #$10                     ; SEND BACKSPACE CHARACTER TO DISPLAY
               JSR LCD_INPUT                 ; OUTPUT CLEAR TO SIPO SERIALLY
               BSET PortM,RS                 ; SEND A COMMAND TO LCD
               LDAA #$20                     ; SEND BACKSPACE CHARACTER TO DISPLAY
               JSR LCD_INPUT                 ; OUTPUT CLEAR TO SIPO SERIALLY
               BCLR PortM,RS                 ; SEND A COMMAND TO LCD
               LDAA #$10                     ; SEND BACKSPACE CHARACTER TO DISPLAY
               JSR LCD_INPUT                 ; OUTPUT CLEAR TO SIPO SERIALLY
NO_BSPC        RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; PURPOSE: PRINT A STRING TO THE LCD (USES LCD_INPUT)
PRINT_STRING: 
Loop1	LDAA 0,X		; LOAD A CHARACTER INTO ACMA
	BEQ Done1		; QUIT IF WE REACH A $00
	JSR LCD_INPUT		; AND OUTPUT THE CHARACTER
	INX		; GO TO NEXT CHARACTER
	BRA Loop1                     ; PROCESS NEXT CHARACTER
Done1          RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
DRAW_SCREEN:   BCLR PortM, RS                ; SEND A COMMAND TO LCD
               LDAA #$01                     ; CLEAR SCREEN COMMAND
               JSR LCD_INPUT                 ; SEND TO LCD
               LDAA #$02                     ; RETURN TO HOME COMMAND
               JSR LCD_INPUT                 ; SEND COMMAND
               
               ; CHECK WHETHER SYSTEM IS PAUSED OR NOT
               BSET PortM, RS                ; LET'S PRINT TO LCD
               
               BRCLR PAUSE,$01,RUN           ; WAIT AT POLL WHILE THE IRQ' (PAUSE) INTERRUPT FLAG IS SET
               LDX #STRING1                  ; IF WE'RE IN PAUSE MODE PRINT 'PAUSED'
               BRA DIR                       ; GO TO DIR TO PRINT VALUE
RUN            LDX #STRING2                  ; IF WE'RE RUNNING PRINT 'RUN'
DIR            JSR PRINT_STRING              ; GO TO PRINT_STRING SUB 
               ; CHECK WHETHER WE'RE COUTNING UP OR DOWN
               BRSET DIR_FLAG,$01,DOWN       ; IF THE DIRECTION FLAG IS SET, THEN COUNT DOWN
               LDX #STRING3                  ; IF WE'RE COUTING UP PRINT 'UP'
               BRA PCOUNT                    ; GO TO PCOUNT TO PRINT
DOWN           LDX #STRING4                  ; IF WE'RE COUTING DOWN PRINT 'DOWN'
PCOUNT         JSR PRINT_STRING              ; GO TO PRINT_STRING SUB TO PPRINT
               
               BCLR PortM, RS                ; SENT A COMMAND TO LCD
               LDAA #$C0                     ; GO TO SECOND LINE TO PRINT
               JSR LCD_INPUT                 ; SEND COMMAND
               
               ; PRINT THE CURRENT COUNT
               BSET PortM, RS                ; LET'S PRINT TO LCD
               LDX #STRING5                  ; PRINT 'COUNT'
               JSR PRINT_STRING              ; LET'S PRINT THE STRING NOW
               
               JSR UPDATE_TENS_DISPLAY       ; PRINT 10'S VALUE
               JSR UPDATE_ONES_DISPLAY       ; PRINT 1'S VALUE
               
               BCLR PortM, RS                ; SEND A COMMAND TO LCD
               LDAA #$0E                     ; LCD DISPLAY ON, CURSOR BLINKING
               JSR LCD_INPUT                 ; PRINT COMMAND TO LCD
               
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
DIRECTIONS:    BCLR PortM, RS                ; SEND A COMMAND TO LCD
               LDAA #$01                     ; CLEAR SCREEN COMMAND
               JSR LCD_INPUT                 ; SEND TO LCD
               LDAA #$02                     ; RETURN TO HOME COMMAND
               JSR LCD_INPUT                 ; SEND COMMAND
               BSET PortM, RS                ; LET'S PRINT TO LCD
               LDX #STRING6                  ; IF WE'RE IN PAUSE MODE PRINT 'PAUSED'
               JSR PRINT_STRING              ; GO TO PRINT_STRING SUB 
               BCLR PortM, RS                ; SENT A COMMAND TO LCD
               LDAA #$C0                     ; GO TO SECOND LINE TO PRINT
               JSR LCD_INPUT                 ; SEND COMMAND
               BSET PortM, RS                ; LET'S PRINT TO LCD
               LDX #STRING7                  ; IF WE'RE COUTING DOWN PRINT 'DOWN'
               JSR PRINT_STRING              ; GO TO PRINT_STRING SUB TO PPRINT
               JSR delay2                    ; DELAY A BIT
               JSR delay2                    ; DELAY A BIT
               
               BCLR PortM, RS                ; SEND A COMMAND TO LCD
               LDAA #$01                     ; CLEAR SCREEN COMMAND
               JSR LCD_INPUT                 ; SEND TO LCD
               LDAA #$02                     ; RETURN TO HOME COMMAND
               JSR LCD_INPUT                 ; SEND COMMAND
               BSET PortM, RS                ; LET'S PRINT TO LCD
               LDX #STRING8                  ; IF WE'RE IN PAUSE MODE PRINT 'PAUSED'
               JSR PRINT_STRING              ; GO TO PRINT_STRING SUB 
               BCLR PortM, RS                ; SENT A COMMAND TO LCD
               LDAA #$C0                     ; GO TO SECOND LINE TO PRINT
               JSR LCD_INPUT                 ; SEND COMMAND
               BSET PortM, RS                ; LET'S PRINT TO LCD
               LDX #STRING9                  ; IF WE'RE COUTING DOWN PRINT 'DOWN'
               JSR PRINT_STRING              ; GO TO PRINT_STRING SUB TO PPRINT
               JSR delay2                    ; DELAY A BIT
               JSR delay2                    ; DELAY A BIT
               
               BCLR PortM, RS                ; SEND A COMMAND TO LCD
               LDAA #$01                     ; CLEAR SCREEN COMMAND
               JSR LCD_INPUT                 ; SEND TO LCD
               LDAA #$02                     ; RETURN TO HOME COMMAND
               JSR LCD_INPUT                 ; SEND COMMAND
               BSET PortM, RS                ; LET'S PRINT TO LCD
               LDX #STRING10                  ; IF WE'RE IN PAUSE MODE PRINT 'PAUSED'
               JSR PRINT_STRING              ; GO TO PRINT_STRING SUB 
               BCLR PortM, RS                ; SENT A COMMAND TO LCD
               LDAA #$C0                     ; GO TO SECOND LINE TO PRINT
               JSR LCD_INPUT                 ; SEND COMMAND
               BSET PortM, RS                ; LET'S PRINT TO LCD
               LDX #STRING11                  ; IF WE'RE COUTING DOWN PRINT 'DOWN'
               JSR PRINT_STRING              ; GO TO PRINT_STRING SUB TO PPRINT
               JSR delay2                    ; DELAY A BIT
               JSR delay2                    ; DELAY A BIT
               
               RTS                           ; RETURN FROM SUBROUTINE               
;**********************************************************************************************
; PURPOSE: TAKE THE VALUE IN THE X INDEX AND DISPLAY IT IN THE TENS LCD
UPDATE_TENS_DISPLAY:
               JSR PREP_VALS                 ; PREPARE OUR COUNT VALUE FOR OUTPUT
               TFR X,B                       ; MOVE X INTO B
               LDX #ASCII                    ; LOAD THE BEGINNING ADDRESS OF TABLE INTO X
               ABX                           ; ADD B TO THE X INDEX
               LDAA X                        ; LOAD THE ADDRESS OF INDEX X INTO ACCUM A
               BSET PortM, RS                ; PRINT CHARACTER TO LCD
               JSR LCD_INPUT                 ; SEND CHARACTER TO LCD
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; PURPOSE: TAKE THE VALUE IN THE Y INDEX AND DISPLAY IT IN THE ONES LCD
UPDATE_ONES_DISPLAY:
               JSR PREP_VALS                 ; PREPARE OUR COUNT VALUE FOR OUTPUT
               TFR Y,B                       ; MOVE Y INTO B SO WE CAN USE Y
               LDY #ASCII                    ; LOAD THE BEGINNING ADDRESS OF TABLE INTO Y
               ABY                           ; ADD B TO THE Y INDEX
               LDAA Y                        ; LOAD THE ADDRESS OF INDEX Y INTO ACCUM A
               BSET PortM, RS                ; PRINT CHARACTER TO LCD
               JSR LCD_INPUT                 ; SEND CHARACTER TO LCD
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; PURPOSE INCREMENT THE VALUE OF COUNT_VAL UNTIL WE REACH 99, THEN RESET TO 00
COUNT_UP:      
               LDY COUNT_VAL                 ; LOAD THE COUNT VALUE INTO Y
               INY                           ; INCREMENT THE NUMBER BY 1
               CPY #100                      ; COMPARE IT TO 100
               BEQ U_RESET                   ; IF WE'RE ATT 100, THEN RESET THE NUMBER
               STY COUNT_VAL                 ; STORE THE COUNT VALUE BACK INTO Y
               RTS                           ; RETURN FROM SUBROUTINE
U_RESET        LDY 0                         ; RESET Y TO 0
               STY COUNT_VAL                 ; STORE THE COUNT VALUE BACK INTO Y               
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; PURPOSE: DECREMENT THE VALUE OF COUNT_VAL UNTIL WE REACH 0, THEN RESET TO 99
COUNT_DOWN:
               LDY COUNT_VAL                 ; LOAD THE COUNT VALUE INTO Y
               CPY #0                        ; COMPARE IT TO 0
               BEQ D_RESET                   ; IF WE'RE AT ZERO, THEN RESET IT
               DEY                           ; DECREMENT THE NUMBER BY Y
               STY COUNT_VAL                 ; STORE THE COUNT VALUE BACK INTO Y
               RTS                           ; RETURN FROM SUBROUTINE
D_RESET        LDY 99                        ; RESET Y TO 0
               STY COUNT_VAL                 ; STORE THE COUNT VALUE BACK INTO Y               
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
BLINK:         LDY #0                        ; SET Y TO ZERO
BLINKING       PSHY                          ; PUSH Y ONTO THE STACK
               BCLR PortM, RS                ; SEND A COMMAND TO LCD
               
               LDAA #$08                     ; TURN LCD OFF COMMAND
               JSR LCD_INPUT                 ; SEND COMMAND TO LCD
               BRCLR TMR_FLAG,$01,*          ; WAIT A SECOND HERE
               MOVB #$00,TMR_FLAG            ; CLEAR THE TIMER FLAG
               
               LDAA #$0C                     ; DISPLAY ON COMMAND
               JSR LCD_INPUT                 ; SEND COMMAND TO LCD
               BRCLR TMR_FLAG,$01,*          ; WAIT A SECOND HERE
               MOVB #$00,TMR_FLAG            ; CLEAR THE TIMER FLAG
               
               PULY                          ; PULL Y OFF STACK
               INY                           ; INCREMENT Y
               CPY #3                        ; SEE IF WE'VE BLINKED 3 TIMES
               BNE BLINKING                  ; IF NOT THEN BLINK AGAIN!
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
delay          LDY #8000	               ; COMMAND DELAY ROUTINE.  WAY TO LONG. OVERKILL!
A2:	DEY		; BUT WE DO NEED TO WAIT FOR THE LCD CONTROLLER
	BNE A2	               ; TO DO IT'S THING.  HOW MUCH TIME?
	RTS                           ; RETURN FROM SUBROUTINE

delay2         LDY #$F000	               ; LONG DELAY ROUTINE.  ADJUST AS NEEDED.
	PSHA		; SAVE ACMA
A3:	LDAA #$8F                     ; LONG DELAY LOAD ACMA WITH 8F (NESTED LOOP)
AB:	DECA                          ; DECREMENT A
	BNE AB	               ; BRANCH TO AB IF NOT EQUAL
	DEY                           ; DECREMENT Y
	BNE A3	               ; BRANCH TO A3 IF NOT EQUAL
	PULA		; GET ACMA BACK
	RTS                           ; RETURN FROM SUBROUTINE

delay3         LDAA #$0F                     ; LOAD 15 (F) INTO ACMA
AA6:	LDY #$FFFF	               ; LOAD Y WITH FFFF (Blink Delay routine.)
A6:	DEY		; DECREMENT Y
	BNE A6                        ; BRANCH TO A6 IF NOT EQUAL
	DECA                          ; DECREMENT A
	BNE AA6	               ; BRANCH TO AA6 IF NOT EQUAL
	RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; TC0 INTERRUPT SUBROUTINE
ISR_TC0:       LDD TC0                       ; INTERRUPT READS THE FLAG SO THIS WRITE CLEARS THE FLAG
               ADDD #3750                    ; ADD THE EQUIVALENT .1 SECOND CNT TO REGISTER D
               STD TC0                       ; UPDATE TC0 MEMORY TO NEW VALUE
               BRSET PAUSE,$01,PAUSED        ; IF PAUSED DON'T UPDATE TIME_COUNT!!
               PSHA                          ; SAVE A ON THE STACK
               LDAA TIME_COUNT               ; LOAD THE VALUE OF TIME_COUNT INTO A
               CMPA #100                     ; IF TIME_COUNT = 100 THEN WE HAVE 1 SECOND
               BNE TMR_UPDATE                ; IF WE'RE NOT AT 100 YET, GOTO TMR_UPDATE LINE
               MOVB #$01,TMR_FLAG            ; TURN ON OUR TIMER FLAG
               MOVB #$00,TIME_COUNT          ; RESET OUR TIMER COUNT BACK TO ZERO
               PULA                          ; PUL A BACK OFF THE STACK
PAUSED         RTI                           ; RETURN FROM THE INTERRUPT
TMR_UPDATE     ADDA #01                      ; INCREMENT THE VALUE IN A
               STAA TIME_COUNT               ; STORE A BACK INTO TIME_COUNT
               PULA                          ; PULL A BACK OFF THE STACK
               RTI                           ; RETURN FROM THE INTERRUPT
;****************************************************************************************
; IRQ' INTERRUPT SUBROUTINE
ISR_IRQ:       COM PAUSE                     ; TOGGLE THE START/PAUSE FLAG 
               JSR DRAW_SCREEN
               RTI                           ; RETURN FROM INTERRUPT
;****************************************************************************************
; XIRQ' INTERRUPT SUBROUTINE
ISR_XIRQ:      COM DIR_FLAG                  ; TOGGLE THE DIRECTION FLAG
               JSR DRAW_SCREEN
               RTI                           ; RETURN FROM INTERRUPT
;******************************************************************************************
               ORG $FFF2                     ; IRQ' VECTOR ADDRESS
               FDB ISR_IRQ                   ; ISR_IRQ IS A LABEL FOR THE INTERRUPT SUBROUTINE

               ORG $FFF4                     ; XIRQ' VECTOR ADDRESS
               FDB ISR_XIRQ                  ; ISR_XIRQ' IS A LABEL FOR THE INTERRUPT SUBROUTINE                                                                                  

               ORG $FFEE                     ; VECTOR ADDRESS FOR TC0 INTERRUPT
               FDB ISR_TC0                   ; ISR_TIMER IS A LABEL FOR THE INTERRUPT SUBROUTINE                                                                                  
;*****************************************************************************************
; Have the Assembler put the solution data in the look-up table

               ORG $5500                     ; The look-up table is at $5500

TABLE:         DC.B $00, $01, $02, $03, $04  ; Define data table of mappings to each of the 
               DC.B $05, $06, $07, $08, $09  ; matrix keypad values.
               DC.B $0A, $0B, $0C, $0D, $0E  ; Memory locations correspond to their values
               DC.B $0F                      ; i.e. $5500 = 0, $5501 = 1, etc
               
ASCII:         DC.B $30, $31, $32, $33, $34  ; Define data table of mappings to each of the 
               DC.B $35, $36, $37, $38, $39  ; ascii values for the keypad
               DC.B $41, $42, $43, $44, $45  ; Memory locations correspond to their values
               DC.B $46                      ; i.e. $5500 = 0, $5501 = 1, etc              
                                             
ROW:           DC.B $10, $20, $40, $80       ; PortT OUTPUT VALUES FOR MATRIX KEYPAD ROWS
COLUMN:        DC.B $01, $02, $04, $08       ; PortM INPUT VALUES FOR MATRIX KEYPDA COLUMNS                                             

KP_VALUE:      DC.B $01, $02, $03, $0A       ; KEY VALUES FROM KEYPAD FOR ITERATING THROUGH
               DC.B $04, $05, $06, $0B
               DC.B $07, $08, $09, $0C
               DC.B $00, $0F, $0E, $0D      

STRING1        FCC "PAUSED      "            ; CREATE A STRING FOR PAUSED
               DC.B $00
STRING2        FCC "RUN         "            ; CREATE A STRING WITH THE RUN
               DC.B $00
STRING3        FCC "  UP"                    ; CREATE A STRING WITH THE UP
               DC.B $00
STRING4        FCC "DOWN"                    ; CREATE A STRING WITH THE DOWN
               DC.B $00
STRING5        FCC "   COUNT: "              ; CREATE A STRING FOR THE TIME LINE
               DC.B $00                      
STRING6        FCC "ENTER NUMBER ON"         ; CREATE A STRING 
               DC.B $00
STRING7        FCC "KEYPAD"                  ; CREATE A STRING 
               DC.B $00
STRING8        FCC "PRESS RIGHT"              ; CREATE A STRING 
               DC.B $00
STRING9        FCC "BUTTON TO START"         ; CREATE A STRING 
               DC.B $00
STRING10       FCC "MIDDLE BUTTON TO"            ; CREATE A STRING 
               DC.B $00
STRING11       FCC "CHANGE DIRECTIONS"    ; CREATE A STRING 
               DC.B $00

; End of code

; Define Power-On Reset Interrupt Vector - Required for all programs!

; AGAIN - OP CODES are at column 9 
               ORG $FFFE                     ; $FFFE, $FFFF = Power-On Reset Int. Vector Location
               FDB START                     ; Specify instruction to execute on power up
     
               END                           ; (Optional) End of source code
        
; Labels start in the first column  (left most column = colunm 1)
; OP CODES are at column 9 
; COMMENTS follow a ";" symbol
; Blank lines are allowed (Makes the code more readable)