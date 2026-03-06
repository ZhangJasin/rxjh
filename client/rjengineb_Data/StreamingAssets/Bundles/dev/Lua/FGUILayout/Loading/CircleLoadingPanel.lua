local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CircleLoadingPanel = class("CircleLoadingPanel", BaseFGUILayout)

function CircleLoadingPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:GetAllFGuiData()
end

function CircleLoadingPanel:GetAllFGuiData()
    self.t_reconnecting = FGUI:GetTransition(self.component, "reconnecting")
end

function CircleLoadingPanel:Enter()
    if not FGUI:Transition_getIsPlaying(self.t_reconnecting) then
        FGUI:Transition_setAutoPlay(self.t_reconnecting,true,-1)
    end
    
end

function CircleLoadingPanel:Refresh(data)
    if data and data.tipStr and data.tipStr ~= "" then 
        FGUI:GTextField_setText(self._ui.tipsLabel, data.tipStr)
        FGUI:setVisible(self._ui.tipsLabel, true)
    else
        FGUI:setVisible(self._ui.tipsLabel, false)
    end
end

function CircleLoadingPanel:Exit()
    if self.t_reconnecting then
        FGUI:Transition_dispose(self.t_reconnecting)
    end
end

function CircleLoadingPanel:Destroy()
end

function CircleLoadingPanel:OnClose()
    self.super.Close(self)
end

return CircleLoadingPanel