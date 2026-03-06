local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorSkillFramePanel = class("VisitorSkillFramePanel", BaseFGUILayout)

local PAGE_DATA = {
	[1] = {name = "武功", componentName = "VisitorSkillStudyPanel", obj = nil},
	[2] = {name = "气功", componentName = "VisitorSkillPracticePanel", obj = nil},
}

function VisitorSkillFramePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)

	self:InitData()
	self:InitEvent()
	self:InitPage()
end

function VisitorSkillFramePanel:Exit()
	if self._selPage then 
		local lastData = PAGE_DATA[self._selPage]
		if not lastData then  
			return 
		end 

		if lastData.obj then 
			lastData.obj:Exit()
			FGUI:setVisible(lastData.obj.component, false)
		end
	end

	for i = 1, #PAGE_DATA do 
		PAGE_DATA[i].obj = nil
	end 

	self._selPage = nil
end

function VisitorSkillFramePanel:Close()
	self.super.Close(self)
end

function VisitorSkillFramePanel:InitData()
	self._selPage = nil
end

function VisitorSkillFramePanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
end

function VisitorSkillFramePanel:Enter(page)
	self:SelectPage(page)
end 

function VisitorSkillFramePanel:InitPage()
	FGUI:GList_itemRenderer(self._ui.list_page, function (idx, item)
		local index = idx + 1
		local data = PAGE_DATA[index]
		if not data then 
			return 
		end 

		local text_normal = FGUI:GetChild(item, "text_normal")
		local text_select = FGUI:GetChild(item, "text_select")
        FGUI:GTextField_setText(text_normal, data.name)
        FGUI:GTextField_setText(text_select, data.name)
    end)
    FGUI:GList_setNumItems(self._ui.list_page, #PAGE_DATA)
	FGUI:GList_addOnClickItemEvent(self._ui.list_page, function(item)
        local index = FGUI:GList_getSelectedIndex(self._ui.list_page) + 1
		self:SelectPage(index)
    end)
end

function VisitorSkillFramePanel:SelectPage(index)
	FGUI:GList_setSelectedIndex(self._ui.list_page, index - 1)
	if self._selPage then 
		local lastData = PAGE_DATA[self._selPage]
		if not lastData then  
			return 
		end 

		if lastData.obj then 
			lastData.obj:Exit()
			FGUI:setVisible(lastData.obj.component, false)
		end
	end
	self._selPage = index

	local pageData = PAGE_DATA[index]
	if not pageData then 
		return 
	end 

	if not pageData.obj then 
		pageData.obj = FGUI:CreateObject(self._ui.Node_Content, "Skill", pageData.componentName, true)
	end

    FGUI:setVisible(pageData.obj.component, true)
    pageData.obj:Enter()
end

return VisitorSkillFramePanel