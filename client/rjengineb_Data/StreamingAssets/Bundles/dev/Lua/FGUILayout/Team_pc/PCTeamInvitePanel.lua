local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCTeamInvitePanel = class("PCTeamInvitePanel", BaseFGUILayout)

local PAGE_DATA = {
	[1] = {name = "我的好友", page = 1, nothing = "暂无好友"},
	[2] = {name = "附近玩家", page = 2, nothing = "暂无玩家"},
	[3] = {name = "门派成员", page = 3, nothing = "暂无成员"},
}

function PCTeamInvitePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:setWindowDrag(self.component, self._ui.bg)

	self:InitData()
	self:InitEvent()
end 

function PCTeamInvitePanel:Close()
	self.super.Close(self)
end

function PCTeamInvitePanel:InitData()
    self._selPage = 1
    self._members = {}
    self._selUID = nil
    self._isLeader = false
    self._requestGuild = false
    self._requestFriend = false
end

function PCTeamInvitePanel:InitEvent()
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))

    -- page
    FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.PageRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)

    -- list
	FGUI:GList_itemRenderer(self._ui.list_player, handler(self, self.InviteListRenderer))
end

function PCTeamInvitePanel:Enter()
    self:SelectPage(1)
    self:RegisterEvent()
end

function PCTeamInvitePanel:Exit()
    self._requestGuild = false
    self._requestFriend = false
	self:RemoveEvent()
end

function PCTeamInvitePanel:PageRenderer(idx, item)
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

function PCTeamInvitePanel:OnClickPage(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
    self:SelectPage(index)
end

function PCTeamInvitePanel:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page, index - 1)
	self._selPage = index

    self:OnUpdateTeamMemberList()
end

function PCTeamInvitePanel:OnUpdateTeamMemberList(index)
    table.clear(self._members)
    local hasTeam = SL:GetValue("TEAM_COUNT") > 0
    if not hasTeam then  
        FGUI:GList_setNumItems(self._ui.list_player, 0)
        self:RefreshNothingInfo()
        return 
    end 

	local myUID = SL:GetValue("USER_ID")
	self._isLeader = SL:GetValue("TEAM_IS_LEADER", myUID)

    if self._selPage == 1 then -- 好友
        if not self._requestFriend then
            self._requestFriend = true
            SL:RequestFriendList()
        end
        local friendList = SL:GetValue("FRIEND_LIST")
        for _, v in pairs(friendList) do
            if v.Line == 1 and ((not v.GroupID) or v.GroupID <= 0) and (not SL:GetValue("TEAM_IS_MEMBER", tonumber(v.UserID))) then
                local data = {}
                data.uid = v.UserID
                data.name = v.UserName
                data.level = v.Level
                data.guildName = v.GuildName
                data.job = v.Job
                data.sex = v.Sex
                data.power = 0
                data.AvatarID = v.AvatarID
                data.PhotoframeID = v.PhotoframeID
                table.insert(self._members, data)
            end
        end
    elseif self._selPage == 2 then -- 附近
        local nearPlayer = SL:GetValue("FIND_IN_VIEW_PLAYER_LIST")
        for i = 1, #nearPlayer do
            local player = nearPlayer[i]
            -- 排除人形怪、有队伍的玩家、英雄
            if not (SL:GetValue("ACTOR_IS_HUMAN", player) or SL:GetValue("ACTOR_TEAM_STATE", player) ~= 0) then
                if not SL:GetValue("TEAM_IS_MEMBER", player) then
                    local data = {}
                    data.uid = player
                    data.name = SL:GetValue("ACTOR_NAME", player)
                    data.level = SL:GetValue("ACTOR_LEVEL", player)
                    data.job = SL:GetValue("ACTOR_JOB_ID", player)
                    data.sex = SL:GetValue("ACTOR_SEX", player)
                    data.power = 0
                    data.AvatarID = SL:GetValue("ACTOR_AVATAR", player)
                    data.PhotoframeID = SL:GetValue("ACTOR_AVATAR_FRAME", player)
                    table.insert(self._members, data)
                end
            end
        end
    elseif self._selPage == 3 then -- 门派
        if not self._requestGuild then
            self._requestGuild = true
            SL:RequestGuildMemberList()
        end
        local myUid = SL:GetValue("USER_ID")
        local guildName = SL:GetValue("GUILD_NAME")
        local guildMembers = SL:GetValue("GUILD_MEMBER_LIST") or {}
        for _, v in pairs(guildMembers) do
            if tonumber(v.UserID) ~= myUid and v.Line == 1 and ((not v.GroupID) or v.GroupID <= 0) and (not SL:GetValue("TEAM_IS_MEMBER", tonumber(v.UserID))) then
                local data = {}
                data.uid = v.UserID
                data.name = v.UserName
                data.level = v.Level
                data.guildName = guildName
                data.job = v.Job
                data.sex = v.Sex
                data.power = 0 
                data.AvatarID = v.AvatarID
                data.PhotoframeID = v.PhotoframeID
                table.insert(self._members, data)
            end
        end
    end
    FGUI:GList_setNumItems(self._ui.list_player, #self._members)
    self:RefreshNothingInfo()
end

function PCTeamInvitePanel:RefreshNothingInfo()
    FGUI:setVisible(self._ui.panel_nothing, #self._members == 0)
    if #self._members == 0 then 
        local sNothing = PAGE_DATA[self._selPage].nothing
        FGUI:GTextField_setText(self._ui.text_nothing, sNothing)
    end 
end

local AVATOR_DATA = {}
function PCTeamInvitePanel:InviteListRenderer(idx, item)
    if not self._members or not next(self._members) then  
        return 
    end 
    
    local index = idx + 1
    local member = self._members[index]
    if not member then 
        return 
    end

    local ui_name = FGUI:GetChild(item, "text_name")
    FGUI:GTextField_setText(ui_name, FGUIFunction:GetServerName(member.name))

    local ui_level = FGUI:GetChild(item, "text_level")
    FGUI:GTextField_setText(ui_level, "Lv："..member.level)

    local ui_avator = FGUI:GetChild(item, "avator")
    AVATOR_DATA.AvatarID = member.AvatarID
    AVATOR_DATA.Job = member.job
    AVATOR_DATA.Sex = member.sex
    AVATOR_DATA.FrameID = member.PhotoframeID
    FGUIFunction:SetCommonPlayerFrame(ui_avator, AVATOR_DATA)

    local ui_iconJob = FGUI:GetChild(item, "img_job")
    local pathJob = FGUIFunction:GetJobUrl(member.job)
    FGUI:GLoader_setUrl(ui_iconJob, pathJob)

    local ui_btnInvite = FGUI:GetChild(item, "btn_invite")
    FGUI:GButton_setBright(ui_btnInvite, true)
    FGUI:GButton_setGrey(ui_btnInvite, false)
    FGUI:setOnClickEvent(ui_btnInvite, function(eventData)
        FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

        self._selUID = member.uid
        SL:RequestInviteJoinTeam(self._selUID)
        FGUI:GButton_setBright(ui_btnInvite, false)
        FGUI:GButton_setGrey(ui_btnInvite, true)
    end)
end

-----------------------------------注册事件--------------------------------------
function PCTeamInvitePanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_NEAR_PLAYER_UPDATE, "PCTeamInvitePanel", handler(self, self.OnUpdateTeamMemberList))
end

function PCTeamInvitePanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_NEAR_PLAYER_UPDATE, "PCTeamInvitePanel")
end

return PCTeamInvitePanel