TracePoint = {}
local TracePoint = TracePoint

-- pointData =
-- {
--     key,
--     rawX,
--     rawY,
--     rawZ,
--     rawMapId,
--     des,
-- }
local _pointDatas = {}
local _k = 0


function TracePoint.main()
    TracePoint.HideAll()
    -- 绑定寻路追踪
    SL:RegisterLUAEvent(LUA_EVENT_AUTO_MOVE_BEGIN, "TracePoint", TracePoint.OnAutoMoveBegin)
    SL:RegisterLUAEvent(LUA_EVENT_AUTO_MOVE_END, "TracePoint", TracePoint.OnAutoMoveEnd)

    --测试
    -- local key = TracePoint.Show(256, nil, 331, "101", "Test1 ")
    -- TracePoint.Hide(key)
end

--------------------------------------------------------------------------------
---增加追踪点
---@param x float 地图坐标x
---@param y float 地图坐标y (=nil时使用默认地表高度)
---@param z float 地图坐标z
---@param mapId string 地图id (=nil时不校验地图)
---@param des string 额外描述(可空)
---@param key string 指定唯一key (=nil时自动分配)
---@return key string 返回唯一key
function TracePoint.Show(x, y, z, mapId, des, key)
    local data
    if key then
        -- 更新指定key的追踪点
        data = _pointDatas[key]
        if not data then
            data = {}
            _pointDatas[key] = data
        end
    else
        _k = _k + 1
        key = _k
        data = {}
        _pointDatas[key] = data
    end
    data.key = key
    data.rawX = x or 0
    data.rawY = y
    data.rawZ = z or 0
    data.rawMapId = mapId
    data.des = des

    SL:onLUAEvent(LUA_EVENT_ADD_TRACE_POINT, key)
    local packageName = SL:GetValue("IS_PC_OPER_MODE") and "TracePoint_pc" or "TracePoint"
    local componentName = SL:GetValue("IS_PC_OPER_MODE") and "PCTracePointPanel" or "TracePointPanel"
    if not FGUI:CheckOpen(packageName, componentName) then
        FGUI:Open(packageName, componentName, nil, FGUI_LAYER.BG, {classPath = "FGUILayout/TracePoint/TracePointPanel"})
    end
    return key
end

---移除追踪点
---@param key string 指定唯一key
function TracePoint.Hide(key)
    local data = _pointDatas[key]
    if not data then return end
    _pointDatas[key] = nil
    SL:onLUAEvent(LUA_EVENT_RMV_TRACE_POINT, key)
end

---移除所有追踪点
function TracePoint.HideAll()
    for k, pointData in pairs(_pointDatas) do
        TracePoint.Hide(k)
    end
end

function TracePoint.Get(key)
    if key then
        return _pointDatas[key]
    else
        return _pointDatas
    end
end

--------------------------------------------------------------------------------

function TracePoint.OnAutoMoveBegin(data)
    TracePoint.Show(data.x, data.y, data.z, data.mapID, nil, "move")
end

function TracePoint.OnAutoMoveEnd()
    TracePoint.Hide("move")
end
