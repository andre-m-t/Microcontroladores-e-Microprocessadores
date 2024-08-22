; PIC16F877A Configuration Bit Settings
; Assembly source line config statements
#include "p16f877a.inc"
; CONFIG
; __config 0xFF71
 __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

#define BANK0      BCF STATUS,RP0
#define BANK1      BSF STATUS,RP0
 
 CBLOCK 0X20
    FLAGS
    FILTRO
    UNIDADE
    DEZENA
    CENTENA
    MILHAR
    W_TEMP
    S_TEMP
    VALOR_ADC_H
    VALOR_ADC_L
    VALOR_ADC0_H
    VALOR_ADC0_L
    VALOR_ADC1_H
    VALOR_ADC1_L
    CONTADOR
    R_H
    R_L
    X_H
    X_L
    Y_H
    Y_L
    DELAY_ADC
    H_POTENCIOMETRO
    L_POTENCIOMETRO
    H_TEMPERATURA
    L_TEMPERATURA
    U_POT
    D_POT
    C_POT
    M_POT
    U_TEMP
    D_TEMP
    C_TEMP
    M_TEMP
 ENDC
 
#define ACAO		FLAGS,0
#define INT_ATIVA	FLAGS,1
#define FIM_TEMPO	FLAGS,2
#define EH_NEGATIVO	FLAGS,3
#define QUAL_CANAL	FLAGS,4
#define AQUECENDO	FLAGS,5 
 
#define DISPLAY		PORTD
#define D_UNIDADE	PORTB,4
#define D_DEZENA	PORTB,5
#define D_CENTENA	PORTB,6
#define D_MILHAR	PORTB,7
#define B_POT		PORTB,0
#define B_TEMP		PORTB,1
#define LIGA		PORTB,2
#define DESLIGA		PORTB,3
#define HEATER		PORTC,2
#define COOLER		PORTC,1
 
V_TMR0      equ     .6	    ;256 - 6 = 250 pulsos -> 250*0,5*16 = 2ms

V_FILTRO    equ     .100
V_CONT	    equ     .4
;programa ===================================================
RES_VECT    CODE    0x0000            ; reset vector
    GOTO    START                   ; go to beginning of program

INTERRUPT_VECT  CODE    0x0004
    MOVWF   W_TEMP
    MOVF    STATUS,W
    MOVWF   S_TEMP
    BTFSS   INTCON,T0IF
    GOTO    SAI_INTERRUPCAO
    BCF     INTCON,T0IF    
    MOVLW   V_TMR0
    ADDWF   TMR0,F
    BSF     INT_ATIVA
    DECFSZ  CONTADOR,F
    GOTO    SAI_INTERRUPCAO
    BSF     FIM_TEMPO
    MOVLW   V_CONT
    MOVWF   CONTADOR
SAI_INTERRUPCAO
    MOVF    S_TEMP,W
    MOVWF   STATUS
    MOVF    W_TEMP,W
    RETFIE
    
