Guild = {}

function Guild.main()
    -- 行会操作失败
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_ERROR_TIPS, "Guild", function(errorcode)
        --     2 申请成功
        --    -1 名称为空
        --    -2 名字已经存在
        --    -3 没有准备好物品
        --    -4 缺少创建费用
        --    -5 你已经加入或拥有行会
        --    -6 对方已拥有行会
        --    -7 对方拒绝了你的申请
        --    -8 已经申请了 
        --    -9 已经联盟 
        --    -10 行会战争中
        --    -11 对方拒绝联盟 body = 拒绝行会GUID&拒绝行会名称
        --    -12 掌门禁止退出行会
        --    -13 职位数量超过上线
        --    -14 行会人数超过上线
        --    -15 设置职位错误
        --    -16 服务器禁止解散行会
        --    -17 玩家不是该行会成员
        --    -18 一键加入行会失败
        --    -19 已经在申请列表
        --    -21 与改玩家不同阵营，无法邀请加入门派
        if errorcode == 2 then   
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003021))
        elseif errorcode == -1 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003003))
        elseif errorcode == -2 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003004))
        elseif errorcode == -3 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003005))
        elseif errorcode == -4 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003006))
        elseif errorcode == -5 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003007))
        elseif errorcode == -6 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003008))
        elseif errorcode == -7 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003009))
        elseif errorcode == -8 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003010))
        elseif errorcode == -9 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003011))
        elseif errorcode == -10 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003012))
        elseif errorcode == -11 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003013))
        elseif errorcode == -12 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003019))
        elseif errorcode == -13 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003034))
        elseif errorcode == -14 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003035))
        elseif errorcode == -15 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003036))
        elseif errorcode == -16 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003038))
        elseif errorcode == -17 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003053))
        elseif errorcode == -18 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003054))
        elseif errorcode == -19 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003056))
        elseif errorcode == -21 then
            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003067))
        end
    end)
    -- 创建行会成功
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_CREATE, "Guild", function()
        SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003014))
        -- 关闭行会创建界面
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Close("Guild_pc", "PCGuildJoinList")
        else
            FGUI:Close("Guild", "GuildJoinList")
        end
        
        -- 显示行会主界面
        FGUIFunction:OpenGuildMainFrameUI(1)
    end)
    -- 加入行会成功
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_JOIN, "Guild", function()
        SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003028))
        -- 关闭行会创建界面
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Close("Guild_pc", "PCGuildJoinList")
        else
            FGUI:Close("Guild", "GuildJoinList")
        end   
    end)
    -- 主动退出行会返回
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_LEAVE, "Guild", function()
        SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003029))
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Close("Guild_pc", "PCGuildMainPanel")
        else
            FGUI:Close("Guild", "GuildMainPanel")
        end
        
        SL:RequestGuildInfo()
    end)
    -- 解散行会
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_DISBANDED, "Guild", function()
        SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003037))
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Close("Guild_pc", "PCGuildMainPanel")
        else
            FGUI:Close("Guild", "GuildMainPanel")
        end
        
        SL:RequestGuildInfo()
    end)
    -- 被踢出行会
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_BE_KICK, "Guild", function()
        SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003027))
        if SL:GetValue("IS_PC_OPER_MODE") then
             FGUI:Close("Guild_pc", "PCGuildMainPanel")
        else
            FGUI:Close("Guild", "GuildMainPanel")
        end
       
        SL:RequestGuildInfo()
    end)
    -- 设置允许自动加入
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_AUTO_JOIN, "Guild", function(autoJoin)
        local str = SL:GetValue("I18N_STRING", 10003030)
        SL:ShowSystemTips(str)
    end)
    -- 设置成员职位成功
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_APPOINT_RANK, "Guild", function()
        SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003026))
    end)
    -- 收到入会申请
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_USER_APPLY, "Guild", function(userName)
        if userName then
            SL:ShowSystemTips(userName..SL:GetValue("I18N_STRING", 10003052))
        end 

        -- 主界面气泡
        local function callback()
            if SL:GetValue("IS_PC_OPER_MODE") then
                FGUI:Open("Guild_pc", "PCGuildApplyList")
            else
                FGUI:Open("Guild", "GuildApplyList")
            end    
        end
        SL:AddBubbleTips(10, FGUIDefine.BubbleTipType.Guild, callback)
    end)

    -- 请求申请列表用于管理员气泡显示
    SL:RequestGuildApplydList()
    -- 收到服务器下发的申请列表
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_APPLYLIST, "Guild", function(applyList)
        if SL:GetValue("GUILD_CHECK_PERMISSION_APPROVE_APPLY") and applyList and applyList.List and #applyList.List > 0 then
            local function callback()
                if SL:GetValue("IS_PC_OPER_MODE") then
                    FGUI:Open("Guild_pc", "PCGuildApplyList")
                else
                    FGUI:Open("Guild", "GuildApplyList")
                end      
            end
            SL:AddBubbleTips(10, FGUIDefine.BubbleTipType.Guild, callback)
        end
    end)
    -- 删除成员成功
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_REMOVE_MEMBER, "Guild", function(userName)
        SL:ShowSystemTips(userName..SL:GetValue("I18N_STRING", 10003020))
        SL:RequestGuildMemberList()
    end)
    -- 收到来自行会会长邀请
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_INVITE, "Guild", function(guildID, guildName, masterName)
        SL:AddBubbleTips(11, FGUIDefine.BubbleTipType.Guild, function()
            SL:DelBubbleTips(11)
            local data = {}
            data.str = string.format(GET_STRING(10003047), masterName, guildName)
            data.btnDesc = {GET_STRING(1093), GET_STRING(1092)}
            data.callback = function (tag)
                if tag == 1 then
                    SL:RequestGuildApproveUserInvite(guildID)
                elseif tag == 2 then
                    SL:RequestGuildRejectUserInvite(guildID)
                end
            end
            SL:OpenCommonDialog(data)
        end)
    end)
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_INVITE_RESULT, "Guild", function(name)
        SL:ShowSystemTips(string.format(SL:GetValue("I18N_STRING", 10003043), name))
    end)
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_ERROR, "Guild", function(code, tip)
        SL:ShowSystemTips(tip)
    end)
end
