local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCFuncDockNewTip = class("PCFuncDockNewTip", BaseFGUILayout)
local FuncDockUtil = requireFGUILayout("FuncDock_pc/FuncDockUtil")
local MODEL_SCALE = 0.8
-- 角色面板弹窗
function PCFuncDockNewTip:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self.dialog_player_info = self._ui.dialog_player_info
    FGUIFunction:SetCloseUIWhenClickOutside(self)
    self:GetAllFGuiData()
    self:InitGridLayout()
    self:InitOnClickEvent()
end

-- 获取所有需要用到的组件和controller
function PCFuncDockNewTip:GetAllFGuiData()
    self.btn_close = self._ui.btn_close
    self.text_player_name = self._ui.text_player_name
    self.text_player_level = self._ui.text_player_level
    self.text_player_guild = self._ui.text_player_guild
    self.grid_layout_btn = self._ui.grid_layout_btn
    self.com_playerIcon = self._ui.com_playerIcon
    self.model_root = self._ui.model_root
    self.panel_touch = self._ui.panel_touch
    self.text_camp = self._ui.text_camp
    self.ctrl_job = FGUI:getController(self.component,"ctrl_job")
end

function PCFuncDockNewTip:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
end

function PCFuncDockNewTip:InitGridLayout()
    FGUI:GList_itemRenderer(self.grid_layout_btn,handler(self,self.ListViewCellsItemRenderer))
    self.LineGap = FGUI:GList_getLineGap(self.grid_layout_btn)
    self.itemHeight = 36
end

function PCFuncDockNewTip:ListViewCellsItemRenderer(idx,item)
    local btnType = self.btnTypes[idx + 1]
    FGUI:setOnClickEvent(item,function()
        FuncDockUtil:DoFunction(btnType, self._data.targetId)
        FGUI:Close("FuncDock_pc", "PCFuncDockNewTip")
    end)

    local btn_name = FuncDockUtil.BtnTypeShowName[btnType] or FuncDockUtil:GetBtnTypeShowNameDynamic(btnType) or ""
    FGUI:GButton_setTitle(item, btn_name)
end

-- 可以根据类别动态设置按钮
function PCFuncDockNewTip:InitButtonData()
    -- mergeData ---
    self._data.targetName = self._server_data.Name
    self._data.Sex = self._server_data.Sex
    self._data.Job = self._server_data.Job
    self._data.Level = self._server_data.Lv
    self._data.GuildName = self._server_data.GuildName
    self._data.AvatarID = self.featureData.avatar
    FuncDockUtil.SetLayerType(self._data)
    self.btnTypes = FuncDockUtil:GetBtns(self._data.targetId,self._data.TipsType) or {}
end

