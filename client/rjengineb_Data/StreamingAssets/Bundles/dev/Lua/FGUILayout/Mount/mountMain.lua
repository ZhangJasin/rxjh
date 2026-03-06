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
local mountMainData = SL:RequireFile("FGUILayout/Mount/mountMainData")

-- 数字转中文大写
local NUMBER_TO_CHINESE = {"零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"}

-- 常量定义
local TAB_TYPE = {
    MOUNT = 0,    -- 坐骑标签
    MOUNT_HH = 1  -- 坐骑幻化标签
}

local PET_TYPE = {
    SPIRIT_BEAST = 1,  -- 灵兽
    SPIRIT_HH = 2      -- 灵兽幻化
}

local STATUS = {
    FIGHT = 0,   -- 出战状态
    REST = 1     -- 休息状态
}

function mountMain:Create()
    mountMainData:Init()
    -- 初始化UI组件
    self._ui = FGUI:ui_delegate(self.component) 
    -- 初始化界面UI
    self:initVariables()
    -- 绑定关闭按钮事件
    FGUI:setOnClickEvent(self._ui.closeBtn, function()  
        FGUI:Close("Mount", "mountMain")
    end)
    -- 初始化订阅事件
    self._subscriptions = {}
     -- 订阅数据管理器事件并且初始化显示数据
    self:subscribeEvents()
    -- 初始化标签和列表
    self:initTabsAndLists()
    -- 绑定事件监听
    self:bindEvents()
