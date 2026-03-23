local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCSkillPracticePanel = class("PCSkillPracticePanel", BaseFGUILayout)

local PAGE_DATA = {
	[1] = {name = "通用气功", page = 1},
	[2] = {name = "登封气功", page = 2},
}

local MAX_QIGONG_SCHEME_COUNT = 6

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
    self:InitQiGongSchemes()
end

function PCSkillPracticePanel:Exit()
    self._selPage = 1
    self._qigongList = {}
    self._selScheme = nil
    self._schemeNames = {}
    self._inputState = 1
	self:RemoveEvent()
end

function PCSkillPracticePanel:InitData()
    self._selPage = 1
    self._qigongList = {}
    self._selScheme = nil
    self._schemeNames = {}
    self._inputState = 1
end

function PCSkillPracticePanel:InitEvent()
    -- Scheme点击空白  
	FGUI:setOnClickEvent(self._ui.mask, handler(self, self.OnClickSchemeMask))

    -- page
	FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.ItemRendererPage))
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))

    -- list
	FGUI:GList_itemRenderer(self._ui.list_qigong, handler(self, self.OnListItemRenderer))

    -- 方案 
    FGUI:GList_itemRenderer(self._ui.list_scheme, handler(self, self.SchemeListRenderer))
	FGUI:setOnClickEvent(self._ui.btn_scheme, handler(self, self.OnClickBtnScheme))
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

function PCSkillPracticePanel:ShowSkillTips(qigongData, posX, posY)
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
    FGUI:setPosition(self._ui.panel_tips, posX, posY)

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

