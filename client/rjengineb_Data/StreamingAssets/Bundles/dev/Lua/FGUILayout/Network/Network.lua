-- 断线
Network = {}

function Network.main()
    SL:RegisterLUAEvent(LUA_EVENT_NETWORK_DISCONNECT,"Network",function(data)
        print("断线了")
    end)
end