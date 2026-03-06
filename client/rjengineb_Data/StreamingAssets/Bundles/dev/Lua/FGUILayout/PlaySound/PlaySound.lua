-- 播放音效

PlaySound = {}

function PlaySound.main()
    -- 玩家死亡
    SL:RegisterLUAEvent(LUA_EVENT_MAIN_PLAYER_DIE, "PlaySound", function(data)
        SL:PlaySound(24, nil, nil, 1)
    end)
    -- 网络玩家死亡
    SL:RegisterLUAEvent(LUA_EVENT_NET_PLAYER_DIE, "PlaySound", function(data)
        SL:PlaySound(24, nil, nil, 3)
    end)
end