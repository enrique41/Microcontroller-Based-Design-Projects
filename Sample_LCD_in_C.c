/*************************************************************************************************/
/*                                                                                               */
/* C Progrmming examples for ECE 367                                                             */
/*                                                                                               */
/* Prepared by Robert Becker                                                                     */
/* November 20, 2012                                                                             */
/*                                                                                               */
/* Functions included: getkey, keyrelease, delayby1ms,                                           */
/* SetClk8 (PLL setup for 24mHz from 8mHz systems                                                */
/*                                                                                               */
/* Also includes many C programming general examples.                                            */
/*                                                                                               */
/*************************************************************************************************/ 

/* Some include (header) files needed by Codewarrior with machine info for the NanoCore12        */

#include <hidef.h>           /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */

/* We need to define some constants. Similar to EQU's in assembly                                */
/* The commented out defines already exist in one of the above header files. The compiler        */
/* does not like the redundancy. So, they are commented out with the // symbols                  */

#define     IOREGS_BASE  0x0000

#define     _IO8(off)    *(unsigned char  volatile *)(IOREGS_BASE + off) //define form prototype 8-bit
#define     _IO16(off)   *(unsigned short volatile *)(IOREGS_BASE + off) //define form prototype 16-bit


#define   PORTT     _IO8(0x240)     /* portT data register is unsigned 8-bit at address $0240        */
/* because of the form prototype defines above this is the same as                                   */                                                                 
/* #define PORTT (*(unsigned char  volatile *) 0x240);    Means PORTT points to address $0240        */
/* the statement PORTT = 0x34; means to store $34 at location $0240                                  */
/* if the contents of PORTT is 0xd3 then the assignment x = PORTT; means x is now equal to 0xd3      */
/*****************************************************************************************************/
#define   PORTTi     _IO8(0x241)    // portT data register
#define   keypad    PORTT
#define   PORTM     _IO8(0x250)     // portM data register
//#define     TSCR1   _IO8(0x46)     //timer system control register
#define     MCCTL   _IO8(0x66)     //modulus down conunter control
#define     MCFLG   _IO8(0x67)     //down counter flags
#define     MCCNT   _IO16(0x76)    //modulus down counter register
//#define     PTT	  	_IO8(0x240)    //portt data register
//#define     DDRT		_IO8(0x242)    //portt direction register
//#define     CRGFLG  _IO8(0x37)     //pll flags register
//#define     SYNR    _IO8(0x34)     //synthesizer / multiplier register
//#define     REFDV   _IO8(0x35)     //reference divider register
//#define     CLKSEL  _IO8(0x39)     //clock select register
//#define     PLLCTL  _IO8(0x3a)     //pll control register
#define   SPBR     _IO8(0xDA)

// Let's define some bit locations for some flags and config bits
#define     PLLSEL  0x80
#define     LOCK    0x08
#define     TFFCA   0x10
#define     MCZF    0x80
#define     BIT0    0x01
#define     BIT1    0x02
#define     BIT2    0x04
#define     BIT3    0x08
#define     RS      0x01
#define     ENABLE  0x02
#define     RCK     0x08
/* Here we give function prototypes before we start on the main code */

void SetClk8(void); 
void delayby1ms(int k);
void delay(void);
void delay2(void);
void delay3(void);
void InitLCD(void);
void Clear(void);
void Command(char a);
void Print(char a);
void printString(char *string);

/* declare some global variables */

int i;
int j;

/* The main program begins here */

