package game

import "core:slice"
import rl "vendor:raylib"

Enemy :: struct {
    tex: rl.Texture2D,
    pos: Vec3,

    dead: bool,
    hp: int,
}

Enemies :: [dynamic]Enemy

EnemyHit :: struct {
    enemy: ^Enemy,
    hit: bool,
    dist: f32,
}

draw_enemy :: proc(enemy: Enemy, opacity: u8 = 255) {
    if enemy.dead do return
    rl.DrawBillboard(gs.camera, enemy.tex, enemy.pos, 0.75, {255, 255, 255, opacity})

//    bodyPos := enemy.pos
//    body := rl.BoundingBox {
//        min = bodyPos - {0.18, 0.33, 0.18},
//        max = bodyPos + {0.18, 0.33, 0.18},
//    }
//    rl.DrawBoundingBox(body, rl.MAROON)
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
