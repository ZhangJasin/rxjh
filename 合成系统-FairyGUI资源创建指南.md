# FairyGUI界面资源创建指南

## 📦 已为您创建的基础结构

```
9963d_rxjh_fgui_project/assets/
├── A_Compound/                      ✅ 已创建目录和package.xml
│   ├── Components/                   ✅ 
│   ├── Images/                       ✅ 
│   └── package.xml                   ✅ 
│
└── A_Compound_PC/                   ✅ 已创建目录和package.xml
    ├── Components/                   ✅ 
    ├── Images/                       ✅ 
    └── package.xml                   ✅ 
```

## 🎯 您只需要在FairyGUI编辑器中操作

详细步骤请参考: **`FGUI创建步骤.md`**

## 🎨 界面设计详细规范

### compoundMain.xml (主界面)

```xml
<?xml version="1.0" encoding="utf-8"?>
<component size="1334,750">
  <displayList>
    <!-- 背景 -->
    <component id="n0_bg" name="bg" src="..." 
               fileName="common/CommonBg.xml" 
               xy="667,375" pivot="0.5,0.5" 
               size="1000,650">
      <relation target="" sidePair="center-center,middle-middle"/>
    </component>
    
    <!-- 关闭按钮 -->
    <component id="n1_close" name="btn_close" 
               src="..." fileName="common/btn_close.xml" 
               xy="1135,78">
      <relation target="" sidePair="center-center,middle-middle"/>
    </component>
    
    <!-- 标题 -->
    <text id="n2_title" name="title" 
          xy="667,60" pivot="0.5,0.5" 
          size="100,40" font="SimSun" fontSize="28" 
          color="#ffffff" align="center" 
          text="合 成">
      <relation target="" sidePair="center-center"/>
    </text>
    
    <!-- 一级分组列表 -->
    <list id="n3_group1" name="list_group1" 
          xy="50,120" size="200,100" 
          scroll="vertical" lineGap="5" 
          defaultItem="ui://.../btn_group1" 
          selectionMode="single">
    </list>
    
    <!-- 二级分组列表 -->
    <list id="n4_group2" name="list_group2" 
          xy="50,240" size="200,400" 
          scroll="vertical" lineGap="5" 
          defaultItem="ui://.../btn_group2" 
          selectionMode="single">
    </list>
    
    <!-- 右侧内容区 -->
    <!-- 材料消耗标题 -->
    <text id="n5_costTitle" 
          xy="350,120" size="300,40" 
          font="SimSun" fontSize="24" 
          color="#ffd700" align="center" 
          text="⚙ 材料消耗 ⚙">
    </text>
    
    <!-- 材料消耗容器 -->
    <component id="n6_costContainer" 
               name="cost_items_container" 
               xy="350,180" size="600,300">
    </component>
    
    <!-- 合成获得标题 -->
    <text id="n7_targetTitle" 
          xy="350,500" size="300,40" 
          font="SimSun" fontSize="24" 
          color="#ffd700" align="center" 
          text="⚙ 合成获得 ⚙">
    </text>
    
    <!-- 目标道具图标 -->
    <image id="n8_targetIcon" 
           name="target_icon" 
           xy="550,550" size="80,80">
    </image>
    
    <!-- 目标道具数量 -->
    <text id="n9_targetCount" 
          name="target_count" 
          xy="640,590" size="100,30" 
          font="SimSun" fontSize="20" 
          color="#ffffff" 
          text="×1">
    </text>
    
    <!-- 货币消耗面板 -->
    <component id="n10_currency" 
               name="currency_cost_panel" 
               xy="350,650" size="600,50">
    </component>
    
    <!-- 成功率 -->
    <text id="n11_successRate" 
          name="txt_success_rate" 
          xy="550,620" size="200,30" 
          font="SimSun" fontSize="18" 
          color="#00ff00" align="center" 
          text="成功率:100%">
    </text>
    
    <!-- 合成按钮 -->
    <component id="n12_compoundBtn" 
               name="btn_compound" 
               src="..." 
               xy="550,660" size="200,50">
      <title text="合 成"/>
    </component>
  </displayList>
</component>
```

### CostItem.xml (材料消耗项)

```xml
<?xml version="1.0" encoding="utf-8"?>
<component size="580,100">
  <displayList>
    <!-- 背景 -->
    <graph id="n0_bg" xy="0,0" size="580,100" 
           type="rect" lineSize="0" 
           fillColor="#1a1a2e">
    </graph>
    
    <!-- 道具图标 -->
    <image id="n1_icon" name="icon" 
           xy="10,10" size="80,80">
    </image>
    
    <!-- 道具名称 -->
    <text id="n2_name" 
          xy="100,15" size="200,30" 
          font="SimSun" fontSize="18" 
          color="#ffffff" 
          text="材料名称">
    </text>
    
    <!-- 需要数量 -->
    <text id="n3_need" name="txt_need" 
          xy="100,50" size="150,30" 
          font="SimSun" fontSize="16" 
          color="#ffd700" 
          text="需要:5">
    </text>
    
    <!-- 拥有数量 -->
    <text id="n4_have" name="txt_have" 
          xy="300,50" size="200,30" 
          font="SimSun" fontSize="16" 
          color="#00ff00" 
          text="拥有:3/5">
    </text>
  </displayList>
</component>
```

### CurrencyCost.xml (货币消耗)

