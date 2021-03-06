; University of Illinois at Chicago, Dept. of Electrical and Computer Engineering
; ECE 367 -Microprocessor-Based Design
; Semester: Spring 2013

; Experiment Title: Count Up/Down Timer
; Experiment Description: This system is a timer that is capable of starting and 
;                         pausing operation, as well as reversing the count direction.
;                         It will count from 00 to 99 or 99 to 00 and when it reaches 00
;                         again, it will blink 3 times and then reset the system.  You 
;                         can enter number values on the keypad at any time to change the
;                         timing values.                        
; Date: 2/21/2013
; Updated: 2/25/2013
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
TMR2_FLAG      EQU $3812                     ; DEFINES LOCATION FOR STORAGE OF TIMER FLAG 2
                                             ; FLAG= 0->NOTHING; 1->TIMER FIRED
TIME_COUNT     EQU $3814                     ; MEM ADDRESS TO STORE TIME FOR SECONDS
XIRQ_FLAG      EQU $3816                     ; PAUSE FOR XIRQ (1 MSEC)
NUM_FLAG       EQU $3818                     ; A FLAG THAT GOES TO 1 IF A KEY IS PRESSED ON THE PAD
CUR_PAD_VAL    EQU $3820                     ; USED TO HOUSE THE VALUE FOR THE CURRENT KEYPAD ITERATION

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
        
               ; SETUP THE DATA DIRECTON REGISTERS AND INITIALIZE PORT A & PORT T
               MOVB #$03,DDRM                ; SET PortM PINS 0&1 TO OUTBOUND
               MOVB #$00,PortM               ; SET ALL PortM PINS TO LOW (0)
               MOVB #$FF,DDRT                ; SET ALL PortT PINS TO OUTBOUND
               MOVB #$00,PortT               ; SET ALL PortT PINS TO LOW
               
               ; SET UP TIMER COUNT INFORMATION AND PRESCALE INITIALIZE THE COUNTER
               MOVB #$06,TSCR2               ; CONFIGURE PRESCALE FACTOR 64
               MOVB #$01,TIOS                ; ENABLE OC0 FOR OUTPUT COMPARE
               MOVB #$90,TSCR1               ; ENABLE TCNT & FAST FLAGS CLEAR
               MOVB #$01,TIE                 ; ENABLE TC1 INTERRUPT
               LDD TCNT                      ; FIRST GET CURRENT TCNT
               ADDD #3750                    ; INCREMENT TCNT COUNT BY 3750 AND STORE INTO TC0
               STD TC0                       ; WE WILL HAVE A SUCCESSFUL COMPARE IN 375 CLICKS
               MOVB #$01,TFLG1               ; OF TCNT. BETTER BE SURE FLAG C0F IS CLEAR TO START
               MOVB #$01,TFLG2
               
               ; PROGRAM INITIALIZATION
RESTART        MOVB #$01,PAUSE               ; INITIALIZE IN THE SYSTEM IN PAUSE MODE
               MOVB #$00,DIR_FLAG            ; INITIALIZE THE SYSTEM IN COUNT UP MODE
               MOVB #$00,TMR_FLAG            ; INITIALIZE THE TIMER FLAG TO LOW
               MOVB #$00,TIME_COUNT          ; SET TIME_COUNT TO 0
               MOVB #$00,NUM_FLAG            ; SET NUM_FLAG TO 0 TO
               MOVB #$01,PortM               ; TURN TENS ENABLE ON
               MOVB #$79,PortT               ; OUTPUT AN E
               MOVB #$02,PortM               ; TURN ONES ENABLE ON
               MOVB #$37,PortT               ; OUTPUT AN N
               
               
               ; ALL VARIABLES ARE INITIALIZED SO WE'RE READY FOR INTERRUPTS
               CLI                           ; TURN ON INTERRUPTS
                                      
POLL:          ;LOGIC FOR KEYPAD
               JSR GET_KEY                   ; CHECK THE KEYPAD FOR A PRESSED VALUE
               BRCLR NUM_FLAG,$01,NO_KEY     ; IF NO KEY HAS BEEN PRESSED THEN MOVE ON THE THE NO_KEY LINE
               JSR LOAD_NUMBER               ; IF A KEY HAS BEEN PRESSED THEN LOAD THE NEW NUMBERS
               MOVB #$00,NUM_FLAG            ; CLEAR THE NUM FLAG TO WAIT FOR A NEW KEY
