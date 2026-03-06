local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorSkillStudyPanel = class("VisitorSkillStudyPanel", BaseFGUILayout)
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

function VisitorSkillStudyPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    self._uiTips = FGUI:ui_delegate(FGUI:GetChild(self.component, "skill_tips"))

    self:InitData()
    self:InitEvent()
end 

function VisitorSkillStudyPanel:Enter()
    self:SelectPage(1)
end

function VisitorSkillStudyPanel:Exit()
    self:CleanData()
end

function VisitorSkillStudyPanel:InitData()
    self._myJob = SL:GetValue("VISITOR_JOB")
    self._myGoodEvil = SL:GetValue("VISITOR_GOOD_DEBIL_ID")
    self._selPage = 1
    self._skillWuGong = nil
    self._selSkillID = nil
    self._selSkillLevel = nil
    self._skillCells = {}
    self._costList = {}
    self._skills = {}

    self._selScheme = nil

    self._autoSkill = {}
end

function VisitorSkillStudyPanel:CleanData()
    self._selPage = 1
    self._skillWuGong = nil
    self._selSkillID = nil
    self._selSkillLevel = nil
    self._skillCells = {}
    self._costList = {}
    self._skills = {}

    --self._schemeNames = {}
    self._selScheme = nil
    self._autoSkill = {}
end

function VisitorSkillStudyPanel:CleanSelSkill()
    self._selSkillID = nil
    self._selSkillLevel = nil
end

function VisitorSkillStudyPanel:InitEvent()
    -- Scheme点击空白  
	FGUI:setOnClickEvent(self._ui.mask, handler(self, self.OnClickSchemeMask))
    FGUI:setVisible(self._ui.mask, false)

    -- Tips点击空白
	FGUI:setOnClickEvent(self._uiTips.mask, handler(self, self.OnClickMask))
    -- page
	FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.ItemRendererPage))--上面三个 职业武功  通用武功 其他
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))

end

function VisitorSkillStudyPanel:ItemRendererPage(idx, item)--上面三个 职业武功  通用武功 其他
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

function VisitorSkillStudyPanel:OnClickPage()
    local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
    self:SelectPage(index)
end

function VisitorSkillStudyPanel:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page, index - 1)
    FGUI:setVisible(self._ui.skill_tips, false)

	self._selPage = PAGE_DATA[index].page
    self._skillWuGong = SL:GetValue("VISITOR_SKILL_WUGONG_TYPE_BY_GOODEVIL", self._myJob, self._selPage, self._myGoodEvil)
    self:UpdateSkillList()
end

