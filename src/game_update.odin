package game

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
    // TODO: mouse wheel to switch weapons

    switch {
    case rl.IsKeyPressed(.ONE):   change_weapon(.Pistol)
    case rl.IsKeyPressed(.TWO):   change_weapon(.Rifle)
    case rl.IsKeyPressed(.THREE): change_weapon(.Machine_Gun)
    case rl.IsKeyPressed(.BACKSPACE): gs.should_restart = true
    }

    update_weapon(dt)
    player_move(&gs.player, &gs.camera, dt)

    for &enemy in gs.level.enemies do update_enemy(&enemy, dt)
    for item, i in gs.level.items {
        if update_item(item) do unordered_remove(&gs.level.items, i)
    }

    if gs.should_restart do restart()
}

update_editor :: proc(dt: f32) {
    update_editor_input(&gs.editor)
    player_move(&gs.player, &gs.camera, dt, ignore_col = true)
    update_editor_item(&gs.editor)
}
