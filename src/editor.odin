package game

import rl "vendor:raylib"

Editor :: struct {
    active: bool,
    snap: bool,

    sel: union {Item, Enemy},
    sel_index: int,
    pointed: union {^Item, ^Enemy},
}

create_editor :: proc() -> Editor {
    editor := Editor {
        snap = true,
        sel = create_item(item_cfg[.Ammo_Box], {0, item_cfg[.Ammo_Box].y_off, 0}),
    }
    return editor
}

highlight_item :: proc(item: $Actor) {
    bodyPos := item.pos
    body := rl.BoundingBox {
        min = bodyPos - {item.col_radius, item.half_height, item.col_radius},
        max = bodyPos + {item.col_radius, item.half_height, item.col_radius},
    }
    rl.DrawBoundingBox(body, rl.ORANGE)
}

draw_editor :: proc(editor: Editor) {
    switch p in editor.pointed {
    case ^Item: highlight_item(p)
    case ^Enemy: highlight_item(p)
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
        switch s in editor.sel {
        case Item:  append(&gs.level.items, s)
        case Enemy: append(&gs.level.enemies, s)
        }
    }
    if rl.IsMouseButtonPressed(.RIGHT) {
        switch p in editor.pointed {
        case ^Item:
            for &item, i in gs.level.items {
                if &item == p do ordered_remove(&gs.level.items, i)
            }
        case ^Enemy:
            for &enemy, i in gs.level.enemies {
                if &enemy == p do ordered_remove(&gs.level.enemies, i)
            }
        }
    }
    if rl.IsKeyPressed(.KP_MULTIPLY) do editor.snap = !editor.snap

    switch {
    case rl.IsKeyPressed(.F5):
        save_level(gs.level)
        show_message("Level saved...")
    }

    if wheel := rl.GetMouseWheelMove(); wheel != 0 {
        NUM :: 5
        editor.sel_index = (editor.sel_index + int(wheel) + NUM) % NUM

        switch editor.sel_index {
        case 0: editor.sel = create_item(item_cfg[.Clip], {0, item_cfg[.Clip].y_off, 0})
        case 1: editor.sel = create_item(item_cfg[.Ammo_Box], {0, item_cfg[.Ammo_Box].y_off, 0})
        case 2: editor.sel = create_item(item_cfg[.Armor], {0, item_cfg[.Armor].y_off, 0})
        case 3: editor.sel = create_item(item_cfg[.Exit], {0, item_cfg[.Exit].y_off, 0})
        case 4: editor.sel = create_enemy(enemy_cfg[.Cobra], {0, enemy_cfg[.Cobra].y_off, 0})
        }
    }
}

update_editor_item :: proc(editor: ^Editor) {
    switch &s in editor.sel {
    case Item: _update_editor_item(&s, editor.snap)
    case Enemy: _update_editor_item(&s, editor.snap)
    }

    // TODO: use raycast instead
    editor.pointed = nil
    for &item in gs.level.items {
        if rl.Vector3Distance(item.pos, gs.camera.target) < item.col_radius {
            editor.pointed = &item
            break
        }
    }
    for &enemy in gs.level.enemies {
        if rl.Vector3Distance(enemy.pos, gs.camera.target) < enemy.col_radius {
            editor.pointed = &enemy
            break
        }
    }
}

@(private="file")
_update_editor_item :: proc(item: ^$Actor, snap: bool) {
    item.pos.xz = gs.camera.target.xz
    if snap {
        item.pos.x = f32(int(item.pos.x)) + 0.5
        item.pos.z = f32(int(item.pos.z)) + 0.5
    }
}
