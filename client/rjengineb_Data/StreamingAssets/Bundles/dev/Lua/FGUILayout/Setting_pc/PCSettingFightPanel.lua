local PCSettingPageBase = requireFGUILayout("Setting_pc/PCSettingPageBase")
local PCSettingFightPanel = class("PCSettingFightPanel", PCSettingPageBase)

local HANDLE_CFG = {
    [SLDefine.SET_FUNC.PLAYER_AUTO_HP] = {
        title = 80000401,
        enableKey = "SETTING_PLAYER_AUTO_HP_ENABLE",
        limitKey = "SETTING_PLAYER_AUTO_HP_LIMIT",
        orderKey = "SETTING_PLAYER_AUTO_HP_VALUE",
        itemName = "player_hp"
    },
    [SLDefine.SET_FUNC.PLAYER_AUTO_FAST_HP] = {
        title = 80000402,
        enableKey = "SETTING_PLAYER_AUTO_FAST_HP_ENABLE",
        limitKey = "SETTING_PLAYER_AUTO_FAST_HP_LIMIT",
        orderKey = "SETTING_PLAYER_AUTO_FAST_HP_VALUE",
        itemName = "player_fast_hp"
    },
    [SLDefine.SET_FUNC.PLAYER_AUTO_MP] = {
        title = 80000403,
        enableKey = "SETTING_PLAYER_AUTO_MP_ENABLE",
        limitKey = "SETTING_PLAYER_AUTO_MP_LIMIT",
        orderKey = "SETTING_PLAYER_AUTO_MP_VALUE",
        itemName = "player_mp"
    },
    [SLDefine.SET_FUNC.PLAYER_AUTO_FAST_MP] = {
        title = 80000404,
        enableKey = "SETTING_PLAYER_AUTO_FAST_MP_ENABLE",
        limitKey = "SETTING_PLAYER_AUTO_FAST_MP_LIMIT",
        orderKey = "SETTING_PLAYER_AUTO_FAST_MP_VALUE",
        itemName = "player_fast_mp"
    },
    [SLDefine.SET_FUNC.PET_AUTO_HP] = {
        title = 80000405,
        enableKey = "SETTING_PET_AUTO_HP_ENABLE",
        limitKey = "SETTING_PET_AUTO_HP_LIMIT",
        orderKey = "SETTING_PET_AUTO_HP_VALUE",
        itemName = "pet_hp"
    },
    [SLDefine.SET_FUNC.PET_AUTO_FAST_HP] = {
        title = 80000406,
        enableKey = "SETTING_PET_AUTO_FAST_HP_ENABLE",
        limitKey = "SETTING_PET_AUTO_FAST_HP_LIMIT",
        orderKey = "SETTING_PET_AUTO_FAST_HP_VALUE",
        itemName = "pet_fast_hp"
    },
    [SLDefine.SET_FUNC.PET_AUTO_MP] = {
        title = 80000407,
        enableKey = "SETTING_PET_AUTO_MP_ENABLE",
        limitKey = "SETTING_PET_AUTO_MP_LIMIT",
        orderKey = "SETTING_PET_AUTO_MP_VALUE",
        itemName = "pet_mp"
    },
    [SLDefine.SET_FUNC.PET_AUTO_FAST_MP] = {
        title = 80000408,
        enableKey = "SETTING_PET_AUTO_FAST_MP_ENABLE",
        limitKey = "SETTING_PET_AUTO_FAST_MP_LIMIT",
        orderKey = "SETTING_PET_AUTO_FAST_MP_VALUE",
        itemName = "pet_fast_mp"
    },
    [SLDefine.SET_FUNC.PET_AUTO_FAVORITE] = {
        title = 80000409,
        enableKey = "SETTING_PET_AUTO_FAVORITE_ENABLE",
        limitKey = "SETTING_PET_AUTO_FAVORITE_LIMIT",
        orderKey = "SETTING_PET_AUTO_FAVORITE_VALUE",
        itemName = "pet_favor"
    }
}

local ItemHandler = class("ItemHandler")
function ItemHandler:Init(widget, id)
    self.item = FGUI:ui_delegate(widget)
    self.id = id
    self.info = HANDLE_CFG[id]

    FGUI:GButton_setOnChangedCallback(self.item.enable, handler(self, self.OnEnableChanged))
    FGUI:addOnClickEvent(self.item.check, handler(self, self.OnClickCheckBtn))
    FGUI:GSlider_addOnChanged(self.item.slider, handler(self, self.OnLimitValueChanged))
    self:RefreshItem()
