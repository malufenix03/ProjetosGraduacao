;###########################################################################
;						PIANO GRAVADOR
;AUTORA: LUANA RODRIGUES DA SILVA E LIMA
;###########################################################################


#include <P16F873.INC>
;########################################
;			VARIÁVEIS
;########################################

CBLOCK 0x20
	CICLOS								;quantidade ciclos
	SEGUNDOS							;quantidade segundos
	CICLO_SEG							;16 ciclos por segundo
	DURACAO_CICLO						;quantidade ciclos que a nota atual está tocando
	DURACAO_SEG							;quantidade segundos que a nota atual está tocando
	NOTA								;nota atual
	NOTA_GRAV							;número de endereços usados (notas)
	NOTA_TOCA							;número de endereços lidos(notas)
	FLAG								;flag para sinalizar quando ler um registrador
										;bit 0 refere a nota/segundos, bit 1 refere ao ciclo
											;0: tocar	1:leR
ENDC	
;########################################
;		ARMAZENAMENTO NA EEPROM
;########################################
;	ARMAZENA-SE A NOTA TOCADA E O TEMPO QUE ELA SE MANTEVE TOCANDO, SENDO QUE:
;	NADA = 0		DÓ = 1		RÉ = 2		MI = 3		FÁ = 4		SOL = 5		LÁ = 6		SÍ = 7
;		REGISTRADOR 1: 3 MSBs refere à nota (0 a 7), 5 LSBs refere ao segundos (0 a 20)	
;		REGISTRADOR 2:	guarda o número de ciclos que a nota anterior foi tocada desconsiderando os segundos

;########################################
;			CÓDIGO
;########################################
	ORG 0
	GOTO INICIO
;________________________________________________________________
;################ VERIFICAR INTERRUPÇÃO
	ORG 4
	BCF INTCON,7				;desligar interrupções

;OBS: flag de cada interrupção muda mesmo com interrupção desativada, apenas não interrompem o código quando o valor delas é setado
;como nem todas as interrupções estão ligadas simultâneamente não basta checar a flag, precisa verificar se está ativada
	BTFSC INTCON,2 				;flag do timer está limpa?				flag timer==0?
	BTFSS INTCON,5				;não, o timer está ativado?				flag timer = 1 -> timer==1? (flag pode estar on com timer off)
	BTFSS INTCON,3 				;flag timer limpa ou timer off, tecla está on?			flag timer = 0 ou timer = 0 -> tecla==1?
	GOTO INTE_TIMER				;flag timer set e timer on, ou tecla off			(flag timer = 1 e timer = 1) ou tecla = 0	
	GOTO INTE_BOTAO				;flag timer limpa ou timer off, e tecla on			tecla = 1 e (flag timer = 0 ou timer = 0)
;________________________________________________________________


;________________________________________________________________													CONFIGURAÇÕES
;################ CONFIGURAÇÃO DO PWM PARA TRANSMITIR FREQUÊNCIA DAS NOTAS
CONF_PWM:
	BANKSEL TRISC
	CLRF TRISC					;colocar ccp1, rc0 e rc1 como output
								;ccp1 vai transmitir as ondas, rc1 será o led de gravação e rc0 será o led de transmissão
	BANKSEL CCP1CON
	MOVLW b'00101111'			;XX1011XX 	10 LSBs inicialmente  e modo pwm (11XX)
	MOVWF CCP1CON
	MOVLW b'01111010'			;Xxxx x01X prescaler como 16 (1x) e não ligar timer ainda, pois não deve mandar frequencia sem som
	MOVWF T2CON
	CLRF PORTC					;certificar que os leds estão desligados
	RETURN

;################ CONFIGURAÇÃO INICIAL DAS INTERRUPÇÕES
CONF_INTE:
	BANKSEL TRISB
	MOVLW b'01110000'			;setar pinos 0 a 3 como output e setar pinos 4, 5 e 6 como input para a interrupção
	MOVWF TRISB
	BANKSEL PORTB
	MOVLW b'00001111'			;mandar sinal alto para o teclado
	MOVWF PORTB
	MOVLW 	b'10001000' 		;ativar interrupção de porta (rb4 a rb6), interrompe sempre que essas portas mudarem de estado
								;timer desligado pois não está gravando e nem transmitindo inicialmente
	MOVWF INTCON
	BANKSEL OPTION_REG			;configurar option_reg antecipadamente para quando ligar o timer
	MOVLW b'11010111' 			;usar clock (0) e associar ao timer(0) , prescaler 256 (111) (16 interrupções por segundo)
	MOVWF OPTION_REG 			;XX0X0111
	RETURN

