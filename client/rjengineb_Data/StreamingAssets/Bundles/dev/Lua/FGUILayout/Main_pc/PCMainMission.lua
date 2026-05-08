local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCMainMission = class("PCMainMission", BaseFGUILayout)


function PCMainMission:Create()
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Main)
    self._ui = FGUI:ui_delegate(self.component)
    self._mission = FGUIFunction:BindClass(self.component, "Main/MainMission")
    self._mission:Create()

    self._show = false

    self._hideTrans = FGUI:GetTransition(self.component, "hide")
    self._hideCompleteHandler = handler(self, self.SetVisible, false)

    self._visible = false

    FGUI:setOnClickEvent(self._ui.Btn_arrow, handler(self, self.OnSwitch, true))

    self:Show(false)
end

function PCMainMission:Enter()
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_HIDE, "PCMainMission", handler(self, self.Hide,true))
end

function PCMainMission:Exit()
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_HIDE, "MainAssist")
end

function PCMainMission:Destroy()
    self._mission:Destroy()
    self._ui = nil
    self._hideTrans = nil
end

-------------------------------------------

function PCMainMission:OnSwitch(tween)
    if self._show then
        self:Hide(tween)
    else
        self:Show(tween)
    end
end

function PCMainMission:Show(tween)
    if self._show then return end
    self._show = true
    self:SetVisible(true)
    FGUI:Transition_stop(self._hideTrans, false, false)
    if tween then
        FGUI:Transition_playReverse(self._hideTrans)
    else
        FGUI:Transition_playReverse(self._hideTrans, nil, 1, 0, 0.5, -1)
    end
end

function PCMainMission:Hide(tween)
    if not self._show then return end
    self._show = false
    FGUI:Transition_stop(self._hideTrans, false, false)
    if tween then
        FGUI:Transition_play(self._hideTrans, self._hideCompleteHandler)
    else
        FGUI:Transition_play(self._hideTrans, self._hideCompleteHandler, 1, 0, 0.5, -1)
    end
end

function PCMainMission:SetVisible(v)
    if self._visible == v then return end
    self._visible = v
    FGUI:setVisible(self._ui.group, v)
    if v then
        --Enter
        self._mission:Enter()
    else
        --Exit
        self._mission:Exit()
    end
end


return PCMainMission