ssrNetMsgCfg, ssrNetMsgCfgEx  = {}, {}

ssrNetMsgCfg.sync             = 100 --同步数据

ssrNetMsgCfg.gmbox                         = "gmbox"                                                -- gm
ssrNetMsgCfg.EquipDuanZao                  = "EquipDuanZao"                                         -- 装备锻造  强化  加工  合成  
ssrNetMsgCfg.TipsRealiveBox                = "TipsRealiveBox"                                       -- 人物死亡复活面板
ssrNetMsgCfg.Task                          = "Task"                                                 -- 主线任务功能
ssrNetMsgCfg.moveItem                      = "moveItem"                                             -- 传送道具
ssrNetMsgCfg.FashionSystem                 = "FashionSystem"                                        -- 时装系统
ssrNetMsgCfg.wuxun                         = "wuxun"                                                -- 武勋系统
ssrNetMsgCfg.quickItem                     = "quickItem"                                            -- 快捷道具
ssrNetMsgCfg.Guild                         = "Guild"                                                -- 公会

ssrNetMsgCfg.mountMain                     = "mountMain"                                            -- 坐骑
ssrNetMsgCfg.npcDialog                     = "npcDialog"                                            -- NPC对话框
ssrNetMsgCfg.bag                           = "bag"                                                  -- 背包
ssrNetMsgCfg.MentorShip                    = "MentorShip"                                           -- 师徒

--自定义消息ID
ssrNetMsgCfg.USER_MESSAGE_ID  = 1000000

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
