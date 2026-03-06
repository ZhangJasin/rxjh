-- 右上角面板数据层：网络消息监听 + 缓存 + 事件发布
local righttoppanlData = {
    _state = {
        cityitemlist = {},      -- 回城符集合
        xunlutab = {},         -- 自动寻路参数表
    },
    _listeners = {},       -- { eventName = { [token] = callback } }
    _tokenSeed = 0,
}

-- 回城符列表定义
local cityitemtab = {127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140}


function righttoppanlData.Get()
    return righttoppanlData
end

-- 简单事件系统
function righttoppanlData:Subscribe(event, cb)
    if not self._listeners[event] then self._listeners[event] = {} end
    self._tokenSeed = self._tokenSeed + 1
    local token = tostring(self._tokenSeed)
    self._listeners[event][token] = cb
    return token
end

function righttoppanlData:Unsubscribe(token)
    for _, bucket in pairs(self._listeners) do
        if bucket[token] then
            bucket[token] = nil
            return true
        end
    end
    return false
end

function righttoppanlData:_Emit(event, payload)
    local bucket = self._listeners[event]
    if not bucket then return end
    for _, cb in pairs(bucket) do
        pcall(cb, payload)
    end
end

-- 对外请求接口（UI调用）
-- 使用回城符道具
function righttoppanlData:RequestBackCity(param)
    ssrMessage:sendmsgEx("moveItem", "BackCity", param)
end
-- 使用传送符道具
function righttoppanlData:RequestMove(param)
    ssrMessage:sendmsgEx("moveItem", "move", param)
end
-- 使用道具弹窗
function righttoppanlData:RequestUseItem(data)
    ssrMessage:sendmsgEx(data.param1, data.param2, { data.param3, data.param4 })
end

-- 获取状态
function righttoppanlData:GetState()
    return self._state
end

-- 更新回城符列表数据
function righttoppanlData:getitemnum()
    self._state.cityitemlist = {}
    for i = 1, #cityitemtab do
        local itemid = cityitemtab[i]
        local itemnum = SL:GetValue("ITEMCOUNT", itemid)
        local data = SL:GetValue("ITEM_DATA", itemid)
        if itemnum > 0 then
            table.insert(self._state.cityitemlist, { data, itemnum })
        end
    end
    self:_Emit("city_item_update", self._state.cityitemlist)
    return self._state.cityitemlist
end

-- 自动寻路开始
function righttoppanlData:onXunlunBegin(data)
    self._state.xunlutab = { data.mapID, data.x, data.z }
    self:_Emit("xunlun_begin", data)
end

-- 自动寻路结束
function righttoppanlData:onXunlunEnd()
    self:_Emit("xunlun_end")
end

-- 目标变化
function righttoppanlData:onTargerChange(data)
    self:_Emit("target_change", data)
end

-- 等级改变
function righttoppanlData:OnRefreshPropertyShow(curlv)
    self:_Emit("level_change", {lv = curlv or SL:GetValue("LEVEL")})
end

-- 使用道具确认处理
function righttoppanlData:useItem(data)
    self:_Emit("use_item", data)
end


-- 注册全局事件
function righttoppanlData:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_AUTO_MOVE_BEGIN, "righttoppanlData", handler(self, self.onXunlunBegin))
    SL:RegisterLUAEvent(LUA_EVENT_AUTO_MOVE_END, "righttoppanlData", handler(self, self.onXunlunEnd))
    SL:RegisterLUAEvent(LUA_EVENT_TARGET_CAHNGE, "righttoppanlData", handler(self, self.onTargerChange))
    SL:RegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "righttoppanlData", handler(self, self.OnRefreshPropertyShow))
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "righttoppanlData", handler(self, self.OnRefreshPropertyShow))
end

-- 移除全局事件
function righttoppanlData:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_AUTO_MOVE_BEGIN, "righttoppanlData")
    SL:UnRegisterLUAEvent(LUA_EVENT_AUTO_MOVE_END, "righttoppanlData")
    SL:UnRegisterLUAEvent(LUA_EVENT_TARGET_CAHNGE, "righttoppanlData")
    SL:UnRegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "righttoppanlData")
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "righttoppanlData")
end

return righttoppanlData