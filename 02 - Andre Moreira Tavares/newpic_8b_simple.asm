#include "p16f628a.inc"
;ANDRÉ MOREIRA TAVARES
; CONFIG
__CONFIG _FOSC_INTOSCIO & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _BOREN_ON & _LVP_OFF & _CPD_OFF & _CP_OFF
 
RES_VECT CODE 0x0000 ; VETOR DE RESET, INDICA A POSI  O INICIAL DO PROGRAMA NA FLASH
    BSF STATUS,RP0  ;ENTRANDO NO BANCO 1
    MOVLW   B'11110000'		    ;W= B'11110000'(.240)
    MOVWF   TRISB		    ;DEFININDO AS SAIDAS E ENTRADAS DO PORTB
    BCF	STATUS,RP0  ;VOLTANDO AO BANCO 0
    BCF	PORTB,0	    ;APAGANDO A LAMPADA
    BCF PORTB,1
    BCF PORTB,2
    BCF PORTB,3
 
LE_BOTAO1
    BTFSC   PORTA,1		    ;lê e testa o bit 1 da PORT A1
    GOTO    LE_BOTAO1		    ;se não for zero, pula para LE_BOTAO1
    BTFSC   PORTB,0		    ;testa o bit da saida B0
    GOTO    APAGA_B0		    ;se estiver desligada apaga
    BSF	    PORTB,0		    ;se estiver desligada acende
    GOTO    LE_BOTAO2		    ;pula para LE_BOTAO2 para que nao apague na sequencia do codigo
APAGA_B0
    BCF	    PORTB,0		    ;apaga led b0 e segue o codigo 
    
LE_BOTAO2			    ;daqui por diante, repete-se os passos anteriores para os botoes e lampadas consecutivos
    BTFSC   PORTA,2		    
    GOTO    LE_BOTAO2		    
    BTFSC   PORTB,1
    GOTO    APAGA_B1
    BSF	    PORTB,1
    GOTO    LE_BOTAO3
APAGA_B1
    BCF	    PORTB,1
    
LE_BOTAO3
    BTFSC   PORTA,3		    
    GOTO    LE_BOTAO3		   
    BTFSC   PORTB,2
    GOTO    APAGA_B2
    BSF	    PORTB,2		    
    GOTO    LE_BOTAO4
APAGA_B2
    BCF	    PORTB,2
LE_BOTAO4
    BTFSC   PORTA,4		    
    GOTO    LE_BOTAO4		   
    BTFSC   PORTB,3
    GOTO    APAGA_B3
    BSF	    PORTB,3		    
    GOTO    LE_BOTAO1		    
APAGA_B3
    BCF	    PORTB,3
    GOTO    LE_BOTAO1
END