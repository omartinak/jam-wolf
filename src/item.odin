package game

import rl "vendor:raylib"

Item_Type :: enum {
    Clip,
    Ammo_Box,
    Armor,
    Exit,
}

Item :: struct {
    tex: rl.Texture2D, // TODO: shouldn't be store here or in the level file, take from enum array
    pos: Vec3,

    col_radius: f32,
    half_height: f32,
    type: Item_Type,
}

Item_Cfg :: struct {
    col_radius: f32,
    half_height: f32,
    y_off: f32,
    type: Item_Type, // TODO: replace
}

Items :: [dynamic]Item

create_item :: proc(cfg: Item_Cfg, pos: Vec3) -> Item {
    item := Item {
        pos = pos + {0, cfg.y_off, 0},
        col_radius = cfg.col_radius,
        half_height = cfg.half_height,
        type = cfg.type,
    }
    // TODO: map Item_Type -> Tex?
    switch cfg.type {
    case .Clip:     item.tex = gs.textures[.Clip]
    case .Ammo_Box: item.tex = gs.textures[.Ammo_Box]
    case .Armor:    item.tex = gs.textures[.Armor]
    case .Exit:     item.tex = gs.textures[.Brain]
    }
    return item
}

update_item :: proc(item: Item) -> bool {
    if rl.Vector3Distance(gs.player.pos, item.pos) < (item.col_radius + gs.player.col_radius) {
        switch item.type {
        case .Clip:
            gs.ammo += 1
            show_message("+1 ammo")

        case .Ammo_Box:
            gs.ammo += 5
            show_message("+5 ammo")

        case .Armor:
            gs.player.armor = 100
            show_message("full armor")

        case .Exit:
            show_message("Congratulations! Restarting level...")
            gs.should_restart = true
            return false
        }
        return true
    }
    return false
}

draw_item :: proc(item: Item, opacity: u8 = 255) {
    rl.DrawBillboard(gs.camera, item.tex, item.pos, 0.25, {255, 255, 255, opacity})

    if gs.dbg.show_bbox {
        bodyPos := item.pos
        body := rl.BoundingBox {
            min = bodyPos - {item.col_radius, item.half_height, item.col_radius},
            max = bodyPos + {item.col_radius, item.half_height, item.col_radius},
        }
        rl.DrawBoundingBox(body, rl.MAROON)
    }
}
