local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TestRichTextField_Component = class("TestRichTextField_Component", BaseFGUILayout)

function TestRichTextField_Component:Create()
    self.handle_close = handler(self, self.Close)
    self.test_richText = self:GetChild("test_richText")
    self.test_inputText = self:GetChild("test_inputText")
    self.onInputChange = handler(self, self.OnInputTextChange)

    local colorLabel = self:GetChild("color")
    self._colorValue_Tex = colorLabel:GetChild("title")
    self._colorValue_Tex.promptText = "颜色"
    self._switchColor_Btn = colorLabel:GetChild("set")
    self._switchColor_Btn.title = "Color"
    self._switchColor = handler(self, self.OnClickSwitchColor)

    local alignLabel = self:GetChild("align")
    self._alignValue_Tex = alignLabel:GetChild("title")
    self._switchAlign_Btn = alignLabel:GetChild("set")
    self._switchAlign_Btn.title = "Align"
    self._switchAlign = handler(self, self.OnClickSwitchAlign)

    local verticalAlignLabel = self:GetChild("verticalAlign")
    self._verticalAlignValue_Tex = verticalAlignLabel:GetChild("title")
    self._switchVerticalAlign_Btn = verticalAlignLabel:GetChild("set")
    self._switchVerticalAlign_Btn.title = "VerticalAlign"
    self._switchVerticalAlign = handler(self, self.OnClickSwitchVerticalAlign)

    local singleLineLabel = self:GetChild("singleLine")
    self._singleLineValue_Tex = singleLineLabel:GetChild("title")
    self._switchSingleLine_Btn = singleLineLabel:GetChild("set")
    self._switchSingleLine_Btn.title = "SingleLine"
    self._switchSingleLine = handler(self, self.OnClickSwitchSingleLine)

    local strokeLabel = self:GetChild("stroke")
    self._strokeValue_Tex = strokeLabel:GetChild("title")
    self._strokeValue_Tex.promptText = "描边"
    self._switchStroke_Btn = strokeLabel:GetChild("set")
    self._switchStroke_Btn.title = "Stroke"
    self._switchStroke = handler(self, self.OnClickSwitchStroke)

    local strokeColorLabel = self:GetChild("strokeColor")
    self._strokeColorValue_Tex = strokeColorLabel:GetChild("title")
    self._strokeColorValue_Tex.promptText = "描边颜色"
    self._switchStrokeColor_Btn = strokeColorLabel:GetChild("set")
    self._switchStrokeColor_Btn.title = "StrokeColor"
    self._switchStrokeColor = handler(self, self.OnClickSwitchStrokeColor)

    local showOffsetLabel = self:GetChild("showOffset")
    self._showOffsetValue_Tex = showOffsetLabel:GetChild("title")
    self._switchShowOffset_Btn = showOffsetLabel:GetChild("set")
    self._switchShowOffset_Btn.title = "ShowOffset"
    self._switchShowOffset = handler(self, self.OnClickSwitchShowOffset)

    local ubbEnabledLabel = self:GetChild("ubbEnabled")
    self._ubbEnabledValue_Tex = ubbEnabledLabel:GetChild("title")
    self._switchUbbEnabled_Btn = ubbEnabledLabel:GetChild("set")
    self._switchUbbEnabled_Btn.title = "UBB Enabled"
    self._switchUbbEnabled = handler(self, self.OnClickSwitchUBBEnabled)

    local autoSizeLabel = self:GetChild("autoSize")
    self._autoSizeValue_Tex = autoSizeLabel:GetChild("title")
    self._switchAutoSize_Btn = autoSizeLabel:GetChild("set")
    self._switchAutoSize_Btn.title = "AutoSize"
    self._switchAutoSize = handler(self, self.OnClickSwitchAutoSize)

    local sizeLabel = self:GetChild("size")
    self._sizeValue_Tex = sizeLabel:GetChild("title")
    self._switchSize_Btn = sizeLabel:GetChild("set")
    self._switchSize_Btn.title = "Size"
    self._switchSize = handler(self, self.OnClickSwitchSize)

    self:InitEvent()
    self:RefreshValues()
end

function TestRichTextField_Component:InitEvent()
    local btn_close = self:GetChild("closeButton")
    btn_close.onClick:Add(self.handle_close)
    self.test_inputText.onChanged:Add(self.onInputChange)

    self._switchColor_Btn.onClick:Add(self._switchColor)
    self._switchAlign_Btn.onClick:Add(self._switchAlign)
    self._switchVerticalAlign_Btn.onClick:Add(self._switchVerticalAlign)
    self._switchSingleLine_Btn.onClick:Add(self._switchSingleLine)
    self._switchStroke_Btn.onClick:Add(self._switchStroke)
    self._switchStrokeColor_Btn.onClick:Add(self._switchStrokeColor)
    self._switchShowOffset_Btn.onClick:Add(self._switchShowOffset)
    self._switchUbbEnabled_Btn.onClick:Add(self._switchUbbEnabled)
    self._switchAutoSize_Btn.onClick:Add(self._switchAutoSize)
    self._switchSize_Btn.onClick:Add(self._switchSize)
