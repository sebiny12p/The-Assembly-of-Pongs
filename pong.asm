; ==============================================================================
; THE ASSEMBLY OF PONGS - HIGH PERFORMANCE & GAME OVER STATES
; Player 1 (Left, Cyan): W / S or Up / Down arrow keys
; Bot AI (Right, Magenta): Beatable AI (tracks only on right court with speed limit)
; Optimization: Delta-rendering (only updates paddle ends, 60 FPS smooth)
; Fail State: Screen turns RED if player loses, GREEN if AI loses!
; ==============================================================================
    bra main

; Memory variables
p1_y:      .word 25         ; Player Y (0 to 49)
p1_old_y:  .word 25
p2_y:      .word 25         ; Bot Y
p2_old_y:  .word 25

ball_x:    .word 40         ; Ball position
ball_y:    .word 30
ball_old_x:.word 40
ball_old_y:.word 30
ball_dx:   .word 1          ; Ball velocity
ball_dy:   .word 1

bot_tick:  .word 0          ; Frame counter for AI speed handicap

main:
    leti sp, 0x10000000

    ; --- 1. INITIAL DRAW: Draw full paddles at startup ---
    leti r1, 2
    load r2, [p1_y]
    leti r3, 0x00FFFFFF     ; Cyan
    call draw_full_paddle

    leti r1, 77
    load r2, [p2_y]
    leti r3, 0xFF00FF00     ; Magenta
    call draw_full_paddle

game_loop:
    ; -------------------------------------------------------------
    ; 2. READ PLAYER INPUT (MMIO at 0xC0000000)
    ; Up / W returns -1 (0xFFFFFFFF), Down / S returns +1
    ; -------------------------------------------------------------
    leti r1, 0xC0000000
    load r2, [r1]

    load r3, [p1_y]
    store [p1_old_y], r3

    subi r4, r0, 1          ; r4 = -1
    bne  r2, r4, check_down
    leti r5, 1
    ble  r3, r5, apply_bot  ; top bound
    subi r3, r3, 1          ; player moves UP
    bra  save_p1

check_down:
    leti r4, 1
    bne  r2, r4, apply_bot
    leti r5, 49
    bge  r3, r5, apply_bot  ; bottom bound
    addi r3, r3, 1          ; player moves DOWN

save_p1:
    store [p1_y], r3

apply_bot:
    ; -------------------------------------------------------------
    ; 3. BEATABLE BOT AI
    ; Handicap 1: Bot only reacts when ball is moving toward it (ball_dx > 0)
    ; Handicap 2: Bot only reacts on right half of court (ball_x >= 35)
    ; Handicap 3: Bot only moves on alternate frames (speed cap)
    ; -------------------------------------------------------------
    load r6, [p2_y]
    store [p2_old_y], r6

    load r1, [ball_dx]
    blez r1, move_ball      ; If ball moving away, bot doesn't track!

    load r1, [ball_x]
    leti r5, 35
    blt  r1, r5, move_ball  ; If ball on left court, bot doesn't track!

    ; Alternate frame check (bot moves at half speed!)
    load r8, [bot_tick]
    addi r8, r8, 1
    store [bot_tick], r8
    modi r8, r8, 2
    bnez r8, move_ball      ; Skip move on odd frames!

    load r7, [ball_y]
    addi r8, r6, 4          ; center of bot paddle
    blt  r7, r8, bot_up
    bgt  r7, r8, bot_down
    bra  move_ball

bot_up:
    leti r5, 1
    ble  r6, r5, move_ball
    subi r6, r6, 1
    bra  save_bot

bot_down:
    leti r5, 49
    bge  r6, r5, move_ball
    addi r6, r6, 1

save_bot:
    store [p2_y], r6

move_ball:
    ; -------------------------------------------------------------
    ; 4. MOVE BALL
    ; -------------------------------------------------------------
    load r1, [ball_x]
    load r2, [ball_y]
    store [ball_old_x], r1
    store [ball_old_y], r2

    load r3, [ball_dx]
    load r4, [ball_dy]
    add  r1, r1, r3
    add  r2, r2, r4

    ; Bounce Top / Bottom Walls (1 to 58)
    leti r5, 1
    ble  r2, r5, bounce_y
    leti r5, 58
    bge  r2, r5, bounce_y
    bra  check_paddle1

bounce_y:
    sub  r4, r0, r4         ; negate dy
    store [ball_dy], r4

check_paddle1:
    ; -------------------------------------------------------------
    ; 5. PADDLE 1 COLLISION (LEFT: x <= 3)
    ; -------------------------------------------------------------
    leti r5, 3
    bgt  r1, r5, check_paddle2

    load r6, [p1_y]
    blt  r2, r6, player_loses   ; Ball went past paddle -> FAIL STATE!
    addi r7, r6, 10
    bgt  r2, r7, player_loses   ; Ball went past paddle -> FAIL STATE!

    ; Deflection bounce!
    leti r3, 1
    store [ball_dx], r3
    leti r1, 4
    bra  store_ball

check_paddle2:
    ; -------------------------------------------------------------
    ; 6. PADDLE 2 COLLISION (RIGHT: x >= 76)
    ; -------------------------------------------------------------
    leti r5, 76
    blt  r1, r5, store_ball

    load r6, [p2_y]
    blt  r2, r6, ai_loses       ; Ball went past AI -> VICTORY STATE!
    addi r7, r6, 10
    bgt  r2, r7, ai_loses       ; Ball went past AI -> VICTORY STATE!

    ; Deflection bounce!
    subi r3, r0, 1
    store [ball_dx], r3
    leti r1, 75

