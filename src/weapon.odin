package game

import rl "vendor:raylib"

Weapon_Type :: enum {
    Pistol,
    Rifle,
    Machine_Gun,
//    Nuker,
}

Weapon :: struct {
    tex: [3]rl.Texture2D,
    x_off: i32,

    damage: int,

    anim: bool,
    anim_frame: int,
    anim_time: f32,
}

Weapons :: [Weapon_Type]Weapon

draw_weapon :: proc() {
    SCALE :: 4

    center := Vec2{f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight())}
    weapon := &gs.weapons[gs.cur_weapon]

    tex := weapon.tex[weapon.anim_frame]
    off := f32(weapon.x_off * SCALE)
    pos := Vec2{center.x - f32(tex.width/2)*SCALE + off, center.y - f32(tex.height)*SCALE}

    rl.DrawTextureEx(tex, pos, 0, SCALE, rl.WHITE)
}

update_weapon :: proc(dt: f32) {
    weapon := &gs.weapons[gs.cur_weapon]
    if !weapon.anim do return

    weapon.anim_time -= dt
    if weapon.anim_time <= 0 {
        weapon.anim_frame += 1
        weapon.anim_time = 0.05

        if weapon.anim_frame >= len(weapon.tex) {
            weapon.anim_frame = 0
            weapon.anim = false
        }
    }
}

play_weapon_anim :: proc() {
    weapon := &gs.weapons[gs.cur_weapon]
    weapon.anim = true
    weapon.anim_time = 0.05
}
