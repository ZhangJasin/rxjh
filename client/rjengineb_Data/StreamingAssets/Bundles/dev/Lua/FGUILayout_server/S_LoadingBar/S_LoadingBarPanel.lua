local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local S_LoadingBarPanel = class("S_LoadingBarPanel", BaseFGUILayout)

function S_LoadingBarPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
end

function S_LoadingBarPanel:Enter()
	self:RegisterEvent()
end

function S_LoadingBarPanel:Exit()
	self:RemoveEvent()
end

function S_LoadingBarPanel:Destroy()

    self._ui = nil	
end

function S_LoadingBarPanel:ShowTips(str)
    FGUI:GTextField_setText(self._ui.title, str)
end


-----------------------------------注册事件--------------------------------------
function S_LoadingBarPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_LOADINGBAR_UPDATE_TIPS, "S_LoadingBarPanel", handler(self, self.ShowTips))
end

function S_LoadingBarPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_LOADINGBAR_UPDATE_TIPS, "S_LoadingBarPanel")
end


return S_LoadingBarPanel