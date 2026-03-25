local BaseFGUILayout = requireFGUI("BaseFGUILayout")
-- local EquipDuanZaoEx = require("FGUILayer/Main/EquipDuanZaoEx")
local EquipDuanZao = class("EquipDuanZao", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local EquipQHTab = require("game_config/cfgcsv/EquipQHTab")
local EquipQHItemTab = require("game_config/cfgcsv/EquipQHItemTab")
local EquipFYTab = require("game_config/cfgcsv/EquipFYTab")
local EquipHCTab = require("game_config/cfgcsv/EquipHCTab")

local attrConfigs = SL:GetValue("ATTR_CONFIGS")
--EquipDuanZao.itemobjlist = {}
local leftpage = { {"装备", "#ffff00"}, {"背包", "#CCCCCC"} }
local equippos = { 
    {0,1,4,5,6,7,12,13,25,26}, 
    {0,1,4,5,6,7,12},
    {0,1,4,5,6,7,12}, --转移可不显示装备信息，也可和强化保持一致
    {2,3,8,9,10}, 
    {0,1}, 
}  -- 不同页签获得的身上装备位置 通过这个获取需要显示的装备
local equippos2 = {  -- 不同页签获得的背包装备 通过这个获取需要显示的装备
    {[5]=1,[3]=1,[8]=1,[9]=1,[51]=1,[53]=1,[54]=1,[65]=1,[66]=1},
    {[5]=2,[3]=2,[8]=2,[9]=2,[51]=2,[53]=2},
    {[5]=2,[3]=2,[8]=2,[9]=2,[51]=2,[53]=2}, --转移可不显示背包装备，也可和强化保持一致
    {[15]=3,[19]=3,[22]=3},
    {[5]=4,[3]=4},
}
local equippos3 = { [5]=1, [3]=2, [8]=3, [9]=4, [51]=5, [15]=6, [19]=7, [22]=8,[53]=9,[54]=6,[65]=7,[66]=8 }        -- 装备位置对应表内id映射  当前整个系统多个子页签因共用一套装备所以公用这个方法。如果有大的改变可向equippos2自行优化，服务端也要改
local xyfitemlist = {190,191,192,193,194}  --幸运符列表一直展示
local equipposlist = {  --身上装备列表
}
local bagequiplist = {  --背包装备列表
}
local bagitemlist = {   --背包提升道具
}
local xzequipstate = {}  -- 记录选中状态
-- 装备数据层
local EquipDuanZaoData = SL:RequireFile("FGUILayout/A_EquipDuanZao/EquipDuanZaoData")
-----------------------------------------------------------------------
--- Create: 创建界面并初始化事件及数据
-----------------------------------------------------------------------
function EquipDuanZao:Create()
    -- 移除 CCUI 全局引用
    SL:RegisterLUAEvent(LUA_EVENT_TAKE_ON_EQUIP_SUCCESS, "EquipDuanZao", handler(self, self.onUpdata))
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)

    --适配pc端UI
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    if isPC then 
        FGUI:setScale(self.component, 0.85, 0.85)
        FGUI:setPosition(self.component, screenW / 2, screenH / 2)
        FGUI:setAnchorPoint(self.component, 0.5, 0.5, true)
    end

    -- 关闭按钮点击事件绑定 ---关闭按钮
    FGUI:setOnClickEvent(self._ui.closebtn, function()
        FGUI:Close("A_EquipDuanZao", "EquipDuanZao")
    end)

    self.List_Filter = FGUI:ui_delegate(self._ui.List_Filter)

    -- 默认选中第一页第一个
    FGUI:GList_setSelectedIndex(self._ui.List_Filter, 0)
    FGUI:GList_setSelectedIndex(self._ui.List_Page, 0)
    local obj = FGUI:GetChildAt(self._ui.List_Page, 0)
    FGUI:GButton_setTitleColor(obj, "#ffff00")

    for i = 1, #leftpage do
        local obj = FGUI:GetChildAt(self._ui.List_Filter, i - 1)
        FGUI:GButton_setTitle(obj, "" .. leftpage[i][1])
        FGUI:GButton_setTitleColor(obj, "" .. leftpage[i][2])
    end

    -- 右侧容器类型,页签
    self.pageControlle = FGUI:getController(self.component, "page")
    -- 左边容器类型,是装备还是背包
    self.itemlistControlle = FGUI:getController(self.component, "itemlist")
    
    FGUI:GList_addOnClickItemEvent(self._ui.List_Filter, function(context)
        local index = FGUI:GList_getSelectedIndex(self._ui.List_Filter)
        for i = 1, #leftpage do
            local obj = FGUI:GetChildAt(self._ui.List_Filter, i - 1)
            if index == i - 1 then
                FGUI:GButton_setTitleColor(obj, "#ffff00")
            else
                FGUI:GButton_setTitleColor(obj, "#CCCCCC")
            end
        end
        FGUI:Controller_setSelectedIndex(self.itemlistControlle, index)
        self.itemlistControlle.selectedIndex = index
        FGUI:Controller_setSelectedIndex(self.additemControlle, 0)

        -- 强化转移页面切换时不清除选中数据
        if self.pageControlle.selectedIndex ~= 2 then
            self:clearequip()
            self:succfont()
        end
    end)

    self.pageControlle.selectedIndex = 0
    FGUI:GList_addOnClickItemEvent(self._ui.List_Page, function(context)
        local index = FGUI:GList_getSelectedIndex(self._ui.List_Page)
        for i = 1, 4 do
            local obj = FGUI:GetChildAt(self._ui.List_Page, i - 1)
            if index == i - 1 then
                FGUI:GButton_setTitleColor(obj, "#ffff00")
            else
                FGUI:GButton_setTitleColor(obj, "#CCCCCC")
            end
        end
        
        FGUI:Controller_setSelectedIndex(self.pageControlle, index)
        self.pageControlle.selectedIndex = index
        FGUI:Controller_setSelectedIndex(self.additemControlle, 0)

        FGUI:GList_clearSelection(self.ListBag)
        FGUI:GList_clearSelection(self.ListEquip)

        self:GetPageData()
        self:RefrsList()

        self:clearequip()   -- 清除右侧选中道具装备
        self:InitData()
    end)

    self.tipsbg = FGUI:ui_delegate(self._ui.panl_tip)
    self:GetPageData()
    self:equiplist()
    self:baglist()
    self:InitData()
    
    -- 订阅数据层事件
    self._eventTokens = {}
    
    
    -- 装备更新事件
    table.insert(self._eventTokens, EquipDuanZaoData:Subscribe("equip_update", handler(self, self.onUpdata)))
    
    -- 强化更新事件
    table.insert(self._eventTokens, EquipDuanZaoData:Subscribe("qianghua_update", function(data)
        if tonumber(data.param1) == 0 then  -- 装备损坏
            self.qhequipMakeIndex = 0
            self:GetPageData()
            self:GetAddItem()
            self:RefrsList()
            FGUI:GList_clearSelection(self.ListBag)
            FGUI:GList_clearSelection(self.ListEquip)
            self:clearequip()
        else  -- 装备更新
            self.qhequiplv = tonumber(data.param2)
            self:GetPageData()
            self:GetAddItem()
            self:RefrsList()
            self:clearitem1()
            self:clearitem2()
            self:clearitem3()
            self:upitem2num()
            self:succfont()
        end
    end))
    
    -- 赋予更新事件
    table.insert(self._eventTokens, EquipDuanZaoData:Subscribe("fuyu_update", function(data)
        self.qhequiplv = tonumber(data.param2)
        self:GetPageData()
        self:GetAddItem()
        self:RefrsList()
        self:clearitem1()
        self:clearitem2()
        self:clearitem3()
        self:upitem2num()
        self:succfont()
    end))
    
    -- 合成更新事件
    table.insert(self._eventTokens, EquipDuanZaoData:Subscribe("hecheng_update", function(data)
        self:GetPageData()
        self:GetAddItem()
        self:RefrsList()
        if tonumber(data.param1) == 1 then
            self:clearequip()
            self:succfont()
        else
            self:clearitem1()
            self:clearitem3()
            self:succfont()
        end
    end))
    
    -- 强化转移更新事件
    table.insert(self._eventTokens, EquipDuanZaoData:Subscribe("transfer_update", function(data)
        if tonumber(data.param1) == 1 then  -- 转移成功
            local newLevel = tonumber(data.param2) or 0
            -- 强制刷新装备数据（包括身上装备）
            self:GetPageData()
            -- 刷新列表显示
            self:RefrsList()
            -- 清空源装备和目标装备选择
            self:clearSourceEquip()
            self:clearTargetEquip()
            -- 刷新道具消耗显示
            self:upitem2num_transfer()
            -- 显示成功消息
            SL:ShowScreenCenterTip(string.format("强化转移成功！目标装备获得+%d强化", newLevel), 251, 0, 200, 1, 1)
        else  -- 转移失败
            SL:ShowScreenCenterTip("强化转移失败！", 251, 0, 200, 1, 1)
        end
    end))
    
