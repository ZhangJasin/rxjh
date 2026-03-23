local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MapRoutePanel = class("MapRoutePanel", BaseFGUILayout)

local titleShowFormat = "%s-%s线"

function MapRoutePanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    if SL:GetValue("IS_PC_OPER_MODE") then
	    FGUIFunction:setWindowDrag(self.component, self._ui.background)
    else
        FGUIFunction:SetCloseUIWhenClickOutside(self)
    end

    self:InitEvent()
end

function MapRoutePanel:Enter()
    self:InitData()
    self:InitUI()

    SL:ComponentAttach(SLDefine.SUIComponentTable.MapRoute, self._ui.Node_attach)
end

function MapRoutePanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.MapRoute)
end

function MapRoutePanel:OnClose()
    self.super.Close(self)
end

function MapRoutePanel:InitData()
    self._selectRouteIdx = SL:GetValue("MAP_ROUTE_IDX") or 1
    self._curMapName = SL:GetValue("MAP_NAME") or ""
    local mapID = SL:GetValue("MAP_ID")
    self._mapLines = SL:GetValue("MAP_INFO_ROUTES", mapID)
end

function MapRoutePanel:InitUI()
    if not self._mapLines then
        return
    end
    FGUI:GList_itemRenderer(self._ui.list_line, handler(self, self.OnLineItemRenderer))
    FGUI:GList_setVirtual(self._ui.list_line, false)
    FGUI:GList_addOnClickItemEvent(self._ui.list_line, handler(self, self.OnClickLineItem))
    FGUI:GList_setNumItems(self._ui.list_line, self._mapLines)
    FGUI:GList_setSelectedIndex(self._ui.list_line, self._selectRouteIdx - 1)
end

function MapRoutePanel:OnLineItemRenderer(idx, item)
    idx = idx + 1
    local title = FGUI:GetChild(item, "title")
    FGUI:GTextField_setText(title, string.format(titleShowFormat, self._curMapName, idx))
end

function MapRoutePanel:OnClickLineItem(context)
    local idx = FGUI:GetChildIndex(self._ui.list_line, context.data)
    self._selectRouteIdx = idx + 1
end

function MapRoutePanel:InitEvent()
    FGUI:setOnClickEvent(self._ui.btn_switch, handler(self, self.OnSwitchRoute))
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.OnClose))
end

function MapRoutePanel:OnSwitchRoute(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
    if not self._selectRouteIdx or self._selectRouteIdx < 1 then
        return
    end

    SL:RequestMapRouteSwitch(self._selectRouteIdx)
end


return MapRoutePanel