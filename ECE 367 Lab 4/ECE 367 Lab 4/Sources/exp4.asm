; University of Illinois at Chicago, Dept. of Electrical and Computer Engineering
; ECE 367 -Microprocessor-Based Design
; Semester: Spring 2013

; Experiment Title: 24 Second Shot Clock
; Experiment Description: This system is a 24 second shot clock which counts down 
;                         from 24 seconds to 0 seconds and has the ability to pause 
;                         and restart when the button is pressed.  When the clock
;                         reaches 00, it will blink three times indicating the 
;                         timer is done and the clock will reset.
; Date: 2/15/2013
; Updated: 2/15/2013
; Version: 1
; Programmer: Mitchell Hedditch
; Lab Session: Tuesday 8AM-10:50AM 
                       

; Define symbolic constants 
PortA   EQU $00                           ; PortA address (relative to Regbase i.e. offset)
PortM   EQU $0250                         ; PortM offset (actual address of PortM)
PortT   EQU $0240                         ; PortT offset (actual address of PortT)
DDRA    EQU $02                           ; PortA Data Direction control register offset
DDRM    EQU $0252                         ; PortM Data Direction control register offset
DDRT    EQU $0242                         ; Actual Data Direction Register for PortT
INITRG  EQU	$11
INITRM	EQU	$10
CLKSEL	EQU	$39
PLLCTL	EQU	$3A
CRGFLG	EQU	$37
SYNR	  EQU	$34
REFDV	  EQU	$35
COPCTL	EQU	$3C
TSCR1	  EQU	$46
TSCR2	  EQU	$4D
TIOS	  EQU	$40
TCNT	  EQU	$44
TC0	    EQU	$50
TFLG1	  EQU	$4E
IRQCR   EQU $001E                         ; IRQ CONTROL REGISTER ADDRESS LABEL
Regbas  EQU $0000                         ; Register block starts at $0000
SAVE_Y  EQU $3800                         ; Defines location for the storage of the Y index register
FLAG1   EQU $3802                         ; DEFINES LOCATION FOR STORAGE OF FLAG1 FOR INTERRUPTS
                                          ; FLAG = 0->PAUSE; 1->RUN

;******************************************************************************************
; The ORG statment below is followed by variable definitions
; THIS IS THE BEGINNING SETUP CODE
;
	    ORG	$3800		                        ; Beginning of RAM for Variables
;
; The main code begins here. Note the START Label
;
	    ORG	$4000		                        ; Beginning of Flash EEPROM
START	LDS	#$3FC0		                      ; Top of the Stack
	    SEI			                            ; Turn Off Interrupts
      MOVB	#$00, INITRG	                ; I/O and Control Registers Start at $0000
	    MOVB	#$39, INITRM	                ; RAM ends at $3FFF
;
; We Need To Set Up The PLL So that the E-Clock = 24MHz
;
	    BCLR CLKSEL,$80                     ; disengage PLL from system
	    BSET PLLCTL,$40                     ; turn on PLL
	    MOVB #$2,SYNR                       ; set PLL multiplier
	    MOVB #$0,REFDV                      ; set  PLL divider
	    NOP		                              ; No OP
	    NOP		                              ; NO OP
PLP 	BRCLR CRGFLG,$08,PLP ; while (!(crg.crgflg.bit.lock==1))
	    BSET CLKSEL,$80                     ; engage PLL
;
;
;
	    CLI		                              ; Turn ON Interrupts
;
; End of  setup code. You will always need the above setup code for every experiment
;*****************************************************************************************
; Begin Code

; Initialize the 68HC11

        LDY  #Regbas                       ; Initialize register base address
                                           ; Note that Regbas = $0000 so now <Y> = $0000

; SETUP S BIT ON INTERRUPTS
        BSET IRQCR,$C0                     ; TURN ON IRQ INTERRUPT AND SET TO EDGE TRIGGERED
        
