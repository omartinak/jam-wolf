package game

import rl "vendor:raylib"

Weapon_Type :: enum {
    Pistol,
    Rifle,
    Machine_Gun,
}

Weapon_Anim :: enum {
    Idle,
    Fire,
}

Weapon :: struct {
    anim: Anim(Weapon_Anim),
    x_off: i32,
    damage: int,
    owned: bool,
}

Weapon_Cfg :: struct {
    anim: [Weapon_Anim]Anim_Cfg(Weapon_Anim),
    x_off: i32,
    damage: int,
    owned: bool,
}

Weapons :: [Weapon_Type]Weapon

create_weapon :: proc(cfg: Weapon_Cfg) -> Weapon {
    weapon := Weapon {
        anim = create_anim(cfg.anim),
        x_off = cfg.x_off,
        damage = cfg.damage,
        owned = cfg.owned,
    }
    return weapon
}

destroy_weapon :: proc(weapon: Weapon) {
    destroy_anim(weapon.anim)
}

draw_weapon :: proc() {
    SCALE :: 4

    center := Vec2{f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight())}
    weapon := &gs.weapons[gs.cur_weapon]

    tex := get_anim_frame(weapon.anim)
    off := f32(weapon.x_off * SCALE)
    pos := Vec2{center.x - f32(tex.width/2)*SCALE + off, center.y - f32(tex.height)*SCALE}

    rl.DrawTextureEx(tex, pos, 0, SCALE, rl.WHITE)
}

update_weapon :: proc(dt: f32) {
    weapon := &gs.weapons[gs.cur_weapon]
    update_anim(&weapon.anim, dt)
}

can_weapon_shoot :: proc() -> bool {
    weapon := &gs.weapons[gs.cur_weapon]
    return weapon.anim.cur_anim == .Idle
}

play_weapon_anim :: proc() {
    weapon := &gs.weapons[gs.cur_weapon]
    play_anim(&weapon.anim, Weapon_Anim.Fire)
}

change_weapon :: proc(weapon_type: Weapon_Type) {
    if gs.weapons[weapon_type].owned {
        gs.cur_weapon = weapon_type
    }
}

