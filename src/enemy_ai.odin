package game

import rl "vendor:raylib"

enemy_ai :: proc(enemy: ^Enemy, dt: f32) {
    enemy.dist = rl.Vector3Distance(enemy.pos, gs.player.pos)

    // TODO: crashes when saving level with goals
    enemy.goals = get_applicable_goals(enemy)

    if enemy.cur_goal == nil && len(enemy.goals) > 0 {
        enemy.cur_goal = enemy.goals[0]
    }

    if cur_goal, ok := enemy.cur_goal.?; ok {
        cur_goal.execute(enemy, dt)
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

enemy_path :: proc(enemy: ^Enemy, dest: Vec3) {
//    bfs(enemy.pos, gs.player.pos, &enemy.nav_data)
    bfs(enemy.pos, dest, &enemy.nav_data)
    if len(enemy.nav_data.path) < 2 do return

    dx := f32(enemy.nav_data.path[1].x)
    dz := f32(enemy.nav_data.path[1].y)
    enemy.dest = {dx, 0, dz} + {0.5, 0, 0.5} // Go to the middle of a tile
//    fmt.println(enemy.nav_data.path)
}
