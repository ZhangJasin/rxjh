Levelup = {}
Levelup._fxID = 1001001
Levelup._fxEntity = nil

function Levelup.main()
    if not Levelup._fxID then return end
    SL:RegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "Levelup", Levelup.OnLevelChange)
end

function Levelup.OnLevelChange()
    -- 播放升级特效
    local fxEntity = Levelup._fxEntity
    if not fxEntity then
        fxEntity = SL:Fx3D_Create(SL:GetValue("USER_ID"), Levelup._fxID)
        Levelup._fxEntity = fxEntity
        SL:Fx3D_AddOnComplete(fxEntity, function()
            SL:Fx3D_Stop(fxEntity)
            SL:Fx3D_SetPosition(fxEntity, -9999, -9999, -9999)
        end)
    end
    SL:Fx3D_SetPosition(fxEntity, 0, 0, 0)
    SL:Fx3D_Stop(fxEntity)
    SL:Fx3D_Play(fxEntity)

    -- 播放升级音效
    SL:PlaySound(1, nil, nil, 1)
end