---------------------------------技能列表---------------------------------start
function VisitorSkillStudyPanel:UpdateSkillList()--下面的技能表
    if not self._skillWuGong then 
        return 
    end 

	FGUI:GList_itemRenderer(self._ui.list_skill, handler(self, self.SkillTypeListRenderer))
    FGUI:GList_setNumItems(self._ui.list_skill, #self._skillWuGong)
end

-- 类别(大页签)
local SkillGroup = {}
function VisitorSkillStudyPanel:SkillTypeListRenderer(idx, item)
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
            local reLevel = SL:GetValue("VISITOR_RE_LEVEL") == 0 and 1 or SL:GetValue("VISITOR_RE_LEVEL")
            if itemData.NeedLevel then 
                if reLevel < itemData.NeedLevel then 
                    local showReLv = string.format(GET_STRING(5000+itemData.NeedLevel))
                    FGUI:GTextField_setText(ui_condition, string.format(GET_STRING(60012023), showReLv))--"%s转解锁"
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
function VisitorSkillStudyPanel:SkillGroupRenderer(idx, item) 
    local index = idx + 1
    if not SkillGroup[index] then 
        return 
    end

    local SkillID = SkillGroup[index].SkillID
    local SkillLevel = SkillGroup[index].SkillLevel
    local SkillName = SkillGroup[index].Name
    local SkillShowName = SkillGroup[index].ShowName
    local SkillCost = SkillGroup[index].Cost

    local isLearned = SL:GetValue("VISITOR_SKILL_DATA_BY_ID", SkillID) or nil --技能是否学了
    local isCondition = SL:GetValue("CONDITION", SkillGroup[index].ConditionId) --条件检测

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
    local path = SL:GetValue("VISITOR_SKILL_SQUARE_ICON_PATH_BY_ID", SkillID, SkillLevel)
    FGUI:GLoader_setUrl(ui_icon, path, nil, true)

    -- skill name 
    local ui_name = FGUI:GetChild(item, "text_name")
    FGUI:GTextField_setText(ui_name, SkillShowName)

    -- condition     
    local ui_condition = FGUI:GetChild(item, "text_condition")
    local sTips = SL:GetValue("CONDITION_TIPS", SkillGroup[index].ConditionId)
    if isLearned then--试玩服务器返回
        FGUI:GRichTextField_setColor(ui_condition, "#00ff00")
    else
        FGUI:GRichTextField_setColor(ui_condition, "#ff0000")
    end 
    FGUI:GRichTextField_setText(ui_condition, sTips)

    -- skill select 
    local ui_select = FGUI:GetChild(item, "icon_select")
    FGUI:setVisible(ui_select, false)
end

function VisitorSkillStudyPanel:RefreshListLight(selID)
    for id, cell in pairs(self._skillCells) do
        local ui_select = FGUI:GetChild(cell.item, "icon_select")
        local isShow = selID == id
        FGUI:setVisible(ui_select, isShow)
    end
end

function VisitorSkillStudyPanel:OnClickSkillIcon(context)
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
end

function VisitorSkillStudyPanel:OnClickSchemeMask()
    FGUI:setVisible(self._ui.list_scheme, false)
    FGUI:setVisible(self._ui.list_release, false)
    FGUI:setVisible(self._ui.mask, false)
end

function VisitorSkillStudyPanel:OnClickMask(context)
    self:CleanSelSkill()
    FGUI:setVisible(self._ui.skill_tips, false)
end

---------------------------------技能列表---------------------------------end


function VisitorSkillStudyPanel:OnTipCallBack(op, skillId, skillLevel)
    if op == FGUIDefine.SkillTipOp.Close then--Mask关闭
        self:CleanSelSkill()
    end
end
---------------------------------技能tips---------------------------------end
function VisitorSkillStudyPanel:ShowSkillTips(SkillID, SkillLevel)
    if not SkillID and SkillLevel then 
        return
    end 

    local skillConfig = SL:GetValue("VISITOR_SKILL_UPGRADE_CONFIG_BY_ID_LEVEL", SkillID, SkillLevel)

    FGUI:setVisible(self._ui.skill_tips, true)
    FGUI:setVisible(self._uiTips.btn_config, false)
    FGUI:setVisible(self._uiTips.btn_upgrade, false)
    FGUI:setVisible(self._uiTips.btn_practice, false)

    -- icon 
    local path = SL:GetValue("VISITOR_SKILL_SQUARE_ICON_PATH_BY_ID", SkillID)
    FGUI:GLoader_setUrl(self._uiTips.skill_icon, path, nil, true) 

    -- name
    local name = SL:GetValue("VISITOR_SKILL_UP_SHOWNAME_BY_ID", SkillID, SkillLevel)
    FGUI:GTextField_setText(self._uiTips.text_name, name)

    -- range type
    local rangeType = SL:GetValue("VISITOR_SKILL_RANGE_CATEGORY", SkillID)
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
    local desc = SL:GetValue("VISITOR_SKILL_UP_DESC_BY_ID", SkillID, SkillLevel)
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
    local skillCfg = SL:GetValue("VISITOR_SKILL_CONFIG_BY_SKILL_ID", SkillID)
    if skillCfg then 
        FGUI:GTextField_setText(self._uiTips.text_cd, string.format(GET_STRING(60012006), skillCfg.CD * 0.001 or 0))
    end


    FGUI:SetIntData(self._uiTips.btn_practice, SkillID)
end

function VisitorSkillStudyPanel:CheckSkillCost(skillID, showTips)
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

return VisitorSkillStudyPanel