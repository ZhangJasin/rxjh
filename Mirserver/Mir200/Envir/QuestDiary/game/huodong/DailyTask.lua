-- 每日必做系统
-- 活跃点任务和宝箱奖励
DailyTask = {}
local DailyTask_cfg = require("Envir/QuestDiary/game_config/cfgcsv/actPointDetail.lua")
local ActPointAward_cfg = require("Envir/QuestDiary/game_config/cfgcsv/actPointAward.lua")
local BossXS_Cfg  =  require("Envir/QuestDiary/game_config/cfgcsv/BOSSInfo.lua")

local YL_BASE_COUNT = 500000
local MON_BASE_COUNT = 500
local _taskType = {
    _guildexp       = 1,                -- 门派捐献
    _guildTask      = 2,                -- 门派任务
    _QH             = 3,                -- 装备强化
    _killBoss       = 4,                -- 击杀BOSS
    _buyshopping    = 5,                -- 购买商品
    _bossXS         = 6,                -- BOSS悬赏
    _ylcost         = 7,                -- 消耗银两50万
    _killmon        = 8,                -- 击杀怪物500个
}

-- 获取每日任务数据
function DailyTask.getData(actor)
    local taskData ={}
    for _, val in ipairs(DailyTask_cfg) do
        table.insert(taskData,gethumvar(actor,val.varName) or 0)
    end
    return taskData
end

-- 获取宝箱奖励领取状态
function DailyTask.getAwardFlag(actor)
    local awardData = {}
    for _, val in ipairs(ActPointAward_cfg) do
        table.insert(awardData,flag(actor,val.flag))
    end
    return awardData
end

-- 发送数据给客户端
function DailyTask.sendDataToClient(actor)
    local taskData = DailyTask.getData(actor)
    local awardData = DailyTask.getAwardFlag(actor)
    local activePoint = gethumvar(actor, VarCfg.U_MRBZ_Point) or 0
    Message.sendmsgEx(actor, "DailyTask", "UpdateData", {
        taskList = taskData,
        awardList = awardData,
        activePoint = activePoint,
    })
end

function DailyTask.sendAwardDataToClient(actor)
    local awardData = DailyTask.getAwardFlag(actor)
    Message.sendmsgEx(actor, "DailyTask", "UpdateAwardData", {
        awardList = awardData
    })
end


-- 领取活跃点宝箱奖励
function DailyTask.getPointAward(actor, data)
    local awardId = tonumber(data[1])
    local cfg = ActPointAward_cfg[awardId]
    if not cfg then
        sendmsg(actor, 9, "奖励配置不存在")
        return
    end
    local activePoint = gethumvar(actor, VarCfg.U_MRBZ_Point) or 0
    
    -- 检查活跃点是否足够
    if activePoint < cfg.point then
        sendmsg(actor, 9, "活跃点不足，需要" .. cfg.point .. "点")
        return
    end
        
    -- 检查是否已领取
    if check(actor,cfg.flag,1) then
        sendmsg(actor, 9, "该奖励已领取")
        return
    end
    
    -- 标记为已领取
    set(actor,cfg.flag,1)

    -- 发放奖励
    if cfg.award and #cfg.award > 1 then
        giveitem(actor, cfg.award[1] .. "#" .. cfg.award[2].. "#" .. ConstCfg.binding,1)
    end   
       
    sendmsg(actor, 9, "领取成功")
    DailyTask.checkRed(actor)
    DailyTask.sendAwardDataToClient(actor)
end

-- 请求数据（客户端打开界面时调用）
function DailyTask.reqData(actor)
    DailyTask.sendDataToClient(actor)
end

function DailyTask.checkRed(actor)
    local nRed = 0
    local activePoint = gethumvar(actor, VarCfg.U_MRBZ_Point) or 0
    for _, val in ipairs(ActPointAward_cfg) do
        if activePoint >= val.point and not check(actor,val.flag,1) then
            nRed = 1
            break
        end
    end
    sethumvar(actor, VarCfg.N_mrbz_red,nRed)
    Message.sendmsgEx(actor, "righttoppanl","mrbzRedUpdate",nRed)
end
-- 每日重置（每日零点调用）
local function _dailyReset(actor)
    -- 重置任务完成次数
    for _, val in ipairs(DailyTask_cfg) do
        sethumvar(actor,val.varName,0) 
    end    
    -- 重置宝箱领取状态
    for _, val in ipairs(ActPointAward_cfg) do
        set(actor,val.flag,0)
    end
    --重置活跃点、怪物数量、银两消耗
    sethumvar(actor, VarCfg.U_MRBZ_Point, 0)
    sethumvar(actor, VarCfg.U_MRBZ_Mon, 0)
    sethumvar(actor, VarCfg.U_MRBZ_YLXH, 0)
    sethumvar(actor, VarCfg.N_mrbz_red, 0)
    Message.sendmsgEx(actor, "righttoppanl","mrbzRedUpdate",0)
    -- 通知客户端
    DailyTask.sendDataToClient(actor)
