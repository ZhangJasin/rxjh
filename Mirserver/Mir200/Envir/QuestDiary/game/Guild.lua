
Guild = {}
local filname = "Guild"
-- function Guild.buy(actor,data)
--     local num = money(actor, 20)
--     local total = tonumber(data.count) * tonumber(data.price)
--     if num < total then 
--         return sendmsg(actor,9,"门派贡献不足")
--     end
--     delItemNum(actor,20,total)
--     local itemJson = {}
--     itemJson[tonumber(data.Itemid)]= tonumber(data.count) 
--     giveItmeByList(actor,itemJson)
--     sendmsg(actor,9,"购买成功")
--     Message.sendmsgEx(actor, "GuildMainPanel","UpdataPage2")
-- end

function Guild.getData(actor)
    local gxCount = gethumvar(actor, VarCfg.U_Donate_Num) or 0
    local taskCount = gethumvar(actor, VarCfg.U_REWARD_FINISH) or 0
    local freeCount = gethumvar(actor, VarCfg.U_REWARD_REFUSH) or 0
    local taskId = 103145--gethumvar(actor, VarCfg.U_REWARD_INDEX) or 0
    local taskState= gethumvar(actor, VarCfg.U_REWARD_STATE) or 0

    Message.sendmsg(actor, ssrNetMsgCfg.Guild_RetData,  gxCount,taskCount,freeCount,{taskid=taskId,state=taskState })
end
local function _onRefreshTask(actor)
end

local function _onDelTask(actor)
    local curTaskId = gethumvar(actor, VarCfg.U_REWARD_INDEX) or 0
    if curTaskId > 0 then
        local curTaskData = Task.getCurTask(actor)
        if curTaskData[""..curTaskId] then
            curTaskData[""..curTaskId] = nil
            newdeletetask(actor, curTaskId)
            sethumvar(actor, VarCfg.T_TaskProgress_data, tbl2json(curTaskData))
            Message.sendmsgEx(actor, "MainMission", "UpdataTask", {param1 = curTaskData})
        end
        sethumvar(actor, VarCfg.U_REWARD_REFUSH, 0)
        sethumvar(actor, VarCfg.U_REWARD_STATE, 0)
    end    
end

function Guild.pickTask(actor)
    Guild.getData(actor)
end

function Guild.compTask(actor)
    Guild.getData(actor)
end

function Guild.abortTask(actor)
    Guild.getData(actor)
end

function Guild.refreshTask(actor)
    Guild.getData(actor)
end

function Guild.subTask(actor,mid)
    Guild.getData(actor)
end


local function _onreset(actor)
    sethumvar(actor, VarCfg.U_Donate_Num, 0) -- 跨天清除门派每日已捐献次数
    sethumvar(actor, VarCfg.U_REWARD_FINISH, 0) -- 门派任务已完成次数
    sethumvar(actor, VarCfg.U_REWARD_REFUSH, 0) -- 门派任务免费刷新次数

    _onDelTask(actor)
    _onRefreshTask(actor)
end
GameEvent.add(EventCfg.onResetday, function (actor)
    _onreset(actor)
end, Guild)

GameEvent.add(EventCfg.onCreateguild, function (actor)
    _onRefreshTask(actor)
end, Guild)
GameEvent.add(EventCfg.onGuildaddmemberafter, function (actor)
    _onRefreshTask(actor)
end, Guild)

GameEvent.add(EventCfg.onGuilddelmember, function (actor)
    _onDelTask(actor)
end, Guild)
GameEvent.add(EventCfg.onGuildclosebefore, function (actor)
    _onDelTask(actor)
end, Guild)
Message.RegisterNetMsg(ssrNetMsgCfg.Guild, Guild)
return Guild