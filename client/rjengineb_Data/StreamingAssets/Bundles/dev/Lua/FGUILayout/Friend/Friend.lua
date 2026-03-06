Friend = {}

function Friend.main()
    -- 好友列表刷新
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_LIST_UPDATE, "Friend", function(friendList)

    end)

    -- 黑名单列表刷新
    SL:RegisterLUAEvent(LUA_EVENT_BLACK_LIST_UPDATE, "Friend", function(blackList)

    end)

    -- 好友申请通知
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_APPLY, "Friend", function(data)

    end)

    -- 对方拒绝好友申请
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_REFUSE, "Friend", function(str)
        local splitPos = string.find(str, "&")
        if not splitPos then return end
        local name = string.sub(str, splitPos + 1)
        if name and name ~= "" then
            ShowSystemTips(string.format(GET_STRING(40020007), name))
        end
    end)

    -- 对方同意好友申请
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_AGREE, "Friend", function(str)
        local splitPos = string.find(str, "&")
        if not splitPos then return end
        local name = string.sub(str, splitPos + 1)
        if name and name ~= "" then
            ShowSystemTips(string.format(GET_STRING(40020008), name))
        end
    end)

    -- 申请好友，发送成功
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_SENDED, "Friend", function()
        ShowSystemTips(GET_STRING(40020017))
    end)

    -- 申请好友，已经是好友
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_ALREADY, "Friend", function()
        ShowSystemTips(GET_STRING(40020004))
    end)

    -- 删除好友成功
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_DELETE, "Friend", function(data)
        ShowSystemTips(string.format(GET_STRING(40020011), data.UserName))
    end)

    -- 添加黑名单成功
    SL:RegisterLUAEvent(LUA_EVENT_BLACK_ADD, "Friend", function(str)
        local splitPos = string.find(str, "&")
        if not splitPos then return end
        local name = string.sub(str, splitPos + 1)
        if name and name ~= "" then
            ShowSystemTips(string.format(GET_STRING(40020009), name))
        end
    end)

    -- 删除黑明单成功
    SL:RegisterLUAEvent(LUA_EVENT_BLACK_DELETE, "Friend", function(data)
        ShowSystemTips(string.format(GET_STRING(40020010), data.UserName))
    end)

    -- 好友申请列表
    SL:RegisterLUAEvent(LUA_EVENT_APPLY_LIST_UPDATE, "Friend", function(applyList)

    end)

    -- 好友搜索数据刷新
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_SEARCH_UPDATE, "Friend", function(data)

    end)

    -- 宿敌列表刷新
    SL:RegisterLUAEvent(LUA_EVENT_ENEMY_LIST_UPDATE, "Friend", function(enemyList)

    end)

    -- 随机好友列表
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_RANDOM_UPDATE, "Friend", function(randomList)

    end)

    -- 最近聊天列表
    SL:RegisterLUAEvent(LUA_EVENT_RECENT_CHAT_LIST_UPDATE, "Friend", function(recentList)

    end)

    -- 好友错误码 
    SL:RegisterLUAEvent(LUA_EVENT_FRIEND_MSG_ERROR, "Friend", function(errorCode)
        SL:Print("=======================Friend Error Msg:" .. errorCode)
        local tipStr
        if errorCode == -1 then
            tipStr = GET_STRING(40020002)
        elseif errorCode == -2 then
            tipStr = GET_STRING(40020003)
        elseif errorCode == -3 then
            tipStr = GET_STRING(40020004)
        elseif errorCode == -4 then
            tipStr = GET_STRING(40020005)
        elseif errorCode == -5 then
            tipStr = GET_STRING(40020006)
        elseif errorCode == -6 then
            tipStr = GET_STRING(40020018)
        elseif errorCode == -7 then
            tipStr = GET_STRING(40020019)
        else
            SL:Print("==================UnDefined Friend Error Msg" .. errorCode)
            return
        end

        if not tipStr then 
            return 
        end
        ShowSystemTips(tipStr)
    end)
end