end

GameEvent.add(EventCfg.onLoginEnd, function (actor)
    DailyTask.checkRed(actor)
end, DailyTask)

GameEvent.add(EventCfg.onResetday, function (actor)
    _dailyReset(actor)
end, DailyTask)

local function _onKill_Mon(actor)
    local cfg = DailyTask_cfg[_taskType._killmon]
    if not cfg or not cfg.varName then
        return
    end
    local limitTimes = cfg.limitTimes or 0
    local curTimes = gethumvar(actor,cfg.varName) or 0
    if curTimes >= limitTimes then
        return
    end
    local curMonCount = gethumvar(actor,VarCfg.U_MRBZ_Mon) or 0
    local nextCount = curMonCount + 1
    local addPoint = 0
    if nextCount >= MON_BASE_COUNT then
        nextCount = 0
        addPoint = cfg.point or 0
    end
    sethumvar(actor,VarCfg.U_MRBZ_Mon,nextCount)
    if addPoint > 0 then
        sethumvar(actor,cfg.varName,curTimes + 1)

        local curPoint = gethumvar(actor,VarCfg.U_MRBZ_Point) or 0
        sethumvar(actor,VarCfg.U_MRBZ_Point,curPoint + addPoint)
        sendmsg(actor, 9, string.format("击杀怪物达到500只，获得%d点活跃",addPoint))

        DailyTask.sendDataToClient(actor)
        DailyTask.checkRed(actor)
    end
end
local function _onKill_bossxs(actor,monidx)
    if not BossXS_Cfg[monidx] then
        return
    end
    local cfg = DailyTask_cfg[_taskType._bossXS]
    if not cfg or not cfg.varName then
        return
    end
    local limitTimes = cfg.limitTimes or 0
    local curTimes = gethumvar(actor,cfg.varName) or 0
    if curTimes >= limitTimes then
        return
    end
    local addPoint = cfg.point or 0
    if addPoint > 0 then
        sethumvar(actor,cfg.varName,curTimes + 1)
        
        local curPoint = gethumvar(actor,VarCfg.U_MRBZ_Point) or 0
        sethumvar(actor,VarCfg.U_MRBZ_Point,curPoint + addPoint)
        sendmsg(actor, 9, string.format("挑战BOSS，获得%d点活跃",addPoint))

        DailyTask.sendDataToClient(actor)
        DailyTask.checkRed(actor)
    end
end
local function _onKill_boss(actor,monidx)
    local monType = Monster_cfg[monidx].BossSign or 0
    if monType ~= 3 then
        return
    end
    local cfg = DailyTask_cfg[_taskType._killBoss]
    if not cfg or not cfg.varName then
        return
    end
    local limitTimes = cfg.limitTimes or 0
    local curTimes = gethumvar(actor,cfg.varName) or 0
    if curTimes >= limitTimes then
        return
    end
    local addPoint = cfg.point or 0
    if addPoint > 0 then
        sethumvar(actor,cfg.varName,curTimes + 1)

        local curPoint = gethumvar(actor,VarCfg.U_MRBZ_Point) or 0
        sethumvar(actor,VarCfg.U_MRBZ_Point,curPoint + addPoint)
        sendmsg(actor, 9, string.format("击杀BOSS，获得%d点活跃",addPoint))

        DailyTask.sendDataToClient(actor)
        DailyTask.checkRed(actor)
    end
end
local function _onKillMon(actor, mon, mapid, monidx)   
    _onKill_Mon(actor)
    _onKill_boss(actor,monidx)
    _onKill_bossxs(actor,monidx)   
end
GameEvent.add(EventCfg.onKillMon, function (actor, mon, mapid, monidx)                 -- 怪物死亡触发
    _onKillMon(actor, mon, mapid, monidx)
end, DailyTask)

local function _onQiangHua(actor, isQH)
    if not isQH then
        return
    end
    local cfg = DailyTask_cfg[_taskType._QH]
    if not cfg or not cfg.varName then
        return
    end
    local limitTimes = cfg.limitTimes or 0
    local curTimes = gethumvar(actor,cfg.varName) or 0
    if curTimes >= limitTimes then
        return
    end
    local addPoint = cfg.point or 0
    if addPoint > 0 then
        sethumvar(actor,cfg.varName,curTimes + 1)

        local curPoint = gethumvar(actor,VarCfg.U_MRBZ_Point) or 0
        sethumvar(actor,VarCfg.U_MRBZ_Point,curPoint + addPoint)
        sendmsg(actor, 9, string.format("装备强化，获得%d点活跃",addPoint))

        DailyTask.sendDataToClient(actor)
        DailyTask.checkRed(actor)
    end
