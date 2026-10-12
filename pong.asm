; ==============================================================================
; THE ASSEMBLY OF PONGS - COMPLETE RETRO ARCADE CHAMPIONSHIP
; Features:
;   - First to 3 Points Match System
;   - Clean, minimalist LED score pips on the top border (No UI clutter!)
;   - Paddle Aiming / Spin Physics:
;       * Top 3 pixels   : Sharp upward angle  (dy = -1)
;       * Middle 4 pixels: Flat horizontal laser (dy = 0)
;       * Bottom 3 pixels: Sharp downward angle (dy = +1)
;   - 4 Selectable AI Difficulties (1=Easy, 2=Normal, 3=Hard, 4=Very Hard)
;   - Dynamic Rally Acceleration in Very Hard Mode
;   - Instant Match Restarts via R / Space or 1..4 anytime
;   - Ultra-smooth 60 FPS Delta-Rendering (only paddle ends updated)
;   - Flashing celebration & game over fail/victory states
; ==============================================================================
    bra main

; --- Memory Variables ---
difficulty:    .word 2          ; 1=Easy, 2=Normal, 3=Hard, 4=Very Hard
current_delay: .word 3800       ; Delay counter for speed control
rally_count:   .word 0          ; Rallies in current point
p1_score:      .word 0          ; First to 3 points wins!
p2_score:      .word 0

p1_y:          .word 25         ; Player Y (0 to 49)
p1_old_y:      .word 25
p2_y:          .word 25         ; Bot Y
p2_old_y:      .word 25

ball_x:        .word 40         ; Ball position
ball_y:        .word 30
ball_old_x:    .word 40
ball_old_y:    .word 30
ball_dx:       .word 1          ; Ball horizontal velocity (+1 or -1)
ball_dy:       .word 1          ; Ball vertical velocity (-1, 0, or +1)

bot_tick:          .word 0      ; Continuous frame counter
bot_target_offset: .word 4      ; Active paddle hit target (1=top, 4=center, 7=bottom)

; ==============================================================================
; MAIN ENTRY POINT
; ==============================================================================
main:
    leti sp, 0x10000000

start_match:
    ; Reset Match Scores
    leti r1, 0
    store [p1_score], r1
    store [p2_score], r1

    ; Initial serve direction towards AI
    leti r1, 1
    store [ball_dx], r1

serve_round:
    ; 1. Reset Round State Variables
    leti r1, 25
    store [p1_y], r1
    store [p1_old_y], r1
    store [p2_y], r1
    store [p2_old_y], r1

    leti r1, 40
    store [ball_x], r1
    store [ball_old_x], r1
    leti r1, 30
    store [ball_y], r1
    store [ball_old_y], r1

    leti r1, 1
    store [ball_dy], r1

    leti r1, 0
    store [bot_tick], r1
    store [rally_count], r1

    leti r1, 4
    store [bot_target_offset], r1

    ; Set initial speed delay based on difficulty
    load r2, [difficulty]
    leti r3, 1
    beq  r2, r3, set_speed_easy
    leti r3, 2
    beq  r2, r3, set_speed_normal
    leti r3, 3
    beq  r2, r3, set_speed_hard
    ; Difficulty 4 (Very Hard)
    leti r1, 3500
    bra  save_speed

set_speed_easy:
    leti r1, 4600
    bra  save_speed

set_speed_normal:
    leti r1, 3800
    bra  save_speed

set_speed_hard:
    leti r1, 2800

save_speed:
    store [current_delay], r1

    ; 2. Clear Screen & Draw Minimalist Court with Score Pips
    call clear_screen
    call draw_borders

    ; 3. Draw initial paddles
    leti r1, 2
    load r2, [p1_y]
    leti r3, 0x00FFFFFF         ; Cyan
    call draw_full_paddle

    leti r1, 77
    load r2, [p2_y]
    leti r3, 0xFF00FF00         ; Magenta
    call draw_full_paddle

