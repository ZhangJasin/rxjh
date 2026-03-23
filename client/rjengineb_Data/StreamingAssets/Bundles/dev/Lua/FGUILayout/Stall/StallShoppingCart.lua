local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local StallShoppingCart = class("StallShoppingCart", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")


function StallShoppingCart:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	self._data = nil
	self._totalMoneyList = {}
	self._scheduleMap = {}
	self._buyFailItems = {}	--购买失败商品
	FGUIFunction:SetCloseUIWhenClickOutside(self)

	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:GList_itemRenderer(self._ui.list_shop, handler(self, self.OnItemRenderer))
	FGUI:setOnClickEvent(self._ui.btn_buy_all, handler(self, self.OnClickBuyAll))
	FGUI:GList_itemRenderer(self._ui.list_total_money, handler(self, self.OnTotalMoneyListRenderer))
	FGUI:GList_setOnClickItemEvent(self._ui.list_shop, handler(self, self.OnItemSelectedChanged))
end

function StallShoppingCart:Enter()
	self:RegisterEvent()
	self:RefreshDisplay()
	self._buyFailItems = {}	-- 重新打开清空失败商品列表
end

function StallShoppingCart:RefreshDisplay()
	self._data = SL:GetValue("STALL_SHOPPING_CART_DATA")
	local num = self._data and #self._data or 0
	FGUI:GList_setNumItems(self._ui.list_shop, num)
	self:RefreshTotalMoney()
	FGUI:setVisible(self._ui.text_empty_tip, num == 0)
end 

function StallShoppingCart:OnItemRenderer(idx, item)
	local data = self._data[idx + 1]
	local obj_item = FGUI:GetChild(item, "item")
	local itemData = SL:GetValue("ITEM_DATA", data.index)
	FGUI:SetIntData(item, idx)
	ItemUtil:RefreshItemUIByData(obj_item, itemData)
	ItemUtil:UpdateIsShowLockByItemID(obj_item, itemData)
	ItemUtil:SetItemSubScriptByItemID(obj_item, itemData.ID)
	FGUI:setOnClickEvent(obj_item, handler(self, self.ShowItemTips))
	-- 店主名
	local text_owner_name = FGUI:GetChild(item, "text_owner_name")
	local str_owner_name = string.format(SL:GetValue("I18N_STRING", 90010036), data.username)
	FGUI:GTextField_setText(text_owner_name, str_owner_name)
	-- 道具名
	local text_item_name = FGUI:GetChild(item, "text_item_name")
	local str_item_name = string.format(SL:GetValue("I18N_STRING", 90010037), itemData.Name)
	FGUI:GTextField_setText(text_item_name, str_item_name)
	-- 销售总量
	local text_total_count = FGUI:GetChild(item, "text_total_count")
	FGUI:GTextField_setText(text_total_count, data.maxcount)
	-- 单价
	local moneyData = SL:GetValue("ITEM_DATA", data.moneytype) or {}
	local text_price = FGUI:GetChild(item, "text_price")
	FGUI:GTextField_setText(text_price, data.price)
	local text_price_money_name = FGUI:GetChild(item, "text_price_money_name")
	FGUI:GTextField_setText(text_price_money_name, moneyData.Name)
	local text_total_price_money_name = FGUI:GetChild(item, "text_total_price_money_name")
	FGUI:GTextField_setText(text_total_price_money_name, moneyData.Name)
	-- 购买数量
	local text_buy_count = FGUI:GetChild(item, "text_buy_count")
	FGUI:GTextField_setText(text_buy_count, data.buycount)
	local btn_edit_count = FGUI:GetChild(item, "btn_edit_count")
	FGUI:setOnClickEvent(btn_edit_count, handler(self, self.OpenEditCountPanel))
	local btn_count_max = FGUI:GetChild(item, "btn_count_max")
	FGUI:setOnClickEvent(btn_count_max, handler(self, self.SetMaxBuyCount, data.maxcount))
	-- 总价
	local totalPrice = data.price * data.buycount
	local text_total_price = FGUI:GetChild(item, "text_total_price")
	FGUI:GTextField_setText(text_total_price, totalPrice)
	-- 移除物品
	local btn_del = FGUI:GetChild(item, "btn_delete")
	FGUI:setOnClickEvent(btn_del, handler(self, self.RemoveItem, data.makeindex))
	-- 选中按钮
	FGUI:GButton_setSelected(item, data.selected == 1)

	-- 查看摊主信息
	local btn_owner_info = FGUI:GetChild(item, "btn_owner_info")
	FGUI:setOnClickEvent(btn_owner_info, handler(self, self.OnClickOwnerInfo))

	-- 结算失败提示
	local text_tip = FGUI:GetChild(item, "text_fail_tip")
	local errorStr = self._buyFailItems[data.makeindex]
	if errorStr then
		FGUI:setVisible(text_tip, true)
		FGUI:GTextField_setText(text_tip, errorStr)
	else
		FGUI:setVisible(text_tip, false)
	end
end

-- 点击查看摊位主
function StallShoppingCart:OnClickOwnerInfo(context)
	FGUI:EventContext_stopPropagation(context)
	local idx = FGUI:GetIntData(FGUI:GetParent(context.sender))
	local data = self._data[idx + 1]
	local tipData = {}
	tipData.targetId = tonumber(data.userid)
	tipData.TipsType = SL:GetValue("DOCKTYPE_NENUM").Func_Stall
    FGUIFunction:RequestPlayerDataAndSetTipType(tipData)
end

-- 显示物品提示
function StallShoppingCart:ShowItemTips(context)
	FGUI:EventContext_stopPropagation(context)
	local idx = FGUI:GetIntData(FGUI:GetParent(context.sender))
	local data = self._data[idx + 1]
	local itemData = SL:GetValue("ITEM_DATA", data.index)
	FGUIFunction:OpenItemTips({itemData = itemData, hideButtons = true})
end

-- 选中/取消物品
function StallShoppingCart:OnItemSelectedChanged(context)
	local item = context.data
	local idx = FGUI:GetIntData(item)
	local data = self._data[idx + 1]
	local isSelected = FGUI:GButton_getSelected(item)
	data.selected = isSelected and 1 or 0
	self:RefreshTotalMoney()
end

-- 打开修改数量界面
function StallShoppingCart:OpenEditCountPanel(context)
	FGUI:EventContext_stopPropagation(context)
	local parent = FGUI:GetParent(context.sender)
	local idx = FGUI:GetIntData(parent)
	local cartData = self._data[idx + 1]
	local data = {}
	data.title = GET_STRING(90010006)
	data.maxNum = cartData.maxcount
	data.callback_yes = function (number)
		cartData.buycount = number
		self:SetBuyCountText(parent, number, cartData.price)
	end
	FGUIFunction:OpenCommonNumberInputPanel(data)
end

-- 设置最大购买数量
function StallShoppingCart:SetMaxBuyCount(count, context)
	FGUI:EventContext_stopPropagation(context)
	local parent = FGUI:GetParent(context.sender)
	local idx = FGUI:GetIntData(parent)
	local data = self._data[idx + 1]
	data.buycount = count
	self:SetBuyCountText(parent, count, data.price)
end

function StallShoppingCart:SetBuyCountText(parent, count, price)
	local text_buy_count = FGUI:GetChild(parent, "text_buy_count")
	local text_total_price = FGUI:GetChild(parent, "text_total_price")
	FGUI:GTextField_setText(text_buy_count, count)
	FGUI:GTextField_setText(text_total_price, count * price)
	self:RefreshTotalMoney()
end

-- 将物品从购物车移除
function StallShoppingCart:RemoveItem(makeindex, context)
	FGUI:EventContext_stopPropagation(context)
	SL:RequestStallRemoveFromShoppingCart(makeindex)
end

-- 更新合计
function StallShoppingCart:RefreshTotalMoney()
	if not self._data then
		FGUI:GList_setNumItems(self._ui.list_total_money, 0)
		return
	end

	local moneyList = {}	
	local num = 0
	for _, v in ipairs(self._data) do
		if v.selected == 1 then
			local moneytype = v.moneytype
			local total_price = v.buycount * v.price
			if moneyList[moneytype] then
				moneyList[moneytype] = moneyList[moneytype] + total_price
			else
				moneyList[moneytype] = total_price
				num = num + 1
			end
		end
	end

	self._totalMoneyList = {}
	for index, price in pairs(moneyList) do
		local data = {}
		data.index = index
		data.price = price
		local owner_count = tonumber(SL:GetValue("MONEY", data.index)) or 0
		data.moneyenough = owner_count >= data.price
		table.insert(self._totalMoneyList, data)
	end

	FGUI:GList_setNumItems(self._ui.list_total_money, num)
end

function StallShoppingCart:OnTotalMoneyListRenderer(idx, item)
	local data = self._totalMoneyList[idx + 1]
	local moneyData = SL:GetValue("ITEM_DATA", data.index) or {}
	local text_money_name = FGUI:GetChild(item, "text_money_name")
	FGUI:GTextField_setText(text_money_name, moneyData.Name)
	local text_money_count = FGUI:GetChild(item, "text_money_count")
	FGUI:GTextField_setText(text_money_count, data.price)
	FGUI:GTextField_setColor(text_money_count, data.moneyenough and "#FFFFFF" or "#FF0000")
end

-- 点击结算
function StallShoppingCart:OnClickBuyAll()
	if not self._data then return end

	local isMoneyEnough = true
	for k, v in ipairs(self._totalMoneyList) do
		if not v.moneyenough then
			isMoneyEnough = false
			break
		end
	end

	if not isMoneyEnough then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING", 30000087))
	else
		SL:RequestStallShoppingCartBuyAll(self._data)
	end
end


function StallShoppingCart:Exit()
	self:RemoveEvent()
	-- 保存购物车信息，保存选中状态和购物数量
	local data = {}
	for k, v in ipairs(self._data) do
		if not self._buyFailItems[v.makeindex] then
			data[v.makeindex] = v
		end	
	end
	SL:SetValue("STALL_SAVE_SHOPPING_CART_DATA", data)
	SLBridge:onLUAEvent(LUA_EVENT_STALL_REFRESH_CART)
	for k, v in pairs(self._scheduleMap) do
		SL:UnSchedule(v)
	end
	self._scheduleMap = {}
end

function StallShoppingCart:Close()
	self.super.Close(self)
end

function StallShoppingCart:OnBuyFailTips(errorType, makeindex)
	local errorStr = ""
	if errorType == -2 then
		errorStr = SL:GetValue("I18N_STRING", 90010012)
	elseif errorType == -3 then
		errorStr = SL:GetValue("I18N_STRING", 90010013)
	elseif errorType == -6 then
		errorStr = SL:GetValue("I18N_STRING", 70000006)
	end
	local str = SL:GetValue("I18N_STRING", 90010039)
	if errorStr ~= "" then
		str = string.format("%s：%s", str, errorStr)
	end

	self._buyFailItems[makeindex] = str
end

function StallShoppingCart:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_STALL_REFRESH_CART, "StallShoppingCart", handler(self, self.RefreshDisplay))
	SL:RegisterLUAEvent(LUA_EVENT_STALL_BUY_FAIL_TIPS, "StallShoppingCart", handler(self, self.OnBuyFailTips))
end

function StallShoppingCart:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_REFRESH_CART, "StallShoppingCart")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_BUY_FAIL_TIPS, "StallShoppingCart")
end

return StallShoppingCart