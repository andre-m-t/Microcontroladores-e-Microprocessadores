#include <controleTemperatura.h>
#include <lcd_8bits.c>
//constantes
#define canal_temp 0
#define canal_pot  1


//variaveis globais
int1 fim_tempo = 0;
int8 contador = 250;  //1ms*250 = 250ms
int1 processo = 0;
int1 ligar_fan = 0;
int16 histerese = 10;
int16 potenciometro, temperatura;
//declaracao de funcoes
void leiturasAnalogicas();


//espaco reservado para interrupcao
#INT_TIMER0
void  TIMER0_isr(void) 
{
   contador--;
   if(contador == 0){
      fim_tempo = 1;
      contador = 250;
   }   
}
//fim espaco reservado

void main()
{
   //ENTRADAS ANALOGICAS
   setup_adc_ports(AN0_AN1_AN3);
   setup_adc(ADC_CLOCK_INTERNAL);
   setup_timer_0(RTCC_INTERNAL|RTCC_DIV_8|RTCC_8_BIT);      //1,0 ms overflow

   //INTERRUPCAO
   enable_interrupts(INT_TIMER0);
   enable_interrupts(GLOBAL);
   
   //LCD
   lcd_init();
   printf(lcd_write_dat,"Sp:");//setpoint
   lcd_gotoxy(1,2);
   printf(lcd_write_dat,"Tp:");//temperatura
   lcd_gotoxy(9,1);
   printf(lcd_write_dat,"Fn:");//fan
   lcd_gotoxy(9,2);
   printf(lcd_write_dat,"Ht:");//heater
   lcd_gotoxy(15,2);
   printf(lcd_write_dat,"Of");//processo
   lcd_gotoxy(12,1);
   printf(lcd_write_dat,"Of");//fan
   lcd_gotoxy(12,2);
   printf(lcd_write_dat,"Of");//heater


   while(TRUE)
   {
      if(fim_tempo)
         leiturasAnalogicas();
      if(input_state(B_LIGA) == 0)
         processo = 1;
      if(input_state(B_DESL) == 0) {  
         processo = 0;
         ligar_fan = 0;
         output_low(HEATER);
         output_low(FAN);
      }
      if(processo){
         lcd_gotoxy(15,2);
         printf(lcd_write_dat,"On");//processo
         //temperatura menor que a setada
         if((temperatura+histerese) < potenciometro){
            output_high(HEATER);
            lcd_gotoxy(12,2);
            printf(lcd_write_dat,"On");//heater
         }
         //temperatura maior que a setada   
         if((temperatura-histerese) > potenciometro){
            output_low(HEATER);
            lcd_gotoxy(12,2);
            printf(lcd_write_dat,"Of");//heater
         }
         if(ligar_fan){
            output_high(FAN);
            lcd_gotoxy(12,1);
            printf(lcd_write_dat,"On");//fan
            if(temperatura <= potenciometro)
               ligar_fan = 0;
         }
         else{
            output_low(FAN);
            lcd_gotoxy(12,1);
            printf(lcd_write_dat,"Of");//fan
         }
         //condicao para ligar o fan    
         if((temperatura-20) > potenciometro)
            ligar_fan = 1;
         
      }else{
         lcd_gotoxy(15,2);
         printf(lcd_write_dat,"Of");//processo
         lcd_gotoxy(12,1);
         printf(lcd_write_dat,"Of");//fan
         lcd_gotoxy(12,2);
         printf(lcd_write_dat,"Of");//heater
      }
      //TODO: User Code
   }

}

void leiturasAnalogicas(){
   fim_tempo = 0;
   //adc temperatura
   set_adc_channel(canal_temp);
   delay_us(40);
   temperatura = read_adc();
   lcd_gotoxy(4,2);
   printf(lcd_write_dat,"%4lu",temperatura);//setpoint
   //adc potenciometro
   set_adc_channel(canal_pot);
   delay_us(40);
   potenciometro = read_adc();
   lcd_gotoxy(4,1);
   printf(lcd_write_dat,"%4lu",potenciometro);//setpoint
   return;
}

