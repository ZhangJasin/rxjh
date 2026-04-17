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

-- 灵兽属性转化比例配置表（按等级阶梯）
-- 格式：{minLevel, maxLevel, rate}  表示 minLevel-maxLevel 等级段使用 rate 转化比例
local PetLevelRateConfig = {
    { 1,   10,  0.03 }, -- 1-10级 3%
    { 11,  20,  0.04 }, -- 11-20级 4%
    { 21,  30,  0.05 }, -- 21-30级 5%
    { 31,  40,  0.06 }, -- 31-40级 6%
    { 41,  50,  0.08 }, -- 41-50级 8%
    { 51,  60,  0.10 }, -- 51-60级 10%
    { 61,  70,  0.12 }, -- 61-70级 12%
    { 71,  80,  0.15 }, -- 71-80级 15%
    { 81,  90,  0.18 }, -- 81-90级 18%
    { 91,  100, 0.21 }, -- 91-100级 21%
    { 101, 110, 0.25 }, -- 101-110级 25%
}

-- 根据等级获取转化比例
local function getPetAttrRateByLevel(level)
    for _, config in ipairs(PetLevelRateConfig) do
        if level >= config[1] and level <= config[2] then
            return config[3]
        end
    end
    -- 默认返回最低档比例
    return PetLevelRateConfig[1][3]
end

-- 点击冷却表（开源节流功能）
local _clickCooldown = {
    petQhbtn = 0,     -- 灵兽出战/召回按钮
    qhbtn = 0,        -- 坐骑切换按钮
    huanhua = 0,      -- 坐骑幻化按钮
    petHuanhua = 0,   -- 灵兽幻化按钮
}
local _CLICK_INTERVAL = 500 -- 500ms点击间隔

-- 检查按钮是否在冷却中，返回true表示可以点击
local function checkCooldown(btnName)
    local now = os.time() * 1000 -- 毫秒
    if now - _clickCooldown[btnName] < _CLICK_INTERVAL then
        SL:ShowSystemTips("请勿操作频繁")
        return false
    end
    _clickCooldown[btnName] = now
    return true
end

-- 从配置表读取tips字段
local function getTipsFromConfig(config)
    if not config then return "" end
    for _, v in pairs(config) do
        if v.tips and v.tips ~= "" then
            return v.tips
        end
    end
    return ""
end
Mount.Tips = getTipsFromConfig(Mount)
MountHuanhua.Tips = getTipsFromConfig(MountHuanhua)
Pet.Tips = getTipsFromConfig(Pet)
PetHuanhua.Tips = getTipsFromConfig(PetHuanhua)

-- 数字转中文大写
local NUMBER_TO_CHINESE = { "零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十" }

-- 常量定义
local TAB_TYPE = {
    MOUNT = 0,    -- 坐骑标签
    MOUNT_HH = 1, -- 坐骑幻化标签
    -- 注意：灵兽的 topTabList 和 petTopTabList 各自有独立的索引（0,1）
    -- petTopTabList 索引：0=灵兽, 1=幻化
    -- topTabList 索引：0=坐骑, 1=幻化
}

local STATUS = {
    FIGHT = 0, -- 出战状态
    REST = 1   -- 休息状态
}

