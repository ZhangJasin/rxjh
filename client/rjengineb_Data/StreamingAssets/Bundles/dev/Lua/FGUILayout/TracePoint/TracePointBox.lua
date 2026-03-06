local k = 0
local TracePointBox = class("TracePointBox")


function TracePointBox:Create(resPackageName, resObjName, calcPosHandler, squareOffsetSize)
	self._ui = FGUI:ui_delegate(self.component)

    k = k + 1
    self._k = k
    self._resPackageName = resPackageName
    self._resObjName = resObjName
    self._calcPosHandler = calcPosHandler
    self._squareOffsetSize = squareOffsetSize or 0
    self._count = 0
    self._points = {}
end

function TracePointBox:Enter()
    self:RegisterEvent()

    self:UpdateSquareLimitSize()
    self:Init()
end

function TracePointBox:Exit()
    self:RemoveEvent()

    self:HideAll()
end

function TracePointBox:Destroy()
    self._ui = nil	
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
--     z,
--     show
--     mapX,
--     mapY,

--     _item,
--     _icon,
--     _ctl,
-- }

function TracePointBox:Init()
    local pointDatas = TracePoint.Get()
    for k, pointData in pairs(pointDatas) do
        self:Show(k)
    end
end

function TracePointBox:Show(key)
    local data = SL:CopyData(TracePoint.Get(key))
    if not self._points[key] then
        self._count =  self._count + 1
    end
    self._points[key] = data
    if not data._item then 
        data._item = FGUI:CreateObject(self.component, self._resPackageName, self._resObjName)
        data._icon = FGUI:GetChild(data._item, "icon")
        data._ctl = FGUI:getController(data._item, "state")
        data.show = true
    end
    self:UpdatePointData(data)
    self:UpdatePoint(data)
end

function TracePointBox:Hide(key)
    if not key then return end
    local data = self._points[key]
    if not data then return end
    
    if data._item then
        FGUI:RemoveFromParent(data._item, true)
        data._item = nil
        data.show = false
    end
    
    self._points[key] = nil
    self._count = self._count - 1
end

function TracePointBox:HideAll()
    local points = self._points
    for k, pointData in pairs(points) do
        self:Hide(k)
    end
end

function TracePointBox:SetMapID(mapID)
    self._mapId = mapID
    self:UpdatePoints()
end

function TracePointBox:UpdatePointDatas()
    local points = self._points
    for k, pointData in pairs(points) do
        self:UpdatePointData(pointData)
    end
end

function TracePointBox:UpdatePointData(data)
    if not data then return end
    local curMapId = self._mapId or SL:GetValue("MAP_ID")
    if data.rawMapId and data.rawMapId ~= curMapId then
        data.x = nil
        data.z = nil
        --显示关联传送点位置
        local scenePathList, nodeList = SL:GetValue("MAP_AUTO_MOVE_FIND_PORTALS", curMapId, data.rawMapId)
        if nodeList then
            local portal = nodeList[#nodeList]
            if portal then
                data.x = portal.x
                data.z = portal.z
            end
        end
    else
        data.x = data.rawX or 0
        data.z = data.rawZ or 0
    end
    local show = data.x ~= nil and data.z ~= nil
    self:UpdateMapPoint(data)
    if data.show ~= show then
        data.show = show
        if data._item then
            FGUI:setVisible(data._item, show)
        end
        self:UpdatePoint(data)
    end
end

function TracePointBox:UpdatePoints()
    local points = self._points
    for k, pointData in pairs(points) do
        self:UpdatePointData(pointData)
        self:UpdatePoint(pointData)
    end
end

function TracePointBox:UpdatePoint(data)
    if not data._item then return end
    if not data.x or not data.z then return end
    if not data.show then return end
    self:UpdatePosition(data)
end

function TracePointBox:UpdateMapPoints()
    local points = self._points
    for k, point in pairs(points) do
        self:UpdateMapPoint(point)
    end
    self:UpdatePoints()
end

function TracePointBox:UpdateMapPoint(data)
    if not data.x or not data.z then return end
    if not self._calcPosHandler then return end
    data.mapX, data.mapY = self._calcPosHandler(data.x, data.z)
end

function TracePointBox:UpdatePosition(data)
    if not data.mapX or not data.mapY then return end
    --显示区域修正
    local x, y, angle = self:GetSquareAdjust(data.mapX, data.mapY)
    if not angle then
        -- 不修正
        FGUI:Controller_setSelectedIndex(data._ctl, 1)
    else
        FGUI:Controller_setSelectedIndex(data._ctl, 0)
        FGUI:setRotation(data._icon, angle)
    end
    FGUI:setPosition(data._item, x, y)
end

function TracePointBox:GetAngle(rawX, rawY, x, y)
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
    angle = angle
    return angle
end

-- 方形限制区域调整
function TracePointBox:UpdateSquareLimitSize()
    local x, y = FGUI:getPosition(self.component)
    local w, h = FGUI:getSize(self.component)
    --边缘区域限制
    local minX = -x + self._squareOffsetSize
    local maxX = minX + w - self._squareOffsetSize * 2
    local minY = -y + self._squareOffsetSize
    local maxY = minY + h - self._squareOffsetSize * 2
    local cx = minX + (maxX - minX) / 2
    local cy = minY + (maxY - minY) / 2
    
    self._minX = minX 
    self._maxX = maxX 
    self._minY = minY 
    self._maxY = maxY 
    self._cx   = cx
    self._cy   = cy
    self._k1 = (maxY - cy) / (maxX - cx)
    self._k2 = (maxY - cy) / (minX - cx)
    self._k3 = (minY - cy) / (minX - cx)
    self._k4 = (minY - cy) / (maxX - cx)

    self:UpdatePoints()
end

-- 方形区域修正
function TracePointBox:GetSquareAdjust(x, y)
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
function TracePointBox:OnAddTracePoint(key)
    self:Show(key)
end
function TracePointBox:OnRmvTracePoint(key)
    self:Hide(key)
end
-----------------------------------注册事件--------------------------------------

function TracePointBox:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ADD_TRACE_POINT, "TracePointBox" .. self._k, handler(self, self.OnAddTracePoint))
    SL:RegisterLUAEvent(LUA_EVENT_RMV_TRACE_POINT, "TracePointBox" .. self._k, handler(self, self.OnRmvTracePoint))

    SL:RegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "TracePointBox" .. self._k, handler(self, self.UpdatePointDatas))
end

function TracePointBox:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ADD_TRACE_POINT, "TracePointBox" .. self._k)
    SL:UnRegisterLUAEvent(LUA_EVENT_RMV_TRACE_POINT, "TracePointBox" .. self._k)

    SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "TracePointBox" .. self._k)
end


return TracePointBox