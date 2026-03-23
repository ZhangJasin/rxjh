local PCSettingPageBase = requireFGUILayout("Setting_pc/PCSettingPageBase")
local PCSettingKeyBoardPanel = class("PCSettingKeyBoardPanel", PCSettingPageBase)

function PCSettingKeyBoardPanel:Enter()
    PCSettingKeyBoardPanel.super.Enter(self)
    self._packageName = "Setting_pc"
    if not self.component then
        release_log_traceback("ERROR PCSettingKeyBoardPanel component is nil. packageName:"..self._packageName)
        return
    end
    self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:InitEvent()
    self:RefreshPanel()
end

function PCSettingKeyBoardPanel:Exit()
    PCSettingKeyBoardPanel.super.Exit(self)
    SL:UnRegisterLUAEvent(LUA_EVENT_KEY_SETTING_CAHNGE, "PCSettingKeyBoardPanel")
end

function PCSettingKeyBoardPanel.Create()
    return PCSettingKeyBoardPanel.new()
end

function PCSettingKeyBoardPanel:InitData()
    self._settings = SettingKey.GetShowSettings()
	self._inputId = nil
	self._inputLen = 0
	self._inputMap = {}
	self._inputs = {}
	self._functionKeys = 
	{
		["KEY_SHIFT"] = true,
		["KEY_CTRL"] = true,
		["KEY_ALT"] = true,
		["KEY_RIGHT_ALT"] = true,
		["KEY_RIGHT_CTRL"] = true,
		["KEY_RIGHT_SHIFT"] = true,
	}
	FGUI:addOnClickEvent(self._ui.Btn_reset, handler(self, self.OnReset))

	FGUI:GList_itemRenderer(self._ui.List_key, handler(self, self.OnListKeyRender))
end

function PCSettingKeyBoardPanel:InitEvent()
    SL:RegisterLUAEvent(LUA_EVENT_KEY_SETTING_CAHNGE, "PCSettingKeyBoardPanel", handler(self, self.OnKeySettingChange))
end

