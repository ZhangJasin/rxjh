local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local Yueka = class("Yueka", BaseFGUILayout)

function Yueka:Create()
    self._ui = FGUI:ui_delegate(self.component)
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    FGUI:SetCloseUIWhenClickOutside(self)
    --关闭按钮
    FGUI:setOnClickEvent(self._ui.btn_close, function()
        FGUI:Close("Z_Jasin", isPC and "PCYueka" or "Yueka")
    end)
    --畅玩按钮
    FGUI:setOnClickEvent(self._ui.btn_page1, function()
        FGUI:Open("Z_Jasin", isPC and "PCChangwan" or "Changwan", {}, FGUI_LAYER.NORMAL,
            { destroyTime = 1, classPath = "FGUILayout/Z_Jasin/Changwan" })
            
        FGUI:Close("Z_Jasin", isPC and "PCYueka" or "Yueka")
    end)
end

function Yueka:Destroy()
end

function Yueka:Exit()
end

return Yueka
