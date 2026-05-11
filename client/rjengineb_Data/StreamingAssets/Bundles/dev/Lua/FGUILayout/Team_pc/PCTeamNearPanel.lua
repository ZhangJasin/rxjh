local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCTeamNearPanel = class("PCTeamNearPanel", BaseFGUILayout)

local PAGE_DATA = {
	[1] = {name = "所有队伍", page = 1, nothing = "暂无队伍"},
	[2] = {name = "附近队伍", page = 2, nothing = "暂无队伍"},
	[3] = {name = "队伍邀请", page = 3, nothing = "暂无邀请"},
}

local PICK_DATA = {
	{name = "自由分配", value = 0},
	{name = "随机分配", value = 1},
	{name = "顺序分配", value = 2},
	{name = "队长分配", value = 3},
}

function PCTeamNearPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	
	-- 修复 FGUI XML 中 list_team 的 defaultItem 引用错误
	-- 原引用 ui://pnop7ha6nc451v 是 MentorShip 包的，应改为 Team 包的 item_near
	if self._ui.list_team then
		FGUI:GList_setDefaultItem(self._ui.list_team, "ui://xh57ov19k9rf9")
	end
	
    FGUIFunction:setWindowDrag(self.component, self._ui.bg)

	self:InitData()
	self:InitEvent()
end 

function PCTeamNearPanel:Close()
	self.super.Close(self)
end

function PCTeamNearPanel:InitData()
    self._nearList = {}
    self._selPage = 1
end

function PCTeamNearPanel:InitEvent()
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.btn_refresh, handler(self, self.OnClickBtnRefresh))
    FGUI:setOnClickEvent(self._ui.btn_create, handler(self, self.OnClickBtnCreateTeam))
    FGUI:setOnClickEvent(self._ui.check_autoInvited, handler(self, self.OnClickAutoInvited))

	-- Menu 
    FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.PageRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)

    -- list
    FGUI:GList_itemRenderer(self._ui.list_team, handler(self, self.NearListRenderer))
end

function PCTeamNearPanel:Enter(page)
    local isAutoInvited = GET_CLOUD_STORAGE_DATA("TEAM_AUTO_INVITED")
    FGUI:GButton_setSelected(self._ui.check_autoInvited, isAutoInvited)

    self:SelectPage(page or 1)
    self:RegisterEvent()

	SL:ComponentAttach(SLDefine.SUIComponentTable.TeamNear, self._ui.Node_attach)
end

function PCTeamNearPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.TeamNear)

	self:RemoveEvent()
end

function PCTeamNearPanel:PageRenderer(idx, item)
    local index = idx + 1
    local data = PAGE_DATA[index]
    if not data then 
        return 
    end 

    local text_normal = FGUI:GetChild(item, "text_normal")
    local text_select = FGUI:GetChild(item, "text_select")
    FGUI:GTextField_setText(text_normal, data.name)
    FGUI:GTextField_setText(text_select, data.name)
end

function PCTeamNearPanel:OnClickPage(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
    self:SelectPage(index)
end

function PCTeamNearPanel:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page, index - 1)
	self._selPage = index

    if self._selPage == 1 then 
        SL:RequestRandomTeam()
    elseif self._selPage == 2 then 
        SL:RequestNearTeam()
    end 
    self:OnUpdateNearTeam()
end

