local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local EquipComparePreviewTips = class("EquipComparePreviewTips", BaseFGUILayout)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

function EquipComparePreviewTips:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)

	self._viewList = {self._ui.Pop1, self._ui.Pop2, self._ui.Pop3}

	FGUI:setOnClickEvent(self._ui.Mask, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
end

function EquipComparePreviewTips:InitPreviewPanel(data)	
	self._euqipDataList = data or {}

	for i, viewPop in ipairs(self._viewList) do
		local equipData = self._euqipDataList[i]
		local viewPanel = FGUIFunction:BindClass(viewPop, "Common/TipPreviewModel")
		viewPanel:Create()
		viewPanel:Enter(equipData)

		local isShow = self._euqipDataList[i] and true or false
		if isShow then
			viewPanel:UpdatePreviewModel()
		end
		FGUI:setVisible(viewPop, isShow)
	end
end

function EquipComparePreviewTips:Enter(data)
	self:InitPreviewPanel(data)
end

function EquipComparePreviewTips:Exit()
end

function EquipComparePreviewTips:Close()
	self.super.Close(self)
end

return EquipComparePreviewTips