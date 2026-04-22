local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local equipCollect = class("equipCollect", BaseFGUILayout)

function equipCollect:Create()
    self._ui = FGUI:ui_delegate(self.component)
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    --equipCollect.self = self  --绑定组件

    FGUI:SetCloseUIWhenClickOutside(self)               --点击空白关闭

    FGUI:setOnClickEvent(self._ui.btn_close, function() --关闭按钮
        FGUI:Close("Z_Jasin", isPC and "equipCollect" or "equipCollect")
    end)

    --适配pc端UI
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    if isPC then
        FGUI:setScale(self.component, 0.75, 0.75)
        FGUI:setPosition(self.component, screenW / 2, screenH / 2)
        FGUI:setAnchorPoint(self.component, 0.5, 0.5, true)
    end
end

return equipCollect
