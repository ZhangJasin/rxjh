--require("Envir/QuestDiary/util.lua")
----------#######任务系统需配置三张表，data目录下Task表，用接口增删任务用
----------#######还需要data/cfgcsv配置表里的Task（具体任务配置），Language（文本显示配置）
Task = {}
local filname = "Task"
local Task_cfg  =  require("Envir/QuestDiary/game_config/cfgcsv/Task.lua")
local Language_cfg = require("Envir/QuestDiary/game_config/cfgcsv/Language")
local SkillUpgrade  =  require("Envir/QuestDiary/game_config/SkillUpgrade.lua")
local SysConstant  =  require("Envir/QuestDiary/game_config/cfgcsv/SysConstant.lua")
local tasktypelist = {  --任务类型
    "主线","转职","支线"
}
-- 任务状态
local _taskState = {
    -- before = 0, -- 接取前
    ongoing = 1,   -- 进行中
    finish = 2,    -- 完成时(奖励未领取)
}
-- 任务类型
local _taskType = {
    _zhuxian  = 1,                 -- 主线任务
    _Transfer = 2,                 -- 转职任务
    _zhixian  = 3,                 -- 支线任务
}
-- 任务目标类型
local _taskMBType = {
    _killmon = 1,                 -- 击杀指定数量的怪物 
    _GetItem = 2,                 -- 击杀指怪物获取道具  同种完成方式
    _level = 3,                   -- 达到指定等级
    _GameplayDevelopment = 4,     -- 进行指定次数的某个培养
    _GameplayCompelete   = 5,     -- 通关指定次数的某个玩法
    _CompeleteTask       = 6,     -- 完成某个指定任务
}
-- 任务目标类型  进行指定次数的某个培养  子类型
local _taskMB4data = {
    _studySkill             = 1,     -- 学习固定数量的武功
    _JoinGoodevilid         = 2,     -- 加入任意阵营
    _addFriend              = 3,     -- 添加好友
    _creatTeam              = 4,     -- 创建一支队伍
    _creatGuild             = 5,     -- 创建或加入1个门派
    _UpPet                  = 6,     -- 升级宠物
    _Transfer               = 7,     -- 转职
    _QiangHua               = 8,     -- 强化
    _QiGongDian             = 9,     -- 启动点为0
    _BaiShi                 = 10,     -- 拜师
    _ShouTu                 = 11,     -- 收徒
    _GuildTask              = 12,     -- 完成一次门派任务
    _GuildCon               = 13,     -- 完成一次门派捐献
    _ActivePet              = 14,     -- 激活宠物
    _ActiveMount            = 15,     -- 激活坐骑
    _UpMount                = 16,     -- 升级坐骑
    _FuYu                   = 17,     -- 赋予
}
local _QiangHuaCount = 1          -- 1为强化次数
local _QiangHuaStdModeLevel = 2   -- 2为强化部位指定等级
local Task_Change_Flag = 1        --任务改变状态
local Task_Finish_Flag = 1        --任务完成状态
local equippostab = {
    [5]=0,[3]=1,[19]=2,[22]=3,[8]=4,[51]=5,[9]=6,[8]=7,[22]=8,[19]=9,[15]=10,[53]=12,
}
-------------------------------↓↓↓ 本地方法 ↓↓↓---------------------------------------
-- 获取当前任务数据
function Task.getCurTask(actor)
    local TaskProgress_data = gethumvar(actor,VarCfg.T_TaskProgress_data) or "" 
    if TaskProgress_data ~= "" then
        TaskProgress_data = json2tbl(TaskProgress_data)
    else
        TaskProgress_data = {   --默认接取第一个任务
            ["100001"] = {state = _taskState.ongoing,count = 0},
        }
    end
    -- dump(TaskProgress_data)
    return TaskProgress_data
end

-- 获取已完成任务数据
function Task.getFinishTask(actor)
    local TaskComplete_data = gethumvar(actor,VarCfg.T_TaskComplete_data) or ""   -- 已完成任务id {[已完成任务id]=1,........}
    if TaskComplete_data ~= "" then
        TaskComplete_data = json2tbl(TaskComplete_data)
    else
        TaskComplete_data = {}
    end

    return TaskComplete_data
end
-- 引导任务完成响应
function Task.onTaskTurnComplete(actor, data)
    local taskid = tonumber(data.taskid)
    if not taskid then
        return
    end    
    
    local TaskProgress_data = Task.getCurTask(actor)
    local taskCfg = Task_cfg[taskid]
    
    if not taskCfg then
        return
    end
    
    -- 检查是否是引导类型任务
    if taskCfg.task_turntype ~= 3 then
        return
    end
    
    -- 检查任务是否在进行中
    if not TaskProgress_data[""..taskid] then
        return
    end
    
    -- 更新任务状态为完成
    TaskProgress_data[""..taskid] = {state = _taskState.finish, count = 1}
    sethumvar(actor, VarCfg.T_TaskProgress_data, tbl2json(TaskProgress_data))
    
    -- 通知客户端更新任务
    Message.sendmsgEx(actor, "MainMission", "UpdataTask", {param1 = TaskProgress_data})
    
    -- 触发任务完成事件（可领取奖励）
    --GameEvent.push(EventCfg.onTaskFinish, actor, taskid)
