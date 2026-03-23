local Type = SettingKey.Type

local movdDir = {x = 0, y = 0}

local function UpdateMoveDir()
    local dir = movdDir
	if dir.x ~= 0 or dir.y ~= 0 then
		local angle = math.floor(Mathf.Atan2(-dir.y, dir.x) * Mathf.Rad2Deg)
        SL:SetValue("USER_INPUT_MOVE", angle)
    else
        SL:SetValue("USER_ABORT_MOVE")
    end
end

local SettingKeyFunc = {}

SettingKeyFunc.PressFunc = {
    [Type.BAG] = function()
        FGUIFunction:SwitchPanel("Bag_pc", "PCPlayerInfoPanel", 1)
    end,
    [Type.CHAT] = function()
        SL:onLUAEvent(LUA_EVENT_CHAT_FOCUS)
    end,
    [Type.EQUIP] = function()
        FGUIFunction:SwitchPanel("Bag_pc", "PCPlayerInfoPanel", 2)
    end,
    [Type.FRIEND] = function()
        FGUIFunction:SwitchPanel("Friend_pc", "PCFriendPanel", FGUIDefine.FriendPage.Recent)
    end,
    [Type.GUILD] = function()
        if FGUI:CheckOpen("Guild_pc", "PCGuildJoinList") or FGUI:CheckOpen("Guild_pc", "PCGuildMainPanel") then
            FGUIFunction:CloseGuildAutoUI()
        else
            FGUIFunction:OpenGuildAutoUI()
        end 
    end,
    [Type.MAP] = function()
        FGUIFunction:SwitchPanel("MiniMap_pc", "PCMiniMapPanel")
    end,
    [Type.MAIL] = function()
        FGUIFunction:SwitchPanel("Mail_pc", "PCMailPanel")
    end,
    [Type.RANK] = function()
        FGUIFunction:SwitchPanel("Rank_pc", "PCRankPanel")
    end,
    [Type.TEAM] = function()
        FGUIFunction:SwitchPanel("Team_pc", "PCTeamNearPanel", 1)
    end,
    [Type.SETTING] = function()
        FGUIFunction:SwitchPanel("Setting_pc", "PCSettingPanel")
    end,
    [Type.QUICK1] = function() PCGameMain.DoQuickUse(1) end,
    [Type.QUICK2] = function() PCGameMain.DoQuickUse(2) end,
    [Type.QUICK3] = function() PCGameMain.DoQuickUse(3) end,
    [Type.QUICK4] = function() PCGameMain.DoQuickUse(4) end,
    [Type.QUICK5] = function() PCGameMain.DoQuickUse(5) end,
    [Type.QUICK6] = function() PCGameMain.DoQuickUse(6) end,
    [Type.QUICK7] = function() PCGameMain.DoQuickUse(7) end,
    [Type.QUICK8] = function() PCGameMain.DoQuickUse(8) end,
    [Type.QUICK9] = function() PCGameMain.DoQuickUse(9) end,
    [Type.QUICK10] = function() PCGameMain.DoQuickUse(10) end,
    [Type.SPLIT_ITEM] = function() end,
    [Type.MOVE_UP] = function()
        movdDir.y = movdDir.y - 1
        UpdateMoveDir()
    end,
    [Type.MOVE_DOWN] = function()
        movdDir.y = movdDir.y + 1
        UpdateMoveDir()
    end,
    [Type.MOVE_LEFT] = function()
        movdDir.x = movdDir.x - 1
        UpdateMoveDir()
    end,
    [Type.MOVE_RIGHT] = function()
        movdDir.x = movdDir.x + 1
        UpdateMoveDir()
    end,
    [Type.CLOSE_UI] = function()
        local succ = FGUI:CloseTop(FGUI_LAYER.NORMAL)
        if not succ then
            FGUI:Open("Setting_pc", "PCSettingPanel")
        end
    end,
    [Type.AUCTION] = function()
        FGUIFunction:SwitchPanel("Auction_pc", "PCAuctionRootPanel")
    end,
    [Type.BAG_SMALL] = function()
        FGUI:Open("Bag_pc","PCEquipBar",nil,FGUI_LAYER.NORMAL,{fullScreen = true})
    end,
    [Type.STATUS_SMALL]=function()
        FGUI:Open("Bag_pc","PCBarRootPanel",nil,FGUI_LAYER.NORMAL,{fullScreen = true})
    end,
    [Type.EXCHANGE]=function()
        FGUI:Open("ExChange_pc","PCExChangeRootPanel",nil,FGUI_LAYER.NORMAL,{fullScreen = true})
    end
}

SettingKeyFunc.ReleaseFunc = {
    [Type.SPLIT_ITEM] = function() end,
    [Type.MOVE_UP] = function()
        movdDir.y = movdDir.y + 1
        UpdateMoveDir()
    end,
    [Type.MOVE_DOWN] = function()
        movdDir.y = movdDir.y - 1
        UpdateMoveDir()
    end,
    [Type.MOVE_LEFT] = function()
        movdDir.x = movdDir.x + 1
        UpdateMoveDir()
    end,
    [Type.MOVE_RIGHT] = function()
        movdDir.x = movdDir.x - 1
        UpdateMoveDir()
    end,
}

return SettingKeyFunc