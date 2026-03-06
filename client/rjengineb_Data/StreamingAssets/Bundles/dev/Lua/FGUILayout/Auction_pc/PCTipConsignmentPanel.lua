local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCTipConsignmentPanel = class("PCTipConsignmentPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemMoney = SL:RequireFile("FGUILayout/Item/ItemMoney")

-- 拍卖行寄售页面
function PCTipConsignmentPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)

    self:InitData()
    self:GetAllFGuiData()
    self:InitClickEvent()
    self:InitUI()
end

function PCTipConsignmentPanel:InitUI()
    local configValue = SL:GetValue("GAME_DATA", "BackpackTab")
	self.arrayNameTable = string.split(configValue, "|")
    self:ClickTabCellEvent(1)
    self:ClickBagCellEvent(1)
end

function PCTipConsignmentPanel:RefreshTabList()
    FGUI:GList_setNumItems(self.list_tab,#self.arrayNameTable)
end
-- 初始化数据
function PCTipConsignmentPanel:InitData()
    self._currentJiShouCount = 0
    self._selected_item_index = -1
    -- 当前寄售数量
    self._cur_jishou_count = 1
    -- 当前寄售底价
    self._cur_jishou_diJia = 0
    -- 当前一口价
    self._cur_once_price = 0
    -- 当前物品的货币类型
    self._cur_costType = 1
    -- 当前选中物品的拍卖配置
    self._cfgPaiMaiData = nil

    self._can_paiMai_data = {}
    self._item_list = {}
    self._cur_selected_item = nil
    self._min_JiShouDIJia = 0

    self._item_money1 = nil
    self._item_money2 = nil
end

function PCTipConsignmentPanel:GetAllFGuiData()
    -- 关闭按钮
    self.btn_close = self._ui.btn_close
    -- 物品名字
    self.text_item_name = self._ui.text_item_name
    -- 寄售底价
    self.input_jsdj = self._ui.input_jsdj
    -- 一口价
    self.input_once_price = self._ui.input_once_price
    -- 寄售数量
    self.input_jishou_count = self._ui.input_jishou_count
    -- 寄售按钮
    self.btn_jiShou = self._ui.btn_jiShou
    -- 上一次出价
    self.btn_lastChuJia = self._ui.btn_lastChuJia
    -- checkBox
    self.cbx = self._ui.cbx
    -- 背包列表
    self.list_bag = self._ui.list_bag
    -- tab列表
    self.list_tab = self._ui.list_tab
    -- 当前选中展示的cell
    self.node_curSelected = self._ui.node_curSelected
    -- 减少按钮
    self.btn_minus = self._ui.btn_minus
    -- 增加按钮
    self.btn_add = self._ui.btn_add
    -- 最大值
    self.btn_max = self._ui.btn_max
    -- 货币图标
    self.itemMoney1 = self._ui.itemMoney1
    -- 货币图标
    self.itemMoney2 = self._ui.itemMoney2

    self.text_tip = self._ui.text_tip
    -- 控制器是否已经上架过
    self.ctrl_isHaveLastPrice = FGUI:getController(self.component,"isHaveLastPrice")
    -- 是否有道具可以上架
    self.ctrl_isHaveItemToAdd = FGUI:getController(self.component,"isHaveItemToAdd")
end

function PCTipConsignmentPanel:InitClickEvent()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_jiShou,handler(self,self.BtnJiShouClicked))
    FGUI:setOnClickEvent(self.btn_lastChuJia,handler(self,self.BtnLastChuJia))
    FGUI:setOnClickEvent(self.btn_minus,handler(self,self.BtnMinusClicked))
    FGUI:setOnClickEvent(self.btn_add,handler(self,self.BtnAddClicked))
    FGUI:setOnClickEvent(self.btn_max,handler(self,self.BtnMaxClicked))

    FGUI:GList_itemRenderer(self.list_tab,handler(self,self.TabItemRender))
    FGUI:GList_addOnClickItemEvent(self.list_tab,handler(self,self.TabItemClicked))
    
    FGUI:GList_itemRenderer(self.list_bag,handler(self,self.BagItemRender))
    FGUI:GList_setVirtual(self.list_bag)
    FGUI:GList_addOnClickItemEvent(self.list_bag,handler(self,self.BagItemClicked))
    FGUI:setOnFocusOut(self.input_jishou_count,handler(self,self.InputJiShouCountFoucsIn))
    FGUI:setOnFocusOut(self.input_once_price,handler(self,self.InputOncePriceOnFocusOut))
    FGUI:setOnFocusOut(self.input_jsdj,handler(self,self.InputJiShouDiJiaOnFocusOut))
