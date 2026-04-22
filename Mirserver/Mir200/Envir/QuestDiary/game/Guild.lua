
Guild = {}
local filname = "Guild"
-- function Guild.buy(actor,data)
--     local num = money(actor, 20)
--     local total = tonumber(data.count) * tonumber(data.price)
--     if num < total then 
--         return sendmsg(actor,9,"门派贡献不足")
--     end
--     delItemNum(actor,20,total)
--     local itemJson = {}
--     itemJson[tonumber(data.Itemid)]= tonumber(data.count) 
--     giveItmeByList(actor,itemJson)
--     sendmsg(actor,9,"购买成功")
--     Message.sendmsgEx(actor, "GuildMainPanel","UpdataPage2")
-- end

function Guild.getTaskData(actor)
    Message.sendmsg(actor, ssrNetMsgCfg.Guild_TaskData,  10,510101,3)
end
Message.RegisterNetMsg(ssrNetMsgCfg.Guild, Guild)
return Guild