START
    BANK1
    CLRF    TRISD   ;DEFINE PORTD COMO SAIDA
    MOVLW   B'00001111'
    MOVWF   TRISB   ;DEFININDO PINOS DA TROCA DE DISPLAY
    
    BCF     TRISC,2 ;DEFININDO HEATER COMO SAIDA
    BCF     TRISC,1 ;DEFININDO COOLER COMO SAIDA
    MOVLW   B'01010011' ;valor para configurar o TIMER0(ps:16)
    MOVWF   OPTION_REG  ;carrega valor no TIMER0
    MOVLW   B'11000100' ;bit 7 - justificar   direita
            ;bit 6 - clock gerado por RC
            ;bit 5 e 4 - n o usado
            ;bit 3,2,1,0 - seleciona AN0, AN1 e AN3 como entradas anal gicas
    MOVWF   ADCON1  ;carregar valor no ADCON1
    BANK0
    MOVLW   B'11000001' ;bit 7 e 6 - clock gerado por RC
            ;bit 5,4,3 - seleciona a entrada AN0 para leitura
            ;bit 2 - inicia e indica que a convers o finalizou
            ;bit 1 - n o usado
            ;bit 0 - liga o conversor           
    MOVWF   ADCON0  ;carregar valor no ADCON0    
    ;SETANDO AS SAIDAS NO INICIO DO PROGRAMA
    CLRF    DISPLAY
    BCF     D_UNIDADE
    BCF     D_DEZENA
    BCF     D_CENTENA
    BCF     D_MILHAR    
    CLRF    UNIDADE
    CLRF    DEZENA
    CLRF    CENTENA
    CLRF    MILHAR    
    MOVLW   V_FILTRO
    MOVWF   FILTRO
    BCF     FIM_TEMPO
    MOVLW   V_CONT
    MOVWF   CONTADOR
    BCF     ACAO
    BCF     INT_ATIVA
    BSF     QUAL_CANAL
    BCF     HEATER
    MOVLW   V_TMR0
    MOVWF   TMR0
    BSF     INTCON,T0IE		;PERMITE ATENDER INTERRUPCOES POR TMR0
    BSF     INTCON,GIE		;PERMITE ATENDER INTERRUPCOES
LACO_PRINCIPAL
    BTFSS   B_TEMP		;TESTA SE BOTAO DE TEMPERATURA FOI PRESSIONADO
    BCF     QUAL_CANAL		;QUAL_CANAL = 0
    BTFSS   B_POT		;TESTA SE BOTAO DE POTENCIOMETRO FOI PRESSIONADO
    BSF     QUAL_CANAL		;QUAL_CANAL = 1
    BTFSS   LIGA		;TESTA SE BOTAO LIGAR FOI PRESSIONADO
    BSF     AQUECENDO		;ATIVA BIT AUXILIAR DE AQUECENDO
    BTFSS   DESLIGA		;TESTA SE BOTAO DESLIGAR FOI PRESSIONADO
    CALL    DESLIGA_AQUECENDO	;CHAMA SUBROTINA PARA DESLIGAR O AQUECENDO
    
    BTFSC   INT_ATIVA
    CALL    ATUALIZA_DISPLAY
    BTFSS   FIM_TEMPO
    GOTO    LACO_PRINCIPAL
    BCF     FIM_TEMPO
    MOVLW   B'11000111' ;seleciona canal AN0        
    ANDWF   ADCON0,F    ;carregar valor no ADCON0
    MOVLW   .19
    MOVWF   DELAY_ADC
    DECFSZ  DELAY_ADC,F
    GOTO    $-1
    ;inicia a convers o
    BSF     ADCON0,GO
    ;aguarda o final da convers o
    BTFSC   ADCON0,GO
    GOTO    $-1
    MOVF    ADRESH,W        ;l  os 8 bits mais significativos da convers o AD
    MOVWF   VALOR_ADC0_H    ;carrega na vari vel VALOR_ADC0_H
    BANK1
    MOVF    ADRESL,W        ;l  os 8 bits menos significativos da convers o AD
    BANK0
    MOVWF   VALOR_ADC0_L    ;carrega na vari vel VALOR_ADC0_L 
    ;le e converte a entrada anal gica AN1 
    BSF     ADCON0,3    ;seleciona para o canal AN1 ADCON0 = xx001xxx 
    ;temporizar antes de ativar a convers o 
    MOVLW   .19
    MOVWF   DELAY_ADC
    DECFSZ  DELAY_ADC,F
    GOTO    $-1
    ;inicia a convers o
    BSF     ADCON0,GO
    ;aguarda o final da convers o
    BTFSC   ADCON0,GO
    GOTO    $-1
    MOVF    ADRESH,W        ;l  os 8 bits mais significativos da convers o AD
    MOVWF   VALOR_ADC1_H    ;carrega na vari vel VALOR_ADC1_H
    BANK1
    MOVF    ADRESL,W        ;l  os 8 bits menos significativos da convers o AD
    BANK0
    MOVWF   VALOR_ADC1_L    ;carrega na vari vel VALOR_ADC1_L
    BTFSC   AQUECENDO
    CALL    CONTROLA_AQUECENDO
    BTFSS   QUAL_CANAL
    GOTO    MOSTRA_CANAL_0
