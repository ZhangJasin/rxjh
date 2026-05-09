-- 坐骑/灵兽主界面
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local mountMain = class("mountMain", BaseFGUILayout)

-- 导入配置表
local AttScoreNames = require("game_config/AttScore")

-- 导入工具类
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")

local Mount = require("game_config/cfgcsv/Mount")
local MountHuanhua = require("game_config/cfgcsv/MountHuanhua")
local Pet = require("game_config/cfgcsv/Pet")
local PetHuanhua = require("game_config/cfgcsv/PetHuanhua")
local mountMainData = SL:RequireFile("FGUILayout/Mount/mountMainData")

-- 灵兽属性转化比例配置表
local PetLevelRateConfig = {
    { 1,  10, 0.03 }, { 11, 20, 0.04 }, { 21, 30, 0.05 }, { 31, 40, 0.06 },
    { 41, 50, 0.08 }, { 51, 60, 0.10 }, { 61, 70, 0.12 }, { 71, 80, 0.15 },
    { 81, 90, 0.18 }, { 91, 100, 0.21 }, { 101, 110, 0.25 },
}

local function getPetAttrRateByLevel(level)
    for _, config in ipairs(PetLevelRateConfig) do
        if level >= config[1] and level <= config[2] then return config[3] end
    end
    return PetLevelRateConfig[1][3]
end

-- 点击冷却表
local _clickCooldown = { petQhbtn = 0, qhbtn = 0, huanhua = 0, petHuanhua = 0 }
local _CLICK_INTERVAL = 500

local function checkCooldown(btnName)
    local now = os.time() * 1000
    if now - _clickCooldown[btnName] < _CLICK_INTERVAL then
        SL:ShowSystemTips("请勿操作频繁")
        return false
    end
    _clickCooldown[btnName] = now
    return true
end

local function getTipsFromConfig(config)
    if not config then return "" end
    for _, v in pairs(config) do
        if v.tips and v.tips ~= "" then return v.tips end
    end
    return ""
end

Mount.Tips = getTipsFromConfig(Mount)
MountHuanhua.Tips = getTipsFromConfig(MountHuanhua)
Pet.Tips = getTipsFromConfig(Pet)
PetHuanhua.Tips = getTipsFromConfig(PetHuanhua)

local NUMBER_TO_CHINESE = { "零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十" }

local TAB_TYPE = { MOUNT = 0, MOUNT_HH = 1 }
local STATUS = { FIGHT = 0, REST = 1 }

local PercentAttrConfig = {
    [68] = true,
    [67] = true,
    [107] = true,
    [57] = true,
    [104] = true,
    [105] = true,
    [99] = true,
    [100] = true,
    [103] = true,
    [9] = true
}

local function parseClassID(classIdConfig)
    local result = {}
    if classIdConfig then
        for i = 1, #classIdConfig do
            table.insert(result, { tonumber(classIdConfig[i][1]), tonumber(classIdConfig[i][2]) })
        end
    end
    return result
end

-- ================= 模型旋转通用工具 =================
local function BindModelRotation(touchTarget, modelBody, modelIndex)
    local angleY = 0
    local beginX = nil
    FGUI:setOnTouchEvent(touchTarget,
        function(context)
            beginX = context.inputEvent.x
            _, angleY, _ = modelBody:GetObjectEulerAngles(modelIndex)
            FGUI:EventContext_CaptureTouch(context)
        end,
        function(context)
            if not beginX then return end
            local distence = context.inputEvent.x - beginX
            local angle = angleY - (distence * 360 / 1000)
            modelBody:SetObjectEulerAngles(0, angle, 0, modelIndex)
        end,
        function(context) beginX = nil end
    )
end

-- ================= 生命周期 =================
function mountMain:Create()
    mountMainData:Init()
    self._ui = FGUI:ui_delegate(self.component)
    self:initVariables()
    FGUI:setOnClickEvent(self._ui.closeBtn, function() FGUI:Close("Mount", "mountMain") end)
    self._subscriptions = {}
    self:subscribeEvents()
    self:initTabsAndLists()
    self:bindEvents()
end

function mountMain:Destroy()
    if self._subscriptions then
        for _, token in pairs(self._subscriptions) do
            if self._data and self._data.Unsubscribe then self._data:Unsubscribe(token) end
        end
        self._subscriptions = nil
    end
    self._data = nil
    self._ui = nil
end

function mountMain:initVariables()
    self.topTabList = FGUI:ui_delegate(self._ui.topTabList)
    self.rightTabList = FGUI:ui_delegate(self._ui.rightTabList)
    self.leftList = self._ui.leftList
    self.mountBody = FGUI:UIModel_Bind(self._ui.mountBody)
    self.uiTouch = FGUI:GetChild(self.component, "mountModel")

    self.jieshuName = FGUI:ui_delegate(self._ui.jieshu)
    self.currentMountAttr = FGUI:ui_delegate(self._ui.nowAttr)
    self.nextMountAttr = FGUI:ui_delegate(self._ui.nextAttr)
    self.huanhuaAttr = FGUI:ui_delegate(self._ui.huanhuaAttr)

    self.petTopTabList = FGUI:ui_delegate(self._ui.petTopTabList)
    self.petBody = FGUI:UIModel_Bind(self._ui.petBody)
    self.petUiTouch = FGUI:GetChild(self.component, "petModel")

    self.petJieshuName = FGUI:ui_delegate(self._ui.petJieshu)
    self.currentPetAttr = FGUI:ui_delegate(self._ui.petNowAttr)
    self.nextPetAttr = FGUI:ui_delegate(self._ui.petNextAttr)
    self.petHuanhuaAttr = FGUI:ui_delegate(self._ui.petHuanhuaAttr)

    self.nowPetHHIndex = 0
    self.tipsControlle = FGUI:getController(self.component, "tips")

    -- PC端适配
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    if isPC then
        FGUI:setScale(self.component, 0.75, 0.75)
        FGUI:setPosition(self.component, screenW / 2, screenH / 2)
        FGUI:setAnchorPoint(self.component, 0.5, 0.5, true)
        local listX, listY = FGUI:getPosition(self._ui.rightTabList)
        local listW, _ = FGUI:getSize(self._ui.rightTabList)
        local scaledRightEdge = (listX + listW) * 0.75
        if scaledRightEdge > screenW then
            FGUI:setPosition(self._ui.rightTabList, listX - (scaledRightEdge - screenW) - 10, listY)
        end
    end
