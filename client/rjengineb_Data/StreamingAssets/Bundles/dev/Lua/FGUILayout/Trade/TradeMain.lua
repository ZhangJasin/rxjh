local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TradeMain = class("TradeMain", BaseFGUILayout)
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local goldIndex = SL:GetValue("GAME_DATA", "DealGoldTypeId") or 1

function TradeMain:Create()
	self.super.Create(self)
    self._capacity = SL:GetValue("GAME_DATA", "PersonalTransactions") or 8  -- 交易格子容量
    self._target_items = {}
    self._self_items = {}

    self.handler_onTargetItemsRenderer = handler(self, self.OnTargetItemsRenderer)
    self.handler_onSelfItemsRenderer = handler(self, self.OnSelfItemsRenderer)
    self.handler_onClickItemEvent = handler(self, self.OnClickItemEvent)
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:setOnClickEvent(self._ui.btn_agree, handler(self, self.OnClickAgreeButton))
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.btn_edit_money, handler(self, self.OnClickChangeMoneyButton))
    FGUI:GList_itemRenderer(self._ui.list_target_items, self.handler_onTargetItemsRenderer)
    FGUI:GList_itemRenderer(self._ui.list_self_items, self.handler_onSelfItemsRenderer)
    local goldData = SL:GetValue("ITEM_DATA", goldIndex)
    local icon_target_money = ItemShow.new(self._ui.icon_target_money, goldData)
    icon_target_money:UpdateGradeIsShow(false)
    local icon_my_money = ItemShow.new(self._ui.icon_self_money, goldData)
    icon_my_money:UpdateGradeIsShow(false)
end

function TradeMain:Enter()
	self:RegisterEvent()
	self:InitUI()
end

function TradeMain:InitUI()
    FGUI:GTextField_setText(self._ui.text_target_state, GET_STRING(90180025))
    FGUI:GTextField_setColor(self._ui.text_target_state, "#CC3300")
    FGUI:GButton_setTitle(self._ui.btn_agree, GET_STRING(90180024))
    FGUI:GTextField_setText(self._ui.text_target_money_count, 0)
    FGUI:GTextField_setText(self._ui.text_self_money_count, 0)
    local traderData = SL:GetValue("TRADE_TARGET_INFO") or {}
    FGUI:GTextField_setText(self._ui.text_target_name, FGUIFunction:GetServerName(traderData.name))
    FGUI:GTextField_setText(self._ui.text_self_name, FGUIFunction:GetServerName(SL:GetValue("USER_NAME")))
    FGUI:GList_setNumItems(self._ui.list_self_items, self._capacity)
    FGUI:GList_setNumItems(self._ui.list_target_items, self._capacity)
    FGUI:setVisible(self._ui.btn_edit_money, true) 
    FGUI:GTextField_setColor(self._ui.text_self_money_count, "#000000")
end

function TradeMain:Exit()
	self:RemoveEvent()
    SL:RequestEndTrade()
    FGUI:Close("Bag", "SimpleBagPanel")
    self._target_items = {}
    self._self_items = {}
end

function TradeMain:Destroy()
    self:CleanItemViewCache()
end

function TradeMain:Close()
	self.super.Close(self)
end

-- 点击接受按钮
function TradeMain:OnClickAgreeButton()
    SL:RequestChangeTradeLock()
end

-- 点击编辑金币按钮
function TradeMain:OnClickChangeMoneyButton()
    local data = {}
    local itemData = SL:GetValue("ITEM_DATA", goldIndex)
    local goldName = itemData and itemData.Name or ""
    data.str = string.format(GET_STRING(90180027), goldName)

    data.btnDesc = {GET_STRING(1001), GET_STRING(1000)}
    data.callback = function (tag, data)
        if tag == 1 then
            -- 确认
            local input = data.editStr
            local number = tonumber(input)
            if number then
                SL:RequestChangeTradeMoney(number)
            else
                SL:ShowSystemTips(GET_STRING(90180028))
            end
        elseif tag == 2 then
            -- 取消

        end
    end
    data.showEdit = true
    data.editParams = {}
    --data.editParams.maxLength = 10
    SL:OpenCommonDialog(data)
