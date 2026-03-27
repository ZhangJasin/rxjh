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

-- 为配置表添加tips字段
Mount.Tips = "坐骑可以提供移动速度和属性加成。\n通过升级坐骑可以提升属性效果。\n出战坐骑可增强人物战斗力。"
MountHuanhua.Tips = "激活坐骑幻化可以改变坐骑外观，\n同时获得额外的属性加成。\n通过消耗道具激活幻化效果，\n让你的坐骑更加炫酷。"
Pet.Tips = "灵兽可以跟随出战，提供额外属性加成。\n出战灵兽3%的属性转化给人物。"
PetHuanhua.Tips = "激活灵兽幻化可以改变灵兽外观，\n同时获得额外的属性加成。\n通过消耗道具激活幻化效果。"

-- 数字转中文大写
local NUMBER_TO_CHINESE = {"零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"}

-- 常量定义
local TAB_TYPE = {
    MOUNT = 0,    -- 坐骑标签
    MOUNT_HH = 1,  -- 坐骑幻化标签
    -- 注意：灵兽的 topTabList 和 petTopTabList 各自有独立的索引（0,1）
    -- petTopTabList 索引：0=灵兽, 1=幻化
    -- topTabList 索引：0=坐骑, 1=幻化
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
            --灵兽
            self:setPetInfo()
            self:setPetAtta()
            self:setPetBtPetBtn()
            self:setPetXhcl()
        end)
        self._subscriptions.lsLevelResult = self._data:Subscribe("ls_level_result", function(state)
            self._dataForPet = state
            --灵兽
            self:setPetInfo()
            self:setPetAtta()
            self:setPetBtPetBtn()
            self:setPetXhcl()
        end)
        self._subscriptions.lsUpdateModel = self._data:Subscribe("ls_update_model", function(state)
            self._dataForPet = state
            --灵兽
            self:updatePetView()
        end)
        self._subscriptions.lsUnrecallpet = self._data:Subscribe("ls_unrecallpet", function(state)
            self._dataForPet = state
            self:setPetBtPetBtn()
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
        -- 灵兽升级事件
        self._subscriptions.petLevelUp = self._data:Subscribe("petLevelUp", function(state)
            print("=== 客户端收到petLevelUp事件 ===")
            self._dataForPet = state
            print("灵兽等级:", state.allJieshu, "是否激活:", state.isPetJh)
            self:InitPetData()
            self:setPetBtPetBtn()
        end)
        -- 灵兽幻化事件
        self._subscriptions.petUpdateHHResult = self._data:Subscribe("petUpdateHHResult", function(state)
            self._dataForPet = state._dataForPet
            self:initPetHuanhuaTab()
        end)
        -- 灵兽出战/休息事件
        self._subscriptions.petUpdateBtn = self._data:Subscribe("petUpdateBtn", function(state)
            print("=== 收到petUpdateBtn事件 ===")
            print("isPetChuzhan:", state.isPetChuzhan, "isPetJh:", state.isPetJh)
            -- 更新内存数据（注意：Lua中0是falsy，需用nil判断）
            if state.isPetChuzhan ~= nil then self._dataForPet.isPetChuzhan = state.isPetChuzhan end
            if state.isPetJh ~= nil then self._dataForPet.isPetJh = state.isPetJh end
            if state.allJieshu ~= nil then self._dataForPet.allJieshu = state.allJieshu end
            
            -- 刷新按钮状态
            -- isPetChuzhan: 0=出战(显示召回), 1=休息(显示出战)
            local title = FGUI:GetChild(self._ui.petQhbtn, "title")
            if title then
                if self._dataForPet.isPetChuzhan == 0 then
                    FGUI:GTextField_setText(title, "召回")
                else
                    FGUI:GTextField_setText(title, "出战")
                end
            end
            print("按钮状态更新完成")
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
    self.topTab = TAB_TYPE.MOUNT  -- 默认坐骑标签
    self.petTopTab = 0  -- 默认灵兽升阶标签
    self.nowPetHHIndex = 0  -- 初始化灵兽幻化索引
    --默认显示灵兽页面
    self.selectPetIndex = 1 --灵兽默认选择
    -- 坐骑数据初始化并显示
    self:initMountData()
    -- 坐骑显示模型和消耗材料
    if self._dataForMount.isJh == 0 then
        -- 未激活：显示默认模型
        self.modelId = Mount[0] and Mount[0].Model or 800001
        self:updateModel()
        -- 显示激活消耗材料
        if Mount[0] and Mount[0].Cost then
            local costs = Mount[0].Cost
            local iconItem = FGUI:GetChild(self._ui.xhcl, "iconItem")
            -- 清除旧图标
            if FGUI:GetChildCount(iconItem) > 0 then
                FGUI:RemoveChildAt(iconItem, 0, true)
            end
            -- 创建物品显示
            local itemData = SL:GetValue("ITEM_DATA", tonumber(costs[1]))
            local extData = {}
            extData.hideTip = false
            extData.itemTipData = itemData
            extData.clickCallback = false
            extData.doubleClickCallback = false
            extData.bgVisible = true
            ItemUtil:ItemShow_Create(itemData, iconItem, extData)
            -- 设置数量显示和颜色
            local itemNum = FGUI:GetChild(self._ui.xhcl, "n2")
            local fuhao = FGUI:GetChild(self._ui.xhcl, "n1")
            local num = costs[2]
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
        -- 显示下级属性（激活后的属性）
        self:setMountXJZQSx()
    end
    -- 灵兽数据初始化
    self:setPetInfo()
    self:setPetAtta()
    self:setPetBtPetBtn()
    self:setPetXhcl()
    -- self:setPetSelect() -- UI中不存在petsList，暂时注释
    -- 只初始化灵兽页面（确保显示灵兽升阶标签）
    self:initPetTab()
end
function mountMain:Enter(data)
    if data and data.type then
        -- dump(data)
        self.rightTabs = FGUI:getController(self.component, "rightTabs")
        FGUI:Controller_setSelectedIndex(self.rightTabs, tonumber(data.type))
        if data.type == 0  then
            --灵兽
            --直接选中当前出战的
            for w=1,#self._dataForPet.allPets do
                if self._dataForPet.allPets[w].ID == self._dataForPet.selectViewPetId then
                    self.selectPetIndex = w
                end
            end
            -- 更新视图
            self:setPetInfo()
            self:setPetAtta()
            self:setPetBtPetBtn()
            self:setPetXhcl()
        else
            FGUI:Controller_setSelectedIndex(self.rightTabs, 1)
            --坐骑
            if data.name then
                --幻化
                -- 设置列表渲染
                self.topTabs = FGUI:getController(self.component, "topTabs")
                FGUI:Controller_setSelectedIndex(self.topTabs, 1)
                self.topTab = TAB_TYPE.MOUNT_HH
                --幻化
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
                    self._data:setModel({mountId = self.modelId})
                end)
                -- 更新模型和按钮状态
                self:updateModel()
                self:setHHAddBtn()
                self:UpdateHHBtnName()
                self:setXHCL()
            else
                self.topTabs = FGUI:getController(self.component, "topTabs")
                FGUI:Controller_setSelectedIndex(self.topTabs, 0)
                --坐骑
            end 
        end
    end
end
-- 初始化界面UI
function mountMain:initVariables()
    -- 坐骑UI元素引用
    self.topTabList = FGUI:ui_delegate(self._ui.topTabList)   -- 坐骑顶部标签列表
    self.rightTabList = FGUI:ui_delegate(self._ui.rightTabList) -- 右上标签列表
    self.leftList = FGUI:ui_delegate(self._ui.leftList)    -- 坐骑幻化列表
    self.mountBody = FGUI:UIModel_Bind(self._ui.mountBody) -- 坐骑模型
    self.uiTouch = FGUI:GetChild(self.component, "mountModel")
    -- 坐骑UI元素引用
    self.jieshuName = FGUI:ui_delegate(self._ui.jieshu)   -- 坐骑阶数
    self.xxshu = FGUI:ui_delegate(self._ui.xxshu)     -- 坐骑星星数
    self.currentMountAttr = FGUI:ui_delegate(self._ui.nowAttr)  -- 坐骑当前属性
    self.nextMountAttr = FGUI:ui_delegate(self._ui.nextAttr)    -- 坐骑下级属性
    self.huanhuaAttr = FGUI:ui_delegate(self._ui.huanhuaAttr)   -- 坐骑幻化属性

    -- 灵兽UI元素引用（与坐骑结构一致）
    self.petTopTabList = FGUI:ui_delegate(self._ui.petTopTabList)   -- 灵兽顶部标签列表
    self.petBody = FGUI:UIModel_Bind(self._ui.petBody) -- 灵兽模型
    self.petUiTouch = FGUI:GetChild(self.component, "petModel")
    -- 灵兽UI元素引用
    self.petJieshuName = FGUI:ui_delegate(self._ui.petJieshu)   -- 灵兽阶数
    self.petXxshu = FGUI:ui_delegate(self._ui.petxxshu)     -- 灵兽星星数
    self.currentPetAttr = FGUI:ui_delegate(self._ui.petNowAttr)  -- 灵兽当前属性
    self.nextPetAttr = FGUI:ui_delegate(self._ui.petNextAttr)    -- 灵兽下级属性
    self.petHuanhuaAttr = FGUI:ui_delegate(self._ui.petHuanhuaAttr)   -- 灵兽幻化属性

    -- 初始化索引变量
    self.nowPetHHIndex = 0  -- 灵兽幻化当前选中索引

    ---- 以下为tips界面
    self.tipsControlle = FGUI:getController(self.component,"tips")
end
-- 初始化标签和列表
function mountMain:initTabsAndLists()
    -- 设置默认选中标签
    FGUI:GList_setSelectedIndex(self._ui.topTabList, TAB_TYPE.MOUNT)   -- 0坐骑 1幻化
    FGUI:GList_setSelectedIndex(self._ui.rightTabList, 0)               -- 0灵兽 1坐骑
    FGUI:GList_setSelectedIndex(self.leftList, 0)

    -- 灵兽标签
    FGUI:GList_setSelectedIndex(self._ui.petTopTabList, 0)   -- 0灵兽 1幻化
    FGUI:GList_setSelectedIndex(self._ui.petLeftList, 0)
    -- 绑定灵兽相关按钮事件
    self:bindPetButtonsEvents()
end
-- 绑定事件监听
function mountMain:bindEvents()
    -- 坐骑顶部标签切换事件
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

    -- 右侧标签切换事件（灵兽/坐骑）
    FGUI:GList_addOnClickItemEvent(self._ui.rightTabList, function(context)
        local index = FGUI:GList_getSelectedIndex(self._ui.rightTabList)
        print("=== 右侧标签切换 ===")
        print("切换到:", index == 0 and "灵兽" or "坐骑")
        if index == 0 then
            -- 切换到灵兽：固定到灵兽升阶标签
            self.petTopTab = 0
            FGUI:GList_setSelectedIndex(self._ui.petTopTabList, 0)
            self:InitPetData()
        else
            -- 切换到坐骑：固定到坐骑升阶标签
            self.topTab = TAB_TYPE.MOUNT
            FGUI:GList_setSelectedIndex(self._ui.topTabList, TAB_TYPE.MOUNT)
            self:InitData()
        end
    end)

    -- 坐骑出战按钮事件
    FGUI:setOnClickEvent(self._ui.qhbtn, function()
        self._data:chuzhan()
    end)

    -- 坐骑升级按钮事件
    FGUI:setOnClickEvent(self._ui.shengjizuoqi, function()
        print("升级坐骑")
        self._data:shengji()
    end)

    -- 灵兽顶部标签切换事件
    FGUI:GList_addOnClickItemEvent(self._ui.petTopTabList, function(context)
        local index = FGUI:GList_getSelectedIndex(self._ui.petTopTabList)
        if self._dataForPet.isPetJh == 0 and index == 1 then
            -- 未激活时禁止切换到幻化标签
            SL:ShowSystemTips("请先激活灵兽")
            FGUI:GList_setSelectedIndex(self._ui.petTopTabList, 0)
        else
            self.petTopTab = index
            self:InitPetData()
        end
    end)

    ---- 以下为tips界面
    -- 灵兽页面tips按钮 (n110: rightTabs=0, topTabs=0)
    FGUI:setOnClickEvent(self._ui.n110,function()
        local tipsbg = FGUI:ui_delegate(self._ui.n114)
        local tipinfoScro = FGUI:ui_delegate(tipsbg.infoScro)
        FGUI:GTextField_setText(tipsbg.title, "灵兽页面功能说明")
        FGUI:GRichTextField_setText(tipinfoScro['n3'], Pet.Tips)
        FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        FGUI:Controller_setSelectedIndex(self.tipsControlle,1)

        -- 绑定关闭按钮事件
        FGUI:setOnClickEvent(tipsbg.closetips,function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        end)
        FGUI:setOnClickEvent(tipsbg.bg,function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        end)
    end)

    -- 灵兽幻化页面tips按钮 (n111: rightTabs=0, topTabs=1)
    FGUI:setOnClickEvent(self._ui.n111,function()
        local tipsbg = FGUI:ui_delegate(self._ui.n114)
        local tipinfoScro = FGUI:ui_delegate(tipsbg.infoScro)
        FGUI:GTextField_setText(tipsbg.title, "灵兽幻化功能说明")
        FGUI:GRichTextField_setText(tipinfoScro['n3'], PetHuanhua.Tips)
        FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        FGUI:Controller_setSelectedIndex(self.tipsControlle,1)

        -- 绑定关闭按钮事件
        FGUI:setOnClickEvent(tipsbg.closetips,function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        end)
        FGUI:setOnClickEvent(tipsbg.bg,function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        end)
    end)

    -- 坐骑页面tips按钮 (n112: rightTabs=1, topTabs=0)
    FGUI:setOnClickEvent(self._ui.n112,function()
        local tipsbg = FGUI:ui_delegate(self._ui.n114)
        local tipinfoScro = FGUI:ui_delegate(tipsbg.infoScro)
        FGUI:GTextField_setText(tipsbg.title, "坐骑页面功能说明")
        FGUI:GRichTextField_setText(tipinfoScro['n3'], Mount.Tips)
        FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        FGUI:Controller_setSelectedIndex(self.tipsControlle,1)

        -- 绑定关闭按钮事件
        FGUI:setOnClickEvent(tipsbg.closetips,function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        end)
        FGUI:setOnClickEvent(tipsbg.bg,function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        end)
    end)

    -- 坐骑幻化页面tips按钮 (n113: rightTabs=1, topTabs=1)
    FGUI:setOnClickEvent(self._ui.n113,function()
        local tipsbg = FGUI:ui_delegate(self._ui.n114)
        local tipinfoScro = FGUI:ui_delegate(tipsbg.infoScro)
        FGUI:GTextField_setText(tipsbg.title, "坐骑幻化功能说明")
        FGUI:GRichTextField_setText(tipinfoScro['n3'], MountHuanhua.Tips)
        FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        FGUI:Controller_setSelectedIndex(self.tipsControlle,1)

        -- 绑定关闭按钮事件
        FGUI:setOnClickEvent(tipsbg.closetips,function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        end)
        FGUI:setOnClickEvent(tipsbg.bg,function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
        end)
    end)
end

-- ==================== 灵兽相关功能 ====================

-- 初始化灵兽数据
function mountMain:setPetInfo()
    local stars = self._dataForPet.allJieshu
    -- 设置名称
    local petData = Pet[stars] or Pet[0]
    FGUI:GTextField_setText(self._ui.petName, petData.Name or "龙猫")
    -- 设置阶数
    local jieshu = math.floor(stars / 10)
    local liang = stars % 10
    -- 特殊情况处理：10星进1阶
    if liang == 0 and jieshu > 0 then
        liang = 10
        jieshu = jieshu - 1
    end
    FGUI:GTextField_setText(self.petJieshuName["bigLevel"], NUMBER_TO_CHINESE[jieshu + 1])
    -- 设置出战按钮文字
    local title = FGUI:GetChild(self._ui.petQhbtn, "title")
    -- 显示出战或召回状态
    if self._dataForPet.isPetChuzhan == STATUS.FIGHT then
        FGUI:GTextField_setText(title, "出战")
    else
        FGUI:GTextField_setText(title, "召回")
    end
end

-- 设置灵兽属性显示
function mountMain:setPetAtta()
    if self.petTopTab == 0 then
        -- 灵兽本体属性
        self:setPetBTAtta()
    else
        -- 灵兽幻化属性
        self:setPetHHAtta()
    end
end

-- 设置灵兽本体属性
function mountMain:setPetBTAtta()
    local stars = self._dataForPet.allJieshu
    -- 计算下一等级
    local nextStars = stars + 1
    -- 防止越界
    if nextStars > #Pet then
        nextStars = #Pet
    end
    -- 格式化属性数据
    local result1 = {}
    local result2 = {}
    local classIds = Pet[stars] and Pet[stars].ClassID or {}
    local nextClassIds = Pet[nextStars] and Pet[nextStars].ClassID or {}
    for b = 1, #classIds do
        table.insert(result1, {tonumber(classIds[b][1]), tonumber(classIds[b][2])})
    end
    for b = 1, #nextClassIds do
        table.insert(result2, {tonumber(nextClassIds[b][1]), tonumber(nextClassIds[b][2])})
    end
    -- 渲染属性列表
    self:renderAttributeList(self.currentPetAttr["n15"], result1)
    self:renderAttributeList(self.nextPetAttr["n15"], result2)
    -- 设置星星显示
    self:setPetStars(stars)
    -- 设置模型
    local petData = Pet[stars] or Pet[0]
    self:setPetModel(petData.Model, 0, 1.1)
end

-- 设置灵兽幻化属性
function mountMain:setPetHHAtta()
    -- 获取选中的幻化数据
    local hhIndex = FGUI:GList_getSelectedIndex(self._ui.petLeftList)
    if hhIndex < 0 then
        hhIndex = 0
    end
    self.nowPetHHIndex = hhIndex
    -- 设置幻化属性
    self:setPetHHSx()
end

-- 设置灵兽当前属性
function mountMain:setPetDQZQSx(stars)
    local result = {}
    if stars and stars > 0 then
        local classIds = Pet[stars] and Pet[stars].ClassID or {}
        -- 格式化属性数据
        for b = 1, #classIds do
            table.insert(result, {tonumber(classIds[b][1]), tonumber(classIds[b][2])})
        end
    end
    -- 渲染属性列表
    self:renderAttributeList(self.currentPetAttr["n15"], result)
end

-- 设置灵兽下级属性
function mountMain:setPetXJZQSx(stars)
    local nextStars = (stars or 0) + 1
    -- 防止越界
    if nextStars > #Pet then
        nextStars = #Pet
    end
    local result = {}
    local classIds = Pet[nextStars] and Pet[nextStars].ClassID or {}
    -- 格式化属性数据
    for b = 1, #classIds do
        table.insert(result, {tonumber(classIds[b][1]), tonumber(classIds[b][2])})
    end
    -- 渲染属性列表
    self:renderAttributeList(self.nextPetAttr["n15"], result)
end

-- 设置灵兽星星显示
function mountMain:setPetStars(lv)
    for i = 0, 9 do
        local item = FGUI:GetChildAt(self._ui.petxxshu, i)
        if item then
            local controller = FGUI:getController(item, "checked")
            if i < lv then
                FGUI:Controller_setSelectedIndex(controller, 1)
            else
                FGUI:Controller_setSelectedIndex(controller, 0)
            end
        end
    end
end

-- 设置灵兽模型
function mountMain:setPetModel(modelId, offsetY, scale)
    print("=== setPetModel 函数被调用 ===")
    print("modelId:", modelId, "offsetY:", offsetY, "scale:", scale)
    print("petBody:", self.petBody)
    if not self.petBody then
        print("错误: petBody 为空!")
        return
    end
    FGUI:UIModel_clear(self.petBody)
    self._petModelIndex = FGUI:UIModel_addLegoModel(
        self.petBody, 
        modelId, 
        {x = 0, y = offsetY or 0, z = 0}, 
        {x = 0, y = 180, z = 0}, 
        {x = scale or 1, y = scale or 1, z = scale or 1}, 
        false
    )
    print("模型添加完成, index:", self._petModelIndex)
    FGUI:UIModel_setObjectEulerAngles(self.petBody, 0, 0, 0, 0)
    -- 设置模型回调
    FGUI:UIModel_setModelCallback(self.petBody, function(index)
        self:SetPetModelRotate()
    end)
end

-- 设置灵兽模型旋转
function mountMain:SetPetModelRotate()
    local angleX = 0
    local angleY = 0
    local angleZ = 0
    local beginX = nil
    -- 触摸开始回调
    local beginFunc = function(context)
        beginX = context.inputEvent.x
        angleX, angleY, angleZ = self.petBody:GetObjectEulerAngles(self._petModelIndex)
        FGUI:EventContext_CaptureTouch(context)
    end
    -- 触摸移动回调
    local moveFunc = function(context)
        local distanceMax = 1000
        local distence = context.inputEvent.x - (beginX or 0)
        local angle = angleY - (distence * 360 / distanceMax)
        self.petBody:SetObjectEulerAngles(0, angle, 0, self._petModelIndex)
    end
    -- 触摸结束回调
    local endFunc = function(context)
        angleX = 0
        angleY = 0
        angleZ = 0
    end
    -- 绑定触摸事件
    FGUI:setOnTouchEvent(self.petUiTouch, beginFunc, moveFunc, endFunc)
end

-- 设置本体宠物按钮状态
function mountMain:setPetBtPetBtn()
    local title = FGUI:GetChild(self._ui.petQhbtn, "title")
    -- 根据激活状态控制显示
    if self._dataForPet.isPetJh == 0 then
        -- 未激活
        FGUI:setVisible(self._ui.petQhbtn, false)
    else
        -- 已激活
        FGUI:setVisible(self._ui.petQhbtn, true)
        -- 显示出战或召回状态
        -- 服务端逻辑：isPetChuzhan=0表示出战，isPetChuzhan=1表示休息
        -- 出战状态显示"召回"按钮，休息状态显示"出战"按钮
        if self._dataForPet.isPetChuzhan == 0 then
            FGUI:GTextField_setText(title, "召回")
        else
            FGUI:GTextField_setText(title, "出战")
        end
    end
end

-- 设置宠物消耗材料
function mountMain:setPetXhcl()
    print("=== setPetXhcl 开始 ===")
    print("当前等级:", self._dataForPet.allJieshu, "标签页:", self.petTopTab)

    local num = 1
    local costs = {}
    local iconItem = FGUI:GetChild(self._ui.petXhcl, "iconItem")
    FGUI:setVisible(self._ui.n85, true)
    FGUI:setVisible(self._ui.petXhcl, true)
    -- 清除旧图标
    if FGUI:GetChildCount(iconItem) > 0 then
        FGUI:RemoveChildAt(iconItem, 0, true)
    end
    -- 已满级处理
    if self._dataForPet.allJieshu == #Pet and self.petTopTab == 0 then
        FGUI:setVisible(self._ui.n85, false)
        FGUI:setVisible(self._ui.petXhcl, false)
        print("已满级")
        return
    end
    -- 获取消耗材料
    if self.petTopTab == 0 then
        -- 灵兽升星石
        local wz = self._dataForPet.allJieshu + 1
        if wz == 1 then
            wz = 0
        end
        costs = Pet[wz].Cost
        print("消耗材料配置索引:", wz, "Cost:", costs and costs[1], costs[2])
    else
        -- 幻化消耗材料
        -- 安全检查：确保 hhSortList 不为空
        if not self._dataForPet.hhSortList or #self._dataForPet.hhSortList == 0 then
            FGUI:setVisible(self._ui.n85, false)
            FGUI:setVisible(self._ui.petXhcl, false)
            print("幻化列表为空")
            return
        end

        -- 确保 nowPetHHIndex 在有效范围内
        if self.nowPetHHIndex < 0 then
            self.nowPetHHIndex = 0
        end
        if self.nowPetHHIndex >= #self._dataForPet.hhSortList then
            self.nowPetHHIndex = #self._dataForPet.hhSortList - 1
        end

        local results = {}
        local nowName = self._dataForPet.hhSortList[self.nowPetHHIndex + 1].Name
        print("当前幻化名称:", nowName)
        -- 收集同名的幻化配置
        for i = 1, #PetHuanhua do
            if PetHuanhua[i].Name == nowName then
                results[#results + 1] = PetHuanhua[i]
            end
        end
        print("收集到", #results, "个同名幻化配置")
        -- 计算当前等级
        local nowGrade = 1
        if self._dataForPet.hhlistsj[nowName] then
            nowGrade = self._dataForPet.hhlistsj[nowName] + 1
            print("已激活等级:", self._dataForPet.hhlistsj[nowName], "下一等级:", nowGrade)
        end
        -- 防止越界
        if #results < nowGrade or #results == 0 then
            FGUI:setVisible(self._ui.n85, false)
            FGUI:setVisible(self._ui.petXhcl, false)
            nowGrade = self._dataForPet.hhlistsj[nowName]
            if not nowGrade then
                print("幻化等级配置无效")
                return
            end
            costs = results[nowGrade].Cost
        else
            costs = results[nowGrade].Cost
            print("使用配置等级:", nowGrade, "Cost:", costs[1], costs[2])
        end
    end
    -- 设置数量和图标
    num = costs[2]
    local itemData = SL:GetValue("ITEM_DATA", tonumber(costs[1]))
    print("物品ID:", costs[1], "需要数量:", num, "物品数据:", itemData)
    -- 创建物品显示
    local extData = {}
    extData.hideTip = false -- 是否隐藏默认的Tip
    extData.itemTipData = itemData -- table类型，对应ItemTips.ShowTip传入的参数
    extData.clickCallback = false -- 单击事件回调
    extData.doubleClickCallback = false -- 双击事件回调
    extData.bgVisible = true -- 背景隐藏
    ItemUtil:ItemShow_Create(itemData, iconItem, extData)
    -- 设置数量显示和颜色
    local itemNum = FGUI:GetChild(self._ui.petXhcl, "n2")
    local fuhao = FGUI:GetChild(self._ui.petXhcl, "n1")
    local haveNum = SL:GetValue(TITEMCOUNT, tonumber(costs[1]))
    FGUI:GTextField_setText(itemNum, num)
    if haveNum >= tonumber(num) then
        FGUI:GTextField_setColor(itemNum, "#00FF00")
        FGUI:GTextField_setColor(fuhao, "#00FF00")
    else
        FGUI:GTextField_setColor(itemNum, "#ff0000")
        FGUI:GTextField_setColor(fuhao, "#ff0000")
    end
    print("=== setPetXhcl 完成 ===")
end

-- 设置宠物选中状态（暂未使用，UI中不存在petsList）
--[[
function mountMain:setPetSelect()
    -- 重置所有选中状态
    local itemList = FGUI:GetChildren(self._ui.petsList)
    for i = 1, #itemList do
        local controller = FGUI:getController(itemList[i], "isSelect")
        FGUI:Controller_setSelectedIndex(controller, 0)
        if (i-1) == self._dataForPet.allJieshu then
             FGUI:Controller_setSelectedIndex(controller, 1)
        end
    end
end
]]

-- 更新灵兽视图
function mountMain:updatePetView()
    print("=== updatePetView 被调用 ===")
    print("showPetModelId:", self._dataForPet.showPetModelId)
    -- 优先使用服务端返回的showPetModelId（幻化后的模型）
    if self._dataForPet.showPetModelId and self._dataForPet.showPetModelId > 0 then
        self.modelId = self._dataForPet.showPetModelId
        print("updatePetView: 使用服务端模型ID:", self.modelId)
        self:setPetModel(self.modelId, 0, 1.1)
    end
    self:setPetInfo()
    self:setPetAtta()
    self:setPetXhcl()
end

-- 绑定灵兽相关按钮事件
function mountMain:bindPetButtonsEvents()
    -- 出战按钮事件
    FGUI:setOnClickEvent(self._ui.petQhbtn, function()
        print("点击出战/召回按钮")
        -- 发送服务端请求，由服务端返回消息更新UI
        self._data:petChuzhan()
    end)

    -- 幻化按钮事件
    FGUI:setOnClickEvent(self._ui.petHuanhua, function()
        self._data:setPetModel({mountId = self.modelId})
    end)

    -- 激活/升阶按钮事件
    FGUI:setOnClickEvent(self._ui.shengjilingshou, function()
        print("升级灵兽")
        if self.petTopTab == 0 then
            -- 灵兽本体
            if self._dataForPet.isPetJh == 0 then
                -- 首次激活
                print("首次激活灵兽")
                if Pet[1] and Pet[1].Cost then
                    self._data:lsjihuo({itemId = Pet[1].Cost[1]})
                else
                    print("Pet[1]配置不存在或缺少Cost字段")
                end
            else
                -- 已激活，进行升阶
                print("灵兽升阶,当前等级:", self._dataForPet.allJieshu)
                local nextLevel = self._dataForPet.allJieshu + 1
                if Pet[nextLevel] and Pet[nextLevel].Cost then
                    self._data:levelUp({
                        name = Pet[nextLevel].Name or "灵兽",
                        maxLv = #Pet,
                        num = Pet[nextLevel].Cost[2] or 1,
                        itemId = Pet[nextLevel].Cost[1] or 0
                    })
                else
                    print("下一级配置不存在或已达到最高级")
                end
            end
        else
            -- 灵兽幻化
            self:onPetHuanhuaActivateOrUpgrade()
        end
    end)
end

-- 初始化灵兽数据
function mountMain:InitPetData()
    if self.petTopTab == 0 then
        -- 灵兽标签
        self:initPetTab()
    else
        -- 幻化标签
        self:initPetHuanhuaTab()
    end
    self:setPetXhcl()
end

-- 初始化灵兽标签
function mountMain:initPetTab()
    print("=== initPetTab 开始 ===")
    print("是否激活:", self._dataForPet.isPetJh)
    print("当前等级:", self._dataForPet.allJieshu)
    print("出战状态:", self._dataForPet.isPetChuzhan)

    local title = FGUI:GetChild(self._ui.shengjilingshou, "n1")
    -- 判断是否已激活
    if self._dataForPet.isPetJh == 0 then
        -- 未激活状态
        FGUI:setVisible(self._ui.petQhbtn, false)
        FGUI:GTextField_setText(title, "激活")
    else
        -- 已激活状态
        FGUI:setVisible(self._ui.petQhbtn, true)
        FGUI:GTextField_setText(title, "升阶")
        local petQhbtnTitle = FGUI:GetChild(self._ui.petQhbtn, "title")
        -- 显示出战或召回状态
        if self._dataForPet.isPetChuzhan == STATUS.FIGHT then
            FGUI:GTextField_setText(petQhbtnTitle, "出战")
        else
            FGUI:GTextField_setText(petQhbtnTitle, "召回")
        end
    end
    -- 设置模型ID
    self.modelId = Pet[self._dataForPet.allJieshu] and Pet[self._dataForPet.allJieshu].Model or Pet[0].Model
    print("模型ID:", self.modelId, "Pet数据:", Pet[self._dataForPet.allJieshu] and Pet[self._dataForPet.allJieshu])
    -- 更新模型
    if self.modelId then
        self:setPetModel(self.modelId, 0, 1.1)
        print("模型设置完成")
    end
    -- 加载视图
    self:setPetDQZQSx(self._dataForPet.allJieshu)
    self:setPetXJZQSx(self._dataForPet.allJieshu)
    -- 设置灵兽名称和阶数
    self:setPetInfo()
    print("=== initPetTab 完成 ===")
end

-- 初始化灵兽幻化标签
function mountMain:initPetHuanhuaTab()
    print("=== initPetHuanhuaTab 开始 ===")
    self.nowPetHHIndex = FGUI:GList_getSelectedIndex(self._ui.petLeftList)
    if self.nowPetHHIndex < 0 then
        self.nowPetHHIndex = 0
    end
    self:updatePetMainTitle()
    -- 获取排序后的幻化列表
    print("幻化列表数量:", self._dataForPet.hhSortList and #self._dataForPet.hhSortList or 0)
    if self._dataForPet.hhSortList and #self._dataForPet.hhSortList > 0 then
        self.modelId = self._dataForPet.hhSortList[self.nowPetHHIndex + 1].Model
        print("当前选中模型ID:", self.modelId)
    end
    -- 设置幻化属性
    self:setPetHHSx()
    -- 设置列表渲染
    self:setupPetHuanhuaList()
    -- 绑定幻化按钮事件
    FGUI:setOnClickEvent(self._ui.petHuanhua, function()
        self._data:setPetModel({mountId = self.modelId})
    end)
    -- 更新模型和按钮状态
    if self.modelId then
        self:setPetModel(self.modelId, 0, 1.1)
        print("幻化模型设置完成")
    end
    self:setPetHHAddBtn()
    self:UpdatePetHHBtnName()
    self:setPetXhcl()
    -- 注意：不调用setPetInfo，因为幻化标签的名字由updatePetMainTitle处理
    print("=== initPetHuanhuaTab 完成 ===")
end

-- 更新灵兽主标题
function mountMain:updatePetMainTitle()
    local nowName = "龙猫"
    if self._dataForPet.allJieshu > 0 then
        local petData = Pet[self._dataForPet.allJieshu]
        if petData then
            nowName = petData.Name
        end
    end
    -- 判断当前标签类型
    if self.petTopTab == 1 then
        if self._dataForPet.hhSortList and #self._dataForPet.hhSortList > 0 then
            nowName = self._dataForPet.hhSortList[self.nowPetHHIndex + 1].Name
        end
    end
    FGUI:GTextField_setText(self._ui.petName, nowName)
end

-- 设置灵兽幻化属性
function mountMain:setPetHHSx()
    -- 获取排序后的列表和当前选中的幻化项
    if not self._dataForPet.hhSortList or #self._dataForPet.hhSortList == 0 then
        return
    end

    local allNamesObj = {}
    local name = self._dataForPet.hhSortList[self.nowPetHHIndex + 1].Name
    -- 收集同名的幻化配置
    for i = 1, #PetHuanhua do
        if PetHuanhua[i].Name == name then
            allNamesObj[#allNamesObj + 1] = PetHuanhua[i]
        end
    end
    -- 获取当前等级
    local nowGrade = 1
    if self._dataForPet.hhlistsj[name] then
        nowGrade = self._dataForPet.hhlistsj[name]
    end
    -- 防止越界
    if nowGrade > #allNamesObj then
        nowGrade = #allNamesObj
    end
    -- 设置属性和模型
    local sx = allNamesObj[nowGrade].ClassID
    self.modelId = allNamesObj[nowGrade].Model
    -- 设置BUFF描述
    local hhbuffTextHeight = 26 * #sx + 5
    local buffText = ""
    if allNamesObj[nowGrade].BuffDesc then
        buffText = allNamesObj[nowGrade].BuffDesc
    end
    FGUI:GTextField_setAutoSize(self.petHuanhuaAttr.buffText, 2)
    FGUI:setPosition(self.petHuanhuaAttr.buffText, 15, hhbuffTextHeight)
    FGUI:GTextField_setText(self.petHuanhuaAttr.buffText, buffText)
    -- 渲染属性列表
    FGUI:GList_itemRenderer(self.petHuanhuaAttr["sxlist"], function(index, item)
        local label = AttScoreNames[sx[index + 1][1]].Name .. ":"
        local value = sx[index + 1][2]
        local itemLabel = FGUI:GetChild(item, "label")
        local itemValue = FGUI:GetChild(item, "zhi")
        FGUI:GTextField_setText(itemLabel, label)
        FGUI:GTextField_setText(itemValue, value)
    end)
    FGUI:GList_setNumItems(self.petHuanhuaAttr["sxlist"], #sx)
end

-- 设置灵兽幻化列表渲染
function mountMain:setupPetHuanhuaList()
    FGUI:GList_itemRenderer(self._ui.petLeftList, function(idx, item)
        if not self._dataForPet.hhSortList or #self._dataForPet.hhSortList == 0 then
            return
        end
        local itemData = self._dataForPet.hhSortList[idx+1]
        local controller = FGUI:getController(item, "checked")
        local controller2 = FGUI:getController(item, "isActivation")
        FGUI:Controller_setSelectedIndex(controller, 0)
        FGUI:Controller_setSelectedIndex(controller2, 0)
        if idx == self.nowPetHHIndex then
            FGUI:Controller_setSelectedIndex(controller, 1)
        end
        -- 设置图标
        local obj = FGUI:GetChild(item, "avatar")
        FGUI:GLoader_setUrl(obj, "ui://Mount/" .. itemData.mount_icon)
        -- 设置激活状态
        if self._dataForPet.hhlistsj[itemData.Name] and self._dataForPet.hhlistsj[itemData.Name] > 0 then
            -- 已经激活过了显示升级
            FGUI:Controller_setSelectedIndex(controller2, 1)
        end
        FGUI:setOnClickEvent(item, function()
            print("=== 点击灵兽幻化列表项 ===")
            print("索引:", idx, "名称:", itemData.Name)
            self.nowPetHHIndex = idx
            -- 更新模型ID
            self.modelId = itemData.Model
            print("新模型ID:", self.modelId)
            -- 更新模型显示
            self:setPetModel(self.modelId, 0, 1.1)
            -- 更新名称和属性
            FGUI:GTextField_setText(self._ui.petName, itemData.Name)
            self:setPetHHSx()
            self:UpdatePetHHBtnName()
            self:setPetXhcl()
            self:setPetHHAddBtn()
        end)
    end)
    if self._dataForPet.hhSortList then
        FGUI:GList_setNumItems(self._ui.petLeftList, #self._dataForPet.hhSortList)
    end
    -- 绑定激活/升级按钮事件
    FGUI:setOnClickEvent(self._ui.petActiveBtn, function()
        self:onPetHuanhuaActivateOrUpgrade()
    end)
end

-- 灵兽幻化激活或升级
function mountMain:onPetHuanhuaActivateOrUpgrade()
    -- 安全检查
    if not self._dataForPet.hhSortList or #self._dataForPet.hhSortList == 0 then
        return
    end
    
    local sendData = {}
    local jhhhlist = {}
    local yijihuocishu = 0
    local selectData = self._dataForPet.hhSortList[self.nowPetHHIndex + 1]
    
    if not selectData then
        return
    end
    
    -- 获取当前激活次数
    if self._dataForPet.hhlistsj[selectData.Name] and self._dataForPet.hhlistsj[selectData.Name] > 0 then
        yijihuocishu = self._dataForPet.hhlistsj[selectData.Name]
    end
    -- 收集同名的幻化配置
    for i = 1, #PetHuanhua do
        if PetHuanhua[i].Name == selectData.Name then
            jhhhlist[#jhhhlist + 1] = PetHuanhua[i]
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
        self._data:petTodoHHlist(sendData)
    end
end

-- 设置灵兽幻化激活/升级按钮
function mountMain:setPetHHAddBtn()
    local text = "激活"
    FGUI:setVisible(self._ui.petHuanhua, false)
    local itemLabel = FGUI:GetChild(self._ui.petActiveBtn, "n1")

    if not self._dataForPet.hhSortList or #self._dataForPet.hhSortList == 0 then
        FGUI:GTextField_setText(itemLabel, text)
        return
    end

    local results = {}
    local nowName = self._dataForPet.hhSortList[self.nowPetHHIndex + 1].Name
    -- 收集同名的幻化配置
    for i = 1, #PetHuanhua do
        if PetHuanhua[i].Name == nowName then
            results[#results + 1] = PetHuanhua[i]
        end
    end
    -- 判断是否已激活
    if self._dataForPet.hhlistsj[nowName] and self._dataForPet.hhlistsj[nowName] > 0 then
        FGUI:setVisible(self._ui.petHuanhua, true)
        text = "升级"
        -- 判断是否已满级
        if self._dataForPet.hhlistsj[nowName] == #results then
            text = "已满级"
        end
    end
    -- 设置按钮文本
    FGUI:GTextField_setText(itemLabel, text)
end

-- 更新灵兽幻化按钮名称
function mountMain:UpdatePetHHBtnName()
    local title = FGUI:GetChild(self._ui.petHuanhua, "title")

    if not self._dataForPet.hhSortList or #self._dataForPet.hhSortList == 0 then
        return
    end

    local thisName = self._dataForPet.hhSortList[self.nowPetHHIndex + 1].Name
    local nowGrade = 1
    if self._dataForPet.hhlistsj[thisName] then
        nowGrade = self._dataForPet.hhlistsj[thisName]
    end
    -- 查找对应的模型ID
    local thisPetId = 0
    for w = 1, #PetHuanhua do
        if PetHuanhua[w].Name == thisName and PetHuanhua[w].grade == nowGrade then
            thisPetId = PetHuanhua[w].Model
        end
    end
    -- 设置按钮文本
    if thisPetId == self._dataForPet.petHHid then
        FGUI:GTextField_setText(title, "取消幻化")
    else
        FGUI:GTextField_setText(title, "幻化")
    end
end

-- ==================== 坐骑相关功能 ====================

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
    -- 更新主标题
    self:updateMainTitle()
end

-- 更新主标题
function mountMain:updateMainTitle()
    local nowName = "乌龙驹"
    -- 判断当前标签类型
    if self.topTab == TAB_TYPE.MOUNT_HH then
        -- 安全检查:确保幻化列表不为空且索引有效
        if self._dataForMount.hhSortList and #self._dataForMount.hhSortList > 0 then
            local idx = self.nowIndex + 1
            if idx >= 1 and idx <= #self._dataForMount.hhSortList then
                nowName = self._dataForMount.hhSortList[idx].Name
            end
        else
            nowName = "暂无幻化"
        end
    end
    FGUI:GTextField_setText(self._ui.mountName, nowName)
end

-- 初始化幻化标签
function mountMain:initHuanhuaTab()
    print("=== initHuanhuaTab 开始 ===")
    
    -- 从数据管理器重新获取最新数据,确保切换标签时有正确数据
    self._dataForMount = self._data:GetDataForMount()
    
    print("坐骑幻化列表数量:", self._dataForMount.hhSortList and #self._dataForMount.hhSortList or 0)
    
    self.leftList = self._ui.leftList
    self.nowIndex = FGUI:GList_getSelectedIndex(self.leftList)
    if self.nowIndex < 0 then
        self.nowIndex = 0
    end
    
    -- 检查幻化列表是否为空
    if not self._dataForMount.hhSortList or #self._dataForMount.hhSortList == 0 then
        print("坐骑幻化列表为空，不更新显示")
        -- 隐藏幻化相关的UI
        FGUI:setVisible(self._ui.huanhuaAttr, false)
        FGUI:setVisible(self._ui.huanhua, false)
        FGUI:setVisible(self._ui.n60, false)
        FGUI:GTextField_setText(self._ui.mountName, "暂无幻化")
        print("=== initHuanhuaTab 完成（无数据） ===")
        return
    end
    
    -- 显示幻化相关UI
    FGUI:setVisible(self._ui.huanhuaAttr, true)
    FGUI:setVisible(self._ui.huanhua, true)
    FGUI:setVisible(self._ui.n60, true)
    
    -- 确保索引在有效范围内
    if self.nowIndex >= #self._dataForMount.hhSortList then
        self.nowIndex = 0
    end
    
    print("当前索引:", self.nowIndex)
    
    self:updateMainTitle()
    -- 获取排序后的幻化列表
    self.modelId = self._dataForMount.hhSortList[self.nowIndex + 1].Model
    print("模型ID:", self.modelId)
    -- 设置幻化属性
    self:setMountHHSx()
    -- 设置列表渲染
    self:setupHuanhuaList()
    -- 绑定幻化按钮事件
    FGUI:setOnClickEvent(self._ui.huanhua, function() 
        self._data:setModel({mountId = self.modelId})
    end)
    -- 更新模型和按钮状态
    self:updateModel()
    self:setHHAddBtn()
    self:UpdateHHBtnName()
    
    print("=== initHuanhuaTab 完成 ===")
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
    self:setMountDQZQSx()
    self:setMountXJZQSx()

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
    end
    -- 渲染属性列表
    self:renderAttributeList(self.currentMountAttr["n15"], result)
end

-- 设置下级坐骑属性
function mountMain:setMountXJZQSx()
    local stars = tonumber(self._dataForMount.allJieshu) + 1
    -- 防止越界
    if stars > #Mount then
        stars = #Mount
    end
    -- 未激活状态下，显示激活后的属性（Mount[1]）
    if self._dataForMount.isJh == 0 then
        stars = 1
    end
    local result = {}
    local classIds = Mount[stars].ClassID
    -- 格式化属性数据
    for b = 1, #classIds do
        table.insert(result, {tonumber(classIds[b][1]), tonumber(classIds[b][2])})
    end
    -- 渲染属性列表
    self:renderAttributeList(self.nextMountAttr["n15"], result)
end

-- 渲染属性列表（通用方法）
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
