; PIC16F877A Configuration Bit Settings
; Assembly source line config statements
#include "p16f877a.inc"
; CONFIG
; __config 0xFF72
 __CONFIG _FOSC_HS & _WDTE_OFF & _PWRTE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF
    
#define BANK0	BCF STATUS,RP0
#define BANK1	BSF STATUS,RP0
 
 CBLOCK	0x20
    UNIDADE	;0x20
    DEZENA	;0x21
    CENTENA	;0x22
    MILHAR	;0x23
    FLAGS	;0x24
    FLAGS2	;0X25
    CONTADOR	;0x26
    W_TEMP	;0x27
    S_TEMP	;0x28
    VALOR_ADC	;0x29
    CONTADOR2	;0x30
    VALOR_SP	;0x31
    VALOR_PV	;0x32   
    HISTERESE	;0X33
    FILTRO1	;0x34
    FILTRO2	;0x35
    FILTRO3	;0x36
    FILTRO4	;0x37
 ENDC
 
;variaveis bool
#define FIM_TEMPO   FLAGS,0
#define INT_ATIVA   FLAGS,1
#define QUAL_CANAL  FLAGS,2
#define PROCESSO    FLAGS,3 
#define	ACAO1	    FLAGS,4
#define	ACAO2	    FLAGS,5
#define	ACAO3	    FLAGS,6
#define	ACAO4	    FLAGS,7
#define	MOSTRA_HIST FLAGS2,0
 
 
;entradas
#define	B_LG_DSLG	        PORTB,0
#define	B_MOSTRA_INFO	    PORTB,1
#define	B_INC_HIST	    PORTB,2
#define	B_DEC_HIST	    PORTB,3 
 
;saidas
#define	DISPLAY	    PORTD
#define	D_UNIDADE	    PORTB,4
#define	D_DEZENA	    PORTB,5
#define	D_CENTENA	    PORTB,6
#define	D_MILHAR	    PORTB,7
#define	HEATER	    PORTC,2
 
;constantes
V_CONT	       equ	   .250 
V_TMR0	       equ	   .131
V_FILTRO       equ	   .50 
    
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

ISR       CODE    0x0004           ; interrupt vector location
    MOVWF   W_TEMP	    ;salva o W na mem ria RAM
    MOVF    STATUS,W	    ;carrega o STATUS em W
    MOVWF   S_TEMP	    ;e salva na mem ria RAM
    BTFSS   INTCON,T0IF	    ;verifica se a interrup  o foi por TIMER0
    GOTO    SAI_INTERRUPCAO ;se n o foi v  para SAI_INTERRUPCAO
    BCF	    INTCON,T0IF	    ;se sim, limpa bit indicador de interrup  o
    MOVLW   V_TMR0		    ;carrega 6 em W para ajustar 25 pulsos no TMR0
    ADDWF   TMR0,F	    ;soma 6 no TMR0 para que conte 250 pulsos
    BSF	    INT_ATIVA	    ;ativa indica de evento a cada 4ms
    DECFSZ  CONTADOR,F	    ;decremente o CONTADOR e verifique se zerou
    GOTO    SAI_INTERRUPCAO ;se n o zerou, v  para SAI_INTERRUPCAO
    MOVLW   V_CONT	    ;move para o valor da constante
    MOVWF   CONTADOR	    ;inicializa o CONTADOR
    BSF	    FIM_TEMPO	    ;seta a vari vel booleana para pedir a leitura do ADC
SAI_INTERRUPCAO
    MOVF    S_TEMP,W	    ;carrega o S_TEMP em W
    MOVWF   STATUS	    ;restaura STATUS
    MOVF    W_TEMP,W	    ;restaura W    
    RETFIE

