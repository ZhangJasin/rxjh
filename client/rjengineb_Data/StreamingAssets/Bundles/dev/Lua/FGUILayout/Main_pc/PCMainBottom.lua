local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCMainBottom = class("PCMainBottom", BaseFGUILayout)

function PCMainBottom:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Main)

    self._quicks = FGUIFunction:BindClass(self._ui.Group_quick, "Main_pc/PCMainQuick")
    self._buffs = FGUIFunction:BindClass(self._ui.List_buff, "Main_pc/PCMainBuff")

    self._quicks:Create()
    self._buffs:Create()

    self._bubbleTipsData = {}
    self._bubbleTipsCells = {}

    self._loadingFile = {}

    self._isAutoFight = false
    self._isAutoMove = false

    self._funcMap = {
        ["Stall_pc/PCStallMain"] = self._ui.Btn_action,
        ["Team_pc/PCTeamNearPanel"] = self._ui.Btn_team,
        ["Skill_pc/PCSkillFramePanel"] = self._ui.Btn_skill,
        ["Mail_pc/PCMailPanel"] = self._ui.Btn_mail,
        ["TreasureShop_pc/PCTreasurePanel"] = self._ui.Btn_shop,
        ["Friend_pc/PCFriendPanel"] = self._ui.Btn_friend,
        ["Setting_pc/PCSettingPanel"] = self._ui.Btn_setting,
        ["Z_Jasin/equipCollect"] = self._ui.Btn_zbtj,
    }
    local guildSelectFunc = function()
        local isOpen = FGUI:CheckOpen("Guild_pc", "PCGuildJoinList") or FGUI:CheckOpen("Guild_pc", "PCGuildMainPanel")
        FGUI:GButton_setSelected(self._ui.Btn_guild, isOpen)
    end
    self._funcMap2 = {
        ["Guild_pc/PCGuildJoinList"] = guildSelectFunc,
        ["Guild_pc/PCGuildMainPanel"] = guildSelectFunc,
        ["Bag_pc/PCPlayerInfoPanel"] = function(isOpen)
            FGUI:GButton_setSelected(self._ui.Btn_status, isOpen)
            FGUI:GButton_setSelected(self._ui.Btn_bag, isOpen)
        end,
    }

    local funcBtns = {
        { btn = self._ui.Btn_action, name = GET_STRING(40070002), key = nil },
        { btn = self._ui.Btn_team, name = GET_STRING(40070003), key = SettingKey.Type.TEAM },
        { btn = self._ui.Btn_guild, name = GET_STRING(40070006), key = SettingKey.Type.GUILD },
        { btn = self._ui.Btn_status, name = GET_STRING(40070007), key = nil },
        { btn = self._ui.Btn_bag, name = GET_STRING(40070008), key = SettingKey.Type.BAG },
        { btn = self._ui.Btn_skill, name = GET_STRING(40070009), key = nil },
        { btn = self._ui.Btn_mail, name = GET_STRING(40070010), key = SettingKey.Type.MAIL },
        { btn = self._ui.Btn_shop, name = GET_STRING(40070011), key = nil },
        { btn = self._ui.Btn_friend, name = GET_STRING(40070012), key = SettingKey.Type.FRIEND },
        { btn = self._ui.Btn_setting, name = GET_STRING(40070013), key = nil },
        { btn = self._ui.Btn_zbtj, name = "图鉴", key = nil },
    }
    for k, v in pairs(funcBtns) do
        v.index = k
        v.icon = FGUI:GetChild(v.btn, "icon")
        v.scale = 1
        FGUI:GButton_setChangeStateOnClick(v.btn, false)
        FGUI:GButton_setSelected(v.btn, false)
        FGUI:GButton_setTitle(v.btn, v.name)
        FGUI:setOnRollOverEvent(v.btn, handler(self, self.OnBtnFuncRollOver, v))
        FGUI:setOnRollOutEvent(v.btn, handler(self, self.OnBtnFuncRollOut, v))
        FGUI:setOnTouchEvent(v.btn, handler(self, self.OnBtnFuncTouchBegin, v), nil,
            handler(self, self.OnBtnFuncTouchEnd, v))
    end

    FGUI:setOnClickEvent(self._ui.Btn_action, handler(self, self.OnClickAction))
    FGUI:setOnClickEvent(self._ui.Btn_team, handler(self, self.OnClickTeam))
    FGUI:setOnClickEvent(self._ui.Btn_guild, handler(self, self.OnClickGuild))
    FGUI:setOnClickEvent(self._ui.Btn_status, handler(self, self.OnClickStatus))
    FGUI:setOnClickEvent(self._ui.Btn_bag, handler(self, self.OnClickBag))
    FGUI:setOnClickEvent(self._ui.Btn_skill, handler(self, self.OnClickSkill))
    FGUI:setOnClickEvent(self._ui.Btn_mail, handler(self, self.OnClickMail))
    FGUI:setOnClickEvent(self._ui.Btn_shop, handler(self, self.OnClickShop))
    FGUI:setOnClickEvent(self._ui.Btn_friend, handler(self, self.OnClickFriend))
    FGUI:setOnClickEvent(self._ui.Btn_setting, handler(self, self.OnClickSetting))
    FGUI:setOnClickEvent(self._ui.Btn_zbtj, handler(self, self.OnClickZbtj))

    FGUI:UIModel_addFx(self._ui.Graph_autoFight, 1001010, true, nil, nil, Vector3(0.3, 0.3, 0.3))
    FGUI:UIModel_pause(self._ui.Graph_autoFight)
    FGUI:setVisible(self._ui.Graph_autoFight, self._isAutoFight)
    FGUI:setVisible(self._ui.Image_autoMove, self._isAutoMove)
    FGUI:setVisible(self._ui.ProgressBar_preLoad, false)

    self._quickTip = self._ui.QuickTip
    FGUI:RemoveFromParent(self._quickTip, false)

    FGUI:GList_resizeToFit(self._ui.List_bubbleTip)
