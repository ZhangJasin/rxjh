ssrNetMsgCfg, ssrNetMsgCfgEx  = {}, {}

ssrNetMsgCfg.sync             = 100 --同步数据

ssrNetMsgCfg.gmbox                          = "GMBox"                   -- gm   
ssrNetMsgCfg.righttoppanl                   = "righttoppanl"            -- 右上     
ssrNetMsgCfg.EquipDuanZao                   = "EquipDuanZao"            -- 装备锻造  强化  加工  合成  赋予 觉醒   
ssrNetMsgCfg.TipRoleDiePanl                 = "TipRoleDiePanl"          -- 人物死亡复活面板
ssrNetMsgCfg.tulingfuPanl                   = "tulingfuPanl"            -- 土灵符面板 
ssrNetMsgCfg.FashionSystemPanl              = "FashionSystemPanl"       -- 时装系统面板 
ssrNetMsgCfg.taskDeliver                    = "taskDeliver"             -- 任务交付面板 
ssrNetMsgCfg.npcDialog                      =  "npcDialog"              --npc对话框 
ssrNetMsgCfg.WuXunPanl                      = "WuXunPanl"               -- 武勋系统界面 
ssrNetMsgCfg.WuXunUpLevel                   = "WuXunUpLevel"            -- 武勋升级特效界面
ssrNetMsgCfg.campPanl                       = "campPanl"                -- 阵营界面 

--引擎界面
ssrNetMsgCfg.MainMission                    =  "MainMission"            -- 任务面板
ssrNetMsgCfg.MainPlayer                     =  "MainPlayer"             --人物主界面
ssrNetMsgCfg.PCMainPlayer                   =  "PCMainPlayer"           --人物主界面
ssrNetMsgCfg.PCMainAssist                   =  "PCMainAssist"           --人物辅助界面
ssrNetMsgCfg.GuildMainPanel                 =  "GuildMainPanel"         -- 行会主界面

ssrNetMsgCfg.mountMain                      = "mountMain"               --坐骑
ssrNetMsgCfg.MentorShipPanel                =  "MentorShipPanel"     --师徒
ssrNetMsgCfg.MentorShipShop                 =  "MentorShipShop"     --师徒商店
ssrNetMsgCfg.FindApprenticePanel            =  "FindApprenticePanel" --徒弟 列表
ssrNetMsgCfg.FindMentorPanel                =  "FindMentorPanel"     --师傅 列表 
ssrNetMsgCfg.ShipApplyLists                 =  "ShipApplyLists"     --申请列表列表 
ssrNetMsgCfg.MyShipApplyLists               =  "MyShipApplyLists"  --所有申请列表列表 
ssrNetMsgCfg.MentorShipMain                 =  "MentorShipMain"     --师徒主界面 
ssrNetMsgCfg.MentorShipTeach                =  "MentorShipTeach"     --师徒传功界面 
ssrNetMsgCfg.Invitation                     =  "Invitation"     --师徒副本
ssrNetMsgCfg.BagRecycleViewModel            =  "BagRecycleViewModel"               --自动回收 
ssrNetMsgCfg.TransferPanel                  =  "TransferPanel"               --转职

--Z_Jasin
ssrNetMsgCfg.Changwan                       = "Changwan"                   --畅玩特权


--自定义消息ID
ssrNetMsgCfg.USER_MESSAGE_ID  = 1000000

local t                       = {}
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
