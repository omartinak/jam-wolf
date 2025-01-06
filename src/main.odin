package game

import "core:mem"
import "core:fmt"
import "core:slice"
import rl "vendor:raylib"

_ :: mem
_ :: fmt

main :: proc() {
    when ODIN_DEBUG {
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
                for _, entry in track.allocation_map {
                    fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
                }
            }
            if len(track.bad_free_array) > 0 {
                fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
                for entry in track.bad_free_array {
                    fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
                }
            }
            mem.tracking_allocator_destroy(&track)
        }
    }

    rl.InitWindow(1920, 1200, "jam-wolf")
//    rl.InitWindow(1280, 800, "jam-wolf")
    rl.InitAudioDevice()
    rl.DisableCursor()
//    rl.SetWindowState({.VSYNC_HINT, .WINDOW_RESIZABLE})
    rl.SetWindowState({.WINDOW_RESIZABLE})

    init()

    for !rl.WindowShouldClose() {
        update()
        draw()

        free_all(context.temp_allocator)
    }

    destroy()
    rl.CloseAudioDevice()
    rl.CloseWindow()
}

init :: proc() {
    gs = Game_State {
        textures = create_textures(),

        camera = {
//            position = {0, 0.5, 0},
//            target = {0, 0.5, -1.0},
            up = {0, 1, 0},
            fovy = 45, // TODO
            projection = .PERSPECTIVE,
        },
        player = {
//            pos = {0, 0.5, 0},
//            pos = {13.5, 0.5, 43},
            col_radius = 0.1,
            hp = 100,
            armor = 0,
        },
        ammo = 50,
    }
    gss = &gs

//    gs.level, gs.level_runtime = init_level()
    gs.level, gs.level_runtime = load_level("data/levels/level01a.json")

    gs.weapons[.Pistol] = create_weapon(pistol_cfg)
    gs.weapons[.Rifle] = create_weapon(rifle_cfg)
    gs.weapons[.Machine_Gun] = create_weapon(machinegun_cfg)

    gs.player.pos = gs.level.player_start
    gs.player.pos.z += 0.01 // TODO: fixes visible seams between tiles - wtf?
    // TODO
    gs.camera.position = gs.player.pos
    gs.camera.target = gs.camera.position + {1, 0, 0}

    gs.editor = init_editor()
}

destroy :: proc() {
    for weapon in gs.weapons {
        destroy_weapon(weapon)
    }
    destroy_level(gs.level, gs.level_runtime)
    destroy_textures(gs.textures)
}

update :: proc() {
    update_start := rl.GetTime()
    dt := rl.GetFrameTime()

    if rl.IsKeyPressed(.F2) do gs.editor.active = !gs.editor.active
    if rl.IsKeyPressed(.APOSTROPHE) || rl.IsKeyPressed(.Q) {
        ray := rl.Ray {
            position = gs.camera.position,
            direction = rl.Vector3Normalize(gs.camera.target - gs.camera.position),
        }
        enemy_hit := get_enemy_hit(ray, check_dead = true)

        if enemy_hit.enemy == gs.dbg_enemy do gs.dbg_enemy = nil
        else do gs.dbg_enemy = enemy_hit.enemy
    }
    if rl.IsKeyPressed(.F9) {
        switch gs.dbg.ui_state {
        case .None: gs.dbg.ui_state = .Small
        case .Small: gs.dbg.ui_state = .Full
        case .Full: gs.dbg.ui_state = .None
        }
    }
    if gs.dbg_enemy != nil && rl.IsKeyPressed(.KP_0) do gs.dbg.show_path = !gs.dbg.show_path

    if gs.editor.active {
        update_editor_input(&gs.editor)
    } else {
        switch gs.cur_weapon {
        case .Pistol:
            if rl.IsMouseButtonPressed(.LEFT) && can_weapon_shoot() {
                player_shoot()
            }
        case .Rifle: fallthrough
        case .Machine_Gun:
            if rl.IsMouseButtonDown(.LEFT) && can_weapon_shoot() {
                player_shoot()
            }
        }
        // TODO: mouse wheel to switch weapons

        switch {
        case rl.IsKeyPressed(.ONE):   gs.cur_weapon = .Pistol
        case rl.IsKeyPressed(.TWO):   gs.cur_weapon = .Rifle
        case rl.IsKeyPressed(.THREE): gs.cur_weapon = .Machine_Gun
//        case rl.IsKeyPressed(.FOUR):  gs.cur_weapon = .Nuker
        }
    }

    update_weapon(dt)

    player_move(&gs.player, &gs.camera, dt)
//    dbg_print(0, "player %.2f", gs.player.pos.xz)

    for &enemy in gs.level.enemies do update_enemy(&enemy, dt)

    update_editor(&gs.editor)

    if !gs.editor.active {
        for item, i in gs.level.items {
            if rl.Vector3Distance(gs.player.pos, item.pos) < 0.5 {
                switch item.type {
                case .Clip:
                    gs.ammo += 1
                    show_message("+1 ammo")

                case .Ammo_Box:
                    gs.ammo += 5
                    show_message("+5 ammo")

                case .Armor:
                    gs.player.armor = 100
                    show_message("full armor")
                }
                unordered_remove(&gs.level.items, i)
            }
        }
    }

    if gs.message_time > 0 do gs.message_time -= dt

    gs.dbg.update_time = rl.GetTime() - update_start
}

