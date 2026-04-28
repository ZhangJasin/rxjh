# 合成页面实现说明

## 文件结构

```
Lua/FGUILayout/A_Compound/
├── compoundMain.lua          # UI控制层(界面交互)
├── compoundMainData.lua      # 数据层(状态管理)
└── CompoundDataProcessor.lua # 数据处理层(配置解析)
```

## 架构说明

### 1. CompoundDataProcessor.lua (数据处理层)
**职责:** 解析compItems.lua配置文件,组装成三级菜单结构

**核心功能:**
- ✅ 拆分menus字段(按`#`分隔符)
- ✅ 合并同类菜单项
- ✅ 组装三级树形结构
- ✅ 解析payItems/payCost字段
- ✅ 排序处理(一级→二级→三级)

**主要方法:**
```lua
-- 解析完整菜单结构
menuTree = CompoundDataProcessor.ParseMenuStructure(configTable)

-- 解析单个物品数据
itemData = CompoundDataProcessor.ParseItemData(itemConfig)

-- 解析支付数据(道具/货币)
payData = CompoundDataProcessor.ParsePayData(payStr)

-- 完整处理流程
processedData = CompoundDataProcessor.ProcessAll()
-- 返回: {menuTree, dataFormat}
```

### 2. compoundMainData.lua (数据层)
**职责:** 管理界面状态,提供数据查询接口

**核心数据:**
```lua
self._menuTree = {}          -- 完整三级菜单树
self._group1List = {}        -- 一级菜单列表
self._group2Map = {}         -- 二级菜单映射
self._itemsMap = {}          -- 物品映射
self._currentGroup1 = ""     -- 当前一级菜单
self._currentGroup2 = ""     -- 当前二级菜单
self._currentItem = nil      -- 当前选中物品
self._group2OpenState = {}   -- 二级菜单展开状态
```

**主要方法:**
```lua
-- 获取一级菜单列表
group1List = self:GetGroup1List()

-- 获取二级菜单列表
group2List = self:GetGroup2List(group1)

-- 获取物品列表
itemList = self:GetItemList(group1, group2)

-- 选择一级菜单(自动重置二级和物品)
self:SelectGroup1(group1)

-- 切换二级菜单展开/折叠
self:ToggleGroup2Open(group2Name)

-- 判断二级菜单是否展开
isOpen = self:IsGroup2Open(group2Name)

-- 选择物品
self:SelectItem(index, item)
```

### 3. compoundMain.lua (控制层)
**职责:** UI交互,界面刷新,菜单联动

**核心功能:**
- ✅ 一级菜单列表渲染
- ✅ 二级+三级混合列表渲染(折叠/展开)
- ✅ 菜单联动逻辑(切换一级→刷新二级→选中物品)
- ✅ 消耗道具/货币显示
- ✅ 调试信息打印

**菜单联动流程:**
```
用户点击一级菜单
  ↓
data:SelectGroup1(group1)  ← 切换数据状态
  ↓
RefreshUI()                ← 刷新整个界面
  ├─ RefreshGroup1List()   ← 刷新一级列表选中状态
  ├─ RefreshMixedList()    ← 刷新混合列表(二级+三级)
  └─ RefreshContent()      ← 刷新物品详情(消耗等)
```

## 数据流转

### 配置解析流程
```
compItems.lua (原始配置)
    ↓
CompoundDataProcessor.ProcessAll()
    ↓
{
    menuTree: 三级菜单树,
    dataFormat: {group1List, group2Map, itemsMap}
}
    ↓
compoundMainData._initFromConfig()
    ↓
数据存储到各成员变量
```

### 用户交互流程
```
用户点击一级菜单项
    ↓
compoundMain: 触发onClick事件
    ↓
data:SelectGroup1(group1)
    ├─ 重置二级菜单为第一个
    ├─ 重置物品为第一个
    └─ 重置展开状态
    ↓
compoundMain:RefreshUI()
    ├─ 刷新一级列表显示
    ├─ 刷新混合列表显示
    └─ 刷新物品详情显示
```

## 混合列表实现

### 设计思路(参考minimap)
将二级菜单标题和三级菜单项混合到一个列表中显示:

