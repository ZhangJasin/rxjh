local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TeamApplyPanel = class("TeamApplyPanel", BaseFGUILayout)

function TeamApplyPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)

	self:InitData()
	self:InitEvent()
end 

function TeamApplyPanel:Close()
	self.super.Close(self)
end

function TeamApplyPanel:InitData()
    self._applyList = {}
end

function TeamApplyPanel:InitEvent()
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.mask, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.btn_agreeAll, handler(self, self.OnClickBtnAgreeAll))
    FGUI:setOnClickEvent(self._ui.btn_refuseAll, handler(self, self.OnClickBtnRefuseAll))
	FGUI:GList_itemRenderer(self._ui.list_apply, handler(self, self.ApplyListRenderer))
end

function TeamApplyPanel:Enter()
    self:OnUpdateTeamApplyList()
    self:RegisterEvent()
end

function TeamApplyPanel:Exit()
	self:RemoveEvent()
end

function TeamApplyPanel:OnUpdateTeamApplyList()
    self._applyList = {}
    local myUID = SL:GetValue("USER_ID")
    local isLeader = SL:GetValue("TEAM_IS_LEADER", myUID)
    if not isLeader then  
        FGUI:GList_setNumItems(self._ui.list_apply, 0)
        self:RefreshNothingInfo()
        return
    end 
    self._applyList = SL:GetValue("TEAM_APPLY_LIST")

    FGUI:setVisible(self._ui.btn_agreeAll, isLeader)
    FGUI:setVisible(self._ui.btn_refuseAll, isLeader)
    FGUI:GList_setNumItems(self._ui.list_apply, #self._applyList)
    self:RefreshNothingInfo()
end

function TeamApplyPanel:RefreshNothingInfo()
    -- Directly control text_nothing visibility since panel_nothing is removed
    if #self._applyList == 0 then
        FGUI:setVisible(self._ui.text_nothing, true)
        FGUI:GTextField_setText(self._ui.text_nothing, GET_STRING(40010035))
    else
        FGUI:setVisible(self._ui.text_nothing, false)
    end
end

function TeamApplyPanel:ApplyListRenderer(idx, item)
    if not self._applyList or not next(self._applyList) then  
        return 
    end 
    
    local index = idx + 1
    local data = self._applyList[index]
    if not data then 
        return 
    end
 
    local ui_name = FGUI:GetChild(item, "text_name")
    FGUI:GTextField_setText(ui_name, FGUIFunction:GetServerName(data.UserName))

    local ui_level = FGUI:GetChild(item, "text_level")
    FGUI:GTextField_setText(ui_level, data.Level)

    local ui_iconJob = FGUI:GetChild(item, "img_job")
    local pathJob = FGUIFunction:GetJobUrl(data.Job)
    FGUI:GLoader_setUrl(ui_iconJob, pathJob)

    local btn_agree = FGUI:GetChild(item, "btn_agree")
    local btn_refuse = FGUI:GetChild(item, "btn_refues")
    FGUI:GButton_setBright(btn_agree, true)
    FGUI:GButton_setGrey(btn_agree, false)
    FGUI:GButton_setBright(btn_refuse, true)
    FGUI:GButton_setGrey(btn_refuse, false)
    FGUI:setOnClickEvent(btn_agree, handler(self, self.OnClickBtnAgree))
    FGUI:setOnClickEvent(btn_refuse, handler(self, self.OnClickBtnRefuse))
	FGUI:SetIntData(item, idx)
end

function TeamApplyPanel:OnClickBtnAgree(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	local index = FGUI:GetIntData(eventData.sender.parent) + 1
    local data = self._applyList[index]
    if not data then 
        return
    end 

    FGUI:GButton_setBright(eventData.sender, false)
    FGUI:GButton_setGrey(eventData.sender, true)

    if data.isInvited then 
        SL:RequestAgreeTeamInvite(data.UserID)
    else    
        SL:RequestApplyAgree(data.UserID)
    end 
    self:OnUpdateTeamApplyList()
end

function TeamApplyPanel:OnClickBtnRefuse(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	local index = FGUI:GetIntData(eventData.sender.parent) + 1
    local data = self._applyList[index]
    if not data then 
        return
    end 

    FGUI:GButton_setBright(eventData.sender, false)
    FGUI:GButton_setGrey(eventData.sender, true)

    if data.isInvited then 
        SL:RequestRefuseTeamInvite(data.UserID)
    else    
        SL:RequestApplyRefuse(data.UserID)
    end 
    self:OnUpdateTeamApplyList()
end

function TeamApplyPanel:OnClickBtnAgreeAll(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    SL:RequestTeamAllApplyAgree()
    self:OnUpdateTeamApplyList()
end

function TeamApplyPanel:OnClickBtnRefuseAll(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    SL:RequestTeamAllApplyRefuse()
    self:OnUpdateTeamApplyList()
end

-----------------------------------注册事件--------------------------------------
function TeamApplyPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_APPLY_UPDATE, "TeamApplyPanel", handler(self, self.OnUpdateTeamApplyList))
end

function TeamApplyPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_APPLY_UPDATE, "TeamApplyPanel")

end

return TeamApplyPanel