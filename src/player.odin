package game

import rl "vendor:raylib"

PLAYER_RADIUS :: 0.1

Player :: struct {
    pos: Vec3,

    hp: int,
    armor: int,
}

player_move :: proc(player: ^Player, camera: ^rl.Camera, velocity: ^Vec3, dt: f32) {
    speed :: 5

    forward := rl.Vector3Normalize(camera.target - camera.position)
    forward.y = 0
    right := forward.zyx
    right.x *= -1

    forward_mag: f32
    right_mag: f32

    if rl.IsKeyDown(.W) do forward_mag += 1
    if rl.IsKeyDown(.S) do forward_mag -= 1
    if rl.IsKeyDown(.A) do right_mag -= 1
    if rl.IsKeyDown(.D) do right_mag += 1

    // TODO: diag movement
    velocity^ = forward * forward_mag + right * right_mag
    velocity^ = rl.Vector3Normalize(velocity^)
    velocity^ *= speed * dt

    player.pos += velocity^

    // TODO: derive from player pos and direction?
    camera.position += velocity^
    camera.target += velocity^

    mouse_delta := rl.GetMouseDelta()
    camera_yaw(camera, -mouse_delta.x * 0.001)
    camera_pitch(camera, -mouse_delta.y * 0.001)
}

// TODO: move to a different file
slide :: proc(pos, velocity: Vec3, rc_tile: rl.Rectangle) -> Vec3 {
    rc := rl.Rectangle{pos.x - 0.1, pos.z - 0.1, 0.2, 0.2}
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

player_shoot :: proc() {
    dmg := 0
    if gs.ammo > 0 {
        play_weapon_anim()
        gs.ammo -= 1
        dmg = gs.weapons[gs.cur_weapon].damage
    }

    if dmg > 0 {
        ray := rl.Ray {
        // TODO: use player direction/rotation
            position = gs.camera.position,
            direction = rl.Vector3Normalize(gs.camera.target - gs.camera.position),
        }

        enemy_hit := get_enemy_hit(ray)
        if enemy_hit.hit {
            show_message("hit")
            enemy_hit.enemy.hp -= dmg
            enemy_hit_anim(enemy_hit.enemy)

            if enemy_hit.enemy.hp <= 0 {
                enemy_hit.enemy.dead = true
                enemy_death_anim(enemy_hit.enemy)
            }
        }
    }
}
