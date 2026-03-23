local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCGuildPermissionSetting = class("PCGuildPermissionSetting", BaseFGUILayout)

local PermissionInfo = {
	[1] = {
		-- 同意申请
		Title = GET_STRING(10003058),
		Bit = 1
	},
	[2] = {
		-- 踢人
		Title = GET_STRING(10003059),
		Bit = 2
	},
	[3] = {
		-- 任命
		Title = GET_STRING(10003060),
		Bit = 4
	},
	[4] = {
		-- 邀请
		Title = GET_STRING(10003061),
		Bit = 8
	},
	[5] = {
		-- 修改门派名称
		Title = GET_STRING(10003062),
		Bit = 16
	},
	[6] = {
		-- 修改门派公告
		Title = GET_STRING(10003063),
		Bit = 32
	},
	[7] = {
		-- 入会申请设置
		Title = GET_STRING(10003064),
		Bit = 64
	},
}


local perCount = #PermissionInfo or 0

function PCGuildPermissionSetting:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	self._rankInfos = {}
	self._curSelectRankInfo = nil

	self.handler_rankListRenderer = handler(self, self.OnRankListItemRenderer)
	self.handler_permissionListRenderer = handler(self, self.OnPermissionListItemRenderer)
	self.handler_onClickRankItem = handler(self, self.OnClickRankItem)
	
	FGUIFunction:setWindowDrag(self.component, self._ui.bg)

	FGUI:GList_itemRenderer(self._ui.list_rank, self.handler_rankListRenderer)
	FGUI:GList_setOnClickItemEvent(self._ui.list_rank, self.handler_onClickRankItem)
	FGUI:GList_itemRenderer(self._ui.list_permission, self.handler_permissionListRenderer)
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_save, handler(self, self.OnClickSave))
	FGUI:setOnClickEvent(self._ui.btn_reset, handler(self, self.OnClickReset))
end

function PCGuildPermissionSetting:Enter()
	self:RegisterEvent()
	self._rankInfos = SL:GetValue("GUILD_SORT_RANK_INFO")
	FGUI:GList_setNumItems(self._ui.list_rank, #self._rankInfos)
	FGUI:GList_setSelectedIndex(self._ui.list_rank, 0)
	self:SelectRank(0)
end

function PCGuildPermissionSetting:Exit()
	self:RemoveEvent()
end

function PCGuildPermissionSetting:Close()
	self.super.Close(self)
end


-- 点击职位
function PCGuildPermissionSetting:OnClickRankItem()
	local selectIdx = FGUI:GList_getSelectedIndex(self._ui.list_rank)
	self:SelectRank(selectIdx)
end

-- 点击保存
function PCGuildPermissionSetting:OnClickSave(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
	local selection = FGUI:GList_getSelection(self._ui.list_permission)
	local permission = 0
	for _, itemIndex in ipairs(selection) do	
		permission = permission + PermissionInfo[itemIndex + 1].Bit
	end
	if self._curSelectRankInfo then
		SL:RequestGuildSetPermissionByID(self._curSelectRankInfo.ID, permission)
		local newTitle = FGUI:GTextField_getText(self._ui.text_rank)
		SL:RequestSetGuildTitle(self._curSelectRankInfo.ID, newTitle)
	end
end

-- 点击重置
function PCGuildPermissionSetting:OnClickReset(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
	if not self._curSelectRankInfo then return end
	SL:RequestGuildRankPermission(self._curSelectRankInfo.ID)
	self:RefreshPermission(true)
end

function PCGuildPermissionSetting:SelectRank(itemIdx)
	local info = self._rankInfos[itemIdx + 1]
	if not info then return end
	self._curSelectRankInfo = info
	FGUI:GTextField_setText(self._ui.text_rank, info.Title)
	FGUI:GList_setNumItems(self._ui.list_permission, perCount)
end

-- 刷新权限UI
function PCGuildPermissionSetting:RefreshPermission(notTip)
	self._rankInfos = SL:GetValue("GUILD_SORT_RANK_INFO")
	FGUI:GList_setNumItems(self._ui.list_permission, perCount)
	if not notTip then
		SL:ShowSystemTips(GET_STRING(10003065))
	end	
end

-- 职位列表
function PCGuildPermissionSetting:OnRankListItemRenderer(idx, item)
	local info = self._rankInfos[idx + 1]
	if not info then return end
	FGUI:GButton_setTitle(item, string.format(GET_STRING(10003066), idx + 1))
end

-- 权限列表
function PCGuildPermissionSetting:OnPermissionListItemRenderer(idx, item)
	local info = PermissionInfo[idx + 1]
	if not info then return end
	FGUI:GButton_setTitle(item, info.Title)
	if not self._curSelectRankInfo then return end
	local isSelect = self._curSelectRankInfo.Permission & info.Bit == info.Bit
	FGUI:GButton_setSelected(item, isSelect)
end

function PCGuildPermissionSetting:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_PERMISSION, "PCGuildPermissionSetting", handler(self, self.RefreshPermission))
end

function PCGuildPermissionSetting:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_PERMISSION, "PCGuildPermissionSetting")
end

return PCGuildPermissionSetting