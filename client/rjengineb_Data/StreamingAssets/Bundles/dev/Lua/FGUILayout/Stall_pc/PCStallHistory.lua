local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCStallHistory = class("PCStallHistory", BaseFGUILayout)


function PCStallHistory:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	self._historyData = {}
	self.handler_onHistoryListRenderer = handler(self, self.OnHistoryListRenderer)

	FGUIFunction:setWindowDrag(self.component, self._ui.bg)
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:GList_itemRenderer(self._ui.list_history, handler(self, self.OnHistoryListRenderer))
end

function PCStallHistory:Enter(userid)
	self:RegisterEvent()
	SL:RequestStallSellHistory(userid)
end


function PCStallHistory:Exit()
	self:RemoveEvent()
end

function PCStallHistory:Close()
	self.super.Close(self)
end

function PCStallHistory:RefreshSellHistory(listData)
	self._historyData = listData
	if not self._historyData or #self._historyData == 0 then
		FGUI:GList_setNumItems(self._ui.list_history, 0)
		FGUI:setVisible(self._ui.text_empty, true)
		return
	end
	FGUI:setVisible(self._ui.text_empty, false)
	FGUI:GList_setNumItems(self._ui.list_history, #self._historyData)
end

function PCStallHistory:OnHistoryListRenderer(idx, item)
	if not self._historyData then return end
	local data = self._historyData[idx + 1]
	if not data then 
		return
	end
	local configStr 
	if tonumber(data.id) <= 0 then
		configStr = SL:GetValue("GAME_DATA", "BaiTanLog")
	else
		configStr = SL:GetValue("EVENT_LIST_CONFIG_STRING", data.id)
	end
	
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
	FGUI:GTextField_setText(FGUI:GetChild(item, "text_content"), str)
end

function PCStallHistory:RegisterEvent()
	SL:RequestGameActionLogAddListener(2, LUA_EVENT_STALL_SELL_HISTORY, "PCStallHistory", handler(self, self.RefreshSellHistory))
end

function PCStallHistory:RemoveEvent()
	SL:RequestGameActionLogRemoveListener(2, LUA_EVENT_STALL_SELL_HISTORY, "PCStallHistory")
end

return PCStallHistory