end

-- 完成某个指定任务
local function _onCompleteOtherTask(actor)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if task_targettype == _taskMBType._CompeleteTask and taskxq then  --完成指定任务
            local TaskComplete_data = Task.getFinishTask(actor)
            local needtaskid = tonumber(Task_cfg[taskid]['task_target_param'])
            if TaskComplete_data[""..needtaskid] then
                TaskProgress_data[k]['count'] = 1
                TaskProgress_data[k]['state'] = _taskState.finish
                taskchange = Task_Change_Flag
            -- elseif TaskProgress_data[""..needtaskid] then
            --     local jindu = Task_cfg[needtaskid]['task_progress'] or 1
            --     local curjindu = TaskProgress_data[""..needtaskid]['count'] or 0
            --     if curjindu >= jindu then
            --         TaskProgress_data[k]['count'] = 1
            --         TaskProgress_data[k]['state'] = _taskState.finish
            --         taskchange = Task_Change_Flag
            --     end
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
    end
end

-- 击杀怪物，杀怪收集道具类任务
local function _onKillMon(actor, mon, mapid, monidx)
    if not isplayer(actor) then
        return
    end
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0
    local isLoopTaskFinished = false --跑环是否完成
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if (task_targettype == _taskMBType._killmon or task_targettype == _taskMBType._GetItem) and taskxq then  --杀怪任务 收集任务  同一逻辑
            local jl = Task_cfg[taskid]['task_target_param'][3] or 1
            local neednum = Task_cfg[taskid]['task_progress'] or 1
            local sum = math.random(1,100)
            local needkillmonidList = Task_cfg[taskid]['task_target_param'][1] or 0
            local isTaskMon = false     -- 是否为任务怪
            if type(needkillmonidList) == "table" then
                for i=1,#needkillmonidList do
                    if needkillmonidList[i] == monidx then
                        isTaskMon = true
                        break
                    end
                end
            elseif type(needkillmonidList) == "number" then
                isTaskMon = needkillmonidList == monidx
            end
            if isTaskMon and v['count'] < neednum and jl*100 >= sum then  --任务未完成 满足条件 进度加一
                TaskProgress_data[k]['count'] = TaskProgress_data[k]['count']+1
                taskchange = Task_Change_Flag
                if TaskProgress_data[k]['count'] == neednum then
                    TaskProgress_data[k]['state'] = _taskState.finish
                    taskfinish = Task_Finish_Flag
                end
            end
        end
    end

    if taskchange == Task_Change_Flag and not isLoopTaskFinished then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
                --跑完，完成直接领取
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end
-- 升级任务
local function _onLevelUp(actor, cur_level, before_level)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        local neednum = Task_cfg[taskid]['task_progress'] or 1
        if task_targettype == _taskMBType._level and taskxq then  --升级任务  
            TaskProgress_data[k]['count'] = cur_level
            taskchange = Task_Change_Flag
            if TaskProgress_data[k]['count'] >= neednum then
                TaskProgress_data[k]['state'] = _taskState.finish
                taskfinish = Task_Finish_Flag
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
    Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
end

-- 锻造强化次数  强化部位指定等级
local function _onQiangHua(actor,flag)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --强化功能
            local targetTab = Task_cfg[taskid]['task_target_param']
            if type(targetTab) == "table" and targetTab[1] == _taskMB4data._QiangHua then
                local qhType = targetTab[2]
                local neednum = Task_cfg[taskid]['task_progress'] or 1
                if qhType == _QiangHuaCount and v['count'] < neednum then     --强化指定次数
                    TaskProgress_data[k]['count'] = TaskProgress_data[k]['count']+1
                    taskchange = Task_Change_Flag
                    if TaskProgress_data[k]['count'] >= neednum then
                        TaskProgress_data[k]['state'] = _taskState.finish
                        taskfinish = Task_Finish_Flag
                    end
                elseif qhType == _QiangHuaStdModeLevel then  --强化部位指定等级
                    local equipmakeIndex = bodyiteminfo(actor, equippostab[targetTab[3]]..'_MakeIndex')
                    if equipmakeIndex and equipmakeIndex ~= "" then
                        linkitembymakeindex(actor, equipmakeIndex)
                        local qhlv = linkitem(actor, "INTVALUE0") or 0                        
                        if qhlv >= neednum then
                            TaskProgress_data[k]['state'] = _taskState.finish
                            taskchange = Task_Change_Flag
                            taskfinish = Task_Finish_Flag
                        elseif qhlv ~= v['count'] then
                            taskchange = Task_Change_Flag
                        end
                        TaskProgress_data[k]['count'] = qhlv
                    end
                end
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end
--赋予次数
local function _onFuYu(actor,flag)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --赋予功能
            local targetTab = Task_cfg[taskid]['task_target_param']
            local targetType = 0
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = targetTab[1]
            end
            if targetType == _taskMB4data._FuYu then               
                local neednum = Task_cfg[taskid]['task_progress'] or 1
                TaskProgress_data[k]['count'] = TaskProgress_data[k]['count']+1
                taskchange = Task_Change_Flag
                if TaskProgress_data[k]['count'] >= neednum then
                    TaskProgress_data[k]['state'] = _taskState.finish
                    taskfinish = Task_Finish_Flag
                end                
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end
-- 切换地图类
local function _onChangeMap(actor, cur_mapid)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskxq = Task.ConditionLv(actor, 102005)
    if tostring(cur_mapid) == "102" and TaskProgress_data['102005'] and taskxq then
        TaskProgress_data['102005']['count'] = 1
        TaskProgress_data['102005']['state'] = _taskState.finish
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        _onCompleteOtherTask(actor) -- 有任务有变化是判断
    end
