package game

import rl "vendor:raylib"

Player :: struct {
    pos: Vec3,
    velocity: Vec3,
    col_radius: f32,

    hp: int,
    armor: int,
}

player_move :: proc(player: ^Player, camera: ^rl.Camera, dt: f32, ignore_col := false) {
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
    player.velocity = forward * forward_mag + right * right_mag
    player.velocity = rl.Vector3Normalize(player.velocity)
    player.velocity *= speed * dt

    player.pos += player.velocity

    if !ignore_col do slide(&player.pos, &player.velocity, player.col_radius)

    camera_target := camera.target - camera.position
    camera.position = player.pos
    camera.target = camera.position + camera_target

    mouse_delta := rl.GetMouseDelta()
    camera_yaw(camera, -mouse_delta.x * 0.001)
    camera_pitch(camera, -mouse_delta.y * 0.001)
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
            enemy_hit.enemy.hp -= dmg

            if enemy_hit.enemy.hp > 0 {
                play_anim(&enemy_hit.enemy.anim, Enemy_Anim.Hit)
            } else {
                enemy_hit.enemy.dead = true
                play_anim(&enemy_hit.enemy.anim, Enemy_Anim.Death)
            }
        }
    }
}
