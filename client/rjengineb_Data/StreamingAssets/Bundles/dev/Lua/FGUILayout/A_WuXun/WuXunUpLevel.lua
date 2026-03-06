local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local WuXunUpLevel = class("WuXunUpLevel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

function WuXunUpLevel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    
    FGUI:SetCloseUIWhenClickOutside(self)
    FGUI:setOnClickEvent(self._ui.back, function()           -- 查看百宝阁
        FGUI:Close("A_WuXun", "WuXunUpLevel")
    end)
    
end

function WuXunUpLevel:Enter(data)
    self.effectid = data.effectid or 0
	self:UpdateRoleModel()                      -- 更新中间模型数据
end

function WuXunUpLevel:ClearModel()                           -- 清理中间模型数据
    if self._WuXunModel then
        self:UIModel_Unbind(self._ui.graph_fashion_role)
    end
end
function WuXunUpLevel:UpdateRoleModel()                      -- 更新中间模型数据
    self:ClearModel()
    -- 人物模型
	self._WuXunModel = self:UIModel_Bind(self._ui.graph_fashion_role)
	FGUI:UIModel_setObjectEulerAngles(self._WuXunModel, nil, 0, 0, 0)

    local bodyId = nil
    local weaponId = nil
    local helmetId = nil
	local faceId = nil
    local Sex = SL:GetValue("SEX")
    local Job = SL:GetValue("JOB")
    local modelData = SL:GetValue("FEATURE")
    if modelData then 
		local extData = {}
		extData.sex = Sex
		extData.job = Job
		extData.bodyId = modelData.clothID == 0 and bodyId or modelData.clothID
		extData.helmetId = modelData.helmetID == 0 and helmetId or modelData.helmetID
        extData.weaponId = modelData.weaponID == 0 and weaponId or modelData.weaponID
		extData.faceId = modelData.faceID == 0 and weaponId or modelData.faceID
        self._WuXunModelIndex = FGUI:UIModel_addCharacterModel(self._WuXunModel, extData, nil, nil,Vector3.one * 1.3)
        --self._WuXunEffectIndex = FGUI:UIModel_addLegoModel(self._WuXunModel, 500094, nil, {x = 270,y = 90,z = 0},Vector3.one * 1)
        FGUI:UIModel_addFx(self._WuXunModel, self.effectid,true,{x=0,y=0.7,z=0})
    end
    FGUI:UIModel_setModelCallback(self._WuXunModel, function(index)
        FGUI:UIModel_playAnimation(self._WuXunModel, index, "FashionModel", nil, 0)
        self:SetModelRotate(self._ui.panel_touch)
    end)
end

function WuXunUpLevel:SetModelRotate(uiTouch)                -- 设置模型旋转
    local angleX = 0
    local angleY = 0
    local angleZ = 0
    local beginX = nil
    local beginFunc = function (eventData)
        if not self._WuXunModel then
            return
        end
        beginX = eventData.inputEvent.x
        angleX, angleY, angleZ = self._WuXunModel:GetObjectEulerAngles(self._WuXunModelIndex)
        FGUI:EventContext_CaptureTouch(eventData)
    end

    local moveFunc = function (eventData)
        if not self._WuXunModel then
            return
        end
        local distanceMax = 1000
        local distence = eventData.inputEvent.x - (beginX or 0)
        local angle = angleY - (distence * 360 / distanceMax)
        self._WuXunModel:SetObjectEulerAngles(0, angle, 0, self._WuXunModelIndex)
    end

    local endFunc = function (eventData)
        angleX = 0
        angleY = 0
        angleZ = 0
    end

    FGUI:setOnTouchEvent(uiTouch, beginFunc, moveFunc, endFunc)
end




return WuXunUpLevel