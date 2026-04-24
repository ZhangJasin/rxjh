equipCollect = {}

local config = require("Envir/QuestDiary/game_config/cfgcsv/equipCollect.lua")


function equipCollect.ReqActive(actor, id)
    --Message.sendmsgEx(actor, equipCollectData, "RetActive", {
    --    type = "red",
    --    max = 10000,
    --    now = 10000,
    --    icon = icon
    --})
end

GameEvent.add(EventCfg.onLoginEnd, function(actor)
end, equipCollect)

GameEvent.add(EventCfg.onNewHuman, function(actor)

end, equipCollect)

Message.RegisterNetMsg(ssrNetMsgCfg.equipCollect, equipCollect)
return equipCollect
