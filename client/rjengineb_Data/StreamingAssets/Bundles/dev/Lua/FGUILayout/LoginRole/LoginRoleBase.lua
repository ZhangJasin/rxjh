local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local LoginRoleBase = class("LoginRoleBase", BaseFGUILayout)
if not LoginScene then
	SL:RequireFile("FGUILayout/login/LoginScene")
end

local beginX = 0

LoginRoleBase.FitstEntry = true

function LoginRoleBase:Create()
    self.modelEntity = nil
    if SL:GetValue("IS_PC_OPER_MODE") then
        self._packageName = "LoginRole_pc"
    else
        self._packageName = "LoginRole"
    end
    self.jobSelectPath = "ui://"..self._packageName.."/icon_job_select_%s"
    self.jobUnselectPath = "ui://"..self._packageName.."/icon_job_unselect_%s"
    self.jobAttriPath = "ui://"..self._packageName.."/icon_attr_%s"
    self.jobTextPath = "ui://"..self._packageName.."/text_job_%s"
    
    global.Facade:sendNotification(global.NoticeTable.Layer_Server_Close)
end

function LoginRoleBase:OpenCreateRolePanel()
    FGUI:Open(self._packageName, "LoginRoleCreate", nil, nil, {classPath = "FGUILayout/LoginRole/LoginRoleCreate"})
    FGUI:Close(self._packageName, "LoginRoleSelect")
end

function LoginRoleBase:OpenSelectRolePanel()
    FGUI:Open(self._packageName, "LoginRoleSelect", nil, nil, {classPath = "FGUILayout/LoginRole/LoginRoleSelect"})
    FGUI:Close(self._packageName, "LoginRoleCreate")
end

-- 设置模型旋转
function  LoginRoleBase:SetModelRotate(uiTouch)
    local angleX = 0
    local angleY = 0
    local angleZ = 0

    local beginFunc = function (eventData)
        beginX = eventData.inputEvent.x
        angleX, angleY, angleZ = SL:GetCreateSceneModelRotation(self.modelEntity)
        FGUI:EventContext_CaptureTouch(eventData)
    end

    local moveFunc = function (touchInfo)
        local distanceMax = 1000
        local distence = touchInfo.inputEvent.x - (beginX or 0)
        local angle = angleY - (distence * 360 / distanceMax)
        SL:SetCreateSceneModelRotation(self.modelEntity, angle)
    end

    local endFunc = function (touchInfo)
        local info = touchInfo
        angleX = 0
        angleY = 0
        angleZ = 0
    end

    FGUI:setOnTouchEvent(uiTouch, beginFunc, moveFunc, endFunc)
end


--------------------------------------------动作播放逻辑------------------------------------------------
function LoginRoleBase:DoAnim(skillID)
    if not skillID then
        return
    end

    local skillCfg = SL:GetValue("SKILL_CONFIG_BY_SKILL_ID", skillID)
    if not skillCfg or not skillCfg.Animation then
        return
    end

    local animCfg = SL:GetValue("SKILL_ANIMATION_CONFIG_BY_ID", skillCfg.Animation)
    if not animCfg or not animCfg.Anim then
        return
    end

    local animName = animCfg.Anim
    SL:CreateSceneModelDoAnim(self.modelEntity, animName, skillID)
end



return LoginRoleBase