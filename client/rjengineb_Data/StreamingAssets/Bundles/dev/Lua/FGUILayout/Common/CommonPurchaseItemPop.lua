local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CommonPurchaseItemPop = class("CommonPurchaseItemPop", BaseFGUILayout)
local ItemMoney = SL:RequireFile("FGUILayout/Item/ItemMoney")

--[[
	-- 购买框参数 table
	-- num = 默认购买数量
	-- minNum = 最小购买数量
	-- maxNum = 最大购买数量
	-- coinId = 货币ID (支持多货币#分隔)
	-- storeId = 商品ID
	-- price = 单价
	-- buyCount = 最大购买次数
	-- curBuyCount = 当前购买次数
	-- purchaseType = 购买类型

	-- customBuy = bool 是否自定义购买(无需商品ID)
	-- customLeftBtnText = 自定义左侧按钮文本 (配置增加左侧按钮显示)
	-- customLeftBtnWidth = 自定义左侧按钮宽度
	-- customLeftBtnFunc = 自定义左侧按钮事件触发 function
	-- customBuyFunc = 自定义购买按钮事件触发 function
]]
function CommonPurchaseItemPop:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)

    self._countInput = self._ui.input_count
	self._posController = FGUI:getController(self.component, "btn_pos")
    
    self.onAddNumHandler = handler(self, self.OnAddNumEvent)
	self.onSubNumHandler = handler(self, self.OnSubNumEvent)
	self.onSetMinNumHandler = handler(self, self.OnSetMinNumEvent)
	self.onSetMaxNumHandler = handler(self, self.OnSetMaxNumEvent)
	self.onPurchaseItemHandler = handler(self, self.OnPurchaseItemEvent)
	self.onCustomBtnHandler = handler(self, self.OnCustomBtnEvent)
	self.onInputItemHandler	= handler(self, self.OnInputItemEvent)
    
    FGUI:setOnClickEvent(self._ui.btn_add, self.onAddNumHandler)
	FGUI:setOnClickEvent(self._ui.btn_sub, self.onSubNumHandler)
	FGUI:setOnClickEvent(self._ui.btn_m_min, self.onSetMinNumHandler)
	FGUI:setOnClickEvent(self._ui.btn_m_max, self.onSetMaxNumHandler)
	FGUI:setOnClickEvent(self._ui.btn_purchase, self.onPurchaseItemHandler)
	FGUI:setOnClickEvent(self._ui.btn_custom, self.onCustomBtnHandler)
    if SL:GetValue("IS_PC_OPER_MODE") then
		FGUI:setOnFocusIn(self._countInput, self.onInputItemHandler)
	else
		FGUI:setOnClickEvent(self._countInput, self.onInputItemHandler)
	end
end

function CommonPurchaseItemPop:Enter(data)
    if not data or not next(data) then
        return
    end
    self._curItemID = data and data.itemID
    self:InitItemPurchasePanel(data)
end

function CommonPurchaseItemPop:Exit()
	self.super.Exit(self)
end

-- 道具购买框
function CommonPurchaseItemPop:OnAddNumEvent()
	if self._inputNum >= self._inputMaxNum then
		return
	end

	self._inputNum = self._inputNum + 1
	FGUI:GTextInput_setText(self._countInput, self._inputNum)
	self:UpdatePriceShow()
end

function CommonPurchaseItemPop:OnSubNumEvent()
	if self._inputNum <= self._inputMinNum then
		return
	end
	self._inputNum = self._inputNum - 1
	FGUI:GTextInput_setText(self._countInput, self._inputNum)
	self:UpdatePriceShow()
end

function CommonPurchaseItemPop:OnSetMinNumEvent()
	self._inputNum = self._inputMinNum
	FGUI:GTextInput_setText(self._countInput, self._inputNum)
	self:UpdatePriceShow()
end

function CommonPurchaseItemPop:OnSetMaxNumEvent()
	self._inputNum = self._inputMaxNum
	FGUI:GTextInput_setText(self._countInput, self._inputNum)
	self:UpdatePriceShow()
end

