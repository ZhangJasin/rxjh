local FuncDockUtil = {}

-- 功能菜单类型
FuncDockUtil.FuncDockType = {
    Func_Player_Head        = 1,    -- 点击玩家头像
    Func_Friend             = 2,    -- 好友界面
    Func_Team               = 3,    -- 左侧组队导航栏
    Func_Guild              = 4,    -- 行会界面
    Func_Friend_Recent      = 5,    -- 好友最近联系界面
    Func_Friend_Enemy       = 6,    -- 好友仇敌界面
    Func_Friend_BlackList   = 7,    -- 好友黑名单界面
    Func_TeamLayer          = 8,    -- 组队界面
    Func_Monster_Head       = 9,    -- 点击人形怪头像
    Func_Near_Player        = 10,   -- 附近玩家
    Func_Archenemy          = 11,   -- 宿敌
    Func_Player_Rank        = 12    -- 排行榜
}

local FuncType = FuncDockUtil.FuncDockType

-- 按钮操作类型
FuncDockUtil.BtnOperatorType = {
    look_role       = 1,    -- 查看玩家
    add_friend      = 2,    -- 添加好友
    chat            = 3,    -- 私聊
    team            = 4,    -- 组队
    trade           = 5,    -- 交易
    invite_team     = 6,    -- 邀请入队
    invite_guild    = 7,    -- 邀请入会
    apply_team      = 8,    -- 申请入队
    out_team        = 10,   -- 踢出队伍
    set_teamLeader  = 11,   -- 升为队长
    add_blacklist   = 12,   -- 拉黑
    out_guild       = 13,   -- 踢出行会
    call_teammate   = 14,   -- 召集队员
    send_position   = 15,   -- 发送位置
    exit_team       = 16,   -- 退出队伍
    look_team       = 17,   -- 查看队伍
    out_blacklist   = 21,   -- 移出黑名单
    delete_friend   = 22,   -- 删除好友

    challenge       = 24,   -- 挑战
    horse_invite    = 25,   -- 骑马邀请

    appoint_rank1   = 101,  -- 转移会长
    appoint_rank2   = 102,  -- 任命副会
    appoint_rank3   = 103,  -- 行会 任命职位
    appoint_rank4   = 104,  -- 行会 任命职位
    appoint_rank5   = 105,  -- 行会 任命职位
}
local BtnType = FuncDockUtil.BtnOperatorType

FuncDockUtil.BtnTypeShowName = {
    [BtnType.look_role]     = GET_STRING(40030001),
    [BtnType.add_friend]    = GET_STRING(40030002),
    [BtnType.chat]          = GET_STRING(40030003),
    [BtnType.team]          = GET_STRING(40030004),
    [BtnType.trade]         = GET_STRING(40030005),
    [BtnType.invite_team]   = GET_STRING(40030006),
    [BtnType.invite_guild]  = GET_STRING(40030007),
    [BtnType.apply_team]    = GET_STRING(40030008),
    [BtnType.out_team]      = GET_STRING(40030009),
    [BtnType.set_teamLeader]= GET_STRING(40030010),
    [BtnType.add_blacklist] = GET_STRING(40030011),
    [BtnType.out_guild]     = GET_STRING(40030012),
    [BtnType.call_teammate] = GET_STRING(40030013),
    [BtnType.send_position] = GET_STRING(40030014),
    [BtnType.exit_team]     = GET_STRING(40030015),
    [BtnType.look_team]     = GET_STRING(40030110),
    [BtnType.out_blacklist] = GET_STRING(40030016),
    [BtnType.delete_friend] = GET_STRING(40030017),
    
    [BtnType.challenge]     = GET_STRING(40030018),
    [BtnType.horse_invite]  = GET_STRING(40030019),
}

function FuncDockUtil:GetBtnTypeShowNameDynamic(type)
    -- 行会称号
    local index = type - BtnType.appoint_rank1 + 1
    local rankInfo = SL:GetValue("GUILD_SORT_RANK_INFO")
    if rankInfo and rankInfo[index] then
        return string.format(GET_STRING(40030107), rankInfo[index].Title)
    end
    return nil
end

