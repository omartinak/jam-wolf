package game

import "base:runtime"
import "core:mem"
import "core:fmt"
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
            up = {0, 1, 0},
            fovy = 45, // TODO
            projection = .PERSPECTIVE,
        },
        ammo = 50,
    }
    gss = &gs

//    gs.level, gs.level_runtime = create_test_level()
    gs.level, gs.level_runtime = load_level("data/levels/level01a.json")
    gs.player = create_player(gs.level.player_start)

    gs.weapons[.Pistol] = create_weapon(pistol_cfg)
    gs.weapons[.Rifle] = create_weapon(rifle_cfg)
    gs.weapons[.Machine_Gun] = create_weapon(machinegun_cfg)

    gs.editor = create_editor()
}

destroy :: proc() {
    for weapon in gs.weapons {
        destroy_weapon(weapon)
    }
    destroy_level(gs.level, gs.level_runtime)
    destroy_textures(gs.textures)
}

restart :: proc() {
    level_name := gs.level.file_name

    destroy_level(gs.level, gs.level_runtime)

    gs.should_restart = false
    gs.cur_weapon = .Pistol
    gs.ammo = 50

    gs.level, gs.level_runtime = load_level(level_name)
    gs.player = create_player(gs.level.player_start)
}
