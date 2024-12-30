package game

import    "core:fmt"
import    "core:math"
import    "core:math/linalg"
import	  "core:math/rand"
import rl "vendor:raylib"

WINDOW_WIDTH  :: 1080
WINDOW_HEIGHT :: 720
WINDOW_CENTER :: WINDOW_WIDTH / 2 
LINE_WIDTH    :: 1 
LINE_HEIGHT   :: 16
LINE_SPACING  :: 8
PADDLE_WIDTH  :: 12
PADDLE_HEIGHT :: 40
PADDLE_SPEED  :: 30
BALL_SPEED    :: 3 
BALL_SIZE     :: 10
MAX_SCORE     :: 5
SPEED_INC     :: 0.2
CPU_SPEED     :: 4.0

Paddle :: struct {
    width: int,
    height: int,
    pos: rl.Vector2,
}

Ball :: struct {
    size: f32, // Will use same size for LxW of Rectangle (PONG USED RECTANGLE BALL)
    speed:  rl.Vector2,
    pos:    rl.Vector2
}

Game_State :: struct {
    player: Paddle,
    cpu : Paddle,
    ball: Ball,
    player_score: int,
    cpu_score:    int,
    max_score: int,
    scene: Game_Scene,
}

Game_Scene :: enum {
    Menu,
    Start,
    GameOver,
    NewGame,
    NextRound,
}


// Global initializers
scene  := Game_Scene(.Menu)
player := Paddle{PADDLE_WIDTH, PADDLE_HEIGHT, rl.Vector2{ WINDOW_WIDTH * .1 , WINDOW_HEIGHT / 2}}
cpu    := Paddle{PADDLE_WIDTH, PADDLE_HEIGHT, rl.Vector2{ WINDOW_WIDTH * .9, WINDOW_HEIGHT / 2}}
ball   := Ball{10, rl.Vector2{BALL_SPEED, BALL_SPEED}, rl.Vector2{0, 0}}
state := Game_State{player, cpu, ball, 0, 0, MAX_SCORE, scene}

paddle_sound    : rl.Sound
ball_sound      : rl.Sound
gamestart_sound : rl.Sound
score_sound  : rl.Sound 

main :: proc() {
    // Set up
    rl.SetConfigFlags({})
    rl.SetTargetFPS(60)
    rl.InitAudioDevice()

     // Initialize Game State
    initial_state(&state)

    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Odin Pong")

    paddle_sound = rl.LoadSound("paddle_hit.wav")
    ball_sound = rl.LoadSound("ball_hit.wav")
    gamestart_sound = rl.LoadSound("game_start.wav")
    score_sound = rl.LoadSound("score.wav")

     // Main game Loop
    for !rl.WindowShouldClose() {
	if scene ==      .Menu     { scene = scene_menu(&state) }
	else if scene == .NewGame  { scene = scene_new_game(&state) }
	else if scene == .Start    { scene = scene_game_start(&state) }
	else if scene == .GameOver { scene = scene_game_over(&state) }
	else if scene == .NextRound    { scene = scene_next_round(&state) }
    }

    defer rl.UnloadSound(paddle_sound)
    defer rl.UnloadSound(ball_sound)
    defer rl.UnloadSound(gamestart_sound)
    defer rl.UnloadSound(score_sound)
    defer rl.CloseAudioDevice()
    defer rl.CloseWindow()

}

initial_state :: proc(state: ^Game_State) {
    scene  := Game_Scene.Menu
    player := Paddle{PADDLE_WIDTH, PADDLE_HEIGHT, rl.Vector2{ WINDOW_WIDTH * 0.1, WINDOW_HEIGHT / 2}}
    cpu    := Paddle{PADDLE_WIDTH, PADDLE_HEIGHT, rl.Vector2{ WINDOW_WIDTH * 0.9, WINDOW_HEIGHT / 2}}
    ball   := Ball{10, rl.Vector2{BALL_SPEED, BALL_SPEED}, rl.Vector2{0, 0}}
    state := Game_State{player, cpu, ball, 0, 0, MAX_SCORE, scene}
}

random_ball_speed :: proc() -> rl.Vector2 {

    number_flags := [4]int {0, 1, 2, 3}
    random_start_vector_flag := rand.choice(number_flags[:])
    speed : rl.Vector2 
    switch random_start_vector_flag {
	case 0: speed = {BALL_SPEED, -BALL_SPEED} // Top Right
	case 1: speed = {-BALL_SPEED, -BALL_SPEED} // Top Left
	case 2: speed = {-BALL_SPEED, BALL_SPEED} // Bottom left
	case 3: speed = {BALL_SPEED, BALL_SPEED} // Bottom Right
    }

    return speed
}

