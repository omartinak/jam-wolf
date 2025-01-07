package game

import rl "vendor:raylib"

Editor :: struct {
    active: bool,
    snap: bool,

    cur_item: union {Item, Enemy},
    cur_item_index: int,
}

init_editor :: proc() -> Editor {
    editor := Editor {
        snap = true,
        cur_item = create_item(ammo_box_cfg, {0, 0.12, 0}),
    }
    return editor
}

draw_editor :: proc(editor: Editor) {
    if editor.active {
        switch i in editor.cur_item {
        case Item:  draw_item(i, opacity = 128)
        case Enemy: draw_enemy(i, opacity = 128)
        }
    }
}

draw_editor_hud ::proc(editor: Editor) {
    if editor.active {
        rc := rl.Rectangle{0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
        rl.DrawRectangleLinesEx(rc, 2, rl.ORANGE)
    }
}

update_editor_input :: proc(editor: ^Editor) {
    if rl.IsMouseButtonPressed(.LEFT) {
        switch i in editor.cur_item {
        case Item:  append(&gs.level.items, i)
        case Enemy: append(&gs.level.enemies, i)
        }
    }

    switch {
    case rl.IsKeyPressed(.F5):
        save_level(gs.level)
        show_message("lavel01 saved...")
    }

    if wheel := rl.GetMouseWheelMove(); wheel != 0 {
        NUM :: 4
        editor.cur_item_index = (editor.cur_item_index + int(wheel) + NUM) % NUM
        switch editor.cur_item_index {
        case 0: editor.cur_item = create_item(clip_cfg, {0, 0.12, 0})
        case 1: editor.cur_item = create_item(ammo_box_cfg, {0, 0.12, 0})
        case 2: editor.cur_item = create_item(armor_cfg, {0, 0.12, 0})
        case 3:
            editor.cur_item = Enemy {
                // TODO: replace with cfg
                anim = create_anim(cobra_anim_cfg),
                pos = {0, 0.38, 0},
                col_radius = 0.25,
                hit_radius = 0.18,
                hp = 20,
            }
        }
    }
}

update_editor_item :: proc(editor: ^Editor) {
    // TODO: fix unions
    switch &i in editor.cur_item {
    case Item:  i.pos.xz = gs.camera.target.xz
    case Enemy: i.pos.xz = gs.camera.target.xz
    }

    if editor.snap {
        switch &i in editor.cur_item {
        case Item:
            i.pos.x = f32(int(i.pos.x)) + 0.5
            i.pos.z = f32(int(i.pos.z)) + 0.5
        case Enemy:
            i.pos.x = f32(int(i.pos.x)) + 0.5
            i.pos.z = f32(int(i.pos.z)) + 0.5
        }
    }
}