;################ CONFIGURAÇÃO DE CICLOS POR SEGUNDO
SETA_CICLO:
	MOVLW d'16'
	MOVWF CICLO_SEG	;CICLO_SEG=16 ciclos p/segundo
	RETURN
;________________________________________________________________


;________________________________________________________________													RESETAR VARIÁVEIS
;################ RESETA CICLOS
NOVO_CICLO:
	MOVLW d'16'
	MOVWF CICLOS				;16 ciclos completam 1 segundo						CICLO_SEG=16 ciclos p/segundo
	RETURN

;################ RESETA TEMPO DE GRAVAÇÃO
NOVO_SEG:
	MOVLW d'20'					;tempo máximo de gravação é 20 segundos				SEGUNDOS=20 
	MOVWF SEGUNDOS	
	RETURN

;################ RESETA TEMPO QUE A NOTA ESTÁ SENDO TOCADA
NOVA_NOTA:
	CLRF DURACAO_CICLO			
	CLRF DURACAO_SEG
	RETURN
;________________________________________________________________


;________________________________________________________________													MANIPULAR TIMER
;################ LIGAR INTERRUPÇÃO DO TIMER
LIGAR_TIMER:
	BANKSEL PORTC
	CALL NOVO_CICLO				;resetar ciclo
	CALL NOVO_SEG				;resetar segundos
	CALL NOVA_NOTA				;resetar duração que uma nota está sendo tocada
	MOVLW d'12' 				;valor do tmr0 para 16 ciclos por segundo					256-12=244		
	MOVWF TMR0
	BSF INTCON,5				;ligar interrupção timer
	BCF INTCON,2				;limpar flag do timer
	RETURN

;################ DESLIGAR INTERRUPÇÃO TIMER
DESLIGAR_TIMER:
	BANKSEL PORTC				
	BCF PORTC,1					;desliga led de gravação
	BCF PORTC,0					;desliga led de transmissão
	BCF INTCON,5 				;desliga interrupção do timer
	RETURN

;################ TRATAR INTERRUPÇÃO DO TIMER
INTE_TIMER:
	BCF INTCON,2				;limpa flag do timer
	BANKSEL PORTC
	BTFSS PORTC,1 				;verifica se está gravando através do led de gravação	led ligado?
	GOTO TOCANDO				;não está gravando, logo deve estar transmitindo
	GOTO GRAVANDO				;sim, está gravando

;################ RESETAR TIMER
FIM_CICLO:
	BANKSEL TMR0
	MOVLW d'12'					;resetar valor tmr0
	MOVWF TMR0
	GOTO FIM_INTE				;finaliza interrupção
;________________________________________________________________


;________________________________________________________________													MANIPULAR BUZZER
;################ SETAR NOTA
DO:
	MOVLW d'238'					;262 Hz (dó) precisa de pr2=238
	BANKSEL PR2
	MOVWF PR2				
;setar duty cycle em 50%
	BANKSEL CCPR1L
	MOVLW b'01110111'				;MSBs = 0111 0111
	MOVWF CCPR1L
	BSF CCP1CON,5					;LSBs = 10
;verficar se está gravando
	BTFSS PORTC,RC1					;led de gravação está ligado?
	GOTO TOCAR_BUZZER 				;não, tocar nota normalmente
;sim
	CALL TESTA_NOTA					;gravar na eeprom nota antiga e resetar valores para nota nova
	BSF NOTA,5						;setar nota atual como 1 considerando apenas o 3 bits iniciais NOTA=001 0 0000
;1 = DÓ
	GOTO TOCAR_BUZZER				;tocar nota

RE:
	MOVLW d'212'					;294 Hz (ré) precisa de pr2=212
	BANKSEL PR2
	MOVWF PR2
;setar duty cycle em 50%
	BANKSEL CCPR1L
	MOVLW b'01101010' 				;MSBs = 0110 1010
	MOVWF CCPR1L
	BSF CCP1CON,5					;LSBs = 10
;verficar se está gravando
	BTFSS PORTC,RC1					;led de gravação está ligado?
	GOTO TOCAR_BUZZER 				;não, tocar nota normalmente
;sim
	CALL TESTA_NOTA					;gravar na eeprom nota antiga e resetar valores para nota nova
	BSF NOTA,6						;setar nota atual como 2 considerando apenas o 3 bits iniciais NOTA=010 0 0000
;2 = RÉ
	GOTO TOCAR_BUZZER				;tocar nota

MI:
	MOVLW d'188'					;330 Hz (mi) precisa de pr2=188
	BANKSEL PR2
	MOVWF PR2
