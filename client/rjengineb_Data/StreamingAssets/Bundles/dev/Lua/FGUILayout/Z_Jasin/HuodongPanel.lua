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

    --考虑优化使用switchPage方法
    FGUI:Open("Z_Jasin", isPC and "PCChangwan" or "Changwan", {}, FGUI_LAYER.NORMAL,
        { destroyTime = 1, classPath = "FGUILayout/Z_Jasin/Changwan" })

    FGUI:Close("Z_Jasin", isPC and "PCHuodongPanel" or "HuodongPanel")
    --self.p1BtnContro = FGUI:getController(self._ui.btn_page1, "btn_name")
    --self.p1SelectContro = FGUI:getController(self._ui.btn_page1, "isSelected")
    --
    --FGUI:Controller_setSelectedIndex(self.p1BtnContro, 0)
    --FGUI:Controller_setSelectedIndex(self.p1SelectContro, 0)
    --
    --self.p2BtnContro = FGUI:getController(self._ui.btn_page2, "btn_name")
    --self.p2SelectContro = FGUI:getController(self._ui.btn_page2, "isSelected")
    --
    --FGUI:Controller_setSelectedIndex(self.p2BtnContro, 1)
    --FGUI:Controller_setSelectedIndex(self.p2SelectContro, 1)
end

return HuodongPanel
