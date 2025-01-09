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
    ammo: int,

    hit_splashes: [dynamic]Hit_Splash,

    goals: [dynamic]Ai_Goal,
    cur_goal: Maybe(Ai_Goal),
    dist: f32,
    dest: Vec3,
    dest_ammo: Maybe(Vec3),

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
    point: Vec3,
    dist: f32,
}

create_enemy :: proc(cfg: Enemy_Cfg, pos: Vec3) -> Enemy {
    enemy := Enemy {
        pos = pos,
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
    for hit_splash in enemy.hit_splashes do destroy_hit_splash(hit_splash)
    delete(enemy.hit_splashes)
}

draw_enemy :: proc(enemy: Enemy, opacity: u8 = 255) {
    frame := get_anim_frame(enemy.anim)
    rl.DrawBillboard(gs.camera, frame, enemy.pos, 0.75, {255, 255, 255, opacity})

    for hit_splash in enemy.hit_splashes {
        draw_hit_splash(hit_splash)
    }

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
        // TODO: this is brittle
        //       ai data is deallocated every frame by temp_allocator
        //       if enemy_ai is not called every frame crashes happen
        //       because for example dbg uses the data
        enemy_ai(enemy, dt)
    }
    update_anim(&enemy.anim, dt)

    // TODO: hit_splash position should be moved together with enemy
    //       it sort of works without it because hit_splash is drawn after enenmy
    for &hit_splash, i in enemy.hit_splashes {
        update_hit_splash(&hit_splash, dt)

        if !hit_splash.anim.playing {
            destroy_hit_splash(hit_splash)
            // TODO: unordered_remove is bad? will skip swapped anim?
            unordered_remove(&enemy.hit_splashes, i)
        }
    }
}

check_enemy_collision :: proc(enemy: Enemy, ray: rl.Ray, check_dead := false) -> (bool, Vec3) {
    if !check_dead && enemy.dead do return false, {}

    bodyPos := enemy.pos
    body := rl.BoundingBox {
        min = bodyPos - {enemy.hit_radius, enemy.half_height, enemy.hit_radius},
        max = bodyPos + {enemy.hit_radius, enemy.half_height, enemy.hit_radius},
    }

    colBody := rl.GetRayCollisionBox(ray, body)
    if colBody.hit do return true, colBody.point

    return false, {}
}

get_enemy_hit :: proc(ray: rl.Ray, check_dead := false) -> EnemyHit {
    if len(gs.level.enemies) == 0 do return {}

    // TODO: optimize, don't check everyone
    // TODO: slice instead of dynamic array? probably not, we don't know how many we hit
    enemiesHit := make([dynamic]EnemyHit, 0, len(gs.level.enemies), context.temp_allocator)

    for &enemy in gs.level.enemies {
        hit, point := check_enemy_collision(enemy, ray, check_dead)
        if hit {
            append(&enemiesHit, EnemyHit {
                enemy = &enemy,
                hit = hit,
                point = point,
                dist = rl.Vector3Distance(enemy.pos, gs.camera.position),
            })
        }
    }
    if len(enemiesHit) == 0 do return {}

    slice.sort_by(enemiesHit[:], proc(a, b: EnemyHit) -> bool {
        return a.dist < b.dist
    })
    hit := enemiesHit[0]

    // Fake (only visual) spread
    spread := Vec3 {
        f32(rl.GetRandomValue(-10, 10)) / 300,
        f32(rl.GetRandomValue(-10, 10)) / 300,
        f32(rl.GetRandomValue(-10, 10)) / 300,
    }
    append(&hit.enemy.hit_splashes, create_hit_splash(blood_splash_cfg, hit.point + spread))

    return hit
}

deal_damage :: proc(enemy: ^Enemy, dmg: int) {
    enemy.hp -= dmg

    if enemy.hp > 0 {
        play_anim(&enemy.anim, Enemy_Anim.Hit)
    } else {
        enemy.dead = true
        play_anim(&enemy.anim, Enemy_Anim.Death)

        // TODO: not ideal
        enemy.goals = nil
        enemy.cur_goal = nil
        enemy.dest_ammo = nil
    }
}