end

function PCMainBottom:Enter()
    self._quicks:Enter()
    self._buffs:Enter()
    self:RegisterEvent()

    self:InitAdapt()
    self:OnRefreshPropertyShow()
    self:UpdateAutoState()
    self:InitBubbleTips()

    -- 启动状态同步
    self:ScheduleStateSync()
end

function PCMainBottom:Exit()
    self._quicks:Exit()
    self._buffs:Exit()
    if self._timer then
        SL:UnSchedule(self._timer)
        self._timer = nil
    end
    self:UnscheduleStateSync()
    self:ClearBubbleTips()
    self:RemoveEvent()
end

function PCMainBottom:Destroy()
    self._quicks:Destroy()
    self._buffs:Destroy()
    self._ui = nil

    if self.quickTip then
        FGUI:RemoveFromParent(self.quickTip, true)
        self.quickTip = nil
    end
end

function PCMainBottom:InitAdapt()
    local safeBottom = SL:GetValue("SCREEN_SAFE_AREA_BOTTOM")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    FGUI:setHeight(self.component, screenH - safeBottom)
    FGUI:setPositionY(self.component, 0)
end

function PCMainBottom:OnRefreshPropertyShow()
    local curExp = SL:GetValue("EXP") or 0
    local maxExp = SL:GetValue("MAXEXP")
    maxExp = maxExp > 0 and maxExp or 1
    local expPer = math.floor(curExp / maxExp * 100)
    FGUI:GProgressBar_setValue(self._ui.ProgressBar_exp, expPer)
end

function PCMainBottom:OnRefreshBubbleTips(data)
    if data.status then
        self:AddBubbleTips(data)
    else
        self:RmvBubbleTips(data)
    end
end

function PCMainBottom:OnClickAction()
    FGUIFunction:SwitchPanel("Stall_pc", "PCStallMain")