end

function PCTipConsignmentPanel:TabItemRender(idx,item)
    local index = idx + 1
    local data = self.arrayNameTable[index]
    if data then
        local title = FGUI:GetChild(item,"title")
        FGUI:GTextField_setText(title,data)
    end

    local ctrl = FGUI:getController(item,"isSelected")
    ctrl.selectedIndex = index == self._cur_tab_index and 0 or 1
end

function PCTipConsignmentPanel:TabItemClicked(contextData)
    local childIdx = FGUI:GetChildIndex(self.list_tab, contextData.data)
	local idx = FGUI:GList_childIndexToItemIndex(self.list_tab, childIdx)
	self:ClickTabCellEvent(idx + 1)
end

-- 过滤数据
function PCTipConsignmentPanel:TabFilterData()
    local data = SL:GetValue("PAIMAI_BAG_DATA")
    local filterData = {}

    for k,v in pairs(data) do
        if self._cur_tab_index == 1 or v.itemType  == self._cur_tab_index then
            table.insert(filterData,v)
        end
    end
    return filterData
end

function PCTipConsignmentPanel:ClickTabCellEvent(idx)
    self._cur_tab_index = idx
    self:RefreshTabList()
    self:RefreshCanPaiMaiData()
end

function PCTipConsignmentPanel:BagItemRender(idx,item)
    local index = idx + 1
    local data = self._can_paiMai_data[index]
    local item_root = FGUI:GetChild(item,"item_root")
    local isSelected = FGUI:GetChild(item,"isSelected")
    local id = FGUI:GetID(item)

    if data then
        if self._item_list [id] then
            ItemUtil:ItemShow_Release(self._item_list [id])
        end
        FGUI:setVisible(item_root,true)
        FGUI:setVisible(isSelected,self._selected_item_index == index)
        self._item_list[id] =  ItemUtil:ItemShow_Create(data.BagData,item_root,{disableClick = true})
    else
        FGUI:setVisible(item_root,false)
        FGUI:setVisible(isSelected,false)
    end
end

function PCTipConsignmentPanel:BagItemClicked(contextData)
    local childIdx = FGUI:GetChildIndex(self.list_bag, contextData.data)
	local idx = FGUI:GList_childIndexToItemIndex(self.list_bag, childIdx)
	self:ClickBagCellEvent(idx + 1)
end

-- bagCell点击
function PCTipConsignmentPanel:ClickBagCellEvent(index)
    self._selected_item_index = index
    self:RefreshLeftPanelInfo()
end

-- 左边面板信息
function PCTipConsignmentPanel:RefreshLeftPanelInfo()
    self.ctrl_isHaveItemToAdd.selectedIndex =  table.nums(self._can_paiMai_data) == 0 and 1 or 0
    local data = self._can_paiMai_data[self._selected_item_index]
    if not data then
        return
    end

    FGUI:GList_setNumItems(self.list_bag,self._bag_open_counts)
    if self._cur_selected_item then
        ItemUtil:ItemShow_Release(self._cur_selected_item)
    end


    local itemData = data.ItemData
    FGUI:GTextField_setText(self.text_item_name,itemData.Name or "")
    self._cur_selected_item =  ItemUtil:ItemShow_Create(itemData,self.node_curSelected,{OverLap = data.BagData.OverLap})
    self._cur_jishou_count = 1
    self:RefreshJiShouCount()
    self._cfgPaiMaiData = SL:GetValue("PAIMAI_CONFIG",data.ItemData.nPaimaiConfig)
    if self._cfgPaiMaiData then
        self._cur_jishou_diJia = self._cfgPaiMaiData.nPrice
        self._cur_once_price = self._cfgPaiMaiData.nPrice
        -- 最低寄售底价
        if self._cfgPaiMaiData.nPriceLimit then
            self._min_JiShouDIJia = self._cfgPaiMaiData.nPrice - self._cfgPaiMaiData.nPriceLimit
            self._max_JiShouDIJia = self._cfgPaiMaiData.nPrice + self._cfgPaiMaiData.nPriceLimit
        else
            self._min_JiShouDIJia = 1
            self._max_JiShouDIJia = nil
        end
        self._cur_costType = self._cfgPaiMaiData.nCurrency
        local moneyData = SL:GetValue("ITEM_DATA",self._cfgPaiMaiData.nCurrency)
        self:RefreshMoneyItemShow(moneyData)
        self:RefreshTipMinJiShou(moneyData)
        self:RefreshJiShouDiJia()
        self:RefreshOncePrice()
    end

    self.ctrl_isHaveLastPrice.selectedIndex = SL:GetValue("PAIMAI_ADD_HISTORY_LOG",itemData.ID)  ~= nil and 0 or 1
