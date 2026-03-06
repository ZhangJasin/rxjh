local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local Store = requireFGUILayout("MentorShip/MentorShipData")
local FindApprenticePanel = class("FindApprenticePanel", BaseFGUILayout)
local MasterApprenticeShip = require("game_config/cfgcsv/MasterApprenticeShip")

local REFRESH_DEBOUNCE_SEC = 1.0

local function safe(v, fb)
	if v ~= nil then
		return v
	end
	return fb
end

function FindApprenticePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
	self._store = Store.Get()
	self:InitData()
	self:InitEvent()
	self:InitPage()
	FindApprenticePanelUI.CCUI = self
end

function FindApprenticePanel:Enter()
	self:RegisterEvent()
	self:_RequestList(false)
end

function FindApprenticePanel:Exit()
	self:ClearAllModels()
	self:RemoveEvent()
end

function FindApprenticePanel:InitData()
	self._list = {}
	self._raw  = nil
	self._itemModels = {}
	self._lastRefreshAt = 0
	self._requesting = false
end

function FindApprenticePanel:Close()
	self.super.Close(self)
end

function FindApprenticePanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_refresh, handler(self, self.OnClickRefresh))
	FGUI:setOnClickEvent(self._ui.btn_publish, handler(self, self.OnClickPublish))
	FGUI:setOnClickEvent(self._ui.btn_applylist, handler(self, self.OnClickApplylist))
	local search = FGUI:GetChild(self._ui.searchView,"search")
	FGUI:setOnClickEvent(search, handler(self, self.todoSearch))
	FGUI:GList_itemRenderer(self._ui.list_find, handler(self, self.FinderRenderer))
end

function FindApprenticePanel:todoSearch()
	local searchInput = FGUI:GetChild(self._ui.searchView,"searchText")
	local text = FGUI:GTextInput_getText(searchInput)
	self._store:RequestFindApprenticeList(text)
end

function FindApprenticePanel:InitPage()
	FGUI:GList_setNumItems(self._ui.list_find, 0)
end

function FindApprenticePanel:_RequestList(force)
	if self._requesting then
		return
	end
	self._requesting   = true
	self._store:RequestFindApprenticeList("*")
end

function FindApprenticePanel:OnRecvApprenticeList(evtPayload)
	self = FindApprenticePanelUI.CCUI
	self._raw  = evtPayload
	self._list = self:_NormalizeAndSort(evtPayload)
	local num = #self._list
	if num > MasterApprenticeShip['max_show_master'].VALUE then
		num = MasterApprenticeShip['max_show_master'].VALUE
	end
	FGUI:GList_setNumItems(self._ui.list_find, num)
	self._requesting = false
end

