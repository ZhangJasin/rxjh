local MentorShipPageBase = requireFGUILayout("MentorShip/MentorShipPageBase")
local MentorShipShop = class("MentorShipShop", MentorShipPageBase)

local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local StoreData = require("game_config/Store")

function MentorShipShop:Create()
	return MentorShipShop.new()
end

function MentorShipShop:Enter()
	self._ui = FGUI:ui_delegate(self.component)
	self.selectData = {}
	self:initData()
end

function MentorShipShop:initData()
	self.shopItemListData = {}
	for i = 1,#StoreData do
		local item = StoreData[i]
		if tonumber(item.BtLeafType) == 69 then
			table.insert(self.shopItemListData,item)
		end
	end
	self.myMoney = SL:GetValue("MONEY",21)
	FGUI:GTextField_setText(self._ui.money_text,self.myMoney)
	local itemDataMoney = SL:GetValue("ITEM_DATA", 21) 
	local extDataMoney = {}
	extDataMoney.hideTip = false --是否隐藏默认的Tip
	extDataMoney.itemTipData = itemDataMoney --table类型，对应ItemTips.ShowTip传入的参数
	extDataMoney.clickCallback = false --单击事件回调
	extDataMoney.doubleClickCallback = false --双击事件回调
	extDataMoney.bgVisible = false --背景隐藏
	ItemUtil:ItemShow_Create(itemDataMoney,self._ui.moneyIcon,extDataMoney)
	self:setList()
	MentorShipShopUI.CCUI = self
end

function MentorShipShop:Close()
	self.super.Close(self)
end

