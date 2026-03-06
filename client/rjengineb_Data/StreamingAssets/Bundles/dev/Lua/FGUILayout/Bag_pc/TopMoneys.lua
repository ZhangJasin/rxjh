local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TopMoneys = class("TopMoney", BaseFGUILayout)
local ItemMoney = SL:RequireFile("FGUILayout/Item/ItemMoney")
local MoneyId = SL:GetValue("BAG_MONEY_LIST")

function TopMoneys:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self:InitView()
end

function TopMoneys:Enter()
	self:RegisterEvent()
	for i = 1, #MoneyId do
		local id = MoneyId[i]
		self:RefreshCurrency({id = id,count = SL:GetValue("MONEY", id)})
	end
end

function TopMoneys:Exit()
	self:UnRegisterEvent()
end

function TopMoneys:InitView()

	--初始化货币信息
	self._moneyObjDic = {}
	for i = 1, #MoneyId do
		local model = {
			iconObj = self._ui["commonItem"..i],
			textObj = self._ui["MoneyNum"..i]
		}
		local id = MoneyId[i]
		local itemCfg = SL:GetValue("ITEM_DATA", id)
		if itemCfg then
			ItemMoney.new(model.iconObj,itemCfg)
		end
		self._moneyObjDic[id] = model

		self:RefreshCurrency({id = id,count = SL:GetValue("MONEY", id)})
		FGUI:setOnClickEvent(self._ui["MoneyBg"..i], function()
			self:MoneyBgClickEvent(MoneyId[i])
		end)
	end
end

function TopMoneys:MoneyBgClickEvent(moneyID)
	local itemCfg = SL:GetValue("ITEM_DATA", moneyID)
	FGUIFunction:OpenItemTips({itemData = itemCfg,hideButtons = true } )
end

function TopMoneys:RefreshCurrency(moneyID, moneyValue)
	--元宝显示绑定元宝和元宝的总和
	if moneyID == 2 or moneyID  == 5 then
		moneyValue = SL:GetValue("MONEY", 2) + SL:GetValue("MONEY", 5)
		moneyID = 2
	end
	local money =self._moneyObjDic[moneyID]
	if money then
		ItemUtil:UpdateItemCount(money.textObj, moneyValue or 0)
	end
end

function TopMoneys:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_MONEY_CHANGE, "TopMoneys", handler(self, self.RefreshCurrency))

end

function TopMoneys:UnRegisterEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_MONEY_CHANGE, "TopMoneys")
end


return TopMoneys