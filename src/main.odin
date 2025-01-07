package game

import "base:runtime"
import "core:mem"
import "core:fmt"
import "core:slice"
import "core:prof/spall"
import "core:sync"
import rl "vendor:raylib"

_ :: mem
_ :: fmt
_ :: runtime

spall_ctx: spall.Context
@(thread_local) spall_buffer: spall.Buffer

//@(instrumentation_enter)
//spall_enter :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
//    spall._buffer_begin(&spall_ctx, &spall_buffer, "", "", loc)
//}
//
//@(instrumentation_exit)
//spall_exit :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
//    spall._buffer_end(&spall_ctx, &spall_buffer)
//}

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

    spall_ctx = spall.context_create("jam-wolf_trace.spall")
    defer spall.context_destroy(&spall_ctx)

    buffer_backing := make([]u8, spall.BUFFER_DEFAULT_SIZE)
    spall_buffer = spall.buffer_create(buffer_backing, u32(sync.current_thread_id()))
    defer spall.buffer_destroy(&spall_ctx, &spall_buffer) // TODO: it's not deallocated

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

//    gs.level, gs.level_runtime = create_test_level()
    gs.level, gs.level_runtime = load_level("data/levels/level01a.json")

    gs.weapons[.Pistol] = create_weapon(pistol_cfg)
    gs.weapons[.Rifle] = create_weapon(rifle_cfg)
    gs.weapons[.Machine_Gun] = create_weapon(machinegun_cfg)

    gs.player.pos = gs.level.player_start
    gs.player.pos.z += 0.01 // TODO: fixes visible seams between tiles - wtf?
    // TODO
    gs.camera.position = gs.player.pos
    gs.camera.target = gs.camera.position + {1, 0, 0}

    gs.editor = create_editor()
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
    dbg_input()

    if gs.editor.active {
        update_editor(dt)
    } else {
        update_game(dt)
    }

    gs.dbg.update_time = rl.GetTime() - update_start
}

update_game :: proc(dt: f32) {
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

    update_weapon(dt)

    player_move(&gs.player, &gs.camera, dt)

    for &enemy in gs.level.enemies do update_enemy(&enemy, dt)


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

    if gs.message_time > 0 do gs.message_time -= dt
}

update_editor :: proc(dt: f32) {
    update_editor_input(&gs.editor)
    player_move(&gs.player, &gs.camera, dt, ignore_col = true)
    update_editor_item(&gs.editor)
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

draw :: proc() {
    draw_start := rl.GetTime()

    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    rl.BeginMode3D(gs.camera)

    draw_level(gs.level_runtime)

    sort_and_draw_billboards()

    if gs.dbg_enemy != nil {
        rl.DrawSphere(gs.dbg_enemy.pos + {0, 0.5, 0}, 0.05, rl.VIOLET)
    }

    player := &gs.player
    x := i32(player.pos.x)
    y := i32(player.pos.z)
    dbg_print(0, "player %.2f", player.pos)
    dbg_print(1, "pl tile %d, %d", x, y)

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
        w := rl.MeasureText(gs.message, 20)
        rl.DrawText(gs.message, (rl.GetScreenWidth() - w) / 2, 0, 20, rl.RAYWHITE)
    }

    gs.dbg.draw_time = rl.GetTime() - draw_start // Debug UI and frame present is not included

    dbg_draw_ui()
    dbg_draw_messages()

    rl.EndDrawing()
}