end

-- 刷新货币图标显示
function PCTipConsignmentPanel:RefreshMoneyItemShow(moneyData)
    if not moneyData then
        moneyData = SL:GetValue("ITEM_DATA",1)
        SL:PrintError("配表错误","获取不到货币类型,请检查配置表")
        return
    end

    if self._item_money1 then
        self._item_money1:UpdateItemData(moneyData)
    else
        self._item_money1 = ItemMoney.new(self.itemMoney1,moneyData)
    end

    if self._item_money2 then
        self._item_money2:UpdateItemData(moneyData)
    else
        self._item_money2 = ItemMoney.new(self.itemMoney2,moneyData)
    end

    self._item_money1:UpdateItemCounts(false)
    self._item_money2:UpdateItemCounts(false)
end

-- 刷新底部最低寄售底价
function PCTipConsignmentPanel:RefreshTipMinJiShou(moneyData)
    if moneyData and moneyData.Name then
        local showStr = self._min_JiShouDIJia < 0 and 0 or self._min_JiShouDIJia .. moneyData.Name
        FGUI:GTextField_setText(self.text_tip,string.format(GET_STRING(30000060),showStr))
    end
end

-- 刷新寄售底价显示
function PCTipConsignmentPanel:RefreshJiShouDiJia()
    FGUI:GTextInput_setText(self.input_jsdj, self._cur_jishou_diJia)
end

-- 刷新一口价显示
function PCTipConsignmentPanel:RefreshOncePrice()
    FGUI:GTextInput_setText(self.input_once_price, self._cur_once_price)
end

function PCTipConsignmentPanel:InputJiShouCountEndInput(input)
    if self._cur_jishou_count ~= input then
        if input <= 0 then
            input = 1
        end

        local data = self._can_paiMai_data[self._selected_item_index]
        if not data then
            return
        end

        if input >=  data.BagData.OverLap then
            input = data.BagData.OverLap
        end
        
        self._cur_jishou_count = input
        self:RefreshJiShouCount()
    end
end

-- 点击修改
function PCTipConsignmentPanel:InputJiShouCountFoucsIn(context)
    local bagData = self._can_paiMai_data[self._selected_item_index]
    if bagData then
        local num = FGUI:GTextField_getText(self.input_jishou_count)
        if not num then
            return
        end

        local number = tonumber(num)
        if number > bagData.BagData.OverLap then
            number = bagData.BagData.OverLap
        end
        
        FGUI:GTextField_setText(self.input_jishou_count,number)
        self:InputJiShouCountEndInput(number)
    end
end

-- 寄售底价输入完毕
function PCTipConsignmentPanel:InputJiShouDiJiaOnFocusOut(context)
    local content = FGUI:GTextInput_getText(context.sender)
    if string.isNullOrEmpty(content) then
        self:RefreshJiShouDiJia()
        return
    end

    local input = tonumber(content)
    if self._max_JiShouDIJia then
        if input < self._min_JiShouDIJia or input > self._max_JiShouDIJia then
            SL:ShowSystemTips(string.format(GET_STRING(31000000),self._min_JiShouDIJia,self._max_JiShouDIJia))
            input = self._min_JiShouDIJia
        end
    else
        if input < self._min_JiShouDIJia then
            SL:ShowSystemTips(string.format(GET_STRING(31000002),self._min_JiShouDIJia))
            input = self._min_JiShouDIJia
        end
    end

    if input > self._cur_once_price then
        SL:ShowSystemTips(GET_STRING(31000001))
        self._cur_once_price = input
        self:RefreshOncePrice()
    end

    self._cur_jishou_diJia = input
    self:RefreshJiShouDiJia()