MOSTRA_CANAL_1          ;preparar para mostrar o canal 1
    MOVF    VALOR_ADC1_H,W
    MOVWF   VALOR_ADC_H
    MOVF    VALOR_ADC1_L,W
    MOVWF   VALOR_ADC_L    
    GOTO    MOSTRA_NO_DISPLAY
MOSTRA_CANAL_0    
    MOVF    VALOR_ADC0_H,W
    MOVWF   VALOR_ADC_H
    MOVF    VALOR_ADC0_L,W
    MOVWF   VALOR_ADC_L     
MOSTRA_NO_DISPLAY    
    CLRF    UNIDADE
    CLRF    DEZENA
    CLRF    CENTENA
    CLRF    MILHAR
EXTRAI_MILHAR
    MOVF    VALOR_ADC_H,W
    MOVWF   X_H
    MOVF    VALOR_ADC_L,W
    MOVWF   X_L  
    MOVLW   0X03
    MOVWF   Y_H
    MOVLW   0XE8
    MOVWF   Y_L    
    CALL    SUBTRACAO_16BITS
    BTFSC   EH_NEGATIVO
    GOTO    EXTRAI_CENTENA
    MOVF    R_H,W
    MOVWF   VALOR_ADC_H
    MOVF    R_L,W
    MOVWF   VALOR_ADC_L    
    INCF    MILHAR,F
    GOTO    EXTRAI_MILHAR  
EXTRAI_CENTENA
    MOVF    VALOR_ADC_H,W
    MOVWF   X_H
    MOVF    VALOR_ADC_L,W
    MOVWF   X_L 
    MOVLW   .0
    MOVWF   Y_H
    MOVLW   .100
    MOVWF   Y_L    
    CALL    SUBTRACAO_16BITS
    BTFSC   EH_NEGATIVO
    GOTO    EXTRAI_DEZENA
    MOVF    R_H,W
    MOVWF   VALOR_ADC_H
    MOVF    R_L,W
    MOVWF   VALOR_ADC_L    
    INCF    CENTENA,F
    GOTO    EXTRAI_CENTENA    
EXTRAI_DEZENA
    MOVLW   .10
    SUBWF   VALOR_ADC_L,W
    BTFSS   STATUS,C
    GOTO    EXTRAI_UNIDADE
    MOVWF   VALOR_ADC_L
    INCF    DEZENA,F
    GOTO    EXTRAI_DEZENA
EXTRAI_UNIDADE
    MOVF    VALOR_ADC_L,W
    MOVWF   UNIDADE
    GOTO    LACO_PRINCIPAL    
CONTROLA_AQUECENDO
    BCF	    COOLER
    MOVF    VALOR_ADC1_H,W
    MOVWF   X_H
    MOVF    VALOR_ADC1_L,W
    MOVWF   X_L  
    MOVF    VALOR_ADC0_H,W
    MOVWF   Y_H
    MOVF    VALOR_ADC0_L,W
    MOVWF   Y_L    
    CALL    SUBTRACAO_16BITS
    BTFSC   EH_NEGATIVO
    GOTO    DESLIGA_HEATER
    BSF	    HEATER
    RETURN    
DESLIGA_HEATER    
    BCF	    HEATER
    RETURN
SUBTRACAO_16BITS
    BCF     EH_NEGATIVO
    MOVF    Y_L,W
    SUBWF   X_L,W
    MOVWF   R_L
    BTFSS   STATUS,C
    BSF     EH_NEGATIVO
    MOVF    Y_H,W
    SUBWF   X_H,W
    MOVWF   R_H
    BTFSC   STATUS,C
    GOTO    E_POSITIVO_MSB
    BSF     EH_NEGATIVO
    RETURN