void main(void) {
  /* put your own code here */
  /* Below is a simple program example that sets up the PLL to 24mHz,       */
  /* initializes the LCD and prints some information to the LCD             */
  /* We see some examples of LCD commands                                   */
      
    SetClk8();                  // go setup the PLL
  
  /* Need to initialize the SPI system                                      */
  
    SPIBR = 0x22;               // SPI register
    DDRM = 0x3B;                // control port m direction
    SPICR1 = 0x50;              // spi control register 1 set
    SPICR2 = 0x00;              // spi control register 2 set

  /* Set up some initial control line values                                */

    PORTM |= RCK;               // RCK = Active LOW; bset RCK
    PORTM &= ~ENABLE;           // Enable = Active HIGH; bclr ENABLE
  
  /* Now initialize the LCD                                                 */
  
    InitLCD();   
  
  /* The while construct will allow the code between {} to loop forever     */
  
  while(1){
    
  /* Let's print some strings */
  
  printString("ECE 367   ");
  Command(0xC0);                 // Move cursor to line two
  printString("Spring 2013  ");  
  delay2();                      // Let's show the image for a while
  
  /* Let's blink 4 times */
  
  for(i=0;i<4;i++) {             // Loop to blink 4 times
    Command(0x08);               // Turn off the display but keep the memory values
    delay3();
    Command(0x0C);               // Turn on the display. So, we blinked!
    delay3();
  }
  
  /* Let's clear the display */
  Clear();
	
	 /* Let's print the strings in reverse order and blink 4 times*/
  
  printString("Spring 2013   ");
  Command(0xC0);                 // Move cursor to line two
  printString("ECE 367   ");  
  delay2();                      // Let's show the image for a while
  
  /* Let's blink 4 times */
  
  for(i=0;i<4;i++) {             // Loop to blink 4 times
    Command(0x08);               // Turn off the display but keep the memory values
    delay3();
    Command(0x0C);               // Turn on the display. So, we blinked!
    delay3();
  }
  
 
	/* Let's shift the display right 4 spaces   */
	
	for(i=1;i<=5;i++){
	  Command(0x1C);     // shift right one space
	  delay();           // this command take a bit of time to execute
	  delay();
	}
	 
	 delay2();           // wait a bit
	 
	 
	  /* Let's shift the display left 4 spaces   */
	
	for(i=1;i<=5;i++){
	  Command(0x18);     // shift left one space
	  delay();           // this command take a bit of time to execute
	  delay();
	}
	 
	 delay2();           // wait a bit
	
	/* Let's clear the display and repeat forever  */
	
	Clear();
	
  }



  for(;;) {
    _FEED_COP(); /* feeds the dog */
  }              /* loop forever */
                 /* please make sure that you never leave main */
}                /* else bad things may happen.*/



/********************************************************************/
/* This function enables PLL and use an 8-MHz crystal oscillator to */
/* generate 24-MHz E clock. Same as done in assembler.              */
/********************************************************************/
void SetClk8(void) 
{
    asm(sei);          // turn of interrupts
    CLKSEL  &= PLLSEL; // disengage PLL from system
    SYNR    = 0x02;    // set SYSCLK to 24 MHz from a 4-MHz oscillator
    REFDV   = 0;       //  
    PLLCTL  = 0x40;    // turn on PLL, set automatic 
    while(!(CRGFLG & LOCK)); // wait for HIGN on LOCK bit at address CRGFLG
    asm(nop);          // very short delays
    asm(nop);
    CLKSEL  |= PLLSEL; // clock derived from PLL
    asm(cli);          // turn on interrups
}
        //Sample  Time Delay Functions

void delay(void)     //This will be the delay for LCD commands - count clock cycles
{
	int y = 8000;      //Initialize Y as 8000
	int i = 0;         //Initialize i as 0
	for(i; i<=y;i++);  //Do the delay 8000 times
}

void delay2(void)    // Nested loop for longer time
{
  for(i=0; i<=0xF000; i++){
    for(j=0; j<=0x8F; j++){
    }
  }
}
void delay3(void)    //This delay has nested while loops - count clock cycles
{
	int y = 0x0F;      //Iniialize Y as $0F
	while (y!=0){      //Loop while Y!=0
		int x = 0xFFFF;  //Initialize X as $FFFF
		while(x!=0){     //Loop while X!=0
			x--;           //Decrement X
		}
		y--;             //Decrement Y
	}
}



