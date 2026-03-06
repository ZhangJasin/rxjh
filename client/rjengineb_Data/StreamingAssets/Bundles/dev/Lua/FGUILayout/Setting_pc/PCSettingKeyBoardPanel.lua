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
	self._mouseReady = false
	FGUI:addOnClickEvent(self._ui.Btn_reset, handler(self, self.OnReset))

	FGUI:GList_itemRenderer(self._ui.List_key, handler(self, self.OnListKeyRender))
end

function PCSettingKeyBoardPanel:InitEvent()
    SL:RegisterLUAEvent(LUA_EVENT_KEY_SETTING_CAHNGE, "PCSettingKeyBoardPanel", handler(self, self.OnKeySettingChange))
end

function PCSettingKeyBoardPanel:RefreshPanel()
	FGUI:GList_setNumItems(self._ui.List_key, #self._settings)
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
	FGUI:setTouchEnabled(item, data.enable ~= 2)
	FGUI:setOnKeyDown(ui_key, handler(self, self.OnKeyDown))
	FGUI:setOnKeyUp(ui_key, handler(self, self.OnKeyUp))
	FGUI:setOnFocusIn(ui_key, handler(self, self.OnFocusIn, data))
	FGUI:setOnFocusOut(ui_key, handler(self, self.OnFocusOut, data))
	-- FGUI:setOnTouchEvent(ui_key, handler(self, self.OnMouseBegin), nil, handler(self, self.OnMouseEnd))
end

function PCSettingKeyBoardPanel:OnFocusIn(settingData, context)
	local input = context.sender
	FGUI:GTextInput_setText(input, GET_STRING(40060003))
	FGUI:GTextField_setColor(input, "#666666")
	local id = settingData.id
	if self._inputId == id then return end
	self._isEmpty = true
	self._inputId = id
	self._inputLen = 0
	self._mouseReady = false
	table.clear(self._inputMap)
	table.clear(self._inputs)
end

function PCSettingKeyBoardPanel:OnFocusOut(settingData, context)
	local input = context.sender
	FGUI:GTextInput_setText(input, settingData.keysStr)
	if settingData.keysStr == "" then
		FGUI:GTextField_setColor(input, "#666666")
	else
		FGUI:GTextField_setColor(input, "#FFFFFF")
	end
	if self._isEmpty then
		SettingKey.SetCustomKey(self._inputId, nil, true)
	end
	self._inputId = nil
	self._inputLen = 0
	table.clear(self._inputMap)
	table.clear(self._inputs)
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
	self._isEmpty = false
	self._inputLen = self._inputLen + 1
	self._inputMap[keyName] = true
	if self._inputLen > 2 then return end--最大2个键
	table.insert(self._inputs, keyName)
end

function PCSettingKeyBoardPanel:SetKeyUp(keyName, context)
	if not self._inputMap[keyName] then return end
	self._inputLen = self._inputLen - 1
	local input = context.sender
	--设置结束
	if self._inputLen == 0 then
		local keysStr = SettingKey.GetKeysStr(self._inputs)
		local settingData = SettingKey.GetSetting(self._inputId)
		if settingData and settingData.keysStr == keysStr then
			--未更换按键
			if keysStr ~= "" then
				FGUI:GTextInput_setText(input, keysStr)
				FGUI:GTextField_setColor(input, "#FFFFFF")
			end
		else
			local keys = SL:CopyData(self._inputs)
			SettingKey.SetCustomKey(self._inputId, keys, true)
		end
		table.clear(self._inputMap)
		table.clear(self._inputs)
		FGUI:GTextInput_cancelFocus(input)
	end
end

function PCSettingKeyBoardPanel:OnKeyDown(context)
	local keyName = FGUI:EventContext_getKeyCode(context)
	if not keyName then return end
	if keyName == "KEY_NONE" then return end
	self:SetKeyDown(keyName)
end

function PCSettingKeyBoardPanel:OnKeyUp(context)
	local keyName = FGUI:EventContext_getKeyCode(context)
	if not keyName then return end
	self:SetKeyUp(keyName, context)
end

-- function PCSettingKeyBoardPanel:OnMouseBegin(context)
-- 	--过滤第一下选中点击
-- 	if not self._mouseReady then return end
-- 	local keyName = "MOUSE_" .. context.data.button
-- 	self:SetKeyDown(keyName)
-- end

-- function PCSettingKeyBoardPanel:OnMouseEnd(context)
-- 	if not self._mouseReady then
-- 		self._mouseReady = true
-- 		return
-- 	end
-- 	local keyName = "MOUSE_" .. context.data.button
-- 	self:SetKeyUp(keyName, context)
-- end

function PCSettingKeyBoardPanel:OnReset()
	SettingKey.Reset()
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