end

function PCMainBottom:OnClickTeam()
    FGUIFunction:SwitchPanel("Team_pc", "PCTeamNearPanel")
end

function PCMainBottom:OnClickGuild()
    local playerLevel = SL:GetValue("LEVEL") or 1
    if playerLevel < 25 then
        return SL:ShowSystemTips("人物25级解锁门派")
    end
    if FGUI:CheckOpen("Guild_pc", "PCGuildJoinList") or FGUI:CheckOpen("Guild_pc", "PCGuildMainPanel") then
        FGUIFunction:CloseGuildAutoUI()
    else
        FGUIFunction:OpenGuildAutoUI()
    end
end

function PCMainBottom:OnClickStatus()
    FGUIFunction:SwitchPanel("Bag_pc", "PCPlayerInfoPanel", 2)
end

function PCMainBottom:OnClickBag()
    FGUIFunction:SwitchPanel("Bag_pc", "PCPlayerInfoPanel", 1)
end

function PCMainBottom:OnClickSkill()
    local playerLevel = SL:GetValue("LEVEL") or 1
    if playerLevel < 10 then
        return SL:ShowSystemTips("人物10级解锁功法")
    end
    FGUIFunction:SwitchPanel("Skill_pc", "PCSkillFramePanel", 1)
end

function PCMainBottom:OnClickMail()
    FGUIFunction:SwitchPanel("Mail_pc", "PCMailPanel")
end

function PCMainBottom:OnClickShop()
    FGUIFunction:SwitchPanel("TreasureShop_pc", "PCTreasurePanel")
end

function PCMainBottom:OnClickFriend()
    FGUIFunction:SwitchPanel("Friend_pc", "PCFriendPanel", FGUIDefine.FriendPage.Recent)
end

function PCMainBottom:OnClickSetting()
    FGUIFunction:SwitchPanel("Setting_pc", "PCSettingPanel")
end

function PCMainBottom:OnClickZbtj()
    local playerLevel = SL:GetValue("LEVEL") or 1
    if playerLevel < 35 then
        return SL:ShowSystemTips("人物35级解锁图鉴")
    end
    if FGUI:CheckOpen("Z_Jasin", "equipCollect") then
        FGUI:Close("Z_Jasin", "equipCollect")
    else
        FGUI:Open("Z_Jasin", "equipCollect", {}, FGUI_LAYER.NORMAL,
            { destroyTime = 1, classPath = "FGUILayout/Z_Jasin/zbtj/equipCollect" })
    end
end

function PCMainBottom:OnBtnFuncRollOver(data)
    local x, y = FGUI:getPosition(data.btn)
    local parent = FGUI:GetParent(data.btn)
    local wx, wy = FGUI:LocalToWorld(parent, x, y)
    FGUI:setPosition(self._quickTip, wx, wy - 15)
    local name = data.name
    if data.key then
        local keyData = SettingKey.GetSetting(data.key)
        if keyData and keyData.keysStr then
            name = name .. "\n" .. keyData.keysStr
        end
    end
    FGUI:GLabel_setTitle(self._quickTip, name)
    SL:onLUAEvent(LUA_EVENT_TOP_TIP_ADD, self._quickTip, "PCMainBottomFunc" .. data.index)

    data.scale = data.scale + 0.1
    local scale = math.max(1, math.min(1.1, data.scale))
    FGUI:setScale(data.icon, scale, scale)
end

function PCMainBottom:OnBtnFuncRollOut(data)
    SL:onLUAEvent(LUA_EVENT_TOP_TIP_REMOVE, self._quickTip, "PCMainBottomFunc" .. data.index)
    data.scale = data.scale - 0.1
    local scale = math.max(1, math.min(1.1, data.scale))
    FGUI:setScale(data.icon, scale, scale)
end

