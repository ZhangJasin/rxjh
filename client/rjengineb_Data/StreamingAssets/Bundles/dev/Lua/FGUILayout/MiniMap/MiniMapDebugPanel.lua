local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MiniMapDebugPanel = class("MiniMapDebugPanel", BaseFGUILayout)

function MiniMapDebugPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:InitEvent()
end

function MiniMapDebugPanel:Enter()
    self:RegisterEvent()
    FGUI:setDragable(self._ui.drag, true)
	self:InitData()
    FGUI:GTextInput_setText(self._ui.scal_input, tostring(self.mapCameraSize))
    FGUI:GTextInput_setText(self._ui.x_input, tostring(self._offsetX))
    FGUI:GTextInput_setText(self._ui.y_input, tostring(self._offsetY))
end

function MiniMapDebugPanel:Exit()
    self:RemoveEvent()
    FGUI:setDragable(self._ui.drag, false)
end

function MiniMapDebugPanel:Destroy()
end

function MiniMapDebugPanel:OnClose()
    self.super.Close(self)
end

function MiniMapDebugPanel:RegisterEvent()
end

function MiniMapDebugPanel:RemoveEvent()
end

function MiniMapDebugPanel:InitData()
    self._mapSizeW = MiniMapPanelObj._mapSizeW
    self._mapSizeH = MiniMapPanelObj._mapSizeH
    self._mapId = MiniMapPanelObj._mapId
    local offset = SL:GetValue("MINIMAP_OFFSET", self._mapId)
    self._offsetX = offset[1]
    self._offsetY = offset[2]
    self.mapCameraSize = SL:GetValue("MINIMAP_CAMERA_SIZE", self._mapId)
end

function MiniMapDebugPanel:InitEvent()
    FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.OnClose))

    FGUI:setOnClickEvent(self._ui.scal_left, handler(self, self.OnClickScalLeft))
    FGUI:setOnClickEvent(self._ui.scal_right, handler(self, self.OnClickScalRight))
    FGUI:GTextInput_addOnChanged(self._ui.scal_input, handler(self, self.OnScalInputChange))

    FGUI:setOnClickEvent(self._ui.x_left, handler(self, self.OnClickXLeft))
    FGUI:setOnClickEvent(self._ui.x_right, handler(self, self.OnClickXRight))
    FGUI:GTextInput_addOnChanged(self._ui.x_input, handler(self, self.OnXInputChange))

    FGUI:setOnClickEvent(self._ui.y_left, handler(self, self.OnClickYLeft))
    FGUI:setOnClickEvent(self._ui.y_right, handler(self, self.OnClickYRight))
    FGUI:GTextInput_addOnChanged(self._ui.y_input, handler(self, self.OnYInputChange))
end

function MiniMapDebugPanel:OnClickXLeft()
    self:OnOffsetChangeX(self._offsetX - 1, true)
end
function MiniMapDebugPanel:OnClickXRight()
    self:OnOffsetChangeX(self._offsetX + 1, true)
end
function MiniMapDebugPanel:OnXInputChange()
    local value = tonumber(FGUI:GTextInput_getText(self._ui.x_input))
	value = value or 0
    self:OnOffsetChangeX(value, false)
end
function MiniMapDebugPanel:OnOffsetChangeX(x, setText)
    self._offsetX = x
	setText = setText or true
	if setText then
		FGUI:GTextInput_setText(self._ui.x_input, tostring(x))
	end
    MiniMapPanelObj._offsetX = self._offsetX
    self:RefreshActorPoint()
end

function MiniMapDebugPanel:OnClickYLeft()
    self:OnOffsetChangeY(self._offsetY - 1, true)
end
function MiniMapDebugPanel:OnClickYRight()
    self:OnOffsetChangeY(self._offsetY + 1, true)
end
function MiniMapDebugPanel:OnYInputChange()
    local value = tonumber(FGUI:GTextInput_getText(self._ui.y_input))
	value = value or 0
    self:OnOffsetChangeY(value, false)
end
function MiniMapDebugPanel:OnOffsetChangeY(y, setText)
    self._offsetY = y
	FGUI:GTextInput_setText(self._ui.y_input, tostring(y))
	if setText then
		MiniMapPanelObj._offsetY = self._offsetY
	end
    self:RefreshActorPoint()
end

function MiniMapDebugPanel:OnClickScalLeft()
    self:OnCameraSizeChange(self.mapCameraSize - 1, true)
end
function MiniMapDebugPanel:OnClickScalRight()
    self:OnCameraSizeChange(self.mapCameraSize + 1, true)
end
function MiniMapDebugPanel:OnScalInputChange()
    local value = tonumber(FGUI:GTextInput_getText(self._ui.scal_input))
	value = value or 0
    self:OnCameraSizeChange(value, false)
end
function MiniMapDebugPanel:OnCameraSizeChange(size, setText)
    self.mapCameraSize = size
	if setText then
		FGUI:GTextInput_setText(self._ui.scal_input, tostring(size))
	end
    self:RefreshActorPoint()
end

function MiniMapDebugPanel:RefreshActorPoint()
	MiniMapPanelObj._offsetX = self._offsetX
	MiniMapPanelObj._offsetY = self._offsetY
	self._mapParamX = self._mapSizeW / self._mapSizeH * self.mapCameraSize
    self._mapParamY = self.mapCameraSize
    MiniMapPanelObj._mapParamX = self._mapParamX
    MiniMapPanelObj._mapParamY = self._mapParamY
    MiniMapPanelObj:RecycleElement()
    -- 小地图怪物数据请求
    SL:RequestMiniMapMonsters(MiniMapPanelObj._mapId)
    
    MiniMapPanelObj._pointPlayer = MiniMapPanelObj:CreatePlayerPoint()
    MiniMapPanelObj:RefreshPoints()
    MiniMapPanelObj:UpdateFindPath()
end

return MiniMapDebugPanel
