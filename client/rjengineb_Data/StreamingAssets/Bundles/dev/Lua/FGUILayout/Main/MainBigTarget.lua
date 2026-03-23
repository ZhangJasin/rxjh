local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainBigTarget = class("MainBigTarget", BaseFGUILayout)

local TWEEN_TIME = 0.5--秒

function MainBigTarget:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Main)

    self._targetID = nil
    self._belongID = nil

    self._curHP = 0
    self._maxHP = 0
    self._hpSum = 1         --总条数
    self._hpNum = nil       --当前条数

    self._tweenTime = 0
    self._isTween = false

    self._waitCloseHandler = handler(self, self.WaitClose)
    FGUI:setOnClickEvent(self._ui.Button_close, handler(self, self.OnClose))
end

function MainBigTarget:Enter()
	self:RegisterEvent()
end

function MainBigTarget:Refresh()
    self:SelectTarget(SL:GetValue("SELECT_TARGET_ID"))
end

function MainBigTarget:Exit()
	self:RemoveEvent()
    self._targetID = nil
    self:ClearCloseTimer()
end

function MainBigTarget:Destroy()
    self._ui = nil	
end


--------------------------------------------------------


function MainBigTarget:OnClose()
    SL:SetValue("SELECT_TARGET_ID", nil)
end

function MainBigTarget:SelectTarget(targetID)
    if targetID == self._targetID then return end
    if not targetID then      
        self:Close()
        return
    end
    self._targetID = targetID
    self:UpdateTargetHP(true)
    self:UpdateTargetInfo()
end

function MainBigTarget:OnRefreshActorHP(actorID)
    if not actorID then return end
    if self._targetID ~= actorID then return end

    self:UpdateTargetHP(false)
end

function MainBigTarget:OnOwnerChange(actorID)
    if self._targetID ~= actorID then return end
    self:UpdateTargetOwner()
end

function MainBigTarget:UpdateTargetHP(changeTarget)
    local targetID = self._targetID
    local inView = SL:GetValue("ACTOR_IN_VIEW", targetID)
    if not inView then
        return
    end

    local curHP = SL:GetValue("ACTOR_HP", targetID)
    local maxHP = SL:GetValue("ACTOR_MAXHP", targetID)
    local capacity = maxHP / self._hpSum--单条血容量
    self._curHP = curHP
    self._maxHP = maxHP

    self:ClearCloseTimer()
    if changeTarget then
        self._hpSum = 1
        if SL:GetValue("ACTOR_IS_MONSTER", targetID) then
            local typeIndex = SL:GetValue("ACTOR_TYPE_INDEX", targetID)
            local config = SL:GetMetaValue("MONSTER_CONFIG", typeIndex)
            if config and config.HpCount then
                capacity = maxHP / config.HpCount
                self._hpSum = math.ceil(config.HpCount)
            end
        end
    end

    -- 血量刷新
    local percent = math.ceil(curHP / maxHP * 100)
    FGUI:GTextField_setText(self._ui.Text_hp, percent .. "%")
    if changeTarget then--切换目标情况
        local curPer = self._curHP / self._maxHP * self._hpSum
        self._tweenHP = self._curHP
        self._isTween = false
        self:UpdateHP(curPer)
    else
        self._tweenDiff = self._tweenHP - self._curHP
        self._startHP = self._tweenHP
        self._isTween = true
        self._tweenTime = 0
    end
end

-- self._startHP = 0
function MainBigTarget:Update(dt)
    if not self._isTween then return end
    local time = self._tweenTime + dt
    self._tweenTime = time

    self._tweenHP = self._startHP - self._tweenDiff * math.min(1, time / TWEEN_TIME)
    local numPro = self._tweenHP / self._maxHP * self._hpSum
    self:UpdateHP(numPro)

    if time >= TWEEN_TIME then
        --最后一次更新
        self._isTween = false
        self._tweenHP = self._curHP

        --死亡移除
        if self._curHP <= 0 then
            self:ClearCloseTimer()
            self._timer = SL:ScheduleOnce(self._waitCloseHandler, 0.2)
        end
    end
