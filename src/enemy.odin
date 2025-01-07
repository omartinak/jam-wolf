package game

import "core:slice"
import rl "vendor:raylib"

Enemy_Type :: enum {
    Cobra,
}

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
    pos: Vec3,
    velocity: Vec3,

    anim: Anim(Enemy_Anim),

    col_radius: f32,
    hit_radius: f32,
    half_height: f32,

    dead: bool,
    hp: int,

    hit_anim: bool,
    death_anim: bool,
    anim_frame: int,
    anim_time: f32,

    action: Enemy_Action,
    action_time: f32,
    dest: Vec3,

    nav_data: Nav_Data,

    type: Enemy_Type, // TODO: replace
}

Enemy_Cfg :: struct {
    anim: [Enemy_Anim]Anim_Cfg(Enemy_Anim),
    col_radius: f32,
    hit_radius: f32,
    half_height: f32,
    hp: int,
    y_off: f32,
    type: Enemy_Type, // TODO: replace
}

Enemies :: [dynamic]Enemy

EnemyHit :: struct {
    enemy: ^Enemy,
    hit: bool,
    dist: f32,
}

create_enemy :: proc(cfg: Enemy_Cfg, pos: Vec3) -> Enemy {
    enemy := Enemy {
        pos = pos + {0, cfg.y_off, 0},
        anim = create_anim(cfg.anim),
        col_radius = cfg.col_radius,
        hit_radius = cfg.hit_radius,
        half_height = cfg.half_height,
        hp = cfg.hp,
        type = cfg.type,
    }
    return enemy
}

destroy_enemy :: proc(enemy: Enemy) {
    destroy_anim(enemy.anim)
}

draw_enemy :: proc(enemy: Enemy, opacity: u8 = 255) {
    frame := get_anim_frame(enemy.anim)
    rl.DrawBillboard(gs.camera, frame, enemy.pos, 0.75, {255, 255, 255, opacity})

    if gs.dbg.show_bbox {
        bodyPos := enemy.pos
        body := rl.BoundingBox {
            min = bodyPos - {enemy.hit_radius, enemy.half_height, enemy.hit_radius},
            max = bodyPos + {enemy.hit_radius, enemy.half_height, enemy.hit_radius},
        }
        rl.DrawBoundingBox(body, rl.MAROON)
    }
}

update_enemy :: proc(enemy: ^Enemy, dt: f32) {
    if !enemy.dead {
        enemy_ai(enemy, dt)
    }
    update_anim(&enemy.anim, dt)
}

check_enemy_collision :: proc(enemy: Enemy, ray: rl.Ray, check_dead := false) -> bool {
    if !check_dead && enemy.dead do return {}

    bodyPos := enemy.pos
    body := rl.BoundingBox {
        min = bodyPos - {enemy.hit_radius, enemy.half_height, enemy.hit_radius},
        max = bodyPos + {enemy.hit_radius, enemy.half_height, enemy.hit_radius},
    }

    colBody := rl.GetRayCollisionBox(ray, body)
    if colBody.hit do return true

    return false
}

get_enemy_hit :: proc(ray: rl.Ray, check_dead := false) -> EnemyHit {
    if len(gs.level.enemies) == 0 do return {}

    // TODO: optimize, don't check everyone
    enemiesHit := make([dynamic]EnemyHit, 0, len(gs.level.enemies), context.temp_allocator)

    for &enemy in gs.level.enemies {
        hit := check_enemy_collision(enemy, ray, check_dead)
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
