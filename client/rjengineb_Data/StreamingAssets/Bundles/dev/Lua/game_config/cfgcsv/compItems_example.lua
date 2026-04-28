--- 合成页面处理示例
--- 演示如何使用compItems_handler.lua

-- 加载配置和处理逻辑
local compItemsConfig = require("game_config.cfgcsv.compItems")
local CompItemsHandler = require("game_config.cfgcsv.compItems_handler")

--- 示例1: 解析菜单结构
function Example_PrintMenuStructure()
    print("========== 示例1: 打印菜单树结构 ==========")

    local menuTree = CompItemsHandler.ParseMenuStructure(compItemsConfig)
    -- PrintMenuTree 已删除，此处仅解析
end

--- 示例2: 解析单个配置项的payItems和payCost
function Example_ParseSingleItem()
    print("\n========== 示例2: 解析单个配置项 ==========")
    
    local item = compItemsConfig[1]
    print("物品: " .. item.itemName)
    print("菜单: " .. item.menus)
    
    local payItems = CompItemsHandler.ParsePayItems(item.payItems)
    print("所需物品:")
    for i, option in ipairs(payItems) do
        print("  选项" .. i .. ":")
        for _, material in ipairs(option) do
            print("    物品ID: " .. material.itemId .. ", 数量: " .. material.count)
        end
    end
    
    local payCost = CompItemsHandler.ParsePayCost(item.payCost)
    print("所需消耗:")
    for i, cost in ipairs(payCost) do
        print("  选项" .. i .. ": 货币类型=" .. cost.costType .. ", 数量=" .. cost.amount)
    end
end

--- 示例3: 完整的配置处理流程
function Example_FullProcess()
    print("\n========== 示例3: 完整处理流程 ==========")
    
    local menuTree = CompItemsHandler.ProcessConfig(compItemsConfig)
    
    -- 遍历处理后的完整数据
    for _, level1 in ipairs(menuTree) do
        print("一级菜单: " .. level1.name)
        
        for _, level2 in ipairs(level1.children) do
            print("  二级菜单: " .. level2.name)
            
            for _, item in ipairs(level2.children) do
                print("    合成项: " .. item.itemName)
                print("      物品ID: " .. item.itemId)
                print("      所需物品选项数: " .. #item.parsedPayItems)
                print("      所需消耗选项数: " .. #item.parsedPayCost)
            end
        end
    end
end

--- 示例4: 获取特定菜单路径下的所有合成项
function Example_GetSpecificMenu()
    print("\n========== 示例4: 获取特定菜单路径 ==========")
    
    local menuTree = CompItemsHandler.ParseMenuStructure(compItemsConfig)
    
    -- 查找"普通合成 > 强化石一"下的所有物品
    local targetLevel1 = "普通合成"
    local targetLevel2 = "强化石一"
    
    for _, level1 in ipairs(menuTree) do
        if level1.name == targetLevel1 then
            for _, level2 in ipairs(level1.children) do
                if level2.name == targetLevel2 then
                    print("找到 [" .. targetLevel1 .. " > " .. targetLevel2 .. "]:")
                    for _, item in ipairs(level2.children) do
                        print("  - " .. item.itemName .. " (ID: " .. item.itemId .. ")")
                    end
                end
            end
        end
    end
end

--- 示例5: 统计信息
function Example_Statistics()
    print("\n========== 示例5: 统计信息 ==========")
    
    local menuTree = CompItemsHandler.ParseMenuStructure(compItemsConfig)
    
    local totalLevel1 = #menuTree
    local totalLevel2 = 0
    local totalItems = 0
    
    for _, level1 in ipairs(menuTree) do
        totalLevel2 = totalLevel2 + #level1.children
        for _, level2 in ipairs(level1.children) do
            totalItems = totalItems + #level2.children
        end
    end
    
    print("一级菜单数量: " .. totalLevel1)
    print("二级菜单数量: " .. totalLevel2)
    print("合成项总数: " .. totalItems)
end

-- 运行所有示例
print("===== 合成页面处理示例 =====\n")
Example_PrintMenuStructure()
Example_ParseSingleItem()
Example_FullProcess()
Example_GetSpecificMenu()
Example_Statistics()
