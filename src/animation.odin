package game

import rl "vendor:raylib"

Anim_Cfg :: struct($Enum: typeid) {
    tex: []Tex,
    time: f32,
    transition: Maybe(Enum),
}

Anim_Frames :: struct($Enum: typeid) {
    tex: [dynamic]rl.Texture2D,
    time: f32,
    transition: Maybe(Enum),
}

Anim :: struct($Enum: typeid) {
    frames: [Enum]Anim_Frames(Enum),

    playing: bool,
    cur_anim: Enum,
    cur_frame: int,
    cur_time: f32,
}

create_anim :: proc(cfg: [$Enum]Anim_Cfg(Enum)) -> Anim(Enum) {
    anim: Anim(Enum)
    add_anim(&anim, cfg)
    return anim
}

add_anim :: proc(anim: ^Anim($Enum), cfg: [Enum]Anim_Cfg(Enum)) {
    for anim_cfg, anim_type in cfg {
        anim.frames[anim_type].time = anim_cfg.time
        anim.frames[anim_type].transition = anim_cfg.transition

        for tex in anim_cfg.tex {
            append(&anim.frames[anim_type].tex, gs.textures[tex])
        }
    }
}

destroy_anim :: proc(anim: Anim($Enum)) {
    for frames in anim.frames {
        delete(frames.tex)
    }
}

get_anim_frame :: proc(anim: Anim($Enum)) -> rl.Texture2D {
    // TODO: assert? bounds check?
    if len(anim.frames) == 0 || len(anim.frames[anim.cur_anim].tex) == 0 do return {}
    return anim.frames[anim.cur_anim].tex[anim.cur_frame]
}

update_anim :: proc(anim: ^Anim($Enum), dt: f32) {
    // TODO: bounds
    if !anim.playing do return

    anim.cur_time -= dt
    if anim.cur_time <= 0 {
        anim.cur_frame += 1
        anim.cur_time = anim.frames[anim.cur_anim].time

        if anim.cur_frame >= len(anim.frames[anim.cur_anim].tex) {
            if next, ok := anim.frames[anim.cur_anim].transition.?; ok {
                play_anim(anim, next)
            } else {
                anim.cur_frame -= 1
                anim.playing = false
            }
        }
    }
}

play_anim :: proc(anim: ^Anim($Enum), anim_type: Enum) {
//    if anim.cur_anim == anim_type do return // TODO

    anim.cur_anim = anim_type
    anim.cur_time = anim.frames[anim.cur_anim].time
    anim.cur_frame = 0
    anim.playing = true
}
