package game

import "core:fmt"
import rl "vendor:raylib"

Debug_UI_State :: enum {
    None = 1,
    Small = 0, // Default
    Full = 2,
}

Debug_Data :: struct {
    messages: [10]cstring,

    ui_state: Debug_UI_State,
    update_time: f64,
    draw_time: f64,
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

dbg_draw_ui :: proc() {
    screen_width := rl.GetScreenWidth()
    working_set, private_usage: int // TODO

    switch gs.dbg.ui_state {
    case .None:
    case .Small:
        mem_text := fmt.ctprintf("memory: %d MB, %d MB", working_set, private_usage)
        width := 120 + rl.MeasureText(mem_text, 20)
        pos := (screen_width - width) / 2

        rl.DrawRectangle(pos - 20, 0, width + 40, 25, {0, 0, 0, 100})
        rl.DrawFPS(pos, 0)
        rl.DrawText(mem_text, pos + 120, 0, 20, rl.WHITE)

    case .Full:
        pos := screen_width - 250

        rl.DrawRectangle(pos - 20, 0, screen_width - pos + 20, 190, {0, 0, 0, 100})
        rl.DrawFPS(pos, 0)
        rl.DrawText(fmt.ctprintf("frame: %.2f ms", rl.GetFrameTime() * 1_000), pos, 25, 20, rl.WHITE)
        rl.DrawText(fmt.ctprintf("  update: %.2f ms", gs.dbg.update_time * 1_000), pos, 50, 20, rl.WHITE)
        rl.DrawText(fmt.ctprintf("  draw: %.2f ms", gs.dbg.draw_time * 1_000), pos, 75, 20, rl.WHITE)
        rl.DrawText(fmt.ctprintf("memory: %d MB, %d MB", working_set, private_usage), pos, 100, 20, rl.WHITE)
        rl.DrawText(fmt.ctprintf("actors: %d", len(gs.level.enemies) + len(gs.level.items)), pos, 125, 20, rl.WHITE)
        rl.DrawText(fmt.ctprintf("  enemies: %d", len(gs.level.enemies)), pos, 150, 20, rl.WHITE)
    }
}
