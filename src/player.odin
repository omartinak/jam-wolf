package game

import rl "vendor:raylib"

Player :: struct {
    pos: Vec3,
    velocity: Vec3,
    col_radius: f32,

    move_forward: f32,
    move_right: f32,

    hp: int,
    armor: int,
    hit_time: f32,
    hit_time_max: f32,
    dead: bool,
}

create_player :: proc(pos: Vec3) -> Player {
    player := Player {
        pos = pos,
        col_radius = 0.2,
        hp = 100,
        armor = 0,
        hit_time_max = 0.5,
    }

    // TODO
    player.pos.z += 0.01 // TODO: fixes visible seams between tiles - wtf?
    gs.camera.position = gs.player.pos
    gs.camera.target = gs.camera.position + {1, 0, 0}

    return player
}

update_player :: proc(player: ^Player, dt: f32) {
    if player.hit_time > 0 do player.hit_time -= dt
}

player_move :: proc(player: ^Player, camera: ^rl.Camera, dt: f32, ignore_col := false) {
    speed :: 5

    forward := rl.Vector3Normalize(camera.target - camera.position)
    forward.y = 0
    right := forward.zyx
    right.x *= -1

    // TODO: diag movement
    player.velocity = forward * player.move_forward + right * player.move_right
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

    gs.player.move_forward = 0
    gs.player.move_right = 0
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
            damage_enemy(enemy_hit.enemy, dmg)
        }
    }
}

damage_player :: proc(player: ^Player, dmg: int) {
    player.hp = max(player.hp - dmg, 0)
    player.hit_time = player.hit_time_max

    if player.hp <= 0 {
        player.dead = true
        // TODO: easing to animate fall
        player.pos.y = 0.1
    }
}
