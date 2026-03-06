local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MySkill = class("MySkill", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local PAGE_DATA = {
	[1] = {name = "职业武功", page = 1, obj = nil},
	[2] = {name = "通用武功", page = 2, obj = nil},
}

function MySkill:Create()
	self._ui = FGUI:ui_delegate(self.component)
    self._uiTips = FGUI:ui_delegate(FGUI:GetChild(self.component, "skill_tips"))
    self:InitEvent()
end 

function MySkill:Enter()
    self:RegisterEvent()
    self:InitData()
    self:SelectPage(1)
    self:UpdateSkillPad()
end

function MySkill:Exit()
	self:RemoveEvent()
    self:CleanData()
end

function MySkill:InitData()
    self._myJob = SL:GetValue("JOB")
    self._myGoodEvil = SL:GetValue("GOODEVILID")
    self._selPage = 1
    self._skillWuGong = nil
    self._selSkillID = nil
    self._selSkillLevel = nil
    self._skillCells = {}
    self._costList = {}
    self._skills = {}
end

function MySkill:CleanData()
    self._selPage = 1
    self._skillWuGong = nil
    self._selSkillID = nil
    self._selSkillLevel = nil
    self._skillCells = {}
    self._costList = {}
    self._skills = {}
end

function MySkill:CleanSelSkill()
    self._selSkillID = nil
    self._selSkillLevel = nil
end

function MySkill:InitEvent()
	FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.ItemRendererPage))
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))
end

function MySkill:ItemRendererPage(idx, item)
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

function MySkill:OnClickPage()
    local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
    self:SelectPage(index)
end

function MySkill:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page, index - 1)
    FGUI:setVisible(self._ui.skill_tips, false)
    self:CleanData()

	self._selPage = index
    self._skillWuGong = SL:GetValue("SKILL_WUGONG_TYPE_BY_GOODEVIL", self._myJob, self._selPage, self._myGoodEvil)
    self:UpdateSkillList()
    self:UpdatePlayerInfo()
end