; Setup the data directon for PortA and PortT

        BCLR DDRM,$FF                      ; Set all pins of PortM to inbound
        BSET DDRM,$0C                      ; PortM pins 2 & 3 are outbound
        BCLR PortM,$0C                     ; Set pins 2 & 3 of PortM to low
        BSET DDRT,$FF                      ; set all PortT pins to outbound
        BCLR PortT,$FF                     ; Make Sure all PortT pins are low
        
; INITIALIZE THE ENTIRE SYSTEM VARIABLES AND BEGIN OPERATIONAL CODE
              
BEGIN:  MOVB #$00,FLAG1                    ; INITIALIZE THE SYSTEM IN PAUSE MODE
        LDX #TABLE+2                       ; Load the beginning address of the table into x
        LDY #TABLE+4                       ; Load the beginning address of the table into y
        JSR SET_TENS                       ; Call set tens to start LCD1
        JSR SET_ONES                       ; CALL SET ONES TO START LCD2
        STY SAVE_Y                         ; Save the value of Y b/c it will change in delay
        JSR Sec_Delay                      ; Delay a bit to let the user let go of button
        LDY SAVE_Y                         ; Reload Y from it's saved location after delay
POLL:   BRCLR FLAG1,$01,POLL               ; WAIT AT POLL UNTIL THE IRQ' INTERRUPT FLAG IS SET
        CPX #TABLE+9                       ; Compare X to 09
        BNE NOBUZZ                         ; Branch if X=09 to END_RESET
        CPY #TABLE+9
        BNE NOBUZZ
        JSR BUZZ
        JSR BEGIN
        
NOBUZZ: CPY #TABLE+9                       ; Compare ones index (Y) to 1
        BNE ONES                           ; If ones place not TABLE-1 branch to ONES so we only
                                           ; Change the ones LCD
        JSR SET_TENS                       ; Increment the tens LCD otherwise
ONES:   JSR SET_ONES                       ; Call set ones
        BCLR PortM,$0C                     ; Set PortM pins 2 and 3 back to low
        STY SAVE_Y                         ; Save the value of Y b/c it will change in delay
        JSR Sec_Delay                      ; Delay a bit to let the user let go of button
        LDY SAVE_Y                         ; Reload Y from it's saved location after delay
        JMP POLL                           ; Jump back and begin polling M0 again        

;**********************************************************************************************
SET_TENS:
        LDAA 1,X-                          ; Load A with X (post-decrement X)
        BCLR PortM,$0C                     ; Set pins 2 & 3 of PortM to low (just to make sure)
        BSET PortM,$04                     ; Set pin 2 to high for latch for TEN's LCD
        STAA PortT                         ; Output new value for LCD to PortT        
        CPX #TABLE-1                       ; Compare index X to TABLE
        BNE CON_X                          ; As long as index X is != 10 skip the reset to 0
        LDX #TABLE+9                       ; Reset the index X to the base value of TABLE
CON_X:  RTS                                ; Return from subroutine
;**********************************************************************************************
SET_ONES:
        LDAA 1,Y-                          ; Load A with Y (post-decrement Y)        
        BCLR PortM,$0C                     ; Set pins 2 & 3 of PortM to low (just to make sure)
        BSET PortM,$08                     ; Set pin 3 to high for latch for TEN's LCD
        STAA PortT                         ; Output new value for LCD to PortT        
        CPY #TABLE-1                       ; Compare index Y to TABLE
        BNE CON_Y                          ; As long as index Y in != 10 skip the reset to 0
        LDY #TABLE+9                       ; Reset the index Y to the base value of TABLE