;setar duty cycle em 50%
	BANKSEL CCPR1L
	MOVLW b'01011110' 				;MSBs = 0101 1110
	MOVWF CCPR1L
	BSF CCP1CON,5					;LSBs = 10
;verficar se está gravando
	BTFSS PORTC,RC1					;led de gravação está ligado?
	GOTO TOCAR_BUZZER 				;não, tocar nota normalmente
;sim
	CALL TESTA_NOTA					;gravar na eeprom nota antiga e resetar valores para nota nova
	BSF NOTA,6
	BSF NOTA,5						;setar nota atual como 3 considerando apenas o 3 bits iniciais NOTA=011 0 0000
;3 = MI
	GOTO TOCAR_BUZZER				;tocar nota

FA:
	MOVLW d'178'					;349 Hz (fá) precisa de pr2=178
	BANKSEL PR2
	MOVWF PR2
;setar duty cycle em 50%
	BANKSEL CCPR1L
	MOVLW b'01011001' 				;MSBs = 0101 1001
	MOVWF CCPR1L				 
	BSF CCP1CON,5					;LSBs = 10
;verficar se está gravando
	BTFSS PORTC,RC1					;led de gravação está ligado?
	GOTO TOCAR_BUZZER 				;não, tocar nota normalmente
;sim
	CALL TESTA_NOTA					;gravar na eeprom nota antiga e resetar valores para nota nova
	BSF NOTA,7						;setar nota atual como 4 considerando apenas o 3 bits iniciais NOTA=100 0 0000
;4 = FA
	GOTO TOCAR_BUZZER				;tocar nota

SOL:
	MOVLW d'158'					;392 Hz (sol) precisa de pr2=158
	BANKSEL PR2
	MOVWF PR2
;setar duty cycle em 50%
	BANKSEL CCPR1L
	MOVLW b'01001111' 				;MSBs = 0100 1111
	MOVWF CCPR1L
	BSF CCP1CON,5					;LSBs = 10
;verficar se está gravando
	BTFSS PORTC,RC1					;led de gravação está ligado?
	GOTO TOCAR_BUZZER 				;não, tocar nota normalmente
;sim
	CALL TESTA_NOTA					;gravar na eeprom nota antiga e resetar valores para nota nova
	BSF NOTA,7
	BSF NOTA,5						;setar nota atual como 5 considerando apenas o 3 bits iniciais NOTA=101 0 0000
;5 = SOL
	GOTO TOCAR_BUZZER				;tocar nota

LA:
	MOVLW d'141'					;440 Hz (lá) precisa de pr2=141
	BANKSEL PR2
	MOVWF PR2
;setar duty cycle em 50%
	BANKSEL CCPR1L
	MOVLW b'01000111' 				;MSBs = 0100 0111
	MOVWF CCPR1L
	BCF CCP1CON,5					;LSBs = 00
;verficar se está gravando
	BTFSS PORTC,RC1					;led de gravação está ligado?
	GOTO TOCAR_BUZZER 				;não, tocar nota normalmente
;sim
	CALL TESTA_NOTA					;gravar na eeprom nota antiga e resetar valores para nota nova
	BSF NOTA,7
	BSF NOTA,6						;setar nota atual como 6 considerando apenas o 3 bits iniciais NOTA=110 0 0000
;6 = LA
	GOTO TOCAR_BUZZER				;tocar nota

SI:
	MOVLW d'125'					;494 Hz (sí) precisa de pr2=125
	BANKSEL PR2
	MOVWF PR2
;setar duty cycle em 50%
	BANKSEL CCPR1L
	MOVLW b'00111111' 				;MSBs = 0011 1111
	MOVWF CCPR1L
	BCF CCP1CON,5					;LSBs = 00
;verficar se está gravando
	BTFSS PORTC,RC1					;led de gravação está ligado?
	GOTO TOCAR_BUZZER 				;não, tocar nota normalmente
;sim
	CALL TESTA_NOTA					;gravar na eeprom nota antiga e resetar valores para nota nova
	BSF NOTA,7
	BSF NOTA,6
	BSF NOTA,5						;setar nota atual como 7 considerando apenas o 3 bits iniciais NOTA=111 0 0000
;7 = SI
	GOTO TOCAR_BUZZER				;tocar nota

;################ TRANSMITIR FREQUÊNCIA DE UMA NOTA PARA O BUZZER
TOCAR_BUZZER:
	BANKSEL T2CON
	BSF T2CON,2						;ligar timer do pwm para mandar frequência
	MOVLW b'00001111'				;setar bits para ligar o modo pwm (11XX)
	IORWF CCP1CON,1					;manter LSBs do duty cycle						1 ou x = 1 / 0 ou x = x
	BTFSS PORTC,0					;verifica se está transmitindo através do led de transmissão
	GOTO LOOP						;não, vai para o final da interrupção do botão
	GOTO TOCAR_NOTA					;sim, começa a contar o tempo que a nota está tocando

