-- 数据层：网络消息监听 + 缓存 + 事件发布
local MainAssistData = {
    _state = {
        
    },
    _listeners = {},       -- { eventName = { [token] = callback } }
    _tokenSeed = 0,
}

function MainAssistData.Get()
    return MainAssistData
end

-- 简单事件系统
function MainAssistData:Subscribe(event, cb)
    if not self._listeners[event] then self._listeners[event] = {} end
    self._tokenSeed = self._tokenSeed + 1
    local token = tostring(self._tokenSeed)
    self._listeners[event][token] = cb
    return token
end

function MainAssistData:Unsubscribe(token)
    for _, bucket in pairs(self._listeners) do
        if bucket[token] then
            bucket[token] = nil
            return true
        end
    end
    return false
end

function MainAssistData:_Emit(event, payload)
    local bucket = self._listeners[event]
    if not bucket then return end
    for _, cb in pairs(bucket) do
        pcall(cb, payload)
    end
end

-- 对外请求接口（UI调用）
function MainAssistData:GetState()
    return self._state
end


-- 改变MainAssist显示状态（UI调用）
function MainAssistData:ChangeShow(flag)
    -- 通知UI层改变显示状态
    self:_Emit("change_show", flag)
end


return MainAssistData