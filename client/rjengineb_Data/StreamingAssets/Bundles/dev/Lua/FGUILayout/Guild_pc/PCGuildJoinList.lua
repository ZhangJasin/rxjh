local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCGuildJoinList = class("PCGuildJoinList", BaseFGUILayout)
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")

function PCGuildJoinList:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	--FGUI:SetCloseUIWhenClickOutside(self)
	FGUIFunction:setWindowDrag(self.component, self._ui.bg)
	self._curListData = nil
	self._curSelectData = nil
	self._isJoinedSect = false
	self._isListEmpty =false	--行会列表是否为空
	self._joinBtn_guildId_map = {}
	self.handler_onJoinItemRenderer = handler(self, self.OnJoinItemRenderer)
	self.handler_onClickJoinItemEvent = handler(self, self.OnClickJoinItemEvent)
	self.handler_onClickJoinButtonEvent = handler(self, self.OnClickJoinButtonEvent)

	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_join,self.handler_onClickJoinButtonEvent)
	FGUI:GList_itemRenderer(self._ui.list_join, self.handler_onJoinItemRenderer)
	FGUI:GList_addOnClickItemEvent(self._ui.list_join, self.handler_onClickJoinItemEvent)
	FGUI:GList_setVirtual(self._ui.list_join)
	-- 一键申请
	FGUI:setOnClickEvent(self._ui.btn_quick_join, handler(self, self.OnClickQuickJoinEvent))

	-- 刷新
	FGUI:setOnClickEvent(self._ui.btn_refresh, function ()
		SL:RequestGuildList(0)
		FGUI:GButton_setBright(self._ui.btn_quick_join, true)
	end)

	-- 搜索
	FGUI:setOnClickEvent(self._ui.btn_search, handler(self, self.OnClickSearchEvent))

	-- 创建门派
	FGUI:setOnClickEvent(self._ui.btn_create, handler(self, self.OnClickCreateGuild))

end

function PCGuildJoinList:Enter()
    self:RegisterEvent()
	self._isJoinedSect = SL:GetValue("GUILD_IS_JOINED")

	local isLimitGoodEvild = SL:GetValue("GAME_DATA", "GuildFilterGoodEvild")
	isLimitGoodEvild = isLimitGoodEvild and isLimitGoodEvild == 1 or false
	FGUI:setVisible(self._ui.condition_evild, isLimitGoodEvild)

	SL:RequestGuildList(0)
	local defaultTips = SL:GetValue("GAME_DATA", "SectPrecautions") or ""
	FGUI:GTextField_setText(self._ui.text_notice, defaultTips)
	-- 一键申请按钮恢复
	FGUI:GButton_setBright(self._ui.btn_quick_join, true)

	SL:ComponentAttach(SLDefine.SUIComponentTable.GuildJoinList, self._ui.Node_attach)
end

function PCGuildJoinList:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.GuildJoinList)

	self:RemoveEvent()
end

function PCGuildJoinList:Close()
	self.super.Close(self)
end
-- 点击创建门派
function PCGuildJoinList:OnClickCreateGuild()
	FGUI:Open("Guild_pc", "PCGuildCreatePopup")
end

-- 加入公会列表Item显示
function PCGuildJoinList:OnJoinItemRenderer(idx, item)
	if not self._curListData then return end
	local itemData = self._curListData[idx + 1]
	if not itemData then return end
	local text_name = FGUI:GetChild(item, "text_name")
	local text_level = FGUI:GetChild(item, "text_level")
	local text_member_count = FGUI:GetChild(item, "text_member_count")
	local text_owner_name = FGUI:GetChild(item, "text_owner_name")
	FGUI:GTextField_setText(text_name, FGUIFunction:GetServerName(itemData.GuildName))
	FGUI:GTextField_setText(text_level, string.format(GET_STRING(1024), itemData.Level))
	FGUI:GTextField_setText(text_member_count, string.format("%s/%s", itemData.Member, itemData.MemberMax))
	FGUI:GTextField_setText(text_owner_name, FGUIFunction:GetServerName(itemData.MasterName))
	FGUI:SetIntData(item, idx)
end

