local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCTradeMain = class("PCTradeMain", BaseFGUILayout)
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

local goldIndex = SL:GetValue("GAME_DATA", "DealGoldTypeId") or 1

function PCTradeMain:Create()
	self.super.Create(self)
    self._capacity = SL:GetValue("GAME_DATA", "PersonalTransactions") or 8  -- 交易格子容量
    self._target_items = {}
    self._self_items = {}

    self.handler_onTargetItemsRenderer = handler(self, self.OnTargetItemsRenderer)
    self.handler_onSelfItemsRenderer = handler(self, self.OnSelfItemsRenderer)
    self.handler_onClickItemEvent = handler(self, self.OnClickItemEvent)
	self._ui = FGUI:ui_delegate(self.component)

    FGUIFunction:setWindowDrag(self.component, self._ui.bg)

	FGUI:setOnClickEvent(self._ui.btn_agree, handler(self, self.OnClickAgreeButton))
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
    FGUI:GList_itemRenderer(self._ui.list_target_items, self.handler_onTargetItemsRenderer)
    FGUI:GList_itemRenderer(self._ui.list_self_items, self.handler_onSelfItemsRenderer)
    local goldData = SL:GetValue("ITEM_DATA", goldIndex)
    local icon_target_money = ItemShow.new(self._ui.icon_target_money, goldData)
    icon_target_money:UpdateGradeIsShow(false)
    local icon_my_money = ItemShow.new(self._ui.icon_self_money, goldData)
    icon_my_money:UpdateGradeIsShow(false)

    FGUI:GTextInput_setOnChanged(self._ui.text_self_money_count, handler(self, self.OnMoneyInputChanged))
    FGUI:setOnFocusOut(self._ui.text_self_money_count, handler(self, self.OnMoneyInputFocusOut))
    FGUI:setOnFocusIn(self._ui.text_self_money_count, handler(self, self.OnMoneyInputFocusIn))
end

function PCTradeMain:Enter()
	self:RegisterEvent()
	self:InitUI()
end

function PCTradeMain:InitUI()
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
    FGUI:GTextField_setColor(self._ui.text_self_money_count, "#000000")
end

function PCTradeMain:Exit()
	self:RemoveEvent()
    SL:RequestEndTrade()
    FGUI:Close("Bag_pc", "PCSimpleBagPanel")
    self._target_items = {}
    self._self_items = {}
end

function PCTradeMain:Destroy()
    self:CleanItemViewCache()
end

function PCTradeMain:Close()
	self.super.Close(self)
end

-- 点击接受按钮
function PCTradeMain:OnClickAgreeButton()
    SL:RequestChangeTradeLock()
end


-- 金币输入变化
function PCTradeMain:OnMoneyInputChanged(context)
    local str = FGUI:GTextInput_getText(context.sender)
    local moneyCount = tonumber(SL:GetValue("MONEY", goldIndex))
	if str and str ~= "" then
		local num = tonumber(str)
        if num then
            if num > moneyCount then
               FGUI:GTextInput_setText(self._ui.text_self_money_count, moneyCount) 
            else
                FGUI:GTextInput_setText(self._ui.text_self_money_count, num) 
            end
        end
	end
end


function PCTradeMain:OnMoneyInputFocusIn(context)
    local str = FGUI:GTextInput_getText(context.sender)
    str = string.gsub(str, ",", "")
    FGUI:GTextInput_setText(self._ui.text_self_money_count, str) 
end

-- 金币输入结束
function PCTradeMain:OnMoneyInputFocusOut(context)
    local str = FGUI:GTextInput_getText(context.sender)
    local num = 0
    local inputNum = tonumber(str)
    if inputNum then
       num = inputNum 
    end
    SL:RequestChangeTradeMoney(num)
end


-- 刷新对方交易栏金币
function PCTradeMain:OnRefreshTargetMoney()
    local count = SL:GetValue("TRADE_TARGET_MONEY")
    local count_str = SL:GetThousandSepString(count)
    FGUI:GTextField_setText(self._ui.text_target_money_count, count_str)
end

-- 刷新我方交易栏金币
function PCTradeMain:OnRefreshMyMoney()
    local count = SL:GetValue("TRADE_SELF_MONEY")
    local count_str = SL:GetThousandSepString(count)
    FGUI:GTextField_setText(self._ui.text_self_money_count, count_str)
