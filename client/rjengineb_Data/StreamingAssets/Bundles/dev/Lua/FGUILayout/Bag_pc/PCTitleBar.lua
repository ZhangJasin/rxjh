local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCTitleBar = class("PCTitleBar", BaseFGUILayout)

--角色属性组件
function PCTitleBar:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._pageList = {}
    self._listCells = {}
    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitUI()
end

function PCTitleBar:InitData()
    self._curSelectedID = nil
    self._curSelectedIndex = nil
    self._lastSelectCell = nil
    self._curSelectCell = nil
    self._curTitelCellSchedule = nil
    self._scheduleSet = {}
end
 
function PCTitleBar:GetAllFGuiData()
    self.btn_use = self._ui.btn_use
    self.text_titleGet = self._ui.text_titleGet
    self.title_list = self._ui.title_list
    self.gloader_selected = self._ui.gloader_selected
    self.text_selectedName = self._ui.text_selectedName
    self.text_leftTime = self._ui.text_leftTime
    self.ctrl_curSelectedTitleState = FGUI:getController(self.component,"curSelectedTitleState")
    self.ctrl_isHaveSelected = FGUI:getController(self.component,"isHaveSelected")
    self.ctrl_isTimer = FGUI:getController(self.component,"isTimer")
    self.time_left = self._ui.text_leftTime
end

function PCTitleBar:CleanSchedule()
    for k,v in pairs(self._scheduleSet) do
        if v then
            SL:UnSchedule(v)
            v = nil
        end
    end

    if self._curTitelCellSchedule then
        SL:UnSchedule(self._curTitelCellSchedule)
        self._curTitelCellSchedule = nil
    end
end

function PCTitleBar:InitUI()
    FGUI:GList_itemRenderer(self.title_list,handler(self,self.TitleItemRender))
    -- FGUI:GList_addOnClickItemEvent(self.title_list,handler(self,self.TitleItemClicked))
    FGUI:GList_setVirtual(self.title_list)
end

function PCTitleBar:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_use,handler(self,self.BtnUseClicked))
end

function PCTitleBar:TitleItemRender(idx,item)
    local ctrl_state = FGUI:getController(item,"titleState")
    local ctrl_selected = FGUI:getController(item,"isSelected")
    local ctrl_isTimer = FGUI:getController(item,"isTimer")
    local ctrl_IsPing = FGUI:getController(item,"isPin")
    local time_left = FGUI:GetChild(item,"time_left")
    local title_name = FGUI:GetChild(item,"title_name")
    local gloader_title = FGUI:GetChild(item,"gloader_title")
    local mask = FGUI:GetChild(item,"mask")
    local btn_pin = FGUI:GetChild(item,"btn_pin")
    local data = self.titleData[idx + 1]

    if self._scheduleSet[data.cfg.ID] then
        SL:UnSchedule(self._scheduleSet[data.cfg.ID])
        self._scheduleSet[data.cfg.ID] = nil
    end

    if data.isActive == false then
        ctrl_state.selectedIndex = 0
    elseif data.isActive == true and data.isUsed == false then
        ctrl_state.selectedIndex = 1
    elseif data.isActive == true and data.isUsed == true then
        ctrl_state.selectedIndex = 2
    end

    local itemEquipData = SL:GetValue("ITEM_DATA",data.itemID)
    FGUI:GTextField_setText(title_name,itemEquipData.Name or "")

    ctrl_selected.selectedIndex = self._curSelectedIndex == idx and 0 or 1
    if data.endTime and data.endTime > 0 then
        local callBack = function()
            local curTime  = SL:GetValue("SERVER_TIME") or 0
            if data.endTime - curTime <= 0 then
                if self._scheduleSet[data.cfg.ID] then
                    SL:UnSchedule(self._scheduleSet[data.cfg.ID])
                    self._scheduleSet[data.cfg.ID] = nil
                end
                FGUI:GTextField_setText(time_left,"")
                ctrl_isTimer.selectedIndex = 1
            else
                local leftTime = SecondToHMS(math.ceil(data.endTime - curTime),true, true)
                print("leftTime",leftTime)
                FGUI:GTextField_setText(time_left,leftTime)
                ctrl_isTimer.selectedIndex = 0
            end
        end
        
        callBack()
        self._scheduleSet[data.cfg.ID] = SL:Schedule(callBack, 1)
    else
        ctrl_isTimer.selectedIndex = 1
        FGUI:GTextField_setText(time_left,"")
    end

    FGUI:setOnClickEvent(mask,function()
        self:SwitchSelected(idx,item)
    end)

    ctrl_IsPing.selectedIndex = data.isPin == 0 and 1 or 0
    FGUI:setOnClickEvent(btn_pin,function()
        SL:SetValue("TITLE_UPDATE_PIN_DATA",data.cfg.ID, data.isPin == 0 and SL:GetValue("SERVER_TIME") or 0)
    end)

    local url =  FGUIFunction:GetTitleIconURL(data.cfg.Icon)
    FGUI:GLoader_setUrl(gloader_title, url, nil, true)
    
    local id = FGUI:GetID(gloader_title)
    if not self._listCells[id] then
        self._listCells[id] = gloader_title
        FGUI:setOnRollOverEvent(gloader_title, handler(self, self.OnTitleItemFocusIn))
        FGUI:setOnRollOutEvent(gloader_title, handler(self, self.OnTitleItemFocusOut))
    end
end

