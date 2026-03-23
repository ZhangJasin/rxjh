local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainTeam = class("MainTeam", BaseFGUILayout)

function MainTeam:Create()
	self._ui = FGUI:ui_delegate(self.component)

    self._memberCells = {}

    FGUI:setOnClickEvent(self._ui.Btn_createTeam, handler(self, self.OnCreateTeam))
    FGUI:setOnClickEvent(self._ui.Btn_joinTeam, handler(self, self.OnJoinTeam))
    FGUI:setOnClickEvent(self._ui.Btn_teamInvite, handler(self, self.OnTeamInvite))
    FGUI:setOnClickEvent(self._ui.Btn_teamList, handler(self, self.OnTeamList))

    FGUI:GList_itemRenderer(self._ui.List_team, handler(self, self.OnItemRendererTeam))
    FGUI:GList_addOnClickItemEvent(self._ui.List_team, handler(self, self.OnListTeamItemClick))
end

function MainTeam:Enter()
	self:RegisterEvent()

    self:UpdateTeamMember()
end

function MainTeam:Exit()

	self:RemoveEvent()
end

function MainTeam:Destroy()
    self._ui = nil	
end

----------------------------------------------------------------------------

function MainTeam:UpdateTeamMember()
    local memberList = SL:GetValue("TEAM_MEMBER_LIST")
    local memberCount = #memberList
    local haveTeam = memberCount > 0
    FGUI:setVisible(self._ui.Group_noTeam, not haveTeam)
    FGUI:setVisible(self._ui.Group_haveTeam, haveTeam)

    table.clear(self._memberCells)
    FGUI:GList_setNumItems(self._ui.List_team, memberCount)
    self:UpdateInviteMember()
end

function MainTeam:UpdateInviteMember()
    local memberList = SL:GetValue("TEAM_MEMBER_LIST")
    local memberCount = #memberList
    local memberCountMax = SL:GetValue("TEAM_MAX_COUNT")
    FGUI:GButton_setTitle(self._ui.Btn_teamInvite, string.format(GET_STRING(40010070), memberCount, memberCountMax))
end

function MainTeam:OnCreateTeam()
    local hasTeam = SL:GetValue("TEAM_COUNT") > 0
    if not hasTeam then
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Open("Team_pc", "PCTeamCreatePanel")
        else
            FGUI:Open("Team", "TeamCreatePanel")
        end
    end 
end

function MainTeam:OnJoinTeam()
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Team_pc", "PCTeamNearPanel")
    else
        FGUI:Open("Team", "TeamNearPanel")
    end
end

function MainTeam:OnTeamInvite()
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Team_pc", "PCTeamInvitePanel")
    else
        FGUI:Open("Team", "TeamInvitePanel")
    end
end

function MainTeam:OnTeamList()
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Team_pc", "PCTeamPanel")
    else
        FGUI:Open("Team", "TeamPanel")
    end
end

function MainTeam:OnItemRendererTeam(index, item)
    local memberList = SL:GetValue("TEAM_MEMBER_LIST")
    local data = memberList[index + 1]
    if not data then return end
    local itemUI = FGUI:ui_delegate(item)
    self._memberCells[data.UserID] = itemUI
    FGUI:GTextField_setText(itemUI.Text_name, FGUIFunction:GetServerName(data.UserName))
    FGUI:setVisible(itemUI.Img_leader, data.Rank == 1)
    self:UpdateMemberCellHead(itemUI, data)
    self:UpdateMemberCellState(itemUI, data)
    self:UpdateMemberCellHpMp(itemUI, data)
end

function MainTeam:UpdateMemberCellHead(ui, data)
	if not ui then return end
    if not data then return end
	local headData = {}
    if data.UserID == SL:GetValue("USER_ID") then
        headData.AvatarID = SL:GetValue("AVATAR")
        headData.Job = SL:GetValue("JOB")
        headData.Sex = SL:GetValue("SEX")
        headData.FrameID = SL:GetValue("AVATAR_FRAME_DATA")
    else   
        headData.AvatarID = data.AvatarID
        headData.Job = data.Job
        headData.Sex = data.Sex
        headData.FrameID = data.PhotoframeID
    end
    FGUIFunction:SetCommonPlayerFrame(ui.header_icon, headData)
end