end

function ItemHandler:RefreshItem()
    local enable = SL:GetValue(self.info.enableKey)
    local limit = SL:GetValue(self.info.limitKey)
    FGUI:GButton_setSelected(self.item.enable, enable)
    FGUI:GSlider_setValue(self.item.slider, limit)
    self.format = GET_STRING(self.info.title)
    FGUI:GTextField_setText(self.item.title, string.format(self.format, limit))
end

function ItemHandler:OnEnableChanged(context)
    local enable = FGUI:GButton_getSelected(context.sender)
    SL:SetValue(self.info.enableKey, enable)
end

function ItemHandler:OnClickCheckBtn(context)
    local callBack = function(orderList)
        SL:SetValue(self.info.orderKey, orderList)
    end
    local data = {
        id = self.id,
        key = self.info.orderKey,
        callback = callBack
    }
    FGUI:Open("Setting_pc", "PCSettingSetItemOrderPanel", data)
end

function ItemHandler:OnLimitValueChanged(context)
    local limit = FGUI:GSlider_getValue(context.sender)
    SL:SetValue(self.info.limitKey, limit)
    FGUI:GTextField_setText(self.item.title, string.format(self.format, limit))
end

function PCSettingFightPanel:Enter()
    PCSettingFightPanel.super.Enter(self)
    self._packageName = "Setting_pc"
    if not self.component then
        release_log_traceback("ERROR PCSettingFightPanel component is nil. packageName:"..self._packageName)
        return
    end
    self._ui = FGUI:ui_delegate(self.component)
    self:Delegate()
    self:InitData()
    self:InitEvent()
    self:RefreshPanel()

    SL:ComponentAttach(SLDefine.SUIComponentTable.SettingFight, self._ui.Node_attach)
end

function PCSettingFightPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.SettingFight)

    PCSettingFightPanel.super.Exit(self)
end

function PCSettingFightPanel.Create()
    return PCSettingFightPanel.new()
end

function PCSettingFightPanel:Delegate()
    if SL:GetValue("JOB") == 1 then
        FGUI:GLoader_setUrl(self._ui.replace_loader, "ui://"..self._packageName.."/fight_option1")
    else
        FGUI:GLoader_setUrl(self._ui.replace_loader, "ui://"..self._packageName.."/fight_option2")
    end
    self._replace_loader = FGUI:GLoader_getComponent(self._ui.replace_loader)
end

function PCSettingFightPanel:InitData()
    self._handlers = {}
    self._helpSkillList = {}

    self.handler_OnHelpSkillEnableChanged = handler(self, self.OnHelpSkillEnableChanged)

    self._recover_skill_id = {}
    self._recover_skill_name = {}
    self._recover_skill_limit = SL:GetValue("SETTING_LHA_RELEASE_SKILL_LIMIT")
    self._recover_skill_select = SL:GetValue("SETTING_LHA_RELEASE_SKILL_ID")
    self._recover_skill_idx = 0
    local idx = 0
    local args = SL:GetValue("SETTING_FUNC_ARGS", SLDefine.SET_FUNC.USE_SKILL_ON_LOW_HP)
    local strAry = string.split(args, '|')
    for i, v in ipairs(strAry) do
        local id = tonumber(v)
        if SL:GetValue("SKILL_IS_LEARNED", id) then
            local name = SL:GetValue("SKILL_NAME_BY_ID", id)
            if name and string.len(name) > 0 then
                table.insert(self._recover_skill_id, id)
                table.insert(self._recover_skill_name, name)
                if id == self._recover_skill_select then
                    self._recover_skill_idx = idx
                end
                idx = idx + 1
            end
        end
    end

    self._recover_team_skill_id = {}
    self._recover_team_skill_name = {}
    self._recover_team_skill_limit = SL:GetValue("SETTING_TLHA_RELEASE_SKILL_LIMIT")
    self._recover_team_skill_select = SL:GetValue("SETTING_TLHA_RELEASE_SKILL_ID")
    self._recover_team_skill_idx = 0
    local idx = 0
    local args = SL:GetValue("SETTING_FUNC_ARGS", SLDefine.SET_FUNC.USE_SKILL_ON_LOW_TEAM_HP)
    local strAry = string.split(args, '|')
    for i, v in ipairs(strAry) do
        local id = tonumber(v)
        if SL:GetValue("SKILL_IS_LEARNED", id) then
            local name = SL:GetValue("SKILL_NAME_BY_ID", id)
            if name and string.len(name) > 0 then
                table.insert(self._recover_team_skill_id, id)
                table.insert(self._recover_team_skill_name, name)
                if id == self._recover_team_skill_select then
                    self._recover_team_skill_idx = idx
                end
                idx = idx + 1
            end
        end
    end