function PCTitleBar:OnTitleItemFocusIn(eventData)
    print("OnTitleItemFocusIn===================================")
    local cell = FGUI:GetParent(eventData.sender)
    local index = FGUI:GetChildIndex(self.title_list, cell)
    index = FGUI:GList_childIndexToItemIndex(self.title_list, index)
    local idx = index + 1
    local data = self.titleData[idx]
    if data then
    local tipData = {}
        tipData.itemID = data.itemID
        tipData.titleCfg = data.cfg
        SL:OpenTitleAttributeTips(tipData)
    end
end

function PCTitleBar:OnTitleItemFocusOut(eventData)
    SL:CloseTitleAttributeTips()
end

function PCTitleBar:RefreshTitleList()
    self.titleData = SL:GetValue("TITLE_SHOW_LIST") or {}
    FGUI:GList_setNumItems(self.title_list,table.nums(self.titleData or {}))
    self:RefreshButton()
end

-- function PCTitleBar:TitleItemClicked(eventData)
--     local childIdx = FGUI:GetChildIndex(self.title_list, eventData.data)
--     local idx = FGUI:GList_childIndexToItemIndex(self.title_list, childIdx)
--     self:SwitchSelected(idx,eventData.data)
-- end

function PCTitleBar:SwitchSelected(idx,cell)
    self._lastSelectCell = self._curSelectCell
    self._curSelectCell = cell
    self._curSelectedIndex = idx
    if self._lastSelectCell then
        local ctrl_selected = FGUI:getController(self._lastSelectCell,"isSelected")
        ctrl_selected.selectedIndex = 1
    end
    if self._curSelectCell then
        local ctrl_selected = FGUI:getController(self._curSelectCell,"isSelected")
        self.ctrl_isHaveSelected.selectedIndex = self._curSelectCell ~= nil and 0 or 1
        ctrl_selected.selectedIndex = 0
        self:RefreshSelectTitleBarInfo()
        self:RefreshButton()
    end
end

function PCTitleBar:RefreshSelectTitleBarInfo()
    local data = self.titleData[self._curSelectedIndex + 1]
    if not data then
       return 
    end

    local itemEquipData = SL:GetValue("ITEM_DATA",data.itemID)
    FGUI:GTextField_setText(self.text_selectedName,itemEquipData.Name or "")

    if data.isActive == false then
        self.ctrl_curSelectedTitleState.selectedIndex = 0
    elseif data.isActive == true and data.isUsed == false then
        self.ctrl_curSelectedTitleState.selectedIndex = 1
    elseif data.isActive == true and data.isUsed == true then
        self.ctrl_curSelectedTitleState.selectedIndex = 2
    end

    local url =  FGUIFunction:GetTitleIconURL(data.cfg.Icon)
    FGUI:GLoader_setUrl(self.gloader_selected, url, nil, true)

    if data.endTime and data.endTime > 0 then
        local callBack = function()
            local curTime  = SL:GetValue("SERVER_TIME") or 0
            if data.endTime - curTime <= 0 then
                if self._curTitelCellSchedule then
                    SL:UnSchedule(self._curTitelCellSchedule)
                    self._curTitelCellSchedule = nil
                end
                FGUI:GTextField_setText(self.time_left,"")
                self.ctrl_isTimer.selectedIndex = 1
            else
                local leftTime = SecondToHMS(math.ceil(data.endTime - curTime),true, true)
                print("leftTime",leftTime)
                FGUI:GTextField_setText(self.time_left,leftTime)
                self.ctrl_isTimer.selectedIndex = 0
            end
        end

        self._curTitelCellSchedule = SL:Schedule(callBack, 1)
    else
        self.ctrl_isTimer.selectedIndex = 1
        FGUI:GTextField_setText(self.time_left,"")
    end
end


function PCTitleBar:RefreshButton()
    if not self._curSelectedIndex then
        return
    end

    local data = self.titleData[self._curSelectedIndex + 1]
    if not data then
        return 
    end
    if data.isActive == false then
        FGUI:GButton_setTitle(self.btn_use,GET_STRING(30000112))
    elseif data.isActive == true and data.isUsed == false then
        -- 使用
        FGUI:GButton_setTitle(self.btn_use,GET_STRING(30000112))
    elseif data.isActive == true and data.isUsed == true then
        -- 卸下
        FGUI:GButton_setTitle(self.btn_use,GET_STRING(30000111))
    end
end

function PCTitleBar:BtnUseClicked()
    if not self._curSelectedIndex then
        return
    end

    local data = self.titleData[self._curSelectedIndex + 1]
    if not data then
        return
    end
    if data.isActive == false then
        SL:ShowSystemTips(GET_STRING(30000113))
    elseif data.isActive == true and data.isUsed == false then
        SL:RequestTitle(4,data.itemID)
    elseif data.isActive == true and data.isUsed == true then
        SL:RequestTitle(5,data.itemID)
    end
end

function PCTitleBar:Enter()
    self:RegisterEvent()
    self:InitData()
    self:RefreshTitleList()
    self.ctrl_isHaveSelected.selectedIndex = self._curSelectCell ~= nil and 0 or 1
end

function PCTitleBar:Exit()
    self:RemoveEvent()
    self:CleanSchedule()
    for k,v in pairs(self._listCells) do
        if v then
            FGUI:setOnRollOverEvent(v, nil)
            FGUI:setOnRollOutEvent(v, nil)
        end
    end
    self._listCells = {}
end

function PCTitleBar:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_TITLE_UPDATE, "PCTitleBar", handler(self, self.RefreshTitleList))
end

function PCTitleBar:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_TITLE_UPDATE,"PCTitleBar")
end


return PCTitleBar