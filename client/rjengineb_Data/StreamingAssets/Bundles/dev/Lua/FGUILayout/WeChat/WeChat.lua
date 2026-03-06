-- 微信游戏圈数据
WeChat = {}

function WeChat.main()
    SL:RegisterLUAEvent(LUA_EVENT_WX_CLUB_DATA, "WeChat", function(data)
        SL:RequestWXClubDataSubmit(data)
    end)
end