local MainMissionData = {}
local Task_cfg = require("game_config/cfgcsv/Task")

-- 缓存数据
MainMissionData.data = {
    missionDatas = {},
    taskProgressList = {},
    taskProgressPre = {},
    transfer_cur = {},
    transfer_next = {},
    taskID = nil,
    stopTime = 0,
    subscribers = {},
    isNotifying = false  -- 添加防循环标志
}
-- 排序
local function SortMissionData(a, b)
    a.weight = Task_cfg[a.taskid] and Task_cfg[a.taskid]['task_weight'] or 0
    b.weight = Task_cfg[b.taskid] and Task_cfg[b.taskid]['task_weight'] or 0
    return a.weight < b.weight
end

-- 订阅数据更新
function MainMissionData:Subscribe(callback)
    if callback and type(callback) == "function" then
        table.insert(self.data.subscribers, callback)
    end
end

-- 取消订阅
function MainMissionData:Unsubscribe(callback)
    for i, cb in ipairs(self.data.subscribers) do
        if cb == callback then
            table.remove(self.data.subscribers, i)
            break
        end
    end
end

-- 通知所有订阅者
function MainMissionData:NotifySubscribers()
    -- 防循环检查
    if self.data.isNotifying then
        -- print("MainMissionData:NotifySubscribers - 检测到循环调用，已阻止")
        return
    end

    -- 排序
    if self.data.missionDatas and #self.data.missionDatas > 0 then
        table.sort(self.data.missionDatas, SortMissionData)
    end
    
    self.data.isNotifying = true
    
    -- 安全检查：避免在UI组件销毁后触发事件
    for i = #self.data.subscribers, 1, -1 do
        local callback = self.data.subscribers[i]
        if callback and type(callback) == "function" then
            -- 使用更安全的参数传递方式
            local success, err = xpcall(function()
                -- 确保传递正确的数据格式
                local notifyData = {
                    missionDatas = self.data.missionDatas,
                    taskProgressList = self.data.taskProgressList,
                    taskID = self.data.taskID,
                    stopTime = self.data.stopTime
                }
                callback(notifyData)
            end, debug.traceback)
            
            if not success then
                -- 如果回调失败，可能是UI组件已销毁，移除该订阅者
                -- print("MainMissionData:NotifySubscribers callback failed:", err)
                table.remove(self.data.subscribers, i)
            end
        else
            -- 移除无效的回调
            table.remove(self.data.subscribers, i)
        end
    end
    
    self.data.isNotifying = false
end

-- 获取任务数据
function MainMissionData:GetMissionDatas()
    return self.data.missionDatas
end


-- 设置任务数据
function MainMissionData:SetMissionDatas(datas)
    -- 确保datas是有效表格
    if not datas or type(datas) ~= "table" then
        datas = {}
    end

    -- 检查数据是否真的发生了变化
    local hasChanged = false
    if #self.data.missionDatas ~= #datas then
        hasChanged = true
    else
        -- 不仅比较数量和ID，还需要检查任务数据的完整性
        for i, newData in ipairs(datas) do
            local oldData = self.data.missionDatas[i]
            if not oldData or oldData.taskid ~= newData.taskid then
                hasChanged = true
                break
            end
            -- 简单检查：如果有任何字段不同，则认为数据已变化
            -- 更严格的检查可以在这里添加
        end
    end
    
    -- 强制更新：即使数据看似相同，也可能存在隐藏的变化
    -- 这可以解决一些因为数据比较不全面导致的刷新问题
    table.clear(self.data.missionDatas)
    for k, data in pairs(datas) do
        table.insert(self.data.missionDatas, data)
    end
    
    -- 始终通知订阅者，确保UI与数据同步
    self:NotifySubscribers()
end



-- 获取任务进度列表
function MainMissionData:GetTaskProgressList()
    -- dump(self.data.taskProgressList ,"当前任务进度列表")
    if next(self.data.taskProgressList) == nil then
        -- print("MainMissionData:GetTaskProgressList - 任务进度列表为空，尝试从存储加载")
        local progressList = SL:GetValue("T", 12) or 0
        if progressList == 0 or progressList == "" then
            self.data.taskProgressList = {}  
        else
            local decodedProgress = SL:JsonDecode(progressList)
            -- 确保解码结果是有效表格
            if decodedProgress and type(decodedProgress) == "table" then
                self.data.taskProgressList = decodedProgress
            else
                self.data.taskProgressList = {}
            end
        end
    end
    return self.data.taskProgressList
end

