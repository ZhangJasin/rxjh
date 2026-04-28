--- 合成页面数据处理模块
--- 负责解析compItems.lua配置并组装成三级菜单结构
--- 放置在FGUILayout/A_Compound目录下,专门服务于合成界面

local CompoundDataProcessor = {}

-- 加载配置表
local CompItems = SL:RequireFile("game_config/cfgcsv/compItems")
local ItemConfig = SL:GetValue("ITEM_CONFIG") or require("game_config/cfgcsv/Item")

--- 字符串分割函数
-- @param str 要分割的字符串
-- @param separator 分隔符
-- @return 分割后的数组
function CompoundDataProcessor.SplitString(str, separator)
    local result = {}
    if str then
        local start = 1
        local separatorEnd = string.find(str, separator, start)
        
        while separatorEnd do
            table.insert(result, string.sub(str, start, separatorEnd - 1))
            start = separatorEnd + 1
            separatorEnd = string.find(str, separator, start)
        end
        
        table.insert(result, string.sub(str, start))
    end
    return result
end

--- 解析配置数据,组装成三级菜单结构
-- @param configTable 原始配置表 (compItems.lua)
-- @return 三级菜单结构的数组
-- 结构示例:
-- {
--   {
--     name = "普通合成",  -- 一级菜单
--     children = {
--       {
--         name = "强化石一",  -- 二级菜单
--         children = { 配置项数组 }  -- 三级菜单
--       }
--     }
--   }
-- }
function CompoundDataProcessor.ParseMenuStructure(configTable)
    local menuTree = {}
    local menuMap = {} -- 用于快速查找已存在的菜单节点
    
    -- 遍历所有配置项
    for _, itemConfig in pairs(configTable) do
        -- 解析menus字段
        local menus = CompoundDataProcessor.SplitString(itemConfig.menus, "#")
        
        if #menus >= 2 then
            local level1Name = menus[1]
            local level2Name = menus[2]
            
            -- 查找或创建一级菜单
            local level1Node = menuMap[level1Name]
            if not level1Node then
                level1Node = {
                    name = level1Name,
                    children = {},
                    childMap = {} -- 用于快速查找二级菜单
                }
                menuMap[level1Name] = level1Node
                table.insert(menuTree, level1Node)
            end
            
            -- 查找或创建二级菜单
            local level2Node = level1Node.childMap[level2Name]
            if not level2Node then
                level2Node = {
                    name = level2Name,
                    children = {}
                }
                level1Node.childMap[level2Name] = level2Node
                table.insert(level1Node.children, level2Node)
            end
            
            -- 解析完整物品数据
            local itemData = CompoundDataProcessor.ParseItemData(itemConfig)
            
            -- 添加配置项到二级菜单下(这就是第三级)
            table.insert(level2Node.children, itemData)
        end
    end
    
    -- 清理临时用的childMap(不需要暴露给外部)
    for _, level1Node in ipairs(menuTree) do
        level1Node.childMap = nil
    end
    
    -- 排序处理
    CompoundDataProcessor.SortMenuTree(menuTree)
    
    return menuTree
end

--- 解析单个物品的完整数据
-- @param itemConfig 单个物品配置
-- @return 解析后的物品数据
function CompoundDataProcessor.ParseItemData(itemConfig)
    return {
        index = itemConfig.index,
        itemId = itemConfig.itemId,
        itemName = itemConfig.itemName or "",
        menus = itemConfig.menus or "",
        payItems = CompoundDataProcessor.ParsePayData(itemConfig.payItems),
        payCost = CompoundDataProcessor.ParsePayData(itemConfig.payCost),
        sect = itemConfig.sect or 0,
    }
end

--- 解析payItems/payCost字段
-- @param payStr 支付数据字符串,格式: "道具ID#数量|道具ID#数量"
-- @return 解析后的数组 {{id=xxx, count=xxx}, ...}
function CompoundDataProcessor.ParsePayData(payStr)
    local result = {}
    if not payStr or payStr == "" then
        return result
    end

    local items = CompoundDataProcessor.SplitString(payStr, "|")
    for _, item in ipairs(items) do
        local parts = CompoundDataProcessor.SplitString(item, "#")
        local id = tonumber(parts[1]) or 0
        local count = tonumber(parts[2]) or 0
        if id > 0 and count > 0 then
            table.insert(result, {id = id, count = count})
        end
    end
    return result
end

--- 对菜单树进行排序
-- @param menuTree 菜单树
function CompoundDataProcessor.SortMenuTree(menuTree)
    -- 对一级菜单按名称排序
    table.sort(menuTree, function(a, b)
        return a.name < b.name
    end)
    
    -- 对二级菜单按名称排序
    for _, level1 in ipairs(menuTree) do
        table.sort(level1.children, function(a, b)
            return a.name < b.name
        end)
        
        -- 对三级物品按index排序
        for _, level2 in ipairs(level1.children) do
            table.sort(level2.children, function(a, b)
                return a.index < b.index
            end)
        end
    end
end

--- 将菜单树转换为compoundMainData需要的格式
-- @param menuTree 菜单树
-- @return {group1List, group2Map, itemsMap}
function CompoundDataProcessor.ConvertToDataFormat(menuTree)
    local group1List = {}
    local group2Map = {}
    local itemsMap = {}
    
    for _, level1 in ipairs(menuTree) do
        table.insert(group1List, level1.name)
        group2Map[level1.name] = {}
        
        for _, level2 in ipairs(level1.children) do
            table.insert(group2Map[level1.name], level2.name)
            
            local key = level1.name .. "." .. level2.name
            itemsMap[key] = level2.children
        end
    end
    
    return {
        group1List = group1List,
        group2Map = group2Map,
        itemsMap = itemsMap
    }
end

--- 完整的处理流程
-- @return 处理后的完整配置数据
function CompoundDataProcessor.ProcessAll()
    -- 1. 解析菜单结构
    local menuTree = CompoundDataProcessor.ParseMenuStructure(CompItems)
    
    -- 2. 转换为compoundMainData需要的格式
    local dataFormat = CompoundDataProcessor.ConvertToDataFormat(menuTree)
    
    return {
        menuTree = menuTree,
        dataFormat = dataFormat
    }
end

--- 调试用:打印菜单树结构
-- @param menuTree 菜单树
-- @param indent 缩进级别
function CompoundDataProcessor.PrintMenuTree(menuTree, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    
    for _, level1 in ipairs(menuTree) do
        print(indentStr .. "Level 1: " .. level1.name)
        
        for _, level2 in ipairs(level1.children) do
            print(indentStr .. "  Level 2: " .. level2.name)
            
            for _, item in ipairs(level2.children) do
                print(indentStr .. "    Item: " .. item.itemName .. " (ID: " .. item.itemId .. ")")
                print(indentStr .. "      消耗道具: " .. #item.payItems .. "项")
                print(indentStr .. "      消耗货币: " .. #item.payCost .. "项")
            end
        end
    end
end

return CompoundDataProcessor