E_POSITIVO_MSB
    BTFSS   EH_NEGATIVO
    RETURN
    MOVLW   .1
    SUBWF   R_H,F
    BTFSS   STATUS,C
    GOTO    E_EH_NEGATIVO
    BCF     EH_NEGATIVO
    RETURN
E_EH_NEGATIVO
    BSF     EH_NEGATIVO
    RETURN
ATUALIZA_DISPLAY
    BCF     INT_ATIVA
    BTFSS   D_UNIDADE
    GOTO    TESTA_DISPLAY_DEZENA
    BCF     D_UNIDADE
    MOVF    DEZENA,W
    CALL    BUSCA_CODIGO
    MOVWF   DISPLAY
    BSF     D_DEZENA
    RETURN
TESTA_DISPLAY_DEZENA
    BTFSS   D_DEZENA
    GOTO    TESTA_DISPLAY_CENTENA
    BCF     D_DEZENA
    MOVF    CENTENA,W
    CALL    BUSCA_CODIGO
    MOVWF   DISPLAY
    BSF     D_CENTENA
    RETURN
TESTA_DISPLAY_CENTENA    
    BTFSS   D_CENTENA
    GOTO    TESTA_DISPLAY_MILHAR
    BCF     D_CENTENA
    MOVF    MILHAR,W
    CALL    BUSCA_CODIGO
    MOVWF   DISPLAY
    BSF     D_MILHAR
    RETURN
TESTA_DISPLAY_MILHAR
    BCF     D_MILHAR
    MOVF    UNIDADE,W
    CALL    BUSCA_CODIGO
    MOVWF   DISPLAY
    BSF     D_UNIDADE
    RETURN   
    
DESLIGA_AQUECENDO
    BCF	    AQUECENDO
    CALL    RESFRIAMENTO_30GRAUS
    RETURN
    
BUSCA_CODIGO
    ADDWF   PCL,F   
    RETLW   .63     ;0 
    RETLW   .6      ;1 
    RETLW   .91     ;2 
    RETLW   .79     ;3 
    RETLW   .102    ;4
    RETLW   .109    ;5 
    RETLW   .125    ;6 
    RETLW   .7      ;7
    RETLW   .127    ;8 
    RETLW   .111    ;9 
    RETLW   .0      ;APAGADO    
    
    
    
LER_TEMPERATURA
    ;GARANTINDO QUE ESTOU NO CANAL DA TEMPERATURA
    BCF	    ADCON0,3	    ;reseta o bit4 para seleciona o canal 0
    ;BSF	    QUAL_CANAL
    ;LEITURA DO VALOR DA TEMP
    BSF	    ADCON0,GO		    ;inicia a conversão
    BTFSC   ADCON0,GO		    ;testa se finalizou a conversão
    GOTO    $-1			    ;mesma coisa de  GOTO TESTA_FIM
    MOVF    ADRESH,W		    ;lê os 8MSBs do resultado da conversão
    MOVWF   H_TEMPERATURA	    ;VALOR_ADC_H = ADRESH
    BANK1			    ;seleciona banco 1 da memória RAM
    MOVF    ADRESL,W		    ;lê os 8LSBs do resultado da conversão
    BANK0			    ;seleciona banco 0 da memória RAM
    MOVWF   L_TEMPERATURA	    ;VALOR_ADC_L = ADRESL
    CLRF    M_TEMP	    ;MILHAR = 0
EXTRAI_MILHAR_TEMP    
    MOVF    H_TEMPERATURA,W   ;W = VALOR_ADC_H
    MOVWF   X_H		    ;X_H = VALOR_ADC_H
    MOVF    L_TEMPERATURA,W   ;W = VALOR_ADC_L
    MOVWF   X_L		    ;X_L = VALOR_ADC_L  
    MOVLW   0x03	    ;W = 0x03
    MOVWF   Y_H		    ;Y_H = 0x03
    MOVLW   0xE8	    ;W = 0xE8
    MOVWF   Y_L		    ;Y_L = 0xE8 
    CALL    SUBTRACAO_16BITS	    ;chama rotina de subtração de 16 bits
    BTFSC   EH_NEGATIVO	    ;testa se o resultado da operação deu EH_NEGATIVO
    GOTO    TRATA_CENTENA_TEMP   ;se EH_NEGATIVO pula para TRATA_CENTENA
    MOVF    R_H,W	    ;W = R_H
    MOVWF   H_TEMPERATURA	    ;VALOR_ADC_H = R_H
    MOVF    R_L,W	    ;W = R_L
    MOVWF   L_TEMPERATURA	    ;VALOR_ADC_L = R_L    
    INCF    M_TEMP,F	    ;MILHAR++
    GOTO    EXTRAI_MILHAR_TEMP   ;pula para EXTRAI_MILHAR
