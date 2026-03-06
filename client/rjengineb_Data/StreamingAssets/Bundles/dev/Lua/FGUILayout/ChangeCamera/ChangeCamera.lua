local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local ChangeCamera = class("ChangeCamera", BaseFGUILayout)

function ChangeCamera:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:GetAllFGuiData()
    self:InitUI()
    self:InitOnClickEvent()
end

function ChangeCamera:InitUI()
    FGUI:GList_itemRenderer(self.list_CameraMode,handler(self,self.CellRender))
    FGUI:GList_addOnClickItemEvent(self.list_CameraMode,handler(self,self.CellClicked))
end

function ChangeCamera:GetAllFGuiData()
    self.mask = self._ui.mask
    self.btn_sure = self._ui.btn_sure
    self.list_CameraMode = self._ui.list_CameraMode
end

function ChangeCamera:InitOnClickEvent()
    -- FGUI:setOnClickEvent(self.mask,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_sure,handler(self,self.BtnSureClicked))
end

function ChangeCamera:BtnSureClicked()
    SL:SetValue("CAMERA_MODE_SET",self._cameraMode)
    print("self._cameraMode=",self._cameraMode)
    self:OnClose()
end

function ChangeCamera:OnClose()
    self.super.Close(self)
end

function ChangeCamera:CellRender(idx,item)
    local index = idx + 1
    local ctrl_CameraMode = FGUI:getController(item,"CameraMode")
    ctrl_CameraMode.selectedIndex = idx

    local ctrl_isSelected = FGUI:getController(item,"isSelected")
    ctrl_isSelected.selectedIndex = index == self._cameraMode and 0 or 1
end

function ChangeCamera:CellClicked(context)
    local childIdx = FGUI:GetChildIndex(self.list_CameraMode, context.data)
    local idx = FGUI:GList_childIndexToItemIndex(self.list_CameraMode, childIdx)
    self._cameraMode = idx + 1
    self:RefreshUI()
    SL:SetValue("CAMERA_MODE_PREVIEW",self._cameraMode)
end

function ChangeCamera:RefreshUI()
    FGUI:GList_setNumItems(self.list_CameraMode,3)
end

function ChangeCamera:Enter()
    self._cameraMode  = SL:GetValue("CAMERA_MODE_FROM_LOCAL")
    print("self._cameraMode ====",self._cameraMode)
    self:RefreshUI()
end

function ChangeCamera:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_CAMERA_DATA_SAVE_SUCESS, "SellPanel", handler(self, self.OnClose))
end

function ChangeCamera:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_CAMERA_DATA_SAVE_SUCESS,"SellPanel")
end

return ChangeCamera