;################ PARAR DE TOCAR UMA NOTA
PARAR_BUZZER:
	BANKSEL T2CON
	BCF T2CON,2						;desligar timer do pwm
	MOVLW b'00000000'				;XX0000XX desabilitar modo pwm (0000)
	MOVWF CCP1CON
	BCF PORTC,2						;não mandar sinal para buzzer

;verficar se está gravando
	BTFSS PORTC,RC1					;led de gravação está ligado?
	RETURN							;não, prosseguir programa
	CALL TESTA_NOTA					;gravar na eeprom nota antiga e resetar valores para nota nova
	RETURN
;________________________________________________________________


;________________________________________________________________													LER TECLAS
;################ VERIFICAR QUAL BOTÃO FOI PRESSIONADO
INTE_BOTAO:
	BCF INTCON,3					;desligar interrupção de porta
	BANKSEL PORTB					;verificar qual pino recebeu sinal alto
	BTFSC PORTB,RB4 				;pino 4 está com sinal baixo?									RB4==0?
	GOTO DO_FA						;não, verificar qual botão da 1° linha foi pressionado			RB4=1
	BTFSC PORTB,RB5 				;sim, pino 5 está com sinal baixo?								RB5==0?
	GOTO LA_SI						;não, verificar qual botão da 2° linha foi pressionado			RB5=1
	BTFSC PORTB,RB6 				;sim, pino 6 está com sinal baixo?								RB6==0?
	GOTO GRAVACAO					;não, verificar qual botão da 3° linha foi pressionado			RB6=1
	
;se nenhum dos pinos estava com sinal alto, botão que antes tinha sido pressionado foi solto
	CALL PARAR_BUZZER				;parar de tocar pois não tem nenhuma tecla pressionada
;final da interrupção do botão
LOOP:
	MOVLW b'00001111'				;mandar sinal alto para pinos 0 a 3			
	BANKSEL PORTB					
	IORWF PORTB,1					;setar pinos r0 a rb3 sem alterar o valor dos pinos rb4 a rb6		1 ou x = 1 / 0 ou x = x
	BSF INTCON,3					;ligar interrupção de porta
FIM_INTE:
	BANKSEL PORTB
	MOVLW b'00001111'			;mandar sinal alto para pinos 0 a 3	
	IORWF PORTB,1				;setar pinos r0 a rb3 sem alterar o valor dos pinos rb4 a rb6		1 ou x = 1 / 0 ou x = x
	BCF INTCON,0				;limpar flag das portas
	BSF INTCON,7				;ligar interrupções
	RETFIE						

;################ VERIFICAR QUAL BOTÃO DA 1° LINHA FOI PRESSIONADO
DO_FA:
;dó, ré, mi ou fá
	BCF PORTB,RB0 				;parar de mandar sinal alto ao pino 0 para verificar se botão da coluna 1 foi pressionado
	BTFSS PORTB,RB4				;rb4 ainda está ligado?									RB4==1?
	GOTO DO 					;não, então botão da 1° coluna estava pressionado		RB4=0
	BSF PORTB,RB0 				;sim, continuar testando								RB4=1
	BCF PORTB,RB1 				;parar de mandar sinal alto ao pino 1 para verificar se botão da coluna 2 foi pressionado
	BTFSS PORTB,RB4				;rb4 ainda está ligado?									RB4==1?
	GOTO RE 					;não, então botão da 2° coluna estava pressionado		RB4=0
	BSF PORTB,RB1 				;sim, continuar testando								RB4=1
	BCF PORTB,RB2  				;parar de mandar sinal alto ao pino 2 para verificar se botão da coluna 3 foi pressionado
	BTFSS PORTB,RB4				;rb4 ainda está ligado?									RB4==1?
	GOTO MI 					;não, então botão da 3° coluna estava pressionado		RB4=0
	BSF PORTB,RB2 				;sim, continuar testando								RB4=1
	BCF PORTB,RB3  				;parar de mandar sinal alto ao pino 3 para verificar se botão da coluna 4 foi pressionado
	BTFSS PORTB,RB4				;rb4 ainda está ligado?									RB4==1?
	GOTO FA 					;não, então botão da 4° coluna estava pressionado		RB4=0
	BSF PORTB,RB0 				;sim, continuar testando								RB4=1
	CALL PARAR_BUZZER 			;caso não detectar nenhum dos botões pressionados ocorreu um erro, parar de tocar
	GOTO LOOP					;e ir para final da interrupção do botão

