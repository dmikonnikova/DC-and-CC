.include "m8def.inc"

;Константы для настройки USART
.equ BAUD = 115200
.equ freq = 8000000
.equ UBBRVALUEV = freq/(16*BAUD)-1

;Настройка интревалов Таймеров
.equ TIMER1_INTERVAL = 235
.equ TIMER2_INTERVAL = 250

.cseg  
;Основная программа
.org 0x000                          
rjmp MAIN  
;Прерывание Timer0                         
.org $009                            
rjmp TIM0_OVF   
;Прерывание Timer2                    
.org $004                           
rjmp TIM2_OVF                      

;Слова
ping:
    .db "ping\r\n", 0 ,0
pong:
    .db "pong\r\n", 0 ,0

;Инициализация стека
RESET:
    ldi r16, HIGH(RAMEND)
    out SPH, r16
    ldi r16, LOW(RAMEND)
    out SPL, r16


;Настройка Timer0
TIMER0_SET:
	;Начальное значение Timer0 (Интервал)
    ldi r16, TIMER0_INTERVAL
    out TCNT0, r16    
	;Запуск Timer0   
    ldi r16, 0b111          
    out TCCR0, r16         
	;Разрешить прерывания по переполнению Таймеров
    ldi r16, 0b101          
    out TIMSK, r16
    ret

;Настройка Timer2
TIMER2_SET:
	;Начальное значение Timer2 (Интервал)
    ldi r16, TIMER2_INTERVAL
    out TCNT2, r16
	;Запуск Timer2
    ldi r16, 0b101          
    out TCCR2, r16  
	;Разрешить прерывания по переполнению таймеров 
    ldi r16, 0x41
    out TIMSK, r16
    ret

;Настройка USART
init_USART: 
    ;Загрузка количества BAUD 
    ldi r16, high(UBBRVALUEV)
    out UBRRH, r16

    ldi r16, low(UBBRVALUEV)
    out UBRRL, r16

	;Разрешение на передачу
    ldi r16, (1<<TXEN)
    out UCSRB, r16
    ldi r16, (1<<URSEL)|(1<<UCSZ0)|(1<<UCSZ1)
    out UCSRC, r16
    ret

;Отправка байта
TRANSMIT_BYTE:
    sbis UCSRA, UDRE
    rjmp TRANSMIT_BYTE 
    out UDR, r17
    ret 

;Отправка первого сообщения
START_SEND_PING:
	;Установить время срабатывания (Интервал)
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

;Отправка второго сообщения
START_SEND_PONG:
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
    
;Главная программа
MAIN:
    rcall RESET
    rcall init_USART
    rcall TIMER1_SETUP
    rcall TIMER2_SETUP
    sei
LOOP:
    rjmp LOOP

;Прерывание Timer0
TIM0_OVF:
    sei
    rcall START_SEND_PING
    reti

;Прерывание Timer2
TIM2_OVF:
    sei
    rcall START_SEND_PONG
    reti
