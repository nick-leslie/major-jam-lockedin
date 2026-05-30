/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
- game_should_close: For stopping your game when close button is pressed
- game_shutdown: Shuts down game and frees memory
- game_shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
	pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g` global
	variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

VIRTUAL_WIDTH :: 480
VIRTUAL_HEIGHT :: 270


Game_Memory :: struct {
	// player_pos: rl.Vector2,
	// player_texture: rl.Texture,
	player: Character,
	some_number: int,
	run: bool,
	canvas: rl.RenderTexture2D,
}

g: ^Game_Memory

game_camera :: proc() -> rl.Camera2D {
	return {
			zoom = 1.0, // Scale is 1.0 because we are rendering 1:1 into the canvas
			target = g.player.pos,
			offset = { VIRTUAL_WIDTH / 2, VIRTUAL_HEIGHT / 2 }, // Center on the virtual canvas
		}
}

ui_camera :: proc() -> rl.Camera2D {
	return {
		zoom = 1.0,
	}
}

update :: proc() {

	player_update(&g.player)
	
	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
	}

	if rl.IsKeyPressed(.F1) {
		rl.SetWindowSize(1280, 720)
	}
	if rl.IsKeyPressed(.F2) {
		rl.SetWindowSize(1920, 1080)
	}
	if rl.IsKeyPressed(.F3) {
		rl.SetWindowSize(2560, 1440)
	}
	if rl.IsKeyPressed(.F4) {
		rl.SetWindowSize(3840, 2160)
	}
}

draw :: proc() {
	// ---Draw game world to render texture ---
	rl.BeginTextureMode(g.canvas)
		rl.ClearBackground(rl.BLACK) // Virtual background color

		rl.BeginMode2D(game_camera())
			player_draw(&g.player)
			rl.DrawRectangleV({20, 20}, {10, 10}, rl.RED)
			rl.DrawRectangleV({-30, -20}, {10, 10}, rl.GREEN)
		rl.EndMode2D()

		rl.BeginMode2D(ui_camera())
			rl.DrawText(fmt.ctprintf("some_number: %v\nplayer_pos: %v", g.some_number, g.player.pos), 5, 5, 8, rl.WHITE)
		rl.EndMode2D()
	rl.EndTextureMode()

	// --- Draw render texture to window ---
	rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK) // Black bars fill the rest of the window

		window_w := f32(rl.GetScreenWidth())
		window_h := f32(rl.GetScreenHeight())

		// Calculate the optimal scaling factor to fit the window cleanly
		scale := math.min(window_w / VIRTUAL_WIDTH, window_h / VIRTUAL_HEIGHT)

		// Source rect: OpenGL render textures are vertically inverted, so we flip the height
		src_rect := rl.Rectangle{ 0, 0, VIRTUAL_WIDTH, -VIRTUAL_HEIGHT }

		// Destination rect: Center the texture in the window with letterboxing/pillarboxing
		dst_rect := rl.Rectangle{
			(window_w - (VIRTUAL_WIDTH * scale)) * 0.5,
			(window_h - (VIRTUAL_HEIGHT * scale)) * 0.5,
			VIRTUAL_WIDTH * scale,
			VIRTUAL_HEIGHT * scale,
		}

		// Draw the complete scaled frame to the monitor
		rl.DrawTexturePro(g.canvas.texture, src_rect, dst_rect, {0, 0}, 0, rl.WHITE)
	rl.EndDrawing()
}

@(export)
game_update :: proc() {
	update()
	draw()

	// Everything on tracking allocator is valid until end-of-frame.
	free_all(context.temp_allocator)
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "Odin + Raylib + Hot Reload template!")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
	g = new(Game_Memory)

	g^ = Game_Memory {
		run = true,
		some_number = 100,

		// Initialize the canvas at virtual resolution
		canvas = rl.LoadRenderTexture(VIRTUAL_WIDTH, VIRTUAL_HEIGHT),
		
		// You can put textures, sounds and music in the `assets` folder. Those
		// files will be part any release or web build.
		//player_texture = rl.LoadTexture("assets/round_cat.png"),
	}
	rl.SetTextureFilter(g.canvas.texture, .POINT) // Set point filtering for pixel art
	
	player_setup(&g.player)
	
	game_hot_reloaded(g)
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return g.run
}

@(export)
game_shutdown :: proc() {
	rl.UnloadRenderTexture(g.canvas)
	free(g)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g = (^Game_Memory)(mem)

	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside `g`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