function PCMainBottom:OnBtnFuncTouchBegin(data)
    data.scale = data.scale - 0.1
    local scale = math.max(1, math.min(1.1, data.scale))
    FGUI:setScale(data.icon, scale, scale)
end

function PCMainBottom:OnBtnFuncTouchEnd(data)
    data.scale = data.scale + 0.1
    local scale = math.max(1, math.min(1.1, data.scale))
    FGUI:setScale(data.icon, scale, scale)
end

--------------------------- 气泡栏 -----------------------------

function PCMainBottom:InitBubbleTips()
    local datas = SL:GetValue("BUBBLE_TIPS")
    for k, data in pairs(datas) do
        self:AddBubbleTips(data)
    end
end

function PCMainBottom:ClearBubbleTips()
    local datas = {}
    for k, data in pairs(self._bubbleTipsData) do
        table.insert(datas, data)
    end
    for k, data in pairs(datas) do
        self:RmvBubbleTips(data)
    end
end

function PCMainBottom:AddBubbleTips(data)
    if self._bubbleTipsData[data.id] then
        self._bubbleTipsData[data.id] = data
        return false
    end
    self._bubbleTipsData[data.id] = data
    local cell = self:CreateBubbleTipsCell(data)
    self._bubbleTipsCells[data.id] = cell

    SL:PlaySound(50004)
end

function PCMainBottom:RmvBubbleTips(data)
    if not self._bubbleTipsData[data.id] then
        return false
    end
    self._bubbleTipsData[data.id] = nil
    local cell = self._bubbleTipsCells[data.id]
    if cell then
        local trans = FGUI:GetTransition(cell, "effect")
        FGUI:Transition_stop(trans)
        self._bubbleTipsCells[data.id] = nil
        FGUI:GList_removeChildToPool(self._ui.List_bubbleTip, cell)
    end

    if data.timer then
        SL:UnSchedule(data.timer)
        data.timer = nil
    end
end

-- 气泡cell
function PCMainBottom:CreateBubbleTipsCell(data)
    local id = data.id
    if data.time then
        data.endTime = data.time + SL:GetValue("SERVER_TIME")
    end

    local cell = FGUI:GList_addItemFromPool(self._ui.List_bubbleTip)
    FGUI:GList_resizeToFit(self._ui.List_bubbleTip)
    FGUI:setLocalZOrder(cell, id)
    local ctl = FGUI:getController(cell, "type")
    FGUI:Controller_setSelectedIndex(ctl, data.type)

    FGUI:setOnClickEvent(cell, function()
        if data.callback then
            data.callback()
        end
    end)

    -- 时间
    local function callback()
        local remaining = data.endTime - SL:GetValue("SERVER_TIME")
        FGUI:GButton_setTitle(cell, remaining)

        if remaining <= 0 then
            if data.timer then
                SL:UnSchedule(data.timer)
                data.timer = nil
            end
            FGUI:GButton_setTitle(cell, "")
            if data.timeOverCB then
                data.timeOverCB()
            end
        end
    end

    if data.endTime then
        if data.timer then
            SL:UnSchedule(data.timer)
            data.timer = nil
        end
        data.timer = SL:Schedule(callback, 1)
        callback()
    else
        FGUI:GButton_setTitle(cell, "")
    end

    local imgEffetc = FGUI:GetChild(cell, "Image_effect")
    FGUI:setAlpha(imgEffetc, 0)
    return cell
end

-----------------------------------Auto------------------------------------
function PCMainBottom:OnAutoMoveBegin(data)
    self:UpdateAutoState(nil, true)
end

function PCMainBottom:OnAutoMoveEnd()
    self:UpdateAutoState(nil, false)
end

function PCMainBottom:OnFightBegin()
    self:UpdateAutoState(true, nil)
end

function PCMainBottom:OnFightEnd()
    self:UpdateAutoState(false, nil)
end