end
-- 创建队伍 加入队伍
local function _onCreatTeam(actor)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --玩法培养
            local targetTab = Task_cfg[taskid]['task_target_param']
            local targetType = 0
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = targetTab[1]
            end
            if targetType == _taskMB4data._creatTeam then   --创建队伍
                TaskProgress_data[k]['count'] = 1
                TaskProgress_data[k]['state'] = _taskState.finish
                taskchange = Task_Change_Flag
                taskfinish = Task_Finish_Flag
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end
-- 创建门派 加入门派
local function _onCreateGuild(actor)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --玩法培养
            local targetTab = Task_cfg[taskid]['task_target_param']
            local targetType = 0
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = targetTab[1]
            end
            if targetType == _taskMB4data._creatGuild then   --创建队伍
                TaskProgress_data[k]['count'] = 1
                TaskProgress_data[k]['state'] = _taskState.finish
                taskchange = Task_Change_Flag
                taskfinish = Task_Finish_Flag
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end
local function _onGuildsetexp(actor)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --门派捐献功能
            local targetTab = Task_cfg[taskid]['task_target_param']
            local targetType = 0
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = targetTab[1]
            end
            if targetType == _taskMB4data._GuildCon then               
                local neednum = Task_cfg[taskid]['task_progress'] or 1
                TaskProgress_data[k]['count'] = TaskProgress_data[k]['count']+1
                taskchange = Task_Change_Flag
                if TaskProgress_data[k]['count'] >= neednum then
                    TaskProgress_data[k]['state'] = _taskState.finish
                    taskfinish = Task_Finish_Flag
                end                
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end
-- 加入任意阵营
local function _onJoinGOODEVILID(actor)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --玩法培养
            local targetTab = Task_cfg[taskid]['task_target_param']
            local targetType = 0
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = targetTab[1]
            end
            if targetType == _taskMB4data._JoinGoodevilid then   --加入任意阵营
                local GOODEVILID = targetinfo(actor, "GOODEVILID")
                if GOODEVILID > 0 then
                    TaskProgress_data[k]['count'] = 1
                    TaskProgress_data[k]['state'] = _taskState.finish
                    taskchange = Task_Change_Flag
                    taskfinish = Task_Finish_Flag
                end
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end

-- 添加好友数
local function _onAddFriend(actor)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --玩法培养
            local neednum = Task_cfg[taskid]['task_progress'] or 1
            local targetTab = Task_cfg[taskid]['task_target_param']
            local targetType = 0
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = targetTab[1]
            end
            if targetType == _taskMB4data._addFriend then   --好友数
                local friendlist  = getallfriendid(actor) or {}
                if TaskProgress_data[k]['count'] >= neednum then
                    TaskProgress_data[k]['state'] = _taskState.finish
                    taskchange = Task_Change_Flag
                    taskfinish = Task_Finish_Flag
                elseif #friendlist ~= v['count'] then
                    taskchange = Task_Change_Flag
                end
                TaskProgress_data[k]['count'] = #friendlist or 0
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end

-- 气功点变化为0
local function _onChangeQGD(actor)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --玩法培养
            local neednum = Task_cfg[taskid]['task_progress'] or 0
            local targetTab = Task_cfg[taskid]['task_target_param']
            local targetType = 0
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = targetTab[1]
            end
            --print("targetType="..targetType)
            if targetType == _taskMB4data._QiGongDian then   -- 气功点
                local qgdnum  = money(actor, 19) or 0 
                --print("qgdnum="..qgdnum)
                if qgdnum == 0 then
                    TaskProgress_data[k]['state'] = _taskState.finish
                    TaskProgress_data[k]['count'] = 1
                    taskchange = Task_Change_Flag
                    taskfinish = Task_Finish_Flag
                end
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end

--- 升级宠物  暂无
local function _onPetLevelinfo(actor,hasPet)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0
    local allLevel = 0
    for k,v in pairs(hasPet) do
        allLevel = allLevel + v
    end
    -- dump(hasPet)
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --玩法培养
            local neednum = Task_cfg[taskid]['task_progress'] or 0
            local targetTab = Task_cfg[taskid]['task_target_param']
            local targetType = 0
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = targetTab[1]
            end
            --print("targetType="..targetType)
            if targetType == _taskMB4data._UpPet then  
                if TaskProgress_data[k]['count'] >= neednum then
                    TaskProgress_data[k]['state'] = _taskState.finish
                    taskchange = Task_Change_Flag
                    taskfinish = Task_Finish_Flag
                elseif allLevel ~= v['count'] then
                    taskchange = Task_Change_Flag
                end
                TaskProgress_data[k]['count'] = allLevel
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end

