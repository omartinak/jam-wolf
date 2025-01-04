package game

import rl "vendor:raylib"

slide :: proc(pos, velocity: ^Vec3, radius: f32) {
// TODO: optimize - spatial accel struct, check only adjacent tiles, merge tiles
    for y in 0..<gs.level_runtime.grid_tex.height {
        for x in 0..<gs.level_runtime.grid_tex.width {
            rc := rl.Rectangle{f32(x), f32(y), 1, 1}

            // TODO: unify collision check and penetration
            if is_wall(x, y) && rl.CheckCollisionCircleRec(pos.xz, radius, rc) {
                correction := get_penetration(pos^, velocity^, rc, radius)
                pos^ += correction
            }
        }
    }
}

get_penetration :: proc(pos, velocity: Vec3, rc_tile: rl.Rectangle, radius: f32) -> Vec3 {
    rc := rl.Rectangle{pos.x - radius, pos.z - radius, radius * 2, radius * 2}
    if rl.CheckCollisionRecs(rc, rc_tile) {
        xPenetration: f32
        zPenetration: f32

        if velocity.x < 0 do xPenetration = (rc_tile.x + rc_tile.width) - rc.x
        else              do xPenetration = rc_tile.x - (rc.x + rc.width)

        if velocity.z < 0 do zPenetration = (rc_tile.y + rc_tile.height) - rc.y
        else              do zPenetration = rc_tile.y - (rc.y + rc.height)

        if abs(xPenetration) < abs(zPenetration) do return {xPenetration, 0, 0}
        else                                     do return {0, 0, zPenetration}
    }
    return {}
}
