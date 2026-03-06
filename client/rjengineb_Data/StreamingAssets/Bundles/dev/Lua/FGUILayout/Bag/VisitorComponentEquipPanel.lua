local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorComponentEquipPanel = class("VisitorComponentEquipPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local MMO = global.MMO
-- 如果是弓手的话多一格弓箭装备
local EQUIP_POS_COUNT = 13
local TITLE_SCALE = 0.5
local MODEL_SCALE = 1.2
-- 装备属性页面
function VisitorComponentEquipPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self.stageClickHandler = handler(self, self.StageClickEvent)
    self.STAGE_EVENT_COMMON_TIP = "STAGE_EVENT_COMMON_TIP_1"
    self:GetAllFGuiData()
    self:InitData()
    self:InitUI()
end

function VisitorComponentEquipPanel:InitUI()
end

function VisitorComponentEquipPanel:CheckInitiatorIsButton(data)
	local eventInitiator = FGUI:EventContext_getInitiator(data.eventData)
	if eventInitiator and eventInitiator.gameObject then
		if "btn_cloth_chose" == eventInitiator.gameObject.name then
			return false
		end
	end
	return true
end

function VisitorComponentEquipPanel:StageClickEvent(data)
    if data.eventName == self.STAGE_EVENT_COMMON_TIP then
        local tapClose = true
		tapClose = self:CheckInitiatorIsButton(data)
		if tapClose then
			self.ctl_isShowClothChoseTip.selectedIndex = 1
		end
    end
end

function VisitorComponentEquipPanel:GetAllFGuiData()
    self.model_root = self._ui.model_root
    self.model_title = self._ui.model_title
    self.panel_touch = self._ui.panel_touch
    self.movie_node = self._ui.movie_node
    self.exPosGongjian = self._ui.exPosGongjian
    self.pos12 = self._ui.pos12 -- 弓箭手专有装备格
    self.btn_cloak_switch = self._ui.btn_cloak_switch
    self.btn_scheme_switch = self._ui.btn_scheme_switch
    self.btn_cloth_1 = self._ui.btn_cloth_1
    self.btn_cloth_2 = self._ui.btn_cloth_2
    self.text_title = self._ui.text_title

    self.ctl_isShowClothChoseTip = FGUI:getController(self.component,"isShowClothChoseTip")
    self.ctl_btnCloth1 = FGUI:getController(self.btn_cloth_1,"isSelected")
    self.ctl_btnCloth2 = FGUI:getController(self.btn_cloth_2,"isSelected")
    self.ani_openSwitchCloth = FGUI:GetTransition(self.component,"openSwitchCloth")
    self.ctl_titleType = FGUI:getController(self.component,"titleType")
    self.ctl_isShowTitile = FGUI:getController(self.component,"isShowTitle")

    FGUI:setVisible(self.btn_cloak_switch, false)
end

function VisitorComponentEquipPanel:InitData()
    self._sex = SL:GetValue("VISITOR_SEX") or 0
	self._job = SL:GetValue("VISITOR_JOB") or 0
    self._bodyId = nil
    self._weaponId = nil
    self.equipMentSlots = {}
    -- 保存对应位置的ROOT后续操作频率高
    for index = 0,EQUIP_POS_COUNT do
        self.equipMentSlots[index] = self._ui["pos" .. (index+1)]
    end

    self.equipMentObjList = {}
end

function VisitorComponentEquipPanel:ClearTitle()
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


-- 刷新模型
function VisitorComponentEquipPanel:RefreshRole()
    local BagProxy = global.Facade:retrieveProxy(global.ProxyTable.VisitorTradingBankProxy)
    local featureData = BagProxy:GetRoleFeature()
    if not featureData then
        return
    end
    local fxfeatureData = BagProxy:GetRoleFxFeature()
    if not fxfeatureData then
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
    extData.bodyId   = featureData.clothID or bodyId
    extData.weaponId = featureData.weaponID or weaponId
    extData.faceId   = featureData.faceID or faceId
    extData.wingId   = featureData.wingID
    extData.helmetId = featureData.helmetID or helmetId
	
    extData.leftFxId  = fxfeatureData.leftFxID
    extData.rightFxId = fxfeatureData.rightFxID
    extData.chestFxId = fxfeatureData.chestFxID
    extData.headFxId  = fxfeatureData.headFxID
    extData.wingFxId  = fxfeatureData.wingFxID

    FGUI:UIModel_setObjectEulerAngles(self.model_root, nil, 0, 0, 0)

    if not self._modelIndex then
        self._modelIndex = FGUI:UIModel_addCharacterModel(self.model_root, extData, Vector3.New(0,0,0), nil, Vector3.New(MODEL_SCALE,MODEL_SCALE,MODEL_SCALE))
        FGUI:UIModel_setModelCallback(self.model_root, function(index)

        FGUI:UIModel_playAnimation(self.model_root, index, global.MMO.ANIM_IDLE, nil, 0)
            self:SetModelRotate(self.panel_touch)
        end)
    end
end
function VisitorComponentEquipPanel:RefreshScheme()
    -- 刷新模型
    self:ReleaseAllEquipItem()
    self:RefreshEquipCheck()
    self:RefreshEquipByPos()
end

-- 弓手职业才显示
function VisitorComponentEquipPanel:RefreshEquipCheck()
    FGUI:setVisible(self.pos12,SL:GetValue("VISITOR_JOB") == MMO.ACTOR_PLAYER_JOB_1)
end

function VisitorComponentEquipPanel:RefreshEquipItemByPosAndEquipData(equipData)
    if not equipData then
        return
    end

    local pos = equipData.Where
    if self.equipMentObjList[pos] then
        ItemUtil:ItemShow_Release(self.equipMentObjList[pos])
    end

    local parent = self.equipMentSlots[pos]
    -- print("pos--------------------",pos)
    if parent then
        self.equipMentObjList[pos] = ItemUtil:ItemShow_Create(equipData,parent,
        {
            OverLap = equipData.OverLap,
            disableClick = false,
            })
    end
end

-- 刷新方案周边的装备
function VisitorComponentEquipPanel:RefreshEquipByPos()
    local bodyEquips = SL:GetValue("VISITOR_EQUIP_POS_DATAS")
    -- SL:print_t(bodyEquips)
    for pos, makeindex in pairs(bodyEquips) do
        local equipData = SL:GetValue("VISITOR_EQUIP_DATA_BY_MAKEINDEX", makeindex)--判断装备是否再身上
        if equipData then
            self:RefreshEquipItemByPosAndEquipData(equipData)
        end
    end
end

function VisitorComponentEquipPanel:ReleaseAllEquipItem()
    for k,v in pairs(self.equipMentObjList) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end
    self.equipMentObjList = {}
end

-- 设置旋转
function VisitorComponentEquipPanel:SetModelRotate(uiTouch)
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

function VisitorComponentEquipPanel:Enter()
    self:RefreshScheme()
    FGUI:StageEvent_AddListener(self.STAGE_EVENT_COMMON_TIP,self.stageClickHandler)
    self:RefreshRole()
    SL:ComponentAttach(SLDefine.SUIComponentTable.VisitorPlayerInfoEquip, self._ui.Node_attach)
    SL:ComponentAttach(SLDefine.SUIComponentTable.VisitorPlayerInfoEquip_B, self._ui.Node_attach_b)
end

function VisitorComponentEquipPanel:Exit()
    FGUI:StageEvent_RemoveListener(self.STAGE_EVENT_COMMON_TIP)
    SL:ComponentDetach(SLDefine.SUIComponentTable.VisitorPlayerInfoEquip)
    SL:ComponentDetach(SLDefine.SUIComponentTable.VisitorPlayerInfoEquip_B)
end


return VisitorComponentEquipPanel