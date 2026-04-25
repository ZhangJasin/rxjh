local equipCollectData = {}

local config = require("game_config/cfgcsv/equipCollect")
local attrConfig = require("game_config/cfgcsv/equipCollectAttr")
local _data = {
    _subscribers = {},
    activeList = {},
    curValue = 0,
    nextValue = 0,
    curAttr = {},
    nextAttr = {}
}

--初始化数据
function equipCollectData:Init()
    --TODO:处理角色数据串
    --_data.activeList = {}

    local vars = { 37, 38, 39 }
    for _, id in ipairs(vars) do
        local content = SL:GetValue("T", id)
        if content and content ~= "" then
            local decode = SL:JsonDecode(content)
            if type(decode) == "table" then
                for k, _ in pairs(decode) do
                    _data.activeList[k] = true
                end
            end
        end
    end
    --dump(_data.activeList)

    --序列化属性配表
    self._sortedScores = {}
    for score, _ in pairs(attrConfig) do
        table.insert(self._sortedScores, score)
    end
    table.sort(self._sortedScores)

    self:CalculateValue()
    self:CalculateAttr()
end

--外部接口
function equipCollectData:Get()
    return equipCollectData
end

function equipCollectData:GetActiveList()
    return _data.activeList
end

function equipCollectData:GetCurValue()
    return _data.curValue
end

function equipCollectData:GetNextValue()
    return _data.nextValue
end

function equipCollectData:GetCurAttr()
    return _data.curAttr
end

function equipCollectData:GetNextAttr()
    return _data.nextAttr
end

function equipCollectData:CalculateValue()
    local val = 0
    for id, _ in pairs(_data.activeList) do
        for _, conf in ipairs(config) do
            if tonumber(id) == conf.idx then
                val = val + conf.value
            end
        end
    end
    _data.curValue = val

    local nextVal = 0
    local count = #self._sortedScores
    if count > 0 then
        for i = 1, count do
            local scoreThreshold = self._sortedScores[i]
            if val < scoreThreshold then
                nextVal = scoreThreshold
                break
            end
        end
        if nextVal == 0 then
            nextVal = self._sortedScores[count]
        end
    end
    _data.nextValue = nextVal
end

function equipCollectData:CalculateAttr()
    local value = _data.curValue
    local bestConf = {}
    local nextConf = {}
    local count = #self._sortedScores
    if count == 0 then return end
    for i = 1, count do
        local scoreKey = self._sortedScores[i]
        local conf = attrConfig[scoreKey]
        if value >= conf.scores then
            bestConf = conf.attr
            if i == count then
                nextConf = conf.attr
            end
        else
            nextConf = conf.attr
            break
        end
    end
    _data.curAttr = bestConf
    _data.nextAttr = nextConf
end

function equipCollectData:IsActive(id)
    --dump(_data.activeList)
    return _data.activeList[tostring(id)] == true
end

--订阅事件
function equipCollectData:Subscribe(event, callback)
    if not _data._subscribers[event] then
        _data._subscribers[event] = {}
    end
    local token = #_data._subscribers[event] + 1
    _data._subscribers[event][token] = callback
    return { event = event, token = token }
end

function equipCollectData:Publish(event, data)
    if _data._subscribers and _data._subscribers[event] then
        for _, callback in pairs(_data._subscribers[event]) do
            if callback then callback(data) end
        end
    end
end

function equipCollectData:Unsubscribe(subscription)
    if subscription and subscription.event and subscription.token then
        if _data._subscribers[subscription.event] then
            _data._subscribers[subscription.event][subscription.token] = nil
        end
    end
end

--网络数据
function equipCollectData:ReqActive(id)
    ssrMessage:sendmsgEx("equipCollect", "ReqActive", id)
end

function equipCollectData:RetActive(data)
    if data.result then
        _data.activeList[tostring(data.id)] = true
        dump(_data.activeList)
        self:CalculateValue()
        self:CalculateAttr()
        self:Publish("EQUIP_COLLECT_UPDATE", {
            id = data.id
        })
    end
end

return equipCollectData