NO_KEY         BRSET PAUSE,$01,POLL          ; WAIT AT POLL WHILE THE IRQ' (PAUSE) INTERRUPT FLAG IS SET
               BRCLR PortE,$01,*             ; BRANCH HERE UNTIL THE XIRQ PORT IS HIGH AGAIN
               JSR INITIALIZE                ; SEE IF WE HAVE NUMBERS LOADED OR WE NEED TO INITIALIZE
               BRCLR TMR_FLAG,$01,POLL       ; IF THE TIME FLAG ISN'T SET BRANCH BACK TO POLL
               BRSET DIR_FLAG,$01,CDOWN      ; IF THE DIRECTION FLAG IS SET, THEN COUNT DOWN
               JSR COUNT_UP                  ; ADVANCE X&Y INDICES UPWARD
               BRA UPDATE_DISPLAY            ; BRANCE TO CONTINUE
CDOWN          JSR COUNT_DOWN                ; ADVANCE X&Y INDICES DOWNWARD               
UPDATE_DISPLAY JSR UPDATE_ONES_DISPLAY       ; UPDATE THE ONES DISPLAY LED TO CURRENT Y
               JSR UPDATE_TENS_DISPLAY       ; UPDATE THE TENS DISPLAY LED TO CURRENT X
               MOVB #$00,TMR_FLAG            ; CLEAR THE TIMER FLAG
               CPY 0                         ; COMPARE Y TO ZERO
               BNE CONTINUE                  ; IF WE'RE NOT AT ZERO THEN CONTINUE
               JSR BLINK                     ; BLINK 3 TIMES
               BRA RESTART                   ; RESTART OUR SYSTEM
CONTINUE       BRA POLL                      ; GO BACK START PROCESSING AT POLL AGAIN!

;**********************************************************************************************
GET_KEY:       MOVB #$00,PortM               ; TURN THE LATCH ENABLES OFF!!
               STX SAVE_X                    ; SAVE THE CURRENT VALUE OF X TO MEMORY
               STY SAVE_Y                    ; SAVE THE CURRENT VALUE OF Y TO MEMORY
               LDX #KP_VALUE                 ; LOAD X WITH MEM ADDRESS FOR KP_VALUE                 
               STX CUR_PAD_VAL               ; STORE THE ADDRESS OF THE FIRST KEYPAD VALUE 
               LDX #ROW                      ; LOAD X WITH THE INITIAL VALUE AT THE ROW ADDRESS
               LDY #COLUMN                   ; LOAD Y WITH THE INITIAL VALUE AT THE COLUMN ADDRESS
               ; NOW WE BEGIN OUR LOOPING
NEXT_ROW       LDAA 1,X+                     ; LOAD ACCUM A WITH CURRENT ROW VALUE POST INCREMENT
NEXT_COLUMN    LDAB 1,Y+                     ; LOAD ACCUM Y WITH CURRENT COLUMN VALUE POST INCREMENT
               STAA PortT                    ; SET THE CURRENT ROW TO HIGH VALUE
               NOP                           ; WAIT SOME TIME FOR PIN TO GO HI
               NOP                           ; WAIT SOME TIME FOR PIN TO GO HI
               NOP                           ; WAIT SOME TIME FOR PIN TO GO HI
               CMPB PortM                    ; COMPARE THE VALUE IN B TO PortM
               BEQ KEY_PRESSED               ; IF THE KEY IS PRESSED THEN MAKE IT SO!
               LDD CUR_PAD_VAL               ; LOAD THE CUR_PAD_VAL INTO D
               ADDD #1                       ; ADD 1 TO D
               STD CUR_PAD_VAL               ; STORE THE PAD VALUE BACK INTO D
               CPY #COLUMN+4                 ; CHECK TO SEE IF WE'RE AT THE END OF THE COLUMNS
               BNE NEXT_COLUMN               ; IF NOT, THEN GO BACK AND TRY NEXT COLUMN
               LDY #COLUMN                   ; IF WE ARE THEN RESET THE COLUMNS
               CPX #ROW+4                    ; CHECK TO SEE IF WE'RE AT THE END OF THE ROWS
               BNE NEXT_ROW                  ; IF WE'RE NOT AT END OF ROWS, GO TO NEXT ROW
               LDY SAVE_Y                    ; LOAD THE VALUE OF Y BACK TO THE INDEX
               LDX SAVE_X                    ; LOAD THE VALUE OF X BACK TO THE INDEX
               RTS                           ; RETURN FROM THE SUBROUTINE IF WE'VE PROCESS ALL ROWS AND COLUMNS
