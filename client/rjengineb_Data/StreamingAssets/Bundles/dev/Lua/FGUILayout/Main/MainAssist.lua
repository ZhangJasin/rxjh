local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainAssist = class("MainAssist", BaseFGUILayout)

local IDX_NULL = 0
local IDX_MISSION = 1
local IDX_TEAM = 2

function MainAssist:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Main)

    self._index = IDX_NULL
    self._hideAssist = false

    self._pageDatas = {
        [IDX_MISSION] = {
            objName = "MainMission",
            obj = nil,
        },
        [IDX_TEAM] = {
            objName = "MainTeam",
            obj = nil,
        },
    }

    FGUI:GButton_setChangeStateOnClick(self._ui.Btn_mission, false)
    FGUI:GButton_setChangeStateOnClick(self._ui.Btn_team, false)
    FGUI:setOnClickEvent(self._ui.Btn_arrow, handler(self, self.OnSwitch))
    FGUI:setOnClickEvent(self._ui.Btn_mission, handler(self, self.ShowMission))
    FGUI:setOnClickEvent(self._ui.Btn_team, handler(self, self.ShowTeam))

    FGUIFunction:AdaptNotch(self.component)
end

function MainAssist:Enter()
	self:RegisterEvent()

	self:ShowMission()

    SL:ComponentAttach(SLDefine.SUIComponentTable.MainRootAssist, self._ui.Node_attach)
end

function MainAssist:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.MainRootAssist)

	self:RemoveEvent()
    self:PageClose()
end

function MainAssist:Destroy()
    self._ui = nil
    for k, v in pairs(self._pageDatas) do
        if v and v.obj then
            v.obj:Destroy()
            v.obj = nil
        end
    end
    self._pageDatas = nil
    self._isDestroy = true
end


--------------------------------------------------------

function MainAssist:OnShow()
    self:ChangeHideStatus(false)
end

function MainAssist:OnHide()
    self:ChangeHideStatus(true)
end

function MainAssist:OnSwitch()
    self:ChangeHideStatus(not self._hideAssist)
end

function MainAssist:ChangeHideStatus(isHide)
    if self._hideAssist == isHide then return end
    self._hideAssist = isHide
    local trans = FGUI:GetTransition(self.component, "Hide")
    if self._hideTweenning then
        FGUI:Transition_setPaused(trans, true)
    end
    self._hideTweenning = true
    local complete = function()
        self._hideTweenning = false
    end
    if self._hideAssist then
        FGUI:Transition_play(trans, complete)
    else
        FGUI:Transition_playReverse(trans, complete)
        if self._index == IDX_TEAM then 
            local hasTeam = SL:GetValue("TEAM_COUNT") > 0
            if hasTeam then 
                SL:RequestTeamMemberData()
            end
        end 
    end
end


function MainAssist:PageTo(index)
    if not index then return end
    if self._index == index then return end
    self:PageClose()
    self:PageOpen(index)
    self:UpdateSelect()
end

function MainAssist:PageClose()
    local pageData = self._pageDatas[self._index]
    if not pageData then return true end
    local pageObj = pageData.obj
    if pageObj then 
        pageObj:Exit()
        FGUI:setVisible(pageObj.component, false)
    end
    self._index = IDX_NULL
    return true
end

function MainAssist:PageOpen(index)
    if self._index == index then return end
    self._index = index
    local pageData = self._pageDatas[self._index]
    if not pageData then return end
    local pageObj = pageData.obj
    -- 异步流程
    if not pageObj then
        if pageData.loading then return end
        pageData.loading = true
        FGUI:CreateObjectAsync("Main", pageData.objName, function(pageObj)
            if self._isDestroy then
                FGUI:RemoveFromParent(pageObj.component, true)
                return
            end
            FGUI:AddChild(self._ui.Node_Content, pageObj.component)
            pageObj:Create()
            pageData.obj = pageObj
            if self._index == index then
                FGUI:setVisible(pageObj.component, true)
                pageObj:Enter()
            else
                FGUI:setVisible(pageObj.component, false)
            end
        end, true)
    else
        FGUI:setVisible(pageObj.component, true)
        pageObj:Enter()
    end
end

function MainAssist:UpdateSelect()
    FGUI:GButton_setSelected(self._ui.Btn_mission, self._index == IDX_MISSION)
    FGUI:GButton_setSelected(self._ui.Btn_team, self._index == IDX_TEAM)
end

function MainAssist:ShowMission()
    self:PageTo(IDX_MISSION)
end

function MainAssist:ShowTeam()
    local hasTeam = SL:GetValue("TEAM_COUNT") > 0
    if self._index == IDX_TEAM then
        if hasTeam then  
            FGUI:Open("Team", "TeamPanel")
        else 
            FGUI:Open("Team", "TeamCreatePanel")
        end 
        return
    else 
        if hasTeam then 
            SL:RequestTeamMemberData()
        end
    end
    self:PageTo(IDX_TEAM)
end

function MainAssist:OnJoinTeam(userName)
    local myName = SL:GetValue("USER_NAME")
    if myName == userName then 
        self:PageTo(IDX_TEAM)
    end
end

-----------------------------------注册事件--------------------------------------
function MainAssist:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_SHOW, "MainAssist", handler(self, self.OnShow))
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_HIDE, "MainAssist", handler(self, self.OnHide))
    SL:RegisterLUAEvent(LUA_EVENT_ASSIST_CHANGE, "MainAssist", handler(self, self.OnSwitch))
    SL:RegisterLUAEvent(LUA_EVENT_JOIN_TEAM, "MainAssist", handler(self, self.OnJoinTeam))
end

function MainAssist:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_SHOW, "MainAssist")
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_HIDE, "MainAssist")
    SL:UnRegisterLUAEvent(LUA_EVENT_ASSIST_CHANGE, "MainAssist")
    SL:UnRegisterLUAEvent(LUA_EVENT_JOIN_TEAM, "MainAssist")
end


return MainAssist