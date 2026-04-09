-- itemReplace: 物品替换/随机替换配置模块
-- 功能: 根据配置随机替换物品

local itemReplace = {}

-- 加载配置
local ItemReplaceCfg = require("Envir/QuestDiary/game_config/cfgcsv/ItemReplace.lua")

--[[
    根据物品ID随机获取一个替换的物品
    
    配置格式：
    ItemReplaceCfg = {
        [物品ID] = {
            rate_arr = {概率1, 概率2, 概率3, ...},  -- 每组物品的获取概率
            itemList = {
                {"物品ID1#物品数量1", "物品ID2#物品数量2", ...},  -- 第1组物品列表
                {"物品ID3#物品数量3", "物品ID4#物品数量4", ...},  -- 第2组物品列表
                {"物品ID5#物品数量5", ...},  -- 第3组物品列表
                ...
            }
        }
    }
    
    @param itemId: 原始物品ID
    @return newItemId: 新物品ID, count: 数量。失败时返回nil, nil
    
    使用示例:
        local newItemId, count = itemReplace.getRandomItem(999)
        if newItemId then
            giveitem(actor, newItemId .. "#" .. count)
        end
]]
function itemReplace.getRandomItem(itemId)
    -- 检查配置是否存在该物品ID
    if not ItemReplaceCfg[itemId] then
        return nil, nil
    end
    
    local cfg = ItemReplaceCfg[itemId]
    local rate_arr = cfg.rate_arr or {}
    local itemList = cfg.itemList or {}
    
    -- 检查配置是否有效
    if #rate_arr == 0 or #itemList == 0 then
        return nil, nil
    end
    
    -- 计算总概率
    local totalRate = 0
    for i, rate in ipairs(rate_arr) do
        totalRate = totalRate + rate
    end
    
    -- 如果总概率为0，默认选择第一组
    if totalRate == 0 then
        local group = itemList[1]
        if group and #group > 0 then
            local randomIndex = math.random(1, #group)
            local itemStr = group[randomIndex]
            local id, num = string.match(itemStr, "(%d+)#(%d+)")
            if id and num then
                return tonumber(id), tonumber(num)
            end
        end
        return nil, nil
    end
    
    -- 基于概率随机选择一个物品组
    local randomValue = math.random(1, totalRate)
    local currentRate = 0
    local selectedGroupIdx = 1
    
    for i, rate in ipairs(rate_arr) do
        currentRate = currentRate + rate
        if randomValue <= currentRate then
            selectedGroupIdx = i
            break
        end
    end
    
    -- 从选中的物品组中随机选择一个物品
    local group = itemList[selectedGroupIdx]
    if not group or #group == 0 then
        return nil, nil
    end
    
    local randomIndex = math.random(1, #group)
    local itemStr = group[randomIndex]
    local id, num = string.match(itemStr, "(%d+)#(%d+)")
    
    if id and num then
        return tonumber(id), tonumber(num)
    end
    
    return nil, nil
end

--[[
    根据物品ID获取替换物品列表
    
    @param itemId: 原始物品ID
    @return table: 配置信息或nil {rate_arr, itemList}
]]
function itemReplace.getItemList(itemId)
    return ItemReplaceCfg[itemId]
end

--[[
    检查物品是否可以替换
    
    @param itemId: 原始物品ID
    @return boolean: 是否可以替换
]]
function itemReplace.canReplace(itemId)
    return ItemReplaceCfg[itemId] ~= nil
end

--[[
    批量替换物品
    
    @param actor: 玩家对象
    @param itemId: 原始物品ID
    @param count: 替换次数
    @return number: 实际替换次数
]]
function itemReplace.batchReplace(actor, itemId, count)
    if not itemReplace.canReplace(itemId) or count <= 0 then
        return 0
    end
    
    local successCount = 0
    for i = 1, count do
        local newId, newCount = itemReplace.getRandomItem(itemId)
        if newId then
            local emptySlots = bagnilcount(actor) or 0 
            if emptySlots > 0 then
                giveitem(actor, newId .. "#" .. newCount)
                successCount = successCount + 1
            else
                sendmsg(actor, 9, "背包空间不足,停止使用")
                break
            end            
        end
    end
    
    return successCount
end

return itemReplace