draw :: proc() {
    draw_start := rl.GetTime()

    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    rl.BeginMode3D(gs.camera)

    draw_level(gs.level_runtime)

    // TODO: sort items and enemies together
    slice.sort_by(gs.level.items[:], proc(a, b: Item) -> bool {
        a_dist := rl.Vector3DistanceSqrt(gs.camera.position, a.pos)
        b_dist := rl.Vector3DistanceSqrt(gs.camera.position, b.pos)
        return a_dist > b_dist
    })
    for item in gs.level.items do draw_item(item)

    slice.sort_by(gs.level.enemies[:], proc(a, b: Enemy) -> bool {
        a_dist := rl.Vector3DistanceSqrt(gs.camera.position, a.pos)
        b_dist := rl.Vector3DistanceSqrt(gs.camera.position, b.pos)
        return a_dist > b_dist
    })
    for enemy in gs.level.enemies do draw_enemy(enemy)
    if gs.dbg_enemy != nil {
        rl.DrawSphere(gs.dbg_enemy.pos + {0, 0.5, 0}, 0.05, rl.VIOLET)
    }

    draw_editor(gs.editor)

    // Debug grid
    //    for y in 0..=57 {
    //        for x in 0..=62 {
    //            box := rl.BoundingBox {
    //                min = {f32(x), 0, f32(y)},
    //                max = {f32(x+1), 1, f32(y+1)},
    //            }
    //            rl.DrawBoundingBox(box, {0, 0, 255, 128})
    //        }
    //    }

    player := &gs.player
    x := i32(player.pos.x)
    y := i32(player.pos.z)
    dbg_print(0, "player %.2f", player.pos)
    dbg_print(1, "pl tile %d, %d", x, y)

    //    rl.DrawCubeWiresV({f32(x+2), 0, f32(y)} + gs.level.pos, {1, 1, 1}, rl.BLUE)
    //    rl.DrawCubeWiresV({f32(x), 0, f32(y)}, {2, 2, 2}, rl.BLUE)

    rl.EndMode3D()

    draw_minimap()
    draw_crosshair()
    if !gs.editor.active {
        draw_weapon()
        draw_hud()
    }
    draw_editor_hud(gs.editor)
    if gs.dbg_enemy != nil {
        dbg_draw_enemy()
    }

    if gs.message_time > 0 {
    //        w := rl.MeasureTextEx({}, gs.message, 20, 2)
        w := rl.MeasureText(gs.message, 20)
        rl.DrawTextEx({}, gs.message, {f32(rl.GetScreenWidth() - w)/2, 0}, 20, 2, rl.RAYWHITE)
    }

    gs.dbg.draw_time = rl.GetTime() - draw_start // Debug UI and frame present is not included

//    rl.DrawFPS(10, 10)
    dbg_draw_ui()
    dbg_draw_messages()

    rl.EndDrawing()
}
