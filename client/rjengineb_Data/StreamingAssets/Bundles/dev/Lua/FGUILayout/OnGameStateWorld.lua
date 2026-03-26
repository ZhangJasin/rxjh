--[[
我在进入游戏世界开始加载
]]

function OnGameStateWorld()
    SL:Print("Hello World, This is OnGameStateWorld!")
    -- 清除缓存  重新加载CampUpdate
    -- 清除缓存  重新加载CampUpdate
    package.loaded["FGUILayout/Hud/CampUpdate"] = nil
    SL:RequireFile("FGUILayout/Hud/CampUpdate") -- 阵营更新
    -- 事件
    SL:RequireFile("FGUILayout/Apanl/init")
    --全局表
    HCDObj_cfd = {}         -- 合成点对象  背包整理时销毁用
    WuXunJianDing_cfd = {}  -- 武勋装备未鉴定时添加用
    WuXunOBJ_cfg = {}       -- 武勋tips对象
end
OnGameStateWorld()

local IsPC = SL:GetValue("IS_PC_OPER_MODE")

if IsPC then FGUI:SetDefaultFont("SIMSUN") end

-----------------------------------------------------------------------------
-- 断网处理
SL:RequireFile("FGUILayout/Network/Network")
Network.main()

-- 微信圈
SL:RequireFile("FGUILayout/WeChat/WeChat")
WeChat.main()

-- 飘血事件，滴血屏幕变红
SL:RequireFile("FGUILayout/HurtTips/HurtEvent")
HurtEvent.main()

--挂机控制
SL:RequireFile("FGUILayout/Auto/AutoController")
AutoController.main()

--辅助机器：自动喝药、自动施法等相关
SL:RequireFile("FGUILayout/Auto/AutoRobot")
AutoRobot.main()

--找目标
SL:RequireFile("FGUILayout/Auto/AutoFindTarget")
SL:RequireFile("FGUILayout/Auto/AutoFindDropItem")

-- 跳转界面
SL:RequireFile("FGUILayout/JumpUI")
JumpUI.main()

-----------------------------------------------------------------------------
-- 升级 触发
SL:RequireFile("FGUILayout/Levelup/Levelup")
Levelup.main()

-- 追踪点
SL:RequireFile("FGUILayout/TracePoint/TracePoint")
TracePoint.main()

-- 使用物品音效
SL:RequireFile("FGUILayout/Item/ItemUseSound")
ItemUseSound.main()

-- NPC商店百宝阁相关
SL:RequireFile("FGUILayout/TreasureShop/TreasureShop")
TreasureShop.main()

-- FuncDock模块
SL:RequireFile("FGUILayout/FuncDock/FuncDock")
FuncDock.main()

-----------------------------------------------------------------------------
-- 称号
SL:RequireFile("FGUILayout/Bag/TitleCheck")
TitleCheck.main()

-- 行会
SL:RequireFile("FGUILayout/Guild/Guild")
Guild.main()

-- 背包
SL:RequireFile("FGUILayout/Bag/Bag")
Bag.main()

-- 摆摊
SL:RequireFile("FGUILayout/Stall/Stall")
Stall.main()

-- 交易
SL:RequireFile("FGUILayout/Trade/Trade")
Trade.main()

-- 邮件
SL:RequireFile("FGUILayout/Mail/Mail")
Mail.main()

-- 好友
SL:RequireFile("FGUILayout/Friend/Friend")
Friend.main()

-- 组队
SL:RequireFile("FGUILayout/Team/Team")
Team.main()

-- 顶部货币
SL:RequireFile("FGUILayout/TopCurrency/TopCurrency")
TopCurrency.main()

-- 快捷键
-- if IsPC then
    SL:RequireFile("FGUILayout/Setting_pc/SettingKey")
    SettingKey.main()
-- end

if IsPC then
    SL:RequireFile("FGUILayout/Bag_pc/PCBagOnDragDrop")
    PCBagOnDragDrop.main()
end
-- 通知
SL:RequireFile("FGUILayout/Notice/Notice")
Notice.main()

-- 采集
SL:RequireFile("FGUILayout/Collection/Collection")
Collection.main()

-- NPC Talk
SL:RequireFile("FGUILayout/NPC/NPCTalk")
NPCTalk.main()

-- 使用道具
SL:RequireFile("FGUILayout/Item/ItemAutoUse")
ItemAutoUse.main()

-- 播放一些触发音效
SL:RequireFile("FGUILayout/PlaySound/PlaySound")
PlaySound.main()

-- Chat
SL:RequireFile("FGUILayout/Chat/ChatParserLua")
ChatParserLua.main()

-- 主界面
if IsPC then
    SL:RequireFile("FGUILayout/Main_pc/PCGameMain")
    PCGameMain.main()
else
    SL:RequireFile("FGUILayout/Main/GameMain")
    GameMain.main()
end

-- 聊天-上线欢迎
SL:RequireFile("FGUILayout/Chat/ChatWelcome")
ChatWelcome.main()

-----------------------------------------------------------------------------
-- !!!注意，FGUIUtil加载放到最后面
-- 加载GUIUtil.lua
SL:RequireFile("FGUILayout/FGUIUtil", true)