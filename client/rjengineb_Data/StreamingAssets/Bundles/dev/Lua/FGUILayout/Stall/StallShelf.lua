local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local StallShelf = class("StallShelf", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
-- 摆摊上架输入界面

local defualtMoneyType = 0

function StallShelf:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)

	self._curInputVal = 0 	-- 当前输入值
	self._lastInputVal = 0 	-- 上一次输入值
	self._makeindex = nil	-- 物品MakeIndex
	self._productPrice = 1	-- 出售单价
	self._productCount = 1	-- 出售数量
	self._goldType = 1		-- 货币类型
	self._maxCount = 1		-- 最大出售数量
	self._goldInfos = {}	-- 货币参数信息 {i:id, v:额度, t:税率}

	FGUI:GList_itemRenderer(self._ui.list_money_type,  handler(self, self.OnMoneyListRenderer))
	FGUI:GList_addOnClickItemEvent(self._ui.list_money_type, handler(self, self.OnSelectGoldType))

	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.mask, handler(self, self.Close))
	
	FGUI:setOnClickEvent(self._ui.btn_count_edit, function ()
		local data = {}
		data.title = GET_STRING(90010006)
		data.callback_yes = function (number)
			self:SetCount(number)
		end
		FGUIFunction:OpenCommonNumberInputPanel(data)
	end)

	FGUI:setOnClickEvent(self._ui.btn_price_edit, function ()
		local data = {}
		data.title = GET_STRING(90010007)
		data.callback_yes = function (number)
			self:SetPrice(number)
		end
		FGUIFunction:OpenCommonNumberInputPanel(data)
	end)

	--出售数量
	FGUI:setOnClickEvent(self._ui.btn_count_sub, function ()
		self:SetCount(self._productCount - 1)
	end)

	FGUI:setOnClickEvent(self._ui.btn_count_add, function ()
		self:SetCount(self._productCount + 1)
	end)
	FGUI:setOnClickEvent(self._ui.btn_count_max, function ()
		self:SetCount(self._maxCount)
	end)

	--出售单价
	FGUI:setOnClickEvent(self._ui.btn_price_sub, function ()
		self:SetPrice(self._productPrice - 1)
	end)
	FGUI:setOnClickEvent(self._ui.btn_price_add, function ()
		self:SetPrice(self._productPrice + 1)
	end)

	-- 上架
	FGUI:setOnClickEvent(self._ui.btn_shelf, handler(self, self.OnClickShelfEvent))
	-- 取消
	FGUI:setOnClickEvent(self._ui.btn_cancel, handler(self, self.Close))
end

function StallShelf:Enter(itemData)
	self:RegisterEvent()
	self:InitMoneyInfo()
	FGUI:GList_setSelectedIndex(self._ui.list_money_type, defualtMoneyType)
	self:SetCount(1)
	self:SetPrice(1)
	itemData.isShowCount = false
	-- 图标
	ItemUtil:RefreshItemUIByData(self._ui.item, itemData)
	ItemUtil:UpdateIsShowLockByItemID(self._ui.item, itemData)
	ItemUtil:SetItemSubScriptByItemID(self._ui.item, itemData.ID)
	ItemUtil:AddItemClick(self._ui.item, itemData)
	FGUI:GTextField_setText(self._ui.text_product_name, itemData.Name)
	self._maxCount = itemData.OverLap
	self._makeindex = itemData.MakeIndex
	self:OnSelectGoldType()
end

-- 初始化货币信息
function StallShelf:InitMoneyInfo()
	self._goldInfos = SL:GetValue("STALL_MONEY_INFO") or {}
	FGUI:GList_setNumItems(self._ui.list_money_type,  #self._goldInfos)
end

function StallShelf:OnMoneyListRenderer(idx, item)
	local data = self._goldInfos[idx + 1]
	local id = data.i	--货币id
	--local remain = data.v	--货币额度
	local tax = data.t	--货币税率
	local moneyData = SL:GetValue("ITEM_DATA", id) or {}
	self._goldInfos[idx + 1].Name = moneyData.Name
	local text_name = FGUI:GetChild(item, "text_money_name")
	local text_tax = FGUI:GetChild(item, "text_money_tax")
	FGUI:GTextField_setText(text_name, moneyData.Name)
	FGUI:GTextField_setText(text_tax, string.format(GET_STRING(90010018), moneyData.Name, tax / 100))
end

function StallShelf:Exit()
	self:RemoveEvent()
end

function StallShelf:Close()
	self.super.Close(self)
end

function StallShelf:SetCount(num)
	if num < 1 then
		num = 1
	elseif num > self._maxCount then
		num = self._maxCount
	end

	self._productCount = num
	FGUI:GTextField_setText(self._ui.text_count, num)
	FGUI:GTextField_setText(self._ui.text_total_price, self._productCount * self._productPrice)
end

function StallShelf:SetPrice(price)
	if price < 1 then
		price = 1
	end

	self._productPrice = price
	FGUI:GTextField_setText(self._ui.text_price, price)
	FGUI:GTextField_setText(self._ui.text_total_price, self._productCount * self._productPrice)
end

-- 上架
function StallShelf:OnClickShelfEvent()
	if not self._goldInfos or not next(self._goldInfos) then
		SL:print("No GoldInfos")
		return
	end

	local goldListIndex = FGUI:GList_getSelectedIndex(self._ui.list_money_type)
	local goldType = self._goldInfos[goldListIndex + 1].i

	--比较额度是否充足
	-- local totalPrice = self._productCount * self._productPrice
	-- if totalPrice > self._goldInfos[goldListIndex + 1].v then
	-- 	SL:ShowSystemTips(GET_STRING(90010019))
	-- 	return
	-- end

	SL:RequestStallPutOnItem(self._makeindex, self._productCount, self._productPrice, goldType)
end

-- 上架物品成功
function StallShelf:OnPutOnSuccess(data)
	self:Close()
end


function StallShelf:OnSelectGoldType()
	local goldListIndex = FGUI:GList_getSelectedIndex(self._ui.list_money_type)
	local info = self._goldInfos[goldListIndex + 1]
	if info then
		FGUI:GTextField_setText(self._ui.text_totol_name, string.format("[%s]",info.Name))
	end
end


function StallShelf:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_STALL_PUT_ON_SUCCESS, "StallShelf", handler(self, self.OnPutOnSuccess))
end

function StallShelf:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_PUT_ON_SUCCESS, "StallShelf")
end

return StallShelf