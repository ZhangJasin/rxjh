local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local PCQuickBox = class("PCQuickBox")


function PCQuickBox:Create(main, index)
	self._ui = FGUI:ui_delegate(self.component)
    self.main = main
    self.index = index

    self.type = nil

    self.itemIndex = nil
    self.makeIndex = nil

    self.skillId = nil
    self.skillAuto = false
    self.isWuGong = false

    self.cdEndTime = nil
    self.keyType = SettingKey.Type.QUICK1 + index - 1

    self.autoMovieClip = nil

    self.maskVisible = FGUI:getVisible(self._ui.Progress_mask)

    FGUI:setOnRollOverEvent(self.component, handler(self, self.OnRollOver))
    FGUI:setOnRollOutEvent(self.component, handler(self, self.OnRollOut))
    FGUI:setOnDropEvent(self.component, handler(self, self.OnDragDrop))
    FGUI:setOnClickEvent(self._ui.Loader_icon, handler(self, self.OnClickIcon))
    FGUI:setOnRightClickEvent(self._ui.Loader_icon, handler(self, self.OnRightClickIcon))
end

function PCQuickBox:Enter()
	self:RegisterEvent()
    self:UpdateKeysStr()
end

function PCQuickBox:Exit()
	self:RemoveEvent()
    self:RemoveItemEvent()
    self:RemoveSkillEvent()
end

function PCQuickBox:Destroy()
    self._ui = nil
end


--------------------------------------------------------------------------------

function PCQuickBox:UpdateKeysStr()
    local keysStr = ""
    local keyData = SettingKey.GetSetting(self.keyType)
    if keyData then
        keysStr = keyData.keysStr or ""
    end
    FGUI:GTextField_setText(self._ui.Text_key, keysStr)
end

function PCQuickBox:OnKeyChange(type)
    if type ~= self.keyType then return end
    self:UpdateKeysStr()
end

function PCQuickBox:OnRollOver()
    self.showAutoSet = true
    self:UpdateShowAutoSet()
    if self.type == FGUIDefine.PCQuickType.Skill then
        local level = SL:GetValue("SKILL_LEVEL_BY_ID", self.skillId)
        local posX, posY = FGUI:getWorldPosition(self.component)
        local w, h = FGUI:getSize(self.component)
        if self.isWuGong then posY = posY - 34 end--减去一个自动释放勾选框的高度
        local ext = {posX = posX + w / 2, posY = posY, anchorX = 0.5, anchorY = 1}
        FGUIFunction:ShowSkillTip(self.skillId, level, ext)
    elseif self.type == FGUIDefine.PCQuickType.Item then
        local itemData = SL:GetValue("BAG_DATA_BY_MAKEINDEX", self.makeIndex) or
                        SL:GetValue("ITEM_DATA", self.itemIndex)
        if itemData then
            FGUIFunction:OpenItemTips({itemData = itemData})
        end
    end
end

function PCQuickBox:OnRollOut()
    self.showAutoSet = false
    self:UpdateShowAutoSet()
    if self.type == FGUIDefine.PCQuickType.Skill then
        FGUIFunction:HideSkillTip()
    elseif self.type == FGUIDefine.PCQuickType.Item then
        FGUIFunction:CloseItemTips()
    end
end

function PCQuickBox:OnDragDrop(eventData)
    if not self.main then return end
    self.main:DragDrop(self.index, eventData)
end


function PCQuickBox:UpdateShowAutoSet()
    if not self.main then return end
    local show = self.isWuGong and self.showAutoSet
    if show then
        self.main:ShowSkillAutoSet(self.index)
    else
        self.main:HideSkillAutoSet(self.index)
    end
end

function PCQuickBox:OnClickIcon(eventData)
    if not self.main then return end
    self.main:DragQuickItem(self.index, eventData)
end

