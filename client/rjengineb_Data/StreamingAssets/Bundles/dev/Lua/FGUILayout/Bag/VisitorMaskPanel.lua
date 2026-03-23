local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorMaskPanel = class("VisitorMaskPanel", BaseFGUILayout)

function VisitorMaskPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:InitOnClickEvent()
end

function VisitorMaskPanel:InitOnClickEvent()
    self.btn_info   = self._ui.btn_info
    self.btn_wugong = self._ui.btn_wugong
    self.btn_box    = self._ui.btn_box
    self.btn_back_box    = self._ui.btn_back_box
    FGUI:setOnClickEvent(self.btn_info,handler(self,self.BtnInfoClicked))
    FGUI:setOnClickEvent(self.btn_wugong,handler(self,self.BtnWugongClicked))
    FGUI:setOnClickEvent(self.btn_box,handler(self,self.BtnBoxClicked))--返回盒子
    FGUI:setOnClickEvent(self.btn_back_box,handler(self,self.BtnTradingClicked))--返回交易行

    if SL:GetValue("BOX_TRADING_VISITOR") then
        FGUI:setVisible(self.btn_box, true)
        FGUI:setVisible(self.btn_back_box, false)
    else
        FGUI:setVisible(self.btn_box, false)
        FGUI:setVisible(self.btn_back_box, true)
    end

    -- pc隐藏返回盒子按钮
    if SL:GetValue("PLATFORM_WINDOWS") then
        FGUI:setVisible(self.btn_box, false)
    end
end

function VisitorMaskPanel:BtnInfoClicked()
    FGUI:Open("Bag","VisitorPlayerInfoPanel",1)
end

function VisitorMaskPanel:BtnWugongClicked()
    FGUI:Open("Skill", "VisitorSkillFramePanel", 1)
end

function VisitorMaskPanel:BtnBoxClicked()
    SL:Logout()
end

function VisitorMaskPanel:BtnTradingClicked()
    SL:ShowBoxTradingView()
    FGUI:Close("Bag","VisitorMaskPanel")
end

function VisitorMaskPanel:Enter()

end

function VisitorMaskPanel:Exit()

end

return VisitorMaskPanel