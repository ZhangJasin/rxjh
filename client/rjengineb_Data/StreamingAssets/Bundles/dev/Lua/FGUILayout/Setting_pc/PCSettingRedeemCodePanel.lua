local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCSettingRedeemCodePanel = class("PCSettingRedeemCodePanel", BaseFGUILayout)

function PCSettingRedeemCodePanel:Create()
	self._ui				= FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)
	self:InitData()
	self:InitEvent()
end 

function PCSettingRedeemCodePanel:InitData()
	-- 关闭按钮
	self.handler_clickCloseBtn = handler(self, self.OnClose)
end

function PCSettingRedeemCodePanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, self.handler_clickCloseBtn)
	FGUI:setOnClickEvent(self._ui.mask, self.handler_clickCloseBtn)
	FGUI:setOnClickEvent(self._ui.btn_yes, handler(self, self.OnClicYesBtn))
end

-- 
function PCSettingRedeemCodePanel:Enter(userdata)
	self:RegisterEvent()
end

function PCSettingRedeemCodePanel:Exit()
	self:RemoveEvent()
end

function PCSettingRedeemCodePanel:OnClose()
	self.super.Close(self)
end

function PCSettingRedeemCodePanel:Destroy()
end

function PCSettingRedeemCodePanel:RegisterEvent()
end

function PCSettingRedeemCodePanel:RemoveEvent()
end

function PCSettingRedeemCodePanel:OnClicYesBtn()
	local cdk = FGUI:GTextInput_getText(FGUI:GetChild(self._ui.input_cdk, "input_value"))
	if cdk == nil or string.len(cdk) == 0 then
		return
	end
	SL:RequestCDK(cdk)
	self:OnClose()
end

return PCSettingRedeemCodePanel