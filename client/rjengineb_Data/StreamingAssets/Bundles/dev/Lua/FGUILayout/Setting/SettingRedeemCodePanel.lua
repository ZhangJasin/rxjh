local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local SettingRedeemCodePanel = class("SettingRedeemCodePanel", BaseFGUILayout)

function SettingRedeemCodePanel:Create()
	self._ui				= FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)
	self:InitData()
	self:InitEvent()
end 

function SettingRedeemCodePanel:InitData()
	-- 关闭按钮
	self.handler_clickCloseBtn = handler(self, self.OnClose)
end

function SettingRedeemCodePanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, self.handler_clickCloseBtn)
	FGUI:setOnClickEvent(self._ui.mask, self.handler_clickCloseBtn)
	FGUI:setOnClickEvent(self._ui.btn_yes, handler(self, self.OnClicYesBtn))
end

-- 
function SettingRedeemCodePanel:Enter(userdata)
	self:RegisterEvent()
end

function SettingRedeemCodePanel:Exit()
	self:RemoveEvent()
end

function SettingRedeemCodePanel:OnClose()
	self.super.Close(self)
end

function SettingRedeemCodePanel:Destroy()
end

function SettingRedeemCodePanel:RegisterEvent()
end

function SettingRedeemCodePanel:RemoveEvent()
end

function SettingRedeemCodePanel:OnClicYesBtn()
	local cdk = FGUI:GTextInput_getText(FGUI:GetChild(self._ui.input_cdk, "input_value"))
	if cdk == nil or string.len(cdk) == 0 then
		return
	end
	SL:RequestCDK(cdk)
	self:OnClose()
end

return SettingRedeemCodePanel