local sharedTab = {}
function CommonPurchaseItemPop:OnPurchaseItemEvent(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	if not self._storeID and not self._customBuy then
		return
	end
	
	if self._maxBuyCount and self._curBuyCount >= self._maxBuyCount then
	    SL:ShowSystemTips(SL:GetValue("I18N_STRING", 30000013))
	    return
	end

	local price = self._inputNum * self._price
	local isMoneyEnough, costType, currentMoney, costList = SL:GetValue("NPC_STORE_GET_ENOUGH_COSTTYPE", self._coinID, price)
	local costTypeName = SL:GetValue("ITEM_DATA",costType).Name
	if not isMoneyEnough then
		SL:ShowSystemTips(string.format(SL:GetValue("I18N_STRING", 30000010), costTypeName))
        return
	end

	if SL:GetValue("BAG_IS_FULL", true) then
	    return
	end

	if self._customBuyFunc then
		sharedTab.inputNum = self._inputNum
		self._customBuyFunc(sharedTab)
		return
	end

	if not self._storeID then
		return
	end

	local callBack = function()
		SL:RequestStoreBuy(self._storeID, self._inputNum, self._purchaseType)
	end

	TreasureShop.ReqBuyDialog(costList,callBack)
end

function CommonPurchaseItemPop:OnCustomBtnEvent()
	if self._customLeftBtnFunc then
		sharedTab.inputNum = self._inputNum
		self._customLeftBtnFunc(sharedTab)
	end
end

function CommonPurchaseItemPop:OnInputItemEvent()
    local data = {}
    data.title = SL:GetValue("I18N_STRING", 90010006)
    data.maxNum = self._inputMaxNum
	data.curNum = self._inputNum
    data.callback_yes = function(number)
		self:SetInputNum(number)
		FGUI:GTextInput_setText(self._countInput, self._inputNum)
		self:UpdatePriceShow()
    end
    FGUIFunction:OpenCommonNumberInputPanel(data)
end

function CommonPurchaseItemPop:SetInputNum(number)
    if self._inputMinNum then
        self._inputNum = math.max(number, self._inputMinNum)
    end

	if self._inputMaxNum then
        self._inputNum = math.min(number, self._inputMaxNum)
    end

    self._inputNum = math.max(self._inputNum, 1)
end

function CommonPurchaseItemPop:UpdatePriceShow()
	local price = self._inputNum * self._price
	local isMoneyEnough = SL:GetValue("NPC_STORE_GET_ENOUGH_COSTTYPE", self._coinID, price)
	local priceText = FGUI:GetChild(self._ui.price_cell, "text_count")
	FGUI:GTextField_setText(priceText, tostring(price))
	FGUI:GTextField_setColor(priceText, isMoneyEnough and "#00FF00" or "#FF0000")
end

function CommonPurchaseItemPop:InitItemPurchasePanel(data)
    if not data or not next(data) then
        return
    end

	local num = data.num or 1
	local minNum = data.minNum or 1
	local maxNum = data.maxNum or 9999
	local coinID = data.coinId or 2
	local storeID = data.storeId
	local price = data.price or 0
	local buyCount = data.buyCount
	local curBuyCount = data.curBuyCount or 0
	local purchaseType = data.purchaseType or 0
	local coinID1 = coinID
	if type(coinID) == "string" then
		local coinIDList = SL:Split(coinID, "#")
		coinID1 = tonumber(coinIDList[1])
	end
	local haveNum = tonumber(SL:GetValue("MONEY", coinID1))
	local moneyData = SL:GetValue("ITEM_DATA", coinID1)

	self._price = price
	self._storeID = storeID
	self._coinID = coinID
	self._inputNum = num
	self._inputMinNum = minNum
	self._inputMaxNum = maxNum
	self._curBuyCount = curBuyCount
	self._maxBuyCount = buyCount
	self._purchaseType = purchaseType
	self._coinName = moneyData and moneyData.Name or "ERROR货币"
	self._customBuy = data.customBuy
	self._customBuyFunc = data.customBuyFunc
	self._customLeftBtnFunc = data.customLeftBtnFunc
	self._showCustomLeftBtn = data.customLeftBtnText
	
	FGUI:Controller_setSelectedIndex(self._posController, self._showCustomLeftBtn and 1 or 0)
	FGUI:setVisible(self._ui.btn_custom, self._showCustomLeftBtn and true or false)
	if self._showCustomLeftBtn then
		FGUI:GButton_setTitle(self._ui.btn_custom, data.customLeftBtnText or "")
		FGUI:setWidth(self._ui.btn_custom, data.customLeftBtnWidth or FGUI:getWidth(self._ui.btn_purchase))
	end

	FGUI:GTextInput_setText(self._countInput, num)
	if not self._maxBuyCount then
		FGUI:setVisible(self._ui.text_buy_count, false)
	else
		FGUI:setVisible(self._ui.text_buy_count, true)
		FGUI:GTextField_setText(self._ui.text_buy_count, string.format("购买次数：%s/%s", curBuyCount, buyCount))
	end
	local priceCell = self._ui.price_cell
	local haveCell = self._ui.have_cell
	local haveText = FGUI:GetChild(haveCell, "text_count")
	FGUI:GTextField_setText(haveText, tostring(haveNum))
	self:UpdatePriceShow()

	local priceItem = FGUI:GetChild(priceCell, "item_money")
	local haveItem = FGUI:GetChild(haveCell, "item_money")

	if self._priceItemMoney then
		self._priceItemMoney:UpdateItemData(moneyData)
	else
		self._priceItemMoney = ItemMoney.new(priceItem, moneyData)
	end

	if self._haveItemMoney then
		self._haveItemMoney:UpdateItemData(moneyData)
	else
		self._haveItemMoney = ItemMoney.new(haveItem, moneyData)
	end

	self._priceItemMoney:UpdateItemCounts(false)
	self._haveItemMoney:UpdateItemCounts(false)

end

return CommonPurchaseItemPop