//*********************************************************************************************************
// University of Illinois at Chicago, Dept. of Electrical and Computer Engineering
// ECE 367 -Microprocessor-Based Design
// Semester: Spring 2013

// Experiment Title: Count Up/Down Timer Using The SPI Subsystem and LCD Display
// Experiment Description: This system is a timer that is capable of starting and 
//                         pausing operation, as well as reversing the count direction.
//                         It will count from 00 to 99 or 99 to 00 and when it reaches 00
//                         again, it will blink 3 times and then reset the system.  You 
//                         can enter number values on the keypad at any time to change the
//                         timing values.  All data displayed on LCD.                      
// Date: 4/13/2013
// Updated: 4/13/2013
// Version: 1
// Programmer: Mitchell Hedditch
// Lab Session: Tuesday 8AM-10:50AM 
//*********************************************************************************************************
/* Some include (header) files needed by Codewarrior with machine info for the NanoCore12                */

#include <hidef.h>                                          /* common defines and macros                 */
#include "derivative.h"                                     /* derivative-specific definitions           */


/* We need to define some constants. Similar to EQU's in assembly                                        */
#define     IOREGS_BASE  0x0000

#define     _IO8(off)    *(unsigned char  volatile *)(IOREGS_BASE + off) //define form prototype 8-bit
#define     _IO16(off)   *(unsigned short volatile *)(IOREGS_BASE + off) //define form prototype 16-bit


//#define   PORTT     _IO8(0x240)     
/* portT data register is unsigned 8-bit at address $0240                                                */
/* because of the form prototype defines above this is the same as                                       */                                                                 
/* #define PORTT *(unsigned char  volatile *) (0x240);    Means PORTT points to address $0240            */
/* the statement PORTT = 0x34; means to store $34 at location $0240                                      */
/* if the contents of PORTT is 0xd3 then the assignment x = PORTT; means x is now equal to 0xd3          */
/*********************************************************************************************************/
/* The commented out defines already exist in one of the above header files. The compiler                */
/* does not like the redundancy. So, they are commented out with the // symbols                          */
//#define     TSCR1   _IO8(0x46)             //timer system control register
//#define     PTT     _IO8(0x240)            //portt data register
//#define     DDRT    _IO8(0x242)            //portt direction register
//#define     CRGFLG  _IO8(0x37)             //pll flags register
//#define     SYNR    _IO8(0x34)             //synthesizer / multiplier register
//#define     REFDV   _IO8(0x35)             //reference divider register
//#define     CLKSEL  _IO8(0x39)             //clock select register
//#define     PLLCTL  _IO8(0x3a)             //pll control register
#define   PORTT    _IO8(0x240)               // PortT data register     
#define   PORTTi   _IO8(0x241)               // portT data register
#define   PORTM    _IO8(0x250)               // portM data register
#define   MCCTL    _IO8(0x66)                //modulus down conunter control
#define   MCFLG    _IO8(0x67)                //down counter flags
#define   SPCR1    _IO8(0xD8)                //SPI SPCR1 REGISTER LOCATION
#define   SPCR2    _IO8(0xD9)                //SPI SPCR2 REGISTER LOCATION
#define   SPIB     _IO8(0xDA)                //SPI SPIB REGISTER LOCATION
#define   SPSR     _IO8(0xDB)                //SPI SPSR REGISTER LOCATION
#define   SPDR     _IO8(0xDD)                //SPI SPDR REGISTER LOCATION
#define   MCCNT    _IO16(0x76)               //modulus down counter register
#define   keypad   PORTT


// Let's define some bit locations for some flags and config bits
#define   PLLSEL  0x80
#define   LOCK    0x08
#define   TFFCA   0x10
#define   MCZF    0x80
#define   BIT0    0x01
#define   BIT1    0x02
#define   BIT2    0x04
#define   BIT3    0x08
#define   BIT4    0x10
#define   BIT5    0x20
#define   BIT6    0x40
#define   BIT7    0x80
#define   ENABLE  0x02                       // LCD ENABLE AT PM1
#define   RCK     0x08                       // RCK CONNECTED TO PM3
#define   RS      0x01                       // REGISTER SELECT (RS) AT PM0 (0=COMMAND,1=DATA)


