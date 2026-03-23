local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CommonECOWnd = class("CommonECOWnd", BaseFGUILayout)


function CommonECOWnd:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self._ui_drag = FGUI:ui_delegate(self._ui.dragComponent)

    FGUI:GSlider_addOnChanged(self._ui_drag.slider, handler(self, self.OnSliderValueChange))
    FGUI:GSlider_addOnGripTouchEnd(self._ui_drag.slider, handler(self, self.OnSliderValueChangeEnd))
    self.ecoType = SL:GetValue("SETTING_FUNC_ARGS", SLDefine.SET_FUNC.ECO_TYPE)
end

function CommonECOWnd:Refresh(data)
    if self.ecoType == 1 then
        if SL:GetMetaValue("WXMINIGAME") then
            self.rt = SL:SetECOTexture(self._ui.Node_ECO)
            FGUI:setVisible(self._ui.bg, true)
            FGUI:setVisible(self._ui.bg_black, false)
        else
            FGUI:setVisible(self._ui.bg, false)
            FGUI:setVisible(self._ui.bg_black, true)
        end
    elseif self.ecoType == 2 then
        FGUI:setVisible(self._ui.bg, true)
        FGUI:setVisible(self._ui.bg_black, false)
        self.originVsync = SL:GetValue("SETTING_VSYNC_ENABLE")
        SL:SetValue("SETTING_VSYNC_ENABLE", 0)
        self.originAniti = SL:GetValue("SETTING_PIPELINE_ANITI")
        SL:SetValue("SETTING_PIPELINE_ANITI", 0)
        self.originAnitiLevel = SL:GetValue("SETTING_MSAA_QUALITY")
        SL:SetValue("SETTING_MSAA_QUALITY", 0)
    end

    self:UpdateTime()
    FGUI:GImage_setFillAmount(self._ui_drag.fill, 0)
    FGUI:GSlider_setValue(self._ui_drag.slider, 0.047)
end

function CommonECOWnd:OnSliderValueChange(context)
    local value = FGUI:GSlider_getValue(context.sender)
    local temp = (4.7 + (95.3 - 4.7) * value / 100) / 100
    FGUI:GImage_setFillAmount(self._ui_drag.fill, temp)
    if value >= 99 then
        SL:QuitECOMode()
        self:Close()
    end
end

function CommonECOWnd:OnSliderValueChangeEnd(context)
    FGUI:GImage_setFillAmount(self._ui_drag.fill, 0)
    FGUI:GSlider_setValue(self._ui_drag.slider, 0.047)
end

function CommonECOWnd:Update()
    self:UpdateTime()
end

function CommonECOWnd:Exit()
    if self.ecoType == 1 then
        if self.rt then
            SL:ReleaseRT(self.rt)
        end
    elseif self.ecoType == 2 then
        SL:SetValue("SETTING_VSYNC_ENABLE", self.originVsync)
        SL:SetValue("SETTING_PIPELINE_ANITI", self.originAniti)
        SL:SetValue("SETTING_MSAA_QUALITY", self.originAnitiLevel)
    end
end

function CommonECOWnd:UpdateTime()
    local date = os.date("*t", SL:GetValue("SERVER_TIME"))
    local timeStr = string.format("%02d:%02d", date.hour, date.min)
    FGUI:GTextField_setText(self._ui.time, timeStr)
end

return CommonECOWnd
