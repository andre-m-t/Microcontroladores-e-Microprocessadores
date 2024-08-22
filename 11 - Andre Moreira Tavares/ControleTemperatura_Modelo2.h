#include <16F877A.h>
#device ADC=10

#FUSES PUT                      //Power Up Timer
#FUSES NOBROWNOUT               //No brownout reset
#FUSES LVP                      //Low Voltage Programming on B3(PIC16) or B5(PIC18)
#FUSES NOCPD                    //No EE protection
#FUSES NOWRT                    //Program memory not write protected
#FUSES NOPROTECT                //Code not protected from reading

#use delay(crystal=8MHz)


#use fixed_io(c_outputs=PIN_C2, PIN_C1)

#define  B_LIGA_DESL    PIN_B0
#define  B_DEC_HIST     PIN_B1
#define  B_INC_HIST     PIN_B2
#define  B_TROCA_INFO   PIN_B3
#define  HEATER         PIN_C2
#define  FAN            PIN_C1