function MentorShipShop:setList()
	FGUI:GList_itemRenderer(self._ui.showItemList, function(idx,item)
		local data = self.shopItemListData[idx+1]
		local icon = FGUI:GetChild(item,"icon")
		local title = FGUI:GetChild(item,"title")
		local text_money = FGUI:GetChild(item,"text_money")
		local itemData = SL:GetValue("ITEM_DATA", tonumber(data.Itemid)) 
		local icon_money = FGUI:GetChild(item,"icon_money")
		local text_xiangou = FGUI:GetChild(item,"text_xiangou")
		local text_xiangouBG = FGUI:GetChild(item,"n13")
		local limitBuy = data.Limitbuy 
		local OnceCount = SL:Split(data.OnceCount, "#")
		if limitBuy then
			local arr = SL:Split(limitBuy, "#")
			local textStr = ''
			if tonumber(arr[1]) == 1 then
				textStr = '每日限购'..arr[2].."次"
			end
			if tonumber(arr[1]) == 2 then
				textStr = '每周限购'..arr[2].."次"
			end
			if tonumber(arr[1]) == 3 then
				textStr = '终身限购'..arr[2].."次"
			end
			if tonumber(arr[1]) == 4 then
				textStr = '每月限购'..arr[2].."次"
			end
			FGUI:GTextField_setText(text_xiangou,textStr)
		else
			FGUI:setVisible(text_xiangou,false)
			FGUI:setVisible(text_xiangouBG,false)
		end
		local extData = {}
		extData.hideTip = false --是否隐藏默认的Tip
		extData.itemTipData = itemData --table类型，对应ItemTips.ShowTip传入的参数
		extData.clickCallback = false --单击事件回调
		extData.doubleClickCallback = false --双击事件回调
		extData.bgVisible = true --背景隐藏
		ItemUtil:ItemShow_Create(itemData,icon,extData)

		local itemDataMoney = SL:GetValue("ITEM_DATA", 21) 
		local extDataMoney = {}
		extDataMoney.hideTip = false --是否隐藏默认的Tip
		extDataMoney.itemTipData = itemDataMoney --table类型，对应ItemTips.ShowTip传入的参数
		extDataMoney.clickCallback = false --单击事件回调
		extDataMoney.doubleClickCallback = false --双击事件回调
		extDataMoney.bgVisible = false --背景隐藏
		ItemUtil:ItemShow_Create(itemDataMoney,icon_money,extDataMoney)

		FGUI:GTextField_setText(title,data.Desc)
		FGUI:GTextField_setText(text_money,data.Nowprice)
		if tonumber(self.myMoney) >= tonumber(data.Nowprice) then
			FGUI:GTextField_setColor(text_money,"#ffffff")
		else
			FGUI:GTextField_setColor(text_money,"#ff0000")
		end
		local clickBtn = FGUI:GetChild(item,'click_node')
		FGUI:setOnClickEvent(clickBtn,function()
			self.selectData = data
			if tonumber(self.myMoney) >= tonumber(self.selectData.Nowprice) then
			else
				SL:ShowSystemTips("您的师徒币不足")
				return 
			end
			FGUI:setVisible(self._ui.dialogToBuy,true)
			local buyCount = 1
			local max = 999
			local btn_red = FGUI:GetChild(self._ui.dialogToBuy,"btn_red") 
			local btn_green = FGUI:GetChild(self._ui.dialogToBuy,"btn_green") 
			local btn_minus = FGUI:GetChild(self._ui.dialogToBuy,"btn_minus") 
			local btn_add = FGUI:GetChild(self._ui.dialogToBuy,"btn_add") 
			local btn_max = FGUI:GetChild(self._ui.dialogToBuy,"btn_max") 
			local text_name = FGUI:GetChild(self._ui.dialogToBuy,"text_name") 
			local iconNode = FGUI:GetChild(self._ui.dialogToBuy,"iconNode") 
			local numInput = FGUI:GetChild(self._ui.dialogToBuy,"input_count") 
			local text_title = FGUI:GetChild(self._ui.dialogToBuy,"text_title") 
			FGUI:GTextField_setText(text_name,self.selectData.Desc)
			FGUI:GTextField_setText(text_title,"购买")
			self:setInput(numInput,buyCount)
			local iconData = SL:GetValue("ITEM_DATA", tonumber(self.selectData.Itemid)) 
			local iconExtData = {}
			iconExtData.hideTip = false --是否隐藏默认的Tip
			iconExtData.itemTipData = iconData --table类型，对应ItemTips.ShowTip传入的参数
			iconExtData.clickCallback = false --单击事件回调
			iconExtData.doubleClickCallback = false --双击事件回调
			iconExtData.bgVisible = true --背景隐藏
			ItemUtil:ItemShow_Create(iconData,iconNode,iconExtData)
			FGUI:GTextInput_setOnChanged(numInput, function(context)
				local count = tonumber(FGUI:GTextInput_getText(numInput))
				if count < tonumber(OnceCount[1]) then
					count = tonumber(OnceCount[1]) 
				end
				if count > tonumber(OnceCount[2])  then
					count = tonumber(OnceCount[2])
				end
				self:setInput(numInput,count)
			end)
			FGUI:setOnClickEvent(btn_minus, function ()
				buyCount = buyCount - 1 
				if buyCount < tonumber(OnceCount[1]) then
					buyCount = tonumber(OnceCount[1]) 
				end
				self:setInput(numInput,buyCount)
			end)
			FGUI:setOnClickEvent(btn_add, function ()
				buyCount = buyCount + 1 
				if buyCount > tonumber(OnceCount[2])  then
					buyCount = tonumber(OnceCount[2])
				end
				self:setInput(numInput,buyCount)
			end)
			FGUI:setOnClickEvent(btn_max, function ()
				buyCount = tonumber(OnceCount[2])
				self:setInput(numInput,buyCount)
			end)
			FGUI:setOnClickEvent(btn_red, function ()
				FGUI:setVisible(self._ui.dialogToBuy,false)
			end)
			FGUI:setOnClickEvent(btn_green, function ()
				local count = FGUI:GTextInput_getText(numInput)
				ssrMessage:sendmsgEx("MentorShip", "buy",{count = count,ID=self.selectData.ID})
				FGUI:setVisible(self._ui.dialogToBuy,false)
			end)
    	end)
	end)
	FGUI:GList_setNumItems(self._ui.showItemList, #self.shopItemListData)
end

function MentorShipShop:updateView()
	self = MentorShipShopUI.CCUI
	self.myMoney = SL:GetValue("MONEY",21)
	FGUI:GTextField_setText(self._ui.money_text,self.myMoney)
	local itemDataMoney = SL:GetValue("ITEM_DATA", 21) 
	local extDataMoney = {}
	extDataMoney.hideTip = false --是否隐藏默认的Tip
	extDataMoney.itemTipData = itemDataMoney --table类型，对应ItemTips.ShowTip传入的参数
	extDataMoney.clickCallback = false --单击事件回调
	extDataMoney.doubleClickCallback = false --双击事件回调
	extDataMoney.bgVisible = false --背景隐藏
	ItemUtil:ItemShow_Create(itemDataMoney,self._ui.moneyIcon,extDataMoney)
	FGUI:GList_setNumItems(self._ui.showItemList, #self.shopItemListData)
end

function MentorShipShop:setInput(input,num)
	FGUI:GTextInput_setText(input,""..num)
end

function MentorShipShop:onClickItem()
	
end


return MentorShipShop