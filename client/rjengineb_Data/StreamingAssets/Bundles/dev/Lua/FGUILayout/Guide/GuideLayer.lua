local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local GuideLayer = class("GuideLayer", BaseFGUILayout)

function GuideLayer:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self._uiGuideTip = FGUI:ui_delegate(self._ui.GuideTip)
	self._arrowAni = FGUI:GetTransition(self._ui.GuideTip, ("ArrowAni"))
	self._task = nil
	self._guideArrController =FGUI:getController(self._ui.GuideTip,"arrDir")
	FGUI:setOnClickEvent(self._ui.blackBack, handler(self, self.BlackBackClickEvent))

	self.stageClickHandler = handler(self, self.StageClickEvent)
	self.stageSizeClickHandler = handler(self, self.StageSizeChangeEvent)
	self.STAGE_EVENT_GUIDE = "STAGE_EVENT_GUIDE"
end

function GuideLayer:RegisterEvent()
	FGUI:StageEvent_AddListener(self.STAGE_EVENT_GUIDE,self.stageClickHandler)
	FGUI:StageEvent_AddListener(self.STAGE_EVENT_GUIDE,self.stageSizeClickHandler,2)
	SL:RegisterLUAEvent(LUA_EVENT_GUIDE_HIDE, "GuideLayer", handler(self, self.OnHide))
end

function GuideLayer:UnRegisterEvent()
	FGUI:StageEvent_RemoveListener(self.STAGE_EVENT_GUIDE)
	FGUI:StageEvent_RemoveListener(self.STAGE_EVENT_GUIDE,2)
	SL:UnRegisterLUAEvent(LUA_EVENT_GUIDE_HIDE, "GuideLayer")
end

function GuideLayer:Enter(task)

end

function GuideLayer:Refresh(task)
	self:OnShow()
	self:OnUpdateTask(task)
end

function GuideLayer:OnShow()
	self:RegisterEvent()
	FGUI:setVisible(self.component, true)
end

function GuideLayer:OnHide()
	self:UnRegisterEvent()
	FGUI:setVisible(self.component, false)
	FGUI:RemoveChildren(self._uiGuideTip.Node_sui)
end

function GuideLayer:Exit()
	self:UnRegisterEvent()
end

function GuideLayer:PointInRect(px,py,rectX,rectY,rectWidth,rectHeight)
	local left = rectX
	local  right = rectX +  rectWidth
	local top = rectY
	local  bottom = rectY +  rectHeight
	return (px > left) and (px <right)and (py >top)and (py <bottom)
end

function GuideLayer:PointInEllipse(px,py,ellipseX,ellipseY,ellipseWidth,ellipseHeight)
	local centerX = ellipseX + ellipseWidth /2
	local centerY = ellipseY + ellipseHeight /2

	local a = math.abs(ellipseWidth) /2
	local b = math.abs(ellipseHeight) /2

	local dx = px - centerX
	local dy = py - centerY

	return (dx *dx) / (a*a) + (dy *dy) / (b*b) <= 1
end
function GuideLayer:CheckClickInArea(eventData)
	if  self._task then
		local maskWidth,maskHeight = FGUI:getSize(self._ui.window)
		local maskPosX,maskPosY =  FGUI:getPosition(self._ui.window)
		local clickX,clickY = FGUI:getTouchPosition(eventData)

		if self._task._maskGraph == 0 then
			return self:PointInEllipse(clickX,clickY,maskPosX,maskPosY,maskWidth,maskHeight)
		elseif self._task._maskGraph == 1 then
			return self:PointInRect(clickX,clickY,maskPosX,maskPosY,maskWidth,maskHeight)
		end
	end
	return false
end
--点击挖洞区域
function GuideLayer:StageClickEvent(data)
	if data.eventName == self.STAGE_EVENT_GUIDE then
		local  eventData = data.eventData
		if self:CheckClickInArea(eventData) then
			self:CompleteTask()
		end
	end
end

function GuideLayer:StageSizeChangeEvent(data)
	if data.eventName == self.STAGE_EVENT_GUIDE then
		self:RefreshView(self._task )
	end
end

function GuideLayer:ExecuteTask()
	if  self._task._ssrWidget then
		FGUI:SimulateClick(self._task._ssrWidget,false)
		self:CompleteTask()

	end
end
--点击背景mask
function GuideLayer:BlackBackClickEvent(eventData)
	if not self._task then
		return
	end

	if self._task._fireWidgetClick then
		self:ExecuteTask()
	else
		if not  self._task:IsForce() then
			self:CompleteTask()
		end
	end

	FGUI:EventContext_stopPropagation(eventData)
end


function GuideLayer:HandleArrowAnimation(task)
	if not self._arrowAni then
		return
	end

	FGUI:Transition_play(self._arrowAni)
end