-- 设置任务进度列表
function MainMissionData:SetTaskProgressList(progressList)
    -- 检查数据是否真的发生了变化
    local hasChanged = false
    if not self.data.taskProgressList or #self.data.taskProgressList ~= #progressList then
        hasChanged = true
    else
        for k, v in pairs(progressList) do
            if not self.data.taskProgressList[k] or 
               self.data.taskProgressList[k].count ~= v.count or 
               self.data.taskProgressList[k].state ~= v.state then
                hasChanged = true
                break
            end
        end
    end
    
    if hasChanged then
        self.data.taskProgressList = progressList
        self:NotifySubscribers()
    end
end

-- 获取当前任务ID
function MainMissionData:GetTaskID()
    return self.data.taskID
end

-- 设置当前任务ID
function MainMissionData:SetTaskID(taskID)
    self.data.taskID = taskID
    self:NotifySubscribers()
end

-- 获取停止时间
function MainMissionData:GetStopTime()
    return self.data.stopTime
end

-- 设置停止时间
function MainMissionData:SetStopTime(stopTime)
    self.data.stopTime = stopTime
    self:NotifySubscribers()
end

-- 更新任务进度
function MainMissionData:UpdateTaskProgress(data)
    if not data or not data.param1 then
        return
    end
    
    -- 检查数据是否真的发生了变化
    local hasChanged = false
    local newProgressList = data.param1
    
    if not self.data.taskProgressList or #self.data.taskProgressList ~= #newProgressList then
        hasChanged = true
    else
        for k, v in pairs(newProgressList) do
            if not self.data.taskProgressList[k] or 
               self.data.taskProgressList[k].count ~= v.count or 
               self.data.taskProgressList[k].state ~= v.state then
                hasChanged = true
                break
            end
        end
    end
    
    if hasChanged then
        self.data.taskProgressList = newProgressList
        
        -- 立即通知，避免定时器相关的复杂问题
        -- 使用pcall包装通知调用，防止错误传播
        local success, err = pcall(function()
            self:NotifySubscribers()
        end)
        
        if not success then
            -- print("MainMissionData:UpdateTaskProgress - 通知订阅者失败:", err)
        end
    end
end


-- 添加任务项
function MainMissionData:AddMissionItem(data)
    -- 检查是否已存在相同任务
    local exists = false
    for _, item in ipairs(self.data.missionDatas) do
        if item.taskid == data.taskid then
            exists = true
            break
        end
    end
    
    if not exists then
        table.insert(self.data.missionDatas, data)
        self:NotifySubscribers()
    end
end

-- 移除任务项
function MainMissionData:RemoveMissionItem(data)
    local rmvSucc = false
    for k, v in pairs(self.data.missionDatas) do
        if v.type == data.type then
            rmvSucc = true
            table.remove(self.data.missionDatas, k)
            break
        end
    end
    if rmvSucc then
        self:NotifySubscribers()
    end
end

-- 任务项置顶
function MainMissionData:TopMissionItem(id)
    self:NotifySubscribers()
end

-- 任务项变更
function MainMissionData:ChangeMissionItem(data)
    self:NotifySubscribers()
end

-- 初始化任务进度
function MainMissionData:InitTaskProgress()
    local progressList = SL:GetValue("T", 12) or 0
    if progressList == 0 or progressList == "" then
        self.data.taskProgressList = {}  
    else
        local decodedProgress = SL:JsonDecode(progressList)
        -- 确保解码结果是有效表格
        if decodedProgress and type(decodedProgress) == "table" then
            self.data.taskProgressList = decodedProgress
        else
            self.data.taskProgressList = {}
        end
    end

    self.data.transfer_cur = SL:GetMetaValue("TRANSFER_MAINPLAYER_CONFIG")
    self.data.transfer_next = SL:GetMetaValue("TRANSFER_MAINPLAYER_NEXT_CONFIG")
    -- 确保备份数据也是有效表格
    self.data.taskProgressPre = self.data.taskProgressList or {}
    
    -- 通知订阅者，确保进度数据变化时UI能更新
    self:NotifySubscribers()
end

function MainMissionData:TransferComplete()  -- 网络请求
    self.data.transfer_cur = SL:GetMetaValue("TRANSFER_MAINPLAYER_CONFIG")
    self.data.transfer_next = SL:GetMetaValue("TRANSFER_MAINPLAYER_NEXT_CONFIG")
    FGUI:Open("Transfer", "TransferSucceed", { curCfg = self.data.transfer_cur, nextCfg = self.data.transfer_next })
end

function MainMissionData:OpenTransfer()  -- 网络请求
    FGUI:Open("Transfer", "TransferPanel")
end

-- 转职数据
function MainMissionData:SetTransferData()
    self.data.transfer_cur = SL:GetMetaValue("TRANSFER_MAINPLAYER_CONFIG")
    self.data.transfer_next = SL:GetMetaValue("TRANSFER_MAINPLAYER_NEXT_CONFIG")
end


function MainMissionData:UpdataTask(data)
    MainMissionData:UpdateTaskProgress(data)
end

return MainMissionData