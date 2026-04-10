local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TeamCreatePanel = class("TeamCreatePanel", BaseFGUILayout)

local APPLY_NAME = {GET_STRING(40010054), GET_STRING(40010053), GET_STRING(40010062)}
local PICK_DATA = {
	{name = GET_STRING(40010066), value = FGUIDefine.TeamPickType.Freedom},
	{name = GET_STRING(40010067), value = FGUIDefine.TeamPickType.Random},
	{name = GET_STRING(40010068), value = FGUIDefine.TeamPickType.Sequence},
	{name = GET_STRING(40010069), value = FGUIDefine.TeamPickType.Learder},
}

function TeamCreatePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)

	self:InitData()
	self:InitEvent()
end 

function TeamCreatePanel:Enter()
	self:UpdataCreateUI()
	self:RegisterEvent()
end 

function TeamCreatePanel:Exit()
	self._pickValue = 0
	self._autoValue = 1
	self:RemoveEvent()
end

function TeamCreatePanel:Close()
	self.super.Close(self)
end

function TeamCreatePanel:InitData()
	self._pickValue = 0
	self._autoValue = 1

	local myName = SL:GetValue("USER_NAME")
	self._teamName = string.format(GET_STRING(40010055), myName)
end

function TeamCreatePanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.mask, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.bg, handler(self, self.OnClickBg))
	FGUI:setOnClickEvent(self._ui.btn_save, handler(self, self.OnClickBtnSave))
	FGUI:setOnClickEvent(self._ui.btn_pick, handler(self, self.OnClickBtnPick))

	-- pick
	FGUI:GList_itemRenderer(self._ui.list_pick, handler(self, self.PickListRenderer))
	FGUI:GList_addOnClickItemEvent(self._ui.list_pick, handler(self, self.OnClickPickItem))


	-- auto
	FGUI:GList_itemRenderer(self._ui.list_auto, handler(self, self.AutoApplyRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.list_auto, handler(self, self.OnClickAuto))
end

-- pick
function TeamCreatePanel:OnClickBg()
	FGUI:setVisible(self._ui.list_pick, false)
end

function TeamCreatePanel:OnClickBtnPick()
	FGUI:setVisible(self._ui.list_pick, not FGUI:getVisible(self._ui.list_pick))
end

function TeamCreatePanel:PickListRenderer(idx, item)
	local index = idx + 1
	local data = PICK_DATA[index]
	if not data then 
		return 
	end 

	FGUI:GButton_setTitle(item, data.name)
end

function TeamCreatePanel:OnClickPickItem()
	local idx = FGUI:GList_getSelectedIndex(self._ui.list_pick)
	local index = idx + 1
	self._pickValue = idx

	FGUI:GTextField_setText(self._ui.text_pick, PICK_DATA[index].name)
	FGUI:setVisible(self._ui.list_pick, false)
end

-- auto
function TeamCreatePanel:AutoApplyRenderer(idx, item)
    local index = idx + 1
    -- 当 self._autoValue 为 -1 时，所有 checkbox 都不选中
	FGUI:GButton_setSelected(item, idx == self._autoValue)

	local text_name = FGUI:GetChild(item, "text_name")
	FGUI:GTextField_setText(text_name, APPLY_NAME[index])
end

function TeamCreatePanel:OnClickAuto(context)
	local idx = FGUI:GetChildIndex(self._ui.list_auto, context.data)
	
	-- 如果点击的是当前已选项，则取消选中（设置为 -1 或 nil）
	if idx == self._autoValue then
		self._autoValue = -1
	else
		self._autoValue = idx
	end
	
	-- 刷新列表显示
	FGUI:GList_setNumItems(self._ui.list_auto, #APPLY_NAME)
end

function TeamCreatePanel:OnClickBtnSave(eventData)
	local teamName = FGUI:GTextInput_getText(self._ui.input_name)
	teamName = string.trim(teamName)
	if string.len(teamName) <= 0 then 
		SL:ShowSystemTips(GET_STRING(40010056))
		return 
	end 

	SL:RequestCreateTeam(self._pickValue, self._autoValue, teamName)
	self:Close()
end

function TeamCreatePanel:UpdataCreateUI()
	-- team name 
    FGUI:GTextField_setText(self._ui.input_name, self._teamName)

	-- pick 
	local index = self._pickValue + 1
    FGUI:GTextField_setText(self._ui.text_pick, PICK_DATA[index].name)
	FGUI:GList_setNumItems(self._ui.list_pick, #PICK_DATA)
	FGUI:GList_setSelectedIndex(self._ui.list_pick, 0)
	FGUI:setVisible(self._ui.list_pick, false)

	-- auto 
	FGUI:GList_setNumItems(self._ui.list_auto, #APPLY_NAME)
end

function TeamCreatePanel:OnUpdataCreate()
	local data = SL:GetValue("TEAM_SETTING_DATA")
	if data and next(data) then 
		self._autoValue = tonumber(data.AutoJoin)
		self._teamName = data.GroupName
	end 

	self:UpdataCreateUI()
end

-----------------------------------注册事件--------------------------------------
function TeamCreatePanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_SETTING_UPDATE, "TeamCreatePanel", handler(self, self.OnUpdataCreate))
end

function TeamCreatePanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_SETTING_UPDATE, "TeamCreatePanel")
end

return TeamCreatePanel