end

-- 刷新对方交易栏金币
function TradeMain:OnRefreshTargetMoney()
    local count = SL:GetValue("TRADE_TARGET_MONEY")
    local count_str = SL:GetThousandSepString(count)
    FGUI:GTextField_setText(self._ui.text_target_money_count, count_str)
end

-- 刷新我方交易栏金币
function TradeMain:OnRefreshMyMoney()
    local count = SL:GetValue("TRADE_SELF_MONEY")
    local count_str = SL:GetThousandSepString(count)
    FGUI:GTextField_setText(self._ui.text_self_money_count, count_str)
end

-- 刷新对方交易状态
function TradeMain:OnRefreshTargetStatus(state)
    if state == 0 then
        FGUI:GTextField_setText(self._ui.text_target_state, GET_STRING(90180025))
        FGUI:GTextField_setColor(self._ui.text_target_state, "#CC3300")
        FGUI:setTouchEnabled(self._ui.btn_edit_money, true)
        FGUI:GTextField_setColor(self._ui.text_self_money_count, "#000000")
    elseif state == 1 then
        FGUI:GTextField_setText(self._ui.text_target_state, GET_STRING(90180026))
        FGUI:GTextField_setColor(self._ui.text_target_state, "##00CC33")
        FGUI:setTouchEnabled(self._ui.btn_edit_money, false)
        FGUI:GTextField_setColor(self._ui.text_self_money_count, "#4B4B4B")
    end

end

-- 刷新我方交易状态
function TradeMain:OnRefreshMyStatus(state)
	if state == 0 then
        FGUI:GButton_setTitle(self._ui.btn_agree, GET_STRING(90180024))
        FGUI:setTouchEnabled(self._ui.btn_edit_money, true)
        FGUI:GTextField_setColor(self._ui.text_self_money_count, "#000000")
    elseif state == 1 then
        FGUI:GButton_setTitle(self._ui.btn_agree, GET_STRING(90180032))
        FGUI:setTouchEnabled(self._ui.btn_edit_money, false)
        FGUI:GTextField_setColor(self._ui.text_self_money_count, "#4B4B4B")
    end
end

local itemViewCache = {}
function TradeMain:CleanItemViewCache()
	for k, v in pairs(itemViewCache) do
		if v then
			ItemUtil:ItemShow_Release(v)
		end
	end
	itemViewCache = { }
end

function TradeMain:OnTargetItemsRenderer(idx, item)
    local itemData = self._target_items[idx + 1]
    local id = FGUI:GetID(item)
    local cacheItem = itemViewCache[id]
    
    if cacheItem then
        ItemUtil:ItemShow_Release(cacheItem)
        itemViewCache[id]= nil
    end
    if itemData then
        local node_item = FGUI:GetChild(item, "node_item")
        itemData.isShowCount = true
        local itemContentView =ItemUtil:ItemShow_Create(itemData, node_item)
	    itemViewCache[id] = itemContentView
    end
end

function TradeMain:OnSelfItemsRenderer(idx, item)
    local itemData = self._self_items[idx + 1]
    local id = FGUI:GetID(item)
    local cacheItem = itemViewCache[id]
    if cacheItem then
        ItemUtil:ItemShow_Release(cacheItem)
        itemViewCache[id]= nil
    end
    if itemData then   
        local node_item = FGUI:GetChild(item, "node_item")
        itemData.isShowCount = true
        local itemContentView = ItemUtil:ItemShow_Create(itemData, node_item, {disableClick = true})
	    itemViewCache[id] = itemContentView
        FGUI:SetIntData(item, idx)
        FGUI:setOnClickEvent(item, self.handler_onClickItemEvent)
    end
end

