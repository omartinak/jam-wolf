package game

import rl "vendor:raylib"

Vec3 :: rl.Vector3
Vec2 :: rl.Vector2

Game_State :: struct {
    textures: Textures,

    cubicmap: rl.Texture2D,
    map_pixels: [^]rl.Color,
    map_model: rl.Model,
    map_pos: Vec3,

    message: cstring,
    message_time: f32,

    camera: rl.Camera,

    player: Player,
    weapons: Weapons,
    cur_weapon: Weapon_Type,

    items: Items,

    dbg: Debug_Data,
}

gs: Game_State // TODO