KEY_PRESSED    COM NUM_FLAG                  ; SET NUM_FLAG SINCE A NUMBER WAS PRESSED
               LDY SAVE_Y                    ; LOAD THE VALUE OF Y BACK TO THE INDEX
               LDX SAVE_X                    ; LOAD THE VALUE OF X BACK TO THE INDEX
               JSR KEY_RELEASE               ; NOW WE NEED TO WAIT UNTIL THE KEYS ARE RELEASED                             
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
KEY_RELEASE:   MOVB #$70,PortT               ; SET ALL ROWS TO HIGH
               BRCLR TMR2_FLAG,$01,*         ; WAIT A SECOND HERE
               BRCLR TMR2_FLAG,$01,*         ; WAIT A SECOND HERE
               BRCLR TMR2_FLAG,$01,*         ; WAIT A SECOND HERE
               BRCLR TMR2_FLAG,$01,*         ; WAIT A SECOND HERE
               BRSET PortM,$04,*             ; WAIT HERE UNTIL COLUMN 1 IS CLEAR
               BRSET PortM,$08,*             ; WAIT HERE UNTIL COLUMN 2 IS CLEAR
               BRSET PortM,$10,*             ; WAIT HERE UNTIL COLUMN 3 IS CLEAR
               BRSET PortM,$20,*             ; WAIT HERE UNTIL COLUMN 4 IS CLEAR
               MOVB #$01,TMR2_FLAG
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
LOAD_NUMBER:   LDAA #$00                     ; SET A TO ZERO
               TFR Y,X                       ; TRANSFER THE Y REGISTER INTO THE X REGISTER
               LDY CUR_PAD_VAL               ; LOAD THE EFFECTIVE ADDRESS INTO Y (NEW VALUE)
               LDAB Y                        ; LOAD A WITH THE ADDRESS IN Y
               ADDD #TABLE                   ; ADD THE REGISTER VALUE OF TABLE TO THE NUMBER IN D
               TFR D,Y                       ; TRANSFER THE VALUE IN A TO Y
               JSR UPDATE_ONES_DISPLAY       ; UPDATE THE ONES DISPLAY LED TO CURRENT Y
               JSR UPDATE_TENS_DISPLAY       ; UPDATE THE TENS DISPLAY LED TO CURRENT X
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
UPDATE_TENS_DISPLAY:
               MOVB #$01,PortM               ; ENABLE THE TENS LATCH
               CPX 10                        ; COMPARE X TO 9
               BLT T_ZERO                    ; IF IT'S LESS THEN 10 MAKE IT ZERO
               LDD 10                        ; PLACE TEN IN D
               TFR X,D                       ; SWITCH VALUES IN X & D
               IDIV                          ; DIVIDE 
               MOVB X,PortT                   ; OUTPUT VALUE TO PortT
               MOVB #$00,PortM               ; DISABLE THE TENS LATCH
               RTS                           ; RETURN FROM SUBROUTINE
T_ZERO         MOVB #TABLE,PortT             ; OUTPUT VALUE TO PortT
               MOVB #$00,PortM               ; DISABLE THE TENS LATCH
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
UPDATE_ONES_DISPLAY:
               MOVB #$02,PortM               ; ENABLE THE TENS LATCH
               MOVB Y,PortT                  ; OUTPUT VALUE TO PortT
               MOVB #$00,PortM               ; ENABLE THE TENS LATCH
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
INITIALIZE:    CPY #0                        ; CHECK TO SEE IF Y = 0
               BNE CHECK_X                   ; IF Y NOT EQUAL TO ZERO CHECK X
               LDY #TABLE                    ; INITIALIZE Y TO THE BEGINNING OF THE TABLE
CHECK_X        CPX #0                        ; CHECK TO SEE IF X = 0
               BNE NO_INIT                   ; IF Y NOT EQUAL TO ZERO CHECK X
               LDX #TABLE                    ; INITIALIZE Y TO THE BEGINNING OF THE TABLE
NO_INIT        RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
COUNT_UP:      INCY
               CPY 100                       ; COMPARE IT TO TABLE+10 (BEYOND MAX DIGIT 9)
               BNE CU_EXIT                   ; BNE TO THE BOTTOM TO EXIT THE SUBROUTINE
               LDX 0
CU_EXIT        RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
COUNT_DOWN:
               LDAA 1,-Y                     ; GET ONES VALUE (Y) AND PRE DECREMENT
               CPY #TABLE-1                  ; COMPARE IT TO TABLE-1 (BELOW 0 DIGIT)
               BNE CD_EXIT                   ; BNE TO THE BOTTOM TO EXIT THE SUBROUTINE
               LDY #TABLE+9                  ; SET ONES = TABLE+9
                                             ; IF WE MADE IT HERE WE ALSO NEED TO DECREMENT THE TENS DIGIT
               LDAA 1,-X                     ; GET THE TENS VALUE AND PRE-DECREMENT
               CPX #TABLE-1                  ; COMPARE IT TO TABLE-1 (BELOW 0 DIGIT)
               BNE CU_EXIT                   ; BNE TO THE END TO EXIT SUBROUTINE
               LDX #TABLE+9                  ; SET TENS = TABLE+9
