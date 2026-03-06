-- 土灵符系统数据层：网络消息监听 + 缓存 + 事件发布
local tulingfuPanlData = {
    _state = {
        TuLingPosTab = {},           -- 土灵符位置表
        Index = 0,                   -- 当前选中索引
        Name = "",                   -- 当前名称
    },
    _listeners = {},       -- { eventName = { [token] = callback } }
    _tokenSeed = 0,
}

function tulingfuPanlData.Get()
    return tulingfuPanlData
end

-- 简单事件系统
function tulingfuPanlData:Subscribe(event, cb)
    if not self._listeners[event] then self._listeners[event] = {} end
    self._tokenSeed = self._tokenSeed + 1
    local token = tostring(self._tokenSeed)
    self._listeners[event][token] = cb
    return token
end

function tulingfuPanlData:Unsubscribe(token)
    for _, bucket in pairs(self._listeners) do
        if bucket[token] then
            bucket[token] = nil
            return true
        end
    end
    return false
end

function tulingfuPanlData:_Emit(event, payload)
    local bucket = self._listeners[event]
    if not bucket then return end
    for _, cb in pairs(bucket) do
        pcall(cb, payload)
    end
end

-- 对外请求接口（UI调用）
function tulingfuPanlData:RequestUseTuLing(index)
    ssrMessage:sendmsgEx("moveItem", "usetuling", {index})
end

function tulingfuPanlData:RequestAddPos(index, name)
    ssrMessage:sendmsgEx("moveItem", "addpos", {index, name})
end

function tulingfuPanlData:RequestDelPos(index)
    ssrMessage:sendmsgEx("moveItem", "delpos", {index})
end

function tulingfuPanlData:GetState()
    return self._state
end

-- 设置当前选中索引
function tulingfuPanlData:SetIndex(index)
    self._state.Index = index
    self:_Emit("index_changed", {index = index})
end

-- 设置当前名称
function tulingfuPanlData:SetName(name)
    self._state.Name = name
    self:_Emit("name_changed", {name = name})
end

-- 网络消息回调（由 ssrMessage 注册指向本 data 脚本）

-- 更新土灵符位置数据
function tulingfuPanlData:UpdateTuLingPosTab(data)
    self._state.TuLingPosTab = data.param1
    -- 通知UI层更新数据
    self:_Emit("data_update", {param1 = self._state.TuLingPosTab})
end

-- 打开界面回调
function tulingfuPanlData:Open(data)
    self._state.TuLingPosTab = data.param1
    FGUI:Open("A_TuLingFu", "tulingfuPanl", {}, FGUI_LAYER.NORMAL , { destroyTime = 1})
end

-- 更新界面数据回调
function tulingfuPanlData:Updata(data)
    self._state.TuLingPosTab = data.param1
    -- 通知UI层更新数据
    self:_Emit("data_update", {param1 = self._state.TuLingPosTab})
end

return tulingfuPanlData