local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TeamSettingPanel = class("TeamSettingPanel", BaseFGUILayout)

local DEFAULT_LEVEL_MIN = 1
local DEFAULT_LEVEL_MAX = 100

local JOB_NAME = {GET_STRING(3011), GET_STRING(3012), GET_STRING(3013),GET_STRING(3014), GET_STRING(3015), GET_STRING(3016)}
local CAMP_NAME = {GET_STRING(40010050), GET_STRING(40010051), GET_STRING(40010052)}
local INVITE_NAME = {GET_STRING(40010059), GET_STRING(40010060)}
local APPLY_NAME = {GET_STRING(40010054), GET_STRING(40010053), GET_STRING(40010062)}
local PICK_DATA = {
	{name = GET_STRING(40010066), value = FGUIDefine.TeamPickType.Freedom},
	{name = GET_STRING(40010067), value = FGUIDefine.TeamPickType.Random},
	{name = GET_STRING(40010068), value = FGUIDefine.TeamPickType.Sequence},
	{name = GET_STRING(40010069), value = FGUIDefine.TeamPickType.Learder},
}


function TeamSettingPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)

	self:InitData()
	self:InitEvent()
end 

function TeamSettingPanel:Enter()
	self:OnUpdataSetting()
	self:RegisterEvent()
end 

function TeamSettingPanel:Exit()
	self:RemoveEvent()
end

function TeamSettingPanel:Close()
	self.super.Close(self)
end

function TeamSettingPanel:InitData()
	self._job = {true, true, true, true, true, true}
	self._campValue = 0
	self._allowInvite = 0
	self._autoValue = 1
	self._levelMin = 1
	self._levelMax = 100
	self._teamName = ""
	self._pickValue = 0
end

function TeamSettingPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.mask, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_reset, handler(self, self.OnClickBtnReset))
	FGUI:setOnClickEvent(self._ui.btn_save, handler(self, self.OnClickBtnSave))

	-- camp
	FGUI:GList_itemRenderer(self._ui.list_camp, handler(self, self.CampListRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.list_camp, handler(self, self.OnClickCamp))
	FGUI:GList_setNumItems(self._ui.list_camp, 3)

	-- job
	FGUI:GList_itemRenderer(self._ui.list_job, handler(self, self.JobListRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.list_job, handler(self, self.OnClickJob))
	FGUI:GList_setNumItems(self._ui.list_job, 6)

	-- player invite
	FGUI:GList_itemRenderer(self._ui.list_invite, handler(self, self.InviteListRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.list_invite, handler(self, self.OnClickInvite))
	FGUI:GList_setNumItems(self._ui.list_invite, 2)

	-- auto
	FGUI:GList_itemRenderer(self._ui.list_auto, handler(self, self.ApplyListRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.list_auto, handler(self, self.OnClickApply))
	FGUI:GList_setNumItems(self._ui.list_auto, #APPLY_NAME)
end

-- camp
function TeamSettingPanel:CampListRenderer(idx, item)
	local index = idx + 1
	FGUI:GButton_setSelected(item, idx == self._campValue)

	local text_name = FGUI:GetChild(item, "text_name")
	FGUI:GTextField_setText(text_name, CAMP_NAME[index])

end

function TeamSettingPanel:OnClickCamp(context)
	local idx = FGUI:GetChildIndex(self._ui.list_camp, context.data) 
	self._campValue = idx
end

-- job
function TeamSettingPanel:JobListRenderer(idx, item)
    local index = idx + 1
	FGUI:GButton_setSelected(item, self._job[index])

	local text_name = FGUI:GetChild(item, "text_name")
	FGUI:GTextField_setText(text_name, JOB_NAME[index])
end

function TeamSettingPanel:OnClickJob(context)
	local idx = FGUI:GetChildIndex(self._ui.list_job, context.data) 
    local index = idx + 1
	self._job[index] = not self._job[index]
end

-- invite
function TeamSettingPanel:InviteListRenderer(idx, item)
    local index = idx + 1
	FGUI:GButton_setSelected(item, idx == self._allowInvite)

	local text_name = FGUI:GetChild(item, "text_name")
	FGUI:GTextField_setText(text_name, INVITE_NAME[index])
end

function TeamSettingPanel:OnClickInvite(context)
	local idx = FGUI:GetChildIndex(self._ui.list_invite, context.data) 
	self._allowInvite = idx
end

-- apply
function TeamSettingPanel:ApplyListRenderer(idx, item)
    local index = idx + 1
	FGUI:GButton_setSelected(item, idx == self._autoValue)

	local text_name = FGUI:GetChild(item, "text_name")
	FGUI:GTextField_setText(text_name, APPLY_NAME[index])
end

function TeamSettingPanel:OnClickApply(context)
	local idx = FGUI:GetChildIndex(self._ui.list_auto, context.data) 
	self._autoValue = idx
end

function TeamSettingPanel:OnClickBtnReset()
	self:ResetSettingData()
	self:UpdataSettingUI()
	SL:ShowSystemTips(GET_STRING(40010044))
end

local data = {}
local function formatnumber(sNum)
	local s = sNum:reverse()
	local result = s:gsub("(%d)", "%1,")
	result = result:reverse():gsub("^,", "")
	return result
end 
function TeamSettingPanel:OnClickBtnSave()
	local teamName = FGUI:GTextField_getText(self._ui.input_name) or ""
    local levelMin = tonumber(FGUI:GTextField_getText(self._ui.input_min)) or 1
    local levelMax = tonumber(FGUI:GTextField_getText(self._ui.input_max)) or 100
	local sDesc = ""
	local sJob = ""
	for i, v in ipairs(self._job) do 
		if v == true then 
			sJob = sJob..i
		end 
	end 
	sJob = formatnumber(sJob)

	data.GroupName = teamName
	data.JoinLvMin = levelMin
	data.JoinLvMax = levelMax
	data.JoinJob = sJob
	data.JoinComp = tonumber(self._campValue)
	data.AllowInvite = tonumber(self._allowInvite)
	data.AutoJoin = tonumber(self._autoValue)
	data.PickType = self._pickValue
	data.JoinCondition = 0
	data.JoinMemo = sDesc
	SL:RequestSaveTeamSetting(data, function(isOK)
		-- 保存提示
		if isOK then
			SL:ShowSystemTips(GET_STRING(40010043))
		else
			SL:ShowSystemTips(GET_STRING(40010058))
		end
	end)

end

function TeamSettingPanel:UpdataSettingUI()
	-- team name 
    FGUI:GTextField_setText(self._ui.input_name, self._teamName)

	-- level
	FGUI:GTextField_setText(self._ui.input_min, self._levelMin)
    FGUI:GTextField_setText(self._ui.input_max, self._levelMax)

	-- list 
	FGUI:GList_setNumItems(self._ui.list_camp, 3)
	FGUI:GList_setNumItems(self._ui.list_job, 6)
	FGUI:GList_setNumItems(self._ui.list_invite, 2)
	FGUI:GList_setNumItems(self._ui.list_auto, 3)

	-- pick 
	local pickValue = self._pickValue or 0
	local name = PICK_DATA[pickValue + 1].name
    FGUI:GTextField_setText(self._ui.text_pick, name)
end

function TeamSettingPanel:ResetSettingData()
	for i = 1, 6 do 
		self._job[i] = true
	end 

	self._campValue = 0
	self._allowInvite = 0
	self._autoValue = 1
	self._levelMin = DEFAULT_LEVEL_MIN
	self._levelMax = DEFAULT_LEVEL_MAX
	self._teamName = string.format(GET_STRING(40010055), SL:GetValue("USER_NAME"))
end

function TeamSettingPanel:OnUpdataSetting()
	local data = SL:GetValue("TEAM_SETTING_DATA")
	if data and next(data) then 
		self._job = {false, false, false, false, false, false}
		local tJob = string.split(data.JoinJob, ",")
		for i, v in ipairs(tJob) do 
			local index = tonumber(v)
			if index then 
				self._job[index] = true
			end
		end

		local teamName  = data.GroupName
		if not teamName or teamName == "" then 
			teamName = string.format(GET_STRING(40010055), SL:GetValue("USER_NAME"))
		end
		self._campValue = tonumber(data.JoinComp)
		self._allowInvite = tonumber(data.AllowInvite)
		self._autoValue = tonumber(data.AutoJoin)
		self._levelMin = data.JoinLvMin
		self._levelMax = data.JoinLvMax
		self._pickValue = data.PickType
		self._teamName = teamName
	else 
		self:ResetSettingData()
	end 

	self:UpdataSettingUI()
end

-----------------------------------注册事件--------------------------------------
function TeamSettingPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_SETTING_UPDATE, "TeamSettingPanel", handler(self, self.OnUpdataSetting))
end

function TeamSettingPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_SETTING_UPDATE, "TeamSettingPanel")
end

return TeamSettingPanel