// Let's define our general variables
unsigned char DIRECTION;
unsigned char PAUSE;
unsigned int TIMER_COUNT;
unsigned char COUNT_VALUE;


/* Here we give function prototypes before we start on the main code */
char getkey(void);
void SetClk8(void); 
void delayby1ms(int k);
void keyrelease(void);
void Command(char a);
void Print(char a);
void Clear(void); 
void delay(void);
void delay3(void);
void systemInitialize(void);
void SPIInitialize(void);
void InitLCD(void);
void updateDisplay(void);
void insertNumber(char Number);
void displayNumber(void);
void blink(void);

/******************************************************************
*  This is the main code where everything should go,
*  All program function is directed by this code
*****************************************************************/
void main(void) 
{
     char key1;
	
	systemInitialize();                                    //Run system initialization
     
     updateDisplay();                                       //Print out the display
     
     TIMER_COUNT = 0;                                       // INITIALIZE TIMER_COUNT TO 0
          
	while(1)                                               // this is and infinite while loop
     {   
          /* OK. 1ms gone by. Let's see if user pressed the A key or the B key. */
		key1  = getkey();                                 // go check for keypress
		if(key1 < 0x1f)                                   // did we get a key? If so, do the next three statements
		{
		     keyrelease();                                //check for keyrelease
		     delay();                                     //short delay
			while((PORTTi & 0x08));                      // if column 3 is HIGH wait here until LOW  
			if(key1 >= 10)                               //Did user press anything above 9?
			{
				if(key1==10)                            // If user pressed A do the following
				{
				     PAUSE=~PAUSE;                      // Compliment the Start/Stop flag.
                         
                         //IF COUNT VALUE IS 0, AND WE'RE STARTING TO COUNT DOWN, SET IT TO 99				     
				     if (COUNT_VALUE==99) COUNT_VALUE = 0;/
				
                         updateDisplay();                   //Print out the display
                    }
				if(key1==11)                            // If user pressed B do the following
				{
				     DIRECTION=~DIRECTION;              // Compliment the Up/Down flag.
				     
				     //IF COUNT VALUE IS 0, AND WE'RE STARTING TO COUNT DOWN, SET IT TO 99
				     if (COUNT_VALUE==0) COUNT_VALUE = 99;        
				
				     updateDisplay();                   //Print out the display
                    } 
		     } 
		     else 
		     {
		          insertNumber(key1);                     // if we're here then insert a new number for the user.        
		          updateDisplay();                        //Print out the display
               }
	     }
          
          if (PAUSE != 0x01)                                // IF WE'RE NOT IN PAUSE MODE
          {
               delayby1ms(1);                               // DELAY BY 1 MSEC
                              
               TIMER_COUNT++;                               // INCREASE 
               
               if (TIMER_COUNT == 1000)                     // IF WE'VE REACHED 1000 MSECS IT'S TIME TO UPDATE COUNT 
               {
                    if (DIRECTION == 0xFF) {                // ARE WE IN DOWN MODE?
     	               COUNT_VALUE--;                     //COUNT DOWN BY 1
     	          } else {                                // ELSE WE'RE IN UP MODE SO
                         COUNT_VALUE++;                     // COUNT UP BY 1
                    }
               
                    updateDisplay();                        //UPDATE OUR DISPLAY
                    
                    TIMER_COUNT = 0;                        // RESET OUR TIMER COUNTER
               }

               if (COUNT_VALUE == 0 || COUNT_VALUE ==100)   //Have we reached 0? 
               {
                    COUNT_VALUE = 0;                        //Reset our count to zero
                    updateDisplay();                        //Refresh the display
                    blink();                                //Lets make the display blink a few times
                    PAUSE = 0x01;                           //Pause the system
                    TIMER_COUNT = 0;                        //Reest our timer to zero
                    DIRECTION = 0x00;                       //DIRECTION UP
                    updateDisplay();                        //Refresh the display
               }
          }          
     } 
}                



