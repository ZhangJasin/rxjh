Changwan = {}
local filname = "Changwan"

function Changwan.recv(actor)
    print("服务端领取畅玩特权")
    sendmsg(actor, 9, "服务端领取畅玩特权")
end

Message.RegisterNetMsg(ssrNetMsgCfg.Changwan, Changwan)
return Changwan