function PCMainBottom:UpdateAutoState(isAutoFight, isAutoMove)
    if isAutoFight == nil then
        -- 综合判断:战斗状态 + 挂机状态才是真正的自动战斗
        local battleState = SL:GetValue("BATTLE_IS_FIGHT_STATE") or false
        local afkState = SL:GetValue("BATTLE_IS_AFK") or false
        isAutoFight = battleState and afkState
    end
    if self._isAutoFight ~= isAutoFight then
        self._isAutoFight = isAutoFight
        if isAutoFight then
            FGUI:setVisible(self._ui.Graph_autoFight, true)
            FGUI:UIModel_resume(self._ui.Graph_autoFight)
        else
            FGUI:UIModel_pause(self._ui.Graph_autoFight)
            FGUI:setVisible(self._ui.Graph_autoFight, false)
        end
    end
    if isAutoFight then isAutoMove = false end
    if isAutoMove == nil then
        isAutoMove = SL:GetValue("BATTLE_IS_AUTO_MOVE")
    end
    if self._isAutoMove ~= isAutoMove then
        self._isAutoMove = isAutoMove
        FGUI:setVisible(self._ui.Image_autoMove, isAutoMove)
    end
end

-- 定期同步状态,确保指示图状态与引擎一致
function PCMainBottom:ScheduleStateSync()
    if not self._stateSyncTimer then
        self._stateSyncTimer = SL:Schedule(handler(self, self.SyncAutoState), 1)
    end
end

function PCMainBottom:UnscheduleStateSync()
    if self._stateSyncTimer then
        SL:UnSchedule(self._stateSyncTimer)
        self._stateSyncTimer = nil
    end
end

function PCMainBottom:SyncAutoState()
    self:UpdateAutoState()
end

---------------------------------------------------------------------------

-- 预加载开始
function PCMainBottom:OnPreLoadStart(key)
    table.insert(self._loadingFile, key)
    FGUI:setVisible(self._ui.ProgressBar_preLoad, true)
    if not self._timer then
        self._timer = SL:Schedule(handler(self, self.UpdatePreLoadProgress), 1)
    end
    self:UpdatePreLoadProgress()
end

-- 预加载结束
function PCMainBottom:OnPreLoadEnd(key)
    if self._timer then
        SL:UnSchedule(self._timer)
        self._timer = nil
    end
    if not self._loadingFile or not next(self._loadingFile) then
        FGUI:setVisible(self._ui.ProgressBar_preLoad, false)
        return
    end
    local idx = -1
    for i, v in ipairs(self._loadingFile) do
        if key == v then
            idx = i
            break
        end
    end
    if idx > -1 then
        table.remove(self._loadingFile, idx)
    end
    if not next(self._loadingFile) then
        FGUI:setVisible(self._ui.ProgressBar_preLoad, false)
        return
    end
    self:UpdatePreLoadProgress()
end

function PCMainBottom:UpdatePreLoadProgress()
    if not self._loadingFile or not next(self._loadingFile) then
        FGUI:GProgressBar_setValue(self._ui.ProgressBar_preLoad, 0)
        return
    end

    local totalP = 0
    for i, key in ipairs(self._loadingFile) do
        local progress = SL:GetValue("PRELOAD_PROGRESS", key)
        totalP = totalP + progress
    end
    local P = totalP / #self._loadingFile * 100
    FGUI:GProgressBar_setValue(self._ui.ProgressBar_preLoad, P)
end

