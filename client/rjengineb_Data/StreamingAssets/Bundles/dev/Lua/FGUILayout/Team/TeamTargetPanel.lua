local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TeamTargetPanel = class("TeamTargetPanel", BaseFGUILayout)

function TeamTargetPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)

	self:InitData()
    self:InitEvent()
end 

function TeamTargetPanel:Close()
	self.super.Close(self)
end

function TeamTargetPanel:InitData()
    self._targetData = {
        name = GET_STRING(40010047),
        minLv = 0,
        maxLv = 0,
        count = SL:GetValue("TEAM_MAX_COUNT")
    }
end

function TeamTargetPanel:InitEvent()
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.mask, handler(self, self.Close))
	FGUI:GList_itemRenderer(self._ui.list_target, handler(self, self.ItemRendererTarget))
end

function TeamTargetPanel:Enter()
    self:OnUpdateTargetList()
end

function TeamTargetPanel:Exit()

end

local settingData = {name = GET_STRING(), minLv = 0, maxLv = 0, count = 0}
function TeamTargetPanel:OnUpdateTargetList()
    table.clear(self._targetData)
    local settingData = SL:GetValue("TEAM_SETTING_DATA")
    local myLevel = SL:GetValue("LEVEL")
    local data = {
        name = GET_STRING(40010047),
        minLv = settingData.JoinLvMin or (myLevel-10) > 0 and (myLevel-10) or 1,
        maxLv = settingData.JoinLvMax or myLevel + 10,
        count = SL:GetValue("TEAM_MAX_COUNT")
    }
    table.insert(self._targetData, data)
    FGUI:GList_setNumItems(self._ui.list_target, #self._targetData)
end

function TeamTargetPanel:ItemRendererTarget(idx, item)
    local index = idx + 1
    local data = self._targetData[index]
    if not data then 
        return 
    end
 
    local ui_name = FGUI:GetChild(item, "text_name")
    FGUI:GTextField_setText(ui_name, data.name)

    local ui_level = FGUI:GetChild(item, "text_level")
    FGUI:GTextField_setText(ui_level, string.format(GET_STRING(40010048), data.minLv, data.maxLv))

    local ui_count = FGUI:GetChild(item, "text_count")
    FGUI:GTextField_setText(ui_count, data.count)

    local btn_select = FGUI:GetChild(item, "btn_select")
    FGUI:setOnClickEvent(btn_select, handler(self, self.OnClickBtnSelect))
	FGUI:SetIntData(item, idx)
end

function TeamTargetPanel:OnClickBtnSelect(context)
    self:Close()
    SLBridge:onLUAEvent(LUA_EVENT_TEAM_TARGET_INFO)
end

return TeamTargetPanel