function MainTeam:UpdateMemberCellState(ui, data)
    if not ui then return end
    if not data then return end
    local ctl = FGUI:getController(ui.nativeUI, "state")
    FGUI:GTextField_setText(ui.Text_level, data.Level)
    if data.Line ~= 1 then
        FGUI:setGrey(ui.nativeUI, true)
        FGUI:Controller_setSelectedIndex(ctl, 2)
        return
    end
    local curMapId = SL:GetValue("MAP_ORIGIN_ID")
    local mapId = data.Map
    local mapStrs = string.split(mapId, "-")
    local mapId = mapStrs[1]
    local route = mapStrs[2]
    local isSameMap = data.Map == curMapId
    
    FGUI:setGrey(ui.nativeUI, false)
    FGUI:Controller_setSelectedIndex(ctl, isSameMap and 0 or 1)
    if not isSameMap then
        local mapName = SL:GetValue("MAP_NAME", mapId)
        if route then
            mapName = mapName .. string.format(GET_STRING(40041004), route)
        end
        FGUI:GTextField_setText(ui.Text_map, mapName)
    end
end

--点击队伍成员显示操作列表
function MainTeam:OnListTeamItemClick(context)
    local item = context.data
    if not item then return end
	local idx = FGUI:GetChildIndex(self._ui.List_team, item)
    if not idx or idx == -1 then return end
    local memberList = SL:GetValue("TEAM_MEMBER_LIST")
    local data = memberList[idx + 1]
    if not data then return end

    local inView = SL:GetValue("ACTOR_IN_VIEW", data.UserID)
    if not inView then 
        local data_ = {
            TipsType  = SL:GetValue("DOCKTYPE_NENUM").Func_Team,
            targetId = data.UserID,
            Level = data.Level,
            Job = data.Job,
            Sex = data.Sex,
            targetName = data.UserName,
            GuildName = data.GuildName or "",
            FrameID = data.PhotoframeID
        }
        FGUIFunction:OpenFuncDockTips(data_)
    else 
        SL:SetValue("SELECT_TARGET_ID", data.UserID)
    end 
end

function MainTeam:UpdateMemberCellHpMp(ui, data)
    if not ui then return end
    if not data then return end
    local hpPercent, mpPercent
    if (not data.MaxHP) or (data.MaxHP <= 0) then
        hpPercent = 100
    else
        hpPercent = 100 * data.HP / data.MaxHP
    end
    if (not data.MaxMP) or (data.MaxMP <= 0) then
        mpPercent = 0
    else
        mpPercent = 100 * data.MP / data.MaxMP
    end
    FGUI:GProgressBar_setValue(ui.ProgressBar_hp, hpPercent)
    FGUI:GProgressBar_setValue(ui.ProgressBar_mp, mpPercent)
end

function MainTeam:OnMemberStateChange(data)
    if not data then return end
    local cell = self._memberCells[data.UserID]
    if not cell then return end
    self:UpdateMemberCellState(cell, data)
end

function MainTeam:OnMemberHPMPChange(data)
    if not data then return end
    local cell = self._memberCells[data.UserID]
    if not cell then return end
    self:UpdateMemberCellHpMp(cell, data)
end

function MainTeam:OnChangeScene()
    local memberList = SL:GetValue("TEAM_MEMBER_LIST")
    if (not memberList) or (#memberList <= 0) then return end
    for _, member in pairs(memberList) do
        local uid = member.UserID
        local cell = self._memberCells[uid]
        if cell then
            self:UpdateMemberCellState(cell, member)
        end
    end
end

function MainTeam:OnCustomDataChange(actorID)
    if not SL:GetValue("TEAM_IS_MEMBER", actorID) then return end
	local memberList = SL:GetValue("TEAM_MEMBER_LIST")
	for _, member in pairs(memberList) do
		if member.UserID == actorID then
			local cell = self._memberCells[actorID]
    		if cell then
    		    self:UpdateMemberCellHead(cell, member)
    		end
		end
	end
end

-----------------------------------注册事件--------------------------------------
function MainTeam:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "MainTeam", handler(self, self.UpdateTeamMember))
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_STATE_UPDATE, "MainTeam", handler(self, self.OnMemberStateChange))
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_HPMP_UPDATE, "MainTeam", handler(self, self.OnMemberHPMPChange))
    SL:RegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MainTeam", handler(self, self.OnChangeScene))
    SL:RegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE,"MainTeam",handler(self, self.OnCustomDataChange))
    SL:RegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE,"MainTeam",handler(self, self.OnCustomDataChange))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA,"MainTeam",handler(self, self.OnCustomDataChange))
end

function MainTeam:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "MainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_STATE_UPDATE, "MainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_HPMP_UPDATE, "MainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE,"MainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE,"MainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA,"MainTeam")
end


return MainTeam