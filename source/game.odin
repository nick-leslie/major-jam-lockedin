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

import "core:log"
import "core:fmt"
import rl "vendor:raylib"
import tiled "../libs/odin-tiled/tiled"
import vmem "core:mem/virtual"
import "core:mem"
PIXEL_WINDOW_HEIGHT :: 180

Game_Memory :: struct {
	// player_pos: rl.Vector2,
	// player_texture: rl.Texture,
	player: Character,
	some_number: int,
	run: bool,
	tile_map: tiled.Map,
	sprite_sheet: rl.Texture,
	arena:mem.Dynamic_Arena,
}

g: ^Game_Memory

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {
		zoom = h/PIXEL_WINDOW_HEIGHT,
		target = g.player.pos,
		offset = { w/2, h/2 },
	}
}

ui_camera :: proc() -> rl.Camera2D {
	return {
		zoom = f32(rl.GetScreenHeight())/PIXEL_WINDOW_HEIGHT,
	}
}

update :: proc() {

	player_update(&g.player)

	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.BeginMode2D(game_camera())
	render_tiled_map(g.tile_map, g.sprite_sheet)
	player_draw(&g.player)
	rl.DrawRectangleV({20, 20}, {10, 10}, rl.RED)
	rl.DrawRectangleV({-30, -20}, {10, 10}, rl.GREEN)
	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())

	// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
	// cleared at the end of the frame by the main application, meaning inside
	// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
	rl.DrawText(fmt.ctprintf("some_number: %v\nplayer_pos: %v", g.some_number, g.player.pos), 5, 5, 8, rl.WHITE)

	rl.EndMode2D()

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
	arena:mem.Dynamic_Arena
	mem.dynamic_arena_init(&arena)   // only if not already initialized elsewhere
	arena_alocator := mem.dynamic_arena_allocator(&arena)
	log.debug("test")
    tiled_map := tiled.parse_tilemap("assets/test2.tmj",arena_alocator)
    tileset_texture := rl.LoadTexture("assets/moderninteriors-win/1_Interiors/32x32/Room_Builder_32x32.png")


	g^ = Game_Memory {
		run = true,
		some_number = 100,
		tile_map = tiled_map,
		sprite_sheet = tileset_texture,
		arena = arena,
		// You can put textures, sounds and music in the `assets` folder. Those
		// files will be part any release or web build.
		//player_texture = rl.LoadTexture("assets/round_cat.png"),
	}

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
	mem.dynamic_arena_destroy(&g.arena)
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
