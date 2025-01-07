package game

import rl "vendor:raylib"

Editor :: struct {
    active: bool,
    snap: bool,

    sel: union {Item, Enemy},
    sel_index: int,
}

create_editor :: proc() -> Editor {
    editor := Editor {
        snap = true,
        sel = create_item(ammo_box_cfg, {0, 0.12, 0}),
    }
    return editor
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
    if rl.IsKeyPressed(.KP_MULTIPLY) do editor.snap = !editor.snap

    switch {
    case rl.IsKeyPressed(.F5):
        save_level(gs.level)
        show_message("lavel01 saved...")
    }

    if wheel := rl.GetMouseWheelMove(); wheel != 0 {
        NUM :: 4
        editor.sel_index = (editor.sel_index + int(wheel) + NUM) % NUM

        switch editor.sel_index {
        case 0: editor.sel = create_item(clip_cfg, {0, 0.12, 0})
        case 1: editor.sel = create_item(ammo_box_cfg, {0, 0.12, 0})
        case 2: editor.sel = create_item(armor_cfg, {0, 0.12, 0})
        case 3: editor.sel = create_enemy(cobra_cfg, {0, 0.38, 0})
        }
    }
}

update_editor_item :: proc(editor: ^Editor) {
    switch &s in editor.sel {
    case Item: _update_editor_item(&s, editor.snap)
    case Enemy: _update_editor_item(&s, editor.snap)
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