--- 个人BOSS  暂无

-------------------------------↓↓↓ 网络消息 ↓↓↓---------------------------------------
-- 检测玩家当前位置附近是否有任务交付NPC
function Task.checkNearbyTaskNpc(actor)
    local TaskProgress_data = Task.getCurTask(actor)
    local playerX = targetinfo(actor, "X")
    local playerY = targetinfo(actor, "Y")
    local playerMap = targetinfo(actor, "NEWMAP")
    local nearbyTaskNpc = false
    
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local neednpc = Task_cfg[taskid]['task_finnpc'] or 0
        local state = TaskProgress_data[""..taskid]['state'] or 0
        
        -- 只检查已完成且需要NPC交付的任务
        if state == _taskState.finish and neednpc > 0 then
            local task_fintype = Task_cfg[taskid]['task_fintype']
            -- 只检查需要到NPC交付的任务 (task_fintype == 2)
            if task_fintype == 2 then
                local postab = Task_cfg[taskid]['task_finpos']
                if postab and postab[1] == tostring(playerMap) then
                    local npcX = tonumber(postab[2])
                    local npcY = tonumber(postab[3])
                    local range = tonumber(postab[4]) or 5
                    
                    -- 计算玩家与NPC的距离
                    local distance = math.sqrt((playerX - npcX) ^ 2 + (playerY - npcY) ^ 2)
                    -- 如果在NPC范围内，说明附近有任务NPC
                    if distance <= range then
                        nearbyTaskNpc = true
                        break
                    end
                end
            end
        end
    end
    
    return nearbyTaskNpc
end

-- 点npc打开面板
function Task.Clicknpc(actor, npcid)
	-- print("接取任务npcid",npcid)
    local isopenpanl = false   -- 是否已打开界面
    local TaskProgress_data = Task.getCurTask(actor)
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local neednpc = Task_cfg[taskid]['task_finnpc'] or 0
        local jindu = Task_cfg[taskid]['task_progress'] or 1
        local curjindu = TaskProgress_data[""..taskid]['count'] or 0
        local state = TaskProgress_data[""..taskid]['state'] or 0
        if state == _taskState.finish and npcid == neednpc then   --寻路到npc
            Message.sendmsgEx(actor, "taskDeliver","OpenPanl",{param1 = TaskProgress_data,param2 = taskid})
            isopenpanl = true
            break
        end
    end

    if not isopenpanl and npcid == 12 then     -- 暂定为月老npc
        -- 打开侠侣契约界面
        -- 已有侣侣关系验证
        local targetId = gethumvar(actor, VarCfg.U_MarryPartner) or 0
        if targetId == 0 then
            sendmsg(actor, 9, "请先结缘才能签订契约")
            return
        end
        if not checkstate(targetId,2) then 
		    sendmsg(actor, 9, "结缘对象不在线")
		    return
        end
        -- 组队验证
        if not isInSameTeam(actor, targetId) then
            sendmsg(actor, 9, "需要与对方组队才能签订契约")
            return
        end
        local leaderID = groupmasterid(actor)
        local dzactor,dyactor = actor,targetId
        if leaderID == targetId then 
		    dzactor,dyactor = targetId,actor
        end
        Message.sendmsgEx(actor, "page_marriage","Open",{dzactor,dyactor,targetId})
        return
    end

    if not isopenpanl then
        GameEvent.push(EventCfg.onOpenNpc,actor,npcid)
    end
end


-- 领取奖励 完成任务 添加新任务
function Task.getReward(actor, data)
    local taskid = tonumber(data[1])
	--print("领取奖励，完成任务",taskid)
    local TaskProgress_data = Task.getCurTask(actor)
    local TaskComplete_data = Task.getFinishTask(actor)
    --local jindu = Task_cfg[taskid]['task_progress'] or 1
    local state = TaskProgress_data[""..taskid]['state'] or 0
    --print("state",state)
    --if state == _taskState.finish or not Task_cfg[taskid]['task_targettype']  then 
    if state == _taskState.finish then 
        TaskProgress_data[""..taskid] = nil
        newdeletetask(actor, taskid)
        --自动接取任务
        if Task_cfg[taskid]['task_pro'] then
            for i=1,#Task_cfg[taskid]['task_pro'] do
                local newtaskid = Task_cfg[taskid]['task_pro'][i]
                if Task.Condition(actor, newtaskid) and not TaskComplete_data[""..newtaskid] then
                    TaskProgress_data[""..newtaskid] = {state = _taskState.ongoing,count = 0}
                    newpicktask(actor, newtaskid,0)
                end
            end
        end
        if TaskComplete_data[""..taskid] then
            TaskComplete_data[""..taskid] = TaskComplete_data[""..taskid] + 1
        else
            TaskComplete_data[""..taskid] = 1
        end
        --dump(TaskComplete_data)
        sethumvar(actor,VarCfg.T_TaskComplete_data,tbl2json(TaskComplete_data))  --已完成任务id {[已完成任务id]=1,........}
    --     local TaskComplete_data = Task.getFinishTask(actor)
    --     dump(TaskComplete_data)
    --     print("actor2="..actor)
        TaskProgress_data = Task.updateTaskInfo(actor,TaskProgress_data)   --判断接取新任务状态

        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
       
       
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量

        _onCompleteOtherTask(actor)
        if Task_cfg[taskid]['task_drop'] then
            Player.giveItemByJobTable(actor, Task_cfg[taskid]['task_drop'], 1, 1)
        end
        -- 转职任务 更新界面       
        if Task_cfg[taskid]['task_type'] == 2 then
            TransferInfo.getTaskState(actor)
        end
    end