TRATA_CENTENA_TEMP    
    CLRF    C_TEMP	    ;CENTENA = 0
EXTRAI_CENTENA_TEMP  
    MOVF    H_TEMPERATURA,W   ;W = VALOR_ADC_H
    MOVWF   X_H		    ;X_H = VALOR_ADC_H
    MOVF    L_TEMPERATURA,W   ;W = VALOR_ADC_L
    MOVWF   X_L		    ;X_L = VALOR_ADC_L  
    MOVLW   0x00	    ;W = 0x00
    MOVWF   Y_H		    ;Y_H = 0x03
    MOVLW   0x64	    ;W = 0x64
    MOVWF   Y_L		    ;Y_L = 0xE8 
    CALL    SUBTRACAO_16BITS	    ;chama rotina de subtração de 16 bits    
    BTFSC   EH_NEGATIVO	    ;testa se o resultado da operação deu EH_NEGATIVO
    GOTO    TRATA_DEZENA_TEMP    ;se EH_NEGATIVO pula para TRATA_DEZENA    
    MOVF    R_H,W	    ;W = R_H
    MOVWF   H_TEMPERATURA	    ;VALOR_ADC_H = R_H
    MOVF    R_L,W	    ;W = R_L
    MOVWF   L_TEMPERATURA	    ;VALOR_ADC_L = R_L    
    INCF    C_TEMP,F	    ;CENTENA++
    GOTO    EXTRAI_CENTENA_TEMP  ;pula para EXTRAI_CENTENA    
TRATA_DEZENA_TEMP
    CLRF    D_TEMP	    ;DEZENA = 0
EXTRAI_DEZENA_TEMP
    MOVLW   .10		    ;W = 10
    SUBWF   L_TEMPERATURA,W   ;W = VALOR_ADC_L - W
    BTFSS   STATUS,C	    ;testa se o resultado é EH_NEGATIVO
    GOTO    TRATA_UNIDADE_TEMP  ;se EH_NEGATIVO, pula para verificar valor unidade
    MOVWF   L_TEMPERATURA	    ;VALOR_ADC_L = W = VALOR_ADC_L - 10
    INCF    D_TEMP,F	    ;DEZENA++
    GOTO    EXTRAI_DEZENA_TEMP   ;    
TRATA_UNIDADE_TEMP
    MOVF    L_TEMPERATURA,W   ;W = VALOR_ADC_L
    MOVWF   U_TEMP	    ;UNIDADE = VALOR_ADC_L 
    RETURN
    

    
    
LER_POTENCIOMETRO
    ;GARANTINDO QUE ESTOU NO CANAL DO POTENCIOMETRO
    BSF	    ADCON0,3	    ;reseta o bit4 para seleciona o canal 1
    ;BCF	    QUAL_CANAL
    ;LEITURA DO VALOR SETADO NO POT
    BSF	    ADCON0,GO		    ;inicia a conversãO
    BTFSC   ADCON0,GO		    ;testa se finalizou a conversão
    GOTO    $-1			    ;mesma coisa de  GOTO TESTA_FIM
    MOVF    ADRESH,W		    ;lê os 8MSBs do resultado da conversão
    MOVWF   H_POTENCIOMETRO	    ;VALOR_ADC_H = ADRESH
    BANK1			    ;seleciona banco 1 da memória RAM
    MOVF    ADRESL,W		    ;lê os 8LSBs do resultado da conversão
    BANK0			    ;seleciona banco 0 da memória RAM
    MOVWF   L_POTENCIOMETRO	    ;VALOR_ADC_L = ADRESL
    CLRF    M_POT	    ;MILHAR = 0
