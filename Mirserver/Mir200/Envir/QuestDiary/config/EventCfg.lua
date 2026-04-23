EventCfg = {}

--引擎事件
EventCfg.onStartUp                  = "onStartUp"                     --m2启动
EventCfg.onNewHuman                 = "onNewHuman"                    --新角色第一次登录    (参数：actor)
EventCfg.onLogin                    = "onLogin"                       --登录    (参数：actor)
EventCfg.onLoginAttr                = "onLoginAttr"                   --登录附加属性    (参数：actor, 登录属性数据)
EventCfg.onLoginEnd                 = "onLoginEnd"                    --登录完成    (参数：actor, 登录同步数据)
EventCfg.onResetday                 = "onResetday"                    --跨天登录出发    (参数：actor)
EventCfg.onKillMon                  = "onKillMon"                     --任意地图杀怪    (参数：actor, 死亡怪物唯一ID)
EventCfg.onPlayLevelUp              = "onPlayLevelUp"                 --玩家升级    (参数：actor, 当前等级, 之前等级)
EventCfg.onTakeOnEx                 = "onTakeOnEx"                    --穿装备goPlayerVar
EventCfg.onTakeOffEx                = "onTakeOffEx"                   --脱装备
EventCfg.onAddBag                   = "onAddBag"                      --物品进背包
EventCfg.onBeforeAddBag             = "onBeforeAddBag"                --物品进背包前
EventCfg.onExitGame                 = "onExitGame"                    --小退或大退游戏
EventCfg.onTriggerChat              = "onTriggerChat"                 --聊天栏输入信息
EventCfg.onClicknpc                 = "onClicknpc"                    --点击某NPC
EventCfg.goEnterMap                 = "goEnterMap"                    --进入地图
EventCfg.goSwitchMap                = "goSwitchMap"                   --切换地图
EventCfg.onMove                     = "onMove"                        --移动触发 (参数：actor, 0跑/1走)
EventCfg.onTakeonbeforeex           = "onTakeonbeforeex"              --穿戴任意装备前触发
EventCfg.onTakebeforeex             = "onTakebeforeex"                --脱下任意装备前触发

EventCfg.onStartGroup               = "onStartGroup"                  --创建队伍前触发
EventCfg.onGroupCreate              = "onGroupCreate"                 --创建队伍触发
EventCfg.onInviteGroup              = "onInviteGroup"                 --邀请组队前触发 target 被邀请玩家对象ID
EventCfg.onExitMyGroup              = "onExitMyGroup"                 --离开队伍前触发
EventCfg.onLeaveGroup               = "onLeaveGroup"                  --离开队伍时触发
EventCfg.onGroupDelMember           = "onGroupDelMember"              --删除组队成员触发 actor 队长玩家对象ID targetName 被踢玩家名字
EventCfg.onGroupUserAddMember       = "onGroupUserAddMember"          --加入队伍前触发
EventCfg.onGroupAddMember           = "onGroupAddMember"              --添加组队成员触发 targetName 被邀请的玩家名字
EventCfg.onGroupKillMon             = "onGroupKillMon"                --组队杀怪触发
EventCfg.onSkillBegin               = "onSkillBegin"                  --技能前触发
EventCfg.onMonDropItemEX            = "onMonDropItemEX"               --怪物掉落任意物品前触发
EventCfg.onFightBBDie               = "onFightBBDie"                  --出战宝宝死亡
EventCfg.onBuffChange               = "onBuffChange"                  --buff变化
EventCfg.onMonBuffChange            = "onMonBuffChange"               --怪物buff变化
EventCfg.onBBBuffChange             = "onBBBuffChange"                --宝宝buff变化

EventCfg.onCheckbuildguild          = "onCheckbuildguild"             --创建门派前触发
EventCfg.onGuildaddmember           = "onGuildaddmember"              --加入门派前触发
EventCfg.onGuildaddmemberafter      = "onGuildaddmemberafter"         --加入门派触发
EventCfg.onGuilddelmemberbefore     = "onGuilddelmemberbefore"        --退出门派前触发
EventCfg.onGuilddelmember           = "onGuilddelmember"              --退出门派触发
EventCfg.onUpdateguildnotice        = "onUpdateguildnotice"           --编辑门派公告前触发
EventCfg.onGuildchiefdelmember      = "onGuildchiefdelmember"         --掌门踢出门派成员前触发
EventCfg.onGuildclosebefore         = "onGuildclosebefore"            --解散门派前触发
EventCfg.onCreateguild              = "onCreateguild"                 --创建门派成功触发
EventCfg.onInivitguild              = "onInivitguild"                 --邀请加入门派前触发
EventCfg.onGuildsetexp              = "onGuildsetexp"                 --设置门派经验值触发
EventCfg.onGuildTask                = "onGuildTask"                   --完成门派任务

