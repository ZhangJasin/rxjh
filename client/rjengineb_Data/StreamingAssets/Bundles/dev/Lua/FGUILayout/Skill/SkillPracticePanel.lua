local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local SkillPracticePanel = class("SkillPracticePanel", BaseFGUILayout)

local PAGE_DATA = {
	[1] = {name = "通用气功", page = 1},
	[2] = {name = "登封气功", page = 2},
}

local MAX_QIGONG_SCHEME_COUNT = 6

function SkillPracticePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:InitEvent()
end 

function SkillPracticePanel:Enter()
    self:RegisterEvent()

    ------------交易行截图begin----------
    local tradingIndex = global.TradingCaptureDatas and global.TradingCaptureDatas.tradingIndex
    ------------交易行截图end----------
    
    self:SelectPage(tradingIndex and 2 or 1)
    self:InitQiGongSchemes()

    FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.SkillGuideFunc,handler(self,self.GetSkillGuideIcon))
end

function SkillPracticePanel:Exit()
    self._selPage = 1
    self._qigongList = {}
    self._qigongCell = {}
    self._selQiGong = nil
    self._showExtraLv = true
    self._selScheme = nil
    self._schemeNames = {}
    self._inputState = 1
	self:RemoveEvent()

    FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.SkillGuideFunc)
end

function SkillPracticePanel:InitData()
    self._selPage = 1
    self._qigongList = {}
    self._qigongCell = {}
    self._selQiGong = nil
    self._showExtraLv = true
    self._selScheme = nil
    self._schemeNames = {}
    self._inputState = 1
end

