local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local Changwan = class("Changwan", BaseFGUILayout)

function Changwan:Create()
    self._ui = FGUI:ui_delegate(self.component)
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    FGUI:SetCloseUIWhenClickOutside(self)
    --关闭按钮
    FGUI:setOnClickEvent(self._ui.btn_close, function()
        FGUI:Close("Z_Jasin", isPC and "PCChangwan" or "Changwan")
    end)
    --月卡按钮
    FGUI:setOnClickEvent(self._ui.btn_page2, function()
        FGUI:Open("Z_Jasin", isPC and "PCYueka" or "Yueka", {}, FGUI_LAYER.NORMAL,
            { destroyTime = 1, classPath = "FGUILayout/Z_Jasin/Yueka" })

        FGUI:Close("Z_Jasin", isPC and "PCChangwan" or "Changwan")
    end)
end

function Changwan:Destroy()
end

function Changwan:Exit()
end

return Changwan