function PCFuncDockNewTip:RefreshBtnGridLayout()
    FGUI:GList_setNumItems(self.grid_layout_btn, #self.btnTypes)
end

function PCFuncDockNewTip:Enter(data)
    if not data then
        SL:PrintEx("PCFuncDockNewTip data is nil")
        return
    end

    self._data = data
    self:RefreshView()
end

function PCFuncDockNewTip:Exit()
    self:ClearModel()
end

function PCFuncDockNewTip:ClearModel()
    if self._model then
        self:UIModel_Unbind(self.model_root)
    end
end

-- 刷新左边(人物模型)
function PCFuncDockNewTip:RefreshLeft()
    self:ClearModel()
    self._model = self:UIModel_Bind(self.model_root)
    FGUI:setOpaque(self.panel_touch,true)
    if self.featureData then
        local bodyId = nil
        local weaponId = nil
        local helmetId = nil
        local faceId = nil
        local classConfig = SL:GetValue("ROLE_CLASS_CONFIG", self._server_data.Job)
        if classConfig then
            bodyId = classConfig.InitModel[1]
            helmetId = classConfig.InitModel[2]
            weaponId = classConfig.InitModel[3]
            faceId = FGUIFunction:GetFaceIDBySex(self._server_data.Sex,classConfig)
        end

        local extData = {}
        extData.sex = self._server_data.Sex
        extData.job = self._server_data.Job
        extData.bodyId = self.featureData.bodyId or bodyId
        extData.weaponId = self.featureData.rWeapon or weaponId
        extData.faceId = self.featureData.faceId or faceId
        extData.wingId = self.featureData.wingId
        extData.helmetId = self.featureData.headId or helmetId
        extData.leftFxId = self.featureData.leftFxId
        extData.rightFxId = self.featureData.rightFxId
        extData.chestFxId = self.featureData.chestFxId
        extData.headFxId = self.featureData.headFxId
        extData.wingFxId = self.featureData.wingFxId
        extData.helmetColor = self.featureData.helmetColor
        FGUI:UIModel_setObjectEulerAngles(self._model, nil, 0, 0, 0)
        self._modelIndex = FGUI:UIModel_addCharacterModel(self._model, extData, Vector3.New(0,0,0), nil, Vector3.New(MODEL_SCALE,MODEL_SCALE,MODEL_SCALE))
        FGUI:UIModel_setModelCallback(self._model, function(index)
            FGUI:UIModel_playAnimation(self._model, index, global.MMO.ANIM_IDLE, nil, 0)
            self:SetModelRotate(self.panel_touch)
        end)
    end
end

-- 设置旋转
function PCFuncDockNewTip:SetModelRotate(uiTouch)
    local angleX = 0
    local angleX = 0
    local angleY = 0
    local angleZ = 0
    local beginX = 0
    local beginFunc = function (eventData)
        if not self._model then
            return
        end
        beginX = eventData.inputEvent.x
        angleX, angleY, angleZ = FGUI:UIModel_getObjectEulerAngles(self._model, self._modelIndex)
        FGUI:EventContext_CaptureTouch(eventData)
    end

    local moveFunc = function (eventData)
        if not self._model then
            return
        end
        local distanceMax = 1000
        local distance = eventData.inputEvent.x - beginX
        local angle = angleY - (distance * 360 / distanceMax)
        FGUI:UIModel_setObjectEulerAngles(self._model, self._modelIndex,0,angle,0)
    end

    local endFunc = function (eventData)
        angleX = 0
        angleY = 0
        angleZ = 0
        beginX = 0
    end

    FGUI:setOnTouchEvent(uiTouch, beginFunc, moveFunc, endFunc)
end

-- 刷新右边
function PCFuncDockNewTip:RefreshRight()
    if self._server_data then
        local headData = {}
        headData.AvatarID  = self._server_data.avatar
        headData.Job  = self._server_data.Job
        headData.Sex  = self._server_data.Sex
        if self.featureData and self.featureData.avatarFrame then
            headData.FrameID = self.featureData.avatarFrame
        end
        FGUIFunction:SetCommonPlayerFrame(self.com_playerIcon,headData)
        FGUI:GTextField_setText(self.text_player_name,FGUIFunction:GetServerName(self._server_data.Name) or "")
        FGUI:GTextField_setText(self.text_player_level,"Lv."..self._server_data.Lv)
        if string.isNullOrEmpty(self._server_data.GuildName) then
            FGUI:GTextField_setText(self.text_player_guild,GET_STRING(30000008))
        else
            FGUI:GTextField_setText(self.text_player_guild,GET_STRING(30000003) .. FGUIFunction:GetServerName(self._server_data.GuildName))
        end

        self.ctrl_job.selectedIndex = self._server_data.Job - 1
        local showCampStr = ""
        local goodDevilID = self._server_data.GoodEvilId or 0
        if goodDevilID == 0 then
            showCampStr = GET_STRING(30000040)
        elseif goodDevilID == 1 then
            showCampStr = GET_STRING(70000105)
        else
            showCampStr = GET_STRING(70000106)
        end
        FGUI:GTextField_setText(self.text_camp,showCampStr)
        self:RefreshBtnGridLayout()
    end
end

function PCFuncDockNewTip:RefreshView()
    self._server_data = SL:GetValue("REQ_PLAYER_INFO_LATEST")
    if self._server_data and self._server_data.Feature then
        self.featureData = FGUIFunction:FormatFeatureAndCustomStr(self._server_data.Feature)
    end
    self:InitButtonData()
    self:RefreshLeft()
    self:RefreshRight()
end

-- 关闭面板
function PCFuncDockNewTip:OnClose()
    self.super.Close(self)
end

return PCFuncDockNewTip