START
    BANK1		    ;seleciona o banco 1 da mem ria de RAM
    BCF	    HEATER	    ;sa da para acionar a resist ncia
    CLRF    TRISD	    ;zera o TRISB e faz com que todo o PORTD torne-se sa da
    MOVLW   B'00001111'	    ;
    MOVWF   TRISB	    ;configura os 4 bits MSB como sa da
    MOVLW   B'11010011'	    ;carrega o valor de configura do TMR0 em W
    MOVWF   OPTION_REG	    ;configura o TMR0
    MOVLW   B'01000100'	    ;carrega o valor de configura  o do ADCON1 em W
    MOVWF   ADCON1
    BANK0		    ;seleciona o banco 0 da mem ria de RAM
    MOVLW   B'11000001'	    ;carrega o valor de configura  o do ADCON1 em W
    MOVWF   ADCON0
    CLRF    UNIDADE	    ;UNIDADE = 0
    CLRF    DEZENA	    ;DEZENA = 0
    CLRF    CENTENA	    ;CENTENA = 0
    CLRF    MILHAR	    ;MILHAR  = 0
    CLRF    FLAGS	    ;limpa todos os flags (booleanas)
    CLRF    PORTB	    ;limpa o PORTB
    CLRF    PORTD	    ;limpa o PORTD
    BCF	    HEATER	    ;desliga a resist ncia
    MOVLW   .5		    ;colocando valor 5 para iniciarmos a histerese com esse valor
    MOVWF   HISTERESE	    ;carrega esse valor na vari vel histerese
    MOVLW   .125	    ;carrega 125 em W
    MOVWF   CONTADOR2	    ;carrega 125 no CONTADOR2
    BSF	    INTCON,T0IE	    ;habilita as interrup  es por TIMER0
    BSF	    INTCON,GIE	    ;habilita a chave geral de interrup es

LACO_PRINCIPAL  
    BTFSC   INT_ATIVA			;TESTA SE ENTROU NA INTERRUPCAO
    CALL    ATUALIZA_DISPLAY		;SE SIM ATUALIZA DISPLAY
    BTFSC   FIM_TEMPO			;TESTA SE PASSOU TEMPO
    CALL    LEITURA_ADC			;SE SIM LE ENTRADAS ANALOGICAS
    BTFSS   B_LG_DSLG			;TESTA BOTAO ON/OFF
    GOTO    B_LG_DSLG_PRESS		;VAI PARA ON/OFF PRESS
    CALL    RESETA_FILTRO1		;RESET DE FILTRO
TESTA_B_INFO
    BTFSS   B_MOSTRA_INFO		;TESTA SE BOTAO MOSTRA INFO FOI SELECIONADO
    GOTO    B_MOSTRA_INFO_PRESS		;VAI PARA B_MOSTRA_INFO_PRESS
    CALL    RESETA_FILTRO2		;RESET DE FILTRO
    BTFSS   PROCESSO			;VERIFICA PROCESSO ATIVO
    CALL    CHECK_B_HIST		;SE NAO ESTIVER ATIVO VAI PARA CHECK_B_HIST
    GOTO    LACO_PRINCIPAL		;RETORNA AO LACO PRINCIPAL   


LEITURA_ADC    
    BCF	    FIM_TEMPO		    ;LIMPA FIM TEMPO
    BCF	    ADCON0,3		    ;slecionar canal 0 (PV - VARIAVEL DE PROCESSO)
    CALL    DELAY_TROCA_CANAL	    ;CHAMA FUNCAO DE DELAY PARA TROCA DE CANAL
    BSF	    ADCON0,GO_DONE	    ;ativa a convers o
    BTFSC   ADCON0,GO_DONE	    ;testa se a convers o foi feita
    GOTO    $-1			    ;se n o acabou, testa de novo
    MOVF    ADRESH,W		    ;l  os 8bits (MSB) da convers o e carrega em W    
    MOVWF   VALOR_PV		    ;carrega o valor do sensor 
