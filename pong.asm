; ==============================================================================
; RETRO PONG IN SCAT ASSEMBLY
; Player (Left, Cyan): Controlled by W / S or Up / Down arrow keys
; Bot AI (Right, Magenta): Tracks the ball automatically
; Ball (Yellow): Bounces off walls and paddles
; ==============================================================================
    bra main

; Memory variables for game state
p1_y:      .word 25         ; Player 1 paddle Y (left)
p1_old_y:  .word 25
p2_y:      .word 25         ; Bot AI paddle Y (right)
p2_old_y:  .word 25

ball_x:    .word 40         ; Ball position (center)
ball_y:    .word 30
ball_old_x:.word 40
ball_old_y:.word 30
ball_dx:   .word 1          ; Ball velocity
ball_dy:   .word 1

main:
    leti sp, 0x10000000

game_loop:
    ; -------------------------------------------------------------
    ; 1. READ PLAYER INPUT (MMIO at 0xC0000000)
    ; Up / W returns -1 (0xFFFFFFFF), Down / S returns +1, None returns 0
    ; -------------------------------------------------------------
    leti r1, 0xC0000000
    load r2, [r1]

    load r3, [p1_y]         ; r3 = p1_y
    store [p1_old_y], r3    ; remember old position for erasing

    ; Check Move Up (-1)
    subi r4, r0, 1          ; r4 = -1
    bne  r2, r4, check_down
    leti r5, 1
    ble  r3, r5, apply_bot  ; if p1_y <= 1, don't move up
    subi r3, r3, 1          ; p1_y--
    bra  save_p1

check_down:
    ; Check Move Down (+1)
    leti r4, 1
    bne  r2, r4, apply_bot
    leti r5, 49
    bge  r3, r5, apply_bot  ; if p1_y >= 49, don't move down
    addi r3, r3, 1          ; p1_y++

save_p1:
    store [p1_y], r3

apply_bot:
    ; -------------------------------------------------------------
    ; 2. BOT AI (PADDLE 2 TRACKS BALL_Y)
    ; -------------------------------------------------------------
    load r6, [p2_y]         ; r6 = p2_y
    store [p2_old_y], r6    ; remember old position
    load r7, [ball_y]       ; r7 = ball_y

    ; Target is center of paddle: p2_y + 4
    addi r8, r6, 4
    blt  r7, r8, bot_up
    bgt  r7, r8, bot_down
    bra  move_ball

bot_up:
    leti r5, 1
    ble  r6, r5, move_ball
    subi r6, r6, 1          ; bot paddle moves up
    bra  save_bot

bot_down:
    leti r5, 49
    bge  r6, r5, move_ball
    addi r6, r6, 1          ; bot paddle moves down

save_bot:
    store [p2_y], r6

move_ball:
    ; -------------------------------------------------------------
    ; 3. MOVE BALL
    ; -------------------------------------------------------------
    load r1, [ball_x]
    load r2, [ball_y]
    store [ball_old_x], r1
    store [ball_old_y], r2

    load r3, [ball_dx]
    load r4, [ball_dy]
    add  r1, r1, r3         ; ball_x += ball_dx
    add  r2, r2, r4         ; ball_y += ball_dy

    ; -------------------------------------------------------------
    ; 4. BOUNCE TOP / BOTTOM WALLS (y <= 1 or y >= 58)
    ; -------------------------------------------------------------
    leti r5, 1
    ble  r2, r5, bounce_y
    leti r5, 58
    bge  r2, r5, bounce_y
    bra  check_paddle1

bounce_y:
    sub  r4, r0, r4         ; ball_dy = -ball_dy
    store [ball_dy], r4

