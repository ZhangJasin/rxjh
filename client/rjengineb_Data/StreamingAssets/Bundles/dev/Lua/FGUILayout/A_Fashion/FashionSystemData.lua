-- 时装系统数据层：网络消息监听 + 缓存 + 事件发布
local FashionSystemData = {
    _state = {
        FashionDate = {},       -- 当前已激活时装数据
        charmValue = 0,         -- 当前时装总魅力值
        charmLv = 1,            -- 当前时装魅力值等级
    },
    _listeners = {},       -- { eventName = { [token] = callback } }
    _tokenSeed = 0,
}

function FashionSystemData.Get()
    return FashionSystemData
end

-- 简单事件系统
function FashionSystemData:Subscribe(event, cb)
    if not self._listeners[event] then self._listeners[event] = {} end
    self._tokenSeed = self._tokenSeed + 1
    local token = tostring(self._tokenSeed)
    self._listeners[event][token] = cb
    return token
end

function FashionSystemData:Unsubscribe(token)
    for _, bucket in pairs(self._listeners) do
        if bucket[token] then
            bucket[token] = nil
            return true
        end
    end
    return false
end

function FashionSystemData:_Emit(event, payload)
    local bucket = self._listeners[event]
    if not bucket then return end
    for _, cb in pairs(bucket) do
        pcall(cb, payload)
    end
end

-- 对外请求接口（UI调用）
function FashionSystemData:RequestHuanHua(params)
    ssrMessage:sendmsgEx("FashionSystem", "HuanHua", params)
end

function FashionSystemData:RequestWearAttr(params)
    ssrMessage:sendmsgEx("FashionSystem", "wearAttr", params)
end

function FashionSystemData:GetState()
    return self._state
end

-- 初始化时装数据
function FashionSystemData:InitFashionData()
    local data = SL:GetValue("T", 13) or 0
    if data == 0 or data == "" then
        self._state.FashionDate = {}
    else
        self._state.FashionDate = SL:JsonDecode(data)
    end
    return self._state.FashionDate
end

-- 网络消息回调（由 ssrMessage 注册指向本 data 脚本）
function FashionSystemData:Open(data)
    FGUI:Open("Apanl", "FashionSystemPanl",data,nil,{destroyTime = 1})
end

-- 更新时装数据
function FashionSystemData:UpdataData(data)
    self._state.FashionDate = data.param1
    self._state.charmValue = tonumber(data.param2) or 0
    self._state.charmLv = tonumber(data.param3) or 1
    -- 通知UI层更新
    self:_Emit("fashion_data_update", data)
end

return FashionSystemData