CANAL_SP
    BSF	    ADCON0,3		    ;seleciona canal 1: bits 5,4,3 = 001
    CALL    DELAY_TROCA_CANAL	    ;CHAMA FUNCAO DE DELAY PARA TROCA DE CANAL
    BSF	    ADCON0,GO_DONE	    ;ativa a convers o
    BTFSC   ADCON0,GO_DONE	    ;testa se a convers o foi feita
    GOTO    $-1			    ;se n o acabou, testa de novo
    MOVF    ADRESH,W		    ;l  os 8bits (MSB) da convers o e carrega em W  
    MOVWF   VALOR_SP		    ;carrega o valor do set-point 
    CALL    COMPARA_POT_MIN	    ;LIMITANDO POTENCIOMETRO
    CALL    COMPARA_POT_MAX	    ;FUNCAO PARA LIMITAR POT
    BTFSC   MOSTRA_HIST		    ;TESTA SE FLAG INDICADOR DE MOSTRA HISTERESE ESTA ATIVO
    GOTO    MOSTRAR_HIST	    ;VAI PARA MOSTRA HISTERESE
    BTFSS   QUAL_CANAL		    ;TESTA QUAL CANAL
    GOTO    CARREGA_SP_VALOR	    
    MOVF    VALOR_PV,W	       
EXTRAI_VALOR  
    MOVWF   VALOR_ADC	    ;carrega o valor convertrido em VALOR_ADC
    CLRF    CENTENA	    ;zera a CENTENA
    CLRF    DEZENA	    ;zera a DEZENA
EXTRAI_CENTENA
    MOVLW   .100	    ;carrega 100 (1 centena) para comparar com VALOR_ADC
    SUBWF   VALOR_ADC,W	    ;subtrai 100 de VALOR_ADC
    BTFSS   STATUS,C	    ;verifica se o resultado   negativo
    GOTO    EXTRAI_DEZENA    ;se for, pula para testa DEZENA
    MOVWF   VALOR_ADC	    ;se n o, carrega da subtra  o em VALOR_ADC
    INCF    CENTENA,F	    ;incrementa CENTENA
    GOTO    EXTRAI_CENTENA   ;testa de novo se o n mero   maior que 100
EXTRAI_DEZENA
    MOVLW   .10		    ;carrega 10 (1 dezena) para comparar com VALOR_ADC
    SUBWF   VALOR_ADC,W	    ;subtrai 10 de VALOR_ADC
    BTFSS   STATUS,C	    ;verifica se o resultado   negativo
    GOTO    EXTRAI_UNIDADE   ;se for, pula para testa UNIDADE
    MOVWF   VALOR_ADC	    ;se n o, carrega da subtra  o em VALOR_ADC
    INCF    DEZENA,F	    ;incrementa DEZENA
    GOTO    EXTRAI_DEZENA    ;testa de novo se o n mero   maior que 10    
EXTRAI_UNIDADE
    MOVF    VALOR_ADC,W	    
    MOVWF   UNIDADE	    
    BTFSS   PROCESSO	    
    GOTO    LACO_PRINCIPAL  
    MOVF    VALOR_SP,W	    
    ADDWF   HISTERESE,W
    SUBWF   VALOR_PV,W	    
    BTFSS   STATUS,C	    
    GOTO    EH_NEGATIVO	    
    BCF	    HEATER	    
    GOTO    LACO_PRINCIPAL  
    
EH_NEGATIVO
    MOVF    VALOR_PV, W	    
    ADDWF   HISTERESE,W	    
    SUBWF   VALOR_SP, W	    
    BTFSS   STATUS,C	     
    GOTO    LACO_PRINCIPAL
    BSF	    HEATER	    
    GOTO    LACO_PRINCIPAL  ;v  para o LACO _PRINCIPAL


MOSTRAR_HIST
    MOVF    HISTERESE,W
    GOTO    EXTRAI_VALOR    
CARREGA_SP_VALOR
    MOVF    VALOR_SP,W	
    GOTO    EXTRAI_VALOR     


DESLIGA_PRESS
    BCF	    PROCESSO	    ;
    BCF	    HEATER	    ;DESLIGA AQUECEDOR
    GOTO    TESTA_B_INFO	    ;pula para TESTA_B_INFO    

