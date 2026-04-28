# 合成页面处理逻辑使用说明

## 文件说明

1. **compItems.lua** - 原始配置文件(已存在)
2. **compItems_handler.lua** - 处理逻辑模块(新增)
3. **compItems_example.lua** - 使用示例(新增)

## 数据结构

### 原始配置格式
```lua
[1] = {
    index = 1,
    itemId = 1307,
    itemName = "金刚石(攻击)",
    menus = "普通合成#强化石一",  -- 用#分隔菜单层级
    payItems = "656#20|657#40#658#80",  -- |分隔选项,#分隔物品和数量
    payCost = "1#400|2#20",  -- |分隔选项,#分隔货币类型和数量
}
```

### 处理后的三级菜单结构
```lua
{
    name = "普通合成",  -- 一级菜单
    children = {
        {
            name = "强化石一",  -- 二级菜单
            children = {  -- 三级:具体合成项
                { itemId=1307, itemName="金刚石(攻击)", ... },
                { itemId=1308, itemName="金刚石(追伤)", ... },
            }
        }
    }
}
```

## 使用方法

### 基础使用

```lua
local CompItemsHandler = require("game_config.cfgcsv.compItems_handler")
local compItemsConfig = require("game_config.cfgcsv.compItems")

-- 1. 解析菜单结构
local menuTree = CompItemsHandler.ParseMenuStructure(compItemsConfig)

-- 2. 解析单个配置项的材料和消耗
local payItems = CompItemsHandler.ParsePayItems(item.payItems)
local payCost = CompItemsHandler.ParsePayCost(item.payCost)
```

### 完整处理流程

```lua
-- 一次性处理所有配置(包括菜单结构和材料/消耗解析)
local menuTree = CompItemsHandler.ProcessConfig(compItemsConfig)

-- 遍历结果
for _, level1 in ipairs(menuTree) do
    print("一级菜单: " .. level1.name)
    for _, level2 in ipairs(level1.children) do
        print("  二级菜单: " .. level2.name)
        for _, item in ipairs(level2.children) do
            print("    合成项: " .. item.itemName)
            -- item.parsedPayItems 和 item.parsedPayCost 已解析完成
        end
    end
end
```

### 查找特定菜单路径

```lua
-- 查找"普通合成 > 强化石一"下的所有物品
for _, level1 in ipairs(menuTree) do
    if level1.name == "普通合成" then
        for _, level2 in ipairs(level1.children) do
            if level2.name == "强化石一" then
                -- level2.children 就是该路径下的所有合成项
                for _, item in ipairs(level2.children) do
                    print(item.itemName)
                end
            end
        end
    end
end
```

## API 说明

### CompItemsHandler.ParseMenuStructure(configTable)
解析配置数据,组装成三级菜单结构

**参数:**
- `configTable`: 原始配置表(compItems.lua)

**返回:**
- 三级菜单结构的数组

### CompItemsHandler.ParsePayItems(payItemsStr)
解析payItems字段

**参数:**
- `payItemsStr`: payItems字符串,如 `"656#20|657#40#658#80"`

**返回:**
- `{{itemId=656, count=20}, {itemId=657, count=40}, ...}`

### CompItemsHandler.ParsePayCost(payCostStr)
解析payCost字段

**参数:**
- `payCostStr`: payCost字符串,如 `"1#400|2#20"`

**返回:**
- `{{costType=1, amount=400}, {costType=2, amount=20}}`

### CompItemsHandler.ProcessConfig(configTable)
完整的配置处理流程(菜单结构 + 材料/消耗解析)

**参数:**
- `configTable`: 原始配置表

**返回:**
- 处理后的完整配置数据

### CompItemsHandler.PrintMenuTree(menuTree, indent)
打印菜单树结构(调试用)

**参数:**
- `menuTree`: 菜单树
- `indent`: 缩进级别

## 运行示例

直接运行示例文件查看效果:
```lua
require("game_config.cfgcsv.compItems_example")
```

示例包含5个演示:
1. 打印完整菜单树结构
2. 解析单个配置项
3. 完整处理流程
4. 获取特定菜单路径
5. 统计信息

## 注意事项

1. **menus字段**: 必须至少有2级(用#分隔),否则会被跳过
2. **合并同类项**: 相同菜单路径的配置项会自动合并到同一节点下
3. **索引清理**: 临时使用的childMap会在解析完成后自动清理
4. **空值处理**: ParsePayItems和ParsePayCost会自动处理空字符串