; ==============================================================================
; MAIN GAME LOOP
; ==============================================================================
game_loop:
    ; Continuous frame clock increment for random seed
    load r4, [bot_tick]
    addi r4, r4, 1
    store [bot_tick], r4

    ; --------------------------------------------------------------------------
    ; 1. READ INPUT CONTROLLER (MMIO at 0xC0000000)
    ; Up / W = -1, Down / S = 1, Restart (R/Space) = 2, Keys 1..4 = 11..14
    ; --------------------------------------------------------------------------
    leti r1, 0xC0000000
    load r2, [r1]

    ; Check Restart (R or Space)
    leti r4, 2
    beq  r2, r4, handle_key_restart

    ; Check Difficulty 1 (Easy)
    leti r4, 11
    beq  r2, r4, handle_key_diff1

    ; Check Difficulty 2 (Normal)
    leti r4, 12
    beq  r2, r4, handle_key_diff2

    ; Check Difficulty 3 (Hard)
    leti r4, 13
    beq  r2, r4, handle_key_diff3

    ; Check Difficulty 4 (Very Hard)
    leti r4, 14
    beq  r2, r4, handle_key_diff4

    ; Check Paddle Movement
    load r3, [p1_y]
    store [p1_old_y], r3

    subi r4, r0, 1              ; r4 = -1 (UP)
    bne  r2, r4, check_down
    leti r5, 1
    ble  r3, r5, apply_bot      ; Top wall bound
    subi r3, r3, 1              ; Player moves UP
    bra  save_p1

check_down:
    leti r4, 1                  ; r4 = 1 (DOWN)
    bne  r2, r4, apply_bot
    leti r5, 49
    bge  r3, r5, apply_bot      ; Bottom wall bound
    addi r3, r3, 1              ; Player moves DOWN

save_p1:
    store [p1_y], r3

apply_bot:
    ; --------------------------------------------------------------------------
    ; 2. BOT AI WITH DYNAMIC SHOT VARIATION & TRACKING
    ; --------------------------------------------------------------------------
    load r6, [p2_y]
    store [p2_old_y], r6

    load r1, [ball_dx]
    blez r1, move_ball          ; If ball moving away, bot doesn't track!

    load r1, [ball_x]
    load r7, [difficulty]

    load r8, [bot_tick]

    ; --- Difficulty 1: Easy ---
    leti r9, 1
    bne  r7, r9, check_diff_2
    leti r5, 52                 ; Only track when ball is close
    blt  r1, r5, move_ball
    modi r8, r8, 3              ; Moves 1 out of 3 frames (sluggish)
    bnez r8, move_ball
    bra  bot_track

check_diff_2:
    ; --- Difficulty 2: Normal ---
    leti r9, 2
    bne  r7, r9, check_diff_3
    leti r5, 35                 ; Half-court tracking
    blt  r1, r5, move_ball
    modi r8, r8, 2              ; Moves 1 out of 2 frames
    bnez r8, move_ball
    bra  bot_track

check_diff_3:
    ; --- Difficulty 3: Hard ---
    leti r9, 3
    bne  r7, r9, check_diff_4
    leti r5, 15                 ; Reacts almost immediately
    blt  r1, r5, move_ball
    bra  bot_track

check_diff_4:
    ; --- Difficulty 4: Very Hard ---
    ; Full court tracking + moves every frame!

bot_track:
    load r7, [ball_y]
    load r9, [bot_target_offset] ; Dynamic hit point (1=top, 4=center, 7=bottom)
    add  r8, r6, r9              ; Target y = p2_y + bot_target_offset
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
    ; --------------------------------------------------------------------------
    ; 3. MOVE BALL
    ; --------------------------------------------------------------------------
    load r1, [ball_x]
    load r2, [ball_y]
    store [ball_old_x], r1
    store [ball_old_y], r2

    load r3, [ball_dx]
    load r4, [ball_dy]
    add  r1, r1, r3
    add  r2, r2, r4

    ; Bounce Top / Bottom Walls (y <= 1 or y >= 58)
    leti r5, 1
    ble  r2, r5, bounce_y
    leti r5, 58
    bge  r2, r5, bounce_y
    bra  check_collisions

bounce_y:
    sub  r4, r0, r4             ; Negate ball_dy
    store [ball_dy], r4