end

-- 刷新对方交易状态
function PCTradeMain:OnRefreshTargetStatus(state)
    if state == 0 then
        FGUI:GTextField_setText(self._ui.text_target_state, GET_STRING(90180025))
        FGUI:GTextField_setColor(self._ui.text_target_state, "#CC3300")
        FGUI:setTouchEnabled(self._ui.text_self_money_count, true)
        FGUI:GTextField_setColor(self._ui.text_self_money_count, "#000000")
    elseif state == 1 then
        FGUI:GTextField_setText(self._ui.text_target_state, GET_STRING(90180026))
        FGUI:GTextField_setColor(self._ui.text_target_state, "##00CC33")
        FGUI:setTouchEnabled(self._ui.text_self_money_count, false)
        FGUI:GTextField_setColor(self._ui.text_self_money_count, "#4B4B4B")
    end

end

-- 刷新我方交易状态
function PCTradeMain:OnRefreshMyStatus(state)
	if state == 0 then
        FGUI:GButton_setTitle(self._ui.btn_agree, GET_STRING(90180024))
        FGUI:setTouchEnabled(self._ui.text_self_money_count, true)
        FGUI:GTextField_setColor(self._ui.text_self_money_count, "#000000")
    elseif state == 1 then
        FGUI:GButton_setTitle(self._ui.btn_agree, GET_STRING(90180032))
        FGUI:setTouchEnabled(self._ui.text_self_money_count, false)
        FGUI:GTextField_setColor(self._ui.text_self_money_count, "#4B4B4B")
    end
end

local itemViewCache = {}
function PCTradeMain:CleanItemViewCache()
	for k, v in pairs(itemViewCache) do
		if v then
			ItemUtil:ItemShow_Release(v)
		end
	end
	itemViewCache = { }
end

function PCTradeMain:OnTargetItemsRenderer(idx, item)
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

function PCTradeMain:OnSelfItemsRenderer(idx, item)
    local itemData = self._self_items[idx + 1]
    local id = FGUI:GetID(item)
    local cacheItem = itemViewCache[id]
    if cacheItem then
        ItemUtil:ItemShow_Release(cacheItem)
        itemViewCache[id]= nil
    end
    FGUI:setOnDropEvent(item ,handler(self, self.OnTradeItemDrop))
    if itemData then   
        local node_item = FGUI:GetChild(item, "node_item")
        itemData.isShowCount = true
        local itemContentView = ItemUtil:ItemShow_Create(itemData, node_item, {disableClick = true})
	    itemViewCache[id] = itemContentView
        FGUI:SetIntData(item, idx)
        FGUI:setOnRightClickEvent(item, self.handler_onClickItemEvent)

        FGUI:setOnClickEvent(itemContentView.component, function(eventData)
            if self.clickDelay then return end
            FGUIFunction:CloseItemTips()
            local touchId = FGUI:InputEvent_getTouchId(eventData)
            local data = {
                itemIndex = itemData.Index,
                makeIndex = itemData.MakeIndex,
                from = ItemFrom.TRADE,
            }
            
            -- 1.使用原图,尺寸可能偏大
            FGUI:DragDropManager_startDrag(itemContentView.component,"ui://public_pc/CommonItem", data, touchId)
            FGUIFunction:OpenBagCheckDragView()
            local commmonItem = FGUI:GLoader_getComponent(FGUI:DragDropManager_getDragAgent())
            ItemUtil:SetItemIconByItemID(commmonItem,itemData.Index)
            ItemUtil:UpdateItemGradeByItemID(commmonItem,itemData.Index)
        end)      
    end

end

function PCTradeMain:OnTradeItemDrop(eventData)
    local data = eventData.data
    if data.from == ItemFrom.BAG then
        local isMyLock = SL:GetValue("TRADE_MY_STATUS") == 1
        local isTargetLock = SL:GetValue("TRADE_TARGET_STATUS") == 1
        if isMyLock or isTargetLock then
            SL:ShowSystemTips(GET_STRING(90180031))
            return
        end
        SL:AddItemToTrade(data.makeIndex)
    end
end

