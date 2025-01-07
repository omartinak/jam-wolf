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
    velocity: Vec3,
    col_radius: f32,
    hit_radius: f32,

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
}

Enemy_Cfg :: struct {
    anim: [Enemy_Anim]Anim_Cfg(Enemy_Anim),
    col_radius: f32,
    hit_radius: f32,
    hp: int,
}

Enemies :: [dynamic]Enemy

EnemyHit :: struct {
    enemy: ^Enemy,
    hit: bool,
    dist: f32,
}

create_enemy :: proc(cfg: Enemy_Cfg, pos: Vec3) -> Enemy {
    enemy := Enemy {
        anim = create_anim(cfg.anim),
        pos = pos,
        col_radius = cfg.col_radius,
        hit_radius = cfg.hit_radius,
        hp = cfg.hp,
    }
    return enemy
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
        enemy_path(enemy) // TODO

        switch enemy.action {
        case .Idle:
            if enemy.action_time <= 0 {
//                enemy_roam(enemy)
//                enemy_path(enemy)
                enemy.action = .Move
            }
        case .Move:
            if rl.Vector3DistanceSqrt(enemy.pos, enemy.dest) < 0.2 {
                rnd := rl.GetRandomValue(1, 10)
                switch rnd {
//                case 1..=2:
//                    enemy.action_time = 1
//                    enemy.action = .Idle

                case:
//                    enemy_roam(enemy)
//                    enemy_path(enemy)
                }
            } else {
                SPEED :: 0.5

                dir := rl.Vector2Normalize((enemy.dest - enemy.pos).xz)
                enemy.velocity = {dir.x, 0, dir.y} * SPEED * dt
                enemy.pos += enemy.velocity

                // TODO: use pathfinding instead of sliding and save performance
                slide(&enemy.pos, &enemy.velocity, enemy.col_radius)

                dbg_print(2, "%.2f", enemy.velocity)
                dbg_print(3, "dest %v", enemy.dest)

                // TODO: stagger when hit
                if enemy.anim.cur_anim == .Idle do play_anim(&enemy.anim, Enemy_Anim.Move)
            }
        }
    }
    update_anim(&enemy.anim, dt)
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

enemy_path :: proc(enemy: ^Enemy) {
    bfs(enemy.pos, gs.player.pos, &enemy.nav_data)
    if len(enemy.nav_data.path) < 2 do return

    dx := f32(enemy.nav_data.path[1].x)
    dz := f32(enemy.nav_data.path[1].y)
    enemy.dest = {dx, 0, dz} + {0.5, 0, 0.5} // Go to the middle of a tile
//    fmt.println(enemy.nav_data.path)
}

check_enemy_collision :: proc(enemy: Enemy, ray: rl.Ray, check_dead := false) -> bool {
    if !check_dead && enemy.dead do return {}

    bodyPos := enemy.pos
    body := rl.BoundingBox {
        min = bodyPos - {enemy.hit_radius, 0.33, enemy.hit_radius},
        max = bodyPos + {enemy.hit_radius, 0.33, enemy.hit_radius},
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