// ------------- Update Functions ------------------
scene_menu :: proc(state: ^Game_State) -> Game_Scene {

    for !rl.WindowShouldClose() {

	free_all(context.temp_allocator)

	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	text := fmt.ctprint("Start Game")
	text_width := rl.MeasureText(text, 24)
	button_rect := rl.Rectangle {f32(WINDOW_CENTER - text_width / 2), f32(WINDOW_HEIGHT / 2), f32(text_width), 20}
	mouse_position := rl.GetMousePosition()

	if rl.IsKeyPressed(.ENTER) {
	    rl.PlaySound(gamestart_sound)
	    return .NewGame
	}

	if rl.CheckCollisionPointRec(mouse_position, button_rect) {
	    rl.SetMouseCursor(.POINTING_HAND)
	    rl.DrawRectangleRec(button_rect, rl.WHITE)
	    rl.DrawText(text, WINDOW_CENTER - text_width / 2, WINDOW_HEIGHT / 2, 24, rl.BLACK)

	    if rl.IsMouseButtonPressed(.LEFT) || rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) { 
		rl.PlaySound(gamestart_sound)
		return .NewGame 
	    }
	}
	else {
	    rl.SetMouseCursor(.DEFAULT)
	    rl.DrawRectangleRec(button_rect, rl.BLACK)
	    rl.DrawText(text, WINDOW_CENTER - text_width / 2, WINDOW_HEIGHT / 2, 24, rl.WHITE)
	}
	
	title_text := fmt.ctprint("ODIN PONG")
	title_text_width := rl.MeasureText(title_text, 64)
	rl.DrawText(title_text, WINDOW_CENTER - title_text_width / 2, 50, 64, rl.WHITE)	
	rl.EndDrawing()
    
    }

    return .Menu

}

scene_new_game :: proc(state: ^Game_State) -> Game_Scene {

    initial_state(state) 
	
    random_ball_position := rand.float32_range(100, WINDOW_HEIGHT - 100)
    state.ball.pos.x = WINDOW_CENTER - 5
    state.ball.pos.y = random_ball_position
    state.ball.speed = random_ball_speed()	

     for !rl.WindowShouldClose() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	draw_seperator_line()
	draw_score_text(state)
	draw_player(state)
	draw_cpu(state)
	draw_ball(state)

	start_text := fmt.ctprintf("Press SPACE")
	start_text_con := fmt.ctprintf("to start!")
	st_width := rl.MeasureText(start_text, 24)

	rl.DrawText(start_text, WINDOW_CENTER - st_width - 20, WINDOW_HEIGHT / 2, 24, rl.WHITE)
	rl.DrawText(start_text_con, WINDOW_CENTER + 20, WINDOW_HEIGHT / 2, 24, rl.WHITE)
	if rl.IsKeyPressed(.SPACE) { return .Start }
	
	rl.EndDrawing()
    
    }

    return .NewGame
}

