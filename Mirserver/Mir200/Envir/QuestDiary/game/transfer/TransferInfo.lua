
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
        local TaskComplete_data = json2tbl(gethumvar(actor,VarCfg.T_TaskComplete_data) or "") or {}
        for _, taskId in ipairs(nextCfg.TaskId) do
            if not TaskComplete_data[taskId] then
                allComp = false
                break
            end
        end    
        if allComp then
            settargetinfo(actor, "RELEVEL", curLv + 1)
            sendmsg(actor, 9, "转职成功")
        else
            sendmsg(actor, 9, "请先完成转职任务")
        end
    end
end
function TransferInfo.pickTask(actor)
    
end

--总任务数、已完成数量、正在进行的任务Id
function TransferInfo.getTaskState(actor)
    local cfg = TransferInfo.getCfg(actor)
    local curLv = targetinfo(actor, "RELEVEL")
    local nextCfg = cfg and cfg[curLv + 1] or nil

    local totalNum,compNum,curTaskId = 0,0,0
    if nextCfg and nextCfg.TaskId then
        totalNum = #nextCfg.TaskId
        local TaskProgress_data = json2tbl(gethumvar(actor, VarCfg.T_TaskProgress_data) or "") or {}        
        local TaskComplete_data = json2tbl(gethumvar(actor,VarCfg.T_TaskComplete_data) or "") or {}
        for _, taskId in ipairs(nextCfg.TaskId) do
            if TaskProgress_data[taskId] then
                curTaskId = taskId
            end
            if TaskComplete_data[taskId] then
                compNum = compNum+1
            end
        end        
    end

    Message.sendmsgEx(actor, "TransferPanel", "RefreshTaskUI", {
        _totalNum = totalNum,
        _compNum = compNum,
        _curTaskId= curTaskId
    })
end


Message.RegisterNetMsg(ssrNetMsgCfg.TransferInfo, TransferInfo)
return TransferInfo