-- 点击加入公会列表Item事件
function PCGuildJoinList:OnClickJoinItemEvent(context)
	local idx = FGUI:GList_getSelectedIndex(self._ui.list_join) + 1
	self:SelectJoinItem(idx)
end

-- 点击加入公会列表Item上的 加入按钮 事件
function PCGuildJoinList:OnClickJoinButtonEvent()
	local curData = self._curSelectData
	if not curData then return end
	local playerLv = SL:GetValue("LEVEL") or 1
	if playerLv < curData.JoinLevel then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003051))
		return
	end

	local canJoinFullMember = (SL:GetValue("GAME_DATA", "guild_Join") or 0) == 1-- 门派满人是否可以加入，1可以 0不能
	if not canJoinFullMember and curData.Member >= curData.MemberMax then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10003055))
		return
	end
	
	local guildID = curData.GuildID
	SL:RequestGuildApply(guildID)
end

-- 一键申请
function PCGuildJoinList:OnClickQuickJoinEvent()
	SL:RequestGuildAutoJoin()
	FGUI:GButton_setBright(self._ui.btn_quick_join, false)
end

-- 搜素
function PCGuildJoinList:OnClickSearchEvent()
	local input = FGUI:GTextField_getText(self._ui.inputField_search)
	local listInfo = SL:GetValue("GUILD_LIST")
	if input == "" then
		self:OnRefreshGuildList(listInfo)
		return
	end

	local newListInfo = {}
	for k, v in ipairs(listInfo) do
		if string.find(v.GuildName, input) or string.find(tostring(v.GuildNum), input) then
			table.insert(newListInfo, v)
		end
	end
	self:OnRefreshGuildList(newListInfo)
end

function PCGuildJoinList:SelectJoinItem(index)
	if not self._curListData or not self._curListData[index] then 
		FGUI:setVisible(self._ui.text_evild, false)
		FGUI:setVisible(self._ui.text_need_level, false)
		return 
	end
	FGUI:GList_setSelectedIndex(self._ui.list_join, index - 1)
	self._curSelectData = self._curListData[index]
	FGUI:setVisible(self._ui.text_evild, true)
	FGUI:setVisible(self._ui.text_need_level, true)

	local evild = self:GetEvildStr(self._curSelectData.GuildGoodEvild)
	FGUI:GTextField_setText(self._ui.text_evild, evild)
	FGUI:GTextField_setText(self._ui.text_need_level, self._curSelectData.JoinLevel)
	local playerLv = SL:GetValue("LEVEL") or 1
	if playerLv < self._curSelectData.JoinLevel or self._isJoinedSect then
		FGUI:GTextField_setColor(self._ui.text_need_level, "#FF0000")
	else
		FGUI:GTextField_setColor(self._ui.text_need_level, "#FFF7D1")
	end
end

function PCGuildJoinList:GetEvildStr(evild)
	if evild == SLDefine.CAMP_TYPE.NONE then
		return GET_STRING(30000040)
	elseif evild == SLDefine.CAMP_TYPE.GOOD then
		return GET_STRING(10003049)
	elseif evild == SLDefine.CAMP_TYPE.EVIL then
		return GET_STRING(10003050)
	end
end

function PCGuildJoinList:OnRefreshGuildList(listData)
	if not listData then
		self._curListData = SL:GetValue("GUILD_LIST")
	else
		self._curListData = listData
	end

	self._isListEmpty = not self._curListData or #self._curListData == 0 
	
	if self._isListEmpty then 
		FGUI:GList_setNumItems(self._ui.list_join, 0)
		FGUI:setVisible(self._ui.text_no_guild, true)
		self:SelectJoinItem(1)
		return
	end
	local num = #self._curListData
	FGUI:setVisible(self._ui.text_no_guild, false)
	FGUI:GList_setNumItems(self._ui.list_join, num)
	-- 默认选中该第一个
	self:SelectJoinItem(1)
end

function PCGuildJoinList:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_LIST, "PCGuildJoinList", handler(self, self.OnRefreshGuildList))
end

function PCGuildJoinList:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_LIST, "PCGuildJoinList")
end

return PCGuildJoinList