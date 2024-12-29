package game

import rl "vendor:raylib"

// TODO: replace with enum array
Textures :: map[string]rl.Texture2D

create_textures :: proc() -> Textures {
    textures := Textures {
        "level01_atlas" = rl.LoadTexture("data/graphics/walls.png"),
        "level01" = rl.LoadTexture("data/levels/level01.png"),
        "gun1" = rl.LoadTexture("data/graphics/lab/guns/gun1a.png"),
        "gun2" = rl.LoadTexture("data/graphics/lab/guns/gun2.png"),
        "gun2b" = rl.LoadTexture("data/graphics/lab/guns/gun2b.png"),
        "gun2c" = rl.LoadTexture("data/graphics/lab/guns/gun2c.png"),
        "gun4" = rl.LoadTexture("data/graphics/lab/guns/gun4.png"),
        "gun5" = rl.LoadTexture("data/graphics/lab/guns/gun5a.png"),
        "clip" = rl.LoadTexture("data/graphics/lab/sprites/i_clip.png"),
        "ammobox" = rl.LoadTexture("data/graphics/lab/sprites/i_ammobox.png"),
        "armor" = rl.LoadTexture("data/graphics/lab/sprites/i_armor.png"),

        "cobra0" = rl.LoadTexture("data/graphics/lab/sprites/cobra0.png"),
    }
    return textures
}

destroy_textures :: proc(textures: Textures) {
    for _, tex in textures do rl.UnloadTexture(tex)
    delete(textures)
}