/********************************************************************/
/*  This is the initialization controller, it initializes program   */
/*  vars & calls other systems to initialize in the hardware        */
/********************************************************************/
void systemInitialize(void)
{
     SetClk8();                                             // go setup the PLL
     
     // setup the data direction registers
     DDRM = 0xfc;                                           // set data direction register for PortM
     DDRT = 0xf0;                                           // set data direction register for PortT
     PORTM = 0;                                             // clear PortM
     COUNT_VALUE = 0;                                       // INITIALIZE COUNT VALUE

     SPIInitialize();                                       // INITIALIZE THE SPI SYSTEM
     
     InitLCD();                                             // INITIALIZE THE LCD 
     
     DIRECTION = 0x00;                                      //INITIALIZE THE SYSTEM IN UP MODE (0=UP,1=DOWN)
     PAUSE = 0x01;                                          //INITIALIZE THE SYSTEM IN PAUSE MODE (0=RUNNING,1=PAUSED)
     COUNT_VALUE = 0;                                       //INITIALIZE COUNTER VALUE TO 0

     TIMER_COUNT = 0;                                       //INITIALIZE TIMER_COUNTER TO ZERO
     
    
}



/********************************************************************/
/* This function enables PLL and use an 8-MHz crystal oscillator to */
/* generate 24-MHz E clock. Same as done in assembler.              */
/********************************************************************/
void SetClk8(void) 
{
     asm(sei);                                              // turn of interrupts
     CLKSEL  &= PLLSEL;                                     // disengage PLL from system
     SYNR    = 0x02;                                        // set SYSCLK to 24 MHz from a 4-MHz oscillator
     REFDV   = 0;                                           //  
     PLLCTL  = 0x40;                                        // turn on PLL, set automatic 
     while(!(CRGFLG & LOCK));                               // wait for HIGN on LOCK bit at address CRGFLG
     asm(nop);                                              // very short delays
     asm(nop);                        
     CLKSEL  |= PLLSEL;                                     // clock derived from PLL
     asm(cli);                                              // turn on interrups
}



/********************************************************************/
/*  This subroutine initializes the SPI system on the HC12S         */
/*                                                                  */
/********************************************************************/
void SPIInitialize(void)
{
     SPIB = 0x22;                                           //SPI CLOCKS A 1/24 OF E-CLOCK
     DDRM = 0x3B;                                           //SETUP PORTM DATA DIRECTION
     SPCR1 = 0x50;                                          //ENABLE SPI AND SET MODE AS MASTER
     SPCR2 = 0x00;                                          //RESETS SPCR2 TO $00 (ALSO DOES AT RESET)
     PORTM = PORTM | RCK;                                   //SET RCK TO IDLE HIGH
     PORTM = PORTM & ~ENABLE;                               //ENABLE TO IDLE LOW
}



/********************************************************************/
/*  This subroutine initializes the LCD screen                      */
/*                                                                  */
/********************************************************************/
void InitLCD(void)                                          //Cheap and dirty method to initialize LCD
{
	Command(0x30);                                         //Call command method with 0x30
	delay3();                                              //Allow the command to take place
	Command(0x30);                                         //Call command method with 0x30
	delay3();                                              //Allow the command to take place
	Command(0x30);                                         //Call command method with 0x30
	delay3();                                              //Allow the command to take place
	Command(0x38);                                         //Call command method with 0x38
	delay3();                                              //Allow the command to take place
	Command(0x0C);                                         //Call command method with 0x0C
	Clear();                                               //Clear the homescreen
}                                                           



