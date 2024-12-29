package game

import "core:os"
import "core:encoding/json"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Level :: struct {
    grid_file: string,
    atlas: string,

    pos: Vec3,
    player_start: Vec3,

    items: Items,
    enemies: Enemies,
}

// TODO: can mark field for marshalling?
Level_Runtime :: struct {
    grid_tex: rl.Texture2D,
    grid: [^]rl.Color,
    model: rl.Model,
}

init_level :: proc() -> (level: Level, runtime: Level_Runtime) {
    level.grid_file = "data/levels/level01.png"
    level.atlas = "level01_atlas"
    level.pos = {-16, 0, -8}
    level.player_start = {13.5, 0.5, 43}

    level.items = {
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

    im_map := rl.LoadImage(strings.clone_to_cstring(level.grid_file, context.temp_allocator)) // TODO: path, to textures?
    defer rl.UnloadImage(im_map)

    runtime.grid_tex = rl.LoadTextureFromImage(im_map)
    runtime.grid = rl.LoadImageColors(im_map)
    runtime.model = rl.LoadModelFromMesh(rl.GenMeshCubicmap(im_map, {1, 1, 1}))

    runtime.model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = gs.textures[level.atlas]

    save_level("data/levels/level01.json", level)

    return level, runtime
}

destroy_level :: proc(level: Level, runtime: Level_Runtime) {
    delete(level.items)
    delete(level.enemies)
    delete(level.grid_file)
    delete(level.atlas)

    rl.UnloadImageColors(runtime.grid)
    rl.UnloadTexture(runtime.grid_tex)
    rl.UnloadModel(runtime.model)
}

load_level :: proc(level_file: string) -> (level: Level, runtime: Level_Runtime) {
    level_data, ok := os.read_entire_file(level_file, context.temp_allocator)
    if !ok {
        fmt.eprintfln("Unable to read level file: %v", level_file)
        return
    }

    json.unmarshal(level_data, &level) // TODO: handle error

    // TODO: temp solution
    for &item in level.items {
        switch item.type {
        case .Clip:     item.tex = gs.textures["clip"]
        case .Ammo_Box: item.tex = gs.textures["ammobox"]
        case .Armor:    item.tex = gs.textures["armor"]
        }
    }

    im_map := rl.LoadImage(strings.clone_to_cstring(level.grid_file, context.temp_allocator)) // TODO: path, to textures?
    defer rl.UnloadImage(im_map)

    runtime.grid_tex = rl.LoadTextureFromImage(im_map)
    runtime.grid = rl.LoadImageColors(im_map)
    runtime.model = rl.LoadModelFromMesh(rl.GenMeshCubicmap(im_map, {1, 1, 1}))

    runtime.model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = gs.textures[level.atlas]

    return level, runtime
}

save_level :: proc(level_file: string, level: Level) {
    if level_data, err := json.marshal(level, {pretty = true}, allocator = context.temp_allocator); err == nil {
        os.write_entire_file(level_file, level_data)
    }
}
