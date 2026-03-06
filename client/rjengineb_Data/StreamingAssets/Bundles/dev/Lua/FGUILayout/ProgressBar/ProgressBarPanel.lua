local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local ProgressBarPanel = class("ProgressBarPanel", BaseFGUILayout)

function ProgressBarPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
end 

function ProgressBarPanel:Enter(data)
	-- body
	local offX, offY 	= 110, 0
	local posX, posY 	= FGUI:getPosition(self._ui.LoadingBar_1)
	local posX1, posY1 	= FGUI:getPosition(self._ui.Text_desc)
	FGUI:setPosition(self._ui.LoadingBar_1, posX + offX, posY + offY)
	FGUI:setPosition(self._ui.Text_desc, posX1 + offX, posY1 + offY)

	self.mNoDisJump = data.NoDisJump
	self.mDis = data.dis

	self:StartProgress(data)
	self:RegisterEvent()
end

function ProgressBarPanel:StartProgress(data)
	-- body
	if self.mScheduleID then
		SL:UnSchedule(self.mScheduleID)
		self.mScheduleID = nil
	end

    self.mElasped = 0
    self.mPercent = 0
    self.mTime = data.time or 0
    self.mDataMsg = data.msg or ""

	self.mScheduleID = SL:Schedule(handler(self, self.UpdateLoadingBar), 0.1)
	self:UpdateLoadingBar()
end

function ProgressBarPanel:UpdateLoadingBar()
	-- body
	self.mPercent = math.min(100, math.ceil(self.mElasped / self.mTime * 100))

    FGUI:GProgressBar_setValue(self._ui.LoadingBar_1, self.mPercent)
    FGUI:GTextField_setText(self._ui.Text_desc, string.format(self.mDataMsg, self.mPercent))
    self.mElasped = self.mElasped + 0.1

    -- 时间到
    if self.mPercent >= 100  then
        FGUI:Close("ProgressBar", "ProgressBarPanel")
    end
end

function ProgressBarPanel:Exit()
	if self.mScheduleID then
		SL:UnSchedule(self.mScheduleID)
		self.mScheduleID = nil
	end
end

function ProgressBarPanel:Destroy()
    self._ui = nil	
end

function ProgressBarPanel:OnMainPlayerActionBegin(actorID, act)
	-- body
	if not SL:ActionIsIdle(act) then
		return
    end

    if self.mDis and self.mDis > 0 then
        if self.mDis == 2 and SLDefine.MODEL_ACTION_NAME.ACTION_ATTACK == act then --施法时监听部分技能是否中断
            return
        end
        FGUI:Close("ProgressBar", "ProgressBarPanel")
    end
end

function ProgressBarPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_BEGIN, "ProgressBarPanel", handler(self, self.OnMainPlayerActionBegin))
end

function ProgressBarPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_BEGIN, "ProgressBarPanel")
end

return ProgressBarPanel