scene_game_start :: proc(state: ^Game_State) -> Game_Scene {

    frame, time, goal_time := 0, 0, 0
    goal_scored := false
    delay_time := 2
    target := state.ball.pos.y
    reaction_time : f32 = 0.0

    for !rl.WindowShouldClose() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	delta := rl.GetFrameTime()
	player_input : rl.Vector2
	frame += 1

	if frame == 60 {
	    time += 1 
	    frame = 0
	}

	{ // Handle Player Updates 
	    if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {
		player_input.y += 1 * 500 * delta

	    }
	    else if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {
		player_input.y -= 1 * 500 * delta
	    }
	    state.player.pos += player_input

	    // Clamps the positions of the paddles between the WINDOW_HEIGHT on the Y axis
	    state.player.pos.y = linalg.clamp(state.player.pos.y, 0, WINDOW_HEIGHT - PADDLE_HEIGHT)

	}


	{ // Handle CPU Updates 
	    reaction_time += delta
	    state.cpu.pos.y = linalg.clamp(state.cpu.pos.y, 0, WINDOW_HEIGHT - PADDLE_HEIGHT)

	    if target > state.cpu.pos.y + PADDLE_HEIGHT / 2 {
		state.cpu.pos.y += CPU_SPEED 
	    } else if target < state.cpu.pos.y + PADDLE_HEIGHT / 2 {
		state.cpu.pos.y -= CPU_SPEED 
	    }

	    if reaction_time >= 0.05 {
		target = state.ball.pos.y
		reaction_time = 0
	    }

	}
	

	{ // Handle Ball Updates
	    state.ball.pos += state.ball.speed
	    
	    // Collision handling with top & bottom of screen
	    if state.ball.pos.y + BALL_SIZE <= 0 {
		state.ball.speed.y = -state.ball.speed.y
		state.ball.pos.y = BALL_SIZE 
		rl.PlaySound(ball_sound)
	    } else if state.ball.pos.y >= WINDOW_HEIGHT - BALL_SIZE {
		state.ball.speed.y = -state.ball.speed.y
		state.ball.pos.y = WINDOW_HEIGHT - BALL_SIZE
		rl.PlaySound(ball_sound)
	    }
	    
	    // Handle Player Paddle Collision
	    if check_player_collision() {
		state.ball.speed.y = -math.abs(state.ball.speed.y);

		// Adjust horizontal speed based on where the ball hits the paddle
		paddle_center := state.player.pos.x + PADDLE_WIDTH / 2
		distance_from_center := state.ball.pos.x - paddle_center;
		state.ball.speed.x += BALL_SPEED + distance_from_center * SPEED_INC;

		rl.PlaySound(paddle_sound)
	    }
	    // Handle CPU Paddle Collision
	    if check_cpu_collision() {
		state.ball.speed.y = -math.abs(state.ball.speed.y)

		// Adjust horizontal speed based on where the ball hits the paddle
		paddle_center := state.cpu.pos.x - PADDLE_WIDTH / 2
		distance_from_center := state.ball.pos.x - paddle_center
		state.ball.speed.x += -math.abs(BALL_SPEED + distance_from_center * SPEED_INC)

		rl.PlaySound(paddle_sound)
	    }

	   // Handle Goal Score
	    if state.ball.pos.x + BALL_SIZE <= 0 && state.cpu_score <= MAX_SCORE {
		state.cpu_score += 1
		state.player.pos = { WINDOW_WIDTH * 0.1, WINDOW_HEIGHT / 2}
		state.cpu.pos = { WINDOW_WIDTH * 0.9, WINDOW_HEIGHT / 2}
		random_ball_position := rand.float32_range(100, WINDOW_HEIGHT - 100)
		state.ball.pos.x = WINDOW_CENTER - 5 
		state.ball.pos.y = random_ball_position
		state.ball.speed = {0,0}
		goal_scored = true
		goal_time = time
		rl.PlaySound(score_sound)

	
	    } else if state.ball.pos.x > WINDOW_WIDTH - BALL_SIZE && state.player_score <= MAX_SCORE {
		state.player_score += 1
		state.player.pos = { WINDOW_WIDTH * 0.1, WINDOW_HEIGHT / 2}
		state.cpu.pos = { WINDOW_WIDTH * 0.9, WINDOW_HEIGHT / 2}
		random_ball_position := rand.float32_range(100, WINDOW_HEIGHT - 100)
		state.ball.pos.x = WINDOW_CENTER - 5 
		state.ball.pos.y = random_ball_position
		state.ball.speed = {0,0}
		goal_scored = true
		goal_time = time
		rl.PlaySound(score_sound)

	    } 
	    else if state.cpu_score == MAX_SCORE || state.player_score == MAX_SCORE {
		return .GameOver
	    }
	    else if goal_scored && time - goal_time == delay_time {
		goal_scored = false
		state.ball.speed = random_ball_speed()
	    }

	}

	draw_seperator_line()
	draw_score_text(state)
	draw_player(state)
	draw_cpu(state)
	draw_ball(state)

	rl.EndDrawing()
    }
    return .Start
}

