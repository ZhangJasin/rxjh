local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCSkillStudyPanel = class("PCSkillStudyPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local PAGE_DATA = {
	[1] = {name = "职业武功", page = 1, obj = nil},
	[2] = {name = "通用武功", page = 2, obj = nil},
}

function PCSkillStudyPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    self._uiTips = FGUI:ui_delegate(FGUI:GetChild(self.component, "skill_tips"))
    self:InitEvent()
end 

function PCSkillStudyPanel:Enter()
    self:RegisterEvent()
    self:InitData()
    ------------交易行截图begin----------
    local tradingIndex = global.TradingCaptureDatas and global.TradingCaptureDatas.tradingIndex
    ------------交易行截图end----------
    self:SelectPage(tradingIndex and 2 or 1)
end

function PCSkillStudyPanel:Exit()
	self:RemoveEvent()
    self:CleanData()
end

function PCSkillStudyPanel:InitData()
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

function PCSkillStudyPanel:CleanData()
    self._selPage = 1
    self._skillWuGong = nil
    self._selSkillID = nil
    self._selSkillLevel = nil
    self._skillCells = {}
    self._costList = {}
    self._skills = {}
end

function PCSkillStudyPanel:CleanSelSkill()
    self._selSkillID = nil
    self._selSkillLevel = nil
end

function PCSkillStudyPanel:InitEvent()
    -- 重置键位
	FGUI:setOnClickEvent(self._ui.btn_reset, handler(self, self.SkillResetKey))

	FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.ItemRendererPage))
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))
end

function PCSkillStudyPanel:ItemRendererPage(idx, item)
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

function PCSkillStudyPanel:OnClickPage()
    local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
    self:SelectPage(index)
end

function PCSkillStudyPanel:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page, index - 1)
    FGUI:setVisible(self._ui.skill_tips, false)
    self:CleanData()

	self._selPage = index
    self._skillWuGong = SL:GetValue("SKILL_WUGONG_TYPE_BY_GOODEVIL", self._myJob, self._selPage, self._myGoodEvil)
    self:UpdateSkillList()
    self:UpdatePlayerInfo()
end

-- 左边 技能表
function PCSkillStudyPanel:UpdateSkillList()
    if not self._skillWuGong then 
        return 
    end 

	FGUI:GList_itemRenderer(self._ui.list_skill, handler(self, self.SkillTypeListRenderer))
    FGUI:GList_setNumItems(self._ui.list_skill, #self._skillWuGong)
end

-- 类别(大页签)
local SkillGroup = {}
function PCSkillStudyPanel:SkillTypeListRenderer(idx, item)
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
    FGUI:GList_setNumItems(list_icon, #SkillGroup)
end

-- 组别(技能组)
function PCSkillStudyPanel:SkillGroupRenderer(idx, item) 
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
    self._skillCells[SkillID] = data

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
            sTips = SL:GetValue("CONDITION_TIPS", SkillGroup[index].ConditionId) -- GET_STRING(60012022)
        end 
    end 
    
    FGUI:GRichTextField_setText(ui_condition, sTips)
    FGUI:setVisible(ui_condition, not isLearned)

    -- skill mask 
    local ui_mask = FGUI:GetChild(item, "skill_mask")
    FGUI:setVisible(ui_mask, not isLearned)

    -- skill drag 
    if isLearned then 
        FGUI:setOnClickEvent(ui_icon, handler(self, self.OnClickSkillIcon))
    else 
        FGUI:setOnClickEvent(ui_icon, handler(self, self.OnClickStudy))
    end 
    FGUI:SetIntData(ui_icon, SkillID)
    FGUI:setOnRollOverEvent(ui_icon, handler(self, self.OnTouchSkillIconOver, SkillID))
    FGUI:setOnRollOutEvent(ui_icon, handler(self, self.OnTouchSkillIconOut, SkillID))
end

function PCSkillStudyPanel:ShowSkillTips(SkillID, SkillLevel)
    if not SkillID and SkillLevel then 
        return
    end 

    FGUI:setVisible(self._ui.skill_tips, true)

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
end

function PCSkillStudyPanel:UpdatePlayerInfo()
    local itemID = 7
    local itemName = SL:GetValue("ITEM_NAME", itemID)
    local itemCount = SL:GetValue("ITEM_COUNT", itemID)
    local color = itemCount == 0 and "#FF0000" or "#00FF00"
    FGUI:GTextField_setText(self._ui.text_myScore, string.format(GET_STRING(60012016), itemName, color, itemCount))
end

function PCSkillStudyPanel:CheckSkillCost(skillID, showTips)
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

function PCSkillStudyPanel:CheckSkillStudy(skillID, showTips)
    local isLearned = self._skillCells[skillID].isLearned
    local isCondition = self._skillCells[skillID].isCondition
    if not isLearned and not isCondition then 
        if showTips then 
            SL:ShowSystemTips(GET_STRING(60012017))
        end
        return 
    end 

    local isCost = self:CheckSkillCost(skillID, true)
    if not isCost then 
        if showTips then 
            SL:ShowSystemTips(GET_STRING(60012019))
        end
        return 
    end 

    return true
end

-- drag
function PCSkillStudyPanel:OnClickSkillIcon(context)
    local selID = FGUI:GetIntData(context.sender)
    local icon_skill = context.sender
    if icon_skill then 
        local touchId = FGUI:InputEvent_getTouchId(context)
        local data = {
            type = FGUIDefine.PCQuickType.Skill,
            id = selID,
        }
        FGUI:DragDropManager_startDrag(icon_skill, SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", selID), data, touchId)
    end 
end

-- touch over 
function PCSkillStudyPanel:OnTouchSkillIconOver(skillID)
    self:ShowSkillTips(self._skillCells[skillID].id, self._skillCells[skillID].level)
end

-- touch out
function PCSkillStudyPanel:OnTouchSkillIconOut(skillID)
    FGUI:setVisible(self._ui.skill_tips, false)
end


function PCSkillStudyPanel:OnClickStudy(context)
    FGUI:setVisible(self._ui.skill_tips, false)

    local skillID = FGUI:GetIntData(context.sender)
    local isStudy = self:CheckSkillStudy(skillID, true)
    if not isStudy then 
        return 
    end 

    SL:RequestWuGongStudy(skillID)
end

function PCSkillStudyPanel:OnClickUpgrade(context)
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

-- 重置键位
function PCSkillStudyPanel:SkillResetKey()
    local skills = SL:GetValue("SKILL_ALL_DATA")
    for _, data in pairs(skills) do
        self:SkillDeleteKey(data.SkillId, data.Key) 
    end

    self:CleanSelSkill()
    SL:RequestSaveSkillKeys()
end

-- 改变键位
function PCSkillStudyPanel:SkillChangeKey(skillId, skillKey)
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
function PCSkillStudyPanel:SkillDeleteKey(skillId, skillKey)
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

function PCSkillStudyPanel:OnWuGongStudy()
    FGUI:setVisible(self._ui.skill_tips, false)
    self._skillWuGong = SL:GetValue("SKILL_WUGONG_TYPE_BY_GOODEVIL", self._myJob, self._selPage, self._myGoodEvil)
    self:UpdateSkillList()
    self:UpdatePlayerInfo()
end

-----------------------------------注册事件--------------------------------------
function PCSkillStudyPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_WUGONG_STUDY, "PCSkillStudyPanel", handler(self, self.OnWuGongStudy))
end

function PCSkillStudyPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_WUGONG_STUDY, "PCSkillStudyPanel")
end

return PCSkillStudyPanel