local HudMoveable = require("FGUILayout/Hud/HudMoveable")
local HudConfig = require("FGUILayout/Hud/HudConfig")
local HudNpc = class("HudNpc", HudMoveable)
HudNpc.type = HUDType.NPC
function HudNpc:ctor(uiHud)
    HudNpc.super.ctor(self, uiHud)
    -- 初始化HUDList
    self._attachTitle       = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.attachTitle)
    self._labelStall        = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.stall, HUDComponentName.CSLabel)
    self._labelStallOwner   = HUDHelp:GetChild(self._uiHud, HudConfig.HUDNode.stallOwner, HUDComponentName.CSLabel)
	
	
    self._hudVisibleList[self._attachTitle] = true
    self._hudVisibleList[self._labelStall] = true
    self._hudVisibleList[self._labelStallOwner] = true

    self._cacheStallName = nil
    self._cacheStallNameVisible = nil
    HUDHelp:SetLabelHalfWidthCallBack(self._labelName, handler(self,self.NameHalfWidthCallBack))
    HUDHelp:SetLabelHalfWidthCallBack(self._labelStall, handler(self,self.StallHalfWidthCallBack))
    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    self._nameOriPosY = namePosY
end

function HudNpc:Init(actorID)
    HudNpc.super.Init(self, actorID)
    self:SetVisible(self._labelStall, false)
    self:SetVisible(self._labelStallOwner, false)
    self:SetHudStallName(nil)
    self:SetHudStallOwnerName(nil)
    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    HUDHelp:SetPosition(self._labelName, 0, namePosY, namePosZ)

    local typeIndex = SL:GetValue("ACTOR_TYPE_INDEX",actorID) 
    local colorID = SL:GetValue("NPC_NAME_COLOR_ID",typeIndex) or 255
    local color3B = SL:GetValue("COLOR3B_BY_ID",colorID) 
    HUDHelp:SetLabelColor(self._labelName, color3B.r,color3B.g, color3B.b, color3B.a)
end

function HudNpc:SetHUDVisibleByType(iType,visible)   
    if iType == HudConfig.HUDType.Name then 
        if self._cacheHudNameTypeVisible == visible then
            return 
        end
        self._cacheHudNameTypeVisible = visible
        self:SetVisible(self._labelName, visible)
        self:SetVisible(self._labelStall, visible)
        self:SetVisible(self._labelStallOwner, visible)
    elseif iType == HudConfig.HUDType.Title then 
        if self._cacheHudTitleTypeVisible == visible then
            return 
        end
        self._cacheHudTitleTypeVisible = visible
        self:SetVisible(self._attachTitle, visible)
    end
end 

function HudNpc:Cleanup()
    HudNpc.super.Cleanup(self)
end

-- 设置摆摊名字隐藏 
function HudNpc:SetHudStallNameVisible(visible)
    if self._cacheStallNameVisible == visible then
        return
    end
    self._cacheStallNameVisible = visible

    self:SetVisible(self._labelStall, visible)
    self:SetVisible(self._labelStallOwner, visible)
end 

-- 设置名字
function HudNpc:SetHudName(name)
    if self._cacheName == name then 
        return 
    end 
    self._cacheName = name
    self._nameHalfWidth = nil
    HUDHelp:SetLabelText(self._labelName, name)
end

-- 设置摆摊名字
function HudNpc:SetHudStallName(name)
    if self._cacheStallName == name then 
        return 
    end 
    self._cacheStallName = name
    self._stallHalfWidth = nil
    if name == nil or name == "" then 
        self:SetVisible(self._labelStall, false)
        HUDHelp:SetLabelText(self._labelStall, "")
    else
        self:SetVisible(self._labelStall, true)
        HUDHelp:SetLabelText(self._labelStall, name)
    end
    self:UpdateStallNameAnchor()
    
end

-- 设置摊主名字
function HudNpc:SetHudStallOwnerName(name)
    if self._cacheStallOwnerName == name then 
        return 
    end 
    self._cacheStallOwnerName = name
    if name == nil or name == "" then 
        self:SetVisible(self._labelStallOwner, false)
        HUDHelp:SetLabelText(self._labelStallOwner, "")
    else
        self:SetVisible(self._labelStallOwner, true)
        HUDHelp:SetLabelText(self._labelStallOwner, name)
    end
