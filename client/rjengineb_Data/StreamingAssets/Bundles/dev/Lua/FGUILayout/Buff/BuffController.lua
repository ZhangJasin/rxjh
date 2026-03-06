local BuffController = class("BuffController")
function BuffController:CheckBuffEffectVisible(actorID, buffID)
    local isVisible = true
    repeat
        if not actorID then
            isVisible = false
            break
        end

        if SL:GetValue("MAIN_PLAYER_ID") == actorID then 
            if SL:GetValue("SETTING_SELF_FIX_EN") then 
                isVisible = false
                break
            end
        elseif SL:GetValue("ACTOR_IS_ENEMY", actorID)  then 
            if SL:GetValue("SETTING_ENEMY_FIX_EN") then 
                isVisible = false
                break
            end
        else
            if SL:GetValue("SETTING_FRND_FIX_EN") then 
                isVisible = false
                break
            end
        end

        if SL:GetValue("ACTOR_IS_RIDE", actorID) then
            if buffID == SLDefine.BUFFID.TIYUNZONG 
                or buffID == SLDefine.BUFFID.CAOSHANGFEI
                or buffID == SLDefine.BUFFID.JIFENGYUQISHU
                then
                isVisible = false
                break
            end
            isVisible = false
            break
        end
    until true
    
    return isVisible
end
return BuffController