EXTRAI_MILHAR_POT    
    MOVF    H_POTENCIOMETRO,W   ;W = VALOR_ADC_H
    MOVWF   X_H		    ;X_H = VALOR_ADC_H
    MOVF    L_POTENCIOMETRO,W   ;W = VALOR_ADC_L
    MOVWF   X_L		    ;X_L = VALOR_ADC_L  
    MOVLW   0x03	    ;W = 0x03
    MOVWF   Y_H		    ;Y_H = 0x03
    MOVLW   0xE8	    ;W = 0xE8
    MOVWF   Y_L		    ;Y_L = 0xE8 
    CALL    SUBTRACAO_16BITS	    ;chama rotina de subtração de 16 bits
    BTFSC   EH_NEGATIVO	    ;testa se o resultado da operação deu EH_NEGATIVO
    GOTO    TRATA_CENTENA_POT   ;se EH_NEGATIVO pula para TRATA_CENTENA
    MOVF    R_H,W	    ;W = R_H
    MOVWF   H_POTENCIOMETRO	    ;VALOR_ADC_H = R_H
    MOVF    R_L,W	    ;W = R_L
    MOVWF   L_POTENCIOMETRO	    ;VALOR_ADC_L = R_L    
    INCF    M_POT,F	    ;MILHAR++
    GOTO    EXTRAI_MILHAR_POT   ;pula para EXTRAI_MILHAR
TRATA_CENTENA_POT    
    CLRF    C_POT	    ;CENTENA = 0
EXTRAI_CENTENA_POT  
    MOVF    H_POTENCIOMETRO,W   ;W = VALOR_ADC_H
    MOVWF   X_H		    ;X_H = VALOR_ADC_H
    MOVF    L_POTENCIOMETRO,W   ;W = VALOR_ADC_L
    MOVWF   X_L		    ;X_L = VALOR_ADC_L  
    MOVLW   0x00	    ;W = 0x00
    MOVWF   Y_H		    ;Y_H = 0x03
    MOVLW   0x64	    ;W = 0x64
    MOVWF   Y_L		    ;Y_L = 0xE8 
    CALL    SUBTRACAO_16BITS	    ;chama rotina de subtração de 16 bits    
    BTFSC   EH_NEGATIVO	    ;testa se o resultado da operação deu EH_NEGATIVO
    GOTO    TRATA_DEZENA_POT    ;se EH_NEGATIVO pula para TRATA_DEZENA    
    MOVF    R_H,W	    ;W = R_H
    MOVWF   H_POTENCIOMETRO	    ;VALOR_ADC_H = R_H
    MOVF    R_L,W	    ;W = R_L
    MOVWF   L_POTENCIOMETRO	    ;VALOR_ADC_L = R_L    
    INCF    C_POT,F	    ;CENTENA++
    GOTO    EXTRAI_CENTENA_POT  ;pula para EXTRAI_CENTENA    
TRATA_DEZENA_POT
    CLRF    D_POT	    ;DEZENA = 0
EXTRAI_DEZENA_POT
    MOVLW   .10		    ;W = 10
    SUBWF   L_POTENCIOMETRO,W   ;W = VALOR_ADC_L - W
    BTFSS   STATUS,C	    ;testa se o resultado é EH_NEGATIVO
    GOTO    TRATA_UNIDADE_POT   ;se EH_NEGATIVO, pula para verificar valor unidade
    MOVWF   L_POTENCIOMETRO	    ;VALOR_ADC_L = W = VALOR_ADC_L - 10
    INCF    D_POT,F	    ;DEZENA++
    GOTO    EXTRAI_DEZENA_POT   ;    
