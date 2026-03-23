local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local SettingCheckPickUpPanel = class("SettingCheckPickUpPanel", BaseFGUILayout)

function SettingCheckPickUpPanel:Create()
	self._ui				= FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)
	self._list_settings		= self._ui.list_settings
	self:InitData()
	self:InitEvent()
end 

function SettingCheckPickUpPanel:InitData()
	-- 关闭按钮
	self.handler_clickCloseBtn				= handler(self, self.OnClose)
	local roleConfig = requireGameConfig("Class")
	self._infoTb = {}
	table.insert(self._infoTb, {job = -1, class = 0})
	table.insert(self._infoTb, {job = -1, class = 1})
	table.insert(self._infoTb, {job = -1, class = 2})
	self._infoNum = 3
	for _, v in pairs(roleConfig) do
		for i = 0, 2, 1 do
			table.insert(self._infoTb, {job = v.ID, class = i})
			self._infoNum = self._infoNum + 1
		end
	end
end

function SettingCheckPickUpPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, self.handler_clickCloseBtn)
	self.handler_OnShowDropItemSwitchChange = handler(self, self.OnShowDropItemSwitchChange)
	self.handler_OnPickUpSwitchChange = handler(self, self.OnPickUpSwitchChange)
end

function SettingCheckPickUpPanel:Refresh(userdata)
	self:RegisterEvent()
	if not userdata then
		return
	end
	self.ID = userdata
	local num = FGUI:GList_getNumItems(self._list_settings)
	if self._infoNum ~= num then
		return
	end
	self:RefreshPanel()
end

function SettingCheckPickUpPanel:Exit()
	self:RemoveEvent()
end

function SettingCheckPickUpPanel:OnClose()
	self.super.Close(self)
end

function SettingCheckPickUpPanel:Destroy()
end

function SettingCheckPickUpPanel:RegisterEvent()
end

function SettingCheckPickUpPanel:RemoveEvent()
end

function SettingCheckPickUpPanel:RefreshPanel()
	for i = 1, self._infoNum, 1 do
		local child_idx = FGUI:GList_itemIndexToChildIndex(self._list_settings, i - 1)
		local info = self._infoTb[i]
		local item = FGUI:GetChildAt(self._list_settings, child_idx)

		local btn = FGUI:GetChild(item, "switch_show")
		local enable = SL:GetValue("SETTING_SHOW_DROPITEM_DETAIL", SLDefine.SET_FUNC.PICKUP_EQU, self.ID , info.job, info.class)
		FGUI:SetIntData(btn, i)
		FGUI:GButton_setSelected(btn, enable)
		FGUI:GButton_setOnChangedCallback(btn, self.handler_OnShowDropItemSwitchChange)

		local btn = FGUI:GetChild(item, "switch_pickup")
		local enable = SL:GetValue("SETTING_AUTO_PICKUP_DETAIL", SLDefine.SET_FUNC.PICKUP_EQU, self.ID, info.job, info.class)
		FGUI:SetIntData(btn, i)
		FGUI:GButton_setSelected(btn, enable)
		FGUI:GButton_setOnChangedCallback(btn, self.handler_OnPickUpSwitchChange)
	end
end

function SettingCheckPickUpPanel:OnShowDropItemSwitchChange(context)
	local idx = FGUI:GetIntData(context.sender)
	local info = self._infoTb[idx]
	local enable = FGUI:GButton_getSelected(context.sender)
	SL:SetValue("SETTING_SHOW_DROPITEM_DETAIL", SLDefine.SET_FUNC.PICKUP_EQU, self.ID, info.job, info.class, enable)
end

function SettingCheckPickUpPanel:OnPickUpSwitchChange(context)
	local idx = FGUI:GetIntData(context.sender)
	local info = self._infoTb[idx]
	local enable = FGUI:GButton_getSelected(context.sender)
	SL:SetValue("SETTING_AUTO_PICKUP_DETAIL", SLDefine.SET_FUNC.PICKUP_EQU, self.ID , info.job, info.class, enable)
end


return SettingCheckPickUpPanel