```
[强化石一]        ← 二级菜单标题(可点击展开/折叠)
  ├─ 金刚石(攻击)  ← 三级菜单项(展开后可见)
  ├─ 金刚石(追伤)
  └─ 金刚石(武功)
[强化石二]        ← 二级菜单标题(折叠状态)
```

### 行索引计算
```lua
-- 遍历二级菜单,计算总行数
for each group2:
    rowIdx++                      -- 二级标题行
    if group2 is open:
        rowIdx += itemCount       -- 三级项行
```

### 点击处理
```lua
-- 根据点击的index判断类型
info = _getMixedItemInfo(index)
if info.type == "group":
    _toggleGroup2(group2Name)     -- 切换展开/折叠
elseif info.type == "item":
    data:SelectItem(item)         -- 选中物品
```

## 扩展指南

### 添加新的消耗显示组件

1. 在FGUI中创建组件(如n50)
2. 在`_RefreshPayItems`或`_RefreshPayCost`中添加刷新逻辑:

```lua
function compoundMain:_RefreshPayItems(payItems)
    -- ... 现有代码 ...
    
    -- 新增: 刷新道具列表显示
    if self._ui.n50 then
        local text = ""
        for i, payItem in ipairs(payItems) do
            local itemName = GetItemName(payItem.id)
            text = text .. string.format("%s x%d\n", itemName, payItem.count)
        end
        FGUI:GTextField_setText(self._ui.n50, text)
    end
end
```

### 添加合成预览功能

```lua
function compoundMain:_RefreshCompoundPreview(item)
    -- 显示合成后的物品图标/名称/属性等
    if self._ui.previewIcon then
        -- 设置图标
    end
    if self._ui.previewName then
        FGUI:GTextField_setText(self._ui.previewName, item.itemName)
    end
end
```

### 添加合成按钮点击事件

```lua
function compoundMain:Create()
    -- ... 现有代码 ...
    
    -- 合成按钮
    if self._ui.btnCompound then
        FGUI:setOnClickEvent(self._ui.btnCompound, function()
            self:OnCompoundButtonClick()
        end)
    end
end

function compoundMain:OnCompoundButtonClick()
    local item = self._data:GetCurrentItem()
    if not item then
        print("请先选择要合成的物品")
        return
    end
    
    -- TODO: 检查材料是否足够
    -- TODO: 发送合成请求到服务器
    -- TODO: 处理合成结果
end
```

## 调试技巧

### 1. 查看菜单结构
打开界面时会自动打印:
```
[合成] === 菜单结构 ===
  1. 普通合成 (一级)
     1.1 强化石一 [展开] (二级) - 3个物品
     1.2 强化石二 [折叠] (二级) - 5个物品
```

### 2. 查看选中物品信息
```
========================================
[合成] 当前选中物品: 金刚石(攻击) ID: 1307
[合成] 菜单路径: 普通合成#强化石一
[合成] 消耗道具列表:
  选项1: [铁矿石] x20 (ID:656)
[合成] 消耗货币列表:
  选项1: [银两] x400 (类型:1)
========================================
```

### 3. 手动调试
```lua
-- 在控制台执行
local main = FGUI:GetUI("A_Compound", "compoundMain")
main:_PrintMenuStructure()

-- 查看当前选中
local info = main:GetCurrentPathInfo()
print(info.level1, info.level2, info.item.itemName)

-- 通过物品ID选中
main:SelectItemById(1307)
```

## 注意事项

1. **配置文件格式**: menus字段必须至少有2级(用`#`分隔)
2. **分隔符**: `#`用于字段内分隔,`|`用于选项分隔
3. **排序**: 一级/二级菜单按名称排序,物品按index排序
4. **展开状态**: 切换一级菜单时会重置所有二级菜单的展开状态
5. **默认选中**: 初始化时默认选中第一个一级菜单下的第一个二级菜单的第一个物品

## TODO

- [ ] 实现材料充足检查
- [ ] 实现合成请求/响应
- [ ] 添加合成动画/特效
- [ ] 添加道具/货币图标
- [ ] 优化列表滚动性能
- [ ] 添加搜索/筛选功能
