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
    show_path: bool,
    show_bbox: bool,

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

dbg_input :: proc() {
    if gs.dbg_enemy != nil {
        if rl.IsKeyPressed(.KP_0) do gs.dbg.show_bbox = !gs.dbg.show_bbox
        if rl.IsKeyPressed(.KP_1) do gs.dbg.show_path = !gs.dbg.show_path
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

dbg_draw_enemy :: proc() {
    if gs.dbg_enemy == nil do return

    y_pos := rl.GetScreenHeight() - 400
    rl.DrawText(fmt.ctprintf("enemy"), 10, y_pos, 20, rl.ORANGE)
    rl.DrawText(fmt.ctprintf("0: bbox"), 10, y_pos + 25, 20, gs.dbg.show_bbox ? rl.DARKBLUE : rl.GRAY)
    rl.DrawText(fmt.ctprintf("1: path"), 95, y_pos + 25, 20, gs.dbg.show_path ? rl.DARKBLUE : rl.GRAY)
    rl.DrawText(fmt.ctprintf("pos: %.2f", gs.dbg_enemy.pos), 10, y_pos + 50, 20, rl.WHITE)
    rl.DrawText(fmt.ctprintf("anim: %v", gs.dbg_enemy.anim.cur_anim), 10, y_pos + 75, 20, rl.WHITE)
    rl.DrawText(fmt.ctprintf("hp: %d", gs.dbg_enemy.hp), 10, y_pos + 100, 20, rl.WHITE)
    rl.DrawText(fmt.ctprintf("ammo: %d", gs.dbg_enemy.ammo), 10, y_pos + 125, 20, rl.WHITE)
    rl.DrawText(fmt.ctprintf("dist: %.2f", gs.dbg_enemy.dist), 10, y_pos + 150, 20, rl.WHITE)
    rl.DrawText(fmt.ctprintf("dest: %.2f", gs.dbg_enemy.dest), 10, y_pos + 175, 20, rl.WHITE)
    cur_goal := gs.dbg_enemy.cur_goal.? or_else {}
    rl.DrawText(fmt.ctprintf("cur goal: %v", cur_goal.name), 10, y_pos + 200, 20, rl.WHITE)
    rl.DrawText(fmt.ctprintf("goals:"), 10, y_pos + 225, 20, rl.WHITE)
    for goal, i in gs.dbg_enemy.goals {
        rl.DrawText(fmt.ctprintf("  %v", goal.name), 10, y_pos + 250 + i32(i)*25, 20, rl.WHITE)
    }

    if gs.dbg.show_path do dbg_draw_bfs(gs.dbg_enemy.nav_data)
}

dbg_draw_bfs :: proc(nav_data: Nav_Data) {
    SIZE :: 18 // TODO: derive from screen size

    pos := Vec2i{(rl.GetScreenWidth() - gs.level.grid_tex.width * SIZE) / 2, 50}

    rc := rl.Rectangle {
        x = f32(nav_data.start.x * SIZE + pos.x),
        y = f32(nav_data.start.y * SIZE + pos.y),
        width = SIZE,
        height = SIZE,
    }
    rl.DrawRectangleRec(rc, {0, 255, 0, 128})
    rc = rl.Rectangle {
        x = f32(nav_data.end.x * SIZE + pos.x),
        y = f32(nav_data.end.y * SIZE + pos.y),
        width = SIZE,
        height = SIZE,
    }
    rl.DrawRectangleRec(rc, {255, 0, 0, 128})

    for y in 0..<gs.level.grid_tex.height {
        for x in 0..<gs.level.grid_tex.width {
            rc = rl.Rectangle {
                x = f32(x * SIZE + pos.x),
                y = f32(y * SIZE + pos.y),
                width = SIZE,
                height = SIZE,
            }
            if gs.level.grid[x + y * gs.level.grid_tex.width].r == 255 {
                rl.DrawRectangleRec(rc, {255, 255, 255, 128})
            }
            rl.DrawRectangleLinesEx(rc, 1, {0, 0, 255, 60})
        }
    }

    for edge in nav_data.edges {
        e0 := edge[0] * SIZE + SIZE/2 + pos
        e1 := edge[1] * SIZE + SIZE/2 + pos
        rl.DrawLine(e0.x, e0.y, e1.x, e1.y, {255, 0, 255, 128})
    }
    if len(nav_data.path) >= 2 {
        for _, i in nav_data.path[1:] { // TODO: indexing is weird
            e0 := nav_data.path[i] * SIZE + SIZE/2 + pos
            e1 := nav_data.path[i+1] * SIZE + SIZE/2 + pos
            rl.DrawLine(e0.x, e0.y, e1.x, e1.y, {0, 255, 0, 128})
        }
    }
}

dbg_draw_grid :: proc() {
    for y in 0..=gs.level.grid_tex.height {
        for x in 0..=gs.level.grid_tex.width {
            box := rl.BoundingBox {
                min = {f32(x), 0, f32(y)},
                max = {f32(x+1), 1, f32(y+1)},
            }
            rl.DrawBoundingBox(box, {0, 0, 255, 128})
        }
    }
}
