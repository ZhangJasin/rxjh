local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TeamPanel = class("TeamPanel", BaseFGUILayout)

local SHOUT_CD = 3
local CHANNEL = SLDefine.CHAT_CHANNEL
local MSGTYPE = SLDefine.CHAT_MSG_TYPE
local AVATOR_DATA = {}

function TeamPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)

	self:InitData()
	self:InitEvent()
end 

function TeamPanel:Close()
	self.super.Close(self)
end

function TeamPanel:Enter()
	self:RefreshTeamUI()
	self:OnUpdateMemberList()
	self:UpdateTargetInfo()
	self:UpdateChatView()
    self:RegisterEvent()

	SL:ComponentAttach(SLDefine.SUIComponentTable.Team, self._ui.Node_attach)
end 

function TeamPanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.Team)

	self._cdTime = nil
	self._messages = nil
	self:RemoveEvent()
end

function TeamPanel:InitData()
	self._memberList = {}
	self._isLeader = false
	self._cdTime = nil
	self._messages = nil
	self.emojiCfgs = SL:GetValue("CHAT_EMOJI")
end

function TeamPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_quit, function ()
		SL:RequestLeaveTeam()
		self:Close()
	end)

	FGUI:setOnClickEvent(self._ui.btn_apply, function ()
		FGUI:Open("Team", "TeamApplyPanel")
	end)

	FGUI:setOnClickEvent(self._ui.btn_setting, function ()
		FGUI:Open("Team", "TeamSettingPanel")
	end)

	FGUI:setOnClickEvent(self._ui.btn_edit, function ()
		FGUI:Open("Team", "TeamTargetPanel")
	end)

    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_help, handler(self, self.OnClickHelp))
	FGUI:setOnClickEvent(self._ui.btn_shout, handler(self, self.OnClickShout))
	FGUI:setOnClickEvent(self._ui.btn_chat, handler(self, self.OnSendMessage))
    FGUI:setOnClickEvent(self._ui.btn_pos, handler(self, self.OnSendPostion))

	-- member
	FGUI:GList_itemRenderer(self._ui.list_team, handler(self, self.TeamMemberRenderer))

    -- list chat 
    FGUI:GList_itemProvider(self._ui.list_chat, handler(self, self.OnProviderChat))
	FGUI:GList_itemRenderer(self._ui.list_chat, handler(self, self.OnRendererChat))

    -- list emoj
    local listEmoj = FGUI:GetChild(self._ui.btn_emoj, "list_emoj")
    if listEmoj then 
        FGUI:GList_itemRenderer(listEmoj, handler(self, self.OnRendererEmoj))
        FGUI:GList_addOnClickItemEvent(listEmoj, handler(self, self.OnClickItemEmoj))
        FGUI:GList_setNumItems(listEmoj, #self.emojiCfgs)
    end 
end

function TeamPanel:OnUpdateMemberList()
    self._memberList = SL:GetValue("TEAM_MEMBER_LIST")
	if #self._memberList == 0 then 
        FGUI:GTextField_setText(self._ui.text_nobody, GET_STRING(40010038))
		FGUI:GList_setNumItems(self._ui.list_team, 0)
	else 
        FGUI:GTextField_setText(self._ui.text_nobody, "")
		local maxCount = SL:GetValue("TEAM_MAX_COUNT")
		FGUI:GList_setNumItems(self._ui.list_team, maxCount)
	end 
end

function TeamPanel:TeamMemberRenderer(idx, item)
	local index = idx + 1
	local frame_team = FGUI:GetChild(item, "frame_team")
	local btn_add = FGUI:GetChild(item, "btn_add")
    local data = self._memberList and self._memberList[index]
	FGUI:setVisible(frame_team, data ~= nil)
	FGUI:setVisible(btn_add, data == nil)
	FGUI:SetIntData(item, idx)
	if data then
        local ui_avator = FGUI:GetChild(item, "avator")

        if data.UserID == SL:GetValue("USER_ID") then
            AVATOR_DATA.AvatarID = SL:GetValue("AVATAR")
            AVATOR_DATA.Job = SL:GetValue("JOB")
            AVATOR_DATA.Sex = SL:GetValue("SEX")
            AVATOR_DATA.FrameID = SL:GetValue("AVATAR_FRAME_DATA")
        else
            AVATOR_DATA.AvatarID = data.AvatarID
            AVATOR_DATA.Job = data.Job
            AVATOR_DATA.Sex = data.Sex
            AVATOR_DATA.FrameID = data.PhotoframeID
        end
        FGUIFunction:SetCommonPlayerFrame(ui_avator, AVATOR_DATA)
		local img_leader = FGUI:GetChild(item, "img_leader")
		FGUI:setVisible(img_leader, data.Rank == 1)

		local text_name = FGUI:GetChild(item, "text_name")
		FGUI:GTextField_setText(text_name, FGUIFunction:GetServerName(data.UserName))

		local text_level = FGUI:GetChild(item, "text_level")
		FGUI:GTextField_setText(text_level, "LV："..data.Level)

		local img_job = FGUI:GetChild(item, "img_job")
		local pathJob = FGUIFunction:GetJobUrl(data.Job)
		FGUI:GLoader_setUrl(img_job, pathJob)
		
		FGUI:setOnClickEvent(frame_team, handler(self, self.OnClickOpenFuncDock))
	else 
		FGUI:setOnClickEvent(btn_add, handler(self, self.OnClickOpenInvite))
	end 
end

-- list chat
function TeamPanel:UpdateChatView()
	local maxChatCount = FGUI:GList_getNumItems(self._ui.list_chat)
	if maxChatCount > 100 then
		FGUI:GList_removeChildToPoolAt(self._ui.list_chat, 0)
	end
	self._messages = {}
	local msgList = SL:GetValue("CHAT_CACHE", CHANNEL.Team) 
	for i, msg in ipairs(msgList) do     
		if msg.UserName ~= "" then 
			table.insert(self._messages, msg)
		end 
	end 
	FGUI:GList_setNumItems(self._ui.list_chat, #self._messages)
end

function TeamPanel:OnProviderChat(idx)
    if not self._messages or not next(self._messages) then 
        return 
    end

    local index = idx + 1
    local data = self._messages[index]
    if not data then 
        return 
    end

    local isSelf = SL:GetValue("USER_ID") == data.UserID
    if isSelf then
        return "ui://xh57ov19k9rf2"
    else
        return "ui://xh57ov19k9rf3"   
    end
end

function TeamPanel:OnRendererChat(idx, item)
    if not self._messages or not next(self._messages) then 
        return 
    end

    local index = idx + 1
    local data = self._messages[index]
    if not data then 
        return 
    end

    local ui_name = FGUI:GetChild(item, "text_name")
    FGUI:GTextField_setText(ui_name, FGUIFunction:GetServerName(data.UserName))

    local ui_avator = FGUI:GetChild(item, "avator")
    AVATOR_DATA.AvatarID = data.AvatarID
    AVATOR_DATA.Job = data.Job
    AVATOR_DATA.Sex = data.Sex
    AVATOR_DATA.FrameID = data.PhotoframeID
    FGUIFunction:SetCommonPlayerFrame(ui_avator, AVATOR_DATA)

    local ui_frame = FGUI:GetChild(item, "Image_chatFrame")
    local frameURL = FGUIFunction:GetChatFrameUrl(data.ChatBID)
    FGUI:GLoader_setUrl(ui_frame, frameURL, nil, true)

    local rich_msg = FGUI:GetChild(item, "rich_msg")
    if data.MT == MSGTYPE.Position then
		local mapData = data.Msg
        local mapName = mapData.mapName
    	local mapX = mapData.mapX
		local mapY = mapData.mapY
		local route = mapData.route or 1
		local posRGB = SL:GetColorByStyleId(218)
		local msg = string.format("[U][color=%s][url=][%s-%s %s,%s][/url][/color][/U]", posRGB, mapName, route, mapX, mapY)
		FGUI:GRichTextField_setText(rich_msg,msg)
		FGUI:GRichTextField_setOnLinkClickEvent(rich_msg, handler(self, self.OnClickPositionLink))
    else 
        FGUI:GRichTextField_setText(rich_msg, SL:ChatParser_Parse(data.Msg))
    end
    
    FGUI:GList_ScrollToView(self._ui.list_chat,idx)
    FGUI:SetIntData(item, idx)
end

-- list emoj
function TeamPanel:OnRendererEmoj(idx, item)
    local index = idx + 1
    local data = self.emojiCfgs[index]
    if not data then 
        return 
    end 

    local imgEmoj = FGUI:GetChild(item, "img_emoj")
    FGUI:GLoader_setUrl(imgEmoj, "ui://public/"..index)
end

function TeamPanel:OnClickItemEmoj(context)
    local listEmoj = FGUI:GetChild(self._ui.btn_emoj, "list_emoj")
    if listEmoj then 
        local idx = FGUI:GetChildIndex(listEmoj, context.data) 
        FGUI:GList_setSelectedIndex(listEmoj, idx)
        local index = idx + 1
        local eData = self.emojiCfgs[index]
        if eData then
            FGUI:GTextInput_replaceSelection(self._ui.input_chat,string.format("[%s]",eData.replace))
        end
    end
end

function TeamPanel:OnSendMessage()
    local msg = FGUI:GTextField_getText(self._ui.input_chat)
    if string.len(msg) <= 0 then
        SL:ShowSystemTips(GET_STRING(40000103))
        return
    end
    FGUI:GTextField_setText(self._ui.input_chat, "")

	SL:RequestSendChatMsg(msg, CHANNEL.Team)
end

function TeamPanel:OnSendPostion()
    SL:RequestSendChatPosMsg(CHANNEL.Team)
end

function TeamPanel:RefreshTeamUI()
	local myUID = SL:GetValue("USER_ID")
	self._isLeader = SL:GetValue("TEAM_IS_LEADER", myUID)
	FGUI:setVisible(self._ui.btn_edit, self._isLeader)
	FGUI:setVisible(self._ui.btn_apply, self._isLeader)
	FGUI:setVisible(self._ui.btn_shout, self._isLeader)
	FGUI:setVisible(self._ui.btn_setting, self._isLeader)
end 

function TeamPanel:OnClickOpenFuncDock(context)
	local index = FGUI:GetIntData(context.sender.parent) + 1
	local data = self._memberList[index]
    if not data then 
        return
    end 
	-- 屏蔽自己的信息
	if data.UserID == SL:GetValue("USER_ID") then
        return
    end
	
	local model_player = context.sender
	FGUIFunction:OpenFuncDockTips({
		TipsType = SL:GetValue("DOCKTYPE_NENUM").Func_TeamLayer,
		targetId = data.UserID,
		targetName = data.UserName,
		Level = data.Level,
		Job = data.Job,
		Sex = data.Sex,
		GuildName = data.GuildName,
		Pos = {x = FGUI:getPositionX(model_player) + 20, y = FGUI:getPositionY(model_player)},
        FrameID = data.PhotoframeID,
	})
end

function TeamPanel:OnClickOpenInvite(context)
	FGUI:Open("Team", "TeamInvitePanel")
end

function TeamPanel:OnClickShout(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
	local nowTime = os.time()
    if self._cdTime and self._cdTime > nowTime then
        SL:ShowSystemTips(GET_STRING(40010030))
        return
    end

	local input = "Team"
	local channel = CHANNEL.World
    local teamCount = SL:GetValue("TEAM_COUNT")
    local teamMaxCount = SL:GetValue("TEAM_MAX_COUNT")
    if teamCount <= 0 then
        SL:ShowSystemTips(GET_STRING(40010002))
        return
    end
    if teamCount >= teamMaxCount then
        SL:ShowSystemTips(GET_STRING(40010013))
        return
    end
    local masterID = SL:GetValue("TEAM_MASTER_ID")
    local param = {
        type = 1,
        count = teamCount,
        max = teamMaxCount,
        uid = masterID
    }
    SL:RequestSendChatExtMsg(input, channel, param, function(success)
        if success then
            SL:ShowSystemTips(GET_STRING(40010029))
            self._cdTime = nowTime + SHOUT_CD
        end
    end)
end

function TeamPanel:OnClickPositionLink(context)
    local index = FGUI:GetIntData(context.sender.parent) + 1
    local data = self._messages[index]
    if not data then 
        return 
    end

    if data.MT == MSGTYPE.Position then
        local mapData = data.Msg
        local mapName = mapData.mapName
        local mapID = mapData.mapID
        local mapX = mapData.mapX
        local mapY = mapData.mapY
        SL:SetValue("BATTLE_AUTO_MOVE_BEGIN",  mapID, mapX, mapY)
    end
end

local helpData = {}
function TeamPanel:OnClickHelp()
	helpData.title = GET_STRING(40010045)
	helpData.str = GET_STRING(40010046)
	SL:OpenCommonHelpDialog(helpData)
end

-- 目标信息
function TeamPanel:UpdateTargetInfo()
    local settingData = SL:GetValue("TEAM_SETTING_DATA")
    local data = {
        name = GET_STRING(40010047),
        minLv = settingData.JoinLvMin or (SL:GetValue("GAME_DATA", "DefaultTeamLevelMin") or 1),
        maxLv = settingData.JoinLvMax or (SL:GetValue("GAME_DATA", "DefaultTeamLevelMax") or 100),
        count = SL:GetValue("TEAM_MAX_COUNT")
    }

	local str = data.name.."   "..string.format(GET_STRING(40010048), data.minLv, data.maxLv)
	FGUI:GTextField_setText(self._ui.text_goal, str)
end

function TeamPanel:OnCustomDataChange(actorID)
    if not SL:GetValue("TEAM_IS_MEMBER", actorID) then return end
    self:OnUpdateMemberList()
end

function TeamPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "TeamPanel", handler(self, self.OnUpdateMemberList))
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_TARGET_INFO, "TeamPanel", handler(self, self.UpdateTargetInfo))
    SL:RegisterLUAEvent(LUA_EVENT_CHAT_ADD_MSG, "TeamPanel", handler(self, self.UpdateChatView))
    SL:RegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE,"TeamPanel",handler(self, self.OnCustomDataChange))
    SL:RegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE,"TeamPanel",handler(self, self.OnCustomDataChange))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA,"TeamPanel",handler(self, self.OnCustomDataChange))
end

function TeamPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "TeamPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_TARGET_INFO, "TeamPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_CHAT_ADD_MSG, "TeamPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE,"TeamPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE,"TeamPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA,"TeamPanel")
end

return TeamPanel