local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local SharedStoragePanel = class("SharedStoragePanel", BaseFGUILayout)

function SharedStoragePanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)
	self.firstEnter = true
	self._disableCellDoubleClick = true
end

function SharedStoragePanel:InitView()
    if not self.bagPanel then
		self.bagPanel = FGUI:CreateObject(self._ui.BagNode, "Bag", "BagPanel", true)
	end
end


function SharedStoragePanel:Enter(data)
    if data then
		self.fromPanel = data.fromPanel
	end
	FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA", "BagMoneyList"))
	self:RegisterEvent()
	self:RefreshData()
	self.firstEnter = false
	self.bagPanel:Enter({ disableCellDoubleClick = self._disableCellDoubleClick} )
	SL:ComponentAttach(SLDefine.SUIComponentTable.Storage, self._ui.Node_attach)

end

function SharedStoragePanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.Storage)

	FGUIFunction:HideTopCurrency()
	self:UnRegisterEvent()
	self.bagPanel:Exit()
end

function SharedStoragePanel:Close()
    self.super.Close(self)
	if self.fromPanel and  self.fromPanel == 1 then
		FGUI:Open("Bag","PlayerInfoPanel",1)
	end
end

function SharedStoragePanel:RegisterEvent()
end

function SharedStoragePanel:UnRegisterEvent()
end

return SharedStoragePanel