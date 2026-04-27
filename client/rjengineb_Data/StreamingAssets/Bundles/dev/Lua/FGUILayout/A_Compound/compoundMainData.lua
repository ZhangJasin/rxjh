local compoundMainData = class("compoundMainData")

local Message = SL:RequireFile("Net/Message")
local FGUI = SL:RequireFile("FGUI/FGUI")

-- 单例
local instance = nil
function compoundMainData:getInstance()
    if not instance then
        instance = compoundMainData:new()
    end
    return instance
end

function compoundMainData:ctor()
    self._eventDispatcher = SL:RequireFile("Event/EventDispatcher"):new()

    -- 数据结构
    self._group1List = {}       -- 一级分组列表
    self._group2Map = {}        -- 二级分组映射 (key: 一级分组, value: 二级分组列表)
    self._group3Map = {}        -- 三级分组映射 (key: 一级.二级, value: 三级分组列表)
    self._currentGroup1 = ""    -- 当前选中的一级分组
    self._currentGroup2 = ""    -- 当前选中的二级分组
    self._currentGroup3 = ""    -- 当前选中的三级分组
    self._currentContent = nil  -- 当前选中的内容

    self:_initGroupData()
end

-- 初始化分组数据
-- 注意：这里需要根据实际的数据来源进行初始化
function compoundMainData:_initGroupData()
    -- 示例数据结构，需要根据实际情况修改
    -- 数据结构示例:
    -- self._group1List = {"分组1", "分组2", "分组3"}
    -- self._group2Map = {
    --     ["分组1"] = {"子分组1-1", "子分组1-2"},
    --     ["分组2"] = {"子分组2-1", "子分组2-2"},
    -- }
    -- self._group3Map = {
    --     ["分组1.子分组1-1"] = {"项目1-1-1", "项目1-1-2"},
    --     ["分组1.子分组1-2"] = {"项目1-2-1", "项目1-2-2"},
    -- }

    -- 默认选中第一个一级分组
    if #self._group1List > 0 then
        self._currentGroup1 = self._group1List[1]
        local g2List = self:GetGroup2List(self._currentGroup1)
        if #g2List > 0 then
            self._currentGroup2 = g2List[1]
            local g3List = self:GetGroup3List(self._currentGroup1, self._currentGroup2)
            if #g3List > 0 then
                self._currentGroup3 = g3List[1]
                self:_updateCurrentContent()
            end
        end
    end
end

-- 设置分组数据（外部调用此方法设置数据）
-- @param group1List 一级分组列表
-- @param group2Map 二级分组映射表
-- @param group3Map 三级分组映射表
function compoundMainData:SetGroupData(group1List, group2Map, group3Map)
    self._group1List = group1List or {}
    self._group2Map = group2Map or {}
    self._group3Map = group3Map or {}
    self:_initGroupData()
end

-- 更新当前内容
function compoundMainData:_updateCurrentContent()
    local group3List = self:GetGroup3List(self._currentGroup1, self._currentGroup2)
    for _, g3 in ipairs(group3List) do
        if g3 == self._currentGroup3 then
            self._currentContent = {
                group1 = self._currentGroup1,
                group2 = self._currentGroup2,
                group3 = self._currentGroup3,
                name = self._currentGroup3,
            }
            break
        end
    end
end

-- 获取一级分组列表
function compoundMainData:GetGroup1List()
    return self._group1List
end

-- 获取二级分组列表
-- @param group1 一级分组名称
function compoundMainData:GetGroup2List(group1)
    return self._group2Map[group1] or {}
end

-- 获取三级分组列表
-- @param group1 一级分组名称
-- @param group2 二级分组名称
function compoundMainData:GetGroup3List(group1, group2)
    local key = group1 .. "." .. group2
    return self._group3Map[key] or {}
end

-- 选择一级分组
function compoundMainData:SelectGroup1(group1)
    self._currentGroup1 = group1
    local g2List = self:GetGroup2List(group1)
    if #g2List > 0 then
        self._currentGroup2 = g2List[1]
        local g3List = self:GetGroup3List(group1, self._currentGroup2)
        if #g3List > 0 then
            self._currentGroup3 = g3List[1]
        else
            self._currentGroup3 = ""
        end
    else
        self._currentGroup2 = ""
        self._currentGroup3 = ""
    end
    self:_updateCurrentContent()
    self:DispatchEvent("compound_group1_changed", {group1 = group1})
end

-- 选择二级分组
function compoundMainData:SelectGroup2(group2)
    self._currentGroup2 = group2
    local g3List = self:GetGroup3List(self._currentGroup1, group2)
    if #g3List > 0 then
        self._currentGroup3 = g3List[1]
    else
        self._currentGroup3 = ""
    end
    self:_updateCurrentContent()
    self:DispatchEvent("compound_group2_changed", {group2 = group2})
end

-- 选择三级分组
function compoundMainData:SelectGroup3(group3)
    self._currentGroup3 = group3
    self:_updateCurrentContent()
    self:DispatchEvent("compound_group3_changed", {group3 = group3})
end

-- 获取当前内容
function compoundMainData:GetCurrentContent()
    return self._currentContent
end

-- 事件系统
function compoundMainData:DispatchEvent(event, data)
    if self._eventDispatcher then
        self._eventDispatcher:Dispatch(event, data)
    end
end

function compoundMainData:Subscribe(event, callback)
    if self._eventDispatcher then
        return self._eventDispatcher:Subscribe(event, callback)
    end
    return nil
end

function compoundMainData:Unsubscribe(token)
    if self._eventDispatcher then
        self._eventDispatcher:Unsubscribe(token)
    end
end

return compoundMainData
