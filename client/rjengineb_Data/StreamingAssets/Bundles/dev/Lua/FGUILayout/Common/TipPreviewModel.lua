local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TipPreviewModel = class("TipPreviewModel", BaseFGUILayout)

local MODEL_SCALE = SL:GetValue("IS_PC_OPER_MODE") and 0.8 or  1.2

function TipPreviewModel:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
end

function TipPreviewModel:Enter(data)
	self._itemData = data
	self._modelIndex = nil
end

function TipPreviewModel:UpdatePreviewModel()
    self._previewModelRoot = self._ui.model_root
    FGUI:UIModel_clear(self._previewModelRoot)

    if not self._itemData then
        return
    end

    local featureData = SL:GetValue("FEATURE")
    local modelID = self._itemData and self._itemData.Model
    if not featureData or not modelID then
        return
    end

    local pos = SL:GetValue("EQUIP_POS_BY_STDMODE", self._itemData.StdMode)
    if not pos then
        return
    end

    local appearPos = SL:GetValue("APPEAR_POS_BY_EQUIP_POS", pos)
    if not appearPos or appearPos == -1 then
        return
    end
    
    local sex = SL:GetValue("SEX")
    local job = SL:GetValue("JOB")

    local cSex = self._itemData and self._itemData.Gender or 0
    -- 性别不同不显示预览
    if sex ~= cSex then
        return
    end

    local bodyId = nil
    local weaponId = nil
    local helmetId = nil
	local faceId = nil
    local classConfig = SL:GetValue("ROLE_CLASS_CONFIG", job)
    if classConfig then
        bodyId = classConfig.InitModel[1]
        helmetId = classConfig.InitModel[2]
        weaponId = classConfig.InitModel[3]
		faceId = FGUIFunction:GetFaceIDBySex(sex, classConfig)
    end

    local extData = {}
    extData.sex = sex
    extData.job = job
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

    if appearPos == 0 then  -- 衣服
        extData.bodyId = modelID
    elseif appearPos == 2 then  -- 武器
        extData.weaponId = modelID
    elseif appearPos == 3 then  -- 翅膀
        extData.wingId = modelID
    elseif appearPos == 4 then  -- 头饰
        extData.helmetId = modelID
    elseif appearPos == 5 then  -- 坐骑 
    end

    FGUI:UIModel_setObjectEulerAngles(self._previewModelRoot, nil, 0, 0, 0)

	FGUI:UIModel_addCharacterModel(self._previewModelRoot, extData, Vector3.New(0,0,0), nil, Vector3.New(MODEL_SCALE,MODEL_SCALE,MODEL_SCALE))
	FGUI:UIModel_setModelCallback(self._previewModelRoot, function(index)
		FGUI:UIModel_playAnimation(self._previewModelRoot, index, SLDefine.MODEL_ANIMATION_NAME.ANIM_IDLE, nil, 0)
	end)

	return true
end


return TipPreviewModel