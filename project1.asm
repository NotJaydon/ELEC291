$NOLIST
$MODLP51
$LIST


CLK           EQU 22118400 ; Microcontroller system crystal frequency in Hz
TIMER0_RATE   EQU 2     ; 2048Hz squarewave (peak amplitude of CEM-1203 speaker)
TIMER0_RELOAD EQU ((65536-(CLK/TIMER0_RATE)))

TIMER1_RATE   EQU 1000     ; 1000Hz, for a timer tick of 1ms
TIMER1_RELOAD EQU ((65536-(CLK/TIMER1_RATE)))



org 0000H
   ljmp MyProgram
   
; Timer/Counter 1 overflow interrupt vector
org 0x001B
	ljmp Timer1_ISR
   
; Timer/Counter 2 overflow interrupt vector
org 0x002B
	ljmp Timer2_ISR

; These register definitions needed by 'math32.inc'
DSEG at 30H
x:   ds 4
y:   ds 4
bcd: ds 5
T2ov: ds 2 ; 16-bit timer 2 overflow (to measure the period of very slow signals)
T1ov: ds 2

BSEG
mf: dbit 1

$NOLIST
$include(math32.inc)
$LIST

cseg
; These 'equ' must match the hardware wiring
LCD_RS equ P3.2
;LCD_RW equ PX.X ; Not used in this code, connect the pin to GND
LCD_E  equ P3.3
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P3.6
LCD_D7 equ P3.7

$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$LIST

;                     1234567890123456    <- This helps determine the location of the counter
Initial_Message:  db 'Capacitance (nf):', 0
No_Signal_Str:    db 'No signal      ', 0

; Sends 10-digit BCD number in bcd to the LCD
Display_10_digit_BCD:
	Display_BCD(bcd+4)
	Display_BCD(bcd+3)
	Display_BCD(bcd+2)
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)
	ret

;Initializes timer/counter 2 as a 16-bit timer
InitTimer2:
	mov T2CON, #0 ; Stop timer/counter.  Set as timer (clock input is pin 22.1184MHz).
	; Set the reload value on overflow to zero (just in case is not zero)
	mov RCAP2H, #0
	mov RCAP2L, #0
	setb ET2
	;clr ET2      ;line added by jaydon
	
	;enabling timer0 and timer1
	mov a, TMOD
	anl a, #0x00
	orl a, #0x11
	mov TMOD, a
	mov TH1, #high(TIMER1_RELOAD)
	mov TL1, #low(TIMER1_RELOAD)
	;Set autoreload value
	mov RH1, #0
	mov RL1, #0
	
	setb ET0
	setb ET1   ;enable timer 1 interrupt
	
	clr TR0
	clr TR1   ;start timer 1
	
    ret

Timer2_ISR:
	clr TF2  ; Timer 2 doesn't clear TF2 automatically. Do it in ISR
	push acc
	inc T2ov+0
	mov a, T2ov+0
	jnz Timer2_ISR_done
	inc T2ov+1
Timer2_ISR_done:
	pop acc
	reti

Timer1_ISR:
	;clr TF1     This is automatically done by the hardware
	push acc
	push psw
	
	inc T1ov+0
	mov a, T1ov+0
	jnz Timer1_ISR_done
	inc T1ov+1

Timer1_ISR_done:
	pop acc
	pop psw
	reti
	

;---------------------------------;
; Hardware initialization         ;
;---------------------------------;
Initialize_All:
    lcall InitTimer2
    lcall LCD_4BIT ; Initialize LCD
    setb EA
	ret

