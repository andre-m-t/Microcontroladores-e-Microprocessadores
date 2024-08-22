#include <16F877A.h>
#device ADC=10

#FUSES PUT                      //Power Up Timer
#FUSES NOBROWNOUT               //No brownout reset
#FUSES LVP                      //Low Voltage Programming on B3(PIC16) or B5(PIC18)
#FUSES NOCPD                    //No EE protection
#FUSES NOWRT                    //Program memory not write protected
#FUSES NOPROTECT                //Code not protected from reading

#use delay(crystal=4MHz)

#use fixed_io(b_outputs= PIN_B4, PIN_B5, PIN_B6, PIN_B7)
#use fixed_io(d_outputs= PIN_D0, PIN_D1, PIN_D2, PIN_D3, PIN_D4, PIN_D5, PIN_D6, PIN_D7)

#define d_unidade    PIN_B4
#define d_dezena     PIN_B5
#define d_centena    PIN_B6
#define d_milhar     PIN_B7

