local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCMainTeam = class("PCMainTeam", BaseFGUILayout)

function PCMainTeam:Create()
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.PCMainTeam)
    self._team = FGUI:GetChild(self.component, "team")
	self._ui = FGUI:ui_delegate(self._team)

    self._memberCells = {}

    self._show = nil

    self._hideTrans = FGUI:GetTransition(self.component, "hide")
    self._hideCompleteHandler = handler(self, self.SetVisible, false)

    self._visible = false

    FGUI:setOnClickEvent(self._ui.Btn_createTeam, handler(self, self.OnCreateTeam))
    FGUI:setOnClickEvent(self._ui.Btn_joinTeam, handler(self, self.OnJoinTeam))
    FGUI:setOnClickEvent(self._ui.Btn_leaveTeam, handler(self, self.OnLeaveTeam))
    FGUI:setOnClickEvent(self._ui.Btn_teamList, handler(self, self.OnTeamList))

    FGUI:GList_itemRenderer(self._ui.List_team, handler(self, self.OnItemRendererTeam))
    FGUI:GList_addOnClickItemEvent(self._ui.List_team, handler(self, self.OnListTeamItemClick))
    FGUI:setOnClickEvent(self._ui.Btn_arrow, handler(self, self.Hide, true))

    FGUI:setDragable(self._ui.Loader_title, true)
    FGUI:setOnDragStartEvent(self._ui.Loader_title, handler(self, self.OnDragStart))
    FGUI:setOnDragEndEvent(self._team, handler(self, self.OnDragEnd))

    local x, y = FGUI:getPosition(self._team)
    FGUI:Transition_setKeyValue(self._hideTrans, "move", x, y)

    FGUI:setVisible(self._team, false)
end

function PCMainTeam:Enter()
    PCGameMain.team = self
    self:RegisterEvent()
    self._teamCount = SL:GetValue("TEAM_COUNT")
    if self._teamCount > 0 then
        self:Show(false)
    end
end

function PCMainTeam:Exit()
    self:RemoveEvent()
    PCGameMain.team = nil
end

function PCMainTeam:Destroy()
    self._ui = nil
    self._team = nil
end

----------------------------------------------------------------------------

function PCMainTeam:Show(tween)
    if self._show then return end
    self:SetShow(true)
    self:SetVisible(true)
    FGUI:Transition_stop(self._hideTrans, false, false)
    if tween then
        FGUI:Transition_playReverse(self._hideTrans)
    else
        FGUI:Transition_playReverse(self._hideTrans, nil, 1, 0, 0.5, -1)
    end
end

function PCMainTeam:Hide(tween)
    if not self._show then return end
    self:SetShow(false)
    FGUI:Transition_stop(self._hideTrans, false, false)
    if tween then
        FGUI:Transition_play(self._hideTrans, self._hideCompleteHandler)
    else
        FGUI:Transition_play(self._hideTrans, self._hideCompleteHandler, 1, 0, 0.5, -1)
    end
end

function PCMainTeam:SetShow(v)
    if v == self._show then return end
    self._show = v
    -- local assist = PCGameMain.assist
    -- if assist then
    --     if assist.OnTeamShowChange then
    --         assist:OnTeamShowChange(self._show)
    --     end
    -- end
end

function PCMainTeam:SetVisible(v)
    if self._visible == v then return end
    self._visible = v
    FGUI:setVisible(self._team, v)
    if v then
        --Enter
        self:RegisterTeamEvent()
        self:UpdateTeamMember()
    else
        --Exit
        self:RemoveTeamEvent()
    end
end

function PCMainTeam:IsShow()
    return self._show
end

function PCMainTeam:OnDragStart(context)
    FGUI:EventContext_preventDefault(context)
    FGUI:startDrag(self._team, FGUI:InputEvent_getTouchId(context))
end

function PCMainTeam:OnDragEnd(context)
    self:AdjustDragPosition()
    local x, y = FGUI:getPosition(self._team)
    FGUI:Transition_setKeyValue(self._hideTrans, "move", x, y)
end

