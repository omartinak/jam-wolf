package game

import "core:slice"
import rl "vendor:raylib"

Enemy :: struct {
    frames: [6]rl.Texture2D,
    pos: Vec3,

    dead: bool,
    hp: int,

    hit_anim: bool,
    death_anim: bool,
    anim_frame: int,
    anim_time: f32,
}

Enemies :: [dynamic]Enemy

EnemyHit :: struct {
    enemy: ^Enemy,
    hit: bool,
    dist: f32,
}

draw_enemy :: proc(enemy: Enemy, opacity: u8 = 255) {
    frame := enemy.frames[enemy.anim_frame]
    rl.DrawBillboard(gs.camera, frame, enemy.pos, 0.75, {255, 255, 255, opacity})

//    bodyPos := enemy.pos
//    body := rl.BoundingBox {
//        min = bodyPos - {0.18, 0.33, 0.18},
//        max = bodyPos + {0.18, 0.33, 0.18},
//    }
//    rl.DrawBoundingBox(body, rl.MAROON)
}

update_enemy :: proc(enemy: ^Enemy, dt: f32) {
    if enemy.hit_anim {
        enemy.anim_time -= dt
        if enemy.anim_time <= 0 {
            enemy.anim_frame = 0
            enemy.hit_anim = false
        }
    }

    if enemy.death_anim {
        enemy.anim_time -= dt
        if enemy.anim_time <= 0 {
            if enemy.anim_frame < len(enemy.frames)-1 {
                enemy.anim_frame += 1
                enemy.anim_time = 0.1
            } else {
                enemy.death_anim = false
            }
        }
    }
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

enemy_hit_anim :: proc(enemy: ^Enemy) {
    enemy.anim_frame = 1
    enemy.hit_anim = true
    enemy.anim_time = 0.1
}

enemy_death_anim :: proc(enemy: ^Enemy) {
    enemy.death_anim = true
    enemy.anim_time = 0.1
}