check_collisions:
    ; Check ball direction: Left (dx < 0) or Right (dx > 0)
    bgtz r3, check_paddle_right

    ; --- Ball Moving LEFT towards Player 1 ---
    leti r5, 3
    bne  r1, r5, check_goal_left

    ; Ball is at x == 3: Check if Paddle 1 intercepts!
    load r6, [p1_y]
    blt  r2, r6, check_goal_left     ; Ball above paddle -> keep flying past!
    addi r7, r6, 10
    bge  r2, r7, check_goal_left     ; Ball below paddle -> keep flying past!

    ; -------------------------------------------------------------
    ; PADDLE 1 DEFLECTION & ANGLE PHYSICS
    ; -------------------------------------------------------------
    leti r3, 1
    store [ball_dx], r3
    leti r1, 4

    ; Check hit offset: delta = ball_y - p1_y (0 to 9)
    sub  r8, r2, r6
    leti r9, 2
    ble  r8, r9, p1_slice_top        ; Top 3 pixels -> dy = -1
    leti r9, 7
    bge  r8, r9, p1_slice_bot        ; Bottom 3 pixels -> dy = +1
    ; Middle 4 pixels -> dy = 0 (horizontal laser)
    leti r4, 0
    bra  save_p1_dy

p1_slice_top:
    subi r4, r0, 1
    bra  save_p1_dy

p1_slice_bot:
    leti r4, 1

save_p1_dy:
    store [ball_dy], r4
    call on_rally_hit

    ; --- AI DYNAMIC SHOT SELECTION ---
    ; Randomize bot hit target offset for this rally (top, flat, or bottom)
    load r8, [bot_tick]
    load r9, [ball_y]
    muli r9, r9, 3
    add  r8, r8, r9
    modi r8, r8, 3              ; 0, 1, or 2
    leti r9, 0
    beq  r8, r9, pick_bot_top
    leti r9, 1
    beq  r8, r9, pick_bot_bot
    ; Remainder 2: center shot (laser flat return)
    leti r9, 4
    bra  set_bot_offset

pick_bot_top:
    leti r9, 1                  ; Aim top -> returns angled UP (-1)
    bra  set_bot_offset

pick_bot_bot:
    leti r9, 7                  ; Aim bottom -> returns angled DOWN (+1)

set_bot_offset:
    store [bot_target_offset], r9

    bra  render_frame

check_goal_left:
    ; Ball missed paddle! Did it hit the back goal wall (x <= 0)?
    blez r1, player_loses_goal
    bra  render_frame

check_paddle_right:
    ; --- Ball Moving RIGHT towards AI Bot ---
    leti r5, 76
    bne  r1, r5, check_goal_right

    ; Ball is at x == 76: Check if Paddle 2 intercepts!
    load r6, [p2_y]
    blt  r2, r6, check_goal_right    ; Ball above paddle -> keep flying past!
    addi r7, r6, 10
    bge  r2, r7, check_goal_right    ; Ball below paddle -> keep flying past!

    ; -------------------------------------------------------------
    ; PADDLE 2 DEFLECTION & ANGLE PHYSICS
    ; -------------------------------------------------------------
    subi r3, r0, 1                   ; dx = -1
    store [ball_dx], r3
    leti r1, 75

    ; Check hit offset: delta = ball_y - p2_y (0 to 9)
    sub  r8, r2, r6
    leti r9, 2
    ble  r8, r9, p2_slice_top        ; Top 3 pixels -> dy = -1
    leti r9, 7
    bge  r8, r9, p2_slice_bot        ; Bottom 3 pixels -> dy = +1
    ; Middle 4 pixels -> dy = 0 (horizontal laser)
    leti r4, 0
    bra  save_p2_dy

p2_slice_top:
    subi r4, r0, 1
    bra  save_p2_dy

p2_slice_bot:
    leti r4, 1

save_p2_dy:
    store [ball_dy], r4
    call on_rally_hit
    bra  render_frame

check_goal_right:
    ; Ball missed AI! Did it hit the back goal wall (x >= 79)?
    leti r5, 79
    bge  r1, r5, ai_loses_goal

