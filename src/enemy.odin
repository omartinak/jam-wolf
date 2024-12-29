package game

import rl "vendor:raylib"

Enemy :: struct {
    tex: rl.Texture2D,
    pos: Vec3,

//    type: Enemy_Type,
}

Enemies :: [dynamic]Enemy

draw_enemy :: proc(enemy: Enemy, opacity: u8 = 255) {
    rl.DrawBillboard(gs.camera, enemy.tex, enemy.pos, 0.75, {255, 255, 255, opacity})
}
