local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCMainPlayer = class("PCMainPlayer", BaseFGUILayout)
local SysConstant = require("game_config/cfgcsv/SysConstant")
local PCMainPlayerData = require("FGUILayout/Main_pc/PCMainPlayerData")      -- 主玩家数据层
function PCMainPlayer:Create()
	self._ui = FGUI:ui_delegate(self.component)
    self._opUI = FGUI:ui_delegate(self._ui.TeamOperation)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Main)

    self._curHP = nil
    self._maxHP = nil
    self._curMP = nil
    self._maxMP = nil
    self._angerProV = 0

    self.comboCurV = 0
    self.comboMaxV = 0
    self.comboPoints = {}
    self.comboPointCtls = {}

    self._hasTeam = false

    self:InitComboId()
    FGUI:setOnClickEvent(self._ui.Touch_player, handler(self, self.OnClickPlayer), nil, nil)
    FGUI:setOnClickEvent(self._ui.player_icon, handler(self, self.OpenRole))
    FGUI:setOnClickEvent(self._ui.Button_team, handler(self, self.OnSwitchTeamOperation))
    FGUI:setOnClickEvent(self._ui.Loader_modeArea, handler(self, self.OnOpenModeSetting))
    FGUI:setOnTouchEvent(self._opUI.Mask, nil, nil, handler(self, self.OnHideTeamOperation))
    FGUI:setOnClickEvent(self._opUI.Button_createTeam, handler(self, self.OnCreateTeam))
    FGUI:setOnClickEvent(self._opUI.Button_joinTeam, handler(self, self.OnJoinTeam))
    -- 订阅数据层事件
    self._subscriptions = {}
    self._subscriptions.data_petResurrec = PCMainPlayerData:Subscribe("data_petResurrec", handler(self, self.petResurrec))
    self._subscriptions.data_showPetPro = PCMainPlayerData:Subscribe("data_showPetPro", handler(self, self.showPetPro)) 
    self._subscriptions.data_setPetInfo = PCMainPlayerData:Subscribe("data_setPetInfo", handler(self, self.setPetInfo)) 
end

function PCMainPlayer:Enter()
	self:RegisterEvent()

    self:InitAdapt()
    self:UpdatePropertys()
    
    FGUI:setVisible(self._ui.TeamOperation, false)
end


function PCMainPlayer:Exit()
	self:RemoveEvent()

    self._angerProV = 0
    FGUI:UIModel_clear(self._ui.Graph_angerEffect)
end

function PCMainPlayer:Destroy()
    self._ui = nil
    self._opUI = nil
    -- 取消订阅
    if self._subscriptions then
        for _, token in pairs(self._subscriptions) do
            PCMainPlayerData:Unsubscribe(token)
        end
        self._subscriptions = nil
    end
end

--------------------------------------------------------

function PCMainPlayer:setPetInfo(data)
    local petIcon = FGUI:GetChild(self._ui.petPro,"petIcon")
    if data.icon then
        FGUI:setVisible(self._ui.petPro,true)
        FGUI:GLoader_setUrl(petIcon,"ui://Main/"..data.icon)
    else
        FGUI:setVisible(self._ui.petPro,false)
    end
    
    self:showPetPro(data)
end

function PCMainPlayer:showPetPro(data)
    if data.type=="red" then
        --50%以上
        local one = FGUI:GetChild(self._ui.petPro,"one") 
        --50%以下
        local two = FGUI:GetChild(self._ui.petPro,"two") 
        local per = data.now * 100 / data.max
        if per >= 50 then
            FGUI:GImage_setFillAmount(one, (per / 50) - 1 )
            FGUI:GImage_setFillAmount(two, 1)
        else
            FGUI:GImage_setFillAmount(one, 0)
            FGUI:GImage_setFillAmount(two, (per/50))
        end
    end 
end

function PCMainPlayer:petResurrec(data)
    if data > 0 then
        local fhtextbg = FGUI:GetChild(self._ui.petPro,"n10")
        local fhtext = FGUI:GetChild(self._ui.petPro,"n11")
        local fhtext2 = FGUI:GetChild(self._ui.petPro,"n12")
        FGUI:GTextField_setText(fhtext, tonumber(SysConstant["PET_Resurre_CD"].Value).."s")
        FGUI:setVisible(fhtextbg,true)
        FGUI:setVisible(fhtext,true)
        FGUI:setVisible(fhtext2,true)
        if self.dsqfh then
            SL:UnSchedule(self.dsqfh)
            self.dsqfh = nil
        end
        self.time = data
        local function realivedjs()
            local times =  SL:GetValue("SERVER_TIME")*1000 - self.time
            local min = tonumber(SysConstant["PET_Resurre_CD"].Value) - math.floor(times/1000)
            if min > 0  then
                FGUI:GTextField_setText(fhtext, min.."s")
                FGUI:setVisible(fhtextbg,true)
                FGUI:setVisible(fhtext,true)
                FGUI:setVisible(fhtext2,true)
            else
                SL:UnSchedule(self.dsqfh)
                self.dsqfh = nil
                FGUI:GTextField_setText(fhtext, min.."s")
                FGUI:setVisible(fhtextbg,false)
                FGUI:setVisible(fhtext,false)
                FGUI:setVisible(fhtext2,false)
                ssrMessage:sendmsgEx("mountMain", "fhpet")
            end
        end
        self.dsqfh = SL:Schedule(realivedjs,1)
    else
        if self.dsqfh then
            SL:UnSchedule(self.dsqfh)
            self.dsqfh = nil
        end
    end
