local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorComponentTitlePanel = class("VisitorComponentTitlePanel", BaseFGUILayout)

--角色属性组件
function VisitorComponentTitlePanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._pageList = {}
    self:GetAllFGuiData()
    self:InitUI()
end

function VisitorComponentTitlePanel:InitData()
    self._curSelectedID = nil
    self._curSelectedIndex = nil
    self._lastSelectCell = nil
    self._curSelectCell = nil
    self._scheduleSet = {}
end
 
function VisitorComponentTitlePanel:GetAllFGuiData()
    self.btn_use = self._ui.btn_use
    self.text_titleGet = self._ui.text_titleGet
    self.list_title = self._ui.list_title
    self.ctrl_ModeWho = FGUI:getController(self.component,"ModeWho")
end

function VisitorComponentTitlePanel:CleanSchedule()
    for k,v in pairs(self._scheduleSet) do
        if v then
            SL:UnSchedule(v)
            v = nil
        end
    end
end

function VisitorComponentTitlePanel:InitUI()
    self.ctrl_ModeWho.selectedIndex = 1
    FGUI:GList_itemRenderer(self.list_title,handler(self,self.TitleItemRender))
    FGUI:GList_setVirtual(self.list_title)
end

function VisitorComponentTitlePanel:TitleItemRender(idx,item)
    local ctrl_state     = FGUI:getController(item,"titleState")
    local ctrl_selected  = FGUI:getController(item,"isSelected")
    local ctrl_isTimer   = FGUI:getController(item,"isTimer")
    local ctrl_isShowPin = FGUI:getController(item,"isShowPin")
    local ctrl_titleType = FGUI:getController(item,"titleType")
    local time_left          = FGUI:GetChild(item,"time_left")
    local gloader_title       = FGUI:GetChild(item,"gloader_title")
    local text_title = FGUI:GetChild(item,"text_title")
    local btn_help       = FGUI:GetChild(item,"btn_help")
    local btn_pin        = FGUI:GetChild(item,"btn_pin")

    local data = self.titleData[idx + 1]
    ctrl_isShowPin.selectedIndex = 0
    FGUI:setOnClickEvent(btn_help,function()
        local tipData = {}
        tipData.itemID = data.itemID
        tipData.titleCfg = data.cfg
        SL:OpenTitleAttributeTips(tipData)
    end)
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

    FGUI:setVisible(btn_pin, false)

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
                FGUI:GTextField_setText(time_left,leftTime)
                ctrl_isTimer.selectedIndex = 0
            end
        end
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
    
end

function VisitorComponentTitlePanel:RefreshTitleList()
    SL:GetValue("VISITOR_TITLE_UPDATTE_DATA")
    self.titleData = SL:GetValue("VISITOR_TITLE_DATA") or {}
    FGUI:GList_setNumItems(self.list_title,table.nums(self.titleData or {}))
    self:RefreshTitleGetCount()
end

function VisitorComponentTitlePanel:RefreshTitleGetCount()
    local activeCount = 0
    for k,v in pairs(self.titleData) do
        if v and v.isActive then
            activeCount = activeCount + 1
        end
    end

    FGUI:GTextField_setText(self.text_titleGet,GET_STRING(30000114) .. activeCount .. "/"..table.nums(self.titleData or {}))
end

function VisitorComponentTitlePanel:Enter()
    self:InitData()
    self:RefreshTitleList()
end

function VisitorComponentTitlePanel:Exit()
    self:CleanSchedule()
end


return VisitorComponentTitlePanel