ATUALIZA_DISPLAY
    BCF	    INT_ATIVA	    ;limpa o indicador de fim de tempo
    BTFSS   D_UNIDADE		    ;verifica se o display da UNIDADE est  aceso
    GOTO    TESTA_DEZENA	    ;se n o estiver, pula e acende TESTA_D_D
    BCF	    D_UNIDADE		    ;apapar o display da UNIDADE
    MOVF    DEZENA,W	    ;carrega a DEZENA em W
    CALL    BUSCA_CODIGO	    ;chama a sub-rotina para o c digo display
    MOVWF   DISPLAY	    ;escreve o valor no DISPLAY
    BSF	    D_DEZENA		    ;acende display DEZENA    
    RETURN
    
TESTA_DEZENA
    BTFSS   D_DEZENA		    ;verifica se o display da DEZENA est  aceso
    GOTO    TESTA_CENTENA	    ;se n o estiver, pula e acende TESTA_D_C
    BCF	    D_DEZENA		    ;apapar o display da DEZENA
    MOVF    CENTENA,W	    ;carrega a CENTENA em W
    CALL    BUSCA_CODIGO	    ;chama a sub-rotina para o c digo display 
    MOVWF   DISPLAY	    ;escreve o valor no DISPLAY
    BSF	    D_CENTENA	    ;acende display CENTENA    
    RETURN
TESTA_CENTENA    
    BTFSS   D_CENTENA		    ;verifica se o display da CENTENA est  aceso
    GOTO    TESTA_UNIDADE	    ;se n o estiver, pula e acende TESTA_D_M
    BCF	    D_CENTENA		    ;apapar o display da CENTENA
    MOVF    MILHAR,W		    ;carrega a MILHAR em W    
    BTFSC   MOSTRA_HIST	    
    GOTO    MOSTRAR_HISTERESE
    BTFSS   QUAL_CANAL
    GOTO    MOSTRAR_POTENCIOMETRO
    GOTO    MOSTRAR_TEMPERATURA
    CALL    MOSTRA_VAR
TESTA_UNIDADE    
    BCF	    D_MILHAR		    ;apapar o display da MILHAR
    MOVF    UNIDADE,W	    ;carrega a UNIDADE em W
    CALL    BUSCA_CODIGO	    ;chama a sub-rotina para o c digo display 
    MOVWF   DISPLAY	    ;escreve o valor no DISPLAY
    BSF	    D_UNIDADE		    ;acende display UNIDADE    
    RETURN       
MOSTRAR_HISTERESE
    MOVLW   .0 ;-> H -> histerese
    CALL    MOSTRA_VAR
    RETURN
MOSTRAR_POTENCIOMETRO
    MOVLW   .1 ;-> S(SetPoint) -> Potenciometro	
    CALL    MOSTRA_VAR
    RETURN
MOSTRAR_TEMPERATURA
    MOVLW   .2	;-> P(Process) -> Temperatura	
    CALL    MOSTRA_VAR
    RETURN
MOSTRA_VAR
    CALL    BUSCA_CODIGO_VAR
    BSF	    D_MILHAR
    MOVWF   DISPLAY
    RETURN
BUSCA_CODIGO_VAR
    ADDWF	PCL,F
    RETLW 	B'01110110'	;-> H -> histerese
    RETLW 	B'01101101'	;-> S(SetPoint) -> Potenciometro
    RETLW 	B'01110011'	;-> P(Process) -> Temperatura

BUSCA_CODIGO
    ADDWF	PCL,F
    RETLW 	.63
    RETLW 	.6
    RETLW 	.91
    RETLW 	.79
    RETLW 	.102
    RETLW 	.109  
    RETLW 	.125
    RETLW 	.7
    RETLW 	.127
    RETLW 	.111

