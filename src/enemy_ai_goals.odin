package game

import "core:slice"
import rl "vendor:raylib"

Ai_Goal :: struct {
    name: string,
    precond: proc(enemy: ^Enemy) -> bool,
    execute: proc(enemy: ^Enemy, dt: f32),
    score: f32,
}

ai_goals := [?]Ai_Goal {
    {
        name = "Idle",
        precond = can_idle,
        execute = idle,
        score = 0.1,
    },
    {
        name = "Go to Last Known Location",
        precond = can_lkl,
        execute = lkl,
        score = 0.2,
    },
    {
        name = "Get Ammo",
        precond = can_get_ammo,
        execute = get_ammo,
        score = 0.3,
    },
    {
        name = "Go to Attack Position",
        precond = can_attack_position,
        execute = attack_position,
        score = 0.6,
    },
    {
        name = "Attack",
        precond = can_attack,
        execute = attack,
        score = 1.0,
    },
    // TODO: hit react - stagger
    // TODO: roam
}

get_applicable_goals :: proc(enemy: ^Enemy) -> [dynamic]Ai_Goal {
    goals := make([dynamic]Ai_Goal, context.temp_allocator)

    for goal in ai_goals {
        if goal.precond(enemy) do append(&goals, goal)
    }

    // TODO: randomize if same score
    slice.sort_by(goals[:], proc(a, b: Ai_Goal) -> bool {
        return a.score > b.score
    })

    return goals
}

can_idle :: proc(enemy: ^Enemy) -> bool {
    return true
}

can_get_ammo :: proc(enemy: ^Enemy) -> bool {
    if enemy.ammo > 0 do return false

    ammo := make([dynamic]^Item, context.temp_allocator)
    for &item in gs.level.items {
        // TODO: Clip and prio
        if item.type == .Ammo_Box {
            append(&ammo, &item)
        }
    }
    if len(ammo) == 0 do return false

    @(static) enemy_pos: Vec3
    enemy_pos = enemy.pos

    // TODO: what if multiple enemies select the same ammo_box?
    //       smart objects - claim
    //       claim smart - every enemy should select closest ammo, not first come first serve
    // TODO: doesn't work?
    slice.sort_by(ammo[:], proc(a, b: ^Item) -> bool {
        a_dist := rl.Vector3DistanceSqrt(enemy_pos, a.pos)
        b_dist := rl.Vector3DistanceSqrt(enemy_pos, b.pos)
        return a_dist < b_dist
    })
    enemy.dest_ammo = ammo[0]

    return true
}

can_attack_position :: proc(enemy: ^Enemy) -> bool {
    sees_player := rl.Vector3Distance(enemy.pos, gs.player.pos) < 7
    has_ammo := enemy.ammo > 0
    return sees_player && has_ammo
}

can_lkl :: proc(enemy: ^Enemy) -> bool {
    has_ammo := enemy.ammo > 0
    return enemy.last_pos != nil && has_ammo
}

can_attack :: proc(enemy: ^Enemy) -> bool {
    // TODO: line of sight check
    dist := rl.Vector3Distance(enemy.pos, gs.player.pos)
//    in_position := dist >= 2 && dist <= 4
    in_position := dist <= 4
    has_ammo := enemy.ammo > 0
//    timeout := enemy.attack_time <= 0

//    return in_position && has_ammo && timeout
    return in_position && has_ammo
}

idle :: proc(enemy: ^Enemy, dt: f32) {
//    enemy.cur_goal = nil // TODO
    // Not visibile in current goal, needs proper interrupt
//    return true
//    return can_idle(enemy) // always true
}

