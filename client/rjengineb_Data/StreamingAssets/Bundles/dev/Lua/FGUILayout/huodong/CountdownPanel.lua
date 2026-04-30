local BaseFGUILayout = requireFGUI("BaseFGUILayout")

---@class CountdownPanel
local CountdownPanel = class("CountdownPanel", BaseFGUILayout)

-- 定时器间隔
local UPDATE_INTERVAL = 1  -- 秒

-- 是否是PC端
local IS_PC = SL:GetValue("IS_PC_OPER_MODE")

function CountdownPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)

    -- 适配PC端
    if IS_PC then
        FGUI:setScale(self.component, 0.75, 0.75)
    end

    -- 初始化数据
    self._endTime = nil      -- 结束时间戳（毫秒）
    self._startTime = nil    -- 开始时间戳（毫秒）
    self._totalDuration = 0  -- 总持续时间（毫秒）
    self._timerId = nil      -- 定时器ID
    self._isPaused = false   -- 是否暂停
    self._onButtonClick = nil -- 按钮点击回调
    self._onCountdownEnd = nil -- 倒计时结束回调
    self._onClose = nil      -- 关闭回调

    -- 设置按钮点击事件
    FGUI:setOnClickEvent(self._ui.btn, handler(self, self.OnButtonClick))
end

function CountdownPanel:Enter(data)
    -- 设置位置在左侧中间
    self:UpdatePosition()

    -- 注册场景切换事件
    self:RegisterEvent()
end

function CountdownPanel:Exit()
    self:Stop()
    self:RemoveEvent()
end

function CountdownPanel:Destroy()
    self:Stop()
    self._ui = nil
    self._onButtonClick = nil
    self._onCountdownEnd = nil
    self._onClose = nil
    self._isDestroy = true
end

-- 设置位置在左侧中间
function CountdownPanel:UpdatePosition()
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local panelH = 124  -- CountdownPanel.xml 的高度
    local marginTop = 300  -- 距离顶部的边距

    FGUI:setPosition(self.component, 0, marginTop + panelH / 2)
    FGUI:setAnchorPoint(self.component, 0, 0.5, true)
end

-- 设置按钮点击回调
---@param callback function 回调函数
function CountdownPanel:SetButtonClickCallback(callback)
    self._onButtonClick = callback
end

-- 设置倒计时结束回调
---@param callback function 回调函数
function CountdownPanel:SetCountdownEndCallback(callback)
    self._onCountdownEnd = callback
end

-- 设置关闭回调
---@param callback function 回调函数
function CountdownPanel:SetCloseCallback(callback)
    self._onClose = callback
end

-- 设置倒计时数据
---@param duration number 持续时间（秒）
---@param btnText string 按钮文本
function CountdownPanel:SetCountdown(duration, btnText)
    -- 设置按钮文本
    local btn_title = FGUI:GetChild(self._ui.btn, "title")
    if btn_title and btnText then
        FGUI:GTextField_setText(btn_title, btnText)
    end

    -- 使用相对时间
    self._startTime = os.time() * 1000
    self._endTime = self._startTime + duration * 1000
    self._totalDuration = duration * 1000
    self._isPaused = false
    self:StartTimer()
    self:UpdateDisplay()
end

-- 暂停倒计时
function CountdownPanel:Pause()
    if self._isPaused then return end
    self._isPaused = true
    self:StopTimer()
end

-- 恢复倒计时
function CountdownPanel:Resume()
    if not self._isPaused then return end
    self._isPaused = false
    self:StartTimer()
end

-- 停止倒计时
function CountdownPanel:Stop()
    self:StopTimer()
    self._endTime = nil
    self._startTime = nil
    self._totalDuration = 0
end

-- 开始定时器
function CountdownPanel:StartTimer()
    if self._timerId then return end
    self._timerId = SL:AddTimer(UPDATE_INTERVAL * 1000, handler(self, self.OnTimer), true)
end

-- 停止定时器
function CountdownPanel:StopTimer()
    if self._timerId then
        SL:RemoveTimer(self._timerId)
        self._timerId = nil
    end
end

-- 定时器回调
function CountdownPanel:OnTimer()
    if self._isPaused then return end
    self:UpdateDisplay()
end

-- 更新显示
function CountdownPanel:UpdateDisplay()
    local now = os.time() * 1000
    local remaining = self._endTime - now

    if remaining <= 0 then
        -- 倒计时结束
        remaining = 0
        FGUI:GTextField_setText(self._ui.time, "剩余时间：00:00:00")
        self:StopTimer()

        -- 触发结束回调
        if self._onCountdownEnd then
            self._onCountdownEnd()
        end
        return
    end

    -- 格式化时间显示
    local timeStr = self:FormatTime(remaining)
    FGUI:GTextField_setText(self._ui.time, "剩余时间：" .. timeStr)
end

-- 格式化时间显示
---@param milliseconds number 剩余时间（毫秒）
---@return string 格式化后的时间字符串
function CountdownPanel:FormatTime(milliseconds)
    local totalSeconds = math.floor(milliseconds / 1000)
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- 按钮点击事件
function CountdownPanel:OnButtonClick()
    FGUI:delayTouchEnabled(self._ui.btn, FGUIDefine.DelayClickTime)

    if self._onButtonClick then
        self._onButtonClick()
    end
end

-- 注册事件
function CountdownPanel:RegisterEvent()
    -- 注册场景切换事件
    SL:RegisterLUAEvent(LUA_EVENT_SCENE_CHANGE, "CountdownPanel", handler(self, self.OnSceneChange))
end

-- 移除事件
function CountdownPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_SCENE_CHANGE, "CountdownPanel")
end

-- 场景切换回调
function CountdownPanel:OnSceneChange()
    self:CloseSelf()
end

-- 关闭自己
function CountdownPanel:CloseSelf()
    if self._onClose then
        self._onClose()
    end
    FGUI:Close("huodong", "CountdownPanel")
end

return CountdownPanel
