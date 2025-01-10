package game

import "core:fmt"
import rl "vendor:raylib"

draw_crosshair :: proc() {
    center := Vec2{f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)}
    size := f32(rl.GetScreenHeight() / 140)
    color :: rl.RAYWHITE

    rl.DrawLineEx(center - {size, 0}, center - {4, 0}, 2, color)
    rl.DrawLineEx(center + {4, 0}, center + {size, 0}, 2, color)
    rl.DrawLineEx(center - {0, size}, center - {0, 4}, 2, color)
    rl.DrawLineEx(center + {0, 4}, center + {0, size}, 2, color)
}

draw_hud :: proc() {
    center := Vec2{f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight()) - 50}

    hp := fmt.ctprintf("hp: %d", gs.player.hp)
    rl.DrawTextEx({}, hp, center - {500, 0}, 40, 2, rl.RAYWHITE)

    armor := fmt.ctprintf("armor: %d", gs.player.armor)
    rl.DrawTextEx({}, armor, center - {350, 0}, 40, 2, rl.RAYWHITE)

    ammo := fmt.ctprintf("ammo: %d", gs.ammo)
    rl.DrawTextEx({}, ammo, center + {400, 0}, 40, 2, rl.RAYWHITE)
}

draw_dead :: proc() {
    x := rl.GetScreenWidth() / 2
    y := rl.GetScreenHeight() - 150

    msg := fmt.ctprintf("You are dead!")
    w := rl.MeasureText(msg, 40)
    rl.DrawText(msg, x - w/2, y, 40, {150, 0, 0, 255})

    msg = fmt.ctprintf("Press 'backspace' to restart...")
    w = rl.MeasureText(msg, 30)
    rl.DrawText(msg, x - w/2, y + 50, 30, {150, 0, 0, 255})
}

show_message :: proc(msg: cstring) {
    gs.message = msg
    gs.message_time = 3
}