get_ammo :: proc(enemy: ^Enemy, dt: f32) {
    if dest_ammo, ok := enemy.dest_ammo.?; ok {
        enemy_path(enemy, dest_ammo.pos)

        if rl.Vector3DistanceSqrt(enemy.pos, dest_ammo.pos) < 0.5 {
            enemy.ammo += 5
            // TODO: what if the item is not valid anymore - items array has changed?
            //       generation handle?
            for &item, i in gs.level.items {
                if &item == dest_ammo {
                    unordered_remove(&gs.level.items, i)
                    break
                }
            }
            enemy.dest_ammo = nil
        } else {
            dir := rl.Vector2Normalize((enemy.dest - enemy.pos).xz)
            enemy.velocity = {dir.x, 0, dir.y} * enemy.speed * dt
            enemy.pos += enemy.velocity

            // TODO: use pathfinding instead of sliding and save performance
            slide(&enemy.pos, &enemy.velocity, enemy.col_radius)

//            dbg_print(2, "%.2f", enemy.velocity)
//            dbg_print(3, "dest %v", enemy.dest)

            // TODO: stagger when hit
            if enemy.anim.cur_anim == .Idle do play_anim(&enemy.anim, Enemy_Anim.Move)
        }
    }
}

lkl :: proc(enemy: ^Enemy, dt: f32) {
    // TODO: set last pos when sees player
    if last_pos, ok := enemy.last_pos.?; ok {
        enemy_path(enemy, last_pos)

        // TODO: loose target, lkl
        // TODO: configurable tolerance, snap to final pos?
        // TODO: magically getting ammo?
        if rl.Vector3Distance(enemy.pos, last_pos) > 0.5 {
            dir := rl.Vector2Normalize((enemy.dest - enemy.pos).xz)
            enemy.velocity = {dir.x, 0, dir.y} * enemy.speed * dt
            enemy.pos += enemy.velocity

            // TODO: use pathfinding instead of sliding and save performance
            slide(&enemy.pos, &enemy.velocity, enemy.col_radius)

            //            dbg_print(2, "%.2f", enemy.velocity)
            //            dbg_print(3, "dest %v", enemy.dest)

            // TODO: stagger when hit
            if enemy.anim.cur_anim == .Idle do play_anim(&enemy.anim, Enemy_Anim.Move)
        } else {
            enemy.last_pos = nil
        }
    }
}

// TODO:
//   enemy shoot projectiles
//   enemy drop remaining ammo
//   alert when hurt - maybe
//   see long distance, but line of sight
//   noise alert
//   enemies shoot projectiles
//   debug - show all enemies on map, change color based on state - idle, attack pos, attack
//     los - bresenham
//     noise - flood fill with limited depth
//   player death - fall down
//   player hit - red vignette

attack_position :: proc(enemy: ^Enemy, dt: f32) {
    enemy_path(enemy, gs.player.pos)

    if rl.Vector3Distance(enemy.pos, gs.player.pos) > 4 {
        dir := rl.Vector2Normalize((enemy.dest - enemy.pos).xz)
        enemy.velocity = {dir.x, 0, dir.y} * enemy.speed * dt
        enemy.pos += enemy.velocity

        // TODO: use pathfinding instead of sliding and save performance
        slide(&enemy.pos, &enemy.velocity, enemy.col_radius)

        //            dbg_print(2, "%.2f", enemy.velocity)
        //            dbg_print(3, "dest %v", enemy.dest)

        // TODO: stagger when hit
        if enemy.anim.cur_anim == .Idle do play_anim(&enemy.anim, Enemy_Anim.Move)
    }
    set_last_pos(enemy, gs.player.pos)
}

attack :: proc(enemy: ^Enemy, dt: f32) {
    // TODO: lesser chance to hit if the player is moving, maybe based on velocity
    if enemy.attack_time <= 0 {
        damage_player(&gs.player, 5)
        enemy.ammo -= 1

        play_anim(&enemy.anim, enemy.cobra_attack == .Left ? Enemy_Anim.Attack_Left : Enemy_Anim.Attack_Right)

        // TODO: last pos when seen?
        set_last_pos(enemy, gs.player.pos)
        enemy.cobra_attack = enemy.cobra_attack == .Left ? .Right : .Left
        enemy.attack_time = 1
    }
}
