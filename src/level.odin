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

    grid_tex: rl.Texture2D,
    grid: [^]rl.Color,
    model: rl.Model,

    player_start: Vec3,

    items: Items,
    enemies: Enemies,
}

create_test_level :: proc() -> (level: Level) {
    level.file_name = "data/levels/level_test.json"
    level.grid_file = "data/levels/level01.png"
    level.atlas = .Level01_Atlas
    level.player_start = {29.5, 0.5, 51.5}

    im_map := rl.LoadImage(strings.clone_to_cstring(level.grid_file, context.temp_allocator)) // TODO: path, to textures?
    defer rl.UnloadImage(im_map)

    level.grid_tex = rl.LoadTextureFromImage(im_map)
    level.grid = rl.LoadImageColors(im_map)
    level.model = rl.LoadModelFromMesh(rl.GenMeshCubicmap(im_map, {1, 1, 1}))

    level.model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = gs.textures[level.atlas]

    return level
}

destroy_level :: proc(level: Level) {
    delete(level.items)
    for enemy in level.enemies do destroy_enemy(enemy)
    delete(level.enemies)
    delete(level.grid_file)

    rl.UnloadImageColors(level.grid)
    rl.UnloadTexture(level.grid_tex)
    rl.UnloadModel(level.model)
}

parse_vec3 :: proc(value: json.Value) -> Vec3 {
    vec: Vec3
    vec.x = f32(value.(json.Array)[0].(json.Float))
    vec.y = f32(value.(json.Array)[1].(json.Float))
    vec.z = f32(value.(json.Array)[2].(json.Float))
    return vec
}

load_level :: proc(level_file: string) -> (level: Level) {
    data, ok := os.read_entire_file(level_file, context.temp_allocator)
    if !ok {
        fmt.eprintfln("Unable to read level file: %v", level_file)
        return
    }

    json_data, err := json.parse(data, allocator = context.temp_allocator)
    if err != .None {
        fmt.eprintfln("Failed to parse level file: %v", level_file)
        fmt.eprintfln("Error: %v", err)
        return
    }

    root := json_data.(json.Object)

    level.file_name = level_file
    level.grid_file = json.clone_string(root["grid_file"].(json.String), context.allocator) or_else ""
    level.atlas = .Level01_Atlas
    level.player_start = parse_vec3(root["player_start"])

    level.items = make(Items, len(root["items"].(json.Array)))
    for value, i in root["items"].(json.Array) {
        obj := value.(json.Object)

        pos := parse_vec3(obj["pos"])
        type := Item_Type(obj["type"].(json.Float)) // Why does it parse as Float?

        level.items[i] = create_item(item_cfg[type], pos)
    }

    level.enemies = make(Enemies, len(root["enemies"].(json.Array)))
    for value, i in root["enemies"].(json.Array) {
        obj := value.(json.Object)

        pos := parse_vec3(obj["pos"])
        type := Enemy_Type(obj["type"].(json.Float)) // Why does it parse as float?

        level.enemies[i] = create_enemy(enemy_cfg[type], pos)
    }

    im_map := rl.LoadImage(strings.clone_to_cstring(level.grid_file, context.temp_allocator)) // TODO: path, to textures?
    defer rl.UnloadImage(im_map)

    level.grid_tex = rl.LoadTextureFromImage(im_map)
    level.grid = rl.LoadImageColors(im_map)
    level.model = rl.LoadModelFromMesh(rl.GenMeshCubicmap(im_map, {1, 1, 1}))

    level.model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = gs.textures[level.atlas]

    return level
}

marshal_vec3 :: proc(vec: Vec3) -> json.Array {
    array := make(json.Array, 3, context.temp_allocator)
    array[0] = json.Float(vec.x)
    array[1] = json.Float(vec.y)
    array[2] = json.Float(vec.z)
    return array
}

save_level :: proc(level: Level, level_file := "") {
    file_name := (level_file == "") ? level.file_name : level_file

    level_data := make(json.Object, context.temp_allocator)

    // TODO: root keys are saved in different order
    level_data["grid_file"] = level.grid_file
    level_data["player_start"] = marshal_vec3(level.player_start)

    items_json := make(json.Array, len(level.items), context.temp_allocator)
    for item, i in level.items {
        obj := make(json.Object, context.temp_allocator)
        obj["pos"] = marshal_vec3(item.pos)
        obj["type"] = json.Integer(item.type)
        items_json[i] = obj
    }
    level_data["items"] = items_json

    enemies_json := make(json.Array, len(level.enemies), context.temp_allocator)
    for enemy, i in level.enemies {
        obj := make(json.Object, context.temp_allocator)
        obj["pos"] = marshal_vec3(enemy.pos)
        obj["type"] = json.Integer(enemy.type)
        enemies_json[i] = obj
    }
    level_data["enemies"] = enemies_json

    if json_data, err := json.marshal(level_data, {pretty = true}, allocator = context.temp_allocator); err == nil {
        if !os.write_entire_file(file_name, json_data) {
            fmt.eprintfln("Unable to save level file: %v", file_name)
        }
    }
}

draw_level :: proc(level: Level) {
    LEVEL_OFFSET :: Vec3{0.5, 0, 0.5} // Each tile is generated to be -0.5..0.5, so we need to shift the level
    rl.DrawModel(level.model, LEVEL_OFFSET, 1, rl.WHITE)
}

// TODO: temp solution
get_roam_tile :: proc(level: Level, x, z: i32) -> (ret: [4][2]i32) {
    ret = {{x, z}, {x, z}, {x, z}, {x, z}}
    if (x-1) >= 0 && level.grid[x-1+z*level.grid_tex.width].r != 255 do ret[0] = {x-1, z}
    if (x+1) < level.grid_tex.width && level.grid[x+1+z*level.grid_tex.width].r != 255 do ret[1] = {x+1, z}
    if (z-1) >= 0 && level.grid[x+(z-1)*level.grid_tex.width].r != 255 do ret[2] = {x, z-1}
    if (z+1) < level.grid_tex.height && level.grid[x+(z+1)*level.grid_tex.width].r != 255 do ret[3] = {x, z+1}
    return ret
}

is_wall :: proc {is_wall_i32, is_wall_Vec2i}

is_wall_i32 :: proc(level: Level, x, y: i32) -> bool {
    return level.grid[x + y * level.grid_tex.width].r == 255
}

is_wall_Vec2i :: proc(level: Level, t: Vec2i) -> bool {
    return is_wall_i32(level, t.x, t.y)
}
