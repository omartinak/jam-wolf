package game

import rl "vendor:raylib"

draw_minimap :: proc() {
    tex := gs.textures[.Level01] // TODO: or_else

//    rl.DrawTextureEx(tex, {10, 50}, 0, 4, rl.WHITE)
    rl.DrawTextureEx(tex, {10, 50}, 0, 4, {255, 255, 255, 128})
    player_pos := Vec2{10, 50} + (gs.player.pos.xz - gs.level.pos.xz) * 4
    rl.DrawCircleV(player_pos + {1.5, 1.5}, 3, rl.GREEN)
    // TODO: line to show character direction
}
