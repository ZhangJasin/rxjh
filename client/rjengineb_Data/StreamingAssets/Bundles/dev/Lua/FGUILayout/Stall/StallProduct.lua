local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local StallProduct = class("StallProduct", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
-- 摆摊商品界面

local range = 5 -- 判定是否在摊位点上的距离
local CHANNEL = SLDefine.CHAT_CHANNEL

function StallProduct:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	self._data = nil
	self._product_data = {}
	self._isSelf = false
	self._closeTime = 0
	self._timeSchedule = nil
	self._curOperateItem = nil
	self._curBuyMakeIndex = nil -- 当前购买界面物品makeindex
	self.handler_OnProductItemRenderer = handler(self, self.OnProductItemRenderer)
	self.handler_ShowItemTips = handler(self, self.ShowItemTips)
	self._capacity = SL:GetValue("GAME_DATA","BaiTanMax") or 8
	self._lastIsSelf = false

	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	-- 关闭摊位
	FGUI:setOnClickEvent(self._ui.btn_close_shop, handler(self, self.CloseStallShop))

	FGUI:GList_itemRenderer(self._ui.list_product, self.handler_OnProductItemRenderer)
	FGUI:GList_setOnClickItemEvent(self._ui.list_product, handler(self, self.OnClickProductItem))

	FGUI:setOnClickEvent(self._ui.btn_prev, function ()
		SL:onLUAEvent(LUA_EVENT_STALL_BROWSE_SWITCH, false)
	end)
	
	FGUI:setOnClickEvent(self._ui.btn_next, function ()
		SL:onLUAEvent(LUA_EVENT_STALL_BROWSE_SWITCH, true)
	end)

	FGUI:setOnClickEvent(self._ui.btn_owner_info, handler(self, self.OnClickOwnerInfo))

	FGUI:setOnClickEvent(self._ui.btn_share, handler(self, self.OnClickShareButton))
	FGUI:setOnClickEvent(self._ui.btn_edit, handler(self, self.OnClickEditNameButton))
	FGUI:setOnClickEvent(self._ui.btn_star, handler(self, self.OnClickCollectShop))
	FGUI:setOnClickEvent(self._ui.btn_sell_history, function ()
		FGUI:Open("Stall", "StallHistory", self._data.Userid)
	end)
end

function StallProduct:Enter()
	self:RegisterEvent()
	FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA", "BagMoneyList"))
end

function StallProduct:Refresh(data) 
	local scrollPanel = FGUI:GetScrollPane(self._ui.list_product)
	FGUI:ScrollPane_scrollTop(scrollPanel, false)
	if not data then return end
	self._data = data
	self._isSelf = data.isSelf
	self._product_data = {}
	SL:RequestStallQueryItems(data.Userid)
	self._closeTime = data.CloseTime or 0

	FGUI:setVisible(self._ui.btn_close_shop, self._isSelf)
	FGUI:setVisible(self._ui.btn_sell_history, self._isSelf)
	FGUI:setVisible(self._ui.btn_edit, self._isSelf)
	FGUI:setVisible(self._ui.btn_share, self._isSelf)
	FGUI:setVisible(self._ui.node_star, not self._isSelf)
	FGUI:setVisible(self._ui.btn_owner_info, not self._isSelf)

	if not self._isSelf then
		local isCollected = self._data.IsCollected
		FGUI:GButton_setSelected(self._ui.btn_star, isCollected)
		local str = SL:GetValue("I18N_STRING", isCollected and 90010033 or 90010034)
		FGUI:GTextField_setText(self._ui.text_star, str)
	end

	if self._isSelf and not self._lastIsSelf then
		local transition = FGUI:GetTransition(self.component, "left")
		FGUI:Transition_play(transition)
	elseif not self._isSelf and self._lastIsSelf then
		local transition = FGUI:GetTransition(self.component, "center")
		FGUI:Transition_play(transition)
	end
	self._lastIsSelf = self._isSelf
	
	-- 商店名
	FGUI:GTextField_setText(self._ui.title_stall_name, data.Name)
	-- 摊主名
	FGUI:GTextField_setText(self._ui.title_owner_name, FGUIFunction:GetServerName(data.UserName))
	FGUI:GList_setNumItems(self._ui.list_product, self._capacity)

	-- 浏览界面显示上一页下一页
	if data.isBrowse then
		FGUI:setVisible(self._ui.btn_prev, true)
		FGUI:setVisible(self._ui.btn_next, true)
	else
		FGUI:setVisible(self._ui.btn_prev, false)
		FGUI:setVisible(self._ui.btn_next, false)
	end

	-- 倒计时
	local refreshTime = function ()
		local remainTime = 	self._closeTime - SL:GetValue("SERVER_TIME")
		if remainTime <= 0 then
			SL:ShowSystemTips(GET_STRING(90010010))
			self:Close()
		else
			local timeStr = SL:SecondToHMS(remainTime, true)
			FGUI:GTextField_setText(self._ui.text_remain_time, timeStr)
		end
	end
	if self._timeSchedule then
		SL:UnSchedule(self._timeSchedule)
		self._timeSchedule = nil
	end
	self._timeSchedule = SL:Schedule( refreshTime, 1)
	refreshTime()

	SL:ComponentAttach(SLDefine.SUIComponentTable.StallProduct, self._ui.Node_attach)
end

function StallProduct:Exit()
	self:RemoveEvent()
	FGUI:Close("Bag", "SimpleBagPanel")
	FGUI:Close("Stall", "StallBuy")
	FGUIFunction:HideTopCurrency()
	if self._timeSchedule then
		SL:UnSchedule(self._timeSchedule)
		self._timeSchedule = nil
	end

	SL:ComponentDetach(SLDefine.SUIComponentTable.StallProduct)
end

function StallProduct:Close()
	self.super.Close(self)
end

function StallProduct:CloseStallShop()
	local dialogData = {}
	dialogData.str = GET_STRING(90010021)
	dialogData.btnDesc = {GET_STRING(1001), GET_STRING(1000)}
	dialogData.callback = function (tag)
		if tag == 1 then
			SL:RequestCloseStallShop()
			-- 查询自身店铺信息
			SL:RequestStallSelfShop()
			SLBridge:onLUAEvent(LUA_EVENT_STALL_REFRESH_PAGE)
		end
	end
	SL:OpenCommonDialog(dialogData)
end

function StallProduct:OnProductItemRenderer(idx, item)
	local data = self._product_data[idx + 1]
	FGUI:SetIntData(item, idx)
	local empty = FGUI:GetChild(item, "empty")
	if not data or not data.useritem then 
		FGUI:setVisible(empty, true)
		FGUI:setTouchEnabled(item, false)
		return
	end
	FGUI:setVisible(empty, false)
	FGUI:setTouchEnabled(item, true)
	local itemData = data.useritem
	if not itemData then return end

	local text_name = FGUI:GetChild(item, "text_name")
	local text_count = FGUI:GetChild(item, "text_count")
	local text_price = FGUI:GetChild(item, "text_price")
	local obj_item = FGUI:GetChild(item, "item")
	local text_money_name = FGUI:GetChild(item, "text_money_name")
	ItemUtil:RefreshItemUIByData(obj_item, itemData)
	ItemUtil:UpdateIsShowLockByItemID(obj_item, itemData)
	ItemUtil:SetItemSubScriptByItemID(obj_item, itemData.ID)
	FGUI:setOnClickEvent(obj_item, self.handler_ShowItemTips)
	FGUI:SetIntData(obj_item, idx)
	local moneyData = SL:GetValue("ITEM_DATA", data.type) or {}
	FGUI:GTextField_setText(text_money_name, moneyData.Name)
	FGUI:GTextField_setText(text_name, itemData.Name)
	FGUI:GTextField_setText(text_count, data.useritem.OverLap)
	FGUI:GTextField_setText(text_price, SL:GetThousandSepString(data.price))
end

function StallProduct:OnClickProductItem(context)
	local idx = FGUI:GetIntData(context.data)
	local data = self._product_data[idx + 1]
	if self._isSelf then
		self:OpenTakeOffPanel(data)
	else
		self:OpenBuyPanel(data)
	end
end

-- 显示物品提示
function StallProduct:ShowItemTips(context)
	FGUI:EventContext_stopPropagation(context)
	local idx = FGUI:GetIntData(context.sender)
	local data = self._product_data[idx + 1]
	FGUIFunction:OpenItemTips({itemData = data.useritem, hideButtons = true})
end

-- 刷新商品界面信息
function StallProduct:OnRefreshProductInfo(data)
	if data then
		self._product_data = data
		FGUI:GList_setNumItems(self._ui.list_product, self._capacity)
	end
end

-- 点击编辑店铺名按钮
function StallProduct:OnClickEditNameButton()
	local data = {}
	data.title =  SL:GetValue("I18N_STRING", 40070002)
	data.str = SL:GetValue("I18N_STRING", 90010032)
	data.showEdit = true
	data.editParams = {}
	data.editParams.str = self._data.Name
	data.btnDesc  = {GET_STRING(90020002), GET_STRING(1000)}
	data.callback = function (tag, editInfo)
		if tag == 1 then
			local input = editInfo.editStr 
			if not input or string.len(input) == 0 then
				SL:ShowSystemTips(GET_STRING(90010015))
				return
			end
			SL:RequestChangeShopName(input)
		end
	end
	SL:OpenCommonDialog(data)
end

-- 点击分享按钮
function StallProduct:OnClickShareButton()
	SL:RequestSendTradeMsg(CHANNEL.Trade, self._data.Name, self._data.Userid)
end

-- 上架
function StallProduct:PutOnItem(itemData)
	local itemInfo = SL:GetValue("ITEM_DATA", itemData.Index)
	if not itemInfo then return end
	local isBind, isMeetType =  SL:GetValue("ITEM_IS_BIND", itemData, FGUIDefine.ItemArticleType.TYPE_STALL)
	if isMeetType then
		SL:ShowSystemTips(GET_STRING(90010029))
		return
	end

	local number = self._product_data and #self._product_data or 0
	if number >= self._capacity then
		SL:ShowSystemTips(GET_STRING(90010025))
		return
	end
	if not self._isSelf then return end
	-- 判断是否在自身摊位旁
	local isOnStallArea = self:IsOnSelfShopPoint()
	if isOnStallArea then
		FGUI:Open("Stall", "StallShelf", itemData)
	else
		local data = {}
		data.str = GET_STRING(90010014)
		data.btnDesc = {GET_STRING(1001), GET_STRING(1000)}
		data.callback = function (tag)
			if tag == 1 then
				SL:SetValue("STALL_AUTO_MOVE_OPEN", nil)
				self:Close()
			end
		end
		SL:OpenCommonDialog(data)		
	end	
end

-- 点击查看摊位主
function StallProduct:OnClickOwnerInfo()
	local dockData = {}
	dockData.targetName = self._data.UserName
    dockData.targetId = tonumber(self._data.Userid)
	dockData.TipsType = SL:GetValue("DOCKTYPE_NENUM").Func_Friend
	dockData.Level = 2
	dockData.Job = 1
	dockData.Sex = 1
    FGUIFunction:OpenFuncDockTips(dockData)
end

function StallProduct:IsOnSelfShopPoint()
	local shopData = SL:GetValue("STALL_MY_DATA")
	if not shopData then 
		return false
	end
	local pX = SL:GetValue("X")
	local pY = SL:GetValue("Z")
	local tX = shopData.X
	local tY = shopData.Y
	local dis = math.sqrt((pX - tX) ^ 2 + (pY - tY) ^ 2)
	if dis < range then
		return true
	else
		return false
	end
end

-- 上架物品成功
function StallProduct:OnPutOnSuccess(data, notTips)
	if not data then return end
	table.insert(self._product_data, data)
	FGUI:GList_setNumItems(self._ui.list_product, self._capacity)
	if not notTips then
		SL:ShowSystemTips(GET_STRING(40050033))
	end	
end

-- 下架物品成功
function StallProduct:OnTakeOffSuccess(makeindex, notTips)
	for pos,v in pairs(self._product_data) do
		if v.useritem.MakeIndex == makeindex then
			table.remove(self._product_data, pos)
		end

		if self._curBuyMakeIndex and makeindex == self._curBuyMakeIndex then
			self._curBuyMakeIndex = nil
			FGUI:Close("Stall", "StallBuy")
			SL:ShowSystemTips(GET_STRING(90010028))
		end
	end
	FGUI:GList_setNumItems(self._ui.list_product, self._capacity)
	if not notTips then
		SL:ShowSystemTips(GET_STRING(40050034))
	end
end

-- 打开购买界面
function StallProduct:OpenBuyPanel(data)
	if not data then return end
	self._curBuyMakeIndex = data.useritem.MakeIndex
	FGUI:Open("Stall", "StallBuy", data)
end

-- 打开下架界面
function StallProduct:OpenTakeOffPanel(data)
	if not data then return end
	local dialogData = {}
	dialogData.str = string.format(GET_STRING(90010011),data.useritem.Name)
	dialogData.btnDesc = {GET_STRING(1001), GET_STRING(1000)}
	dialogData.callback = function (tag)
		if tag == 1 then
			--确定
			-- 判断物品是否还在货架上
			local isExisted  = false
			for _,v in ipairs(self._product_data) do
				if v.useritem.MakeIndex == data.useritem.MakeIndex then
					isExisted = true
					break
				end
			end
			if isExisted then
				SL:RequestStallTakeOffItem(data.useritem.MakeIndex)
			else
				SL:ShowSystemTips(GET_STRING(90010028))
			end	
		end
	end
	SL:OpenCommonDialog(dialogData)
end

-- 购买物品
function StallProduct:OnBuyItem(data)
	local makeindex = data.makeindex
	local count = data.count
	for pos,v in pairs(self._product_data) do
		if v.useritem.MakeIndex == makeindex then
			if count == 0 then
				table.remove(self._product_data, pos)
			else
				v.useritem.OverLap = count
			end
			break
		end
	end
	FGUI:GList_setNumItems(self._ui.list_product, self._capacity)
end

-- 物品变化
function StallProduct:OnItemChange(data)
	if data.userid ~= self._data.Userid then return end

	if data.changeType == 1 then
		-- 新增
		self:OnPutOnSuccess(data, true)
	elseif data.changeType == 2 then
		-- 移除
		self:OnTakeOffSuccess(data.useritem.MakeIndex, true)
	elseif data.changeType == 3 then
		-- 数量变化
		self:OnBuyItem(data)
	end
end

-- 摆摊购买失败提示
function StallProduct:OnBuyFailTips(errorType)
	if errorType == -2 then
		SL:ShowSystemTips(GET_STRING(90010012))
	elseif errorType == -3 then
		SL:ShowSystemTips(GET_STRING(90010013))
	elseif errorType == -6 then
		SL:ShowSystemTips(GET_STRING(70000006))
	else
		SL:ShowSystemTips(GET_STRING(30000039))
		SL:RequestStallQueryItems(self._data.Userid)
		FGUI:Close("Stall", "StallBuy")
	end	
end

function StallProduct:OnChangeShopName(name)
	self._data.Name = name
	FGUI:GTextField_setText(self._ui.title_stall_name, name)
end

-- 点击收藏按钮
function StallProduct:OnClickCollectShop()
	local isSelected = FGUI:GButton_getSelected(self._ui.btn_star)
	SL:RequestCollectShop(self._data.Userid, isSelected)
	local str = SL:GetValue("I18N_STRING", isSelected and 90010033 or 90010034)
	FGUI:GTextField_setText(self._ui.text_star, str)
end

function StallProduct:OnCollectShop(userid, isCollected)
	if userid == self._data.Userid then
		local isVisible = FGUI:getVisible(self._ui.node_star)
		if isVisible then
			FGUI:GButton_setSelected(self._ui.btn_star, isCollected)
			local str = SL:GetValue("I18N_STRING", isCollected and 90010033 or 90010034)
			FGUI:GTextField_setText(self._ui.text_star, str)
		end
	end
end


function StallProduct:RegisterEvent()
   	SL:RegisterLUAEvent(LUA_EVENT_STALL_PUT_ON_SUCCESS, "StallProduct", handler(self, self.OnPutOnSuccess))
	SL:RegisterLUAEvent(LUA_EVENT_STALL_REFRESH_PRODUCT, "StallProduct", handler(self, self.OnRefreshProductInfo))  
	SL:RegisterLUAEvent(LUA_EVENT_STALL_TAKE_OFF, "StallProduct", handler(self, self.OnTakeOffSuccess))
	SL:RegisterLUAEvent(LUA_EVENT_STALL_BUY_ITEM, "StallProduct", handler(self, self.OnBuyItem))
	SL:RegisterLUAEvent(LUA_EVENT_STALL_PRODUCT_CHANGE, "StallProduct", handler(self, self.OnItemChange))
	SL:RegisterLUAEvent(LUA_EVENT_STALL_BUY_FAIL_TIPS, "StallProduct", handler(self, self.OnBuyFailTips))
	SL:RegisterLUAEvent(LUA_EVENT_STALL_OPEN_SHELF, "StallProduct", handler(self, self.PutOnItem))
	SL:RegisterLUAEvent(LUA_EVENT_STALL_CLOSE_SHOP, "StallProduct", handler(self, self.Close))
	SL:RegisterLUAEvent(LUA_EVENT_STALL_CHANGE_SHOP_NAME, "StallProduct", handler(self, self.OnChangeShopName))
	SL:RegisterLUAEvent(LUA_EVENT_STALL_COLLECT_SHOP, "StallProduct", handler(self, self.OnCollectShop))	--收藏店铺
end

function StallProduct:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_PUT_ON_SUCCESS, "StallProduct")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_REFRESH_PRODUCT, "StallProduct")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_TAKE_OFF, "StallProduct")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_BUY_ITEM, "StallProduct")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_PRODUCT_CHANGE, "StallProduct")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_BUY_FAIL_TIPS, "StallProduct")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_OPEN_SHELF, "StallProduct")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_CLOSE_SHOP, "StallProduct")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_CHANGE_SHOP_NAME, "StallProduct")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_COLLECT_SHOP, "StallProduct")
end

return StallProduct