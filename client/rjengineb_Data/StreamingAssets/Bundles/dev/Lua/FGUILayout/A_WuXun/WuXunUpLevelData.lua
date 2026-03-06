-- 数据层：网络消息监听 + 缓存 + 事件发布
local WuXunUpLevelData = {
    _state = {
        effectid = 0,
    },
    _listeners = {},       -- { eventName = { [token] = callback } }
    _tokenSeed = 0,
}

function WuXunUpLevelData.Get()
    return WuXunUpLevelData
end

-- 简单事件系统
function WuXunUpLevelData:Subscribe(event, cb)
    if not self._listeners[event] then self._listeners[event] = {} end
    self._tokenSeed = self._tokenSeed + 1
    local token = tostring(self._tokenSeed)
    self._listeners[event][token] = cb
    return token
end

function WuXunUpLevelData:Unsubscribe(token)
    for _, bucket in pairs(self._listeners) do
        if bucket[token] then
            bucket[token] = nil
            return true
        end
    end
    return false
end

function WuXunUpLevelData:_Emit(event, payload)
    local bucket = self._listeners[event]
    if not bucket then return end
    for _, cb in pairs(bucket) do
        pcall(cb, payload)
    end
end

-- 对外请求接口（UI调用）
function WuXunUpLevelData:GetState()
    return self._state
end

function WuXunUpLevelData:Open(data)
    self._state.effectid = tonumber(data.param1)
    FGUI:Open("A_WuXun", "WuXunUpLevel",self._state,FGUI_LAYER.NORMAL,{destroyTime = 1})
end



return WuXunUpLevelData