function FindApprenticePanel:getResult(data)
	
	self._raw  = data
	self._list = self:_NormalizeAndSort(data)
	FGUI:GList_setNumItems(self._ui.list_find, #self._list)
	self._requesting = false
end


function FindApprenticePanel:_NormalizeAndSort(raw)
	local arr = {}
	if type(raw) == "table" then
		if #raw > 0 then
			for _, v in ipairs(raw) do
				arr[#arr + 1] = self:_NormalizeOne(v)
			end
		else
			for _, v in pairs(raw) do
				arr[#arr + 1] = self:_NormalizeOne(v)
			end
		end
	end
	table.sort(arr, function(a, b)
		local ao, bo = (a.IsOnline and 1 or 0), (b.IsOnline and 1 or 0)
		if ao ~= bo then
			return ao > bo
		end
		local alv, blv = tonumber(a.Level or 0) or 0, tonumber(b.Level or 0) or 0
		if alv ~= blv then
			return alv > blv
		end
		return tostring(a.UserName or "") < tostring(b.UserName or "")
	end)
	return arr
end

function FindApprenticePanel:_NormalizeOne(v)
	local isOnline = v.IsOnline
	if isOnline == nil then
		isOnline = (v.online ~= nil) and (v.online and true or false) or false
	end
	return {
		UserID        = v.UserID or v.id or v.pid or 0,
		UserName      = v.UserName or v.name or "--",
		GuildName     = v.GuildName or v.guild or "",
		AvatarID      = v.AvatarID or v.avatar or 0,
		PhotoframeID  = v.PhotoframeID or v.frame or 0,
		Job           = v.Job or v.job or 0,
		Level         = v.Level or v.level or 1,
		Sex           = v.Sex or v.sex,
		MapName       = v.MapName or v.map,

		PublishGender = v.PublishGender,
		PublishOnline = v.PublishOnline,
		PublishMap    = v.PublishMap,
		IsOnline      = isOnline and true or false,
		bodyId = v.bodyId,
		headId = v.headId,
    	weaponId = v.rWeapon,
    	wingId = v.wingId,
		faceId = v.faceId,
		goodEvilid = v.goodEvilid
	}
end

----------------------------------------------------------------
-- 渲染
----------------------------------------------------------------
function FindApprenticePanel:FinderRenderer(idx, item)
	local data = self._list[idx + 1]
	if not data then
		return
	end

	local graph_model = FGUI:GetChild(item, "graph_model")
	local panel_touch = FGUI:GetChild(item, "panel_touch")
	local icon_job    = FGUI:GetChild(item, "icon_job")
	local btn_info    = FGUI:GetChild(item, "btn_info")
	local btn_apply   = FGUI:GetChild(item, "btn_apply")
	local text_name   = FGUI:GetChild(item, "text_name")
	local text_guild  = FGUI:GetChild(item, "text_guild")
	local text_gender = FGUI:GetChild(item, "text_gender")
	local text_online = FGUI:GetChild(item, "text_online")
	local text_map    = FGUI:GetChild(item, "text_map")
	local text_job    = FGUI:GetChild(item, "text_job")
	local text_level  = FGUI:GetChild(item, "text_level")

	FGUI:GTextField_setText(text_name,  safe(data.UserName, "--"))
	FGUI:GTextField_setText(text_guild, safe(data.GuildName, ""))

	local gender_str = safe(data.PublishGender, safe(data.Sex, "保密"))
	local online_str = safe(data.PublishOnline, data.IsOnline and "在线" or "离线")
	local map_str    = safe(data.PublishMap,    safe(data.MapName, "保密"))

	FGUI:GTextField_setText(text_gender, "性别：" .. tostring(gender_str))
	FGUI:GTextField_setText(text_online, "在线：" .. tostring(online_str))
	FGUI:GTextField_setText(text_map,    "地点：" .. tostring(map_str))

	local jobName = SL:GetMetaValue("JOB_NAME_BY_ID", data.Job) or ""
	FGUI:GTextField_setText(text_job,tostring(jobName))
	FGUI:GTextField_setText(text_level, "Lv." .. tostring(data.Level or 1))

	if icon_job then
		local url = FGUIFunction:GetJobUrl(data.Job)
		FGUI:GLoader_setUrl(icon_job, url or "")
	end

	if btn_info then
		FGUI:SetIntData(btn_info, idx)
		FGUI:setOnClickEvent(btn_info, handler(self, self.OnClickInfo))
	end
	if btn_apply then
		FGUI:SetIntData(btn_apply, idx)
		FGUI:setOnClickEvent(btn_apply, handler(self, self.OnClickApplyApprentice))
	end

	self:BindModelForItem(graph_model, panel_touch, data)
	FGUI:SetIntData(item, idx)
end

function FindApprenticePanel:OnClickRefresh()
	self:_RequestList(true)
end
function FindApprenticePanel:OnClickApplylist()
	--申请成为我的徒弟的列表
	FGUI:Open("MentorShip", "ShipApplyLists", { mode = 2 })
end
function FindApprenticePanel:OnClickPublish()
	--发布当徒弟出现在师傅列表里
	FGUI:Open("MentorShip", "FindPublishPanel", { mode = 1 })
end

function FindApprenticePanel:OnClickInfo(ctx)
	local idx  = FGUI:GetIntData(ctx.sender) + 1
	local data = self._list[idx]; if not data then return end
	local dockEnum = (SL and SL.GetValue and SL:GetValue("DOCKTYPE_NENUM")) or {}
	FGUIFunction:OpenFuncDockTips({
		targetId = tonumber(data.UserID),
		AvatarID = data.AvatarID,
		Job = data.Job,
		Sex = data.Sex,
		targetName = data.UserName,
		Level = data.Level,
		GuildName = data.GuildName,
		TipsType = isTeamMember and SL:GetValue("DOCKTYPE_NENUM").Func_Team or SL:GetValue("DOCKTYPE_NENUM").Func_Near_Player,
		FrameID = data.PhotoframeID
	})
end

function FindApprenticePanel:OnClickApplyApprentice(ctx)
	local idx  = FGUI:GetIntData(ctx.sender) + 1
	local data = self._list[idx]; if not data then return end

	local btn = ctx.sender
	-- FGUI:setTouchEnabled(btn, false)
	self._store:ApplyApprentice(data)
end

function FindApprenticePanel:BindModelForItem(graph_model, panel_touch, data)
	if not graph_model then return end

	local cached = self._itemModels[graph_model]
	if cached and cached.fguiModel then
		self:UIModel_Unbind(graph_model)
		self._itemModels[graph_model] = nil
	end

	local fguiModel = self:UIModel_Bind(graph_model)
	local extData = {}
	extData.sex = data.Sex
	extData.job = data.Job
	extData.bodyId = data.bodyId
	extData.helmetId = data.headId
    extData.weaponId = data.rWeapon
    extData.wingId = data.wingId
	extData.faceId = data.faceId
	local idx = FGUI:UIModel_addCharacterModel(fguiModel, extData, nil, nil, Vector3.one * 0.8)
	FGUI:UIModel_setModelCallback(fguiModel, function(midx)
		FGUI:UIModel_playAnimation(fguiModel, midx, "Idle", nil, 0)
		self:SetModelRotate(panel_touch, fguiModel, midx)
	end)

	self._itemModels[graph_model] = { fguiModel = fguiModel, modelIndex = idx }
end

function FindApprenticePanel:SetModelRotate(uiTouch, fguiModel, modelIndex)
	if not uiTouch or not fguiModel then return end
	local beginX, baseY = 0, 0
	local beginFunc = function(e)
		beginX = e.inputEvent.x
		local _, ay = fguiModel:GetObjectEulerAngles(modelIndex)
		baseY = ay or 0
		FGUI:EventContext_CaptureTouch(e)
	end
	local moveFunc = function(e)
		local curX = e.inputEvent.x or beginX
		local d = (curX - beginX)
		local ang = baseY - (d * 360 / 800)
		fguiModel:SetObjectEulerAngles(0, ang, 0, modelIndex)
	end
	local endFunc = function() beginX, baseY = 0, 0 end
	FGUI:setOnTouchEvent(uiTouch, beginFunc, moveFunc, endFunc)
end

function FindApprenticePanel:ClearAllModels()
	for graph, rec in pairs(self._itemModels) do
		self:UIModel_Unbind(graph)
	end
	self._itemModels = {}
end

function FindApprenticePanel:RegisterEvent()
	SL:RegisterLUAEvent("LUA_EVENT_FIND_APPRENTICE_UPDATE", "FindApprenticePanel", handler(self, self.OnRecvApprenticeList))
end

function FindApprenticePanel:RemoveEvent()
	SL:UnRegisterLUAEvent("LUA_EVENT_FIND_APPRENTICE_UPDATE", "FindApprenticePanel")
end

function FindApprenticePanel:RefreshNow()
	self:_RequestList(true)
end

return FindApprenticePanel
