local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainTarget = class("MainTarget", BaseFGUILayout)
local FuncDockUtil = requireFGUILayout("FuncDock/FuncDockUtil")

function MainTarget:Create()
	self._ui = FGUI:ui_delegate(FGUI:GetChild(self.component, "Target"))
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Main)

    self._targetID = nil

    FGUI:setOnClickEvent(self._ui.Button_close, handler(self, self.OnCancelTarget))
end

function MainTarget:Enter()
	self:RegisterEvent()
end

function MainTarget:Refresh()
    self:SelectTarget(SL:GetValue("SELECT_TARGET_ID"))
end

function MainTarget:Exit()
	self:RemoveEvent()
    FGUI:stopAllActions(self._ui.ProgressBar_hpTween)
end

function MainTarget:Destroy()
    self._ui = nil	
end


--------------------------------------------------------

function MainTarget:OnCancelTarget()
    if not self._targetID then return end
    SL:SetValue("SELECT_TARGET_ID", nil)
end

function MainTarget:SelectTarget(targetID)
    if targetID == self._targetID then return end
    self._targetID = nil
    if not targetID then
        self:Close()
        return
    end
    self._targetID = targetID
    self:UpdateTargetHP(false)
    self:UpdateTargetInfo()
end

function MainTarget:OnRefreshActorHP(actorID)
    if not actorID then return end
    if self._targetID ~= actorID then return end

    self:UpdateTargetHP(true)
end

function MainTarget:OnOwnerChange(actorID)
    if self._targetID ~= actorID then return end
    self:UpdateTargetOwner()
end

function MainTarget:UpdateTargetHP(tween)
    local targetID = self._targetID
    local inView = SL:GetValue("ACTOR_IN_VIEW", targetID)
    if not inView then
        return
    end

    -- 血量刷新
    local curHP = SL:GetValue("ACTOR_HP", targetID)
    local maxHP = SL:GetValue("ACTOR_MAXHP", targetID)
    local percent = math.ceil(curHP / maxHP * 100)

    FGUI:GTextField_setText(self._ui.Text_hp, curHP .. "/" .. maxHP)
    FGUI:GProgressBar_setValue(self._ui.ProgressBar_hp, percent)
    FGUI:stopAllActions(self._ui.ProgressBar_hpTween)
    if not tween then--切换目标情况
        FGUI:GProgressBar_setValue(self._ui.ProgressBar_hpTween, percent)
    else
        local curTweenV = FGUI:GProgressBar_getValue(self._ui.ProgressBar_hpTween)
        if curTweenV > percent then--扣血
            local time = (curTweenV - percent) / 50
            FGUI:runAction(self._ui.ProgressBar_hpTween, FGUI:ActionEaseSineIn(FGUI:ActionProgressTo(time, percent)))
        else
            FGUI:GProgressBar_setValue(self._ui.ProgressBar_hpTween, percent)
        end
    end
end

function MainTarget:UpdateTargetInfo()
    local targetID = self._targetID
    local inView = SL:GetValue("ACTOR_IN_VIEW", targetID)
    if not inView then return end

    local typeController = FGUI:getController(self._ui.nativeUI, "type")
    if SL:GetValue("ACTOR_IS_PLAYER", targetID) then
        FGUI:Controller_setSelectedIndex(typeController, 1)
        local isTeamMember = SL:GetValue("TEAM_IS_MEMBER", targetID)
        local data = {
            AvatarID = SL:GetValue("ACTOR_AVATAR", targetID),
            Job = SL:GetValue("ACTOR_JOB_ID", targetID),
            Sex = SL:GetValue("ACTOR_SEX", targetID),
            targetName = SL:GetValue("ACTOR_NAME", targetID),
            Level = SL:GetValue("ACTOR_LEVEL", targetID),
            GuildName = SL:GetValue("ACTOR_GUILD_NAME",targetID),
            targetId = targetID,
            TipsType = isTeamMember and SL:GetValue("DOCKTYPE_NENUM").Func_Team or SL:GetValue("DOCKTYPE_NENUM").Func_Near_Player,
            FrameID = SL:GetValue("ACTOR_AVATAR_FRAME",targetID)
        }

        local clickCallback = function()
            FGUIFunction:OpenFuncDockTips(data)
        end

        FGUIFunction:SetCommonPlayerFrame(self._ui.Comp_head,data,clickCallback)
    else
        FGUI:Controller_setSelectedIndex(typeController, 0)
    end
    self:UpdateTargetNameInfo()
    self:UpdateTargetOwner()
end

function MainTarget:UpdateTargetNameInfo()
    local targetID = self._targetID
    local level = 0
    local name

    if SL:GetValue("ACTOR_IS_PLAYER", targetID) then
        name = FGUIFunction:GetServerName(SL:GetValue("ACTOR_NAME", targetID)) or ""
        level = SL:GetValue("ACTOR_LEVEL", targetID) or 0
    else
        name = SL:GetValue("ACTOR_NAME", targetID) or ""
        local typeIndex = SL:GetValue("ACTOR_TYPE_INDEX", targetID)
        level = SL:GetValue("MONSTER_LEVEL", typeIndex)
    end
    print("***********************************",SL:GetValue("ACTOR_IS_PET",targetID))
    if SL:GetValue("ACTOR_IS_PET",targetID) then
        --看的是宠物，隐藏宠物对应等级
        FGUI:setVisible(self._ui.Text_level,false)
    else
        FGUI:GTextField_setText(self._ui.Text_level, "Lv:" .. level)
        FGUI:setVisible(self._ui.Text_level,true)
    end
    print("***********************************")
    FGUIFunction:ScrollText_setString(self._ui.Label_name, name, 1, 0)
end

function MainTarget:UpdateTargetOwner()
    local belong
    if self._targetID then
        belong = SL:GetValue("ACTOR_OWNER_NAME", self._targetID) or ""
        belong = FGUIFunction:GetServerName(belong)
    end
    if belong == self._belong then return end
    self._belong = belong
    if belong ~= "" then
        local isSelf = SL:GetValue("ACTOR_OWNER_ID", self._targetID) == SL:GetValue("USER_ID")
        FGUI:GTextField_setColor(self._ui.Text_belong, isSelf and "#00FF00" or "#FF0000")
    end
    FGUI:GTextField_setText(self._ui.Text_belong, belong)
end

-----------------------------------注册事件--------------------------------------
function MainTarget:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ACTOR_REFRESH_HP, "MainTarget", handler(self, self.OnRefreshActorHP))
    SL:RegisterLUAEvent(LUA_EVENT_OWNER_CHANGE, "MainTarget", handler(self, self.OnOwnerChange))
    SL:RegisterLUAEvent(LUA_EVENT_SELECT_TARGET_DIE, "MainTarget", handler(self, self.Close))
end

function MainTarget:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_REFRESH_HP, "MainTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_OWNER_CHANGE, "MainTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_SELECT_TARGET_DIE, "MainTarget")
end


return MainTarget