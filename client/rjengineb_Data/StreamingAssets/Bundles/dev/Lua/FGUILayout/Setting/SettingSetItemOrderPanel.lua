local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local SettingSetItemOrderPanel = class("SettingSetItemOrderPanel", BaseFGUILayout)

function SettingSetItemOrderPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:SetCloseUIWhenClickOutside(self)
    self:InitData()
    self:InitEvent()
end

function SettingSetItemOrderPanel:InitData()
    self.handler_onDragStart = handler(self, self.OnDragStart)
    self.handler_onDragMove = handler(self, self.OnDragMove)
    self.handler_onDragEnd = handler(self, self.OnDragEnd)
end

function SettingSetItemOrderPanel:InitEvent()
    FGUI:GList_itemRenderer(self._ui.skill_list, handler(self, self.SkillListRender))
    FGUI:GList_addOnClickItemEvent(self._ui.skill_list, handler(self, self.OnSelectSkill))
    FGUI:addOnClickEvent(self._ui.btn_close, handler(self, self.Close))
end

function SettingSetItemOrderPanel:Enter(userdata)
    if not userdata or not next(userdata) then
        return
    end
    self._callBack = userdata.callback

    self._skillOrder =SL:CopyData(SL:GetValue(userdata.key))
    if not self._skillOrder or not next(self._skillOrder) then
        self._skillOrder = {}
    end

    FGUI:GList_setNumItems(self._ui.skill_list, #self._skillOrder)
    self._selectIdx = -1
end

function SettingSetItemOrderPanel:Exit()
    self:RemoveEvent()
end

function SettingSetItemOrderPanel:Close()
    self.super.Close(self)
	if self._callBack then
		self._callBack(self._skillOrder)
	end
end

function SettingSetItemOrderPanel:Destroy()
end

function SettingSetItemOrderPanel:RegisterEvent()
end

function SettingSetItemOrderPanel:RemoveEvent()
end

function SettingSetItemOrderPanel:SkillListRender(index, item)
    local uiItem = FGUI:ui_delegate(item)
    FGUI:setVisible(uiItem.selectable, false)
    FGUI:setVisible(uiItem.drag_handler, false)
    FGUI:GTextField_setText(uiItem.order, tostring(index + 1))
    FGUI:GTextField_setText(uiItem.title, SL:GetValue("ITEM_NAME", self._skillOrder[index + 1]))
    FGUI:setDragable(item, false)
end

function SettingSetItemOrderPanel:OnSelectSkill(context)
    local childIdx = FGUI:GetChildIndex(self._ui.skill_list, context.data)
    local idx = FGUI:GList_childIndexToItemIndex(self._ui.skill_list, childIdx) + 1
    local skillId = self._skillOrder[idx]
    self:SetSelect(idx)
end

function SettingSetItemOrderPanel:SetSelect(idx)
    if self._selectIdx == idx then
        return
    end
    local selectItem = nil
    for i = 1, #self._skillOrder, 1 do
        local childIdx = FGUI:GList_itemIndexToChildIndex(self._ui.skill_list, i - 1)
        local item = FGUI:GetChildAt(self._ui.skill_list, childIdx)
        local uiItem = FGUI:ui_delegate(item)
        local isSelect = i == idx
        FGUI:setVisible(uiItem.selectable, isSelect)
        FGUI:setVisible(uiItem.drag_handler, isSelect)
        if isSelect then
            selectItem = item
        end
    end
    self._selectIdx = idx
    if selectItem then
        FGUI:setOnDragEvent(selectItem, self.handler_onDragStart, self.handler_onDragMove, self.handler_onDragEnd)
    end
end

function SettingSetItemOrderPanel:OnDragStart(context)
    FGUI:EventContext_stopPropagation(context)
    self._startX, self._startY = FGUI:getTouchPosition(context)
    local lx, ly = FGUI:WorldToLocal(self._ui.skill_list, self._startX, self._startY)
    self._itemX, self._itemY = FGUI:getPosition(context.sender)
    self._offsetX = lx - self._itemX
    self._offsetY = ly - self._itemY
end

function SettingSetItemOrderPanel:OnDragMove(context)
    FGUI:EventContext_stopPropagation(context)

    local tX, tY = FGUI:getTouchPosition(context)
    local lX, lY = FGUI:WorldToLocal(self._ui.skill_list, self._startX, tY)
    lX = lX - self._offsetX
    lY = lY - self._offsetY
    FGUI:setPosition(context.sender, lX, lY)
end

function SettingSetItemOrderPanel:OnDragEnd(context)
    FGUI:EventContext_stopPropagation(context)
    local getPos = function(idx)
        local childIdx = FGUI:GList_itemIndexToChildIndex(self._ui.skill_list, idx - 1)
        local item = FGUI:GetChildAt(self._ui.skill_list, childIdx)
        local lX, lY = FGUI:getPosition(item)
        return lX, lY
    end
    local sX, sY = getPos(self._selectIdx)
    local cur_dis = math.maxinteger
    local near = -1
    for i = 1, #self._skillOrder, 1 do
        local x,y
        if self._selectIdx ~= i then
            x, y = getPos(i)
        else
            x = self._itemX
            y = self._itemX
        end
        local dis = math.abs(sY - y)
        if dis < cur_dis then
            near = i
            cur_dis = dis
        end
    end
    if near > 0 then
        local temp = self._skillOrder[self._selectIdx]
        self._skillOrder[self._selectIdx] = self._skillOrder[near]
        self._skillOrder[near] = temp
    end
    self._selectIdx = -1
    FGUI:GList_setNumItems(self._ui.skill_list, 0)
    FGUI:GList_setNumItems(self._ui.skill_list, #self._skillOrder)
end

return SettingSetItemOrderPanel
