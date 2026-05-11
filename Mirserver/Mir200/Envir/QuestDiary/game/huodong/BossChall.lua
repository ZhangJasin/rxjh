


BossChall = {}
local filname = "BossChall"
local SysConstant  =  require("Envir/QuestDiary/game_config/cfgcsv/SysConstant.lua")
local BossInfo_Cfg  =  require("Envir/QuestDiary/game_config/cfgcsv/BOSSInfo.lua")
local BossPool_Cfg  =  require("Envir/QuestDiary/game_config/cfgcsv/BOSSPool.lua")

-- BOSS挑战常量
local BOSS_MAP_ID = "230"                    -- 镜像副本地图编号
local BOSS_MAP_NAME = "狩猎场"
local BOSS_SAFE_POS_X = 365                  -- 泫勃派安全区X坐标
local BOSS_SAFE_POS_Y = 513                  -- 泫勃派安全区Y坐标
local BOSS_SAFE_MAP_ID = "101002"               -- 泫勃派地图ID (主城)

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

-- 保存每日挑战次数
local function _saveChalledCount(actor, count)
    sethumvar(actor, VarCfg.U_BOSS_Count, count)
end

-- 根据概率从BOSS列表中随机选择一个BOSS
local function _randomSelectBoss(bossList, excludeIds)
    if not bossList or #bossList == 0 then
        return nil
    end
    
    local totalProb = 0
    local availableBosses = {}
    for i, bossInfo in ipairs(bossList) do
        local bossId = bossInfo[1]
        local prob = bossInfo[2] or 0
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
    
    local randValue = math.random(1, totalProb)
    local cumulative = 0
    for _, bossInfo in ipairs(availableBosses) do
        cumulative = cumulative + bossInfo.prob
        if randValue <= cumulative then
            return bossInfo.id
        end
    end
    
    return availableBosses[#availableBosses].id
end

-- 根据玩家等级获取对应的BOSS池配置
local function _getBossPoolByLevel(playerLevel, job)
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
    
    local poolSize = tonumber(SysConstant['Boss_Chall_Num']["Value"]) or 8
    local poolConfig = _getBossPoolByLevel(curLv, job(actor))
    if not poolConfig then
        return
    end
    
    local bossData = {}
    local selectedIds = {}
    
    for i = 1, poolSize do
        local bossId = _randomSelectBoss(poolConfig, selectedIds)
        if bossId then
            table.insert(selectedIds, bossId)
            table.insert(bossData, {bossId, 0})
        else
            table.insert(bossData, {0, 0})
        end
    end
    
    _saveBossData(actor, bossData)
    BossChall.getData(actor)
end

-- 刷新BOSS列表（消耗刷新卷）
function BossChall.refresh(actor, data)     
    local index = tonumber(data[1]) or 0  
    local bossData = _getBossData(actor)
    if index >= 1 and index <= #bossData then
         -- 获取玩家等级职业对应的BOSS池配置
        local poolConfig = _getBossPoolByLevel(level(actor), job(actor))
        if not poolConfig then
            sendmsg(actor, 9, "BOSS配置异常")
            return
        end
            
        -- 检查刷新卷
        if not takeitem(actor, "刷新卷#1", 0) then
            sendmsg(actor, 9, "刷新卷不足")
            return
        end
        local currentBoss = {}
        for _, info in ipairs(bossData) do
            table.insert(currentBoss,info[1] or 0)
        end
        local newBossId = _randomSelectBoss(poolConfig, currentBoss)
        if newBossId then
            bossData[index] = {newBossId, 0}
            _saveBossData(actor, bossData)
            sendmsg(actor, 9, "刷新成功")
        else
            sendmsg(actor, 9, "刷新失败")
            return
        end
    else
        sendmsg(actor, 9, "无效的位置")
        return
    end
    
    BossChall.getData(actor)
end

-- 选BOSS挑战
function BossChall.chall(actor, data)   
    if targetinfo(actor, "MAPTITLE") == BOSS_MAP_NAME then
        sendmsg(actor, 9, "已在挑狩猎场中")
        return
    end
    local index = tonumber(data[1]) or 0
    -- 获取BOSS数据
    local bossData = _getBossData(actor)
    -- 检查位置有效性
    if index < 1 or index > #bossData then
        sendmsg(actor, 9, "无效的位置")
        return
    end
    
    local bossInfo = bossData[index]
    if not bossInfo or bossInfo[1] == 0 then
        sendmsg(actor, 9, "BOSS不存在")
        return
    end
    local bossCfg = BossInfo_Cfg[bossInfo[1]]
    if not bossCfg then
        sendmsg(actor, 9, "BOSS配置不存在")
        return
    end
    
    local bossId = bossInfo[1]
    local challCount = bossInfo[2] or 0
    
    -- 检查同一BOSS挑战次数限制
    local maxSingleBossCount = tonumber(SysConstant['Boss_Chall_Count']["Value"]) or 5
    if challCount >= maxSingleBossCount then
        sendmsg(actor, 9, "该BOSS今日挑战次数已达上限无法挑战，请挑战其他BOSS或使用刷新卷刷新该BOSS")
        return
    end
    
    -- 检查每日总挑战次数
    local dailyCount = _getChalledCount(actor)
    local maxDailyCount = tonumber(SysConstant['Boss_Day_MAX_Count']["Value"]) or 20
    if dailyCount >= maxDailyCount then
        sendmsg(actor, 9, "今日挑战次数已用完")
        return
    end
    
    -- 检查免费次数
    local freeCount = tonumber(SysConstant['Boss_Day_Free_Count']["Value"]) or 2
    local needToken = dailyCount >= freeCount
    
    local newMapId  = BOSS_MAP_ID .. userid(actor)  --新地图
    if checkmirrormap(newMapId) then        
        delmirrormap(newMapId)
    end
    
    -- 先保存需要的数据
    local challTime = tonumber(SysConstant['Boss_Chall_Time']["Value"]) or 300
    local saveData = {
        index = index,
        bossId = bossId,
        needToken = needToken,
        newMapId = newMapId,
        challTime = challTime,
        dailyCount = dailyCount,
    }
    sethumvar(actor, VarCfg.S_BossChall_Data, tbl2json(saveData))
    -- 延时创建镜像地图，避免返回FALSE
    gotolabel(actor, "@boss_chall", 100, 0, 0)
end

-- 创建镜像地图的延时处理函数
function BossChall.doCreateMirrorMap(actor)
    local saveDataStr = gethumvar(actor, VarCfg.S_BossChall_Data)
    if not saveDataStr or saveDataStr == "" then
        return
    end
    
    local saveData = json2tbl(saveDataStr)
    local newMapId = saveData.newMapId
    local challTime = saveData.challTime
    local needToken = saveData.needToken
    local index = saveData.index
    local bossId = saveData.bossId
    local dailyCount = saveData.dailyCount
    
    -- 创建镜像地图
    local result = addmirrormap(tostring(BOSS_MAP_ID), newMapId, BOSS_MAP_NAME, challTime, BOSS_SAFE_MAP_ID, 1, BOSS_SAFE_POS_X, BOSS_SAFE_POS_Y)
    if not result then
        sendmsg(actor, 9, "创建副本失败，稍后再试")
        return
    end
    
    if needToken then
        -- 需要消耗悬赏令
        if not takeitem(actor, "悬赏令#1", 0) then
            sendmsg(actor, 9, "悬赏令不足")
            delmirrormap(newMapId)
            return
        end
    end
    
    -- 更新BOSS挑战次数
    local bossData = _getBossData(actor)
    bossData[index][2] = (bossData[index][2] or 0) + 1
    _saveBossData(actor, bossData)
    
    -- 更新每日总挑战次数
    _saveChalledCount(actor, dailyCount + 1)
    
    --刷怪
    mongenex(newMapId, 34, 33, 1, Monster_cfg[bossId].Name, 1, -1, 0)
    -- 先移动再设置状态，避免触发地图切换检查
    mapmove(actor, newMapId,22,22,1) 
    -- 移动完成后再设置状态为挑战中
    sethumvar(actor, VarCfg.N_boss_state, 0)
    Message.sendmsg(actor, ssrNetMsgCfg.BOSSChall_Begin, challTime)
    
    -- 清理保存的数据
    sethumvar(actor, VarCfg.S_BossChall_Data, nil)
end


function BossChall.getData(actor)
    Message.sendmsg(actor, ssrNetMsgCfg.BOSSChall_RetData,_getChalledCount(actor),nil,nil,_getBossData(actor))
end

function BossChall.leaveChall(actor) 
    if targetinfo(actor, "MAPTITLE") == BOSS_MAP_NAME then
        mapmove(actor, BOSS_SAFE_MAP_ID, BOSS_SAFE_POS_X, BOSS_SAFE_POS_Y, 5)
        delmirrormap(targetinfo(actor, "NEWMAP"))    
    end
end

GameEvent.add(EventCfg.onResetday, function (actor)
    sethumvar(actor, VarCfg.U_BOSS_Count, 0)
    _refreshBossPool(actor)
end, BossChall)

GameEvent.add(EventCfg.onPlayLevelUp, function (actor, cur_level, before_level)
    local minLv = tonumber(SysConstant['Boss_Open_LV']["Value"]) or 35
    if before_level < minLv and cur_level >= minLv then
        _refreshBossPool(actor)
    end
end, BossChall)

GameEvent.add(EventCfg.goSwitchMap, function (actor, cur_mapid, former_mapid)         -- 切换地图触发
    local newMapId  = BOSS_MAP_ID .. userid(actor)  --新地图   
    if former_mapid == newMapId then
        if gethumvar(actor, VarCfg.N_boss_state) ~= 1 then            
            sendmsg(actor, 9, "当前BOSS挑战失败")
        end
        Message.sendmsg(actor, ssrNetMsgCfg.BOSSChall_Leave)
    end 
end, BossChall)

GameEvent.add(EventCfg.onKillMon, function (actor, mon, mapid, monidx)   
    local newMapId  = BOSS_MAP_ID .. userid(actor)  --新地图
    if newMapId == mapid and BossInfo_Cfg[monidx] then
        sethumvar(actor,VarCfg.N_boss_state,1)
        sendmsg(actor, 9, "当前BOSS挑战成功，狩猎场将于1分钟后关闭")
        local exitTime = tonumber(SysConstant['Boss_Chall_Exit_Time']["Value"]) or 60
        mirrormaptime(mapid,exitTime)
        Message.sendmsg(actor, ssrNetMsgCfg.BOSSChall_End, exitTime)
        --完成师徒任务
        MentorShipChangTask(actor, 11, "*", 1)
    end
end, BossChall)

Message.RegisterNetMsg(ssrNetMsgCfg.BOSSChall, BossChall)
return BossChall