end

--更新跑环
function Task.updateLoopTask(actor,data)
    -- print("更新跑环")
    local taskid = tonumber(data[1])
    local TaskProgress_data = Task.getCurTask(actor)
    local state =  0
    if TaskProgress_data[""..taskid] then
        state = TaskProgress_data[""..taskid]['state']
    end
    if state == _taskState.finish or tonumber(taskid) == 600000 then 
       local newtaskId = nil
       TaskProgress_data[""..taskid] = nil
       newdeletetask(actor, taskid)
       --自动接取任务
       if Task_cfg[taskid]['task_pro'] then
            for i=1,#Task_cfg[taskid]['task_pro'] do
                newtaskId = Task_cfg[taskid]['task_pro'][i]
                TaskProgress_data[""..newtaskId] = {state = _taskState.ongoing,count = 0}
                newpicktask(actor, newtaskId,0)
            end
        else
            for i=1,#LoopTask do
                if LoopTask[i].Level_Interval[1] <= level(actor) and level(actor) <= LoopTask[i].Level_Interval[2] then
                    newtaskId = LoopTask[i].Task_List
                end
            end
            -- print("newtaskId",newtaskId)
            TaskProgress_data[""..newtaskId] = {state = _taskState.ongoing, count = 0}
            newpicktask(actor, newtaskId,0)
       end

       sethumvar(actor,VarCfg.U_LOOP_TASK_ID, newtaskId)

       TaskProgress_data = Task.updateTaskInfo(actor,TaskProgress_data)   --判断接取新任务状态
       sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表

       Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量

       _onCompleteOtherTask(actor)
       if Task_cfg[taskid]['task_drop'] then
            Message.sendmsgEx(actor, "gxhd","initData",taskid)   -- 更新客户端任务进度变量
            Player.giveItemByJobTable(actor, Task_cfg[taskid]['task_drop'], 1, 1)
       end
       --直接导航
        Task.xunlu(actor, {newtaskId})
    end
end

-- 寻路
function Task.xunlu(actor, data)
    local taskid = tonumber(data[1])
    local playlevel = level(actor)                  --玩家等级
    local needlevel = Task_cfg[taskid]['task_level'] or 0
    if needlevel > playlevel then
        return
    end
    -- if true then
    --     gotonow(actor, 107, 113,"301",1)
    --     return
    -- end
    sethumvar(actor,VarCfg.U_click_taskID,taskid)  --当前点击
	-- print("寻路",taskid)
    local TaskProgress_data = Task.getCurTask(actor)
    local jindu = Task_cfg[taskid]['task_progress'] or 1
    local state = TaskProgress_data[""..taskid]['state'] or 0
    local task_fintype = Task_cfg[taskid]['task_fintype']
    
    -- 判断寻路目标类型：NPC还是野外
    local isNpcTarget = false
    if state == _taskState.finish and task_fintype == 2 then  -- 寻路到NPC交付任务
        isNpcTarget = true
    end
    
    if isNpcTarget then
        -- 目标是NPC，停止自动挂机
        autoplaygame(actor,0)
        sethumvar(actor,VarCfg.N_task_xunlu_auto,0)
    else
        -- 目标是野外，开始自动挂机
        autoplaygame(actor,1)
    end
    
    if state == _taskState.finish then   --寻路到npc
        if task_fintype == 2 then  --寻路npc交付任务
            --opennpcshowex(actor, Task_cfg[taskid]['task_finnpc'], 10, 10, 0)
            local postab = Task_cfg[taskid]['task_finpos']
            local range = tonumber(postab[4])
            local x,y = math.random(-range,range),math.random(-range,range)
            -- if x == 0 then x = 1 end
            -- if y == 0 then y = 1 end
            gotonow(actor, tonumber(postab[2]), tonumber(postab[3]),(postab[1]),0,range)
        elseif task_fintype == 1 then   --远程交付任务
            Message.sendmsgEx(actor, "taskDeliver","OpenPanl",{param1 = TaskProgress_data})
        end
    else   --寻路到指定任务点
        local postab = Task_cfg[taskid]['task_pos']
        local range = tonumber(postab[4])
        local x,y = math.random(-range,range),math.random(-range,range)
        -- if x == 0 then x = 1 end
        -- if y == 0 then y = 1 end
        gotonow(actor, tonumber(postab[2]), tonumber(postab[3]),(postab[1]),1,range)
        sethumvar(actor,VarCfg.N_task_xunlu_auto,1)
    end
