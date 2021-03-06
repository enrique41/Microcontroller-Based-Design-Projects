/*************************************************************************************************/
/*                                                                                               */
/* C Progrmming example 2 for ECE 367                                                             */
/*                                                                                               */
/* Prepared by Robert Becker                                                                     */
/* November 25, 2012                                                                             */
/*                                                                                               */
/* Functions included: getkey, keyrelease, delayby1ms,                                           */
/* SetClk8 (PLL setup for 24mHz from 8mHz systems)                                               */
/* Includes array examples and interrupt example.                                                */
/*                                                                                               */
/* Also includes many C programming general examples.                                            */
/*                                                                                               */
/* Program gets a value from the keypad and displays it as 4-bit binary on Port M pins PM5,4,3,2 */
/* If a flag Flag1 is set (by interrupt request from IRQ) then the key value (if decimal 0 - 9)  */
/* is displayed on a seven segment display driven by an 8-bit latch.                             */
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
/* #define PORTT *(unsigned char  volatile *) (0x240);    Means PORTT points to address $0240        */
/* the statement PORTT = 0x34; means to store $34 at location $0240                                  */
/* if the contents of PORTT is 0xd3 then the assignment x = PORTT; means x is now equal to 0xd3      */
/*****************************************************************************************************/
#define   PORTTi     _IO8(0x241)    // portT data register
#define   IRQCR      _IO8(0x001E)
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


// Let's define some bit locations for some flags and config bits
#define     PLLSEL  0x80
#define     LOCK    0x08
#define     TFFCA   0x10
#define     MCZF    0x80
#define     BIT0    0x01
#define     BIT1    0x02
#define     BIT2    0x04
#define     BIT3    0x08


// Prototype for IRQ Interrupt Service Routine function named irqISR
// The next five lines are required
// Change the name for other interrupts 
extern void near irqISR(void);
#pragma CODE_SEG __NEAR_SEG NON_BANKED


#pragma CODE_SEG DEFAULT               // Change code section to DEFAULT.

typedef void (*near tIsrFunc)(void);

const tIsrFunc _vect[] @0xFFF2 = {      
    	irqISR                   // change Vector address and name to use other interrupts
};                             // This format is for a single interrupt system
                               // See appendix G if you are going to use more than one interrupt
                               // for your system
                               // See the bottom of this code for the actual irqIRS code

// Next we have an array. This is the same as a lookup table in assembler. The "const" (constant) type
// means to store into ROM not RAM memory. The array is for 7-seg display patterns of decimal digits
// 0 - 9. Note the last value in the array will clear the 7-seg display (it's 0x00)                                

const unsigned char segpat[11] = {0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x67,0x00};

// Make Flag1 an 8-bit character variable. Initialize Flag1 to 0x00. 
char  Flag1 = 0x00;                 

/* Here we give function prototypes before we start on the main code */  
void SetClk8(void); 
void delayby1ms(int k);
char getkey(void);
void keyrelease(void);
void outdata(char);

/* The main program begins here */