/*********************************************************************************/
/*                                                                               */
/* The getkey functions gets the key value from a 4X4 matrix keypad connected    */
/* PortT. Rows (0,1,2,3) = P4,P5,P6,P7                                           */
/*     Columns (0,1,2,3) = P0,P1,P2,P3                                           */
/* The strategy used here is nessted if -else statements and is similar to what  */
/* we did in assembly language. There are more efficient and elegant strategies. */
/*                                                                               */
/*********************************************************************************/
char getkey(void)
{                                                           // We test the keys in sequence - row 0 columns 0,1,2,3
                                                            // row 2 columns 0,1,2,3 etc. until we have checked
   char keyX;                                               // all of the keys. If a key is pressed then we save the 
                                                            // value in keyX and jump down to return without
                                                            // checking any more keys.  Note that there many
                                                            // more ways to do this.

   PORTT = 0x00;                                            // clear portT
   asm(NOP);                                                // short wait times with assembler NOP
   PORTT |= 0x10;                                           // PORTT = PORTT | 0x10; OR PORTT with $10. ie. set row 0 (PT4) High
   asm(nop);
   asm(nop);
   asm(nop);
   
   if(PORTT & BIT0)                                         // AND PORT with 0x01 and check if ans is 1 (TRUE). ie. Check column 0 for HIGH. If High
           keyX = 1;                                        // then set keyX to 1 and jump to return.
   else if(PORTT & BIT1)                                    // Check column 1
           keyX = 2;
   else if(PORTT & BIT2)                                    // Check column 2
           keyX = 3;
   else if(PORTT & BIT3)                                    // Check column 3
           keyX = 10;
   else {
          PORTT = 0x00;                                     // Clear PortT and start on row 1
          PORTT |= 0x20;                                    //  Set row 1 High
          asm(nop);
          asm(nop);
          asm(nop);
   
          if(PORTT & BIT0)                                  // Check column 0 etc., etc.
           keyX = 4;
          else if(PORTT & BIT1) 
           keyX = 5;
          else if(PORTT & BIT2) 
           keyX = 6;
          else if(PORTT & BIT3) 
           keyX = 11;
          else {
              PORTT = 0x00;
              PORTT |= 0x40;                                // row 2 High
              asm(nop);
              asm(nop);
              asm(nop);
   
              if(PORTT & BIT0) 
                keyX = 7;
              else if(PORTT & BIT1) 
                keyX = 8;
              else if(PORTT & BIT2) 
                keyX = 9;
              else if(PORTT & BIT3)
                keyX = 12;
              else {
                PORTT = 0x00;
                PORTT |= 0x80;                              // row 3 High
                asm(nop);
                asm(nop);
                asm(nop);
   
                if(PORTT & BIT0) 
                  keyX = 0 ;
                else if(PORTT & BIT1)
                  keyX = 15;
                else if(PORTT & BIT2) 
                  keyX = 14;
                else if(PORTT & BIT3)                       
                  keyX = 13; 
                else                                        // if we get to here ==> no key pressed
                  keyX = 0x1f;                              // nokey signal
              }
          }
   }
   return (keyX);                                           // return the key value
}

/************************************************************/
/*                                                          */
/* Key release routine. Check each coulmn bit. If HIGH wait */
/* until it goes LOW to break out of the while statement.   */
/* Note that we are reading the input register of PortT     */
/* which is at address $0241 and is called (here) PORTTi    */
/*                                                          */
/************************************************************/
void keyrelease(void) 
{          
     //PORTT = 0xf0                                         // Set all rows high (not needed here. Why?)
     while((PORTTi & 0x01));                                // if column 0 is HIGH wait here until LOW 
     while((PORTTi & 0x02));                                // if column 1 is HIGH wait here until LOW 
     while((PORTTi & 0x04));                                // if column 2 is HIGH wait here until LOW 
     while((PORTTi & 0x08));                                // if column 3 is HIGH wait here until LOW  
}



/********************************************************************/
/*  This subroutine creates a small delay which counts clock cycles */
/*                                                                  */
/********************************************************************/
void delay(void)                                            //This will be the delay for LCD commands - count clock cycles
{
     int y = 8000;                                          //Initialize Y as 8000
	int i = 0;                                             //Initialize i as 0
	for(i; i<=y;i++);                                      //Do the delay 8000 times
}                                                           



/********************************************************************/
/*  This is a slightly larger delay than delay(), it uses a nested  */
/*  loop to increase the time spent here                            */
/********************************************************************/
void delay3(void)                                           //This delay has nested while loops - count clock cycles
{
	int y = 0x0F;                                          //Iniialize Y as $0F
	while (y!=0){                                          //Loop while Y!=0
		int x = 0xFFFF;                                   //Initialize X as $FFFF
		while(x!=0){                                      //Loop while X!=0
			x--;                                         //Decrement X
		}
		y--;                                              //Decrement Y
	}
}



