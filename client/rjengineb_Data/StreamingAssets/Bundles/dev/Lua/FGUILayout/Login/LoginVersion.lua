local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local LoginVersion = class("LoginVersion", BaseFGUILayout)


function LoginVersion:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	
end

function LoginVersion:Enter(data)
	local resVersion = SL:GetValue("RES_VERSION_STRING")
	FGUI:GTextField_setText(self._ui["Text_version"], resVersion)
end

function LoginVersion:Exit()
	
end

function LoginVersion:Close()
	self.super.Close(self)
end


return LoginVersion