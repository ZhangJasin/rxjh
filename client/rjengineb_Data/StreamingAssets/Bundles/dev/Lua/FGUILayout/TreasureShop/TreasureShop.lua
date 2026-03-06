TreasureShop = {}

function TreasureShop.main()
    SL:RegisterLUAEvent(LUA_EVENT_NPCSTORE_RECY_RES, "TreasureShop", TreasureShop.onResRecycleItem)
end

-- 回收消息
function TreasureShop.onResRecycleItem(code)
    if code > 0 then return end
    if code == 0 then
        SL:ShowSystemTips(GET_STRING(30000107))
    elseif code == -1 then
        SL:ShowSystemTips(GET_STRING(30000104))
    elseif code == -2 then
        SL:ShowSystemTips(GET_STRING(30000105))
    else
        SL:ShowSystemTips(GET_STRING(30000106))
    end
end