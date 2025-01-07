package game

import rl "vendor:raylib"

enemy_ai :: proc(enemy: ^Enemy, dt: f32) {
    enemy.action_time -= dt
    enemy_path(enemy) // TODO

    switch enemy.action {
    case .Idle:
        if enemy.action_time <= 0 {
        //                enemy_roam(enemy)
        //                enemy_path(enemy)
            enemy.action = .Move
        }
    case .Move:
        if rl.Vector3DistanceSqrt(enemy.pos, enemy.dest) < 0.2 {
            rnd := rl.GetRandomValue(1, 10)
            switch rnd {
            //                case 1..=2:
            //                    enemy.action_time = 1
            //                    enemy.action = .Idle

            case:
            //                    enemy_roam(enemy)
            //                    enemy_path(enemy)
            }
        } else {
            SPEED :: 0.5

            dir := rl.Vector2Normalize((enemy.dest - enemy.pos).xz)
            enemy.velocity = {dir.x, 0, dir.y} * SPEED * dt
            enemy.pos += enemy.velocity

            // TODO: use pathfinding instead of sliding and save performance
            slide(&enemy.pos, &enemy.velocity, enemy.col_radius)

            dbg_print(2, "%.2f", enemy.velocity)
            dbg_print(3, "dest %v", enemy.dest)

            // TODO: stagger when hit
            if enemy.anim.cur_anim == .Idle do play_anim(&enemy.anim, Enemy_Anim.Move)
        }
    }
}

enemy_roam :: proc(enemy: ^Enemy) {
    x := i32(enemy.pos.x)
    z := i32(enemy.pos.z)

    rnd_tile := rl.GetRandomValue(0, 3)
    it := get_roam_tile(gs.level_runtime, x, z)[rnd_tile]
    dx := f32(it.x)
    dz := f32(it.y)
    enemy.dest = {dx, 0, dz} + {0.5, 0, 0.5} // Go to the middle of a tile
//    fmt.println(enemy.nav_data.path)
}

enemy_path :: proc(enemy: ^Enemy) {
    bfs(enemy.pos, gs.player.pos, &enemy.nav_data)
    if len(enemy.nav_data.path) < 2 do return

    dx := f32(enemy.nav_data.path[1].x)
    dz := f32(enemy.nav_data.path[1].y)
    enemy.dest = {dx, 0, dz} + {0.5, 0, 0.5} // Go to the middle of a tile
//    fmt.println(enemy.nav_data.path)
}