;################ VERIFICAR QUAL BOTÃO DA 2° LINHA FOI PRESSIONADO
LA_SI:
;sol, lá, sí ou record (gravar)
	BCF PORTB,RB0 				;parar de mandar sinal alto ao pino 0 para verificar se botão da coluna 1 foi pressionado
	BTFSS PORTB,RB5				;rb5 ainda está ligado?									RB5==1?
	GOTO SOL 					;não, então botão da 1° coluna estava pressionado		RB5=0
	BSF PORTB,RB0 				;sim, continuar testando								RB5=1
	BCF PORTB,RB1 				;parar de mandar sinal alto ao pino 1 para verificar se botão da coluna 2 foi pressionado
	BTFSS PORTB,RB5				;rb5 ainda está ligado?									RB5==1?
	GOTO LA 					;não, então botão da 2° coluna estava pressionado		RB5=0
	BSF PORTB,RB1 				;parar de mandar sinal alto ao pino 2 para verificar se botão da coluna 3 foi pressionado
	BCF PORTB,RB2 				;sim, continuar testando								RB5=1
	BTFSS PORTB,RB5				;rb5 ainda está ligado?									RB5==1?
	GOTO SI 					;não, então botão da 3° coluna estava pressionado		RB5=0
	BSF PORTB,RB2  				;sim, continuar testando								RB5=1 				
	BCF PORTB,RB3				;parar de mandar sinal alto ao pino 3 para verificar se botão da coluna 4 foi pressionado
	BTFSS PORTB,RB5				;rb5 ainda está ligado?									RB5==1?
	GOTO GRAVAR					;não, então botão da 4° coluna estava pressionado		RB5=0
	BSF PORTB,RB3 				;sim, continuar testando								RB5=1
	CALL PARAR_BUZZER			;caso não detectar nenhum dos botões pressionados ocorreu um erro, parar de tocar
	GOTO LOOP					;e ir para final da interrupção do botão

;################ VERIFICAR QUAL BOTÃO DA 3° LINHA FOI PRESSIONADO
GRAVACAO:
;stop (parar) ou play (tocar)
	BCF PORTB,RB0 				;parar de mandar sinal alto ao pino 0 para verificar se botão da coluna 1 foi pressionado
	BTFSS PORTB,RB6				;rb6 ainda está ligado?									RB6==1?	
	GOTO PARAR_GRAVACAO 		;não, então botão da 1° coluna estava pressionado		RB6=0
	BSF PORTB,RB0				;sim, continuar testando								RB6=1
	BCF PORTB,RB1 				;parar de mandar sinal alto ao pino 1 para verificar se botão da coluna 2 foi pressionado
	BTFSS PORTB,RB6				;rb6 ainda está ligado?									RB6==1?	
	GOTO TOCAR 					;não, então botão da 2° coluna estava pressionado		RB6=0
	BSF PORTB,RB1				;sim, continuar testando								RB6=1
	CALL PARAR_BUZZER			;caso não detectar nenhum dos botões pressionados ocorreu um erro, parar de tocar
	GOTO LOOP					;e ir para final da interrupção do botão
;________________________________________________________________


;________________________________________________________________													GRAVAÇÃO
;################ INICIAR GRAVAÇÃO
GRAVAR:
	CLRF NOTA_GRAV				;resetar nota_grav, apontar para endereço 0 na eeprom
	BSF PORTB,RB3				
	CALL SETA_CICLO				;setar número de ciclos por segundo
	CALL PARAR_BUZZER			;parar de tocar as notas
	BSF PORTC,RC1				;ligar led de gravação
	CALL LIGAR_TIMER 			;ligar timer
	GOTO LOOP					;final da interrupção de porta

;################ CONTAR TEMPO
GRAVANDO:
	CALL DURACAO				;contar tempo da nota atual tocando
	DECFSZ CICLOS,1				;--CICLOS=0?
	GOTO FIM_CICLO				;nao, resetar timer
	CALL NOVO_CICLO				;sim, reseta ciclo e aumenta segundo
	DECFSZ SEGUNDOS,1			;--SEGUNDOS=0? já passou 20 segundos?
	GOTO FIM_CICLO				;não, resetar timer
	GOTO PARAR_GRAVACAO			;sim, terminar gravação

