local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local HurtTips = class("HurtTips", BaseFGUILayout)

function HurtTips:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
end

function HurtTips:Enter()

end

function HurtTips:Exit()

end

function HurtTips:Close()
	self.super.Close(self)

end

return HurtTips