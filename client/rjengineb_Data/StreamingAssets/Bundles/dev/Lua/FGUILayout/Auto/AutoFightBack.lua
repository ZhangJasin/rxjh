AutoFightBack = class('AutoFightBack')
function AutoFightBack.main()
    SL:RegisterLUAEvent(LUA_EVENT_AUTO_FIGHT_BACK, "AutoFightBack",  AutoFightBack.OnAutoFightBack)
end

function AutoFightBack.FindFinalMaster(targetID)
    local masterID = targetID
    while SL:GetValue("ACTOR_HAVE_MASTER", targetID) do
        local tMasterID = SL:GetValue("ACTOR_MASTER_ID", targetID) 
        if not tMasterID or tMasterID == 0 then
            break
        end
        masterID = tMasterID
    end
    return masterID
end

function AutoFightBack.OnAutoFightBack(attackActorID, actorID, skillID)
    --安全区
    if SL:GetValue("ACTOR_IN_SAFE_ZONE") then 
        return
    end
    
    -- 没有攻击者id
    if not attackActorID or attackActorID == 0 then  
        return
    end

    --怪物或者人形怪 不反击
    local attackMasterID = SL:GetValue("ACTOR_MASTER_ID", attackActorID) 
    if (SL:GetValue("ACTOR_IS_HUMAN", attackActorID) 
        or SL:GetValue("ACTOR_IS_MONSTER", attackActorID)) 
        and not (attackMasterID and attackMasterID ~= 0) then
        return 
    end

    --非自动挂机
    if not SL:GetValue("BATTLE_IS_AFK") then
        return
    end

    --已有仇恨目标 
    local hateID = SL:GetValue("HATE_ID") 
    if hateID and SL:GetValue("ACTOR_IN_VIEW", hateID) then
        return 
    end

    local mainPlayerID = SL:GetValue("MAIN_PLAYER_ID") 
    local masterID = AutoFightBack.FindFinalMaster(actorID)
    local attackBackID = nil -- 要反击的对象id
    -- 攻击 我的宠物/主角
    if masterID == mainPlayerID then
        --自动反击
        if SL:GetValue("SETTING_PROCESS_MOD_ON_UNATTACK") == 1 then 
            if not attackBackID then 
                attackBackID = attackActorID
            end
        --逃跑
        elseif SL:GetValue("SETTING_PROCESS_MOD_ON_UNATTACK") == 2 then 
            local dX, dY, dZ = FGUIFunction:GetRandomMovePos()
            if dX and dY and dZ then 
                SL:SetValue("AUTO_INPUT_MOVE", SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_AFK, dX, dY, dZ)
            end
        end
    end
    --自动切模式  红名切善恶 非红名切全体
    if attackBackID and SL:GetValue("ACTOR_IS_CAN_SELECT", attackBackID) then 
        local pkValue = SL:GetValue("ACTOR_PKVALUE", masterID) 
        if pkValue > 0 then
            local pkMode = SL:GetValue("PKMODE") 
            if pkMode ~= SLDefine.PKMODE.PKATTACK then --善恶 
                SL:RequestChangePKMode(SLDefine.PKMODE.PKATTACK)
            end
        else
            SL:RequestChangePKMode(SLDefine.PKMODE.ALL)
        end

        SL:SetValue("SELECT_TARGET_ID", attackBackID, SLDefine.SELECT_TARGET.SYSTEM)
        SL:SetValue("HATE_ID", attackBackID)
    end
end

