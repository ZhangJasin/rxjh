local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local HuodongPanel = class("HuodongPanel", BaseFGUILayout)

function HuodongPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    --HuodongPanel.self = self  --绑定组件

    FGUI:SetCloseUIWhenClickOutside(self) --点击空白关闭

    FGUI:setOnClickEvent(self._ui.btn_close, function()  --关闭按钮
        FGUI:Close("Z_Jasin", "HuodongPanel")
    end)
end

return HuodongPanel