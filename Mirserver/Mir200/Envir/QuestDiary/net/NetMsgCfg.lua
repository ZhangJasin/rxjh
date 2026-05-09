ssrNetMsgCfg, ssrNetMsgCfgEx = {}, {}

ssrNetMsgCfg.sync            = 100              --同步消息

ssrNetMsgCfg.gmbox           = "gmbox"          -- gm
ssrNetMsgCfg.EquipDuanZao    = "EquipDuanZao"   -- 装备锻造  强化  加工  合成
ssrNetMsgCfg.Compound        = "Compound"       -- 合成系统
ssrNetMsgCfg.TipsRealiveBox  = "TipsRealiveBox" -- 死亡复活提示
ssrNetMsgCfg.Task            = "Task"           -- 任务系统
ssrNetMsgCfg.moveItem        = "moveItem"       -- 移动道具
ssrNetMsgCfg.FashionSystem   = "FashionSystem"  -- 时装系统
ssrNetMsgCfg.wuxun           = "wuxun"          -- 武勋系统
ssrNetMsgCfg.quickItem       = "quickItem"      -- 快捷道具
ssrNetMsgCfg.mountMain       = "mountMain"      -- 坐骑
ssrNetMsgCfg.npcDialog       = "npcDialog"      -- NPC对话框
ssrNetMsgCfg.bag             = "bag"            -- 背包
ssrNetMsgCfg.MentorShip      = "MentorShip"     -- 师徒


--Z_Jasin
ssrNetMsgCfg.Changwan = "Changwan" --畅玩乐园



--自定义消息ID
ssrNetMsgCfg.USER_MESSAGE_ID            = 1000000

ssrNetMsgCfg.TransferInfo               = "TransferInfo" -- 转职
ssrNetMsgCfg.TransferInfo_RefreshTaskUI = 1100000
ssrNetMsgCfg.TransferInfo_RefreshUI     = 1100001

ssrNetMsgCfg.Guild                      = "Guild" -- 公会
ssrNetMsgCfg.Guild_RetData              = 1100010

ssrNetMsgCfg.equipCollect               = "equipCollect" -- 装备图鉴

ssrNetMsgCfg.BOSSChall                      = "BossChall" -- BOSS悬赏
ssrNetMsgCfg.BOSSChall_RetData              = 1100020
ssrNetMsgCfg.BOSSChall_Begin                = 1100021
ssrNetMsgCfg.BOSSChall_End                  = 1100022
ssrNetMsgCfg.BOSSChall_Leave                = 1100023

ssrNetMsgCfg.DailyTask                      = "DailyTask" -- 每日必做

local t = {}
for msgName, msgID in pairs(ssrNetMsgCfg) do
    t[msgName] = msgID
    t[msgID] = msgName

    ssrNetMsgCfgEx[msgName] = msgID
    if type(msgID) ~= "string" then
        if string.find(msgName, "_") then
            ssrNetMsgCfgEx[msgID] = { msgName:match "([^.]*)_(.*)" }
        else
            ssrNetMsgCfgEx[msgID] = { msgName }
        end
    end
end
ssrNetMsgCfg = t

return ssrNetMsgCfg
