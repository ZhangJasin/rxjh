local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PreLoadPanel = class("PreLoadPanel", BaseFGUILayout)

function PreLoadPanel:Create()
	self._ui				= FGUI:ui_delegate(self.component)
	self:InitData()
	self:InitEvent()
end 

function PreLoadPanel:Refresh()
	self:RegisterEvent()
	local keys = {}
	self._loadingFile = {}
	local keys = SL:GetValue("PRELOAD_KEYS")
	for i, v in ipairs(keys) do
		local state = SL:GetValue("PRELOAD_STATE", v)
		if state == 1 then
			table.insert(self._loadingFile, v)
		end
	end
	self.tickSchedule = SL:Schedule(handler(self, self.Tick), 0.01)
end

function PreLoadPanel:Exit()
	self:RemoveEvent()
	self._loadingFile = nil
	if self.tickSchedule then
		SL:UnSchedule(self.tickSchedule)
	end
	self.tickSchedule = nil
end

function PreLoadPanel:Destroy()
end

function PreLoadPanel:OnClose()
	self.super.Close(self)
end

function PreLoadPanel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_PRELOAD_START, "PreLoadPanel", handler(self, self.OnPreLoadStart))
	SL:RegisterLUAEvent(LUA_EVENT_PRELOAD_END, "PreLoadPanel", handler(self, self.OnPreLoadEnd))
end

function PreLoadPanel:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_PRELOAD_START, "PreLoadPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_PRELOAD_END, "PreLoadPanel")
end

function PreLoadPanel:InitData()
end

function PreLoadPanel:InitEvent()
end

-- 预加载开始
function PreLoadPanel:OnPreLoadStart(key)
	table.insert(self._loadingFile, key)
	self:UpdateProgress()
end

function PreLoadPanel:Tick()
	self:UpdateProgress()
end

function PreLoadPanel:UpdateProgress()
	if not self._loadingFile or not next(self._loadingFile) then
		FGUI:GSlider_setValue(self._ui.bar_loading, 0)
		return
	end
	
	local totalP = 0
	for i, key in ipairs(self._loadingFile) do
		local progress = SL:GetValue("PRELOAD_PROGRESS", key)
		totalP = totalP + progress
	end
	local P = totalP / #self._loadingFile * 100
	FGUI:GSlider_setValue(self._ui.bar_loading, P)
end

-- 预加载结束
function PreLoadPanel:OnPreLoadEnd(key)
	self:UpdateProgress()
end


return PreLoadPanel