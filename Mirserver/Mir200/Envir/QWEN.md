## Qwen Added Memories
- 传奇游戏服务器开发相关关键信息总结：

1. **伤害公式系统**：
   - **入口函数**：`Market_Def/QFunction-0.lua` 中的 `m_base(actor, target, ...)` 用于处理怪物攻击玩家的伤害逻辑。
   - **参数定义**：`m_base` 中，`actor` 为玩家 ID，`target` 为怪物 ID。
   - **属性读取**：玩家的防御属性通过 `abil(actor, 属性 ID)` 获取。
   - **新增属性**：
     - **属性 165 (对怪伤害)**：玩家攻击怪物时追加固定伤害。实现位置 `SkillFormula/Custom/CustomPassiveTemplate.lua` (`DMG_PVE_FLAT_FN`)。
     - **属性 56 (对怪防御)**：怪物攻击玩家时减免固定伤害。实现位置 `m_base` 函数。
     - **属性 116 (受怪减伤)**：怪物攻击玩家时按万分比减免伤害。实现位置 `m_base` 函数。
     - 公式：`最终伤害 = 基础伤害 - 属性 56 - (基础伤害 * 属性 116 / 10000)`。

2. **开发工具 (ItemNoteEditor.exe)**：
   - **用途**：编辑 `Item.xls` 的备注列（Z 列），支持 UBB 富文本。
   - **UBB 格式**：使用方括号，如 `[size=50]`, `[color=red]`, `[br]`, `[b]`, `[i]`, `[u]`。
   - **源码路径**：`d:\works\RXjianghu\rxjianghu1\Mirserver\Mir200\Envir\item_note_editor.py`。
   - **编译产物路径**：`d:\works\RXjianghu\rxjianghu1\Mirserver\工具\dist\ItemNoteEditor.exe`。
   - **默认数据路径**：相对于 exe 的 `../../Mir200/Envir/data/Item.xls`。
   - **一键编译命令**：
     `cd /d d:\works\RXjianghu\rxjianghu1\Mirserver\Mir200\Envir && python -c "c=open('item_note_editor.py','r',encoding='gbk').read(); open('item_note_editor.py','w',encoding='utf-8').write(c)" 2>nul & del /f ItemNoteEditor.spec 2>nul & pyinstaller --onefile --windowed --name ItemNoteEditor item_note_editor.py --clean --noconfirm && xcopy /Y "dist\ItemNoteEditor.exe" "..\..\工具\dist\" && rmdir /S /Q "dist" 2>nul & rmdir /S /Q "build" 2>nul & del /f ItemNoteEditor.spec 2>nul`
- 传奇游戏服务器宠物伤害结算属性逻辑：

**伤害入口函数职责**：
- b_base：宠物攻击时的伤害结算（宠物→怪物/玩家）
- m_base：怪物攻击时的伤害结算（怪物→玩家/宠物）
- base：玩家攻击时的伤害结算（玩家→玩家/宠物）

**5个关键属性**：
- 56对怪防御：怪物攻击时固定值减免（从主人属性获取）
- 116受怪减伤：怪物攻击时万分比减免（从主人属性获取）
- 165对怪伤害：攻击怪物时固定值追加（从主人属性获取）
- 67PK加成：攻击玩家时万分比追加（从主人属性获取）
- 68PK减免：受到玩家攻击时万分比减免（从主人属性获取）

**实现位置**：
- Market_Def/QFunction-0.lua：b_base、m_base、base 函数中直接处理属性逻辑
- SkillFormula/Custom/CustomPassiveTemplate.lua：PK_BONUS_FN 和 PK_REDUCE_FN 模板函数（备用）

**宠物属性来源**：所有宠物战斗属性均从主人获取，通过 targetinfo(petId, "MASTERID") 获取主人ID，abil(masterId, 属性ID) 获取属性值