function PCQuickBox:OnRightClickIcon(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
    if self.main and self.main.delayClick then return end
    self:Use()
end

---------------------------------------------------------------------------------

function PCQuickBox:SetEmpty()
    self:SetType(nil)
    FGUI:GLoader_setUrl(self._ui.Loader_icon, "")
    FGUI:setVisible(self._ui.Text_count, false)
    self:ClearCD()
    self:UpdateAutoMovieClip()
end

function PCQuickBox:SetType(type)
    if type == self.type then return end
    self.type = type

    self.skillId = nil
    self.skillAuto = nil
    self:SetIsWuGong(false)
    self.makeIndex = nil
    self.itemIndex = nil
    if self.type == FGUIDefine.PCQuickType.Skill then
        self:RemoveItemEvent()
        self:RegisterSkillEvent()
        FGUI:setVisible(self._ui.Text_count, false)
    elseif self.type == FGUIDefine.PCQuickType.Item then
        self:RemoveSkillEvent()
        self:RegisterItemEvent()
        FGUI:setVisible(self._ui.Text_count, true)
    else
        self:RemoveItemEvent()
        self:RemoveSkillEvent()
        FGUI:setVisible(self._ui.Text_count, false)
    end
end

function PCQuickBox:SetIsWuGong(value)
    if self.isWuGong == value then return end
    self.isWuGong = value
    self:UpdateShowAutoSet()
end

-------------------------------------Skill---------------------------------------

function PCQuickBox:SetSkill(skillId, auto)
    local changeId = self.skillId ~= skillId
    self:SetType(FGUIDefine.PCQuickType.Skill)
    self.skillId = skillId
    self.skillAuto = auto
    self:SetIsWuGong(SL:GetValue("SKILL_CHECK_IS_WUGONG_TYPE", self.skillId, 1))
    if changeId then
        self:ClearCD()
        FGUI:GLoader_setUrl(self._ui.Loader_icon, SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", skillId))
    end
    self:UpdateAutoMovieClip()
end

function PCQuickBox:UpdateAutoMovieClip(isAFK)
    local show = self.skillAuto
    if show then
        isAFK = isAFK == nil and SL:GetValue("BATTLE_IS_AFK") or isAFK
        show = show and isAFK
    end
    if show then
        if not self.autoMovieClip then
            self.autoMovieClip = FGUI:GMovieClip_create(self.component, "6683")
            FGUI:setAnchorPoint(self.autoMovieClip, 0.5, 0.5, true)
            local w, h = FGUI:getSize(self.component)
            FGUI:setPosition(self.autoMovieClip, w / 2, h / 2)
            FGUI:setScale(self.autoMovieClip, 0.5, 0.5)
        else
            FGUI:setVisible(self.autoMovieClip, true)
        end
        FGUI:GMovieClip_setPlaySettings(self.autoMovieClip, 0, -1, 0, -1)
        FGUI:GMovieClip_setPlaying(self.autoMovieClip, true)
    else
        if self.autoMovieClip then
            FGUI:setVisible(self.autoMovieClip, false)
            FGUI:GMovieClip_setPlaying(self.autoMovieClip, false)
        end
    end
end

function PCQuickBox:OnSkillCDTimeChange(data)
    if not data or not data.skillID then return end
    if data.skillID ~= self.skillId then return end
    local percent = data.percent
    if data.time and data.time <= 0 then 
        percent = 0
    end 
    if percent <= 0 then
        self:SetMaskVisible(false)
    else 
        self:SetMaskVisible(true)
        FGUI:GProgressBar_setValue(self._ui.Progress_mask, percent * 100)
    end
end

function PCQuickBox:OnAFKBegin()
    self:UpdateAutoMovieClip(true)
end

function PCQuickBox:OnAFKEnd()
    self:UpdateAutoMovieClip(false)
end

-------------------------------------Item---------------------------------------

function PCQuickBox:SetItem(makeIndex, index)
    self:SetType(FGUIDefine.PCQuickType.Item)
    self.makeIndex = makeIndex
    self.itemIndex = index
    if not makeIndex then return end
    if not index then return end
    local path = ItemUtil:GetIconResPathByItemID(index)
    FGUI:GLoader_setUrl(self._ui.Loader_icon, path)
    self:UpdateItemCount()
    self:UpdateItemCD()
    self:UpdateAutoMovieClip()
end

function PCQuickBox:UpdateItemCount()
    if not self.makeIndex then return end
    local count = 0
    local bagData = SL:GetValue("BAG_DATA_BY_MAKEINDEX", self.makeIndex)
    if bagData then
        count = bagData.OverLap
    end

    count = SL:GetSimpleNumber(count, 2)
    FGUI:GTextField_setText(self._ui.Text_count, count)
end

function PCQuickBox:OnItemInit()
    self:UpdateItemCount()
    self:UpdateItemCD()
end

function PCQuickBox:OnItemAdd(data)
    if not data then return end
    if data.MakeIndex ~= self.makeIndex then return end
    self:UpdateItemCount()
end

function PCQuickBox:OnItemDel(data)
    if not data then return end
    if data.MakeIndex ~= self.makeIndex then return end
    self:UpdateItemCount()
end

function PCQuickBox:OnItemUpdate(data)
    if not data then return end
    if data.MakeIndex ~= self.makeIndex then return end
    self:UpdateItemCount()
end

function PCQuickBox:OnItemCD()
    self:UpdateItemCD()
end

function PCQuickBox:UpdateItemCD()
    local index = self.itemIndex
    local endTime = SL:GetValue("ITEM_CD_ENDTIME", index)
    if not endTime then
        self.cdEndTime = nil
        self:SetMaskVisible(false)
        FGUI:stopAllActions(self._ui.Progress_mask)
        return
    end
    if self.cdEndTime == endTime then return end
    self.cdEndTime = endTime
    local startTime = SL:GetValue("ITEM_CD_USETIME", index)
    FGUI:stopAllActions(self._ui.Progress_mask)
    local curTime = SL:GetValue("SERVER_TIME")
    if endTime <= curTime then
        self:SetMaskVisible(false)
        return
    end
    FGUI:GProgressBar_setValue(self._ui.Progress_mask, 100 * (1 - (curTime - startTime)/(endTime - startTime)))
    FGUI:runAction(self._ui.Progress_mask, FGUI:ActionSequence(
        FGUI:ActionShow(),
        FGUI:ActionProgressTo(endTime - curTime, 0),
        FGUI:ActionHide()
    ))
end

--------------------------------------------------------------------------------



function PCQuickBox:SetMaskVisible(visible)
    if visible == self.maskVisible then return end
    self.maskVisible = visible
    FGUI:setVisible(self._ui.Progress_mask, visible)
end

function PCQuickBox:ClearCD()
    self:SetMaskVisible(false)
    FGUI:stopAllActions(self._ui.Progress_mask)
    self.cdEndTime = nil
    return
end

function PCQuickBox:Use()
    if self.type == FGUIDefine.PCQuickType.Item then
        local itemData = SL:GetValue("BAG_DATA_BY_MAKEINDEX", self.makeIndex)
        SL:RequestUseItem(itemData)
    elseif self.type == FGUIDefine.PCQuickType.Skill then
        FGUIFunction:LaunchSkill(self.skillId)
    end
end

-----------------------------------注册事件--------------------------------------

function PCQuickBox:RegisterEvent()
    local tag = "PCQuickBox" .. self.index
    SL:RegisterLUAEvent(LUA_EVENT_KEY_SETTING_CAHNGE, tag, handler(self, self.OnKeyChange))
end

function PCQuickBox:RemoveEvent()
    local tag = "PCQuickBox" .. self.index
    SL:UnRegisterLUAEvent(LUA_EVENT_KEY_SETTING_CAHNGE, tag)
end

function PCQuickBox:RegisterItemEvent()
    if self.isRegisterItemEvent then return end
    self.isRegisterItemEvent = true
    local tag = "PCQuickBox" .. self.index
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_INIT, tag, handler(self, self.OnItemInit))
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_ADD, tag, handler(self, self.OnItemAdd))
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_DEL, tag, handler(self, self.OnItemDel))
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE, tag, handler(self, self.OnItemUpdate))
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_CD, tag, handler(self, self.OnItemCD))
end

