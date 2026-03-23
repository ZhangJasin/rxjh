-- 采集

Collection = {}

function Collection.main()
    -- 采集
    SL:RegisterLUAEvent(LUA_EVENT_SELECT_COLLECT, "Collection", function(collectID)
        SL:RequestCollect(collectID)
    end)

    SL:RegisterLUAEvent(LUA_EVENT_COLLECT_BEGIN, "Collection", function(time)
        FGUI:Open("Collection", "CollectionPanel", time, FGUI_LAYER.NORMAL, {destroyTime = -1})
    end)

    SL:RegisterLUAEvent(LUA_EVENT_COLLECT_ABORT, "Collection", function()
        FGUI:Close("Collection", "CollectionPanel")
    end)
end