-- 不同类型功能菜单对应按钮组
FuncDockUtil.FuncConfig = {
    [FuncType.Func_Player_Rank] = {
        BtnType.look_role,
        BtnType.chat,
        BtnType.invite_team,
        BtnType.apply_team,
        BtnType.add_friend,
        BtnType.trade,
        BtnType.invite_guild,
        BtnType.add_blacklist,
        BtnType.out_blacklist,
        -- BtnType.horse_invite
    },
    [FuncType.Func_Player_Head] = {
        BtnType.look_role,
        BtnType.chat,
        BtnType.invite_team,
        BtnType.apply_team,
        BtnType.add_friend,
        BtnType.trade,
        BtnType.invite_guild,
        BtnType.add_blacklist,
        BtnType.out_blacklist,
        -- BtnType.horse_invite
    },
    [FuncType.Func_Team] = {
        BtnType.look_role,
        BtnType.add_friend,
        BtnType.trade,
        BtnType.invite_guild,
        BtnType.chat,
        BtnType.set_teamLeader,
        BtnType.out_team,
        BtnType.send_position,
        BtnType.exit_team,
        BtnType.call_teammate,
        BtnType.look_team
    },
    [FuncType.Func_TeamLayer] = {
        BtnType.look_role,
        BtnType.add_friend,
        BtnType.trade,
        BtnType.invite_guild,
        BtnType.chat,
        BtnType.set_teamLeader,
        BtnType.out_team,
        BtnType.send_position,
        BtnType.exit_team,
        BtnType.call_teammate,
        BtnType.look_team
    },
    [FuncType.Func_Guild] = {
        BtnType.look_role,
        BtnType.add_friend,
        BtnType.chat,
        BtnType.invite_team,
        BtnType.appoint_rank1,
        BtnType.appoint_rank2,
        BtnType.appoint_rank3,
        BtnType.appoint_rank4,
        BtnType.appoint_rank5,
        BtnType.out_guild
    },
    [FuncType.Func_Friend] = {
        BtnType.look_role,
        BtnType.delete_friend,
        BtnType.invite_team,
        BtnType.add_blacklist
    },
    [FuncType.Func_Friend_Recent] = {
        BtnType.look_role,
        BtnType.delete_friend,
        BtnType.invite_team,
        BtnType.add_blacklist,
        BtnType.add_friend
    },
    [FuncType.Func_Archenemy] = {
        BtnType.look_role,
        BtnType.invite_team,
        BtnType.add_friend,
        BtnType.add_blacklist
    },
    [FuncType.Func_Friend_Enemy] = {
        BtnType.look_role,
        BtnType.chat,
        BtnType.add_friend,
        BtnType.trade,
        BtnType.invite_team,
        BtnType.invite_guild,
        BtnType.add_blacklist,
        BtnType.delete_enemy
    },
    [FuncType.Func_Friend_BlackList] = {BtnType.look_role, BtnType.out_blacklist},
    [FuncType.Func_Monster_Head] = {BtnType.look_role},
    [FuncType.Func_Near_Player] = {
        BtnType.look_role,
        BtnType.chat,
        BtnType.invite_team,
        BtnType.apply_team,
        BtnType.add_friend,
        BtnType.trade,
        BtnType.invite_guild,
        BtnType.add_blacklist,
        BtnType.out_blacklist,
        -- BtnType.challenge
    }
}
local FuncConfig = FuncDockUtil.FuncConfig

local typeFunction = {}
-----------------组队-----------------
typeFunction[BtnType.invite_team] = function(targetId)
    --邀请入队
    SL:RequestInviteJoinTeam(targetId)
end
typeFunction[BtnType.apply_team] = function(targetId)
    --申请入队
    SL:RequestApplyJoinTeam(targetId)
end
typeFunction[BtnType.out_team] = function(targetId)
    --踢出队伍
    SL:RequestSubTeamMember(targetId)
end
typeFunction[BtnType.set_teamLeader] = function(targetId)
    --升为队长
    SL:RequestTransferTeamLeader(targetId)
end
typeFunction[BtnType.call_teammate] = function(targetId)
    --召集队员
    SL:RequestCallTeamMember()
end
typeFunction[BtnType.send_position] = function(targetId)
    --发送坐标
    local ChatProxy = global.Facade:retrieveProxy(global.ProxyTable.ChatProxy)
    SL:RequestSendChatPosMsg(SLDefine.CHAT_CHANNEL.Team)
end
typeFunction[BtnType.exit_team] = function(targetId)
    --退出队伍
    SL:RequestLeaveTeam()
end
typeFunction[BtnType.look_team] = function(targetId)
    --查看队伍
    FGUIFunction:OpenTeamFrameUI(FGUIDefine.TeamPage.MyTeam)
end


function FuncDockUtil.SetLayerType(data)
    if data.targetId == nil then
        data.targetId = -1
    end

    FuncDockUtil._targetId = data.targetId
    FuncDockUtil._targetName = data.targetName
    FuncDockUtil._sex = data.Sex
    FuncDockUtil._job = data.Job
    FuncDockUtil._level = data.Level
    FuncDockUtil._guildName = data.GuildName
    FuncDockUtil._avatarID = data.AvatarID
end

---------------行会------------------
typeFunction[BtnType.invite_guild] = function(targetId)
    --邀请入会
    SL:RequestGuildInviteMember(targetId)
end
typeFunction[BtnType.out_guild] = function(targetId)
    --踢出行会
    SL:RequestGuildRemoveMember(targetId)
end
typeFunction[BtnType.appoint_rank2] = function(targetId)
    --任命副帮主
    local rankId = SL:GetValue("GUILD_RANK_ID_BY_INDEX", 2)
    if rankId then
        SL:RequestGuildAppointRank(targetId, rankId)   
    end  