end

-- ================= 数据同步与事件订阅 =================
function mountMain:subscribeEvents()
    self._data = mountMainData.Get()
    if not self._data.Subscribe then return end

    self._subscriptions.lsListUpdate = self._data:Subscribe("ls_list_update", function(state)
        self._dataForPet = state._dataForPet
        self.selectPetIndex = state.selectPetIndex
        self:setPetInfo()
        self:setPetAtta()
        self:setPetBtPetBtn()
        self:updateCostUI(true)
        self:updateHuanhuaIconAndLevel(true)
        self:refreshPetModel()
    end)

    self._subscriptions.lsLevelResult = self._data:Subscribe("ls_level_result", function(state)
        self._dataForPet = state
        self:setPetInfo()
        self:setPetAtta()
        self:setPetBtPetBtn()
        self:updateCostUI(true)
        self:refreshPetModel()
    end)

    self._subscriptions.lsUpdateModel = self._data:Subscribe("ls_update_model", function(state)
        self._dataForPet = state
        self:updatePetView()
        self:refreshPetModel()
    end)

    self._subscriptions.lsUnrecallpet = self._data:Subscribe("ls_unrecallpet", function(state)
        self._dataForPet = state
        self:setPetBtPetBtn()
    end)

    self._subscriptions.updateHHResult = self._data:Subscribe("updateHHResult", function(state)
        self._dataForMount = state._dataForMount
        local listSize = #self._dataForMount.hhSortList
        self.nowIndex = math.max(0, math.min((state.selectHHIndex or 1) - 1, listSize - 1))
        FGUI:GList_setSelectedIndex(self._ui.leftList, self.nowIndex)
        FGUI:GList_setNumItems(self._ui.leftList, listSize)

        self:updateHuanhuaAttrView(false)
        self:updateCostUI(false)
        self:updateHuanhuaBtnState(false)
        self:updateModel()
        self:updateHuanhuaActionBtnText(false)
        self:updateHuanhuaIconAndLevel(false)
    end)

    self._subscriptions.mountLevelUp = self._data:Subscribe("mountLevelUp", function(state)
        self._dataForMount = state
        self:initMountData()
        self:updateView()
        self:updateCostUI(false)
    end)

    self._subscriptions.mountUpdateBtn = self._data:Subscribe("mountUpdateBtn", function(state)
        self._dataForMount = state
        local titleNode = FGUI:GetChild(self._ui.qhbtn, "title")
        FGUI:GTextField_setText(titleNode, self._dataForMount.ischuzhan == STATUS.FIGHT and "出战" or "休息")
    end)

    self._subscriptions.petLevelUp = self._data:Subscribe("petLevelUp", function(state)
        self._dataForPet = state
        self:InitPetData()
        self:setPetBtPetBtn()
        self:UpdatePetAttrRate()
    end)

    self._subscriptions.petUpdateHHResult = self._data:Subscribe("petUpdateHHResult", function(state)
        self._dataForPet = state._dataForPet
        self.nowPetHHIndex = math.max(0, (state.selectHHIndex or 1) - 1)
        FGUI:GList_setSelectedIndex(self._ui.petLeftList, self.nowPetHHIndex)
        self:setupListRender(true)
        self:updateHuanhuaAttrView(true)
        self:updateCostUI(true)
        self:updateHuanhuaBtnState(true)
        self:updateHuanhuaActionBtnText(true)
        self:updateHuanhuaIconAndLevel(true)
        self:UpdatePetAttrRate()
    end)

    self._subscriptions.petUpdateModelResult = self._data:Subscribe("updatePetModelResult", function(state)
        self._dataForPet.showPetModelId = state.showPetModelId
        self._dataForPet.petHHid = state.petHHid
        self._dataForPet.hhSortList = self._data:setPetHHListSort()
        FGUI:GList_setNumItems(self._ui.petLeftList, #self._dataForPet.hhSortList)

        self:updateHuanhuaAttrView(true)
        self:updateCostUI(true)
        self:updateHuanhuaBtnState(true)
        self:setPetModel(state.showPetModelId, 0, 1.1)
        self:updateHuanhuaActionBtnText(true)
    end)

    self._subscriptions.petUpdateBtn = self._data:Subscribe("petUpdateBtn", function(state)
        if state.isPetChuzhan ~= nil then self._dataForPet.isPetChuzhan = state.isPetChuzhan end
        if state.isPetJh ~= nil then self._dataForPet.isPetJh = state.isPetJh end
        if state.allJieshu ~= nil then self._dataForPet.allJieshu = state.allJieshu end

        local titleNode = FGUI:GetChild(self._ui.petQhbtn, "title")
        if titleNode then
            FGUI:GTextField_setText(titleNode, self._dataForPet.isPetChuzhan == 1 and "召回" or "出战")
        end
    end)

    self:initDisplayData()
end

function mountMain:initDisplayData()
    self._dataForMount = self._data:GetDataForMount()
    self._dataForPet = self._data:GetDataForPet()
    self.topTab = TAB_TYPE.MOUNT
    self.petTopTab = 0
    self.nowPetHHIndex = 0
    self.selectPetIndex = 1

    self:initMountData()
    if self._dataForMount.isJh == 0 then
        self.modelId = Mount[0] and Mount[0].Model or 800001
        self:updateModel()
        self:updateCostUI(false)
        self:updateBaseAttrView(false)
    end

    self:setPetInfo()
    self:setPetAtta()
    self:setPetBtPetBtn()
    self:updateCostUI(true)
    self:initPetTab()
end

function mountMain:Enter(data)
    if data and data.type then
        self.rightTabs = FGUI:getController(self.component, "rightTabs")
        FGUI:Controller_setSelectedIndex(self.rightTabs, tonumber(data.type))
        if data.type == 0 then
            for w = 1, #self._dataForPet.allPets do
                if self._dataForPet.allPets[w].ID == self._dataForPet.selectViewPetId then
                    self.selectPetIndex = w
                end
            end
            self:setPetInfo()
            self:setPetAtta()
            self:setPetBtPetBtn()
            self:updateCostUI(true)
        else
            FGUI:Controller_setSelectedIndex(self.rightTabs, 1)
            if data.name then
                self.topTabs = FGUI:getController(self.component, "topTabs")
                FGUI:Controller_setSelectedIndex(self.topTabs, 1)
                self.topTab = TAB_TYPE.MOUNT_HH

                for i = 1, #self._dataForMount.hhSortList do
                    if self._dataForMount.hhSortList[i].Name == data.name then self.nowIndex = i - 1 end
                end
                self.nowIndex = math.max(0, self.nowIndex)
                self:initHuanhuaTabCommon(false)
            else
                self.topTabs = FGUI:getController(self.component, "topTabs")
                FGUI:Controller_setSelectedIndex(self.topTabs, 0)
                self.topTab = TAB_TYPE.MOUNT
                self:initMountTab()
                self:updateCostUI(false)
            end
        end
        FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.MountGuide, self._ui)
    end