CD_EXIT        RTS                           ; RETURN FROM SUBROUTINE                            
;**********************************************************************************************
BLINK:         LDY #0                        ; SET Y TO ZERO
BLINKING       BSET PortM,$03                ; SET BOTH Portm PINS TO HIGH FOR OUTPUT
               LDAA #$00                     ; LOAD A WITH ZERO SO DISPLAY GOES BLANK
               STAA PortT                    ; OUTPUT VALUE IN A TO PortT
               BRCLR TMR_FLAG,$01,*          ; WAIT A SECOND HERE
               MOVB #$00,TMR_FLAG            ; CLEAR THE TIMER FLAG
               LDAA TABLE                    ; LOAD A WITH TABLE VALUE TO DISPLAY 00
               STAA PortT                    ; OUTPUT VALUE IN A TO PortT
               BRCLR TMR_FLAG,$01,*          ; WAIT A SECOND HERE
               MOVB #$00,TMR_FLAG            ; CLEAR THE TIMER FLAG
               INY                           ; INCREMENT Y
               CPY #3                        ; SEE IF WE'VE BLINKED 3 TIMES
               BNE BLINKING                  ; IF NOT THEN BLINK AGAIN!
               RTS                           ; RETURN FROM SUBROUTINE
;**********************************************************************************************
; TC0 INTERRUPT SUBROUTINE
ISR_TC0:       LDD TC0                       ; INTERRUPT READS THE FLAG SO THIS WRITE CLEARS THE FLAG
               ADDD #3750                    ; ADD THE EQUIVALENT .1 SECOND CNT TO REGISTER D
               STD TC0                       ; UPDATE TC0 MEMORY TO NEW VALUE
               MOVB #$01,TMR2_FLAG           ; TURN ON OUR TIMER FLAG
               PSHA                          ; SAVE A ON THE STACK
               LDAA TIME_COUNT               ; LOAD THE VALUE OF TIME_COUNT INTO A
               CMPA #100                     ; IF TIME_COUNT = 100 THEN WE HAVE 1 SECOND
               BNE TMR_UPDATE                ; IF WE'RE NOT AT 100 YET, GOTO TMR_UPDATE LINE
               MOVB #$01,TMR_FLAG            ; TURN ON OUR TIMER FLAG
               MOVB #$00,TIME_COUNT          ; RESET OUR TIMER COUNT BACK TO ZERO
               PULA                          ; PUL A BACK OFF THE STACK
               RTI                           ; RETURN FROM THE INTERRUPT
TMR_UPDATE     ADDA #01                      ; INCREMENT THE VALUE IN A
               STAA TIME_COUNT               ; STORE A BACK INTO TIME_COUNT
               PULA                          ; PULL A BACK OFF THE STACK
               RTI                           ; RETURN FROM THE INTERRUPT
;****************************************************************************************
; IRQ' INTERRUPT SUBROUTINE
ISR_IRQ:       COM PAUSE                     ; TOGGLE THE START/PAUSE FLAG 
               RTI                           ; RETURN FROM INTERRUPT
;****************************************************************************************
; XIRQ' INTERRUPT SUBROUTINE
ISR_XIRQ:      COM DIR_FLAG                  ; TOGGLE THE DIRECTION FLAG
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

               ORG $5500                     ; The look-up table is at $5000

TABLE:         DC.B $3F, $06, $5B, $4F, $66  ; Define data table of mappings to each of the 
               DC.B $6D, $7D, $07, $7F, $6F  ; segments of the 7-segment LED displays
               DC.B $5C, $3C, $39, $5F, $7B  ; Memory locations correspond to their values
               DC.B $71                      ; i.e. $5500 = 0, $5501 = 1, etc
                                             
ROW:           DC.B $10, $20, $40, $80       ; PortT OUTPUT VALUES FOR MATRIX KEYPAD ROWS
COLUMN:        DC.B $04, $08, $10, $20       ; PortM INPUT VALUES FOR MATRIX KEYPDA COLUMNS                                             

KP_VALUE:      DC.B $01, $02, $03, $0A       ; KEY VALUES FROM KEYPAD FOR ITERATING THROUGH
               DC.B $04, $05, $06, $0B
               DC.B $07, $08, $09, $0C
               DC.B $00, $0F, $0E, $0D      
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