end

-----------------------------------------------------------------------
--- Enter: 界面打开时调用（参数page可指定打开界面页签）
-----------------------------------------------------------------------
function EquipDuanZao:Enter(page)
    page = tonumber(page) or 1
    local obj = FGUI:GetChildAt(self._ui.List_Page, page - 1)
    FGUI:GButton_FireClick(obj, true, true)
end
-----------------------------------------------------------------------
--- Destroy: 销毁界面时注销事件
-----------------------------------------------------------------------
function EquipDuanZao:Destroy()
    SL:UnRegisterLUAEvent(LUA_EVENT_TAKE_ON_EQUIP_SUCCESS, "EquipDuanZao")
    -- 取消所有订阅
    if self._eventTokens then
        for _, token in ipairs(self._eventTokens) do
            EquipDuanZaoData:Get():Unsubscribe(token)
        end
        self._eventTokens = nil
    end
end

function EquipDuanZao:onUpdata()
    -- 如果是强化转移页面，需要刷新装备数据
    if self.pageControlle.selectedIndex == 2 then
        -- 强制刷新装备数据（包括身上装备）
        self:GetPageData()
        -- 刷新列表显示
        self:RefrsList()
        -- 清除选中装备
        self:clearSourceEquip()
        self:clearTargetEquip()
        -- 刷新道具消耗显示
        self:upitem2num_transfer()
        return
    end
    self:GetPageData()
    self:RefrsList()
    self:clearequip()
    self:InitData()
end
-----------------------------------------------------------------------
--- InitData: 初始化右侧功能区数据和事件
-----------------------------------------------------------------------
function EquipDuanZao:InitData()
     -- 判断是否打开了tips
     self.tipsControlle = FGUI:getController(self.component, "tips")
     self.tipinfoScro = FGUI:ui_delegate(self.tipsbg.infoScro)
     FGUI:GRichTextField_setText(self.tipinfoScro['n3'], EquipQHTab[self.pageControlle.selectedIndex + 1]['TIPS'])
     FGUI:GRichTextField_setText(self.tipsbg['title'], EquipQHTab[self.pageControlle.selectedIndex + 1]['title'])
     FGUI:Controller_setSelectedIndex(self.tipsControlle,0)
     -- 点击tips
     FGUI:setOnClickEvent(self._ui.btntips, handler(self, self.btnTipsClicked))
     FGUI:setOnClickEvent(self.tipsbg.closetips, handler(self, self.btnTipsClicked))

    -- 根据页签选中初始化右侧面板及相关事件绑定
    -- 新页签顺序：0=合成, 1=装备强化, 2=强化转移, 3=首饰加工, 4=装备赋予
    if self.pageControlle.selectedIndex == 0 then
        self.rightbg = FGUI:ui_delegate(self._ui.panl_hc)
        self.additemControlle = FGUI:getController(self._ui.panl_hc, "additem")
        FGUI:setOnClickEvent(self.rightbg.xzqhitem1, handler(self, self.btnSelectItemClicked3))
    elseif self.pageControlle.selectedIndex == 1 then
        self.rightbg = FGUI:ui_delegate(self._ui.panl_qh)
        self.additemControlle = FGUI:getController(self._ui.panl_qh, "additem")
    elseif self.pageControlle.selectedIndex == 2 then
        -- 强化转移页面:使用独立的UI面板
        self.rightbg = FGUI:ui_delegate(self._ui.panl_transfer)
        self.additemControlle = FGUI:getController(self._ui.panl_transfer, "additem")
        self.addlistshowControlle = FGUI:getController(self._ui.panl_transfer, "addlistshow")
        -- 初始化强化转移相关变量
        self.sourceEquipMakeIndex = 0
        self.targetEquipMakeIndex = 0
        self.sourceEquipLevel = 0
        self.targetEquipLevel = 0
        
        -- 为转移页面的装备槽创建ui_delegate以便访问子组件
        self.xzequip = FGUI:ui_delegate(self.rightbg.xzequip)
        self.xzqhitem1 = FGUI:ui_delegate(self.rightbg.xzqhitem1)
        if self.rightbg.xzqhitem2 then
            self.xzqhitem2 = FGUI:ui_delegate(self.rightbg.xzqhitem2)
        end
        
        -- 设置关闭按钮点击事件
        FGUI:setOnClickEvent(self.xzequip.closeitembtn, function()
            self:clearTargetEquip()
        end)
        FGUI:setOnClickEvent(self.xzqhitem1.closeitembtn, function()
            self:clearSourceEquip()
        end)
        
        -- 设置强化转移按钮点击事件
        FGUI:setOnClickEvent(self.rightbg.qhbtn, handler(self, self.onTransferClicked))
        -- 更新道具消耗显示
        self:upitem2num_transfer()
        return
    elseif self.pageControlle.selectedIndex == 3 then
        self.rightbg = FGUI:ui_delegate(self._ui.panl_jg)
        self.additemControlle = FGUI:getController(self._ui.panl_jg, "additem")
    elseif self.pageControlle.selectedIndex == 4 then
        self.rightbg = FGUI:ui_delegate(self._ui.panl_fy)
        self.additemControlle = FGUI:getController(self._ui.panl_fy, "additem")
        FGUI:setOnClickEvent(self.rightbg.xzqhitem1, handler(self, self.btnSelectItemClicked3))
    end

    -- 判断是否选择了复选框
    self.checkBoxIsSelected = FGUI:getController(self.rightbg.ischeck, "isSelected")
    -- 判断是否选择了添加道具窗口
    self.addlistshowControlle = FGUI:getController(self.rightbg.panl_additem, "addlistshow")
   
    -- 幸运符点击事件
    FGUI:setOnClickEvent(self.rightbg.xzitem1, handler(self, self.btnSelectItemClicked1))
    if self.rightbg.xzitem2 then
        FGUI:setOnClickEvent(self.rightbg.xzitem2, handler(self, self.btnSelectItemClicked2))
    end

    -- 复选框选择
    FGUI:setOnClickEvent(self.rightbg.ischeck, handler(self, self.checkBoxIsSelectedClicked))

    self.xzequip = FGUI:ui_delegate(self.rightbg.xzequip)
    self.xzqhitem1 = FGUI:ui_delegate(self.rightbg.xzqhitem1)
    self.xzitem1 = FGUI:ui_delegate(self.rightbg.xzitem1)
    self.xzitem2 = FGUI:ui_delegate(self.rightbg.xzitem2)
    if self.rightbg.xzqhitem2 then
        self.xzqhitem2 = FGUI:ui_delegate(self.rightbg.xzqhitem2)
    end
    if self.rightbg.costitem1 then
        self.costitem1 = FGUI:ui_delegate(self.rightbg.costitem1)
    end
    self.qhequipMakeIndex = 0
    self.selectEquipLv = 0
    self.qhitem1, self.qhitem2, self.qhitem3, self.qhitem4 = 0, 0, 0, 0
    self.selectEquipStdMode = 0
    self.qhequiplv = 0  -- 选中装备对应功能等级
    self.qhitem3Makeid = 0
    self.additemshowlist = {}

    FGUI:setOnClickEvent(self.rightbg['qhbtn'], function()
        local EquipDuanZaoData = SL:RequireFile("FGUILayout/A_EquipDuanZao/EquipDuanZaoData")
        if self.pageControlle.selectedIndex == 0 then           -- 合成
            EquipDuanZaoData:RequestHeCheng({
                self.qhitem1, self.qhitem2, self.qhitem3, 
                self.qhequipMakeIndex, self.qhitem3Makeid, 
                self.checkBoxIsSelected.selectedIndex, self.itemlistControlle.selectedIndex
            })
        elseif self.pageControlle.selectedIndex == 4 then      -- 装备赋予
            EquipDuanZaoData:RequestFuYu({
                self.qhitem1, self.qhitem2, self.qhitem3, 
                self.qhequipMakeIndex, self.checkBoxIsSelected.selectedIndex, 
                self.itemlistControlle.selectedIndex
            })
        else
            EquipDuanZaoData:RequestQiangHua({
                self.qhitem1, self.qhitem2, self.qhitem3, 
                self.qhequipMakeIndex, self.checkBoxIsSelected.selectedIndex, 
                self.itemlistControlle.selectedIndex
            })
        end
        FGUI:Controller_setSelectedIndex(self.additemControlle, 0)
    end)

    FGUI:setOnClickEvent(self.xzequip.closeitembtn, function()
        self:clearequip()
        self:succfont()
    end)
    FGUI:setOnClickEvent(self.xzitem1.closeitembtn, function()
        self:clearitem1()
        self:succfont()
    end)
    FGUI:setOnClickEvent(self.xzitem2.closeitembtn, function()
        self:clearitem2()
        self:succfont()
    end)
    FGUI:setOnClickEvent(self.xzqhitem1.closeitembtn, function()
        self:clearitem3()
    end)

    self.panl_additem = FGUI:ui_delegate(self.rightbg.panl_additem)
    FGUI:setOnClickEvent(self.panl_additem.bg, function()
        FGUI:Controller_setSelectedIndex(self.additemControlle,0)
    end)
    
    self:xyfitemlist()
    self:Listadditem()
