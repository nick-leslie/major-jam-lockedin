package game
import rl "vendor:raylib"
//todo this is temp to fill out for the levels
// we may want to swap this
Entity :: struct {
    using pos:rl.Vector2,
    vel: rl.Vector2,
    size:rl.Rectangle,
    accel:f32,
    damp:f32,
    max_speed:f32,
    texture_index:i32, // what size should this be
    frame:i32, //for animation
    type: enum {
        Player,
        Enemy,
        Pickup, // todo do we want this here
    },
    holding:Maybe(i8),
    health:i8, // should this be here
}

render_entity :: proc(entity: Entity) {
    rl.DrawTexturePro(
        g.level.entity_textures[entity.texture_index],
        entity.size,
        rl.Rectangle{entity.x,entity.y,entity.size.width,entity.size.height},
        {0,0}, // should this be the level offset
        0,
        rl.WHITE
    );
}
