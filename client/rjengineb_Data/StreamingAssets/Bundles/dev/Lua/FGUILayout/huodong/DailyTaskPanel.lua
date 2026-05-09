-- 每日必做面板
-- 活跃点任务和宝箱奖励
require("game_config/cfgcsv/actPointDetail")
require("game_config/cfgcsv/actPointAward")

DailyTaskPanel = class("DailyTaskPanel")

-- 任务状态
local TASK_STATE = {
    ongoing = 0,   -- 进行中（未完成）
    finish = 1,     -- 可领取
    received = 2,   -- 已领取
}

-- 数据管理
DailyTaskPanel.data = {
    taskList = {},       -- 任务列表
    awardList = {},      -- 奖励列表
    activePoint = 0,     -- 当前活跃点
    subscribers = {},    -- 订阅者
}

-- 订阅数据更新
function DailyTaskPanel:Subscribe(callback)
    if callback and type(callback) == "function" then
        table.insert(self.data.subscribers, callback)
    end
end

-- 取消订阅
function DailyTaskPanel:Unsubscribe(callback)
    for i, cb in ipairs(self.data.subscribers) do
        if cb == callback then
            table.remove(self.data.subscribers, i)
            break
        end
    end
end

-- 通知订阅者
function DailyTaskPanel:NotifySubscribers()
    for i = #self.data.subscribers, 1, -1 do
        local callback = self.data.subscribers[i]
        if callback and type(callback) == "function" then
            local success, err = xpcall(function()
                callback(self.data)
            end, debug.traceback)
            if not success then
                table.remove(self.data.subscribers, i)
            end
        else
            table.remove(self.data.subscribers, i)
        end
    end
end

---@param data table {taskList = {}, awardList = {}, activePoint = number}
function DailyTaskPanel:UpdateData(data)
    if data.taskList then
        self.data.taskList = data.taskList
    end
    if data.awardList then
        self.data.awardList = data.awardList
    end
    if data.activePoint then
        self.data.activePoint = data.activePoint
    end
    self:NotifySubscribers()
end

-- 获取任务列表
function DailyTaskPanel:GetTaskList()
    return self.data.taskList
end

-- 获取奖励列表
function DailyTaskPanel:GetAwardList()
    return self.data.awardList
end

-- 获取活跃点
function DailyTaskPanel:GetActivePoint()
    return self.data.activePoint
end

-- 进入界面
function DailyTaskPanel:Enter(data)
    self:RegisterEvent()
    self:RegisterMessageHandler()
    
    -- 请求服务端数据
    self:ReqData()
end

-- 退出界面
function DailyTaskPanel:Exit()
    self:UnregisterEvent()
    self:UnregisterMessageHandler()
end

-- 注册事件
function DailyTaskPanel:RegisterEvent()
    -- 注册任务列表渲染器
    local list_task = self.component:GetChild("n7")
    if list_task then
        FGUI:GList_itemRenderer(list_task, handler(self, self.TaskItemRenderer))
        list_task.numItems = #self.data.taskList
    end
    
    -- 注册奖励列表渲染器
    local list_award = self.component:GetChild("n1")
    if list_award then
        FGUI:GList_itemRenderer(list_award, handler(self, self.AwardItemRenderer))
        list_award.numItems = #self.data.awardList
    end
    
    -- 注册关闭按钮
    local btn_close = self.component:GetChild("n3")
    if btn_close then
        btn_close:AddEventListener(function()
            FGUI:Close("huodong", "DailyTaskPanel")
        end)
    end
end

-- 任务项渲染器
function DailyTaskPanel:TaskItemRenderer(index, item)
    local taskData = self.data.taskList[index + 1]
    if not taskData then return end
    self:UpdateTaskItem(item, taskData, index)
end

-- 奖励项渲染器
function DailyTaskPanel:AwardItemRenderer(index, item)
    local awardData = self.data.awardList[index + 1]
    if not awardData then return end
    self:UpdateAwardItem(item, awardData, index)
end

-- 注册消息处理
function DailyTaskPanel:RegisterMessageHandler()
    -- 监听服务端数据更新
    SLBridge:RegisterMsgHandler(ssrNetMsgCfg.DailyTask_RetData, function(data)
        self:UpdateData(data)
    end)
end

-- 取消注册消息处理
function DailyTaskPanel:UnregisterMessageHandler()
    SLBridge:UnregisterMsgHandler(ssrNetMsgCfg.DailyTask_RetData)
end

-- 请求数据
function DailyTaskPanel:ReqData()
    SLBridge:SendLuaMsg(ssrNetMsgCfg.DailyTask, "reqData", {})
end

