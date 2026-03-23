local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local ExChangeLaunchPanel = class("ExChangeLaunchPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemMoney = SL:RequireFile("FGUILayout/Item/ItemMoney")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

--- 界面被创建时调用
function ExChangeLaunchPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:GetAllFGuiData()
    self:InitClickEvent()
    self:InitData()
end

function ExChangeLaunchPanel:GetAllFGuiData()
    -- 上架数量
    self.text_launch_count = self._ui.text_launch_count
    -- 背包数量
    self.text_bag_count = self._ui.text_bag_count
    -- 背包物品
    self.list_bag = self._ui.list_bag
    -- 我的上架
    self.list_my_launch = self._ui.list_my_launch
    -- 刷新按钮
    self.btn_refresh = self._ui.btn_refresh
    -- 关闭按钮
    self.btn_close = self._ui.btn_close

    self.noItemtip = self._ui.noItemtip
end

function ExChangeLaunchPanel:InitData()
    self._mySells = {}
    self._scheduleSet = {}
end

-- 数据重构
function ExChangeLaunchPanel:ResetData()
    local data = SL:GetValue("PAIMAI_BAG_DATA")
    local resetData = {}
    for k, v in pairs(data) do
        table.insert(resetData, v)
    end

    return resetData
end

-- 初始化数据
function ExChangeLaunchPanel:RefreshData()
    -- 目前上架条件共用拍卖条件
    self._selected_item_index = -1
    self._item_list = {}
end

function ExChangeLaunchPanel:CleanCache()
    if not self._item_list or not self._item_list then
        return
    end

    for k, v in pairs(self._item_list) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end

    self._item_list = {}

    for k,v in pairs(self._scheduleSet) do
        SL:UnSchedule(v)
    end

    self._scheduleSet = {}
end

function ExChangeLaunchPanel:InitClickEvent()
    FGUI:setOnClickEvent(self.btn_refresh, handler(self, self.BtnRefreshClicked))
    FGUI:GList_itemRenderer(self.list_bag, handler(self, self.BagItemRender))
    FGUI:GList_setVirtual(self.list_bag)
    FGUI:GList_addOnClickItemEvent(self.list_bag, handler(self, self.BagItemClicked))

    FGUI:GList_itemRenderer(self.list_my_launch, handler(self, self.MyLaunchItemRender))
    FGUI:GList_setVirtual(self.list_my_launch)
end

function ExChangeLaunchPanel:MyLaunchItemRender(idx, item)
    local text_name = FGUI:GetChild(item, "text_name")
    local text_price = FGUI:GetChild(item, "text_price")
    local text_single_price = FGUI:GetChild(item, "text_single_price")
    local text_time_launch = FGUI:GetChild(item, "text_time_launch")
    local text_time_under = FGUI:GetChild(item, "text_time_under")
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    local btn_getBack = FGUI:GetChild(item, "btn_getBack")
    local icon_Money = FGUI:GetChild(item,"icon_Money")
    local index = idx + 1
    local data = self._mySells[index]
    local id = FGUI:GetID(item)
    if self._item_list[id] then
        ItemUtil:ItemShow_Release(self._item_list[id])
    end

    if data then
        local itemData = SL:GetValue("ITEM_DATA", data.index)
        -- 名称
        FGUI:GTextField_setText(text_name, itemData.Name or "")
        -- 单价
        FGUI:GTextField_setText(text_single_price,GET_STRING(32000010)..SL:GetThousandSepString(data.price))
        -- 总价
        FGUI:GTextField_setText(text_price,GET_STRING(32000011).. SL:GetThousandSepString(data.price * data.useritem.OverLap))
        -- 上架时间
        FGUI:GTextField_setText(text_time_launch, os.date("%Y-%m-%d %H:%M:%S",data.time))

        local moneyData = SL:GetValue("ITEM_DATA",data.type)
        if moneyData then
            ItemUtil:RefreshItemUIByData(icon_Money,moneyData)
            ItemUtil:SetItemGradeVisible(icon_Money,false)
            ItemUtil:SetItemCountVisible(icon_Money,false)
        end
        if self._scheduleSet[id] then
            SL:UnSchedule(self._scheduleSet[id])
            self._scheduleSet[id] = nil
        end

        local callBack = function()
            local curTime = SL:GetValue("SERVER_TIME")
            if data.endtime - curTime <= 0 then
                if self._scheduleSet[id] then
                    SL:UnSchedule(self._scheduleSet[id])
                    self._scheduleSet[id] = nil
                end
            else
                -- 下架计时
                FGUI:GTextField_setText(text_time_under,GET_STRING(32000012) .. SecondToHMS(math.ceil(data.endtime - curTime) ,true, false))
            end
        end
        callBack()

        self._scheduleSet[id] = SL:Schedule(callBack, 1)
        -- 物品Icon
        self._item_list[id] = ItemUtil:ItemShow_Create(data.useritem, itemRoot, {disableClick = true})
        -- 下架
        FGUI:setOnClickEvent(
            btn_getBack, function()
                SL:RequestExBackSell(data.useritem.MakeIndex)
            end
        )
    end
end

function ExChangeLaunchPanel:BagItemRender(idx, item)
    local index = idx + 1
    local data = self._can_launch_data[index]
    local itemNode = FGUI:GetChild(item, "node_root")
    local isSelected = FGUI:GetChild(item, "isSelected")
    local id = FGUI:GetID(item)
    if data then
        if self._item_list[id] then
            ItemUtil:ItemShow_Release(self._item_list[id])
        end
        self._item_list[id] = ItemUtil:ItemShow_Create(data.BagData, itemNode, {disableClick = true})
    else
        FGUI:setVisible(isSelected, false)
    end

    FGUI:setVisible(itemNode, data and true or false)
end

function ExChangeLaunchPanel:BagItemClicked(contextData)
    local childIdx = FGUI:GetChildIndex(self.list_bag, contextData.data)
    local idx = FGUI:GList_childIndexToItemIndex(self.list_bag, childIdx)
    local data = self._can_launch_data[idx + 1]
    if data then
        local tipData = {}
        tipData.itemData = data.BagData
        tipData.from = ItemFrom.ExChange
        FGUIFunction:OpenItemTips(tipData)
    end
end

function ExChangeLaunchPanel:BtnRefreshClicked()
    self:RefreshBagView()
end

-- 刷新面板
function ExChangeLaunchPanel:RefreshBagView()
    self._bag_open_counts = SL:GetValue("BAG_OPEN_SIZE")
    self._can_launch_data = self:ResetData()
    -- 刷新列表
    FGUI:GList_setNumItems(self.list_bag, self._bag_open_counts)
    -- 刷新背包数量
    FGUI:GTextField_setText(self.text_bag_count, table.nums(self._can_launch_data) .. "/" .. self._bag_open_counts)
end

function ExChangeLaunchPanel:RefreshListMyLanuchView()
    self._mySells = SL:GetValue("EXCHANGE_MY_SELLS")
    local len = table.nums(self._mySells)
    FGUI:setVisible(self.noItemtip,len <= 0)
    -- 刷新列表
    FGUI:GList_setNumItems(self.list_my_launch, len)
    -- 最大可上架的数量
    local maxLaunchCount = SL:GetValue("GAME_DATA", "MaxPaimaiCount") or 8
    FGUI:GTextField_setText(self.text_launch_count,string.format(GET_STRING(32000004),len.."/"..maxLaunchCount))
    
    self:RefreshBagView()
end

function ExChangeLaunchPanel:Enter(data)
    self:RegisterEvent()
    self:RefreshData()
    SL:RequestExMySells()
end

--- 界面关闭时调用
function ExChangeLaunchPanel:Exit()
    self:RemoveEvent()
    self:CleanCache()
end

function ExChangeLaunchPanel:RegisterEvent()
    SL:RegisterLUAEvent(
        LUA_EVENT_EXCHANGE_MY_SELLS, "ExChangeLaunchPanel", handler(self, self.RefreshListMyLanuchView)
    )
    
    SL:RegisterLUAEvent(
        LUA_EVENT_EXCHANGE_LAUNCH_REV, "ExChangeLaunchPanel", handler(self, self.RefreshListMyLanuchView)
    )
end

function ExChangeLaunchPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_MY_SELLS, "ExChangeLaunchPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_LAUNCH_REV, "ExChangeLaunchPanel")
end

--- 界面销毁时调用
function ExChangeLaunchPanel:Destroy()
    self:CleanCache()
end

return ExChangeLaunchPanel