end
GameEvent.add(EventCfg.onQiangHua, function (actor,isQH)         -- 强化功能触发  强化次数要求
    _onQiangHua(actor,isQH)
end, DailyTask)

local function _onBuyItem(actor,itemId,itemCount)
    local cfg = DailyTask_cfg[_taskType._buyshopping]
    if not cfg or not cfg.varName then
        return
    end
    local limitTimes = cfg.limitTimes or 0
    local curTimes = gethumvar(actor,cfg.varName) or 0
    if curTimes >= limitTimes then
        return
    end
    local addPoint = cfg.point or 0
    if addPoint > 0 then
        sethumvar(actor,cfg.varName,curTimes + 1)

        local curPoint = gethumvar(actor,VarCfg.U_MRBZ_Point) or 0
        sethumvar(actor,VarCfg.U_MRBZ_Point,curPoint + addPoint)
        sendmsg(actor, 9, string.format("商城购买，获得%d点活跃",addPoint))

        DailyTask.sendDataToClient(actor)
        DailyTask.checkRed(actor)
    end
end
GameEvent.add(EventCfg.onBuyShopItem, function (actor,itemId,num)
    _onBuyItem(actor,itemId,num)
end, DailyTask)

local function _onGuildTask(actor)
    local cfg = DailyTask_cfg[_taskType._guildTask]
    if not cfg or not cfg.varName then
        return
    end
    local limitTimes = cfg.limitTimes or 0
    local curTimes = gethumvar(actor,cfg.varName) or 0
    if curTimes >= limitTimes then
        return
    end
    local addPoint = cfg.point or 0
    if addPoint > 0 then
        sethumvar(actor,cfg.varName,curTimes + 1)

        local curPoint = gethumvar(actor,VarCfg.U_MRBZ_Point) or 0
        sethumvar(actor,VarCfg.U_MRBZ_Point,curPoint + addPoint)
        sendmsg(actor, 9, string.format("完成门派任务，获得%d点活跃",addPoint))

        DailyTask.sendDataToClient(actor)
        DailyTask.checkRed(actor)
    end
end

GameEvent.add(EventCfg.onGuildTask, function (actor)
    _onGuildTask(actor)
end, DailyTask)

local function _onGuildsetexp(actor)
    local cfg = DailyTask_cfg[_taskType._guildexp]
    if not cfg or not cfg.varName then
        return
    end
    local limitTimes = cfg.limitTimes or 0
    local curTimes = gethumvar(actor,cfg.varName) or 0
    if curTimes >= limitTimes then
        return
    end
    local addPoint = cfg.point or 0
    if addPoint > 0 then
        sethumvar(actor,cfg.varName,curTimes + 1)

        local curPoint = gethumvar(actor,VarCfg.U_MRBZ_Point) or 0
        sethumvar(actor,VarCfg.U_MRBZ_Point,curPoint + addPoint)
        sendmsg(actor, 9, string.format("门派捐献，获得%d点活跃",addPoint))

        DailyTask.sendDataToClient(actor)
        DailyTask.checkRed(actor)
    end
end

GameEvent.add(EventCfg.onGuildsetexp, function (actor, type, addzj)         -- 强化功能触发  强化次数要求
    _onGuildsetexp(actor)
end, DailyTask)

local function _onChangeYL(actor,lastCount)
    local curCount = money(actor, 1)
    if curCount >= lastCount then
        return
    end
    --银两消耗 1次
    local cfg = DailyTask_cfg[_taskType._ylcost]
    if not cfg or not cfg.varName then
        return
    end
    local limitTimes = cfg.limitTimes or 0
    local curTimes = gethumvar(actor,cfg.varName) or 0
    if curTimes >= limitTimes then
        return
    end

    local cost = curCount - lastCount
    local curCost = gethumvar(actor,VarCfg.U_MRBZ_YLXH) or 0
    local nextCost = curCost + cost
    local addPoint = 0
    if nextCost >= YL_BASE_COUNT then
        nextCost = 0
        addPoint = cfg.point or 0
    end
    sethumvar(actor,VarCfg.U_MRBZ_YLXH,nextCost)
    if addPoint > 0 then
        sethumvar(actor,cfg.varName,curTimes + 1)

        local curPoint = gethumvar(actor,VarCfg.U_MRBZ_Point) or 0
        sethumvar(actor,VarCfg.U_MRBZ_Point,curPoint + addPoint)
        sendmsg(actor, 9, string.format("银两消耗达到50W，获得%d点活跃",addPoint))

        DailyTask.sendDataToClient(actor)
        DailyTask.checkRed(actor)
    end
end
GameEvent.add(EventCfg.onChangeMoney, function (actor, moneyID, lastCount)   -- 气功点改变
    if moneyID ~= 1 then
        return
    end
    _onChangeYL(actor,lastCount)
end, DailyTask)

-- 注册消息
Message.RegisterNetMsg(ssrNetMsgCfg.DailyTask, DailyTask)

return DailyTask