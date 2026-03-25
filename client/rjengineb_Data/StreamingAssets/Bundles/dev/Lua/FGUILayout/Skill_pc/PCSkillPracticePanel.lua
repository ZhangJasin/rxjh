local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCSkillPracticePanel = class("PCSkillPracticePanel", BaseFGUILayout)

local PAGE_DATA = {
	[1] = {name = "通用气功", page = 1},
	[2] = {name = "登封气功", page = 2},
}

function PCSkillPracticePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    self._uiTips = FGUI:ui_delegate(self._ui.panel_tips)
    self:InitData()
    self:InitEvent()
end 

function PCSkillPracticePanel:Enter()
    self:RegisterEvent()

    ------------交易行截图begin----------
    local tradingIndex = global.TradingCaptureDatas and global.TradingCaptureDatas.tradingIndex
    ------------交易行截图end----------
    
    self:SelectPage(tradingIndex and 2 or 1)
end

function PCSkillPracticePanel:Exit()
	self:RemoveEvent()
end

function PCSkillPracticePanel:InitData()
    self._selPage = 1
    self._qigongList = {}
end

function PCSkillPracticePanel:InitEvent()
    -- page
	FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.ItemRendererPage))
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))

    -- list
	FGUI:GList_itemRenderer(self._ui.list_qigong, handler(self, self.OnListItemRenderer))
end

function PCSkillPracticePanel:ItemRendererPage(idx, item)
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

function PCSkillPracticePanel:OnClickPage()
    local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
    self:SelectPage(index)
end

function PCSkillPracticePanel:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page, index - 1)
	self._selPage = index

    local qigongData = SL:GetValue("SKILL_QIGONG_BY_TYPE", self._selPage)
    qigongData = HashToSortArray(qigongData, function(a, b)
        if not a.Sort or not b.Sort then 
            return a.ID < b.ID 
        end 

        if a.Sort == b.Sort then 
            return a.ID < b.ID 
        end 

        return a.Sort < b.Sort
    end)

    self._qigongList = qigongData
    self:UpdatePlayerInfo()
    self:UpdateSkillList()
end

