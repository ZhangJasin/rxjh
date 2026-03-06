local SettingPageBase = requireFGUILayout("Setting/SettingPageBase")
local SettingAutoFightPanel = class("SettingDisSettingAutoFightPanelplayPanel", SettingPageBase)

local JOB_SKILL                     = 1 --职业武功
local HELP_SKILL                    = 2 --通用武功

local SCHEME_COUNT                  = 5 -- 方案个数

local SKILL_RELEASE_MODEL_LOOP      = 1 -- 循环释放
local SKILL_RELEASE_MODEL_CD        = 2 -- 冷却释放

local OptionsHandlerBase = class("OptionsHandlerBase")
function OptionsHandlerBase:Init(key, item)
    self.key = key
    self.item = item
end
function OptionsHandlerBase:OnValueChanged(context)
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

function SettingAutoFightPanel:Enter()
    SettingAutoFightPanel.super.Enter(self)
    self._packageName = "Setting"
    if not self.component then
        release_log_traceback("ERROR SettingAutoFightPanel component is nil. packageName:"..self._packageName)
        return
    end
    self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:InitEvent()
    self:RefreshPanel()

    SL:ComponentAttach(SLDefine.SUIComponentTable.SettingPickUp, self._ui.Node_attach)
end

function SettingAutoFightPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.SettingPickUp)

    SettingAutoFightPanel.super.Exit(self)
end

function SettingAutoFightPanel.Create()
    return SettingAutoFightPanel.new()
end

function SettingAutoFightPanel:InitData()
    -- self._selectScheme = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_SELECT")
    -- self._releaseModel = SL:GetValue("SETTING_FIGHT_JOB_SKILL_RELEASE_MODEL")

    -- self._schemeNames = {}
    -- for i = 1, SCHEME_COUNT, 1 do
    --     self._schemeNames[i] = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME", i-1)
    -- end

    -- self.handler_OnSchemeNameChanged = handler(self, self.OnSchemeNameChanged)
    -- self.handler_OnSelectSchemeChanged = handler(self, self.OnSelectSchemeChanged)
    -- self.handler_OnSelectReleaseModelChanged = handler(self, self.OnSelectReleaseModelChanged)
    -- self.handler_JobSkillListRender = handler(self, self.JobSkillListRender)
    -- self.handler_OnClickJobSkill = handler(self, self.OnClickJobSkill)

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

function SettingAutoFightPanel:InitEvent()
    -- FGUI:setOnFocusOut(self._ui.jobSkillSchemeName, self.handler_OnSchemeNameChanged)
    -- FGUI:GComboBox_setOnChangeCallback(self._ui.jobSkillSchemeSelect, self.handler_OnSelectSchemeChanged)
    -- FGUI:GComboBox_setOnChangeCallback(self._ui.jobSkillReleaseModelSelect, self.handler_OnSelectReleaseModelChanged)
    -- -- 职业技能
    -- FGUI:GList_itemRenderer(self._ui.jobSkillList, self.handler_JobSkillListRender)
    -- FGUI:GList_addOnClickItemEvent(self._ui.jobSkillList, self.handler_OnClickJobSkill)

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

function SettingAutoFightPanel:OnProcessModOnUnattackChanged(context)
    local idx = FGUI:GComboBox_getSelectedIndex(context.sender)
    SL:SetValue("SETTING_PROCESS_MOD_ON_UNATTACK", idx)
    if idx == 2 then
        FGUI:GButton_setSelected(self._ui.activeAtkEn, 
        SL:GetValue("SETTING_ENABLE_ACTIVE_ATK_ENEMIES_NEARBY"))
    end
end

function SettingAutoFightPanel:OnActiveAtkEnChanged(context)
    local enable = FGUI:GButton_getSelected(context.sender)
    SL:SetValue("SETTING_ENABLE_ACTIVE_ATK_ENEMIES_NEARBY", enable)
    if enable then
        FGUI:GComboBox_setSelectedIndex(self._ui.onUnAttackMod, 
        SL:GetValue("SETTING_PROCESS_MOD_ON_UNATTACK"))
    end
end

function SettingAutoFightPanel:RefreshPanel()
    -- -- 设置方案名
    -- FGUI:GComboBox_setSelectedIndex(self._ui.jobSkillSchemeSelect, self._selectScheme)
    -- FGUI:GComboBox_setItems(self._ui.jobSkillSchemeSelect, self._schemeNames)
    -- -- 设置技能释放方式
    -- FGUI:GComboBox_setSelectedIndex(self._ui.jobSkillReleaseModelSelect, self._releaseModel)

    -- self:RefreshJobSkills()
	
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

