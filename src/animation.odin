package game

import rl "vendor:raylib"

AnimFrames :: struct {
    tex: [dynamic]rl.Texture2D,
    time: f32,
}

Anim :: struct($Enum: typeid) {
    frames: [Enum]AnimFrames, // TODO: parapoly enum array

    playing: bool,
    cur_anim: Enum,
    cur_frame: int,
    cur_time: f32,
}

//create_anim :: proc(frame_time: f32, frames: ..rl.Texture2D) -> Anim {
//    anim := Anim {
//        frame_time = frame_time,
//    }
//    append(&anim.frames, ..frames) // TODO: reserve?
//    return anim
//}

add_anim :: proc(anim: ^Anim($Enum), anim_type: Enum, frame_time: f32, frames: ..rl.Texture2D) {
    anim.frames[anim_type].time = frame_time
    append(&anim.frames[anim_type].tex, ..frames)
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
            anim.cur_frame = 0
            anim.playing = false
        }
    }
}

play_anim :: proc(anim: ^Anim($Enum), anim_type: Enum) {
    anim.cur_anim = anim_type
    anim.cur_time = anim.frames[anim.cur_anim].time
    anim.cur_frame = 0
    anim.playing = true
}