end

function PCMainPlayer:InitAdapt()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local safeL, safeR, safeB, safeT = SL:GetValue("SCREEN_SAFE_AREA_RATIO")
    FGUI:setSize(self.component, screenW - safeR - safeL, screenH - safeB - safeT)
    FGUI:setPosition(self.component, safeL, safeT)
end

function PCMainPlayer:InitComboId()
    local isCK = SL:GetValue("JOB") == 3
    if isCK then
        self.comboId = tonumber(SL:GetValue("GAME_DATA", "ComboPointId"))
    else
        self.comboId = nil
    end
end

function PCMainPlayer:UpdatePropertys()
    --刺客特殊显示
    local controller = FGUI:getController(self.component, "job")
    local isCK = SL:GetValue("JOB") == 3
    FGUI:Controller_setSelectedIndex(controller, isCK and 1 or 0)
    self:InitComboId()
    self:UpdateCombo()

    self:UpdateHead()
    self:UpdateHP()
    self:UpdateMP()
    self:UpdateAnger()
    self:UpdateLevel()
    self:UpdatePKMode()
end

local POINT_WIDTH = 10
local POINT_WIDTH_HALF = POINT_WIDTH / 2
function PCMainPlayer:UpdateCombo()
    if not self.comboId then return end
    local curV = SL:GetValue("CUR_ATTR_BY_ID", self.comboId)
    local maxV = SL:GetValue("MAX_ATTR_BY_ID", self.comboId)
    --更新上限值
    if self.comboMaxV ~= maxV then
        self.comboMaxV = maxV
        local allW = FGUI:getWidth(self._ui.Node_combos)
        local space = (allW - POINT_WIDTH) / (maxV - 1)
        local max = math.max(1, maxV)
        for i = 1, max do
            if i > maxV then
                local point = self.comboPoints[i]
                if point then
                    self.comboPoints[i] = nil
                    FGUI:RemoveFromParent(point, true)
                end
            else
                local point = self.comboPoints[i]
                if not point then
                    point = FGUI:CreateObject(self._ui.Node_combos, "Main_pc", "ComboPoint")
                    FGUI:setAnchorPoint(point, 0.5, 0, true)
                    local controller = FGUI:getController(point, "state")
                    self.comboPoints[i] = point
                    self.comboPointCtls[i] = controller
                end
                FGUI:setPosition(point, space * (i - 1) + POINT_WIDTH_HALF, 0)
            end
        end
    end

    local isFull = curV == maxV
    if self.comboCurV ~= curV then 
        local max = math.max(self.comboCurV, curV)
        local min = math.max(math.min(self.comboCurV, curV), 1)
        self.comboCurV = curV
        for i = min, max, 1 do
            local ctl = self.comboPointCtls[i]
            if ctl then
                if isFull then
                    FGUI:Controller_setSelectedIndex(ctl, 2)
                else
                    FGUI:Controller_setSelectedIndex(ctl, i <= curV and 1 or 0)
                end
            end
        end
    end
end

function PCMainPlayer:UpdateProperty()
    self:UpdateAnger()
    self:UpdateCombo()
end

function PCMainPlayer:UpdateHead()
    local data = {}
    data.AvatarID = SL:GetValue("AVATAR")
    data.Job  = SL:GetValue("JOB")
    data.Sex = SL:GetValue("SEX")
    data.FrameID = SL:GetValue("AVATAR_FRAME_DATA")
    FGUIFunction:SetCommonPlayerFrame(self._ui.player_icon,data)
end

function PCMainPlayer:UpdateHP(hp, maxHp)
    hp = hp or SL:GetValue("HP")
    maxHp = maxHp or SL:GetValue("MAXHP")
    if hp == self._curHP and maxHp == self._maxHP then return end
    self._curHP = hp
    self._maxHP = maxHp
    FGUI:GTextField_setText(self._ui.Text_hp, hp .. "/" .. maxHp)
    FGUI:GProgressBar_setValue(self._ui.ProgressBar_hp, hp / maxHp * 100)
end

function PCMainPlayer:UpdateMP(mp, maxMp)
    mp = mp or SL:GetValue("MP")
    maxMp = maxMp or SL:GetValue("MAXMP")
    if mp == self._curMP and maxMp == self._maxMP then return end
    self._curMP = mp
    self._maxMP = maxMp
    FGUI:GTextField_setText(self._ui.Text_mp, mp .. "/" .. maxMp)
    FGUI:GProgressBar_setValue(self._ui.ProgressBar_mp, mp / maxMp * 100)
end

