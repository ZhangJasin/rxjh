local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCComponentTitlePanel = class("PCComponentTitlePanel", BaseFGUILayout)

--角色属性组件
function PCComponentTitlePanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._pageList = {}
    self._listCells = {}
    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitUI()
end

function PCComponentTitlePanel:InitData()
    self._curSelectedID = nil
    self._curSelectedIndex = nil
    self._lastSelectCell = nil
    self._curSelectCell = nil
    self._scheduleSet = {}
end
 
function PCComponentTitlePanel:GetAllFGuiData()
    self.btn_use = self._ui.btn_use
    self.text_titleGet = self._ui.text_titleGet
    self.list_title = self._ui.list_title
    self.ctrl_ModeWho = FGUI:getController(self.component,"ModeWho")
end

function PCComponentTitlePanel:CleanSchedule()
    for k,v in pairs(self._scheduleSet) do
        if v then
            SL:UnSchedule(v)
            v = nil
        end
    end
end

function PCComponentTitlePanel:InitUI()
    self.ctrl_ModeWho.selectedIndex = 0
    FGUI:GList_itemRenderer(self.list_title,handler(self,self.TitleItemRender))
    FGUI:GList_setVirtual(self.list_title)
end

function PCComponentTitlePanel:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_use,handler(self,self.BtnUseClicked))
end

function PCComponentTitlePanel:TitleItemRender(idx,item)
    local ctrl_state = FGUI:getController(item,"titleState")
    local ctrl_selected = FGUI:getController(item,"isSelected")
    local ctrl_isTimer = FGUI:getController(item,"isTimer")
    local ctrl_IsPing = FGUI:getController(item,"isPin")
    local ctrl_isShowPin = FGUI:getController(item,"isShowPin")
	local ctrl_titleType = FGUI:getController(item,"titleType")
    local time_left = FGUI:GetChild(item,"time_left")
    local gloader_title = FGUI:GetChild(item,"gloader_title")
	local text_title = FGUI:GetChild(item,"text_title")
    local mask = FGUI:GetChild(item,"mask")
    local btn_pin = FGUI:GetChild(item,"btn_pin")
    local data = self.titleData[idx + 1]

    ctrl_isShowPin.selectedIndex = 0
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
    FGUI:setOnClickEvent(mask,function()
        self:SwitchSelected(idx,item)
    end)


    ctrl_IsPing.selectedIndex = data.isPin == 0 and 1 or 0
    FGUI:setOnClickEvent(btn_pin,function()
        SL:SetValue("TITLE_UPDATE_PIN_DATA",data.cfg.ID, data.isPin == 0 and SL:GetValue("SERVER_TIME") or 0)
    end)
	
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
                local leftTime = SecondToHMS(math.ceil(data.endTime - curTime),true, false)
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

	ctrl_titleType.selectedIndex = data.cfg.Type - 1
	if data.cfg.Type == 2 then
		FGUI:GTextField_setText(text_title,data.cfg.Content)
	else
		local url =  FGUIFunction:GetTitleIconURL(data.cfg.Icon)
	    FGUI:GLoader_setUrl(gloader_title, url, nil, true)
	end
	
    
    local id = FGUI:GetID(item)
    if not self._listCells[id] then
        self._listCells[id] = item
        FGUI:setOnRollOverEvent(item, handler(self, self.OnTitleItemFocusIn))
        FGUI:setOnRollOutEvent(item, handler(self, self.OnTitleItemFocusOut))
    end
end

function PCComponentTitlePanel:OnTitleItemFocusIn(eventData)
    print("OnTitleItemFocusIn===================================")
    local cell = eventData.sender
    local index = FGUI:GetChildIndex(self.list_title, cell)
    index = FGUI:GList_childIndexToItemIndex(self.list_title, index)
    local idx = index + 1
    local data = self.titleData[idx]
    if data then
    local tipData = {}
        tipData.itemID = data.itemID
        tipData.titleCfg = data.cfg
        SL:OpenTitleAttributeTips(tipData)
    end
end

function PCComponentTitlePanel:OnTitleItemFocusOut(eventData)
    SL:CloseTitleAttributeTips()
end

function PCComponentTitlePanel:RefreshTitleList()
    self.titleData = SL:GetValue("TITLE_SHOW_LIST") or {}
    FGUI:GList_setNumItems(self.list_title,table.nums(self.titleData or {}))
    self:RefreshButton()
    self:RefreshTitleGetCount()
end

function PCComponentTitlePanel:RefreshTitleGetCount()
    local activeCount = 0
    for k,v in pairs(self.titleData) do
        if v and v.isActive then
            activeCount = activeCount + 1
        end
    end

    FGUI:GTextField_setText(self.text_titleGet,GET_STRING(30000114) .. activeCount .. "/"..table.nums(self.titleData or {}))
end

function PCComponentTitlePanel:SwitchSelected(idx,cell)
    self._lastSelectCell = self._curSelectCell
    self._curSelectCell = cell
    self._curSelectedIndex = idx
    if self._lastSelectCell then
        local ctrl_selected = FGUI:getController(self._lastSelectCell,"isSelected")
        ctrl_selected.selectedIndex = 1
    end
    if self._curSelectCell then
        local ctrl_selected = FGUI:getController(self._curSelectCell,"isSelected")
        ctrl_selected.selectedIndex = 0
        local data = self.titleData[self._curSelectedIndex + 1]
        self:RefreshButton()
        SLBridge:onLUAEvent(LUA_EVENT_ROLE_TITLE_PREVIEW,data)
    end
end

function PCComponentTitlePanel:RefreshButton()
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

function PCComponentTitlePanel:BtnUseClicked()
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

function PCComponentTitlePanel:Enter()
    self:RegisterEvent()
    self:InitData()
    self:RefreshTitleList()
    SL:RequestTitle(1)
end

function PCComponentTitlePanel:Exit()
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

function PCComponentTitlePanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_TITLE_UPDATE, "PCComponentTitlePanel", handler(self, self.RefreshTitleList))
end

function PCComponentTitlePanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_TITLE_UPDATE,"PCComponentTitlePanel")
end


return PCComponentTitlePanel