-- 合成系统处理模块
Compound = {}

-- 配置表
local compItems = require('Envir/QuestDiary/game_config/cfgcsv/compItems')

-- 限流控制：记录每个玩家最后一次请求时间（毫秒）
-- 使用 actor 本身作为表的 key
local _lastRequestTime = {}

-- 检查限流，返回true表示允许执行
local function checkThrottle(actor)
    local now = os.time() * 1000  -- 毫秒
    local lastTime = _lastRequestTime[actor] or 0

    if now - lastTime < 1000 then  -- 每秒最多1次
        return false
    end

    _lastRequestTime[actor] = now
    return true
end

-- 打开合成界面
function Compound.openshow(actor)
    Message.sendmsgEx(actor, 'Compound', 'Open', {})
end

-- 合成处理（对应客户端 sendmsgEx 的 methodName）
-- data: {itemId, isBatch}
function Compound.compound(actor, data)
    -- 限流控制：每秒最多执行1次
    if not checkThrottle(actor) then
        sendmsg(actor, 9, '请勿频繁操作')
        return
    end

    if not data then
        sendmsg(actor, 9, '参数错误')
        return
    end

    local itemId = tonumber(data[1])
    local isBatch = tonumber(data[2]) or 0

    if not itemId then
        sendmsg(actor, 9, '合成参数错误')
        return
    end

    -- 查找配置
    local config = nil
    for k, v in pairs(compItems) do
        if v.itemId == itemId then
            config = v
            break
        end
    end

    if not config then
        sendmsg(actor, 9, '找不到合成配置')
        return
    end

    -- 解析消耗道具
    local payItems = parsePayData(config.payItems)
    local payCost = parsePayData(config.payCost)

    -- 解析成功率（配置中是 succRealRate 字段，格式 n/10000）
    local succRealRate = tonumber(config.succRealRate)
    if not succRealRate then
        sendmsg(actor, 9, '配置错误')
        return
    end

    -- 计算合成次数
    local compoundCount = 1
    if isBatch > 0 and config.isBatch and config.isBatch > 0 then
        compoundCount = config.isBatch
    end

    -- 计算总消耗
    local totalPayItems = {}
    for _, item in ipairs(payItems) do
        table.insert(totalPayItems, {id = item.id, count = item.count * compoundCount})
    end

    local totalPayCost = {}
    for _, cost in ipairs(payCost) do
        table.insert(totalPayCost, {id = cost.id, count = cost.count * compoundCount})
    end

    -- 1. 道具检查 (使用 getItemNum 检查数量)
    for _, item in ipairs(totalPayItems) do
        local haveCount = getItemNum(actor, item.id)
        if haveCount < item.count then
            sendmsg(actor, 9, '道具不足')
            return
        end
    end

    -- 2. 货币检查 (使用 money 函数检查数量)
    for _, cost in ipairs(totalPayCost) do
        -- 只支持货币ID 1(银两) 和 2(元宝)
        if cost.id ~= 1 and cost.id ~= 2 then
            sendmsg(actor, 9, string.format('不支持的货币类型(ID:%d)', cost.id))
            return
        end

        local haveCount = money(actor, cost.id)
        if haveCount < cost.count then
            sendmsg(actor, 9, '货币不足')
            return
        end
    end

    -- 3. 成功率判断（每次合成独立判断）
    local successCount = 0
    local failCount = 0

    for i = 1, compoundCount do
        local roll = math.random(1, 10000)

        if roll <= succRealRate then
            successCount = successCount + 1
        else
            failCount = failCount + 1
        end
    end

    if successCount == 0 then
        sendmsg(actor, 9, '合成失败！')
        Message.sendmsgEx(actor, 'Compound', 'Result', {0, itemId, '合成失败'})
        return
    end

    -- 4. 执行合成 - 扣除道具
    for _, item in ipairs(totalPayItems) do
        local itemStr = item.id .. "#" .. item.count
        takeitem(actor, itemStr, 0)
    end

    -- 5. 执行合成 - 扣除货币
    for _, cost in ipairs(totalPayCost) do
        changemoney(actor, cost.id, '-', cost.count)
    end

    -- 6. 执行合成 - 添加目标物品
    local giveStr = itemId .. "#" .. successCount
    giveitem(actor, giveStr, 0)

    -- 打印合成日志
    print(string.format('[合成日志] 玩家:%s, 物品ID:%d, 批量次数:%d, 成功:%d, 失败:%d',
        getname(actor), itemId, compoundCount, successCount, failCount))

    -- 7. 发送成功响应
    Message.sendmsgEx(actor, 'Compound', 'Result', {1, itemId, successCount, '合成成功'})
    if compoundCount > 1 then
        sendmsg(actor, 9, string.format('合成完成！成功%d次，失败%d次', successCount, failCount))
    else
        sendmsg(actor, 9, '合成成功！')
    end
end

-- 解析消耗数据
function parsePayData(payStr)
    local result = {}
    if not payStr or payStr == '' then
        return result
    end

    local items = splitString(payStr, '|')
    for _, item in ipairs(items) do
        local parts = splitString(item, '#')
        local id = tonumber(parts[1]) or 0
        local count = tonumber(parts[2]) or 0
        if id > 0 and count > 0 then
            table.insert(result, {id = id, count = count})
        end
    end
    return result
end

-- 字符串分割函数
function splitString(str, delimiter)
    local result = {}
    local from = 1
    local delim_start, delim_end = string.find(str, delimiter, from)
    while delim_start do
        table.insert(result, string.sub(str, from, delim_start - 1))
        from = delim_end + 1
        delim_start, delim_end = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

-- 注册网络消息（Message 和 ssrNetMsgCfg 已经是全局变量）
Message.RegisterNetMsg(ssrNetMsgCfg.Compound, Compound)

return Compound
