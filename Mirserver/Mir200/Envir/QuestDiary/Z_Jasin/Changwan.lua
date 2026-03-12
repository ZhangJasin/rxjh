Changwan = {}
local filname = "Changwan"
local itemLst = "香木宝盒#1&百宝箱#1&神匠之盒#1&白银宝盒#1&黄金宝盒#1&碧玉宝盒#1&符文之盒#1&冰灵宝盒#1&宝匣#1"

function Changwan.req(actor)
    local state = flag(actor, 010)
    Message.sendmsgEx(actor, "Changwan", "Ret", { param1 = state })
end

function Changwan.recv(actor)
    local state = tonumber(flag(actor, 010))
    if state == 1 then return sendmsg(actor, 9, "请勿重复领取！") end
    local bagNum = bagnilcount(actor)
    if bagNum < 9 then return sendmsg(actor, 9, "背包空间不足！") end

    local objInfo = giveitem(actor, itemLst)
    set(actor, 010, 1)
    sendmsg(actor, 9, "领取成功！")
    Message.sendmsgEx(actor, "Changwan", "Ret", { param1 = tonumber(flag(actor, 010)) })
end

Message.RegisterNetMsg(ssrNetMsgCfg.Changwan, Changwan)
return Changwan
