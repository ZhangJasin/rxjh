local BaseFGUILayout = requireFGUI("BaseFGUILayout")

---@class CountdownPanel
local CountdownPanel = class("CountdownPanel", BaseFGUILayout)

-- 定时器间隔
local UPDATE_INTERVAL = 1  -- 秒

-- 是否是PC端
local IS_PC = SL:GetValue("IS_PC_OPER_MODE")

function CountdownPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)

    -- 初始化数据
    self._cd = 0             -- 剩余倒计时（秒）
    self._scheduleId = nil   -- 定时器ID
    self._onButtonClick = nil -- 按钮点击回调
    self._onCountdownEnd = nil -- 倒计时结束回调
end

---@param data table {cd = number, btnText = string, callback = function}
function CountdownPanel:Enter(data)
    self:RegisterEvent()
    
    -- 隐藏左侧任务界面
    SLBridge:onLUAEvent(LUA_EVENT_ASSIST_HIDE)
    
    -- 适配PC端缩放
    if IS_PC then
        FGUI:setScale(self.component, 0.68, 0.75)
    end
    self.component.x = IS_PC and 0 or 3
    self.component.y = IS_PC and 105 or 135
    -- 处理传入的数据
    if data then
        local cd = data.cd or 0
        local btnText = data.btnText or "确定"
        local callback = data.callback

        -- 设置按钮文本
        local btn_title = FGUI:GetChild(self._ui.btn, "title")
        if btn_title then
            FGUI:GTextField_setText(btn_title, btnText)
        end

        -- 设置按钮点击回调
        if callback then
            self._onButtonClick = callback
        end

        -- 设置倒计时
        if cd > 0 then
            self:StartCountdown(cd)
        end
    end

    -- 设置按钮点击事件
    FGUI:setOnClickEvent(self._ui.btn, handler(self, self.OnButtonClick))
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
    self._isDestroy = true
end

-- 关闭自己
function CountdownPanel:CloseSelf()
    FGUI:Close("huodong", "CountdownPanel")
end

-- 开始倒计时
---@param seconds number 倒计时秒数
function CountdownPanel:StartCountdown(seconds)
    self._cd = seconds
    self:StartSchedule()
    self:UpdateDisplay()
end

-- 停止倒计时
function CountdownPanel:Stop()
    self:StopSchedule()
    self._cd = 0
end

-- 开始定时器
function CountdownPanel:StartSchedule()
    if self._scheduleId then return end
    self._scheduleId = SL:Schedule(function(dt)
        self._cd = self._cd - UPDATE_INTERVAL
        if self._cd <= 0 then
            self._cd = 0
            self:StopSchedule()
            self:UpdateDisplay()

            -- 触发结束回调
            if self._onCountdownEnd then
                self._onCountdownEnd()
            end
            -- 倒计时结束，关闭界面
            self:CloseSelf()
            return
        end
        self:UpdateDisplay()
    end, UPDATE_INTERVAL)
end

-- 停止定时器
function CountdownPanel:StopSchedule()
    if self._scheduleId then
        SL:UnSchedule(self._scheduleId)
        self._scheduleId = nil
    end
end

-- 更新显示
function CountdownPanel:UpdateDisplay()
    FGUI:GTextField_setText(self._ui.time, "剩余时间：" .. self:FormatTime(self._cd))
end

-- 格式化时间显示
---@param seconds number 剩余秒数
---@return string 格式化后的时间字符串
function CountdownPanel:FormatTime(seconds)
    seconds = math.max(0, seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- 按钮点击事件
function CountdownPanel:OnButtonClick()
    FGUI:delayTouchEnabled(self._ui.btn, FGUIDefine.DelayClickTime)

    if self._onButtonClick then
        self._onButtonClick()
    end
end

-- 设置倒计时结束回调
---@param callback function 回调函数
function CountdownPanel:SetCountdownEndCallback(callback)
    self._onCountdownEnd = callback
end
-- 注册事件
function CountdownPanel:RegisterEvent()
    SL:RegisterNetMsg(ssrNetMsgCfg.BOSSChall_End, handler(self, self.EndChall))
    SL:RegisterNetMsg(ssrNetMsgCfg.BOSSChall_Leave, handler(self, self.CloseSelf))
end
function CountdownPanel:EndChall(_,exitTime)
    -- 先关闭现有界面，再打开新的
    FGUI:Close("huodong", "CountdownPanel")
    FGUI:Open("huodong", "CountdownPanel", {
        cd = exitTime,
        btnText = "离开狩猎场",
        callback = function()
            ssrMessage:sendmsgEx("BossChall", "leaveChall")
        end
    })
end


-- 移除事件
function CountdownPanel:RemoveEvent()
    SL:UnRegisterNetMsg(ssrNetMsgCfg.BOSSChall_End)
    SL:UnRegisterNetMsg(ssrNetMsgCfg.BOSSChall_Leave)
end
return CountdownPanel