function PCMainBottom:OnVersionUpdate(platform, resourceType, pushType, extend)
    --platform平台 0.全部 1.ios 2.安卓  3.pc 4.h5
    --resourceType资源类型 0.全部 1.dev 2.dev_assets 3.dev_server
    --pushType更新类型 0.软提示  1.强更
    --extend自定义
    print(platform, resourceType, pushType, extend, "OnVersionUpdate__")
    if platform == 1 then
        if not SL:GetValue("PLATFORM_IOS") then
            return
        end
    elseif platform == 2 then
        if not SL:GetValue("PLATFORM_ANDROID") then
            return
        end
    elseif platform == 3 then
        if not SL:GetValue("PLATFORM_WINDOWS") then
            return
        end
    elseif platform == 4 then
        if not SL:GetValue("PLATFORM_WEB") then
            return
        end
    end
    if pushType == 1 then
        local callFunc = function(btnIndex)
            SL:RestartGame()
        end
        local data = {}
        data.str = SL:GetValue("I18N_STRING", 20000214)
        data.btnDesc = { SL:GetValue("I18N_STRING", 20000213) }
        data.callback = callFunc
        SL:OpenCommonDialog(data)
    else
        FGUI:setVisible(self._ui.Btn_updateTip, true)
    end
end

function PCMainBottom:OnWindowOpen(data)
    local btn = self._funcMap[data.name]
    if btn then
        FGUI:GButton_setSelected(btn, true)
    else
        local func = self._funcMap2[data.name]
        if func then
            func(true)
        end
    end
end

function PCMainBottom:OnWindowClose(data)
    local btn = self._funcMap[data.name]
    if btn then
        FGUI:GButton_setSelected(btn, false)
    else
        local func = self._funcMap2[data.name]
        if func then
            func(false)
        end
    end
end

-----------------------------------注册事件--------------------------------------
function PCMainBottom:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "PCMainBottom", handler(self, self.OnRefreshPropertyShow))
    SL:RegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "PCMainBottom", handler(self, self.OnRefreshPropertyShow))
    SL:RegisterLUAEvent(LUA_EVENT_EXP_CHANGE, "PCMainBottom", handler(self, self.OnRefreshPropertyShow))
    SL:RegisterLUAEvent(LUA_EVENT_BUBBLETIPS_STATUS_CHANGE, "PCMainBottom", handler(self, self.OnRefreshBubbleTips))
    SL:RegisterLUAEvent(LUA_EVENT_AUTO_MOVE_BEGIN, "PCMainBottom", handler(self, self.OnAutoMoveBegin))
    SL:RegisterLUAEvent(LUA_EVENT_AUTO_MOVE_END, "PCMainBottom", handler(self, self.OnAutoMoveEnd))
    SL:RegisterLUAEvent(LUA_EVENT_FIGHT_BEGIN, "PCMainBottom", handler(self, self.OnFightBegin))
    SL:RegisterLUAEvent(LUA_EVENT_FIGHT_END, "PCMainBottom", handler(self, self.OnFightEnd))
    SL:RegisterLUAEvent(LUA_EVENT_WINDOW_OPEN, "PCMainBottom", handler(self, self.OnWindowOpen))
    SL:RegisterLUAEvent(LUA_EVENT_WINDOW_CLOSE, "PCMainBottom", handler(self, self.OnWindowClose))

    SL:RegisterLUAEvent(LUA_EVENT_PRELOAD_START, "PCMainBottom", handler(self, self.OnPreLoadStart))
    SL:RegisterLUAEvent(LUA_EVENT_PRELOAD_END, "PCMainBottom", handler(self, self.OnPreLoadEnd))
    SL:RegisterLUAEvent(LUA_EVENT_VERSION_UPDATE, "PCMainBottom", handler(self, self.OnVersionUpdate))
end

function PCMainBottom:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "PCMainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "PCMainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_EXP_CHANGE, "PCMainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_BUBBLETIPS_STATUS_CHANGE, "PCMainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_AUTO_MOVE_BEGIN, "PCMainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_AUTO_MOVE_END, "PCMainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_FIGHT_BEGIN, "PCMainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_FIGHT_END, "PCMainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_WINDOW_OPEN, "PCMainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_WINDOW_CLOSE, "PCMainBottom")

    SL:UnRegisterLUAEvent(LUA_EVENT_PRELOAD_START, "PCMainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_PRELOAD_END, "PCMainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_VERSION_UPDATE, "PCMainBottom")
end

return PCMainBottom
