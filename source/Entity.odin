package game
import rl "vendor:raylib"
//todo this is temp to fill out for the levels
// we may want to swap this 
Entity :: struct {
    using pos:rl.Vector2,
    box:rl.Rectangle,
    type: enum {
        Enemy,
        Pickup, // todo do we want this here
    },
    texture:rl.Texture
}