render_frame:
    store [ball_x], r1
    store [ball_y], r2

    ; --------------------------------------------------------------------------
    ; 6. ULTRA-SMOOTH DELTA RENDERING
    ; Only updates pixels that actually changed!
    ; --------------------------------------------------------------------------
    ; Erase old ball
    load r1, [ball_old_x]
    load r2, [ball_old_y]
    leti r3, 0x00000000         ; Black
    call draw_pixel

    ; Delta-update Paddle 1 (X = 2)
    leti r1, 2
    load r2, [p1_old_y]
    load r3, [p1_y]
    leti r4, 0x00FFFFFF         ; Cyan
    call update_paddle_ends

    ; Delta-update Paddle 2 (X = 77)
    leti r1, 77
    load r2, [p2_old_y]
    load r3, [p2_y]
    leti r4, 0xFF00FF00         ; Magenta
    call update_paddle_ends

    ; Draw new ball
    load r1, [ball_x]
    load r2, [ball_y]
    leti r3, 0xFFFF0000         ; Yellow
    call draw_pixel

    ; Frame delay
    call delay

    bra  game_loop

; ==============================================================================
; SCORING & ROUND LIFE CYCLE
; ==============================================================================
player_loses_goal:
    ; Ball hit left wall (x=0) -> AI Scores!
    store [ball_x], r1
    store [ball_y], r2
    load r1, [ball_old_x]
    load r2, [ball_old_y]
    leti r3, 0x00000000
    call draw_pixel
    load r1, [ball_x]
    load r2, [ball_y]
    leti r3, 0xFFFF0000
    call draw_pixel

    ; Flash screen border RED for conceded point
    leti r1, 0xFF000000
    call flash_screen
    call celebration_delay

    ; Increment AI score
    load r6, [p2_score]
    addi r6, r6, 1
    store [p2_score], r6

    ; Check if AI reached 3 points (Match Defeat!)
    leti r7, 3
    bge  r6, r7, match_lost

    ; Continue match: serve next round toward Player
    subi r1, r0, 1              ; dx = -1
    store [ball_dx], r1
    bra  serve_round

match_lost:
    ; AI won 3 points -> Permanent FAIL STATE!
    leti r1, 0xFF000000         ; RED
    call flash_screen
    bra  game_over_wait

ai_loses_goal:
    ; Ball hit right wall (x=79) -> Player Scores!
    store [ball_x], r1
    store [ball_y], r2
    load r1, [ball_old_x]
    load r2, [ball_old_y]
    leti r3, 0x00000000
    call draw_pixel
    load r1, [ball_x]
    load r2, [ball_y]
    leti r3, 0xFFFF0000
    call draw_pixel

    ; Flash screen border GREEN for scored point
    leti r1, 0x00FF0000
    call flash_screen
    call celebration_delay

    ; Increment Player score
    load r6, [p1_score]
    addi r6, r6, 1
    store [p1_score], r6

    ; Check if Player reached 3 points (Match Victory!)
    leti r7, 3
    bge  r6, r7, match_won

    ; Continue match: serve next round toward AI
    leti r1, 1                  ; dx = 1
    store [ball_dx], r1
    bra  serve_round

match_won:
    ; Player won 3 points -> Permanent VICTORY STATE!
    leti r1, 0x00FF0000         ; GREEN
    call flash_screen
    bra  game_over_wait

; ==============================================================================
; DYNAMIC SPEED ACCELERATION (Very Hard Mode)
; ==============================================================================
on_rally_hit:
    push lr
    push r6
    push r7
    load r6, [difficulty]
    leti r7, 4
    bne  r6, r7, rally_done     ; Only accelerate in Very Hard mode!

    load r6, [current_delay]
    leti r7, 800                ; Minimum delay floor (hyper speed!)
    ble  r6, r7, rally_done
    subi r6, r6, 200            ; Accelerate speed with each hit!
    store [current_delay], r6

rally_done:
    pop  r7
    pop  r6
    pop  lr
    ret

; ==============================================================================
; DIFFICULTY / RESTART HOTKEY HANDLERS
; ==============================================================================
handle_key_restart:
    call debounce_key
    bra  start_match

