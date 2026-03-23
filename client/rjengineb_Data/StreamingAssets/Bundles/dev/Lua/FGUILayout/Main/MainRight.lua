local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainRight = class("MainRight", BaseFGUILayout)

function MainRight:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Main)
    
    self._sklll     = FGUIFunction:BindClass(self._ui.Group_skill, "Main/MainSkill")
    self._quickUse  = FGUIFunction:BindClass(self._ui.MainQuickUse, "Main/MainQuickUse")
    self._rightFunc = FGUIFunction:BindClass(self._ui.Group_func, "Main/MainRightFunc")

    self._rightFunc:Create()
    self._sklll:Create()
    self._quickUse:Create()

    FGUI:setOnClickEvent(self._ui.Button_bag, handler(self, self.OnBag))
    FGUI:setOnClickEvent(self._ui.Button_change, handler(self, self.OnSwitch))
    FGUI:setOnClickEvent(self._ui.Button_npcTalk, handler(self, self.OnNpcTalk))

    self._showSkill = true

    self._npcTalkDis = SL:GetValue("GAME_DATA", "NpcTalkBubble") or 3
    self._nearestNpcId = nil
    self._waitCheckNpcTalk = false
    self._waitNpcTalkHandler = handler(self, self.OnResetWaitNpcTalk)

    local posX, posY = FGUI:getPosition(self._ui.Button_bag)
    FGUIFunction:SetPickItemFxUIEndPos(posX, posY)
    FGUIFunction:AdaptNotch(self.component)
end

function MainRight:Enter()
    self._sklll:Enter()
    self._quickUse:Enter()
    self._rightFunc:Enter()

	self:RegisterEvent()
    self:UpdateNpcTalkButton()
end

function MainRight:Exit()
    self._sklll:Exit()
    self._quickUse:Exit()
    self._rightFunc:Exit()

	self:RemoveEvent()
end

function MainRight:Destroy()
    self._sklll:Destroy()
    self._quickUse:Destroy()
    self._rightFunc:Destroy()

    self._ui = nil
end

function MainRight:OnBag()
    FGUI:Open("Bag","PlayerInfoPanel",1)
end

-----------------------------------Switch------------------------------------

function MainRight:OnSwitch()
    self:SwitchVisible(not self._showSkill)
end

function MainRight:SwitchVisible(showSkill, atOnce)
    if self._showSkill == showSkill then return end
    self._showSkill = showSkill
    local trans = FGUI:GetTransition(self.component, "ShowSkill")
    FGUI:Transition_stop(trans, false, false)
    if atOnce then
        --立即切换
        if self._showSkill then
            FGUI:Transition_play(trans, nil, 1, 0, 0.2, 0.2)
        else
            FGUI:Transition_playReverse(trans, nil, 1, 0, 0.2, 0.2)
        end
    else
        if self._showSkill then
            FGUI:Transition_play(trans, nil)
        else
            FGUI:Transition_playReverse(trans, nil)
        end
    end
end

function MainRight:OnShowFunc(atOnce)
    self:SwitchVisible(false, atOnce)
end

-----------------------------------NpcTalk-------------------------------------

function MainRight:OnNpcTalk()
    if not self._nearestNpcId then return end
    SL:RequestTalkToNPC(self._nearestNpcId)
end

function MainRight:OnResetWaitNpcTalk()
    self._waitCheckNpcTalk = false
end

function MainRight:OnPlayerPosChange()
    if self._waitCheckNpcTalk then return end
    self._waitCheckNpcTalk = true
    SL:ScheduleOnce(self._waitNpcTalkHandler, 0.1)
    local npcList = SL:GetValue("FIND_IN_VIEW_NPC_LIST")
    local minActorId = nil
    local minDis = 9999
    for k, actorId in pairs(npcList) do
        local dis = SL:GetValue("TARGET_DISTANCE_FROM_ME", actorId)
        if dis <= self._npcTalkDis and dis < minDis then
            minActorId = actorId
        end
    end
    self:UpdateNpcTalk(minActorId)
end

function MainRight:OnPlayerAction(actorID, act)
    if not SL:CheckIsMoveAction(act) then return end
    self:OnPlayerPosChange()
end

function MainRight:UpdateNpcTalk(actorId)
    if self._nearestNpcId == actorId then return end
    local curShow = self._nearestNpcId ~= nil
    self._nearestNpcId = actorId
    local show = actorId ~= nil
    if curShow ~= show and not SL:GetValue("ACTOR_IS_STALL_NPC",actorId) then
        self:UpdateNpcTalkButton()
    end
end

function MainRight:UpdateNpcTalkButton()
    FGUI:setVisible(self._ui.Button_npcTalk, self._nearestNpcId ~= nil)
end

-----------------------------------注册事件--------------------------------------
function MainRight:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MainRight", handler(self, self.OnPlayerPosChange))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_MAPPOS_CHANGE, "MainRight", handler(self, self.OnPlayerPosChange))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_PROCESS, "MainRight", handler(self, self.OnPlayerAction))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_COMPLETE, "MainRight", handler(self, self.OnPlayerAction))

    SL:RegisterLUAEvent(LUA_EVENT_MAIN_FUNC_SHOW, "MainRight", handler(self, self.OnShowFunc))
end

function MainRight:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MainRight")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_MAPPOS_CHANGE, "MainRight")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_PROCESS, "MainRight")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_COMPLETE, "MainRight")

    SL:UnRegisterLUAEvent(LUA_EVENT_MAIN_FUNC_SHOW, "MainRight")
end


return MainRight