check_paddle1:
    ; -------------------------------------------------------------
    ; 5. COLLISION WITH PADDLE 1 (LEFT, x == 3)
    ; -------------------------------------------------------------
    leti r5, 3
    bgt  r1, r5, check_paddle2
    
    ; Check if ball_y is within paddle1: [p1_y, p1_y + 9]
    load r6, [p1_y]
    blt  r2, r6, p1_miss
    addi r7, r6, 10
    bgt  r2, r7, p1_miss

    ; Hit paddle 1! Bounce right!
    leti r3, 1
    store [ball_dx], r3
    leti r1, 4              ; push slightly off paddle
    bra  store_ball

p1_miss:
    ; Missed left paddle: reset ball to center
    leti r1, 40
    leti r2, 30
    leti r3, 1
    store [ball_dx], r3
    bra  store_ball

check_paddle2:
    ; -------------------------------------------------------------
    ; 6. COLLISION WITH PADDLE 2 (RIGHT, x == 76)
    ; -------------------------------------------------------------
    leti r5, 76
    blt  r1, r5, store_ball

    load r6, [p2_y]
    blt  r2, r6, p2_miss
    addi r7, r6, 10
    bgt  r2, r7, p2_miss

    ; Hit paddle 2! Bounce left!
    subi r3, r0, 1          ; dx = -1
    store [ball_dx], r3
    leti r1, 75             ; push slightly off paddle
    bra  store_ball

p2_miss:
    ; Missed right paddle: reset ball to center
    leti r1, 40
    leti r2, 30
    subi r3, r0, 1
    store [ball_dx], r3

store_ball:
    store [ball_x], r1
    store [ball_y], r2

    ; -------------------------------------------------------------
    ; 7. RENDERING
    ; -------------------------------------------------------------
    ; Erase old ball (Black)
    load r1, [ball_old_x]
    load r2, [ball_old_y]
    leti r3, 0x00000000
    call draw_pixel

    ; Erase old Paddle 1 (Black)
    leti r1, 2              ; X = 2
    load r2, [p1_old_y]
    leti r3, 0x00000000
    call draw_paddle

    ; Erase old Paddle 2 (Black)
    leti r1, 77             ; X = 77
    load r2, [p2_old_y]
    leti r3, 0x00000000
    call draw_paddle

    ; Draw new Paddle 1 (Cyan)
    leti r1, 2
    load r2, [p1_y]
    leti r3, 0x00FFFFFF     ; Cyan
    call draw_paddle

    ; Draw new Paddle 2 (Magenta)
    leti r1, 77
    load r2, [p2_y]
    leti r3, 0xFF00FF00     ; Magenta
    call draw_paddle

    ; Draw new Ball (Yellow)
    load r1, [ball_x]
    load r2, [ball_y]
    leti r3, 0xFFFF0000     ; Yellow
    call draw_pixel

    ; Delay for smooth 30-45 FPS
    call delay

    bra  game_loop

; ==============================================================================
; draw_paddle: draws a vertical paddle of height 10
; Inputs: r1 = x, r2 = y_start, r3 = color
; ==============================================================================
draw_paddle:
    push lr
    push r6
    push r7
    push r8

    mov  r6, r1             ; x
    mov  r7, r2             ; current y
    addi r8, r2, 10         ; y_end = y_start + 10

pad_loop:
    bge  r7, r8, pad_done
    mov  r1, r6
    mov  r2, r7
    call draw_pixel
    addi r7, r7, 1
    bra  pad_loop

pad_done:
    pop  r8
    pop  r7
    pop  r6
    pop  lr
    ret

; ==============================================================================
; draw_pixel: paints pixel at (r1, r2) with color in r3
; ==============================================================================
draw_pixel:
    push r4
    push r5

    muli r4, r1, 4          ; horiz offset
    muli r5, r2, 320        ; vert offset
    add  r4, r5, r4
    leti r5, 0xB0000000     ; VRAM base
    add  r4, r5, r4
    store [r4], r3

    pop  r5
    pop  r4
    ret

; ==============================================================================
; delay: game speed regulation loop
; ==============================================================================
delay:
    leti r10, 25000
delay_l:
    subi r10, r10, 1
    bgtz r10, delay_l
    ret
