package game

import "core:slice"
import rl "vendor:raylib"

draw :: proc() {
    draw_start := rl.GetTime()

    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    rl.BeginMode3D(gs.camera)

    draw_level(gs.level)

    sort_and_draw_billboards()

    draw_editor(gs.editor)
    if gs.dbg_enemy != nil {
        rl.DrawSphere(gs.dbg_enemy.pos + {0, 0.5, 0}, 0.05, rl.VIOLET)
    }

    // Debug draw
    player := &gs.player
    x := i32(player.pos.x)
    y := i32(player.pos.z)
    dbg_print(0, "player %.2f", player.pos)
    dbg_print(1, "pl tile %d, %d", x, y)

    rl.EndMode3D()

    draw_minimap()
    draw_crosshair()

    if !gs.editor.active {
        if !gs.player.dead {
            draw_weapon()
            draw_hud()
        } else {
            draw_dead()
        }

        if gs.dbg_enemy != nil {
            dbg_draw_enemy()
        }
    }
    draw_editor_hud(gs.editor)

    if gs.message_time > 0 {
        FONT_SIZE :: 40
        w := rl.MeasureText(gs.message, FONT_SIZE)
        rl.DrawText(gs.message, (rl.GetScreenWidth() - w) / 2, 40, FONT_SIZE, rl.GOLD)
    }

    gs.dbg.draw_time = rl.GetTime() - draw_start // Debug UI and frame present is not included

    dbg_draw_ui()
    dbg_draw_messages()

    rl.EndDrawing()
}

sort_and_draw_billboards :: proc() {
    Billboard :: struct {
        dist: f32,
        actor: union{^Item, ^Enemy},
        opacity: u8,
    }

    num := len(gs.level.items) + len(gs.level.enemies)
    if gs.editor.active do num += 1

    billboards := make([]Billboard, num, context.temp_allocator)

    for &item, i in gs.level.items {
        billboards[i] = Billboard {
            dist = rl.Vector3DistanceSqrt(gs.camera.position, item.pos),
            actor = &item,
            opacity = 255,
        }
    }
    for &enemy, i in gs.level.enemies {
        billboards[len(gs.level.items)+i] = Billboard {
            dist = rl.Vector3DistanceSqrt(gs.camera.position, enemy.pos),
            actor = &enemy,
            opacity = 255,
        }
    }
    if gs.editor.active {
        switch &s in gs.editor.sel {
        case Item: billboards[num-1] = Billboard {rl.Vector3DistanceSqrt(gs.camera.position, s.pos), &s, 128}
        case Enemy: billboards[num-1] = Billboard {rl.Vector3DistanceSqrt(gs.camera.position, s.pos), &s, 128}
        }
    }

    slice.sort_by(billboards[:], proc(a, b: Billboard) -> bool {
        return a.dist > b.dist
    })

    for billboard in billboards {
        switch a in billboard.actor {
        case ^Item: draw_item(a^, billboard.opacity)
        case ^Enemy: draw_enemy(a^, billboard.opacity)
        }
    }
}