end

--更新摆摊跟名字的位置
function HudNpc:UpdateStallNameAnchor()
    local stall = HUDHelp:GetLabelText(self._labelStall)
    if stall and stall ~= "" then 
        HUDHelp:SetLabelAnchor(self._labelName, HUDAnchor.Left)
        HUDHelp:SetLabelAnchor(self._labelStall, HUDAnchor.Right)
        self._updateStallNameLayout = true
    else 
        HUDHelp:SetLabelAnchor(self._labelName, HUDAnchor.Center)
    end
end

-- 设置摆摊颜色
function HudNpc:SetHudStallNameColor(color)
    HUDHelp:SetLabelColor(self._labelStall, color.r, color.g, color.b, 1)
end

function HudNpc:RefreshLabelNameVisible()
    local isVisible = true
    if SL:GetValue("ACTOR_IS_STALL_NPC",self._actorID) then 
        if SL:GetValue("SETTING_STALLS_EN") then 
            isVisible = false
        end   
    end
    self:SetHudNameVisible(isVisible)
end

function HudNpc:RefreshSatllNameVisible()
    local isVisible = true
    if SL:GetValue("ACTOR_IS_STALL_NPC",self._actorID) then 
        if SL:GetValue("SETTING_STALLS_EN") then 
            isVisible = false
        end   
    end
    self:SetHudStallNameVisible(isVisible)
end

function HudNpc:RefreshLabelSatllName()
    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    local stallPosX, stallPosY, stallPosZ = HUDHelp:GetPosition(self._labelStall)
    if SL:GetValue("ACTOR_IS_STALL_NPC",self._actorID) then 
        local showName = SL:GetValue("I18N_STRING", 20000201)
        self:SetHudStallName(showName)
        self:SetHudStallNameColor(SL:GetValue("COLOR3B_BY_ID", 70))
        self:SetHudNameColor(SL:GetValue("COLOR3B_BY_ID", 151))
        self:SetHudStallOwnerName(SL:GetValue("ACTOR_OWNER_NAME",self._actorID))

        HUDHelp:SetPosition(self._labelName, namePosX, self._nameOriPosY + 0.3, namePosZ)
        HUDHelp:SetPosition(self._labelStall, stallPosX, self._nameOriPosY + 0.3, stallPosZ)
    else 
        HUDHelp:SetPosition(self._labelName, namePosX, self._nameOriPosY, namePosZ)
        HUDHelp:SetPosition(self._labelStall, stallPosX, self._nameOriPosY, stallPosZ)
    end
end

function HudNpc:RefreshAllTitleVisible()
    local isVisible = true
    repeat
        if not SL:GetValue("ACTOR_MODEL_IS_VSIBLE", self._actorID) then
            isVisible = false
            break
        end
    until true

    self:SetHudAllTitleVisible(isVisible)
end

function HudNpc:NameHalfWidthCallBack(halfWidth)
    self._nameHalfWidth = halfWidth / 100
    if self._updateStallNameLayout then 
        self:UpdateStallNameLayout()
    end
end

function HudNpc:StallHalfWidthCallBack(halfWidth)
    self._stallHalfWidth = halfWidth / 100
    if self._updateStallNameLayout then 
        self:UpdateStallNameLayout()
    end
end

function HudNpc:UpdateStallNameLayout()
    if not self._stallHalfWidth 
    or not self._nameHalfWidth then 
        return      
    end

    local namePosX, namePosY, namePosZ = HUDHelp:GetPosition(self._labelName)
    local halfWidth = self._nameHalfWidth + self._stallHalfWidth
    local offsetX = 2 *self._stallHalfWidth - halfWidth
    local nameOffsetX = halfWidth - 2*self._nameHalfWidth
    HUDHelp:SetPosition(self._labelStall, offsetX,namePosY, namePosZ)
    HUDHelp:SetPosition(self._labelName, nameOffsetX,namePosY, namePosZ)

    self._updateStallNameLayout = false
end

return HudNpc