TRATA_UNIDADE_POT
    MOVF    L_POTENCIOMETRO,W   ;W = VALOR_ADC_L
    MOVWF   U_POT	    ;UNIDADE = VALOR_ADC_L 
    RETURN
    
    
RESFRIAMENTO_30GRAUS
;DESATIVANDO INTERRUPÇÕES PARA NAO HAVER BUGS DE DISPLAY
    BCF	    INTCON,GIE	    ;NAO permite atender interrupções
    BCF	    INTCON,T0IE	    ;permite atender interrupção por TMR0
    BCF	    HEATER
    ;LEITURA DO POTENCIOMETRO E TEMPERATURA
    MOVLW    .0
    MOVWF   M_POT
    MOVLW    .3
    MOVWF   C_POT
    MOVLW    .6
    MOVWF   D_POT
    MOVLW    .0
    MOVWF   U_POT
    CALL    LER_TEMPERATURA
    ;TESTAR SE VALOR ESTA ABAIXO OU ACIMA DA TEMPERATURA
    BSF	    ADCON0,GO	    ;inicia a conversão    
    BTFSC   ADCON0,GO	    ;testa se finalizou a conversão
    GOTO    $-1		    ;mesma coisa de  GOTO TESTA_FIM
    MOVF    ADRESH,W	    ;lê os 8MSBs do resultado da conversão
    MOVWF   VALOR_ADC_H	    ;VALOR_ADC_H = ADRESH
    BANK1		    ;seleciona banco 1 da memória RAM
    MOVF    ADRESL,W	    ;lê os 8LSBs do resultado da conversão
    BANK0		    ;seleciona banco 0 da memória RAM
    MOVWF   VALOR_ADC_L	    ;VALOR_ADC_L = ADRESL
    MOVF    VALOR_ADC_H,W   ;W = VALOR_ADC_H
    MOVWF   X_H		    ;X_H = VALOR_ADC_H
    MOVF    VALOR_ADC_L,W   ;W = VALOR_ADC_L
    MOVWF   X_L		    ;X_L = VALOR_ADC_L  
    MOVLW   B'00000001'	    ;W = 0x03
    MOVWF   Y_H		    ;Y_H = 0x03
    MOVLW   B'01101000'	    ;W = 0xE8
    MOVWF   Y_L		    ;Y_L = 0xE8 
    CALL    SUBTRACAO_16BITS	    ;chama rotina de subtração de 16 bits
    BTFSC   EH_NEGATIVO	    ;testa se o resultado da operação deu EH_NEGATIVO
    GOTO    FINALIZA_ESFRIAR   ;se EH_NEGATIVO pula para TRATA_CENTENA
    ;AQUECENDO DE AQUECIMENTO
    BSF	    COOLER
AQUECENDO_DE_RESFRIAMENTO
    CALL    LER_TEMPERATURA
    MOVF    M_TEMP,W
    MOVWF   MILHAR
    MOVF    C_TEMP,W
    MOVWF   CENTENA
    MOVF    D_TEMP,W
    MOVWF   DEZENA
    MOVF    U_TEMP,W
    MOVWF   UNIDADE
    CALL    ATUALIZA_DISPLAY
    ;TESTAR SE VALOR ESTA ABAIXO OU ACIMA DA TEMPERATURA
    MOVF    C_TEMP,W
    SUBWF   C_POT,W
    BTFSS   STATUS,Z
    GOTO    AQUECENDO_DE_RESFRIAMENTO
    ;TESTANDO DEZENA
    MOVF    D_TEMP,W
    SUBWF   D_POT,W
    BTFSS   STATUS,Z
    GOTO    AQUECENDO_DE_RESFRIAMENTO
    ;TESTANDO UNIDADE
    MOVF    U_TEMP,W
    SUBWF   U_POT,W
    BTFSS   STATUS,Z
    GOTO    AQUECENDO_DE_RESFRIAMENTO
FINALIZA_ESFRIAR
    BCF	    COOLER
    BSF	    INTCON,GIE
    BSF	    INTCON,T0IE	    ;permite atender interrupção por TMR0
    RETURN
END