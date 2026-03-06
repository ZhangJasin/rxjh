local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local StallBuy = class("StallBuy", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
-- 摆摊购买界面

function StallBuy:Create()
	self.super.Create(self)
	self._itemInfo = nil
	self._maxCount = 1
	self._price = 1
	self._curCount = 1
	self._goldType = nil
	self._ui = FGUI:ui_delegate(self.component)

	FGUI:setOnClickEvent(self._ui.btn_sub, function ()
		self:SetCount(self._curCount - 1)
	end)
	FGUI:setOnClickEvent(self._ui.btn_add, function ()
		self:SetCount(self._curCount + 1)
	end)
	FGUI:setOnClickEvent(self._ui.btn_max, function ()
		self:SetCount(self._maxCount)
	end)
	FGUI:setOnClickEvent(self._ui.btn_no, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_yes, handler(self, self.OnClickBuyButton))

	FGUI:setOnClickEvent(self._ui.btn_input_edit, function ()
		local data = {}
		data.title = GET_STRING(90010006)
		data.maxNum =  self:GetMaxCount()
		data.callback_yes = function (number)
			self:SetCount(number)
		end
		FGUIFunction:OpenCommonNumberInputPanel(data)
	end)

end

function StallBuy:Enter(data)
	self:RegisterEvent()
	if not data then return end
	self._itemInfo = data
	self._maxCount = self._itemInfo.useritem.OverLap
	self._price = self._itemInfo.price
	self._goldType = self._itemInfo.type
	self:InitUI()
end

function StallBuy:InitUI()
	local itemData = SL:GetValue("ITEM_DATA", self._itemInfo.useritem.Index) or {}
	ItemUtil:RefreshItemUIByData(self._ui.icon_item, itemData)
	ItemUtil:UpdateIsShowLockByItemID(self._ui.icon_item,itemData)
	ItemUtil:SetItemSubScriptByItemID(self._ui.icon_item,itemData.ID)
	local goldData = SL:GetValue("ITEM_DATA", self._goldType)
	FGUI:GTextField_setText(self._ui.text_gold, goldData.Name)
	FGUI:GTextField_setText(self._ui.text_item_name, itemData.Name)
	self:SetCount(1)
end

function StallBuy:SetCount(cnt)
	if cnt < 1 then
		cnt = 1
	elseif cnt > self:GetMaxCount() then
		cnt = self:GetMaxCount()
	end
	self._curCount = cnt
	FGUI:GTextField_setText(self._ui.text_count, self._curCount)
	local price_str = SL:GetThousandSepString(self._price * self._curCount)
	FGUI:GTextField_setText(self._ui.text_total_price, price_str)
end

function StallBuy:GetMaxCount()
	local moneyCount = SL:GetValue("MONEY", self._goldType)
	local canBuyCount = math.floor(moneyCount / self._price)
	local cnt = math.min(canBuyCount, self._maxCount)
	if cnt < 1 then
		cnt = 1
	end
	return 	cnt
end

function StallBuy:OnClickBuyButton()
	local count = tonumber(SL:GetValue("MONEY", self._itemInfo.type)) or 0
	local total_price = self._price * self._curCount
	--货币不足
	if count < total_price then
		SL:ShowSystemTips(GET_STRING(70000006))
		return
	end

	SL:RequestStallBuyItem(self._itemInfo.useritem.MakeIndex, self._price, self._curCount)
end

function StallBuy:Exit()
	self:RemoveEvent()
	self._itemInfo = nil
end

function StallBuy:Close()
	self.super.Close(self)
end

-- 购买物品成功
function StallBuy:OnBuyItemSuccess()
	self:Close()
end

function StallBuy:RegisterEvent()
   	SL:RegisterLUAEvent(LUA_EVENT_STALL_BUY_ITEM, "StallBuy", handler(self, self.OnBuyItemSuccess))

end

function StallBuy:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_BUY_ITEM, "StallBuy")
end

return StallBuy