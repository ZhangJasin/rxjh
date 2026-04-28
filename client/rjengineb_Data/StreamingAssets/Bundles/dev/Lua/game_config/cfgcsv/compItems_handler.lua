--- 合成页面处理逻辑
--- 负责解析compItems.lua配置并组装成三级菜单结构

local CompItemsHandler = {}

--- 解析配置数据,组装成三级菜单结构
-- @param configTable 原始配置表 (compItems.lua)
-- @return 三级菜单结构的数组
function CompItemsHandler.ParseMenuStructure(configTable)
    -- 存储三级菜单结构
    -- 结构: {
    --   name = "一级菜单名",
    --   children = {
    --     name = "二级菜单名",
    --     children = { 配置项数组 }
    --   }
    -- }
    local menuTree = {}
    local menuMap = {} -- 用于快速查找已存在的菜单节点
    
    -- 遍历所有配置项
    for _, itemConfig in pairs(configTable) do
        -- 解析menus字段
        local menus = CompItemsHandler.SplitString(itemConfig.menus, "#")
        
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
            
            -- 添加配置项到二级菜单下(这就是第三级)
            table.insert(level2Node.children, itemConfig)
        end
    end
    
    -- 清理临时用的childMap(不需要暴露给外部)
    for _, level1Node in ipairs(menuTree) do
        level1Node.childMap = nil
    end
    
    return menuTree
end

--- 解析payItems字段
-- @param payItemsStr payItems字符串,如 "656#20|657#40#658#80"
-- @return 解析后的数组 {{itemId, count}, ...}
function CompItemsHandler.ParsePayItems(payItemsStr)
    if not payItemsStr or payItemsStr == "" then
        return {}
    end
    
    local result = {}
    
    -- 先按 | 分割不同选项
    local options = CompItemsHandler.SplitString(payItemsStr, "|")
    
    for _, optionStr in ipairs(options) do
        -- 每个选项内按 # 分割
        local parts = CompItemsHandler.SplitString(optionStr, "#")
        
        local option = {}
        for i = 1, #parts, 2 do
            local itemId = tonumber(parts[i]) or 0
            local count = tonumber(parts[i + 1]) or 0
            table.insert(option, {
                itemId = itemId,
                count = count
            })
        end
        
        table.insert(result, option)
    end
    
    return result
end

--- 解析payCost字段
-- @param payCostStr payCost字符串,如 "1#400|2#20"
-- @return 解析后的数组 {{costType, amount}, ...}
function CompItemsHandler.ParsePayCost(payCostStr)
    if not payCostStr or payCostStr == "" then
        return {}
    end
    
    local result = {}
    
    -- 按 | 分割不同选项
    local options = CompItemsHandler.SplitString(payCostStr, "|")
    
    for _, optionStr in ipairs(options) do
        -- 每个选项内按 # 分割
        local parts = CompItemsHandler.SplitString(optionStr, "#")
        
        local costType = tonumber(parts[1]) or 0
        local amount = tonumber(parts[2]) or 0
        
        table.insert(result, {
            costType = costType,
            amount = amount
        })
    end
    
    return result
end

--- 字符串分割辅助函数
-- @param str 要分割的字符串
-- @param separator 分隔符
-- @return 分割后的数组
function CompItemsHandler.SplitString(str, separator)
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

--- 完整的配置处理流程
-- @param configTable 原始配置表
-- @return 处理后的完整配置数据
function CompItemsHandler.ProcessConfig(configTable)
    -- 1. 解析菜单结构
    local menuTree = CompItemsHandler.ParseMenuStructure(configTable)
    
    -- 2. 为每个配置项解析payItems和payCost
    for _, level1 in ipairs(menuTree) do
        for _, level2 in ipairs(level1.children) do
            for _, item in ipairs(level2.children) do
                item.parsedPayItems = CompItemsHandler.ParsePayItems(item.payItems)
                item.parsedPayCost = CompItemsHandler.ParsePayCost(item.payCost)
            end
        end
    end
    
    return menuTree
end

return CompItemsHandler