-- 左边 技能表
function MySkill:UpdateSkillList()
    if not self._skillWuGong then 
        return 
    end 

	FGUI:GList_itemRenderer(self._ui.list_skill, handler(self, self.SkillTypeListRenderer))
    FGUI:GList_setNumItems(self._ui.list_skill, #self._skillWuGong)
end

-- 类别(大页签)
local SkillGroup = {}
function MySkill:SkillTypeListRenderer(idx, item)
    local index = idx + 1
    SkillGroup = self._skillWuGong[index]
    if not SkillGroup or not next(SkillGroup) then 
        return 
    end

    -- 组别 物品Id
    local itemId = SkillGroup[1].ItemId
    if itemId then 
        local ui_item = FGUI:GetChild(item, "item_icon")
        local itemData = SL:GetValue("ITEM_DATA", itemId)
        if itemData then 
            ItemUtil:RefreshItemUIByData(ui_item, itemData)
            ItemUtil:AddItemClick(ui_item, itemData)
        end 
    end

    -- 组别 技能
    local list_icon = FGUI:GetChild(item, "list_icon")
    FGUI:GList_itemRenderer(list_icon, handler(self, self.SkillGroupRenderer))
    FGUI:GList_addOnClickItemEvent(list_icon, handler(self, self.OnClickSkillIcon))
    FGUI:GList_setNumItems(list_icon, #SkillGroup)
end

-- 组别(技能组)
function MySkill:SkillGroupRenderer(idx, item) 
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
    local sTips = ""
    local isCost = self:CheckSkillCost(SkillID)
    if not isLearned then 
        if isCondition and isCost then 
            sTips = GET_STRING(60012018)
        else 
            sTips = GET_STRING(60012022) -- SL:GetValue("CONDITION_TIPS", SkillGroup[index].ConditionId)
        end 
    end 
    
    FGUI:GRichTextField_setText(ui_condition, sTips)
    FGUI:setVisible(ui_condition, not isLearned)

    -- skill mask 
    local ui_mask = FGUI:GetChild(item, "skill_mask")
    FGUI:setVisible(ui_mask, not isLearned)

    -- skill select 
    local ui_select = FGUI:GetChild(item, "icon_select")
    FGUI:setVisible(ui_select, false)
end

function MySkill:RefreshSkillIcon(selID)
    for id, cell in pairs(self._skillCells) do
        local ui_select = FGUI:GetChild(cell.item, "icon_select")
        local isShow = selID == id
        FGUI:setVisible(ui_select, isShow)
    end
end

-- 技能键位
function MySkill:UpdateSkillPad()
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
        local isWuGong = SL:GetValue("SKILL_CHECK_IS_WUGONG_TYPE", data.SkillId, self._selPage)
        if not isAttack then 
            idx = idx + 1
            self._skills[idx] = data
        end 
    end

    if not self._skills then 
        return 
    end 

    -- 刷新icon
    for _, skill in ipairs(self._skills) do
        local key = skill.Key
        if key then 
            local uiPadCell = self._ui["skill_pad"..key]
            if uiPadCell then  
                local ui_icon = FGUI:GetChild(uiPadCell, "skill_icon")
                local path = SL:GetValue("SKILL_ICON_PATH_BY_ID", skill.SkillId)
                FGUI:GLabel_setIcon(ui_icon, path, true)
            end
        end
    end

    self:RefreshSkillPad(false)
end

-- 刷新技能键位选中状态
function MySkill:RefreshSkillPad(isShow)
    local keyCount = SL:GetValue("SKILL_KEY_COUNT")
    for i = 1, keyCount do 
        local uiPadCell = self._ui["skill_pad"..i]
        if uiPadCell then   
            local ui_select = FGUI:getChildByName(uiPadCell, "skill_select")
            FGUI:setVisible(ui_select, isShow) 
        end 
    end 
end

-- 改变键位
function MySkill:SkillChangeKey(skillId, skillKey)
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

    -- reset last
    local lastKey = SL:GetValue("SKILL_KEY_BY_ID", skillId)
    if lastKey and lastKey ~= skillKey then
        self:SkillDeleteKey(skillId, lastKey)
    end

    -- new key
    local ui_icon = FGUI:GetChild(uiPadCell, "skill_icon")
    local path = SL:GetValue("SKILL_ICON_PATH_BY_ID", skillId)
    FGUI:GLabel_setIcon(ui_icon, path, true)

    SL:SetSkillKeyToLocal(skillId, skillKey)
end

-- 删除键位
function MySkill:SkillDeleteKey(skillId, skillKey)
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

    SL:DeleteSkillKeyToLocal(skillId)
end



function MySkill:ShowSkillTips(SkillID, SkillLevel)
    if not SkillID and SkillLevel then 
        return
    end 

    FGUI:setVisible(self._ui.skill_tips, true)
    FGUI:setVisible(self._uiTips.btn_config, self._selSkillID)
    FGUI:setVisible(self._uiTips.btn_practice, not self._selSkillID)

    local skillConfig = SL:GetValue("SKILL_UPGRADE_CONFIG_BY_ID_LEVEL", SkillID, SkillLevel)

    -- icon 
    local path = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", SkillID)
    FGUI:GLoader_setUrl(self._uiTips.skill_icon, path, nil, true) 

    -- name
    local name = SL:GetValue("SKILL_UP_NAME_BY_ID", SkillID, SkillLevel)
    FGUI:GTextField_setText(self._uiTips.text_name, name)

    -- condition 
    local sTips = SL:GetValue("CONDITION_TIPS", skillConfig.ConditionId)
    FGUI:GRichTextField_setText(self._uiTips.text_condition, sTips)

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
	FGUI:setOnClickEvent(self._uiTips.btn_practice, handler(self, self.OnClickPractice))

    FGUI:SetIntData(self._uiTips.btn_practice, SkillID)
end

function MySkill:UpdatePlayerInfo()
    local itemID = 7
    local itemName = SL:GetValue("ITEM_NAME", itemID)
    local itemCount = SL:GetValue("ITEM_COUNT", itemID)
    FGUI:GTextField_setText(self._ui.text_myScore, string.format(GET_STRING(60012016), itemName, itemCount))
end

function MySkill:CheckSkillCost(skillID, showTips)
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

-- event
function MySkill:OnClickSkillIcon(context)
    local selID = FGUI:GetIntData(context.data)
    self:RefreshSkillIcon(selID)

    local isLearned = self._skillCells[selID].isLearned
    local isCondition = self._skillCells[selID].isCondition
    if isLearned and isCondition then 
        self._selSkillID = self._skillCells[selID].id
        self._selSkillLevel = self._skillCells[selID].level
    else 
        self:CleanSelSkill()
    end 
    
    self:ShowSkillTips(self._skillCells[selID].id, self._skillCells[selID].level)
    self:RefreshSkillPad(false)
end

function MySkill:OnClickPadSkill(context)
    if not self._selSkillID then 
        return 
    end 

    local key = FGUI:GetIntData(context.sender)
    self:SkillChangeKey(self._selSkillID, key)
    self:CleanSelSkill()
    self:RefreshSkillIcon(nil)
    self:RefreshSkillPad(false)
end

function MySkill:OnClickConfig(context)
    if not self._selSkillID then 
        return 
    end 

    self:RefreshSkillPad(true)
    FGUI:setVisible(self._ui.skill_tips, false)
end

function MySkill:OnClickPractice(context)
    FGUI:setVisible(self._ui.skill_tips, false)

    local skillID = FGUI:GetIntData(context.sender)
    local isLearned = self._skillCells[skillID].isLearned
    local isCondition = self._skillCells[skillID].isCondition
    if not isLearned and not isCondition then 
        SL:ShowSystemTips(GET_STRING(60012017))
        return 
    end 

    local isLevelUp = self:CheckSkillCost(skillID, true)
    if not isLevelUp then 
        return 
    end 

    SL:RequestWuGongLevelUp(skillID)
end

function MySkill:OnClickMask(context)
    self:CleanSelSkill()
    FGUI:setVisible(self._ui.skill_tips, false)
end

function MySkill:OnWuGongLevelUp()
    FGUI:setVisible(self._ui.skill_tips, false)
    self._skillWuGong = SL:GetValue("SKILL_WUGONG_TYPE_BY_GOODEVIL", self._myJob, self._selPage, self._myGoodEvil)
    self:UpdateSkillList()
    self:UpdateSkillPad()
    self:UpdatePlayerInfo()
end

-----------------------------------注册事件--------------------------------------
function MySkill:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_WUGONG_LEVELUP, "MySkill", handler(self, self.OnWuGongLevelUp))
end

function MySkill:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_WUGONG_LEVELUP, "MySkill")
end

return MySkill