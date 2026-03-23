local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCSettingSelectSkillPanel = class("PCSettingSelectSkillPanel", BaseFGUILayout)

function PCSettingSelectSkillPanel:Create()
	self._ui				= FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)
	self:InitData()
	self:InitEvent()
end 

function PCSettingSelectSkillPanel:InitData()
end

function PCSettingSelectSkillPanel:InitEvent()
	FGUI:GList_itemRenderer(self._ui.list, handler(self, self.SkillListRender))
	FGUI:GList_addOnClickItemEvent(self._ui.list, handler(self, self.OnSelectSkill))
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.OnClickCloseBtn))
end

function PCSettingSelectSkillPanel:Enter(userdata)
	userdata = userdata or {}
	self._skillList = userdata.skill or {}
	self._callback = userdata.callback
	FGUI:GList_setNumItems(self._ui.list, #self._skillList)
end

function PCSettingSelectSkillPanel:Exit()
	self:RemoveEvent()
end

function PCSettingSelectSkillPanel:OnClose()
	self.super.Close(self)
end

function PCSettingSelectSkillPanel:Destroy()
end

function PCSettingSelectSkillPanel:RegisterEvent()
end

function PCSettingSelectSkillPanel:RemoveEvent()
end

function PCSettingSelectSkillPanel:SkillListRender(idx, item)
	local id = self._skillList[idx+1].SkillId
	local path = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", id)
	FGUI:GButton_setIcon(item, path, true)
	FGUI:GButton_setTitle(item,SL:GetValue("SKILL_NAME_BY_ID", id))
end

function PCSettingSelectSkillPanel:OnSelectSkill(context)
	local childIdx = FGUI:GetChildIndex(self._ui.list, context.data)
	local index = FGUI:GList_childIndexToItemIndex(self._ui.list, childIdx)
	local id = self._skillList[index + 1].SkillId
	if self._callback then
		self._callback(id)
	end
	self:Close()
end

function PCSettingSelectSkillPanel:OnClickCloseBtn()
	if self._callback then
		self._callback(-1)
	end
	self:Close()
end

return PCSettingSelectSkillPanel