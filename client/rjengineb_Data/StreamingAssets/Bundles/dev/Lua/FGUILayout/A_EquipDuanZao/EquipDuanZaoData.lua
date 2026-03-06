-- 装备锻造系统数据层：网络消息监听 + 缓存 + 事件发布
local EquipDuanZaoData = {
    _state = {
        -- 可以根据需要添加数据缓存
    },
    _listeners = {},       -- { eventName = { [token] = callback } }
    _tokenSeed = 0,
}

function EquipDuanZaoData.Get()
    return EquipDuanZaoData
end

-- 简单事件系统
function EquipDuanZaoData:Subscribe(event, cb)
    if not self._listeners[event] then self._listeners[event] = {} end
    self._tokenSeed = self._tokenSeed + 1
    local token = tostring(self._tokenSeed)
    self._listeners[event][token] = cb
    return token
end

function EquipDuanZaoData:Unsubscribe(token)
    for _, bucket in pairs(self._listeners) do
        if bucket[token] then
            bucket[token] = nil
            return true
        end
    end
    return false
end

function EquipDuanZaoData:_Emit(event, payload)
    local bucket = self._listeners[event]
    if not bucket then return end
    for _, cb in pairs(bucket) do
        pcall(cb, payload)
    end
end

-- 对外请求接口（UI调用）
function EquipDuanZaoData:RequestHeCheng(params)
    ssrMessage:sendmsgEx("EquipDuanZao", "hecheng", params)
end

function EquipDuanZaoData:RequestFuYu(params)
    ssrMessage:sendmsgEx("EquipDuanZao", "fuyu", params)
end

function EquipDuanZaoData:RequestJueXing(params)
    ssrMessage:sendmsgEx("EquipDuanZao", "juexing", params)
end

function EquipDuanZaoData:RequestFuHun(params)
    ssrMessage:sendmsgEx("EquipDuanZao", "fuhun", params)
end

function EquipDuanZaoData:RequestQiangHua(params)
    ssrMessage:sendmsgEx("EquipDuanZao", "qianghua", params)
end

-- 网络消息回调（由 ssrMessage 注册指向本 data 脚本）

-- 穿戴装备更新
function EquipDuanZaoData:OnEquipUpdate()
    self:_Emit("equip_update")
end

-- 强化更新回调
function EquipDuanZaoData:UpdataQH(data)
    self:_Emit("qianghua_update", data)
end

-- 赋予更新回调
function EquipDuanZaoData:UpdataFY(data)
    self:_Emit("fuyu_update", data)
end

-- 合成石更新回调
function EquipDuanZaoData:UpdataHC(data)
    self:_Emit("hecheng_update", data)
end


return EquipDuanZaoData
