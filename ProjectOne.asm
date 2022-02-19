$NOLIST
$MODLP51
$LIST

CLK                   EQU 22118400 					
TIMER0_RATE_LOW       EQU 3900  
TIMER0_RELOAD_LOW     EQU ((65536-(CLK/TIMER0_RATE_LOW)))  					
TIMER0_RATE_HIGH      EQU 4100
TIMER0_RELOAD_HIGH    EQU ((65536-(CLK/TIMER0_RATE_HIGH)))
TIMER0_RATE_WAIT      EQU 1000
TIMER0_RELOAD_WAIT    EQU ((65536-(CLK/TIMER0_RATE_WAIT)))
TIMER1_RATE           EQU 1000
TIMER1_RELOAD         EQU ((65536-(CLK/TIMER1_RATE)))
TIMER2_SERVO_RIGHT    EQU 500
TIMER2_SERVO_LEFT     EQU 1000
TIMER2_RELOAD_RIGHT   EQU ((65536-(CLK/TIMER2_SERVO_RIGHT)))
TIMER2_RELOAD_LEFT    EQU ((65536-(CLK/TIMER2_RELOAD_LEFT)))
STEADY_STATE          EQU 73000000
WINNING_SCORE         EQU 0x65
SOUND_OUT             EQU P1.1
SEED_GENERATOR        EQU P4.5
SERVO                 EQU P0.3
US_SENSOR             EQU P0.4

; Reset vector
org 0000H
   ljmp Start
   
; Timer/Counter 0 overflow interrupt vector
org 0x000B
	ljmp Timer0_ISR

org 0x001B
    ljmp Timer1_ISR

org 0x002B
    ljmp Timer2_ISR

; These register definitions needed by 'math32.inc'
DSEG at 30H
x:   ds 4
y:   ds 4
Seed: ds 4
bcd: ds 5
T2ov: ds 2
T1ov: ds 2
T0ov: ds 2
player1: ds 1
player2: ds 1
lives_left: ds 1
guess_score: ds 1
hold_bcd: ds 1

BSEG
tone: dbit 1
inc_or_dec: dbit 1
mf: dbit 1
game_or_guess: dbit 1
Go_To_Wait: dbit 1
score_to_update: dbit 1
direction: dbit 1
tone_select: dbit 1
lockout: dbit 1

$NOLIST
$include(math32.inc)
$include(LCD_4bit.inc)
$LIST

CSEG
; These 'equ' must match the hardware wiring
LCD_RS equ P3.2
;LCD_RW equ PX.X ; Not used in this code, connect the pin to GND
LCD_E  equ P3.3
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P3.6
LCD_D7 equ P3.7


Initial_Message_Top:    db 'Player 1:', 0
Initial_Message_Bottom: db 'Player 2:', 0
Clear:                  db '                ', 0
Player1_Message:        db 'Player One Won!', 0
Player2_Message:        db 'Player Two Won!', 0
Guess_Player_Message:   db 'Player Score: 0', 0
Lives_Message:          db 'Lives Left: 3', 0
Lost:                   db 'Game Lost!', 0

Display_10_digit_BCD:
    Display_BCD(bcd+4)
	Display_BCD(bcd+3)
	Display_BCD(bcd+2)
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)
	ret

; Initializes timer/counter 0 as a 16-bit timer
InitTimers01:
	mov a, TMOD
	anl a, #0x00
	orl a, #0x11
	mov TMOD, a
	mov TH1, #high(TIMER1_RELOAD)
    mov TL1, #low(TIMER1_RELOAD)
    mov RH1, #0
    mov RL1, #0
	clr TR0
	clr TR1
	clr TF0
	clr TF1
	setb ET0
	setb ET1
	ret
	
Timer0_ISR:
	clr TF0
    push acc
    push psw
    ; jb lockout ; Tentatively disabling this line
    jb Go_To_Wait, Waiting_Period
	cpl SOUND_OUT
	sjmp Timer0_ISR_Done

Waiting_Period:
    inc T0ov+0
    mov a, T0ov+0
    jnz Compare
    inc T0ov+1

Compare:
    mov a, T0ov+0
    cjne a, #low(3000), Timer0_ISR_Done
    mov a, T0ov+1
    cjne a, #high(3000), Timer0_ISR_Done
    clr Go_To_Wait
    clr TR0
    clr TF0

Timer0_ISR_Done:
    pop acc
    pop psw
    reti

Timer1_ISR:
	clr TF1
    push acc
    push psw
    inc T1ov+0
    mov a, T1ov+0
    jnz Timer1_ISR_Done
    inc T1ov+1

