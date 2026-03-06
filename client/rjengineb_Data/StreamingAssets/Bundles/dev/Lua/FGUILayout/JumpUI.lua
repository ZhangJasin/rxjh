JumpUI = {}

local LINK_TYPE = {
    Equip               = 1,            -- 角色-装备
    Bag                 = 2,            -- 背包
    Guild               = 3,            -- 智能行会界面
    GuildMain           = 4,            -- 行会-主界面
    GuildMember         = 5,            -- 行会成员列表
    GuildList           = 6,            -- 行会列表
    GuildCreate         = 7,            -- 行会创建
    Mail                = 8,            -- 邮件
    Team                = 9,            -- 组队
    MiniMap             = 10,           -- 小地图
    Recharge            = 11,           -- 充值
    Friend              = 12,           -- 好友
    Rank                = 13,           -- 排行榜
    Chat                = 14,           -- 聊天
    SettingBasic        = 15,           -- 基础设置
    ExitToRole          = 16,           -- 小退
    ForceExitToRole     = 17,           -- 强制小退
    AssistChange        = 18,           -- 主界面-任务栏
    Storage             = 19,           -- 仓库
    Auction             = 20,           -- 拍卖行
    TreasureShop        = 21,           -- 百宝阁
    Skill               = 22,           -- 武功
    Tranfer             = 23,           -- 转职
    TTSQ                = 100,          -- 天天省钱
    Trading             = 101,          -- 交易行
}

function JumpUI.main()
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    if isPC then 
        JumpUI._links = JumpUI.LoadDefineLinksPC()
    else 
        JumpUI._links = JumpUI.LoadDefineLinks()
    end 
    
    SL:RegisterLUAEvent(LUA_EVENT_SERVER_JUMP_UI, "JumpTo", JumpUI.JumpTo)
end

function JumpUI.LoadDefineLinks()
    return {
        [LINK_TYPE.Equip]               = {open = function() FGUI:Open("Bag","PlayerInfoPanel") end,                packageName = "Bag", componentName = "PlayerInfoPanel"},
        [LINK_TYPE.Bag]                 = {open = function() FGUIFunction:OpenBag() end,                            packageName = "Bag", componentName = "PlayerInfoPanel"},
        [LINK_TYPE.Guild]               = {open = function() FGUIFunction:OpenGuildAutoUI() end,                    close = function() FGUIFunction:CloseGuildAutoUI() end, 
                                            checkOpen = function() return FGUI:CheckOpen("Guild", "GuildMainPanel") or FGUI:CheckOpen("Guild", "GuildJoinList") end},
        [LINK_TYPE.GuildMain]           = {open = function() FGUIFunction:OpenGuildMainFrameUI(1) end,              packageName = "Guild", componentName = "GuildMainPanel"},
        [LINK_TYPE.GuildMember]         = {open = function() FGUIFunction:OpenGuildMainFrameUI(2) end,              packageName = "Guild", componentName = "GuildMainPanel"},
        [LINK_TYPE.GuildList]           = {open = function() FGUI:Open("Guild", "GuildJoinList") end,               packageName = "Guild", componentName = "GuildJoinList"},
        [LINK_TYPE.GuildCreate]         = {open = function() FGUI:Open("Guild", "GuildJoinList") end,               packageName = "Guild", componentName = "GuildJoinList"},
        [LINK_TYPE.Mail]                = {open = function() FGUI:Open("Mail", "MailPanel") end,                    packageName = "Mail", componentName = "MailPanel"},
        [LINK_TYPE.Team]                = {open = function() FGUI:Open("Team", "TeamPanel") end,                    packageName = "Team", componentName = "TeamPanel"},
        [LINK_TYPE.MiniMap]             = {open = function() FGUI:Open("MiniMap", "MiniMapPanel") end,              packageName = "MiniMap", componentName = "MiniMapPanel"},
        [LINK_TYPE.Recharge]            = {open = function() FGUI:Open("Recharge", "RechargePanel") end, packageName = "Recharge", componentName = "RechargePanel"},
        [LINK_TYPE.Friend]              = {open = function() FGUI:Open("Friend", "FriendPanel", 1) end,        packageName = "Friend", componentName = "FriendPanel"},
        [LINK_TYPE.Rank]                = {open = function(param) FGUI:Open("Rank", "RankPanel", param) end,        packageName = "Rank", componentName = "RankPanel"},
        [LINK_TYPE.Chat]                = {open = function() FGUI:Open("Chat", "ChatPanel") end,                    packageName = "Chat", componentName = "ChatPanel"},
        [LINK_TYPE.SettingBasic]        = {open = function() FGUI:Open("Setting", "SettingPanel", 1) end,           packageName = "Setting", componentName = "SettingPanel"},
        [LINK_TYPE.ExitToRole]          = {open = function() SL:RequestLeaveWorld() end},
        [LINK_TYPE.ForceExitToRole]     = {open = function() SL:ForceLeaveWorld() end},
        [LINK_TYPE.AssistChange]        = {open = function() SLBridge:onLUAEvent(LUA_EVENT_ASSIST_SHOW) end,        close = function() SLBridge:onLUAEvent(LUA_EVENT_ASSIST_HIDE) end},
        [LINK_TYPE.Storage]             = {open = function() FGUI:Open("Bag", "StoragePanel") end,                  packageName = "Bag", componentName = "StoragePanel"},
        [LINK_TYPE.Auction]             = {open = function() FGUI:Open("Auction", "AuctionRootPanel") end,          packageName = "Auction", componentName = "AuctionRootPanel"},
        [LINK_TYPE.TreasureShop]        = {open = function() SL:RequestGroupData(0) end,                            packageName = "TreasureShop", componentName = "TreasurePanel"},
        [LINK_TYPE.Skill]               = {open = function(param) FGUI:Open("Skill", "SkillFramePanel", param and param==0 and 1 or 1) end,     packageName = "Skill", componentName = "SkillFramePanel"},
        [LINK_TYPE.TTSQ]                = {open = function(param) SL:Open996BoxTTSQ() end,     close = function() SL:Close996BoxTTSQ() end,checkOpen = function() return SL._IsOpen996BoxTTSQ end},
        [LINK_TYPE.Trading]             = {open = function(param) SL:OpenTradingBankUI() end,     close = function()  end},
    }
