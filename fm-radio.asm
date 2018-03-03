.DEVICE attiny2313

#define RAMSIZE (32 + 64 + 128)
#define RAMEND (RAMSIZE - 1)
#define PORTB 0x18
#define DDRB 0x17
#define PINB 0x16
#define SPL 0x3D

start:
    ldi r16, RAMEND
    out SPL, r16
    
    rcall setup
    
    again:
    rcall main_loop
    rjmp again

setup:
    ldi r16, (1 << 0)
    out DDRB, r16
    ret

main_loop:
    ldi r16, (1 << 0)
    out PORTB, r16
    ldi r16, 100
    rcall delay_4ms
    ldi r16, 0
    out PORTB, r16
    ldi r16, 150
    rcall delay_4ms
    ret

delay_4ms:
    push r17
    push r18
    delay_0:
    ldi r17, 50
    delay_1:
    ldi r18, 26
    delay_2:
    dec r18
    brne delay_2
    dec r17
    brne delay_1
    dec r16
    brne delay_0
    pop r18
    pop r17
    ret