store_ball:
    store [ball_x], r1
    store [ball_y], r2

    ; -------------------------------------------------------------
    ; 7. ULTRA-SMOOTH DELTA RENDERING
    ; Only updates pixels that actually changed!
    ; -------------------------------------------------------------
    ; 1. Erase old ball
    load r1, [ball_old_x]
    load r2, [ball_old_y]
    leti r3, 0x00000000     ; Black
    call draw_pixel

    ; 2. Delta-update Paddle 1 (X = 2)
    leti r1, 2
    load r2, [p1_old_y]
    load r3, [p1_y]
    leti r4, 0x00FFFFFF     ; Cyan
    call update_paddle_ends

    ; 3. Delta-update Paddle 2 (X = 77)
    leti r1, 77
    load r2, [p2_old_y]
    load r3, [p2_y]
    leti r4, 0xFF00FF00     ; Magenta
    call update_paddle_ends

    ; 4. Draw new ball
    load r1, [ball_x]
    load r2, [ball_y]
    leti r3, 0xFFFF0000     ; Yellow
    call draw_pixel

    call delay

    bra  game_loop

; ==============================================================================
; FAIL STATE: Player missed! Fill screen border with RED & halt!
; ==============================================================================
player_loses:
    leti r1, 0xFF000000     ; RED (Loss)
    call flash_screen
    bra  +0                 ; HALT (Game Over - You Lost!)

; ==============================================================================
; VICTORY STATE: AI missed! Fill screen border with GREEN & halt!
; ==============================================================================
ai_loses:
    leti r1, 0x00FF0000     ; GREEN (Win)
    call flash_screen
    bra  +0                 ; HALT (Game Over - You Won!)

; ==============================================================================
; flash_screen: paints entire top and bottom borders with color in r1
; ==============================================================================
flash_screen:
    push lr
    push r6
    push r7
    mov  r6, r1             ; color
    leti r7, 0              ; x = 0
flash_loop:
    leti r8, 80
    bge  r7, r8, flash_done
    mov  r1, r7
    leti r2, 0              ; top row
    mov  r3, r6
    call draw_pixel
    mov  r1, r7
    leti r2, 59             ; bottom row
    mov  r3, r6
    call draw_pixel
    addi r7, r7, 1
    bra  flash_loop
flash_done:
    pop  r7
    pop  r6
    pop  lr
    ret

; ==============================================================================
; update_paddle_ends: Only draws 1 pixel ON and 1 pixel OFF!
; Inputs:
;   r1 = x
;   r2 = old_y
;   r3 = new_y
;   r4 = paddle_color
; ==============================================================================
update_paddle_ends:
    push lr
    push r6
    push r7
    push r8
    push r9

    beq  r2, r3, ends_done  ; If paddle didn't move, write 0 pixels!

    blt  r3, r2, paddle_moved_up

    ; --- PADDLE MOVED DOWN (new_y > old_y) ---
    ; Erase old top pixel: (x, old_y) -> Black
    mov  r6, r1
    mov  r7, r2
    mov  r8, r3
    mov  r9, r4

    mov  r1, r6
    mov  r2, r7             ; old_y
    leti r3, 0x00000000
    call draw_pixel

    ; Draw new bottom pixel: (x, new_y + 9) -> paddle_color
    mov  r1, r6
    addi r2, r8, 9          ; new_y + 9
    mov  r3, r9
    call draw_pixel
    bra  ends_done

paddle_moved_up:
    ; --- PADDLE MOVED UP (new_y < old_y) ---
    mov  r6, r1
    mov  r7, r2
    mov  r8, r3
    mov  r9, r4

    ; Draw new top pixel: (x, new_y) -> paddle_color
    mov  r1, r6
    mov  r2, r8             ; new_y
    mov  r3, r9
    call draw_pixel

    ; Erase old bottom pixel: (x, old_y + 9) -> Black
    mov  r1, r6
    addi r2, r7, 9          ; old_y + 9
    leti r3, 0x00000000
    call draw_pixel

ends_done:
    pop  r9
    pop  r8
    pop  r7
    pop  r6
    pop  lr
    ret

; ==============================================================================
; draw_full_paddle: draws all 10 pixels (used only once at startup)
; Inputs: r1 = x, r2 = y_start, r3 = color
; ==============================================================================
draw_full_paddle:
    push lr
    push r6
    push r7
    push r8

    mov  r6, r1
    mov  r7, r2
    addi r8, r2, 10

full_pad_loop:
    bge  r7, r8, full_pad_done
    mov  r1, r6
    mov  r2, r7
    call draw_pixel
    addi r7, r7, 1
    bra  full_pad_loop

full_pad_done:
    pop  r8
    pop  r7
    pop  r6
    pop  lr
    ret

; ==============================================================================
; draw_pixel(r1=x, r2=y, r3=color)
; ==============================================================================
draw_pixel:
    push r4
    push r5

    muli r4, r1, 4
    muli r5, r2, 320
    add  r4, r5, r4
    leti r5, 0xB0000000
    add  r4, r5, r4
    store [r4], r3

    pop  r5
    pop  r4
    ret

; ==============================================================================
; delay: tuned for smooth 60 FPS
; ==============================================================================
delay:
    leti r10, 4000
delay_loop:
    subi r10, r10, 1
    bgtz r10, delay_loop
    ret