EventCfg.onWalk                     = "onWalk"                        --移动触发
EventCfg.onPlayDie                  = "onPlayDie"                     --人物死亡     (参数：actor, 杀人者对象)
EventCfg.onCheckDropuseItems        = "onCheckDropuseItems"           --人物死亡装备掉落前触发 (参数：actor, 装备位置, 装备ID)
EventCfg.beforeUseItem              = "beforeUseItem"                 --使用道具前触发
EventCfg.stdUseItem                 = "stdUseItem"                    --双击物品触发
EventCfg.onChangeExp                = "onChangeExp"                   --获取经验值触发
EventCfg.onAttrChange               = "onAttrChange"                  --人物属性改变 （参数actor, 变化的属性id）
EventCfg.onPickUpItemfrontEX        = "onPickUpItemfrontEX"           --玩家捡取任意物品前触发（参数：actor,itemid）
EventCfg.onPickUpItemEX             = "onPickUpItemEX"                --玩家捡取任意物品后触发（参数：actor,makeindex,itemid）
EventCfg.onAutoPlayGame             = "onAutoPlayGame"                --挂机触发(参数：actor,1开始0结束)

EventCfg.onMirrorMapEnd             = "onMirrorMapEnd"                --镜像地图到期触发 actor, 镜像地图id

--游戏事件
EventCfg.onAddFriendSelf            = "onAddFriendSelf"               --同意好友成功触发  param1 申请人ID
EventCfg.onDelFirendSelf            = "onDelFirendSelf"               --删除好友成功触发  param1 申请人ID

EventCfg.onAttack                   = "onAttack"                       -- 攻击触发
EventCfg.onAddTask                  = "onAddTask"                      -- 添加任务(参数：actor, 任务id)
EventCfg.onTaskFinish               = "onTaskFinish"                   -- 完成任务(参数：actor, 任务id)
EventCfg.onTaskDel                  = "onTaskDel"                      -- 删除任务(参数：actor, 任务id)
EventCfg.onTaskClick                = "onTaskClick"                    -- 点击任务(参数：actor, 任务id)
EventCfg.onTaskRe                   = "onTaskRe"                       -- 刷新任务(参数：actor, 任务id)


EventCfg.onGetMailItem              = "onGetMailItem"                  -- 提取邮件


EventCfg.onQiangHua                 = "onQiangHua"                     -- 玩家强化触发(参数：actor, 成功true失败false)
EventCfg.onFuYu                     = "onFuYu"                         -- 玩家赋予触发(参数：actor)


EventCfg.onJoinUpright              = "onJoinUpright"                  -- 加入正派(参数：actor)
EventCfg.onJoinEvil                 = "onJoinEvil"                     -- 加入邪派(参数：actor)
EventCfg.onClearGoodevolid          = "onClearGoodevolid"              -- 清除阵营(参数：actor)
EventCfg.onChangeQGD                = "onChangeQGD"                    -- 气功点改变触发(actor, moneyID, lastCount)
EventCfg.onOpenNpc                  = "onOpenNpc"                      -- 打开npc指定界面(actor, npcid)
EventCfg.onPetLevel                 = "onPetLevel"                     -- 宠物升级事件(actor, npcid)
EventCfg.onMountLv                  = "onMountLv"                    -- 坐骑升级事件(actor, npcid)
EventCfg.onPetZhan                  = "onPetZhan"                      -- 宠物出战事件(actor, npcid)
EventCfg.onMountZhan                = "onMountZhan"                      -- 坐骑出战事件(actor, npcid)


-- EventCfg.onGroupGetExp              = "onGroupGetExp"                  -- 组队获得经验触发(actor, exp)
EventCfg.updateMakeItem             = "updateMakeItem"                 -- 触发制造更新师徒打造任务
EventCfg.updateJiangHuLuTask        = "updateJiangHuLuTask"            -- 触发更新完成江湖录小阶段任务
EventCfg.onActivityNotice           = "onActivityNotice"               -- 活动预告(参数：actor, 活动id)
EventCfg.onActivityOpen             = "onActivityOpen"                 -- 活动开启(参数：actor, 活动id)
EventCfg.onActivityClose            = "onActivityClose"                -- 活动关闭(参数：actor, 活动id)
EventCfg.onKuaFuLogin               = "onKuaFuLogin"                   -- 跨服登录
EventCfg.onKuaFuEnd                 = "onKuaFuEnd"                     -- 跨服退出

EventCfg.onCalculationHurm          = "onCalculationHurm"              -- 对怪造成伤害触发

EventCfg.onPlayRealive              = "onPlayRealive"                  -- 人物复活
EventCfg.onChangStatusLS            = "onChangStatusLS"                --灵兽召唤收回
EventCfg.onChangeMoney              = "onChangeMoney"                  --货币改变（除了19）
EventCfg.UseMoveItem                = "UseMoveItem"                    --使用传送符
EventCfg.onBuyShopItem              = "onBuyShopItem"                  --商店购买物品
EventCfg.onRecycleItems             = "onRecycleItems"                  --物品回收

return EventCfg

