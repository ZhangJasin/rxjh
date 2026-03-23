local PCSettingPageBase = requireFGUILayout("Setting_pc/PCSettingPageBase")
local PCSettingAutoFightPanel = class("PCSettingAutoFightPanel", PCSettingPageBase)

local OptionsHandlerBase = class("OptionsHandlerBase")
function OptionsHandlerBase:Init(key, item)
    self.key = key
    self.item = item
end
function OptionsHandlerBase:OnValueChanged(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
end

local TogHandler = class("TogHandler", OptionsHandlerBase)
function TogHandler:Init(key, item)
    self.super.Init(self, key, item)
    local enable = SL:GetValue(key)
    FGUI:GButton_setSelected(item, enable)
    FGUI:GButton_setOnChangedCallback(item, handler(self, self.OnValueChanged))
end
function TogHandler:OnValueChanged(context)
    self.super.OnValueChanged(self, context)
    local enable = FGUI:GButton_getSelected(context.sender)
    SL:SetValue(self.key, enable)
end

local InputTextHandler = class("InputTextHandler", OptionsHandlerBase)
function InputTextHandler:Init(key, item)
    self.super.Init(self, key, item)
    local value = SL:GetValue(key)
    FGUI:GTextInput_setText(item, tostring(value))
    FGUI:GTextInput_setOnChanged(item, handler(self, self.OnValueChanged))
end
function InputTextHandler:OnValueChanged(context)
    self.super.OnValueChanged(self, context)
    local str = FGUI:GTextInput_getText(context.sender)
    local value = 0
    if str and string.len(str) then
        value = tonumber(str)
    end
    SL:SetValue(self.key, value)
end

local ComboBoxHandler = class("ComboBoxHandler", OptionsHandlerBase)
function ComboBoxHandler:Init(key, item)
    self.super.Init(self, key, item)
    local value = SL:GetValue(key)
    FGUI:GComboBox_setSelectedIndex(item, value)
    FGUI:GComboBox_setOnChangeCallback(item, handler(self, self.OnValueChanged))
end
function ComboBoxHandler:OnValueChanged(context)
    self.super.OnValueChanged(self, context)
    local idx = FGUI:GComboBox_getSelectedIndex(context.sender)
    SL:SetValue(self.key, idx)
end

local SwitchHandler = class("SwitchHandler", OptionsHandlerBase)
function SwitchHandler:Init(key, item)
	self.super.Init(self, key, item)
	local enable = SL:GetValue(key)
	self:ResetSwitch(item, enable)
	FGUI:GButton_setOnChangedCallback(item, handler(self, self.OnValueChanged))
end
function SwitchHandler:OnValueChanged(context)
	self.super.OnValueChanged(self, context)
	local enable = FGUI:GButton_getSelected(context.sender)
	SL:SetValue(self.key, enable)
end
function SwitchHandler:ResetSwitch(widget, enable)
	if FGUI:GButton_getSelected(widget) == enable then
		return
	end
	local transition = FGUI:GetTransition(widget, (enable == true) and "open" or "close")
	local time = FGUI:Transition_getTotalDuration(transition)
	FGUI:Transition_play(transition, nil, nil, nil, time)
	FGUI:GButton_setSelected(widget, enable)
end

local infoTb = {
    ["useForEnemyEn"] = {
        key = "SETTING_ENABLE_ENEMIES_NEARBY",
        func = function()
            return TogHandler.new()
        end
    },
    ["useForEnemyDis"] = {
        key = "SETTING_DISTANCE_ENEMIES_NEARBY",
        func = function()
            return InputTextHandler.new()
        end
    },
    ["useForEnemyNum"] = {
        key = "SETTING_NUM_ENEMIES_NEARBY",
        func = function()
            return InputTextHandler.new()
        end
    },
    ["useForRedNameEn"] = {
        key = "SETTING_ENABLE_HOSTILES_NEARBY",
        func = function()
            return TogHandler.new()
        end
    },
    ["useForRedNameDis"] = {
        key = "SETTING_DISTANCE_HOSTILES_NEARBY",
        func = function()
            return InputTextHandler.new()
        end
    },
    ["useForRedNameNum"] = {
        key = "SETTING_NUM_HOSTILES_NEARBY",
        func = function()
            return InputTextHandler.new()
        end
    },
    ["activeAtkDis"] = {
        key = "SETTING_DISTANCE_ACTIVE_ATK_ENEMIES_NEARBY",
        func = function()
            return InputTextHandler.new()
        end
    },
    ["avoidConflictEn"] = {
        key = "SETTING_AVOID_CONFLICT_TARGET",
        func = function()
            return SwitchHandler.new()
        end
    },
    ["ignoreDropByPlayerEn"] = {
        key = "SETTING_IGNORE_DROP_BY_PLAYER",
        func = function()
            return SwitchHandler.new()
        end
    },
}

function PCSettingAutoFightPanel:Enter()
    PCSettingAutoFightPanel.super.Enter(self)
    self._packageName = "Setting_pc"
    if not self.component then
        release_log_traceback("ERROR PCSettingAutoFightPanel component is nil. packageName:"..self._packageName)
        return
    end
    self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:InitEvent()
    self:RefreshPanel()

    SL:ComponentAttach(SLDefine.SUIComponentTable.SettingPickUp, self._ui.Node_attach)
end

function PCSettingAutoFightPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.SettingPickUp)

    PCSettingAutoFightPanel.super.Exit(self)
