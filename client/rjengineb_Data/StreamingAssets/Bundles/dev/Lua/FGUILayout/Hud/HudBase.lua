local HudBase = class("HudBase")
local HudConfig = require("FGUILayout/Hud/HudConfig")
HudBase.type = HUDType.UNKNOW
function HudBase:ctor(uiHud)
    self._uiHud = uiHud
    
    self._hudAllVisible = true
    self._hudVisibleList = {}
    self._labelName = HUDHelp:GetChild(uiHud, HudConfig.HUDNode.name, HUDComponentName.CSLabel)
    self._hudVisibleList[self._labelName] = true

    self._offsetY = nil
    self._cacheName = nil
    self._cacheNameColor = nil
    self._cacheLabelNameVisible = nil

    self._cameraHUDRefID = nil
    self._actorID = nil
end

function HudBase:Init(actorID)
    self._actorID = actorID
    -- 跟随相机
    if not self._cameraHUDRefID then 
        self._cameraHUDRefID = HUDHelp:InitCamera(self._uiHud)
    end
	self:SetHudOffsetY(HudConfig.HUDInitPos.y)
end

function HudBase:Destroy()
end

function HudBase:Cleanup()
	self._offsetY = -9999
	HUDHelp:CleanCamera(self._cameraHUDRefID)
    HUDHelp:SetPosition(self._uiHud, -9999,-9999,-9999)
    HUDHelp:ClearLabelGradientColor(self._labelName)
    if self._buffs then 
        for i, v in pairs(self._buffs) do 
            HUDHelp:RecycleHUDBuffObject(v)
        end 
    end

    self._cameraHUDRefID = nil
end


-- 设置Hud节点隐藏
function HudBase:SetVisible(comp, visible)
    if self._hudVisibleList[comp] == visible then
        return
    end
	self._hudVisibleList[comp] = visible

    if self._hudAllVisible == false then
        return
    end
    
    if self._hudVisibleList[comp] then
        HUDHelp:SetVisible(comp, true)
    else
        HUDHelp:SetVisible(comp, false)
    end
end 

function HudBase:SetAllVisible(visible)
    if self._hudAllVisible == visible then
        return false
    end
	self._hudAllVisible = visible

    if self._hudAllVisible then
        for k, v in pairs(self._hudVisibleList) do
            if v == true then
                HUDHelp:SetVisible(k, true)
            end
        end
    else
        for k, v in pairs(self._hudVisibleList) do
            HUDHelp:SetVisible(k, false)
        end
    end
end 

-- 设置Y轴偏移
function HudBase:SetHudOffsetY(offsetY)
    if self._offsetY == offsetY then
        return
    end
    self._offsetY = offsetY

    HUDHelp:SetPosition(self._uiHud, HudConfig.HUDInitPos.x, offsetY, HudConfig.HUDInitPos.z)
	self:RefreshHUDScaleDirty()
end 

-- 设置名字
function HudBase:SetHudName(name)
    if self._cacheName == name then 
        return 
    end 
    self._cacheName = name

    HUDHelp:SetLabelText(self._labelName, name)
end

-- 设置名字隐藏 
function HudBase:SetHudNameVisible(visible)
    if self._cacheLabelNameVisible == visible then
        return
    end
    self._cacheLabelNameVisible = visible

    self:SetVisible(self._labelName, visible)
end 

-- 设置名字颜色
function HudBase:SetHudNameColor(color)
    if self._cacheNameColor == color then 
        return 
    end 
    self._cacheNameColor = color

    HUDHelp:SetLabelColor(self._labelName, color.r, color.g, color.b, 1)
end

-- 设置名字渐变颜色
function HudBase:SetHudNameGradientColor(dir , id)
	HUDHelp:SetLabelGradientColor(self._labelName, dir, id)
end

-- buff icon
function HudBase:SetHudBuffIcon(buffID, iType, actorID)
    if not buffID then 
        return 
    end 

    if not iType then 
        return 
    end 

    local config = SL:GetValue("BUFF_CONFIG_BY_ID", buffID)
    if not config or not config.Icon then 
        return 
    end 

    if not self._buffs then 
        self._buffs = {}
    end 

    if iType == 1 then -- add
        self._buffs[buffID] = nil
        self._buffs[buffID] = self:CreateHudBuffIcon(buffID)

    elseif iType == 0 then -- remove
        if self._buffs[buffID] then 
            HUDHelp:RecycelBuffIcon(self._buffs[buffID])
            self._buffs[buffID] = nil 
        end 
        
    elseif iType == 2 then -- update
        if self._buffs[buffID] then 
            self:UpdateHudBuffCD(buffID)
        end 
        
    end

    if SL:GetValue("ACTOR_IS_PLAYER", actorID) then 
		self:UpdateHudBuffPosition(1, 0.35, 0)
	end

	if SL:GetValue("ACTOR_IS_MONSTER", actorID) then 
		self:UpdateHudBuffPosition(-0.52, 0.1, 0)
	end
end

function HudBase:CreateHudBuffIcon(buffID)
    local config = SL:GetValue("BUFF_CONFIG_BY_ID", buffID)
    if not config or not config.Icon then 
        return 
    end 

    local uiBuff = HUDHelp:GetBuff(self._uiHud)
    HUDHelp:SetPosition(uiBuff, 0, 0, 0)
    HUDHelp:SetScale(uiBuff, 0.3, 0.3, 0.3)


    local icon = HUDHelp:GetBuffIcon(uiBuff)
    HUDHelp:SetSpriteName(icon, config.Icon)

    local time = HUDHelp:GetBuffTime(uiBuff)
    HUDHelp:SetLabelText(time, "")

    return uiBuff
end

function HudBase:UpdateHudBuffCD(buffID, leftTime)
    if not buffID then 
        return 
    end 

    if not leftTime then 
        return 
    end 

    if not self._buffs or not self._buffs[buffID] then 
        return 
    end 

    -- 倒计时
    local labelTime = HUDHelp:GetBuffTime(self._buffs[buffID])
    if labelTime then 
        HUDHelp:SetLabelText(labelTime, leftTime or "")
    end
end

function HudBase:UpdateHudBuffPosition(x, y, z)
    if self._buffs and next(self._buffs) then 
        local index = 0
        for id, buff in pairs(self._buffs) do 
            index = index + 1
            HUDHelp:SetPosition(buff, x+(index-1)*0.3, y, z)
        end 
    end 
end 

function HudBase:SetHudBuffVisible(visible)
    if self._buffs and next(self._buffs) then 
        for _, buff in pairs(self._buffs) do 
            self:SetVisible(buff, visible)
        end 
    end 
end 

--刷新名字
function HudBase:RefHudName()
    local showName = SL:GetValue("ACTOR_SHOWNAME", self._actorID)
    self:SetHudName(showName)
end 

-- 刷新HUD缩放
function HudBase:RefreshHUDScaleDirty()
	if global.gameCameraController then
		return global.gameCameraController:RefreshHUDScaleDirty(self._cameraHUDRefID)
	end
end

function HudBase:RefreshLabelNameColor()
end

return HudBase