local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local comCalc = class("comCalc", BaseFGUILayout)

--- 界面被创建时调用

function comCalc:Create(super)
    self._ui = FGUI:ui_delegate(self.component)
    self.super = super
    self:InitClickEvent()
end

function comCalc:InitClickEvent()
    for i = 0, 9 do
        FGUI:setOnClickEvent(
            self._ui["btn_" .. i], function()
                self._curNum = self._curNum * 10 + i
                self:ShowNumber()
            end
        )
    end

    FGUI:setOnClickEvent(
        self._ui["btn_add"], function()
            self._curNum = self._curNum + 1
            self:ShowNumber()
        end
    )

    FGUI:setOnClickEvent(
        self._ui["btn_minus"], function()
            self._curNum = self._curNum - 1
            self:ShowNumber()
        end
    )

    FGUI:setOnClickEvent(
        self._ui["btn_10"], function()
            self._curNum = self._curNum + 10
            self:ShowNumber()
        end
    )

    FGUI:setOnClickEvent(
        self._ui["btn_100"], function()
            self._curNum = self._curNum + 100
            self:ShowNumber()
        end
    )

    FGUI:setOnClickEvent(
        self._ui["btn_clear"], function()
            self._curNum = 0
            self:ShowNumber()
        end
    )

    FGUI:setOnClickEvent(
        self._ui["btn_min"], function()
            self._curNum = self.min or 0
            self:ShowNumber()
        end
    )

    FGUI:setOnClickEvent(
        self._ui["btn_max"], function()
            self._curNum = self.max or 0
            self:ShowNumber()
        end
    )

    FGUI:setOnClickEvent(
        self._ui["btn_return"], function()
            self._curNum = math.floor(self._curNum / 10)
            self:ShowNumber()
        end
    )
end

function comCalc:Reset(data)
    if data and data.min then
        self.min = data.min
    else
        self.min = nil
    end

    if data and data.max then
        self.max = data.max
    else
        self.max = nil
    end
    
    self._curNum = (data and data.curValue) and data.curValue or 1
    FGUI:GTextField_setText(self._ui.text_cal, self._curNum)
end

function comCalc:ShowNumber(noNeedRefresh)
    if not self.min then
        self.min = 0
    end
    if self._curNum < self.min then
        self._curNum = self.min
    end
    if self.max then
        if self._curNum > self.max then
            self._curNum = self.max
        end
    end

    FGUI:GTextField_setText(self._ui.text_cal, self._curNum)
    if self.super and self.super.RefreshCalcResult then
        self.super:RefreshCalcResult()
    end
end

--- 界面打开时调用
function comCalc:Enter()
end

--- 界面打开和刷新时调用
function comCalc:Refresh(data)
end

--- 界面关闭时调用
function comCalc:Exit()
end

--- 界面销毁时调用
function comCalc:Destroy()
end

--- 界面每帧执行(通常不启用)
-- function comCalc:Update(dt)
-- end

return comCalc