B_LG_DSLG_PRESS
    BTFSC   ACAO1
    GOTO    LACO_PRINCIPAL
    DECFSZ  FILTRO1,F
    GOTO    LACO_PRINCIPAL
    BSF	    ACAO1
    BTFSC   PROCESSO
    GOTO    DESLIGA_PRESS
    BSF	    PROCESSO
    GOTO    LACO_PRINCIPAL
RESETA_FILTRO1
    MOVLW   V_FILTRO
    MOVWF   FILTRO1
    BCF	    ACAO1
    RETURN

B_MOSTRA_INFO_PRESS
    BTFSC   ACAO2
    GOTO    LACO_PRINCIPAL
    DECFSZ  FILTRO2,F
    GOTO    LACO_PRINCIPAL
    BSF	    ACAO2
    BTFSC   MOSTRA_HIST
    GOTO    TROCA_P_SP
    BTFSS   QUAL_CANAL
    GOTO    TROCA_P_PV
    BSF	    MOSTRA_HIST
    GOTO    LACO_PRINCIPAL
RESETA_FILTRO2
    MOVLW   V_FILTRO
    MOVWF   FILTRO2
    BCF	    ACAO2
    RETURN

B_INC_HIST_PRESS   
    BTFSC   ACAO3
    GOTO    LACO_PRINCIPAL
    DECFSZ  FILTRO3,F
    GOTO    LACO_PRINCIPAL
    BSF	    ACAO3
    CALL    INCREMENTAR_HIST
    GOTO    LACO_PRINCIPAL
RESETA_FILTRO3
    MOVLW   V_FILTRO
    MOVWF   FILTRO3
    BCF	    ACAO3
    RETURN
    
B_DEC_HIST_PRESS   
    BTFSC   ACAO4
    GOTO    LACO_PRINCIPAL
    DECFSZ  FILTRO4,F
    GOTO    LACO_PRINCIPAL
    BSF	    ACAO4
    CALL    DECREMENTAR_HIST
    GOTO    LACO_PRINCIPAL
RESETA_FILTRO4
    MOVLW   V_FILTRO
    MOVWF   FILTRO4
    BCF	    ACAO4
    RETURN

CHECK_B_HIST
    BTFSS   MOSTRA_HIST
    RETURN
    BTFSS   B_INC_HIST
    GOTO    B_INC_HIST_PRESS
    CALL    RESETA_FILTRO3
    BTFSS   B_DEC_HIST
    GOTO    B_DEC_HIST_PRESS
    CALL    RESETA_FILTRO4
    RETURN    

INCREMENTAR_HIST
    MOVLW   .10
    SUBWF   HISTERESE,W
    BTFSS   STATUS,C
    INCF    HISTERESE
    RETURN
DECREMENTAR_HIST
    MOVLW   .0
    SUBWF   HISTERESE,W
    BTFSS   STATUS,Z
    DECF    HISTERESE
    RETURN 

TROCA_P_SP
    BCF	    MOSTRA_HIST
    BCF	    QUAL_CANAL
    GOTO    LACO_PRINCIPAL
TROCA_P_PV
    BCF	    MOSTRA_HIST
    BSF	    QUAL_CANAL
    GOTO    LACO_PRINCIPAL
COMPARA_POT_MIN
    MOVLW   .85
    SUBWF   VALOR_SP,W
    BTFSC  STATUS,C
    RETURN
    MOVLW   .85
    MOVWF   VALOR_SP
    RETURN
COMPARA_POT_MAX
    MOVLW   .185
    SUBWF   VALOR_SP,W
    BTFSS   STATUS,C
    RETURN
    MOVLW   .185
    MOVWF   VALOR_SP
    RETURN
DELAY_TROCA_CANAL
    MOVLW   .20		    ;W = 20
    MOVWF   CONTADOR2	    ;CONTADOR2 = 20
    DECFSZ  CONTADOR2,F	    ;CONTADOR2--
    GOTO    $-1		    ;se n o zerou decrementa novamente
    RETURN 
END