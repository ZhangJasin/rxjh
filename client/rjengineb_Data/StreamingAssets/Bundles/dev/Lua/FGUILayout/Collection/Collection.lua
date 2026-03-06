-- 采集

Collection = {}

function Collection.main()
    -- 采集
    SL:RegisterLUAEvent(LUA_EVENT_SELECT_COLLECT, "Collection", function(collectID)
        SL:RequestCollect(collectID)
    end)
    SL:RegisterLUAEvent(LUA_EVENT_COLLECT_BEGIN, "Collection", function(time)
    end)
    SL:RegisterLUAEvent(LUA_EVENT_COLLECT_ABORT, "Collection", function()
    end)
end