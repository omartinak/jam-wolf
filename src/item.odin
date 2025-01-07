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

Item_Cfg :: struct {
    y_off: f32,
    type: Item_Type, // TODO: replace
}

Items :: [dynamic]Item

create_item :: proc(cfg: Item_Cfg, pos: Vec3) -> Item {
    item := Item {
        pos = pos + {0, cfg.y_off, 0},
        type = cfg.type,
    }
    // TODO: map Item_Type -> Tex?
    switch cfg.type {
    case .Clip:     item.tex = gs.textures[.Clip]
    case .Ammo_Box: item.tex = gs.textures[.Ammo_Box]
    case .Armor:    item.tex = gs.textures[.Armor]
    }
    return item
}

draw_item :: proc(item: Item, opacity: u8 = 255) {
    rl.DrawBillboard(gs.camera, item.tex, item.pos, 0.25, {255, 255, 255, opacity})
}