function PCMainTeam:AdjustDragPosition()
    local winW, winH = FGUI:getSize(self.component)
    local x, y = FGUI:getPosition(self._team)
    local w, h = FGUI:getSize(self._team)
    local minX, minY = x, y
    local maxX = minX + w
    local maxY = minY + h
    local offset = false
    if minX < 0 then
        x = x - minX
        offset = true
    elseif maxX > winW then
        x = x - (maxX - winW)
        offset = true
    end
    if minY < 0 then
        y = y - minY
        offset = true
    elseif maxY > winH then
        y = y - (maxY - winH)
        offset = true
    end
    if offset then
        FGUI:setPosition(self._team, x, y)
    end
end

function PCMainTeam:OnUpdateTeamMember()
    local teamCount = SL:GetValue("TEAM_COUNT")
    local curTeamCount = self._teamCount
    if teamCount == self._teamCount then return end
    self._teamCount = teamCount
    if curTeamCount == 0 and teamCount > 0 then
        --进入队伍弹出队伍列表
        self:Show(true)
    elseif curTeamCount > 0 and teamCount == 0 then
        --退出队伍
        self:Hide(false)
    end
end

-------------------------------------------------------------------------------

function PCMainTeam:UpdateTeamMember()
    local memberList = SL:GetValue("TEAM_MEMBER_LIST")
    -- local isLeader = SL:GetValue("TEAM_IS_LEADER")
    local memberCount = #memberList
    local haveTeam = memberCount > 0

    local ctl = FGUI:getController(self._team, "state")
    if haveTeam then
        FGUI:Controller_setSelectedIndex(ctl, 0)
    else
        FGUI:Controller_setSelectedIndex(ctl, 1)
    end
    table.clear(self._memberCells)
    FGUI:GList_setNumItems(self._ui.List_team, memberCount)
    FGUI:GList_resizeToFit(self._ui.List_team)
end

function PCMainTeam:OnCreateTeam()
    local hasTeam = SL:GetValue("TEAM_COUNT") > 0
    if not hasTeam then
        FGUI:Open("Team_pc", "PCTeamCreatePanel")
    end 
end

function PCMainTeam:OnJoinTeam()
    FGUI:Open("Team_pc", "PCTeamNearPanel")
end

function PCMainTeam:OnLeaveTeam()
    SL:RequestLeaveTeam()
end

function PCMainTeam:OnTeamList()
    FGUI:Open("Team_pc", "PCTeamPanel")
end

function PCMainTeam:OnItemRendererTeam(index, item)
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

function PCMainTeam:UpdateMemberCellHead(ui, data)
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

function PCMainTeam:UpdateMemberCellState(ui, data)
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
function PCMainTeam:OnListTeamItemClick(context)
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

function PCMainTeam:UpdateMemberCellHpMp(ui, data)
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

function PCMainTeam:OnMemberStateChange(data)
    if not data then return end
    local cell = self._memberCells[data.UserID]
    if not cell then return end
    self:UpdateMemberCellState(cell, data)
end

function PCMainTeam:OnMemberHPMPChange(data)
    if not data then return end
    local cell = self._memberCells[data.UserID]
    if not cell then return end
    self:UpdateMemberCellHpMp(cell, data)
end

function PCMainTeam:OnChangeScene()
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

function PCMainTeam:OnCustomDataChange(actorID)
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
function PCMainTeam:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "PCMainTeam2", handler(self, self.OnUpdateTeamMember))
end
function PCMainTeam:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "PCMainTeam2")
end
function PCMainTeam:RegisterTeamEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "PCMainTeam", handler(self, self.UpdateTeamMember))
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_STATE_UPDATE, "PCMainTeam", handler(self, self.OnMemberStateChange))
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_HPMP_UPDATE, "PCMainTeam", handler(self, self.OnMemberHPMPChange))
    SL:RegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "PCMainTeam", handler(self, self.OnChangeScene))
    SL:RegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE,"PCMainTeam",handler(self, self.OnCustomDataChange))
    SL:RegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE,"PCMainTeam",handler(self, self.OnCustomDataChange))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA,"PCMainTeam",handler(self, self.OnCustomDataChange))
end

function PCMainTeam:RemoveTeamEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "PCMainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_STATE_UPDATE, "PCMainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_HPMP_UPDATE, "PCMainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "PCMainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE,"PCMainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE,"PCMainTeam")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA,"PCMainTeam")
end


return PCMainTeam