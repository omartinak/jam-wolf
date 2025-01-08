package game

import rl "vendor:raylib"

Hit_Splash_Anim :: enum {
    Splash,
}

Hit_Splash :: struct {
    pos: Vec3,
    anim: Anim(Hit_Splash_Anim),
    color: rl.Color,
}

Hit_Splash_Cfg :: struct {
    anim: [Hit_Splash_Anim]Anim_Cfg(Hit_Splash_Anim),
    color: rl.Color,
}

create_hit_splash :: proc(cfg: Hit_Splash_Cfg, pos: Vec3) -> Hit_Splash {
    hit_splash := Hit_Splash {
        pos = pos,
        anim = create_anim(cfg.anim),
        color = cfg.color,
    }
    play_anim(&hit_splash.anim, Hit_Splash_Anim.Splash)
    return hit_splash
}

destroy_hit_splash :: proc(hit_splash: Hit_Splash) {
    destroy_anim(hit_splash.anim)
}

draw_hit_splash :: proc(hit_splash: Hit_Splash, opacity: u8 = 255) {
    frame := get_anim_frame(hit_splash.anim)
    color := hit_splash.color
    color.a = opacity
    rl.DrawBillboard(gs.camera, frame, hit_splash.pos, 0.25, color)
}

update_hit_splash :: proc(hit_splash: ^Hit_Splash, dt: f32) {
    update_anim(&hit_splash.anim, dt)
}
