#include <leituraanalogica.h>
//constantes
#define vl_cont1 250    //2ms*250 = 500ms
#define vl_cont2 10    //500ms*10 = 5000ms -> 5s

#define canal_temp 0
#define canal_pot  1

//variaveis globais
int1 fim_2ms = 0;
int1 fim_500ms = 0;
int1 fim_5s = 0;
int1 mostrarPot = 1;
int8 cont1 = vl_cont1;
int8 cont2 = vl_cont2;
char codigo[10] = {0b00111111,0b00000110,0b01011011,0b01001111,0b01100110,0b01101101,0b01111101,0b00000111,0b01111111,0b01101111}; //c�digo para aparecer nodisplay
int8 unidade, dezena, centena, milhar;
int16 potenciometro, temperatura;

//declaracao de funcoes
void varrerDisplay();
void leiturasAnalogicas();
void mostrarDisplay();
void quebrarNumero(int16 valor);
//espaco reservado para interrupcao
#INT_TIMER0
void  TIMER0_isr(void) 
{
   fim_2ms = 1;
   cont1--;
   if(cont1 == 0){
      cont1 = vl_cont1;
      fim_500ms = 1;
      cont2--;
      if(cont2 == 0){
         cont2 = vl_cont2;
         fim_5s = 1;
      }
   }   
   
}

void main()
{
   setup_adc_ports(AN0_AN1_AN3);
   setup_adc(ADC_CLOCK_INTERNAL);
   setup_timer_0(RTCC_INTERNAL|RTCC_DIV_8|RTCC_8_BIT);      //2,0 ms overflow


   enable_interrupts(INT_TIMER0);
   enable_interrupts(GLOBAL);
   
   
   //iniciar com valor do pot
   leiturasAnalogicas();
   quebrarNumero(potenciometro);

   while(TRUE)
   {
      if(fim_2ms)
         varrerDisplay();
      if(fim_500ms)
         leiturasAnalogicas();
      if(fim_5s)
         mostrarDisplay();
   }

}
void mostrarDisplay(){
   fim_5s = 0;
   if(mostrarPot){
      mostrarpot = 0;
      quebrarNumero(potenciometro);

   }else{
      mostrarPot = 1;
      quebrarNumero(temperatura);
   }
   return;
}

void quebrarNumero(int16 valor){
   milhar = valor/1000;
   if(milhar > 0)
      valor = valor - 1000;
   centena = valor/100;
   switch(centena){
      case 1:
         valor = valor -100;
         break;
      case 2:
         valor = valor -200;
         break;
      case 3:
         valor = valor -300;
         break;
      case 4:
         valor = valor -400;
         break;
      case 5:
         valor = valor -500;
         break;
      case 6:
         valor = valor -600;
         break;
      case 7:
         valor = valor -700;
         break;
      case 8:
         valor = valor -800;
         break;
      case 9:
         valor = valor-900;
         break;
   }
   dezena = valor/10;
   switch(dezena){
      case 0:
         unidade = valor;
         break;
      case 1:
         unidade = valor -10;
         break;
      case 2:
         unidade = valor -20;
         break;
      case 3:
         unidade = valor -30;
         break;
      case 4:
         unidade = valor -40;
         break;
      case 5:
         unidade = valor -50;
         break;
      case 6:
         unidade = valor -60;
         break;
      case 7:
         unidade = valor -70;
         break;
      case 8:
         unidade = valor -80;
         break;
      case 9:
         unidade = valor-90;
         break;
   }
   return;
}


void leiturasAnalogicas(){
   fim_500ms = 0;
   //adc temperatura
   set_adc_channel(canal_temp);
   delay_us(40);
   temperatura = read_adc();
   //adc potenciometro
   set_adc_channel(canal_pot);
   delay_us(40);
   potenciometro = read_adc();
   return;
}


void varrerDisplay(){
   fim_2ms = 0;
   if(input_state(d_unidade) == 1){
      output_low(d_unidade);
      output_d(codigo[dezena]);
      output_high(d_dezena);
   }else{
      if(input_state(d_dezena) == 1){
         output_low(d_dezena);
         output_d(codigo[centena]);
         output_high(d_centena);
      }else{
         if(input_state(d_centena) == 1){
            output_low(d_centena);
            output_d(codigo[milhar]);
            output_high(d_milhar);
         }else{
               output_low(d_milhar);
               output_d(codigo[unidade]);
               output_high(d_unidade);
         }
      }
   }
   return;
}

