local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local righttoppanl = class("righttoppanl", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local righttoppanlData = SL:RequireFile("FGUILayout/A_Right/righttoppanlData")

--- 创建界面并绑定各UI事件
function righttoppanl:Create()
    --- 获取当前界面的代理对象，用于操作UI
    self._ui = FGUI:ui_delegate(self.component)
    self:InitAdapt()
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    if isPC then
        local rightpanlX = FGUI:getPositionX(self.component)
        FGUI:setPositionX(self.component, rightpanlX + 70)
    end

    --- 获取右上角图标UI代理对象
    self._righttop = FGUI:ui_delegate(self._ui.righttopbg)

    --- 绑定收起/展开按钮点击事件
    FGUI:setOnClickEvent(self._ui.shounabtn, function()
        if FGUI:getVisible(self._ui.righttopbg) then
            FGUI:setVisible(self._ui.righttopbg, false)
            FGUI:GButton_setSelected(self._ui.shounabtn, true)
        else
            FGUI:setVisible(self._ui.righttopbg, true)
            FGUI:GButton_setSelected(self._ui.shounabtn, false)
        end
    end)

    --- 初始化回城符列表数据
    self.cityControlle = FGUI:getController(self.component, "city")

    --- 绑定回城符按钮事件
    FGUI:setOnClickEvent(self._ui.citybtn, function()
        local newIndex = (self.cityControlle.selectedIndex == 1) and 0 or 1
        FGUI:Controller_setSelectedIndex(self.cityControlle, newIndex)
        if self.cityControlle.selectedIndex == 1 then
            local cityItems = righttoppanlData:Get():getitemnum()
            FGUI:GList_setNumItems(self.itemlist, #cityItems)
            FGUI:GList_refreshVirtualList(self.itemlist) --- 刷新虚拟列表
            FGUI:GButton_setSelected(self._ui.citybtn, true)
        else
            FGUI:GButton_setSelected(self._ui.citybtn, false)
        end
    end)

    --- 配置回城符列表界面
    self.citylist = FGUI:ui_delegate(self._ui.citylist)
    self.itemlist = self.citylist.itemlist
    FGUI:GList_itemRenderer(self.itemlist, handler(self, self.ListViewCellsitem))
    FGUI:GList_setDefaultItem(self.itemlist, "ui://h3jungk0oqrpt")
    FGUI:GList_setVirtual(self.itemlist)
    FGUI:GList_addOnClickItemEvent(self.itemlist, function(context)
        local itemRoot = FGUI:GetChild(context.data, "itemRoot")
        local itemRoot2 = FGUI:GetChild(context.data, "itemRoot2")
        local index = FGUI:GetIntData(itemRoot)
        local cityItems = righttoppanlData:Get():GetState().cityitemlist
        if cityItems[index] then
            local itemData = cityItems[index][1]
            FGUI:addOnClickEvent(itemRoot2, function()
                righttoppanlData:Get():RequestBackCity({ itemData.ID })
                FGUI:Controller_setSelectedIndex(self.cityControlle, 0)
                FGUI:GButton_setSelected(self._ui.citybtn, false)
            end)
        end
    end)

    --- 配置传送符使用和自动寻路按钮
    self.moveobj = FGUI:ui_delegate(self._ui.btn_move)
    self.moveControlle = FGUI:getController(self.component, "move")
    FGUI:setOnClickEvent(self._ui.btn_move, function()
        local xunlutab = righttoppanlData:Get():GetState().xunlutab
        righttoppanlData:Get():RequestMove({ xunlutab })
    end)


    --- GM按钮点击事件绑定
    FGUI:setOnClickEvent(self._ui.btn_gm, function()
        FGUI:Open("A_gm", "GMBox", {}, FGUI_LAYER.NORMAL, { fullScreen = false, destroyTime = 1 })
    end)
    -- 百宝阁按钮点击事件绑定
    FGUI:setOnClickEvent(self._righttop.btn_BBG, function()
        SL:RequestGroupData(0)
    end)
    -- 拍卖行按钮点击事件绑定
    FGUI:setOnClickEvent(self._righttop.btn_paimai, function()
        FGUI:Open("Auction", "AuctionRootPanel", {}, FGUI_LAYER.NORMAL, { destroyTime = 1 })
    end)
    -- 充值按钮点击事件绑定
    FGUI:setOnClickEvent(self._righttop.btn_bill, function()
        FGUI:Open("Recharge", "RechargePanel", {}, FGUI_LAYER.NORMAL, { destroyTime = 1 })
    end)

    -- 活动大厅按钮点击事件绑定
    FGUI:setOnClickEvent(self._righttop.btn_hddt, function()
        SL:dump("点击活动大厅按钮")
        FGUI:Open("Z_Jasin", "HuodongPanel", {}, FGUI_LAYER.NORMAL, { destroyTime = 1 })
    end)

    -- 订阅数据层事件
    self:SubscribeEvents()

    -- 事件注册
    righttoppanlData:Get():RegisterEvent()
end

--- 销毁界面时移除事件订阅
function righttoppanl:Destroy()
    -- 事件注销
    righttoppanlData:Get():RemoveEvent()
    -- 取消数据层事件订阅
    if self._subscriptions then
        for _, token in ipairs(self._subscriptions) do
            righttoppanlData:Get():Unsubscribe(token)
        end
        self._subscriptions = nil
    end
end

-- 订阅数据层事件
function righttoppanl:SubscribeEvents()
    self._subscriptions = {}

    -- 回城符更新
    table.insert(self._subscriptions, righttoppanlData:Get():Subscribe("city_item_update", function(data)
        if self.cityControlle and self.cityControlle.selectedIndex == 1 then
            FGUI:GList_setNumItems(self.itemlist, #data)
            FGUI:GList_refreshVirtualList(self.itemlist)
        end
    end))

    -- 自动寻路开始
    table.insert(self._subscriptions, righttoppanlData:Get():Subscribe("xunlun_begin", function(data)
        FGUI:Controller_setSelectedIndex(self.moveControlle, 1)
    end))

    -- 自动寻路结束
    table.insert(self._subscriptions, righttoppanlData:Get():Subscribe("xunlun_end", function()
        FGUI:Controller_setSelectedIndex(self.moveControlle, 0)
    end))

    -- 目标变化
    table.insert(self._subscriptions, righttoppanlData:Get():Subscribe("target_change", function(data)
        if data.targetID then --- 选中目标 右上收起
            FGUI:setVisible(self._ui.righttopbg, false)
            FGUI:GButton_setSelected(self._ui.shounabtn, true)
        end
    end))

    -- 等级变化
    table.insert(self._subscriptions, righttoppanlData:Get():Subscribe("level_change", function(data)

    end))


    -- 使用道具
    table.insert(self._subscriptions, righttoppanlData:Get():Subscribe("use_item", function(data)
        self:useItem(data)
    end))
end

function righttoppanl:InitAdapt()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local safeL, safeR, safeB, safeT = SL:GetValue("SCREEN_SAFE_AREA_RATIO")

    FGUI:setSize(self.component, screenW - safeR - safeL, screenH - safeB - safeT)
    FGUI:setPosition(self.component, safeL, safeT)
end

--- 回城符列表项渲染函数
function righttoppanl:ListViewCellsitem(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    FGUI:SetIntData(itemRoot, idx + 1)

    local cityItems = righttoppanlData:Get():GetState().cityitemlist
    if cityItems[idx + 1] then
        local itemnum = cityItems[idx + 1][2]
        local itemData = cityItems[idx + 1][1]
        local n0 = FGUI:GetChild(item, "n0")

        FGUI:setOnClickEvent(n0, function()
            righttoppanlData:RequestBackCity({ itemData.ID })
            FGUI:Controller_setSelectedIndex(self.cityControlle, 0)
            FGUI:GButton_setSelected(self._ui.citybtn, false)
        end)

        local extData = {}
        extData.hideTip = false            --- 是否隐藏默认Tip
        extData.itemTipData = itemData     --- ItemTips.ShowTip对应的参数数据
        extData.clickCallback = false      --- 单击事件回调
        extData.doubleClickCallback = true --- 双击事件回调
        extData.bgVisible = false          --- 隐藏背景显示
        ItemUtil:ItemShow_Create(itemData, itemRoot, extData)

        local name = FGUI:GetChild(item, "name")
        local num = FGUI:GetChild(item, "num")
        FGUI:GTextField_setText(name, "" .. itemData.Name)
        FGUI:GTextField_setText(num, "" .. itemnum)
    end
end

--- 使用道具确认处理
--- data.param1, param2, param3, param4 用于命令参数，param5为提示信息
function righttoppanl:useItem(data)
    if data.param1 and data.param2 and data.param3 and data.param4 then
        local callBack = function(tag)
            if tag == 1 then --- 确定
                righttoppanlData:RequestUseItem(data)
            end
        end
        local tcdata = {}
        tcdata.title = "提示"
        tcdata.str = data.param5 or "是否确定使用"
        tcdata.btnDesc = { "确定", "取消" }
        tcdata.callback = callBack
        SL:OpenCommonDialog(tcdata)
    end
end

function righttoppanl:updateLSmodel(data)
    righttoppanlData:Get():updateLSmodel(data)
end

return righttoppanl