-- 需要显示为百分比的属性ID配置表（属性值会缩小100后显示，如 500 -> 5%）
-- 格式：{[属性ID] = true} 或 {[属性ID] = 除数}，如果需要不同的缩放比例
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
    [9] = true,
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
            -- 更新幻化图标n117
            self:UpdatePetHHIcon()
            -- 刷新模型显示
            self:refreshPetModel()
        end)
        self._subscriptions.lsLevelResult = self._data:Subscribe("ls_level_result", function(state)
            self._dataForPet = state
            --灵兽
            self:setPetInfo()
            self:setPetAtta()
            self:setPetBtPetBtn()
            self:setPetXhcl()
            -- 刷新模型显示
            self:refreshPetModel()
        end)
        self._subscriptions.lsUpdateModel = self._data:Subscribe("ls_update_model", function(state)
            self._dataForPet = state
            --灵兽
            self:updatePetView()
            -- 刷新模型显示，确保幻化模型正确显示
            self:refreshPetModel()
        end)
        self._subscriptions.lsUnrecallpet = self._data:Subscribe("ls_unrecallpet", function(state)
            self._dataForPet = state
            self:setPetBtPetBtn()
        end)
        self._subscriptions.updateHHResult = self._data:Subscribe("updateHHResult", function(state)
            -- dump(state)
            self._dataForMount = state._dataForMount
            -- 保留当前选中的索引（用户正在操作的幻化），不要被服务端返回值覆盖
            -- self.nowIndex = state.selectHHIndex - 1
            -- 确保索引有效
            local listSize = #self._dataForMount.hhSortList
            if self.nowIndex and self.nowIndex >= 0 and self.nowIndex < listSize then
                -- 保持当前索引不变
            else
                self.nowIndex = 0
            end
            FGUI:GList_setNumItems(self.leftList, listSize)
            -- 更新视图
            self:setMountHHSx()
            self:setXHCL()
            self:setHHAddBtn()
            self:updateModel()
            self:UpdateHHBtnName()
            -- 更新n118控件的level控制器（幻化升级后需要刷新等级显示）
            self:UpdateMountHHIcon()
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
            -- 更新灵兽属性幻化百分比n107（升级后等级变化需要刷新）
            self:UpdatePetAttrRate()
        end)
        -- 灵兽幻化事件
        self._subscriptions.petUpdateHHResult = self._data:Subscribe("petUpdateHHResult", function(state)
            self._dataForPet = state._dataForPet
            -- 同步更新选中索引
            self.nowPetHHIndex = state.selectHHIndex - 1
            if self.nowPetHHIndex < 0 then
                self.nowPetHHIndex = 0
            end
            -- 同步更新列表选中状态
            FGUI:GList_setSelectedIndex(self._ui.petLeftList, self.nowPetHHIndex)
            -- 重新设置列表渲染器和数量（确保点击事件正确绑定）
            self:setupPetHuanhuaList()
            -- 刷新当前选中项的视图
            self:setPetHHSx()
            self:setPetXhcl()
            self:setPetHHAddBtn()
            self:UpdatePetHHBtnName()
            -- 更新n117控件的level控制器（幻化升级后需要刷新等级显示）
            self:UpdatePetHHIcon()
            -- 更新灵兽属性幻化百分比n107（根据等级同步服务端配置）
            self:UpdatePetAttrRate()
        end)
        -- 灵兽幻化切换结果（服务端返回）
        self._subscriptions.petUpdateModelResult = self._data:Subscribe("updatePetModelResult", function(state)
            print("=== 收到updatePetModelResult事件 ===")
            self._dataForPet.showPetModelId = state.showPetModelId
            self._dataForPet.petHHid = state.petHHid
            self._dataForPet.hhSortList = self._data:setPetHHListSort()
            -- 刷新列表
            FGUI:GList_setNumItems(self._ui.petLeftList, #self._dataForPet.hhSortList)
            -- 刷新视图
            self:setPetHHSx()
            self:setPetXhcl()
            self:setPetHHAddBtn()
            self:setPetModel(state.showPetModelId, 0, 1.1)
            self:UpdatePetHHBtnName()
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
            -- isPetChuzhan: 0=休息(显示"出战"按钮), 1=出战(显示"召回"按钮)
            local title = FGUI:GetChild(self._ui.petQhbtn, "title")
            if title then
                if self._dataForPet.isPetChuzhan == 1 then
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
    self.topTab = TAB_TYPE.MOUNT -- 默认坐骑标签
    self.petTopTab = 0           -- 默认灵兽升阶标签
    self.nowPetHHIndex = 0       -- 初始化灵兽幻化索引
    --默认显示灵兽页面
    self.selectPetIndex = 1      --灵兽默认选择
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
                FGUI:GTextField_setColor(itemNum, "#00f900")
                FGUI:GTextField_setColor(fuhao, "#00f900")
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
        if data.type == 0 then
            --灵兽
            --直接选中当前出战的
            for w = 1, #self._dataForPet.allPets do
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
                for i = 1, #results do
                    if results[i].Name == data.name then
                        self.nowIndex = i - 1
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
                -- 绑定幻化按钮事件（500ms冷却）
                FGUI:setOnClickEvent(self._ui.huanhua, function()
                    if not checkCooldown("huanhua") then return end
                    self._data:setModel({ mountId = self.modelId })
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
    self.topTabList = FGUI:ui_delegate(self._ui.topTabList)     -- 坐骑顶部标签列表
    self.rightTabList = FGUI:ui_delegate(self._ui.rightTabList) -- 右上标签列表
    self.leftList = FGUI:ui_delegate(self._ui.leftList)         -- 坐骑幻化列表
    self.mountBody = FGUI:UIModel_Bind(self._ui.mountBody)      -- 坐骑模型
    self.uiTouch = FGUI:GetChild(self.component, "mountModel")
    -- 坐骑UI元素引用
    self.jieshuName = FGUI:ui_delegate(self._ui.jieshu)        -- 坐骑阶数
    self.xxshu = FGUI:ui_delegate(self._ui.xxshu)              -- 坐骑星星数
    self.currentMountAttr = FGUI:ui_delegate(self._ui.nowAttr) -- 坐骑当前属性
    self.nextMountAttr = FGUI:ui_delegate(self._ui.nextAttr)   -- 坐骑下级属性
    self.huanhuaAttr = FGUI:ui_delegate(self._ui.huanhuaAttr)  -- 坐骑幻化属性

    -- 灵兽UI元素引用（与坐骑结构一致）
    self.petTopTabList = FGUI:ui_delegate(self._ui.petTopTabList) -- 灵兽顶部标签列表
    self.petBody = FGUI:UIModel_Bind(self._ui.petBody)            -- 灵兽模型
    self.petUiTouch = FGUI:GetChild(self.component, "petModel")
    -- 灵兽UI元素引用
    self.petJieshuName = FGUI:ui_delegate(self._ui.petJieshu)       -- 灵兽阶数
    self.petXxshu = FGUI:ui_delegate(self._ui.petxxshu)             -- 灵兽星星数
    self.currentPetAttr = FGUI:ui_delegate(self._ui.petNowAttr)     -- 灵兽当前属性
    self.nextPetAttr = FGUI:ui_delegate(self._ui.petNextAttr)       -- 灵兽下级属性
    self.petHuanhuaAttr = FGUI:ui_delegate(self._ui.petHuanhuaAttr) -- 灵兽幻化属性

    -- 初始化索引变量
    self.nowPetHHIndex = 0 -- 灵兽幻化当前选中索引

    ---- 以下为tips界面
    self.tipsControlle = FGUI:getController(self.component, "tips")

    --适配pc端UI
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    if isPC then
        FGUI:setScale(self.component, 0.75, 0.75)
        FGUI:setPosition(self.component, screenW / 2, screenH / 2)
        FGUI:setAnchorPoint(self.component, 0.5, 0.5, true)
        -- PC端动态调整rightTabList位置，确保在屏幕内
        local listX, listY = FGUI:getPosition(self._ui.rightTabList)
        local listW, listH = FGUI:getSize(self._ui.rightTabList)
        local scaledRightEdge = (listX + listW) * 0.75
        if scaledRightEdge > screenW then
            local offset = scaledRightEdge - screenW
            local newX = listX - offset - 10
            FGUI:setPosition(self._ui.rightTabList, newX, listY)
            --print("PC端调整rightTabList位置: 原X=" .. listX .. ", 新X=" .. newX)
        end
    end
end

-- 初始化标签和列表
function mountMain:initTabsAndLists()
    -- 设置默认选中标签
    FGUI:GList_setSelectedIndex(self._ui.topTabList, TAB_TYPE.MOUNT) -- 0坐骑 1幻化
    FGUI:GList_setSelectedIndex(self._ui.rightTabList, 0)            -- 0灵兽 1坐骑
    FGUI:GList_setSelectedIndex(self.leftList, 0)

    -- 灵兽标签
    FGUI:GList_setSelectedIndex(self._ui.petTopTabList, 0) -- 0灵兽 1幻化
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

    -- 坐骑出战按钮事件（500ms冷却）
    FGUI:setOnClickEvent(self._ui.qhbtn, function()
        if not checkCooldown("qhbtn") then return end
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
    FGUI:setOnClickEvent(self._ui.n110, function()
        local tipsbg = FGUI:ui_delegate(self._ui.n114)
        local tipinfoScro = FGUI:ui_delegate(tipsbg.infoScro)
        FGUI:GTextField_setText(tipsbg.title, "灵兽页面功能说明")
        FGUI:GRichTextField_setText(tipinfoScro['n3'], Pet.Tips)
        FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
        FGUI:Controller_setSelectedIndex(self.tipsControlle, 1)

        -- 绑定关闭按钮事件
        FGUI:setOnClickEvent(tipsbg.closetips, function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
        end)
        FGUI:setOnClickEvent(tipsbg.bg, function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
        end)
    end)

    -- 灵兽幻化页面tips按钮 (n111: rightTabs=0, topTabs=1)
    FGUI:setOnClickEvent(self._ui.n111, function()
        local tipsbg = FGUI:ui_delegate(self._ui.n114)
        local tipinfoScro = FGUI:ui_delegate(tipsbg.infoScro)
        FGUI:GTextField_setText(tipsbg.title, "灵兽幻化功能说明")
        FGUI:GRichTextField_setText(tipinfoScro['n3'], PetHuanhua.Tips)
        FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
        FGUI:Controller_setSelectedIndex(self.tipsControlle, 1)

        -- 绑定关闭按钮事件
        FGUI:setOnClickEvent(tipsbg.closetips, function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
        end)
        FGUI:setOnClickEvent(tipsbg.bg, function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
        end)
    end)

    -- 坐骑页面tips按钮 (n112: rightTabs=1, topTabs=0)
    FGUI:setOnClickEvent(self._ui.n112, function()
        local tipsbg = FGUI:ui_delegate(self._ui.n114)
        local tipinfoScro = FGUI:ui_delegate(tipsbg.infoScro)
        FGUI:GTextField_setText(tipsbg.title, "坐骑页面功能说明")
        FGUI:GRichTextField_setText(tipinfoScro['n3'], Mount.Tips)
        FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
        FGUI:Controller_setSelectedIndex(self.tipsControlle, 1)

        -- 绑定关闭按钮事件
        FGUI:setOnClickEvent(tipsbg.closetips, function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
        end)
        FGUI:setOnClickEvent(tipsbg.bg, function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
        end)
    end)

    -- 坐骑幻化页面tips按钮 (n113: rightTabs=1, topTabs=1)
    FGUI:setOnClickEvent(self._ui.n113, function()
        local tipsbg = FGUI:ui_delegate(self._ui.n114)
        local tipinfoScro = FGUI:ui_delegate(tipsbg.infoScro)
        FGUI:GTextField_setText(tipsbg.title, "坐骑幻化功能说明")
        FGUI:GRichTextField_setText(tipinfoScro['n3'], MountHuanhua.Tips)
        FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
        FGUI:Controller_setSelectedIndex(self.tipsControlle, 1)

        -- 绑定关闭按钮事件
        FGUI:setOnClickEvent(tipsbg.closetips, function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
        end)
        FGUI:setOnClickEvent(tipsbg.bg, function()
            FGUI:Controller_setSelectedIndex(self.tipsControlle, 0)
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
    -- 判断是否已满级（与坐骑对齐）
    if self._dataForPet.allJieshu == #Pet then
        -- 设置升级按钮文本为"已满级"
        local itemLabel = FGUI:GetChild(self._ui.shengjilingshou, "n1")
        if itemLabel then
            FGUI:GTextField_setText(itemLabel, "已满级")
        end
        -- 隐藏消耗文本n104（与坐骑的n34对齐）
        FGUI:setVisible(self._ui.n104, false)
    else
        -- 非满级时显示消耗文本
        FGUI:setVisible(self._ui.n104, true)
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
        table.insert(result1, { tonumber(classIds[b][1]), tonumber(classIds[b][2]) })
    end
    for b = 1, #nextClassIds do
        table.insert(result2, { tonumber(nextClassIds[b][1]), tonumber(nextClassIds[b][2]) })
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
            table.insert(result, { tonumber(classIds[b][1]), tonumber(classIds[b][2]) })
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
        table.insert(result, { tonumber(classIds[b][1]), tonumber(classIds[b][2]) })
    end
    -- 渲染属性列表
    self:renderAttributeList(self.nextPetAttr["n15"], result)
end

-- 设置灵兽星星显示
function mountMain:setPetStars(stars)
    -- 计算阶数和星星数量（与坐骑一致）
    local jieshu = math.floor(stars / 10)
    local liang = stars % 10
    -- 特殊情况处理：10星进1阶
    if liang == 0 and jieshu > 0 then
        liang = 10
        jieshu = jieshu - 1
    end
    -- 设置星星显示（与坐骑一致：i <= liang - 1 亮起）
    for i = 0, 9 do
        local item = FGUI:GetChildAt(self._ui.petxxshu, i)
        if item then
            local controller = FGUI:getController(item, "checked")
            if i <= liang - 1 then
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
        { x = 0, y = offsetY or 0, z = 0 },
        { x = 0, y = 180, z = 0 },
        { x = scale or 1, y = scale or 1, z = scale or 1 },
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
        -- isPetChuzhan: 0=休息(显示"出战"按钮), 1=出战(显示"召回"按钮)
        if self._dataForPet.isPetChuzhan == 1 then
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

    local costs = {}
    local iconItem = FGUI:GetChild(self._ui.petXhcl, "iconItem")
    local iconItem2 = FGUI:GetChild(self._ui.petXhcl, "iconItem2") -- 第二个消耗图标
    FGUI:setVisible(self._ui.n85, true)
    FGUI:setVisible(self._ui.petXhcl, true)
    FGUI:setVisible(self._ui.n104, true) -- 非满级时默认显示消耗文本

    -- 保存默认位置用于切换
    if not self._petXhclDefaultPos then
        self._petXhclDefaultPos = {FGUI:getPosition(self._ui.petXhcl)}
        self._n104DefaultPos = {FGUI:getPosition(self._ui.n104)}
    end
    -- 清除旧图标
    if FGUI:GetChildCount(iconItem) > 0 then
        FGUI:RemoveChildAt(iconItem, 0, true)
    end
    if iconItem2 and FGUI:GetChildCount(iconItem2) > 0 then
        FGUI:RemoveChildAt(iconItem2, 0, true)
    end
    -- 已满级处理
    if self._dataForPet.allJieshu == #Pet and self.petTopTab == 0 then
        FGUI:setVisible(self._ui.n85, false)
        FGUI:setVisible(self._ui.petXhcl, false)
        FGUI:setVisible(self._ui.n104, false) -- 与坐骑n34对齐，满级隐藏消耗文本
        print("已满级")
        return
    end
    -- 获取消耗材料
    if self.petTopTab == 0 then
        -- 灵兽升星石
        -- allJieshu = 0 表示未激活，显示 Pet[0].Cost (激活消耗)
        -- allJieshu >= 1 表示已激活，显示 Pet[allJieshu].Cost (当前等级升下一级的消耗)
        local wz = self._dataForPet.allJieshu
        costs = Pet[wz].Cost
        print("消耗材料配置索引:", wz, "当前等级:", self._dataForPet.allJieshu, "Cost:", costs)
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
            print("使用配置等级:", nowGrade, "Cost:", costs)
        end
    end

    -- 检查是否是多重消耗格式
    local isMultiCost = (type(costs[1]) == "table")

    if isMultiCost then
        -- 多重消耗格式：{[1] = {[1] = itemId, [2] = num}, [2] = {[1] = itemId, [2] = num}}
        print("检测到多重消耗，共", #costs, "个材料")

        -- 设置到默认位置
        if self._petXhclDefaultPos then
            FGUI:setPosition(self._ui.petXhcl, self._petXhclDefaultPos[1], self._petXhclDefaultPos[2])
            FGUI:setPosition(self._ui.n104, self._n104DefaultPos[1], self._n104DefaultPos[2])
        end

        -- 显示第二个消耗（如果存在）
        if #costs >= 2 and iconItem2 then
            local cost2 = costs[2]
            local itemId2 = tonumber(cost2[1])
            local num2 = tonumber(cost2[2])
            local itemData2 = SL:GetValue("ITEM_DATA", itemId2)
            print("第二个物品ID:", itemId2, "需要数量:", num2, "物品数据:", itemData2)

            -- 创建物品显示
            local extData2 = {}
            extData2.hideTip = false
            extData2.itemTipData = itemData2
            extData2.clickCallback = false
            extData2.doubleClickCallback = false
            extData2.bgVisible = true
            ItemUtil:ItemShow_Create(itemData2, iconItem2, extData2)

            -- 设置数量显示和颜色
            local itemNum2 = FGUI:GetChild(self._ui.petXhcl, "n4") -- 第二个消耗数量
            local fuhao2 = FGUI:GetChild(self._ui.petXhcl, "n3")   -- 第二个消耗符号
            if itemNum2 then
                local haveNum2 = SL:GetValue(TITEMCOUNT, itemId2)
                FGUI:GTextField_setText(itemNum2, num2)
                if haveNum2 >= num2 then
                    FGUI:GTextField_setColor(itemNum2, "#00f900")
                    if fuhao2 then FGUI:GTextField_setColor(fuhao2, "#00f900") end
                else
                    FGUI:GTextField_setColor(itemNum2, "#ff0000")
                    if fuhao2 then FGUI:GTextField_setColor(fuhao2, "#ff0000") end
                end
                FGUI:setVisible(itemNum2, true)
                if fuhao2 then FGUI:setVisible(fuhao2, true) end
            end
            FGUI:setVisible(iconItem2, true)
        end

        -- 设置第一个消耗
        local cost1 = costs[1]
        local itemId1 = tonumber(cost1[1])
        local num1 = tonumber(cost1[2])
        local itemData1 = SL:GetValue("ITEM_DATA", itemId1)
        print("第一个物品ID:", itemId1, "需要数量:", num1, "物品数据:", itemData1)

        -- 创建物品显示
        local extData1 = {}
        extData1.hideTip = false
        extData1.itemTipData = itemData1
        extData1.clickCallback = false
        extData1.doubleClickCallback = false
        extData1.bgVisible = true
        ItemUtil:ItemShow_Create(itemData1, iconItem, extData1)

        -- 设置数量显示和颜色
        local itemNum = FGUI:GetChild(self._ui.petXhcl, "n2")
        local fuhao = FGUI:GetChild(self._ui.petXhcl, "n1")
        local haveNum = SL:GetValue(TITEMCOUNT, itemId1)
        FGUI:GTextField_setText(itemNum, num1)
        if haveNum >= num1 then
            FGUI:GTextField_setColor(itemNum, "#00f900")
            FGUI:GTextField_setColor(fuhao, "#00f900")
        else
            FGUI:GTextField_setColor(itemNum, "#ff0000")
            FGUI:GTextField_setColor(fuhao, "#ff0000")
        end
    else
        -- 单消耗格式（兼容旧数据）
        -- 隐藏第二个消耗
        if iconItem2 then FGUI:setVisible(iconItem2, false) end
        local itemNum2 = FGUI:GetChild(self._ui.petXhcl, "n4")
        local fuhao2 = FGUI:GetChild(self._ui.petXhcl, "n3")
        if itemNum2 then FGUI:setVisible(itemNum2, false) end
        if fuhao2 then FGUI:setVisible(fuhao2, false) end

        -- 设置第一个消耗
        local num = costs[2]
        local itemId = tonumber(costs[1])
        local itemData = SL:GetValue("ITEM_DATA", itemId)
        print("物品ID:", itemId, "需要数量:", num, "物品数据:", itemData)

        -- 创建物品显示
        local extData = {}
        extData.hideTip = false
        extData.itemTipData = itemData
        extData.clickCallback = false
        extData.doubleClickCallback = false
        extData.bgVisible = true
        ItemUtil:ItemShow_Create(itemData, iconItem, extData)

        -- 设置数量显示和颜色
        local itemNum = FGUI:GetChild(self._ui.petXhcl, "n2")
        local fuhao = FGUI:GetChild(self._ui.petXhcl, "n1")
        local haveNum = SL:GetValue(TITEMCOUNT, itemId)
        FGUI:GTextField_setText(itemNum, num)
        if haveNum >= tonumber(num) then
            FGUI:GTextField_setColor(itemNum, "#00f900")
            FGUI:GTextField_setColor(fuhao, "#00f900")
        else
            FGUI:GTextField_setColor(itemNum, "#ff0000")
            FGUI:GTextField_setColor(fuhao, "#ff0000")
        end

        -- 单一材料时，控件右移50
        if self._petXhclDefaultPos then
            FGUI:setPosition(self._ui.petXhcl, self._petXhclDefaultPos[1] + 50, self._petXhclDefaultPos[2])
            FGUI:setPosition(self._ui.n104, self._n104DefaultPos[1] + 50, self._n104DefaultPos[2])
        end
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
    print("allJieshu:", self._dataForPet.allJieshu)
    print("modelId:", self._dataForPet.modelId)
    print("isPetChuzhan:", self._dataForPet.isPetChuzhan)

    -- 灵兽模型独立更新，不受坐骑出战状态影响
    -- 优先使用服务端返回的showPetModelId（幻化后的模型）
    if self._dataForPet.showPetModelId and self._dataForPet.showPetModelId > 0 then
        self.modelId = self._dataForPet.showPetModelId
        print("updatePetView: 使用幻化模型ID:", self.modelId)
    else
        -- 使用基础模型
        self.modelId = self._dataForPet.modelId or
        (Pet[self._dataForPet.allJieshu] and Pet[self._dataForPet.allJieshu].Model) or 800001
        print("updatePetView: 使用基础模型ID:", self.modelId)
    end
    if self.modelId then
        self:setPetModel(self.modelId, 0, 1.1)
    end
    self:setPetInfo()
    self:setPetAtta()
    self:setPetXhcl()
end

-- 绑定灵兽相关按钮事件
function mountMain:bindPetButtonsEvents()
    -- 出战按钮事件（500ms冷却）
    FGUI:setOnClickEvent(self._ui.petQhbtn, function()
        if not checkCooldown("petQhbtn") then return end
        print("点击出战/召回按钮")
        -- 发送服务端请求，由服务端返回消息更新UI
        self._data:petChuzhan()
    end)

    -- 幻化按钮事件（500ms冷却）
    FGUI:setOnClickEvent(self._ui.petHuanhua, function()
        if not checkCooldown("petHuanhua") then return end
        self._data:setPetModel({ mountId = self.modelId })
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
                    local costs = Pet[1].Cost
                    local isMultiCost = (type(costs[1]) == "table")

                    if isMultiCost then
                        -- 多重消耗：传递完整的消耗数组
                        self._data:lsjihuo({ costs = costs })
                    else
                        -- 单消耗格式（兼容旧数据）
                        self._data:lsjihuo({ itemId = costs[1] })
                    end
                else
                    print("Pet[1]配置不存在或缺少Cost字段")
                end
            else
                -- 已激活，进行升阶
                print("灵兽升阶,当前等级:", self._dataForPet.allJieshu)
                local nextLevel = self._dataForPet.allJieshu + 1
                if Pet[nextLevel] and Pet[nextLevel].Cost then
                    local costs = Pet[nextLevel].Cost
                    local isMultiCost = (type(costs[1]) == "table")

                    if isMultiCost then
                        -- 多重消耗：传递完整的消耗数组
                        self._data:levelUp({
                            name = Pet[nextLevel].Name or "灵兽",
                            maxLv = #Pet,
                            costs = costs -- 传递完整的消耗数组
                        })
                    else
                        -- 单消耗格式（兼容旧数据）
                        self._data:levelUp({
                            name = Pet[nextLevel].Name or "灵兽",
                            maxLv = #Pet,
                            num = costs[2] or 1,
                            itemId = costs[1] or 0
                        })
                    end
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
        -- isPetChuzhan: 0=休息(显示"出战"按钮), 1=出战(显示"召回"按钮)
        if self._dataForPet.isPetChuzhan == 1 then
            FGUI:GTextField_setText(petQhbtnTitle, "召回")
        else
            FGUI:GTextField_setText(petQhbtnTitle, "出战")
        end
    end
    -- 设置模型ID：如果有幻化模型ID则使用幻化模型，否则使用基础模型
    if self._dataForPet.showPetModelId and self._dataForPet.showPetModelId > 0 then
        self.modelId = self._dataForPet.showPetModelId
    else
        self.modelId = Pet[self._dataForPet.allJieshu] and Pet[self._dataForPet.allJieshu].Model or Pet[0].Model
    end
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

-- 刷新灵兽模型显示
function mountMain:refreshPetModel()
    print("=== refreshPetModel 开始 ===")
    print("showPetModelId:", self._dataForPet.showPetModelId)
    print("petHHid:", self._dataForPet.petHHid)
    -- 根据showPetModelId设置模型ID
    if self._dataForPet.showPetModelId and self._dataForPet.showPetModelId > 0 then
        self.modelId = self._dataForPet.showPetModelId
        print("使用幻化模型ID:", self.modelId)
    else
        -- 使用基础模型
        self.modelId = Pet[self._dataForPet.allJieshu] and Pet[self._dataForPet.allJieshu].Model or Pet[1].Model
        print("使用基础模型ID:", self.modelId)
    end
    -- 更新模型显示
    if self.modelId and self.petBody then
        self:setPetModel(self.modelId, 0, 1.1)
    end
    print("=== refreshPetModel 完成 ===")
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
    -- 更新幻化图标n117
    self:UpdatePetHHIcon()
    -- 更新灵兽属性幻化百分比n107（根据等级同步服务端配置）
    self:UpdatePetAttrRate()
    -- 绑定幻化按钮事件（500ms冷却）
    FGUI:setOnClickEvent(self._ui.petHuanhua, function()
        if not checkCooldown("petHuanhua") then return end
        self._data:setPetModel({ mountId = self.modelId })
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
    -- 设置BUFF描述（处理\n换行符）
    local buffText = ""
    if allNamesObj[nowGrade].BuffDesc then
        buffText = string.gsub(allNamesObj[nowGrade].BuffDesc, "\\n", "\n")
    end
    -- 设置文本控件自动调整高度以支持多行显示
    FGUI:GTextField_setAutoSize(self.petHuanhuaAttr.buffText, 2) -- 2=Both
    FGUI:GTextField_setText(self.petHuanhuaAttr.buffText, buffText)
    -- 支持ClassID为空时不显示属性列表
    if sx and #sx > 0 then
        local hhbuffTextHeight = 26 * #sx + 5
        FGUI:setPosition(self.petHuanhuaAttr.buffText, 15, hhbuffTextHeight)
        -- 渲染属性列表
        FGUI:GList_itemRenderer(self.petHuanhuaAttr["sxlist"], function(index, item)
            local attrId = sx[index + 1][1]
            local attrValue = sx[index + 1][2]
            local label = AttScoreNames[attrId].Name .. ":"
            local itemLabel = FGUI:GetChild(item, "label")
            local itemValue = FGUI:GetChild(item, "zhi")
            -- 检查是否需要显示为百分比
            local valueText = attrValue
            if PercentAttrConfig[attrId] then
                valueText = math.floor(attrValue / 100) .. "%"
            end
            FGUI:GTextField_setText(itemLabel, label)
            FGUI:GTextField_setText(itemValue, valueText)
        end)
        FGUI:GList_setNumItems(self.petHuanhuaAttr["sxlist"], #sx)
    else
        -- ClassID为空时不显示属性列表
        FGUI:GList_setNumItems(self.petHuanhuaAttr["sxlist"], 0)
    end
end

-- 更新灵兽幻化图标n117（名字和等级）
function mountMain:UpdatePetHHIcon()
    -- 安全检查
    if not self._dataForPet.hhSortList or #self._dataForPet.hhSortList == 0 then
        return
    end

    -- 使用当前选中的幻化（不要根据petHHid覆盖nowPetHHIndex）
    local currentHHItem = nil
    local currentHHName = nil
    -- 确保索引在有效范围内
    if self.nowPetHHIndex >= 0 and self.nowPetHHIndex < #self._dataForPet.hhSortList then
        currentHHItem = self._dataForPet.hhSortList[self.nowPetHHIndex + 1]
        if currentHHItem then
            currentHHName = currentHHItem.Name
        end
    end

    -- 如果没找到，使用第一个幻化
    if not currentHHItem then
        currentHHItem = self._dataForPet.hhSortList[1]
        if currentHHItem then
            currentHHName = currentHHItem.Name
        end
    end

    if not currentHHItem then
        return
    end

    -- 更新名字
    local nameText = FGUI:GetChild(self._ui.n117, "name")
    if nameText then
        FGUI:GTextField_setText(nameText, currentHHName)
    end

    -- 获取幻化等级并更新level控制器
    -- 未激活或1级 → 控制器0（普通）
    -- 2级 → 控制器1（勇者）
    -- 以此类推...
    local levelCtrl = FGUI:getController(self._ui.n117, "level")
    if levelCtrl then
        local currentGrade = self._dataForPet.hhlistsj[currentHHName] or 0
        -- 等级-1得到控制器索引，未激活/1级都是0
        local controllerIndex = math.max(0, currentGrade - 1)
        -- 防止越界（最大4）
        controllerIndex = math.min(controllerIndex, 4)
        FGUI:Controller_setSelectedIndex(levelCtrl, controllerIndex)
    end
end

-- 更新灵兽属性幻化百分比n107（根据灵兽等级同步服务端PetLevelRateConfig）
function mountMain:UpdatePetAttrRate()
    -- 获取灵兽等级（从_dataForPet.allJieshu获取，这是升阶后的等级）
    local petLevel = self._dataForPet and self._dataForPet.allJieshu or 0
    if not petLevel or petLevel < 1 then
        petLevel = 1
    end
    petLevel = tonumber(petLevel) or 1
    
    -- 根据等级获取转化比例
    local rate = getPetAttrRateByLevel(petLevel)
    local ratePercent = math.floor(rate * 100) .. "%"
    
    -- 更新n107文本
    local n107Text = self._ui.n107
    if n107Text then
        FGUI:GTextField_setText(n107Text, string.format("出战灵兽[color=#00ff00]%s[/color]的属性转化给人物", ratePercent))
    end
    
    print("=== UpdatePetAttrRate: petLevel=" .. petLevel .. ", rate=" .. ratePercent .. " ===")
end

-- 更新坐骑幻化图标n118（名字和等级）
-- 参数：可选的指定名称，用于点击列表时显示正确的幻化名字
function mountMain:UpdateMountHHIcon(specifiedName)
    -- 安全检查
    if not self._dataForMount.hhSortList or #self._dataForMount.hhSortList == 0 then
        return
    end

    local currentHHItem = nil
    local currentHHName = nil

    -- 优先级1：如果传入了指定名称（点击列表时），直接使用该名称
    if specifiedName and specifiedName ~= "" then
        for i = 1, #self._dataForMount.hhSortList do
            if self._dataForMount.hhSortList[i].Name == specifiedName then
                currentHHItem = self._dataForMount.hhSortList[i]
                currentHHName = currentHHItem.Name
                break
            end
        end
    end

    -- 优先级2：如果没有指定名称，优先使用当前索引对应的幻化（用户正在操作的）
    if not currentHHItem and self.nowIndex and self.nowIndex >= 0 and self.nowIndex < #self._dataForMount.hhSortList then
        currentHHItem = self._dataForMount.hhSortList[self.nowIndex + 1]
        if currentHHItem then
            currentHHName = currentHHItem.Name
        end
    end

    -- 优先级3：如果当前索引无效，使用mountHHid找到当前出战的幻化
    if not currentHHItem and self._dataForMount.mountHHid and tonumber(self._dataForMount.mountHHid) > 0 then
        for i = 1, #self._dataForMount.hhSortList do
            if self._dataForMount.hhSortList[i].Model == self._dataForMount.mountHHid then
                currentHHItem = self._dataForMount.hhSortList[i]
                currentHHName = currentHHItem.Name
                break
            end
        end
    end

    -- 优先级4：最后使用第一个幻化
    if not currentHHItem then
        currentHHItem = self._dataForMount.hhSortList[1]
        if currentHHItem then
            currentHHName = currentHHItem.Name
        end
    end

    if not currentHHItem then
        return
    end

    -- 更新名字
    local nameText = FGUI:GetChild(self._ui.n118, "name")
    if nameText then
        FGUI:GTextField_setText(nameText, currentHHName)
    end

    -- 获取幻化等级并更新level控制器
    local levelCtrl = FGUI:getController(self._ui.n118, "level")
    if levelCtrl then
        local currentGrade = self._dataForMount.hhlistsj[currentHHName] or 0
        local controllerIndex = math.max(0, currentGrade - 1)
        controllerIndex = math.min(controllerIndex, 4)
        FGUI:Controller_setSelectedIndex(levelCtrl, controllerIndex)
    end
end

-- 设置灵兽幻化列表渲染
function mountMain:setupPetHuanhuaList()
    FGUI:GList_itemRenderer(self._ui.petLeftList, function(idx, item)
        if not self._dataForPet.hhSortList or #self._dataForPet.hhSortList == 0 then
            return
        end
        local itemData = self._dataForPet.hhSortList[idx + 1]
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
            self:SelectedPetHH()
            self:UpdatePetHHBtnName()
            self:setPetXhcl()
            self:setPetHHAddBtn()
            -- 更新n117控件（幻化名字和等级）
            self:UpdatePetHHIcon()
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

-- 选择灵兽幻化项
function mountMain:SelectedPetHH()
    -- 重置所有选中状态
    local itemList = FGUI:GetChildren(self._ui.petLeftList)
    for i = 1, #itemList do
        local controller = FGUI:getController(itemList[i], "checked")
        FGUI:Controller_setSelectedIndex(controller, 0)
        if self.nowPetHHIndex == i - 1 then
            FGUI:Controller_setSelectedIndex(controller, 1)
        end
    end
    -- 更新模型
    self:setPetModel(self.modelId, 0, 1.1)
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

    -- 保留当前选中的索引（用户正在操作的幻化），只在无效时初始化
    -- 如果self.nowIndex无效，根据mountHHid确定索引
    local listSize = #self._dataForMount.hhSortList
    if not self.nowIndex or self.nowIndex < 0 or self.nowIndex >= listSize then
        self.nowIndex = 0
        -- 如果当前没有有效索引，使用mountHHid找到对应索引
        if self._dataForMount.mountHHid and tonumber(self._dataForMount.mountHHid) > 0 then
            for i = 1, listSize do
                if self._dataForMount.hhSortList[i].Model == self._dataForMount.mountHHid then
                    self.nowIndex = i - 1
                    break
                end
            end
        end
    end

    -- 确保索引在有效范围内
    if self.nowIndex < 0 or self.nowIndex >= #self._dataForMount.hhSortList then
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
    -- 绑定幻化按钮事件（500ms冷却）
    FGUI:setOnClickEvent(self._ui.huanhua, function()
        if not checkCooldown("huanhua") then return end
        self._data:setModel({ mountId = self.modelId })
    end)
    -- 更新模型和按钮状态
    self:updateModel()
    self:setHHAddBtn()
    self:UpdateHHBtnName()
    -- 更新n118控件（坐骑幻化名字和等级）
    self:UpdateMountHHIcon()

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
        local itemData = self._dataForMount.hhSortList[idx + 1]
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
            -- 更新n118控件（坐骑幻化名字和等级），传入当前点击的幻化名称
            self:UpdateMountHHIcon(itemData.Name)
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
    local selectData = self._dataForMount.hhSortList[self.nowIndex + 1]
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
        if self.nowIndex == i - 1 then
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
    -- 设置BUFF描述（处理\n换行符）
    local hhbuffTextHeight = 26 * #sx + 5
    local hhbuffs = allNamesObj[nowGrade].BuffID
    local buffText = ""
    if allNamesObj[nowGrade].BuffDesc then
        buffText = string.gsub(allNamesObj[nowGrade].BuffDesc, "\\n", "\n")
    end
    FGUI:GTextField_setAutoSize(self.huanhuaAttr.buffText, 2)
    FGUI:setPosition(self.huanhuaAttr.buffText, 15, hhbuffTextHeight)
    FGUI:GTextField_setText(self.huanhuaAttr.buffText, buffText)
    -- 渲染属性列表
    FGUI:GList_itemRenderer(self.huanhuaAttr["sxlist"], function(index, item)
        local attrId = sx[index + 1][1]
        local attrValue = sx[index + 1][2]
        local label = AttScoreNames[attrId].Name .. ":"
        local itemLabel = FGUI:GetChild(item, "label")
        local itemValue = FGUI:GetChild(item, "zhi")
        -- 检查是否需要显示为百分比
        local valueText = attrValue
        if PercentAttrConfig[attrId] then
            valueText = math.floor(attrValue / 100) .. "%"
        end
        FGUI:GTextField_setText(itemLabel, label)
        FGUI:GTextField_setText(itemValue, valueText)
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
            table.insert(result, { tonumber(classIds[b][1]), tonumber(classIds[b][2]) })
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
        table.insert(result, { tonumber(classIds[b][1]), tonumber(classIds[b][2]) })
    end
    -- 渲染属性列表
    self:renderAttributeList(self.nextMountAttr["n15"], result)
end

-- 渲染属性列表（通用方法）
function mountMain:renderAttributeList(list, attributes)
    FGUI:GList_itemRenderer(list, function(index, item)
        local attrId = attributes[index + 1][1]
        local attrValue = attributes[index + 1][2]
        local label = AttScoreNames[attrId].Name .. ":"
        local itemLabel = FGUI:GetChild(item, "label")
        local itemValue = FGUI:GetChild(item, "zhi")
        local isDouble = FGUI:getController(item, 'isDouble')
        -- 设置交替背景
        if index % 2 == 0 then
            FGUI:Controller_setSelectedIndex(isDouble, 0)
        else
            FGUI:Controller_setSelectedIndex(isDouble, 1)
        end
        -- 检查是否需要显示为百分比
        local valueText = attrValue
        if PercentAttrConfig[attrId] then
            valueText = math.floor(attrValue / 100) .. "%"
        end
        -- 设置属性文本
        FGUI:GTextField_setText(itemLabel, label)
        FGUI:GTextField_setText(itemValue, valueText)
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
        { x = 0, y = 0, z = 0 },
        { x = 0, y = 180, z = 0 },
        { x = 1.1, y = 1.1, z = 1.1 },
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

-- 设置消耗材料显示（对齐灵兽，支持多消耗）
function mountMain:setXHCL()
    local costs = {}
    local iconItem = FGUI:GetChild(self._ui.xhcl, "iconItem")
    local iconItem2 = FGUI:GetChild(self._ui.xhcl, "iconItem2") -- 第二个消耗图标
    FGUI:setVisible(self._ui.n34, true)
    FGUI:setVisible(self._ui.xhcl, true)

    -- 保存默认位置用于切换
    if not self._xhclDefaultPos then
        self._xhclDefaultPos = {FGUI:getPosition(self._ui.xhcl)}
        self._n34DefaultPos = {FGUI:getPosition(self._ui.n34)}
    end
    -- 清除旧图标
    if FGUI:GetChildCount(iconItem) > 0 then
        FGUI:RemoveChildAt(iconItem, 0, true)
    end
    if iconItem2 and FGUI:GetChildCount(iconItem2) > 0 then
        FGUI:RemoveChildAt(iconItem2, 0, true)
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
        -- allJieshu = 0 表示未激活，显示 Mount[0].Cost (激活消耗)
        -- allJieshu >= 1 表示已激活，显示 Mount[allJieshu].Cost (当前等级升下一级的消耗)
        local wz = self._dataForMount.allJieshu
        costs = Mount[wz].Cost
        print("坐骑消耗材料配置索引:", wz, "当前等级:", self._dataForMount.allJieshu, "Cost:", costs)
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

    -- 检查是否是多重消耗格式
    local isMultiCost = (type(costs[1]) == "table")

    if isMultiCost then
        -- 多重消耗格式：{[1] = {[1] = itemId, [2] = num}, [2] = {[1] = itemId, [2] = num}}
        print("检测到坐骑多重消耗，共", #costs, "个材料")

        -- 设置到默认位置
        if self._xhclDefaultPos then
            FGUI:setPosition(self._ui.xhcl, self._xhclDefaultPos[1], self._xhclDefaultPos[2])
            FGUI:setPosition(self._ui.n34, self._n34DefaultPos[1], self._n34DefaultPos[2])
        end

        -- 显示第二个消耗（如果存在）
        if #costs >= 2 and iconItem2 then
            local cost2 = costs[2]
            local itemId2 = tonumber(cost2[1])
            local num2 = tonumber(cost2[2])
            local itemData2 = SL:GetValue("ITEM_DATA", itemId2)
            print("坐骑第二个物品ID:", itemId2, "需要数量:", num2, "物品数据:", itemData2)

            -- 创建物品显示
            local extData2 = {}
            extData2.hideTip = false
            extData2.itemTipData = itemData2
            extData2.clickCallback = false
            extData2.doubleClickCallback = false
            extData2.bgVisible = true
            ItemUtil:ItemShow_Create(itemData2, iconItem2, extData2)

            -- 设置数量显示和颜色
            local itemNum2 = FGUI:GetChild(self._ui.xhcl, "n4") -- 第二个消耗数量
            local fuhao2 = FGUI:GetChild(self._ui.xhcl, "n3")   -- 第二个消耗符号
            if itemNum2 then
                local haveNum2 = SL:GetValue(TITEMCOUNT, itemId2)
                FGUI:GTextField_setText(itemNum2, num2)
                if haveNum2 >= num2 then
                    FGUI:GTextField_setColor(itemNum2, "#00f900")
                    if fuhao2 then FGUI:GTextField_setColor(fuhao2, "#00f900") end
                else
                    FGUI:GTextField_setColor(itemNum2, "#ff0000")
                    if fuhao2 then FGUI:GTextField_setColor(fuhao2, "#ff0000") end
                end
                FGUI:setVisible(itemNum2, true)
                if fuhao2 then FGUI:setVisible(fuhao2, true) end
            end
            FGUI:setVisible(iconItem2, true)
        end

        -- 设置第一个消耗
        local cost1 = costs[1]
        local itemId1 = tonumber(cost1[1])
        local num1 = tonumber(cost1[2])
        local itemData1 = SL:GetValue("ITEM_DATA", itemId1)
        print("坐骑第一个物品ID:", itemId1, "需要数量:", num1, "物品数据:", itemData1)

        -- 创建物品显示
        local extData1 = {}
        extData1.hideTip = false
        extData1.itemTipData = itemData1
        extData1.clickCallback = false
        extData1.doubleClickCallback = false
        extData1.bgVisible = true
        ItemUtil:ItemShow_Create(itemData1, iconItem, extData1)

        -- 设置数量显示和颜色
        local itemNum = FGUI:GetChild(self._ui.xhcl, "n2")
        local fuhao = FGUI:GetChild(self._ui.xhcl, "n1")
        local haveNum = SL:GetValue(TITEMCOUNT, itemId1)
        FGUI:GTextField_setText(itemNum, num1)
        if haveNum >= num1 then
            FGUI:GTextField_setColor(itemNum, "#00f900")
            FGUI:GTextField_setColor(fuhao, "#00f900")
        else
            FGUI:GTextField_setColor(itemNum, "#ff0000")
            FGUI:GTextField_setColor(fuhao, "#ff0000")
        end
    else
        -- 单消耗格式（兼容旧数据）
        -- 隐藏第二个消耗
        if iconItem2 then FGUI:setVisible(iconItem2, false) end
        local itemNum2 = FGUI:GetChild(self._ui.xhcl, "n4")
        local fuhao2 = FGUI:GetChild(self._ui.xhcl, "n3")
        if itemNum2 then FGUI:setVisible(itemNum2, false) end
        if fuhao2 then FGUI:setVisible(fuhao2, false) end

        -- 设置第一个消耗
        local num = costs[2]
        local itemId = tonumber(costs[1])
        local itemData = SL:GetValue("ITEM_DATA", itemId)
        print("坐骑物品ID:", itemId, "需要数量:", num, "物品数据:", itemData)

        -- 创建物品显示
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
        local haveNum = SL:GetValue(TITEMCOUNT, itemId)
        FGUI:GTextField_setText(itemNum, num)
        if haveNum >= tonumber(num) then
            FGUI:GTextField_setColor(itemNum, "#00f900")
            FGUI:GTextField_setColor(fuhao, "#00f900")
        else
            FGUI:GTextField_setColor(itemNum, "#ff0000")
            FGUI:GTextField_setColor(fuhao, "#ff0000")
        end

        -- 单一材料时，控件右移50
        if self._xhclDefaultPos then
            FGUI:setPosition(self._ui.xhcl, self._xhclDefaultPos[1] + 50, self._xhclDefaultPos[2])
            FGUI:setPosition(self._ui.n34, self._n34DefaultPos[1] + 50, self._n34DefaultPos[2])
        end
    end
end

return mountMain
