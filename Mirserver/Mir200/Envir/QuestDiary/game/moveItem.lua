--require("Envir/QuestDiary/util.lua")
moveItem = {}
local filname = "moveItem"

-- 回城符对应城市坐标表
local citypostab = {
    [127] = {"101",209,314,5},    -- 泫渤派
    [128] = {"301",99,268,5},     -- 柳正关
    [129] = {"2101",110,95,5},    -- 三邪关
    [130] = {"501",195,80,5},     -- 神武门
    [131] = {"2301",82,82,5},     -- 柳善府
    [132] = {"1201",200,69,5},    -- 百武关
    [133] = {"2501",131,118,5},   -- 松月关
    [134] = {"0",100,100,5},      -- 九泉
    [135] = {"1401",96,195,5},    -- 南林
    [136] = {"1601",138,168,5},   -- 北海冰宫
    [137] = {"701",75,80,5},      -- 虎峡谷
    [138] = {"1901",59,170,5},    -- 花亭平原
    [139] = {"0",100,100,5},      -- 银币广场
    [140] = {"2701",48,30,5},     -- 燕飞阁
}
-- 禁止使用传送、土灵符地图
local banMoveMap = {
    ["10001"] = true,  -- 跨服势力战地图
}

-- 回城符使用，传送到指定城市
function moveItem.BackCity(actor, data)
    local itemid = tonumber(data[1])
    local posinfo = citypostab[itemid]
    if posinfo then
        if posinfo[1] == "0" then
            sendmsg(actor, 9, "该地图未配置")
            return
        end
        local x, y = targetinfo(actor, "X"), targetinfo(actor, "Y")
        local mapid = targetinfo(actor, "NEWMAP")
        mapmove(actor, posinfo[1], posinfo[2], posinfo[3], posinfo[4])
        local itemname = fieldvalue(actor, string.format("%d_%s", itemid, "Name"))
        takeitem(actor, itemname .. "#1#0")

        if not checkmirrormap(mapid) then
            local TuLingPosTab = gethumvar(actor, VarCfg.T_TuLingPosTab) or ""
            if TuLingPosTab ~= "" then
                TuLingPosTab = json2tbl(TuLingPosTab)
            else
                TuLingPosTab = {}
            end
            TuLingPosTab["-1"] = {mapid, x, y}    -- 记录最后一次使用回城符地点
            sethumvar(actor, VarCfg.T_TuLingPosTab, tbl2json(TuLingPosTab))
        end
    end
    
end

-- 使用土灵符，传送到已记录的任务坐标
function moveItem.usetuling(actor, data)
    local count = getItemNum(actor, "土灵符")
    if count < 1 then
        sendmsg(actor, 9, "土灵符不足！")
        return
    end
    local mapid = targetinfo(actor, "NEWMAP")
    -- 禁止使用传土灵符地图
    if banMoveMap[""..mapid] then
        sendmsg(actor, 9, "当前地图禁止使用土灵符！")
        return
    end
    local index = data[1] or -1
    local TuLingPosTab = gethumvar(actor, VarCfg.T_TuLingPosTab) or ""
    if TuLingPosTab ~= "" then
        TuLingPosTab = json2tbl(TuLingPosTab)
    else
        TuLingPosTab = {}
    end
    --dump(TuLingPosTab, "TuLingPosTab")
    if not TuLingPosTab[""..index] then
        --print("TuLingPosTab1")
        sendmsg(actor, 9, "请先记录坐标")
        return
    end
    --print("TuLingPosTab2")
    delItemNum(actor, "土灵符", 1)
    mapmove(actor, TuLingPosTab[""..index][1], TuLingPosTab[""..index][2], TuLingPosTab[""..index][3], 2)
end

-- 记录土灵符坐标
function moveItem.addpos(actor, data)
    local index = data[1]
    local name = data[2] or ""
    local TuLingPosTab = gethumvar(actor, VarCfg.T_TuLingPosTab) or ""
    if TuLingPosTab ~= "" then
        TuLingPosTab = json2tbl(TuLingPosTab)
    else
        TuLingPosTab = {}
    end
    local x, y = targetinfo(actor, "X"), targetinfo(actor, "Y")
    local mapid = targetinfo(actor, "NEWMAP")
    local mapname = targetinfo(actor, "MAPTITLE")
    if name == "" then
        name = x .. "," .. y
    end
    TuLingPosTab[""..index] = {mapid, x, y, mapname, name}
    sethumvar(actor, VarCfg.T_TuLingPosTab, tbl2json(TuLingPosTab))
    Message.sendmsgEx(actor, "tulingfuPanl", "Updata", {param1 = TuLingPosTab})
end

-- 删除土灵符坐标
function moveItem.delpos(actor, data)
    local index = data[1]
    local TuLingPosTab = gethumvar(actor, VarCfg.T_TuLingPosTab) or ""
    if TuLingPosTab ~= "" then
        TuLingPosTab = json2tbl(TuLingPosTab)
    else
        TuLingPosTab = {}
    end
    TuLingPosTab[""..index] = nil
    sethumvar(actor, VarCfg.T_TuLingPosTab, tbl2json(TuLingPosTab))
    Message.sendmsgEx(actor, "tulingfuPanl", "Updata", {param1 = TuLingPosTab})
end

-- 使用传送符，传送到指定坐标
function moveItem.move(actor, data)
    local count = getItemNum(actor, "传送符")
    if count < 1 then
        sendmsg(actor, 9, "传送符不足！")
        return
    end
    local mapid, x, y = data[1][1], data[1][2], data[1][3]
    if banMoveMap[""..mapid] then
        sendmsg(actor, 9, "当前地图禁止使用传送符！")
        return
    end
    delItemNum(actor, "传送符", 1)
    mapmove(actor, mapid, math.floor(x), math.floor(y), 2)
    local isauto = gethumvar(actor, VarCfg.N_task_xunlu_auto)
    if isauto == 1 then
        sethumvar(actor, VarCfg.N_task_xunlu_auto, 0)
    end
    GameEvent.push(EventCfg.UseMoveItem, actor)
end

-- 双击使用时QF触发
GameEvent.add(EventCfg.stdUseItem, function (actor, itemID,itemobj,useNumber,param1,param2)  -- 双击使用时QF触发
    -- print(param1," ",param2)
    if citypostab[itemID] then
        local posinfo = citypostab[itemID]
        if posinfo then
            if posinfo[1] == "0" then
                sendmsg(actor, 9, "该地图未配置")
                return
            end
            mapmove(actor, posinfo[1], posinfo[2], posinfo[3], posinfo[4])
        end
    end
end, moveItem)

-- 死亡事件，自动记录当前位置到土灵符
GameEvent.add(EventCfg.onPlayDie, function(actor, target)
    local x, y = targetinfo(actor, "X"), targetinfo(actor, "Y")
    local mapid = targetinfo(actor, "NEWMAP")
    if not checkmirrormap(mapid) then
        local TuLingPosTab = gethumvar(actor, VarCfg.T_TuLingPosTab) or ""
        if TuLingPosTab ~= "" then
            TuLingPosTab = json2tbl(TuLingPosTab)
        else
            TuLingPosTab = {}
        end
        TuLingPosTab["0"] = {mapid, x, y}
        sethumvar(actor, VarCfg.T_TuLingPosTab, tbl2json(TuLingPosTab))
    end
    
end, moveItem)

-- 注册网络消息
Message.RegisterNetMsg(ssrNetMsgCfg.moveItem, moveItem)

return moveItem



