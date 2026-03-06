local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCBagPanel = class("PCBagPanel", BaseFGUILayout)


function PCBagPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:setDragable(self._ui.dragGrapic,true)
    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitData()
    self:InitUI()
end

function PCBagPanel:InitData()
end

function PCBagPanel:InitUI()
end

function PCBagPanel:GetAllFGuiData()
    self.btn_close = self._ui.btn_close
end

function PCBagPanel:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
end

function PCBagPanel:OnClose()
    self.super.Close(self)
end
function PCBagPanel:Enter()
end

function PCBagPanel:Exit()
end

function PCBagPanel:Destroy()
end

function PCBagPanel:RegisterEvent()
end
--移除事件
function PCBagPanel:RemoveEvent()
end

return PCBagPanel