CON_Y:  RTS                                ; Return from subroutine
;**********************************************************************************************
BUZZ:
        BSET PortM,$0C                     ; Set pin 2 to high for latch for TEN's LCD
        LDAA #$00                          ; Load A with X (post-decrement X)
        STAA PortT                         ; Output new value for LCD to PortT        
        JSR Buzzer_Delay                   ; Delay a bit to let the user let go of button
        LDAA TABLE                         ; Load A with X (post-decrement X)
        STAA PortT                         ; Output new value for LCD to PortT        
        JSR Buzzer_Delay                   ; Delay a bit to let the user let go of button
        LDAA #$00                          ; Load A with X (post-decrement X)
        STAA PortT                         ; Output new value for LCD to PortT        
        JSR Buzzer_Delay                   ; Delay a bit to let the user let go of button
        LDAA TABLE                         ; Load A with X (post-decrement X)
        STAA PortT                         ; Output new value for LCD to PortT        
        JSR Buzzer_Delay                   ; Delay a bit to let the user let go of button
        LDAA #$00                          ; Load A with X (post-decrement X)
        STAA PortT                         ; Output new value for LCD to PortT        
        JSR Buzzer_Delay                   ; Delay a bit to let the user let go of button
        LDAA TABLE                         ; Load A with X (post-decrement X)
        STAA PortT                         ; Output new value for LCD to PortT        
        JSR Buzzer_Delay                   ; Delay a bit to let the user let go of button
        RTS                                ; Return from subroutine
;*****************************************************************************************
Sec_Delay:
        LDAB #100                          ; Outer Loop counter - 1 clock cycle
A1:     LDY  #30000                        ; Inside Loop Counter 2 clock cycles
A0:     BRCLR FLAG1,$01,A0                 ; WAIT AT POLL UNTIL THE IRQ' INTERRUPT FLAG IS SET
        LBRN A0                            ; 3 clock cycles \
        DEY                                ; 1 clock cycles  | 8 clock cycles in loop
        LBNE A0                            ; 4 clock cycles /
        DECB                               ; 1 clock cycles
        BNE  A1                            ; 3 clock cycles
        RTS                                ; Return from subroutine - 5 clock cycles
                                           ; when we get here we have
                                           ; ([(8*30000) + (2) + (1) + (3)]*100) + 1 + 5
                                           ; 24000606 clock cycles or approx 1 sec.
;*****************************************************************************************
Buzzer_Delay:
        LDAB #100                          ; Outer Loop counter - 1 clock cycle
A2:     LDY  #6000                         ; Inside Loop Counter 2 clock cycles
A3:     LBRN A3                            ; 3 clock cycles \
        DEY                                ; 1 clock cycles  | 8 clock cycles in loop
        LBNE A3                            ; 4 clock cycles /
        DECB                               ; 1 clock cycles
        BNE  A2                            ; 3 clock cycles
        RTS                                ; Return from subroutine - 5 clock cycles
                                           ; when we get here we have
                                           ; ([(8*30000) + (2) + (1) + (3)]*100) + 1 + 5
                                           ; 24000606 clock cycles or approx 1 sec.                                             
;****************************************************************************************
ISR_IRQ:COM FLAG1                          ; TOGGLE THE FLAG
        RTI                                ; RETURN FROM INTERRUPT
;******************************************************************************************
        ORG $FFF2                          ; IRQ' VECTOR ADDRESS
        FDB ISR_IRQ                        ; ISR_XIRQ IS A LABEL THE ADDRESS OF THE LABEL
                                           ; IS THE VECTOR                                       
;*****************************************************************************************
; Have the Assembler put the solution data in the look-up table

        ORG $5500                          ; The look-up table is at $5000

TABLE:  DC.B $6F, $03, $5D, $57, $33       ; Define data table of mappings to each of the 
        DC.B $76, $7E, $43, $7F, $73       ; segments of the 7-segment LED displays
                                           ; Memory locations correspond to their values
                                           ; i.e. $5500 = 0, $5501 = 1, etc
      
; End of code

; Define Power-On Reset Interrupt Vector - Required for all programs!

; AGAIN - OP CODES are at column 9 
        ORG $FFFE                 ; $FFFE, $FFFF = Power-On Reset Int. Vector Location
        FDB START                 ; Specify instruction to execute on power up
     
        END                       ; (Optional) End of source code
        
; Labels start in the first column  (left most column = colunm 1)
; OP CODES are at column 9 
; COMMENTS follow a ";" symbol
; Blank lines are allowed (Makes the code more readable)
