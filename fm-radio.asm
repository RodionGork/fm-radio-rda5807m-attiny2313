.DEVICE attiny2313

#define RAMSIZE (32 + 64 + 128)
#define RAMEND (RAMSIZE - 1)
#define PORTB 0x18
#define DDRB 0x17
#define PINB 0x16
#define PORTD 0x12
#define DDRD 0x11
#define PIND 0x10
#define SPL 0x3D

start:
    ldi r16, RAMEND
    out SPL, r16
    
    rcall setup
    
    again:
    rcall main_loop
    rjmp again

setup:
    ldi r16, (0xF << 0)
    out DDRB, r16
    ldi r16, (1 << 2) | (1 << 3)
    out PORTD, r16
    rcall i2c_init
    rcall fm_reset
    ret

main_loop:
    sbis PIND, 2
    rcall fm_prev
    sbis PIND, 3
    rcall fm_next
    sbi PORTB, 3
    ldi r16, 50
    rcall delay_4ms
    cbi PORTB, 3
    ldi r16, 200
    rcall delay_4ms
    ret

fm_reset:
    ldi r20, 0xC0
    ldi r21, 0x03
    ldi r22, 0x00
    ldi r23, 0x03
    rcall fm_command
    ret

fm_prev:
    push r16
    sbi PORTB, 1
    ldi r16, 100
    rcall delay_4ms
    cbi PORTB, 1
    ldi r20, 0xC1
    ldi r21, 0x0D
    ldi r22, 0x00
    ldi r23, 0x03
    rcall fm_command
    pop r16
    ret

fm_next:
    push r16
    sbi PORTB, 0
    ldi r16, 100
    rcall delay_4ms
    cbi PORTB, 0
    ldi r20, 0xC3
    ldi r21, 0x0D
    ldi r22, 0x00
    ldi r23, 0x03
    rcall fm_command
    pop r16
    ret

fm_command:
    push r16
    rcall i2c_start
    ldi r16, (0x10 << 1) | 0
    rcall i2c_write
    mov r16, r20
    rcall i2c_write
    mov r16, r21
    rcall i2c_write
    mov r16, r22
    rcall i2c_write
    mov r16, r23
    rcall i2c_write
    rcall i2c_stop
    pop r16
    ret

i2c_init:
    cbi PORTB, 7
    cbi PORTB, 5
    rcall scl_hi
    rcall sda_hi
    ret

i2c_start:
    rcall sda_lo
    rcall scl_lo
    ret

i2c_stop:
    rcall scl_hi
    rcall sda_hi
    ret

i2c_write:
    push r17
    ldi r17, 8
    i2c_wr_0:
    sbrc r16, 7
    rcall sda_hi
    sbrs r16, 7
    rcall sda_lo
    rcall scl_hi
    rcall scl_lo
    lsl r16
    dec r17
    brne i2c_wr_0
    rcall sda_hi
    rcall scl_hi
    sbis PINB, 5
    ldi r16, 1
    rcall scl_lo
    pop r17
    ret

i2c_delay:
    push r16
    ldi r16, 7
    i2c_delay_0:
    dec r16
    brne i2c_delay_0
    ;ldi r16, 150
    ;rcall delay_4ms
    pop r16
    ret

scl_lo:
    sbi DDRB, 7
    ;cbi PORTB, 1
    rcall i2c_delay
    ret

scl_hi:
    cbi DDRB, 7
    ;sbi PORTB, 1
    rcall i2c_delay
    ret

sda_lo:
    sbi DDRB, 5
    ;cbi PORTB, 0
    rcall i2c_delay
    ret

sda_hi:
    cbi DDRB, 5
    ;sbi PORTB, 0
    rcall i2c_delay
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

