local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local LookPlayerSingleEquipPanel = class("LookPlayerSingleEquipPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function LookPlayerSingleEquipPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:SetCloseUIWhenClickOutside(self)
    self._pageList = {}
    self:GetAllFGuiData()
    self:InitData()
    self:InitOnClickEvent()
end 

function LookPlayerSingleEquipPanel:GetAllFGuiData()
    self.btn_close = self._ui.btn_close
    self.infoPanel = self._ui.infoPanel
    self.panel_touch = FGUI:GetChild(self.infoPanel,"panel_touch")
    self.model_root = FGUI:GetChild(self.infoPanel,"model_root")
end

function LookPlayerSingleEquipPanel:Destory()
end

function LookPlayerSingleEquipPanel:Enter(page)
    self:RegisterEvent()
    self:RefreshView()
end

function LookPlayerSingleEquipPanel:RefreshView()
    local data = SL:GetValue("L.M.PLAYER_DATA")
    if not data or not next(data) then
        return
    end

    self:UpdateRoleModel()
    self:UpdatePlayerEquip()
end

function LookPlayerSingleEquipPanel:UpdatePlayerInfo()

end

function LookPlayerSingleEquipPanel:Exit()
    self:RemoveEvent()
    self:ClearModel()
    self:ClearAllEquipItem()
end

function LookPlayerSingleEquipPanel:Close()
	self.super.Close(self)
end

function LookPlayerSingleEquipPanel:InitData()
    self.equipMentObjList = {}
end

function LookPlayerSingleEquipPanel:InitOnClickEvent()
	FGUI:setOnClickEvent(self.btn_close, handler(self, self.Close))
end

function LookPlayerSingleEquipPanel:UpdatePlayerEquip()
    -- equips
    self:ClearAllEquipItem()
    local tEquipt = SL:GetValue("L.M.EQUIP_POS_DATAS") or {}
    for pos, equip in pairs(tEquipt) do
        local equipData = SL:GetValue("L.M.EQUIP_BY_MAKEINDEX",equip.MakeIndex)
        if equipData then  
            if self.equipMentObjList[pos] then
                ItemUtil:ItemShow_Release(self.equipMentObjList[pos])
            end

            local parent = FGUI:GetChild(self.infoPanel,"pos"..(equip.Where + 1))
            if parent then
                self.equipMentObjList[pos] = ItemUtil:ItemShow_Create(equipData,parent)
                if self.equipMentObjList[pos].hideArrow then
                    self.equipMentObjList[pos]:hideArrow()
                end
            end
        end
    end
end

-- 释放所有挂载的Item
function LookPlayerSingleEquipPanel:ClearAllEquipItem()
    for k,v in pairs(self.equipMentObjList) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end

    self.equipMentObjList = {}
end

function LookPlayerSingleEquipPanel:ClearModel()
    if self._model then
        self:UIModel_Unbind(self.model_root)
    end
end


function LookPlayerSingleEquipPanel:UpdateRoleModel()
    self:ClearModel()
	self._model = self:UIModel_Bind(self.model_root)
	FGUI:UIModel_setObjectEulerAngles(self._model, nil, 0, 0, 0)

    local bodyId = nil
    local weaponId = nil
    local helmetId = nil
	local faceId = nil
    local lookSex = SL:GetValue("L.M.SEX")
    local lookJob = SL:GetValue("L.M.JOB")
    local classConfig = SL:GetValue("ROLE_CLASS_CONFIG", lookJob)
    if classConfig then 
		faceId = FGUIFunction:GetFaceIDBySex(lookSex,classConfig)
    end 
    
    local modelData = SL:GetValue("L.M.PLAYER_MODEL")
    if modelData then 
		local extData = {}
		extData.sex = lookSex
		extData.job = lookJob
		extData.bodyId = modelData.bodyId == 0 and bodyId or modelData.bodyId
		extData.helmetId = modelData.headId == 0 and helmetId or modelData.headId
        extData.weaponId = modelData.rWeapon == 0 and weaponId or modelData.rWeapon
        extData.wingId = modelData.wingId or 0
		extData.faceId = faceId
        self._modelIndex = FGUI:UIModel_addCharacterModel(self._model, extData, Vector3.New(0,0,0))
    end
    FGUI:UIModel_setModelCallback(self._model, function(index)
        FGUI:UIModel_playAnimation(self._model, index, "Idle", nil, 0)
        self:SetModelRotate(self.panel_touch)
    end)
end

function LookPlayerSingleEquipPanel:Destroy()
    self:ClearAllEquipItem()
end

-- 设置模型旋转
function  LookPlayerSingleEquipPanel:SetModelRotate(uiTouch)
    local angleX = 0
    local angleY = 0
    local angleZ = 0
    local beginX = nil
    local beginFunc = function (eventData)
        if not self._model then
            return
        end
        beginX = eventData.inputEvent.x
        angleX, angleY, angleZ = self._model:GetObjectEulerAngles(self._modelIndex)
        FGUI:EventContext_CaptureTouch(eventData)
    end

    local moveFunc = function (eventData)
        if not self._model then
            return
        end
        local distanceMax = 1000
        local distence = eventData.inputEvent.x - (beginX or 0)
        local angle = angleY - (distence * 360 / distanceMax)
        self._model:SetObjectEulerAngles(0, angle, 0, self._modelIndex)
    end

    local endFunc = function (eventData)
        angleX = 0
        angleY = 0
        angleZ = 0
    end

    FGUI:setOnTouchEvent(uiTouch, beginFunc, moveFunc, endFunc)
end

-----------------------------------注册事件--------------------------------------
function LookPlayerSingleEquipPanel:RegisterEvent()
end

function LookPlayerSingleEquipPanel:RemoveEvent()
end

return LookPlayerSingleEquipPanel