;---------------------------------;
; Main program loop               ;
;---------------------------------;
MyProgram:
    ; Initialize the hardware:
    mov SP, #7FH
    lcall Initialize_All
    ;setb P0.0 ; Pin is used as input for timer 2
    ;setb P0.1 ; Pin is used as input for timer 1
    
    
    ;setb ET2  ;LINE ADDED BY JAYDON
	
	
	
	;Set_Cursor(1, 1)
    ;Send_Constant_String(#Initial_Message)
    
forever:
    ; synchronize with rising edge of the signal applied to pin P0.0
    clr TR2 ; Stop timer 2
    mov TL2, #0
    mov TH2, #0
    mov T2ov+0, #0
    mov T2ov+1, #0
    clr TF2
    setb TR2
    
synch1:
	mov a, T2ov+1
	anl a, #0xfe
	jnz no_signal ; If the count is larger than 0x01ffffffff*45ns=1.16s, we assume there is no signal
    jb P0.0, synch1
    
synch2:    
	mov a, T2ov+1
	anl a, #0xfe
	jnz no_signal
    jnb P0.0, synch2
    
    ; Measure the period of the signal applied to pin P0.0
    clr TR2
    mov TL2, #0
    mov TH2, #0
    mov T2ov+0, #0
    mov T2ov+1, #0
    clr TF2
    setb TR2 ; Start timer 2
    
measure1:
	;mov a, T2ov+1
	;anl a, #0xfe
	;jnz no_signal 
    jb P0.0, measure1
    
measure2:    
	;mov a, T2ov+1
	;anl a, #0xfe
	;jnz no_signal
    jnb P0.0, measure2
    clr TR2 ; Stop timer 2, [T2ov+1, T2ov+0, TH2, TL2] * 45.21123ns is the period

forever_1:
;added for timer 1
    clr TR1 ; Stop timer 1
    mov TL1, #0
    mov TH1, #0
    mov T1ov+0, #0
    mov T1ov+1, #0
    clr TF1
    setb TR1
    
synch1_1:
	;added for timer 1
    mov a, T1ov+1
	anl a, #0xfe
	jnz no_signal ; If the count is larger than 0x01ffffffff*45ns=1.16s, we assume there is no signal
    jb P0.1, synch1_1
    
synch2_1:
	;added for timer 1
    mov a, T1ov+1
	anl a, #0xfe
	jnz no_signal
    jnb P0.1, synch2_1
    
    ;added for timer 1
    ; Measure the period of the signal applied to pin P0.1
    clr TR1
    mov TL1, #0
    mov TH1, #0
    mov T1ov+0, #0
    mov T1ov+1, #0
    clr TF1
    setb TR1 ; Start timer 1

  
measure1_1:
	;added for timer 1
   ; mov a, T1ov+1
	;anl a, #0xfe
;	jnz no_signal 
    jb P0.1, measure1_1
    
measure2_1:
	;added for timer 1
;	mov a, T1ov+1
;	anl a, #0xfe
	;jnz no_signal
    jnb P0.1, measure2_1
    clr TR1 ; Stop timer 2, [T2ov+1, T2ov+0, TH2, TL2] * 45.21123ns is the period
 
	;sjmp skip_this_1
	ljmp skip_this_1
	
no_signal:	
	Set_Cursor(2, 1)
    Send_Constant_String(#No_Signal_Str)
    ljmp forever ; Repeat!
     
skip_this_1:

	; Make sure [T2ov+1, T2ov+2, TH2, TL2]!=0
	mov a, TL2
	orl a, TH2
	orl a, T2ov+0
	orl a, T2ov+1
	jz no_signal
	; Using integer math, convert the period to frequency:
	mov x+0, TL2
	mov x+1, TH2
	mov x+2, T2ov+0
	mov x+3, T2ov+1
	Load_y(45) ; One clock pulse is 1/22.1184MHz=45.21123ns
	lcall mul32
	
	Load_y(100)
	lcall div32
	
	Load_y(144)
	lcall mul32
	
	Load_y(100)
	lcall div32
	
	Load_y(1102)    ;resistor
	lcall div32
	
	Load_y(100)
	lcall mul32
	

	; Convert the result to BCD and display on LCD
	Set_Cursor(1, 1)
	lcall hex2bcd
	lcall Display_10_digit_BCD
	
	sjmp skip_this_2
	;ljmp forever

no_signal_bridge:
	ljmp no_signal

skip_this_2:

	; Make sure [T1ov+1, T1ov+2, TH1, TL1]!=0

	mov a, TL1
	orl a, TH1
	orl a, T1ov+0
	orl a, T1ov+1
	jz no_signal_bridge
	; Using integer math, convert the period to frequency:
	
	Load_y(0)
	lcall mul32  ;clearing x
	
	mov x+0, TL1
	mov x+1, TH1
	mov x+2, T1ov+0
	mov x+3, T1ov+1
	Load_y(45) ; One clock pulse is 1/22.1184MHz=45.21123ns
	lcall mul32
	
	Load_y(100)
	lcall div32
	
	Load_y(144)
	lcall mul32
	
	Load_y(100)
	lcall div32
	
	Load_y(1102)    ;resistor
	lcall div32
	
	Load_y(100)
	lcall mul32
	
	
	; Convert the result to BCD and display on LCD
	Set_Cursor(2, 1)
	lcall hex2bcd
	lcall Display_10_digit_BCD
	
    ljmp forever ; Repeat! 
    

end