local AVATOR_DATA = {}
function PCTeamNearPanel:NearListRenderer(idx, item)
    if not self._nearList or not next(self._nearList) then  
        return 
    end 
    
    local index = idx + 1
    local data = self._nearList[index]
    if not data then 
        return 
    end

    local ui_name = FGUI:GetChild(item, "text_name")
    local name = data.MasterName or data.UserName
    FGUI:GTextField_setText(ui_name, FGUIFunction:GetServerName(name))

    local ui_level = FGUI:GetChild(item, "text_level")
    FGUI:GTextField_setText(ui_level, data.Level)

    local ui_teamName = FGUI:GetChild(item, "text_teamName")
    FGUI:GTextField_setText(ui_teamName, data.GroupName or "")

    local ui_count = FGUI:GetChild(item, "text_count")
    local memberCount = data.MemBer and #data.MemBer or data.MemberCount
    memberCount = memberCount or 1 
    local memberMax = SL:GetValue("GAME_DATA","GroupMembersMax")
    FGUI:GTextField_setText(ui_count, string.format(GET_STRING(40020020), memberCount, memberMax))

    local ui_pick = FGUI:GetChild(item, "text_pick")
    local pickName = "" 
    if data.DropType then 
        pickName = PICK_DATA[data.DropType + 1].name
    end 
    FGUI:GTextField_setText(ui_pick, string.format(GET_STRING(40010064), pickName))

    local ui_avator = FGUI:GetChild(item, "avator")
    AVATOR_DATA.AvatarID = data.AvatarID
    AVATOR_DATA.Job = data.Job
    AVATOR_DATA.Sex = data.Sex
    AVATOR_DATA.FrameID = data.PhotoframeID
    FGUIFunction:SetCommonPlayerFrame(ui_avator, AVATOR_DATA)

    local ui_iconJob = FGUI:GetChild(item, "img_job")
    local pathJob = FGUIFunction:GetJobUrl(data.Job)
    FGUI:GLoader_setUrl(ui_iconJob, pathJob)

    local ui_needLv = FGUI:GetChild(item, "text_needLv")
    if self._selPage == 1 or self._selPage == 2 then 
        local color = (SL:GetValue("LEVEL") >= data.jlv and SL:GetValue("LEVEL") <= data.jlvmax) and "#00FF00" or "#FF0000"
        FGUI:GRichTextField_setText(ui_needLv, string.format(GET_STRING(40010063), color, data.jlv, data.jlvmax))
    else 
        FGUI:GRichTextField_setText(ui_needLv, "")
    end

    local btn_join = FGUI:GetChild(item, "btn_join")
    local btn_refuse = FGUI:GetChild(item, "btn_refuse")
    local btn_agree = FGUI:GetChild(item, "btn_agree")
    FGUI:setVisible(btn_join, self._selPage == 1 or self._selPage == 2)
    FGUI:setVisible(btn_refuse, self._selPage == 3)
    FGUI:setVisible(btn_agree, self._selPage == 3)

    if self._selPage == 1 then 
        FGUI:GButton_setBright(btn_join, true)
        FGUI:GButton_setGrey(btn_join, false)
        FGUI:setOnClickEvent(btn_join, handler(self, self.OnClickBtnJoin))
    elseif self._selPage == 2 then 
        FGUI:GButton_setBright(btn_join, true)
        FGUI:GButton_setGrey(btn_join, false)
        FGUI:setOnClickEvent(btn_join, handler(self, self.OnClickBtnJoin))
    elseif self._selPage == 3 then 
        FGUI:GButton_setBright(btn_agree, true)
        FGUI:GButton_setGrey(btn_agree, false)
        FGUI:GButton_setBright(btn_refuse, true)
        FGUI:GButton_setGrey(btn_refuse, false)
        FGUI:setOnClickEvent(btn_agree, handler(self, self.OnClickBtnAgree))
        FGUI:setOnClickEvent(btn_refuse, handler(self, self.OnClickBtnRefuse))
    end 
    FGUI:SetIntData(item, idx)
end

