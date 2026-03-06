--[[
    任务交付面板数据层
    主要功能：任务数据管理、订阅机制、数据缓存
--]]

local taskDeliverData = {}
local NpcList = require("game_config/NpcList")
local Task_cfg = require("game_config/cfgcsv/Task")
local Language_cfg = require("game_config/cfgcsv/Language")

-- 缓存数据
taskDeliverData.data = {
    taskID = nil,
    taskProgressData = nil,
    rewardList = {},
    subscribers = {},
    isNotifying = false
}

-- 订阅数据更新
function taskDeliverData:Subscribe(callback)
    if callback and type(callback) == "function" then
        table.insert(self.data.subscribers, callback)
    end
end

-- 取消订阅
function taskDeliverData:Unsubscribe(callback)
    for i, cb in ipairs(self.data.subscribers) do
        if cb == callback then
            table.remove(self.data.subscribers, i)
            break
        end
    end
end

-- 通知所有订阅者
function taskDeliverData:NotifySubscribers()
    -- 防循环检查
    if self.data.isNotifying then
        -- print("taskDeliverData:NotifySubscribers - 检测到循环调用，已阻止")
        return
    end
    
    self.data.isNotifying = true
    
    -- 安全检查：避免在UI组件销毁后触发事件
    for i = #self.data.subscribers, 1, -1 do
        local callback = self.data.subscribers[i]
        if callback and type(callback) == "function" then
            local success, err = xpcall(function()
                callback(self.data)
            end, debug.traceback)
            
            if not success then
                -- print("taskDeliverData:NotifySubscribers callback failed:", err)
                table.remove(self.data.subscribers, i)
            end
        else
            table.remove(self.data.subscribers, i)
        end
    end
    
    self.data.isNotifying = false
end

-- 获取任务ID
function taskDeliverData:GetTaskID()
    return self.data.taskID
end

-- 设置任务ID
function taskDeliverData:SetTaskID(taskID)
    if self.data.taskID ~= taskID then
        self.data.taskID = taskID
        self:NotifySubscribers()
    end
end

-- 获取任务进度数据
function taskDeliverData:GetTaskProgressData()
    return self.data.taskProgressData
end

-- 设置任务进度数据
function taskDeliverData:SetTaskProgressData(progressData)
    self.data.taskProgressData = progressData
    self:NotifySubscribers()
end

-- 获取奖励列表
function taskDeliverData:GetRewardList()
    return self.data.rewardList
end

-- 设置奖励列表
function taskDeliverData:SetRewardList(rewardList)
    self.data.rewardList = rewardList
    self:NotifySubscribers()
end

-- 根据职业筛选奖励
function taskDeliverData:FilterRewardsByJob()
    if not self.data.taskID then return {} end
    
    local myJob = SL:GetValue("JOB")
    local mySex = SL:GetValue("SEX")
    local myZy = SL:GetValue("GOODEVILID") or 0
    local tab = Task_cfg[self.data.taskID]['task_drop'] or {}
    local filteredRewards = {}
    local index = 0
    
    for _, v in pairs(tab) do
        local needjob,needsex,needzy = v[1],v[4] or 0,v[5] or 0 
        if (needjob == myJob or needjob == 9) and (needsex == mySex or needsex == 0) and (needzy == myZy or needzy == 0) then
            index = index + 1
            filteredRewards[index] = v
        end
    end
    
    return filteredRewards
end

-- 获取NPC信息
function taskDeliverData:GetNpcInfo()
    if not self.data.taskID then return nil end
    local npcid = Task_cfg[self.data.taskID]['task_finnpc']
    return NpcList[npcid]
end

-- 获取任务标题
function taskDeliverData:GetTaskTitle()
    if not self.data.taskID then return "" end
    return Language_cfg[Task_cfg[self.data.taskID]['task_name']]['Dec']
end

-- 获取任务内容
function taskDeliverData:GetTaskContent()
    if not self.data.taskID then return "" end
    local context = Language_cfg[Task_cfg[self.data.taskID]['task_findial']]['Dec'] or ""
    if context == "" then
        context = Task_cfg[self.data.taskID]['task_findial']
    end
    return context
end

-- 打开面板
function taskDeliverData:OpenPanl(data)
    if data and data.param2 then
        self:SetTaskID(tonumber(data.param2))
    end
    if data and data.param1 then
        self:SetTaskProgressData(data.param1)
    end
    
    -- 筛选奖励
    local rewards = self:FilterRewardsByJob()
    self:SetRewardList(rewards)
    
    FGUI:Open("A_TaskDeliver", "taskDeliver", {}, FGUI_LAYER.NORMAL, { destroyTime = 0.1})
end

return taskDeliverData