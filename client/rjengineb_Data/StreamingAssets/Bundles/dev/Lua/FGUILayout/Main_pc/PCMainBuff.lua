local PCMainBuff = class("PCMainBuff")

local LIST_MAX_SHOW_COUNT = 10

function PCMainBuff:Create()
    self.listBuff = self.component

    self._buffDatas = {}
    self._listCells = {}

    FGUI:GList_itemRenderer(self.listBuff, handler(self, self.OnListBuffRender))
end

function PCMainBuff:Enter()
	self:RegisterEvent()

    self:UpdateBuffList()
end

function PCMainBuff:Exit()
	self:RemoveEvent()
    
    self.buffTipData = nil
    self:HideBuffTip()
end

function PCMainBuff:Destroy()
    self.listBuff = nil
    if self.buffTipUI then
        FGUI:RemoveFromParent(self.buffTipUI.nativeUI, true)
        self.buffTipUI = nil
    end
end

----------------------------------------------------------------------------

function PCMainBuff:UpdateBuffList()
    local buffDatas = SL:GetMetaValue("ACTOR_BUFF_DATA")
    self._buffDatas = buffDatas
    if self.buffTipData then
        local id = self.buffTipData.id
        self.buffTipData = nil
        --更新当前显示tip的buffData
        for k, v in pairs(buffDatas) do
            if v.id == id then
                self.buffTipData = v
            end
        end
        if not self.buffTipData then
            self:HideBuffTip()
        end
    end
    FGUI:GList_setNumItems(self.listBuff, #buffDatas)
    FGUI:GList_resizeToFit(self.listBuff, LIST_MAX_SHOW_COUNT)
end

function PCMainBuff:OnListBuffRender(index, cell)
    local idx = index + 1
    local data = self._buffDatas[idx]
    if not data then return end
    local icon = FGUI:GetChild(cell, "icon")
    local iconPath = SL:GetValue("BUFF_ICON_PATH_BY_ID", data.id)
    FGUI:GLoader_setUrl(icon, iconPath, nil, true)

    local id = FGUI:GetID(cell)
    if not self._listCells[id] then
        self._listCells[id] = cell
        FGUI:setOnRollOverEvent(cell, handler(self, self.OnBuffFocusIn))
        FGUI:setOnRollOutEvent(cell, handler(self, self.OnBuffFocusOut))
    end
end

function PCMainBuff:UpdateBuffLeftTime()
    local data = self.buffTipData
    if data and data.endTime then 
        local endTime = data.endTime
        local curTime = SL:GetValue("SERVER_TIME") or 0
        local leftTime = endTime - curTime
        if leftTime >= 0 then
            FGUI:GTextField_setText(self.buffTipUI.Text_time, SL:SecondToHMS(leftTime, true, true))
            return
        end
    end

    self:HideBuffTip()
end

function PCMainBuff:GetBuffTip()
    if not self.buffTipUI then
        local buffTip = FGUI:CreateObject(self.component, "Main_pc", "BuffTip")
        FGUI:RemoveFromParent(buffTip, false)
        self.buffTipUI = FGUI:ui_delegate(buffTip)
    end
    return self.buffTipUI
end

function PCMainBuff:OnBuffFocusIn(eventData)
    local cell = eventData.sender
    local index = FGUI:GetChildIndex(self.listBuff, cell)
    index = FGUI:GList_childIndexToItemIndex(self.listBuff, index)
    local idx = index + 1
    local data = self._buffDatas[idx]
    if not data or not data.config then return end
    self.buffTipData = data

    local buffTipUI = self:GetBuffTip()
    local buffTip = buffTipUI.nativeUI
    local parent = FGUI:GetParent(self.listBuff)
    

    FGUI:GTextField_setText(self.buffTipUI.Text_name, data.config.Name or "")
    FGUI:GTextField_setText(self.buffTipUI.Text_desc, data.config.Tips or "")

    if self.buffTimer then
        SL:UnSchedule(self.buffTimer)
        self.buffTimer = nil
    end
    if data.endTime then
        self.buffTimer = SL:Schedule(handler(self, self.UpdateBuffLeftTime), 1)
        self:UpdateBuffLeftTime()
    else
        FGUI:GTextField_setText(self.buffTipUI.Text_desc, "")
    end
    local worldX, worldY = FGUI:getTouchPosition(eventData)
    local x, y = FGUI:WorldToLocal(parent, worldX, worldY)
    FGUI:setPosition(buffTip, x - 20, y+500)
    self.tipIdx = idx
    SL:onLUAEvent(LUA_EVENT_TOP_TIP_ADD, buffTip, "PCMainBuff" .. self.tipIdx)
end

function PCMainBuff:OnBuffFocusOut(eventData)
    local cell = eventData.sender
    local index = FGUI:GetChildIndex(self.listBuff, cell)
    index = FGUI:GList_childIndexToItemIndex(self.listBuff, index)
    local idx = index + 1
    local data = self._buffDatas[idx]
    if not data then return end
    if not self.buffTipData then return end
    if self.buffTipData.id ~= data.id then return end
    if idx ~= self.tipIdx then return end
    -- if not self.buffTipUI then return end
    self:HideBuffTip()
end

function PCMainBuff:HideBuffTip()
    if self.buffTipUI and self.tipIdx then
        SL:onLUAEvent(LUA_EVENT_TOP_TIP_REMOVE, self.buffTipUI.nativeUI, "PCMainBuff" .. self.tipIdx)
        self.tipIdx = nil
    end
    if self.buffTimer then
        SL:UnSchedule(self.buffTimer)
        self.buffTimer = nil
    end
end

-----------------------------------注册事件--------------------------------------
function PCMainBuff:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_MAIN_BUFF_UPDATE, "PCMainBuff", handler(self, self.UpdateBuffList))
end

function PCMainBuff:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_MAIN_BUFF_UPDATE, "PCMainBuff")
end


return PCMainBuff