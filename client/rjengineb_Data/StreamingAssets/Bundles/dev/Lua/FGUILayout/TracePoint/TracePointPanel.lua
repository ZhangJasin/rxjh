local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TracePointPanel = class("TracePointPanel", BaseFGUILayout)

local packageName

function TracePointPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.TracePoint)

    packageName = SL:GetValue("IS_PC_OPER_MODE") and "TracePoint_pc" or "TracePoint"
    self._count = 0
    self._points = {}
end

function TracePointPanel:Enter()
    self:RegisterEvent()

    self:UpdateEllipseLimitSize()
    self:Init()
end

function TracePointPanel:Exit()
    self:RemoveEvent()

    self:HideAll()
end

function TracePointPanel:Destroy()
    self._ui = nil	
end

function TracePointPanel:Update()
    local points = self._points
    for k, pointData in pairs(points) do
        if pointData.show then
            self:UpdatePoint(pointData)
        end
    end
end

--------------------------------------------------------------------------------

-- pointData =
-- {
--     key,
--     rawX,
--     rawZ,
--     rawMapId,
--     des,

--     x,       
--     y,
--     z,
--     link,
--     show

--     _curX,
--     _curY,
--     _curPX,
--     _curPY,
--     _item,
--     _imageArrow,
--     _txtDistance,
--     _ctl,
-- }

function TracePointPanel:Init()
    local pointDatas = TracePoint.Get()
    for k, pointData in pairs(pointDatas) do
        self:Show(k)
    end
end

function TracePointPanel:Show(key)
    local data = SL:CopyData(TracePoint.Get(key))
    if not self._points[key] then
        self._count =  self._count + 1
    end
    self._points[key] = data
    if not data._item then 
        local item = FGUI:CreateObject(self.component, packageName, "TracePointItem")
        data._item = item
        data._imageArrow = FGUI:GetChild(item, "Image_arrow")
        data._txtDistance = FGUI:GetChild(item, "Text_distance")
        data._ctl = FGUI:getController(item, "state")
        data.show = true
    end
    self:UpdatePointData(data)
    self:UpdatePoint(data)
end

function TracePointPanel:Hide(key)
    if not key then return end
    local data = self._points[key]
    if not data then return end
    
    if data._item then
        FGUI:RemoveFromParent(data._item, true)
        data._item = nil
        data._imageArrow = nil
        data._txtDistance = nil
        data.show = false
    end
    
    self._points[key] = nil
    self._count = self._count - 1
    if self._count <= 0 then
        self:Close()
    end
end

function TracePointPanel:HideAll()
    local points = self._points
    for k, pointData in pairs(points) do
        self:Hide(k)
    end
end

function TracePointPanel:UpdatePointDatas()
    local points = self._points
    for k, pointData in pairs(points) do
        self:UpdatePointData(pointData)
    end
end

