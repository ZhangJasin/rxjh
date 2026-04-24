

Guild = {}
local filname = "Guild"
local Task_cfg  =  require("Envir/QuestDiary/game_config/cfgcsv/Task.lua")
local TaskPool_cfg  =  require("Envir/QuestDiary/game_config/cfgcsv/guildTaskPool.lua")

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

local function _getCurTaskJinDu(actor,taskId)
    local taskDataList = Task.getCurTask(actor)
    local curTaskData = taskDataList[""..taskId] 
    if curTaskData then
        return curTaskData['count'] or 0
    end
    return 0
end
function Guild.getData(actor)
    local gxCount = gethumvar(actor, VarCfg.U_Donate_Num) or 0
    local taskCount = gethumvar(actor, VarCfg.U_REWARD_FINISH) or 0
    local freeCount = gethumvar(actor, VarCfg.U_REWARD_REFUSH) or 0
    local taskId = 103145--gethumvar(actor, VarCfg.U_REWARD_INDEX) or 0
    local taskState= gethumvar(actor, VarCfg.U_REWARD_STATE) or 0
    local curJindu = _getCurTaskJinDu(actor,taskId)

    Message.sendmsg(actor, ssrNetMsgCfg.Guild_RetData,  gxCount,taskCount,freeCount,{taskid=taskId,state=taskState,jindu=curJindu })
end


-- 根据玩家等级从任务池中随机获取任务
local function _getRandomGuildTask(zy,lv)
    -- 根据玩家等级获取对应的任务池配置
    local taskPool = nil
    for _, pool in pairs(TaskPool_cfg or {}) do
        if lv >= (pool.minLv or 0) and lv <= (pool.maxLv or 999) then
            taskPool = pool
            break
        end
    end
    
    if not taskPool then
        -- 默认使用第一个任务池
        taskPool = TaskPool_cfg[1]
    end
    
    if not taskPool then
        return nil
    end
    
    -- 根据概率随机选择星级
    local rate_arr = taskPool.rate_arr or {}
    local totalRate = 0
    for _, rate in pairs(rate_arr) do
        totalRate = totalRate + rate
    end
    
    local randValue = math.random(1, totalRate)
    local curRate = 0
    local starIndex = 1
    for i, rate in ipairs(rate_arr) do
        curRate = curRate + rate
        if randValue <= curRate then
            starIndex = i
            break
        end
    end
    
    -- 根据星级获取任务列表  
    local taskList = zy == 2 and taskPool.taskList2[starIndex] or taskPool.taskList1[starIndex]
    if not taskList or #taskList == 0 then
        return nil
    end
    
    -- 随机选择一个任务
    local taskIndex = math.random(1, #taskList)
    return taskList[taskIndex]
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
        sethumvar(actor, VarCfg.U_REWARD_INDEX, 0)
        sethumvar(actor, VarCfg.U_REWARD_STATE, 0)
    end    
end

local function _onRefreshTask(actor)
    local guildId = targetinfo(actor, "GUILDID") or 0
    local zy = targetinfo(actor, "GOODEVILID")
    if guildId ~= 0 and zy ~= 0 then
        local level = level(actor)        
        local newTaskId = _getRandomGuildTask(zy,level) or 0
        sethumvar(actor, VarCfg.U_REWARD_INDEX, newTaskId)
        sethumvar(actor, VarCfg.U_REWARD_STATE, 0)
    end    
end

function Guild.updateTask(actor,taskid)
    local guildId = targetinfo(actor, "GUILDID") or 0
    if guildId == 0 then
        return
    end
    local curTaskId = gethumvar(actor, VarCfg.U_REWARD_INDEX) or 0
    if curTaskId ~= taskid then
        return
    end
    local TaskProgress_data = Task.getCurTask(actor)
    local state =  0
    if TaskProgress_data[""..taskid] then
        state = TaskProgress_data[""..taskid]['state']
    end
    if state == 2 then 
       TaskProgress_data[""..taskid] = nil
       newdeletetask(actor, taskid)
       sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  
       Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})  

       if Task_cfg[taskid]['task_drop'] then           
            Player.giveItemByJobTable(actor, Task_cfg[taskid]['task_drop'], 1, 1)
       end

       --更新任务次数，刷新任务
       local taskCount = gethumvar(actor, VarCfg.U_REWARD_FINISH) or 0
       taskCount = taskCount + 1
       sethumvar(actor, VarCfg.U_REWARD_FINISH, taskCount)
       local allCount = tonumber(SysConstant['Num_Daily_RewardTask']["Value"]) or 10
       if taskCount < allCount then
            _onRefreshTask(actor)
       end

       Guild.getData(actor)

       GameEvent.push(EventCfg.onGuildTask, actor)
    end
