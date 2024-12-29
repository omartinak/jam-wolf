package game

import rl "vendor:raylib"

Item_Type :: enum {
    Clip,
    Ammo_Box,
    Armor,
}

Item :: struct {
    tex: rl.Texture2D, // TODO: shouldn't be store here or in the level file, take from enum array
    pos: Vec3,

    type: Item_Type,
}

Items :: [dynamic]Item

draw_item :: proc(item: Item, opacity: u8 = 255) {
    rl.DrawBillboard(gs.camera, item.tex, item.pos, 0.25, {255, 255, 255, opacity})
}
