local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local S_SystemTips = class("S_SystemTips", BaseFGUILayout)

function S_SystemTips:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._cells = {}
end

function S_SystemTips:Enter()
    self:RegisterEvent()
end

function S_SystemTips:Exit()
    self:RemoveEvent()
end

function S_SystemTips:Destroy()
    self._ui = nil
    self._cells = nil
end


function S_SystemTips:AddTips(str, color)
    local label = FGUI:CreateObject(self._ui.Node_tip, "S_SystemTips", "LabelSystemTip")
    FGUI:GLabel_setTitle(label, str)
    FGUI:GLabel_setTitleColor(label, color)

    table.insert(self._cells, label)

    if not self._systemTipH then
        self._systemTipH = FGUI:getHeight(label)
    end
    local count = #self._cells
    for key, cell in pairs(self._cells) do
        FGUI:setPositionY(cell, -(count-key) * self._systemTipH)
    end

    FGUI:runAction(label, FGUI:ActionSequence(FGUI:ActionDelayTime(2), FGUI:ActionFadeOut(1), FGUI:ActionCallFunc(function()
        table.remove(self._cells, 1)
        FGUI:RemoveFromParent(label, true)
    end)))
end



function S_SystemTips:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_NOTICE_SYSYTEM_TIPS, "SystemTips", handler(self, self.AddTips))
end

function S_SystemTips:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_NOTICE_SYSYTEM_TIPS, "SystemTips")
end

return S_SystemTips