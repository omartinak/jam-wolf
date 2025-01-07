package game

import "core:os"
import "core:encoding/json"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Level :: struct {
    file_name: string,

    grid_file: string,
    atlas: Tex,

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

create_test_level :: proc() -> (level: Level, runtime: Level_Runtime) {
    level.file_name = "data/levels/level_test.json"
    level.grid_file = "data/levels/level01.png"
    level.atlas = .Level01_Atlas
    level.player_start = {29.5, 0.5, 51.5}

    im_map := rl.LoadImage(strings.clone_to_cstring(level.grid_file, context.temp_allocator)) // TODO: path, to textures?
    defer rl.UnloadImage(im_map)

    runtime.grid_tex = rl.LoadTextureFromImage(im_map)
    runtime.grid = rl.LoadImageColors(im_map)
    runtime.model = rl.LoadModelFromMesh(rl.GenMeshCubicmap(im_map, {1, 1, 1}))

    runtime.model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = gs.textures[level.atlas]

    return level, runtime
}

destroy_level :: proc(level: Level, runtime: Level_Runtime) {
    delete(level.items)
    for enemy in level.enemies do destroy_enemy(enemy)
    delete(level.enemies)
    delete(level.grid_file)

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
    level.file_name = level_file // TODO: should not be marshalled

    // TODO: temp solution
    for &item in level.items {
        item = create_item(item_cfg[item.type], item.pos)
    }
    for &enemy in level.enemies {
        enemy = create_enemy(enemy_cfg[enemy.type], enemy.pos)
    }

    im_map := rl.LoadImage(strings.clone_to_cstring(level.grid_file, context.temp_allocator)) // TODO: path, to textures?
    defer rl.UnloadImage(im_map)

    runtime.grid_tex = rl.LoadTextureFromImage(im_map)
    runtime.grid = rl.LoadImageColors(im_map)
    runtime.model = rl.LoadModelFromMesh(rl.GenMeshCubicmap(im_map, {1, 1, 1}))

    runtime.model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = gs.textures[level.atlas]

    return level, runtime
}

save_level :: proc(level: Level, level_file := "") {
    file_name := (level_file == "") ? level.file_name : level_file
    if level_data, err := json.marshal(level, {pretty = true}, allocator = context.temp_allocator); err == nil {
        os.write_entire_file(file_name, level_data)
    }
}

draw_level :: proc(runtime: Level_Runtime) {
    LEVEL_OFFSET :: Vec3{0.5, 0, 0.5} // Each tile is generated to be -0.5..0.5, so we need to shift the level
    rl.DrawModel(runtime.model, LEVEL_OFFSET, 1, rl.WHITE)
}

// TODO: temp solution
get_roam_tile :: proc(runtime: Level_Runtime, x, z: i32) -> (ret: [4][2]i32) {
    ret = {{x, z}, {x, z}, {x, z}, {x, z}}
    if (x-1) >= 0 && runtime.grid[x-1+z*runtime.grid_tex.width].r != 255 do ret[0] = {x-1, z}
    if (x+1) < runtime.grid_tex.width && runtime.grid[x+1+z*runtime.grid_tex.width].r != 255 do ret[1] = {x+1, z}
    if (z-1) >= 0 && runtime.grid[x+(z-1)*runtime.grid_tex.width].r != 255 do ret[2] = {x, z-1}
    if (z+1) < runtime.grid_tex.height && runtime.grid[x+(z+1)*runtime.grid_tex.width].r != 255 do ret[3] = {x, z+1}
    return ret
}

is_wall :: proc {is_wall_i32, is_wall_Vec2i}

is_wall_i32 :: proc(x, y: i32) -> bool {
    return gs.level_runtime.grid[x + y * gs.level_runtime.grid_tex.width].r == 255
}

is_wall_Vec2i :: proc(t: Vec2i) -> bool {
    return is_wall_i32(t.x, t.y)
}