function PCTeamNearPanel:OnUpdateNearTeam()
    if not self._ui or not self._ui.list_team then return end

    self._nearList = {}
    if self._selPage == 1 then
        self._nearList = SL:GetValue("TEAM_RANDOM_LIST")
    elseif self._selPage == 2 then
        self._nearList = SL:GetValue("TEAM_NEAR_LIST")
    elseif self._selPage == 3 then
        local invitedData = SL:GetValue("TEAM_BEINVITED_LIST")
        for i, data in pairs(invitedData) do
            table.insert(self._nearList, data)
        end
    end
    FGUI:GList_setNumItems(self._ui.list_team, #self._nearList)

    self:RefreshNothingInfo()
end

function PCTeamNearPanel:RefreshNothingInfo()
    -- Directly control text_nothing visibility
    if #self._nearList == 0 then
        local sNothing = PAGE_DATA[self._selPage].nothing
        FGUI:setVisible(self._ui.text_nothing, true)
        FGUI:GTextField_setText(self._ui.text_nothing, sNothing)
    else
        FGUI:setVisible(self._ui.text_nothing, false)
    end
end

function PCTeamNearPanel:OnClickBtnJoin(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	local index = FGUI:GetIntData(eventData.sender.parent) + 1
	local data = self._nearList[index]
    if not data then 
        return
    end 

    local canJoin = self:CheckJoinCondition(data)
    if not canJoin then 
        return
    end 

    FGUI:GButton_setBright(eventData.sender, false)
    FGUI:GButton_setGrey(eventData.sender, true)
    SL:RequestApplyJoinTeam(data.MasterID)
end

function PCTeamNearPanel:OnClickBtnAgree(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	local index = FGUI:GetIntData(eventData.sender.parent) + 1
    local data = self._nearList[index]
    if not data then 
        return
    end 

    FGUI:GButton_setBright(eventData.sender, false)
    FGUI:GButton_setGrey(eventData.sender, true)
    SL:RequestAgreeTeamInvite(data.UserID)
    self:Close()
end

function PCTeamNearPanel:OnClickBtnRefuse(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	local index = FGUI:GetIntData(eventData.sender.parent) + 1
    local data = self._nearList[index]
    if not data then 
        return
    end 

    FGUI:GButton_setBright(eventData.sender, false)
    FGUI:GButton_setGrey(eventData.sender, true)
    SL:RequestRefuseTeamInvite(data.UserID)
    self:OnUpdateNearTeam()
end

function PCTeamNearPanel:OnClickBtnCreateTeam(event)
    local hasTeam = SL:GetValue("TEAM_COUNT") > 0
    if not hasTeam then  
        FGUI:Open("Team_pc", "PCTeamCreatePanel")
    end   
    self:Close() 
end

function PCTeamNearPanel:OnClickBtnRefresh(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    if self._selPage == 1 then 
        SL:RequestRandomTeam()
    elseif self._selPage == 2 then 
        SL:RequestNearTeam()
    end 
end

function PCTeamNearPanel:OnClickAutoInvited(context)
    local isSel = FGUI:GButton_getSelected(context.sender)
    SET_CLOUD_STORAGE_DATA("TEAM_AUTO_INVITED", isSel)
end


function PCTeamNearPanel:CheckJoinCondition(data)
    local myLevel = SL:GetValue("LEVEL")
    if myLevel < data.jlv and myLevel > data.jlvmax then
        SL:ShowSystemTips(GET_STRING(40010032))
        return false
    end

    local canJob = false
    local myJob = SL:GetValue("JOB")
    local tJob = string.split(data.JoinJob, ",")
    for i = 1, #tJob do 
        if myJob == tonumber(tJob[i]) then
            canJob = true
            break
        end 
    end 

    if not canJob then 
        SL:ShowSystemTips(GET_STRING(40010041))
        return false
    end 

    return true
end 


-----------------------------------注册事件--------------------------------------
function PCTeamNearPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_RANDOM_UPDATE, "PCTeamNearPanel", handler(self, self.OnUpdateNearTeam))
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_NEAR_UPDATE, "PCTeamNearPanel", handler(self, self.OnUpdateNearTeam))
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_BEINVITED_UPDATE, "PCTeamNearPanel", handler(self, self.OnUpdateNearTeam))
end

function PCTeamNearPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_RANDOM_UPDATE, "PCTeamNearPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_NEAR_UPDATE, "PCTeamNearPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_BEINVITED_UPDATE, "PCTeamNearPanel")

end

return PCTeamNearPanel