scene_game_over :: proc(state: ^Game_State) -> Game_Scene {

    state.player = Paddle{PADDLE_WIDTH, PADDLE_HEIGHT, rl.Vector2{ WINDOW_WIDTH * 0.1, WINDOW_HEIGHT / 2}}
    state.cpu    = Paddle{PADDLE_WIDTH, PADDLE_HEIGHT, rl.Vector2{ WINDOW_WIDTH * 0.9, WINDOW_HEIGHT / 2}}
    state.ball   = Ball{10, rl.Vector2{BALL_SPEED, BALL_SPEED}, rl.Vector2{0, 0}}

    for !rl.WindowShouldClose() {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.BLACK)

	//TODO; Draw Winnter text & show button to restart the game
	text := fmt.ctprint("Start Game")
	text_width := rl.MeasureText(text, 24)
	button_rect := rl.Rectangle {f32(WINDOW_CENTER - text_width / 2), f32(WINDOW_HEIGHT / 2), f32(text_width), 20}
	mouse_position := rl.GetMousePosition()

	title_text : cstring
	
	if (state.player_score == MAX_SCORE) {
	    title_text = fmt.ctprint("Player 1 Wins!")
	}
	else if state.cpu_score == MAX_SCORE {
	    title_text = fmt.ctprint("CPU Wins!")
	}

	title_text_width := rl.MeasureText(title_text, 64)
	rl.DrawText(title_text, WINDOW_CENTER - title_text_width / 2, 50, 64, rl.WHITE)	

	if rl.IsKeyPressed(.ENTER) {
	    state.player_score = 0
	    state.cpu_score = 0
	    rl.PlaySound(gamestart_sound)
	    return .NewGame
	}

	if rl.CheckCollisionPointRec(mouse_position, button_rect) {
	    rl.SetMouseCursor(.POINTING_HAND)
	    rl.DrawRectangleRec(button_rect, rl.WHITE)
	    rl.DrawText(text, WINDOW_CENTER - text_width / 2, WINDOW_HEIGHT / 2, 24, rl.BLACK)

	    if rl.IsMouseButtonPressed(.LEFT) || rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) { 
		rl.PlaySound(gamestart_sound)
		state.player_score = 0
		state.cpu_score = 0
		return .NewGame 
	    }
	}
	else {
	    rl.SetMouseCursor(.DEFAULT)
	    rl.DrawRectangleRec(button_rect, rl.BLACK)
	    rl.DrawText(text, WINDOW_CENTER - text_width / 2, WINDOW_HEIGHT / 2, 24, rl.WHITE)
	}
	
    }

    return .GameOver
}

scene_next_round :: proc(state: ^Game_State) -> Game_Scene {
    return .Start
}

check_player_collision :: proc() -> bool {
    player_rec := rl.Rectangle {
	x      = state.player.pos.x,
	y      = state.player.pos.y,
	width  = PADDLE_WIDTH,
	height = PADDLE_HEIGHT,
    }

    ball_rec := rl.Rectangle {
	x = state.ball.pos.x,
	y = state.ball.pos.y,
	width = BALL_SIZE,
	height = BALL_SIZE,
    }

    return rl.CheckCollisionRecs(player_rec, ball_rec)
}

check_cpu_collision :: proc() -> bool {
    cpu_rec := rl.Rectangle {
	x      = state.cpu.pos.x,
	y      = state.cpu.pos.y,
	width  = PADDLE_WIDTH,
	height = PADDLE_HEIGHT,
    }

    ball_rec := rl.Rectangle {
	x = state.ball.pos.x,
	y = state.ball.pos.y,
	width = BALL_SIZE,
	height = BALL_SIZE,
    }

    return rl.CheckCollisionRecs(cpu_rec, ball_rec)

}


// -------------- Rendering Functions- ----------------
draw_seperator_line :: proc() {
    x: i32 = 0

    for i in 0..<30 {
	rl.DrawRectangle(WINDOW_CENTER, x, LINE_WIDTH, LINE_HEIGHT, rl.WHITE)
	x += 24
    }
}

draw_score_text :: proc(state: ^Game_State) {
    // Player Score
    player_text := fmt.ctprintf("%d", state.player_score)
    rl.DrawText(player_text, WINDOW_CENTER * 0.5, 20, 64, rl.WHITE)

    // CPU Score
    cpu_text := fmt.ctprintf("%d", state.cpu_score)
    rl.DrawText(cpu_text, WINDOW_CENTER * 1.5, 20, 64, rl.WHITE)
}

draw_player :: proc(state: ^Game_State) {
    
    player_pos_x, player_pos_y := i32(state.player.pos.x), i32(state.player.pos.y)
    rl.DrawRectangle(
	player_pos_x, 
	player_pos_y, 
	PADDLE_WIDTH,
	PADDLE_HEIGHT,
	rl.WHITE
    )
   
}

draw_cpu :: proc(state: ^Game_State) {

    cpu_pos_x, cpu_pos_y := i32(state.cpu.pos.x), i32(state.cpu.pos.y)
    rl.DrawRectangle(
	cpu_pos_x, 
	cpu_pos_y,
	PADDLE_WIDTH,
	PADDLE_HEIGHT,
	rl.WHITE
    )
}

draw_ball :: proc(state: ^Game_State) {
    ball_pos_x, ball_pos_y := i32(state.ball.pos.x), i32(state.ball.pos.y)
    rl.DrawRectangle(ball_pos_x, ball_pos_y, BALL_SIZE, BALL_SIZE, rl.WHITE)     
}


