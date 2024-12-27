package game

import    "core:fmt"
import    "core:math/linalg"
import rl "vendor:raylib"

WINDOW_WIDTH  :: 1080
WINDOW_HEIGHT :: 720
WINDOW_CENTER :: WINDOW_WIDTH / 2 
LINE_WIDTH    :: 2
LINE_HEIGHT   :: 16
LINE_SPACING  :: 8
PADDLE_WIDTH  :: 12
PADDLE_HEIGHT :: 40
PADDLE_SPEED  :: 30

Paddle :: struct {
    width: int,
    height: int,
    pos: rl.Vector2,
}

Ball :: struct {
    width:  int,
    height: int,
    pos:    rl.Vector2
}

Game_State :: struct {
    player_paddle: Paddle,
    cpu_paddle : Paddle,
    ball: Ball,
    player_score: int,
    cpu_score:    int,
    scene: Game_Scene,
}

Game_Scene :: enum {
    Menu,
    Start,
    Pause,
    GameOver,
    NewGame,
}


// Global initializers
scene  := Game_Scene(.Menu)
player := Paddle{PADDLE_WIDTH, PADDLE_HEIGHT, rl.Vector2{ WINDOW_WIDTH * .1 , WINDOW_HEIGHT / 2}}
cpu    := Paddle{PADDLE_WIDTH, PADDLE_HEIGHT, rl.Vector2{ WINDOW_WIDTH * .9, WINDOW_HEIGHT / 2}}
ball   := Ball{10, 10, rl.Vector2{0, 0}}
state := Game_State{player, cpu, ball, 0, 0, scene}




main :: proc() {
    // Set up
    rl.SetConfigFlags({})
    rl.SetTargetFPS(60)

    // Initialize Game State
    reset_state()

    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Odin Pong")
    defer rl.CloseWindow()

    // Main game Loop
    for !rl.WindowShouldClose() {
	if scene ==      .Menu     { scene = scene_menu() }
	else if scene == .NewGame  { scene = scene_new_game() }
	else if scene == .Start    { scene = scene_game_start() }
	else if scene == .GameOver { scene = scene_game_over() }
	else if scene == .Pause    { scene = scene_pause() }
    }
}

reset_state :: proc() {
    player := Paddle{PADDLE_WIDTH, PADDLE_HEIGHT, rl.Vector2{ WINDOW_WIDTH * 0.15, WINDOW_HEIGHT / 2}}
    cpu    := Paddle{PADDLE_WIDTH, PADDLE_HEIGHT, rl.Vector2{ WINDOW_WIDTH * 0.85, WINDOW_HEIGHT / 2}}
    ball   := Ball{10, 10, rl.Vector2{0, 0}}
    state := Game_State{player, cpu, ball, 0, 0, scene}
}


// Game Scene States
scene_menu :: proc() -> Game_Scene {

    for !rl.WindowShouldClose() {

	free_all(context.temp_allocator)

	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	text := fmt.ctprint("Start Game")
	text_width := rl.MeasureText(text, 24)
	button_rect := rl.Rectangle {f32(WINDOW_CENTER - text_width / 2), f32(WINDOW_HEIGHT / 2), f32(text_width), 20}
	mouse_position := rl.GetMousePosition()

	if rl.CheckCollisionPointRec(mouse_position, button_rect) {
	    rl.SetMouseCursor(.POINTING_HAND)
	    rl.DrawRectangleRec(button_rect, rl.WHITE)
	    rl.DrawText(text, WINDOW_CENTER - text_width / 2, WINDOW_HEIGHT / 2, 24, rl.BLACK)

	    if rl.IsMouseButtonPressed(.LEFT) || rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.SPACE) { 
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
	rl.DrawText("ODIN PONG", WINDOW_CENTER - title_text_width / 2, 50, 64, rl.WHITE)	
	rl.EndDrawing()
    
    }

    return .Menu

}

scene_new_game :: proc() -> Game_Scene {

    reset_state() 

     for !rl.WindowShouldClose() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)
	draw_seperator_line()
	draw_score_text(state.player_score, state.cpu_score)
	draw_player_paddle(state.player_paddle.pos)
	if rl.IsKeyPressed(.SPACE) { return .Start }
	
	rl.EndDrawing()
    
    }

    return .NewGame
}

scene_game_start :: proc() -> Game_Scene {

    for !rl.WindowShouldClose() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	delta := rl.GetFrameTime()
	player_input : rl.Vector2
	
	if rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN) {
	    player_input.y += 1 * 500 * delta
	}
	else if rl.IsKeyDown(.W) || rl.IsKeyDown(.UP) {
	    player_input.y -= 1 * 500 * delta
	}

	state.player_paddle.pos += player_input

	fmt.println("Player position %d", state.player_paddle.pos.y)

	draw_seperator_line()
	draw_score_text(state.player_score, state.cpu_score)
	draw_player_paddle(state.player_paddle.pos)

	rl.EndDrawing()
    }
    return .Start
}

scene_game_over :: proc() -> Game_Scene {
    return .GameOver
}

scene_pause :: proc() -> Game_Scene {
    return .Pause
}



// Rendering Functions
draw_seperator_line :: proc() {
    x: i32 = 0

    for i in 0..<30 {
	rl.DrawRectangle(WINDOW_CENTER, x, LINE_WIDTH, LINE_HEIGHT, rl.WHITE)
	x += 24
    }
}

draw_score_text :: proc(player_score: int, cpu_score: int) {
    // Player Score
    player_text := fmt.ctprintf("%d", player_score)
    rl.DrawText(player_text, WINDOW_CENTER * 0.5, 20, 64, rl.WHITE)

    // CPU Score
    cpu_text := fmt.ctprintf("%d", cpu_score)
    rl.DrawText(cpu_text, WINDOW_CENTER * 1.5, 20, 64, rl.WHITE)
}

draw_player_paddle :: proc(player_position: rl.Vector2) {
    
	player_pos_x, player_pos_y := i32(player_position.x), i32(player_position.y)
	rl.DrawRectangle(
	    player_pos_x, 
	    player_pos_y, 
	    PADDLE_WIDTH,
	    PADDLE_HEIGHT,
	    rl.WHITE
	)
   
}

draw_ball :: proc() {

}