void main(void) 
{
  /* put your own code here */
  /* Below is a simple program example that sets up the PLL to 24mHz,          */
  /* gets a value from the keypad and displays it in binary on portM           */
  /* pins PM6, PM5, PM4, and PM3. There is some delay required and,            */
  /* of course, a key release routine. Does not seem to be any key bounce.     */
  /* If Flag1 is 0x01 then we should also display the key (if 0-9) on a 7-seg  */
  /* display. The latch enable line is PM0. Since it is a control line we must */
  /* take care not to let PM0 go HIGH accidentally.                            */
  /* Hence the  PORTM = (key1<<2) & ~0x01 ; statement.                         */
  
    char key1;                // define key1 as 8-bit character
 
    SetClk8();                // go setup the PLL
        
    DDRM = 0xfd;              // setup the data direction registers
    DDRT = 0xf0;
    PORTM = 0x00;             // clear PortM
    IRQCR = 0xC0;             // enable IRQ with falling edge trigger          
  
   
          while(1)                  // this is and infinite while loop
    {       
          PORTM = 0;
          outdata(0x0a);
          delayby1ms(100);
          key1  = getkey();    // go get a key 
          if(key1 < 0x1f) 
          {    // did we get a key? If so, do the next three statements to display the binary value
             PORTM = (key1<<2) & ~0x01 ; // shift data left twice and output to see it on PM2,3,4,5 pins
             keyrelease();      // wait for key release
             delayby1ms(2000);   // wait a bit - 200 X 1ms = 0.2 sec 
           if((Flag1 == 0x01) & (key1 < 0x0a))  //  When Flag1 = 0 display the key in decimal
               {
                outdata(key1); 
                delayby1ms(3000);
               }
           } 
                              // if we get here without executing the above statemets (after the 1st if)
                              // then no key was pressed. so, do not do any output just
                              // go back to the beginning of the while [statement PORTM = 0;]
                              // and repeat all
    } 
 

	EnableInterrupts;  // same as  asm(cli);


  for(;;) {
    _FEED_COP(); /* feeds the dog */
  }              /* loop forever */
                 /* please make sure that you never leave main */
}                /* else bad things may happen.*/

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
{                     // We test the keys in sequence - row 0 columns 0,1,2,3
                      // row 2 columns 0,1,2,3 etc. until we have checked
   char keyX;         // all of the keys. If a key is pressed then we save the 
                      // value in keyX and jump down to return without
                      // checking any more keys.  Note that there many
                      // more ways to do this.

   PORTT = 0x00;      // clear portT
   asm(NOP);          // short wait times with assembler NOP
   PORTT |= 0x10;     // PORTT = PORTT | 0x10; OR PORTT with $10. ie. set row 0 (PT4) High
   asm(nop);
   asm(nop);
 
   if(PORTT & BIT0)   // AND PORT with 0x01 and check if ans is 1 (TRUE). ie. Check column 0 for HIGH. If High
           keyX = 1;  // then set keyX to 1 and jump to return.
   else if(PORTT & BIT1)  // Check column 1
           keyX = 2;
   else if(PORTT & BIT2)  // Check column 2
           keyX = 3;
   else if(PORTT & BIT3)  // Check column 3
           keyX = 10;
   else {
          PORTT = 0x00;    // Clear PortT and start on row 1
          PORTT |= 0x20;   //  Set row 1 High
          asm(nop);
          asm(nop);
 
          if(PORTT & BIT0) // Check column 0 etc., etc.
           keyX = 4;
          else if(PORTT & BIT1) 
           keyX = 5;
          else if(PORTT & BIT2) 
           keyX = 6;
          else if(PORTT & BIT3) 
           keyX = 11;
          else {
              PORTT = 0x00;
              PORTT |= 0x40; // row 2 High
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
                PORTT |= 0x80; // row 3 High
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
                else            // if we get to here ==> no key pressed
                  keyX = 0x1f;  // nokey signal
              }
          }
   }
   return (keyX);               // return the key value
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
{          // PORTT = 0xf0;  Usually we need this but not for this case. Why?
           while((PORTTi & 0x01)); // if column 0 is HIGH wait here until LOW 
           while((PORTTi & 0x02)); // if column 1 is HIGH wait here until LOW 
           while((PORTTi & 0x04)); // if column 2 is HIGH wait here until LOW 
           while((PORTTi & 0x08)); // if column 3 is HIGH wait here until LOW  

}

/*********************************************************************/
/* The following function creates a time delay which is equal to the */
/* multiple of 1ms. The value passed in k specifies the number of     */
/* milliseconds to be delayed.                                       */
/*********************************************************************/
void delayby1ms(int k)
{
     int ix;
     TSCR1 = 0x90;      /* enable TCNT and fast timer flag clear */
     TSCR2 = 0x06;      /* disable timer interrupt, set prescaler to 64 */
     TIOS  |= BIT0;     /* enable OC0 */
     TFLG1 &= BIT0;     /* clear timer flag OC0F*/
     TC0 = TCNT + 375;
      
     for(ix = 0; ix < k; ix++) {
            while(!(TFLG1 & BIT0)); // ASM==> Here BRCLR TFLAG1, $01, Here
            TC0 += 375;             // If we get here FLAG1's BIT0 became HIGH
         }

     TIOS  &= (~BIT0);  /* disable OC0  and exit.  note no return statement require*/
}

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
void outdata(char keyout) 
{
     DDRM = 0xfd;
     DDRT = 0xff;
     asm(nop);
     asm(nop);
     PORTT = segpat[keyout];
     PORTM |= 0x01;
     asm(nop);
     asm(nop);
     PORTM &= ~0x01;
     asm(nop);
     asm(nop);
     DDRM = 0xfd;
     DDRT = 0xf0;
}

//  Here is the IRQ  interrupt service routine. Note: no RTI required! 
interrupt void irqISR(void)
{
  
       if(Flag1 == 0x00)
         {
           Flag1 = 0x01;
         }
       
       else  Flag1 = 0x00; 
       
       asm(nop);  // not really needed.
}
        