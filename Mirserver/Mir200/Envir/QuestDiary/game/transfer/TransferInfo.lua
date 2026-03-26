local TransferInfo = {}

TransferInfo.config = require("Envir/QuestDiary/game_config/Transfer.lua")

for _,v in pairs(TransferInfo.config) do
    TransferInfo[v.ClassID] = TransferInfo[v.ClassID] or {}
    TransferInfo[v.ClassID][v.Type] = TransferInfo[v.ClassID][v.Type] or v
end

function TransferInfo.getCurrent(actor)
    return targetinfo(actor,"RELEVEL")
end

function TransferInfo.doTransfer(actor)
    local jb = job(actor)
    local zy = targetinfo(actor,"GOODEVILID")
    local transfer = TransferInfo[jb] and TransferInfo[jb][zy]
    if transfer then
        settargetinfo(actor,"RELEVEL",transfer.TransferLV+1)
        Message.sendmsgEx(actor, "MainMission","TransferComplete")
    end
end

return TransferInfo 