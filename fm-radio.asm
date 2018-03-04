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
    rcall btn_left
    sbis PIND, 3
    rcall btn_right
    sbrs r23, 3
    sbi PORTB, 3
    sbrc r23, 3
    sbi PORTB, 2
    ldi r16, 10
    rcall delay_4ms
    cbi PORTB, 3
    cbi PORTB, 2
    ldi r16, 60
    rcall delay_4ms
    ret

fm_reset:
    ldi r20, 0xC0 ; control and seek
    ldi r21, 0x03 ; modes and reset
    ldi r22, 0x04 ; volume up to 0x0F
    ldi r23, 0x03 ; band 0x03 or 0x0F
    ldi r24, 0x08 ; sensitivity up to 0x0F
    rcall fm_command
    ldi r21, 0x0D
    ret

btn_left:
    sbi PORTB, 1
    ldi r16, 150
    rcall delay_4ms
    sbic PIND, 3
    rjmp btn_left_single
    rcall fm_switch_band
    rjmp btn_left_tune
    btn_left_single:
    sbic PIND, 2
    rjmp btn_left_tune
    btn_left_vol:
    ldi r16, 150
    rcall delay_4ms
    sbic PIND, 2
    rjmp btn_left_done
    rcall fm_vol_decr
    rjmp btn_left_vol
    btn_left_tune:
    rcall fm_prev
    btn_left_done:
    ldi r16, 0
    rcall leds_4bit
    ret

btn_right:
    sbi PORTB, 0
    ldi r16, 150
    rcall delay_4ms
    sbic PIND, 3
    rjmp btn_right_tune
    btn_right_sense:
    ldi r16, 150
    rcall delay_4ms
    sbic PIND, 3
    rjmp btn_right_done
    rcall fm_sensitivity
    rjmp btn_right_sense
    btn_right_tune:
    rcall fm_next
    btn_right_done:
    ldi r16, 0
    rcall leds_4bit
    ret

fm_prev:
    ldi r20, 0xC1
    rcall fm_command
    rcall fm_wait_seek
    ret

fm_next:
    ldi r20, 0xC3
    rcall fm_command
    rcall fm_wait_seek
    ret

fm_wait_seek:
    push r16
    push r17
    fm_wait_seek_0:
    ldi r16, 50
    rcall delay_4ms
    rcall fm_status
    sbrs r17, 6
    rjmp fm_wait_seek_0
    push r17
    mov r17, r16
    ldi r16, 0
    rcall leds_4bit
    ldi r16, 50
    rcall delay_4ms
    pop r16
    lsl r16
    bst r17, 7
    bld r16, 0
    rcall leds_3bit
    mov r16, r17
    swap r16
    rcall leds_3bit
    mov r16, r17
    lsr r16
    rcall leds_3bit
    pop r17
    pop r16
    ret

fm_vol_decr:
    push r16
    cpi r22, 0
    brne fm_vol_decr_norm
    ldi r22, 16
    fm_vol_decr_norm:
    ldi r20, 0xC0
    dec r22
    rcall fm_command
    mov r16, r22
    rcall leds_4bit
    pop r16
    ret

fm_sensitivity:
    push r16
    cpi r24, 0
    brne fm_sense_decr_norm
    ldi r24, 16
    fm_sense_decr_norm:
    dec r24
    mov r16, r24
    rcall leds_4bit
    pop r16
    ret

fm_switch_band:
    push r16
    fm_switch_band_wait:
    in r16, PIND
    com r16
    andi r16, (1 << 3) | (1 << 2)
    brne fm_switch_band_wait
    ldi r16, 0x0C
    eor r23, r16
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
    ldi r16, 0x00
    rcall i2c_write
    mov r16, r23
    rcall i2c_write
    ldi r16, 0x04
    rcall i2c_write
    ldi r16, 0x00
    rcall i2c_write
    ldi r16, 0x80
    or r16, r24
    rcall i2c_write
    ldi r16, 0x80
    or r16, r22
    rcall i2c_write
    rcall i2c_stop
    pop r16
    ret

fm_status:
    rcall i2c_start
    ldi r16, (0x10 << 1) | 1
    rcall i2c_write
    set
    rcall i2c_read
    mov r17, r16
    clt
    rcall i2c_read
    rcall i2c_stop
    ret

leds_4bit:
    push r16
    push r17
    in r17, PORTB
    andi r17, 0xF0
    or r17, r16
    out PORTB, r17
    pop r17
    pop r16
    ret

leds_3bit:
    push r16
    andi r16, 7
    brne leds_3bit_nz
    ldi r16, 8
    leds_3bit_nz:
    rcall leds_4bit
    ldi r16, 150
    rcall delay_4ms
    ldi r16, 0
    rcall leds_4bit
    ldi r16, 50
    rcall delay_4ms
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

i2c_read:
    push r17
    ldi r17, 8
    rcall sda_hi
    i2c_rd_0:
    rcall scl_hi
    lsl r16
    sbic PINB, 5
    inc r16
    rcall scl_lo
    dec r17
    brne i2c_rd_0
    brtc i2c_read_skip_ack
    rcall sda_lo
    i2c_read_skip_ack:
    rcall scl_hi
    rcall scl_lo
    rcall sda_lo
    pop r17
    ret

i2c_delay:
    push r16
    ldi r16, 7
    i2c_delay_0:
    dec r16
    brne i2c_delay_0
    pop r16
    ret

scl_lo:
    sbi DDRB, 7
    rcall i2c_delay
    ret

scl_hi:
    cbi DDRB, 7
    rcall i2c_delay
    ret

sda_lo:
    sbi DDRB, 5
    rcall i2c_delay
    ret

sda_hi:
    cbi DDRB, 5
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

