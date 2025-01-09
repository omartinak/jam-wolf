package game

pistol_cfg := Weapon_Cfg {
    anim = {
        .Idle = { tex = {.Pistol01}, time = 0, transition = .Idle, },
        .Fire = { tex = {.Pistol01, .Pistol02, .Pistol03}, time = 0.05, transition = .Idle, },
    },
    x_off = 0,
    damage = 5,
    owned = true,
}

rifle_cfg := Weapon_Cfg {
    anim = {
        .Idle = { tex = {.Rifle01}, time = 0, transition = .Idle, },
        .Fire = { tex = {.Rifle01, .Rifle02, .Rifle03}, time = 0.05, transition = .Idle, },
    },
    x_off = 2,
    damage = 5,
    owned = false,
}

machinegun_cfg := Weapon_Cfg {
    anim = {
        .Idle = { tex = {.Machine_Gun01}, time = 0, transition = .Idle, },
        .Fire = { tex = {.Machine_Gun01, .Machine_Gun02, .Machine_Gun03}, time = 0.05, transition = .Idle, },
    },
    x_off = -1,
    damage = 10,
    owned = false,
}

blood_splash_cfg := Hit_Splash_Cfg {
    anim = {
        .Splash = { tex = {.Blood0, .Blood1, .Blood2, .Blood3, .Blood4}, time = 0.05, },
    },
    color = {200, 0, 0, 255},
}

enemy_cfg := [Enemy_Type]Enemy_Cfg {
    .Cobra = {
        anim = {
            .Idle = { tex = {.Cobra0}, time = 0, transition = .Idle, },
            .Move = { tex = {.Cobra0, .Cobra1, .Cobra2}, time = 0.1, transition = .Idle, },
            .Hit = { tex = {.Cobra_Hit0}, time = 0.1, transition = .Idle, },
            .Attack_Left = { tex = {.Cobra_Att0, .Cobra_Att2}, time = 0.1, transition = .Idle, },
            .Attack_Right = { tex = {.Cobra_Att0, .Cobra_Att1}, time = 0.1, transition = .Idle, },
            .Death = { tex = {.Cobra_Hit0, .Cobra_Hit1, .Cobra_Hit2, .Cobra_Hit3, .Cobra_Hit4}, time = 0.1, },
        },
        speed = 1,
        col_radius = 0.25,
        hit_radius = 0.18,
        half_height = 0.33,
        hp = 20,
        y_off = 0.38,
        type = .Cobra,
    },
}

// TODO: union add ammo, armor, hp
item_cfg := [Item_Type]Item_Cfg {
    .Pistol = {
        tex = .Pistol,
        col_radius = 0.3,
        half_height = 0.15,
        y_off = 0.12,
        type = .Pistol,
    },
    .Rifle = {
        tex = .Rifle,
        col_radius = 0.3,
        half_height = 0.15,
        y_off = 0.12,
        type = .Rifle,
    },
    .Machine_Gun = {
        tex = .Machine_Gun,
        col_radius = 0.3,
        half_height = 0.15,
        y_off = 0.12,
        type = .Machine_Gun,
    },
    .Clip = {
        tex = .Clip,
        col_radius = 0.3,
        half_height = 0.15,
        y_off = 0.12,
        type = .Clip,
    },
    .Ammo_Box = {
        tex = .Ammo_Box,
        col_radius = 0.3,
        half_height = 0.15,
        y_off = 0.12,
        type = .Ammo_Box,
    },
    .Armor = {
        tex = .Armor,
        col_radius = 0.3,
        half_height = 0.15,
        y_off = 0.12,
        type = .Armor,
    },
    .Health = {
        tex = .Health,
        col_radius = 0.3,
        half_height = 0.15,
        y_off = 0.12,
        type = .Health,
    },
    .Exit = {
        tex = .Brain,
        col_radius = 0.3,
        half_height = 0.15,
        y_off = 0.12,
        type = .Exit,
    },
}
