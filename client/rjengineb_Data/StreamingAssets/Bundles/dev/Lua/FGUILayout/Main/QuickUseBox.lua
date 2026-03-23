local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local QuickUseBox = class("QuickUseBox")


function QuickUseBox:Create(root, index)
	self._ui = FGUI:ui_delegate(self.component)
    self.root = root
    self.index = index
  
    FGUI:setOnClickEvent(self._ui.Button_add, handler(self, self.OnSelectItem))
    FGUI:setOnTouchEvent(self._ui.Button_add, handler(self, self.OnTouchBegin), nil, handler(self, self.OnTouchEnd))
    FGUI:setOnClickEvent(self._ui.Button_icon, handler(self, self.OnClickItem))
    FGUI:setOnTouchEvent(self._ui.Button_icon, handler(self, self.OnTouchBegin), nil, handler(self, self.OnTouchEnd))

    self.itemId = nil
    self.itemData = nil
    self.countStr = nil
    self.cdEndTime = nil

    local x, y = FGUI:getPosition(self._ui.Button_add)
    self.touchX, self.touchY = FGUI:LocalToWorld(self.component, x, y)
end

function QuickUseBox:Enter()
end

function QuickUseBox:Exit()

    if self.touchTimer then
        SL:UnSchedule(self.touchTimer)
        self.touchTimer = nil
    end
end

function QuickUseBox:Destroy()
    self._ui = nil
end


--------------------------------------------------------------------------------

function QuickUseBox:SetItem(itemId, force)
    if itemId == self.itemId and not force then return end
    self.itemId = itemId
    if itemId then
        self:RegisterEvent()
    else
        self:RemoveEvent()
    end

    if itemId then
        FGUI:setVisible(self._ui.Group_item, true)
        FGUI:setVisible(self._ui.Button_add, false)

        local iconPath = ItemUtil:GetIconResPathByItemID(itemId)
        FGUI:GButton_setIcon(self._ui.Button_icon, iconPath)
        self.itemData = SL:GetValue("BAG_DATA_BY_INDEX", itemId)
        if not self.itemData then
            self.root:SetItemIndex(self.index, nil)
            self:SetItem(nil)
        else
            local count = self:GetItemCount(itemId)
            self:UpdateCount(count)
        end
    else
        self.itemData = nil
        FGUI:setVisible(self._ui.Group_item, false)
        FGUI:setVisible(self._ui.Button_add, true)
    end
    self:UpdateItemCD()
end

function QuickUseBox:OnSelectItem(eventData)
    if not self.root then return end
    self.root:ShowSelect(self.index, self.touchX, self.touchY)
end

function QuickUseBox:OnClickItem(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
    if not self.itemData then return end
    if self.cdEndTime and self.cdEndTime > SL:GetValue("SERVER_TIME") then return end
    local holdTime = FGUI:InputEvent_getHoldTime(eventData)
    if holdTime > 0.55 then return end
    SL:RequestSendUseItem(self.itemData, 1)
end

function QuickUseBox:OnTouchBegin(eventData)
    if self.touchTimer then
        SL:UnSchedule(self.touchTimer)
        self.touchTimer = nil
    end
    self.touchTimer = SL:ScheduleOnce(function()
        self.touchTimer = nil
        self.root:ShowSelect(self.index, self.touchX, self.touchY)
    end, 0.5)
end

function QuickUseBox:OnTouchEnd(eventData)
    if self.touchTimer then
        SL:UnSchedule(self.touchTimer)
        self.touchTimer = nil
    end
end

function QuickUseBox:GetItemCount(index)
    local itemData = SL:GetValue("ITEM_DATA", index)
    if not itemData then return 0 end
    local count = 0
    local bagData = SL:GetValue("BAG_DATA")
    if itemData.StdMode == 103 then
        for k, data in pairs(bagData) do
            if data.Index == index then
                count = count + (data.Dura or 0)
            end
        end
    else
        for k, data in pairs(bagData) do
            if data.Index == index then
                count = count + (data.OverLap or 1)
            end
        end
    end
    
    return count
end

function QuickUseBox:UpdateItemCD()
    local index = self.itemId
    local progress = self._ui.Progress_mask
    if not index then
        self.cdEndTime = nil
        FGUI:setVisible(progress, false)
        FGUI:stopAllActions(progress)
        return
    end
    local endTime = SL:GetValue("ITEM_CD_ENDTIME", index)
    if not endTime then
        FGUI:setVisible(progress, false)
        FGUI:stopAllActions(progress)
        return
    end
    if self.cdEndTime == endTime then return end
    self.cdEndTime = endTime
    local startTime = SL:GetValue("ITEM_CD_USETIME", index)

    FGUI:stopAllActions(progress)
    local curTime = SL:GetValue("SERVER_TIME")
    if endTime <= curTime then
        FGUI:setVisible(progress, false)
        return
    end
    FGUI:GProgressBar_setValue(progress, 100 * (1 - (curTime - startTime)/(endTime - startTime)))
    FGUI:runAction(progress, FGUI:ActionSequence(
        FGUI:ActionShow(),
        FGUI:ActionProgressTo(endTime - curTime, 0),
        FGUI:ActionHide()
    ))
end

function QuickUseBox:UpdateCount(count)
    if not self.itemId then return end
    count = count or self:GetItemCount(self.itemId)
    if count <= 0 then
        --取消id绑定
        self:SetItem(nil)
        return
    end
    local countStr = SL:GetSimpleNumber(count, 2)
    if self.countStr == countStr then return end
    self.countStr = countStr
    FGUI:GTextField_setText(self._ui.Text_count, countStr)
end

-- --------------------------------------------------------------------------------

function QuickUseBox:OnItemAdd(data)
    if not data then return end
    if data.Index ~= self.itemId then return end
    self:UpdateCount()
end

function QuickUseBox:OnItemDel(data)
    if not data then return end
    if data.Index ~= self.itemId then return end
    self:SetItem(self.itemId, true)
end

function QuickUseBox:OnItemUpdate(data)
    if not data then return end
    if data.Index ~= self.itemId then return end
    self:UpdateCount()
end

function QuickUseBox:OnItemCD()
    self:UpdateItemCD()
end


-----------------------------------注册事件--------------------------------------
function QuickUseBox:RegisterEvent()
    if self.initRegisterEvent then return end
    self.initRegisterEvent = true
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_ADD, "QuickUseBox" .. self.index, handler(self, self.OnItemAdd))
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_DEL, "QuickUseBox" .. self.index, handler(self, self.OnItemDel))
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE, "QuickUseBox" .. self.index, handler(self, self.OnItemUpdate))
    SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_CD, "QuickUseBox" .. self.index, handler(self, self.OnItemCD))
end

function QuickUseBox:RemoveEvent()
    if not self.initRegisterEvent then return end
    self.initRegisterEvent = false
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_ADD, "QuickUseBox" .. self.index)
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_DEL, "QuickUseBox" .. self.index)
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE, "QuickUseBox" .. self.index)
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_CD, "QuickUseBox" .. self.index)
end


return QuickUseBox