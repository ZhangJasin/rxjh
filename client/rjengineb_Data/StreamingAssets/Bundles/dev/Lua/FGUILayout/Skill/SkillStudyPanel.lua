local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local SkillStudyPanel = class("SkillStudyPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local PAGE_DATA = {
	[1] = {name = "职业武功", page = 1},
	[2] = {name = "通用武功", page = 2},
	[3] = {name = "其他", page = 6},
}

local RANGE_TYPE_NAME = {
    [1] = "辅助技能",
    [2] = "单体技能",
    [3] = "群体技能"
}

local RELEASE_MODEL_NAME = {
    [1] = "循环释放",
    [2] = "冷却释放",
}

local MAX_SCHEME_COUNT = 10

function SkillStudyPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    self._uiTips = FGUI:ui_delegate(FGUI:GetChild(self.component, "skill_tips"))

    self:InitData()
    self:InitEvent()
end 

function SkillStudyPanel:Enter()
    self:RegisterEvent()

    ------------交易行截图begin----------
    local tradingIndex = global.TradingCaptureDatas and global.TradingCaptureDatas.tradingIndex
    ------------交易行截图end----------
    self:SelectPage(tradingIndex and 2 or 1)
    self:UpdateAutoSkillSetting()
    self:UpdateSkillPad()
end

function SkillStudyPanel:Exit()
	self:RemoveEvent()
    self:CleanData()
end

function SkillStudyPanel:InitData()
    self._myJob = SL:GetValue("JOB")
    self._myGoodEvil = SL:GetValue("GOODEVILID")
    self._selPage = 1
    self._skillWuGong = nil
    self._selSkillID = nil
    self._selSkillLevel = nil
    self._skillCells = {}
    self._costList = {}
    self._skills = {}

    self._selScheme = nil
    self._schemeNames = {}
    self._inputState = 1    -- 0不能输入 1可输入
    self._autoSkill = {}
end

function SkillStudyPanel:CleanData()
    self._selPage = 1
    self._skillWuGong = nil
    self._selSkillID = nil
    self._selSkillLevel = nil
    self._skillCells = {}
    self._costList = {}
    self._skills = {}

    self._selScheme = nil
    self._schemeNames = {}
    self._inputState = 1
    self._autoSkill = {}
end

function SkillStudyPanel:CleanSelSkill()
    self._selSkillID = nil
    self._selSkillLevel = nil
end

function SkillStudyPanel:InitEvent()
    -- Scheme点击空白  
	FGUI:setOnClickEvent(self._ui.mask, handler(self, self.OnClickSchemeMask))
    FGUI:setVisible(self._ui.mask, false)

    -- Tips点击空白
	FGUI:setOnClickEvent(self._uiTips.mask, handler(self, self.OnClickMask))

    -- 重置键位
	FGUI:setOnClickEvent(self._ui.btn_reset, handler(self, self.OnClickResetKey))

    -- page
	FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.ItemRendererPage))
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))

    -- 方案 
    FGUI:GList_itemRenderer(self._ui.list_scheme, handler(self, self.SchemeListRenderer))
	FGUI:setOnClickEvent(self._ui.btn_scheme, handler(self, self.OnClickBtnScheme))

    -- 施法方式
    FGUI:GList_itemRenderer(self._ui.list_release, handler(self, self.ReleaseListRenderer))
	FGUI:setOnClickEvent(self._ui.btn_release, handler(self, self.OnClickBtnRelease))

    -- 是否显示在主界面
    FGUI:setOnClickEvent(self._ui.check_main, handler(self, self.OnClickSchemeShowMain))
end

function SkillStudyPanel:ItemRendererPage(idx, item)
    local index = idx + 1
    local data = PAGE_DATA[index]
    if not data then 
        return 
    end 

    local text_normal = FGUI:GetChild(item, "text_normal")
    local text_select = FGUI:GetChild(item, "text_select")
    FGUI:GTextField_setText(text_normal, data.name)
    FGUI:GTextField_setText(text_select, data.name)
end

function SkillStudyPanel:OnClickPage()
    local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
    self:SelectPage(index)
end