end

function mountMain:Exit()
    FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.MountGuide)
end

-- ================= UI 初始化绑定 =================
function mountMain:initTabsAndLists()
    FGUI:GList_setSelectedIndex(self._ui.topTabList, TAB_TYPE.MOUNT)
    FGUI:GList_setSelectedIndex(self._ui.rightTabList, 0)
    FGUI:GList_setSelectedIndex(self._ui.leftList, 0)
    FGUI:GList_setSelectedIndex(self._ui.petTopTabList, 0)
    FGUI:GList_setSelectedIndex(self._ui.petLeftList, 0)
end

function mountMain:bindEvents()
    FGUI:GList_addOnClickItemEvent(self._ui.topTabList, function()
        if self._dataForMount.allJieshu == 0 then
            SL:ShowSystemTips("请先激活坐骑")
            FGUI:GList_setSelectedIndex(self._ui.topTabList, 0)
        else
            self.topTab = FGUI:GList_getSelectedIndex(self._ui.topTabList)
            self:InitData()
        end
    end)

    FGUI:GList_addOnClickItemEvent(self._ui.rightTabList, function()
        local index = FGUI:GList_getSelectedIndex(self._ui.rightTabList)
        if index == 0 then
            self.petTopTab = 0
            FGUI:GList_setSelectedIndex(self._ui.petTopTabList, 0)
            self:InitPetData()
        else
            self.topTab = TAB_TYPE.MOUNT
            FGUI:GList_setSelectedIndex(self._ui.topTabList, TAB_TYPE.MOUNT)
            self:InitData()
        end
    end)

    FGUI:setOnClickEvent(self._ui.qhbtn, function()
        if checkCooldown("qhbtn") then self._data:chuzhan() end
    end)

    FGUI:setOnClickEvent(self._ui.shengjizuoqi, function() self._data:shengji() end)

    FGUI:GList_addOnClickItemEvent(self._ui.petTopTabList, function()
        local index = FGUI:GList_getSelectedIndex(self._ui.petTopTabList)
        if self._dataForPet.isPetJh == 0 and index == 1 then
            SL:ShowSystemTips("请先激活灵兽")
            FGUI:GList_setSelectedIndex(self._ui.petTopTabList, 0)
        else
            self.petTopTab = index
            self:InitPetData()
        end
    end)

    FGUI:setOnClickEvent(self._ui.petQhbtn, function()
        if checkCooldown("petQhbtn") then self._data:petChuzhan() end
    end)

    FGUI:setOnClickEvent(self._ui.shengjilingshou, function()
        if self.petTopTab == 0 then
            if self._dataForPet.isPetJh == 0 then
                if Pet[1] and Pet[1].Cost then
                    local costs = Pet[1].Cost
                    self._data:lsjihuo(type(costs[1]) == "table" and { costs = costs } or { itemId = costs[1] })
                end
            else
                local nextLevel = self._dataForPet.allJieshu + 1
                if Pet[nextLevel] and Pet[nextLevel].Cost then
                    local costs = Pet[nextLevel].Cost
                    local sendData = { name = Pet[nextLevel].Name or "灵兽", maxLv = #Pet }
                    if type(costs[1]) == "table" then
                        sendData.costs = costs
                    else
                        sendData.num, sendData.itemId = costs[2] or 1, costs[1] or 0
                    end
                    self._data:levelUp(sendData)
                end
            end
        else
            self:onHuanhuaTodo(true)
        end
    end)

    -- Tips 统一绑定
    local tipsbg = FGUI:ui_delegate(self._ui.n114)
    local function BindTipsEvent(btn, title, content)
        FGUI:setOnClickEvent(btn, function()
            local tipinfoScro = FGUI:ui_delegate(tipsbg.infoScro)
            FGUI:GTextField_setText(tipsbg.title, title)
            FGUI:GRichTextField_setText(tipinfoScro['n3'], content)
            FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
            FGUI:Controller_setSelectedIndex(self.tipsControlle, 1)

            local closeFunc = function() FGUI:Controller_setSelectedIndex(self.tipsControlle, 0) end
            FGUI:setOnClickEvent(tipsbg.closetips, closeFunc)
            FGUI:setOnClickEvent(tipsbg.bg, closeFunc)
        end)
    end
    BindTipsEvent(self._ui.n110, "灵兽页面功能说明", Pet.Tips)
    BindTipsEvent(self._ui.n111, "灵兽幻化功能说明", PetHuanhua.Tips)
    BindTipsEvent(self._ui.n112, "坐骑页面功能说明", Mount.Tips)
    BindTipsEvent(self._ui.n113, "坐骑幻化功能说明", MountHuanhua.Tips)
end

-- ================= UI 基础渲染封装 (DRY) =================

function mountMain:setup3DModel(modelBody, modelId, offsetY, scale, touchArea)
    FGUI:UIModel_clear(modelBody)
    local modelIndex = FGUI:UIModel_addLegoModel(
        modelBody, modelId, { x = 0, y = offsetY or 0, z = 0 }, { x = 0, y = 180, z = 0 }, {
            x = scale,
            y = scale,
            z =
                scale
        }, false
    )
    FGUI:UIModel_setObjectEulerAngles(modelBody, 0, 0, 0, 0)
    FGUI:UIModel_setModelCallback(modelBody, function() BindModelRotation(touchArea, modelBody, modelIndex) end)
    return modelIndex
end

function mountMain:renderStars(container, totalStars)
    local jieshu = math.floor(totalStars / 10)
    local liang = totalStars % 10
    if liang == 0 and jieshu > 0 then liang, jieshu = 10, jieshu - 1 end
    for i = 0, 9 do
        local item = FGUI:GetChildAt(container, i)
        if item then FGUI:Controller_setSelectedIndex(FGUI:getController(item, "checked"), i <= liang - 1 and 1 or 0) end
    end
    return jieshu
end

function mountMain:renderAttributeList(list, attributes)
    FGUI:GList_itemRenderer(list, function(index, item)
        local attrId, attrValue = attributes[index + 1][1], attributes[index + 1][2]
        FGUI:Controller_setSelectedIndex(FGUI:getController(item, 'isDouble'), index % 2 == 0 and 0 or 1)

        local valueText = PercentAttrConfig[attrId] and (math.floor(attrValue / 100) .. "%") or attrValue
        FGUI:GTextField_setText(FGUI:GetChild(item, "label"), AttScoreNames[attrId].Name .. ":")
        FGUI:GTextField_setText(FGUI:GetChild(item, "zhi"), valueText)
    end)
    FGUI:GList_setNumItems(list, #attributes)
end

-- 统一渲染消耗材料界面
function mountMain:renderCosts(costs, container, textNode, defaultPosData)
    if not costs or not next(costs) then
        FGUI:setVisible(textNode, false)
        FGUI:setVisible(container, false)
        return
    end

    FGUI:setVisible(textNode, true)
    FGUI:setVisible(container, true)

    local iconItem = FGUI:GetChild(container, "iconItem")
    local iconItem2 = FGUI:GetChild(container, "iconItem2")
    if FGUI:GetChildCount(iconItem) > 0 then FGUI:RemoveChildAt(iconItem, 0, true) end
    if iconItem2 and FGUI:GetChildCount(iconItem2) > 0 then FGUI:RemoveChildAt(iconItem2, 0, true) end

    if defaultPosData then
        FGUI:setPosition(container, defaultPosData.containerPos[1], defaultPosData.containerPos[2])
        FGUI:setPosition(textNode, defaultPosData.textPos[1], defaultPosData.textPos[2])
    end

    local function setupSingle(cfg, iconNode, numName, symName)
        local itemId, needNum = tonumber(cfg[1]), tonumber(cfg[2])
        local itemData = SL:GetValue("ITEM_DATA", itemId)
        if iconNode then
            ItemUtil:ItemShow_Create(itemData, iconNode, { hideTip = false, itemTipData = itemData, bgVisible = true })
            FGUI:setVisible(iconNode, true)
        end
        local numNode, symNode = FGUI:GetChild(container, numName), FGUI:GetChild(container, symName)
        if numNode then
            local haveNum = SL:GetValue(TITEMCOUNT, itemId)
            FGUI:GTextField_setText(numNode, needNum)
            local color = haveNum >= needNum and "#00f900" or "#ff0000"
            FGUI:GTextField_setColor(numNode, color)
            if symNode then FGUI:GTextField_setColor(symNode, color) end
            FGUI:setVisible(numNode, true)
            if symNode then FGUI:setVisible(symNode, true) end
        end
    end

    if type(costs[1]) == "table" then
        setupSingle(costs[1], iconItem, "n2", "n1")
        if #costs >= 2 and iconItem2 then setupSingle(costs[2], iconItem2, "n4", "n3") end
    else
        if iconItem2 then FGUI:setVisible(iconItem2, false) end
        local num2, sym2 = FGUI:GetChild(container, "n4"), FGUI:GetChild(container, "n3")
        if num2 then FGUI:setVisible(num2, false) end
        if sym2 then FGUI:setVisible(sym2, false) end

        setupSingle({ costs[1], costs[2] }, iconItem, "n2", "n1")

        if defaultPosData then
            FGUI:setPosition(container, defaultPosData.containerPos[1] + 50, defaultPosData.containerPos[2])
            FGUI:setPosition(textNode, defaultPosData.textPos[1] + 50, defaultPosData.textPos[2])
        end
    end
end

-- ================= 核心业务逻辑合并 =================

function mountMain:InitData()
    if self.topTab == TAB_TYPE.MOUNT then self:initMountTab() else self:initHuanhuaTabCommon(false) end
    self:updateCostUI(false)
end

function mountMain:InitPetData()
    if self.petTopTab == 0 then self:initPetTab() else self:initHuanhuaTabCommon(true) end
    self:updateCostUI(true)
end

function mountMain:updateMainTitle(isPet)
    local dataObj = isPet and self._dataForPet or self._dataForMount
    local configTab = isPet and self.petTopTab or self.topTab
    local configBase = isPet and Pet or Mount
    local nameNode = isPet and self._ui.petName or self._ui.mountName
    local nowIndex = isPet and self.nowPetHHIndex or self.nowIndex

    local nowName = isPet and "龙猫" or "乌龙驹"
    if dataObj.allJieshu > 0 and configBase[dataObj.allJieshu] then nowName = configBase[dataObj.allJieshu].Name end

    if configTab == 1 then
        if dataObj.hhSortList and #dataObj.hhSortList > 0 then
            local idx = nowIndex + 1
            if idx >= 1 and idx <= #dataObj.hhSortList then nowName = dataObj.hhSortList[idx].Name end
        else
            nowName = "暂无幻化"
        end
    end
    FGUI:GTextField_setText(nameNode, nowName)
end

function mountMain:updateBaseAttrView(isPet)
    local dataObj = isPet and self._dataForPet or self._dataForMount
    local configList = isPet and Pet or Mount
    local curAttrUi = isPet and self.currentPetAttr or self.currentMountAttr
    local nextAttrUi = isPet and self.nextPetAttr or self.nextMountAttr

    local stars = dataObj.allJieshu
    local curClassIds = (stars > 0 and configList[stars]) and configList[stars].ClassID or {}
    local nextStars = math.min(stars + 1, #configList)
    if dataObj.isJh == 0 and not isPet then nextStars = 1 end

    self:renderAttributeList(curAttrUi["n15"], parseClassID(curClassIds))
    self:renderAttributeList(nextAttrUi["n15"],
        parseClassID(configList[nextStars] and configList[nextStars].ClassID or {}))
end

function mountMain:updateHuanhuaAttrView(isPet)
    local dataObj = isPet and self._dataForPet or self._dataForMount
    local configList = isPet and PetHuanhua or MountHuanhua
    
    -- 包装后的 Lua Table（用于获取子节点）
    local attrUi = isPet and self.petHuanhuaAttr or self.huanhuaAttr
    -- 原生的 C# 组件对象（用于获取 Controller）
    local rawAttrUi = isPet and self._ui.petHuanhuaAttr or self._ui.huanhuaAttr
    
    local nowIndex = isPet and self.nowPetHHIndex or self.nowIndex
    
    if not dataObj.hhSortList or #dataObj.hhSortList == 0 then return end
    
    local name = dataObj.hhSortList[nowIndex + 1].Name
    local sameConfigs = {}
    for i = 1, #configList do
        if configList[i].Name == name then table.insert(sameConfigs, configList[i]) end
    end
    
    local nowGrade = math.max(1, math.min(dataObj.hhlistsj[name] or 1, #sameConfigs))
    local cfg = sameConfigs[nowGrade]
    self.modelId = cfg.Model
    
    local rTabsVal = self.rightTabs and FGUI:Controller_getSelectedIndex(self.rightTabs) or (isPet and 0 or 1)
    
    -- 【修复点】使用原生的 rawAttrUi 来获取控制器，避免 XLua 报错
    local typeCtrl = FGUI:getController(rawAttrUi, "type")
    if typeCtrl then FGUI:Controller_setSelectedIndex(typeCtrl, rTabsVal) end
    
    -- 使用 delegate 表来获取子节点
    local buffNode = attrUi.buffText
    FGUI:GTextField_setAutoSize(buffNode, 2)
    FGUI:GTextField_setUBBEnabled(buffNode, true)
    FGUI:GTextField_setText(buffNode, cfg.BuffDesc and string.gsub(cfg.BuffDesc, "\\n", "\n") or "")
    
    if cfg.ClassID and #cfg.ClassID > 0 then
        FGUI:setPosition(buffNode, 15, (rTabsVal == 1 and 50 or 0) + 26 * #cfg.ClassID + 5)
        self:renderAttributeList(attrUi["sxlist"], cfg.ClassID)
    else
        FGUI:setPosition(buffNode, 15, 5)
        FGUI:GList_setNumItems(attrUi["sxlist"], 0)
    end
end

function mountMain:updateCostUI(isPet)
    local dataObj = isPet and self._dataForPet or self._dataForMount
    local configTab = isPet and self.petTopTab or self.topTab
    local configBase = isPet and Pet or Mount
    local configHH = isPet and PetHuanhua or MountHuanhua
    local container = isPet and self._ui.petXhcl or self._ui.xhcl
    local textNode = isPet and self._ui.n104 or self._ui.n34

    -- 缓存并提供默认位置
    if isPet then
        self._petXhclDefaultPos = self._petXhclDefaultPos or { FGUI:getPosition(container) }
        self._n104DefaultPos = self._n104DefaultPos or { FGUI:getPosition(textNode) }
    else
        self._xhclDefaultPos = self._xhclDefaultPos or { FGUI:getPosition(container) }
        self._n34DefaultPos = self._n34DefaultPos or { FGUI:getPosition(textNode) }
    end
    local posData = isPet and { containerPos = self._petXhclDefaultPos, textPos = self._n104DefaultPos } or
        { containerPos = self._xhclDefaultPos, textPos = self._n34DefaultPos }

    if configTab == 0 and dataObj.allJieshu == #configBase then
        FGUI:setVisible(container, false); FGUI:setVisible(textNode, false); return
    end

    local costs = nil
    if configTab == 0 then
        costs = configBase[dataObj.allJieshu] and configBase[dataObj.allJieshu].Cost
    else
        if not dataObj.hhSortList or #dataObj.hhSortList == 0 then
            FGUI:setVisible(container, false); FGUI:setVisible(textNode, false); return
        end
        local nowName = dataObj.hhSortList[(isPet and self.nowPetHHIndex or self.nowIndex) + 1].Name
        local grades = {}
        for i = 1, #configHH do if configHH[i].Name == nowName then table.insert(grades, configHH[i]) end end

        local nextGrade = (dataObj.hhlistsj[nowName] or 0) + 1
        if nextGrade > #grades then
            FGUI:setVisible(container, false); FGUI:setVisible(textNode, false); return
        end
        costs = grades[nextGrade].Cost
    end
    self:renderCosts(costs, container, textNode, posData)
end

function mountMain:setupListRender(isPet)
    local dataObj = isPet and self._dataForPet or self._dataForMount
    local listUi = isPet and self._ui.petLeftList or self._ui.leftList

    FGUI:GList_itemRenderer(listUi, function(idx, item)
        if not dataObj.hhSortList or #dataObj.hhSortList == 0 then return end
        local itemData = dataObj.hhSortList[idx + 1]

        FGUI:Controller_setSelectedIndex(FGUI:getController(item, "checked"),
            idx == (isPet and self.nowPetHHIndex or self.nowIndex) and 1 or 0)
        FGUI:Controller_setSelectedIndex(FGUI:getController(item, "isActivation"),
            (dataObj.hhlistsj[itemData.Name] or 0) > 0 and 1 or 0)
        FGUI:GLoader_setUrl(FGUI:GetChild(item, "avatar"), "ui://Mount/" .. itemData.mount_icon)

        FGUI:setOnClickEvent(item, function()
            if isPet then self.nowPetHHIndex = idx else self.nowIndex = idx end

            self.modelId = itemData.Model
            FGUI:GTextField_setText(isPet and self._ui.petName or self._ui.mountName, itemData.Name)
            self:updateHuanhuaAttrView(isPet)

            local items = FGUI:GetChildren(listUi)
            for i = 1, #items do
                FGUI:Controller_setSelectedIndex(FGUI:getController(items[i], "checked"),
                    (isPet and self.nowPetHHIndex or self.nowIndex) == i - 1 and 1 or 0)
            end

            if isPet then self:setPetModel(self.modelId, 0, 1.1) else self:updateModel() end
            self:updateHuanhuaBtnState(isPet)
            self:updateHuanhuaActionBtnText(isPet)
            self:updateHuanhuaIconAndLevel(isPet, itemData.Name)
            self:updateCostUI(isPet)
        end)
    end)
    if dataObj.hhSortList then FGUI:GList_setNumItems(listUi, #dataObj.hhSortList) end
end

function mountMain:updateHuanhuaBtnState(isPet)
    local dataObj = isPet and self._dataForPet or self._dataForMount
    local configList = isPet and PetHuanhua or MountHuanhua
    local btnActive = isPet and self._ui.petActiveBtn or self._ui.n60
    local btnHuanhua = isPet and self._ui.petHuanhua or self._ui.huanhua

    FGUI:setVisible(btnHuanhua, false)
    if not dataObj.hhSortList or #dataObj.hhSortList == 0 then
        FGUI:GTextField_setText(FGUI:GetChild(btnActive, "n1"), "激活")
        return
    end

    local nowName = dataObj.hhSortList[(isPet and self.nowPetHHIndex or self.nowIndex) + 1].Name
    local sameNames = 0
    for i = 1, #configList do if configList[i].Name == nowName then sameNames = sameNames + 1 end end

    local activatedGrade = dataObj.hhlistsj[nowName] or 0
    local text = "激活"
    if activatedGrade > 0 then
        FGUI:setVisible(btnHuanhua, true)
        text = (activatedGrade >= sameNames) and "已满级" or "升级"
    end
    FGUI:GTextField_setText(FGUI:GetChild(btnActive, "n1"), text)
end

function mountMain:updateHuanhuaActionBtnText(isPet)
    local dataObj = isPet and self._dataForPet or self._dataForMount
    local configList = isPet and PetHuanhua or MountHuanhua

    if not dataObj.hhSortList or #dataObj.hhSortList == 0 then return end
    local thisName = dataObj.hhSortList[(isPet and self.nowPetHHIndex or self.nowIndex) + 1].Name
    local nowGrade = dataObj.hhlistsj[thisName] or 1

    local targetModelId = 0
    for i = 1, #configList do
        if configList[i].Name == thisName and configList[i].grade == nowGrade then
            targetModelId = configList[i].Model; break
        end
    end

    FGUI:GTextField_setText(FGUI:GetChild(isPet and self._ui.petHuanhua or self._ui.huanhua, "title"),
        targetModelId == (isPet and dataObj.petHHid or dataObj.mountHHid) and "取消幻化" or "幻化")
end

function mountMain:updateHuanhuaIconAndLevel(isPet, specifiedName)
    local dataObj = isPet and self._dataForPet or self._dataForMount
    local uiNode = isPet and self._ui.n117 or self._ui.n118
    if not dataObj.hhSortList or #dataObj.hhSortList == 0 then return end

    local currentHHItem = nil
    if specifiedName and specifiedName ~= "" then
        for i = 1, #dataObj.hhSortList do
            if dataObj.hhSortList[i].Name == specifiedName then
                currentHHItem = dataObj.hhSortList[i]; break
            end
        end
    end

    local nowIndex = isPet and self.nowPetHHIndex or self.nowIndex
    if not currentHHItem and nowIndex >= 0 and nowIndex < #dataObj.hhSortList then
        currentHHItem = dataObj.hhSortList
            [nowIndex + 1]
    end

    local currentHHId = isPet and dataObj.petHHid or dataObj.mountHHid
    if not currentHHItem and currentHHId and tonumber(currentHHId) > 0 then
        for i = 1, #dataObj.hhSortList do
            if dataObj.hhSortList[i].Model == currentHHId then
                currentHHItem = dataObj.hhSortList[i]; break
            end
        end
    end

    currentHHItem = currentHHItem or dataObj.hhSortList[1]
    if not currentHHItem then return end

    local nameText = FGUI:GetChild(uiNode, "name")
    if nameText then FGUI:GTextField_setText(nameText, currentHHItem.Name) end

    local levelCtrl = FGUI:getController(uiNode, "level")
    if levelCtrl then
        FGUI:Controller_setSelectedIndex(levelCtrl,
            math.min(math.max(0, (dataObj.hhlistsj[currentHHItem.Name] or 0) - 1), 4))
    end
end

function mountMain:onHuanhuaTodo(isPet)
    local dataObj = isPet and self._dataForPet or self._dataForMount
    local configList = isPet and PetHuanhua or MountHuanhua
    local listData = dataObj.hhSortList[(isPet and self.nowPetHHIndex or self.nowIndex) + 1]
    if not listData then return end

    local activatedGrade = dataObj.hhlistsj[listData.Name] or 0
    local sameNames = {}
    for i = 1, #configList do if configList[i].Name == listData.Name then table.insert(sameNames, configList[i]) end end

    if activatedGrade >= #sameNames then return end

    local nextCfg = sameNames[activatedGrade + 1]
    local sendData = {
        idx = listData.ID,
        Name = listData.Name,
        grade = nextCfg.grade,
        ClassID = nextCfg.ClassID,
        Cost =
            nextCfg.Cost
    }
    if isPet then self._data:petTodoHHlist(sendData) else self._data:todoHHlist(sendData) end
end

-- ================= 坐骑与灵兽特有初始化 =================

function mountMain:initMountData()
    if self._dataForMount.isJh == 0 then
        FGUI:setVisible(self._ui.qhbtn, false)
        FGUI:GTextField_setText(FGUI:GetChild(self._ui.shengjizuoqi, "n1"), "激活")
    else
        FGUI:setVisible(self._ui.qhbtn, true)
        FGUI:GTextField_setText(FGUI:GetChild(self._ui.shengjizuoqi, "n1"), "升阶")
        FGUI:GTextField_setText(FGUI:GetChild(self._ui.qhbtn, "title"),
            self._dataForMount.ischuzhan == STATUS.FIGHT and "出战" or "休息")
    end
end

function mountMain:initMountTab()
    if self._dataForMount.allJieshu > 0 then
        FGUI:setVisible(self._ui.qhbtn, true)
        FGUI:GTextField_setText(FGUI:GetChild(self._ui.shengjizuoqi, "n1"), "升阶")
        FGUI:GTextField_setText(FGUI:GetChild(self._ui.qhbtn, "title"),
            self._dataForMount.ischuzhan == STATUS.FIGHT and "出战" or "休息")
    end
    self.modelId = self._dataForMount.modelId
    self:updateView()
    self:updateMainTitle(false)
end

function mountMain:updateView()
    local jieshu = self:renderStars(self._ui.xxshu, self._dataForMount.allJieshu)
    FGUI:GTextField_setText(self.jieshuName["bigLevel"], NUMBER_TO_CHINESE[jieshu + 1])
    self.modelId = (self._dataForMount.mountHHid and self._dataForMount.mountHHid ~= 0) and self._dataForMount.mountHHid or
        Mount[self._dataForMount.allJieshu].Model
    self:updateModel()
    self:updateBaseAttrView(false)
    if self._dataForMount.allJieshu == #Mount then
        FGUI:GTextField_setText(FGUI:GetChild(self._ui.shengjizuoqi, "n1"),
            "已满级")
    end
end

function mountMain:updateModel() self._modelIndex = self:setup3DModel(self.mountBody, self.modelId, 0, 1.1, self.uiTouch) end

function mountMain:initPetTab()
    local titleNode = FGUI:GetChild(self._ui.shengjilingshou, "n1")
    if self._dataForPet.isPetJh == 0 then
        FGUI:setVisible(self._ui.petQhbtn, false)
        FGUI:GTextField_setText(titleNode, "激活")
    else
        FGUI:setVisible(self._ui.petQhbtn, true)
        FGUI:GTextField_setText(titleNode, "升阶")
        FGUI:GTextField_setText(FGUI:GetChild(self._ui.petQhbtn, "title"),
            self._dataForPet.isPetChuzhan == 1 and "召回" or "出战")
    end
    self.modelId = (self._dataForPet.showPetModelId and self._dataForPet.showPetModelId > 0) and
        self._dataForPet.showPetModelId or
        (Pet[self._dataForPet.allJieshu] and Pet[self._dataForPet.allJieshu].Model or Pet[0].Model)
    if self.modelId then self:setPetModel(self.modelId, 0, 1.1) end
    self:updateBaseAttrView(true)
    self:setPetInfo()
end

function mountMain:setPetInfo()
    local stars = self._dataForPet.allJieshu
    FGUI:GTextField_setText(self._ui.petName, (Pet[stars] or Pet[0]).Name or "龙猫")
    FGUI:GTextField_setText(self.petJieshuName["bigLevel"],
        NUMBER_TO_CHINESE[self:renderStars(self._ui.petxxshu, stars) + 1])

    if self._dataForPet.isPetJh ~= 0 then
        FGUI:setVisible(self._ui.petQhbtn, true)
        FGUI:GTextField_setText(FGUI:GetChild(self._ui.petQhbtn, "title"),
            self._dataForPet.isPetChuzhan == 1 and "召回" or "出战")
    end
    if stars == #Pet then
        FGUI:GTextField_setText(FGUI:GetChild(self._ui.shengjilingshou, "n1"), "已满级")
        FGUI:setVisible(self._ui.n104, false)
    else
        FGUI:setVisible(self._ui.n104, true)
    end
end

function mountMain:setPetAtta()
    if self.petTopTab == 0 then self:updateBaseAttrView(true) else self:updateHuanhuaAttrView(true) end
end

function mountMain:setPetModel(modelId, offsetY, scale)
    self._petModelIndex = self:setup3DModel(self.petBody, modelId, offsetY, scale, self.petUiTouch)
end

function mountMain:setPetBtPetBtn()
    if self._dataForPet.isPetJh == 0 then
        FGUI:setVisible(self._ui.petQhbtn, false)
    else
        FGUI:setVisible(self._ui.petQhbtn, true)
        FGUI:GTextField_setText(FGUI:GetChild(self._ui.petQhbtn, "title"),
            self._dataForPet.isPetChuzhan == 1 and "召回" or "出战")
    end
end

function mountMain:refreshPetModel()
    self.modelId = (self._dataForPet.showPetModelId and self._dataForPet.showPetModelId > 0) and
        self._dataForPet.showPetModelId or
        (Pet[self._dataForPet.allJieshu] and Pet[self._dataForPet.allJieshu].Model or Pet[1].Model)
    if self.modelId and self.petBody then self:setPetModel(self.modelId, 0, 1.1) end
end

function mountMain:updatePetView()
    self.modelId = (self._dataForPet.showPetModelId and self._dataForPet.showPetModelId > 0) and
        self._dataForPet.showPetModelId or
        (self._dataForPet.modelId or (Pet[self._dataForPet.allJieshu] and Pet[self._dataForPet.allJieshu].Model) or 800001)
    if self.modelId then self:setPetModel(self.modelId, 0, 1.1) end
    self:setPetInfo()
    self:setPetAtta()
    self:updateCostUI(true)
end

function mountMain:initHuanhuaTabCommon(isPet)
    local dataObj = isPet and self._dataForPet or self._dataForMount
    local attrUi = isPet and self._ui.petHuanhuaAttr or self._ui.huanhuaAttr
    local btnHuanhua = isPet and self._ui.petHuanhua or self._ui.huanhua
    local btnActive = isPet and self._ui.petActiveBtn or self._ui.n60
    local nameNode = isPet and self._ui.petName or self._ui.mountName

    if not isPet then
        self._dataForMount = self._data:GetDataForMount(); dataObj = self._dataForMount
    end

    if not dataObj.hhSortList or #dataObj.hhSortList == 0 then
        FGUI:setVisible(attrUi, false); FGUI:setVisible(btnHuanhua, false); FGUI:setVisible(btnActive, false)
        FGUI:GTextField_setText(nameNode, "暂无幻化")
        return
    end

    FGUI:setVisible(attrUi, true); FGUI:setVisible(btnHuanhua, true); FGUI:setVisible(btnActive, true)

    local nowIdx = isPet and self.nowPetHHIndex or self.nowIndex
    if not nowIdx or nowIdx < 0 or nowIdx >= #dataObj.hhSortList then
        nowIdx = 0
        local currentHHId = isPet and dataObj.petHHid or dataObj.mountHHid
        if currentHHId and tonumber(currentHHId) > 0 then
            for i = 1, #dataObj.hhSortList do
                if dataObj.hhSortList[i].Model == currentHHId then
                    nowIdx = i - 1; break
                end
            end
        end
    end

    if isPet then self.nowPetHHIndex = nowIdx else self.nowIndex = nowIdx end

    self:updateMainTitle(isPet)
    self.modelId = dataObj.hhSortList[nowIdx + 1].Model
    self:updateHuanhuaAttrView(isPet)
    self:setupListRender(isPet)

    if isPet then self:setPetModel(self.modelId, 0, 1.1) else self:updateModel() end

    self:updateHuanhuaBtnState(isPet)
    self:updateHuanhuaActionBtnText(isPet)
    self:updateHuanhuaIconAndLevel(isPet)
    self:updateCostUI(isPet)

    FGUI:setOnClickEvent(btnHuanhua, function()
        if not checkCooldown(isPet and "petHuanhua" or "huanhua") then return end
        if isPet then
            self._data:setPetModel({ mountId = self.modelId })
        else
            self._data:setModel({
                mountId = self
                    .modelId
            })
        end
    end)
    FGUI:setOnClickEvent(btnActive, function() self:onHuanhuaTodo(isPet) end)
end

function mountMain:UpdatePetAttrRate()
    local petLevel = tonumber(self._dataForPet and self._dataForPet.allJieshu or 1) or 1
    if self._ui.n107 then
        FGUI:GTextField_setText(self._ui.n107,
            string.format("出战灵兽[color=#00ff00]%s[/color]的属性转化给人物",
                math.floor(getPetAttrRateByLevel(petLevel) * 100) .. "%"))
    end
end

return mountMain
