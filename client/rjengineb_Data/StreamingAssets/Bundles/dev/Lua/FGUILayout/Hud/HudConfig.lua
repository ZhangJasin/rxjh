local HudConfig = class("HudConfig")
HudConfig.HUDInitPos = {
    x = 0,
    y = 2,
    z = 0
}

HudConfig.HPConfig = {
    HP_RED = {res ="hp_red",Y = 0.5,scale9 = {5,7,3,4}, size = {132,12}},
    HP_RED_BOSS = {res ="hp_red_boss",Y = 0.47,scale9 = {5,7,6,8}, size = {156,18}},
    HP_NORMAL_BG = {res ="hp_red_bg", Y = 0.5, scale9 = {12,14,13,14}, size = {146,30}},
    HP_ELITE_BG = {res ="hp_red_bg",Y = 0.5, scale9 = {12,14,13,14}, size = {146,30}},
    HP_BOSS_BG = {res ="hp_red_bg_boss",Y = 0.5, scale9 = {68,68,13,12}, size = {220,41}},
}

HudConfig.HUDType = {
    Name = 1,
    HP = 2,
    Title = 3,
    HPLabel = 4,
}

HudConfig.HUDNode = {
    name                = "nameLabel",
    hpBg                = 'SpriteMesh-hpbg',
    hp                  = 'SpriteMesh-hp',
    hpAni               = 'SpriteMesh-hpAni',
    attachTitle         = "Attach_title",
    guild               = "guildLabel",
    stall               = "stallLabel",  
    stallOwner          = "stallOwnerLabel", 
    hpLabel             = "hpLabel",
}

HudConfig.KuaFuType = {
    TEXT = 1,
    SPRITE = 2,
}
return HudConfig