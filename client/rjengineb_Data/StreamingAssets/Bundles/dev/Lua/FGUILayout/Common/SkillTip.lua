local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local SkillTip = class("SkillTip", BaseFGUILayout)

function SkillTip:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._costList = {}

    if not SL:GetValue("IS_PC_OPER_MODE") then
        self:InitMobile()
    end

    FGUI:GList_itemRenderer(self._ui.list_cost, handler(self, self.OnCostItemRender))
end

function SkillTip:Enter()

end

function SkillTip:Exit()
    self._callBack = nil
end

function SkillTip:Refresh(data)
    if not data then return end
    local SkillID = data.id
    local SkillLevel = data.level
    self._callBack = data.callBack
    if self._skillID ~= SkillID or self._skillLevel ~= SkillLevel then
        self._skillID = SkillID
        self._skillLevel = SkillLevel
        self:UpdateSkillTip(SkillID, SkillLevel)
    end
    if not SL:GetValue("IS_PC_OPER_MODE") then
        self:UpdateButtons(data.showBtn, SkillID, SkillLevel)
    end
    local ax = data.anchorX or 0
    local ay = data.anchorY or 0
    FGUI:setAnchorPoint(self.component, ax, ay, true)
    --无坐标数据默认居中
    if data.posX and data.posY then
        FGUIFunction:SetSafePosition(self.component, data.posX, data.posY)
    end
end

-------------------------------------------------------------------------------

function SkillTip:UpdateSkillTip(SkillID, SkillLevel)
    if not SkillID or not SkillLevel then return end 

    local skillConfig = SL:GetValue("SKILL_UPGRADE_CONFIG_BY_ID_LEVEL", SkillID, SkillLevel)

    -- icon 
    local path = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", SkillID)
    FGUI:GLoader_setUrl(self._ui.skill_icon, path, nil, true) 

    -- name
    local name = SL:GetValue("SKILL_UP_NAME_BY_ID", SkillID, SkillLevel)
    FGUI:GTextField_setText(self._ui.text_name, name)

    -- condition 
    local sTips = SL:GetValue("CONDITION_TIPS", skillConfig.ConditionId)
    FGUI:GRichTextField_setText(self._ui.text_condition, sTips)

    -- cost
    table.clear(self._costList)
    if skillConfig.Cost then 
        local sp = string.split(skillConfig.Cost, "|")
        for i = 1, #sp do 
            local data = {}
            local sp2 = string.split(sp[i], "#")
            data.id = tonumber(sp2[1])
            data.count = tonumber(sp2[2])
            table.insert(self._costList, data)
        end 
    end
    FGUI:GList_setNumItems(self._ui.list_cost, #self._costList)

    -- desc
    local desc = SL:GetValue("SKILL_UP_DESC_BY_ID", SkillID, SkillLevel)
    FGUI:GRichTextField_setText(self._ui.text_desc, desc)

    -- weili
    FGUI:GTextField_setText(self._ui.text_weili, string.format(GET_STRING(60012004), skillConfig.Power or 0))

    -- att   
    local skillcost = skillConfig.SkillCost
    if skillcost then 
        if tonumber(skillcost[1]) == 0 then 
            local attData = SL:GetValue("ATTR_CONFIG", tonumber(skillcost[2]))
            if attData then 
                FGUI:GTextField_setText(self._ui.text_neili, string.format(GET_STRING(60012005), attData.Name, tonumber(skillcost[3])))
            end 
        end 
    end

    -- cd
    local skillCfg = SL:GetValue("SKILL_CONFIG_BY_SKILL_ID", SkillID)
    if skillCfg then 
        FGUI:GTextField_setText(self._ui.text_cd, string.format(GET_STRING(60012006), skillCfg.CD * 0.001 or 0))
    end
end

function SkillTip:UpdateButtons(showBtn, SkillID, SkillLevel)
    if not showBtn then
        FGUI:setVisible(self._ui.btn_config, false)
        FGUI:setVisible(self._ui.btn_upgrade, false)
        FGUI:setVisible(self._ui.btn_practice, false)
    else

        local skillConfig = SL:GetValue("SKILL_UPGRADE_CONFIG_BY_ID_LEVEL", SkillID, SkillLevel)
        local isLearned = SL:GetValue("SKILL_IS_LEARNED", SkillID)
        local isCondition = SL:GetValue("CONDITION", skillConfig.ConditionId)

        FGUI:setVisible(self._ui.btn_config, isLearned and isCondition)
        FGUI:setVisible(self._ui.btn_upgrade, showBtn and skillConfig.TipsBtn)
        FGUI:setVisible(self._ui.btn_practice, not isLearned)
    end
end

function SkillTip:OnCostItemRender(idx, item)
    local index = idx + 1
    local data = self._costList[index]
    if not data then return end  

    local text_cost = FGUI:GetChild(item, "text_cost")
    local itemName = SL:GetValue("ITEM_NAME", data.id)
    local myCount = SL:GetValue("ITEM_COUNT", data.id)
    local needCount = data.count   
    local color = myCount >= needCount and "#00FF00" or "#FF0000"
    FGUI:GTextField_setText(text_cost, string.format(GET_STRING(60012007), itemName, color, needCount))
end

---------------------------------------------------------------------------
--手机端
function SkillTip:InitMobile()
	FGUI:setOnClickEvent(self._ui.mask, handler(self, self.OnClose))
    FGUI:setOnClickEvent(self._ui.btn_config, handler(self, self.OnClickConfig))
	FGUI:setOnClickEvent(self._ui.btn_upgrade, handler(self, self.OnClickUpgrade))
	FGUI:setOnClickEvent(self._ui.btn_practice, handler(self, self.OnClickPractice))
end

function SkillTip:OnClose()
    if self._callBack then 
        self._callBack(FGUIDefine.SkillTipOp.Close, self._skillID, self._skillLevel)
    end
    self:Close()
end

function SkillTip:OnClickConfig(context)
    if self._callBack then 
        self._callBack(FGUIDefine.SkillTipOp.Set, self._skillID, self._skillLevel)
    end
    self:Close()
end

function SkillTip:OnClickPractice(context)
    if self._callBack then 
        self._callBack(FGUIDefine.SkillTipOp.Study, self._skillID)
    end
    self:Close()
end

function SkillTip:OnClickUpgrade(context)
    if self._callBack then 
        self._callBack(FGUIDefine.SkillTipOp.Upgrade, self._skillID, self._skillLevel)
    end
    self:Close()
end



return SkillTip