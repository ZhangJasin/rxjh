-- 武勋系统数据层：网络消息监听 + 缓存 + 事件发布
local WuXunPanlData = {
    _state = {
        WuXun_Level = 1,             -- 武勋等阶
        WuXun_curExp = 0,            -- 武勋当前经验值
        WuXun_DailyState = 0,        -- 武勋每日奖励领取状态
        goodDevilID = 1,             -- 阵营ID 0无 1正 2邪
        WuXun_ChuiLianList = {},     -- 锤炼等级列表
        WuXunFXID = 0,               -- 武勋特效ID
    },
    _listeners = {},       -- { eventName = { [token] = callback } }
    _tokenSeed = 0,
}

function WuXunPanlData.Get()
    return WuXunPanlData
end

-- 简单事件系统
function WuXunPanlData:Subscribe(event, cb)
    if not self._listeners[event] then self._listeners[event] = {} end
    self._tokenSeed = self._tokenSeed + 1
    local token = tostring(self._tokenSeed)
    self._listeners[event][token] = cb
    return token
end

function WuXunPanlData:Unsubscribe(token)
    for _, bucket in pairs(self._listeners) do
        if bucket[token] then
            bucket[token] = nil
            return true
        end
    end
    return false
end

function WuXunPanlData:_Emit(event, payload)
    local bucket = self._listeners[event]
    if not bucket then return end
    for _, cb in pairs(bucket) do
        pcall(cb, payload)
    end
end

-- 对外请求接口（UI调用）
function WuXunPanlData:RequestWuXunData()
    -- 初始化数据
    self._state.WuXun_Level = SL:GetValue("U", 69) or 0
    if self._state.WuXun_Level < 1 then
        self._state.WuXun_Level = 1
    end
    self._state.WuXun_curExp = SL:GetValue("U", 70) or 0
    self._state.WuXun_DailyState = SL:GetValue("U", 71) or 0
    self._state.goodDevilID = tonumber(SL:GetValue("GOODEVILID")) or 1
    if self._state.goodDevilID < 1 then
        self._state.goodDevilID = 1
    end
    
    -- 获取锤炼数据
    local chuiLianData = SL:GetValue("T", 29) or 0
    if chuiLianData == 0 or chuiLianData == "" then
        self._state.WuXun_ChuiLianList = {}
    else
        self._state.WuXun_ChuiLianList = SL:JsonDecode(chuiLianData)
    end
    
    -- 计算特效ID
    local wuxun_level_data = require("game_config/cfgcsv/wuxun_level_data")
    if wuxun_level_data[self._state.WuXun_Level] and wuxun_level_data[self._state.WuXun_Level]['WuXunEffect'] then
        self._state.WuXunFXID = wuxun_level_data[self._state.WuXun_Level]['WuXunEffect'][self._state.goodDevilID] or 0
    end
    -- dump(self._state,"武勋数据")
    -- 通知UI层数据更新
    self:_Emit("wuxun_data_update", self._state)
    
    -- 发送消息激活特效
    ssrMessage:sendmsgEx("wuxun", "OpenWuXunPanl")
end

function WuXunPanlData:GetDailyReward()
    ssrMessage:sendmsgEx("wuxun", "GetDailyReward")
end

function WuXunPanlData:WuXunEquipChuilian(params)
    ssrMessage:sendmsgEx("wuxun", "WuXunEquipChuilian", params)
end

function WuXunPanlData:GetState()
    return self._state
end

-- 网络消息回调（由 ssrMessage 注册指向本 data 脚本）

-- 更新领取武勋等级每日奖励标识
function WuXunPanlData:update_dailyPanl(data)
    self._state.WuXun_DailyState = data.param1
    self:_Emit("daily_reward_update", {state = data.param1})
end

-- 更新武勋锤炼数据
function WuXunPanlData:UpdateWuXunChuiLianData(data)
    self._state.WuXun_ChuiLianList = data.param1
    self:_Emit("chuilian_data_update", {list = data.param1})
end

-- 更新武勋铸阶数据
function WuXunPanlData:UpdateWuXunZhujieData(data)
    self:_Emit("zhujie_data_update", data)
end

-- 更新武勋转印数据
function WuXunPanlData:UpdateWuXunZhuanYinData(data)
    self:_Emit("zhuanyin_data_update", data)
end

return WuXunPanlData