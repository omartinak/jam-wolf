package game

import rl "vendor:raylib"

Item_Type :: enum {
    Pistol,
    Rifle,
    Machine_Gun,

    Clip,
    Ammo_Box,
    Armor,
    Health,

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
        pos = pos,
        col_radius = cfg.col_radius,
        half_height = cfg.half_height,
        type = cfg.type,
    }
    // TODO: map Item_Type -> Tex?

    // TOD: put textures type in the config
    switch item.type {
    case .Pistol:      item.tex = gs.textures[.Pistol]
    case .Rifle:       item.tex = gs.textures[.Rifle]
    case .Machine_Gun: item.tex = gs.textures[.Machine_Gun]
    case .Clip:        item.tex = gs.textures[.Clip]
    case .Ammo_Box:    item.tex = gs.textures[.Ammo_Box]
    case .Armor:       item.tex = gs.textures[.Armor]
    case .Health:      item.tex = gs.textures[.Health]
    case .Exit:        item.tex = gs.textures[.Brain]
    }
    return item
}

update_item :: proc(item: Item) -> bool {
    if rl.Vector3Distance(gs.player.pos, item.pos) < (item.col_radius + gs.player.col_radius) {
        switch item.type {
        case .Pistol:
            gs.weapons[.Pistol].owned = true
            show_message("You got pistol!")

        case .Rifle:
            gs.weapons[.Rifle].owned = true
            if gs.cur_weapon == .Pistol do change_weapon(.Rifle)
            show_message("You got rifle!")

        case .Machine_Gun:
            gs.weapons[.Machine_Gun].owned = true
            if gs.cur_weapon == .Pistol || gs.cur_weapon == .Rifle do change_weapon(.Machine_Gun)
            show_message("You got machine gun!")

        case .Clip:
            gs.ammo += 1
            show_message("+1 ammo")

        case .Ammo_Box:
            gs.ammo += 5
            show_message("+5 ammo")

        case .Armor:
            gs.player.armor = 100
            show_message("Full armor")

        case .Health:
            gs.player.hp += 10
            show_message("+10 health")

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
