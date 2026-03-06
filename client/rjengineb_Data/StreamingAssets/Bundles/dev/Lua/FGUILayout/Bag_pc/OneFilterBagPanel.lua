local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local OneFilterBagPanel = class("OneFilterBagPanel", BaseFGUILayout)

function OneFilterBagPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self._bagPanel = FGUIFunction:BindClass(self._ui.view_bag, "Bag_pc/FilterBagPanel")
	self._bagPanel:Create()
	self._data = nil
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:SetCloseUIWhenClickOutside(self)
end

function OneFilterBagPanel:Enter(data)
	self._bagPanel:Enter(data)
	self._data = data
	FGUI:GTextField_setText(self._ui.title,data.title or GET_STRING(60003002))
	FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA", "BagMoneyList"))
end

function OneFilterBagPanel:Exit()
	self._bagPanel:Exit()
	FGUIFunction:HideTopCurrency()
end

function OneFilterBagPanel:Close()
	self.super.Close(self)
	if self._data then
		if self._data.packageName and self._data.componentName then
			FGUI:Close(self._data.packageName, self._data.componentName )
		end
	end
end

function OneFilterBagPanel:Destroy()
	if self._bagPanel then
		self._bagPanel:CleanItem()
	end
end

return OneFilterBagPanel