function PCMainPlayer:UpdateAnger()
    local cur = SL:GetValue("MAX_ATTR_BY_ID", SLDefine.ATTRIBUTE.ANGER) or 0
	local max = 1000
    max = max > 0 and max or 1
    local v = cur / max * 100
    if v == self._angerProV then return end
    if self._angerProV < 100 and v >= 100 then
        FGUI:UIModel_addFx(self._ui.Graph_angerEffect, 100041, true, nil, nil, {x = 0.5, y = 0.5, z = 0.5})
    elseif self._angerProV >= 100 and v < 100 then
        FGUI:UIModel_clear(self._ui.Graph_angerEffect)
    end
    self._angerProV = v
    FGUI:GProgressBar_setValue(self._ui.ProgressBar_anger, v)
end

function PCMainPlayer:UpdateLevel()
    local lv = SL:GetValue("LEVEL")
    FGUI:GTextField_setText(self._ui.Text_lv, tostring(lv))
end

function PCMainPlayer:UpdatePKMode()
    local pkMode = SL:GetValue("PKMODE")
    local cfg = SL:GetValue("PKMODE_CONFIG_BY_ID", pkMode)
    local id = cfg and cfg.ID or 0
    FGUI:GLoader_setUrl(self._ui.Loader_mode, "ui://Main_pc/main_player_mode" .. id)

end

function PCMainPlayer:OnClickPlayer()
    SL:SetValue("SELECT_TARGET_ID", SL:GetValue("USER_ID"))
end

function PCMainPlayer:OpenRole()
    FGUIFunction:SwitchPanel("Bag_pc", "PCPlayerInfoPanel", 2)
end

function PCMainPlayer:OnOpenModeSetting()
    FGUIFunction:SwitchPanel("Main_pc","PCModeSetting")
end

function PCMainPlayer:OnUpdateHead(actorID)
    if SL:GetValue("USER_ID") ~= actorID then return end
    self:UpdateHead()
end

------------------------------------Team---------------------------------------

function PCMainPlayer:OnSwitchTeamOperation()
    local hasTeam = SL:GetValue("TEAM_COUNT") > 0
    if hasTeam then
        if PCGameMain.team then
            if PCGameMain.team:IsShow() then
                PCGameMain.team:Hide(true)
            else
                PCGameMain.team:Show(true)
            end
        end
    else
        local visible = FGUI:getVisible(self._ui.TeamOperation)
        FGUI:setVisible(self._ui.TeamOperation, not visible)
    end
end

function PCMainPlayer:OnHideTeamOperation()
    FGUI:setVisible(self._ui.TeamOperation, false)
end

function PCMainPlayer:OnListTeamAllotRender(index, item)
    local idx = index + 1
    local data = PICK_DATA[idx]
    if not data then return end
    FGUI:GButton_setTitle(item, data.name)
end

function PCMainPlayer:OnCreateTeam()
    local hasTeam = SL:GetValue("TEAM_COUNT") > 0
    if not hasTeam then
        FGUI:Open("Team_pc", "PCTeamCreatePanel")
    end
end

function PCMainPlayer:OnJoinTeam()
    FGUI:Open("Team_pc", "PCTeamNearPanel")
end

function PCMainPlayer:OnTeamMemberUpdate()
    local hasTeam = SL:GetValue("TEAM_COUNT") > 0
    if hasTeam == self._hasTeam then return end
    self._hasTeam = hasTeam
    if hasTeam then
        self:OnHideTeamOperation()
    end
end


-----------------------------------注册事件--------------------------------------
function PCMainPlayer:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "PCMainPlayer", handler(self, self.UpdatePropertys))
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_CHANGE, "PCMainPlayer", handler(self, self.UpdateProperty))
    SL:RegisterLUAEvent(LUA_EVENT_HP_CHANGE, "PCMainPlayer", handler(self, self.UpdateHP))
    SL:RegisterLUAEvent(LUA_EVENT_MP_CHANGE, "PCMainPlayer", handler(self, self.UpdateMP))
    SL:RegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "PCMainPlayer", handler(self, self.UpdateLevel))
    SL:RegisterLUAEvent(LUA_EVENT_PKSTATE_CHANGE, "PCMainPlayer", handler(self, self.UpdatePKMode))
    SL:RegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE,"PCMainPlayer",handler(self, self.OnUpdateHead))
    SL:RegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE,"PCMainPlayer",handler(self, self.OnUpdateHead))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA,"PCMainPlayer",handler(self, self.OnUpdateHead))

    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "PCMainPlayer", handler(self, self.OnTeamMemberUpdate))
end

function PCMainPlayer:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "PCMainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_CHANGE, "PCMainPlayer")
	SL:UnRegisterLUAEvent(LUA_EVENT_HP_CHANGE, "PCMainPlayer")
	SL:UnRegisterLUAEvent(LUA_EVENT_MP_CHANGE, "PCMainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "PCMainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_PKSTATE_CHANGE, "PCMainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE,"PCMainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE,"PCMainPlayer")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA,"PCMainPlayer")

    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "PCMainPlayer")
end


return PCMainPlayer