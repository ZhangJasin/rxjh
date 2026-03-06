local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PlayDice = class("PlayDice", BaseFGUILayout)

local dice_result_path = "ui://NPC/dice_result_%s"
local resultDuration = 3

function PlayDice:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	self._data = nil
	self._scheduleAni = nil
	self._scheduleClose = nil
	FGUI:GList_itemRenderer(self._ui.list_res, handler(self, self.OnResultListItemRenderer))
end

function PlayDice:Enter(data)
	if not data then
		FGUI:setVisible(self._ui.list_ani, false)
		FGUI:setVisible(self._ui.list_res, false)
		return
	end
	self._items = data.arr
	self._count = data.count
	-- 播放序列帧动画
	FGUI:setVisible(self._ui.list_ani, true)
	FGUI:setVisible(self._ui.list_res, false)
	FGUI:GList_setNumItems(self._ui.list_ani, self._count)

	if self._scheduleAni then
		SL:UnSchedule(self._scheduleAni)
		self._scheduleAni = nil
	end

	self._scheduleAni = SL:ScheduleOnce(handler(self, self.ShowResult), 1.5 + math.random(0, 5) / 10)
end

-- 显示结果
function PlayDice:ShowResult()
	FGUI:setVisible(self._ui.list_ani, false)
	FGUI:setVisible(self._ui.list_res, true)
	FGUI:GList_setNumItems(self._ui.list_res, self._count)
	if self._scheduleClose then
		SL:UnSchedule(self._scheduleClose)
		self._scheduleClose = nil
	end
	self._scheduleClose = SL:ScheduleOnce(handler(self, self.Close), resultDuration)
end
 
function PlayDice:OnResultListItemRenderer(idx, item)
	if not self._items then
		FGUI:setVisible(item, false)
		return
	end

	local num = self._items[idx + 1]
	local icon = FGUI:GetChild(item, "icon")
	FGUI:GLoader_setUrl(icon, string.format(dice_result_path, num))
end

function PlayDice:Exit()
	if self._scheduleAni then
		SL:UnSchedule(self._scheduleAni)
		self._scheduleAni = nil
	end
	if self._scheduleClose then
		SL:UnSchedule(self._scheduleClose)
		self._scheduleClose = nil
	end
end

function PlayDice:Close()
	self.super.Close(self)
end

return PlayDice