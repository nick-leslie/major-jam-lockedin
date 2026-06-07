package game

import "core:encoding/entity"
import rl "vendor:raylib"
import "core:math/linalg"

Character :: struct {
    using entity:Entity,
    texture:rl.Texture2D,
    player_pickup_box:rl.Rectangle,
}

player_update :: proc(player: ^Entity){
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
    player_collider := rl.Rectangle {
        x = player.pos.x,
        y= player.pos.y,
        width = player.size.x,
        height = player.size.y
    }
	if check_map_collision_tile(player_collider,g.tile_map) == false {
	    player.pos += player.vel
	}
}

player_draw :: proc(player: ^Character){
	rl.DrawTextureEx(player.texture, player.pos, 0, 1, rl.WHITE)
}

player_setup :: proc(player: ^Character, accel: f32 = 100, damping: f32 = 0.85, max_speed: f32 = 100){
	player.texture = rl.LoadTexture("assets/round_cat.png")
	player.accel = accel
	player.damp = damping
	player.max_speed = max_speed
	player.size = {0,0,10,10}
}


player_pickup_weppon :: proc(player:^Character,lvl:^Level) {
    for i:=0;i<len(lvl.pickups);i+=1 {
        item_index := lvl.pickups[i]
        item := lvl.entitys[item_index]
        assert(item.type == .Pickup,"you cant put anything oither than an item here")
        rect_base := [4]f32{item.size.x,item.size.y,item.size.width,item.size.height}+[4]f32{item.x,item.y,0,0}
        //todo the part above this sucks
        if rl.CheckCollisionRecs(player.player_pickup_box,rl.Rectangle{rect_base.x,rect_base.y,rect_base.z,rect_base.w}) {
            player.holding = i8(item_index)
        }
    }
}