-- 任务点击
function DailyTaskPanel:OnTaskClick(taskData)
    if taskData.state == TASK_STATE.finish then
        -- 可领取，发送领取请求
        SLBridge:SendLuaMsg(ssrNetMsgCfg.DailyTask, "getTaskAward", {taskData.id})
    elseif taskData.state == TASK_STATE.received then
        -- 已领取
        showTip("奖励已领取")
    else
        -- 进行中，前往任务
        self:GotoTask(taskData)
    end
end

-- 奖励点击
function DailyTaskPanel:OnAwardClick(awardData)
    if awardData.state == 1 then
        -- 已领取
        showTip("奖励已领取")
    elseif self.data.activePoint >= awardData.needPoint then
        -- 活跃点足够，发送领取请求
        SLBridge:SendLuaMsg(ssrNetMsgCfg.DailyTask, "getPointAward", {awardData.id})
    else
        -- 活跃点不足
        showTip("活跃点不足，需要" .. awardData.needPoint .. "点")
    end
end

-- 前往任务
function DailyTaskPanel:GotoTask(taskData)
    -- 根据任务类型跳转到对应界面或玩法
    if taskData.target and taskData.target ~= "" then
        -- 如果有目标信息，可能需要解析并导航
        showTip("前往：" .. taskData.name)
    end
end

-- 刷新任务列表
function DailyTaskPanel:RefreshTaskList()
    local list_task = self.component:GetChild("n7")
    if not list_task then return end
    
    list_task:RemoveChildrenToPool()
    
    for i, taskData in ipairs(self.data.taskList) do
        local item = list_task:AddItemFromPool()
        self:UpdateTaskItem(item, taskData, i)
    end
end

-- 更新任务项
function DailyTaskPanel:UpdateTaskItem(item, taskData, index)
    -- 任务名称
    local text_name = item:GetChild("n1")
    if text_name then
        text_name.text = taskData.name or ""
    end
    
    -- 进度文本
    local text_progress = item:GetChild("n2")
    if text_progress then
        text_progress.text = taskData.count .. "/" .. taskData.maxCount
    end
    
    -- 活跃点
    local text_point = item:GetChild("n3")
    if text_point then
        text_point.text = "+" .. taskData.point
    end
    
    -- 前往/领取按钮
    local btn_go = item:GetChild("n4")
    if btn_go then
        if taskData.state == TASK_STATE.finish then
            btn_go.title = "领取"
        elseif taskData.state == TASK_STATE.received then
            btn_go.title = "已领取"
            btn_go.grayed = true
        else
            btn_go.title = "前往"
            btn_go.grayed = false
        end
    end
end

-- 刷新奖励列表
function DailyTaskPanel:RefreshAwardList()
    local list_award = self.component:GetChild("n1")
    if not list_award then return end
    
    list_award:RemoveChildrenToPool()
    
    for i, awardData in ipairs(self.data.awardList) do
        local item = list_award:AddItemFromPool()
        self:UpdateAwardItem(item, awardData, i)
    end
end

-- 更新奖励项
function DailyTaskPanel:UpdateAwardItem(item, awardData, index)
    -- 需要活跃点
    local text_need = item:GetChild("n1")
    if text_need then
        text_need.text = awardData.needPoint
    end
    
    -- 领取状态
    local btn_get = item:GetChild("n2")
    if btn_get then
        if awardData.state == 1 then
            btn_get.title = "已领取"
            btn_get.grayed = true
        elseif self.data.activePoint >= awardData.needPoint then
            btn_get.title = "领取"
            btn_get.grayed = false
        else
            btn_get.title = awardData.needPoint .. "点"
            btn_get.grayed = true
        end
    end
    
    -- 奖励预览（如果有）
    local icon_award = item:GetChild("n3")
    if icon_award and awardData.awards and #awardData.awards > 0 then
        local itemId = awardData.awards[1][1]
        local itemCount = awardData.awards[1][2]
        -- 可以设置物品图标
    end
end

-- 刷新活跃点进度
function DailyTaskPanel:RefreshActivePoint()
    local text_point = self.component:GetChild("n6")
    if text_point then
        text_point.text = self.data.activePoint
    end
    
    -- 更新进度条
    local progress = self.component:GetChild("n5")
    if progress then
        local maxPoint = 200  -- 最大活跃点
        local percent = math.min(self.data.activePoint / maxPoint, 1)
        progress.value = percent * 100
    end
end

-- 完整刷新
function DailyTaskPanel:RefreshAll()
    self:RefreshTaskList()
    self:RefreshAwardList()
    self:RefreshActivePoint()
end

return DailyTaskPanel
