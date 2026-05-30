package game
import rl "vendor:raylib"
import tiled "../libs/odin-tiled/tiled"
import "core:log"
import "core:mem"

Level :: struct {
    tile_map:tiled.Map,
    // entitys: [50]Entity,
    // enemys: [50]i32 index for enemeys
}

setup_level_1 :: proc(g:^Game_Memory) -> Level {
    arena_alocator := mem.dynamic_arena_allocator(&g.level_arena)
    mem.free_all(arena_alocator)
    tiled_map := tiled.parse_tilemap("assets/level1.tmj",arena_alocator)
    return Level {
        tile_map=tiled_map,
    }
}

render_tiled_map :: proc(t_map: tiled.Map, texture: rl.Texture2D,tile_width:i32=32,tile_height:i32=32) {
    for layer in t_map.layers {
        for y in 0..<layer.height {
            for x in 0..<layer.width {
                gid := layer.data[y * layer.width + x]
                if gid == 0 {
                    continue
                }
                tile_x := i32(gid - 1) % (texture.width / tile_width)
                tile_y := i32(gid - 1) / (texture.width / tile_height)

                src_rect := rl.Rectangle{
                    x = f32(tile_x * tile_width),
                    y = f32(tile_y * tile_height),
                    width = f32(tile_width),
                    height = f32(tile_height),
                }

                dst_rect := rl.Rectangle{
                    x = f32(x * tile_width),
                    y = f32(y * tile_height),
                    width = f32(tile_width),
                    height = f32(tile_height),
                }

                rl.DrawTexturePro(texture, src_rect, dst_rect, rl.Vector2{0, 0}, 0, rl.WHITE)
            }
        }
    }
}

check_map_collision_tile :: proc(col:rl.Rectangle,tiled_map:tiled.Map,tile_size:i32=32) -> bool {
    for layer in tiled_map.layers {
        //todo is this how we should do it
        if layer.type == .tilelayer && layer.name == "col" {
            for y in 0..<layer.height {
                for x in 0..<layer.width {
                    gid := layer.data[y * layer.width + x]
                    if gid == 0 {
                        continue
                    }
                    rect := rl.Rectangle{
                        x = f32(x*tile_size),
                        y = f32(y*tile_size),
                        width = f32(tile_size),
                        height = f32(tile_size),
                    }
                    if rl.CheckCollisionRecs(col, rect) {
                        return true
                    }
                }
            }
        }
    }
    return false
}
