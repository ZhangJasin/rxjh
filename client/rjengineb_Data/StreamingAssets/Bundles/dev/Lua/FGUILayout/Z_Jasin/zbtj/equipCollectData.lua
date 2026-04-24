local equipCollectData = {}

local config = require("game_config/cfgcsv/equipCollect")

local _data = {
    _subscribers = {},
    activeList = {},
    totalValue = 0
}

--初始化数据
function equipCollectData:Init()

end

--外部接口
function equipCollectData:Get()
    return equipCollectData
end

function equipCollectData:GetActiveList()
    return _data.activeList
end

function equipCollectData:GetValue()
    return _data.totalValue
end

function equipCollectData:CalculateValue()
    local val = 0
    for id, _ in pairs(_data.activeList) do
        for _, conf in ipairs(config) do
            if id == conf.idx then
                val = val + conf.value
            end
        end
    end
    _data.totalValue = val
end

function equipCollectData:IsActive(id)
    return _data.activeList[id] == true
end

--订阅事件
function equipCollectData:Subscribe(event, callback)
    if not _data._subscribers then
        _data._subscribers[event] = {}
    end
    local token = #_data._subscribers[event] + 1
    _data._subscribers[event][token] = callback
    return { event = event, token = token }
end

function equipCollectData:Publish(event, data)
    if _data._subscribers[event] then
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
    --self:Publish("updateHHResult", {
    --    _dataForMount = self:GetDataForMount(),
    --    selectHHIndex = selectHHIndex
    --})
end

return equipCollectData
