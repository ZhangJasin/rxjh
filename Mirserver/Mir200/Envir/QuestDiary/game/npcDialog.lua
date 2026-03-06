npcDialog = {}
local filname = "npcDialog"

function npcDialog.toOpenShop(actor,data)
    opennpcshop(actor, 0, tonumber(data), 0,"ил╣Й")
end

GameEvent.add(EventCfg.onOpenNpc,function(actor,npcid)
    Message.sendmsgEx(actor, "npcDialog","update",npcid)
end,npcDialog)

Message.RegisterNetMsg(ssrNetMsgCfg.npcDialog, npcDialog)
return npcDialog