/*********************************************************************/
/* The following function creates a time delay which is equal to the */
/* multiple of 1ms. The value passed in k specifies the number of    */
/* milliseconds to be delayed.                                       */
/*********************************************************************/
void delayby1ms(int k)                                      // k*1ms delay with embedded key press check
{
     /* Standard Timer Setup */
	int ix;
	
	TSCR1 = 0x90;                                          /* enable TCNT and fast timer flag clear */
	TSCR2 = 0x06;                                          /* disable timer interrupt, set prescaler to 64 */
	TIOS  |= BIT0;                                         /* enable OC0 */
	TFLG1 &= BIT0;                                         /* clear timer flag OC0F*/
	TC0 = TCNT + 375;                                      /* add 375 to the tcount*/

	for(ix = 0; ix < k; ix++)                              // Do this loop k times. Where k*1ms is the ~time wait we need. Not necessarily 1 second.
	{
	     while(!(TFLG1 & BIT0));                           // ASM==> Here BRCLR TFLAG1, $01, Here
		TC0 += 375;                                       // If we get here TFLAG1's BIT0 became HIGH
     }
	TIOS  &= (~BIT0);                                      /* disable OC0  and exit.  note no return statement required*/
}



/********************************************************************/
/*  This function clears the LCD screen                             */
/*                                                                  */
/********************************************************************/
void Clear(void)                                            //Clears the LCD screen
{
	Command(0x01);                                         //Sends the clear command to LCD
	delay();                                               //Allows the command to go through
	delay();                                               //Allows the command to go through
}


     
/********************************************************************/
/*  This subroutine sends a command to the LCD, for example to move */
/*  the cursor to the beginning of the screen                       */
/********************************************************************/
void Command(char a)                                        //Method to send commands to LCD via SPI to SIPO system
{
	while(!(SPISR & 0x20));                                //Wait for register empty flag (SPIEF)
	SPIDR = a;                                             //Output command via SPI to SIPO
	while(!(SPISR & 0x80));                                //Wait for SPI Flag
	a = SPIDR;                                             //Equate a with SPIDR
	asm(nop);                                              //Wait for 1 cycle
	PORTM &= ~RCK;                                         //Pulse RCK
	asm(nop);                                              //Wait for 1 cycle
	asm(nop);                                              //Wait for 1 cycle
	PORTM |= RCK;                                          //Command now available for LCD
	PORTM &= ~RS;                                          //RS = 0 for commands
	asm(nop);                                              //Wait for 1 cycle
	asm(nop);                                              //Wait for 1 cycle
	asm(nop);                                              //Wait for 1 cycle
	PORTM |= ENABLE;                                       //Fire ENABLE
	asm(nop);                                              //Wait for 1 cycle
	asm(nop);                                              //Wait for 1 cycle
	PORTM &= ~ENABLE;                                      //ENABLE off
	delay();                                               //Delay
	delay();                                               //Delay
}



/********************************************************************/
/*  This subroutine prints an ASCII character to the screen         */
/*                                                                  */
/********************************************************************/
void Print(char a)                                          // Method to send data to LCD via SPI to SIPO system
{
	while(!(SPISR & 0x20));                                //Wait for register empty flag (SPIEF)
	SPIDR = a;                                             //Output command via SPI to SIPO
	while(!(SPISR & 0x80));                                //Wait for SPI Flag
	a = SPIDR;                                             //Equate a with SPIDR
	asm(nop);                                              //Wait for 1 cycle
	PORTM &= ~RCK;                                         //Pulse RCK
	asm(nop);                                              //Wait for 1 cycle
	asm(nop);                                              //Wait for 1 cycle
	PORTM |= RCK;                                          //Command now available for LCD
	PORTM |= RS;                                           //RS = 1 for data
	asm(nop);                                              //Wait for 1 cycle
	asm(nop);                                              //Wait for 1 cycle
	asm(nop);                                              //Wait for 1 cycle
	PORTM |= ENABLE;                                       //Fire ENABLE
	asm(nop);                                              //Wait for 1 cycle
	asm(nop);                                              //Wait for 1 cycle
	PORTM &= ~ENABLE;                                      //ENABLE off
	delay();                                               //Delay
	delay();                                               //Delay
}



