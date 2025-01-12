package game

import "core:fmt"
import rl "vendor:raylib"

update :: proc() {
    update_start := rl.GetTime()
    dt := rl.GetFrameTime()

    if rl.IsKeyPressed(.F2) do gs.editor.active = !gs.editor.active
    if rl.IsKeyPressed(.APOSTROPHE) || rl.IsKeyPressed(.Q) {
        ray := rl.Ray {
            position = gs.camera.position,
            direction = rl.Vector3Normalize(gs.camera.target - gs.camera.position),
        }
        enemy_hit := get_enemy_hit(ray, check_dead = true)

        if enemy_hit.enemy == gs.dbg_enemy do gs.dbg_enemy = nil
        else do gs.dbg_enemy = enemy_hit.enemy
    }
    if rl.IsKeyPressed(.F9) {
        switch gs.dbg.ui_state {
        case .None: gs.dbg.ui_state = .Small
        case .Small: gs.dbg.ui_state = .Full
        case .Full: gs.dbg.ui_state = .None
        }
    }
    dbg_input()

    if gs.editor.active {
        update_editor(dt)
    } else {
        update_game(dt)
    }

    if gs.message_time > 0 do gs.message_time -= dt
    gs.dbg.update_time = rl.GetTime() - update_start
}

update_game :: proc(dt: f32) {
    game_input()

    if !gs.player.dead {
        player_input()
    }

    update_weapon(dt)
    update_player(&gs.player, dt)
    player_move(&gs.player, &gs.camera, dt)

    for &enemy in gs.level.enemies do update_enemy(&enemy, dt)
    for item, i in gs.level.items {
        if update_item(item) do unordered_remove(&gs.level.items, i)
    }

    if gs.should_restart do restart()
}

update_editor :: proc(dt: f32) {
    update_editor_input(&gs.editor)
    player_input_move()
    player_move(&gs.player, &gs.camera, dt, ignore_col = true)
    update_editor_item(&gs.editor)
}

player_input :: proc() {
    switch gs.cur_weapon {
    case .Pistol:
        if rl.IsMouseButtonPressed(.LEFT) && can_weapon_shoot() {
            player_shoot()
        }
    case .Rifle: fallthrough
    case .Machine_Gun:
        if rl.IsMouseButtonDown(.LEFT) && can_weapon_shoot() {
            player_shoot()
        }
    }
    if wheel := rl.GetMouseWheelMove(); wheel != 0 {
    // TODO: doesn't skip non-owned weapons
        new_weapon := gs.cur_weapon + Weapon_Type(wheel)
        if new_weapon >= .Pistol && new_weapon <= .Machine_Gun {
            change_weapon(new_weapon)
        }
    }

    switch {
    case rl.IsKeyPressed(.ONE):   change_weapon(.Pistol)
    case rl.IsKeyPressed(.TWO):   change_weapon(.Rifle)
    case rl.IsKeyPressed(.THREE): change_weapon(.Machine_Gun)
    case rl.IsKeyPressed(.BACKSPACE): gs.should_restart = true
    case rl.IsKeyPressed(.TAB): kill_all_enemies()
    }

    player_input_move()
}

player_input_move :: proc() {
    if rl.IsKeyDown(.W) do gs.player.move_forward += 1
    if rl.IsKeyDown(.S) do gs.player.move_forward -= 1
    if rl.IsKeyDown(.A) do gs.player.move_right -= 1
    if rl.IsKeyDown(.D) do gs.player.move_right += 1
    fmt.println("input move")
}

game_input :: proc() {
    if rl.IsKeyPressed(.BACKSPACE) do gs.should_restart = true
}
