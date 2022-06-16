.include "m8def.inc"

;��������� ��� ��������� USART
.equ BAUD = 115200
.equ freq = 8000000
.equ UBBRVALUEV = freq/(16*BAUD)-1
;��������� ���������� ��������
.equ TIMER1_INTERVAL = 235
.equ TIMER2_INTERVAL = 250

.cseg  
;�������� ���������
.org 0x000                          
rjmp MAIN  
;���������� Timer0                         
.org $009                            
rjmp TIM0_OVF   
;���������� Timer2                    
.org $004                           
rjmp TIM2_OVF                      

;�����
ping:
    .db "ping\r\n", 0 ,0
pong:
    .db "pong\r\n", 0 ,0

;������������� �����
RESET:
    ldi r16, HIGH(RAMEND)
    out SPH, r16
    ldi r16, LOW(RAMEND)
    out SPL, r16


;��������� Timer0
TIMER0_SET:
	;��������� �������� Timer0 (��������)
    ldi r16, TIMER0_INTERVAL
    out TCNT0, r16    
	;������ Timer0   
    ldi r16, 0b111          
    out TCCR0, r16         
	;��������� ���������� �� ������������ ��������
    ldi r16, 0b101          
    out TIMSK, r16
    ret

;��������� Timer2
TIMER2_SET:
	;��������� �������� Timer2 (��������)
    ldi r16, TIMER2_INTERVAL
    out TCNT2, r16
	;������ Timer2
    ldi r16, 0b101          
    out TCCR2, r16  
	;��������� ���������� �� ������������ ��������     
    ldi r16, 0x41
    out TIMSK, r16
    ret

;��������� USART
init_USART: 
    ;�������� ���������� BAUD 
    ldi r16, high(UBBRVALUEV)
    out UBRRH, r16

    ldi r16, low(UBBRVALUEV)
    out UBRRL, r16

    ldi r16, (1<<TXEN);��������� ��������
    out UCSRB, r16
    ldi r16, (1<<URSEL)|(1<<UCSZ0)|(1<<UCSZ1)
    out UCSRC, r16
    ret

;�������� �����
TRANSMIT_BYTE:
    sbis UCSRA, UDRE
    rjmp TRANSMIT_BYTE 
    out UDR, r17
    ret 

;�������� ������� ���������
START_SEND_PING:
	;���������� ����� ������������ (��������)
    ldi r18, TIMER1_INTERVAL
    out TCNT0, r18

    ldi ZH, high(ping)
    ldi ZL, low(ping)
    add ZL,ZL
    adc ZH,ZH
PING_SEND:
    lpm r17, Z+
    cpi r17, 0
    breq ENDS_PING 
    rcall TRANSMIT_BYTE 
    rjmp PING_SEND
ENDS_PING:
    ret

;�������� ������� ���������
START_SEND_PONG:
	;���������� ����� ������������ (��������)
    ldi r19, TIMER2_INTERVAL
    out TCNT2, r19

    ldi ZH, high(pong)
    ldi ZL, low(pong)
    add ZL,ZL
    adc ZH,ZH
BYTE_PONG:
    lpm r17, Z+
    cpi r17, 0
    breq ENDS_PONG 
    rcall TRANSMIT_BYTE 
    rjmp BYTE_PONG
ENDS_PONG:
    ret
    
;������� ���������
MAIN:
    rcall RESET
    rcall init_USART
    rcall TIMER1_SETUP
    rcall TIMER2_SETUP
    sei
LOOP:
    rjmp LOOP

;���������� Timer0
TIM0_OVF:
    sei
    rcall START_SEND_PING
    reti

;���������� Timer2
TIM2_OVF:
    sei
    rcall START_SEND_PONG
    reti