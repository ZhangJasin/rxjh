local compoundMainData = class("compoundMainData")

-- 配置表
local CompItems = SL:RequireFile("game_config/cfgcsv/compItems")
local ItemConfig = SL:GetValue("ITEM_CONFIG") or require("game_config/cfgcsv/Item")
local CompoundDataProcessor = SL:RequireFile("FGUILayout/A_Compound/CompoundDataProcessor")

-- 单例
local instance = nil
function compoundMainData:getInstance()
    if not instance then
        instance = compoundMainData:new()
    end
    return instance
end

function compoundMainData:ctor()
    self._group1List = {}       -- 一级分组列表
    self._group2Map = {}        -- 二级分组映射 (key: 一级分组, value: 二级分组列表)
    self._itemsMap = {}         -- 物品映射 (key: 一级.二级, value: 物品列表)
    self._currentGroup1 = ""    -- 当前选中的一级分组
    self._currentGroup2 = ""    -- 当前选中的二级分组
    self._currentItem = nil     -- 当前选中的物品
    self._currentItemIndex = 1  -- 当前选中的物品索引
    self._group2OpenState = {}  -- 二级菜单展开状态 (key: 二级分组名称, value: boolean)
    self._menuTree = {}         -- 三级菜单树结构(用于完整的数据访问)

    self:_initFromConfig()
end

-- 从配置表初始化数据(使用CompoundDataProcessor处理)
function compoundMainData:_initFromConfig()
    -- 使用CompoundDataProcessor处理配置
    local processedData = CompoundDataProcessor.ProcessAll()
    
    -- 保存完整的菜单树
    self._menuTree = processedData.menuTree
    
    -- 使用转换后的数据格式
    local dataFormat = processedData.dataFormat
    self._group1List = dataFormat.group1List
    self._group2Map = dataFormat.group2Map
    self._itemsMap = dataFormat.itemsMap

    -- 默认选中第一个
    if #self._group1List > 0 then
        self._currentGroup1 = self._group1List[1]
        local g2List = self:GetGroup2List(self._currentGroup1)
        if #g2List > 0 then
            self._currentGroup2 = g2List[1]
            local itemList = self:GetItemList(self._currentGroup1, self._currentGroup2)
            if #itemList > 0 then
                self._currentItem = itemList[1]
                self._currentItemIndex = 1
            end

            -- 默认展开第一个二级菜单
            self._group2OpenState[self._currentGroup2] = true
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

-- 获取物品列表
-- @param group1 一级分组名称
-- @param group2 二级分组名称
function compoundMainData:GetItemList(group1, group2)
    local key = group1 .. "." .. group2
    return self._itemsMap[key] or {}
end

-- 选择一级分组
-- 切换一级菜单时，二级菜单重置为第一个，物品选中第一个
function compoundMainData:SelectGroup1(group1)
    self._currentGroup1 = group1
    local g2List = self:GetGroup2List(group1)
    
    -- 重置所有二级菜单的展开状态
    self._group2OpenState = {}
    
    if #g2List > 0 then
        self._currentGroup2 = g2List[1]
        local itemList = self:GetItemList(group1, self._currentGroup2)
        if #itemList > 0 then
            self._currentItem = itemList[1]
            self._currentItemIndex = 1
        else
            self._currentItem = nil
            self._currentItemIndex = 1
        end
        
        -- 默认展开第一个二级菜单
        self._group2OpenState[self._currentGroup2] = true
    else
        self._currentGroup2 = ""
        self._currentItem = nil
        self._currentItemIndex = 1
    end
end

-- 选择二级分组
-- 切换二级菜单时，物品重置为第一个
function compoundMainData:SelectGroup2(group2)
    self._currentGroup2 = group2
    local itemList = self:GetItemList(self._currentGroup1, group2)
    if #itemList > 0 then
        self._currentItem = itemList[1]
        self._currentItemIndex = 1
    else
        self._currentItem = nil
        self._currentItemIndex = 1
    end
end

-- 选择物品
function compoundMainData:SelectItem(index, item)
    self._currentItemIndex = index
    self._currentItem = item
end

-- 获取当前选中的物品
function compoundMainData:GetCurrentItem()
    return self._currentItem
end

-- 获取当前选中的物品索引
function compoundMainData:GetCurrentItemIndex()
    return self._currentItemIndex
end

-- 切换二级菜单的展开/折叠状态
-- @param group2Name 二级分组名称
function compoundMainData:ToggleGroup2Open(group2Name)
    local currentState = self._group2OpenState[group2Name] or false
    
    if currentState then
        -- 收起：关闭当前二级菜单，清理三级菜单选中状态
        self._group2OpenState[group2Name] = false
        self._currentItem = nil
        self._currentItemIndex = 1
    else
        -- 展开：关闭其他二级菜单，展开当前二级菜单
        -- 先关闭所有其他展开的二级菜单
        for k, v in pairs(self._group2OpenState) do
            if k ~= group2Name and v then
                self._group2OpenState[k] = false
            end
        end
        
        self._group2OpenState[group2Name] = true
        self._currentGroup2 = group2Name
        
        -- 自动选中该二级菜单下的第一个物品
        local itemList = self:GetItemList(self._currentGroup1, group2Name)
        if #itemList > 0 then
            self._currentItem = itemList[1]
            self._currentItemIndex = 1
        end
    end
end

-- 获取二级菜单的展开状态
-- @param group2Name 二级分组名称
-- @return boolean 是否展开
function compoundMainData:IsGroup2Open(group2Name)
    return self._group2OpenState[group2Name] or false
end

-- 获取所有二级菜单的展开状态（用于刷新列表时遍历）
function compoundMainData:GetAllGroup2OpenState()
    return self._group2OpenState
end

return compoundMainData
