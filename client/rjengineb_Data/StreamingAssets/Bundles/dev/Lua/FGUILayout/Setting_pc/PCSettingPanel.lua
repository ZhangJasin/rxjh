local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCSettingPanel = class("PCSettingPanel", BaseFGUILayout)
local PCSettingSystemPanel = requireFGUILayout("Setting_pc/PCSettingSystemPanel")
local PCSettingFightPanel = requireFGUILayout("Setting_pc/PCSettingFightPanel")
local PCSettingDisplayPanel = requireFGUILayout("Setting_pc/PCSettingDisplayPanel")
local PCSettingAutoFightPanel = requireFGUILayout("Setting_pc/PCSettingAutoFightPanel")
local PCSettingKeyBoardPanel = requireFGUILayout("Setting_pc/PCSettingKeyBoardPanel")

function PCSettingPanel:Create()
	self._ui				= FGUI:ui_delegate(self.component)
	self._packageName = "Setting_pc"
	FGUIFunction:setWindowDrag(self.component, self._ui.background)

	self:InitData()
	self:InitEvent()
end 

function PCSettingPanel:InitData()
	self._pageHandler = 
	{
		[FGUIDefine.SettingPage.System]= 
		{
			url = "ui://"..self._packageName.."/panel_system_setting",
			processor = PCSettingSystemPanel.Create(),
		},
		[FGUIDefine.SettingPage.Fight]=
		{
			url = "ui://"..self._packageName.."/panel_fight_setting",
			processor = PCSettingFightPanel.Create(),
		},
		[FGUIDefine.SettingPage.Display]=
		{
			url = "ui://"..self._packageName.."/panel_display_setting",
			processor = PCSettingDisplayPanel.Create(),
		},
		[FGUIDefine.SettingPage.AutoFight]=
		{
			url = "ui://"..self._packageName.."/panel_auto_fight_setting",
			processor = PCSettingAutoFightPanel.Create(),
		},
		[FGUIDefine.SettingPage.KeyBoard]=
		{
			url = "ui://"..self._packageName.."/panel_key_board_setting",
			processor = PCSettingKeyBoardPanel.Create(),
		}
	}
	-- 关闭按钮
	self.handler_clickCloseBtn				= handler(self, self.OnClose)
	-- 切换页面
	self.handler_clickSwitchPageBtn			= handler(self, self.OnClickSwitchPageBtn)
end

function PCSettingPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, self.handler_clickCloseBtn)
	FGUI:GList_addOnClickItemEvent(self._ui.page_switch_list, self.handler_clickSwitchPageBtn)
end

-- 
function PCSettingPanel:Enter(userdata)
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

function PCSettingPanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.SettingMain)

	self:RemoveEvent()
end

function PCSettingPanel:OnClose()
	self.super.Close(self)
end

function PCSettingPanel:Destroy()
end

function PCSettingPanel:RegisterEvent()
end

function PCSettingPanel:RemoveEvent()
end

function PCSettingPanel:OnClickSwitchPageBtn(context)
	local index = FGUI:GList_getSelectedIndex(self._ui.page_switch_list)
	local page = index + 1
	self:SetPage(page)
end

function PCSettingPanel:SetPage(page)
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

function PCSettingPanel:OnPageChange(url, page)
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

return PCSettingPanel