end

function JumpUI.LoadDefineLinksPC()
    return {
        [LINK_TYPE.Equip]               = {open = function() FGUI:Open("Bag","PlayerInfoPanel") end, packageName = "Bag", componentName = "PlayerInfoPanel"},
        [LINK_TYPE.Bag]                 = {open = function() FGUIFunction:OpenBag() end, packageName = "Bag", componentName = "PlayerInfoPanel"},
        [LINK_TYPE.Guild]               = {open = function() FGUIFunction:OpenGuildAutoUI() end, close = function() FGUIFunction:CloseGuildAutoUI() end, 
                                            checkOpen = function() return FGUI:CheckOpen("Guild", "GuildMainPanel") or FGUI:CheckOpen("Guild", "GuildJoinList") end},
        [LINK_TYPE.GuildMain]           = {open = function() FGUIFunction:OpenGuildMainFrameUI(1) end, packageName = "Guild", componentName = "GuildMainPanel"},
        [LINK_TYPE.GuildMember]         = {open = function() FGUIFunction:OpenGuildMainFrameUI(2) end, packageName = "Guild", componentName = "GuildMainPanel"},
        [LINK_TYPE.GuildList]           = {open = function() FGUI:Open("Guild", "GuildJoinList") end, packageName = "Guild", componentName = "GuildJoinList"},
        [LINK_TYPE.GuildCreate]         = {open = function() FGUI:Open("Guild", "GuildJoinList") end, packageName = "Guild", componentName = "GuildJoinList"},
        [LINK_TYPE.Mail]                = {open = function() FGUI:Open("Mail_pc", "PCMailPanel") end, packageName = "Mail_pc", componentName = "PCMailPanel"},
        [LINK_TYPE.Team]                = {open = function() FGUI:Open("Team_pc", "PCTeamPanel") end, packageName = "Team_pc", componentName = "PCTeamPanel"},
        [LINK_TYPE.MiniMap]             = {open = function() FGUI:Open("MiniMap", "MiniMapPanel") end, packageName = "MiniMap", componentName = "MiniMapPanel"},
        [LINK_TYPE.Recharge]            = {open = function() FGUI:Open("Recharge_pc", "RechargePanel", nil, nil, {classPath = "FGUILayout/Recharge/RechargePanel"}) end, packageName = "Recharge", componentName = "RechargePanel"},
        [LINK_TYPE.Friend]              = {open = function() FGUI:Open("Friend_PC", "PCFriendPanel", 1) end,        packageName = "Friend_PC", componentName = "PCFriendPanel"},
        [LINK_TYPE.Rank]                = {open = function(param) FGUI:Open("Rank_pc", "PCRankPanel", param) end, packageName = "Rank_pc", componentName = "PCRankPanel"},
        [LINK_TYPE.Chat]                = {open = function() FGUI:Open("Chat", "ChatPanel") end, packageName = "Chat", componentName = "ChatPanel"},
        [LINK_TYPE.SettingBasic]        = {open = function() FGUI:Open("Setting_pc", "PCSettingPanel", 1) end, packageName = "Setting_pc", componentName = "PCSettingPanel"},
        [LINK_TYPE.ExitToRole]          = {open = function() SL:RequestLeaveWorld() end},
        [LINK_TYPE.ForceExitToRole]     = {open = function() SL:ForceLeaveWorld() end},
        [LINK_TYPE.AssistChange]        = {open = function() SLBridge:onLUAEvent(LUA_EVENT_ASSIST_SHOW) end, close = function() SLBridge:onLUAEvent(LUA_EVENT_ASSIST_HIDE) end},
        [LINK_TYPE.Storage]             = {open = function() FGUI:Open("Bag", "StoragePanel") end, packageName = "Bag", componentName = "StoragePanel"},
        [LINK_TYPE.Auction]             = {open = function() FGUI:Open("Auction", "AuctionRootPanel") end, packageName = "Auction", componentName = "AuctionRootPanel"},
        [LINK_TYPE.TreasureShop]        = {open = function() SL:RequestGroupData(0) end, packageName = "TreasureShop", componentName = "TreasurePanel"},
        [LINK_TYPE.Skill]               = {open = function() FGUI:Open("Skill_pc", "PCSkillFramePanel", 1) end, packageName = "Skill_pc", componentName = "PCSkillFramePanel"},
        [LINK_TYPE.TTSQ]                = {open = function(param) SL:Open996BoxTTSQ() end,     close = function() SL:Close996BoxTTSQ() end,checkOpen = function() return SL._IsOpen996BoxTTSQ end},
        [LINK_TYPE.Trading]             = {open = function(param) SL:OpenTradingBankUI() end,     close = function()  end},

    }