handle_key_diff1:
    leti r5, 1
    store [difficulty], r5
    call debounce_key
    bra  start_match

handle_key_diff2:
    leti r5, 2
    store [difficulty], r5
    call debounce_key
    bra  start_match

handle_key_diff3:
    leti r5, 3
    store [difficulty], r5
    call debounce_key
    bra  start_match

handle_key_diff4:
    leti r5, 4
    store [difficulty], r5
    call debounce_key
    bra  start_match

; ==============================================================================
; GAME OVER WAIT: Player can press R, Space, 1, 2, 3, 4, or Up/Down to restart!
; ==============================================================================
game_over_wait:
    leti r1, 0xC0000000
    load r2, [r1]

    beqz r2, go_idle            ; No key pressed yet

    ; Check if 1, 2, 3, 4 was pressed
    leti r4, 11
    blt  r2, r4, go_restart     ; Any movement/restart key -> restart match!
    leti r4, 14
    bgt  r2, r4, go_restart

    ; Key was 11, 12, 13, or 14 -> Update difficulty!
    subi r5, r2, 10
    store [difficulty], r5

go_restart:
    call debounce_key
    bra  start_match

go_idle:
    call small_delay
    bra  game_over_wait

; ==============================================================================
; debounce_key: Waits until key is released
; ==============================================================================
debounce_key:
    push lr
    push r1
    push r2
    leti r1, 0xC0000000
debounce_loop:
    load r2, [r1]
    bnez r2, debounce_loop
    pop  r2
    pop  r1
    pop  lr
    ret

; ==============================================================================
; clear_screen: Fills 80x60 framebuffer with black
; ==============================================================================
clear_screen:
    push r1
    push r2
    push r3
    leti r1, 0xB0000000
    leti r2, 0xB0004B00         ; 80 * 60 * 4 = 19200 = 0x4B00
    leti r3, 0
clear_loop:
    bge  r1, r2, clear_done
    store [r1], r3
    addi r1, r1, 4
    bra  clear_loop
clear_done:
    pop  r3
    pop  r2
    pop  r1
    ret

; ==============================================================================
; draw_borders: Top/Bottom borders + Minimalist LED Score Pips + Difficulty Dots
; Top row (y=0) layout:
;   x = 10, 12, 14 : Player 1 Score Pips (Cyan LEDs)
;   x = 37, 39, 41, 43 : Difficulty Dots
;   x = 65, 67, 69 : AI Score Pips (Magenta LEDs)
; ==============================================================================
draw_borders:
    push lr
    push r6
    push r7
    push r8
    push r9

    ; 1. Draw top (y=0) and bottom (y=59) borders in dark gray
    leti r6, 0                  ; x = 0
border_loop:
    leti r7, 80
    bge  r6, r7, border_scores

    mov  r1, r6
    leti r2, 0                  ; Top row
    leti r3, 0x22222200         ; Dark gray border
    call draw_pixel

    mov  r1, r6
    leti r2, 59                 ; Bottom row
    leti r3, 0x22222200
    call draw_pixel

    addi r6, r6, 1
    bra  border_loop

border_scores:
    ; -------------------------------------------------------------
    ; 2. Player 1 Score Pips (x=10, 12, 14, Cyan if scored)
    ; -------------------------------------------------------------
    load r8, [p1_score]

    leti r1, 10
    leti r2, 0
    leti r3, 0x33333300         ; Unlit pip
    leti r7, 1
    blt  r8, r7, p1_draw_pip1
    leti r3, 0x00FFFFFF         ; Lit Cyan pip
p1_draw_pip1:
    call draw_pixel

    leti r1, 12
    leti r2, 0
    leti r3, 0x33333300
    leti r7, 2
    blt  r8, r7, p1_draw_pip2
    leti r3, 0x00FFFFFF
p1_draw_pip2:
    call draw_pixel

    leti r1, 14
    leti r2, 0
    leti r3, 0x33333300
    leti r7, 3
    blt  r8, r7, p1_draw_pip3
    leti r3, 0x00FFFFFF
