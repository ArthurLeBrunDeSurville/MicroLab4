.include "m324padef.inc"
; Replace with your application code
.ORG 0
JMP MAIN
.ORG 0x40

MAIN:
 call USART_Init

start:
 call USART_ReceiveChar
 call USART_SendChar
 rjmp start

;init UART 0
;CPU clock is 1Mhz
USART_Init:
	; Set baud rate to 9600 bps with 8 MHz clock
	ldi r16, 103
	sts UBRR0L, r16
	;set double speed
	ldi r16, (1 << U2X0)
	sts UCSR0A, r16
	; Set frame format: 8 data bits, no parity, 1 stop bit
	ldi r16, (1 << UCSZ01) | (1 << UCSZ00)
	sts UCSR0C, r16
	; Enable transmitter and receiver
	ldi r16, (1 << RXEN0) | (1 << TXEN0)
	sts UCSR0B, r16
	ret

;send out 1 byte in r16
USART_SendChar:
	push r17

	; Wait for the transmitter to be ready
	USART_SendChar_Wait:
	lds r17, UCSR0A
	sbrs r17, UDRE0 ;check USART Data Register Empty bit
	rjmp USART_SendChar_Wait
	sts UDR0, r16 ;send out
	pop r17
	ret

;receive 1 byte in r16
USART_ReceiveChar:
	push r17
	; Wait for the transmitter to be ready
	USART_ReceiveChar_Wait:
	lds r17, UCSR0A
	sbrs r17, RXC0 ;check USART Receive Complete bit
	rjmp USART_ReceiveChar_Wait
	lds r16, UDR0 ;get data
	pop r17
	ret
