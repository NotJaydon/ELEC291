$NOLIST
$MODLP51
$LIST

CLK                   EQU 22118400 					
TIMER0_RATE_LOW       EQU 2000   
TIMER0_RELOAD_LOW     EQU ((65536-(CLK/TIMER0_RATE_LOW)))  					
TIMER0_RATE_HIGH      EQU 2100
TIMER0_RELOAD_HIGH    EQU ((65536-(CLK/TIMER0_RATE_HIGH)))
SOUND_OUT             EQU P1.1
SEED_GENERATOR        EQU P4.5

; Reset vector
org 0000H
   ljmp Start
   
; Timer/Counter 0 overflow interrupt vector
org 0x000B
	ljmp Timer0_ISR

; These register definitions needed by 'math32.inc'
DSEG at 30H
x:   ds 4
y:   ds 4
Seed: ds 4
bcd: ds 5

BSEG
tone: dbit 1
mf: dbit 1
game: dbit 1

$NOLIST
$include(math32.inc)
$include(LCD_4bit.inc)
$LIST

CSEG
; These 'equ' must match the hardware wiring
LCD_RS equ P2.6
;LCD_RW equ PX.X ; Not used in this code, connect the pin to GND
LCD_E  equ P2.7
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P2.5
LCD_D7 equ P2.3

; Initializes timer/counter 0 as a 16-bit timer
InitTimer0:
	mov a, TMOD
	anl a, #0x00
	orl a, #0x01
	mov TMOD, a
	setb ET0
	; Disable timer so that transducer does not produce sound
	clr TR0
	ret
	
Timer0_ISR:
	cpl SOUND_OUT
	reti

InitTimer2:
    mov T2CON, #0
    mov RCAP2H, #0
    mov RCAP2L, #0
    clr ET2
    clr TR2
    ret

;---------------------------------;
; Hardware initialization         ;
;---------------------------------;
Initialize_All:
	lcall InitTimer0
    lcall InitTimer2
    setb EA
	ret

Initial_Seed:
	setb TR2
    jb SEED_GENERATOR, $
    mov Seed+0, TH2
    mov Seed+1, #0x20
    mov Seed+2, #0x81
    mov Seed+3, TL2
    clr TR2
	ret
;---------------------------------;
; Main program loop               ;
;---------------------------------;

Random:
    mov x+0, Seed+0
    mov x+1, Seed+1
    mov x+2, Seed+2
    mov x+3, Seed+3
    Load_y(214013)
    lcall mul32
    Load_y(2531011)
    lcall add32
    mov Seed+0, x+0
    mov Seed+1, x+1
    mov Seed+2, x+2
    mov Seed+3, x+3
    ret 

Wait_Random:
    Wait_Milli_Seconds(Seed+0)
    Wait_Milli_Seconds(Seed+1)
    Wait_Milli_Seconds(Seed+2)
    Wait_Milli_Seconds(Seed+3)
    Wait_Milli_Seconds(Seed+0)
    Wait_Milli_Seconds(Seed+1)
    Wait_Milli_Seconds(Seed+2)
    Wait_Milli_Seconds(Seed+3)
    Wait_Milli_Seconds(Seed+0)
    Wait_Milli_Seconds(Seed+1)
    Wait_Milli_Seconds(Seed+2)
    Wait_Milli_Seconds(Seed+3)
    Wait_Milli_Seconds(Seed+0)
    Wait_Milli_Seconds(Seed+1)
    Wait_Milli_Seconds(Seed+2)
    Wait_Milli_Seconds(Seed+3)
    Wait_Milli_Seconds(Seed+0)
    Wait_Milli_Seconds(Seed+1)
    Wait_Milli_Seconds(Seed+2)
    Wait_Milli_Seconds(Seed+3)
   	Wait_Milli_Seconds(Seed+0)
    Wait_Milli_Seconds(Seed+1)
    Wait_Milli_Seconds(Seed+2)
    Wait_Milli_Seconds(Seed+3)
    ret
    
Game_Select:
	mov TMOD, #20H
	mov TH1, #-6
	mov SCON, #50H
	setb TR1
Wait:
	jnb RI, Wait
	mov a, SBUF
	mov x+0, a
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
	Load_y(#1)
	lcall x_eq_y
	ret

Start:
    ; Initialize the hardware:
    lcall Game_Select
    lcall Initialize_All
    jb mf, Rapid_Touch
    
Sound_Off:
    lcall Initial_Seed

forever:
    lcall Random
    mov a, Seed+1
    mov c, acc.3
    mov tone, c
    jc tone_high

tone_low:
    mov TH0, #high(TIMER0_RELOAD_LOW)
	mov TL0, #low(TIMER0_RELOAD_LOW)
	; Set autoreload value
	mov RH0, #high(TIMER0_RELOAD_LOW)
	mov RL0, #low(TIMER0_RELOAD_LOW)
    lcall Wait_Random
    setb TR0
    sjmp tone_off

tone_high:
    mov TH0, #high(TIMER0_RELOAD_HIGH)
    mov TH1, #high(TIMER0_RELOAD_HIGH)
    ; Set autoreload value
	mov RH0, #high(TIMER0_RELOAD_HIGH)
	mov RL0, #low(TIMER0_RELOAD_HIGH)
    lcall Wait_Random
    setb TR0
    sjmp tone_off

tone_off:
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#100)
    clr TR0
    sjmp forever
    
Rapid_Touch:
	sjmp Rapid_Touch
end