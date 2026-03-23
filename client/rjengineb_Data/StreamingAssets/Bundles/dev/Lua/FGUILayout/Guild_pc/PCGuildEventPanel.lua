local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCGuildEventPanel = class("PCGuildEventPanel", BaseFGUILayout)

function PCGuildEventPanel:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)

	FGUIFunction:setWindowDrag(self.component, self._ui.bg)
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:GList_itemRenderer(self._ui.list_event, handler(self, self.OnEventItemRenderer))
end

function PCGuildEventPanel:Enter()
	self:RegisterEvent()
	SL:RequestQueryGuildEventList()
end

function PCGuildEventPanel:Exit()
	self:RemoveEvent()
end

function PCGuildEventPanel:Close()
	self.super.Close(self)
end

-- 刷新事件列表
function PCGuildEventPanel:RefreshEventList(listData)
	self._eventsData = listData
	if not self._eventsData then
		FGUI:GList_setNumItems(self._ui.list_event, 0)
		FGUI:setVisible(self._ui.text_empty_tip, true)
		return
	end
	self._eventsCount = #self._eventsData
	
	if self._eventsCount == 0 then
		FGUI:setVisible(self._ui.text_empty_tip, true)
	else
		FGUI:setVisible(self._ui.text_empty_tip, false)
	end
	
	FGUI:GList_setNumItems(self._ui.list_event, self._eventsCount)
end


function PCGuildEventPanel:OnEventItemRenderer(idx, item)
	if not self._eventsData then return end
	-- 倒叙显示，时间大的在前
	local data = self._eventsData[idx + 1]
	if not data then 
		return
	end
	local configStr = SL:GetValue("EVENT_LIST_CONFIG_STRING", data.id)
	local time = os.date("%Y-%m-%d %H:%M:%S", data.time)
	local errorStr = nil
	if not configStr then 
		SL:release_print("EVENT_LIST_CONFIG_STRING is nil, id:".. data.id)
		errorStr = "Error EventLog ID:" .. data.id
	end

	-- 计算%s数量
	local count = 0
	for _ in string.gmatch(configStr, "%%s") do
		count = count + 1
	end

	if count > #data.params then
		SL:release_print("EVENT_LIST_CONFIG_STRING params number error, id:".. data.id)
		errorStr = "Error:" .. configStr
	end

	
	FGUI:GTextField_setText(FGUI:GetChild(item, "text_time"), time)
	local str = errorStr or string.format(configStr, table.unpack(data.params,1,count))
	FGUI:GTextField_setText(FGUI:GetChild(item, "text_event"), str)
end



function PCGuildEventPanel:RegisterEvent()
	SL:RequestGameActionLogAddListener(1, LUA_EVENT_GUILD_EVENT_LIST, "GuildEventPanel", handler(self, self.RefreshEventList))
end

function PCGuildEventPanel:RemoveEvent()
	SL:RequestGameActionLogRemoveListener(1, LUA_EVENT_GUILD_EVENT_LIST, "GuildEventPanel")
end

return PCGuildEventPanel