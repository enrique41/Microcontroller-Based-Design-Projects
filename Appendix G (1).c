/*****************************************************************************************/
/*                                                                                       */
/*  Appendix G: Vector Table Template in C for the HCS12 (Used in CodeWarrior)           */
/*                                                                                       */
/*  Three function prototype are given: tch5ISR,irqISR, and rtiISR                       */
/*  You must also include the #pragma lines, the UnimplementedISR interrupt routine,     */
/*  the typedef line and the tisFunc_vect[] table. You can delete contiguous table lines */
/*  to reduce the table but you will need to adjust the start addres from @0xFF80 to     */
/*  the new start lines. Since this is an array definition the referenced addresses      */
/*  must be contiguous.  Complete example given at the end of this file                  */
/*                                                                                       */
/*****************************************************************************************/


#include <hidef.h>           /* common defines and macros */
#include "derivative.h"      /* derivative-specific definitions */

// 
// interrupt function prototypes
//
extern void near tc5ISR(void);            // tc5ISR() is in a different file
extern void near irqISR(void);           // irqISR() is in a different file
extern void near rtiISR(void);           // rtiISR() is in a different file
extern void near UnimplementedISR(void); //
//
// put the function name of your interrupt handler into this constant array below
// at the ISR location that you want
// 
#pragma CODE_SEG __NEAR_SEG NON_BANKED /* interrupt section for this module. placement
                                        will be in NON_BANKED area. */
// 
// 
interrupt void  UnimplementedISR(void) 
{
      for(;;);    // do nothing. simply return
}
//
//
#pragma CODE_SEG DEFAULT       // change code section to default
typedef void (*near tIsrFunc) (void);
const tIsrFunc _vect[] @0xFF80 = {
/* complete interrupt table. Only change the names for interrupts your code will use.
   Leave unused interrupts labled as UnimplementedIRS so that they will be handeled 
   by the UnimpletementedISR function code above */
       UnimplementedISR,        // 0xFF80 reserved
       UnimplementedISR,        // 0xFF82 reserved
       UnimplementedISR,        // 0xFF84 reserved
       UnimplementedISR,        // 0xFF86 reserved
       UnimplementedISR,        // 0xFF88 reserved
       UnimplementedISR,        // 0xFF0a reserved
       UnimplementedISR,        // 0xFF8c PWM emergency shutdown
       UnimplementedISR,        // 0xFF8e port P
       UnimplementedISR,        // 0xFF90 reserved
       UnimplementedISR,        // 0xFF92 reserved
       UnimplementedISR,        // 0xFF94 reserved
       UnimplementedISR,        // 0xFF96 reserved
       UnimplementedISR,        // 0xFF98 reserved
       UnimplementedISR,        // 0xFF9a reserved
       UnimplementedISR,        // 0xFF9c reserved
       UnimplementedISR,        // 0xFF9e reserved
       UnimplementedISR,        // 0xFFa0 reserved
       UnimplementedISR,        // 0xFFa2 reserved
       UnimplementedISR,        // 0xFFa4 reserved
       UnimplementedISR,        // 0xFFa6 reserved
       UnimplementedISR,        // 0xFFa8 reserved
       UnimplementedISR,        // 0xFFaa reserved
       UnimplementedISR,        // 0xFFac reserved
       UnimplementedISR,        // 0xFFae reserved
       UnimplementedISR,        // 0xFFb0 CAN0 transmit
       UnimplementedISR,        // 0xFFb2 CAN0 receive
       UnimplementedISR,        // 0xFFb4 CAN0 errors
       UnimplementedISR,        // 0xFFb6 CAN0 wake-up
       UnimplementedISR,        // 0xFFb8 flash
       UnimplementedISR,        // 0xFFba EEPROM
       UnimplementedISR,        // 0xFFbc reserved
       UnimplementedISR,        // 0xFFbe reserved
       UnimplementedISR,        // 0xFFc0 IIC bus
       UnimplementedISR,        // 0xFFc2 BDLC
       UnimplementedISR,        // 0xFFc4 CRG self clock mode
       UnimplementedISR,        // 0xFFc6 CRG PLL lock
       UnimplementedISR,        // 0xFFc8 pulse accumulator B overflow
       UnimplementedISR,        // 0xFFca modulus down counter underflow
       UnimplementedISR,        // 0xFFcc portH
       UnimplementedISR,        // 0xFFce portJ
       UnimplementedISR,        // 0xFFd0 ATD1
       UnimplementedISR,        // 0xFFd2 ATD0
       UnimplementedISR,        // 0xFFd4 SCI1
       UnimplementedISR,        // 0xFFd6 SCI0
       UnimplementedISR,        // 0xFFd8 SPIO
       UnimplementedISR,        // 0xFFda pulse accumulator input edge
       UnimplementedISR,        // 0xFFdc pulse accumulator A overflow
       UnimplementedISR,        // 0xFFde timer overflow
       UnimplementedISR,        // 0xFFE0 timer Ch7
       UnimplementedISR,        // 0xFFE2 timer Ch6
       tc5ISR,                  // 0xFFE4 timer Ch5
       UnimplementedISR,        // 0xFFE6 timer Ch4
       UnimplementedISR,        // 0xFFE8 timer Ch3
       UnimplementedISR,        // 0xFFEA timer Ch2
       UnimplementedISR,        // 0xFFEC timer Ch1
       UnimplementedISR,        // 0xFFEE timer Ch0
       rtiISR,                  // 0xFFF0 real time interrupt
       irqISR,                  // 0xFFF2 IRQ
       UnimplementedISR,        // 0xFFF4 XIRQ
       UnimplementedISR,        // 0xFFF6 swi
       UnimplementedISR,        // 0xFFF8 unimplemented instruction trap
       UnimplementedISR,        // 0xFFFA COP fail reset 
       UnimplementedISR,        // 0xFFFC clock monitor fail reset
 /* _startup, by default in library. So, DO NOT INCLUDE HERE! 0xFFFE reset vector*/
};