-- 点击货架上的物品
function TradeMain:OnClickItemEvent(context)
    local item = context.sender
    local idx = FGUI:GetIntData(item)
    local itemData = self._self_items[idx + 1]
    
    if itemData then
        local tipData = {}
        local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM") or {}
        tipData.from = ItemFrom.TRADE
        tipData.itemData = itemData
        tipData.hideButtons = false
        FGUIFunction:OpenItemTips(tipData)
    end  
end

-- 刷新对方交易栏道具
function TradeMain:OnRefreshTargetItem()
    self._target_items = SL:GetValue("TRADE_TARGET_ITEMS")
	FGUI:GList_setNumItems(self._ui.list_target_items, self._capacity)
end

-- 刷新我方交易栏道具
function TradeMain:OnRefreshMyItem()
    self._self_items = SL:GetValue("TRADE_SELF_ITEMS")
    FGUI:GList_setNumItems(self._ui.list_self_items, self._capacity)
end

-- 交易成功
function TradeMain:OnTradeSuccess()
    self:Close()
end

-- 添加道具失败
function TradeMain:OnAddItemFail(makeIndex)
    
end

-- 移除道具失败
function TradeMain:OnRemoveItemFail(makeIndex)
    
end

-- 交易状态改变失败提示
function TradeMain:ChangeStatusFailTips(errorType)
    local errorStr = GET_STRING(90180005)
    if errorType == -1 then
        errorStr = GET_STRING(90180019)
    elseif errorType == -2 then
        errorStr = GET_STRING(90180020)
    elseif errorType == -3 then
        errorStr = GET_STRING(90180021)
    elseif errorType == -4 then
        errorStr = GET_STRING(90180022)
    end
    
    SL:ShowSystemTips(errorStr)
end

function TradeMain:BagCellClickEvent(bagItem)
    bagItem:SetTipEnable(false)
    local isMyLock = SL:GetValue("TRADE_MY_STATUS") == 1
    local isTargetLock = SL:GetValue("TRADE_TARGET_STATUS") == 1
    if isMyLock or isTargetLock then
        SL:ShowSystemTips(GET_STRING(90180031))
        return
    end
    SL:AddItemToTrade(bagItem._itemData.MakeIndex)
end

function TradeMain:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_MONEY_CHANGE, "TradeMain", handler(self, self.OnRefreshTargetMoney))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_MY_MONEY_CHANGE, "TradeMain", handler(self, self.OnRefreshMyMoney))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_STATUS_CHANGE, "TradeMain", handler(self, self.OnRefreshTargetStatus))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_MY_STATUS_CHANGE, "TradeMain", handler(self, self.OnRefreshMyStatus))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_TARGET_ITEM_CHANGE, "TradeMain", handler(self, self.OnRefreshTargetItem))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_MY_ITEM_CHANGE, "TradeMain", handler(self, self.OnRefreshMyItem))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_SUCCESS, "TradeMain", handler(self, self.OnTradeSuccess))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_ADD_ITEM_FAIL, "TradeMain", handler(self, self.OnAddItemFail))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_REMOVE_ITEM_FAIL, "TradeMain", handler(self, self.OnRemoveItemFail))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_STATUS_FAIL_TIPS, "TradeMain", handler(self, self.ChangeStatusFailTips))
    SL:RegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "TradeMain",  handler(self,self.BagCellClickEvent))
    
end

function TradeMain:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_MONEY_CHANGE, "TradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_MY_MONEY_CHANGE, "TradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_STATUS_CHANGE, "TradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_MY_STATUS_CHANGE, "TradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_TARGET_ITEM_CHANGE, "TradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_MY_ITEM_CHANGE, "TradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_SUCCESS, "TradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_ADD_ITEM_FAIL, "TradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_REMOVE_ITEM_FAIL, "TradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_STATUS_FAIL_TIPS, "TradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "TradeMain")
end

return TradeMain