package game

import rl "vendor:raylib"

draw_minimap :: proc() {
    SCALE :: 4

    tex := gs.textures[.Level01] // TODO: or_else

    rl.DrawTextureEx(tex, {10, 50}, 0, SCALE, {255, 255, 255, 128})
    player_pos := Vec2{10, 50} + (gs.player.pos.xz) * SCALE
    rl.DrawCircleV(player_pos, 3, rl.GREEN)
    // TODO: line to show character direction
}
