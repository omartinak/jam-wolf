package game

import rl "vendor:raylib"

Tex :: enum {
    Level01_Atlas,
    Level01,

    Pistol01, Pistol02, Pistol03,
    Rifle01, Rifle02, Rifle03,
    Machine_Gun01, Machine_Gun02, Machine_Gun03,

    Pistol, Rifle, Machine_Gun,
    Clip, Ammo_Box, Armor, Brain, Health,

    Blood0, Blood1, Blood2, Blood3, Blood4,

    Cobra0, Cobra1, Cobra2,
    Cobra_Att0, Cobra_Att1, Cobra_Att2,
    Cobra_Hit0, Cobra_Hit1, Cobra_Hit2, Cobra_Hit3, Cobra_Hit4,

    Blood_Overlay,
}

Textures :: [Tex]rl.Texture2D

create_textures :: proc() -> Textures {
    textures := Textures {
        .Level01_Atlas = rl.LoadTexture("data/graphics/walls.png"),
        .Level01 = rl.LoadTexture("data/levels/level01.png"),

        .Pistol01 = rl.LoadTexture("data/graphics/lab/guns/gun2.png"),
        .Pistol02 = rl.LoadTexture("data/graphics/lab/guns/gun2b.png"),
        .Pistol03 = rl.LoadTexture("data/graphics/lab/guns/gun2c.png"),

        .Rifle01 = rl.LoadTexture("data/graphics/lab/guns/gun5a.png"),
        .Rifle02 = rl.LoadTexture("data/graphics/lab/guns/gun5b.png"),
        .Rifle03 = rl.LoadTexture("data/graphics/lab/guns/gun5c.png"),

        .Machine_Gun01 = rl.LoadTexture("data/graphics/lab/guns/gun1a.png"),
        .Machine_Gun02 = rl.LoadTexture("data/graphics/lab/guns/gun1b.png"),
        .Machine_Gun03 = rl.LoadTexture("data/graphics/lab/guns/gun1c.png"),

        .Pistol = rl.LoadTexture("data/graphics/lab/sprites/i_pistol.png"),
        .Rifle = rl.LoadTexture("data/graphics/lab/sprites/i_rifle.png"),
        .Machine_Gun = rl.LoadTexture("data/graphics/lab/sprites/i_nuker.png"),

        .Clip = rl.LoadTexture("data/graphics/lab/sprites/i_clip.png"),
        .Ammo_Box = rl.LoadTexture("data/graphics/lab/sprites/i_ammobox.png"),
        .Armor = rl.LoadTexture("data/graphics/lab/sprites/i_armor.png"),
        .Brain = rl.LoadTexture("data/graphics/lab/sprites/brain.png"),
        .Health = rl.LoadTexture("data/graphics/lab/sprites/i_health.png"),

        .Blood0 = rl.LoadTexture("data/graphics/lab/sprites/bloodspr_0.png"),
        .Blood1 = rl.LoadTexture("data/graphics/lab/sprites/bloodspr_1.png"),
        .Blood2 = rl.LoadTexture("data/graphics/lab/sprites/bloodspr_2.png"),
        .Blood3 = rl.LoadTexture("data/graphics/lab/sprites/bloodspr_3.png"),
        .Blood4 = rl.LoadTexture("data/graphics/lab/sprites/bloodspr_4.png"),

        .Cobra0 = rl.LoadTexture("data/graphics/lab/sprites/cobra0.png"),
        .Cobra1 = rl.LoadTexture("data/graphics/lab/sprites/cobra1.png"),
        .Cobra2 = rl.LoadTexture("data/graphics/lab/sprites/cobra2.png"),
        .Cobra_Att0 = rl.LoadTexture("data/graphics/lab/sprites/cobraatt0.png"),
        .Cobra_Att1 = rl.LoadTexture("data/graphics/lab/sprites/cobraatt1.png"),
        .Cobra_Att2 = rl.LoadTexture("data/graphics/lab/sprites/cobraatt2.png"),
        .Cobra_Hit0 = rl.LoadTexture("data/graphics/lab/sprites/cobrahit0.png"),
        .Cobra_Hit1 = rl.LoadTexture("data/graphics/lab/sprites/cobrahit1.png"),
        .Cobra_Hit2 = rl.LoadTexture("data/graphics/lab/sprites/cobrahit2.png"),
        .Cobra_Hit3 = rl.LoadTexture("data/graphics/lab/sprites/cobrahit3.png"),
        .Cobra_Hit4 = rl.LoadTexture("data/graphics/lab/sprites/cobrahit4.png"),

        .Blood_Overlay = rl.LoadTexture("data/graphics/blood_overlay.png"),
    }
    return textures
}

destroy_textures :: proc(textures: Textures) {
    for tex in textures do rl.UnloadTexture(tex)
}