end

function PCSettingAutoFightPanel.Create()
    return PCSettingAutoFightPanel.new()
end

function PCSettingAutoFightPanel:InitData()
    self._enemies_nearby_id = {}
    self._enemies_nearby_name = {}
    self._enemies_nearby_select = SL:GetValue("SETTING_ITEM_ENEMIES_NEARBY")
    self._enemies_nearby_idx = 0
    local idx = 0
    local args = SL:GetValue("SETTING_FUNC_ARGS", SLDefine.SET_FUNC.ITEM_ENEMIES_NEARBY)
    local strAry = string.split(args, '|')
    for i, v in ipairs(strAry) do
        local id = tonumber(v)
        local name = SL:GetValue("ITEM_NAME", id)
        if name and string.len(name) > 0 then
            table.insert(self._enemies_nearby_id, id)
            table.insert(self._enemies_nearby_name, name)
            if id == self._enemies_nearby_select then
                self._enemies_nearby_idx = idx
            end
			idx = idx + 1
        end
    end

    self._hostiles_nearby_id = {}
    self._hostiles_nearby_name = {}
    self._hostiles_nearby_select = SL:GetValue("SETTING_ITEM_HOSTILES_NEARBY")
    self._hostiles_nearby_idx = 0
    local idx = 0
    local args = SL:GetValue("SETTING_FUNC_ARGS", SLDefine.SET_FUNC.ITEM_HOSTILES_NEARBY)
    local strAry = string.split(args, '|')
    for i, v in ipairs(strAry) do
        local id = tonumber(v)
        local name = SL:GetValue("ITEM_NAME", id)
        if name and string.len(name) > 0 then
            table.insert(self._hostiles_nearby_id, id)
            table.insert(self._hostiles_nearby_name, name)
            if id == self._hostiles_nearby_select then
                self._hostiles_nearby_idx = idx
            end
			idx = idx + 1
        end
    end
end

function PCSettingAutoFightPanel:InitEvent()
    for name, info in pairs(infoTb) do
        local item = self._ui[name]
        local handler = info.func()
        handler:Init(info.key, item)
    end

    FGUI:GButton_setOnChangedCallback(self._ui.autoFightModForMap, handler(self, self.OnAutoFightModForMapChanged))
    FGUI:GButton_setOnChangedCallback(self._ui.autoFightModForRang, handler(self, self.OnAutoFightModForRangChanged))

    FGUI:GSlider_setOnChanged(self._ui.autoFightSlider, handler(self, self.OnAutoFightSliderChanged))

    local value = SL:GetValue("SETTING_PROCESS_MOD_ON_UNATTACK")
    local item = self._ui.onUnAttackMod
    FGUI:GComboBox_setSelectedIndex(item, value)
    FGUI:GComboBox_setOnChangeCallback(item, handler(self, self.OnProcessModOnUnattackChanged))

    local enable = SL:GetValue("SETTING_ENABLE_ACTIVE_ATK_ENEMIES_NEARBY")
    local item = self._ui.activeAtkEn
    FGUI:GButton_setSelected(item, enable)
    FGUI:GButton_setOnChangedCallback(item, handler(self, self.OnActiveAtkEnChanged))
end

function PCSettingAutoFightPanel:OnProcessModOnUnattackChanged(context)
    local idx = FGUI:GComboBox_getSelectedIndex(context.sender)
    SL:SetValue("SETTING_PROCESS_MOD_ON_UNATTACK", idx)
    if idx == 2 then
        FGUI:GButton_setSelected(self._ui.activeAtkEn, 
        SL:GetValue("SETTING_ENABLE_ACTIVE_ATK_ENEMIES_NEARBY"))
    end
