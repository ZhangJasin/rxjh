Team = {}

function Team.main()
    -- 组队创建返回
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_CREATE, "Team", function(data)
        ShowSystemTips(GET_STRING(40010008))
    end)

    -- 组队解散返回
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_LEAVE, "Team", function(iType)
        if iType == 1 then
            -- 离开队伍
            ShowSystemTips(GET_STRING(40010010))
        elseif iType == 2 then
            -- 被踢出队伍
            ShowSystemTips(GET_STRING(40010011))
        elseif iType == 3 then
            -- 解散
            -- ShowSystemTips(GET_STRING(40010018))
        end
    end)

    -- 加入队伍
    SL:RegisterLUAEvent(LUA_EVENT_JOIN_TEAM, "Team", function(userName, data)

    end)

    -- 离开队伍
    SL:RegisterLUAEvent(LUA_EVENT_LEAVE_TEAM, "Team", function(userName, data)
        ShowSystemTips(string.format(GET_STRING(40010009), userName))
    end)

    -- 组队成员信息刷新
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "Team", function(userName)

    end)

    -- 组队被邀请
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_BEINVITED_UPDATE, "Team", function(data)

    end)

    -- 组队邀请 已发送
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_BEINVITED_SENDED, "Team", function()
        ShowSystemTips(GET_STRING(40010026))
    end)

    -- 组队被邀请 拒绝
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_BEINVITED_REFUSE, "Team", function(str)
        local splitPos = string.find(str, "&")
        if not splitPos then return end
        local name = string.sub(str, splitPos + 1)
        if name and name ~= "" then
            ShowSystemTips(string.format(GET_STRING(40010015), name))
        end
    end)

    -- 申请入队列表刷新
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_APPLY_UPDATE, "Team", function(applyList)

    end)

    -- 申请入队 已发送
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_APPLY_SENDED, "Team", function()
        ShowSystemTips(GET_STRING(40010027))
    end)

    -- 申请入队 被拒绝
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_APPLY_REFUSE, "Team", function(str)
        local splitPos = string.find(str, "&")
        if not splitPos then return end
        local name = string.sub(str, splitPos + 1)
        if name and name ~= "" then
            ShowSystemTips(string.format(GET_STRING(40010016), name))
        end
    end)

    -- 附近队伍刷新
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_NEAR_UPDATE, "Team", function(nearTeam)

    end)

    -- 随机队伍刷新
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_RANDOM_UPDATE, "Team", function(randomTeam)

    end)


    -- 组队成员状态刷新
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_STATE_UPDATE, "Team", function(merber)

    end)

    -- 组队成员Hp/Mp刷新
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_HPMP_UPDATE, "Team", function(merber)

    end)

    -- 组队设置刷新
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_SETTING_UPDATE, "Team", function(data)

    end)

    -- 组队目标
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_TARGET_INFO, "Team", function()

    end)

    -- 组队错误码 
    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MSG_ERROR, "Team", function(errorCode, errorCode1)
        SL:Print("=================Team Error Msg:" .. errorCode)
        local tipStr
        if errorCode == -1 then
            tipStr = GET_STRING(40010001)
        elseif errorCode == -2 then
            tipStr = GET_STRING(40010002)
        elseif errorCode == -3 then
            tipStr = GET_STRING(40010003)
        elseif errorCode == -4 then
            tipStr = GET_STRING(40010004)
        elseif errorCode == -5 then
            tipStr = GET_STRING(40010005)
        elseif errorCode == -6 then
            tipStr = GET_STRING(40010006)
        elseif errorCode == -7 then
            tipStr = GET_STRING(40010007)
        elseif errorCode == -8 then
            tipStr = GET_STRING(40010017)
        elseif errorCode == -9 then
            tipStr = GET_STRING(40010013)
        elseif errorCode == -11 then
            tipStr = GET_STRING(40010032)
        elseif errorCode == -12 then
            if errorCode1 == 6 then 
                tipStr = GET_STRING(40010065)
            else 
                tipStr = GET_STRING(40010033)
            end 
        elseif errorCode == -13 then
            tipStr = GET_STRING(40010034)
        else   
            SL:Print("==================UnDefined Team Error Msg" .. errorCode)
            return
        end

        if not tipStr then 
            return 
        end
        ShowSystemTips(tipStr)
    end)
end