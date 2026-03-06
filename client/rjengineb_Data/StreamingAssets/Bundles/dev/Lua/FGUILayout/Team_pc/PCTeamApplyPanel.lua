local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCTeamApplyPanel = class("PCTeamApplyPanel", BaseFGUILayout)

function PCTeamApplyPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	--FGUI:SetCloseUIWhenClickOutside(self)
    FGUIFunction:setWindowDrag(self.component, self._ui.bg)

	self:InitData()
	self:InitEvent()
end 

function PCTeamApplyPanel:Close()
	self.super.Close(self)
end

function PCTeamApplyPanel:InitData()
    self._applyList = {}
end

function PCTeamApplyPanel:InitEvent()
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.btn_agreeAll, handler(self, self.OnClickBtnAgreeAll))
    FGUI:setOnClickEvent(self._ui.btn_refuseAll, handler(self, self.OnClickBtnRefuseAll))
	FGUI:GList_itemRenderer(self._ui.list_apply, handler(self, self.ApplyListRenderer))
end

function PCTeamApplyPanel:Enter()
    self:OnUpdateTeamApplyList()
    self:RegisterEvent()
end

function PCTeamApplyPanel:Exit()
	self:RemoveEvent()
end

function PCTeamApplyPanel:OnUpdateTeamApplyList()
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

function PCTeamApplyPanel:RefreshNothingInfo()
    if #self._applyList == 0 then 
        FGUI:GTextField_setText(self._ui.text_nothing, GET_STRING(40010035))
    else 
        FGUI:GTextField_setText(self._ui.text_nothing, "")
    end 
end

function PCTeamApplyPanel:ApplyListRenderer(idx, item)
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

function PCTeamApplyPanel:OnClickBtnAgree(context)
	local index = FGUI:GetIntData(context.sender.parent) + 1
    local data = self._applyList[index]
    if not data then 
        return
    end 

    FGUI:GButton_setBright(context.sender, false)
    FGUI:GButton_setGrey(context.sender, true)

    if data.isInvited then 
        SL:RequestAgreeTeamInvite(data.UserID)
    else    
        SL:RequestApplyAgree(data.UserID)
    end 
    self:OnUpdateTeamApplyList()
end

function PCTeamApplyPanel:OnClickBtnRefuse(context)
	local index = FGUI:GetIntData(context.sender.parent) + 1
    local data = self._applyList[index]
    if not data then 
        return
    end 

    FGUI:GButton_setBright(context.sender, false)
    FGUI:GButton_setGrey(context.sender, true)

    if data.isInvited then 
        SL:RequestRefuseTeamInvite(data.UserID)
    else    
        SL:RequestApplyRefuse(data.UserID)
    end 
    self:OnUpdateTeamApplyList()
end

function PCTeamApplyPanel:OnClickBtnAgreeAll(context)
    SL:RequestTeamAllApplyAgree()
    self:OnUpdateTeamApplyList()
end

function PCTeamApplyPanel:OnClickBtnRefuseAll(context)
    SL:RequestTeamAllApplyRefuse()
    self:OnUpdateTeamApplyList()
end

-----------------------------------注册事件--------------------------------------
function PCTeamApplyPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_APPLY_UPDATE, "PCTeamApplyPanel", handler(self, self.OnUpdateTeamApplyList))
end

function PCTeamApplyPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_APPLY_UPDATE, "PCTeamApplyPanel")

end

return PCTeamApplyPanel