function PCSettingKeyBoardPanel:RefreshPanel()
	FGUI:GList_setNumItems(self._ui.List_key, #self._settings)
	FGUI:GTextField_setText(self._ui.tips, GET_STRING(80000603))
end

function PCSettingKeyBoardPanel:OnListKeyRender(idx, item)
    local index = idx + 1
	local data = self._settings[index]
	if not data then return end 

	local ui_name = FGUI:GetChild(item, "Text_name")
	FGUI:GTextField_setText(ui_name, data.name)

	local ui_key = FGUI:GetChild(item, "Input_key")
	FGUI:GTextInput_setEditable(ui_key, false)
	FGUI:GTextInput_setText(ui_key, data.keysStr)
	if data.keysStr == "" or data.enable == 2 then
		FGUI:GTextField_setColor(ui_key, "#666666")
	else
		FGUI:GTextField_setColor(ui_key, "#FFFFFF")
	end
	FGUI:setVisible(FGUI:GetChild(item, "item_selected"), true)
	FGUI:setVisible(FGUI:GetChild(item, "item_unselected"), false)
	FGUI:setTouchEnabled(item, data.enable ~= 2)
	FGUI:setOnKeyDown(ui_key, handler(self, self.OnKeyDown))
	FGUI:setOnKeyUp(ui_key, handler(self, self.OnKeyUp))
	FGUI:setOnFocusIn(ui_key, handler(self, self.OnFocusIn, data))
	FGUI:setOnFocusOut(ui_key, handler(self, self.OnFocusOut, data))
end

function PCSettingKeyBoardPanel:OnFocusIn(settingData, context)
	local input = context.sender
	local item = FGUI:GetParent(input)
	FGUI:setVisible(FGUI:GetChild(item, "item_selected"), false)
	FGUI:setVisible(FGUI:GetChild(item, "item_unselected"), true)
	FGUI:GTextField_setColor(input, "#000000")
	local id = settingData.id
	if self._inputId == id then return end
	self._inputId = id
	self._inputLen = 0
	self._inputIsEmpty = true
	table.clear(self._inputMap)
	table.clear(self._inputs)
	
	if settingData then
		local value = string.format(GET_STRING(80000602), settingData.name)
		FGUI:GTextField_setText(self._ui.tips, value)
	end
end

function PCSettingKeyBoardPanel:OnFocusOut(settingData, context)
	self:OnSetCustomKeyEnd(context)
end

function PCSettingKeyBoardPanel:OnKeyDown(context)
	local keyName = FGUI:InputEvent_getKeyCode(context)
	if not keyName then return end
	if keyName == "KEY_NONE" then return end
	if keyName == "KEY_DELETE" or keyName == "KEY_BACKSPACE" then
		table.clear(self._inputMap)
		table.clear(self._inputs)
		self._inputIsEmpty = false
		self:OnSetCustomKeyEnd(context)
		return
	end
	local isDirty = false
	if not self._inputMap[keyName] then
		isDirty = true
	end
	self:SetKeyDown(keyName)
	if isDirty then
		local input = context.sender
		FGUI:GTextInput_setText(input, SettingKey.GetKeysStr(self._inputs))
		if not self:CheckKey() then
			FGUI:GTextField_setColor(input, "#860000")
		else
			FGUI:GTextField_setColor(input, "#000000")
		end
	end
end

function PCSettingKeyBoardPanel:OnKeyUp(context)
	local keyName = FGUI:InputEvent_getKeyCode(context)
	if not keyName then return end
	self:SetKeyUp(keyName, context)
end

function PCSettingKeyBoardPanel:SetKeyDown(keyName)
	if self._inputMap[keyName] then return end--重复/重复触发
	if not SettingKey.GetSimpleKeyName(keyName) then
		if self._inputShowTip == false then return end
		self._inputShowTip = false
		SL:ShowSystemTips(GET_STRING(40060004))
		SL:ScheduleOnce(function()
			self._inputShowTip = true
		end, 1)
		return 
	end
	self._inputLen = self._inputLen + 1
	if self._inputLen > 2 then return end--最大2个键
	self._inputMap[keyName] = true
	self._inputIsEmpty = false
	table.insert(self._inputs, keyName)
end

function PCSettingKeyBoardPanel:SetKeyUp(keyName, context)
	if not self._inputMap[keyName] then return end
	self._inputLen = self._inputLen - 1
	if self._inputLen == 0 then
		self:OnSetCustomKeyEnd(context)
	end
end

function PCSettingKeyBoardPanel:OnSetCustomKeyEnd(context)
	if not self._inputId then
		return
	end
	
	if not self:CheckKey() then
		self._inputIsEmpty = true
		SL:ShowSystemTips(GET_STRING(80000601))
	end

	if self._inputIsEmpty == false then
		local keys = SL:CopyData(self._inputs)
		SettingKey.SetCustomKey(self._inputId, keys, true)
	end
	
	local input = context.sender
	local item = FGUI:GetParent(input)
	FGUI:setVisible(FGUI:GetChild(item, "item_selected"), true)
	FGUI:setVisible(FGUI:GetChild(item, "item_unselected"), false)
	FGUI:GTextField_setText(self._ui.tips, GET_STRING(80000603))
	
	local settingData = SettingKey.GetSetting(self._inputId)
	if not settingData or settingData.keysStr == "" then
		FGUI:GTextField_setColor(input, "#666666")
		FGUI:GTextInput_setText(context.sender, GET_STRING(80000600))
	else
		FGUI:GTextInput_setText(input, settingData.keysStr)
		FGUI:GTextField_setColor(input, "#FFFFFF")
	end
	
	self._inputId = nil
	self._inputLen = 0
	self._inputIsEmpty = true
	table.clear(self._inputMap)
	table.clear(self._inputs)
	FGUI:GTextInput_cancelFocus(context.sender)
end

function PCSettingKeyBoardPanel:OnReset()
	SettingKey.Reset()
end

function PCSettingKeyBoardPanel:CheckKey()
	if not next(self._inputs) then
		return true
	end
	if #self._inputs == 1 and self._functionKeys[self._inputs[1]] then
		return false
	end
	local commit = false
	for i, k in ipairs(self._inputs) do
		if not self._functionKeys[k] then
			commit = true
		end
	end
	return commit
end

function PCSettingKeyBoardPanel:OnKeySettingChange(id)
	for idx, setting in pairs(self._settings) do
		if setting.id == id then
			local index = idx - 1
			local rawIndex = FGUI:GList_itemIndexToChildIndex(self._ui.List_key, index)
			if rawIndex >= 0 then
				local item = FGUI:GetChildAt(self._ui.List_key, rawIndex)
				if item then
					self:OnListKeyRender(index, item)
				end
			end
			return
		end
	end
end

return PCSettingKeyBoardPanel
