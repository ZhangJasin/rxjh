local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local ApplicationListPanel = class("ApplicationListPanel", BaseFGUILayout)

function ApplicationListPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)

	self:InitData()
	self:InitEvent()
	self:InitPage()
end

function ApplicationListPanel:InitData()
	self._recv = {} -- 收到的申请
	self._send = {} -- 我发出的申请
end

function ApplicationListPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_tab_1, function() FGUI:Controller_setSelectedIndex(self.pageController, 0) end) -- 收到
	FGUI:setOnClickEvent(self._ui.btn_tab_2, function() FGUI:Controller_setSelectedIndex(self.pageController, 1) end) -- 已发

	FGUI:GList_itemRenderer(self._ui.list_recv, handler(self, self.RecvRenderer))
	FGUI:GList_itemRenderer(self._ui.list_send, handler(self, self.SendRenderer))
end

function ApplicationListPanel:InitPage()
	FGUI:GList_setNumItems(self._ui.list_recv, 0)
	FGUI:GList_setNumItems(self._ui.list_send, 0)
end

-- 具体逻辑待完善
function ApplicationListPanel:Enter()
	self:RegisterEvent()
	-- if RequestMentorApplicationBox then
	-- 	RequestMentorApplicationBox()
	-- else
	-- 	RequestMentorRecvList()
	-- 	RequestMentorSendList()
	-- end
end

function ApplicationListPanel:Exit()
	self:RemoveEvent()
end

