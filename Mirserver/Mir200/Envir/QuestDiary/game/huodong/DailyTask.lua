-- 每日必做系统
-- 活跃点任务和宝箱奖励
DailyTask = {}
local DailyTask_cfg = require("Envir/QuestDiary/game_config/cfgcsv/actPointDetail.lua")
local ActPointAward_cfg = require("Envir/QuestDiary/game_config/cfgcsv/actPointAward.lua")

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
    
    -- 发放奖励
    if cfg.awardList and #cfg.awardList > 0 then
        for _, award in ipairs(cfg.awardList) do
            giveitem(actor, award[1] .. "#" .. award[2])
        end
    end
    
    -- 标记为已领取
    
    sendmsg(actor, 9, "领取成功")
    DailyTask.checkRed(actor)
    DailyTask.sendDataToClient(actor)
end

-- 请求数据（客户端打开界面时调用）
function DailyTask.reqData(actor, data)
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

-- 注册消息
Message.RegisterNetMsg(ssrNetMsgCfg.DailyTask, DailyTask)

return DailyTask