;################ CONTAR TEMPO QUE A NOTA ATUAL ESTÁ TOCANDO
DURACAO:
	BANKSEL 0
	INCF DURACAO_CICLO 			;aumenta a quantidade de ciclos que a nota atual está tocando		DURACAO_CICLO++
	MOVF DURACAO_CICLO,0		;verificar se já passou 16 ciclos
	SUBWF CICLO_SEG,0			;se passaram 16 ciclos subtração vai dar 0			
	BTFSS STATUS,Z 				;DURACAO_CICLO==CICLO_SEG?
	RETURN						;não, continua programa
	CLRF DURACAO_CICLO 			;sim, reseta ciclo da nota atual									DURACAO_CICLO=0
	INCF DURACAO_SEG			;aumenta segundos da nota atual										DURACAO_SEG++
	RETURN

;################ GRAVA NOTA ANTERIOR NA EEPROM E RESETA VALORES PARA A NOVA NOTA
TESTA_NOTA:
	CLRW 						;W=0	
	SUBWF NOTA_GRAV,0			;verificar se já gravou uma nota antes
	BTFSS STATUS,2				;primeira nota a ser gravada?
	CALL SALVAR_NOTA			;não, salvar nota anterior na eeprom
	BANKSEL 0
	CLRF NOTA					;limpar valor da nota anterior
	INCF NOTA_GRAV,1			;incrementar o número de endereços a serem gravados
	CALL NOVA_NOTA				;resetar tempo que a nota anterior foi tocada
	RETURN

;################ SALVAR INFORMAÇÕES DA NOTA NA EEPROM
SALVAR_NOTA:
	BANKSEL 0

	MOVLW d'129'				;sem espaço para gravar mais dois registradores	(NOTA 129 SALVA  NO ENDERECO 128 E 129)
	SUBWF NOTA_GRAV,0			;W=notas gravadas-129, se !=0 tem espaço
;	BTFSC STATUS,2	;tem espaço?
;	GOTO CHEIO		;não, sem mais espaço

	DECF NOTA_GRAV,0			;endereço da nota a ser gravada é 1 a menos do que o número de endereços gravados	 W=NOTA_GRAV-1
	BANKSEL EECON1
	BTFSC EECON1,WR				;checa se está no meio de outra escrita
	GOTO $-1
	BANKSEL EEADR
	MOVWF EEADR					;endereço a ser gravado na eeprom
	BANKSEL 0
	MOVF NOTA,0					;ler nota
	IORWF DURACAO_SEG,0			;juntar a quantidade de segundos junto com a identificação da nota		
;NNN0 0000 || 000S SSSS = NNNS SSSS, onde NNN é a nota e S SSSS é o número de segundos
;OBS: como segundos podem ser no máximo 20 (10100 em binário), a identificação da nota guardada nos 3 bits iniciais não seria perdida

	BANKSEL EEDATA				
	MOVWF EEDATA				;valor que vai ser escrito na eeprom
	CALL ESCREVER				;escrever na eeprom
	BANKSEL 0
	INCF NOTA_GRAV,1			;incrementa o número de endereços gravados
	DECF NOTA_GRAV,0			;endereço a ser gravada é 1 a menos do que o número de endereços gravados	 		W=NOTA_GRAV-1
	BANKSEL EECON1
	BTFSC EECON1,WR				;checa se está no meio de outra escrita
	GOTO $-1
	BANKSEL EEADR
	MOVWF EEADR					;endereço a ser gravado na eeprom
	BANKSEL 0
	MOVF DURACAO_CICLO,0		;ler número de ciclos da nota
	BANKSEL EEDATA
	MOVWF EEDATA				;valor que vai ser escrito na eeprom
	CALL ESCREVER				;escrever na eeprom
	RETURN

;################ ESCRITA NA EEPROM
ESCREVER:
	BANKSEL EECON1
	BCF EECON1,EEPGD			;aponta para eeprom
	BSF EECON1,WREN				;permite escrita na eeprom
;5 INSTRUÇÕES ESPECIAIS
	MOVLW 0x55
	MOVWF EECON2
	MOVLW 0xAA
	MOVWF EECON2
	BSF EECON1,WR				;escrever na eeprom
ESPERA
	BTFSC   EECON1, WR			;escrita já foi finalizada?
	GOTO    ESPERA				;não, verificar de  novo
	BCF EECON1,WREN				;sim, desabilitar escrita na eeprom
	RETURN

;################ TERMINAR GRAVAÇÃO
PARAR_GRAVACAO:
	BANKSEL PORTC
	CALL TESTA_NOTA				;não, salvar última nota tocada											led ligado
