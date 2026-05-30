package game

import rl "vendor:raylib"
import "core:math/linalg"

Character :: struct {
	pos: rl.Vector2,
	vel: rl.Vector2,
	texture: rl.Texture,
	size:rl.Vector2,
	accel: f32,
	damp: f32,
	max_speed: f32,
}

player_update :: proc(player: ^Character){
	input: rl.Vector2

	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
		input.y -= 1
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		input.y += 1
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		input.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		input.x += 1
	}

	input = linalg.normalize0(input)
	player.vel += input * rl.GetFrameTime() * player.accel
	player.vel *= player.damp
	speed := linalg.length(player.vel)
	if speed > player.max_speed {
		player.vel = player.vel / speed * player.max_speed
	}
	// check_map_collision_tile(player,g.tile_map)
	player.pos += player.vel
}

player_draw :: proc(player: ^Character){
	rl.DrawTextureEx(player.texture, player.pos, 0, 1, rl.WHITE)
}

player_setup :: proc(player: ^Character, accel: f32 = 100, damping: f32 = 0.85, max_speed: f32 = 100){
	player.texture = rl.LoadTexture("assets/round_cat.png")
	player.accel = accel
	player.damp = damping
	player.max_speed = max_speed
	player.size = {10,10}
}
