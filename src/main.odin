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
    im_map := rl.LoadImage("data/levels/level01.png") // TODO: path, to textures?
    defer rl.UnloadImage(im_map)

    gs = Game_State {
        textures = create_textures(),

        cubicmap = rl.LoadTextureFromImage(im_map),
        map_model = rl.LoadModelFromMesh(rl.GenMeshCubicmap(im_map, {1, 1, 1})),
        map_pixels = rl.LoadImageColors(im_map),
        map_pos = Vec3{-16, 0, -8},

        camera = {
            position = {0, 0.5, 0},
            target = {0, 0.5, -1.0},
            up = {0, 1, 0},
            fovy = 45, // TODO
            projection = .PERSPECTIVE,
        },
        player = {
//            pos = {0, 0.5, 0},
            pos = {13.5, 0.5, 43},
            hp = 100,
            armor = 0,
        },
    }

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
            x_off = 0,
            ammo = 200,
        },
        .Nuker = {
            tex = gs.textures["gun4"],
            x_off = -8,
            ammo = 10,
        },
    }

    gs.items = {
        {
            tex = gs.textures["ammobox"],
            pos = {18, 0.2, 43},
            type = .Ammo_Box,
        },
        {
            tex = gs.textures["ammobox"],
            pos = {18, 0.2, 42},
            type = .Ammo_Box,
        },
        {
            tex = gs.textures["ammobox"],
            pos = {18, 0.2, 41},
            type = .Ammo_Box,
        },
        {
            tex = gs.textures["armor"],
            pos = {22, 0.2, 38},
            type = .Armor,
        },
    }

    gs.player.pos.z += 0.01 // TODO: fixes visible seams between tiles - wtf?
    // TODO
    gs.camera.position = gs.player.pos
    gs.camera.target = gs.camera.position + {1, 0, 0}

    gs.map_model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = gs.textures["atlas"]
}

destroy :: proc() {
    delete(gs.items)

    rl.UnloadImageColors(gs.map_pixels)
    rl.UnloadTexture(gs.cubicmap)
    rl.UnloadModel(gs.map_model)

    destroy_textures(gs.textures)
}

draw :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    rl.BeginMode3D(gs.camera)

    rl.DrawModel(gs.map_model, gs.map_pos, 1, rl.WHITE)
    slice.sort_by(gs.items[:], proc(a, b: Item) -> bool {
        a_dist := rl.Vector3DistanceSqrt(gs.camera.position, a.pos)
        b_dist := rl.Vector3DistanceSqrt(gs.camera.position, b.pos)
        return a_dist > b_dist
    })
    for item in gs.items do draw_item(item)

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

    velocity: Vec3
    player_move(&gs.player, &gs.camera, &velocity, dt)
    dbg_print(0, "player %.2f", gs.player.pos.xz)

    // TODO: optimize - spatial accel struct, check only adjacent tiles, merge tiles
    for y in 0..<gs.cubicmap.height {
        for x in 0..<gs.cubicmap.width {
            rc := rl.Rectangle {
                x = gs.map_pos.x - 0.5 + f32(x),
                y = gs.map_pos.z - 0.5 + f32(y),
                width = 1,
                height = 1,
            }

            if gs.map_pixels[x + y * gs.cubicmap.width].r == 255 && rl.CheckCollisionCircleRec(gs.player.pos.xz, PLAYER_RADIUS, rc) {
                correction := slide(gs.player.pos, velocity, rc)

                // TODO: update camera based on player automatically when frame starts
                gs.player.pos += correction
                gs.camera.position += correction
                gs.camera.target += correction
            }
        }
    }

    for item, i in gs.items {
        if rl.Vector3Distance(gs.player.pos, item.pos) < 0.5 {
            switch item.type {
            case .Ammo_Box:
                gs.weapons[gs.cur_weapon].ammo += 5
                show_message("+5 ammo")

            case .Armor:
                gs.player.armor = 100
                show_message("full armor")
            }
            unordered_remove(&gs.items, i)
        }
    }

    if gs.message_time > 0 do gs.message_time -= dt
}