function PCTradeMain:OnBagItemDrop(eventData)
    local data = eventData.data
    if data.from == ItemFrom.TRADE then
        local isMyLock = SL:GetValue("TRADE_MY_STATUS") == 1
        local isTargetLock = SL:GetValue("TRADE_TARGET_STATUS") == 1
        if isMyLock or isTargetLock then
            SL:ShowSystemTips(GET_STRING(90180031))
            return
        end
        SL:RemoveItemFromTrade(data.makeIndex)
    end
end

-- 放入物品
function PCTradeMain:BagCellClickEvent(bagItem)
    local isMyLock = SL:GetValue("TRADE_MY_STATUS") == 1
    local isTargetLock = SL:GetValue("TRADE_TARGET_STATUS") == 1
    if isMyLock or isTargetLock then
        SL:ShowSystemTips(GET_STRING(90180031))
        return
    end
    SL:AddItemToTrade(bagItem._itemData.MakeIndex)
end

-- 取回物品
function PCTradeMain:OnClickItemEvent(context)
    local item = context.sender
    local idx = FGUI:GetIntData(item)
    local itemData = self._self_items[idx + 1]
    
    if itemData then
        local isMyLock = SL:GetValue("TRADE_MY_STATUS") == 1
        local isTargetLock = SL:GetValue("TRADE_TARGET_STATUS") == 1
        if isMyLock or isTargetLock then
            SL:ShowSystemTips(GET_STRING(90180031))
            return
        end
        SL:RemoveItemFromTrade(itemData.MakeIndex)
    end  
end

-- 刷新对方交易栏道具
function PCTradeMain:OnRefreshTargetItem()
    self._target_items = SL:GetValue("TRADE_TARGET_ITEMS")
	FGUI:GList_setNumItems(self._ui.list_target_items, self._capacity)
end

-- 刷新我方交易栏道具
function PCTradeMain:OnRefreshMyItem()
    self._self_items = SL:GetValue("TRADE_SELF_ITEMS")
    FGUI:GList_setNumItems(self._ui.list_self_items, self._capacity)
end

-- 交易成功
function PCTradeMain:OnTradeSuccess()
    self:Close()
end

-- 添加道具失败
function PCTradeMain:OnAddItemFail(makeIndex)
    
end

-- 移除道具失败
function PCTradeMain:OnRemoveItemFail(makeIndex)
    
end

-- 交易状态改变失败提示
function PCTradeMain:ChangeStatusFailTips(errorType)
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

function PCTradeMain:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_MONEY_CHANGE, "PCTradeMain", handler(self, self.OnRefreshTargetMoney))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_MY_MONEY_CHANGE, "PCTradeMain", handler(self, self.OnRefreshMyMoney))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_STATUS_CHANGE, "PCTradeMain", handler(self, self.OnRefreshTargetStatus))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_MY_STATUS_CHANGE, "PCTradeMain", handler(self, self.OnRefreshMyStatus))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_TARGET_ITEM_CHANGE, "PCTradeMain", handler(self, self.OnRefreshTargetItem))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_MY_ITEM_CHANGE, "PCTradeMain", handler(self, self.OnRefreshMyItem))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_SUCCESS, "PCTradeMain", handler(self, self.OnTradeSuccess))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_ADD_ITEM_FAIL, "PCTradeMain", handler(self, self.OnAddItemFail))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_REMOVE_ITEM_FAIL, "PCTradeMain", handler(self, self.OnRemoveItemFail))
    SL:RegisterLUAEvent(LUA_EVENT_TRADE_STATUS_FAIL_TIPS, "PCTradeMain", handler(self, self.ChangeStatusFailTips))
    SL:RegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "PCTradeMain",  handler(self,self.BagCellClickEvent))
    
end

function PCTradeMain:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_MONEY_CHANGE, "PCTradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_MY_MONEY_CHANGE, "PCTradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_STATUS_CHANGE, "PCTradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_MY_STATUS_CHANGE, "PCTradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_TARGET_ITEM_CHANGE, "PCTradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_MY_ITEM_CHANGE, "PCTradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_SUCCESS, "PCTradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_ADD_ITEM_FAIL, "PCTradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_REMOVE_ITEM_FAIL, "PCTradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_TRADE_STATUS_FAIL_TIPS, "PCTradeMain")
    SL:UnRegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "PCTradeMain")
end

return PCTradeMain