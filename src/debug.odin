package game

import "core:fmt"
import rl "vendor:raylib"

Debug_Data :: struct {
    messages: [10]cstring,
}

dbg_print :: proc(index: int, format: string, args: ..any) {
    // TODO: check index
    // TODO: touching gamestate
    gs.dbg.messages[index] = fmt.ctprintf(format, ..args)
}

dbg_draw_messages :: proc() {
    for cstr, i in gs.dbg.messages {
        rl.DrawTextEx({}, cstr, {10, f32(300 + i*20)}, 20, 2, rl.RAYWHITE)
    }
}