end
-- 订阅数据管理器事件
function mountMain:subscribeEvents()
    -- 获取数据管理器实例
    self._data = mountMainData.Get()
    -- 订阅数据更新事件
    if self._data.Subscribe then
        self._subscriptions.lsListUpdate = self._data:Subscribe("ls_list_update", function(state)
            self._dataForPet = state._dataForPet
            self.selectPetIndex = state.selectPetIndex
            FGUI:GList_setNumItems(self._ui.petsList, #self._dataForPet.allPets)
            --灵兽
            self:setPetInfo()
            self:setAtta()
            self:setBtPetBtn()
            self:setPetXhcl()
            self:setPetSelect()
            self:setLsBtnText()
        end)
        self._subscriptions.lsLevelResult = self._data:Subscribe("ls_level_result", function(state)
            self._dataForPet = state
            FGUI:GList_setNumItems(self._ui.petsList, #self._dataForPet.allPets)
            --灵兽
            self:setPetInfo()
            self:setAtta()
            self:setBtPetBtn()
            self:setPetXhcl()
            self:setPetSelect()
            self:setLsBtnText()
        end)
        self._subscriptions.lsUpdateModel = self._data:Subscribe("ls_update_model", function(state)
            self._dataForPet = state
            FGUI:GList_setNumItems(self._ui.petsList, #self._dataForPet.allPets)
            --灵兽
            self:updatePetView()
        end)
        self._subscriptions.lsUnrecallpet = self._data:Subscribe("ls_unrecallpet", function(state)
            self._dataForPet = state
            FGUI:GList_setNumItems(self._ui.petsList, #self._dataForPet.allPets)
            self:setLsBtnText()
        end)
        self._subscriptions.updateHHResult = self._data:Subscribe("updateHHResult", function(state)
            -- dump(state)
            self._dataForMount = state._dataForMount
            self.nowIndex = state.selectHHIndex - 1
            FGUI:GList_setNumItems(self.leftList, #self._dataForMount.hhSortList)
             -- 更新视图
            self:setMountHHSx()
            self:setXHCL()
            self:setHHAddBtn()
            self:updateModel()
            self:UpdateHHBtnName()
        end)
        self._subscriptions.mountLevelUp = self._data:Subscribe("mountLevelUp", function(state)
            self._dataForMount = state
            self:initMountData()
            self:updateView()
            self:setXHCL()
        end)
        self._subscriptions.mountUpdateBtn = self._data:Subscribe("mountUpdateBtn", function(state)
            self._dataForMount = state
            local title = FGUI:GetChild(self._ui.qhbtn, "title")
            if self._dataForMount.ischuzhan == STATUS.FIGHT then 
                FGUI:GTextField_setText(title, "出战")
            else
                FGUI:GTextField_setText(title, "休息")
            end
        end)
    end
    -- 初始化显示数据
    self:initDisplayData()
end
-- 清理订阅
function mountMain:Destroy()
    if self._subscriptions then
        for _, token in pairs(self._subscriptions) do
            if self._data and self._data.Unsubscribe then
                self._data:Unsubscribe(token)
            end
        end
        self._subscriptions = nil
    end
    self._data = nil
    self._ui = nil
end
-- 初始化显示数据
function mountMain:initDisplayData()
    -- 从数据管理器获取数据或使用默认值
    self._dataForMount = self._data:GetDataForMount()
    self._dataForPet = self._data:GetDataForPet()
    self.topTab = 0
    --灵兽
    self.selectPetIndex = 1 --灵兽默认选择
    self.petIndex = 0 --当前灵兽视图左右切换下标
    self:setPetInfo()
    self:setAtta()
    self:setBtPetBtn()
    self:setPetXhcl()
    self:setPetSelect()
    self:setLsBtnText()
    --坐骑
    self:initMountData()
    self:InitData()
end
function mountMain:Enter(data)
    if data and data.type then
        -- dump(data)
        self.rightTabs = FGUI:getController(self.component, "rightTabs")
        FGUI:Controller_setSelectedIndex(self.rightTabs, tonumber(data.type))
        self.topTabs = FGUI:getController(self.component, "topTabs")
        if data.type == 0  then
            --灵兽
            --直接选中当前出战的
            self.petsList = self._ui.petsList
            for w=1,#self._dataForPet.allPets do
                if self._dataForPet.allPets[w].ID == self._dataForPet.selectViewPetId then
                    self.selectPetIndex = w
                end
            end
            -- 更新视图
            self:setPetInfo()
            self:setAtta()
            self:setBtPetBtn()
            self:setPetXhcl()
            self:setPetSelect()
            self:setLsBtnText()
        else
            FGUI:Controller_setSelectedIndex(self.rightTabs, 1)
            --坐骑
            if data.name then
                --幻化
                -- 设置列表渲染
                FGUI:Controller_setSelectedIndex(self.topTabs, 1)
                -- FGUI:GList_setSelectedIndex(self._ui.topTabList, TAB_TYPE.MOUNT_HH)
                self.topTab = TAB_TYPE.MOUNT_HH
                --幻化
                -- self:updateViewByName(data.name)
                local results = self._dataForMount.hhSortList
                -- dump(results)
                for i=1,#results do
                    if results[i].Name == data.name then
                        self.nowIndex = i -1
                    end
                end
                self.leftList = self._ui.leftList
                if self.nowIndex < 0 then
                    self.nowIndex = 0
                end
                self:updateMainTitle()
                -- 获取排序后的幻化列表
                self.modelId = self._dataForMount.hhSortList[self.nowIndex + 1].Model
                -- 设置幻化属性
                self:setMountHHSx()
                -- 设置列表渲染
                self:setupHuanhuaList()
                -- 绑定幻化按钮事件
                FGUI:setOnClickEvent(self._ui.huanhua, function() 
                    -- ssrMessage:sendmsgEx("mountMain", "setModel", {mountId = self.modelId})
                    self._data:setModel({mountId = self.modelId})
                end)
                -- 更新模型和按钮状态
                self:updateModel()
                self:setHHAddBtn()
                self:UpdateHHBtnName()
                self:setXHCL()
            else
                FGUI:Controller_setSelectedIndex(self.topTabs, 0)
                --坐骑
            end 
        end
    end
end
-- 初始化界面UI
function mountMain:initVariables()
    -- 标签和列表引用
    self.topTabList = FGUI:ui_delegate(self._ui.topTabList)   -- 左上标签列表
    self.rightTabList = FGUI:ui_delegate(self._ui.rightTabList) -- 右上标签列表
    self.leftList = FGUI:ui_delegate(self._ui.leftList)    -- 幻化列表
    self.mountBody = FGUI:UIModel_Bind(self._ui.mountBody) -- 坐骑模型
    self.uiTouch = FGUI:GetChild(self.component, "mountModel")
    -- UI元素引用
    self.jieshuName = FGUI:ui_delegate(self._ui.jieshu)   -- 阶数
    self.xxshu = FGUI:ui_delegate(self._ui.xxshu)     -- 星星数
    self.currentMountAttr = FGUI:ui_delegate(self._ui.nowAttr)  -- 当前坐骑属性
    self.nextMountAttr = FGUI:ui_delegate(self._ui.nextAttr)    -- 下级坐骑属性
    self.huanhuaAttr = FGUI:ui_delegate(self._ui.huanhuaAttr)   -- 幻化属性
end
-- 初始化标签和列表
function mountMain:initTabsAndLists()
    -- 设置默认选中标签
    FGUI:GList_setSelectedIndex(self._ui.topTabList, TAB_TYPE.MOUNT)   -- 0坐骑 1幻化
    FGUI:GList_setSelectedIndex(self._ui.rightTabList, 0)               -- 0灵兽 1坐骑
    FGUI:GList_setSelectedIndex(self._ui.leftList, 0)
    FGUI:GList_setSelectedIndex(self._ui.petsList, 0)
end
-- 绑定事件监听
function mountMain:bindEvents()
    -- 顶部标签切换事件
    FGUI:GList_addOnClickItemEvent(self._ui.topTabList, function(context)
        local index = FGUI:GList_getSelectedIndex(self._ui.topTabList)
        if self._dataForMount.allJieshu and self._dataForMount.allJieshu == 0 then
            SL:ShowSystemTips("请先激活坐骑")
            FGUI:GList_setSelectedIndex(self._ui.topTabList, 0)
        else
            self.topTab = index
            self:InitData()
        end
    end)
    FGUI:GList_itemRenderer(self._ui.petsList, handler(self, self.RenderPetList))
    FGUI:GList_setNumItems(self._ui.petsList, #self._dataForPet.allPets)
    -- 绑定灵兽左右切换按钮事件
    self:bindPetSwitchEvents()
    -- 绑定灵兽相关按钮事件
    self:bindPetButtonsEvents()
end
--灵兽渲染
function mountMain:RenderPetList(idx,item)
    local petData = self._dataForPet.allPets[idx + 1]
    local petName = FGUI:GetChild(item, "n1")
    local petLv = FGUI:GetChild(item, "n5")
    -- 设置等级和名称颜色
    local thisLv = 0
    local nameColor = "#81807F"
    if self._dataForPet.allPetsActive[petData.Pet_Name] then
        thisLv = self._dataForPet.allPetsActive[petData.Pet_Name]
        nameColor = "#FFCC00"
    end
    if thisLv > 0 then
        FGUI:setVisible(petLv, true)
    end
    -- 设置图标
    local obj = FGUI:GetChild(item, "n7")
    FGUI:GLoader_setUrl(obj, "ui://Mount/" .. petData.Pet_Icon)
    -- 设置名称和等级
    FGUI:GTextField_setText(petName, petData.Pet_Name)
    FGUI:GTextField_setColor(petName, nameColor)
    FGUI:GTextField_setText(petLv, 'Lv' .. thisLv)
    -- 设置选中状态和出战状态
    local controller = FGUI:getController(item, 'isSelect')
    local ischuzhan = FGUI:getController(item, 'ischuzhan')
    if (idx + 1) == self.selectPetIndex then
        FGUI:Controller_setSelectedIndex(controller, 1)
    else
        FGUI:Controller_setSelectedIndex(controller, 0)
    end
    if self._dataForPet.selectViewPetId == petData.ID then
        FGUI:Controller_setSelectedIndex(ischuzhan, 1)
    else
        FGUI:Controller_setSelectedIndex(ischuzhan, 0)
    end
    FGUI:setOnClickEvent(item, function()
        self.selectPetIndex = idx + 1
        -- 重置控制器和索引
        local cont = FGUI:getController(self._ui.lingshou, 'whichIndex')
        FGUI:Controller_setSelectedIndex(cont, 0)
        self.petIndex = 0
        -- 更新视图
        self:setPetInfo()
        self:setAtta()
        self:setBtPetBtn()
        self:setPetXhcl()
        self:setPetSelect()
        self:setLsBtnText()
    end)
end
--灵兽召唤收回按钮文字
function mountMain:setLsBtnText()
    local lshuanhua = FGUI:GetChild(self._ui.lingshou, "lshuanhua")
    local petData = self._dataForPet.allPets[self.selectPetIndex]
    if self._dataForPet.selectViewPetId == petData.ID then
        FGUI:GTextField_setText(lshuanhua, "收回")
    else
        FGUI:GTextField_setText(lshuanhua, "召唤")
    end
end
-- 设置灵兽信息
function mountMain:setPetInfo()
    local cont = FGUI:getController(self._ui.lingshou, 'whichIndex')
    local which = FGUI:Controller_getSelectedIndex(cont)
    if which == 1 then
        -- 灵兽幻化
        self:setPetHHInfo()
    else
        -- 灵兽本体
        self:setPetBTInfo()
    end
end
-- 设置灵兽幻化信息
function mountMain:setPetHHInfo()
    local data = self.thisPetData[self.petIndex]
    local titlePanl = FGUI:GetChild(self._ui.lingshou, "n16")
    local title = FGUI:GetChild(titlePanl, "n0")
    -- 设置标题
    FGUI:GTextField_setText(title, data.Pet_Name)
    -- 设置BUFF信息
    local hhsx = FGUI:GetChild(self._ui.lingshou, "hhsx")
    local buffdesc = FGUI:GetChild(hhsx, "n21")
    local bufficon = FGUI:GetChild(hhsx, "skillicon")
    local icon = FGUI:GetChild(bufficon, "icon")
    FGUI:GLoader_setUrl(icon, "ui://Mount/" .. data.Buff_Icon)
    FGUI:GTextField_setText(buffdesc, data.BUFF_DESC)
end
-- 设置灵兽本体信息
function mountMain:setPetBTInfo()
    local data = self._dataForPet.allPets[self.selectPetIndex]
    local titlePanl = FGUI:GetChild(self._ui.lingshou, "btTitle")
    local title = FGUI:GetChild(titlePanl, "n0")
    local thislv = FGUI:GetChild(titlePanl, "n1")
    -- 获取等级
    local lv = 0
    if self._dataForPet.allPetsActive[data.Pet_Name] then
        lv = self._dataForPet.allPetsActive[data.Pet_Name]
    end
    -- 设置名称和等级
    FGUI:GTextField_setText(title, data.Pet_Name)
    FGUI:GTextField_setText(thislv, lv .. "级")
    -- 控制等级显示
    if lv == 0 then
        FGUI:setVisible(thislv, false)
    else
        FGUI:setVisible(thislv, true)
    end
    -- 设置升级按钮文本
    local btsx = FGUI:GetChild(self._ui.lingshou, "btsx")
    local activeslBtn = FGUI:GetChild(btsx, "activeslBtn")
    local btnText = FGUI:GetChild(activeslBtn, "n1")
    if lv == #data.BasePet_GrowRatio then
        FGUI:GTextField_setText(btnText, "已满级")
    else
        FGUI:GTextField_setText(btnText, "升级")
    end
end
-- 绑定灵兽左右切换按钮事件
function mountMain:bindPetSwitchEvents()
    local toleft = FGUI:GetChild(self._ui.lingshou, "toleft")
    local toright = FGUI:GetChild(self._ui.lingshou, "toright")
    -- 向左切换
    FGUI:setOnClickEvent(toleft, function()
        local modelid = self._dataForPet.allPets[self.selectPetIndex].ID
        local maxCount = self:getMaxCountByid(modelid)
        local cont = FGUI:getController(self._ui.lingshou, 'whichIndex')
        if self.petIndex == 0 then
            self.petIndex = maxCount
        else
            self.petIndex = self.petIndex - 1
        end
        if self.petIndex == 0 then
            FGUI:Controller_setSelectedIndex(cont, 0)
            self:setBtPetBtn()
        else
            FGUI:Controller_setSelectedIndex(cont, 1)
        end
        
        self:updatePetView()
    end)
    -- 向右切换
    FGUI:setOnClickEvent(toright, function()
        local modelid = self._dataForPet.allPets[self.selectPetIndex].ID
        local maxCount = self:getMaxCountByid(modelid)
        local cont = FGUI:getController(self._ui.lingshou, 'whichIndex')
        if self.petIndex == maxCount then
            self.petIndex = 0
        else
            self.petIndex = self.petIndex + 1
        end
        if self.petIndex == 0 then
            FGUI:Controller_setSelectedIndex(cont, 0)
            self:setBtPetBtn()
        else
            FGUI:Controller_setSelectedIndex(cont, 1)
        end
        self:updatePetView()
    end)
end
-- 绑定灵兽相关按钮事件
function mountMain:bindPetButtonsEvents()
    local hhbtn = FGUI:GetChild(self._ui.lingshou, "hhbtn")
    local lshuanhua = FGUI:GetChild(self._ui.lingshou, "lshuanhua")
    -- 幻化按钮事件
    FGUI:setOnClickEvent(hhbtn, function()
        local thisBtId = self.thisPetData[self.petIndex].CoverPet_ID
        local newId = self.thisPetData[self.petIndex].Pet_Lego 
        local isJhbt = false
        local btid = 0
        local btmodelId = nil
        for i = 1, #self._dataForPet.allPets do
            if self._dataForPet.allPets[i].ID == thisBtId and self._dataForPet.allPetsActive[self._dataForPet.allPets[i].Pet_Name] then
                isJhbt = true
                btid = self._dataForPet.allPets[i].ID
                btmodelId = self._dataForPet.allPets[i].Pet_Lego
            end
        end
        if isJhbt then
            self._data:updatePetModel({id = btid, modelid = newId, btmodelId = btmodelId })
        else
            SL:ShowSystemTips("请先激活本体")
        end         
    end)
    -- 召唤/收回按钮事件
    FGUI:setOnClickEvent(lshuanhua, function()
        local lshuanhua = FGUI:GetChild(self._ui.lingshou, "lshuanhua")
        local nowText = FGUI:GTextField_getText(lshuanhua)
        if nowText == "收回" then
            nowText = "召唤"
            self._data:unrecallpet()
        else
            nowText = "收回"
            self._data:recallpet({ btid = self._dataForPet.allPets[self.selectPetIndex].ID, isNeedBack = 1 })
        end
        FGUI:GList_setNumItems(self._ui.petsList, #self._dataForPet.allPets)
        FGUI:GTextField_setText(lshuanhua, nowText)
    end)
    -- 绑定本体升级按钮事件
    self:bindPetUpgradeEvents()
end
-- 绑定本体升级按钮事件
function mountMain:bindPetUpgradeEvents()
    local btsx = FGUI:GetChild(self._ui.lingshou, "btsx")
    local activeslBtn = FGUI:GetChild(btsx, "activeslBtn") -- 升级按钮
    local activeslBtn2 = FGUI:GetChild(btsx, "activeslBtn2") -- 激活按钮
    -- 本体升级
    FGUI:setOnClickEvent(activeslBtn, function()
        local data = self._dataForPet.allPets[self.selectPetIndex]
        local nowLv = self._dataForPet.allPetsActive[data.Pet_Name]
        if nowLv == #data.BasePet_GrowRatio then
            return
        end
        local itemId = data.BasePet_GrowCost[1]
        local num = data.BasePet_GrowCost[2][nowLv]
        self._data:levelUp({name = data.Pet_Name, maxLv = #data.BasePet_GrowRatio, num = num, itemId = itemId})
    end)
    -- 激活按钮事件
    FGUI:setOnClickEvent(activeslBtn2, function()
        local data = self._dataForPet.allPets[self.selectPetIndex]
        local itemId = data.Pet_ACTIVE
        local num = 1
        self._data:lsjihuo({itemId = itemId})
    end)
    -- 绑定幻化激活按钮事件
    local hhsx = FGUI:GetChild(self._ui.lingshou, "hhsx")
    local activeslBtn3 = FGUI:GetChild(hhsx, "activeslBtn2")
    FGUI:setOnClickEvent(activeslBtn3, function()
        local itemId = self.thisPetData[self.petIndex].Pet_ACTIVE
        self._data:lsjihuo({itemId = itemId})
    end)
end
-- 根据ID获取最大数量
function mountMain:getMaxCountByid(id)
    local maxCount = 0
    self.thisPetData = {}
    for i = 1, #self._dataForPet.allPetsHH do
        if tonumber(self._dataForPet.allPetsHH[i].CoverPet_ID) == tonumber(id) then
            maxCount = maxCount + 1
            table.insert(self.thisPetData, self._dataForPet.allPetsHH[i])
        end
    end 
    return maxCount
end
-- 设置本体宠物按钮状态
function mountMain:setBtPetBtn()
    local btn = FGUI:GetChild(self._ui.lingshou, "lshuanhua")
    -- 根据激活状态控制显示
    if self._dataForPet.allPetsActive[self._dataForPet.allPets[self.selectPetIndex].Pet_Name] then
        FGUI:setVisible(btn, true)
    else
        FGUI:setVisible(btn, false)
    end
end
-- 更新灵兽视图
function mountMain:updatePetView()
    self:setPetInfo()
    self:setAtta()
    self:setPetXhcl()
end
-- 设置灵兽信息
function mountMain:setPetInfo()
    local cont = FGUI:getController(self._ui.lingshou, 'whichIndex')
    local which = FGUI:Controller_getSelectedIndex(cont)
    if which == 1 then
        -- 灵兽幻化
        self:setPetHHInfo()
    else
        -- 灵兽本体
        self:setPetBTInfo()
    end
end
-- 设置灵兽属性显示
function mountMain:setAtta()
    local cont = FGUI:getController(self._ui.lingshou, 'whichIndex')
    local which = FGUI:Controller_getSelectedIndex(cont)
    if which == 1 then
        -- 灵兽幻化
        self:setPetHHAtta()
    else
        -- 灵兽本体
        self:setPetBTAtta()
    end
end
-- 设置灵兽幻化属性
function mountMain:setPetHHAtta()
    local hhAttr = FGUI:GetChild(self._ui.lingshou, 'hhsx')
    local data = self.thisPetData[self.petIndex]
    -- 格式化属性数据
    local result1 = {}
    local result2 = {}
    for b = 1, #data.CoverPet_ActiveProType do
        table.insert(result1, {tonumber(data.CoverPet_ActiveProType[b]), tonumber(data.CoverPet_ActiveProNum[b])})
    end
    for c = 1, #data.CoverPet_CoverProType do
        table.insert(result2, {tonumber(data.CoverPet_CoverProType[c]), tonumber(data.CoverPet_CoverProNum[c])})
    end
    -- 获取属性列表组件
    local nowAttr = FGUI:GetChild(hhAttr, "n3")
    local nextAttr = FGUI:GetChild(hhAttr, "n7")
    -- 渲染当前属性
    self:renderAttributeList(nowAttr, result1)
    -- 渲染下一阶属性
    self:renderAttributeList(nextAttr, result2)
    -- 设置模型
    local petModelPanl = FGUI:GetChild(self._ui.lingshou, 'n12')
    if self.petModel then
        FGUI:UIModel_Unbind(self.petModel)
    end
    self.petModel = FGUI:UIModel_Bind(petModelPanl)
    local modelId = data.Pet_Lego
    FGUI:UIModel_addLegoModel(
        self.petModel, 
        modelId, 
        {x = 0, y = data.Lego_Offset, z = 0}, 
        nil, 
        Vector3.one * data.Model_Scale
    )
    FGUI:UIModel_setModelCallback(self.petModel, function(index)
        FGUI:UIModel_playAnimation(self.petModel, index, "Stand", nil, 0)
    end)
    -- 设置幻化按钮状态
    local isActiveModel = self:setPetHHStatus()
    local thisModelBtn = FGUI:GetChild(self._ui.lingshou, 'hhbtn')
    local thisModelCont = FGUI:getController(thisModelBtn, 'HHstatus')
    if isActiveModel then
        if self._dataForPet.showPetModelId == modelId then
            -- 幻化中
            FGUI:Controller_setSelectedIndex(thisModelCont, 1)
        else
            -- 幻化
            FGUI:Controller_setSelectedIndex(thisModelCont, 0)
        end
    end
end
-- 设置灵兽本体属性
function mountMain:setPetBTAtta()
    local btAttr = FGUI:GetChild(self._ui.lingshou, 'btsx')
    local btCont = FGUI:getController(btAttr, 'isActive')
    local nowAttr = FGUI:GetChild(btAttr, "n3")
    local nextAttr = FGUI:GetChild(btAttr, "n7")
    -- 获取等级
    local lv = 0
    local data = self._dataForPet.allPets[self.selectPetIndex]
    if self._dataForPet.allPetsActive[data.Pet_Name] then
        lv = tonumber(self._dataForPet.allPetsActive[data.Pet_Name])
    end
    -- 计算下一等级
    local nextLv = lv + 1
    -- 防止越界
    if lv == 0 then
        lv = 1
    end
    if nextLv > #data.BasePet_GrowRatio then
        nextLv = #data.BasePet_GrowRatio
    end
    -- 格式化属性数据
    local result1 = {}
    local result2 = {}
    for d = 1, #data.BasePet_ProType do
        table.insert(result1, {tonumber(data.BasePet_ProType[d]), math.floor(data.BasePet_ProNum[d] + data.BasePet_ProNum[d] * data.BasePet_GrowRatio[lv])})
        table.insert(result2, {tonumber(data.BasePet_ProType[d]), math.floor(data.BasePet_ProNum[d] + data.BasePet_ProNum[d] * data.BasePet_GrowRatio[nextLv])})
    end
    -- 渲染属性列表
    self:renderAttributeList(nowAttr, result1)
    self:renderAttributeList(nextAttr, result2)
    -- 设置模型
    local petModelPanl = FGUI:GetChild(self._ui.lingshou, 'n12')
    if self.petModel then
        FGUI:UIModel_Unbind(self.petModel)
    end
    self.petModel = FGUI:UIModel_Bind(petModelPanl)
    local modelId = data.Pet_Lego
    FGUI:UIModel_addLegoModel(
        self.petModel, 
        modelId, 
        {x = 0, y = data.Lego_Offset, z = 0}, 
        nil, 
        Vector3.one * data.Model_Scale
    )
    FGUI:UIModel_setModelCallback(self.petModel, function(index)
        FGUI:UIModel_playAnimation(self.petModel, index, "Stand", nil, 0)
    end)
end
-- 渲染属性列表
function mountMain:renderAttributeList(list, attributes)
    FGUI:GList_itemRenderer(list, function(index, item)
        local label = AttScoreNames[attributes[index + 1][1]].Name .. ":"
        local value = attributes[index + 1][2]
        local itemLabel = FGUI:GetChild(item, "label")
        local itemValue = FGUI:GetChild(item, "zhi")
        local isDouble = FGUI:getController(item, 'isDouble')
        -- 设置交替背景
        if index % 2 == 0 then
            FGUI:Controller_setSelectedIndex(isDouble, 0)
        else
            FGUI:Controller_setSelectedIndex(isDouble, 1)
        end
        -- 设置属性文本
        FGUI:GTextField_setText(itemLabel, label)
        FGUI:GTextField_setText(itemValue, value)
    end)
    FGUI:GList_setNumItems(list, #attributes)
end
-- 设置宠物幻化状态
function mountMain:setPetHHStatus()
    local result = false
    local cont = FGUI:getController(self._ui.lingshou, 'whichIndex')
    local btn = FGUI:GetChild(self._ui.lingshou, 'hhbtn')
    local which = FGUI:Controller_getSelectedIndex(cont)
    -- 幻化标签
    if which == 1 then
        FGUI:setVisible(btn, false)
        if self._dataForPet.allPetsActive[self.thisPetData[self.petIndex].Pet_Name] then
            -- 已激活
            result = true
            FGUI:setVisible(btn, true)
        end
    end
    return result
end
-- 设置宠物消耗材料
function mountMain:setPetXhcl()
    -- 是否激活
    local isActive = 0
    local cont = FGUI:getController(self._ui.lingshou, 'whichIndex')
    local which = FGUI:Controller_getSelectedIndex(cont)
    local xhclData = {}
    local jhid = nil
    local activeCont = nil
    local iconItem = nil
    local lv = 1
    local num = 1
    if which == 1 then
        -- 灵兽幻化
        local hhsx = FGUI:GetChild(self._ui.lingshou, "hhsx")
        activeCont = FGUI:getController(hhsx, 'isActive')
        local xgclPanl = FGUI:GetChild(hhsx, "xhcl")
        iconItem = FGUI:GetChild(xgclPanl, "iconItem")
        -- 判断是否已激活
        if self._dataForPet.allPetsActive[self.thisPetData[self.petIndex].Pet_Name] then
            isActive = 1
            FGUI:Controller_setSelectedIndex(activeCont, 1)
        else
            local itemNum = FGUI:GetChild(xgclPanl, "n2")
            local fuhao = FGUI:GetChild(xgclPanl, "n1")
            local haveNum = SL:GetValue(TITEMCOUNT, tonumber(self.thisPetData[self.petIndex].Pet_ACTIVE))
            -- 设置数量颜色
            if haveNum >= 1 then
                FGUI:GTextField_setColor(itemNum, "#00FF00")
                FGUI:GTextField_setColor(fuhao, "#00FF00")
            else
                FGUI:GTextField_setColor(itemNum, "#ff0000")
                FGUI:GTextField_setColor(fuhao, "#ff0000")
            end
            FGUI:GTextField_setText(itemNum, 1)
            FGUI:Controller_setSelectedIndex(activeCont, 0)
        end
        jhid = self.thisPetData[self.petIndex].Pet_ACTIVE
    else
        -- 灵兽本体
        local btxs = FGUI:GetChild(self._ui.lingshou, "btsx")
        activeCont = FGUI:getController(btxs, 'isActive')
        local xgclPanl = FGUI:GetChild(btxs, "xhcl")
        iconItem = FGUI:GetChild(xgclPanl, "iconItem")
        local itemNum = FGUI:GetChild(xgclPanl, "n2")
        local fuhao = FGUI:GetChild(xgclPanl, "n1")
        local haveNum = 0
        xhclData = self._dataForPet.allPets[self.selectPetIndex].BasePet_GrowCost
        -- 判断是否已激活
        if self._dataForPet.allPetsActive[self._dataForPet.allPets[self.selectPetIndex].Pet_Name] then
            isActive = 1
            FGUI:Controller_setSelectedIndex(activeCont, 1)
            -- 获取当前等级和消耗数量
            lv = self._dataForPet.allPetsActive[self._dataForPet.allPets[self.selectPetIndex].Pet_Name]
            num = self._dataForPet.allPets[self.selectPetIndex].BasePet_GrowCost[2][lv]
            haveNum = SL:GetValue(TITEMCOUNT, tonumber(xhclData[1]))
            FGUI:GTextField_setText(itemNum, num)
        else
            -- 未激活状态
            num = 1
            haveNum = SL:GetValue(TITEMCOUNT, self._dataForPet.allPets[self.selectPetIndex].Pet_ACTIVE)
            FGUI:GTextField_setText(itemNum, 1)
            FGUI:Controller_setSelectedIndex(activeCont, 0)
        end
        -- 设置数量颜色
        if haveNum >= tonumber(num) then
            FGUI:GTextField_setColor(itemNum, "#00FF00")
            FGUI:GTextField_setColor(fuhao, "#00FF00")
        else
            FGUI:GTextField_setColor(itemNum, "#ff0000")
            FGUI:GTextField_setColor(fuhao, "#ff0000")
        end
        jhid = self._dataForPet.allPets[self.selectPetIndex].Pet_ACTIVE
    end
    -- 创建物品显示
    local itemData = {}
    if isActive == 0 then
        -- 未激活
        itemData = SL:GetValue("ITEM_DATA", tonumber(jhid)) 
    else
        -- 已激活
        itemData = SL:GetValue("ITEM_DATA", tonumber(xhclData[1])) 
    end
    if which == 0 then
        -- 本体
        local extData = {}
        extData.hideTip = false -- 是否隐藏默认的Tip
        extData.itemTipData = itemData -- table类型，对应ItemTips.ShowTip传入的参数
        extData.clickCallback = false -- 单击事件回调
        extData.doubleClickCallback = false -- 双击事件回调
        extData.bgVisible = true -- 背景隐藏
        ItemUtil:ItemShow_Create(itemData, iconItem, extData)
    else
        if isActive == 0 then
            local extData = {}
            extData.hideTip = false -- 是否隐藏默认的Tip
            extData.itemTipData = itemData -- table类型，对应ItemTips.ShowTip传入的参数
            extData.clickCallback = false -- 单击事件回调
            extData.doubleClickCallback = false -- 双击事件回调
            extData.bgVisible = true -- 背景隐藏
            ItemUtil:ItemShow_Create(itemData, iconItem, extData)
        end
    end
end
-- 设置宠物选中状态
function mountMain:setPetSelect()
    -- 重置所有选中状态
    local itemList = FGUI:GetChildren(self._ui.petsList)
    for i = 1, #itemList do
        local controller = FGUI:getController(itemList[i], "isSelect")
        FGUI:Controller_setSelectedIndex(controller, 0)
        if i == self.selectPetIndex then
             FGUI:Controller_setSelectedIndex(controller, 1)
        end
    end
end

-- 初始化坐骑数据显示
function mountMain:initMountData()
    local title = FGUI:GetChild(self._ui.qhbtn, "title")
    local sjtitle = FGUI:GetChild(self._ui.shengjizuoqi, "n1")
    if self._dataForMount.isJh == 0 then
        FGUI:setVisible(self._ui.qhbtn, false)
        FGUI:GTextField_setText(sjtitle, "激活")
    else
        FGUI:setVisible(self._ui.qhbtn, true)
        FGUI:GTextField_setText(sjtitle, "升阶")
        if self._dataForMount.ischuzhan == STATUS.FIGHT then 
            FGUI:GTextField_setText(title, "出战")
        else
            FGUI:GTextField_setText(title, "休息")
        end
    end
end
-- 初始化坐骑数据
function mountMain:InitData()
    -- 判断是坐骑还是幻化标签
    if self.topTab == TAB_TYPE.MOUNT then
        -- 坐骑标签
        self:initMountTab()
    else
        -- 幻化标签
        self:initHuanhuaTab()
    end
    self:setXHCL()
end
-- 初始化坐骑标签
function mountMain:initMountTab()
    -- 获取当前坐骑总阶数 10阶1星
    if self._dataForMount.allJieshu > 0 then
        local sjtitle = FGUI:GetChild(self._ui.shengjizuoqi, "n1")
        local title = FGUI:GetChild(self._ui.qhbtn, "title")
        FGUI:setVisible(self._ui.qhbtn, true)
        FGUI:GTextField_setText(sjtitle, "升阶")
        if self._dataForMount.ischuzhan == STATUS.FIGHT then 
            FGUI:GTextField_setText(title, "出战")
        else
            FGUI:GTextField_setText(title, "休息")
        end
    end
    -- 设置模型ID
    self.modelId = self._dataForMount.modelId
    -- 加载视图
    self:updateView()
    self:setMountDQZQSx(self._dataForMount.allJieshu)
    self:setMountXJZQSx(self._dataForMount.allJieshu)
    -- 绑定出战按钮事件
    FGUI:setOnClickEvent(self._ui.qhbtn, function() 
        self._data:chuzhan()
    end)
    -- 绑定升级按钮事件
    FGUI:setOnClickEvent(self._ui.shengjizuoqi, function() 
        self._data:shengji()
    end)
    -- 更新主标题
    self:updateMainTitle()
end
-- 更新主标题
function mountMain:updateMainTitle()
    local nowName = "乌龙驹"
    -- 判断当前标签类型
    if self.topTab == TAB_TYPE.MOUNT_HH then
        nowName = self._dataForMount.hhSortList[self.nowIndex + 1].Name
    end
    FGUI:GTextField_setText(self._ui.mountName, nowName)
end
-- 初始化幻化标签
function mountMain:initHuanhuaTab()
    self.leftList = self._ui.leftList
    self.nowIndex = FGUI:GList_getSelectedIndex(self.leftList)
    if self.nowIndex < 0 then
        self.nowIndex = 0
    end
    self:updateMainTitle()
    -- 获取排序后的幻化列表
    self.modelId = self._dataForMount.hhSortList[self.nowIndex + 1].Model
    -- 设置幻化属性
    self:setMountHHSx()
    -- 设置列表渲染
    self:setupHuanhuaList()
    -- 绑定幻化按钮事件
    FGUI:setOnClickEvent(self._ui.huanhua, function() 
        -- ssrMessage:sendmsgEx("mountMain", "setModel", {mountId = self.modelId})
        self._data:setModel({mountId = self.modelId})
    end)
    -- 更新模型和按钮状态
    self:updateModel()
    self:setHHAddBtn()
    self:UpdateHHBtnName()
end
-- 设置幻化激活/升级按钮
function mountMain:setHHAddBtn()
    local text = "激活"
    FGUI:setVisible(self._ui.huanhua, false)
    local itemLabel = FGUI:GetChild(self._ui.n60, "n1")
    local results = {}
    local nowName = self._dataForMount.hhSortList[self.nowIndex + 1].Name
    -- 收集同名的幻化配置
    for i = 1, #MountHuanhua do
        if MountHuanhua[i].Name == nowName then
            results[#results + 1] = MountHuanhua[i] 
        end
    end
    -- 判断是否已激活
    if self._dataForMount.hhlistsj[nowName] and self._dataForMount.hhlistsj[nowName] > 0 then
        FGUI:setVisible(self._ui.huanhua, true)
        text = "升级"
        -- 判断是否已满级
        if self._dataForMount.hhlistsj[nowName] == #results then
            text = "已满级"
        end
    end
    -- 设置按钮文本
    FGUI:GTextField_setText(itemLabel, text)
end
-- 设置幻化列表渲染
function mountMain:setupHuanhuaList()
    FGUI:GList_itemRenderer(self._ui.leftList, function(idx, item)
        local itemData = self._dataForMount.hhSortList[idx+1]
        local controller = FGUI:getController(item, "checked")
        local controller2 = FGUI:getController(item, "isActivation")
        FGUI:Controller_setSelectedIndex(controller, 0)
        FGUI:Controller_setSelectedIndex(controller2, 0)
        if idx == self.nowIndex then
            FGUI:Controller_setSelectedIndex(controller, 1)
        end
        -- 设置图标
        local obj = FGUI:GetChild(item, "avatar")
        FGUI:GLoader_setUrl(obj, "ui://Mount/" .. itemData.mount_icon)
        -- 设置激活状态
        if self._dataForMount.hhlistsj[itemData.Name] and self._dataForMount.hhlistsj[itemData.Name] > 0 then
            -- 已经激活过了显示升级
            FGUI:Controller_setSelectedIndex(controller2, 1)
        end
        FGUI:setOnClickEvent(item, function()
            self.nowIndex = idx
            -- 更新名称和属性
            FGUI:GTextField_setText(self._ui.mountName, itemData.Name)
            self:setMountHHSx()
            self:SelectedHH()
            -- 更新模型和按钮状态
            self:updateModel()
            self:setXHCL()
            self:UpdateHHBtnName()
            self:setHHAddBtn()
        end)
    end)
    FGUI:GList_setNumItems(self.leftList, #self._dataForMount.hhSortList)
    -- 绑定激活/升级按钮事件
    FGUI:setOnClickEvent(self._ui.n60, function()
        self:onHuanhuaActivateOrUpgrade()
    end)
end
-- 幻化激活或升级
function mountMain:onHuanhuaActivateOrUpgrade()
    local sendData = {}
    local jhhhlist = {}
    local yijihuocishu = 0
    local selectData = self._dataForMount.hhSortList[self.nowIndex+1]
    -- 获取当前激活次数
    if self._dataForMount.hhlistsj[selectData.Name] and self._dataForMount.hhlistsj[selectData.Name] > 0 then
        yijihuocishu = self._dataForMount.hhlistsj[selectData.Name]
    end
    -- 收集同名的幻化配置
    for i = 1, #MountHuanhua do
        if MountHuanhua[i].Name == selectData.Name then
            jhhhlist[#jhhhlist + 1] = MountHuanhua[i]
        end
    end
    -- 判断是否已满级
    if yijihuocishu == #jhhhlist then
        -- 已满级
        return
    else
        -- 发送激活/升级请求
        sendData.idx = selectData.ID
        sendData.Name = selectData.Name
        sendData.grade = jhhhlist[yijihuocishu + 1].grade
        sendData.ClassID = jhhhlist[yijihuocishu + 1].ClassID
        sendData.Cost = jhhhlist[yijihuocishu + 1].Cost
        self._data:todoHHlist(sendData)
    end
end
-- 选择幻化项
function mountMain:SelectedHH()
    -- 重置所有选中状态
    local itemList = FGUI:GetChildren(self.leftList)
    for i = 1, #itemList do
        local controller = FGUI:getController(itemList[i], "checked")
        FGUI:Controller_setSelectedIndex(controller, 0)
        if self.nowIndex == i-1 then
            FGUI:Controller_setSelectedIndex(controller, 1)
        end
    end
    -- 更新模型
    self:updateModel()
end
-- 更新幻化按钮名称
function mountMain:UpdateHHBtnName()
    local title = FGUI:GetChild(self._ui.huanhua, "title")
    local thisName = self._dataForMount.hhSortList[self.nowIndex + 1].Name
    local nowGrade = 1
    if self._dataForMount.hhlistsj[thisName] then
        nowGrade = self._dataForMount.hhlistsj[thisName]
    end
    -- 查找对应的模型ID
    -- local thisMountId = self._dataForMount.hhSortList[self.nowIndex + 1].Model
    for w = 1, #MountHuanhua do
        if MountHuanhua[w].Name == thisName and MountHuanhua[w].grade == nowGrade then
            thisMountId = MountHuanhua[w].Model
        end
    end
    -- 设置按钮文本
    if thisMountId == self._dataForMount.mountHHid then
        FGUI:GTextField_setText(title, "取消幻化")
    else
        FGUI:GTextField_setText(title, "幻化")
    end
end
-- 更新坐骑视图
function mountMain:updateView()
    -- 计算阶数和星星数量
    local jieshu = math.floor(self._dataForMount.allJieshu / 10)
    local liang = self._dataForMount.allJieshu % 10
    -- 特殊情况处理：10星进1阶
    if liang == 0 and jieshu > 0 then
        liang = 10
        jieshu = jieshu - 1
    end
    -- 设置阶数文本
    FGUI:GTextField_setText(self.jieshuName["bigLevel"], NUMBER_TO_CHINESE[jieshu + 1])
    -- 设置星星显示
    for i = 0, 9 do
        local item = FGUI:GetChildAt(self._ui.xxshu, i)
        local controller = FGUI:getController(item, "checked")
        if i <= liang - 1 then
            -- 亮起来 
            FGUI:Controller_setSelectedIndex(controller, 1)
        else
            FGUI:Controller_setSelectedIndex(controller, 0)
        end
    end
    -- 更新模型和属性
    self.modelId = Mount[self._dataForMount.allJieshu].Model
    self:updateModel()
    self:setMountDQZQSx(tonumber(data))
    self:setMountXJZQSx(tonumber(data))
    
    -- 判断是否已满级
    if self._dataForMount.allJieshu == #Mount then
        local itemLabel = FGUI:GetChild(self._ui.shengjizuoqi, "n1")
        FGUI:GTextField_setText(itemLabel, "已满级")
    end
end
-- 设置坐骑幻化属性
function mountMain:setMountHHSx()
    -- 获取排序后的列表和当前选中的幻化项
    local allNamesObj = {}
    local name = self._dataForMount.hhSortList[self.nowIndex + 1].Name
    -- 收集同名的幻化配置
    for i = 1, #MountHuanhua do
        if MountHuanhua[i].Name == name then
            allNamesObj[#allNamesObj + 1] = MountHuanhua[i]
        end
    end
    -- 获取当前等级
    local nowGrade = 1
    if self._dataForMount.hhlistsj[name] then
        nowGrade = self._dataForMount.hhlistsj[name]
    end
    -- 设置属性和模型
    local sx = allNamesObj[nowGrade].ClassID
    self.modelId = allNamesObj[nowGrade].Model
    -- 设置BUFF描述
    local hhbuffTextHeight = 26 * #sx + 5
    local hhbuffs = allNamesObj[nowGrade].BuffID
    local buffText = ""
    if allNamesObj[nowGrade].BuffDesc then
        buffText = allNamesObj[nowGrade].BuffDesc
    end
    FGUI:GTextField_setAutoSize(self.huanhuaAttr.buffText, 2)
    FGUI:setPosition(self.huanhuaAttr.buffText, 15, hhbuffTextHeight)
    FGUI:GTextField_setText(self.huanhuaAttr.buffText, buffText)
    -- 渲染属性列表
    FGUI:GList_itemRenderer(self.huanhuaAttr["sxlist"], function(index, item)
        local label = AttScoreNames[sx[index + 1][1]].Name .. ":"
        local value = sx[index + 1][2]
        local itemLabel = FGUI:GetChild(item, "label")
        local itemValue = FGUI:GetChild(item, "zhi")
        FGUI:GTextField_setText(itemLabel, label)
        FGUI:GTextField_setText(itemValue, value)
    end)
    FGUI:GList_setNumItems(self.huanhuaAttr["sxlist"], #sx)
end
-- 设置当前坐骑属性
function mountMain:setMountDQZQSx()
    local stars = tonumber(self._dataForMount.allJieshu)
    local result = {}
    if stars > 0 then
        local classIds = Mount[stars].ClassID
        -- 格式化属性数据
        for b = 1, #classIds do
            table.insert(result, {tonumber(classIds[b][1]), tonumber(classIds[b][2])})
        end
        -- 渲染属性列表
        FGUI:GList_itemRenderer(self.currentMountAttr["n15"], function(index, item)
            local label = AttScoreNames[result[index + 1][1]].Name .. ":"
            local value = result[index + 1][2]
            local itemLabel = FGUI:GetChild(item, "label")
            local itemValue = FGUI:GetChild(item, "zhi")
            FGUI:GTextField_setText(itemLabel, label)
            FGUI:GTextField_setText(itemValue, value)
        end)
        FGUI:GList_setNumItems(self.currentMountAttr["n15"], #result)
    end
end
-- 设置下级坐骑属性
function mountMain:setMountXJZQSx()
    stars = tonumber(self._dataForMount.allJieshu) + 1
    -- 防止越界
    if stars > #Mount then
        stars = #Mount
    end
    local result = {}
    local classIds = Mount[stars].ClassID
    -- 格式化属性数据
    for b = 1, #classIds do
        table.insert(result, {tonumber(classIds[b][1]), tonumber(classIds[b][2])})
    end
    -- 渲染属性列表
    FGUI:GList_itemRenderer(self.nextMountAttr["n15"], function(index, item)
        local label = AttScoreNames[result[index + 1][1]].Name .. ":"
        local value = result[index + 1][2]
        local itemLabel = FGUI:GetChild(item, "label")
        local itemValue = FGUI:GetChild(item, "zhi")
        FGUI:GTextField_setText(itemLabel, label)
        FGUI:GTextField_setText(itemValue, value)
    end)
    FGUI:GList_setNumItems(self.nextMountAttr["n15"], #result)
end
-- 更新模型
function mountMain:updateModel()
    -- 清除旧模型
    FGUI:UIModel_clear(self.mountBody)
    -- 添加新模型
    self._modelIndex = FGUI:UIModel_addLegoModel(
        self.mountBody, 
        self.modelId, 
        {x = 0, y = 0, z = 0}, 
        {x = 0, y = 180, z = 0}, 
        {x = 1.1, y = 1.1, z = 1.1}, 
        false
    )
    FGUI:UIModel_setObjectEulerAngles(self.mountBody, 0, 0, 0, 0)
    -- 设置模型回调
    FGUI:UIModel_setModelCallback(self.mountBody, function(index)
        self:SetModelRotate()
    end)
end
-- 设置模型旋转
function mountMain:SetModelRotate()
    local angleX = 0
    local angleY = 0
    local angleZ = 0
    local beginX = nil
    -- 触摸开始回调
    local beginFunc = function(context)
        beginX = context.inputEvent.x
        angleX, angleY, angleZ = self.mountBody:GetObjectEulerAngles(self._modelIndex)
        FGUI:EventContext_CaptureTouch(context)
    end
    -- 触摸移动回调
    local moveFunc = function(context)
        local distanceMax = 1000
        local distence = context.inputEvent.x - (beginX or 0)
        local angle = angleY - (distence * 360 / distanceMax)
        self.mountBody:SetObjectEulerAngles(0, angle, 0, self._modelIndex)
    end
    -- 触摸结束回调
    local endFunc = function(context)
        angleX = 0
        angleY = 0
        angleZ = 0
    end
    -- 绑定触摸事件
    FGUI:setOnTouchEvent(self.uiTouch, beginFunc, moveFunc, endFunc)
end
-- 设置消耗材料显示
function mountMain:setXHCL()
    local num = 1
    local costs = {}
    local iconItem = FGUI:GetChild(self._ui.xhcl, "iconItem")
    FGUI:setVisible(self._ui.n34, true)
    FGUI:setVisible(self._ui.xhcl, true)
    -- 清除旧图标
    if FGUI:GetChildCount(iconItem) > 0 then
        FGUI:RemoveChildAt(iconItem, 0, true)
    end
    -- 已满级处理
    if self._dataForMount.allJieshu == #Mount and self.topTab == TAB_TYPE.MOUNT then
        FGUI:setVisible(self._ui.n34, false)
        FGUI:setVisible(self._ui.xhcl, false)
        return
    end
    -- 获取消耗材料
    if self.topTab == TAB_TYPE.MOUNT then
        -- 坐骑升星石
        local wz = self._dataForMount.allJieshu + 1
        if wz == 1 then
            wz = 0
        end
        costs = Mount[wz].Cost
    else
        -- 幻化消耗材料
        local results = {}
        local nowName = self._dataForMount.hhSortList[self.nowIndex + 1].Name
        -- 收集同名的幻化配置
        for i = 1, #MountHuanhua do
            if MountHuanhua[i].Name == nowName then
                results[#results + 1] = MountHuanhua[i] 
            end
        end
        -- 计算当前等级
        local nowGrade = 1
        if self._dataForMount.hhlistsj[nowName] then
            nowGrade = self._dataForMount.hhlistsj[nowName] + 1
        end
        -- 防止越界
        if #results < nowGrade then
            FGUI:setVisible(self._ui.n34, false)
            FGUI:setVisible(self._ui.xhcl, false)
            nowGrade = self._dataForMount.hhlistsj[nowName]
        end
        costs = results[nowGrade].Cost
    end
    -- 设置数量和图标
    num = costs[2]
    local itemData = SL:GetValue("ITEM_DATA", tonumber(costs[1])) 
    -- 创建物品显示
    local extData = {}
    extData.hideTip = false -- 是否隐藏默认的Tip
    extData.itemTipData = itemData -- table类型，对应ItemTips.ShowTip传入的参数
    extData.clickCallback = false -- 单击事件回调
    extData.doubleClickCallback = false -- 双击事件回调
    extData.bgVisible = true -- 背景隐藏
    ItemUtil:ItemShow_Create(itemData, iconItem, extData)
    -- 设置数量显示和颜色
    local itemNum = FGUI:GetChild(self._ui.xhcl, "n2")
    local fuhao = FGUI:GetChild(self._ui.xhcl, "n1")
    local haveNum = SL:GetValue(TITEMCOUNT, tonumber(costs[1]))
    FGUI:GTextField_setText(itemNum, num)
    if haveNum >= tonumber(num) then
        FGUI:GTextField_setColor(itemNum, "#00FF00")
        FGUI:GTextField_setColor(fuhao, "#00FF00")
    else
        FGUI:GTextField_setColor(itemNum, "#ff0000")
        FGUI:GTextField_setColor(fuhao, "#ff0000")
    end
end

return mountMain