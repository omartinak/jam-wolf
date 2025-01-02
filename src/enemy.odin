package game

import "core:slice"
import rl "vendor:raylib"

Enemy_Anim :: enum {
    Idle,
    Move,
    Hit,
    Death,
}

Enemy_Action :: enum {
    Idle,
    Move,
}

Enemy :: struct {
    anim: Anim(Enemy_Anim),
    pos: Vec3,

    dead: bool,
    hp: int,

    hit_anim: bool,
    death_anim: bool,
    anim_frame: int,
    anim_time: f32,

    action: Enemy_Action,
    action_time: f32,
    dest: Vec3,
}

Enemies :: [dynamic]Enemy

EnemyHit :: struct {
    enemy: ^Enemy,
    hit: bool,
    dist: f32,
}

destroy_enemy :: proc(enemy: Enemy) {
    destroy_anim(enemy.anim)
}

draw_enemy :: proc(enemy: Enemy, opacity: u8 = 255) {
    frame := get_anim_frame(enemy.anim)
    rl.DrawBillboard(gs.camera, frame, enemy.pos, 0.75, {255, 255, 255, opacity})

//    x := i32(enemy.pos.x + 0.5) - i32(gs.level.pos.x)
//    y := i32(enemy.pos.z + 0.5) - i32(gs.level.pos.z)
//
//    rl.DrawCubeWiresV({f32(x), 0, f32(y)} + gs.level.pos, {1, 1, 1}, rl.VIOLET)
//
//    dx := f32(x) + gs.level.pos.x
//    dy := f32(y) + gs.level.pos.z
//    rl.DrawSphere({dx, 0, dy}, 0.2, rl.VIOLET)

//    bodyPos := enemy.pos
//    body := rl.BoundingBox {
//        min = bodyPos - {0.18, 0.33, 0.18},
//        max = bodyPos + {0.18, 0.33, 0.18},
//    }
//    rl.DrawBoundingBox(body, rl.MAROON)
}

update_enemy :: proc(enemy: ^Enemy, dt: f32) {
    if !enemy.dead {
        enemy.action_time -= dt

        switch enemy.action {
        case .Idle:
            if enemy.action_time <= 0 {
                enemy_roam(enemy)
                enemy.action = .Move
            }
        case .Move:
            if rl.Vector3DistanceSqrt(enemy.pos, enemy.dest) < 0.2 {
                rnd := rl.GetRandomValue(1, 10)
                switch rnd {
                case 1..=2:
                    enemy.action_time = 1
                    enemy.action = .Idle

                case:
                    enemy_roam(enemy)
                }
            } else {
                dir := rl.Vector2Normalize((enemy.dest - enemy.pos).xz)
                vel := Vec3{dir.x, 0, dir.y} * 0.5
                vel_dt := vel * dt
                enemy.pos += vel_dt
                dbg_print(2, "%.2f, %.2f", vel, vel_dt)
                // TODO: stagge when hit
                if enemy.anim.cur_anim == .Idle do play_anim(&enemy.anim, Enemy_Anim.Move)
            }
        }
    }
    update_anim(&enemy.anim, dt)
}

enemy_roam :: proc(enemy: ^Enemy) {
    x := i32(enemy.pos.x + 0.5) - i32(gs.level.pos.x)
    z := i32(enemy.pos.z + 0.5) - i32(gs.level.pos.z)

    rnd_tile := rl.GetRandomValue(0, 3)
    it := get_roam_tile(gs.level_runtime, x, z)[rnd_tile]
    dx := f32(it.x) + gs.level.pos.x
    dz := f32(it.y) + gs.level.pos.z
    enemy.dest = {dx, 0, dz}
}

check_enemy_collision :: proc(enemy: Enemy, ray: rl.Ray) -> bool {
    if enemy.dead do return {}

//    bodyPos := enemy.pos - {0, 0.1, 0}
    bodyPos := enemy.pos
    body := rl.BoundingBox {
//        min = bodyPos - {0.12, 0.29, 0.12},
//        max = bodyPos + {0.12, 0.29, 0.12},
//        min = bodyPos - {0.2, 0.4, 0.2},
//        max = bodyPos + {0.2, 0.4, 0.2},
        min = bodyPos - {0.18, 0.33, 0.18},
        max = bodyPos + {0.18, 0.33, 0.18},
    }

    colBody := rl.GetRayCollisionBox(ray, body)
    if colBody.hit do return true

    return false
}

get_enemy_hit :: proc(ray: rl.Ray) -> EnemyHit {
    if len(gs.level.enemies) == 0 do return {}

    // TODO: optimize, don't check everyone
    enemiesHit := make([dynamic]EnemyHit, 0, len(gs.level.enemies), context.temp_allocator)

    for &enemy in gs.level.enemies {
        hit := check_enemy_collision(enemy, ray)
        if hit {
            append(&enemiesHit, EnemyHit {
                enemy = &enemy,
                hit = hit,
                dist = rl.Vector3Distance(enemy.pos, gs.camera.position),
            })
        }
    }
    if len(enemiesHit) == 0 do return {}

    slice.sort_by(enemiesHit[:], proc(a, b: EnemyHit) -> bool {
        return a.dist < b.dist
    })
    return enemiesHit[0]
}

//enemy_hit_anim :: proc(enemy: ^Enemy) {
//    enemy.anim_frame = 1
//    enemy.hit_anim = true
//    enemy.anim_time = 0.1
//}

//enemy_death_anim :: proc(enemy: ^Enemy) {
//    // TODO: death anim is bugged
//    enemy.death_anim = true
//    enemy.anim_time = 0.1
//}