end

-- 一口价刷新
function PCTipConsignmentPanel:InputOncePriceOnFocusOut(context)
    local content = FGUI:GTextInput_getText(context.sender)
    if string.isNullOrEmpty(content) then
        self:RefreshOncePrice()
        return
    end

    self._cur_once_price= tonumber(content)
    if self._cur_once_price < self._cur_jishou_diJia then
        SL:ShowSystemTips(GET_STRING(31000001))
        self._cur_once_price = self._cur_jishou_diJia
    end

    self:RefreshOncePrice()
end

function PCTipConsignmentPanel:CleanCache()
    if self._cur_selected_item then
        ItemUtil:ItemShow_Release(self._cur_selected_item)
    end

    for k,v in pairs(self._item_list) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end
end

function PCTipConsignmentPanel:Destory()
    self:CleanCache()
end

function PCTipConsignmentPanel:RefreshJiShouCount()
    FGUI:GTextInput_setText(self.input_jishou_count,self._cur_jishou_count)
end

-- 刷新背包
function PCTipConsignmentPanel:RefreshCanPaiMaiData()
    self._bag_open_counts = SL:GetValue("BAG_OPEN_SIZE")
    self._can_paiMai_data = self:TabFilterData()
    FGUI:GList_setNumItems(self.list_bag,self._bag_open_counts)
    self:ClickBagCellEvent(1)
end

function PCTipConsignmentPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_MY_AUCTION_ADD_SELL_SUCC, "PCTipConsignmentPanel", handler(self, self.RefreshCanPaiMaiData))
end

function PCTipConsignmentPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_MY_AUCTION_ADD_SELL_SUCC, "PCTipConsignmentPanel")
end

function PCTipConsignmentPanel:Enter()
    self:RegisterEvent()
    self:RefreshCanPaiMaiData()
end

function PCTipConsignmentPanel:Exit()
    self:RemoveEvent()
end

-- 寄售
function PCTipConsignmentPanel:BtnJiShouClicked()
    print("BtnJiShouClicked")
    local data = self._can_paiMai_data[self._selected_item_index]
    if data then
        data._cur_once_price = self._cur_once_price
        data._cur_jishou_count = self._cur_jishou_count
        data._cur_jishou_diJia = self._cur_jishou_diJia
        data._cur_costType = self._cur_costType
        data._cfgPaiMaiData  = self._cfgPaiMaiData
        FGUI:Open("Auction_pc","PCTipJiShouPanel",data)
    end
end

-- 上一次出价
function PCTipConsignmentPanel:BtnLastChuJia()
    local data = self._can_paiMai_data[self._selected_item_index]
    FGUI:Open("Auction_pc","PCTipLastJiShouPanel",data)
end

-- 减一数量
function PCTipConsignmentPanel:BtnMinusClicked()
    self._cur_jishou_count = self._cur_jishou_count - 1
    if self._cur_jishou_count <= 0 then
        self._cur_jishou_count = 1
    end
    self:RefreshJiShouCount()
end

-- 加一数量
function PCTipConsignmentPanel:BtnAddClicked()
    self._cur_jishou_count = self._cur_jishou_count + 1
    local data = self._can_paiMai_data[self._selected_item_index]
    if not data then
        return
    end
    if self._cur_jishou_count >=  data.BagData.OverLap then
        self._cur_jishou_count = data.BagData.OverLap
    end
    self:RefreshJiShouCount()
end

-- 最大值数量
function PCTipConsignmentPanel:BtnMaxClicked()
    local data = self._can_paiMai_data[self._selected_item_index]
    if not data then
        return
    end
    self._cur_jishou_count = data.BagData.OverLap
    self:RefreshJiShouCount()
end


function PCTipConsignmentPanel:OnClose()
    self.super.Close(self)
end

return PCTipConsignmentPanel