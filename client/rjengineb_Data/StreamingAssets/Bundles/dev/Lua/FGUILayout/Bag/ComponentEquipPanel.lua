local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local ComponentEquipPanel = class("ComponentEquipPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local MMO = global.MMO
-- 如果是弓手的话多一格弓箭装备
local EQUIP_POS_COUNT = 13
local TITLE_SCALE = 0.5
local MODEL_SCALE = 1.2
-- 装备属性页面
function ComponentEquipPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:GetAllFGuiData()
    self:InitData()
    self:InitUI()
end

function ComponentEquipPanel:InitUI()
    FGUI:setOnClickEvent(self.btn_cloak_switch,handler(self,self.btnCloakSwitchClicked))
end

function ComponentEquipPanel:SwitchCtlisShowTitile(isShow)
    self.ctl_isShowTitile.selectedIndex = isShow and 0 or 1
end

function ComponentEquipPanel:btnCloakSwitchClicked(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
    SL:RequestOperateIsOpenFashion(not SL:GetValue("SETTING_GET_IS_SHOW_FASHION"))
end

function ComponentEquipPanel:GetAllFGuiData()
    self.model_root = self._ui.model_root
    self.model_title = self._ui.model_title
    self.panel_touch = self._ui.panel_touch
    self.movie_node = self._ui.movie_node
    self.exPosGongjian = self._ui.exPosGongjian
    self.pos12 = self._ui.pos12 -- 弓箭手专有装备格
    self.pos1 = self._ui.pos1
    self.btn_cloak_switch = self._ui.btn_cloak_switch
    self.btn_scheme_switch = self._ui.btn_scheme_switch
    self.btn_cloth_1 = self._ui.btn_cloth_1
    self.btn_cloth_2 = self._ui.btn_cloth_2
    self.text_title = self._ui.text_title

    self.ctl_isShowClothChoseTip = FGUI:getController(self.component,"isShowClothChoseTip")
    self.ctl_btnCloth1 = FGUI:getController(self.btn_cloth_1,"isSelected")
    self.ctl_btnCloth2 = FGUI:getController(self.btn_cloth_2,"isSelected")
    self.ctl_clothKind = FGUI:getController(self.btn_cloak_switch,"clothKind")
    self.ani_openSwitchCloth = FGUI:GetTransition(self.component,"openSwitchCloth")
    self.ctl_titleType = FGUI:getController(self.component,"titleType")
    self.ctl_isShowTitile = FGUI:getController(self.component,"isShowTitle")
    -- 获取武器槽位的控制器
    self.ctrl_equipPosDI = FGUI:getController(self.pos1,"equipPosDI")
end

function ComponentEquipPanel:InitData()
    self._sex = SL:GetValue("SEX") or 0
	self._job = SL:GetValue("JOB") or 0
    self._bodyId = nil
    self._weaponId = nil
    self.equipMentSlots = {}
    -- 保存对应位置的ROOT后续操作频率高
    for index = 0,EQUIP_POS_COUNT do
        self.equipMentSlots[index] = self._ui["pos" .. (index+1)]
    end

    self.equipMentObjList = {}
end

function ComponentEquipPanel:RefreshTitle()
    local iconID = SL:GetValue("ACTOR_ICON", nil,0)
    if iconID and iconID ~=0 then
        self:RefreshTitleModelByIconID(iconID)
    else
        self:ClearTitle()
    end
end

function ComponentEquipPanel:ClearTitle()
    if self.model_titleIndex then
        FGUI:UIModel_remove(self.model_title,self.model_titleIndex)
        self.model_titleIndex = nil
    end

    if self.movie then
        FGUI:RemoveFromParent(self.movie, true)
        self.movie = nil
    end

    FGUI:GTextField_setText(self.text_title,"")
end

-- 刷新称号模型
function ComponentEquipPanel:RefreshTitleModelByIconID(iconID)
    local iconType = SL:GetValue("ICON_TYPE_BY_ID", iconID)
    self.ctl_titleType.selectedIndex = iconType or 0
    self:ClearTitle()
    if iconType == 1 then -- 特效
        local iconContent = SL:GetValue("ICON_CONTENT_BY_ID", iconID)
        iconContent = tonumber(iconContent)
        self.model_titleIndex = FGUI:UIModel_addFx(self.model_title, iconContent, true,
             Vector3.New(0,0,0), nil, Vector3.New(TITLE_SCALE,TITLE_SCALE,TITLE_SCALE))
    elseif iconType == 2 then -- 文本
        local iconContent = SL:GetValue("ICON_CONTENT_BY_ID", iconID)
        FGUI:GTextField_setText(self.text_title,iconContent)
    elseif iconType == 3 then -- 序列帧
        local iconContent = SL:GetValue("ICON_CONTENT_BY_ID", iconID)
        iconContent = tonumber(iconContent)
        self.movie = FGUI:GMovieClip_create(self.movie_node, iconContent)
        FGUI:GMovieClip_setPlaySettings(self.movie, 0, -1, 0)
        local width,height = FGUI:getSize(self.movie)
        FGUI:setAnchorPoint(self.movie,0.5,0.5,true)
        FGUI:setScale(self.movie,TITLE_SCALE,TITLE_SCALE)
    end
end


-- 刷新模型
function ComponentEquipPanel:RefreshRole()
    local featureData = SL:GetValue("FEATURE")
    if not featureData then
        return
    end

    local bodyId = nil
    local weaponId = nil
    local helmetId = nil
	local faceId = nil
    local classConfig = SL:GetValue("ROLE_CLASS_CONFIG", self._job)
    if classConfig then
        bodyId = classConfig.InitModel[1]
        helmetId = classConfig.InitModel[2]
        weaponId = classConfig.InitModel[3]
		faceId = FGUIFunction:GetFaceIDBySex(self._sex,classConfig)
    end

    local extData = {}
    extData.sex = self._sex
    extData.job = self._job
    extData.bodyId = featureData.clothID or bodyId
    extData.weaponId = featureData.weaponID or weaponId
    extData.faceId = featureData.faceID or faceId
    extData.wingId = featureData.wingID
    extData.helmetId = featureData.helmetID or helmetId
	
    extData.leftFxId = featureData.leftFxID
    extData.rightFxId = featureData.rightFxID
    extData.chestFxId = featureData.chestFxID
    extData.headFxId = featureData.headFxID
    extData.wingFxId = featureData.wingFxID
	
    extData.helmetColor = featureData.helmetColor

    FGUI:UIModel_setObjectEulerAngles(self.model_root, nil, 0, 0, 0)

    if not self._modelIndex then
        self._modelIndex = FGUI:UIModel_addCharacterModel(self.model_root, extData, Vector3.New(0,0,0), nil, Vector3.New(MODEL_SCALE,MODEL_SCALE,MODEL_SCALE))
        FGUI:UIModel_setModelCallback(self.model_root, function(index)

        FGUI:UIModel_playAnimation(self.model_root, index, global.MMO.ANIM_IDLE, nil, 0)
            self:SetModelRotate(self.panel_touch)
        end)
    else
        FGUI:UIModel_setCharacterSex(self.model_root, self._modelIndex, SL:GetValue("SEX"))
        FGUI:UIModel_setCharacterAnim(self.model_root, self._modelIndex, extData.bodyId,
            FGUI.CHARACTER_ANIM_TYPE.MODEL_ANIM_CHARACTER)
		
		FGUI:UIModel_setCharacterAnim(self.model_root, self._modelIndex, extData.weaponId,
			FGUI.CHARACTER_ANIM_TYPE.MODEL_ANIM_WEAPON_R)
		
		FGUI:UIModel_setCharacterAnim(self.model_root, self._modelIndex, extData.faceId,
			FGUI.CHARACTER_ANIM_TYPE.MODEL_ANIM_FACE)
		
		FGUI:UIModel_setCharacterAnim(self.model_root, self._modelIndex, extData.wingId,
			FGUI.CHARACTER_ANIM_TYPE.MODEL_ANIM_WINGS)
		
		FGUI:UIModel_setCharacterAnim(self.model_root, self._modelIndex, extData.helmetId,
			FGUI.CHARACTER_ANIM_TYPE.MODEL_ANIM_HELMET)
		
		FGUI:UIModel_setCharacterFx(self.model_root, self._modelIndex, extData.leftFxId,
			FGUI.CHARACTER_EFFECT_TYPE.MODEL_EFFECT_L_HAND)
		
		FGUI:UIModel_setCharacterFx(self.model_root, self._modelIndex, extData.rightFxId,
			FGUI.CHARACTER_EFFECT_TYPE.MODEL_EFFECT_R_HAND)
		
		FGUI:UIModel_setCharacterFx(self.model_root, self._modelIndex, extData.wingFxId,
			FGUI.CHARACTER_EFFECT_TYPE.MODEL_EFFECT_WINGS)
		
		FGUI:UIModel_setCharacterFx(self.model_root, self._modelIndex, extData.chestFxId,
			FGUI.CHARACTER_EFFECT_TYPE.MODEL_EFFECT_CHEST)
		
		FGUI:UIModel_setCharacterFx(self.model_root, self._modelIndex, extData.headFxId,
			FGUI.CHARACTER_EFFECT_TYPE.MODEL_EFFECT_HEAD)
		
		FGUI:UIModel_setCharacterFx(self.model_root, self._modelIndex, extData.helmetColor,
			FGUI.CHARACTER_EFFECT_TYPE.MODEL_EFFECT_HELMET_COLOR)
		
		FGUI:UIModel_apply(self.model_root, self._modelIndex)
    end
end

function ComponentEquipPanel:RefreshUI()
    self.ctl_clothKind.selectedIndex = SL:GetValue("SETTING_GET_IS_SHOW_FASHION") and 1 or 0
    self.ctl_isShowClothChoseTip.selectedIndex = 1
end

function ComponentEquipPanel:RefreshTip()
    self.ctl_clothKind.selectedIndex = SL:GetValue("SETTING_GET_IS_SHOW_FASHION") and 1 or 0
end

function ComponentEquipPanel:RefreshScheme()
    -- 刷新模型
    self:RefreshUI()
    self:ReleaseAllEquipItem()
    self:RefreshEquipCheck()
    self:RefreshEquipByPos()
    self:RefreshTip()
end


function ComponentEquipPanel:RefreshEquipCheck()
    -- 弓手职业才显示
    FGUI:setVisible(self.pos12,SL:GetValue("JOB") == MMO.ACTOR_PLAYER_JOB_1)
    -- 查看fgui控制器equipPosDI设置(图标对应职业)
    FGUI:Controller_setSelectedIndex(self.ctrl_equipPosDI,11 + SL:GetValue("JOB"))
end

function ComponentEquipPanel:RefreshEquipItemByPosAndEquipData(equipData)
    if not equipData then
        return
    end

    local pos = equipData.Where
    if self.equipMentObjList[pos] then
        ItemUtil:ItemShow_Release(self.equipMentObjList[pos])
    end

    local parent = self.equipMentSlots[pos]
    if parent then
        self.equipMentObjList[pos] = ItemUtil:ItemShow_Create(equipData,parent,
        {
            itemTipData = {from = ItemFrom.PALYER_EQUIP},
            OverLap = equipData.OverLap,
            doubleClickCallback = function()
            SL:TakeOffPlayerEquip(equipData)
            end
            })
    end
end

-- 刷新方案周边的装备
function ComponentEquipPanel:RefreshEquipByPos()
    local bodyEquips = SL:GetValue("EQUIP_POS_DATAS")
    for pos, makeindex in pairs(bodyEquips) do
        local equipData = SL:GetValue("EQUIP_DATA_BY_MAKEINDEX", makeindex)
        if equipData then
            self:RefreshEquipItemByPosAndEquipData(equipData)
        end
    end
end

function ComponentEquipPanel:ReleaseAllEquipItem()
    for k,v in pairs(self.equipMentObjList) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end
    self.equipMentObjList = {}
end

-- 设置旋转
function ComponentEquipPanel:SetModelRotate(uiTouch)
    local angleX = 0
    local angleY = 0
    local angleZ = 0
    local beginX = 0
    local beginFunc = function (eventData)
        beginX = eventData.inputEvent.x
        angleX, angleY, angleZ = FGUI:UIModel_getObjectEulerAngles(self.model_root, self._modelIndex)
        FGUI:EventContext_CaptureTouch(eventData)
    end

    local moveFunc = function (eventData)
        local distanceMax = 1000
        local distance = eventData.inputEvent.x - beginX
        local angle = angleY - (distance * 360 / distanceMax)
        FGUI:UIModel_setObjectEulerAngles(self.model_root, self._modelIndex,0,angle,0)
    end

    local endFunc = function (eventData)
        angleX = 0
        angleY = 0
        angleZ = 0
        beginX = 0
    end

    FGUI:setOnTouchEvent(uiTouch, beginFunc, moveFunc, endFunc)
end

function ComponentEquipPanel:Enter()
    self:RegisterEvent()
    self:RefreshScheme()
    self:RefreshTitle()
    self:RefreshRole()
    SL:ComponentAttach(SLDefine.SUIComponentTable.PlayerInfoEquip, self._ui.Node_attach)
    SL:ComponentAttach(SLDefine.SUIComponentTable.PlayerInfoEquip_B, self._ui.Node_attach_b)
end

function ComponentEquipPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.PlayerInfoEquip)
    SL:ComponentDetach(SLDefine.SUIComponentTable.PlayerInfoEquip_B)
    self:RemoveEvent()
end

function ComponentEquipPanel:UpdateSetting(param1)
    if SLDefine.SETTINGID.SETTING_IDX_OPEN_FASHION ~= param1 then
        return
    end

    self:RefreshScheme()
end

-- 预览人物的称号
function ComponentEquipPanel:PreviewRoleTitle(data)
    if data and data.cfg and data.cfg.ID then
        self:RefreshTitleModelByIconID(data.cfg.ID)
    end
end


function ComponentEquipPanel:RegisterEvent()
    -- 装备更新
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_BODY_UPDATE, "ComponentEquipPanel",handler(self, self.RefreshScheme))
    SL:RegisterLUAEvent(LUA_EVENT_TAKE_OFF_EQUIP_SUCCESS,"ComponentEquipPanel",handler(self, self.RefreshScheme))
    SL:RegisterLUAEvent(LUA_EVENT_TAKE_ON_EQUIP_SUCCESS,"ComponentEquipPanel",handler(self, self.RefreshScheme))
    SL:RegisterLUAEvent(LUA_EVENT_FEATURE_CHANGE,"ComponentEquipPanel",handler(self,self.RefreshRole))
    SL:RegisterLUAEvent(LUA_EVENT_SETTING_CAHNGE, "ComponentEquipPanel",handler(self, self.UpdateSetting))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_DEL,"ComponentEquipPanel",handler(self,self.RefreshScheme))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_ADD,"ComponentEquipPanel",handler(self, self.RefreshScheme))
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_TITLE_UPDATE, "ComponentEquipPanel", handler(self, self.RefreshTitle))
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_TITLE_PREVIEW, "ComponentEquipPanel", handler(self, self.PreviewRoleTitle))
end


function ComponentEquipPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_BODY_UPDATE,"ComponentEquipPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_TAKE_ON_EQUIP_SUCCESS,"ComponentEquipPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_TAKE_OFF_EQUIP_SUCCESS,"ComponentEquipPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_FEATURE_CHANGE,"ComponentEquipPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_SETTING_CAHNGE,"ComponentEquipPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_ADD,"ComponentEquipPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_DEL,"ComponentEquipPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_TITLE_UPDATE,"ComponentEquipPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_TITLE_PREVIEW,"ComponentEquipPanel")
end

return ComponentEquipPanel