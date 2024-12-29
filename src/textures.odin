package game

import rl "vendor:raylib"

// TODO: replace with enum array
Textures :: map[string]rl.Texture2D

create_textures :: proc() -> Textures {
    textures := Textures {
        "level01_atlas" = rl.LoadTexture("data/graphics/walls.png"),
        "level01" = rl.LoadTexture("data/levels/level01.png"),

        "pistol01" = rl.LoadTexture("data/graphics/lab/guns/gun2.png"),
        "pistol02" = rl.LoadTexture("data/graphics/lab/guns/gun2b.png"),
        "pistol03" = rl.LoadTexture("data/graphics/lab/guns/gun2c.png"),

        "rifle01" = rl.LoadTexture("data/graphics/lab/guns/gun5a.png"),
        "rifle02" = rl.LoadTexture("data/graphics/lab/guns/gun5b.png"),
        "rifle03" = rl.LoadTexture("data/graphics/lab/guns/gun5c.png"),

        "machinegun01" = rl.LoadTexture("data/graphics/lab/guns/gun1a.png"),
        "machinegun02" = rl.LoadTexture("data/graphics/lab/guns/gun1b.png"),
        "machinegun03" = rl.LoadTexture("data/graphics/lab/guns/gun1c.png"),

        "nuker01" = rl.LoadTexture("data/graphics/lab/guns/gun4.png"),
        "nuker02" = rl.LoadTexture("data/graphics/lab/guns/gun4b.png"),
        "nuker03" = rl.LoadTexture("data/graphics/lab/guns/gun4c.png"),

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