end

function Guild.pickTask(actor)
    local guildId = targetinfo(actor, "GUILDID") or 0
    if guildId == 0 then
        sendmsg(actor, 9, "您还没有加入门派，无法接取门派任务")
        return
    end
        
    local finishCount = gethumvar(actor, VarCfg.U_REWARD_FINISH) or 0
    local maxCount = tonumber(SysConstant['Num_Daily_RewardTask']["Value"]) or 10
    if finishCount >= maxCount then
        sendmsg(actor, 9, "今日门派任务次数已用完，请明天再来")
        return
    end

    local taskState = gethumvar(actor, VarCfg.U_REWARD_STATE) or 0
    if taskState == 1 then
        sendmsg(actor, 9, "您已接取了门派任务，请先完成或放弃当前任务")
        return
    end 
    
    local taskId = gethumvar(actor, VarCfg.U_REWARD_INDEX) or 0
    if not Task_cfg[taskId] then
        sendmsg(actor, 9, "获取任务失败，请稍后重试")
        return
    end

    sethumvar(actor, VarCfg.U_REWARD_STATE, 1) 
    
    local curTaskData = Task.getCurTask(actor)
    curTaskData[""..taskId] = {count = 0, state = 1}
    sethumvar(actor, VarCfg.T_TaskProgress_data, tbl2json(curTaskData))
    newpicktask(actor, taskId,0)
    Message.sendmsgEx(actor, "MainMission", "UpdataTask", {param1 = curTaskData})
    
    sendmsg(actor, 9, "接取门派任务成功")
    Guild.getData(actor)
end

function Guild.compTask(actor,data)
    local guildId = targetinfo(actor, "GUILDID") or 0
    if guildId == 0 then
        sendmsg(actor, 9, "您还没有加入门派，无法完成门派任务")
        return
    end
   
	local taskState = gethumvar(actor, VarCfg.U_REWARD_STATE) or 0
	if taskState ~= 1 then
		sendmsg(actor, 9, "您还没有接取任务")
		return
	end

    local finishCount = gethumvar(actor, VarCfg.U_REWARD_FINISH) or 0
    local maxCount = tonumber(SysConstant['Num_Daily_RewardTask']["Value"]) or 10
    if finishCount >= maxCount then
        sendmsg(actor, 9, "今日门派任务次数已用完")
        return
    end

	-- 检查任务是否已完成
    local curTaskId = gethumvar(actor, VarCfg.U_REWARD_INDEX) or 0
	local TaskProgress_data = Task.getCurTask(actor)
	local curTaskData = TaskProgress_data[""..curTaskId]
	if not curTaskData then
		sendmsg(actor, 9, "任务数据异常")
		return
	end
    local nType = tonumber(data[1] or 0)
	if nType == 1 and curTaskData['state'] ~= 2 then
		-- 快速完成任务，消耗1个悬赏令
		local result = takeitem(actor, "悬赏令#1", 0)
        if not result then
            sendmsg(actor, 9, "您没有悬赏令，无法快速完成")
            return
        end

		-- 直接完成任务
		TaskProgress_data[""..curTaskId]['state'] = 2
        sethumvar(actor, VarCfg.T_TaskProgress_data, tbl2json(TaskProgress_data))

        Guild.updateTask(actor,curTaskId)
	else
		-- 正常完成任务，需要任务已完成
		if curTaskData['state'] ~= 2 then
			sendmsg(actor, 9, "任务尚未完成，请先完成任务")
			return
		end

		Guild.updateTask(actor,curTaskId)		
	end
	Guild.getData(actor)
    sendmsg(actor, 9, "任务已完成，请注意查收奖励")
end

