local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local HelmetColorPanel = class("HelmetColorPanel", BaseFGUILayout)

local MODEL_SCALE = 1

function HelmetColorPanel:Create()
	self.super.Create(self)

	self._model = nil
	self._modelIndex = nil
	self._ui = FGUI:ui_delegate(self.component)
	self._gloader_target_color = self._ui("slider_color", "target_color")
	self._targetAlp = 0.7
	self._targetColor = nil
	FGUIFunction:SetCloseUIWhenClickOutside(self)
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_no, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_ok, handler(self, self.OnClickSureButton))
	FGUI:setOnClickEvent(self._ui.color_select_panel, handler(self, self.OnColorSelect))
	FGUI:GSlider_setOnChanged(self._ui.slider_color, handler(self, self.OnColorSliderChanged))
end


function HelmetColorPanel:Enter()
    self:RegisterEvent()
	self:RefreshModel()
	self:InitData()
end

function HelmetColorPanel:InitData()
	self._targetAlp = 0.7
	self._targetColor = nil
	FGUI:setVisible(self._ui.text_tip, true)
	FGUI:setVisible(self._ui.slider_color, false)
	FGUI:GSlider_setValue(self._ui.slider_color, 70)
	FGUI:GLoader_setColor(self._gloader_target_color, "#FFFFFF")
end

function HelmetColorPanel:Exit()
	self:RemoveEvent()
end

function HelmetColorPanel:Close()
	self.super.Close(self)
end

function HelmetColorPanel:OnClickSureButton()
	if not self._targetColor then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING", 90030001))
		return
	end
	local color = self._targetColor
	local a = self._targetAlp
	SL:RequestChangeHairColor(color[1], color[2], color[3], a)
	self:Close()
end

function HelmetColorPanel:RefreshModel()
	local featureData = SL:GetValue("FEATURE")
	if not featureData then return end

	local bodyId = nil
    local weaponId = nil
    local helmetId = nil
    local faceId = nil
	local sex = SL:GetValue("SEX") or 0
	local job = SL:GetValue("JOB") or 0
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

	self:ClearModel()
	FGUI:setOpaque(self._ui.panel_touch,true)
    self._model = self:UIModel_Bind(self._ui.model_root)
	FGUI:UIModel_setObjectEulerAngles(self._model, nil, 0, 0, 0)
	self._modelIndex = FGUI:UIModel_addCharacterModel(self._model, extData, Vector3.New(0,0,0), nil, Vector3.New(MODEL_SCALE,MODEL_SCALE,MODEL_SCALE))
	FGUI:UIModel_setModelCallback(self._model, function(index)
		FGUI:UIModel_playAnimation(self._model, index, global.MMO.ANIM_IDLE, nil, 0)
		self:SetModelRotate(self._ui.panel_touch)
	end)
end

-- 滑动条变动
function HelmetColorPanel:OnColorSliderChanged()
	if not self._targetColor then return end
	self._targetAlp = FGUI:GSlider_getValue(self._ui.slider_color) / 100
	self:ChangeHelmetColor()
end

-- 选择颜色
function HelmetColorPanel:OnColorSelect(context)
	local targetObj = context.sender
	local wx, wy = FGUI:getTouchPosition(context)
	local localPosX, localPosY = FGUI:WorldToLocal(targetObj, wx, wy)
	local img = FGUI:GetChild(targetObj, "icon")
	local color = FGUI:GImage_getPixel(img, localPosX, localPosY)
	if color and color.a ~= 0 then
		local hexStr = self:ColorRGBToHexStr(color.r, color.g, color.b)
		FGUI:GLoader_setColor(self._gloader_target_color, hexStr)
		self._targetColor = {color.r, color.g, color.b}

		-- 重置滑块
		FGUI:GSlider_setValue(self._ui.slider_color, 70)
		self:OnColorSliderChanged()
		FGUI:setVisible(self._ui.text_tip, false)
		FGUI:setVisible(self._ui.slider_color, true)
	end
end

-- 改变头发颜色
function HelmetColorPanel:ChangeHelmetColor()
	local r = self._targetColor[1]
	local g = self._targetColor[2]
	local b = self._targetColor[3]
	local a = self._targetAlp
	local colorInt = ActorUtils.ColorToInt32(r, g, b, a)
	FGUI:UIModel_setCharacterFx(self._ui.model_root, self._modelIndex, colorInt,
		FGUI.CHARACTER_EFFECT_TYPE.MODEL_EFFECT_HELMET_COLOR)
	FGUI:UIModel_apply(self._ui.model_root, self._modelIndex)
end

function HelmetColorPanel:ColorRGBToHexStr(r, g, b)
	local r_int = math.floor(r * 255 + 0.5)
	local g_int = math.floor(g * 255 + 0.5)
	local b_int = math.floor(b * 255 + 0.5)
	return string.format("#%02X%02X%02X", r_int, g_int, b_int)
end

function HelmetColorPanel:ClearModel()
    if self._model then
        self:UIModel_Unbind(self._ui.model_root)
    end
end

-- 设置旋转
function HelmetColorPanel:SetModelRotate(uiTouch)
    local angleX = 0
    local angleY = 0
    local angleZ = 0
    local beginX = 0
    local beginFunc = function (eventData)
        beginX = eventData.inputEvent.x
        angleX, angleY, angleZ = FGUI:UIModel_getObjectEulerAngles(self._ui.model_root, self._modelIndex)
        FGUI:EventContext_CaptureTouch(eventData)
    end

    local moveFunc = function (eventData)
        local distanceMax = 1000
        local distance = eventData.inputEvent.x - beginX
        local angle = angleY - (distance * 360 / distanceMax)
        FGUI:UIModel_setObjectEulerAngles(self._ui.model_root, self._modelIndex,0,angle,0)
    end

    local endFunc = function (eventData)
        angleX = 0
        angleY = 0
        angleZ = 0
        beginX = 0
    end

    FGUI:setOnTouchEvent(uiTouch, beginFunc, moveFunc, endFunc)
end

function HelmetColorPanel:RegisterEvent()
	
end

function HelmetColorPanel:RemoveEvent()

end

return HelmetColorPanel