end

function TestRichTextField_Component:OnInputTextChange()
    FGUI:GRichTextField_setText(self.test_richText, self.test_inputText.text)
end

function TestRichTextField_Component:OnClickSwitchColor()
    FGUI:GRichTextField_setColor(self.test_richText, self._colorValue_Tex.text)
    self:RefreshValues()
end

function TestRichTextField_Component:OnClickSwitchAlign()
    local align = FGUI:GRichTextField_getAlign(self.test_richText)
    align = align + 1
    align = align % 3
    FGUI:GRichTextField_setAlign(self.test_richText, align)
    self:RefreshValues()
end

function TestRichTextField_Component:OnClickSwitchVerticalAlign()
    local align = FGUI:GRichTextField_getVerticalAlign(self.test_richText)
    align = align + 1
    align = align % 3
    FGUI:GRichTextField_setVerticalAlign(self.test_richText, align)
    self:RefreshValues()
end

function TestRichTextField_Component:OnClickSwitchSingleLine()
    local enable = FGUI:GRichTextField_getSingleLine(self.test_richText)
    enable = not enable
    FGUI:GRichTextField_setSingleLine(self.test_richText, enable)
    self:RefreshValues()
end

function TestRichTextField_Component:OnClickSwitchStroke()
    local stroke = tonumber(self._strokeValue_Tex.text)
    FGUI:GRichTextField_setStroke(self.test_richText, stroke)
    self:RefreshValues()
end

function TestRichTextField_Component:OnClickSwitchStrokeColor()
    FGUI:GRichTextField_setStrokeColor(self.test_richText, self._strokeColorValue_Tex.text)
    self:RefreshValues()
end

local shadow = {0,1,2,3,4,5,6,7,8,9}
local shadow_idx = 1
function TestRichTextField_Component:OnClickSwitchShowOffset()
    shadow_idx = shadow_idx + 1
    shadow_idx = shadow_idx % #shadow
    local w = shadow[shadow_idx]
    FGUI:GRichTextField_setShadowOffset(self.test_richText, w, w)
    self:RefreshValues()
end

function TestRichTextField_Component:OnClickSwitchUBBEnabled()
    local enable = FGUI:GRichTextField_getUBBEnabled(self.test_richText)
    enable = not enable
    FGUI:GRichTextField_setUBBEnabled(self.test_richText, enable)
    self:RefreshValues()
end

function TestRichTextField_Component:OnClickSwitchAutoSize()
    local type = FGUI:GRichTextField_getAutoSize(self.test_richText)
    type = type + 1
    type = type % 3
    FGUI:GRichTextField_setAutoSize(self.test_richText, type)
    self:RefreshValues()
end

function TestRichTextField_Component:OnClickSwitchSize()
    local size = string.split(self._sizeValue_Tex.text, ",")
    if #size ~= 2 then
        return
    end
    local w = tonumber(size[1])
    local h = tonumber(size[2])
    self.test_richText:SetSize(w, h)
    self:RefreshValues()
end

function TestRichTextField_Component:RefreshValues()
    self.test_inputText.text = self.test_richText.text
    self._colorValue_Tex.text = ""
    self._alignValue_Tex.text = 
        tostring(FGUI:GRichTextField_getAlign(self.test_richText))
    self._verticalAlignValue_Tex.text = 
        tostring(FGUI:GRichTextField_getVerticalAlign(self.test_richText))
    self._singleLineValue_Tex.text = 
        tostring(FGUI:GRichTextField_getSingleLine(self.test_richText))
    self._strokeValue_Tex.text = 
        tostring(FGUI:GRichTextField_getStroke(self.test_richText))
    self._strokeColorValue_Tex.text = ""
    local w, h = FGUI:GRichTextField_getShadowOffset(self.test_richText)
    self._showOffsetValue_Tex.text = tostring(w)..","..tostring(h)
    self._ubbEnabledValue_Tex.text = 
        tostring(FGUI:GRichTextField_getUBBEnabled(self.test_richText))
    self._autoSizeValue_Tex.text = 
        tostring(FGUI:GRichTextField_getAutoSize(self.test_richText))
    w = FGUI:GRichTextField_getTextWidth(self.test_richText)
    h = FGUI:GRichTextField_getTextHeight(self.test_richText)
    self._sizeValue_Tex.text = tostring(w)..","..tostring(h)

end

return TestRichTextField_Component