function Guild.abortTask(actor)
    local curTimes = gethumvar(actor, VarCfg.U_REWARD_FINISH) or 0
    local maxTimes = tonumber(SysConstant['Num_Daily_RewardTask']["Value"]) or 10
    if curTimes >= maxTimes then
        return
    end
    local curState = gethumvar(actor, VarCfg.U_REWARD_STATE) or 0
    if curState ~= 1 then
        sendmsg(actor, 9, "还未接取任务！！！")
        return
    end
    local curTaskId = gethumvar(actor, VarCfg.U_REWARD_INDEX) or 0
    local taskData = Task.getCurTask(actor)
    local curTaskData = taskData[""..curTaskId]
    if not curTaskData then
        sendmsg(actor, 9, "还未接取任务！！！")
        return
    end
    sethumvar(actor, VarCfg.U_REWARD_FINISH, curTimes + 1)
    sethumvar(actor, VarCfg.U_REWARD_INDEX, 0)
    sethumvar(actor, VarCfg.U_REWARD_STATE, 0)

    taskData[""..curTaskId] = nil
    newdeletetask(actor, curTaskId)
    sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(taskData))  
    Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = curTaskId}) 
    
    _onRefreshTask(actor)
    Guild.getData(actor)
    sendmsg(actor, 9, "门派任务已刷新")
end

function Guild.refreshTask(actor)
    local guildId = targetinfo(actor, "GUILDID") or 0
    if guildId == 0 then
        sendmsg(actor, 9, "您还没有加入门派，无法刷新任务")
        return
    end

    local taskState = gethumvar(actor, VarCfg.U_REWARD_STATE) or 0
    if taskState == 1 then
        sendmsg(actor, 9, "任务已接取，无法刷新")
        return
    end

    -- 获取当前刷新次数和最大免费次数
    local curRefushCount = gethumvar(actor, VarCfg.U_REWARD_REFUSH) or 0
    local maxFreeCount = tonumber(SysConstant['Num_DailyRefresh_RewardTask']["Value"]) or 3

    if curRefushCount >= maxFreeCount then
        -- 免费次数已用完，检查是否有用任务刷新卷轴    
        local result = takeitem(actor, "任务刷新卷#1", 0)
        if not result then
            sendmsg(actor, 9, "免费刷新次数已用完，没有任务刷新卷，刷新失败")
            return
        end
    else
        -- 使用免费刷新次数
        sethumvar(actor, VarCfg.U_REWARD_REFUSH, curRefushCount + 1)
    end

    -- 刷新任务
    _onRefreshTask(actor)
    Guild.getData(actor)
    sendmsg(actor, 9, "门派任务已刷新")
end

function Guild.subTask(actor,mid)
    local guildId = targetinfo(actor, "GUILDID") or 0
    if guildId == 0 then
        sendmsg(actor, 9, "您还没有加入门派")
        return
    end
    local taskState = gethumvar(actor, VarCfg.U_REWARD_STATE) or 0
	if taskState ~= 1 then
		sendmsg(actor, 9, "您还没有接取任务")
		return
	end
    local finishCount = gethumvar(actor, VarCfg.U_REWARD_FINISH) or 0
    local maxCount = tonumber(SysConstant['Num_Daily_RewardTask']["Value"]) or 10
    if finishCount >= maxCount then
        sendmsg(actor, 9, "今日门派任务次数已用完")
        return
    end

    local curTaskId = gethumvar(actor, VarCfg.U_REWARD_INDEX) or 0
	local TaskProgress_data = Task.getCurTask(actor)
	local curTaskData = TaskProgress_data[""..curTaskId]
	if not curTaskData then
		sendmsg(actor, 9, "任务数据异常")
		return
	end

    --提交道具或装备
    local targetType = Task_cfg[curTaskId]['task_targettype'] or 0
    if targetType ~= 9 and targetType ~= 10 then
        sendmsg(actor, 9, "该任务无需提交道具")
		return
    end
    local targetTab = Task_cfg[curTaskId]['task_target_param'] or {}
    if targetType == 9 then
        --道具id^道具数量
    else
        --根据装备最低等级^装备最高等级^装备品级^装备正邪(不限正邪则不填)
    end
    -- 直接完成任务
    TaskProgress_data[""..curTaskId]['state'] = 2
    sethumvar(actor, VarCfg.T_TaskProgress_data, tbl2json(TaskProgress_data))

    Guild.updateTask(actor,curTaskId)    
    Guild.getData(actor)
    sendmsg(actor, 9, "道具提交成功，请注意查收奖励")
end


local function _onreset(actor)
    sethumvar(actor, VarCfg.U_Donate_Num, 0) -- 跨天清除门派每日已捐献次数
    sethumvar(actor, VarCfg.U_REWARD_FINISH, 0) -- 门派任务已完成次数
    sethumvar(actor, VarCfg.U_REWARD_REFUSH, 0) -- 门派任务免费刷新次数

    _onDelTask(actor)
    _onRefreshTask(actor)
    Guild.getData(actor)
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