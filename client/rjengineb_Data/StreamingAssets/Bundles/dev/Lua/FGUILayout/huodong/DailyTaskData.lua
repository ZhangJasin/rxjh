local DailyTaskData = {
    _listeners = {},       -- { eventName = { [token] = callback } }
    _tokenSeed = 0,
}
local _data = {
    taskList = {},
    awardList = {},
    activePoint = 0,   
}

-- 获取数据层单例
function DailyTaskData:Get()
    return DailyTaskData
end

-- 订阅数据更新（返回 token 用于取消订阅）
function DailyTaskData:Subscribe(event, cb)
    if not self._listeners[event] then self._listeners[event] = {} end
    self._tokenSeed = self._tokenSeed + 1
    local token = tostring(self._tokenSeed)
    self._listeners[event][token] = cb
    return token
end

-- 取消订阅（使用 token）
function DailyTaskData:Unsubscribe(token)
    for _, bucket in pairs(self._listeners) do
        if bucket[token] then
            bucket[token] = nil
            return true
        end
    end
    return false
end

-- 通知订阅者
function DailyTaskData:_Emit(event, data)
    local bucket = self._listeners[event]
    if not bucket then return end
    for _, cb in pairs(bucket) do
        pcall(cb, data)
    end
end

function DailyTaskData:ReqData()
    ssrMessage:sendmsgEx("DailyTask", "reqData")
end
function DailyTaskData:getAward(id)
    ssrMessage:sendmsgEx("DailyTask", "getPointAward",id)
end

-- 更新数据并通知（网络消息回调）
function DailyTaskData:UpdateData(data)
    if data.taskList then
        _data.taskList = data.taskList
    end
    if data.awardList then
        _data.awardList = data.awardList
    end
    if data.activePoint then
        _data.activePoint = data.activePoint
    end
    self:_Emit("update_data")
end

-- 更新数据并通知（网络消息回调）
function DailyTaskData:UpdateAwardData(data)   
    if data.awardList then
        _data.awardList = data.awardList
    end
    self:_Emit("update_award")
end

-- 获取任务列表
function DailyTaskData:GetTaskList()
    return _data.taskList
end

function DailyTaskData:GetTaskProgress(index)
    return _data.taskList[index] or 0
end

-- 获取奖励列表
function DailyTaskData:GetAwardList()
    return _data.awardList
end
function DailyTaskData:IsGotAward(index)
    local isState = _data.awardList[index] or 0
    return isState == 1
end

function DailyTaskData:GetActivePoint()
    return _data.activePoint
end

return DailyTaskData