function SkillPracticePanel:InitEvent()
    -- Scheme点击空白  
	FGUI:setOnClickEvent(self._ui.mask, handler(self, self.OnClickSchemeMask))

    -- btn 
	FGUI:setOnClickEvent(self._ui.btn_study, handler(self, self.OnClickStudy))
	FGUI:setOnClickEvent(self._ui.btn_cz, handler(self, self.OnClickReSet))
	FGUI:setOnClickEvent(self._ui.btn_czAll, handler(self, self.OnClickReSetAll))

    -- 额外气功等级
    FGUI:setOnClickEvent(self._ui.check_level, handler(self, self.OnClickShowExtraLevel))

    -- page
	FGUI:GList_itemRenderer(self._ui.list_page, handler(self, self.ItemRendererPage))
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)
    FGUI:GList_addOnClickItemEvent(self._ui.list_page, handler(self, self.OnClickPage))

    -- list
	FGUI:GList_itemRenderer(self._ui.list_qigong, handler(self, self.OnListItemRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.list_qigong, handler(self, self.OnClickSkillIcon))

    -- 方案 
    FGUI:GList_itemRenderer(self._ui.list_scheme, handler(self, self.SchemeListRenderer))
	FGUI:setOnClickEvent(self._ui.btn_scheme, handler(self, self.OnClickBtnScheme))

    -- 是否显示在主界面
    FGUI:setOnClickEvent(self._ui.check_main, handler(self, self.OnClickSchemeShowMain))
end

function SkillPracticePanel:ItemRendererPage(idx, item)
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

function SkillPracticePanel:OnClickPage()
    local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
    self:SelectPage(index)
end

function SkillPracticePanel:SelectPage(index)
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

    table.clear(self._qigongList)
    self._qigongList = qigongData
    self:UpdatePlayerInfo()
    self:UpdateSkillList()
    self:OnClickSkillIcon()
end

-- 左边 气功列表
function SkillPracticePanel:UpdateSkillList()
    table.clear(self._qigongCell)
	FGUI:GList_setSelectedIndex(self._ui.list_qigong, -1)
    FGUI:GList_setNumItems(self._ui.list_qigong, #self._qigongList)
end

function SkillPracticePanel:OnListItemRenderer(idx, item)
    local index = idx + 1
    local data = self._qigongList[index] 
    if not data then 
        return 
    end

    self._qigongCell[data.ID] = item

    local ui_icon = FGUI:GetChild(item, "skill_icon")
    local path = SL:GetValue("SKILL_QIGONG_SQUARE_ICON_BY_ID", data.ID)
    FGUI:GLoader_setUrl(ui_icon, path, nil, true)  

    local ui_name = FGUI:GetChild(item, "text_name")
    FGUI:GTextField_setText(ui_name, data.Name)

    local ui_lv = FGUI:GetChild(item, "text_needLv")
    local qigongData = SL:GetValue("SKILL_QIGONG_BY_ID", data.ID)

    if qigongData.LevelEx > 0 or qigongData.EquipLevel > 0 then 
        if self._showExtraLv then 
            FGUI:GRichTextField_setText(ui_lv, string.format(GET_STRING(60012013), qigongData.CurLv, qigongData.LevelEx + qigongData.EquipLevel))
        else 
            local totalLv = qigongData.CurLv + qigongData.LevelEx + qigongData.EquipLevel
            FGUI:GRichTextField_setText(ui_lv, string.format(GET_STRING(60012015), totalLv))
        end 
    else
        if qigongData.CurLv == 0 then 
            -- 是否可以激活
            local checkOk = self:CheckQiGongOk(data.ID) 
            if checkOk then 
                FGUI:GRichTextField_setText(ui_lv, GET_STRING(60012027))
            else 
                FGUI:GRichTextField_setText(ui_lv, GET_STRING(60012026))
            end 
        else 
            FGUI:GRichTextField_setText(ui_lv, string.format(GET_STRING(60012015), qigongData.CurLv))
        end 
    end 

    -- 等级不够
    local ui_mask = FGUI:GetChild(item, "skill_mask")
    local isShow = self:CheckQiGongLevel(data.ID)
    FGUI:setVisible(ui_mask, not isShow)
end

function SkillPracticePanel:OnClickSkillIcon(context)
    local idx = 0
    if context then 
        idx = FGUI:GetChildIndex(self._ui.list_qigong, context.data)
    end 
    FGUI:GList_setSelectedIndex(self._ui.list_qigong, idx)
    local index = idx + 1
    local data = self._qigongList[index]
    if not data then  
        return 
    end 

    self._selQiGong = SL:GetValue("SKILL_QIGONG_BY_ID", data.ID)
    self:UpdateSkillDetails()
end

function SkillPracticePanel:CleanSkillDetails()
    FGUI:GTextField_setText(self._ui.text_skillName, "")
    FGUI:GTextField_setText(self._ui.text_level, "")
    FGUI:GTextField_setText(self._ui.text_score, "")
    FGUI:setVisible(self._ui.btn_study, false)
    FGUI:setVisible(self._ui.btn_cz, false)
end

function SkillPracticePanel:UpdateSkillDetails()
    if not self._selQiGong then 
        return
    end 

    local qigongID = self._selQiGong.ID
    local qigongUpMax = self._selQiGong.Lv
    local qigongConfigMax = self._selQiGong.MaxLv
    local curLevel = self._selQiGong.CurLv or 0     -- 气功等级
    local scriptLv = self._selQiGong.LevelEx or 0   -- 脚本等级
    local equipLv = self._selQiGong.EquipLevel or 0 -- 装备等级
    local realLevel = curLevel + scriptLv + equipLv
    local nextLevel = curLevel + 1
    local realNextLevel = nextLevel + scriptLv + equipLv

    FGUI:GButton_setTitle(self._ui.btn_study, realLevel == 0 and GET_STRING(60012020) or GET_STRING(60012021))

    -- cur
    local curData = SL:GetValue("SKILL_QIGONG_CONFIG_BY_ID_AND_LEVEL", qigongID, realLevel)
    if not curData then 
        self:CleanSkillDetails(false)
        return 
    end 

    FGUI:GTextField_setText(self._ui.text_skillName, curData and curData.Name or "")

    -- desc 
    FGUI:GRichTextField_setText(self._ui.rich_desc, curData and curData.Desc or "")

    -- icon
    local ui_icon = FGUI:GetChild(self._ui.icon_select, "skill_icon")
    local path = SL:GetValue("SKILL_QIGONG_SQUARE_ICON_BY_ID", qigongID)
    FGUI:GLoader_setUrl(ui_icon, path, nil, true)  

    local ui_mask = FGUI:GetChild(self._ui.icon_select, "skill_mask2")
    FGUI:setVisible(ui_mask, false)


    local ui_name = FGUI:GetChild(self._ui.icon_select, "text_name")
    FGUI:GTextField_setText(ui_name, curData.Name)

    -- cur desc
    local tDescList = {}
    local tDesc1 = string.split(curData.DescShow, "|")
    if tDesc1 then 
        for i = 1, #tDesc1 do 
            local cellDesc = string.split(tDesc1[i], "#")  
            tDescList[i] = {}
            tDescList[i].name = cellDesc[1]
            tDescList[i].value1 = cellDesc[2]
            tDescList[i].value2 = ""
        end 
    end 

    -- next desc
    local nextData = SL:GetValue("SKILL_QIGONG_CONFIG_BY_ID_AND_LEVEL", qigongID, realNextLevel)
    if nextData then      
        local tDesc2 = string.split(nextData.DescShow, "|")
        if tDesc2 then 
            for i = 1, #tDesc2 do 
                local cellDesc = string.split(tDesc2[i], "#")
                if tDescList[i] and next(tDescList) then
                    tDescList[i].value2 = cellDesc[2]
                end
            end 
        end 
    else 
        if tDesc1 then 
            for i = 1, #tDesc1 do 
                if tDescList[i] then 
                    tDescList[i].value2 = GET_STRING(60012014)
                end
            end 
        end 
    end 

    -- showDesc 
	FGUI:GList_itemRenderer(self._ui.list_desc, function(idx, item)
        local index = idx + 1
        local data = tDescList[index]
        if not data then 
            return 
        end 

        local rich_name = FGUI:GetChild(item, "rich_name")
        local rich_cur = FGUI:GetChild(item, "rich_cur")
        local rich_next = FGUI:GetChild(item, "rich_next") 
        FGUI:GRichTextField_setText(rich_name, data.name..":")
        FGUI:GRichTextField_setText(rich_cur, data.value1)
        FGUI:GRichTextField_setText(rich_next, data.value2)
    end)
    FGUI:GList_setNumItems(self._ui.list_desc, #tDescList)

    if nextLevel > qigongUpMax then 
        self:SetCostInfoVisible(false)
        return 
    else 
        self:SetCostInfoVisible(true)
    end 

    -- cost
    local isLevelUp = self:CheckQiGongLevel(qigongID)
    if not isLevelUp then 
        FGUI:GRichTextField_setText(self._ui.text_score, "")
        FGUI:GRichTextField_setText(self._ui.text_level, string.format(GET_STRING(60012009), curData.LevelRequire))
        FGUI:setVisible(self._ui.btn_study, false)
        FGUI:setVisible(self._ui.btn_cz, false)
        return 
    end 

    local data = {}
    local sp = string.split(curData.Cost, "#")
    data.id = tonumber(sp[1])
    data.count = tonumber(sp[2])
    local itemName = SL:GetValue("ITEM_NAME", data.id)
    local myCount = SL:GetValue("ITEM_COUNT", data.id)
    local needCount = data.count   
    local color2 = myCount >= needCount and "#00FF00" or "#FF0000"
    FGUI:GRichTextField_setText(self._ui.text_score, string.format(GET_STRING(60012010),itemName, color2, myCount, needCount))
    FGUI:GTextField_setText(self._ui.text_level, "")
    FGUI:setVisible(self._ui.btn_study, true)
    FGUI:setVisible(self._ui.btn_cz, true)
end

function SkillPracticePanel:UpdatePlayerInfo()
    local itemID = 19
    local itemName = SL:GetValue("ITEM_NAME", itemID)
    local itemCount = SL:GetValue("ITEM_COUNT", itemID)
    local color = itemCount == 0 and "#FF0000" or "#00FF00"
    FGUI:GTextField_setText(self._ui.text_myScore, string.format(GET_STRING(60012016), itemName, color, itemCount))
end

-- 升级
function SkillPracticePanel:OnClickStudy(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
    if not self._selQiGong then 
        return 
    end 

    local isLevelUp = self:CheckQiGongOk(self._selQiGong.ID, true)
    if not isLevelUp then 
        return 
    end 

    SL:RequestQiGongLevelUp(self._selQiGong.ID)
end

-- 重置
function SkillPracticePanel:OnClickReSet(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
    if not self._selQiGong then 
        return 
    end 

    SL:RequestQiGongReset(self._selQiGong.ID)
end

-- 重置全部
function SkillPracticePanel:OnClickReSetAll(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
    SL:RequestQiGongReset()
end

-- 显示额外气功等级
function SkillPracticePanel:OnClickShowExtraLevel(context)
    self._showExtraLv = FGUI:GButton_getSelected(context.sender)
    FGUI:GList_setNumItems(self._ui.list_qigong, #self._qigongList)
end

function SkillPracticePanel:SetCostInfoVisible(isShow)
    FGUI:setVisible(self._ui.text_level, isShow)
    FGUI:setVisible(self._ui.text_score, isShow)
    FGUI:setVisible(self._ui.btn_study, isShow)
    FGUI:setVisible(self._ui.btn_cz, true)

    local scoreX = FGUI:getPositionX(self._ui.text_score)
    local posX = isShow and scoreX - 100 or scoreX
    FGUI:setPositionX(self._ui.btn_cz, posX)
end

function SkillPracticePanel:CheckQiGongLevel(skillID, showTips)
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

function SkillPracticePanel:CheckQiGongOk(skillID, showTips)
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

-- 引导返回节点
function SkillPracticePanel:GetSkillGuideIcon(qigongParam)
    local param = string.split(qigongParam, "#")
    local group = tonumber(param[1])
    if not group or group ~= 2 then 
        return 
    end 

    local qigongID = tonumber(param[2])
    if not qigongID then 
        return 
    end 

    local page = tonumber(param[3])
    if not page then 
        return 
    end 

    if self._qigongCell[qigongID] then     
        return self._qigongCell[qigongID]
    end 
end

---气功方案
function SkillPracticePanel:InitQiGongSchemes()
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

    -- 方案是否显示主界面
    local isShow = SL:GetValue("SETTING_MAIN_SKILL_SCHEME_SHOW")
    FGUI:GButton_setSelected(self._ui.check_main, isShow)

    self:SetInputing(1)
end

function SkillPracticePanel:SchemeListRenderer(idx, item)
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
        if self._selScheme == idx then 
            FGUI:GTextField_setText(self._ui.text_scheme, inputName)
        end 
    end)

    -- btn select
	FGUI:setOnClickEvent(ui_select, function()
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

function SkillPracticePanel:OnClickBtnScheme()
    if not self:CheckInputing() then 
        return
    end 

    self:ShowSchemeUI()
    FGUI:GList_setNumItems(self._ui.list_scheme, #self._schemeNames)
end

function SkillPracticePanel:OnClickSchemeMask()
    if not self:CheckInputing() then 
        return
    end 

    self:HideSchemeUI()
end

function SkillPracticePanel:OnClickSchemeShowMain(context)
    local isShow = FGUI:GButton_getSelected(context.sender)
    SL:SetValue("SETTING_MAIN_SKILL_SCHEME_SHOW", isShow)
end

function SkillPracticePanel:ShowSchemeUI()
    FGUI:setVisible(self._ui.list_scheme, not FGUI:getVisible(self._ui.list_scheme))
    FGUI:setVisible(self._ui.mask, FGUI:getVisible(self._ui.list_scheme))
end

function SkillPracticePanel:HideSchemeUI()
    FGUI:setVisible(self._ui.list_scheme, false)
    FGUI:setVisible(self._ui.mask, false)
end

function SkillPracticePanel:RefreshSchemeItemTouchState(item)
	local input_name = FGUI:GetChild(item, "input_title")
	local ui_select = FGUI:GetChild(item, "select")
    FGUI:setTouchEnabled(input_name, self._inputState == 0)
    FGUI:setTouchEnabled(ui_select, self._inputState ~= 0)
end 

function SkillPracticePanel:SetInputing(state)
    self._inputState = state
end

function SkillPracticePanel:CheckInputing()
    if self._inputState == 0 then 
        SL:ShowSystemTips(GET_STRING(60012029))
        return false
    end 

    return true
end

function SkillPracticePanel:OnQiGongLevelUp(skillID)
    self._selQiGong = SL:GetValue("SKILL_QIGONG_BY_ID", skillID)
    FGUI:GList_setNumItems(self._ui.list_qigong, #self._qigongList)
    self:UpdateSkillDetails()
    self:UpdatePlayerInfo()
end 

-- 事件 增加方案
function SkillPracticePanel:OnQiGongSchemeAdd(idx)
    local schemeName = SL:GetValue("GET_QIONG_SCHEME_NAME",idx)
    local index = idx + 1
    self._schemeNames[index] = schemeName
    table.insert(self._schemeNames, "")

    FGUI:GList_setNumItems(self._ui.list_scheme, #self._schemeNames)
    FGUI:setHeight(self._ui.list_scheme, #self._schemeNames * 40)
end

-- 事件 改变方案
function SkillPracticePanel:OnQiGongSchemeChange(idx)
    local schemeName = SL:GetValue("GET_QIONG_SCHEME_NAME",idx)
    FGUI:GTextField_setText(self._ui.text_scheme, schemeName) 
    self._selScheme = idx

    self:SelectPage(1)
end

-----------------------------------注册事件--------------------------------------
function SkillPracticePanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_LEVELUP, "SkillPracticePanel", handler(self, self.OnQiGongLevelUp))
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_SCHEME_ADD, "SkillPracticePanel", handler(self, self.OnQiGongSchemeAdd))
    SL:RegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_SCHEME_CHANGE, "SkillPracticePanel", handler(self, self.OnQiGongSchemeChange))
end

function SkillPracticePanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_LEVELUP, "SkillPracticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_SCHEME_ADD, "SkillPracticePanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_SKILL_QIGONG_SCHEME_CHANGE, "SkillPracticePanel")
end

return SkillPracticePanel