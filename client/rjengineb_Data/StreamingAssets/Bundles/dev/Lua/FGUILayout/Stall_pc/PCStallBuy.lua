local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCStallBuy = class("PCStallBuy", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
-- 摆摊购买界面

function PCStallBuy:Create()
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

	FGUI:GTextInput_setOnChanged(self._ui.text_count, handler(self, self.OnCountValueChanged))
	FGUI:setOnFocusOut(self._ui.text_count, handler(self, self.OnCountValueFocusOut))
end

function PCStallBuy:Enter(data)
	self:RegisterEvent()
	if not data then return end
	self._itemInfo = data
	self._maxCount = self._itemInfo.useritem.OverLap
	self._price = self._itemInfo.price
	self._goldType = self._itemInfo.type
	self:InitUI()
end

function PCStallBuy:InitUI()
	local itemData = SL:GetValue("ITEM_DATA", self._itemInfo.useritem.Index) or {}
	ItemUtil:RefreshItemUIByData(self._ui.icon_item, itemData)
	ItemUtil:UpdateIsShowLockByItemID(self._ui.icon_item, itemData)
	ItemUtil:SetItemSubScriptByItemID(self._ui.icon_item, itemData.ID)
	local goldData = SL:GetValue("ITEM_DATA", self._goldType)
	FGUI:GTextField_setText(self._ui.text_gold, goldData.Name)
	FGUI:GTextField_setText(self._ui.text_item_name, itemData.Name)
	self:SetCount(1)
end

function PCStallBuy:OnCountValueChanged(context)
	local str = FGUI:GTextInput_getText(context.sender)
	if str and str ~= "" then
		local num = tonumber(str)	
		if not num then
			self:SetCount(self._curCount)
		else
			self:SetCount(num)
		end
	end
end

function PCStallBuy:OnCountValueFocusOut(context)
	local str = FGUI:GTextInput_getText(context.sender)
	if str and str == "" then
		self:SetCount(1)
	end
end

function PCStallBuy:SetCount(cnt)
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

function PCStallBuy:GetMaxCount()
	local moneyCount = SL:GetValue("MONEY", self._goldType)
	local canBuyCount = math.floor(moneyCount / self._price)
	local cnt = math.min(canBuyCount, self._maxCount)
	if cnt < 1 then
		cnt = 1
	end
	return 	cnt
end

function PCStallBuy:OnClickBuyButton()
	local count = tonumber(SL:GetValue("MONEY", self._itemInfo.type)) or 0
	local total_price = self._price * self._curCount
	--货币不足
	if count < total_price then
		SL:ShowSystemTips(GET_STRING(70000006))
		return
	end

	SL:RequestStallBuyItem(self._itemInfo.useritem.MakeIndex, self._price, self._curCount)
end

function PCStallBuy:Exit()
	self:RemoveEvent()
	self._itemInfo = nil
end

function PCStallBuy:Close()
	self.super.Close(self)
end

-- 购买物品成功
function PCStallBuy:OnBuyItemSuccess()
	self:Close()
end

function PCStallBuy:RegisterEvent()
   	SL:RegisterLUAEvent(LUA_EVENT_STALL_BUY_ITEM, "PCStallBuy", handler(self, self.OnBuyItemSuccess))

end

function PCStallBuy:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_BUY_ITEM, "PCStallBuy")
end

return PCStallBuy