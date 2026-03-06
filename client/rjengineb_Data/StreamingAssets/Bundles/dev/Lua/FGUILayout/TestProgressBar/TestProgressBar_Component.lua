local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TestProgressBar_Component = class("TestProgressBar_Component", BaseFGUILayout)

function TestProgressBar_Component:Create()
    self.handle_close = handler(self, self.Close)
    self._test_progressBar = self:GetChild("test_progressBar")

    local titleType = self:GetChild("titleType")
    self._titleValue_Tex = titleType:GetChild("title")
    self._switchTitle_Btn = titleType:GetChild("set")
    self._switchTitle_Btn.title = "Title"
    self._switchTitle = handler(self, self.OnClickSwitchTitle)

    local minValue = self:GetChild("minValue")
    self._min_Tex = minValue:GetChild("title")
    self._min_Tex.promptText = "最小值"
    self._setMin_Btn = minValue:GetChild("set")
    self._setMin_Btn.title = "Min"
    self._setMin = handler(self, self.OnClickSetMin)

    local maxValue = self:GetChild("maxValue")
    self._max_Tex = maxValue:GetChild("title")
    self._max_Tex.promptText = "最大值"
    self._setMax_Btn = maxValue:GetChild("set")
    self._setMax_Btn.title = "Max"
    self._setMax = handler(self, self.OnClickSetMax)

    local currValue = self:GetChild("currValue")
    self._curr_Tex = currValue:GetChild("title")
    self._refCurr_Btn = currValue:GetChild("set")
    self._refCurr_Btn.title = "RefCurr"
    self._refCurr = handler(self, self.OnClickRefreshValue)

    local isReverse = self:GetChild("isReverse")
    self._isReverse_Tex = isReverse:GetChild("title")
    self._setIsReverse_Btn = isReverse:GetChild("set")
    self._setIsReverse_Btn.title = "IsReverse"
    self._setIsReverse = handler(self, self.OnClickSetIsReverse)

    local tweenValue = self:GetChild("tweenValue")
    self._tween_Tex = tweenValue:GetChild("title")
    self._tween_Tex.promptText = "目标值"
    self._playTween_Btn = tweenValue:GetChild("set")
    self._playTween_Btn.title = "PlayTween"
    self._playTween = handler(self, self.OnClickPlayTween)

    local update = self:GetChild("update")
    self._update_Tex = update:GetChild("title")
    self._update_Tex.promptText = "目标值"
    self._setUpdate_Btn = update:GetChild("set")
    self._setUpdate_Btn.title = "Update"
    self._setUpdate = handler(self, self.OnClickSetUpdate)

    self:InitEvent()
    self:RefreshValues()
end

function TestProgressBar_Component:InitEvent()
    local btn_close = self:GetChild("closeButton")
    btn_close.onClick:Add(self.handle_close)

    self._switchTitle_Btn.onClick:Add(self._switchTitle)
    self._setMin_Btn.onClick:Add(self._setMin)
    self._setMax_Btn.onClick:Add(self._setMax)
    self._refCurr_Btn.onClick:Add(self._refCurr)
    self._setIsReverse_Btn.onClick:Add(self._setIsReverse)
    self._playTween_Btn.onClick:Add(self._playTween)
    self._setUpdate_Btn.onClick:Add(self._setUpdate)
end

function TestProgressBar_Component:OnClickSwitchTitle()
    local type = FGUI:GProgressBar_getTitleType(self._test_progressBar)
    type = type + 1
    type = type % 4
    FGUI:GProgressBar_setTitleType(self._test_progressBar, type)
    self:RefreshValues()
end

function TestProgressBar_Component:OnClickSetMin()
    local mini = tonumber(self._min_Tex.text)
    FGUI:GProgressBar_setMin(self._test_progressBar, mini)
    self:RefreshValues()
end

function TestProgressBar_Component:OnClickSetMax()
    local max = tonumber(self._max_Tex.text)
    FGUI:GProgressBar_setMin(self._test_progressBar, max)
    self:RefreshValues()
end

function TestProgressBar_Component:OnClickRefreshValue()
    self._curr_Tex.text = FGUI:GProgressBar_getValue(self._test_progressBar)
    self:RefreshValues()
end

function TestProgressBar_Component:OnClickSetIsReverse()
    local isReverse = FGUI:GProgressBar_getReverse(self._test_progressBar)
    isReverse = not isReverse
    FGUI:GProgressBar_setReverse(self._test_progressBar, isReverse)
    self:RefreshValues()
end

function TestProgressBar_Component:OnClickPlayTween()
    local value = tonumber(self._tween_Tex.text)
    FGUI:GProgressBar_tweenValue(self._test_progressBar, value, 0.2)
    self:RefreshValues()
end

function TestProgressBar_Component:OnClickSetUpdate()
    local value = tonumber(self._update_Tex.text)
    FGUI:GProgressBar_update(self._test_progressBar, value)
    self:RefreshValues()
end

function TestProgressBar_Component:RefreshValues()
    self._titleValue_Tex.text = tostring(FGUI:GProgressBar_getTitleType(self._test_progressBar))
    self._min_Tex.text = FGUI:GProgressBar_getMin(self._test_progressBar)
    self._max_Tex.text = FGUI:GProgressBar_getMax(self._test_progressBar)
    self._curr_Tex.text = FGUI:GProgressBar_getValue(self._test_progressBar)
    self._isReverse_Tex.text = tostring(FGUI:GProgressBar_getReverse(self._test_progressBar))
    self._tween_Tex.text = ""
    self._update_Tex.text = ""
end

return TestProgressBar_Component
