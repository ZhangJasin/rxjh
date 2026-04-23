--[[
    UI模块初始化与网络消息注册
    1. 加载各功能UI模块
    2. 注册对应网络消息处理器
    3. 保持结构清晰，便于维护和扩展
--]]
local IsPC = SL:GetValue("IS_PC_OPER_MODE")

-- 引擎界面相关
MainAssistData        = SL:RequireFile("FGUILayout/Main/MainAssistData")

MainPlayerData = SL:RequireFile("FGUILayout/Main/MainPlayerData")             -- 主玩家界面
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.MainPlayer, MainPlayerData)

-- PC引擎界面相关
PCMainPlayerData = SL:RequireFile("FGUILayout/Main_pc/PCMainPlayerData")             -- 主玩家界面
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.PCMainPlayer, PCMainPlayerData)

-- 任务相关 引擎界面
MainMissionData                = SL:RequireFile("FGUILayout/Main/MainMissionData")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.MainMission, MainMissionData)
-- 任务相关
taskDeliverData                = SL:RequireFile("FGUILayout/A_TaskDeliver/taskDeliverData")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.taskDeliver, taskDeliverData)


-- gmbox
GMBox                = SL:RequireFile("FGUILayout/A_gm/GMBox")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.gmbox, GMBox)

-- 角色死亡
TipRoleDiePanlData        = SL:RequireFile("FGUILayout/A_TipRoleDie/TipRoleDiePanlData")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.TipRoleDiePanl, TipRoleDiePanlData)
-- 阵营
campPanl              = SL:RequireFile("FGUILayout/Transfer/campPanl")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.campPanl, campPanl)

-- 武勋系统
WuXunPanlData = SL:RequireFile("FGUILayout/A_WuXun/WuXunPanlData")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.WuXunPanl, WuXunPanlData)
-- 武勋升级
WuXunUpLevelData = SL:RequireFile("FGUILayout/A_WuXun/WuXunUpLevelData")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.WuXunUpLevel, WuXunUpLevelData)

-- 土灵符
tulingfuPanlData = SL:RequireFile("FGUILayout/A_TuLingFu/tulingfuPanlData")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.tulingfuPanl, tulingfuPanlData)
-- 装备强化系统
EquipDuanZaoData = SL:RequireFile("FGUILayout/A_EquipDuanZao/EquipDuanZaoData")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.EquipDuanZao, EquipDuanZaoData)
-- 时装系统
FashionSystemData = SL:RequireFile("FGUILayout/A_Fashion/FashionSystemData")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.FashionSystemPanl, FashionSystemData)

-- 坐骑、奖励、NPC对话、循环任务等功能UI及消息注册
mountMainData         = SL:RequireFile("FGUILayout/Mount/mountMainData")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.mountMain, mountMainData)

npcDialogUI         = SL:RequireFile("FGUILayout/NpcDialog/npcDialog")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.npcDialog, npcDialogUI)


-- 师徒系统相关UI及消息注册
MentorShipPanelUI = SL:RequireFile("FGUILayout/MentorShip/MentorShipPanel")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.MentorShipPanel, MentorShipPanelUI)

FindApprenticePanelUI = SL:RequireFile("FGUILayout/MentorShip/FindApprenticePanel")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.FindApprenticePanel, FindApprenticePanelUI)

FindMentorPanelUI = SL:RequireFile("FGUILayout/MentorShip/FindMentorPanel")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.FindMentorPanel, FindMentorPanelUI)

ShipApplyListsUI = SL:RequireFile("FGUILayout/MentorShip/ShipApplyLists")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.ShipApplyLists, ShipApplyListsUI)

MyShipApplyListsUI = SL:RequireFile("FGUILayout/MentorShip/MyShipApplyLists")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.MyShipApplyLists, MyShipApplyListsUI)

MentorShipMainUI = SL:RequireFile("FGUILayout/MentorShip/MentorShipMain")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.MentorShipMain, MentorShipMainUI)

MentorShipTeachUI = SL:RequireFile("FGUILayout/MentorShip/MentorShipTeach")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.MentorShipTeach, MentorShipTeachUI)

--师徒副本
InvitationUI = SL:RequireFile("FGUILayout/MentorShip/Invitation")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.Invitation, InvitationUI)
MentorShipShopUI = SL:RequireFile("FGUILayout/MentorShip/MentorShipShop")
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.MentorShipShop, MentorShipShopUI)

BagRecycleViewModelUI = SL:RequireFile("FGUILayout/Bag/BagRecycleViewModel")   -- 引擎背包界面操作
ssrMessage:RegisterNetMsg(ssrNetMsgCfg.BagRecycleViewModel, BagRecycleViewModelUI)