equipCollect = {}

--local jobNames = {
--    [1] = "弓手",
--    [2] = "枪客",
--    [3] = "刺客",
--    [4] = "医生",
--    [5] = "刀客",
--    [6] = "剑客"
--}

--GOODEVILID 获取阵营正邪(0=无阵营 1=正派 2=邪派)

local config = require("Envir/QuestDiary/game_config/cfgcsv/equipCollect.lua")
local attrConfig = require("Envir/QuestDiary/game_config/cfgcsv/equipCollectAttr.lua")

local function costMaterials(actor, id)
    local jobId = job(actor)
    local GOODEVILID = targetinfo(actor, "GOODEVILID")

    local conf = nil
    for _, info in ipairs(config) do
        if id == info.idx then
            if jobId == info.job and GOODEVILID == info.sect then
                conf = info
            end
        end
    end
    if not conf then
        sendmsg(actor, 9, "激活失败！")
        return
    end
    local haveCount = bagitemcount(actor, id)
    if haveCount < 1 then
        sendmsg(actor, 9, "道具不足！")
        return
    end
    delItemNum(actor, id, 1)
    return true
end

local function getItemVar(id)
    for _, conf in ipairs(config) do
        if conf.idx == id then
            return conf.var
        end
    end
    return
end

local function getTotalValue(actor)
    local valLst = { VarCfg.T_EquipCollect_1, VarCfg.T_EquipCollect_2, VarCfg.T_EquipCollect_3 }
    local val = 0
    for _, var in ipairs(valLst) do
        local t = json2tbl(gethumvar(actor, var)) or {}
        if next(t) then
            for v, _ in pairs(t) do
                for _, k in ipairs(config) do
                    if tonumber(v) == k.idx then
                        val = val + k.value
                    end
                end
            end
        end
    end
    return val
end

local function getValueAttr(actor)
    local value = getTotalValue(actor)
    if value <= 0 then return nil end
    local bestConf = nil
    local _sortedScores = {}
    --序列化属性配表
    for score, _ in pairs(attrConfig) do
        table.insert(_sortedScores, score)
    end
    table.sort(_sortedScores)

    for _, conf in ipairs(_sortedScores) do
        if value >= conf then
            bestConf = conf
        else
            break
        end
    end
    return attrConfig[bestConf].attr or nil
end

local function setValueAttr(actor)
    local attr = getValueAttr(actor)
    if not attr then return end
    for _, group in ipairs(attr) do
        local attrId = tonumber(group[1])
        local attrValue = tonumber(group[2])
        local isPercent = tonumber(group[3])
        if isPercent == 1 then
            attrValue = math.floor(attrValue / 100)
        end
        if attrId and attrValue then
            setscriptabilvalue(actor, attrId, "+", attrValue)
            recalcabilitys(actor)
            changeabil(actor, attrId, "+", attrValue)
        end
    end
end

function equipCollect.ReqActive(actor, id)
    local idStr = tostring(id)
    local idNum = tonumber(id)
    local var = getItemVar(idNum)
    if var then
        local t = json2tbl(gethumvar(actor, var)) or {}
        if t[idStr] then
            sendmsg(actor, 9, "已激活！")
            return
        end
        if costMaterials(actor, idNum) then
            t[idStr] = true
            sendmsg(actor, 9, "激活成功！")
            sethumvar(actor, var, tbl2json(t))
            dump(t)
            Message.sendmsgEx(actor, "equipCollect", "RetActive", {
                id = idStr, result = true
            })
            setValueAttr(actor)
        end
    end
end

GameEvent.add(EventCfg.onLoginEnd, function(actor)
    setValueAttr(actor)
end, equipCollect)

GameEvent.add(EventCfg.onNewHuman, function(actor)

end, equipCollect)

Message.RegisterNetMsg(ssrNetMsgCfg.equipCollect, equipCollect)
return equipCollect
