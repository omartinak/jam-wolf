package game

pistol_cfg := Weapon_Cfg {
    anim = {
        .Idle = { tex = {.Pistol01}, time = 0, transition = .Idle, },
        .Fire = { tex = {.Pistol01, .Pistol02, .Pistol03}, time = 0.05, transition = .Idle, },
    },
    x_off = 0,
    damage = 5,
}

rifle_cfg := Weapon_Cfg {
    anim = {
        .Idle = { tex = {.Rifle01}, time = 0, transition = .Idle, },
        .Fire = { tex = {.Rifle01, .Rifle02, .Rifle03}, time = 0.05, transition = .Idle, },
    },
    x_off = 2,
    damage = 5,
}

machinegun_cfg := Weapon_Cfg {
    anim = {
        .Idle = { tex = {.Machine_Gun01}, time = 0, transition = .Idle, },
        .Fire = { tex = {.Machine_Gun01, .Machine_Gun02, .Machine_Gun03}, time = 0.05, transition = .Idle, },
    },
    x_off = -1,
    damage = 10,
}

enemy_cfg := [Enemy_Type]Enemy_Cfg {
    .Cobra = {
        anim = {
            .Idle = { tex = {.Cobra0}, time = 0, transition = .Idle, },
            .Move = { tex = {.Cobra0, .Cobra1, .Cobra2}, time = 0.1, transition = .Idle, },
            .Hit = { tex = {.Cobra_Hit0}, time = 0.1, transition = .Idle, },
            .Death = { tex = {.Cobra_Hit0, .Cobra_Hit1, .Cobra_Hit2, .Cobra_Hit3, .Cobra_Hit4}, time = 0.1, },
        },
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
    .Clip = {
        y_off = 0.12,
        type = .Clip,
    },
    .Ammo_Box = {
        y_off = 0.12,
        type = .Ammo_Box,
    },
    .Armor = {
        y_off = 0.12,
        type = .Armor,
    },
}