end

function PCSettingAutoFightPanel:OnActiveAtkEnChanged(context)
    local enable = FGUI:GButton_getSelected(context.sender)
    SL:SetValue("SETTING_ENABLE_ACTIVE_ATK_ENEMIES_NEARBY", enable)
    if enable then
        FGUI:GComboBox_setSelectedIndex(self._ui.onUnAttackMod, 
        SL:GetValue("SETTING_PROCESS_MOD_ON_UNATTACK"))
    end
end

function PCSettingAutoFightPanel:RefreshPanel()
	local aX,aY = SL:GetValue("MAP_PLAYER_POS")
	FGUI:GTextField_setText(self._ui.autoFightPoint, string.format("（%0.0f,%0.0f） %s", aX, aY, SL:GetValue("MAP_NAME")))
	
	local range = SL:GetValue("SETTING_AUTO_FIGHT_RANGE_PERCENT")
	FGUI:GSlider_setValue(self._ui.autoFightSlider, range)
	local distance = SL:GetValue("SETTING_AUTO_FIGHT_RANGE")
	distance = math.floor(distance)
	FGUI:GTextField_setText(self._ui.autoFightDis, tostring(distance))
	
	local model = SL:GetValue("SETTING_AUTO_FIGHT_RANGE_ENABLE")
	FGUI:GButton_setSelected(self._ui.autoFightModForMap, model == 0)
	FGUI:GButton_setSelected(self._ui.autoFightModForRang, model == 1)

    FGUI:GComboBox_setItems(self._ui.useForEnemyValue, self._enemies_nearby_name)
    FGUI:GComboBox_setSelectedIndex(self._ui.useForEnemyValue, self._enemies_nearby_idx)
    FGUI:GComboBox_setOnChangeCallback(self._ui.useForEnemyValue, handler(self, self.OnForEnemySelectChanged))
    FGUI:GComboBox_setItems(self._ui.useForRedNameValue, self._hostiles_nearby_name)
    FGUI:GComboBox_setSelectedIndex(self._ui.useForRedNameValue, self._hostiles_nearby_idx)
    FGUI:GComboBox_setOnChangeCallback(self._ui.useForRedNameValue, handler(self, self.OnForRedNameSelectChanged))
end

-- 挂机模式
function PCSettingAutoFightPanel:OnAutoFightModForMapChanged(context)
	local enable = FGUI:GButton_getSelected(context.sender)
	local mod = 0
	if not enable then
		mod = 1
	end
	SL:SetValue("SETTING_AUTO_FIGHT_RANGE_ENABLE", mod)
	FGUI:GButton_setSelected(self._ui.autoFightModForMap, mod == 0)
	FGUI:GButton_setSelected(self._ui.autoFightModForRang, mod == 1)
end
function PCSettingAutoFightPanel:OnAutoFightModForRangChanged(context)
	local enable = FGUI:GButton_getSelected(context.sender)
	local mod = 0
	if enable then
		mod = 1
	end
	SL:SetValue("SETTING_AUTO_FIGHT_RANGE_ENABLE", mod)
	FGUI:GButton_setSelected(self._ui.autoFightModForMap, mod == 0)
	FGUI:GButton_setSelected(self._ui.autoFightModForRang, mod == 1)
end

function PCSettingAutoFightPanel:OnForEnemySelectChanged(context)
    local idx = FGUI:GComboBox_getSelectedIndex(context.sender)
	self._enemies_nearby_idx = idx
	self._enemies_nearby_select = self._enemies_nearby_id[idx+1]
    SL:SetValue("SETTING_ITEM_ENEMIES_NEARBY", self._enemies_nearby_select)
end

function PCSettingAutoFightPanel:OnForRedNameSelectChanged(context)
    local idx = FGUI:GComboBox_getSelectedIndex(context.sender)
	self._hostiles_nearby_idx = idx
	self._hostiles_nearby_select = self._hostiles_nearby_id[idx+1]
    SL:SetValue("SETTING_ITEM_HOSTILES_NEARBY", self._hostiles_nearby_select)
end

function PCSettingAutoFightPanel:OnAutoFightSliderChanged(context)
	local range = FGUI:GSlider_getValue(context.sender)
	SL:SetValue("SETTING_AUTO_FIGHT_RANGE_PERCENT", range)
	local distance = SL:GetValue("SETTING_AUTO_FIGHT_RANGE")
	distance = math.floor(distance)
	FGUI:GTextField_setText(self._ui.autoFightDis, tostring(distance))
end

return PCSettingAutoFightPanel