end

function JumpUI.FindLinkByID(jumpID)
    return JumpUI._links[jumpID]
end

function JumpUI.JumpTo(jumpID, param, param1)
    SL:Print("+++++++++++++hyper link jump", jumpID, param, param1)
    local link = JumpUI.FindLinkByID(tonumber(jumpID) or 0)
    if not link then
        return
    end
    local function openLayer()
        if link and link.open then
            link.open(param)           
        end
    end
    local function closeLayer()
        if link and link.close then
            link.close(param)
        elseif link and link.packageName and link.componentName then
            FGUI:Close(link.packageName, link.componentName)
        end
    end
    local function checkLayerIsOpen()
        if link and link.checkOpen then 
            return link.checkOpen()
        end

        if link and link.packageName and link.componentName then
            return FGUI:CheckOpen(link.packageName, link.componentName)
        end

        return false
    end

    if not param1 or param1 == 0 then -- 0: 打开 已打开界面则关闭
        -- 伸缩类型
        if jumpID == LINK_TYPE.AssistChange then
            SLBridge:onLUAEvent(LUA_EVENT_ASSIST_CHANGE)
            return
        end
        if checkLayerIsOpen() then
            closeLayer() 
        else
            openLayer()
        end
    else
        if param1 == 1 then -- 1: 强制打开
            if not checkLayerIsOpen() then
                openLayer()
            end
        else -- 关闭
            closeLayer()
        end
    end

end

function JUMPTO(...)
    JumpUI.JumpTo(...)
end

return JumpUI