function PCQuickBox:RemoveItemEvent()
    if not self.isRegisterItemEvent then return end
    self.isRegisterItemEvent = false
    local tag = "PCQuickBox" .. self.index
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_INIT, tag)
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_ADD, tag)
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_DEL, tag)
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE, tag)
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_CD, tag)
end

function PCQuickBox:RegisterSkillEvent()
    if self.isRegisterSkillEvent then return end
    self.isRegisterSkillEvent = true
    local tag = "PCQuickBox" .. self.index
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_TIME_CHANGE, tag, handler(self, self.OnSkillCDTimeChange))
    SL:RegisterLUAEvent(LUA_EVENT_AFK_BEGIN, tag, handler(self, self.OnAFKBegin))
    SL:RegisterLUAEvent(LUA_EVENT_AFK_END, tag, handler(self, self.OnAFKEnd))
end

function PCQuickBox:RemoveSkillEvent()
    if not self.isRegisterSkillEvent then return end
    self.isRegisterSkillEvent = false
    local tag = "PCQuickBox" .. self.index
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_TIME_CHANGE, tag)
    SL:UnRegisterLUAEvent(LUA_EVENT_AFK_BEGIN, tag)
    SL:UnRegisterLUAEvent(LUA_EVENT_AFK_END, tag)
end


return PCQuickBox