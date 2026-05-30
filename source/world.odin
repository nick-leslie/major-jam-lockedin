package game
import rl "vendor:raylib"
import tiled "../libs/odin-tiled/tiled"
import "core:log"
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

check_map_collision_tile :: proc(col:rl.Rectangle,tiled_map:tiled.Map) -> bool {
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
                        x = f32(x*32),
                        y = f32(y*32),
                        width = f32(32),
                        height = f32(32),
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
