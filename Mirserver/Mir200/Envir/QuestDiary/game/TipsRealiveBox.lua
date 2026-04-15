--require("Envir/QuestDiary/util.lua")
TipsRealiveBox = {}
local filname = "TipsRealiveBox"
local TipRoleDie = require("Envir/QuestDiary/game_config/cfgcsv/TipRoleDie.lua")
local SpeMapRealive = {
    ['10001'] = '10001',
}
-- 打开复活提示框并处理复活逻辑
function TipsRealiveBox.openshow(actor, data)
    local index1 = tonumber(data[1])
    if not TipRoleDie[index1] then
        return
    end

    -- 处理消耗道具逻辑
    if TipRoleDie[index1]['xhitem_arr'] then
        local itemId = TipRoleDie[index1]['xhitem_arr'][1]
        local needcount = TipRoleDie[index1]['xhitem_arr'][2]
        local count = getItemNum(actor, itemId)
        local itemname = fieldvalue(actor, string.format("%d_%s", itemId, "Name"))
        if needcount > count then
            sendmsg(actor, 9, "货币不足")
            return
        end
        delItemNum(actor, itemId, needcount)
    end

    -- 计算复活后血量和蓝量
    local hppct, mppct = TipRoleDie[index1]['hpmp_arr'][1], TipRoleDie[index1]['hpmp_arr'][2]
    local maxhp, maxmp = abil(actor, 1), abil(actor, 2)
    local fuhp = math.floor(maxhp * hppct / 100)
    local fhmp = math.floor(maxmp * mppct / 100)

    -- 处理经验扣除逻辑
    if TipRoleDie[index1]['exp'] then
        local curexp = currabil(actor, 3)
        changeexp(actor, "-", math.ceil(curexp * TipRoleDie[index1]['exp'] / 100))
    end

    -- 执行复活及属性恢复
    realive(actor) -- 复活人物
    changeabil(actor, 1, "=", fuhp)
    changeabil(actor, 2, "=", fhmp)

    -- 特殊复活效果处理
    if index1 == 3 then
        addtimerex(actor, 101, 100, 1,"@ontimer101","")
    end
    GameEvent.push(EventCfg.onPlayRealive, actor)
    -- 通知客户端更新
    Message.sendmsgEx(actor, "TipRoleDiePanl", "Updata", {})
end


-- 死亡事件监听，打开复活提示框
GameEvent.add(EventCfg.onPlayDie, function(actor, target)
    local mapid = targetinfo(actor, "NEWMAP")

    local warInfo = gethumvar(0,VarCfg.A_FactionWars)
    local isWarMap = false
    if warInfo ~= "" then
        warInfo = json2tbl(warInfo)
        for i=1,#warInfo.warMapInfos do
            if mapid == warInfo.warMapInfos[i].mapid then
                isWarMap = true
                break
            end
        end
    end
   
    if SpeMapRealive[mapid] then
        return
    end
    if isWarMap then
        Message.sendmsgEx(actor, "TipWarDiePanl", "Open", {})
    else
        Message.sendmsgEx(actor, "TipRoleDiePanl", "Open", {})
    end
end, TipsRealiveBox)

-- 注册网络消息
Message.RegisterNetMsg(ssrNetMsgCfg.TipsRealiveBox, TipsRealiveBox)

return TipsRealiveBox