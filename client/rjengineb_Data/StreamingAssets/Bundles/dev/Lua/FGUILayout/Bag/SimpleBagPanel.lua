local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local SimpleBagPanel = class("SimpleBagPanel", BaseFGUILayout)


function SimpleBagPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self._bagPanel = FGUIFunction:BindClass(self._ui.view_bag, "Bag/BagPanel")
	self._bagPanel:Create()
	self._data = nil
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
end

function SimpleBagPanel:Enter(data)
	self._bagPanel:Enter()
	self._data = data
	FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA", "BagMoneyList"))
end

function SimpleBagPanel:Exit()
	self._bagPanel:Exit()
	FGUIFunction:HideTopCurrency()
end

function SimpleBagPanel:Close()
	self.super.Close(self)
	if self._data then
		if self._data.packageName and self._data.componentName then
			FGUI:Close(self._data.packageName, self._data.componentName )
		end
	end
end

function SimpleBagPanel:Destroy()
	if self._bagPanel then
		self._bagPanel:CleanItem()
	end
end

return SimpleBagPanel