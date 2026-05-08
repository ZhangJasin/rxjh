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
            if jobId == info.job then
                if info.sect then
                    if GOODEVILID == info.sect then
                        conf = info
                    end
                else
                    conf = info
                end
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
    local GOODEVILID = targetinfo(actor, "GOODEVILID")
    local jobId = job(actor)
    local val = 0
    for _, var in ipairs(valLst) do
        local t = json2tbl(gethumvar(actor, var)) or {}
        if next(t) then
            for v, _ in pairs(t) do
                for _, k in ipairs(config) do
                    if tonumber(v) == k.idx then
                        if k.sect then
                            if GOODEVILID == k.sect then
                                val = val + k.value
                            end
                        else
                            if jobId == k.job then
                                val = val + k.value
                            end
                        end
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
    -- 1. 获取旧的属性记录（上一次该系统加了多少）
    --
    local oldAttrJson = gethumvar(actor, VarCfg.S_equipCollectAttr)
    local oldAttrMap = json2tbl(oldAttrJson) or {}

    -- 2. 精准扣除旧属性：对齐玩家小退上线逻辑，先清理本系统之前的痕迹
    -- 这样做不会影响其他系统设置的脚本属性
    for attrId, attrValue in pairs(oldAttrMap) do
        local id = tonumber(attrId)
        local val = tonumber(attrValue)
        if id and val > 0 then
            setscriptabilvalue(actor, id, "-", val)
            print("删除id=", id)
            print("删除val=", val)
        end
    end

    -- 3. 计算当前应该加成的新属性
    local newAttr = getValueAttr(actor)
    local newAttrMap = {} -- 用于记录本次加了多少，存入变量供下次使用

    if newAttr then
        for _, group in ipairs(newAttr) do
            local attrId = tonumber(group[1])
            local attrValue = tonumber(group[2])
            local isPercent = tonumber(group[3])

            if isPercent == 1 then
                attrValue = math.floor(attrValue / 100)
            end

            if attrId and attrValue > 0 then
                -- 4. 增加新属性
                setscriptabilvalue(actor, attrId, "+", attrValue)
                -- 记录到 map 中
                newAttrMap[tostring(attrId)] = attrValue
            end
        end
    end

    -- 5. 更新玩家变量中的属性快照，以便下次精准扣除
    sethumvar(actor, VarCfg.S_equipCollectAttr, tbl2json(newAttrMap))

    -- 6. 统一刷新角色属性面板[cite: 3]
    recalcabilitys(actor)
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