/********************************************************************/
/*  This function updates the display by printing characters and    */
/*  Commands to it                                                  */
/********************************************************************/
void updateDisplay(void)
{
     //CLEAR THE DISPLAY
     Clear();                                               //Clear the display
     
     //Set to home position
     Command(0x02);                                         //Move cursor to home positioin
     
	// display Run/Pause
	if (PAUSE == 0x01) {
	     Print(0x50);                                      //Print a "P"
	     Print(0x41);                                      //Print a "A"
	     Print(0x55);                                      //Print a "U"
	     Print(0x53);                                      //Print a "S"
	     Print(0x45);                                      //Print a "E"
	     Print(0x44);                                      //Print a "D"     
	     Print(0x20);                                      //Print a " "  
	} else {
	     Print(0x52);                                      //Print a "R"
	     Print(0x55);                                      //Print a "U"
	     Print(0x4E);                                      //Print a "N"
	     Print(0x4E);                                      //Print a "N"
	     Print(0x49);                                      //Print a "I"
	     Print(0x4E);                                      //Print a "N"     
	     Print(0x47);                                      //Print a "G"     
	}
	
	// display Direction (up/down)
	if (DIRECTION == 0xFF) {
	     //COUNT DOWN
	     Print(0x20);                                      //Print a " "  
	     Print(0x20);                                      //Print a " "  
	     Print(0x20);                                      //Print a " "  
	     Print(0x20);                                      //Print a " "  
	     Print(0x20);                                      //Print a " "  
	     Print(0x44);                                      //Print a "D"  
	     Print(0x4F);                                      //Print a "O"  
	     Print(0x57);                                      //Print a "W"
	     Print(0x4E);                                      //Print a "N"     
	} else {
	     //COUNT UP
	     Print(0x20);                                      //Print a " "  
	     Print(0x20);                                      //Print a " "  
	     Print(0x20);                                      //Print a " "  
	     Print(0x20);                                      //Print a " "  
	     Print(0x20);                                      //Print a " "  
	     Print(0x20);                                      //Print a " "  
	     Print(0x20);                                      //Print a " "  
	     Print(0x55);                                      //Print a "U"
	     Print(0x50);                                      //Print a "P"
     }

	Command(0xC0);								     //NEW LINE
	
	displayNumber();								//DISPLAY NUMBERs in LCD
}

/********************************************************************/
/*  This function allows the user to enter a new number.  The       */
/*  number entered, will appear in the ones place on the display    */
/********************************************************************/
void insertNumber(char USER_NUMBER)
{
     COUNT_VALUE = 10 * (COUNT_VALUE % 10);                 //Take ones digit and multiply it by 10, store in countval
     
     COUNT_VALUE = COUNT_VALUE + USER_NUMBER;               //Add user entered num to count_val
}



/********************************************************************/
/*  This sub displays the number that the count is currently at.    */
/*                                                                  */
/********************************************************************/
void displayNumber(void)
{
     int i;                                                 //declare integer i
     for(i=0; i<14;i++)                                     //loop 14 times 
     {
          Print(0x20);                                      //Print a " "   (space)
     }
	     
     Print((COUNT_VALUE/10)+0x30);                          //Print tens digit
     
     Print(COUNT_VALUE % 10+0x30);                          //Print ones digit
}

/********************************************************************/
/*  This sub does the blinking for use when we reach 00             */
/*                                                                  */
/********************************************************************/
void blink(void)
{
     int t;                                                 //declare integer t
     for(t=0; t<3;t++)                                      //loop through 3 times
     {
          Command(0x08);								//TURN LCD OFF
          delayby1ms(1000);                                 //DELAY FOR A SEC
          Command(0x0C);                                    //TURN LCD ON
          delayby1ms(1000);                                 //DELAY FOR A SEC
     }
}