

BossChall = {}
local filname = "BossChall"
local SysConstant  =  require("Envir/QuestDiary/game_config/cfgcsv/SysConstant.lua")
local BossInfo_Cfg  =  require("Envir/QuestDiary/game_config/cfgcsv/BOSSInfo.lua")
local BossPool_Cfg  =  require("Envir/QuestDiary/game_config/cfgcsv/BOSSPool.lua")


-- 获取玩家BOSS池数据
local function _getBossData(actor)
    local data = gethumvar(actor, VarCfg.T_BossData)
    if data and data ~= "" then
        local ok, result = pcall(json2tbl, data)
        if ok and result then
            return result
        end
    end
    return {}
end

-- 保存玩家BOSS池数据
local function _saveBossData(actor, bossData)
    sethumvar(actor, VarCfg.T_BossData, tbl2json(bossData))
end

-- 获取每日挑战次数
local function _getChalledCount(actor)
    return gethumvar(actor, VarCfg.U_BOSS_Count) or 0
end

-- 根据概率从BOSS列表中随机选择一个BOSS
-- @param bossList BOSS列表，格式: {{bossId, probability}, ...}
-- @param excludeIds 需要排除的BOSS ID列表
-- @return 选中的BOSS ID，未选中返回nil
local function _randomSelectBoss(bossList, excludeIds)
    if not bossList or #bossList == 0 then
        return nil
    end
    
    -- 计算总概率
    local totalProb = 0
    local availableBosses = {}
    for i, bossInfo in ipairs(bossList) do
        local bossId = bossInfo[1]
        local prob = bossInfo[2] or 0
        -- 跳过已排除的BOSS
        local isExclude = false
        if excludeIds then
            for _, excludeId in ipairs(excludeIds) do
                if excludeId == bossId then
                    isExclude = true
                    break
                end
            end
        end
        if not isExclude then
            totalProb = totalProb + prob
            table.insert(availableBosses, {id = bossId, prob = prob, index = i})
        end
    end
    
    if #availableBosses == 0 then
        return nil
    end
    
    -- 随机抽取
    local randValue = math.random(1, totalProb)
    local cumulative = 0
    for _, bossInfo in ipairs(availableBosses) do
        cumulative = cumulative + bossInfo.prob
        if randValue <= cumulative then
            return bossInfo.id
        end
    end
    
    -- 防止概率计算误差，返回最后一个
    return availableBosses[#availableBosses].id
end

-- 根据玩家等级获取对应的BOSS池配置
-- @param playerLevel 玩家等级
-- @return BOSS池配置，未找到返回nil
local function _getBossPoolByLevel(playerLevel,job)
    if not playerLevel or not job then
        return nil
    end
    for _, poolConfig in pairs(BossPool_Cfg) do
        local minLv = poolConfig.minLv or 0
        local maxLv = poolConfig.maxLv or 999999
        if playerLevel >= minLv and playerLevel <= maxLv then
            return poolConfig["bossList"..job]
        end
    end
    
    return nil
end

-- 刷新玩家BOSS池
local function _refreshBossPool(actor)
    local minLv = tonumber(SysConstant['Boss_Open_LV']["Value"]) or 35
    local curLv = level(actor)
    if curLv < minLv then 
        return 
    end
    
    -- 获取BOSS池数量
    local poolSize = tonumber(SysConstant['Boss_Chall_Num']["Value"]) or 8
    
    -- 获取玩家等级对应的BOSS池配置
    local poolConfig = _getBossPoolByLevel(curLv,job(actor))
    if not poolConfig then
        return
    end
    -- 根据概率随机抽取BOSS
    local bossData = {}
    local selectedIds = {}
    
    for i = 1, poolSize do
        local bossId = _randomSelectBoss(poolConfig, selectedIds)
        if bossId then
            table.insert(selectedIds, bossId)
            -- BOSS数据结构: {BOSSID, 已挑战次数}
            table.insert(bossData, {bossId, 0})
        else
            -- BOSS池配置不足，填充空数据
            table.insert(bossData, {0, 0})
        end
    end
    -- 保存到玩家变量
    _saveBossData(actor, bossData)
    
    -- 发送数据给客户端
    BossChall.getData(actor)
end

function BossChall.chall(actor,data)
    local index = tonumber(data[1]) or 0
end

function BossChall.refresh(actor,data)
    local index = tonumber(data[1]) or 0

end

function BossChall.getData(actor)
    Message.sendmsg(actor, ssrNetMsgCfg.BOSSChall_RetData,_getChalledCount(actor),nil,nil,_getBossData(actor))
end

GameEvent.add(EventCfg.onResetday, function (actor)
    sethumvar(actor, VarCfg.U_BOSS_Count, 0)
    _refreshBossPool(actor)
end, BossChall)
GameEvent.add(EventCfg.onPlayLevelUp, function (actor, cur_level, before_level)         -- 升级触发
    local minLv = tonumber(SysConstant['Boss_Open_LV']["Value"]) or 35
    if before_level < minLv and cur_level >= minLv then
        _refreshBossPool(actor)
    end
end, BossChall)

Message.RegisterNetMsg(ssrNetMsgCfg.BOSSChall, BossChall)
return BossChall