void delayby1ms(int k)  // k*1ms delay with embedded key press check
{
/* Standard Timer Setup */
	int ix;
	TSCR1 = 0x90;      /* enable TCNT and fast timer flag clear */
	TSCR2 = 0x06;      /* disable timer interrupt, set prescaler to 64 */
	TIOS  |= BIT0;     /* enable OC0 */
	TFLG1 &= BIT0;     /* clear timer flag OC0F*/
	TC0 = TCNT + 375;  /* add 375 to the tcount*/
	

	for(ix = 0; ix < k; ix++) // Do this loop k times. Where k*1ms is the ~time wait we need. Not necessarily 1 second.
	{
		while(!(TFLG1 & BIT0)); // ASM==> Here BRCLR TFLAG1, $01, Here
		TC0 += 375;             // If we get here TFLAG1's BIT0 became HIGH
	}
	
	
	TIOS  &= (~BIT0);  /* disable OC0  and exit.  note no return statement require*/
}

void InitLCD(void)   // Method to initialize LCD
{ delay3();          // These time delays work
  Command(0x30);     // but could be shortened a bit
  delay3();                       
  Command(0x30);                     
  delay3();
  Command(0x30);
  Command(0x38);     // Call command method with 0x38
	delay3();          // Allow the command to take place
	Command(0x0C);     // Call command method with 0x0C
	Clear();           // Clear the homescreen
  delay();
}



void Clear(void)          // Clears the LCD screen
{
	Command(0x01);          // Sends the clear command to LCD
	delay();                //Allows the command to go through
  delay();                //needs longer delay - probably too loon
  delay();
}

void Command(char a)      //Method to send commands to LCD via SPI to SIPO system
{
	while(!(SPISR & 0x20)); //Wait for register empty flag (SPIEF)
	SPIDR = a;              //Output command via SPI to SIPO
	while(!(SPISR & 0x80)); //Wait for SPI Flag
	a = SPIDR;              //Equate a with SPIDR
	asm(nop);               //Wait for 1 cycle
	PORTM &= ~RCK;          //Pulse RCK
	asm(nop);               //Wait for 1 cycle
	asm(nop);               //Wait for 1 cycle
	PORTM |= RCK;           //Command now available for LCD
	PORTM &= ~RS;           //RS = 0 for commands
	asm(nop);               //Wait for 1 cycle
	asm(nop);               //Wait for 1 cycle
	asm(nop);               //Wait for 1 cycle
	PORTM |= ENABLE;        //Fire ENABLE
	asm(nop);               //Wait for 1 cycle
	asm(nop);               //Wait for 1 cycle
	PORTM &= ~ENABLE;       //ENABLE off
	delay();                //Delay
}

void Print(char a)   // Method to send data to LCD via SPI to SIPO system
{
	while(!(SPISR & 0x20)); //Wait for register empty flag (SPIEF)
	SPIDR = a;              //Output command via SPI to SIPO
	while(!(SPISR & 0x80)); //Wait for SPI Flag
	a = SPIDR;              //Equate a with SPIDR
	asm(nop);               //Wait for 1 cycle
	PORTM &= ~RCK;          //Pulse RCK
	asm(nop);               //Wait for 1 cycle
	asm(nop);               //Wait for 1 cycle
	PORTM |= RCK;           //Command now available for LCD
	PORTM |= RS;            //RS = 1 for data
	asm(nop);               //Wait for 1 cycle
	asm(nop);               //Wait for 1 cycle
	asm(nop);               //Wait for 1 cycle
	PORTM |= ENABLE;        //Fire ENABLE
	asm(nop);               //Wait for 1 cycle
	asm(nop);               //Wait for 1 cycle
	PORTM &= ~ENABLE;       //ENABLE off
	delay();                //Delay
}

/* printStringPrint determines the number of characters in the string so that we can    */
/* send the correct number of characters to the LCD print command.                      */
/* Then, the characters are printed. There are built in functions in the string.h       */
/* library but we are not using that library. So, we will use this home made function.  */
/* Not pretty but it works.                                                             */

void printString(char *string)
{
    int i, n;
    const char *tmp = string;
    
    // NOTE: does NOT check for string == NULL

    while(*tmp != '\0') {      // C strings end with \0
        tmp++;
    }
    n = tmp - string;         // OK. Now we know how many characters to print
    
    for(i=0; i<n; i++) {
        Print(string[i] );    // Call LCD print command
    }
}