CHEIO:
	BANKSEL PORTB
	DECF NOTA_GRAV,1			;decrementar número de notas gravadas por gravação terminou antes de mais algum endereço ser gravado
	DECF NOTA_GRAV,1			;último endereço com nota gravada é igual a número de endereços gravados - 1
	CALL DESLIGAR_TIMER			;desligar timer
	GOTO LOOP					;ir para final da interrupção de tecla
;________________________________________________________________


;________________________________________________________________													TRANSMISSÃO
;################ INICIAR TRASMISSÃO
TOCAR:
	CLRF NOTA_TOCA				;resetar endereços lidos na eeprom
	BSF PORTC,RC0				;ligar led de gravação
	BSF FLAG,0					;necessário ler nota na eeprom	
	BSF FLAG,1					;não ler ciclo na eeprom ainda
	CALL PARAR_BUZZER			;parar de tocar
	BCF INTCON,0				;limpar flag da interrupção de porta
	CALL LIGAR_TIMER			;ligar timer
	GOTO FIM_INTE				;sair da interrupção ser reativar interrupção de porta

;################ LER OU TOCAR NOTA
TOCANDO:
	BTFSS FLAG,0				;precisa ler na memória eeprom a nota a ser tocada e os segundos para tocá-la?		flag == 1?
	GOTO TOCAR_NOTA				;não, então pode tocar o valor que já foi lido										flag=0
	GOTO LER_NOTA				;sim, então ler na memória eeprom													flag=1

;################ LER NOTA E SEGUNDOS
LER_NOTA:
	BCF FLAG,0					;não é mais necessário ler a nota e os segundos
	BSF FLAG,1					;necessário ainda ler os ciclos na memória eeprom
	MOVF NOTA_TOCA,0			;quantidade de endereços já lidos
	BANKSEL EEADR
	MOVWF EEADR					;endereço a ser lido na memória eeprom
	CALL LEITURA				;leitura na eeprom

;converter valor lido em uma nota e número de segundos
	BANKSEL EEDATA				;eedata é o valor lido da eeprom
	MOVLW b'00011111'			;setar 5 bits finais de W, 1 && x = x / 0 && x = 0							W=0001 1111
	ANDWF EEDATA,0				;ler os 5 bits finais de EEDATA e salvar em W para não perder valores		W= EEDATA && W
	BANKSEL 0
	MOVWF SEGUNDOS				;SEGUNDOS=W
	BANKSEL EEDATA
								;nota gravada nos 3 bits iniciais EEDATA	EEDATA=NNNx xxxx, onde NNN é a nota
	SWAPF EEDATA,1				;trocar de lugar os bits					EEDATA=xxxx NNNx, onde NNN é a nota
	RRF	EEDATA,1				;rotacionar para a direita os bits			EEDATA=xxxx xNNN, onde NNN é a nota
	MOVLW b'00000111'			;setar os 3 bits finais de W												W=0000 0111
	ANDWF EEDATA,0				;ler os 3 bits finais de EEDATA, que antes era os 3 bits iniciais			W= EEDATA && W
	BANKSEL 0	
	MOVWF NOTA					;NOTA=W
	CALL NOVO_CICLO				;colocar ciclos/segundo como 16

;converter valor lido para uma nota a ser tocada
	INCF NOTA,1					;adicionar 1 ao valor da nota para pular quando chegar no 0					NOTA -> 1 a 8
	DECFSZ NOTA,1				;NOTA-- = 0? 	(NOTA-1 = 0?)
	GOTO NOT1					;não, continuar verificação
	CALL PARAR_BUZZER			;sim, parar de tocar nota
	GOTO TOCAR_NOTA				;começar a contar tempo que está tocando silêncio
NOT1:
	DECFSZ NOTA,1				;NOTA-- = 0?	(NOTA-1 = 1?)
	GOTO NOT_DO					;não, continuar verificação
	GOTO DO						;sim, tocar a nota dó
NOT_DO:
	DECFSZ NOTA,1				;NOTA-- = 0?	(NOTA-1 = 2?)
	GOTO NOT_RE					;não, continuar verificação
	GOTO RE						;sim, tocar a nota ré
NOT_RE:
	DECFSZ NOTA,1				;NOTA-- = 0?	(NOTA-1 = 3?)
	GOTO NOT_MI 				;não, continuar verificação
	GOTO MI						;sim, tocar a nota mi
NOT_MI:
	DECFSZ NOTA,1				;NOTA-- = 0?	(NOTA-1 = 4?)
	GOTO NOT_FA 				;não, continuar verificação
	GOTO FA						;sim, tocar a nota fa
NOT_FA:
	DECFSZ NOTA,1				;NOTA-- = 0?	(NOTA-1 = 5?)
	GOTO NOT_SOL 				;não, continuar verificação
	GOTO SOL					;sim, tocar a nota sol
