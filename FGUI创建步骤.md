# FGUI界面创建步骤指南

## 📦 已为您创建的文件结构

```
9963d_rxjh_fgui_project/assets/
├── A_Compound/                      ✅ 已创建
│   ├── Components/                   ✅ 目录已创建
│   ├── Images/                       ✅ 目录已创建
│   └── package.xml                   ✅ 配置文件已创建
│
└── A_Compound_PC/                   ✅ 已创建
    ├── Components/                   ✅ 目录已创建
    ├── Images/                       ✅ 目录已创建
    └── package.xml                   ✅ 配置文件已创建
```

## 🎯 FGUI创建步骤 (需要手动操作)

### 步骤1: 打开FairyGUI编辑器

1. 启动 FairyGUI 编辑器
2. 文件 → 打开项目
3. 选择: `9963d_rxjh_fgui_project/9963d_rxjh_fgui_project.fairy`

### 步骤2: 创建A_Compound包

#### 2.1 新建包
1. 点击"新建包"按钮
2. 包名称: `A_Compound`
3. 包路径: `9963d_rxjh_fgui_project/assets/A_Compound`
4. 点击"确定"

#### 2.2 创建主界面 compoundMain

**右键 → 新建组件 → compoundMain**

**界面尺寸**: 1334x750

**添加以下组件**(按层级):

```
compoundMain (1334x750)
├─ bg (GComponent)                背景
│   └─ 引用: CommonBg
├─ btn_close (GComponent)         关闭按钮
│   └─ 引用: btn_close
├─ title (GTextField)             标题"合成"
├─ list_group1 (GList)            一级分组列表
│   └─ defaultItem: btn_group1
├─ list_group2 (GList)            二级分组列表
│   └─ defaultItem: btn_group2
├─ cost_items_container (GComponent)  材料容器
├─ target_icon (GImage)           目标道具图标
├─ target_count (GTextField)      目标数量
├─ currency_cost_panel (GComponent)   货币面板
├─ txt_success_rate (GTextField)  成功率文本
└─ btn_compound (GButton)         合成按钮
```

**组件详细设置**:

1. **bg**
   - 类型: Component
   - 源: 从Common包引用CommonBg
   - 位置: 667,375 (中心)
   - 大小: 1000x650
   - 锚点: 0.5,0.5

2. **btn_close**
   - 类型: Component
   - 源: 从Common包引用btn_close
   - 位置: 1135,78

3. **title**
   - 类型: TextField
   - 文本: "合 成"
   - 字体大小: 28
   - 颜色: #ffffff
   - 位置: 667,60
   - 对齐: 居中

4. **list_group1**
   - 类型: List
   - 位置: 50,120
   - 大小: 200x100
   - 滚动: 垂直
   - 行间距: 5

5. **list_group2**
   - 类型: List
   - 位置: 50,240
   - 大小: 200x400
   - 滚动: 垂直
   - 行间距: 5

6. **cost_items_container**
   - 类型: Component
   - 位置: 350,180
   - 大小: 600x300

7. **target_icon**
   - 类型: Image
   - 位置: 550,550
   - 大小: 80x80

8. **target_count**
   - 类型: TextField
   - 位置: 640,590
   - 文本: "×1"
   - 字体大小: 20

9. **currency_cost_panel**
   - 类型: Component
   - 位置: 350,650
   - 大小: 600x50

10. **txt_success_rate**
    - 类型: TextField
    - 位置: 550,620
    - 文本: "成功率:100%"
    - 颜色: #00ff00

11. **btn_compound**
    - 类型: Button
    - 位置: 550,660
    - 大小: 200x50
    - 标题: "合 成"

#### 2.3 创建CostItem组件

**右键 → 新建组件 → CostItem**

**界面尺寸**: 580x100

```
CostItem (580x100)
├─ bg (GGraph)                    背景
├─ icon (GImage)                  道具图标
├─ txt_need (GTextField)          需要数量
└─ txt_have (GTextField)          拥有数量
```