```xml
<?xml version="1.0" encoding="utf-8"?>
<component size="580,50">
  <displayList>
    <!-- 货币图标 -->
    <image id="n0_icon" name="icon" 
           xy="10,5" size="40,40">
    </image>
    
    <!-- 货币数量文本 -->
    <text id="n1_cost" name="txt_cost" 
          xy="60,10" size="300,30" 
          font="SimSun" fontSize="18" 
          color="#ffd700" 
          text="561万/2.00万">
    </text>
  </displayList>
</component>
```

## 📝 创建步骤

### 步骤1: 在FairyGUI编辑器中创建包

1. 打开FairyGUI编辑器
2. 文件 → 新建包
3. 包名称: `A_Compound`
4. 保存路径: `9963d_rxjh_fgui_project/assets/A_Compound`
5. 导出路径: `client/rjengineb_Data/StreamingAssets/Bundles/dev/`

### 步骤2: 创建组件

#### 2.1 创建主界面 compoundMain
1. 新建组件 → 命名为 `compoundMain`
2. 尺寸: 1334x750
3. 按照XML规范添加所有子组件
4. 命名必须与Lua代码中的命名一致

#### 2.2 创建材料项 CostItem
1. 新建组件 → 命名为 `CostItem`
2. 尺寸: 580x100
3. 添加图标和文本组件

#### 2.3 创建货币消耗 CurrencyCost
1. 新建组件 → 命名为 `CurrencyCost`
2. 尺寸: 580x50

### 步骤3: 创建PC端界面

1. 复制 `A_Compound` 文件夹
2. 重命名为 `A_Compound_PC`
3. 修改组件名称和尺寸适配PC端
4. 调整图标路径为PC端资源

### 步骤4: 配置package.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<packageDescription id="A_Compound">
  <resources>
    <component id="compoundMain" 
               name="compoundMain.xml" 
               path="/"/>
    <component id="CostItem" 
               name="CostItem.xml" 
               path="/Components/"/>
    <component id="CurrencyCost" 
               name="CurrencyCost.xml" 
               path="/Components/"/>
  </resources>
  <publish path="client/rjengineb_Data/StreamingAssets/Bundles/dev/" 
           packageFileExt=".bytes"/>
</packageDescription>
```

### 步骤5: 发布资源

1. 点击发布按钮
2. 选择导出格式: Lua
3. 发布到指定目录
4. 检查是否生成对应的.lua文件

## 🎯 关键注意事项

### 命名规范
所有组件名称必须与Lua代码中使用的名称完全一致:
- `list_group1` - 一级分组列表
- `list_group2` - 二级分组列表
- `cost_items_container` - 材料容器
- `target_icon` - 目标图标
- `target_count` - 目标数量
- `currency_cost_panel` - 货币面板
- `txt_success_rate` - 成功率文本
- `btn_compound` - 合成按钮
- `btn_close` - 关闭按钮

### 组件层级
确保组件层级正确:
```
compoundMain
├─ bg
├─ btn_close
├─ title
├─ list_group1
├─ list_group2
├─ cost_items_container
│  └─ CostItem (动态创建)
├─ target_icon
├─ target_count
├─ currency_cost_panel
├─ txt_success_rate
└─ btn_compound
```

### 关联设置
为列表项设置正确的关联:
```xml
<relation target="" sidePair="width-width"/>
```

### 控制器
如果需要,可以添加控制器管理不同状态:
- 材料不足/充足状态
- 合成中/可合成状态

## 📦 参考资源

### 武勋系统参考
参考 `A_WuXun` 包的结构:
```
A_WuXun/
├── WuXunPanl.xml           # 主界面
├── WuXunUpLevel.xml        # 升级界面
├── Components/             # 组件
└── Images/                 # 图片
```

### 常用组件
- `CommonBg.xml` - 通用背景
- `btn_close.xml` - 关闭按钮
- 可以从其他包中引用

## 🔍 调试技巧

### 在编辑器中预览
1. 使用FairyGUI的预览功能
2. 检查布局是否正确
3. 验证组件命名

### 发布后检查
1. 检查导出目录是否生成文件
2. 检查Lua代码是否能正确加载
3. 测试UI显示是否正常

### 常见问题
**问题**: 组件不显示
**解决**: 检查组件名称是否与Lua代码一致

**问题**: 列表不渲染
**解决**: 检查defaultItem设置是否正确

**问题**: 图片不显示
**解决**: 检查图片资源是否在Images目录

## 🚀 快速模板

提供一个简化的主界面模板:

```xml
<?xml version="1.0" encoding="utf-8"?>
<component size="1334,750">
  <displayList>
    <component id="n0" name="bg" xy="0,0" size="1334,750"/>
    <component id="n1" name="btn_close" xy="1200,50"/>
    <text id="n2" name="title" xy="667,60" text="合成"/>
    <list id="n3" name="list_group1" xy="50,120" size="200,100"/>
    <list id="n4" name="list_group2" xy="50,240" size="200,400"/>
    <component id="n5" name="cost_items_container" xy="350,180"/>
    <image id="n6" name="target_icon" xy="550,550"/>
    <text id="n7" name="target_count" xy="640,590"/>
    <component id="n8" name="currency_cost_panel" xy="350,650"/>
    <text id="n9" name="txt_success_rate" xy="550,620"/>
    <component id="n10" name="btn_compound" xy="550,660"/>
  </displayList>
</component>
```

## ✅ 检查清单

在发布前检查:
- [ ] 所有组件名称正确
- [ ] 组件层级结构正确
- [ ] 列表defaultItem设置正确
- [ ] 图片资源齐全
- [ ] package.xml配置正确
- [ ] 导出路径设置正确
- [ ] 移动端和PC端都已创建

完成以上步骤后,即可发布资源并在游戏中使用合成系统!
