local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local GuildApplyList = class("GuildApplyList", BaseFGUILayout)

function GuildApplyList:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)
	self._applyData = {}
	self._isAllSelected = false

	-- 关闭
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	-- 全选
    FGUI:setOnClickEvent(self._ui.btn_select_all, handler(self, self.OnClickSelectAll))
	-- 通过
	FGUI:setOnClickEvent(self._ui.btn_approve, handler(self, self.OnClickApproveEvent))
	-- 拒绝
	FGUI:setOnClickEvent(self._ui.btn_refuse, handler(self, self.OnClickRefuseEvent))

	-- 设置
	FGUI:setOnClickEvent(self._ui.btn_setting, handler(self, self.OpenSettingPanel))

	FGUI:GList_itemRenderer(self._ui.list_apply, handler(self, self.OnApplyItemRenderer))
	FGUI:GList_addOnClickItemEvent(self._ui.list_apply, handler(self, self.OnClickApplyItem))
end

function GuildApplyList:Enter()
    self:RegisterEvent()
	local showSetting = SL:GetValue("GUILD_CHECK_PERMISSION_APPLY_SETTING")
	FGUI:setVisible(self._ui.btn_setting, showSetting)
	SL:RequestGuildApplydList()
	SL:ComponentAttach(SLDefine.SUIComponentTable.GuildApplyList, self._ui.Node_attach)
end

function GuildApplyList:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.GuildApplyList)
	SL:DelBubbleTips(10)
	self:RemoveEvent()
end

function GuildApplyList:Close()
	self.super.Close(self)
	self._applyData = {}
	SL:RequestGuildMemberList()
end

-- 全选
function GuildApplyList:OnClickSelectAll()
	self._isAllSelected = not self._isAllSelected
	self:SetAllSelect(self._isAllSelected)
end

function GuildApplyList:SetAllSelect(isSelect)
	self._isAllSelected = isSelect
	local itemNums = FGUI:GList_getNumItems(self._ui.list_apply)
	if itemNums < 1 then return end
		
	for i = 0, itemNums - 1 do
		if isSelect then
			FGUI:GList_addSelection(self._ui.list_apply, i)
		else
			FGUI:GList_removeSelection(self._ui.list_apply, i)
		end
	end
end

-- 刷新申请列表
function GuildApplyList:RefreshApplyList(applyList)
	self._applyData = applyList.List
	if not self._applyData or #self._applyData == 0 then
		FGUI:setVisible(self._ui.text_empty_tip, true)
		FGUI:GList_setNumItems(self._ui.list_apply, 0)
	else
		FGUI:setVisible(self._ui.text_empty_tip, false)
		FGUI:GList_setNumItems(self._ui.list_apply, #self._applyData)
	end	
end

-- 点击申请列表项
function GuildApplyList:OnClickApplyItem(context)


end

-- 通过申请
function GuildApplyList:OnClickApproveEvent(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
	if not self._applyData then return end

	local selectItemsIdx = FGUI:GList_getSelection(self._ui.list_apply)
	local uidList = {}

	for _,v in ipairs(selectItemsIdx) do
		local data = self._applyData[v + 1]
		if data then
			table.insert(uidList, data.UserID)
		end		
	end

	if #uidList > 1 then
		SL:RequestGuildApproveUserApplys(uidList)
	else
		SL:RequestGuildApproveUserApply(uidList[1])
	end
	

	local retainItems = {}
	for i, v in ipairs(self._applyData) do
		if not table.contains(selectItemsIdx,  (i - 1)) then
			table.insert(retainItems, v)
		end
	end

	if #retainItems == 0 then
		--SL:DelBubbleTips(10)
	end

	local applyList = {}
	applyList.List = retainItems
	self:RefreshApplyList(applyList)
	self:SetAllSelect(false)

end

-- 拒绝
function GuildApplyList:OnClickRefuseEvent(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
	if not self._applyData then return end
	local selectItemsIdx = FGUI:GList_getSelection(self._ui.list_apply)
	local uidList = {}

	for _,v in ipairs(selectItemsIdx) do
		local data = self._applyData[v + 1]
		if data then
			table.insert(uidList, data.UserID)
		end		
	end

	local num = #uidList

	if num < 1 then return end

	if #uidList > 1 then
		SL:RequestGuildRejectUserApplys(uidList)
	else
		SL:RequestGuildRejectUserApply(uidList[1])
	end
	

	local retainItems = {}
	for i, v in ipairs(self._applyData) do
		if not table.contains(selectItemsIdx,  (i - 1)) then
			table.insert(retainItems, v)
		end
	end

	if #retainItems == 0 then
		--SL:DelBubbleTips(10)
	end

	local applyList = {}
	applyList.List = retainItems
	self:RefreshApplyList(applyList)
	self:SetAllSelect(false)
end

-- 打开设置界面
function GuildApplyList:OpenSettingPanel()
	FGUI:Open("Guild", "GuildApplySetting")
end



function GuildApplyList:OnApplyItemRenderer(idx, item)
	local data = self._applyData[idx + 1]
	FGUI:GTextField_setText(FGUI:GetChild(item, "text_name"), FGUIFunction:GetServerName(data.UserName))
	local levelStr = string.format("%s" .. SL:GetValue("I18N_STRING", 3), data.Level or 0)
	FGUI:GTextField_setText(FGUI:GetChild(item, "text_level"), levelStr)
	local jobStr = SL:GetValue("JOB_NAME_BY_ID", data.Job)
	FGUI:GTextField_setText(FGUI:GetChild(item, "text_job"), jobStr)
	FGUI:GTextField_setText(FGUI:GetChild(item, "text_fight"), data.Fight or 0)
	--FGUI:GButton_setSelected(item, self._isAllSelected)
end

function GuildApplyList:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_GUILD_APPLYLIST, "GuildApplyList", handler(self, self.RefreshApplyList))
end

function GuildApplyList:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_APPLYLIST, "GuildApplyList")
end

return GuildApplyList