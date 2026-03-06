local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local PCQuickBox = class("PCQuickBox")


function PCQuickBox:Create(index)
	self._ui = FGUI:ui_delegate(self.component)
    self.index = index

    self.type = nil

    self.itemIndex = nil
    self.makeIndex = nil

    self.skillId = nil

    self.cdEndTime = nil
    self.keyType = SettingKey.Type.QUICK1 + index - 1
end

function PCQuickBox:Enter()
	self:RegisterEvent()
    self:UpdateKeysStr()
end

function PCQuickBox:Exit()
	self:RemoveEvent()
end

function PCQuickBox:Destroy()
    self._ui = nil
end


--------------------------------------------------------------------------------

function PCQuickBox:Clear()
    self.type = nil
    self.skillId = nil
    self.makeIndex = nil
    self.itemIndex = nil
    FGUI:GLoader_setUrl(self._ui.Loader_icon, "")
    FGUI:setVisible(self._ui.Text_count, false)
    self:ClearCD()
    self:RemoveItemEvent()
    self:RemoveSkillEvent()
end

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

-------------------------------------Skill---------------------------------------

function PCQuickBox:SetSkill(skillId)
    if self.type == FGUIDefine.PCQuickType.Skill and self.skillId == skillId then return end
    if self.type ~= FGUIDefine.PCQuickType.Skill then
        self:Clear()
    end
    self.type = FGUIDefine.PCQuickType.Skill
    self.skillId = skillId
    self.makeIndex = nil
    self.itemIndex = nil
    self.maskVisible = FGUI:getVisible(self._ui.Progress_mask)
    self:ClearCD()
    FGUI:GLoader_setUrl(self._ui.Loader_icon, SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", skillId))
    FGUI:setVisible(self._ui.Text_count, false)
    self:RegisterSkillEvent()
end

function PCQuickBox:OnSkillAdd(data)
    if not data then return end
    if not data.SkillId then return end

end

function PCQuickBox:OnSkillDel(data)
    if not data then return end
    if not data.SkillId then return end

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

-------------------------------------Item---------------------------------------

function PCQuickBox:SetItem(makeIndex, index)
    if self.type == FGUIDefine.PCQuickType.Item and self.makeIndex == makeIndex then return end
    if self.type ~= FGUIDefine.PCQuickType.Item then
        self:Clear()
    end
    self.type = FGUIDefine.PCQuickType.Item
    self.makeIndex = makeIndex
    self.itemIndex = index
    self.skillId = nil
    if not makeIndex then return end
    if not index then return end
    local path = ItemUtil:GetIconResPathByItemID(index)
    FGUI:GLoader_setUrl(self._ui.Loader_icon, path)
    FGUI:setVisible(self._ui.Text_count, true)
    self:UpdateItemCount()
    self:UpdateItemCD()
    self:RegisterItemEvent()
end

function PCQuickBox:UpdateItemCount()
    if not self.makeIndex then return end
    local count = 0
    local bagData = SL:GetValue("BAG_DATA_BY_MAKEINDEX", self.makeIndex)
    if bagData then
        count = bagData.OverLap
    end
    -- local count = SL:GetValue("ITEM_COUNT", self.makeIndex)
    count = SL:GetSimpleNumber(count, 2)
    FGUI:GTextField_setText(self._ui.Text_count, count)

    -- if not self.itemId then return end
    -- SL:GetValue("ITEM_COUNT", self.makeIndex)
    -- local count = self:GetItemCount(self.itemId)
    -- -- if count <= 0 then
    -- --     --取消id绑定
    -- --     self:SetItem(nil)
    -- --     return
    -- -- end
    -- -- local countStr = SL:GetSimpleNumber(count, 2)
    -- FGUI:GTextField_setText(self._ui.Text_count, count)
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
    FGUI:setVisible(self._ui.Progress_mask, visible)
    self.maskVisible = visible
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
        -- local isEquip = SL:GetValue("BAG_ITEM_IS_EQUIP")
        -- if isEquip then
        SL:RequestUseItem(itemData)
        -- else
        --     SL:RequestSendUseItem(itemData, 1)
        -- end
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
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_ADD, tag, handler(self, self.OnSkillAdd))
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_DEL, tag, handler(self, self.OnSkillDel))
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_TIME_CHANGE, tag, handler(self, self.OnSkillCDTimeChange))
end

function PCQuickBox:RemoveSkillEvent()
    if not self.isRegisterSkillEvent then return end
    self.isRegisterSkillEvent = false
    local tag = "PCQuickBox" .. self.index
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_ADD, tag)
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_DEL, tag)
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_TIME_CHANGE, tag)
end


return PCQuickBox