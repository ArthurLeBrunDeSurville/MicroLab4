; Receive signal from the PC with USART communication and send it to the shift register connected to a bar LED using SPI communication

.include "m324padef.inc" 				; Include Atmega324a definition

.org 0x0000
RJMP RESET_HANDLER 
.org 0x0028
RJMP RECEIVE_COMPLETE

.def shiftData = r20 				; Define the shift data register
.equ clearSignalPort = PORTB 			; Set clear signal port to PORTB
.equ clearSignalPin = 0 			; Set clear signal pin to pin 0 of PORTB
.equ shiftClockPort = PORTB 			; Set shift clock port to PORTB
.equ shiftClockPin = 7
.equ shiftDataPin = 5
.equ SCK = 7 				; Set shift clock pin to pin 1 of PORTB
.equ latchPort = PORTB 				; Set latch port to PORTB
.equ latchPin = 1 				; Set latch pin to pin 1 of PORTB
.equ shiftDataPort = PORTB 			; Set shift data port to PORTB
.equ MOSI = 5 				; Set shift data pin to pin 5 of PORTB
.equ SS = 4
.equ SPE = 6
.equ MSTR = 4
.equ SPR0 = 0
.equ SPR1 = 1
.equ SPRX = 0
.equ SPCR = 0x2C  ; I/O address
.equ SPDR = 0x2E  ; I/O address
.equ SPSR = 0X2D  ; I/O address
.equ SPIF = 7
.equ RXCIEN0 = 7




.macro  INIT_SP
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
.endmacro
.cseg
RESET_HANDLER:
	INIT_SP
	CALL SPI_MAS_INIT
	call cleardata
	CALL USART_INIT
	SEI       ; ENABLE global interrupt
	
MAIN:	
	call usart_sendchar
	call cleardata

	call receive_complete
	call shiftoutdata
	CALL USART_RECEIVECHAR

	RJMP MAIN
						; Initialize ports as outputs

	
cleardata:
	cbi clearSignalPort, clearSignalPin 	; Set clear signal pin to low
						; Wait for a short time
	sbi clearSignalPort, clearSignalPin 	; Set clear signal pin to high
	NOP
	ret

; Shift out data
shiftoutdata:
	cbi shiftClockPort, shiftClockPin ;
	ldi r17, 8 ; Shift 8 bits
	shiftloop:
		sbrc shiftData, 7 ; Check if the MSB of shiftData is 1
		sbi shiftDataPort, shiftDataPin ; Set shift data pin to high
		sbi shiftClockPort, shiftClockPin ; Set shift clock pin to high
		lsl shiftData ; Shift left
		cbi shiftClockPort, shiftClockPin ; Set shift clock pin to low
		cbi shiftDataPort, shiftDataPin ; Set shift data pin to low
		dec r18
		brne shiftloop
		; Latch data
		sbi latchPort, latchPin ; Set latch pin to high
		cbi latchPort, latchPin ; Set latch pin to low
ret

SPI_MAS_INIT : 
	PUSH R20
	LDI R20, (1 << MOSI) | (1 << SCK) | (1 << SS)|(1<<clearSignalPin)|(1<<latchPin)
	OUT DDRB, R20

	LDI R20,  (1 << SPE) | (1 << MSTR) | (1 << SPR0)
	OUT SPCR, R20

	POP R20
	RET

SPI_TRANSMISSION :
	PUSH R20
	CBI PORTB, SS
	 ; R17 = SEND DATA
	OUT SPDR, R17
WAIT_SPI : 
	IN R20, SPSR
	SBRS R20, SPIF
	RJMP WAIT_SPI
	IN R18, SPDR    ; R18 = RECEIVED DATA
	ldi r19,32
	sub r18,r19
	SBI PORTB, SS
	CBI PORTB, latchPin 
	NOP
	SBI PORTB, latchPin
	POP R20
	RET 

RECEIVE_COMPLETE :
	MOV R17, R16
	CALL SPI_TRANSMISSION
	RET	
			
USART_INIT:
	; SET BAUD RATE TO 9600 BPS WITH 8 MHZ CLOCK
	LDI R16, 103
	STS UBRR0L, R16
	; SET FRAME FORMAT: 8 DATA BITS, NO PARITY, 1 STOP BIT
	LDI R16, (1 << UCSZ01) | (1 << UCSZ00) 
	STS UCSR0C, R16
	;set double speed
	ldi r16, (1 << U2X0)
	sts UCSR0A, r16
	; ENABLE TRANSMITTER AND RECEIVER
	LDI R16, (1 << RXEN0) | (1 << TXEN0) | (1 << RXCIEN0)
	STS UCSR0B, R16
	RET

;SEND OUT 1 BYTE IN R16
USART_SENDCHAR:
	PUSH R17
; WAIT FOR THE TRANSMITTER TO BE READY
USART_SENDCHAR_WAIT:
	LDS R17, UCSR0A
	SBRS R17, UDRE0 	;CHECK USART DATA REGISTER EMPTY BIT
	RJMP USART_SENDCHAR_WAIT
	STS UDR0, R16 		;SEND OUT
	POP R17
	RET

;RECEIVE 1 BYTE IN R16
USART_RECEIVECHAR:
	PUSH R17
; WAIT FOR THE TRANSMITTER TO BE READY
USART_RECEIVECHAR_WAIT:

	LDS R17, UCSR0A
	SBRS R17, RXC0 ;CHECK USART RECEIVE COMPLETE BIT
	RJMP USART_RECEIVECHAR_WAIT

	LDS R16, UDR0 ;GET DATA
	OUT PORTA, R16

	POP R17
	RET
