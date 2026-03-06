local Queue = Queue
local pools = {}
local poolMap = {}
local types = {}
local infos = {}
local id = 0
local function _GetPool(type)
    local pool = pools[type]
    if not pool then
        pool = Queue.new()
        pools[type] = pool
    end
    return pool
end
local function _GetType(packageName, componentName)
    local id1 = types[packageName]
    if not id1 then
        id = id + 1
        id1 = id
        types[packageName] = id1
    end
    local id2 = types[componentName]
    if not id2 then
        id = id + 1
        id2 = id
        types[componentName] = id2
    end
    return id1 * 10000 + id2
end

---------------------------------------------------------------------------
Pool = {}

-- 注册 池获取对象 绑定 自定义路径Class
function Pool.RegisterClass(packageName, componentName, classPath)
    local type = _GetType(packageName, componentName)
    local curInfo = infos[type]
    if curInfo then
        if curInfo ~= classPath then
            SL:Print("[ERROR] Pool 错误注册")
        return
        end
    end
    infos[type] = classPath
end

-- bindClass: 池获取对象 绑定 界面固定规则路径Class (默认false)
function Pool.Get(packageName, componentName, parent, bindClass)
    local type = _GetType(packageName, componentName)
    local pool = _GetPool(type)
    local item = pool:pop()
    local classPath = infos[type]
    if item then
        local obj = classPath and item.component or item
        local id = FGUI:GetID(obj)
        FGUI:AddChild(parent, obj)
        poolMap[id] = nil
    else
        if classPath == true then
            bindClass = true
        elseif bindClass then
            infos[type] = true
        end
        local obj = FGUI:CreateObject(parent, packageName, componentName, bindClass)
        if not bindClass and classPath then
            local itemClass = SL:RequireFile(classPath)
            item = itemClass.new(obj)
            item.component = obj
        else
            item = obj
        end
    end
    return item
end

-- 回池 (注:需要外部重置显示状态)
function Pool.Release(packageName, componentName, item, remove)
    if not item then return end
    local type = _GetType(packageName, componentName)
    local pool = _GetPool(type)
    local obj = infos[type] and item.component or item
    local id = FGUI:GetID(obj)
    if poolMap[id] then
        -- 重复回池
        SL:Print("[ERROR] Pool 重复回池" .. type)
        return
    end
    poolMap[id] = true
    pool:push(item)
    if remove ~= false then
        FGUI:RemoveFromParent(obj, false)
    end
end

-- 销毁指定类型的池
function Pool.Destroy(packageName, componentName, destroy)
    local type = _GetType(packageName, componentName)
    local pool = pools[type]
    if not pool then return end
    destroy = destroy ~= false
    local item
    local classPath = infos[type]
    repeat
        item = pool:pop()
        if item then
            local obj = classPath and item.component or item
            local id = FGUI:GetID(obj)
            poolMap[id] = nil
            if destroy then
                FGUI:RemoveFromParent(obj, true)
            end
        end
    until (not item)
end