**详细设置**:

1. **bg**
   - 类型: Graph (矩形)
   - 大小: 580x100
   - 填充颜色: #1a1a2e
   - 边框: 无

2. **icon**
   - 类型: Image
   - 位置: 10,10
   - 大小: 80x80

3. **txt_need**
   - 类型: TextField
   - 位置: 100,50
   - 文本: "需要:5"
   - 颜色: #ffd700

4. **txt_have**
   - 类型: TextField
   - 位置: 300,50
   - 文本: "拥有:3/5"
   - 颜色: #00ff00

#### 2.4 创建CurrencyCost组件

**右键 → 新建组件 → CurrencyCost**

**界面尺寸**: 580x50

```
CurrencyCost (580x50)
├─ icon (GImage)                  货币图标
└─ txt_cost (GTextField)          货币数量
```

**详细设置**:

1. **icon**
   - 类型: Image
   - 位置: 10,5
   - 大小: 40x40

2. **txt_cost**
   - 类型: TextField
   - 位置: 60,10
   - 文本: "561万/2.00万"
   - 颜色: #ffd700

### 步骤3: 创建PC端 A_Compound_PC

**方法**: 复制A_Compound包

1. 在FairyGUI编辑器中
2. 右键 A_Compound 包 → 复制包
3. 重命名为: `A_Compound_PC`
4. 调整界面尺寸适配PC端
5. 修改组件名称: `compoundMain` → `compoundMain_PC`

### 步骤4: 发布资源

#### 4.1 移动端发布
1. 选中 `A_Compound` 包
2. 点击"发布"按钮
3. 设置:
   - 发布格式: **Lua**
   - 发布路径: `client/rjengineb_Data/StreamingAssets/Bundles/dev/`
   - 包文件扩展名: `.bytes`
4. 点击"发布"

#### 4.2 PC端发布
1. 选中 `A_Compound_PC` 包
2. 点击"发布"按钮
3. 设置同上
4. 点击"发布"

### 步骤5: 验证

检查以下文件是否生成:
```
client/rjengineb_Data/StreamingAssets/Bundles/dev/
├── A_Compound.bytes
├── A_Compound.lua
├── A_Compound_PC.bytes
└── A_Compound_PC.lua
```

## 📝 快速参考

### 组件命名对照表

| 组件名称 | 类型 | 说明 |
|---------|------|------|
| list_group1 | GList | 一级分组列表 |
| list_group2 | GList | 二级分组列表 |
| cost_items_container | GComponent | 材料消耗容器 |
| target_icon | GImage | 目标道具图标 |
| target_count | GTextField | 目标数量文本 |
| currency_cost_panel | GComponent | 货币消耗面板 |
| txt_success_rate | GTextField | 成功率文本 |
| btn_compound | GButton | 合成按钮 |
| btn_close | GComponent | 关闭按钮 |

### 从其他包引用的资源

```
Common/CommonBg.xml          → 背景
Common/btn_close.xml         → 关闭按钮
Common/gold_icon.png         → 金币图标
Common/silver_icon.png       → 银币图标
Common/diamond_icon.png      → 钻石图标
```

## ⚠️ 注意事项

1. **命名必须一致**: 所有组件名称必须与Lua代码中完全一致
2. **引用资源**: 从Common包引用通用组件
3. **列表defaultItem**: 需要创建btn_group1和btn_group2作为列表项
4. **发布格式**: 必须选择Lua格式
5. **路径正确**: 发布路径必须与package.xml中配置一致

## 🆘 遇到问题?

参考现有项目的UI结构:
- `A_WuXun/WuXunPanl.xml` - 参考主界面结构
- `A_WuXun/Components/` - 参考组件结构

对比学习组件创建方式和布局技巧!

---

**创建时间**: 2026-04-20  
**状态**: 目录结构已创建,需要在FairyGUI编辑器中手动创建组件
