local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local SkillFramePanel = class("SkillFramePanel", BaseFGUILayout)

local PAGE_DATA = {
	[1] = {name = "武功", componentName = "SkillStudyPanel", obj = nil},
	[2] = {name = "气功", componentName = "SkillPracticePanel", obj = nil},
}

function SkillFramePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)

	self:InitData()
	self:InitEvent()
	self:InitPage()
end

function SkillFramePanel:Exit()
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

function SkillFramePanel:Close()
	self.super.Close(self)
end

function SkillFramePanel:InitData()
	self._selPage = nil
end

function SkillFramePanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
end

function SkillFramePanel:Enter(page)
	------------交易行截图begin----------
    local index = global.TradingCaptureDatas and global.TradingCaptureDatas.index
    if index then
        page = index
    end
    ------------交易行截图end----------
	self:SelectPage(page)
end 

function SkillFramePanel:InitPage()
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

function SkillFramePanel:SelectPage(index)
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

return SkillFramePanel