---气功方案
function PCSkillPracticePanel:InitQiGongSchemes()
    -- 初始化方案名字
    local count = SL:GetValue("SKILL_QIGONG_SCHEME_COUNT")
    local schemes = {}
    for i = 1, count do
        schemes[i] = SL:GetValue("GET_QIONG_SCHEME_NAME", i-1)
    end
    self._schemeNames = HashToSortArray(schemes)

    table.insert(self._schemeNames, "")

    -- 方案
    local scheme = SL:GetValue("SKILL_QIGONG_SEL_SCHEME")
    self._selScheme = scheme
    FGUI:GTextField_setText(self._ui.text_scheme, self._schemeNames[scheme+1])
    FGUI:setHeight(self._ui.list_scheme, #self._schemeNames * 40)
    FGUI:GList_setNumItems(self._ui.list_scheme, #self._schemeNames)

    self:SetInputing(1)
end

function PCSkillPracticePanel:SchemeListRenderer(idx, item)
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
    self:RefreshSchemeItemTouchState(item)

    -- input
	FGUI:GTextField_setText(input_name, name)
    FGUI:setOnFocusOut(input_name, function()
        local inputName = FGUI:GTextInput_getText(input_name)
        if string.len(inputName) == 0 then 
            self:SetInputing(0)
            self:RefreshSchemeItemTouchState(item)
            return 
        end 
        self:SetInputing(1)
        self:RefreshSchemeItemTouchState(item)

        self._schemeNames[idx+1] = inputName
        SL:SetValue("SET_QIONG_SCHEME_NAME", idx, inputName)
    end)

    -- btn select
	FGUI:setOnClickEvent(ui_select, function(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
        if not self:CheckInputing() then 
            return
        end 
        
        -- add
        if name == "" then 
            local count = SL:GetValue("SKILL_QIGONG_SCHEME_COUNT")
            if count >= MAX_QIGONG_SCHEME_COUNT then 
                SL:ShowSystemTips(string.format(GET_STRING(60012028), MAX_QIGONG_SCHEME_COUNT))
                return 
            end 

            SL:RequestQiGongSchemeAdd(idx)
            return 
        end 

        -- select
        local lastIdx = self._selScheme
        FGUI:GTextField_setText(self._ui.text_scheme, name)
        if lastIdx ~= idx then 
            SL:RequestQiGongSchemeChange(idx) 
        end 

        self:HideSchemeUI()
	end)

    -- btn edit
	FGUI:setOnClickEvent(btn_edit, function()
        if not self:CheckInputing() then 
            return
        end 

        self:SetInputing(0)
        self:RefreshSchemeItemTouchState(item)
		FGUI:GTextField_setText(input_name, "")
	end)
end

function PCSkillPracticePanel:ShowSchemeUI()
    FGUI:setVisible(self._ui.list_scheme, not FGUI:getVisible(self._ui.list_scheme))
    FGUI:setVisible(self._ui.mask, true)
end

function PCSkillPracticePanel:HideSchemeUI()
    FGUI:setVisible(self._ui.list_scheme, false)
    FGUI:setVisible(self._ui.mask, false)
end

function PCSkillPracticePanel:RefreshSchemeItemTouchState(item)
	local input_name = FGUI:GetChild(item, "input_title")
	local ui_select = FGUI:GetChild(item, "select")
    FGUI:setTouchEnabled(input_name, self._inputState == 0)
    FGUI:setTouchEnabled(ui_select, self._inputState ~= 0)
end 

function PCSkillPracticePanel:SetInputing(state)
    self._inputState = state
end

function PCSkillPracticePanel:CheckInputing()
    if self._inputState == 0 then 
        SL:ShowSystemTips(GET_STRING(60012029))
        return false
    end 

    return true
end

function PCSkillPracticePanel:OnClickBtnScheme()
    if not self:CheckInputing() then 
        return
    end 

    self:ShowSchemeUI()
    FGUI:GList_setNumItems(self._ui.list_scheme, #self._schemeNames)
end

function PCSkillPracticePanel:OnClickSchemeMask()
    if not self:CheckInputing() then 
        return
    end 

    self:HideSchemeUI()
end

-- touch over 
function PCSkillPracticePanel:OnTouchSkillIconOver(qigongData, eventData)
    local posX, posY = FGUI:getWorldPosition(eventData.sender)
    local parentPosX, parentPosY = FGUI:getWorldPosition(FGUI:GetParent(self.component))
    self:ShowSkillTips(qigongData, posX-parentPosX, posY-parentPosY)
end

-- touch out
function PCSkillPracticePanel:OnTouchSkillIconOut(skillID)
    self:HideSkillTips()
end

-- 升级
function PCSkillPracticePanel:OnClickStudy(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
    local index = FGUI:GetIntData(eventData.sender) + 1
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

-- 事件 增加方案
function PCSkillPracticePanel:OnQiGongSchemeAdd(idx)
    local schemeName = SL:GetValue("GET_QIONG_SCHEME_NAME",idx)
    local index = idx + 1
    self._schemeNames[index] = schemeName
    table.insert(self._schemeNames, "")

    FGUI:GList_setNumItems(self._ui.list_scheme, #self._schemeNames)
    FGUI:setHeight(self._ui.list_scheme, #self._schemeNames * 40)
end

-- 事件 改变方案
function PCSkillPracticePanel:OnQiGongSchemeChange(idx)
    local schemeName = SL:GetValue("GET_QIONG_SCHEME_NAME",idx)
    FGUI:GTextField_setText(self._ui.text_scheme, schemeName) 
    self._selScheme = idx

    self:SelectPage(1)
end

-----------------------------------注册事件--------------------------------------
function PCSkillPracticePanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_LEVELUP, "PCSkillPracticePanel", handler(self, self.OnQiGongLevelUp))
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_SCHEME_ADD, "PCSkillPracticePanel", handler(self, self.OnQiGongSchemeAdd))
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_SCHEME_CHANGE, "PCSkillPracticePanel", handler(self, self.OnQiGongSchemeChange))
end

function PCSkillPracticePanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_LEVELUP, "PCSkillPracticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_SCHEME_ADD, "PCSkillPracticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_SCHEME_CHANGE, "PCSkillPracticePanel")
end

return PCSkillPracticePanel