end

-- 接取任务条件判断
function Task.Condition(actor, taskid)
	-- print("接取任务条件判断",taskid)
    local playzy = targetinfo(actor, "GOODEVILID")  --玩家阵营
    --local playlevel = level(actor)                  --玩家等级
    local needzy = Task_cfg[taskid]['task_goodevilid'] or 0
    --local needlevel = Task_cfg[taskid]['task_level'] or 0
    
    if needzy > 0 and playzy ~= needzy then   --判断阵营
        return false
    end
    local tasktype = Task_cfg[taskid]['task_type'] or 0
    local playlevel = currabil(actor, 0)           --玩家等级
    local needlevel = Task_cfg[taskid]['task_level'] or 0
    if needlevel > playlevel and tasktype ~= _taskType._zhuxian then   --主线任务可以不看等级提前接取
        return false
    end

    --local kjqTasktab = Task_cfg[taskid]['task_pre'] or {} --需要完成前置任务

    return true
end
-- 任务是否可以进行
function  Task.ConditionLv(actor, taskid)   
    local playlevel = currabil(actor, 0)           --玩家等级
    local needlevel = Task_cfg[taskid]['task_level'] or 0
    if needlevel > playlevel then   
        return false
    end
    return true
end

-- 接取任务  例 登录任务接取  升级接取任务判断  
function Task.GetAlltaskinfo(actor)
    --print("actor="..actor)
    -- print("任务登录开始")
	local playzy = targetinfo(actor, "GOODEVILID")  --玩家阵营
    local playlevel = level(actor)                  --玩家等级
    local TaskComplete_data = Task.getFinishTask(actor)
    
    local TaskProgress_data = Task.getCurTask(actor)
    _onCompleteOtherTask(actor)

    for k,v in pairs(TaskComplete_data) do
        local ywctaskid = tonumber(k)
        local ywctasktype = Task_cfg[ywctaskid]['task_type'] or 0
        if TaskProgress_data[""..ywctaskid] then  
            TaskProgress_data[""..ywctaskid] = nil   -- 如果任务已完成  则从接取任务中移除
        end
        if Task_cfg[ywctaskid] then
            local kjqTasktab = Task_cfg[ywctaskid]['task_pro'] or {}
            for i=1,#kjqTasktab do
                if not TaskComplete_data[""..kjqTasktab[i]] and not TaskProgress_data[""..kjqTasktab[i]] then  --任务没做过，接取任务
                    if Task.Condition(actor, kjqTasktab[i]) then  --判断接取条件
                        TaskProgress_data[""..kjqTasktab[i]] = {state = _taskState.ongoing,count = 0}
                    end
                end
            end
        end
    end


    TaskProgress_data = Task.updateTaskInfo(actor,TaskProgress_data)   --判断接取新任务状态
    -- TaskProgress_data = {   --默认接取第一个任务
    --         ["100001"] = {state = _taskState.ongoing,count = 0},
    --         ["100002"] = {state = _taskState.ongoing,count = 0},
    --         ["100003"] = {state = _taskState.ongoing,count = 0}
    --     } 
    --TaskProgress_data['200005'] = {state = _taskState.ongoing,count = 0}
    
    sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表

    for k,v in pairs(TaskProgress_data) do
        -- dump(tonumber(k))
        newpicktask(actor, tonumber(k))
    end
    Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})
    -- print("任务登录结束")
end

