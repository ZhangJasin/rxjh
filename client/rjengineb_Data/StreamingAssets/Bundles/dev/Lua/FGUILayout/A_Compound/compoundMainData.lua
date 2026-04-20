local compoundMainData = class("compoundMainData")

local Compound = require("game_config/cfgcsv/Compound")
local Message = SL:RequireFile("Net/Message")
local FGUI = SL:RequireFile("FGUI/FGUI")

-- 单例
local instance = nil
function compoundMainData:getInstance()
    return self
end

function compoundMainData:ctor()
    self._eventDispatcher = SL:RequireFile("Event/EventDispatcher"):new()
    
    -- 数据结构
    self._group1List = {}       -- 一级分组列表
    self._group2List = {}       -- 二级分组列表
    self._currentGroup1 = ""    -- 当前选中的一级分组
    self._currentGroup2 = ""    -- 当前选中的二级分组
    self._currentCompoundID = 0 -- 当前选中的合成ID
    
    self:_initGroupData()
end

-- 初始化分组数据
function compoundMainData:_initGroupData()
    local group1Set = {}
    local group2Set = {}
    
    -- 收集所有一级分组和二级分组
    for _, cfg in pairs(Compound) do
        group1Set[cfg.Group1] = true
        if not group2Set[cfg.Group1] then
            group2Set[cfg.Group1] = {}
        end
        group2Set[cfg.Group1][cfg.Group2] = true
    end
    
    -- 转换为列表
    for g1, _ in pairs(group1Set) do
        table.insert(self._group1List, g1)
    end
    
    table.sort(self._group1List)
    
    -- 为每个一级分组排序二级分组
    for g1, g2Table in pairs(group2Set) do
        local g2List = {}
        for g2, _ in pairs(g2Table) do
            table.insert(g2List, g2)
        end
        table.sort(g2List)
        group2Set[g1] = g2List
    end
    
    self._group2Map = group2Set
    
    -- 默认选中第一个
    if #self._group1List > 0 then
        self._currentGroup1 = self._group1List[1]
        if #self._group2Map[self._currentGroup1] > 0 then
            self._currentGroup2 = self._group2Map[self._currentGroup1][1]
            self:_updateCurrentCompoundID()
        end
    end
end

-- 更新当前合成ID
function compoundMainData:_updateCurrentCompoundID()
    for id, cfg in pairs(Compound) do
        if cfg.Group1 == self._currentGroup1 and cfg.Group2 == self._currentGroup2 then
            self._currentCompoundID = id
            break
        end
    end
end

-- 获取一级分组列表
function compoundMainData:GetGroup1List()
    return self._group1List
end

-- 获取二级分组列表
function compoundMainData:GetGroup2List(group1)
    return self._group2Map[group1] or {}
end

-- 选择一级分组
function compoundMainData:SelectGroup1(group1)
    self._currentGroup1 = group1
    local g2List = self:GetGroup2List(group1)
    if #g2List > 0 then
        self._currentGroup2 = g2List[1]
    end
    self:_updateCurrentCompoundID()
    self:DispatchEvent("compound_group1_changed", {group1 = group1})
end

-- 选择二级分组
function compoundMainData:SelectGroup2(group2)
    self._currentGroup2 = group2
    self:_updateCurrentCompoundID()
    self:DispatchEvent("compound_group2_changed", {group2 = group2})
end

-- 获取当前合成配置
function compoundMainData:GetCurrentCompoundConfig()
    if self._currentCompoundID > 0 then
        return Compound[self._currentCompoundID]
    end
    return nil
end

-- 获取当前选中ID
function compoundMainData:GetCurrentCompoundID()
    return self._currentCompoundID
end

-- 获取消耗材料列表
function compoundMainData:GetCostItems(config)
    local items = {}
    if config.CostItem1 and config.CostItem1 > 0 then
        table.insert(items, {
            itemID = config.CostItem1,
            count = config.CostItemCount1,
        })
    end
    if config.CostItem2 and config.CostItem2 > 0 then
        table.insert(items, {
            itemID = config.CostItem2,
            count = config.CostItemCount2,
        })
    end
    if config.CostItem3 and config.CostItem3 > 0 then
        table.insert(items, {
            itemID = config.CostItem3,
            count = config.CostItemCount3,
        })
    end
    return items
end

-- 获取货币消耗
function compoundMainData:GetCurrencyCost(config)
    return {
        type = config.CostCurrencyType,
        count = config.CostCurrencyCount,
    }
end

-- 请求合成
function compoundMainData:RequestCompound(compoundID)
    if not compoundID or compoundID <= 0 then
        return
    end
    
    local config = Compound[compoundID]
    if not config then
        return
    end
    
    -- 使用武勋相同的网络请求方式
    ssrMessage:sendmsgEx("compound", "CompoundRequest", {compoundID = compoundID})
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
