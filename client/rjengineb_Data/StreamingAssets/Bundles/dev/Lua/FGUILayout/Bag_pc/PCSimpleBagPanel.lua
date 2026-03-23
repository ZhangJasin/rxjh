local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCSimpleBagPanel = class("PCSimpleBagPanel", BaseFGUILayout)


function PCSimpleBagPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self._bagPanel = FGUIFunction:BindClass(self._ui.view_bag, "Bag_pc/PCBagPanel")	
	self._bagPanel:Create()
	self._data = nil
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUIFunction:setWindowDrag(self.component, self._ui.bg)
end

function PCSimpleBagPanel:Enter(data)
	local enterData = {}
	enterData.itemUse = false
	if data.componentName == "StallProduct" then
		enterData.bindParentView = FGUIDefine.BindParentView.PCStallMain
	elseif data.componentName == "TradeMain" then
		enterData.bindParentView = FGUIDefine.BindParentView.PCTradeMain
	end
	
	self._bagPanel:Enter(enterData)
	self._data = data
	FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA", "BagMoneyList"))
end

function PCSimpleBagPanel:Exit()
	self._bagPanel:Exit()
	FGUIFunction:HideTopCurrency()
end

function PCSimpleBagPanel:Close()
	self.super.Close(self)
	if self._data then
		if self._data.packageName and self._data.componentName then
			FGUI:Close(self._data.packageName, self._data.componentName )
		end
	end
end

function PCSimpleBagPanel:Destroy()
	if self._bagPanel then
		self._bagPanel:CleanItem()
	end
end

return PCSimpleBagPanel