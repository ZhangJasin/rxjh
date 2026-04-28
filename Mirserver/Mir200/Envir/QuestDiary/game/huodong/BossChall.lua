
BossChall = {}
local filname = "BossChall"
local SysConstant  =  require("Envir/QuestDiary/game_config/cfgcsv/SysConstant.lua")
local BossInfo_Cfg  =  require("Envir/QuestDiary/game_config/cfgcsv/BOSSInfo.lua")
local BossPool_Cfg  =  require("Envir/QuestDiary/game_config/cfgcsv/BOSSPool.lua")


local function _getBossData(actor)
    return {}
end
local function _getChalledCount(actor)
    return gethumvar(actor, VarCfg.U_BOSS_Count) or 0
end
function BossChall.chall(actor,data)
    local index = tonumber(data[1]) or 0
end
function BossChall.refresh(actor,data)
    local index = tonumber(data[1]) or 0

end

function BossChall.getData(actor)
    Message.sendmsg(actor, ssrNetMsgCfg.BOSSChall_RetData,_getChalledCount(actor),nil,nil,_getBossData(actor))
end

local function _refreshBossPool(actor)
    local minLv = tonumber(SysConstant['Boss_Open_LV']["Value"]) or 35
    local curLv = level(actor)
    if curLv < minLv then return end
    BossChall.getData(actor)
end
GameEvent.add(EventCfg.onResetday, function (actor)
    sethumvar(actor, VarCfg.U_BOSS_Count, 0)
    _refreshBossPool(actor)
end, BossChall)
GameEvent.add(EventCfg.onPlayLevelUp, function (actor, cur_level, before_level)         -- Éý¼¶´¥·¢
    local minLv = tonumber(SysConstant['Boss_Open_LV']["Value"]) or 35
    if before_level < minLv and cur_level >= minLv then
        _refreshBossPool(actor)
    end
end, BossChall)

Message.RegisterNetMsg(ssrNetMsgCfg.BOSSChall, BossChall)
return BossChall