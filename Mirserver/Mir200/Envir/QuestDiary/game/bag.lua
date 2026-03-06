bag = {}
local filname = "bag"

function bag.setAutoPick(actor,data)
    sethumvar(actor,VarCfg.U_AutoPick,data)
    pickupitems(actor, data, 15, 500,999)
end

function bag.setAutoSell(actor,data)
    sethumvar(actor,VarCfg.U_AutoSell,data)
end

function bag.setFilterLv(actor,data)
    sethumvar(actor,VarCfg.U_AutoFilterByLv, data)
end

function bag.sellAll(actor,data)
    recycleAllItem(actor,data)
    Message.sendmsgEx(actor, "BagRecycleViewModel","updateView")
end

function bag.openWareShop(actor)
    opennpcshop(actor, 1, 1, 1,"ÀÊ…Ì…ÃµÍ")
end

function bag.setCheckBox(actor,data)
    local allCheckBox = gethumvar(actor,VarCfg.T_AUTO_SELL_IDS)
    local name = data.boxName
    local status = data.status
    if allCheckBox == "" or allCheckBox == 0 then
        allCheckBox = {}
    else
        allCheckBox = json2tbl(allCheckBox)
    end
    allCheckBox[name] = status
    sethumvar(actor,VarCfg.T_AUTO_SELL_IDS,tbl2json(allCheckBox))
end
Message.RegisterNetMsg(ssrNetMsgCfg.bag, bag)
return bag