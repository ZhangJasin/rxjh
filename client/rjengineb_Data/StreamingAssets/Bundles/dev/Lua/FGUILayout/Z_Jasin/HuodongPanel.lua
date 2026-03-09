local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local HuodongPanel = class("HuodongPanel", BaseFGUILayout)

function HuodongPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    --HuodongPanel.self = self  --绑定组件

    FGUI:SetCloseUIWhenClickOutside(self)               --点击空白关闭

    FGUI:setOnClickEvent(self._ui.btn_close, function() --关闭按钮
        FGUI:Close("Z_Jasin", isPC and "PCHuodongPanel" or "HuodongPanel")
    end)
end

return HuodongPanel