function SkillStudyPanel:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page, index - 1)
    FGUI:setVisible(self._ui.skill_tips, false)

	self._selPage = PAGE_DATA[index].page
    self._skillWuGong = SL:GetValue("SKILL_WUGONG_TYPE_BY_GOODEVIL", self._myJob, self._selPage, self._myGoodEvil)
    self:UpdateSkillList()
    self:UpdatePlayerInfo()
end

---------------------------------技能列表---------------------------------start
function SkillStudyPanel:UpdateSkillList()
    if not self._skillWuGong then 
        return 
    end 

	FGUI:GList_itemRenderer(self._ui.list_skill, handler(self, self.SkillTypeListRenderer))
    FGUI:GList_setNumItems(self._ui.list_skill, #self._skillWuGong)
end

-- 类别(大页签)
local SkillGroup = {}
function SkillStudyPanel:SkillTypeListRenderer(idx, item)
    local index = idx + 1
    SkillGroup = self._skillWuGong[index]
    if not SkillGroup or not next(SkillGroup) then 
        return 
    end

    -- 组别 物品Id
    local itemId = SkillGroup[1].ItemId
    if itemId then 
        local ui_item = FGUI:GetChild(item, "item_icon")
        local ui_name = FGUI:GetChild(item, "text_mainSkill")
        local ui_condition = FGUI:GetChild(item, "text_condition")

        local itemData = SL:GetValue("ITEM_DATA", itemId)
        if itemData then 
            ItemUtil:RefreshItemUIByData(ui_item, itemData)
            FGUI:GTextField_setText(ui_name, itemData.Name)
            FGUI:GTextField_setText(ui_condition, "")
            local reLevel = SL:GetValue("RELEVEL") == 0 and 1 or SL:GetValue("RELEVEL")
            if itemData.NeedLevel then 
                if reLevel < itemData.NeedLevel then 
                    local showReLv = string.format(GET_STRING(5000+itemData.NeedLevel))
                    FGUI:GTextField_setText(ui_condition, string.format(GET_STRING(60012023), showReLv))
                end 
            end 
        end 
    end

    -- 组别 技能
    local list_icon = FGUI:GetChild(item, "list_icon")
    FGUI:GList_itemRenderer(list_icon, handler(self, self.SkillGroupRenderer))
    FGUI:GList_addOnClickItemEvent(list_icon, handler(self, self.OnClickSkillIcon))
    FGUI:GList_setNumItems(list_icon, #SkillGroup)
end

-- 组别(技能组)
function SkillStudyPanel:SkillGroupRenderer(idx, item) 
    local index = idx + 1
    if not SkillGroup[index] then 
        return 
    end

    local SkillID = SkillGroup[index].SkillID
    local SkillLevel = SkillGroup[index].SkillLevel
    local SkillName = SkillGroup[index].Name
    local SkillShowName = SkillGroup[index].ShowName
    local SkillCost = SkillGroup[index].Cost
    local isLearned = SL:GetValue("SKILL_IS_LEARNED", SkillID)
    local isCondition = SL:GetValue("CONDITION", SkillGroup[index].ConditionId)
    local data = {}
    data.id = SkillID
    data.level = SkillLevel
    data.name = SkillName
    data.cost = SkillCost
    data.isLearned = isLearned
    data.isCondition = isCondition
    data.item = item
    self._skillCells[SkillID] = data
    FGUI:SetIntData(item, SkillID)

    -- skill icon
    local ui_icon = FGUI:GetChild(item, "skill_icon")
    local path = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", SkillID, SkillLevel)
    FGUI:GLoader_setUrl(ui_icon, path, nil, true)  

    -- skill name 
    local ui_name = FGUI:GetChild(item, "text_name")
    FGUI:GTextField_setText(ui_name, SkillShowName)

    -- condition     
    local ui_condition = FGUI:GetChild(item, "text_condition")
    local sTips = SL:GetValue("CONDITION_TIPS", SkillGroup[index].ConditionId)
    local isCost = self:CheckSkillCost(SkillID)
    if not isLearned then 
        if isCondition and isCost then 
            sTips = GET_STRING(60012018)
        end
    else 
        FGUI:GRichTextField_setColor(ui_condition, "#00ff00")
    end 
    FGUI:GRichTextField_setText(ui_condition, sTips)

    -- skill select 
    local ui_select = FGUI:GetChild(item, "icon_select")
    FGUI:setVisible(ui_select, false)
end

function SkillStudyPanel:RefreshListLight(selID)
    for id, cell in pairs(self._skillCells) do
        local ui_select = FGUI:GetChild(cell.item, "icon_select")
        local isShow = selID == id
        FGUI:setVisible(ui_select, isShow)
    end
end

function SkillStudyPanel:OnClickSkillIcon(context)
    local selID = FGUI:GetIntData(context.data)
    self:RefreshListLight(selID)

    local isLearned = self._skillCells[selID].isLearned
    local isCondition = self._skillCells[selID].isCondition
    if isLearned and isCondition then 
        self._selSkillID = self._skillCells[selID].id
        self._selSkillLevel = self._skillCells[selID].level
    else 
        self:CleanSelSkill()
    end 
    
    self:ShowSkillTips(self._skillCells[selID].id, self._skillCells[selID].level)
    self:RefreshPadLight(false)
end
---------------------------------技能列表---------------------------------end


---------------------------------玩家历练值---------------------------------start
function SkillStudyPanel:UpdatePlayerInfo()
    local itemID = 7
    local itemName = SL:GetValue("ITEM_NAME", itemID)
    local itemCount = SL:GetValue("ITEM_COUNT", itemID)
    local color = itemCount == 0 and "#FF0000" or "#00FF00"
    FGUI:GTextField_setText(self._ui.text_myScore, string.format(GET_STRING(60012016), itemName, color, itemCount))
end
---------------------------------玩家历练值---------------------------------end


---------------------------------技能按键面板---------------------------------start
function SkillStudyPanel:UpdateSkillPad()
    table.clear(self._skills)
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

    local idx = 0
    for _, data in ipairs(AllData) do
        local isAttack = SL:GetValue("SKILL_CHECK_IS_ATTACK", data.SkillId) 
        if not isAttack then 
            idx = idx + 1
            self._skills[idx] = data
        end 
    end

    if not self._skills then 
        return 
    end 

    self:ChangeScheme(self._selScheme)
    self:RefreshPadLight(false)
end

-- 刷新技能键位选中状态
function SkillStudyPanel:RefreshPadLight(isShow)
    local keyCount = SL:GetValue("SKILL_KEY_COUNT")
    for i = 1, keyCount do 
        local uiPadCell = self._ui["skill_pad"..i]
        if uiPadCell then   
            local ui_select = FGUI:getChildByName(uiPadCell, "skill_select")
            FGUI:setVisible(ui_select, isShow) 
        end 
    end 
end

function SkillStudyPanel:OnClickPadSkill(context)
    if not self._selSkillID then 
        return 
    end 

    local key = FGUI:GetIntData(context.sender)
    self:SetAutoSkill(key, self._selSkillID)
    self:SkillChangeKey(self._selSkillID, key)
    self:CleanSelSkill()
    self:RefreshListLight(nil)
    self:RefreshPadLight(false)
    SL:RequestSaveSkillKeys()
end

function SkillStudyPanel:OnClickPadAuto(context)
    local key = FGUI:GetIntData(context.sender)
    local skill = SL:GetValue("SKILL_DATA_BY_KEY", key)
    local ID = skill.ID

    local isSelected = FGUI:GButton_getSelected(context.sender)
    if isSelected then 
        self:SetAutoSkill(key, ID)
    else 
        self:ClearAutoSkill(key)
    end 
end

function SkillStudyPanel:ClearAutoSkill(key)
    local keyCount = SL:GetValue("SKILL_KEY_COUNT")
    if not key or not (key >= 1 and key <= keyCount) then
        return
    end

    self._autoSkill[key] = -1
    SL:SetValue("SETTING_FIGHT_JOB_SKILL", self._autoSkill, key)
end

function SkillStudyPanel:SetAutoSkill(key, skillID)
    if not skillID then 
        return 
    end 

    if not key then 
        return 
    end 

    local isWuGong = SL:GetValue("SKILL_CHECK_IS_WUGONG_TYPE", skillID, 1)
    if isWuGong then 
        self._autoSkill[key] = skillID
        SL:SetValue("SETTING_FIGHT_JOB_SKILL", self._autoSkill, key)
    end
end

-- 改变键位
function SkillStudyPanel:SkillChangeKey(skillId, skillKey)
    if not skillId then  
        return nil
    end  

    local keyCount = SL:GetValue("SKILL_KEY_COUNT")
    if not skillKey or not (skillKey >= 1 and skillKey <= keyCount) then
        return nil
    end

    local uiPadCell = self._ui["skill_pad"..skillKey]
    if not uiPadCell then
        return nil
    end

    local scheme = self._selScheme
    local skill = SL:GetValue("SKILL_DATA_BY_ID", skillId)
    if skill.Key and skill.Key[scheme] then 
        self:SkillDeleteKey(skillId, skill.Key[scheme])
    end 

    local ui_icon = FGUI:GetChild(uiPadCell, "skill_icon")
    local path = SL:GetValue("SKILL_ICON_PATH_BY_ID", skillId)
    FGUI:GLabel_setIcon(ui_icon, path, true)

    local btnAuto = FGUI:GetChild(uiPadCell, "btn_auto")
    local isWuGong = SL:GetValue("SKILL_CHECK_IS_WUGONG_TYPE", skillId, 1)
    FGUI:setVisible(btnAuto, isWuGong)
    if isWuGong then 
        FGUI:GButton_setSelected(btnAuto, self._autoSkill[skillKey] and self._autoSkill[skillKey] > 0)
    end 

    SL:SetSkillKeyToLocal(skillId, skillKey)
end

-- 删除键位
function SkillStudyPanel:SkillDeleteKey(skillId, skillKey)
    local keyCount = SL:GetValue("SKILL_KEY_COUNT")
    if not skillKey or not (skillKey >= 1 and skillKey <= keyCount) then
        return nil
    end

    local uiPadCell = self._ui["skill_pad"..skillKey]
    if not uiPadCell then
        return nil
    end

    local ui_icon = FGUI:GetChild(uiPadCell, "skill_icon")
    local path = SL:GetValue("SKILL_ICON_PATH_BY_ID", nil)
    FGUI:GLabel_setIcon(ui_icon, path, true)

    local btnAuto = FGUI:GetChild(uiPadCell, "btn_auto")
    FGUI:setVisible(btnAuto, false)
    FGUI:GButton_setSelected(btnAuto, false)

    SL:DeleteSkillKeyToLocal(skillId)
end

-- 重置键位
function SkillStudyPanel:OnClickResetKey()
    local scheme = self._selScheme
    for _, skill in ipairs(self._skills) do
        if skill.Key and skill.Key[scheme] then 
            self:ClearAutoSkill(skill.Key[scheme])
            self:SkillDeleteKey(skill.SkillId, skill.Key[scheme]) 
        end
    end

    self:CleanSelSkill()
    self:RefreshPadLight(false)

    SL:RequestSaveSkillKeys()
end
---------------------------------技能按键面板---------------------------------end


---------------------------------技能设置---------------------------------start
function SkillStudyPanel:UpdateAutoSkillSetting()
    -- 初始化方案名字
    table.clear(self._schemeNames)
    local count = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME_COUNT")
    if count == 0 then 
        local defaultName = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME", 0)
        SL:SetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME", defaultName, 0)
        self._schemeNames[1] = defaultName
    else 
        for i = 1, count do
            self._schemeNames[i] = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME", i-1)
        end
    end 
    table.insert(self._schemeNames, "")

    -- 方案是否显示主界面
    local isShow = SL:GetValue("SETTING_MAIN_SKILL_SCHEME_SHOW")
    FGUI:GButton_setSelected(self._ui.check_main, isShow)

    -- 方案
    local scheme = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_SELECT")
    FGUI:GTextField_setText(self._ui.text_scheme, self._schemeNames[scheme+1])
    self._selScheme = scheme
    FGUI:setHeight(self._ui.list_scheme, #self._schemeNames * 40)
    FGUI:GList_setNumItems(self._ui.list_scheme, #self._schemeNames)

    -- 施法方式
    local releaseModel = SL:GetValue("SETTING_FIGHT_JOB_SKILL_RELEASE_MODEL", self._selScheme)
    FGUI:GTextField_setText(self._ui.text_release, RELEASE_MODEL_NAME[releaseModel+1])
    FGUI:setHeight(self._ui.list_release, #RELEASE_MODEL_NAME * 40)
    FGUI:GList_setNumItems(self._ui.list_release, #RELEASE_MODEL_NAME)

    -- 自动战斗技能
    self._autoSkill = SL:GetValue("SETTING_FIGHT_JOB_SKILL", self._selScheme)
end

function SkillStudyPanel:SchemeListRenderer(idx, item)
	local index = idx + 1
	local name = self._schemeNames[index]
	if not name then 
		return 
	end 

	local input_name = FGUI:GetChild(item, "input_title")
	local ui_select = FGUI:GetChild(item, "select")
	local btn_edit = FGUI:GetChild(item, "btn_edit")
	local img_add = FGUI:GetChild(item, "img_add")
    FGUI:setVisible(input_name, name ~= "")
    FGUI:setVisible(btn_edit, name ~= "")
    FGUI:setVisible(img_add, name == "")
    FGUI:setTouchEnabled(input_name, false)
    FGUI:setTouchEnabled(ui_select, true)

    -- input
	FGUI:GTextField_setText(input_name, name)
    FGUI:setOnFocusOut(input_name, function()
        local inputName = FGUI:GTextInput_getText(input_name)
        if string.len(inputName) == 0 then 
            self._inputState = 0
            return 
        end 

        FGUI:setTouchEnabled(input_name, false)
        FGUI:setTouchEnabled(ui_select, true)

        self._inputState = 1
        self._schemeNames[idx+1] = inputName
        SL:SetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME", inputName, idx)
        FGUI:GTextField_setText(self._ui.text_scheme, inputName)

        self:ChangeScheme(idx)
    end)

    -- btn select
	FGUI:setOnClickEvent(ui_select, function()
        if not self:CheckInputing() then 
            return
        end 
        if name == "" then 
            local count = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME_COUNT")
            if count >= MAX_SCHEME_COUNT then 
                SL:ShowSystemTips(string.format(GET_STRING(60012028), MAX_SCHEME_COUNT))
                return 
            end 

            local schemeName = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME", idx)
            SL:SetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME", schemeName, idx)
            self._schemeNames[index] = schemeName
            table.insert(self._schemeNames, "")

            FGUI:GList_setNumItems(self._ui.list_scheme, #self._schemeNames)
            FGUI:setHeight(self._ui.list_scheme, #self._schemeNames * 40)
            return 
        end 

        local lastIdx = self._selScheme
        if lastIdx == idx then 
            FGUI:setVisible(self._ui.list_scheme, false)
            FGUI:setVisible(self._ui.mask, false)  
            return 
        end 

		FGUI:GTextField_setText(self._ui.text_scheme, self._schemeNames[index])

        local releaseModel = SL:GetValue("SETTING_FIGHT_JOB_SKILL_RELEASE_MODEL", idx)
        FGUI:GTextField_setText(self._ui.text_release, RELEASE_MODEL_NAME[releaseModel+1])
        
        self:ChangeScheme(idx)
        self._selScheme = idx

        FGUI:setVisible(self._ui.list_scheme, false)
        FGUI:setVisible(self._ui.mask, false)  
	end)

    -- btn edit
	FGUI:setOnClickEvent(btn_edit, function()
        if not self:CheckInputing() then 
            return
        end 

		FGUI:setTouchEnabled(input_name, true)
		FGUI:setTouchEnabled(ui_select, false)
		FGUI:GTextField_setText(input_name, "")
        self._inputState = 0
	end)
end

function SkillStudyPanel:ReleaseListRenderer(idx, item)
	local index = idx + 1
	local name = RELEASE_MODEL_NAME[index]
	if not name then 
		return 
	end 

	local input_name = FGUI:GetChild(item, "input_title")
	FGUI:GTextField_setText(input_name, name)

	local ui_select = FGUI:GetChild(item, "select")
	FGUI:setOnClickEvent(ui_select, function()
		SL:SetValue("SETTING_FIGHT_JOB_SKILL_RELEASE_MODEL", idx, self._selScheme)
        FGUI:GTextField_setText(self._ui.text_release, name)
		FGUI:setVisible(self._ui.list_release, false)
        FGUI:setVisible(self._ui.mask, false)  
	end)

    local btn_edit = FGUI:GetChild(item, "btn_edit")
    FGUI:setVisible(btn_edit, false)

    local img_add = FGUI:GetChild(item, "img_add")
    FGUI:setVisible(img_add, false)
end

function SkillStudyPanel:OnClickBtnScheme()
    if not self:CheckInputing() then 
        return
    end 
    local show = not FGUI:getVisible(self._ui.list_scheme)
    FGUI:setVisible(self._ui.list_scheme, not FGUI:getVisible(self._ui.list_scheme))
    FGUI:setVisible(self._ui.list_release, false)
    FGUI:setVisible(self._ui.mask, FGUI:getVisible(self._ui.list_scheme))
    FGUI:GList_setNumItems(self._ui.list_scheme, #self._schemeNames)
end

function SkillStudyPanel:OnClickBtnRelease()
    if not self:CheckInputing() then 
        return
    end 
    FGUI:setVisible(self._ui.list_scheme, false)
    FGUI:setVisible(self._ui.list_release, not FGUI:getVisible(self._ui.list_release))
    FGUI:setVisible(self._ui.mask, true)
end

function SkillStudyPanel:OnClickSchemeMask()
    if not self:CheckInputing() then 
        return
    end 
    self._inputState = 1

    FGUI:setVisible(self._ui.list_scheme, false)
    FGUI:setVisible(self._ui.list_release, false)
    FGUI:setVisible(self._ui.mask, false)
end

function SkillStudyPanel:OnClickSchemeShowMain(context)
    local isShow = FGUI:GButton_getSelected(context.sender)
    SL:SetValue("SETTING_MAIN_SKILL_SCHEME_SHOW", isShow)
end

function SkillStudyPanel:CheckInputing()
    if self._inputState == 0 then 
        SL:ShowSystemTips(GET_STRING(60012029))
        return false
    end 

    return true
end

-- 切换方案
function SkillStudyPanel:ChangeScheme(scheme)
    if not scheme then 
        return 
    end 

    local lastScheme = self._selScheme
    self._selScheme = scheme
    SL:SetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_SELECT", scheme)
    self._autoSkill = SL:GetValue("SETTING_FIGHT_JOB_SKILL", scheme)

    local keyCount = SL:GetValue("SKILL_KEY_COUNT")
    for i = 1, keyCount do 
        local uiPadCell = self._ui["skill_pad"..i]
        if uiPadCell then   
            local ui_icon = FGUI:GetChild(uiPadCell, "skill_icon")
            local path = SL:GetValue("SKILL_ICON_PATH_BY_ID", nil)
            FGUI:GLabel_setIcon(ui_icon, path, true)

            local btnAuto = FGUI:GetChild(uiPadCell, "btn_auto")
            FGUI:setVisible(btnAuto, false)
            FGUI:GButton_setSelected(btnAuto, false)
			
            FGUI:setOnClickEvent(btnAuto, handler(self, self.OnClickPadAuto))
            FGUI:SetIntData(btnAuto, i)

            FGUI:setOnClickEvent(uiPadCell, handler(self, self.OnClickPadSkill))
            FGUI:SetIntData(uiPadCell, i) 
        end 
    end 

    for _, skill in ipairs(self._skills) do
        if skill.Key and skill.Key[scheme] then 
            local uiPadCell = self._ui["skill_pad"..skill.Key[scheme]]
            if uiPadCell then
                local ui_icon = FGUI:GetChild(uiPadCell, "skill_icon")
                local path = SL:GetValue("SKILL_ICON_PATH_BY_ID", skill.SkillId)
                FGUI:GLabel_setIcon(ui_icon, path, true)

                local btnAuto = FGUI:GetChild(uiPadCell, "btn_auto")
                local isWuGong = SL:GetValue("SKILL_CHECK_IS_WUGONG_TYPE", skill.SkillId, 1)
                FGUI:setVisible(btnAuto, isWuGong)
                if isWuGong then 
                    local key = skill.Key[scheme]
                    FGUI:GButton_setSelected(btnAuto, self._autoSkill[key] and self._autoSkill[key] > 0)
                end 
            end
        end 
    end

    SL:SetSchemeKeys(lastScheme, scheme)
end
---------------------------------技能设置---------------------------------end


---------------------------------技能tips---------------------------------start
function SkillStudyPanel:ShowSkillTips(SkillID, SkillLevel)
    if not SkillID and SkillLevel then 
        return
    end 

    local skillConfig = SL:GetValue("SKILL_UPGRADE_CONFIG_BY_ID_LEVEL", SkillID, SkillLevel)

    FGUI:setVisible(self._ui.skill_tips, true)
    FGUI:setVisible(self._uiTips.btn_config, self._selSkillID)
    FGUI:setVisible(self._uiTips.btn_upgrade, self._selSkillID and skillConfig.TipsBtn)
    FGUI:setVisible(self._uiTips.btn_practice, not self._selSkillID)

    -- icon 
    local path = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", SkillID)
    FGUI:GLoader_setUrl(self._uiTips.skill_icon, path, nil, true) 

    -- name
    local name = SL:GetValue("SKILL_UP_SHOWNAME_BY_ID", SkillID, SkillLevel)
    FGUI:GTextField_setText(self._uiTips.text_name, name)

    -- range type
    local rangeType = SL:GetValue("SKILL_RANGE_CATEGORY", SkillID)
    local rangeName = RANGE_TYPE_NAME[rangeType] or ""
    FGUI:GRichTextField_setText(self._uiTips.text_condition, rangeName)

    -- cost
    if skillConfig.Cost then 
        table.clear(self._costList)
        local sp = string.split(skillConfig.Cost, "|")
        for i = 1, #sp do 
            local data = {}
            local sp2 = string.split(sp[i], "#")
            data.id = tonumber(sp2[1])
            data.count = tonumber(sp2[2])
            table.insert(self._costList, data)
        end 
        FGUI:GList_itemRenderer(self._uiTips.list_cost, function(idx, item)
            local index = idx + 1
            local data = self._costList[index]
            if not data then 
                return 
            end  

            local text_cost = FGUI:GetChild(item, "text_cost")
            local itemName = SL:GetValue("ITEM_NAME", data.id)
            local myCount = SL:GetValue("ITEM_COUNT", data.id)
            local needCount = data.count   
            local color = myCount >= needCount and "#00FF00" or "#FF0000"
            FGUI:GTextField_setText(text_cost, string.format(GET_STRING(60012007), itemName, color, needCount))
        end)
        FGUI:GList_setNumItems(self._uiTips.list_cost, #self._costList)
    end

    -- desc
    local desc = SL:GetValue("SKILL_UP_DESC_BY_ID", SkillID, SkillLevel)
    FGUI:GRichTextField_setText(self._uiTips.text_desc, desc)

    -- weili
    FGUI:GTextField_setText(self._uiTips.text_weili, string.format(GET_STRING(60012004), skillConfig.Power or 0))

    -- att   
    local skillcost = skillConfig.SkillCost
    if skillcost then 
        if tonumber(skillcost[1]) == 0 then 
            local attData = SL:GetValue("ATTR_CONFIG", tonumber(skillcost[2]))
            if attData then 
                FGUI:GTextField_setText(self._uiTips.text_neili, string.format(GET_STRING(60012005), attData.Name, tonumber(skillcost[3])))
            end 
        end 
    end

    -- cd
    local skillCfg = SL:GetValue("SKILL_CONFIG_BY_SKILL_ID", SkillID)
    if skillCfg then 
        FGUI:GTextField_setText(self._uiTips.text_cd, string.format(GET_STRING(60012006), skillCfg.CD * 0.001 or 0))
    end


	FGUI:setOnClickEvent(self._uiTips.btn_config, handler(self, self.OnClickConfig))
	FGUI:setOnClickEvent(self._uiTips.btn_upgrade, handler(self, self.OnClickUpgrade))
	FGUI:setOnClickEvent(self._uiTips.btn_practice, handler(self, self.OnClickPractice))
    FGUI:SetIntData(self._uiTips.btn_practice, SkillID)
end

function SkillStudyPanel:OnClickConfig(context)
    if not self._selSkillID then 
        return 
    end 

    self:RefreshPadLight(true)
    FGUI:setVisible(self._ui.skill_tips, false)
end

function SkillStudyPanel:OnClickUpgrade(context)
    FGUI:setVisible(self._ui.skill_tips, false)

    if not self._selSkillID then 
        return 
    end 

    if not self._selSkillLevel then 
        return 
    end 

    local skillConfig = SL:GetValue("SKILL_UPGRADE_CONFIG_BY_ID_LEVEL", self._selSkillID, self._selSkillLevel)
    if not skillConfig then 
        return 
    end 

    if not skillConfig.TipsBtn then 
        return 
    end 

    local data = string.split(skillConfig.TipsBtn, "#")
    if not data or not next(data) then 
        return 
    end 

    local iType = tonumber(data[1]) 
    local ID = tonumber(data[2])
    local name = tostring(data[3])

    SL:RequestTipsBtnClick(iType, ID, name)
end

function SkillStudyPanel:OnClickPractice(context)
    FGUI:setVisible(self._ui.skill_tips, false)

    local skillID = FGUI:GetIntData(context.sender)
    local isLearned = self._skillCells[skillID].isLearned
    local isCondition = self._skillCells[skillID].isCondition
    if not isLearned and not isCondition then 
        SL:ShowSystemTips(GET_STRING(60012017))
        return 
    end 

    local isCost = self:CheckSkillCost(skillID, true)
    if not isCost then 
        SL:ShowSystemTips(GET_STRING(60012019))
        return 
    end 

    SL:RequestWuGongStudy(skillID)
end

function SkillStudyPanel:OnClickMask(context)
    self:CleanSelSkill()
    FGUI:setVisible(self._ui.skill_tips, false)
end
---------------------------------技能tips---------------------------------end


function SkillStudyPanel:CheckSkillCost(skillID, showTips)
    if not skillID then  
        return false
    end 

    local Cost = self._skillCells[skillID].cost
    if not Cost then 
        print("Error, Not Cost in SkillUpgrade config!", skillID)
        return false
    end 

    local sp = string.split(Cost, "|")
    for i = 1, #sp do 
        local data = {}
        local sp2 = string.split(sp[i], "#")
        data.id = tonumber(sp2[1])
        data.count = tonumber(sp2[2])
        local myCount = SL:GetValue("ITEM_COUNT", data.id)
        local needCount = data.count  
        if myCount < needCount then 
            if showTips then 
                SL:ShowSystemTips(GET_STRING(60012019))
            end 
            return false 
        end 
    end 

    return true
end


function SkillStudyPanel:OnWuGongStudy(skillID)
    FGUI:setVisible(self._ui.skill_tips, false)
    self._skillWuGong = SL:GetValue("SKILL_WUGONG_TYPE_BY_GOODEVIL", self._myJob, self._selPage, self._myGoodEvil)

    local skill = SL:GetValue("SKILL_DATA_BY_ID", skillID)
    local key = skill.Key and skill.Key[self._selScheme]
    self:SetAutoSkill(key, skill.ID)
    self:UpdateSkillList()
    self:UpdateSkillPad()
    self:UpdatePlayerInfo()
end

---------------------------------注册事件---------------------------------
function SkillStudyPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_WUGONG_STUDY, "SkillStudyPanel", handler(self, self.OnWuGongStudy))
end

function SkillStudyPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_WUGONG_STUDY, "SkillStudyPanel")
end

return SkillStudyPanel