----------------------------------- 列表刷新 -----------------------------------
function ApplicationListPanel:OnRecvAppBox()
	--   MENTOR_APPBOX_RECV: { {AppID, UserID, UserName, Level, GuildName, Time, Job, AvatarID, PhotoframeID, Sex}, ... }
	--   MENTOR_APPBOX_SEND: { 同上 }
	--   "MENTOR_APPBOX_RECV" 和 "MENTOR_APPBOX_SEND" 待完善 消息获取
	self._recv = "MENTOR_APPBOX_RECV" or {}
	self._send = "MENTOR_APPBOX_SEND" or {}
	FGUI:GList_setNumItems(self._ui.list_recv, #self._recv)
	FGUI:GList_setNumItems(self._ui.list_send, #self._send)
end

function ApplicationListPanel:RecvRenderer(idx, item)
	local data = self._recv[idx + 1]
	if not data then return end

	local vatar      = FGUI:GetChild(item, "vatar")
	local icon_job   = FGUI:GetChild(item, "icon_job")
	local text_name  = FGUI:GetChild(item, "text_name")
	local text_level = FGUI:GetChild(item, "text_level")
	local text_guild = FGUI:GetChild(item, "text_guild")
	local text_time  = FGUI:GetChild(item, "text_time")
	local btn_info   = FGUI:GetChild(item, "btn_info")
	local btn_agree  = FGUI:GetChild(item, "btn_agree")
	local btn_refuse = FGUI:GetChild(item, "btn_refuse")

	FGUI:GTextField_setText(text_name,  data.UserName or "--")
	FGUI:GTextField_setText(text_level, "Lv." .. tostring(data.Level or 1))
	FGUI:GTextField_setText(text_guild, data.GuildName or "")
	FGUI:GTextField_setText(text_time,  data.Time or "")

	if vatar and FGUIFunction.SetCommonPlayerFrame then
		local A = { AvatarID = data.AvatarID, Job = data.Job, Sex = data.Sex, FrameID = data.PhotoframeID }
		FGUIFunction:SetCommonPlayerFrame(vatar, A)
	end
	FGUI:GLoader_setUrl(icon_job, FGUIFunction:GetJobUrl(data.Job))

	FGUI:setOnClickEvent(btn_info, function()
		local dockEnum = SL:GetValue("DOCKTYPE_NENUM") or {}
		FGUIFunction:OpenFuncDockTips({
			TipsType   = dockEnum.Func_Mentor or 0,
			targetName = data.UserName,
			targetId   = data.UserID,
			GuildName  = data.GuildName or "",
			FrameID    = data.PhotoframeID,
			AvatarID   = data.AvatarID,
		})
	end)
	FGUI:setOnClickEvent(btn_agree,  handler(self, self.OnClickAgree))
	FGUI:setOnClickEvent(btn_refuse, handler(self, self.OnClickRefuse))
	FGUI:SetIntData(item, idx)
end

function ApplicationListPanel:SendRenderer(idx, item)
	local data = self._send[idx + 1]
	if not data then return end

	local vatar      = FGUI:GetChild(item, "vatar")
	local icon_job   = FGUI:GetChild(item, "icon_job")
	local text_name  = FGUI:GetChild(item, "text_name")
	local text_level = FGUI:GetChild(item, "text_level")
	local text_guild = FGUI:GetChild(item, "text_guild")
	local text_time  = FGUI:GetChild(item, "text_time")
	local btn_info   = FGUI:GetChild(item, "btn_info")
	local btn_cancel = FGUI:GetChild(item, "btn_cancel")

	FGUI:GTextField_setText(text_name,  data.UserName or "--")
	FGUI:GTextField_setText(text_level, "Lv." .. tostring(data.Level or 1))
	FGUI:GTextField_setText(text_guild, data.GuildName or "")
	FGUI:GTextField_setText(text_time,  data.Time or "")

	if vatar and FGUIFunction.SetCommonPlayerFrame then
		local A = { AvatarID = data.AvatarID, Job = data.Job, Sex = data.Sex, FrameID = data.PhotoframeID }
		FGUIFunction:SetCommonPlayerFrame(vatar, A)
	end
	FGUI:GLoader_setUrl(icon_job, FGUIFunction:GetJobUrl(data.Job))

	FGUI:setOnClickEvent(btn_info, function()
		local dockEnum = SL:GetValue("DOCKTYPE_NENUM") or {}
		FGUIFunction:OpenFuncDockTips({
			TipsType   = dockEnum.Func_Mentor or 0,
			targetName = data.UserName,
			targetId   = data.UserID,
			GuildName  = data.GuildName or "",
			FrameID    = data.PhotoframeID,
			AvatarID   = data.AvatarID,
		})
	end)
	FGUI:setOnClickEvent(btn_cancel, handler(self, self.OnClickCancel))
	FGUI:SetIntData(item, idx)
end

----------------------------------- 按钮回调 -----------------------------------
function ApplicationListPanel:OnClickAgree(context)
	local index = FGUI:GetIntData(context.sender.parent) + 1
	local data  = self._recv[index]
	if not data then return end

	if RequestMentorAccept then
		RequestMentorAccept(data.AppID or data.appId)
	else
		error("No SL.RequestMentorAccept, please wire protocol here.")
	end
end

function ApplicationListPanel:OnClickRefuse(context)
	local index = FGUI:GetIntData(context.sender.parent) + 1
	local data  = self._recv[index]
	if not data then return end

	if RequestMentorReject then
		RequestMentorReject(data.AppID or data.appId)
	else
		error("111")
	end
end

function ApplicationListPanel:OnClickCancel(context)
	local index = FGUI:GetIntData(context.sender.parent) + 1
	local data  = self._send[index]
	if not data then return end

	-- if RequestMentorCancelApply then
	-- 	RequestMentorCancelApply(data.AppID or data.appId)
	-- else
	-- 	-- 与后端用 REJECT 取消
	-- 	error("111")
	-- end
end

----------------------------------- 事件 -----------------------------------
function ApplicationListPanel:RegisterEvent()
	SL:RegisterLUAEvent("LUA_EVENT_MENTOR_APPBOX_UPDATE", "ApplicationListPanel", handler(self, self.OnRecvAppBox))
end

function ApplicationListPanel:RemoveEvent()
	SL:UnRegisterLUAEvent("LUA_EVENT_MENTOR_APPBOX_UPDATE", "ApplicationListPanel")
end

return ApplicationListPanel
