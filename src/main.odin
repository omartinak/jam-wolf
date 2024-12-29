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

    rl.InitWindow(1280, 800, "jam-wolf")
    rl.InitAudioDevice()
    rl.DisableCursor()

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
            hp = 100,
            armor = 0,
        },
    }
    gss = &gs

//    gs.level, gs.level_runtime = init_level()
    gs.level, gs.level_runtime = load_level("data/levels/level01.json")

    gs.weapons = {
        .Pistol = {
            tex = gs.textures["gun2"],
            x_off = 0,
            ammo = 20,
        },
        .Rifle = {
            tex = gs.textures["gun5"],
            x_off = 2,
            ammo = 100,
        },
        .Machine_Gun = {
            tex = gs.textures["gun1"],
            x_off = -1,
            ammo = 200,
        },
        .Nuker = {
            tex = gs.textures["gun4"],
            x_off = -8,
            ammo = 10,
        },
    }

    gs.player.pos = gs.level.player_start
    gs.player.pos.z += 0.01 // TODO: fixes visible seams between tiles - wtf?
    // TODO
    gs.camera.position = gs.player.pos
    gs.camera.target = gs.camera.position + {1, 0, 0}

    gs.editor_item = {
        tex = gs.textures["ammobox"],
        pos = {0, 0.2, 0},
        type = .Ammo_Box,
    }
}

destroy :: proc() {
    destroy_level(gs.level, gs.level_runtime)
    destroy_textures(gs.textures)
}

draw :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    rl.BeginMode3D(gs.camera)

    rl.DrawModel(gs.level_runtime.model, gs.level.pos, 1, rl.WHITE)
    slice.sort_by(gs.level.items[:], proc(a, b: Item) -> bool {
        a_dist := rl.Vector3DistanceSqrt(gs.camera.position, a.pos)
        b_dist := rl.Vector3DistanceSqrt(gs.camera.position, b.pos)
        return a_dist > b_dist
    })
    for item in gs.level.items do draw_item(item)

    if gs.editor {
        draw_item(gs.editor_item, opacity = 128)
    }

    rl.EndMode3D()

    draw_minimap()
    draw_crosshair()
    draw_weapon()
    draw_hud()

    if gs.message_time > 0 {
//        w := rl.MeasureTextEx({}, gs.message, 20, 2)
        w := rl.MeasureText(gs.message, 20)
        rl.DrawTextEx({}, gs.message, {f32(rl.GetScreenWidth() - w)/2, 0}, 20, 2, rl.RAYWHITE)
    }

    rl.DrawFPS(10, 10)
    dbg_draw_messages()

    rl.EndDrawing()
}

update :: proc() {
    dt := rl.GetFrameTime()

    if rl.IsKeyPressed(.F2) do gs.editor = !gs.editor
    if gs.editor {
        if rl.IsMouseButtonPressed(.LEFT) {
            append(&gs.level.items, gs.editor_item)
        }

        switch {
        case rl.IsKeyPressed(.F5):
            save_level("data/levels/level01.json", gs.level)
            show_message("lavel01 saved...")
        }
    } else {
        if rl.IsMouseButtonPressed(.LEFT) {
            player_shoot()
        }
        // TODO: mouse wheel to switch weapons

        switch {
        case rl.IsKeyPressed(.ONE):   gs.cur_weapon = .Pistol
        case rl.IsKeyPressed(.TWO):   gs.cur_weapon = .Rifle
        case rl.IsKeyPressed(.THREE): gs.cur_weapon = .Machine_Gun
        case rl.IsKeyPressed(.FOUR):  gs.cur_weapon = .Nuker
        }
    }

    velocity: Vec3
    player_move(&gs.player, &gs.camera, &velocity, dt)
    dbg_print(0, "player %.2f", gs.player.pos.xz)

    // TODO: optimize - spatial accel struct, check only adjacent tiles, merge tiles
    for y in 0..<gs.level_runtime.grid_tex.height {
        for x in 0..<gs.level_runtime.grid_tex.width {
            rc := rl.Rectangle {
                x = gs.level.pos.x - 0.5 + f32(x),
                y = gs.level.pos.z - 0.5 + f32(y),
                width = 1,
                height = 1,
            }

            if gs.level_runtime.grid[x + y * gs.level_runtime.grid_tex.width].r == 255 && rl.CheckCollisionCircleRec(gs.player.pos.xz, PLAYER_RADIUS, rc) {
                correction := slide(gs.player.pos, velocity, rc)

                // TODO: update camera based on player automatically when frame starts
                gs.player.pos += correction
                gs.camera.position += correction
                gs.camera.target += correction
            }
        }
    }
    gs.editor_item.pos.xz = gs.camera.target.xz

    if !gs.editor {
        for item, i in gs.level.items {
            if rl.Vector3Distance(gs.player.pos, item.pos) < 0.5 {
                switch item.type {
                case .Ammo_Box:
                    gs.weapons[gs.cur_weapon].ammo += 5
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
}
