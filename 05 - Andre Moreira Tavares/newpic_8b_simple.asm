;PISCA PISCA DUPLO
;ANDRE MOREIRA TAVARES
;CLOCK: 4Mhz
;4 CICLOS INTERNOS
;INSTRUCAO: 4Mhz/4Ciclos internos => 1Mhz => P = 1/1Mhz = 1uS
;CICLO DE MAQUINA = 1uS
#include "p16f628a.inc"
; __config 0xFF7B
 __CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF
;DEFININDO REGISTROS DE USO GERAL (VARIAVEIS)
CBLOCK 0X20
    DELAY_1	;0x20
    DELAY_2	;0x21
 ENDC

 ;BANCOS
 #define    BANK1	BSF	    STATUS,RP0		    ;selecionando o banco 1 da memória RAM
 #define    BANK0	BCF	    STATUS,RP0		    ;selecionando o banco 0 da memória RAM
 ;saidas
 #define    LED		PORTA,0				    ;DEFININDO O LED
 ;entradas
 #define    B_2HZ	PORTA,1				    ;DEFININDO BOTAO DE 2HZ
 #define    B_5HZ	PORTA,2				    ;DEFININDO BOTAO DE 5HZ
 #define    B_0		PORTA,3				    ;DEFININDO BOTAO DE DESLIGAR

;========PROGRAMA==================
RES_VECT  CODE    0x0000            ; vetor de reset, indica a posição inicial do programa na FLASH
    BANK1
    BCF	    TRISA,0		    ;seleciona o pino 0 da PORTA como SAIDA
    BANK0
    BCF	    LED			    ;GARANTINDO QUE O LED IRA COMEÇAR DESLIGADO

VERIFICA_BOTOES			    ;LACO PARA VERIFICAR SE OS BOTOES DE PISCA FORAM PRESSIONADOS
    BTFSS   B_2HZ		    ;LE E TESTA BOTAO B_2HZ
    GOTO    B_2HZ_PRESS		    ;SE PRESSIONADO VAI PRA ESSA FUNCAO
    BTFSS   B_5HZ		    ;LE E TESTA BOTAOB_5HZ
    GOTO    B_5HZ_PRESS		    ;SE PRESSIONADO VAI PRA ESSA FUNCAO
    GOTO    VERIFICA_BOTOES	    ;RETORNA PARA O INICIO DO LOOP CASO ESTEJA DESLIGADO
    
B_2HZ_PRESS			    ;FUNCAO CASO B2HZ FOR PRESSIONADO
    BSF	    LED			    ;LIGA LED
    CALL    DELAY_2HZ		    ;CHAMA DELAY PARA 2HZ E PAUSA POR APROXIMADAMENTE 250ms
    BCF	    LED			    ;DESLIGA LED
    CALL    DELAY_2HZ		    ;CHAMA DELAY PARA 2HZ E PAUSA POR APROXIMADAMENTE 250ms
    BTFSC   B_0			    ;TESTA BOTAO DE DESLIGA
    GOTO    B_2HZ_PRESS		    ;SE NAO PRESSIONADO CONTINUA NO LOOP DE PISCA 2HZ
    GOTO    VERIFICA_BOTOES	    ;SE PRESSIONADO APROVEITA QUE O LED TA DESLIGADO E RETORNA PRO LOOP DE VERIFICACAO DE BOTOES
    
B_5HZ_PRESS			    ;FUNCAO CASO B5HZ FOR PRESSIONADO
    BSF	    LED			    ;LIGA LED
    CALL    DELAY_5HZ		    ;CHAMA DELAY PARA 5HZ E PAUSA POR APROXIMADAMENTE 100ms
    BCF	    LED			    ;DESLIGA LED
    CALL    DELAY_5HZ		    ;CHAMA DELAY PARA 5HZ E PAUSA POR APROXIMADAMENTE 100ms
    BTFSC   B_0			    ;TESTA BOTAO DE DESLIGA
    GOTO    B_5HZ_PRESS		    ;SE NAO PRESSIONADO CONTINUA NO LOOP DE PISCA 5HZ
    GOTO    VERIFICA_BOTOES	    ;SE PRESSIONADO APROVEITA QUE O LED TA DESLIGADO E RETORNA PRO LOOP DE VERIFICACAO DE BOTOES
    
DELAY_2HZ			    ;2 ciclos
    BTFSS   B_0			    ;1 ciclo
    RETURN
    MOVLW   .115		    ;1 ciclo
    MOVWF   DELAY_1		    ;1 ciclo
REINICIA_DELAY_2		    ;= 5 ciclos || 5us
    MOVLW   .250		    ;1 ciclo
    MOVWF   DELAY_2		    ;1 ciclo
DECREMENTA_DELAY_2		    ;= 7 ciclos || 7us
    NOP				    ;1 ciclo 
    NOP				    ;1 ciclo 
    NOP				    ;1 ciclo 
    NOP				    ;1 ciclo 
    BTFSS   B_0			    ;1 ciclo
    RETURN
    DECFSZ  DELAY_2,F		    ;1 ciclo
    GOTO    DECREMENTA_DELAY_2	    ;2 ciclos  || 8 ciclos por decremento de delay2 || 2000us
    DECFSZ  DELAY_1,F		    ;1 ciclo
    GOTO    REINICIA_DELAY_2	    ;2 ciclos  || 2000 Ciclos*115 = 230000 ciclos + 7 ciclos
    RETURN
    
    
DELAY_5HZ			    ;2 ciclos
    BTFSS   B_0			    ;1 ciclo
    RETURN
    MOVLW   .45		    ;1 ciclo
    MOVWF   DELAY_1		    ;1 ciclo
REINICIA_DELAY_2B		    ;= 5 ciclos || 5us
    MOVLW   .250		    ;1 ciclo
    MOVWF   DELAY_2		    ;1 ciclo
DECREMENTA_DELAY_2B		    ;= 7 ciclos || 7us
    NOP				    ;1 ciclo 
    NOP				    ;1 ciclo 
    NOP				    ;1 ciclo 
    NOP				    ;1 ciclo 
    BTFSS   B_0			    ;1 ciclo
    RETURN			    
    DECFSZ  DELAY_2,F		    ;1 ciclo
    GOTO    DECREMENTA_DELAY_2B	    ;2 ciclos  || 8 ciclos por decremento de delay2 || 2000us
    DECFSZ  DELAY_1,F		    ;1 ciclo
    GOTO    REINICIA_DELAY_2B	    ;2 ciclos  || 2000 Ciclos*45 = 90000 ciclos + 7 ciclos
    RETURN
END