end

function PCSettingFightPanel:InitEvent()
    FGUI:GList_itemRenderer(self._ui.help_list, handler(self, self.HelpListRender))
    FGUI:addOnClickEvent(FGUI:GetChild(self._replace_loader, "auto_pickup_check"), handler(self, self.OnClickPickupCheckBtn))
    FGUI:GButton_setOnChangedCallback(FGUI:GetChild(self._replace_loader, "auto_pickup_enable"),
        handler(self, self.OnAutoPickupEnableChanged))
    if SL:GetValue("JOB") == 1 then
        FGUI:addOnClickEvent(FGUI:GetChild(self._replace_loader, "auto_assemble_arrow_check"), handler(self, self.OnClickAssembleArrowCheckBtn))
        FGUI:GButton_setOnChangedCallback(FGUI:GetChild(self._replace_loader, "auto_assemble_arrow_enable"),
            handler(self, self.OnAutoAssembleArrowEnableChanged))
    end

    
    FGUI:GComboBox_setItems(self._ui.recoverSkillValue, self._recover_team_skill_name)
    FGUI:GComboBox_setSelectedIndex(self._ui.recoverSkillValue, self._recover_skill_idx)
    FGUI:GComboBox_setOnChangeCallback(self._ui.recoverSkillValue, handler(self, self.OnRecoverSkillSelectChanged))

    FGUI:GComboBox_setItems(self._ui.teamRecoverSkillValue, self._recover_team_skill_name)
    FGUI:GComboBox_setSelectedIndex(self._ui.teamRecoverSkillValue, self._recover_team_skill_idx)
    FGUI:GComboBox_setOnChangeCallback(self._ui.teamRecoverSkillValue, handler(self, self.OnRecoverTeamSkillSelectChanged))

    FGUI:GTextInput_setText(self._ui.recoverSkillLimit, tostring(self._recover_skill_limit))
    FGUI:GTextInput_setOnChanged(self._ui.recoverSkillLimit, handler(self, self.OnRecoverSkillLimitChanged))

    FGUI:GTextInput_setText(self._ui.teamRecoverSkillLimit, tostring(self._recover_team_skill_limit))
    FGUI:GTextInput_setOnChanged(self._ui.teamRecoverSkillLimit, handler(self, self.OnRecoverTeamSkillLimitChanged))
end

function PCSettingFightPanel:OnRecoverSkillLimitChanged(context)
    local str = FGUI:GTextInput_getText(context.sender)
    local value = 0
    if str and string.len(str) then
        value = tonumber(str)
    end
    if not value then
        return
    elseif value < 0 then
        value = 0
    elseif value > 100 then
        value = 100
    end
    FGUI:GTextInput_setText(self._ui.recoverSkillLimit, value)
    SL:SetValue("SETTING_LHA_RELEASE_SKILL_LIMIT", value)
end
function PCSettingFightPanel:OnRecoverSkillSelectChanged(context)
    local idx = FGUI:GComboBox_getSelectedIndex(context.sender)
	self._recover_skill_idx = idx
	self._recover_team_skill_select = self._recover_team_skill_id[idx+1]
    SL:SetValue("SETTING_LHA_RELEASE_SKILL_ID", self._recover_team_skill_select)
end

function PCSettingFightPanel:OnRecoverTeamSkillLimitChanged(context)
    local str = FGUI:GTextInput_getText(context.sender)
    local value = 0
    if str and string.len(str) then
        value = tonumber(str)
    end
    if not value then
        return
    elseif value < 0 then
        value = 0
    elseif value > 100 then
        value = 100
    end
    FGUI:GTextInput_setText(self._ui.teamRecoverSkillLimit, value)
    SL:SetValue("SETTING_TLHA_RELEASE_SKILL_LIMIT", value)
end
function PCSettingFightPanel:OnRecoverTeamSkillSelectChanged(context)
    local idx = FGUI:GComboBox_getSelectedIndex(context.sender)
	self._recover_team_skill_idx = idx
	self._recover_team_skill_select = self._recover_team_skill_id[idx+1]
    SL:SetValue("SETTING_TLHA_RELEASE_SKILL_ID", self._recover_team_skill_select)
