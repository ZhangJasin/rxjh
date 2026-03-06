CampUpdate = {}
local REFDATA_ID_CAMP = 1           -- 正邪阵营
-- 更新阵营图标  正邪阵营
function CampUpdate:SetHudCampIcon(targetHud, camp)
    local campHUD = HUDHelp:GetChild(targetHud._uiHud, "camp", HUDComponentName.CSSpriteMeshScale9)
    if not campHUD then
        return
    end
    -- print("更新阵营图标  正邪阵营", camp)
    local campSprites = {
        [1] = "zheng",
        [2] = "xie",
    }
    local spriteName = campSprites[camp]
    HUDHelp:SetVisible(campHUD, spriteName ~= nil)
    if spriteName then
        HUDHelp:SetSpriteName(campHUD, spriteName)
    end
end
-- 监听事件 更新阵营 
function CampUpdate:OnUpdateCampHud(targetID)
    if not SL:GetValue(ACTOR_IS_PLAYER, targetID) then
        return
    end
    local targetHud = HUDHelp:GetActorHud(targetID)
    if not targetHud then
        return
    end
    local roleCamp1 = SL:GetValue(ACTOR_GM_DATA_BY_ID, targetID, REFDATA_ID_CAMP)
    self:SetHudCampIcon(targetHud, roleCamp1)
end

-- 监听事件 更新阵营图标  更新势力战红蓝阵营图标
function CampUpdate:RegisterEvent()
    SL:RegisterLUAEvent("LUA_EVENT_ACTOR_GMDATA_UPDATE", "CampUpdate", handler(self, self.OnUpdateCampHud))
    SL:RegisterLUAEvent("LUA_EVENT_PLAYER_CAMPHUD_UPDATE", "CampUpdate", handler(self, self.OnUpdateCampHud))
end

CampUpdate:RegisterEvent()
return CampUpdate