p1_draw_pip3:
    call draw_pixel

    ; -------------------------------------------------------------
    ; 3. Difficulty Indicators at top center (y=0)
    ; -------------------------------------------------------------
    ; Dot 1 (x=37) = Green
    leti r1, 37
    leti r2, 0
    leti r3, 0x00FF0000
    call draw_pixel

    load r8, [difficulty]
    leti r7, 2
    blt  r8, r7, border_p2_scores

    ; Dot 2 (x=39) = Cyan
    leti r1, 39
    leti r2, 0
    leti r3, 0x00FFFFFF
    call draw_pixel

    leti r7, 3
    blt  r8, r7, border_p2_scores

    ; Dot 3 (x=41) = Yellow
    leti r1, 41
    leti r2, 0
    leti r3, 0xFFFF0000
    call draw_pixel

    leti r7, 4
    blt  r8, r7, border_p2_scores

    ; Dot 4 (x=43) = Red
    leti r1, 43
    leti r2, 0
    leti r3, 0xFF000000
    call draw_pixel

border_p2_scores:
    ; -------------------------------------------------------------
    ; 4. AI Score Pips (x=65, 67, 69, Magenta if scored)
    ; -------------------------------------------------------------
    load r8, [p2_score]

    leti r1, 65
    leti r2, 0
    leti r3, 0x33333300         ; Unlit pip
    leti r7, 1
    blt  r8, r7, p2_draw_pip1
    leti r3, 0xFF00FF00         ; Lit Magenta pip
p2_draw_pip1:
    call draw_pixel

    leti r1, 67
    leti r2, 0
    leti r3, 0x33333300
    leti r7, 2
    blt  r8, r7, p2_draw_pip2
    leti r3, 0xFF00FF00
p2_draw_pip2:
    call draw_pixel

    leti r1, 69
    leti r2, 0
    leti r3, 0x33333300
    leti r7, 3
    blt  r8, r7, p2_draw_pip3
    leti r3, 0xFF00FF00
p2_draw_pip3:
    call draw_pixel

borders_done:
    pop  r9
    pop  r8
    pop  r7
    pop  r6
    pop  lr
    ret

; ==============================================================================
; flash_screen: Paints entire top and bottom borders with color in r1
; ==============================================================================
flash_screen:
    push lr
    push r6
    push r7
    mov  r6, r1                 ; Color
    leti r7, 0                  ; x = 0
flash_loop:
    leti r8, 80
    bge  r7, r8, flash_done
    mov  r1, r7
    leti r2, 0                  ; Top row
    mov  r3, r6
    call draw_pixel
    mov  r1, r7
    leti r2, 59                 ; Bottom row
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
; Inputs: r1 = x, r2 = old_y, r3 = new_y, r4 = paddle_color
; ==============================================================================
update_paddle_ends:
    push lr
    push r6
    push r7
    push r8
    push r9

    beq  r2, r3, ends_done      ; If paddle didn't move, write 0 pixels!

    blt  r3, r2, paddle_moved_up

    ; --- PADDLE MOVED DOWN (new_y > old_y) ---
    mov  r6, r1
    mov  r7, r2
    mov  r8, r3
    mov  r9, r4

    ; Erase old top pixel: (x, old_y) -> Black
    mov  r1, r6
    mov  r2, r7
    leti r3, 0x00000000
    call draw_pixel

    ; Draw new bottom pixel: (x, new_y + 9) -> paddle_color
    mov  r1, r6
    addi r2, r8, 9
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
    mov  r2, r8
    mov  r3, r9
    call draw_pixel

    ; Erase old bottom pixel: (x, old_y + 9) -> Black
    mov  r1, r6
    addi r2, r7, 9
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
; draw_full_paddle: Draws all 10 pixels (used at round start/restart)
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
; delay routines
; ==============================================================================
delay:
    load r10, [current_delay]
delay_loop:
    subi r10, r10, 1
    bgtz r10, delay_loop
    ret

small_delay:
    leti r10, 2000
sdelay_loop:
    subi r10, r10, 1
    bgtz r10, sdelay_loop
    ret

celebration_delay:
    leti r10, 80000
cdelay_loop:
    subi r10, r10, 1
    bgtz r10, cdelay_loop
    ret
