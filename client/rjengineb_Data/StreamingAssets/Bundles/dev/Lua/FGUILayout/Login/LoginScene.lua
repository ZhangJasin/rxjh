LoginScene = {
    _loginSceneName = "1002",
    _loginRolePosition = Vector3.New(0, 0, -9.71),
    _camerPosition = Vector3.New(0, 0, -9.71),
    _loginRoleScal = Vector3.New(1,1,1),
    _cameraMoveSpeed = 10,
    _loginRoleRotationY = 180,
    _cameraYaw = 90,
    _cameraPitch = 0,
    _cameraDistance = 5,
    _cameraTargetY = 0.9,
}

function LoginScene:GetSceneName()
    if LoginScene._loginSceneName then
        return LoginScene._loginSceneName
    end
    return "1002"
end

function LoginScene:SetSceneName(sceneName)
    LoginScene._loginSceneName = sceneName
end

function LoginScene:GetRolePosition()
    if LoginScene._loginRolePosition then
        return LoginScene._loginRolePosition
    end
    return Vector3.New(0, 0, 0)
end

function LoginScene:GetRoleCamerPosition()
    if LoginScene._camerPosition then
        return LoginScene._camerPosition
    end
    return Vector3.New(0, 0, 0)
end

function LoginScene:GetRoleScal()
    if LoginScene._loginRoleScal then
        return LoginScene._loginRoleScal
    end
    return Vector3.New(1, 1, 1)
end

function LoginScene:CameraMoveSpeed()
    if LoginScene._cameraMoveSpeed then
        return LoginScene._cameraMoveSpeed
    end
    return 10
end

function LoginScene.SetRolePosition(x, y, z)
    LoginScene._loginRolePosition = Vector3.New(x, y, z)
end
function LoginScene.SetCamerPosition(x, y, z)
    LoginScene._camerPosition = Vector3.New(x, y, z)
end
function LoginScene:SetCreateRolePosition(x, y, z)
    LoginScene._createRolePosition = Vector3.New(x, y, z)
end

function LoginScene:GetRoleRotationY()
    if LoginScene._loginRoleRotationY then
        return LoginScene._loginRoleRotationY
    end
    return 180
end

function LoginScene:SetRoleRotationY(y)
    LoginScene._loginRoleRotationY = y
end

function LoginScene:GetCameraYaw()
    if LoginScene._cameraYaw then
        return LoginScene._cameraYaw
    end
    return 90
end

function LoginScene:SetCameraYaw(yaw)
    LoginScene._cameraYaw = yaw
end

function LoginScene:GetCameraPitch()
    if LoginScene._cameraPitch then
        return LoginScene._cameraPitch
    end
    return 0
end

function LoginScene:SetCameraPitch(pitch)
    LoginScene._cameraPitch = pitch
end

function LoginScene:GetCameraDistance()
    if LoginScene._cameraDistance then
        return LoginScene._cameraDistance
    end
    return 5.3
end

function LoginScene:SetCameraDistance(distance)
    LoginScene._cameraDistance = distance
end

function LoginScene:GetCameraTargetY()
    if LoginScene._cameraTargetY then
        return LoginScene._cameraTargetY
    end
    return 1.44
end

function LoginScene:SetCameraTargetY(targetY)
    LoginScene._cameraTargetY = targetY
end

return LoginScene