NOT_SOL:
	DECFSZ NOTA,1				;NOTA-- = 0?	(NOTA-1 = 6?)
	GOTO NOT_LA 				;não, continuar verificação
	GOTO LA						;sim, tocar a nota fa
NOT_LA:
	GOTO SI						;NOTA-1 = 7, por eliminação

;################ LEITURA NA EEPROM
LEITURA:
	BANKSEL EECON1
	BCF EECON1, EEPGD			;aponta para eeprom data memory
	BSF EECON1, RD				;ler data memory
	RETURN

;################ CONTAR TEMPO QUE ESTÁ TOCANDO UMA NOTA		
TOCAR_NOTA:
	BANKSEL 0
	CLRW						;W=0
	SUBWF SEGUNDOS,0			;W=W-SEGUNDOS
	BTFSS STATUS,2				;verificar se não tem mais segundos para ficar tocando			SEGUNDOS==0?
	GOTO CICLO_NORMAL			;não, então ainda precisa tocar por alguns segundos
	GOTO CICLO_FINAL			;não, então não tem mais um segundo completo para continuar tocando

;################ TOCAR POR UM SEGUNDO OU NÚMERO DETERMINADO DE CICLOS	
CICLO_NORMAL:
	DECFSZ CICLOS,1				;CICLOS--=0?
	GOTO FIM_CICLO				;não, reseta timer pois não fez 16 ciclos
	CALL NOVO_CICLO				;sim, reseta o valor de ciclos
	DECFSZ SEGUNDOS,1			;diminui os segundos que faltam para tocar						SEGUNDOS-- =0?
	GOTO FIM_CICLO				;não, resetar timer
								;sim, prosseguir para ler ciclos
;################ LER PRÓXIMO ENDEREÇO
CICLO_FINAL:					
	BTFSC FLAG,1				;já leu os ciclos na memória eeprom?									flag==0?
	GOTO LER_CICLO				;não, ler ciclos na eeprom												flag=1
VERIFICA_NOTA:					;sim, verificar se existem mais notas para serem lidas					flag=0
	MOVF NOTA_GRAV,0			;último endereço com informações a serem lidas							W=NOTA_GRAV
	SUBWF NOTA_TOCA,0			;último endereço lido é igual a último endereço com informações?		W=NOTAS TOCADAS-W
	BTFSS STATUS,2				;NOTA_TOCA==NOTA_GRAV
	GOTO PROX_NOTA				;não, preparar para ler próxima nota
;sim, finalizar transmissão
	CALL PARAR_BUZZER			;parar de tocar a nota atual
	CALL DESLIGAR_TIMER			;desligar timer
	BSF INTCON,3				;ativar novamente as teclas
	BCF INTCON,0				;limpar flag interrupção porta
	GOTO FIM_INTE				;ir para fim da interrupção

;################ PREPARAR PARA LER PRÓXIMA NOTA
PROX_NOTA:
	BSF FLAG,0					;é necessário ler próxima nota na eeprom
	INCF NOTA_TOCA,1			;incrementar valor para ler o endereço seguinte
	GOTO FIM_CICLO				;resetar timer

;################ LER OS CICLOS NA EEPROM
LER_CICLO:
	INCF NOTA_TOCA,1 			;incrementar valor para ler o endereço seguinte
	MOVF NOTA_TOCA,0
	BANKSEL EEADR
	MOVWF EEADR					;endereço a ser lido na eeprom
	CALL LEITURA				;leitura na eeprom
	BANKSEL EEDATA
	INCF EEDATA,0				;aumentar número dos ciclos em 1 apenas para verificar se ciclos é = 0			W=EEDATA+1
	BANKSEL 0
	MOVWF CICLOS				;CICLOS=W
	INCF SEGUNDOS,1				;seta segundo como 1 para repetir o timer considerando os ciclos lidos em vez de 16 ciclos
	BCF FLAG,1					;já foi lido o valor do ciclo na eeprom
;teste se ciclos=0
	DECFSZ CICLOS,1				;verifica se ciclos era igual a 0 e restaura seu valor original					CICLOS--=0?
	GOTO FIM_CICLO				;não, fazer timer como se faltasse esse número de ciclos para dar 1 segundo
	GOTO VERIFICA_NOTA			;sim, verificar se existem mais nota para serem lidas
;________________________________________________________________	

;################  CONFIGURAR PIANO
INICIO:											
	CALL CONF_PWM			;configurar pwm do pic
	CALL CONF_INTE			;configurar interrupções
	GOTO $

END