local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MentorShipPanel = class("MentorShipPanel", BaseFGUILayout)
local MentorShipMain = requireFGUILayout("MentorShip/MentorShipMain")
local MentorShipTeach = requireFGUILayout("MentorShip/MentorShipTeach")
local MentorShipShop = requireFGUILayout("MentorShip/MentorShipShop")

local MentorPage = { Main = 1, teach = 2, shop = 3 }

function MentorShipPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
	self:InitData()
	self:InitEvent()
	MentorShipPanelUI.CCUI = self
end

function MentorShipPanel:InitData()
	self._pageHandler = {
		[MentorPage.Main] = {
			url = "ui://pnop7ha6dos9o4l",
			processor = MentorShipMain.Create(),
		},
		[MentorPage.teach] = {
			url = "ui://pnop7ha6dos9o4m",
			processor = MentorShipTeach.Create(),
		},
		[MentorPage.shop] = {
			url = "ui://pnop7ha6q7pvo68",
			processor = MentorShipShop.Create(),
		},
	}
	self.handler_clickCloseBtn = handler(self, self.OnClose)
	self.handler_clickHelpBtn = handler(self, self.OnHelp)
	self.handler_clickSwitch = handler(self, self.OnClickSwitchPageBtn)
end

function MentorShipPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, self.handler_clickCloseBtn)
	FGUI:setOnClickEvent(self._ui.btn_help, self.handler_clickHelpBtn)
	FGUI:GTextField_setText(self._ui.text_title, "师徒")
	FGUI:GList_addOnClickItemEvent(self._ui.page_switch_list, self.handler_clickSwitch)
	FGUI:setOnClickEvent(self._ui.helpBg, function() 
		FGUI:setVisible(self._ui.helpInfo,false)
	end)
end

function MentorShipPanel:OnHelp()
	FGUI:setVisible(self._ui.helpInfo,true)
end

function MentorShipPanel:Enter(userdata)
	self:RegisterEvent()
	self._currentPage = nil
	local page = (userdata and userdata.defaultPage) or MentorPage.Main
	FGUI:GList_setSelectedIndex(self._ui.page_switch_list, page - 1)
	self:SetPage(page)
	if userdata.openBrearList then	
		ssrMessage:sendmsgEx("MentorShip", "getAllMyBraskApply")
	end
end
function MentorShipPanel:initBreakEvent(data)
	self = MentorShipPanelUI.CCUI
	FGUI:setVisible(self._ui.BreakRlationship,true)
	local closeBtn = FGUI:GetChild(self._ui.BreakRlationship,"btn_close")
	local breakApplyList = FGUI:GetChild(self._ui.BreakRlationship,"applyList")
	FGUI:setOnClickEvent(closeBtn, function(index,item)
		FGUI:setVisible(self._ui.BreakRlationship,false)
	end)
	FGUI:GList_itemRenderer(breakApplyList, function(idx,item)
		local itemData = data[idx+1]
		if itemData then
			local name = FGUI:GetChild(item,"name")
			FGUI:GTextField_setText(name,itemData.UserName)
			local notAgree = FGUI:GetChild(item,"notAgree")
			local agree = FGUI:GetChild(item,"agree")
			local whoController = FGUI:getController(item,"who")
			local targetUserId = itemData.UserID
			-- who  1 我的徒弟申请  2 我的师傅申请
			-- whoController 0 我的徒弟 1 我的师傅
			local status = 0
			if tonumber(itemData.who) == 1 then
				status = 1
			end
			FGUI:Controller_setSelectedIndex(whoController, status )
			FGUI:setOnClickEvent(agree, function(index,item)
				FGUI:setVisible(self._ui.BreakRlationship,false)
				ssrMessage:sendmsgEx("MentorShip", "agreeBreak",{targetId = targetUserId,mode = itemData.who})
			end)
			FGUI:setOnClickEvent(notAgree, function(index,item)
				FGUI:setVisible(self._ui.BreakRlationship,false)
				ssrMessage:sendmsgEx("MentorShip", "notAgreeBreak",targetUserId)
			end)
		end
	end)
	FGUI:GList_setNumItems(breakApplyList, #data)
end

function MentorShipPanel:Exit()
	self:RemoveEvent()
end

function MentorShipPanel:OnClose()
	self.super.Close(self)
end
function MentorShipPanel:Destroy() end
function MentorShipPanel:RegisterEvent() end
function MentorShipPanel:RemoveEvent() end

function MentorShipPanel:OnClickSwitchPageBtn()
	local index = FGUI:GList_getSelectedIndex(self._ui.page_switch_list)
	self:SetPage(index + 1)
end

function MentorShipPanel:SetPage(page)
	if page == self._currentPage then
		return
	end
	local handler = self._pageHandler[page]
	if not handler or not handler.url or not handler.processor then
		FGUI:GLoader_setUrl(self._ui.mentor_content, "")
		self:OnPageChange(nil)
		return
	end
	FGUI:GLoader_setUrl(self._ui.mentor_content, handler.url)
	local component = FGUI:GLoader_getComponent(self._ui.mentor_content)
	handler.processor:ResetComponent(component)
	self:OnPageChange(page)
end

function MentorShipPanel:OnPageChange(page)
	if self._currentPage then
		local last = self._pageHandler[self._currentPage]
		if last and last.processor then
			last.processor:Exit()
		end
	end
	self._currentPage = page
	if page then
		local cur = self._pageHandler[self._currentPage]
		if cur and cur.processor then
			cur.processor:Enter()
		end
	end
end
return MentorShipPanel