Timer1_ISR_Done:
    pop acc
    pop psw
    reti

InitTimer2:
    mov T2CON, #0
    mov RCAP2H, #0
    mov RCAP2L, #0
  	clr ET2
    clr TR2
    ret

Timer2_ISR:
    clr TF2
    push acc
    push psw
    jnb game_or_guess, Timer2_ISR_Counter

Servo_Handler:
    cpl SERVO
    ljmp Timer2_ISR_Done

Timer2_ISR_Counter:
    inc T2ov+0
    mov a, T2ov+0
    jnz Timer2_ISR_Done
    inc T2ov+1

Timer2_ISR_Done:
    pop acc
    pop psw
    reti

;---------------------------------;
; Hardware initialization         ;
;---------------------------------;
Initialize_All:
	lcall InitTimers01
    lcall InitTimer2
    lcall LCD_4BIT
	ret

Initial_Seed:
	clr ET2
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
    ret
    
Receive_Serial:
	setb P3.0											; Pull RX pin high
	setb ET1											; Enable timer 1 interrupts
	mov TMOD, #20H										; Timer 1 in mode 2 (auto reload)
	mov TH1, #-6										; 115200 baud rate with our crystal
	mov SCON, #50H										; Start bit is 0, Stop bit is 1, Rece
	setb TR1											; Start timer 1 for the generation of the baud rate
Wait:
	jnb RI, Wait										; Wait for the interrupt flag to be raised that indicates that a byte has been read
	mov a, SBUF											; Move the contents of the serial buffer into acc
    jnz Update_Game_Or_Guess
    clr game_or_guess									; In this case, this variable is set or cleared depending on the value received from the buffer to choose the game
    ret
    
Update_Game_Or_Guess:
    setb game_or_guess
	ret

Start:
    ; Initialize the hardware:
    mov SP, #7FH										; Needed for interrupts to work
    setb EA												; Enable master interrupt
    lcall Receive_Serial
    lcall Initialize_All
    setb P0.0 											; Pin is used as input for timer 2
    setb P2.0 											; Pin is used as input for timer 1
    setb SEED_GENERATOR									; Pin used as input for the seed generator push button
    clr SOUND_OUT										; Pin used for the speaker output
    setb ET2											; Enable the timer 2 interrupt (it was cleared for the seed generation)
    jb game_or_guess, Jump_To_Guessing_Game				; Bit variable determines which game has been selected
    sjmp Sound_Off
    
Jump_To_Guessing_Game:
	ljmp Guessing_Game
    
