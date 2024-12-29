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
        cur_item = Item {
            tex = gs.textures["ammobox"],
            pos = {0, 0.2, 0},
            type = .Ammo_Box,
        },
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
        save_level("data/levels/level01.json", gs.level)
        show_message("lavel01 saved...")
    }

    if wheel := rl.GetMouseWheelMove(); wheel != 0 {
        NUM :: 4
        editor.cur_item_index = (editor.cur_item_index + int(wheel) + NUM) % NUM
        switch editor.cur_item_index {
        case 0:
            editor.cur_item = Item {
                tex = gs.textures["clip"],
                pos = {0, 0.2, 0},
                type = .Clip,
            }
        case 1:
            editor.cur_item = Item {
                tex = gs.textures["ammobox"],
                pos = {0, 0.2, 0},
                type = .Ammo_Box,
            }
        case 2:
            editor.cur_item = Item {
                tex = gs.textures["armor"],
                pos = {0, 0.2, 0},
                type = .Armor,
            }
        case 3:
            editor.cur_item = Enemy {
                tex = gs.textures["cobra0"],
                pos = {0, 0.38, 0},
                hp = 20,
            }
        }
    }
}

update_editor :: proc(editor: ^Editor) {
    switch &i in editor.cur_item {
    case Item:  i.pos.xz = gs.camera.target.xz
    case Enemy: i.pos.xz = gs.camera.target.xz
    }
//    if editor.snap {
//        editor.cur_item.pos.x = f32(int(editor.cur_item.pos.x+1))
//        editor.cur_item.pos.z = f32(int(editor.cur_item.pos.z))
//    }
//    dbg_print(1, "item: %0.2f", editor.cur_item.pos)
}
