package game
import rl "vendor:raylib"
import tiled "../libs/odin-tiled/tiled"
import "core:log"
import "core:mem"

MAX_ENTITYS :: 50

Level :: struct {
    world_offset:rl.Vector2,
    tile_map:tiled.Map,
    tile_size:rl.Vector2,
    tileset:rl.Texture2D,
    entity_textures:[dynamic]rl.Texture,
    entitys: [MAX_ENTITYS]Entity,
    //should these be dynamics
    enemys: [dynamic]i8, //index for enemeys
    pickups:  [dynamic]i8, //index for items
    lvl_arena_ptr:^mem.Dynamic_Arena,
}

setup_level_1 :: proc(arena:^mem.Dynamic_Arena,world_offset:rl.Vector2) -> Level {
    arena_alocator := mem.dynamic_arena_allocator(arena)
    mem.free_all(arena_alocator)
    tiled_map := tiled.parse_tilemap("assets/level1.tmj",arena_alocator)
    l1 := Level {
        tile_map=tiled_map,
        tile_size={32,32},
        world_offset=world_offset,
        tileset=rl.LoadTexture("assets/moderninteriors-win/1_Interiors/32x32/Room_Builder_32x32.png"),
        lvl_arena_ptr=arena,
        //todo spawn entitys
    }
    l1.entity_textures = make([dynamic]rl.Texture2D,arena_alocator)
    append(&l1.entity_textures, rl.LoadTexture("assets/round_cat.png"))

    l1.entitys[0] = Entity{
        pos= rl.Vector2{40,40}+l1.world_offset,
        size ={0,0,20,24},
        type = .Enemy,
        texture_index=0,
    }
    l1.entitys[1] = Entity{
        pos= rl.Vector2{90,90}+l1.world_offset,
        size ={0,0,20,24},
        type = .Pickup,
        texture_index=0,
    }
    l1.enemys=make([dynamic]i8,arena_alocator)
    append(&l1.enemys,0);
    return l1
}

unload_level :: proc(lvl:^Level) {
    arena_alocator := mem.dynamic_arena_allocator(lvl.lvl_arena_ptr)
    for i:=0;i<len(lvl.entity_textures);i+=1 {
        rl.UnloadTexture(lvl.entity_textures[i])
    }
    rl.UnloadTexture(lvl.tileset)
    mem.free_all(arena_alocator)
}

render_level_entitys :: proc(level:Level) {
    for i:=0;i<len(level.entitys);i+=1 {
        entity := level.entitys[i]
        if entity.type == nil {
            continue
        }
        render_entity(entity)
    }
}

render_level_tilemap :: proc(level: Level) {
    t_map := level.tile_map
    texture := level.tileset
    width := level.tile_size.x
    height := level.tile_size.y
    for layer in t_map.layers {
        for y in 0..<layer.height {
            for x in 0..<layer.width {
                gid := layer.data[y * layer.width + x]
                if gid == 0 {
                    continue
                }
                tile_x := i32(gid - 1) % (texture.width /  i32(level.tile_size.x))
                tile_y := i32(gid - 1) / (texture.height / i32(level.tile_size.y))

                src_rect := rl.Rectangle{
                    x = level.world_offset.x + f32(tile_x * i32(level.tile_size.x)),
                    y = level.world_offset.y + f32(tile_y * i32(level.tile_size.y)),
                    width = f32(level.tile_size.x),
                    height = f32(level.tile_size.y),
                }

                dst_rect := rl.Rectangle{
                    x = f32(x) * level.tile_size.x,
                    y = f32(y) * level.tile_size.y,
                    width  = level.tile_size.x,
                    height = level.tile_size.y,

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