-- 更新任务进度  task表   task_targettype字段 4 5 6 类任务
function Task.updateTaskInfo(actor,TaskProgress_data)
    local taskchange = 0  --任务是否有变化，有的话更新
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --玩法培养
            local targetTab = Task_cfg[taskid]['task_target_param']
            local targetType = 0
            local neednum = Task_cfg[taskid]['task_progress'] or 1
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = tonumber(targetTab[1])
            end
            -- print("taskid="..taskid.."  targetType="..targetType,"_studySkill:".._taskMB4data._studySkill)
            if targetType == _taskMB4data._studySkill then   --学习武功数量
                local skillTab = getallskillid(actor)
                local yxxnum = 0
                -- dump(skillTab,"================")
                for i=1,#skillTab do
                    local skillid = tonumber(skillTab[i])
                    if SkillUpgrade[skillid] then
                        local skilltype = SkillUpgrade[skillid][1]['WuGongType'] or 0 --武功类型
                        if skilltype and tonumber(skilltype) == 1 then  -- 职业武功才算
                            yxxnum = yxxnum+1
                        end
                    end
                end
                if yxxnum >= neednum then
                    TaskProgress_data[k]['state'] = _taskState.finish
                end
                TaskProgress_data[k]['count'] = yxxnum
            elseif targetType == _taskMB4data._JoinGoodevilid then   --加入任意阵营
                local GOODEVILID = targetinfo(actor, "GOODEVILID")
                if GOODEVILID > 0 then
                    TaskProgress_data[k]['count'] = 1
                    TaskProgress_data[k]['state'] = _taskState.finish
                end
            elseif targetType == _taskMB4data._addFriend then   --好友数
                local friendlist  = getallfriendid(actor) or {}
                TaskProgress_data[k]['count'] = #friendlist or 0
                if TaskProgress_data[k]['count'] >= neednum then
                    TaskProgress_data[k]['state'] = _taskState.finish
                end
            elseif targetType == _taskMB4data._creatTeam then   --创建队伍
                local dzid = groupinfo("1_1")
                if dzid == tostring(actor) then  --判断自己是否为队长
                    TaskProgress_data[k]['count'] = 1
                    TaskProgress_data[k]['state'] = _taskState.finish
                end
            elseif targetType == _taskMB4data._creatGuild then   --创建或加入门派
                local GUILDID = targetinfo(actor, "GUILDID")
                if GUILDID ~= "" then  --判断自己是否为队长
                    TaskProgress_data[k]['count'] = 1
                    TaskProgress_data[k]['state'] = _taskState.finish
                end
            elseif targetType == _taskMB4data._UpPet then   --升级宠物   暂留
                local hasPet = json2tbl(gethumvar(actor,VarCfg.T_Pets)) or {}
                local allLevel = 0
                for k,v in pairs(hasPet) do
                    allLevel = allLevel + v
                end
                if allLevel >= neednum then
                    TaskProgress_data[k]['state'] = _taskState.finish
                end
            elseif targetType == _taskMB4data._Transfer then   --几转
                local RELEVEL = targetinfo(actor, "RELEVEL")
                TaskProgress_data[k]['count'] = RELEVEL
                if RELEVEL >= neednum then
                    TaskProgress_data[k]['state'] = _taskState.finish
                end
            elseif targetType == _taskMB4data._QiangHua then   --强化
                local qhtype = targetTab[2]
                if qhtype == _QiangHuaStdModeLevel then  --强化部位指定等级
                    local equipmakeIndex = bodyiteminfo(actor, equippostab[targetTab[3]]..'_MakeIndex')
                    if equipmakeIndex and equipmakeIndex ~= "" then
                        linkitembymakeindex(actor, equipmakeIndex)
                        local qhlv = linkitem(actor, "INTVALUE0") or 0
                        TaskProgress_data[k]['count'] = qhlv
                        if qhlv >= neednum then
                            TaskProgress_data[k]['state'] = _taskState.finish
                        end
                    end
                end
            elseif targetType == _taskMB4data._QiGongDian then   -- 气功点
                local qgdnum  = money(actor, 19) or 0 
                --print("qgdnum="..qgdnum)
                if qgdnum == 0 then
                    TaskProgress_data[k]['count'] = 1
                    TaskProgress_data[k]['state'] = _taskState.finish
                end
            end

        elseif task_targettype == _taskMBType._GameplayCompelete and taskxq then  --通关指定次数的某个玩法   暂时=留
            
        end
    end
    return TaskProgress_data
end

-- 目前需客户端传消息 转职任务
function Task.onTransfer(actor)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskfinish = 0  --任务是否完成
    local taskchange = 0  --任务是否有变化，有的话更新
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        local neednum = Task_cfg[taskid]['task_progress'] or 1
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --玩法培养
            local targetTab = Task_cfg[taskid]['task_target_param']
            local targetType = 0
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = targetTab[1]
            end
            if targetType == _taskMB4data._Transfer then   --几转
                local RELEVEL = targetinfo(actor, "RELEVEL")
                if RELEVEL >= neednum then
                    TaskProgress_data[k]['state'] = _taskState.finish
                    taskfinish = Task_Finish_Flag
                    taskchange = Task_Change_Flag
                elseif RELEVEL ~= v['count'] then
                    taskchange = Task_Change_Flag
                end
                TaskProgress_data[k]['count'] = RELEVEL
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end
-- 学习武功数量
function Task.onStudySkill(actor)
    local TaskProgress_data = Task.getCurTask(actor)
    local taskchange = 0  --任务是否有变化，有的话更新
    local taskfinish = 0  --任务是否完成
    for k,v in pairs(TaskProgress_data) do
        local taskid = tonumber(k)
        local taskxq = Task.ConditionLv(actor, taskid)
        local task_targettype = Task_cfg[taskid]['task_targettype'] or 0
        local neednum = Task_cfg[taskid]['task_progress'] or 1
        if task_targettype == _taskMBType._GameplayDevelopment and taskxq then  --玩法培养
            local targetTab = Task_cfg[taskid]['task_target_param']
            local targetType = 0
            if type(targetTab) == "string" then
                targetType = tonumber(targetTab)
            elseif type(targetTab) == "table" then
                targetType = targetTab[1]
            end
            if targetType == _taskMB4data._studySkill then   --学习武功数量
                local skillTab = getallskillid(actor)
                local yxxnum = 0
                for i=1,#skillTab do
                    local skillid = tonumber(skillTab[i])
                    if SkillUpgrade[skillid] then
                        local skilltype = SkillUpgrade[skillid][1]['WuGongType'] or 0 --武功类型
                        if skilltype and tonumber(skilltype) == 1 then  -- 职业武功才算
                            yxxnum = yxxnum+1
                        end
                    end
                end
                -- print("yxxnum="..yxxnum)
                -- print("v['count']="..v['count'])
                if yxxnum >= neednum then
                    TaskProgress_data[k]['state'] = _taskState.finish
                    taskchange = Task_Change_Flag
                    taskfinish = Task_Finish_Flag
                elseif yxxnum ~= v['count'] then
                    taskchange = Task_Change_Flag
                end
                TaskProgress_data[k]['count'] = yxxnum
            end
        end
    end
    if taskchange == Task_Change_Flag then
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    end
end