-- 左边 气功列表
function PCSkillPracticePanel:UpdateSkillList()
	FGUI:GList_setSelectedIndex(self._ui.list_qigong, -1)
    FGUI:GList_setNumItems(self._ui.list_qigong, #self._qigongList)
end

function PCSkillPracticePanel:OnListItemRenderer(idx, item)
    local index = idx + 1
    local data = self._qigongList[index] 
    if not data then 
        return 
    end

    local qigongData = SL:GetValue("SKILL_QIGONG_BY_ID", data.ID)
    local qigongID = qigongData.ID
    local curLevel = qigongData.CurLv or 0     -- 气功等级
    local scriptLv = qigongData.LevelEx or 0   -- 脚本等级
    local equipLv = qigongData.EquipLevel or 0 -- 装备等级
    local realLevel = curLevel + scriptLv + equipLv

    local curData = SL:GetValue("SKILL_QIGONG_CONFIG_BY_ID_AND_LEVEL", qigongID, realLevel)
    if not curData then 
        return 
    end 

    -- icon
    local ui_icon = FGUI:GetChild(item, "skill_icon")
    local path = SL:GetValue("SKILL_QIGONG_SQUARE_ICON_BY_ID", qigongID)
    FGUI:GLoader_setUrl(ui_icon, path, nil, true)  
    FGUI:setOnRollOverEvent(ui_icon, handler(self, self.OnTouchSkillIconOver, qigongData))
    FGUI:setOnRollOutEvent(ui_icon, handler(self, self.OnTouchSkillIconOut, qigongData))

    -- lv
    local ui_lv = FGUI:GetChild(item, "text_level")
    if scriptLv > 0 or equipLv > 0 then 
        FGUI:GRichTextField_setText(ui_lv, string.format(GET_STRING(60012024), curLevel, scriptLv + equipLv))
    else        
        FGUI:GRichTextField_setText(ui_lv, tostring(curLevel))
    end 

    -- condition
    local ui_condition = FGUI:GetChild(item, "text_condition")
    local isLevelOk = self:CheckQiGongLevel(qigongID)
    local isQiGongOk = self:CheckQiGongOk(qigongID)
    if isLevelOk then 
        if qigongData.CurLv > 0 then 
            FGUI:GRichTextField_setText(ui_condition, "升级")
        else 
            FGUI:GRichTextField_setText(ui_condition, "修炼")
        end 

        local color = isQiGongOk and "#00ff00" or "#FF0000"
        FGUI:GRichTextField_setColor(ui_condition, color) 
    else 
        FGUI:GRichTextField_setText(ui_condition, string.format(GET_STRING(60012025), curData.LevelRequire))
    end

    -- btn
    local btn_add = FGUI:GetChild(item, "btn_add")
    FGUI:setOnClickEvent(btn_add, handler(self, self.OnClickStudy))
    FGUI:SetIntData(btn_add, idx)
end

function PCSkillPracticePanel:UpdatePlayerInfo()
    local itemID = 19
    local itemName = SL:GetValue("ITEM_NAME", itemID)
    local itemCount = SL:GetValue("ITEM_COUNT", itemID)
    local color = itemCount == 0 and "#FF0000" or "#00FF00"
    FGUI:GTextField_setText(self._ui.text_myScore, string.format(GET_STRING(60012016), itemName, color, itemCount))
end

function PCSkillPracticePanel:ShowSkillTips(qigongData)
    local qigongID = qigongData.ID
    local qigongMax = qigongData.Lv
    local curLevel = qigongData.CurLv or 0     -- 气功等级
    local scriptLv = qigongData.LevelEx or 0   -- 脚本等级
    local equipLv = qigongData.EquipLevel or 0 -- 装备等级
    local realLevel = curLevel + scriptLv + equipLv
    local nextLevel = curLevel+1 > qigongMax and qigongMax or curLevel+1
    local realNextLevel = nextLevel + scriptLv + equipLv

    local curData = SL:GetValue("SKILL_QIGONG_CONFIG_BY_ID_AND_LEVEL", qigongID, realLevel)
    if not curData then 
        return 
    end 
    FGUI:setVisible(self._ui.panel_tips, true)

    local sInfo = ""
    -- name 
    FGUI:GTextField_setText(self._uiTips.text_name, curData.Name)

    -- desc 
    FGUI:GRichTextField_setText(self._uiTips.text_desc, curData.Desc)

    -- level    
    sInfo = string.format("[size=14]级别：%s\n[/size]", realLevel)

    -- cur desc
    local tDescList = {}
    local tDesc1 = string.split(curData.DescShow, "|")
    if tDesc1 then 
        for i = 1, #tDesc1 do 
            local cellDesc = string.split(tDesc1[i], "#")  
            tDescList[i] = {}
            tDescList[i].name = cellDesc[1]
            tDescList[i].value = cellDesc[2]
        end 
    end 

    for i, v in ipairs(tDescList) do   
        sInfo = sInfo..string.format("[size=12]%s：%s\n[/size]", v.name, v.value)
    end 

    -- next    
    sInfo = sInfo.."[size=14]-下一步-\n[/size]"
    local nextData = SL:GetValue("SKILL_QIGONG_CONFIG_BY_ID_AND_LEVEL", qigongID, realNextLevel)
    if realLevel+1 > qigongMax then 
        sInfo = sInfo..string.format("[size=14]%s[/size]", GET_STRING(60012014))
    else     
        local tDescList2 = {}
        local tDesc2 = string.split(nextData.DescShow, "|")
        if tDesc2 then 
            for i = 1, #tDesc2 do 
                local cellDesc = string.split(tDesc2[i], "#")
                tDescList2[i] = {}
                tDescList2[i].name = cellDesc[1]
                tDescList2[i].value = cellDesc[2]
            end 
        end 

        for i, v in ipairs(tDescList2) do  
            if i == # tDescList2 then 
                sInfo = sInfo..string.format("[size=12]%s：%s[/size]", v.name, v.value)
            else     
                sInfo = sInfo..string.format("[size=12]%s：%s\n[/size]", v.name, v.value)
            end 
        end
    end 
    FGUI:GRichTextField_setText(self._uiTips.text_info, sInfo)
    local richH = FGUI:GRichTextField_getTextHeight(self._uiTips.text_info)
    local defaultH = 70
    local panelH = 150
    FGUI:setHeight(self._uiTips.bg, richH-defaultH > 0 and panelH + (richH-defaultH) or panelH)
end   

function PCSkillPracticePanel:HideSkillTips()
    FGUI:setVisible(self._ui.panel_tips, false)
end

-- touch over 
function PCSkillPracticePanel:OnTouchSkillIconOver(qigongData)
    self:ShowSkillTips(qigongData)
end

-- touch out
function PCSkillPracticePanel:OnTouchSkillIconOut(skillID)
    self:HideSkillTips()
end

-- 升级
function PCSkillPracticePanel:OnClickStudy(context)
    FGUI:delayTouchEnabled(context.sender, 0.5)
    local index = FGUI:GetIntData(context.sender) + 1
    local data = self._qigongList[index]
    if not data then  
        return
    end

    local isLevelUp = self:CheckQiGongOk(data.ID, true)
    if not isLevelUp then 
        return 
    end 

    SL:RequestQiGongLevelUp(data.ID)
end

function PCSkillPracticePanel:CheckQiGongLevel(skillID, showTips)
    local qigongData = SL:GetValue("SKILL_QIGONG_BY_ID", skillID)
    if not qigongData then 
        return 
    end 

    if qigongData.CurLv+1 > qigongData.Lv then 
        return true
    end 

    local nextLevel = qigongData.CurLv + 1
    local nextData = SL:GetValue("SKILL_QIGONG_CONFIG_BY_ID_AND_LEVEL", skillID, nextLevel)
    if not nextData then 
        return 
    end 

    local myLevel = SL:GetValue("LEVEL")
    if myLevel < nextData.LevelRequire then 
        if showTips then 
            SL:ShowSystemTips(GET_STRING(60012011))
        end
        return 
    end

    return true
end

function PCSkillPracticePanel:CheckQiGongOk(skillID, showTips)
    local qigongData = SL:GetValue("SKILL_QIGONG_BY_ID", skillID)
    if not qigongData then 
        return 
    end 

    if qigongData.CurLv+1 > qigongData.Lv then 
        print("max lv")
        return 
    end 

    local nextLevel = qigongData.CurLv + 1
    local nextData = SL:GetValue("SKILL_QIGONG_CONFIG_BY_ID_AND_LEVEL", skillID, nextLevel)
    if not nextData then 
        return 
    end 

    local myLevel = SL:GetValue("LEVEL")
    if myLevel < nextData.LevelRequire then 
        if showTips then 
            SL:ShowSystemTips(GET_STRING(60012011))
        end
        return 
    end 

    local sp = string.split(nextData.Cost, "#")
    local itemID = tonumber(sp[1])
    local itemCount = tonumber(sp[2])

    local myCount = SL:GetValue("ITEM_COUNT", itemID)
    if myCount < itemCount then 
        if showTips then 
            SL:ShowSystemTips(GET_STRING(60012012))
        end
        return 
    end 

    return true
end 

function PCSkillPracticePanel:OnQiGongLevelUp(skillID)
    FGUI:GList_setNumItems(self._ui.list_qigong, #self._qigongList)
    self:UpdatePlayerInfo()
end 

-----------------------------------注册事件--------------------------------------
function PCSkillPracticePanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_LEVELUP, "PCSkillPracticePanel", handler(self, self.OnQiGongLevelUp))
end

function PCSkillPracticePanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_LEVELUP, "PCSkillPracticePanel")

end

return PCSkillPracticePanel