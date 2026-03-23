local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local SettingPanel = class("SettingPanel", BaseFGUILayout)
local SettingSystemPanel = requireFGUILayout("Setting/SettingSystemPanel")
local SettingFightPanel = requireFGUILayout("Setting/SettingFightPanel")
local SettingDisplayPanel = requireFGUILayout("Setting/SettingDisplayPanel")
local SettingAutoFightPanel = requireFGUILayout("Setting/SettingAutoFightPanel")

function SettingPanel:Create()
	self._ui				= FGUI:ui_delegate(self.component)
	
	self._packageName = "Setting"
	FGUIFunction:SetCloseUIWhenClickOutside(self)
	self:InitData()
	self:InitEvent()
end 

function SettingPanel:InitData()
	self._pageHandler = 
	{
		[FGUIDefine.SettingPage.System]= 
		{
			url = "ui://"..self._packageName.."/panel_system_setting",
			processor = SettingSystemPanel.Create(),
		},
		[FGUIDefine.SettingPage.Fight]=
		{
			url = "ui://"..self._packageName.."/panel_fight_setting",
			processor = SettingFightPanel.Create(),
		},
		[FGUIDefine.SettingPage.Display]=
		{
			url = "ui://"..self._packageName.."/panel_display_setting",
			processor = SettingDisplayPanel.Create(),
		},
		[FGUIDefine.SettingPage.AutoFight]=
		{
			url = "ui://"..self._packageName.."/panel_auto_fight_setting",
			processor = SettingAutoFightPanel.Create(),
		},
	}
	-- 关闭按钮
	self.handler_clickCloseBtn				= handler(self, self.OnClose)
	-- 切换页面
	self.handler_clickSwitchPageBtn			= handler(self, self.OnClickSwitchPageBtn)
end

function SettingPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, self.handler_clickCloseBtn)
	FGUI:GList_addOnClickItemEvent(self._ui.page_switch_list, self.handler_clickSwitchPageBtn)
end

-- 
function SettingPanel:Enter(userdata)
	self:RegisterEvent()
	
	self._currentPage = nil
	local page = FGUIDefine.SettingPage.System
	if userdata and type(userdata) == "number" then
		page = userdata
	end
	FGUI:GList_setSelectedIndex(self._ui.page_switch_list, page - 1)
	self:SetPage(page)

	SL:ComponentAttach(SLDefine.SUIComponentTable.SettingMain, self._ui.Node_attach)
end

function SettingPanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.SettingMain)

	self:RemoveEvent()
end

function SettingPanel:OnClose()
	self.super.Close(self)
end

function SettingPanel:Destroy()
end

function SettingPanel:RegisterEvent()
end

function SettingPanel:RemoveEvent()
end

function SettingPanel:OnClickSwitchPageBtn(context)
	local index = FGUI:GList_getSelectedIndex(self._ui.page_switch_list)
	local page = index + 1
	self:SetPage(page)
end

function SettingPanel:SetPage(page)
	if page == self._currentPage then
		return
	end
	local handler = self._pageHandler[page]
	if not handler or not handler.url or not handler.processor then
		self:OnPageChange("",nil)
		return
	end
	self:OnPageChange(handler.url, page)
end

function SettingPanel:OnPageChange(url, page)
	if self._currentPage then
		local lastHandler = self._pageHandler[self._currentPage]
		if lastHandler and lastHandler.processor then
			lastHandler.processor:Exit()
		end
	end
	FGUI:GLoader_setUrl(self._ui.setting_content, url)
	self._currentPage = page
	if page then
		local currentHandler = self._pageHandler[self._currentPage]
		if currentHandler and currentHandler.processor then
			local component = FGUI:GLoader_getComponent(self._ui.setting_content)
			currentHandler.processor:ResetComponent(component)
			currentHandler.processor:Enter()
		end
	end
end

return SettingPanel