function SettingAutoFightPanel:RefreshJobSkills()
    -- 职业技能
    self._jobSkills = SL:GetValue("SETTING_FIGHT_JOB_SKILL", self._selectScheme)
    if self._jobSkills == nil or not next(self._jobSkills) then
        self._jobSkills = {-1, -1, -1, -1, -1}
    end
    FGUI:GList_setNumItems(self._ui.jobSkillList, #self._jobSkills)
    self._releaseModel = SL:GetValue("SETTING_FIGHT_JOB_SKILL_RELEASE_MODEL", self._selectScheme)
    FGUI:GComboBox_setSelectedIndex(self._ui.jobSkillReleaseModelSelect, self._releaseModel)

    FGUI:GTextInput_setText(self._ui.jobSkillSchemeName, self._schemeNames[self._selectScheme + 1])
end

-- 当方案名改变
function SettingAutoFightPanel:OnSchemeNameChanged(context)
    local name = FGUI:GTextField_getText(self._ui.jobSkillSchemeName)
	if not name or string.len(name) == 0 then
		FGUI:GTextInput_setText(self._ui.jobSkillSchemeName, self._schemeNames[self._selectScheme + 1])
		return
	end
    local callback = function (result)
        if result then
			SL:SetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME", name)
			self._schemeNames[self._selectScheme + 1] = name
			FGUI:GComboBox_setItems(self._ui.jobSkillSchemeSelect, self._schemeNames)
		else
			FGUI:GTextInput_setText(self._ui.jobSkillSchemeName, self._schemeNames[self._selectScheme + 1])
		end
    end
	SL:RequestCheckSensitiveWord(name, 1, callback)
end

-- 选择方案
function SettingAutoFightPanel:OnSelectSchemeChanged(context)
    local idx = FGUI:GComboBox_getSelectedIndex(context.sender)
    self._selectScheme = idx
    SL:SetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_SELECT", idx)
    self:RefreshJobSkills()
end

-- 选择释放模式
function SettingAutoFightPanel:OnSelectReleaseModelChanged(context)
    local idx = FGUI:GComboBox_getSelectedIndex(context.sender)    
    self._releaseModel = idx
    SL:SetValue("SETTING_FIGHT_JOB_SKILL_RELEASE_MODEL", idx, self._selectScheme)
end

-- 职业武功列表刷新
function SettingAutoFightPanel:JobSkillListRender(idx, item)
    local id = self._jobSkills[idx+1]
    if id > 0 then
        local path = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", id)
        FGUI:GButton_setIcon(item, path, true)
        FGUI:GButton_setTitle(item,SL:GetValue("SKILL_NAME_BY_ID", id))
    else
        FGUI:GButton_setIcon(item, nil)
        FGUI:GButton_setTitle(item, "")
    end
end

-- 点击职业技能
function SettingAutoFightPanel:OnClickJobSkill(context)
    local childIdx = FGUI:GetChildIndex(self._ui.jobSkillList, context.data)
	local index = FGUI:GList_childIndexToItemIndex(self._ui.jobSkillList, childIdx)
	local AllData = SL:GetValue("SKILL_ALL_DATA")
	AllData = HashToSortArray(AllData, function(a, b)
			local a_info = SL:GetValue("SKILL_UPGRADE_CONFIG_BY_ID_LEVEL", a.SkillId)
			local b_info = SL:GetValue("SKILL_UPGRADE_CONFIG_BY_ID_LEVEL", b.SkillId)
			if not a_info or not b_info then
				return false
			end
			if not a_info.ID or not b_info.ID then
				return false
			end
			return a_info.ID < b_info.ID
		end)
	local skills = {}
	for _, data in ipairs(AllData) do
		if not SL:GetValue("SKILL_CHECK_IS_ATTACK", data.SkillId)
			and SL:GetValue("SKILL_CHECK_IS_WUGONG_TYPE", data.SkillId, JOB_SKILL)then
			table.insert(skills, data)
		end
	end
    local data = {}
    data.skill = skills
    data.callback = function(id)
        self._jobSkills[index + 1] = id
        SL:SetValue("SETTING_FIGHT_JOB_SKILL", self._jobSkills, index + 1)
        FGUI:GList_setNumItems(self._ui.jobSkillList, #self._jobSkills)
    end
    
    FGUI:Open("Setting", "SettingSelectSkillPanel", data)
end

-- 挂机模式
function SettingAutoFightPanel:OnAutoFightModForMapChanged(context)
	local enable = FGUI:GButton_getSelected(context.sender)
	local mod = 0
	if not enable then
		mod = 1
	end
	SL:SetValue("SETTING_AUTO_FIGHT_RANGE_ENABLE", mod)
	FGUI:GButton_setSelected(self._ui.autoFightModForMap, mod == 0)
	FGUI:GButton_setSelected(self._ui.autoFightModForRang, mod == 1)
end
function SettingAutoFightPanel:OnAutoFightModForRangChanged(context)
	local enable = FGUI:GButton_getSelected(context.sender)
	local mod = 0
	if enable then
		mod = 1
	end
	SL:SetValue("SETTING_AUTO_FIGHT_RANGE_ENABLE", mod)
	FGUI:GButton_setSelected(self._ui.autoFightModForMap, mod == 0)
	FGUI:GButton_setSelected(self._ui.autoFightModForRang, mod == 1)
end

function SettingAutoFightPanel:OnForEnemySelectChanged(context)
    local idx = FGUI:GComboBox_getSelectedIndex(context.sender)
	self._enemies_nearby_idx = idx
	self._enemies_nearby_select = self._enemies_nearby_id[idx+1]
    SL:SetValue("SETTING_ITEM_ENEMIES_NEARBY", self._enemies_nearby_select)
end

function SettingAutoFightPanel:OnForRedNameSelectChanged(context)
    local idx = FGUI:GComboBox_getSelectedIndex(context.sender)
	self._hostiles_nearby_idx = idx
	self._hostiles_nearby_select = self._hostiles_nearby_id[idx+1]
    SL:SetValue("SETTING_ITEM_HOSTILES_NEARBY", self._hostiles_nearby_select)
end

function SettingAutoFightPanel:OnAutoFightSliderChanged(context)
	local range = FGUI:GSlider_getValue(context.sender)
	SL:SetValue("SETTING_AUTO_FIGHT_RANGE_PERCENT", range)
	local distance = SL:GetValue("SETTING_AUTO_FIGHT_RANGE")
	distance = math.floor(distance)
	FGUI:GTextField_setText(self._ui.autoFightDis, tostring(distance))
end

return SettingAutoFightPanel