function TracePointPanel:UpdatePointData(data)
    if not data then return end
    local curMapId = SL:GetValue("MAP_ID")
    if data.rawMapId and data.rawMapId ~= curMapId then
        data.link = true
        data.x = nil
        data.z = nil
        --显示关联传送点位置
        local scenePathList, nodeList = SL:GetValue("MAP_AUTO_MOVE_FIND_PORTALS", curMapId, data.rawMapId)
        if nodeList then
            local portal = nodeList[#nodeList]
            if portal then
                data.x = portal.x
                data.z = portal.z
                self:UpdateSceneH(data)
            end
        end
    else
        data.link = false
        data.x = data.rawX or 0
        data.z = data.rawZ or 0
    end
    local show = data.x ~= nil and data.z ~= nil
    if data.show ~= show then
        data.show = show
        if data._item then
            FGUI:setVisible(data._item, show)
        end
    end
    self:UpdateSceneH(data)
end

function TracePointPanel:UpdateSceneHAll()
    local points = self._points
    for k, pointData in pairs(points) do
        self:UpdateSceneH(pointData)
    end
end

function TracePointPanel:UpdateSceneH(data)
    if not data then return end
    data.y = data.rawY or 0
    if not data.x or not data.z then return end
    if not data.link and data.rawY then return end
    data.y = SL:GetScenePointHeight(data.x, 0, data.z)
end


function TracePointPanel:UpdatePoint(data)
    if not data._item then return end
    if not data.x or not data.z then return end
    self:UpdatePosition(data)
    self:UpdateDistance(data)
end

function TracePointPanel:UpdatePosition(data)
    local x, y = FGUI:SceneConvertToWorld(data.x, data.y, data.z)
    if self._sizeDirty then
        self._sizeDirty = false
    elseif x == data._curX and y == data._curY then
        return
    end

    data._curX = x
    data._curY = y

    --显示区域修正
    local angle = nil
    -- x, y, angle = self:GetSquareAdjust(x, y)
    x, y, angle = self:GetEllipseAdjust(x, y)
    if not angle then
        -- 不修正
        data._state = 1
        FGUI:Controller_setSelectedIndex(data._ctl, 1)
    else
        data._state = 0
        FGUI:Controller_setSelectedIndex(data._ctl, 0)
        FGUI:setRotation(data._imageArrow, angle)
    end
    FGUI:setPosition(data._item, x, y)
end

function TracePointPanel:UpdateDistance(data)
    if data._state ~= 1 then return end-- 范围内状态才更新距离文字
    local playerX, playerZ = SL:GetValue("MAP_PLAYER_POS")
    if playerX == data._curPX and playerZ == data._curPZ then return end
    data._curPX = playerX
    data._curPZ = playerZ
    local x = playerX - data.x
    local z = playerZ - data.z
    local dis = math.floor(math.sqrt(x * x + z * z))
    if dis > 0 then
        FGUI:setVisible(data._txtDistance, true)
        FGUI:GTextField_setText(data._txtDistance, (data.des or "") .. dis .. GET_STRING(40041003))
    else
        FGUI:setVisible(data._txtDistance, false)
    end
end

function TracePointPanel:GetAngle(rawX, rawY, x, y)
    local angle = 0
    local lx = rawX - x
    local ly = y - rawY
    if lx == 0 then
        angle = ly < 0 and 90 or -90
    elseif ly == 0 then
        angle = lx > 0 and 0 or -180
    else
        local v = math.atan(lx / ly)
        angle = v * 180 / math.pi - 90
        if ly < 0 then
            angle = angle + 180
        end
    end
    return angle
end

-- 椭圆限制区域调整
function TracePointPanel:UpdateEllipseLimitSize()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    self._cx = screenW / 2
    self._cy = screenH / 2
    
    self._a = screenW * 0.3   --长半轴
    self._a2 = math.pow(self._a, 2)
    self._b = screenH / 3     --短半轴
    self._b2 = math.pow(self._b, 2)
    self._a2b2 = self._a2 * self._b2
    self._sizeDirty = true
end

-- 椭圆区域修正
function TracePointPanel:GetEllipseAdjust(x, y)
    local rawX, rawY = x, y
    local kx = x - self._cx
    local ky = y - self._cy
    local dis = math.pow(kx, 2) * self._b2 + math.pow(ky, 2) * self._a2
    if dis <= self._a2b2 then
        -- 区域内,不修正
        return x, y, nil
    end
    local disX, disY
    if ky == 0 then
        disX = self._a
        disY = 0
        if x < self._cx then disX = -disX end
    elseif kx == 0 then
        disX = 0
        disY = self._b
        if y < self._cy then disY = -disY end
    else
        local k = ky / kx
        disX = math.sqrt(self._a2b2 / (self._b2 + self._a2 * k * k))
        if x < self._cx then disX = -disX end
        disY = k * disX
    end
    x = disX + self._cx
    y = disY + self._cy

    local angle = self:GetAngle(rawX, rawY, x, y)
    return x, y, angle
end

-- 方形限制区域调整
function TracePointPanel:UpdateSquareLimitSize()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    self._cx = screenW / 2
    self._cy = screenH / 2
    --屏幕1/4边缘限制
    -- self._minX = screenW / 4
    -- self._maxX = screenW - self._minX
    -- self._minY = screenH / 4
    -- self._maxY = screenH - self._minY
    --屏幕边缘区域限制
    self._minX = 40
    self._maxX = screenW - self._minX
    self._minY = 40
    self._maxY = screenH - self._minY - 44
    
    self._k1 = (self._maxY - self._cy) / (self._maxX - self._cx)
    self._k2 = (self._maxY - self._cy) / (self._minX - self._cx)
    self._k3 = (self._minY - self._cy) / (self._minX - self._cx)
    self._k4 = (self._minY - self._cy) / (self._maxX - self._cx)
    self._sizeDirty = true
end

-- 方形区域修正
function TracePointPanel:GetSquareAdjust(x, y)
    local rawX, rawY = x, y
    if x > self._minX and x < self._maxX and y > self._minY and y < self._maxY then
        -- 区域内,不修正
        return x, y, nil
    end
    if rawX == self._cx then
        y = math.min(self._maxY, math.max(self._minY, y))
    elseif rawY == self._cy then
        x = math.min(self._maxX, math.max(self._minX, x))
    else
        local k = (rawY - self._cy) / (rawX - self._cx)
        if rawX >= self._cx then
            if rawY >= self._cy then
                --第一象限
                if k > self._k1 then
                    x, y = nil, self._maxY
                else
                    x, y = self._maxX, nil
                end
            else
                --第四象限
                if k > self._k4 then
                    x, y = self._maxX, nil
                else
                    x, y = nil, self._minY
                end
            end
        else 
            if rawY >= self._cy then
                --第二象限
                if k > self._k2 then
                    x, y = self._minX, nil
                else
                    x, y = nil, self._maxY
                end
            else
                --第三象限
                if k > self._k3 then
                    x, y = nil, self._minY
                else
                    x, y = self._minX, nil
                end
            end
        end
        if not x then x = (y - self._cy)/ k + self._cx end
        if not y then y = k * (x - self._cx) + self._cy end
    end

    local angle = self:GetAngle(rawX, rawY, x, y)
    return x, y, angle
end

----------------------------------------------------------------
function TracePointPanel:OnAddTracePoint(key)
    self:Show(key)
end
function TracePointPanel:OnRmvTracePoint(key)
    self:Hide(key)
end
-----------------------------------注册事件--------------------------------------

function TracePointPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ADD_TRACE_POINT, "TracePointPanel", handler(self, self.OnAddTracePoint))
    SL:RegisterLUAEvent(LUA_EVENT_RMV_TRACE_POINT, "TracePointPanel", handler(self, self.OnRmvTracePoint))

    SL:RegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "TracePointPanel", handler(self, self.UpdatePointDatas))
    -- SL:RegisterLUAEvent(LUA_EVENT_WINDOW_SIZE_CHANGE, "TracePointPanel", handler(self, self.UpdateSquareLimitSize))
    SL:RegisterLUAEvent(LUA_EVENT_WINDOW_SIZE_CHANGE, "TracePointPanel", handler(self, self.UpdateEllipseLimitSize))
    SL:RegisterLUAEvent(LUA_EVENT_SCENE_LOAD_END, "TracePointPanel", handler(self, self.UpdateSceneHAll))
end

function TracePointPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ADD_TRACE_POINT, "TracePointPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_RMV_TRACE_POINT, "TracePointPanel")

    SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "TracePointPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_WINDOW_SIZE_CHANGE, "TracePointPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_SCENE_LOAD_END, "TracePointPanel")
end


return TracePointPanel