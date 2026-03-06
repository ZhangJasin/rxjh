local HudBase = require("FGUILayout/Hud/HudBase")
local HudMoveable = class("HudMoveable", HudBase)
local HudConfig = require("FGUILayout/Hud/HudConfig")
HudMoveable.type = HUDType.UNKNOW
function HudMoveable:ctor(uiHud)
    HudMoveable.super.ctor(self, uiHud)
    self._attachTitle  = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.attachTitle)
    self._cacheHudNameTypeVisible = nil
    self._cacheHudTitleTypeVisible = nil
    self._titleHeight = 0
end

function HudMoveable:Init(actorID)
    HudMoveable.super.Init(self, actorID)
end

function HudMoveable:Cleanup()
    if self._iconIDs then 
        for i = 0, 9 do
            local id = self._iconIDs[i]
            if id and id ~= 0 then 
                local iconType = SL:GetValue("ICON_TYPE_BY_ID", id)
                if iconType == 1 then 
                    HUDHelp:Recycel3DFx(self._icons[i])
                elseif iconType == 2 then 
                    HUDHelp:RecycelLabel(self._icons[i])
                elseif iconType == 3 then 
                    HUDHelp:RecycelFx(self._icons[i])
                end
                self._icons[i] = nil
                self._iconIDs[i] = nil
            end
        end
    end
    
	HudMoveable.super.Cleanup(self)
end

function HudMoveable:SetHudAllTitleVisible(visible)
    self:SetHUDVisibleByType(HudConfig.HUDType.Title, visible)
end

function HudMoveable:SetHUDVisibleByType(iType, visible)   
end

--刷新顶戴
local LabelHeight = 0.29
function HudMoveable:RefIcons()  
    local iconID, iconType, iconContent, iconOffsetX, iconOffsetY, icon, fxHeight,lastIconID
    self._titleHeight = 0
    for i = 0, 9 do
        lastIconID = nil
        iconID = SL:GetValue("ACTOR_ICON", self._actorID, i)
        if self._iconIDs and self._iconIDs[i] then 
            lastIconID = self._iconIDs[i]
            if lastIconID ~= iconID then 
                iconType = SL:GetValue("ICON_TYPE_BY_ID", lastIconID)
                if iconType == 1 then 
                    HUDHelp:Recycel3DFx(self._icons[i])
                elseif iconType == 2 then 
                    HUDHelp:RecycelLabel(self._icons[i])
                elseif iconType == 3 then 
                    HUDHelp:RecycelFx(self._icons[i])
                end
            end
        end
        if iconID ~= 0 then
            self._icons = self._icons or {}
            self._iconIDs = self._iconIDs or {}
            iconType = SL:GetValue("ICON_TYPE_BY_ID", iconID)
            iconContent = SL:GetValue("ICON_CONTENT_BY_ID", iconID)
            iconOffsetX = SL:GetValue("ICON_OFFSETX_BY_ID", iconID)
            iconOffsetY = SL:GetValue("ICON_OFFSETY_BY_ID", iconID)
            if lastIconID == iconID then 
                --特效
                if iconType == 1 then 
                    iconContent = tonumber(iconContent)
                    fxHeight = SL:GetValue("FX_HEIGHT_BY_ID", iconContent)
                    HUDHelp:SetFxPosition(self._icons[i],iconOffsetX, self._titleHeight + iconOffsetY + fxHeight/2, 0)
                    self._titleHeight = self._titleHeight + fxHeight + 0.01
                --文本
                elseif iconType == 2 then 
                    HUDHelp:SetPosition(self._icons[i], iconOffsetX, self._titleHeight + iconOffsetY, 0)
                    self._titleHeight = self._titleHeight + LabelHeight
                --序列帧特效
                elseif iconType == 3 then 
                    fxHeight = SL:GetValue("ICON_HEIGHT_BY_ID", iconID)
                    HUDHelp:SetFxPosition(self._icons[i],iconOffsetX, self._titleHeight + iconOffsetY + fxHeight/2, 0)
                    self._titleHeight = self._titleHeight + fxHeight + 0.01
                end
            else
                --特效
                if iconType == 1 then 
                    iconContent = tonumber(iconContent)
                    fxHeight = SL:GetValue("FX_HEIGHT_BY_ID", iconContent)
                    icon = HUDHelp:Create3DFx(self._attachTitle, "icon_"..iconID, iconOffsetX, self._titleHeight + iconOffsetY + fxHeight/2, iconContent)
                    self._titleHeight = self._titleHeight + fxHeight + 0.01
                --文本
                elseif iconType == 2 then 
                    icon = HUDHelp:CreateHudLabel(self._attachTitle, "icon_"..iconID, iconOffsetX, self._titleHeight + iconOffsetY, iconContent)
                    self._titleHeight = self._titleHeight + LabelHeight
                --序列帧特效
                elseif iconType == 3 then 
                    iconContent = tonumber(iconContent)
                    fxHeight = SL:GetValue("ICON_HEIGHT_BY_ID", iconID)
                    icon = HUDHelp:CreateFx(self._attachTitle, "icon_"..iconID, iconOffsetX, self._titleHeight + iconOffsetY + fxHeight/2, iconContent)
                    self._titleHeight = self._titleHeight + fxHeight + 0.01
                end
                self._icons[i] = icon
                self._iconIDs[i] = iconID
            end
        else 
            if self._iconIDs then 
                self._icons[i] = nil
                self._iconIDs[i] = nil
            end
        end
    end
end
return HudMoveable