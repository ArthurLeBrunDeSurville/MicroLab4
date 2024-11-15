;
; AssemblerApplication1.asm
;
; Created: 12/11/2024 18:11:28
; Author : ArthurLBDS
;



INIT:
; set timer 2 as asynchronous to generate 1Hz signal
LDI R16, (1<<CS21)|(1<<CS20)  ; prescaler clk/32 for 1Hz signal
STS TCCR2B, R16
LDI R16, (1<<AS2)
STS ASSR, R16


SEND_START_CONDITION:

/*
TWINT -> This bit is set by hardware when the TWI has finished its current job and expects application software response.
If the I-bit in SREG and TWIE in TWCR are set, the MCU will jump to the TWI Interrupt Vector. While the TWINT
Flag is set, the SCL low period is stretched. The TWINT Flag must be cleared by software by writing a logic one
to it. Note that this flag is not automatically cleared by hardware when executing the interrupt routine.

TWSTA -> The application writes the TWSTA bit to one when it desires to become a Master on the two-wire Serial Bus.
The TWI hardware checks if the bus is available, and generates a START condition on the bus if it is free.
However, if the bus is not free, the TWI waits until a STOP condition is detected, and then generates a new
START condition to claim the bus Master status. TWSTA must be cleared by software when the START
condition has been transmitted.

TWEN -> The TWEN bit enables TWI operation and activates the TWI interface. When TWEN is written to one, the TWI
takes control over the I/O pins connected to the SCL and SDA pins, enabling the slew-rate limiters and spike
filters. If this bit is written to zero, the TWI is switched off and all TWI transmissions are terminated, regardless of
any ongoing operation
*/

	PUSH R16
	LDI R16, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
	STS TWCR, R16
	POP R16
	RET


STOP_CONDITION:
/*
TWSTO -> Writing the TWSTO bit to one in Master mode will generate a STOP condition on the two-wire Serial Bus. When
the STOP condition is executed on the bus, the TWSTO bit is cleared automatically
*/
	PUSH R16
	LDI R16, (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
	STS TWCR, r16
	POP R16
	RET 