-- 与npc交谈类任务
function Task.onNpc(actor,data)
    local taskid = tonumber(data[1])
    if not Task_cfg[taskid]['task_targettype'] and Task_cfg[taskid]['task_type'] <= 4 then
        local TaskProgress_data = Task.getCurTask(actor)
        TaskProgress_data[""..taskid] = {state = _taskState.finish,count = 1}
        sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
        if taskfinish == Task_Finish_Flag then
            _onCompleteOtherTask(actor) -- 有任务有变化是判断
        end
    else
        -- print("导航到了")
        if Task_cfg[taskid]['task_fintype']== 2 then
            local TaskProgress_data = Task.getCurTask(actor)
            TaskProgress_data[""..taskid] = {state = _taskState.finish,count = 1}
            sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
            Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
            if taskfinish == Task_Finish_Flag then
                _onCompleteOtherTask(actor) -- 有任务有变化是判断
            end
        end
    end
end


-------------------------------↓↓↓ 事件 ↓↓↓---------------------------------------

-----以下为完成任务相关触发
GameEvent.add(EventCfg.onKillMon, function (actor, mon, mapid, monidx)                 -- 怪物死亡触发
    _onKillMon(actor, mon, mapid, monidx)
end, Task)
GameEvent.add(EventCfg.onPlayLevelUp, function (actor, cur_level, before_level)         -- 升级触发
    _onLevelUp(actor, cur_level, before_level)  
    Task.GetAlltaskinfo(actor)    -- 升级后判断是否有可以接取任务
    -- local TaskProgress_data = Task.getCurTask(actor)
    -- Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})
end, Task)
GameEvent.add(EventCfg.onQiangHua, function (actor,flag)         -- 强化功能触发  强化次数要求
    _onQiangHua(actor,flag)
end, Task)
GameEvent.add(EventCfg.onFuYu, function (actor,flag)         -- 强化功能触发  强化次数要求
    _onFuYu(actor,flag)
end, Task)

GameEvent.add(EventCfg.goSwitchMap, function (actor, cur_mapid, former_mapid)         -- 切换地图触发
    _onChangeMap(actor, cur_mapid, former_mapid)
end, Task)
GameEvent.add(EventCfg.onGroupCreate, function (actor, roleName)         -- 创建队伍
     _onCreatTeam(actor)
end, Task)
GameEvent.add(EventCfg.onGroupAddMember, function (actor, targetName)         -- 加入队伍
    _onCreatTeam(actor)
end, Task)

GameEvent.add(EventCfg.onCreateguild, function (actor,guildid,guildName)         -- 创建门派成功触发
    _onCreateGuild(actor)
end, Task)

GameEvent.add(EventCfg.onGuildaddmemberafter, function (actor, guildId, guildName)         -- 加入门派触发
    _onCreateGuild(actor)
end, Task)
GameEvent.add(EventCfg.onGuildsetexp, function (actor, type, addzj)         -- 强化功能触发  强化次数要求
    _onGuildsetexp(actor)
end, Task)

GameEvent.add(EventCfg.onJoinUpright, function (actor)   -- 加入正派
    _onJoinGOODEVILID(actor)
end, Task)
GameEvent.add(EventCfg.onJoinEvil, function (actor, target, effectid, skillid, skilllv)   -- 加入邪派
    _onJoinGOODEVILID(actor)
end, Task)

GameEvent.add(EventCfg.onJoinEvil, function (actor, target, effectid, skillid, skilllv)   -- 加入邪派
    _onJoinGOODEVILID(actor)
end, Task)

GameEvent.add(EventCfg.onAddFriendSelf, function (actor,param1)   -- 添加好友
    _onAddFriend(actor)
    _onAddFriend(param1)
end, Task)  -- 同意好友成功触发  param1 申请人ID

GameEvent.add(EventCfg.onChangeQGD, function (actor, moneyID, lastCount)   -- 气功点改变
    --print("气功点改变")
    _onChangeQGD(actor)
end, Task)

-- 宠物升级事件
GameEvent.add(EventCfg.onPetLevel, function (actor,hasPet)
    _onPetLevelinfo(actor,hasPet)

end, Task)

--点击npc触发
GameEvent.add(EventCfg.onClicknpc, function (actor, npcid)
    Task.Clicknpc(actor, npcid)  
end, Task)


--登录更新任务
GameEvent.add(EventCfg.onLoginEnd, function (actor)
    -- print("登录更新任务")
    Task.GetAlltaskinfo(actor)

end, Task)


Message.RegisterNetMsg(ssrNetMsgCfg.Task, Task)

return Task