end
typeFunction[BtnType.appoint_rank3] = function(targetId)
    --任命长老
    local rankId = SL:GetValue("GUILD_RANK_ID_BY_INDEX", 3)
    if rankId then
        SL:RequestGuildAppointRank(targetId, rankId)   
    end  
end
typeFunction[BtnType.appoint_rank4] = function(targetId)
    --任命精英
    local rankId = SL:GetValue("GUILD_RANK_ID_BY_INDEX", 4)
    if rankId then
        SL:RequestGuildAppointRank(targetId, rankId)   
    end   
end
typeFunction[BtnType.appoint_rank5] = function(targetId)
    -- 任命成员
    local rankId = SL:GetValue("GUILD_RANK_ID_BY_INDEX", 5)
    if rankId then
        SL:RequestGuildAppointRank(targetId, rankId)   
    end  
end
typeFunction[BtnType.appoint_rank1] = function(targetId)
    --转移会长
    local info = SL:GetValue("GUILD_MEMBER_INFO", targetId)
    if not info then return end
    local data    = {}
    data.str = string.format(GET_STRING(40030105), SL:GetValue("GUILD_OFFICIAL_NAME_BY_RANK", 0), info.UserName)
    data.btnDesc  = {GET_STRING(1001), GET_STRING(1000)}
    data.callback = function(type)
        if 1 == type then
            local rankId = SL:GetValue("GUILD_RANK_ID_BY_INDEX", 1)
            if rankId then
                SL:RequestGuildAppointRank(targetId, rankId)
            end
        end  
    end
    SL:OpenCommonDialog(data)
end

typeFunction[BtnType.look_role] = function(targetId)
    --查看 0:单装备面板 1:装备+属性面板
    SL:RequestLookPlayer(targetId)
end

typeFunction[BtnType.chat] = function(targetId)
    --私聊
    local data = {
        UserID = targetId,
        UserName = FuncDockUtil._targetName,
        Job = FuncDockUtil._job,
        Sex = FuncDockUtil._sex,
        Level = FuncDockUtil._level,
        GuildName = FuncDockUtil._guildName,
        AvatarID = FuncDockUtil._avatarID,
        page = FGUIDefine.FriendPage.Recent,
        selectChannel = 1,
        selectFriend = targetId,
        targetData = {
            TargetName = FuncDockUtil._targetName,
            TargetLevel = FuncDockUtil._level,
            TargetJob = FuncDockUtil._job,
            TargetSex = FuncDockUtil._sex,
        },
    }

    SL:PrivateChatWithTarget(data)
    FGUI:Open("Friend_pc", "PCFriendPanel", data)
    SL:onLUAEvent(LUA_EVENT_CHAT_ADD_PRIVATE_ITEM, data)
end

typeFunction[BtnType.trade] = function(targetId)
    --交易
    SL:RequestTrade(targetId)--TODO
end

typeFunction[BtnType.add_friend] = function(targetId)
    --添加好友
    SL:RequestAddFriend(targetId)
end

typeFunction[BtnType.out_blacklist] = function(targetId)
    --移出黑名单
    SL:RequestOutBlacklist(targetId)
end

typeFunction[BtnType.delete_friend] = function(targetId)
    --删除好友
    local data    = {}
    data.btnDesc  = {GET_STRING(1001), GET_STRING(1000)}
    data.str      = string.format(GET_STRING(40030106), FuncDockUtil._targetName)
    data.callback = function(type)
        if 1 == type then
            SL:RequestDelFriend(targetId)
        end
    end
    SL:OpenCommonDialog(data)
end

typeFunction[BtnType.add_blacklist] = function(targetId)
    --拉黑
    local data    = {}
    data.btnDesc  = {GET_STRING(1001), GET_STRING(1000)}
    data.str      = string.format(GET_STRING(40030109), FuncDockUtil._targetName)
    data.callback = function(type)
        if 1 == type then
            local isFriend = SL:GetValue("SOCIAL_IS_FRIEND", targetId)
            if isFriend then 
                SL:RequestDelFriend(targetId)
                SL:RequestAddBlacklist(targetId)
            else 
                SL:RequestAddBlacklist(targetId)
            end 
        end
    end
    SL:OpenCommonDialog(data)
end
        
typeFunction[BtnType.horse_invite] = function(targetId)
    --邀请上马
    -- SL:RequestInviteInHorse(targetId)--TODO
end

-- 传入target信息
function FuncDockUtil:GetBtns(targetId, funcDockType)
    local allBtns = FuncConfig[funcDockType]
    local btns = {}
    for k, btnType in pairs(allBtns) do
        if SL:GetValue("CHECK_FUNCBTN_SHOW",funcDockType,btnType,targetId) then
            table.insert(btns, btnType)
        end
    end
    
    return btns
end

function FuncDockUtil:DoFunction(btnType, targetId)
    if typeFunction[btnType] then
        typeFunction[btnType](targetId)
    end
end

return FuncDockUtil