Sound_Off:
    lcall Initial_Seed
    clr lockout
    Set_Cursor(1, 1)
    Send_Constant_String(#Initial_Message_Top)
    Set_Cursor(2, 1)
    Send_Constant_String(#Initial_Message_Bottom)
	mov player2, #0										; Initialize player 2 score to 0
	mov player1, #0										; Initialize player 1 score to 0
    
Sound_Off_Forever:
    lcall Random										; Generate a random seed	
    mov a, Seed+0
    mov c, acc.3
    jc Tone_High										; Set carry to a random bit in accumulator so that the tone played is random

Tone_Low:
    mov TH0, #high(TIMER0_RELOAD_LOW)					; Set timer 0 so that it plays the low frequency tone
	mov TL0, #low(TIMER0_RELOAD_LOW)
	mov RH0, #high(TIMER0_RELOAD_LOW)
	mov RL0, #low(TIMER0_RELOAD_LOW)
    clr inc_or_dec										; inc_or_dec responsible for determining whether the player that hit the pad deserves to lose a point or gain a point
    lcall Wait_Random									; Wait a random period of time
    clr Go_To_Wait										; Determines whether the timer 1 ISR will be used for waiting or playing the transducer
    sjmp Tone_Off

Tone_High:
    mov TH0, #high(TIMER0_RELOAD_HIGH)					; Set timer 0 so that it plays the high frequency tone
    mov TL0, #low(TIMER0_RELOAD_HIGH)
	mov RH0, #high(TIMER0_RELOAD_HIGH)
	mov RL0, #low(TIMER0_RELOAD_HIGH)
    setb inc_or_dec
    lcall Wait_Random
    clr Go_To_Wait
    
Tone_Off:
	setb TR0
	Wait_Milli_Seconds(#100)							; Play the tone for 100 ms
    clr TR0

Wait_For_Input_SO:
    setb Go_To_Wait										; Now timer 0 will be used for waiting by comparing the value of the overflow variable with 3000 (3s)
    mov TH0, #high(TIMER0_RELOAD_WAIT)					; Set timer 0 to overflow every 1 ms and the ovf var will be compared to 3000 (3s) 
	mov TL0, #low(TIMER0_RELOAD_WAIT)					
    mov RH0, #high(TIMER0_RELOAD_WAIT)
    mov RL0, #low(TIMER0_RELOAD_WAIT)
    mov T0ov+0, #0										; Reset the timer 0 overflow variable
    mov T0ov+1, #0
    setb TR0

Waiting_SO:
    clr TR1												; Prepare timer 1 so that it can be synchronized to P1's 555 timer
    mov TL1, #0											
    mov TH1, #0
    mov T1ov+0, #0
    mov T1ov+1, #0
    clr TF1
    setb TR1

Synch1_TR1:
    jb P2.0, Synch1_TR1									; Synchronization period

Synch2_TR1:
    jnb P2.0, Synch2_TR1
    								
    clr TR1												; Prepare timer 1 so that it can be used to measure the period of P1's 555 timer output			
    mov TL1, #0
    mov TH1, #0
    mov T1ov+0, #0
    mov T1ov+1, #0
    clr TF1
    setb TR1

Measure1_TR1:
    jb P2.0, Measure1_TR1								; Measurement period

Measure2_TR1:
    jnb P2.0, Measure2_TR1
    clr TR1
    clr TF1

    clr TR2												; Same thing as discussed previously for timer 1, but in this case, applied to timer 2
    mov TL2, #0											; which is associated with P2's 555 timer output
    mov TH2, #0
    mov T2ov+0, #0
    mov T2ov+1, #0
    clr TF2
    setb TR2

Synch1_TR2:
    jb P0.0, Synch1_TR2

Synch2_TR2:
    jnb P0.0, Synch2_TR2

    clr TR2
    mov TL2, #0
    mov TH2, #0
    mov T2ov+0, #0
    mov T2ov+1, #0
    clr TF2
    setb TR2

Measure1_TR2:
    jb P0.0, Measure1_TR2

Measure2_TR2:
    jnb P0.0, Measure2_TR2
    clr TR2
    clr TF2

    mov x+0, TL1										; Calculate timer 1 raw period and compare it to see if it exceeds the threshold value
    mov x+1, TH1										; that occurs when player 1 has hit the pad
    mov x+2, T1ov+0
    mov x+3, T1ov+1
    Load_y(45)
    lcall mul32
    Load_y(STEADY_STATE)
    lcall x_gt_y										; Comparison
    setb score_to_update								; If player 1 hit the pad, the score to update will be associated with them
    jb mf, Done_Waiting									; If player 1 hit the pad, we want to leave the waiting loop

    mov x+0, TL2										; Calculate timer 2 raw period for the same reason. 
    mov x+1, TH2
    mov x+2, T2ov+0
    mov x+3, T2ov+1
	Load_y(45)
	lcall mul32
    Load_y(STEADY_STATE)
    lcall x_gt_y										; Comparison
    clr score_to_update									; If player 2 hit the pad, the score to update will be associated with them
    jb mf, Done_Waiting									; If player 1 hit the pad, we want to leave the waiting loop
    ljmp Still_Waiting									; If no one hit the pad, we restart the waiting loop

Done_Waiting:
	clr TR0
	clr TF0
    jb score_to_update, Update_Player_1					; If Player 1 hit the pad, score_to_update would have been set so we know that we
														; have to update player 1's score
Update_Player_2:

Incremement_Score_P2:									
    jnb inc_or_dec, Decrement_Score_P2					; If player 2 hit the pad when a low tone was played, inc_or_dec would be 0 and it would jump to the decremenet routine
	inc player2											; Increment player 2's score if they hit the pad on the high tone
    Set_Cursor(2, 11)
    Display_BCD(player2)
    ljmp Check_Player2									; Increment score and restart. If player 2 matches the winning score it will update in the next cycle

Decrement_Score_P2:
	mov a, player2
	cjne a, #0, Continue_Decrement_P2					; Check to see that score is not 0 and if it is, then do not decrement and start a new cycle
	ljmp Check_Player2
	
Continue_Decrement_P2:
	dec player2
    Set_Cursor(2, 11)
    Display_BCD(player2)
    ljmp Check_Player2

Update_Player_1:

Incremement_Score_P1:
    jnb inc_or_dec, Decrement_Score_P1					; Same idea as above for handling player 2's score
    Set_Cursor(1, 15)
	Display_Char(#'2')
	inc player1
    Set_Cursor(1, 11)
    Display_BCD(player1)
    ljmp Check_Player1

Decrement_Score_P1:
	mov a, player1
	cjne a, #0, Continue_Decrement_P1
	ljmp Check_Player1
	
Continue_Decrement_P1:
	dec player1
    Set_Cursor(1, 11)
    Display_BCD(player1)
    ljmp Check_Player1
    
Still_Waiting:											
    jb Go_To_Wait, Jump_To_Waiting_SO					; If no one hit the pad, then we are still in the waiting loop
    sjmp Check_Player1									; If there was a timeout, then just fall through to the check player routines

Jump_To_Waiting_SO:
	ljmp Waiting_SO										; Restart waiting loop

Check_Player1:											; Check if player 1 has won
    mov a, player1
    cjne a, #WINNING_SCORE, Check_Player2
    ljmp Player_1_Won

Check_Player2:											; Check if player 2 has won
    mov a, player2
    cjne a, #WINNING_SCORE, Game_Still_In_Progress
    ljmp Player_2_Won

Game_Still_In_Progress:									; Restart cycle to play new tone
    clr Go_To_Wait
    ljmp Sound_Off_Forever
    
Player_1_Won:											; If player 1 has won, then display the appropriate message
    Set_Cursor(1, 1)
    Send_Constant_String(#Player1_Message)
    Set_Cursor(2, 1)
    Send_Constant_String(#Clear)
    ljmp Complete

Player_2_Won:											; If player 2 has won, then display the appropriate message
    Set_Cursor(2, 1)
    Send_Constant_String(#Player2_Message)
    Set_Cursor(1, 1)
    Send_Constant_String(#Clear)
    ljmp Complete
    
Guessing_Game:											; The second of our two games
    clr Go_To_Wait
	lcall Initial_Seed
    setb ET2
    Set_Cursor(1, 1)
    Send_Constant_String(#Guess_Player_Message)
    Set_Cursor(2, 1)
    Send_Constant_String(#Lives_Message)
    mov guess_score, #0x00
    mov lives_left, #0x03
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#255)

Guessing_Game_Forever:
    lcall Random
    mov a, Seed+0
    mov c, acc.3
    mov direction, c
    mov TH0, #high(TIMER0_RELOAD_HIGH)
	mov TL0, #low(TIMER0_RELOAD_HIGH)
	mov RH0, #high(TIMER0_RELOAD_HIGH)
	mov RL0, #low(TIMER0_RELOAD_HIGH)
    clr lockout
	clr Go_To_Wait
	clr ET1
    clr TF1
    setb TR0
    Wait_Milli_Seconds(#255)
    Wait_Milli_Seconds(#100)
    clr TR0
    setb lockout
    
Wait_For_Input_GG:
    lcall Receive_Serial
    clr TR1
    clr TF1
    mov TMOD, #01H
    jc Right
    sjmp Left
   
Right:
	lcall Servo_Right
	ljmp Update_Score
	
Left:
	lcall Servo_Left
	ljmp Update_Score

Servo_Right:
	mov TH0, #0FCH
	mov TL0, #19H
	mov RH0, #0
	mov RL0, #0
	setb SERVO
	setb TR0
	
Wait_GG_Right:
	jnb TF0, Wait_GG_Right
	clr SERVO
	clr TF0
	clr TR0
	ret

Servo_Left:
    mov TH0, #0F8H
	mov TL0, #31H
	mov RH0, #0
	mov RL0, #0
	setb SERVO
	setb TR0
    
Wait_GG_Left:
	jnb TF0, Wait_GG_Left
	clr SERVO
	clr TF0
	clr TR0
	ret

Update_Score:
    mov a, game_or_guess
    cjne a, direction, Take_Life

Add_To_Score:
    mov a, guess_score
    add a, #0x01
    da a
    mov guess_score, a
    mov a, lives_left
    da a
    mov lives_left, a
    Set_Cursor(1, 15)
    Display_BCD(guess_score)
    Set_Cursor(2, 13)
    Display_BCD(lives_left)
	ljmp Guessing_Game_Forever
	
Take_Life:
    mov a, lives_left
    add a, #0x99
    da a
    mov lives_left, a
    mov a, guess_score
    da a
    mov guess_score, a
    Set_Cursor(1, 15)
    Display_BCD(guess_score)
    Set_Cursor(2, 13)
    Display_BCD(lives_left)
    mov a, lives_left
    cjne a, #0x00, Game_Not_Lost
    sjmp Game_Lost

Game_Not_Lost:
	ljmp Guessing_Game_Forever

Game_Lost:
    Set_Cursor(2, 1)
    Send_Constant_String(#Clear)
    Set_Cursor(1, 1)
    Send_Constant_String(#Lost)
    
Complete:
    sjmp Complete
end