end

function PCSettingFightPanel:RefreshPanel()
    for id, info in pairs(HANDLE_CFG) do
        local ui = self._ui[info.itemName]
        local handler = ItemHandler.new()
        handler:Init(ui, id)
        self._handlers[id] = handler
    end

    self:RefreshHelpSkill()

    if SL:GetValue("JOB") == 1 then
        FGUI:GButton_setSelected(FGUI:GetChild(self._replace_loader, "auto_assemble_arrow_enable"),
            SL:GetValue("SETTING_AUTO_ASSEMBLE_ARROW_ENABLE"))
    end
    FGUI:GButton_setSelected(FGUI:GetChild(self._replace_loader, "auto_pickup_enable"),
        SL:GetValue("SETTING_GLOBAL_AUTO_PICKUP_EN"))
end

function PCSettingFightPanel:RefreshHelpSkill()
    local cache = SL:GetValue("SETTING_FIGHT_HELP_SKILL") or {}
    local contains = function(id)
        for i, v in ipairs(cache) do
            if v == id then
                return true
            end
        end
        return false
    end
    local args = SL:GetValue("SETTING_FUNC_ARGS", SLDefine.SET_FUNC.HELP_SKILL)
    local strAry = string.split(args, '|')
    for i, v in ipairs(strAry) do
        local id = tonumber(v)
        if SL:GetValue("SKILL_IS_LEARNED", id) and 
            SL:GetValue("SKILL_CHECK_IS_WUGONG_TYPE", id, 2) then
            local info = {}
            info.id = id
            info.enable = contains(id)
            table.insert(self._helpSkillList, info)
        end
    end
    FGUI:GList_setNumItems(self._ui.help_list, #self._helpSkillList)
end

function PCSettingFightPanel:HelpListRender(idx, item)
    local info = self._helpSkillList[idx + 1]
    local title = FGUI:GetChild(item, "title")
    local tog = FGUI:GetChild(item, "tog")
    FGUI:GTextField_setText(title, SL:GetValue("SKILL_NAME_BY_ID", info.id))
    self:ResetSwitch(tog, info.enable)
    FGUI:SetIntData(tog, idx)
    FGUI:GButton_setOnChangedCallback(tog, self.handler_OnHelpSkillEnableChanged)
end

function PCSettingFightPanel:OnHelpSkillEnableChanged(context)
    local id = FGUI:GetIntData(context.sender) + 1
    local enable = FGUI:GButton_getSelected(context.sender)
    self._helpSkillList[id].enable = enable

    self:SaveHelpSkillList()
end

function PCSettingFightPanel:SaveHelpSkillList()
    local list = {}
    for i, v in ipairs(self._helpSkillList) do
        if v.enable then
            table.insert(list, v.id)
        end
    end
    SL:SetValue("SETTING_FIGHT_HELP_SKILL", list)
end

function PCSettingFightPanel:OnClickPickupCheckBtn(context)
    FGUI:Open("Setting_pc", "PCSettingPickUpPanel")
end

function PCSettingFightPanel:OnAutoPickupEnableChanged(context)
    local enable = FGUI:GButton_getSelected(context.sender)
    SL:SetValue("SETTING_GLOBAL_AUTO_PICKUP_EN", enable)
end

-- 自动装箭开关
function PCSettingFightPanel:OnAutoAssembleArrowEnableChanged(context)
    local enable = FGUI:GButton_getSelected(context.sender)
    SL:SetValue("SETTING_AUTO_ASSEMBLE_ARROW_ENABLE", enable)
end

-- 查看箭头排序
function PCSettingFightPanel:OnClickAssembleArrowCheckBtn(context)
    local callBack = function(orderList)
        SL:SetValue("SETTING_AUTO_ASSEMBLE_ARROW_VALUE", orderList)
    end
    local data = {
        key = "SETTING_AUTO_ASSEMBLE_ARROW_VALUE",
        callback = callBack
    }
    FGUI:Open("Setting_pc", "PCSettingSetItemOrderPanel", data)
end

function PCSettingFightPanel:ResetSwitch(widget, enable)
    if FGUI:GButton_getSelected(widget) == enable then
        return
    end
    local transition = FGUI:GetTransition(widget, (enable == true) and "open" or "close")
    local time = FGUI:Transition_getTotalDuration(transition)
    FGUI:Transition_play(transition, nil, nil, nil, time)
    FGUI:GButton_setSelected(widget, enable)
end
return PCSettingFightPanel