end

-----------------------------------------------------------------------
--- baglist: 背包装备列表初始化
-----------------------------------------------------------------------
function EquipDuanZao:baglist()
    self.ListBag = self._ui.List_bag
    FGUI:GList_itemRenderer(self.ListBag, handler(self, self.ListViewCellsItemRenderer))
    FGUI:GList_setDefaultItem(self.ListBag, "ui://h4h4flrtoqrpk")
    FGUI:GList_setVirtual(self.ListBag)
    FGUI:GList_setNumItems(self.ListBag, (#bagequiplist <= 49 and 56 or #bagequiplist + 7))
    FGUI:GList_addOnClickItemEvent(self.ListBag, function(context)
        local itemRoot = FGUI:GetChild(context.data, "itemRoot")
        local index = FGUI:GetIntData(itemRoot)
        local selectedIndex = FGUI:GList_getSelectedIndex(self.ListBag)
        if bagequiplist[index] then
            -- 强化转移页面特殊处理
            if self.pageControlle.selectedIndex == 2 then
                -- 背包装备列表选中则更新xzqhitem1组件
                self:updateTransferEquipDisplay(bagequiplist[index], true)
            else
                -- 正常的装备选择逻辑
                self.selectEquipStdMode = bagequiplist[index].StdMode
                self.qhequipMakeIndex = bagequiplist[index].MakeIndex
                local itemData= SL:GetValue("ITEM_DATA", bagequiplist[index].Index)
                self.selectEquipQHTabIndex = itemData.EquipQHTabId
                -- 合成页面需要重新获取bagitemlist数据
                if self.pageControlle.selectedIndex == 0 then
                    self.selectEquipLv = itemData.NeedLevel
                    self:GetPageData()
                end
                self:GetAddItem()
                self:upitem2num()
                self:succfont()
            end
            self.page2selectindex = selectedIndex
        else
            if self.page2selectindex > 0 then
                FGUI:GList_setSelectedIndex(self.ListBag, self.page2selectindex)
            else
                FGUI:GList_removeSelection(self.ListBag, selectedIndex)
            end
        end
    end)
end

-----------------------------------------------------------------------
--- equiplist: 身上装备列表初始化
-----------------------------------------------------------------------
function EquipDuanZao:equiplist()
    self.ListEquip = self._ui.List_equip
    FGUI:GList_itemRenderer(self.ListEquip, handler(self, self.ListViewCellsEquipRenderer))
    FGUI:GList_setDefaultItem(self.ListEquip, "ui://h4h4flrtoqrpk")
    FGUI:GList_setVirtual(self.ListEquip)
    FGUI:GList_setNumItems(self.ListEquip, 49)
    FGUI:GList_addOnClickItemEvent(self.ListEquip, function(context)
        local itemRoot = FGUI:GetChild(context.data, "itemRoot")
        local index = FGUI:GetIntData(itemRoot)
        local selectedIndex = FGUI:GList_getSelectedIndex(self.ListEquip)
        if equipposlist[index] then
            -- 强化转移页面特殊处理
            if self.pageControlle.selectedIndex == 2 then
                -- 装备列表选中则更新xzequip组件
                self:updateTransferEquipDisplay(equipposlist[index], false)
            else
                -- 正常的装备选择逻辑
                self.selectEquipStdMode = equipposlist[index].StdMode
                self.qhequipMakeIndex = equipposlist[index].MakeIndex

                local itemData= SL:GetValue("ITEM_DATA", equipposlist[index].Index)
                self.selectEquipQHTabIndex = itemData.EquipQHTabId
                -- 合成页面需要重新获取bagitemlist数据
                if self.pageControlle.selectedIndex == 0 then                    
                    self.selectEquipLv = itemData.NeedLevel
                    self:GetPageData()
                end
                self:GetAddItem()
                self:upitem2num()
                self:succfont()
            end
            self.page1selectindex = selectedIndex
        else
            if self.page1selectindex > 0 then
                FGUI:GList_setSelectedIndex(self.ListEquip, self.page1selectindex)
            else
                FGUI:GList_removeSelection(self.ListEquip, selectedIndex)
            end
        end
    end)
end

-----------------------------------------------------------------------
--- xyfitemlist: 幸运符列表初始化
-----------------------------------------------------------------------
function EquipDuanZao:xyfitemlist()
    self.addxyflist = self.panl_additem.additemlist1
    FGUI:GList_itemRenderer(self.addxyflist, handler(self, self.ListViewCellsxyfitem))
    FGUI:GList_setDefaultItem(self.addxyflist, "ui://h4h4flrtoqrp15")
    FGUI:GList_setVirtual(self.addxyflist)
    FGUI:GList_setNumItems(self.addxyflist, #xyfitemlist)
    FGUI:GList_addOnClickItemEvent(self.addxyflist, function(context)
        local itemRoot = FGUI:GetChild(context.data, "itemRoot")
        local index = FGUI:GetIntData(itemRoot)
        local itemnum = SL:GetValue("ITEMCOUNT", xyfitemlist[index])
        if itemnum == 0 then
            return
        end
        self.clickobjitem = context.data
        if xyfitemlist[index] then
            local itemData = SL:GetValue("ITEM_DATA", xyfitemlist[index])
            if FGUI:GetChildCount(self.xzitem1.itemRoot) > 0 then
                FGUI:RemoveChildAt(self.xzitem1.itemRoot, 0, true)
            end
            local extData = {}
            extData.hideTip = false -- 是否隐藏默认的Tip
            extData.itemTipData = itemData -- 对应ItemTips.ShowTip的参数
            extData.clickCallback = false -- 单击事件回调
            extData.doubleClickCallback = true -- 双击事件回调
            extData.bgVisible = true -- 背景隐藏
            local itemobj = ItemUtil:ItemShow_Create(itemData, self.xzitem1.itemRoot, extData) 
            if itemobj.hideArrow then
                itemobj:hideArrow()
            end
            self.qhitem1 = xyfitemlist[index]
            self:succfont()
        end
        FGUI:Controller_setSelectedIndex(self.additemControlle,0)
        FGUI:setVisible(self.xzitem1.closeitembtn, true)
        xzequipstate = {self.itemlistControlle.selectedIndex, self.pageControlle.selectedIndex, index}
    end)
end

-----------------------------------------------------------------------
--- ListViewCellsItemRenderer: 背包装备列表渲染函数
-----------------------------------------------------------------------
function EquipDuanZao:ListViewCellsItemRenderer(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    FGUI:SetIntData(itemRoot, idx + 1)
    if FGUI:GetChildCount(itemRoot) > 0 then
        FGUI:RemoveChildAt(itemRoot, 0, true)
    end
    if bagequiplist[idx + 1] then
        local extData = {}
        extData.hideTip = true -- 是否隐藏默认的Tip
        extData.itemTipData = bagequiplist[idx + 1]
        extData.clickCallback = false -- 单击事件回调
        extData.doubleClickCallback = true -- 双击事件回调
        extData.bgVisible = false -- 背景隐藏
        local itemobj = ItemUtil:ItemShow_Create(bagequiplist[idx + 1], itemRoot, extData) 
        if itemobj.hideArrow then
            itemobj:hideArrow()
        end
    end
end

-----------------------------------------------------------------------
--- ListViewCellsEquipRenderer: 身上装备列表渲染函数
-----------------------------------------------------------------------
function EquipDuanZao:ListViewCellsEquipRenderer(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    FGUI:SetIntData(itemRoot, idx + 1)
    if FGUI:GetChildCount(itemRoot) > 0 then
        FGUI:RemoveChildAt(itemRoot, 0, true)
    end
    if equipposlist[idx + 1] then
        local extData = {}
        extData.hideTip = true -- 是否隐藏默认的Tip
        extData.itemTipData = equipposlist[idx + 1]
        extData.clickCallback = false -- 单击事件回调
        extData.doubleClickCallback = true -- 双击事件回调
        extData.bgVisible = false -- 背景隐藏
        local itemobj = ItemUtil:ItemShow_Create(equipposlist[idx + 1], itemRoot, extData) 
        if itemobj.hideArrow then
            itemobj:hideArrow()
        end
    end
end

-----------------------------------------------------------------------
--- ListViewCellsxyfitem: 幸运符列表渲染函数
-----------------------------------------------------------------------
function EquipDuanZao:ListViewCellsxyfitem(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    FGUI:SetIntData(itemRoot, idx + 1)
    if xyfitemlist[idx + 1] then
        local itemData = SL:GetValue("ITEM_DATA", xyfitemlist[idx + 1])
        local itemnum = SL:GetValue("ITEMCOUNT", xyfitemlist[idx + 1])
        local extData = {}
        extData.hideTip = false -- 是否隐藏默认的Tip
        extData.itemTipData = itemData
        extData.clickCallback = false -- 单击事件回调
        extData.doubleClickCallback = true -- 双击事件回调
        extData.bgVisible = true -- 背景隐藏
        local itemobj = ItemUtil:ItemShow_Create(itemData, itemRoot, extData) 
        if itemobj.hideArrow then
            itemobj:hideArrow()
        end
        local itemname = SL:GetValue("ITEM_NAME", xyfitemlist[idx + 1])
        local name = FGUI:GetChild(item, "name")
        local att = FGUI:GetChild(item, "att")
        local num = FGUI:GetChild(item, "num")
        FGUI:GTextField_setText(name, "" .. itemname)
        FGUIFunction:ScrollText_setString(att, EquipQHItemTab[xyfitemlist[idx + 1]]['TIPS'] or "", 3.5, 0)
        FGUI:GTextField_setText(num, "" .. itemnum)
    end
end

-----------------------------------------------------------------------
--- GetPageData: 获取当前页签数据，重新组织equipposlist、bagequiplist、bagitemlist
-----------------------------------------------------------------------
function EquipDuanZao:GetPageData()
    self.page1selectindex = 0
    self.page2selectindex = 0
    local page = self.pageControlle.selectedIndex + 1
    equipposlist = {}
    bagequiplist = {}
    bagitemlist = { {}, {}, {} }
    local bagData = SL:GetValue("BAG_DATA")
    local csindex = 0
    for i, data in pairs(bagData) do
        local isequip = SL:GetValue("BAG_ITEM_IS_EQUIP", data, data.ID)
        if isequip then
            local equipData = SL:GetValue("BAG_DATA_BY_MAKEINDEX", i) 
            local yhcnum, maxhcnum, yjxlv = 0, equipData.SyntheticStone or 0, 0
            if equippos2[page][equipData.StdMode] then
                for j = 1, #equipData.Values do
                    if page == 1 and equipData.Values[j]['Id'] == 2 then
                        yhcnum = equipData.Values[j]['Value']
                        break
                    end
                end
                if (page == 1 and (yhcnum < maxhcnum or maxhcnum == 0)) or page ~= 1 then
                    if page == 4 then
                        local itemData= SL:GetValue("ITEM_DATA", equipData.Index)
                        if itemData.NeedLevel >= 60 then
                            table.insert(bagequiplist, equipData)
                        end
                    else
                        table.insert(bagequiplist, equipData)
                    end                    
                end
                csindex = csindex + 1
            end
        else
            if EquipQHItemTab[data.ID] then
                if page == 1 and EquipQHItemTab[data.ID].itemtype == 1 and self.selectEquipLv then
                    --需增加等级限制
                    local minLv = EquipQHItemTab[data.ID]['equipMinLv']
                    local maxLv = EquipQHItemTab[data.ID]['equipMaxLv']
                    local canAdd = true
                    if minLv and self.selectEquipLv < minLv then
                        canAdd = false
                    end
                    if maxLv and self.selectEquipLv > maxLv then
                        canAdd = false
                    end
                    if canAdd then
                        if EquipQHItemTab[data.ID]['limitpos'] == 5 then  -- 武器
                            table.insert(bagitemlist[1], data)
                        else
                            table.insert(bagitemlist[2], data)
                        end
                    end                    
                end
            end
        end
    end
    for k, v in pairs(EquipQHItemTab) do
        local data = SL:GetValue("ITEM_DATA", k)
        if v.itemtype == 2 and (page == 2 or page == 4 or page == 5) then
            if v['limitpos'] == 5 then
                table.insert(bagitemlist[1], data)
            else
                table.insert(bagitemlist[2], data)
            end
        elseif page == 5 and v['itemtype'] == 4 then
            if v['limitpos'] == 5 then
                table.insert(bagitemlist[1], data)
            elseif v['limitpos'] == 3 then
                table.insert(bagitemlist[2], data)
            end
        elseif page == 5 and v['itemtype'] == 5 then
            table.insert(bagitemlist[3], data)
        end
    end  
 
    for i = 1, #equippos[page] do
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", equippos[page][i])
        if equipData then
            local yhcnum, maxhcnum, yjxlv = 0, equipData.SyntheticStone or 0, 0
            if equippos2[page][equipData.StdMode] then
                for j = 1, #equipData.Values do
                    if page == 1 and equipData.Values[j]['Id'] == 2 then
                        yhcnum = equipData.Values[j]['Value']
                        break
                    end
                end
                if (page == 1 and (yhcnum < maxhcnum or maxhcnum == 0)) or page ~= 1 then
                    if page == 4 then
                        local itemData= SL:GetValue("ITEM_DATA", equipData.Index)
                        if itemData.NeedLevel >= 60 then
                            table.insert(equipposlist, equipData)
                        end
                    else
                        table.insert(equipposlist, equipData)
                    end   
                end
            end
        end
    end
end

-----------------------------------------------------------------------
--- RefrsList: 刷新所有列表
-----------------------------------------------------------------------
function EquipDuanZao:RefrsList()
    FGUI:GList_setNumItems(self.ListBag, (#bagequiplist <= 49 and 56 or #bagequiplist + 7))
    FGUI:GList_refreshVirtualList(self.ListBag)  -- 刷新背包装备列表

    FGUI:GList_setNumItems(self.ListEquip, 49)
    FGUI:GList_refreshVirtualList(self.ListEquip)  -- 刷新身上装备列表

    FGUI:GList_setNumItems(self.addpanlobj, #self.additemshowlist)
    FGUI:GList_refreshVirtualList(self.addpanlobj)  -- 刷新添加道具列表

    FGUI:GList_setNumItems(self.addxyflist, #xyfitemlist)
    FGUI:GList_refreshVirtualList(self.addxyflist)  -- 刷新幸运符列表
end

-----------------------------------------------------------------------
--- GetAddItem: 获取当前提升道具数据并过滤符合等级的道具
-----------------------------------------------------------------------
function EquipDuanZao:GetAddItem()
    local page = self.pageControlle.selectedIndex + 1
    if page == 1 then
        if self.selectEquipStdMode == 5 then
            self.additemshowlist0 = bagitemlist[1]
        else
            self.additemshowlist0 = bagitemlist[2]
        end
        table.sort(self.additemshowlist0, function(a, b)
            if a.ExAbil then
                if a.ExAbil.abil[1]['v'][1][2] == b.ExAbil.abil[1]['v'][1][2] then
                    return a.ExAbil.abil[1]['v'][1][3] > b.ExAbil.abil[1]['v'][1][3]
                else
                    return a.ExAbil.abil[1]['v'][1][2] > b.ExAbil.abil[1]['v'][1][2]
                end
            end
        end)
        self:xyfjiaohao()
        self:itemsxjiaohao()
    elseif page == 2 then
        if self.selectEquipStdMode == 5 then
            self.additemshowlist0 = bagitemlist[1]
        else
            self.additemshowlist0 = bagitemlist[2]
        end
        self:xyfjiaohao()
        self:itemtsjiaohao()
    elseif page == 3 then
        self.additemshowlist0 = bagitemlist[1]    
        self:itemsxjiaohao()
    elseif page == 4 then
        self.additemshowlist0 = bagitemlist[1]
        self:xyfjiaohao()
        self:itemtsjiaohao()
    elseif page == 5 then
        if self.addlistshowControlle.selectedIndex <= 1 then
            if self.selectEquipStdMode == 5 then
                self.additemshowlist0 = bagitemlist[1]
            elseif self.selectEquipStdMode == 3 then
                self.additemshowlist0 = bagitemlist[2]
            end
        elseif self.addlistshowControlle.selectedIndex == 2 then
            self.additemshowlist0 = bagitemlist[3]
        end
        self:xyfjiaohao()
        self:itemtsjiaohao()
        self:itemsxjiaohao()
    end
    local copylist = SL:CopyData(self.additemshowlist0)
    if #copylist > 0 and page ~= 3 then
        for i = #copylist, 1, -1 do
            local itemid = copylist[i].ID
            local minlv = EquipQHItemTab[itemid]['level_arr'][1] or 0
            local maxlv = EquipQHItemTab[itemid]['level_arr'][2] or 999
            if self.qhequiplv < minlv or self.qhequiplv > maxlv then
                table.remove(copylist, i)
            end
        end
    end
    self.additemshowlist = copylist

    self:addequipshow()
    FGUI:setVisible(self.rightbg.xzequip, true)
    FGUI:setVisible(self.xzequip.closeitembtn, true)

    if page == 5 and self.addlistshowControlle.selectedIndex == 2 then
        if self.qhequiplv > 0 then
            local itemData = {}
            if self.itemlistControlle.selectedIndex == 0 then
                itemData = SL:GetValue("EQUIP_DATA_BY_MAKEINDEX", self.qhequipMakeIndex)
            else
                itemData = SL:GetValue("BAG_DATA_BY_MAKEINDEX", self.qhequipMakeIndex)
            end
            local itemConfig = itemData.ExAbil
            local xhitemid = 0
            if itemConfig.abil[2] then
                local qhtab = itemConfig.abil[2]['v']
                for i = 1, #EquipFYTab[1]['attrid_arr'] do
                    if qhtab[1][2] == EquipFYTab[1]['attrid_arr'][i] or qhtab[1][2] == EquipFYTab[2]['attrid_arr'][i] then
                        xhitemid = EquipFYTab[1]['itemid_arr'][i]
                        break
                    end
                end
            end
            for i = 1, #bagitemlist[3] do
                if bagitemlist[3][i].ID == xhitemid then
                    self.additemshowlist = { bagitemlist[3][i] }
                    break
                end
            end
        end
    end
    FGUI:GList_setNumItems(self.addpanlobj, #self.additemshowlist)
    FGUI:GList_refreshVirtualList(self.addpanlobj)
end

-----------------------------------------------------------------------
--- xyfjiaohao: 幸运符加号显示
-----------------------------------------------------------------------
function EquipDuanZao:xyfjiaohao()
    self.xyfSelected = FGUI:getController(self.rightbg.xzitem1, "c2")
    FGUI:Controller_setSelectedIndex(self.xyfSelected,1)
end

-----------------------------------------------------------------------
--- itemtsjiaohao: 提升材料加号显示
-----------------------------------------------------------------------
function EquipDuanZao:itemtsjiaohao()
    self.itemtsSelected = FGUI:getController(self.rightbg.xzitem2, "c2")
    FGUI:Controller_setSelectedIndex(self.itemtsSelected,1)
end

-----------------------------------------------------------------------
--- itemsxjiaohao: 属性石加号显示
-----------------------------------------------------------------------
function EquipDuanZao:itemsxjiaohao()
    self.itemsxSelected = FGUI:getController(self.rightbg.xzqhitem1, "c2")
    FGUI:Controller_setSelectedIndex(self.itemsxSelected,1)
end

-----------------------------------------------------------------------
--- xyfjiaohaoyc: 幸运符隐藏
-----------------------------------------------------------------------
function EquipDuanZao:xyfjiaohaoyc()
    self.xyfSelected = FGUI:getController(self.rightbg.xzitem1, "c2")
    FGUI:Controller_setSelectedIndex(self.xyfSelected,0)
end

-----------------------------------------------------------------------
--- itemtsjiaohaoyc: 提升材料隐藏
-----------------------------------------------------------------------
function EquipDuanZao:itemtsjiaohaoyc()
    self.itemtsSelected = FGUI:getController(self.rightbg.xzitem2, "c2")
    FGUI:Controller_setSelectedIndex(self.itemtsSelected,0)
end

-----------------------------------------------------------------------
--- itemsxjiaohaoyc: 属性石隐藏
-----------------------------------------------------------------------
function EquipDuanZao:itemsxjiaohaoyc()
    self.itemsxSelected = FGUI:getController(self.rightbg.xzqhitem1, "c2")
    FGUI:Controller_setSelectedIndex(self.itemsxSelected,0)
end

-----------------------------------------------------------------------
--- checkBoxIsSelectedClicked: 复选框点击事件
-----------------------------------------------------------------------
function EquipDuanZao:checkBoxIsSelectedClicked()
    FGUI:Controller_setSelectedIndex(self.checkBoxIsSelected,self.checkBoxIsSelected.selectedIndex == 1 and 0 or 1)
    self:succfont()
end

-----------------------------------------------------------------------
--- btnTipsClicked: 点击tips事件
-----------------------------------------------------------------------
function EquipDuanZao:btnTipsClicked()
    FGUI:Controller_setSelectedIndex(self.tipsControlle,self.tipsControlle.selectedIndex == 1 and 0 or 1)
end

-----------------------------------------------------------------------
--- btnSelectItemClicked1: 幸运符点击事件
-----------------------------------------------------------------------
function EquipDuanZao:btnSelectItemClicked1(content)
    if self.selectEquipStdMode == 0 then return end
    if self.qhitem1 ~= 0 then return end
    FGUI:Controller_setSelectedIndex(self.additemControlle,self.additemControlle.selectedIndex == 1 and 0 or 1)
    FGUI:Controller_setSelectedIndex(self.addlistshowControlle,0)
end

-----------------------------------------------------------------------
--- btnSelectItemClicked2: 提升材料点击事件
-----------------------------------------------------------------------
function EquipDuanZao:btnSelectItemClicked2(content)
    if self.selectEquipStdMode == 0 then return end
    if self.qhitem2 ~= 0 then return end
    FGUI:Controller_setSelectedIndex(self.additemControlle,self.additemControlle.selectedIndex == 1 and 0 or 1)
    FGUI:Controller_setSelectedIndex(self.addlistshowControlle,1)
    self:GetAddItem()
end

-----------------------------------------------------------------------
--- btnSelectItemClicked3: 属性石类特殊材料点击事件
-----------------------------------------------------------------------
function EquipDuanZao:btnSelectItemClicked3(content)
    if self.selectEquipStdMode == 0 then return end
    if self.qhitem3 ~= 0 then return end
    FGUI:Controller_setSelectedIndex(self.additemControlle,self.additemControlle.selectedIndex == 1 and 0 or 1)
    FGUI:Controller_setSelectedIndex(self.addlistshowControlle,2)
    self:GetAddItem()
end

-----------------------------------------------------------------------
--- clearitem1: 清理幸运符显示框
-----------------------------------------------------------------------
function EquipDuanZao:clearitem1()
    if self.xzitem1 and FGUI:GetChildCount(self.xzitem1.itemRoot) > 0 then
        FGUI:RemoveChildAt(self.xzitem1.itemRoot, 0, true)
    end
    self.qhitem1 = 0
    FGUI:setVisible(self.xzitem1.closeitembtn, false)
end

-----------------------------------------------------------------------
--- clearitem2: 清理提升道具显示框
-----------------------------------------------------------------------
function EquipDuanZao:clearitem2()
    if self.xzitem2 and FGUI:GetChildCount(self.xzitem2.itemRoot) > 0 then
        FGUI:RemoveChildAt(self.xzitem2.itemRoot, 0, true)
    end
    self.qhitem2 = 0
    FGUI:setVisible(self.xzitem2.closeitembtn, false)
end

-----------------------------------------------------------------------
--- clearitem3: 清理其他消耗材料显示框
-----------------------------------------------------------------------
function EquipDuanZao:clearitem3()
    if self.xzqhitem1 and FGUI:GetChildCount(self.xzqhitem1.itemRoot) > 0 then
        FGUI:RemoveChildAt(self.xzqhitem1.itemRoot, 0, true)
    end
    self.qhitem3 = 0
    FGUI:setVisible(self.xzqhitem1.closeitembtn, false)
    if self.rightbg.qhfont then
        FGUI:GRichTextField_setText(self.rightbg.qhfont, "")
    end
    if self.xzqhitem2 and FGUI:GetChildCount(self.xzqhitem2.itemRoot) > 0 then
        FGUI:RemoveChildAt(self.xzqhitem2.itemRoot, 0, true)
    end
    if self.xzqhitem2 and self.selectEquipStdMode == 0 then
        FGUI:setVisible(self.xzqhitem2.itemRoot, false)
    end
    if self.rightbg.qhfont2 and self.selectEquipStdMode == 0 then
        FGUI:GRichTextField_setText(self.rightbg.qhfont2, "")
    elseif self.rightbg.qhfont2 and self.pageControlle.selectedIndex ~= 5 then
        FGUI:GRichTextField_setText(self.rightbg.qhfont2, "")
    end
    if self.rightbg.costfont4 then
        FGUI:GTextField_setText(self.rightbg.costfont4, "")
    end
    FGUI:setVisible(self.rightbg.costfont2, false)
    FGUI:setVisible(self.rightbg.costitem1, false)
end

-----------------------------------------------------------------------
--- addequipshow: 选中道具右侧更新显示
-----------------------------------------------------------------------
function EquipDuanZao:addequipshow()
    if FGUI:GetChildCount(self.xzequip.itemRoot) > 0 then
        FGUI:RemoveChildAt(self.xzequip.itemRoot, 0, true)
    end
    local itemData = {}
    if self.qhequipMakeIndex ~= 0 then
        if self.itemlistControlle.selectedIndex == 0 then
            itemData = SL:GetValue("EQUIP_DATA_BY_MAKEINDEX", self.qhequipMakeIndex)
        else
            itemData = SL:GetValue("BAG_DATA_BY_MAKEINDEX", self.qhequipMakeIndex)
        end
        local extData = {}
        extData.hideTip = false -- 是否隐藏默认的Tip
        extData.itemTipData = itemData
        extData.clickCallback = false -- 单击事件回调
        extData.doubleClickCallback = true -- 双击事件回调
        extData.bgVisible = false -- 背景隐藏
        self.qhequiplv = 0
        if self.pageControlle.selectedIndex == 0 and itemData then
            for i = 1, #itemData.Values do
                if itemData.Values[i]['Id'] == 2 then
                    self.qhequiplv = itemData.Values[i]['Value']
                    break
                end
            end
        elseif self.pageControlle.selectedIndex == 4 and itemData then  -- 装备赋予
            for i = 1, #itemData.Values do
                if itemData.Values[i]['Id'] == 1 then
                    self.qhequiplv = itemData.Values[i]['Value']
                    break
                end
            end
        elseif itemData then
            for i = 1, #itemData.Values do
                if itemData.Values[i]['Id'] == 0 then
                    self.qhequiplv = itemData.Values[i]['Value']
                    break
                end
            end
        end
        local itemobj = ItemUtil:ItemShow_Create(itemData, self.xzequip.itemRoot, extData) 
        if itemobj.hideArrow then
            itemobj:hideArrow()
        end
    end
end

-----------------------------------------------------------------------
--- clearequip: 清理右侧数据，重置状态
-----------------------------------------------------------------------
function EquipDuanZao:clearequip()
    if FGUI:GetChildCount(self.xzequip.itemRoot) > 0 then
        FGUI:RemoveChildAt(self.xzequip.itemRoot, 0, true)
    end
    self.selectEquipStdMode = 0
    self.qhequipMakeIndex = 0
    self.selectEquipQHTabIndex = nil
    self.selectEquipLv = 0

    FGUI:setVisible(self.rightbg.xzequip, false)
    FGUI:GList_clearSelection(self.ListBag)
    FGUI:GList_clearSelection(self.ListEquip)
    self:xyfjiaohaoyc()
    self:itemtsjiaohaoyc()
    self:itemsxjiaohaoyc()
    self:clearitem1()
    self:clearitem2()
    self:clearitem3()
end

-----------------------------------------------------------------------
--- upitem2num: 道具消耗更新（提升材料更新）
-----------------------------------------------------------------------
function EquipDuanZao:upitem2num()
    if self.pageControlle.selectedIndex == 0 or self.pageControlle.selectedIndex == 4 then
        self:clearitem3()
        return
    end
    local curQHTabData = EquipQHTab[equippos3[self.selectEquipStdMode]]
    if self.selectEquipQHTabIndex then
        curQHTabData = EquipQHTab[self.selectEquipQHTabIndex]
    end
    local xhitemtab1, xhnumtab1 = curQHTabData['xhitemList'][self.qhequiplv+1], curQHTabData['xhnumList'][self.qhequiplv+1]
    local xhitemid1, xhitemnum1 = 0, 0
    if type(xhitemtab1) == "number" then
        xhitemid1, xhitemnum1 = xhitemtab1, xhnumtab1
    elseif type(xhitemtab1) == "table" then
        xhitemid1, xhitemnum1 = xhitemtab1[1], xhnumtab1[1]
    end

    local itemnum1 = SL:GetValue("ITEMCOUNT", xhitemid1)
    local itemData = SL:GetValue("ITEM_DATA", xhitemid1)
    local extData = {}
    extData.hideTip = false
    extData.itemTipData = itemData
    extData.clickCallback = false
    extData.doubleClickCallback = true
    extData.bgVisible = true
    local color = "#FF0000"
    if itemnum1 >= xhitemnum1 then
        color = "#00FF00"
    end
    local itemobj = ItemUtil:ItemShow_Create(itemData, self.xzqhitem1.itemRoot, extData) 
    if itemobj.hideArrow then
        itemobj:hideArrow()
    end
    FGUI:GRichTextField_setText(self.rightbg.qhfont, "<font color='" .. color .. "'>" .. xhitemnum1 .. "</font>")
    FGUI:setVisible(self.rightbg.xzqhitem2, false)
    FGUI:setVisible(self.rightbg.qhfont2, false)
    if type(xhitemtab1) == "table" and #xhitemtab1 > 1 then
        FGUI:setVisible(self.rightbg.xzqhitem2, true)
        FGUI:setVisible(self.rightbg.qhfont2, true)
        local xhitemid, xhitemnum = xhitemtab1[2], xhnumtab1[2]
        local itemnum = SL:GetValue("ITEMCOUNT", xhitemid)
        local itemData = SL:GetValue("ITEM_DATA", xhitemid)
        local extData = {}
        extData.hideTip = false
        extData.itemTipData = itemData
        extData.clickCallback = false
        extData.doubleClickCallback = true
        extData.bgVisible = true
        local color = "#FF0000"
        if itemnum >= xhitemnum then
            color = "#00FF00"
        end
        local itemobj = ItemUtil:ItemShow_Create(itemData, self.xzqhitem2.itemRoot, extData)
        if itemobj.hideArrow then
            itemobj:hideArrow()
        end
        FGUI:setVisible(self.xzqhitem2.itemRoot, true)
        FGUI:GRichTextField_setText(self.rightbg.qhfont2, "<font color='" .. color .. "'>" .. xhitemnum .. "</font>")
    end
end

-----------------------------------------------------------------------
--- succfont: 成功率更新显示
-----------------------------------------------------------------------
function EquipDuanZao:succfont()
    local basesuc = 0
    if EquipQHItemTab[self.qhitem1] then
        local minlv, maxlv = EquipQHItemTab[self.qhitem1]['level_arr'][1] or 0, EquipQHItemTab[self.qhitem1]['level_arr'][2] or 999
        if self.qhequiplv >= minlv and self.qhequiplv <= maxlv and EquipQHItemTab[self.qhitem1]['addsuccess'] then
            basesuc = basesuc + EquipQHItemTab[self.qhitem1]['addsuccess']
        end
    end
    if EquipQHItemTab[self.qhitem2] then
        local minlv, maxlv = EquipQHItemTab[self.qhitem2]['level_arr'][1] or 0, EquipQHItemTab[self.qhitem2]['level_arr'][2] or 999
        if self.qhequiplv >= minlv and self.qhequiplv <= maxlv and EquipQHItemTab[self.qhitem2]['addsuccess'] then
            basesuc = basesuc + EquipQHItemTab[self.qhitem2]['addsuccess']
        end
    end
    if equippos3[self.selectEquipStdMode] then
        local gxyb, gxcgl = 0, 0
        if self.pageControlle.selectedIndex == 0 then  -- 合成
            gxyb = EquipHCTab[equippos3[self.selectEquipStdMode]]['addsucc_arr'][1]
            gxcgl = EquipHCTab[equippos3[self.selectEquipStdMode]]['addsucc_arr'][2]
        elseif self.pageControlle.selectedIndex == 4 then  -- 装备赋予
            gxyb = EquipFYTab[equippos3[self.selectEquipStdMode]]['addsucc_arr'][1]
            gxcgl = EquipFYTab[equippos3[self.selectEquipStdMode]]['addsucc_arr'][2]
        else
            local curQHTabData = EquipQHTab[equippos3[self.selectEquipStdMode]]
            if self.selectEquipQHTabIndex then
                curQHTabData = EquipQHTab[self.selectEquipQHTabIndex]
            end
            gxyb = curQHTabData['addsucc_arr'][1]
            gxcgl = curQHTabData['addsucc_arr'][2]
        end
        if self.checkBoxIsSelected.selectedIndex == 1 then
            basesuc = basesuc + gxcgl
        end
        FGUI:GTextField_setText(self.rightbg.costfont3, "成功率加成：" .. basesuc .. "%")
        FGUI:GTextField_setText(self.rightbg.costfont1, "使用" .. gxyb .. "元宝提升" .. gxcgl .. "%成功率")
    end
    if self.qhequipMakeIndex ~= 0 and (self.pageControlle.selectedIndex == 1 or self.pageControlle.selectedIndex == 3) then
        if self.pageControlle.selectedIndex == 3 then
            if self.qhequiplv > 4 then
                FGUI:GTextField_setText(self.rightbg.costfont4, "5-10级 加工失败后首饰破碎")
            else
                FGUI:GTextField_setText(self.rightbg.costfont4, "0-4级 加工失败后首饰降级")
            end
        elseif self.pageControlle.selectedIndex == 1 then
            if self.qhequiplv > 7 then
                FGUI:GTextField_setText(self.rightbg.costfont4, "8-15级 强化失败后装备破碎")
            else
                FGUI:GTextField_setText(self.rightbg.costfont4, "0-7级 强化失败后装备降级")
            end
        end
    else
        FGUI:GTextField_setText(self.rightbg.costfont4, "")
    end
end

-----------------------------------------------------------------------
--- Listadditem: 点击添加道具框展示列表
-----------------------------------------------------------------------
function EquipDuanZao:Listadditem()
    self.panl_additem = FGUI:ui_delegate(self.rightbg.panl_additem)
    self.addpanlobj = self.panl_additem['additemlist2']
    FGUI:GList_itemRenderer(self.addpanlobj, handler(self, self.ListadditemRender))
    FGUI:GList_setDefaultItem(self.addpanlobj, "ui://h4h4flrtoqrp15")
    FGUI:GList_setVirtual(self.addpanlobj)
    FGUI:GList_setNumItems(self.addpanlobj, #self.additemshowlist)
    FGUI:GList_addOnClickItemEvent(self.addpanlobj, function(context)
        local itemRoot = FGUI:GetChild(context.data, "itemRoot")
        local index = FGUI:GetIntData(itemRoot)
        local itemnum = SL:GetValue("ITEMCOUNT", self.additemshowlist[index].ID)
        if itemnum == 0 then
            return
        end
        self.clickobjitem = context.data

        local minlv = EquipQHItemTab[self.additemshowlist[index].ID]['level_arr'][1] or 0
        local maxlv = EquipQHItemTab[self.additemshowlist[index].ID]['level_arr'][2] or 999
        local itemtype = EquipQHItemTab[self.additemshowlist[index].ID]['itemtype']
        
        if self.qhequipMakeIndex == 0 then
            SL:ShowScreenCenterTip("请选择合适的道具！", 251, 0, 200, 1, 0.3)
            return
        end
        if self.qhequiplv >= minlv and self.qhequiplv <= maxlv then
            if self.addlistshowControlle.selectedIndex == 1 then
                local extData = {}
                extData.hideTip = false
                extData.itemTipData = self.additemshowlist[index]
                extData.clickCallback = false
                extData.doubleClickCallback = true
                extData.bgVisible = true
                local itemobj = ItemUtil:ItemShow_Create(self.additemshowlist[index], self.xzitem2.itemRoot, extData) 
                if itemobj.hideArrow then
                    itemobj:hideArrow()
                end
                self.qhitem2 = self.additemshowlist[index].ID
                FGUI:setVisible(self.xzitem2.closeitembtn, true)
                self:succfont()
            elseif self.addlistshowControlle.selectedIndex == 2 then
                local extData = {}
                extData.hideTip = false
                extData.itemTipData = self.additemshowlist[index]
                extData.clickCallback = false
                extData.doubleClickCallback = true
                extData.bgVisible = true
                local itemobj = ItemUtil:ItemShow_Create(self.additemshowlist[index], self.xzqhitem1.itemRoot, extData) 
                if itemobj.hideArrow then
                    itemobj:hideArrow()
                end
                self.qhitem3 = self.additemshowlist[index].ID
                self.qhitem3Makeid = self.additemshowlist[index].MakeIndex
                FGUI:setVisible(self.xzqhitem1.closeitembtn, true)
            end
        else
            SL:ShowScreenCenterTip("使用等级不满足！", 251, 0, 200, 1, 1)
            return
        end
        xzequipstate = { self.itemlistControlle.selectedIndex, self.pageControlle.selectedIndex, index }
        FGUI:Controller_setSelectedIndex(self.additemControlle,0)
    end)
end

-----------------------------------------------------------------------
--- ListadditemRender: 添加道具列表渲染函数
-----------------------------------------------------------------------
function EquipDuanZao:ListadditemRender(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    FGUI:SetIntData(itemRoot, idx + 1)
    if self.additemshowlist[idx + 1] then
        local extData = {}
        extData.hideTip = false
        extData.itemTipData = self.additemshowlist[idx + 1]
        extData.clickCallback = false
        extData.doubleClickCallback = true
        extData.bgVisible = true
        local itemobj = ItemUtil:ItemShow_Create(self.additemshowlist[idx + 1], itemRoot, extData) 
        if itemobj.hideArrow then
            itemobj:hideArrow()
        end
        local itemname = SL:GetValue("ITEM_NAME", self.additemshowlist[idx + 1].ID)
        local itemnum = SL:GetValue("ITEMCOUNT", self.additemshowlist[idx + 1].ID)
        local name = FGUI:GetChild(item, "name")
        local att = FGUI:GetChild(item, "att")
        local num = FGUI:GetChild(item, "num")
        FGUI:GTextField_setText(name, "" .. itemname)
        local attrstr = EquipQHItemTab[self.additemshowlist[idx + 1].ID]['TIPS'] or ""
        if EquipQHItemTab[self.additemshowlist[idx + 1].ID]['itemtype'] == 1 or 
            EquipQHItemTab[self.additemshowlist[idx + 1].ID]['itemtype'] == 6 then
            itemnum = ""
        end
        FGUI:GTextField_setText(num, "" .. itemnum)
  
       
        if self.addlistshowControlle.selectedIndex == 2 and (self.pageControlle.selectedIndex == 0) then
            local itemConfig = self.additemshowlist[idx+1].ExAbil
            local suitStr = ""
            if itemConfig and itemConfig.abil[1] then
                local qhtab = itemConfig.abil[1]['v']
                if qhtab then
                    local attId     = qhtab[1][2] or 0     -- 属性ID 绑定表
                    local name = attrConfigs[attId]['Name'].."："
		            local percent   = attrConfigs[attId]['Type'] or 0   -- 是否是百分比
		            local value     = qhtab[1][3] or 0  -- 属性值
		            if percent == 1 then
		            	value = string.format("%.1f", value / 100) * 10 / 10 .. "%"  
		            end
                    attrstr = ""..name..value
                end
            end
        end
        -- dump(attrstr)
        FGUIFunction:ScrollText_setString(att, attrstr, 3.5, 0)
    end
end

-----------------------------------------------------------------------
--- upitem2num: 道具消耗更新（提升材料更新）
-----------------------------------------------------------------------
function EquipDuanZao:upitem2num_transfer()
    if self.pageControlle.selectedIndex ~= 2 then       
        return
    end
   
    FGUI:setVisible(self.rightbg.xzqhitem2, true)
    FGUI:setVisible(self.rightbg.qhfont2, true)
    local xhitemid, xhitemnum = 143, 5
    local itemnum = SL:GetValue("ITEMCOUNT", xhitemid)
    local itemData = SL:GetValue("ITEM_DATA", xhitemid)
    local extData = {}
    extData.hideTip = false
    extData.itemTipData = itemData
    extData.clickCallback = false
    extData.doubleClickCallback = true
    extData.bgVisible = true
    local color = "#FF0000"
    if itemnum >= xhitemnum then
        color = "#00FF00"
    end
    local itemobj = ItemUtil:ItemShow_Create(itemData, self.xzqhitem2.itemRoot, extData)
    if itemobj.hideArrow then
        itemobj:hideArrow()
    end
    FGUI:setVisible(self.xzqhitem2.itemRoot, true)
    FGUI:GRichTextField_setText(self.rightbg.qhfont2, "<font color='" .. color .. "'>" .. xhitemnum .. "</font>")
end


-----------------------------------------------------------------------
--- updateTransferEquipDisplay: 更新强化转移装备显示
-- @param equipData 装备数据
-- @param isSource 是否为源装备(true=源装备/xzequip, false=目标装备/xzqhitem1)
-----------------------------------------------------------------------
function EquipDuanZao:updateTransferEquipDisplay(equipData, isSource)
    -- 根据isSource选择要更新的组件
    -- 身上装备列表 -> 更新xzequip (目标装备区)
    -- 背包装备列表 -> 更新xzqhitem1 (源装备区)
    local uiComponent = self.xzequip
    local makeIndexVar = "targetEquipMakeIndex"
    local levelVar = "targetEquipLevel"
    if isSource then
        uiComponent = self.xzqhitem1
        makeIndexVar = "sourceEquipMakeIndex"
        levelVar = "sourceEquipLevel"
    end
    
    -- 清理原有显示
    if FGUI:GetChildCount(uiComponent.itemRoot) > 0 then
        FGUI:RemoveChildAt(uiComponent.itemRoot, 0, true)
    end

    -- 创建装备显示
    local extData = {}
    extData.hideTip = false
    extData.itemTipData = equipData
    extData.clickCallback = false
    extData.doubleClickCallback = true
    extData.bgVisible = false

    local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
    local itemobj = ItemUtil:ItemShow_Create(equipData, uiComponent.itemRoot, extData)
    if itemobj.hideArrow then
        itemobj:hideArrow()
    end

    -- 获取强化等级
    local qhLevel = 0
    for i = 1, #equipData.Values do
        if equipData.Values[i]['Id'] == 0 then  -- INTVALUE0 是强化等级
            qhLevel = equipData.Values[i]['Value']
            break
        end
    end

    -- 更新变量
    self[makeIndexVar] = equipData.MakeIndex
    self[levelVar] = qhLevel
    FGUI:setVisible(uiComponent.closeitembtn, true)
  
    -- 更新按钮状态
    self:updateTransferDisplay()
end

-----------------------------------------------------------------------
--- updateTransferDisplay: 更新强化转移显示
-----------------------------------------------------------------------
function EquipDuanZao:updateTransferDisplay()
    -- transfer.xml 中只有基本的按钮和装备显示组件
    -- 更新按钮状态
    local canTransfer = self.sourceEquipMakeIndex ~= 0 and
                       self.targetEquipMakeIndex ~= 0 and
                       self.sourceEquipLevel > 0
    FGUI:GButton_setGrey(self.rightbg.qhbtn, not canTransfer)
end

-----------------------------------------------------------------------
--- clearSourceEquip: 清除源装备
-----------------------------------------------------------------------
function EquipDuanZao:clearSourceEquip()
    if FGUI:GetChildCount(self.xzqhitem1.itemRoot) > 0 then
        FGUI:RemoveChildAt(self.xzqhitem1.itemRoot, 0, true)
    end
    self.sourceEquipMakeIndex = 0
    self.sourceEquipLevel = 0
    FGUI:setVisible(self.xzqhitem1.closeitembtn, false)
    FGUI:GList_clearSelection(self.ListBag)
    -- 更新按钮状态
    self:updateTransferDisplay()
end

-----------------------------------------------------------------------
--- clearTargetEquip: 清除目标装备
-----------------------------------------------------------------------
function EquipDuanZao:clearTargetEquip()
    if FGUI:GetChildCount(self.xzequip.itemRoot) > 0 then
        FGUI:RemoveChildAt(self.xzequip.itemRoot, 0, true)
    end
    self.targetEquipMakeIndex = 0
    self.targetEquipLevel = 0
    FGUI:setVisible(self.xzequip.closeitembtn, false)
    FGUI:GList_clearSelection(self.ListEquip)
    -- 更新按钮状态
    self:updateTransferDisplay()
end

-----------------------------------------------------------------------
--- onTransferClicked: 点击强化转移按钮
-----------------------------------------------------------------------
function EquipDuanZao:onTransferClicked()
    -- 检查条件
    if self.sourceEquipMakeIndex == 0 then
        SL:ShowScreenCenterTip("请选择源装备！", 251, 0, 200, 1, 0.3)
        return
    end

    if self.targetEquipMakeIndex == 0 then
        SL:ShowScreenCenterTip("请选择目标装备！", 251, 0, 200, 1, 0.3)
        return
    end

    if self.sourceEquipLevel <= 0 then
        SL:ShowScreenCenterTip("源装备没有强化等级！", 251, 0, 200, 1, 0.3)
        return
    end

    -- 发送强化转移请求
    local EquipDuanZaoData = SL:RequireFile("FGUILayout/A_EquipDuanZao/EquipDuanZaoData")
    EquipDuanZaoData:RequestTransfer({
        self.sourceEquipMakeIndex,
        self.targetEquipMakeIndex
    })
end


return EquipDuanZao




