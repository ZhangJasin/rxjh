local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local S_LoadingLayerPanel = class("S_LoadingLayerPanel", BaseFGUILayout)

function S_LoadingLayerPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    self._percent = 0
    self._percentDesc = ""
    self:UpdateDesc()
    self:UpdatePercent()
end

function S_LoadingLayerPanel:Enter()
	self:RegisterEvent()
    self._percent = 0
    self._percentDesc = ""
end

function S_LoadingLayerPanel:Exit()
	self:RemoveEvent()
end

function S_LoadingLayerPanel:Destroy()
    self._ui = nil	
end

function S_LoadingLayerPanel:Close()
    self.super.Close(self)
end


function S_LoadingLayerPanel:SetPercentAndDesc(percent, desc)
    self:SetPercent(percent)
    self:SetDesc(desc)
end

function S_LoadingLayerPanel:SetPercent(percent)
    if not self._ui then return end
    self._percent = percent
    self:UpdatePercent()
end

function S_LoadingLayerPanel:SetDesc(desc)
    if not self._ui then return end
    self._percentDesc = desc
    self:UpdateDesc()
end

function S_LoadingLayerPanel:UpdateDesc()
    if not self._ui then return end
    FGUI:GTextField_setText(self._ui.title, self._percentDesc)
end

function S_LoadingLayerPanel:UpdatePercent()
    if not self._ui then return end
    FGUI:GProgressBar_update(self._ui.progress, self._percent)
end


function S_LoadingLayerPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_LOADINGLAYER_UPDATE_PROGRESS, "S_LoadingLayerPanel", handler(self, self.SetPercent))
    SL:RegisterLUAEvent(LUA_EVENT_LOADINGLAYER_UPDATE_TIPS, "S_LoadingLayerPanel", handler(self, self.SetDesc))
end

function S_LoadingLayerPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_LOADINGLAYER_UPDATE_PROGRESS, "S_LoadingLayerPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_LOADINGLAYER_UPDATE_TIPS, "S_LoadingLayerPanel")
end


return S_LoadingLayerPanel