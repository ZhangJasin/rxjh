
TransferInfo = {}
local filname = "TransferInfo"

-- 根据职业(ClassID)、正邪(Type)、转职等级(TransferLV)整理配置
local Cfg = {}
for _, v in pairs(Transfer_cfg) do
    Cfg[v.ClassID] = Cfg[v.ClassID] or {}
    Cfg[v.ClassID][v.Type] = Cfg[v.ClassID][v.Type] or {}
    Cfg[v.ClassID][v.Type][v.TransferLV] = v
end

function TransferInfo.getCfg(actor)
    local jb = job(actor)
    local zy = targetinfo(actor, "GOODEVILID") or 0
    return Cfg[jb] and Cfg[jb][zy] or {}
end

function TransferInfo.getCurrent(actor)
    return targetinfo(actor,"RELEVEL")
end

function TransferInfo.doTransfer(actor)
    local cfg = TransferInfo.getCfg(actor)
    local curLv = targetinfo(actor, "RELEVEL")
    local nextCfg = cfg and cfg[curLv + 1] or nil

    if nextCfg and nextCfg.TaskId then      
        local allComp = true       
        local TaskComplete_data = Task.getFinishTask(actor)
        for _, taskId in ipairs(nextCfg.TaskId) do
            if not TaskComplete_data[""..taskId] then
                allComp = false
                break
            end
        end    
        if allComp then
            local parts = {}
            for _, v in pairs(nextCfg.Reward) do
                table.insert(parts, v[1] .. "#" .. v[2] .. "#" .. ConstCfg.binding)
            end
            if #parts > 0 then
                giveitem(actor, table.concat(parts, "&"),1)
            end
            settargetinfo(actor, "RELEVEL", curLv + 1)
            sendmsg(actor, 9, "转职成功")
            Message.sendmsg(actor, ssrNetMsgCfg.TransferInfo_RefreshUI)
        else
            sendmsg(actor, 9, "请先完成转职任务")
        end
    end
end
function TransferInfo.pickTask(actor)
    local cfg = TransferInfo.getCfg(actor)
    local curLv = targetinfo(actor, "RELEVEL")
    local nextCfg = cfg and cfg[curLv + 1] or nil

    if nextCfg and nextCfg.TaskId then
        local taskID = nextCfg.TaskId[1]
        if Task.Condition(actor,taskID) then
            --是否已接取任务
            local TaskProgress_data = Task.getCurTask(actor)        
            local TaskComplete_data = Task.getFinishTask(actor)
            if TaskProgress_data[""..taskID] or TaskComplete_data[""..taskID] then
                sendmsg(actor, 9, "已接取转职任务")
            else
                TaskProgress_data[""..taskID] = {state = 1,count = 0}
                newpicktask(actor, taskID,0)
                Task.updateTaskInfo(actor,TaskProgress_data)
                sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
                Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
                Message.sendmsg(actor, ssrNetMsgCfg.TransferInfo_RefreshTaskUI, #nextCfg.TaskId,0,taskID)
                sendmsg(actor, 9, "成功接取转职任务")
            end
        else
            sendmsg(actor, 9, "等级不足无法接取转职任务")
        end
    else
        sendmsg(actor, 9, "转职已达到最高级")
    end
end

--总任务数、已完成数量、正在进行的任务Id
function TransferInfo.getTaskState(actor)
    local cfg = TransferInfo.getCfg(actor)
    local curLv = targetinfo(actor, "RELEVEL")
    local nextCfg = cfg and cfg[curLv + 1] or nil
    -- dump(nextCfg)
    local totalNum,compNum,curTaskId = 0,0,0
    if nextCfg and nextCfg.TaskId then
        totalNum = #nextCfg.TaskId
        local TaskProgress_data = Task.getCurTask(actor) 
        local TaskComplete_data = Task.getFinishTask(actor)
        for _, taskId in ipairs(nextCfg.TaskId) do
            if TaskProgress_data[""..taskId] then
                curTaskId = taskId
            end
            if TaskComplete_data[""..taskId] then
                compNum = compNum+1
            end
        end        
    end

    Message.sendmsg(actor, ssrNetMsgCfg.TransferInfo_RefreshTaskUI,  totalNum,compNum,curTaskId)
end


Message.RegisterNetMsg(ssrNetMsgCfg.TransferInfo, TransferInfo)
return TransferInfo