function GuideLayer:RefreshView(task)
	if not task then
		return
	end

	local desc = task._desc or ""
	local windex = string.find(desc,"widget:")
    if windex and windex == 1 then 
        local widgetstr = string.sub(desc, windex + 7)
		FGUI:setVisible(self._uiGuideTip.desc, false)
		FGUI:setVisible(self._uiGuideTip.Node_sui, true)
		FGUI:GTextField_setText(self._uiGuideTip.desc, " ")
		FGUI:RemoveChildren(self._uiGuideTip.Node_sui)
        SL:LoadSUI(self._uiGuideTip.Node_sui, widgetstr, handler(SL, SL.SubmitAct), nil)
    else
		FGUI:setVisible(self._uiGuideTip.desc, true)
		FGUI:setVisible(self._uiGuideTip.Node_sui, false)
		FGUI:GTextField_setText(self._uiGuideTip.desc, desc)		--先设置文字，保证后面对容器的大小计算正确
    end

	local maskWidth = 50
	local maskHeight = 50
	local maskPosX = 0
	local maskPosY = 0
	local guideTipPosX = 0
	local guideTipPosY = 0
	if task._ssrWidget then
		maskWidth,maskHeight = FGUI:getSize(task._ssrWidget)

		local anchor =  FGUI:getAsAnchor(task._ssrWidget)
		if anchor then    --注意，此处FGUI界面做法不同，直接通过FGUI:getPosition获取组件坐标可能导致错误的结果
			local pivotX,pivotY =  FGUI:getAnchorPoint(task._ssrWidget)
			maskPosX,maskPosY =  FGUI:LocalToWorld(task._ssrWidget,-maskWidth*pivotX,-pivotY*maskHeight)
		else
			maskPosX,maskPosY =  FGUI:LocalToWorld(task._ssrWidget,0,0)
		end

		maskPosX= math.abs(maskPosX)
		maskPosY= math.abs(maskPosY)
		--CalculateGuideTipPos
		local guideGroupWidth,guideGroupHeight = FGUI:getSize(self._uiGuideTip.GuideContent)		--包含箭头等其他自定义元素的容器大小
		local guideTipWidth,guideTipHeight = FGUI:getSize(self._ui.GuideTip)						--背景的容器大小
		local subWidth = (guideGroupWidth- guideTipWidth)/2					--自定义元素的容器大小和tip背景的宽度差值
		local subHeight = (guideGroupHeight- guideTipHeight)/2					--自定义元素的容器大小和tip背景的高度差值
		if task._arrDir == 1 then
			guideTipPosX = maskPosX  + maskWidth + subWidth
			guideTipPosY = maskPosY  + maskHeight /2 -  guideTipHeight /2
		elseif task._arrDir == 2 then
			guideTipPosX = maskPosX   + maskWidth + subWidth
			guideTipPosY = maskPosY +  maskHeight + subHeight
		elseif task._arrDir == 3 then
			guideTipPosX = maskPosX + maskWidth /2 - guideTipWidth /2
			guideTipPosY = maskPosY +  maskHeight + subHeight
		elseif task._arrDir == 4 then
			guideTipPosX =  maskPosX  - guideGroupWidth + subWidth
			guideTipPosY = maskPosY +  maskHeight + subHeight
		elseif task._arrDir == 5 then
			guideTipPosX = maskPosX  - guideGroupWidth + subWidth
			guideTipPosY = maskPosY  + maskHeight /2 -  guideTipHeight /2
		elseif task._arrDir == 6 then
			guideTipPosX = maskPosX  - guideGroupWidth + subWidth
			guideTipPosY = maskPosY - guideGroupHeight + subHeight
		elseif task._arrDir == 7 then
			guideTipPosX = maskPosX  + maskWidth /2 - guideTipWidth /2
			guideTipPosY = maskPosY - guideGroupHeight + subHeight
		elseif task._arrDir == 8 then
			guideTipPosX = maskPosX  + maskWidth + subWidth
			guideTipPosY = maskPosY - guideGroupHeight + subHeight
		end
	end

	FGUI:setAlpha(self._ui.blackBack, task._hideMask and 0 or 1)
	if task._maskGraph == 0 then
		FGUI:GGraph_DrawEllipse(self._ui.window, maskWidth, maskHeight, 1)
	elseif task._maskGraph == 1 then
		FGUI:GGraph_DrawRect(self._ui.window, maskWidth, maskHeight, 1)
	end

	FGUI:setPosition(self._ui.window, maskPosX, maskPosY)

	FGUI:setPosition(self._ui.GuideTip, guideTipPosX, guideTipPosY)

	FGUI:Controller_setSelectedIndex(	self._guideArrController,task._arrDir and task._arrDir - 1 or 0)

	self:HandleArrowAnimation(task)

	self:AutoExecuteTask(task)
end

function GuideLayer:OnUpdateTask(task)
	FGUI:stopAllActions(self.component)
	self._task = task and task or self._task
	self:RefreshView(self._task)
end

function GuideLayer:CompleteTask()
	self:StopAutoExecuteTaskTimer()
	if self._task then
		self._task:Exit()
	end

	if self._task._clickCallback then
		self._task._clickCallback()
	end
end

function GuideLayer:StopAutoExecuteTaskTimer()
	if self._executeTimerID then
		SL:UnSchedule(self._executeTimerID)
		self._executeTimerID= nil
	end
	self._executeTime = 0
end
function GuideLayer:AutoExecuteTask(task)
	if task then
		self:StopAutoExecuteTaskTimer()
		self._executeTime = 0
		local totalTime = task:GetAutoExecuteTime()
		if totalTime > 0 then
			self._executeTimerID = SL:Schedule(function()
				self._executeTime = self._executeTime + 1
				if self._executeTime >= totalTime then
					self:ExecuteTask()
					return
				end
				task:AutoExecuteTaskTick( math.max(0,totalTime  - self._executeTime))
			end, 1)
		end
	end
end
return GuideLayer