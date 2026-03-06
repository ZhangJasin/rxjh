local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainJoystick = class("MainJoystick", BaseFGUILayout)

local DEFAULT_ALPHA = SL:GetValue("GAME_DATA", "MainJoystickOpacity") or 0.5

function MainJoystick:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Main)

    self._debugDir = {x = 0, y = 0}
    self._isEnableRay = true       -- 是否可以向下穿透射线

	FGUI:setOnTouchEvent(self._ui.Graphic_touch, handler(self, self.OnJoysitckPointerDown), handler(self, self.OnJoystickMove), handler(self, self.OnJoystickPointerUp))
    SL:AddKeyboardEvent("KEY_W", "MainJoystick", handler(self, self.OnPressedKeyW), handler(self, self.OnReleaseKeyW))
    SL:AddKeyboardEvent("KEY_A", "MainJoystick", handler(self, self.OnPressedKeyA), handler(self, self.OnReleaseKeyA))
    SL:AddKeyboardEvent("KEY_S", "MainJoystick", handler(self, self.OnPressedKeyS), handler(self, self.OnReleaseKeyS))
    SL:AddKeyboardEvent("KEY_D", "MainJoystick", handler(self, self.OnPressedKeyD), handler(self, self.OnReleaseKeyD))

    local initX, initY = FGUI:getPosition(self._ui.img_moveBG)
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    self._initX = initX
    self._initBotDis = screenH - initY
    self._touchBeginX = 0
    self._touchBeginY = 0
    self._touchTime = 0

    FGUI:setAlpha(self._ui.Group_move, DEFAULT_ALPHA)
    FGUIFunction:AdaptNotch(self.component)

end

function MainJoystick:Enter()
	self:RegisterEvent()
end

function MainJoystick:Exit()

	self:RemoveEvent()
end

function MainJoystick:Destroy()

    self._ui = nil	
end

function MainJoystick:OnPressedKeyW()
    self._debugDir.y = self._debugDir.y - 1
    self:SetDebugDir(self._debugDir)
end
function MainJoystick:OnPressedKeyA()
    self._debugDir.x = self._debugDir.x - 1
    self:SetDebugDir(self._debugDir)
end
function MainJoystick:OnPressedKeyS()
    self._debugDir.y = self._debugDir.y + 1
    self:SetDebugDir(self._debugDir)
end
function MainJoystick:OnPressedKeyD()
    self._debugDir.x = self._debugDir.x + 1
    self:SetDebugDir(self._debugDir)
end

function MainJoystick:OnReleaseKeyW()
    self._debugDir.y = self._debugDir.y + 1
    self:SetDebugDir(self._debugDir)
end
function MainJoystick:OnReleaseKeyA()
    self._debugDir.x = self._debugDir.x + 1
    self:SetDebugDir(self._debugDir)
end
function MainJoystick:OnReleaseKeyS()
    self._debugDir.y = self._debugDir.y - 1
    self:SetDebugDir(self._debugDir)
end
function MainJoystick:OnReleaseKeyD()
    self._debugDir.x = self._debugDir.x - 1
    self:SetDebugDir(self._debugDir)
end
function MainJoystick:OnReleaseKeySpace()
end

function MainJoystick:OnJoysitckPointerDown(eventData)
    local inputX, inputY = FGUI:getTouchPosition(eventData)
    local x, y = FGUI:WorldToLocal(self.component, inputX, inputY)
    FGUI:setPosition(self._ui.img_moveBG, x, y)
    FGUI:setPosition(self._ui.img_move, x, y)
    FGUI:setAlpha(self._ui.Group_move, 1)
    self._touchBeginX = x
    self._touchBeginY = y
    self._touchTime = SL:GetValue("TIME")
    self._isEnableRay = true
    FGUI:EventContext_CaptureTouch(eventData)
end

function MainJoystick:OnJoystickMove(eventData)
    local inputX, inputY = FGUI:getTouchPosition(eventData)
    local x, y = FGUI:WorldToLocal(self.component, inputX, inputY)
    self:SetMovePosition(x, y)
end

function MainJoystick:OnJoystickPointerUp(eventData)
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local initX = self._initX
    local initY = screenH - self._initBotDis
    FGUI:setAlpha(self._ui.Group_move, DEFAULT_ALPHA)
    FGUI:setPosition(self._ui.img_moveBG, initX, initY)
    FGUI:setPosition(self._ui.img_move, initX, initY)
    self._touchBeginX = 0
    self._touchBeginY = 0

    self:SetMoveDeg(nil)

    -- 未拖动,并且按压时间小于0.2s，开始射线检测遥感下对象
    if self._isEnableRay and SL:GetValue("TIME") < (self._touchTime + 0.2) then
        local haveActor = SL:BeganRaycastActor()
        if not haveActor then
            -- 无对象,进行移动
            SL:CheckMouseMove()
        end
    end
end

----------------------------------------------------------------------------------------
-- Move
local MAX_MOVE_RADIUS       = 50
local MAX_MOVE_RADIUS_SQ    = MAX_MOVE_RADIUS*MAX_MOVE_RADIUS
local IGNORE_RADIUS_SQ      = 15*15
function MainJoystick:SetMovePosition(x, y)
    local px = x - self._touchBeginX
    local py = y - self._touchBeginY
    local lengthSQ = px ^ 2 + py ^ 2
    if lengthSQ <= MAX_MOVE_RADIUS_SQ then
        FGUI:setPosition(self._ui.img_move, x, y)
    else
        local rate = MAX_MOVE_RADIUS / math.sqrt(lengthSQ)
        local x = self._touchBeginX + px * rate
        local y = self._touchBeginY + py * rate
        FGUI:setPosition(self._ui.img_move, x, y)
    end

    -- 计算出角度
    if lengthSQ <= IGNORE_RADIUS_SQ then
        self:SetMoveDeg(nil)
    else
        local deg = math.floor(Mathf.Atan2(-py, px) * Mathf.Rad2Deg)
        self:SetMoveDeg(deg)

        -- 摇杆方向
        deg = deg - 90
        deg = Mathf.Repeat(deg, 360)
    end
end

function MainJoystick:SetMoveDeg(deg)
    if deg then
        self:OnJoystickInputMove(deg)
        self._isEnableRay = false
    else
        if not self._isEnableRay then
            -- 通知移动中断
            SL:SetValue("USER_ABORT_MOVE")
        end
    end
end

function MainJoystick:OnJoystickInputMove(angle)
    SL:SetValue("USER_INPUT_MOVE", angle)
end

----------------------------------------------------------------------------------------
function MainJoystick:SetDebugDir(dir)
    if not dir or not dir.x or not dir.y then
        return
    end
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local initX = self._initX
    local initY = screenH - self._initBotDis

    if dir.x == 0 and dir.y == 0 then
        self:SetMoveDeg(nil)
        FGUI:setAlpha(self._ui.Group_move, DEFAULT_ALPHA)
        FGUI:setPosition(self._ui.img_move, initX, initY)
        return
    end

    FGUI:setAlpha(self._ui.Group_move, 1)
    
    self._touchBeginX = initX
    self._touchBeginY = initY
    local x = self._touchBeginX + dir.x * MAX_MOVE_RADIUS
    local y = self._touchBeginY + dir.y * MAX_MOVE_RADIUS
    self:SetMovePosition(x, y)
end

-----------------------------------注册事件--------------------------------------
function MainJoystick:RegisterEvent()
end

function MainJoystick:RemoveEvent()

end


return MainJoystick