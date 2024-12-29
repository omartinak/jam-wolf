package game

import rl "vendor:raylib"

Weapon_Type :: enum {
    Pistol,
    Rifle,
    Machine_Gun,
    Nuker,
}

Weapon :: struct {
    tex: rl.Texture2D,
    x_off: i32,

    damage: int,
}

Weapons :: [Weapon_Type]Weapon

draw_weapon :: proc() {
    SCALE :: 4

    center := Vec2{f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight())}

    tex := gs.weapons[gs.cur_weapon].tex
    off := f32(gs.weapons[gs.cur_weapon].x_off * SCALE)
    pos := Vec2{center.x - f32(tex.width/2)*SCALE + off, center.y - f32(tex.height)*SCALE}

    rl.DrawTextureEx(tex, pos, 0, SCALE, rl.WHITE)
}