//  Need a few variables for the example
//
volatile unsigned char Flag1 = 0x00, Flag2 = 0x01, HiorLo = 0x00;
volatile unsigned int HiCnt = 50000, LoCnt =20000;
 
void main(void) {

   // put some code here

	EnableInterrupts;  // same as  asm(cli);


  for(;;) {
    _FEED_COP(); /* feeds the dog */
  }              /* loop forever */
                 /* please make sure that you never leave main */
}                /* else bad things may happen.*/

/********************************************************************/
/*                                                                  */
/*  Typical interrupt function code will look something like this:  */
/*                                                                  */
//
interrupt void rtiISR(void)                                    
{                                                              
     Flag1 = ~Flag1;   // complement Flag1                      
}                                                              
                                                               
                                                               
interrupt void irqISR(void)                                    
{                                                              
      Flag2 = ~Flag2;   // complement Flag2                   
}                                                             
                                                              
interrupt void tc5ISR (void)                                 
{                                                              
  	 if(HiorLo)                                                
       {                                                       
      	 	TC5 += HiCnt;                                        
       		HiorLo = 0;                                          
    	 }                                                       
     else                                                      
       {                                                       
      	 	TC5 += LoCnt;                                        
      		HiorLo = 1;                                          
    	 }                                                       
 }                                                             
                                                                   
/******************************************************************************************/
/*                                                                                        */
/*                                                                                        */
/*    Complete Example Using two noncontiguous interrupts                                 */
/*                                                                                        */
/*    extern void near tch5ISR(void)           // tch5ISR() prototype                     */
/*    extern void near irqISR(void);           // irqISR()  prototype                     */
/*    #pragma CODE_SEG_NEAR_SEG NON_BANKED     // required pragma                         */
/*    _interrupt void UnimplementedISR(void)   // required for unimplemented interrupts   */
/*    {                                                                                   */
/*         for(;;);    // do nothing. simply return                                       */
/*    }                                                                                   */
/*                                                                                        */
/*                                                                                        */
/*    #pragma CODE_SEG DEFAULT                 // required pragma                         */
/*    typedef void (*near tisFunc(void);       // required typedef                        */
/*    const tisFunc_vect[] @0xFFE4 = {         // vector array setup                      */
/*       tch5ISR,                 // 0xFFE4 timer Ch5  // interrupt to use                */
/*       UnimplementedISR,        // 0xFFE6 timer Ch4  // contiguous unused interrupts    */
/*       UnimplementedISR,        // 0xFFE8 timer Ch3  // must be accounted for           */
/*       UnimplementedISR,        // 0xFFEA timer Ch2                                     */
/*       UnimplementedISR,        // 0xFFEC timer Ch1                                     */
/*       UnimplementedISR,        // 0xFFEE timer Ch0                                     */
/*       UnimplementedISR,        // 0xFFF0 real time interrupt                           */
/*       irqISR,                  // 0xFFF2 IRQ        // interrupt to use                */
/*    }                                                                                   */
/*                                                                                        */
/*    // Your main code and functions...                                                  */
/*    //                                                                                  */
/*    // Now some interrupt function code                                                 */
/*                                                                                        */
/*   interrupt void irqISR(void)                                                          */
/*   {                                                                                    */
/*      Flag2 = ~Flag2   // complement Flag2                                              */
/*   }                                                                                    */
/*                                                                                        */
/*    interrupt void tch5ISR (void)                                                       */
/*   {                                                                                    */
/*  	 if(HiorLo)                                                                         */
/*       {                                                                                */
/*      	 	TC5 += HiCnt;                                                                 */
/*       		HiorLo = 0;                                                                   */
/*    	 }                                                                                */
/*     else                                                                               */
/*       {                                                                                */
/*      	 	TC5 += LoCnt;                                                                 */
/*      		HiorLo = 1;                                                                   */
/*    	 }                                                                                */
/*    }                                                                                   */
/*                                                                                        */
/******************************************************************************************/