end

function MainBigTarget:ClearCloseTimer()
    if not self._timer then return end
    SL:UnSchedule(self._timer)
    self._timer = nil
end

function MainBigTarget:WaitClose()
    self._timer = nil
    self:Close()
end

function MainBigTarget:UpdateHP(numPro)
    local num = math.floor(numPro)
    local per = numPro - num
    self._hpPer = per
    -- if per <= 0 then num = num - 1 end
    FGUI:GLoader_setFillAmount(self._ui.Loader_hp, per)
    if self._hpNum ~= num then
        self._hpNum = num
        self:UpdateHpNum()
    end
end

function MainBigTarget:UpdateHpNum()
    local hpBarUrl = "ui://Main/image_bigHp_" .. ((self._hpNum % 10) + 1)
    local numStr = self._hpNum >= 1 and ("x" .. self._hpNum) or ""
    local hpBgUrl = self._hpNum >= 1 and "ui://Main/image_bigHp_" .. (((self._hpNum - 1) % 10) + 1) or ""

    FGUI:GTextField_setText(self._ui.Text_count, numStr)
    FGUI:GLoader_setUrl(self._ui.Loader_hp, hpBarUrl)
    FGUI:GLoader_setUrl(self._ui.Loader_hpBg, hpBgUrl)
end


function MainBigTarget:UpdateTargetInfo()
    local targetID = self._targetID
    local inView = SL:GetValue("ACTOR_IN_VIEW", targetID)
    if not inView then return end
    self:UpdateTargetNameInfo()
    self:UpdateTargetOwner()
end

function MainBigTarget:UpdateTargetNameInfo()
    local targetID = self._targetID
    local name  = SL:GetValue("ACTOR_NAME", targetID) or ""
    local level = 0
    local icon = ""

    if SL:GetValue("ACTOR_IS_PLAYER", targetID) then
        level = SL:GetValue("ACTOR_LEVEL", targetID) or 0
    else
        local typeIndex = SL:GetValue("ACTOR_TYPE_INDEX", targetID)
        level = SL:GetValue("MONSTER_LEVEL", typeIndex)
        icon = SL:GetValue("MONSTER_ICON", typeIndex) or ""
    end
    FGUI:GLoader_setUrl(self._ui.Loader_head, icon, nil, true)
    FGUI:GTextField_setText(self._ui.Text_level, "Lv:" .. level)
    FGUIFunction:ScrollText_setString(self._ui.Label_name, name, 1, 0)
end

function MainBigTarget:UpdateTargetOwner()
    local belongID
    if self._targetID then
        belongID = SL:GetValue("ACTOR_OWNER_ID", self._targetID)
    end
    if belongID == self._belongID then return end
    self._belongID = belongID
    local belongName = SL:GetValue("ACTOR_OWNER_NAME", self._targetID) or ""
    local isSelf = belongID == SL:GetValue("USER_ID")
    FGUI:GTextField_setColor(self._ui.Text_belong, isSelf and "#00FF00" or "#FF0000")
    FGUI:GTextField_setText(self._ui.Text_belong, belongName)
end

function MainBigTarget:OnTargetDie()
    if self._tweenHP <= 0 then
        self:Close()
        return
    end
    --不直接关闭,等待掉血动画结束后关闭
end

-----------------------------------注册事件--------------------------------------
function MainBigTarget:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ACTOR_REFRESH_HP, "MainBigTarget", handler(self, self.OnRefreshActorHP))
    SL:RegisterLUAEvent(LUA_EVENT_OWNER_CHANGE, "MainBigTarget", handler(self, self.OnOwnerChange))
    SL:RegisterLUAEvent(LUA_EVENT_SELECT_TARGET_DIE, "MainBigTarget", handler(self, self.OnTargetDie))
end

function MainBigTarget:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_REFRESH_HP, "MainBigTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_OWNER_CHANGE, "MainBigTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_SELECT_TARGET_DIE, "MainBigTarget")
end


return MainBigTarget