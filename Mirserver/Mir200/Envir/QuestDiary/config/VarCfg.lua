VarCfg                                = {}

---------------------------------------↓↓↓ A变量 ↓↓↓---------------------------------------
-- A0-A999 全局字符变量，引擎重启保存 500个
VarCfg.A_Mirror_Offline_Player        = "A0"  -- 副本召唤离线玩家
VarCfg.A_Activity_State               = "A1"  -- sys_activity表里活动的状态activityId为key state 状态（0未开启1进行中）
-- VarCfg.A_taps_list = "A10"   --勇者榜榜单
VarCfg.A_taps_firstCle                = "A11" --历练首通玩家记录
VarCfg.A_AllTeamID                    = "A12" --当前全服队伍记录
VarCfg.A_Huanshou_Data                = "A13" --当前生成的幻兽副本记录
VarCfg.A_Boss_DropRecordWorld         = "A14" --boss副本掉落记录世界
VarCfg.A_Boss_DropRecordWonder        = "A15" --boss副本掉落记录秘境
VarCfg.A_ChangeTime                   = "A20" --修改的开服时间戳
VarCfg.A_System_RunWeek               = "A21" --当前服务器运行周数{week,yearday}

VarCfg.A_EventState                   = "A25" --活动开启状态
VarCfg.A_MarryRelation                = "A26" -- 全局侠侣关系映射
VarCfg.A_MarryIntimacy                = "A27" -- 全局侠侣亲密度映射

VarCfg.A_LastFactionWars              = "A28" -- 最近一次门派战结果数据
VarCfg.A_FactionWars                  = "A33" -- 本次门派战数据

VarCfg.A_KuaFu_FactionWar_Rank        = "A29" -- 跨服势力战排名数据(本次参与玩家前100名数据)
VarCfg.A_KuaFu_FactionWar_PlayList    = "A30" -- 跨服势力战报名列表数据
VarCfg.A_KuaFu_FactionWar_CampData    = "A31" -- 跨服势力战阵营数据
VarCfg.A_KuaFu_FactionWar_PlayData    = "A32" -- 跨服势力战前五玩家外显数据

---------------------------------------↓↓↓ G变量 ↓↓↓---------------------------------------
-- G0 - G999 数字型全局变量.重启服务器保存.500个
VarCfg.G_Sys_Upright                  = "G1"  --全服正派人数
VarCfg.G_Sys_evil                     = "G2"  --全服邪派人数

VarCfg.G_KuaFu_FactionWar_WinningCamp = "G3"  --跨服势力战胜利方阵营

VarCfg.G_SportsSite_Week              = "G11" --竞技场周期


---------------------------------------↓↓↓ U变量 ↓↓↓---------------------------------------
-- 个人数字变量，下线保存
VarCfg.U_first_bill          = 'U1'  -- 首充
VarCfg.U_player_login        = 'U2'  -- 是否是新人
VarCfg.U_OffLine_Time        = "U3"  -- 上一次离线时间
VarCfg.U_LastLoginWeek       = "U4"  -- 上一次登录是服务器第几周,用于判断每周登录触发
VarCfg.U_LastLoginLevel      = "U5"  -- 每天第一次登录等级
VarCfg.U_AutoPick            = "U6"  -- 是否自动拾取
VarCfg.U_AutoSell            = "U7"  -- 是否自动出售
VarCfg.U_AutoFilterByLv      = "U8"  -- 是否勾选查看等级筛选
VarCfg.U_Login_DayTime       = "U9"  -- 每天第一次登录时间 时间戳
VarCfg.U_real_recharge       = "U10" -- 累计充值
VarCfg.U_daily_recharge      = "U11" -- 每日累计充值
VarCfg.U_Once_recharge       = "U12" -- 单笔充值记录
VarCfg.U_IsKuaFu_State       = "U13" -- 是否开启跨服 0未开启1开启
VarCfg.U_OffLine_Hp          = "U14" -- 下线保存当前血量
VarCfg.U_OffLine_Mp          = "U15" -- 下线保存当前血量
VarCfg.U_Role_RELEVEL_Body   = "U16" -- 人物转职模型身体
VarCfg.U_Role_RELEVEL_helmet = "U17" -- 人物转职模型头发

VarCfg.U_Daily_Online        = "U20" -- 日常每日在线时间
VarCfg.U_AutoFenJie          = "U21" -- 自动分解勾选
VarCfg.U_fennudian           = "U22" -- 刺客玩家当前愤怒点
VarCfg.U_lianhuanfeiwuCD     = "U23" -- 气功连环飞舞内置cd

VarCfg.U_Partner_UID         = "U30" -- 给伙伴生成唯一标识
VarCfg.U_Battle_State        = "U31" -- 战斗状态
VarCfg.U_click_taskID        = "U32" -- 当前点击任务ID
VarCfg.U_All_Mount_star      = "U35" -- 坐骑总星数
VarCfg.U_Mount_Take_Id       = "U36" -- 当前坐骑id
VarCfg.U_Mount_Base_ID       = "U37" -- 坐骑基础模型id
VarCfg.U_Mount_IS_HH         = "U38" -- 当前是否幻化
VarCfg.U_Mount_Status        = "U39" -- 是否出战
VarCfg.U_Mount_IS_SET        = "U40" -- 是否激活坐骑功能
VarCfg.U_Mount_BASE_SPEED    = "U41" -- 角色基础速度

VarCfg.U_REWARD_FINISH       = "U42" -- 当日门派任务完成次数  过0点重置
VarCfg.U_REWARD_REFUSH       = "U43" -- 每日门派任务免费刷新次数 3  过0点重置
VarCfg.U_REWARD_INDEX        = "U44" -- 当前接取的门派任务下标
VarCfg.U_REWARD_STATE        = "U45" -- 当前接取状态
VarCfg.U_REWARD_MAX_COUNT    = "U46" -- 今日可完成门派任务最大次数 默认 6 用道具可+1 过0点重置

VarCfg.U_MarryPartner        = "U47" -- 玩家侠侣ID
VarCfg.U_MarryType           = "U48" -- 侠侣类型(1:姻缘 2:金兰 3:结义)
VarCfg.U_MarryLevel          = "U49" -- 情缘等级
VarCfg.U_DivorceApplyObj     = "U50" -- 解缘申请人
VarCfg.U_MarryApplyTime      = "U51" -- 结缘申请时间
VarCfg.U_DivorceApplyTime    = "U52" -- 解缘申请时间
VarCfg.U_DivorceCD           = "U53" -- 解缘冷却时间
VarCfg.U_MarrySkillCD        = "U54" -- 侠侣传送技能CD
VarCfg.U_MarryIntimacyLevel  = "U55" -- 侠侣亲密度等级
VarCfg.U_MarryIntimacyExp    = "U56" -- 侠侣亲密度经验


-- ===== 旧的灵兽U变量（已废弃，使用新灵兽系统）=====
-- VarCfg.U_PETS_NOW_MODEL                  = "U57" -- 当前出战宠物外型（已废弃）
VarCfg.U_PETS_Take_Base      = "U58" -- 当前出战宠物id（已废弃）
-- VarCfg.U_PETS_Index                      = "U59" -- 切换模型位置 0 本体 0以上 幻化（已废弃）
-- VarCfg.U_PETS_DIE_TIME                   = "U60" -- 宠物死亡倒计时（已废弃）

VarCfg.U_SLBYCD              = "U61" -- 神龙庇佑CD
VarCfg.U_YZWCD               = "U62" -- 影之舞CD

-- VarCfg.U_LOOP_TASK_ID                    = "U63" -- 当前跑环任务Id（已废弃）
-- VarCfg.U_LOOP_TASK_TIME                  = "U64" -- 今日跑环任务剩余次数（已废弃）

VarCfg.U_YuYi_Level          = "U65" -- 羽翼等级
VarCfg.U_YuYi_Wear_DefSkill  = "U66" -- 特殊羽翼激活被动技能ID
VarCfg.U_YuYi_HuanHua_Appear = "U67" -- 羽翼幻化外观
VarCfg.U_YuYi_skill_CD       = "U68" -- 羽翼被动CD

VarCfg.U_WuXun_Level         = "U69" -- 武勋等级
VarCfg.U_WuXun_curExp        = "U70" -- 当前武勋值
VarCfg.U_WuXun_DailyState    = "U71" -- 武勋每日奖励领取标识
VarCfg.U_Camp_State          = "U72" -- 阵营随机奖励领取标识
VarCfg.U_MinWuXunZJLevel     = "U73" -- 身上最低武勋铸阶等级
VarCfg.U_Camp_Type           = "U74" -- 玩家当前阵营
VarCfg.U_Camp_RedBlue        = "U75" -- 获取玩家跨服势力战活动阵营 0无1红2蓝
VarCfg.U_kill_Streak         = "U76" -- 跨服势力战，当前连斩数
VarCfg.U_ISBaoMing           = "U77" -- 跨服势力战，是否报名

VarCfg.U_Donate_Num          = "U78" -- 门派每日已捐献次数
VarCfg.U_lastAttackTime      = "U79" --上次攻击时间
VarCfg.U_lastMonDieTime      = "U80" --上次怪物死亡时间

-- 以下为伤害统计
VarCfg.U_windowStartTime     = "U81" -- 时间窗口开始时间
VarCfg.U_totalPlayerDamage   = "U82" -- 窗口内总玩家伤害
VarCfg.U_totalPetDamage      = "U83" -- 窗口内总宠物伤害


VarCfg.U_skill                      = "U95"  --徒弟学的技能威力
VarCfg.U_fuben_time                 = "U96"  --师徒副本倒计时 30秒
VarCfg.U_fuben_start                = "U97"  --师徒副本邀请发起时间
VarCfg.U_Join_Num                   = "U98"  --师徒副本邀请发起时间

VarCfg.U_TeQuan_fuhuo_count         = "U101" -- 特权可复活次数
VarCfg.U_TeQuan_yifuhuo_count       = "U102" -- 特权已复活次数

-- VarCfg.U_UserItemLSHH                     = "U103" -- 用灵兽幻化符道具怪物表ID（已废弃）

VarCfg.U_VIP_Level                  = "U104" -- VIP等级
VarCfg.U_VIP_killMon_Num            = "U105" -- VIP击杀怪物数量

-- ===== 新的灵兽变量（与坐骑结构一致）=====
VarCfg.U_All_Pet_star               = "U106" -- 灵兽总星级/阶数
VarCfg.U_Pet_Take_Id                = "U107" -- 当前使用的灵兽模型ID
VarCfg.U_Pet_Base_ID                = "U108" -- 灵兽基础模型ID
VarCfg.U_Pet_IS_HH                  = "U109" -- 是否使用灵兽幻化模型
VarCfg.U_Pet_IS_SET                 = "U110" -- 是否激活灵兽
VarCfg.U_Pet_Die_Time               = "U111" -- 灵兽死亡复活倒计时
VarCfg.U_Pet_Passive                = "U103" -- 灵兽被动技能ID
VarCfg.U_Pet_Now_Model              = "U112" -- 当前灵兽显示的模型ID（用于外观显示）

VarCfg.U_BOSS_Count                 = "U113" -- 每日BOSS挑战次数

VarCfg.U_MentorShipTeach_Count      = "U114" -- 师徒每日传功次数

VarCfg.U_MRBZ_Start                 = "U115" -- 每日必做任务次数记录U115-U130
VarCfg.U_MRBZ_END                   = "U130" -- 每日必做任务次数记录U115-U130
VarCfg.U_MRBZ_YLXH                  = "U131" --每日银两消耗数量
VarCfg.U_MRBZ_Mon                   = "U132" --每日杀怪数量
VarCfg.U_MRBZ_Point                 = "U133" --每日活跃点数
---------------------------------------↓↓↓ T变量 ↓↓↓---------------------------------------
-- 个人字符变量，下线保存
VarCfg.T_daily_date                 = "T0" -- 格式 20211103 年月日，  每日定时更新，如果定时不在线每日第一次登陆更新
VarCfg.T_sys_date                   = "T1" -- 系统是否解锁
VarCfg.T_zero_date                  = "T2" -- 格式 20211103 年月日，  每日凌晨更新，如果凌晨不在线每日第一次登陆更新
VarCfg.T_servername                 = "T3" -- 原始服务器名字
VarCfg.T_EquipDJGX                  = "T4" -- 装备分解勾选
VarCfg.T_roleTFList                 = "T5" -- 已加点获取天赋
VarCfg.T_roleTFDNum                 = "T6" -- 天赋点数量
VarCfg.T_MountHuanHua               = "T7" -- 坐骑幻化激活对象
-- ===== 旧的灵兽T变量（已废弃，使用新灵兽系统）=====
-- VarCfg.T_Pets                             = "T9"   -- 当前灵兽激活情况（已废弃）
-- VarCfg.T_TAKE_PET                         = "T10"  -- 当前角色添加宠物数据（已废弃）

VarCfg.T_TaskComplete_data          = "T11" -- 已完成任务id {[已完成任务id]=1,........}
VarCfg.T_TaskProgress_data          = "T12" -- 已接取任务进度 {[任务id]=1，[任务id]=1....}
VarCfg.T_Fashion_data               = "T13" -- 已激活时装数据 {}
VarCfg.T_MarryApplyList             = "T14" -- 当前被申请结缘列表
VarCfg.T_MarryIntimacyList          = "T15" -- 玩家亲密度等级列表
VarCfg.T_MarryApplyInfo             = "T16" -- 玩家已申请玩家列表

-- VarCfg.T_PETS_Take_Id                     = "T17"  -- 已激活的本体（已废弃）
-- VarCfg.T_PET_MARK                         = "T18"  --当前召唤的宠物标记（已废弃）
VarCfg.T_AUTO_SELL_IDS              = "T19" --回收界面勾选的ids

VarCfg.T_MarryAllInfo               = "T20" -- 玩家侠侣关系 {结缘时间,侠侣名字,侠侣等级,侠侣亲密度等级}
VarCfg.T_TuLingPosTab               = "T21" -- 记录点坐标

VarCfg.T_BossData                   = "T22" -- BOSS挑战信息（BOSSID 、已挑战次数）
VarCfg.T_YuYi_data                  = "T23" -- 羽翼幻化，已激活被动信息
VarCfg.T_ExpPct_data                = "T24" -- 经验加成道具 加成数值记录

VarCfg.T_Activity_Login_lucky       = "T25" -- 今日运势 设置activity_daylogin_lucky表相关
VarCfg.T_Activity_LoginQianDao_data = "T26" -- 登录签到数据 {[1]=1,[2]=0}  --2已签到 1可签到 0未签到
VarCfg.T_Activity_LeiJiQianDao_data = "T27" -- 累计登录领取数据 {[1]=1,[2]=0}  --2已签到 1可签到 0不可签到

VarCfg.T_WuXun_ChuiLianList         = "T29" -- 武勋装备锤炼等级  绑定人物
VarCfg.T_Damage_SkillCD_List        = "T30" -- 伤害流程里技能CD列表
VarCfg.T_KuaFu_FactionWar_data      = "T31" -- 跨服势力战个人数据
VarCfg.T_Damage_Source              = "T32" -- 玩家伤害来源
VarCfg.T_KuaFu_FactionWar_Rank      = "T33" -- 跨服势力战排名数据
VarCfg.T_KuaFu_FactionWar_PlayData  = "T34" -- 跨服势力战前五玩家外显数据
VarCfg.T_ExpHarmList                = "T35" -- 当前玩家伤害获取经验列表
VarCfg.T_KuaFu_Play_List            = "T36" -- 跨服势力战报名列表

-- VarCfg.T_PetPay_MARK                      = "T37"  -- 当前召唤的氪金版宠物标记（已废弃）
-- VarCfg.T_PetPay_Data                      = "T38"  -- 当前角色添加氪金版宠物数据（已废弃）

VarCfg.T_EquipCollect_1             = "T37" -- 装备图鉴组1
VarCfg.T_EquipCollect_2             = "T38" -- 装备图鉴组2
VarCfg.T_EquipCollect_3             = "T39" -- 装备图鉴组3

VarCfg.T_MentorShipShopBuyTime      = "T40" -- 当前师徒商店限购

VarCfg.t_OfflineGame_Data           = "T86" -- 玩家离线挂机数据

VarCfg.t_CultivationList            = "T87" -- 修炼之门地图时间数据

VarCfg.t_JiangHuLingAward           = "T88" -- 江湖录已领取奖励
VarCfg.t_JiangHuLingJD              = "T89" -- 江湖录进度
VarCfg.T_MyMentorShip_Break         = "T94" -- 我的师徒解除关系列表
VarCfg.T_Skilll_BL                  = "T95" -- 师傅给的技能的倍率
VarCfg.T_MyMentorShip_fuben         = "T96" -- 师徒每日副本挑战情况


-- VarCfg.T_PERSON_FUBEN_FINISH              = "T100" -- 个人副本解锁情况{1=1,2=1,3=1} 副本类型 1 经验 2灵兽 3 坐骑   评分达到S解锁下一级（已废弃）
VarCfg.T_ToDayFuBenData = "T101" -- 每日副本挑战情况

VarCfg.T_personWarInfo  = "T110" -- 个人本次门派战数据

-- VarCfg.T_UserItemLSHHMark                 = "T115" -- 用灵兽幻化符道具宠物标识（已废弃）


VarCfg.T_Modul_Change             = "T118" -- 化形信息  模型改变

-- ===== 新的灵兽T变量（与坐骑结构一致）=====
VarCfg.T_PetHuanHua               = "T119" -- 灵兽幻化激活对象
VarCfg.T_Pet_Mark                 = "T120" -- 当前召唤的灵兽标记

---------------------------------------↓↓↓ 个人标记 ↓↓↓---------------------------------------
-- 个人标记，下线保存
VarCfg.F_LevelGift_start                 = "001" -- 等级礼包占001-010
VarCfg.F_LevelGift_end                   = "010" -- 等级礼包占001-010
VarCfg.F_HWJL_start                      = "011" -- 每日必做活跃奖励011-015
VarCfg.F_HWJL_end                        = "011" -- 每日必做活跃奖励011-015
---------------------------------------↓↓↓ S变量 ↓↓↓---------------------------------------
-- 个人字符变量，下线不保存
VarCfg.S_BossChall_Data           = "S87" -- BOSS挑战信息
VarCfg.S_FuBen_Var_PlayerPosition = "S88" -- 进入副本前的位置信息
VarCfg.S_FuBen_Var_CurrentInfo    = "S89" -- 当前创建的单人副本信息

VarCfg.S_cur_mapid                = "S99" -- 当前所在地图id，切换地图时候获取上一次的地图id

---------------------------------------↓↓↓ N变量 ↓↓↓---------------------------------------
-- N变量  个人数字变量，下线不保存
VarCfg.N_cur_level                = "N1"  --当前等级(为了升级触发获取到上一次是多少级)

VarCfg.N_Model_kf                 = "N11" -- 跨服模式
VarCfg.N_nuqibuff_timer           = "N12" -- 怒气buff结束时间  未结束不能获取怒气
VarCfg.N_task_xunlu_auto          = "N13" -- 任务寻路结束后是否挂机
VarCfg.N_fashion_charmValue       = "N14" -- 时装系统当前魅力值
VarCfg.N_fashion_charmLv          = "N15" -- 时装系统当前魅力值等级
VarCfg.N_FuBen_State              = "N16" -- 当前副本挑战状态  1 进行中 2 成功
VarCfg.N_HP_Item_Limit            = "N17" -- 是否可以使用红药
VarCfg.N_MP_Item_Limit            = "N18" -- 是否可以使用蓝药
VarCfg.N_Pet_recall_time          = "N19" -- 宠物召唤时间

VarCfg.N_person_count             = "N20" -- 当前副本击杀怪物数量
VarCfg.N_person_fuben_type        = "N21" --当前副本类型 1 经验 2灵兽 3 坐骑
VarCfg.N_fuben_monidx             = "N22" --当前副本怪物idx
VarCfg.N_person_FuBen_State       = "N23" --个人副本状态
VarCfg.N_FUBEN_TIME               = "N24" --师徒副本倒计时

VarCfg.N_boss_state               = "N25" --BOSS状态

VarCfg.N_mrbz_red                 = "N26" --每日必做任务红点
---------------------------------------↓↓↓ 自定义临时数字变量 ↓↓↓---------------------------------------
-- 下线不保存
VarCfg.N_LS_Power                 = "N$战力等级" -- 战力
VarCfg.N_LS_Jingjie               = "N$境界" -- 境界

---------------------------------------↓↓↓ 自定义临时字符变量 ↓↓↓---------------------------------------

VarCfg.S_LS_Fuben_BeginData       = "S$副本开始参数"
VarCfg.S_LS_Fuben_PinFen          = "S$副本评分规则"
VarCfg.S_selectFuBen              = "S$当前进入的副本" --当前进入的副本

VarCfg.S_equipCollectAttr         = "S$图鉴上级属性"

---------------------------------------↓↓↓ 批量增加属性组 ↓↓↓---------------------------------------
VarCfg.Att_Partner_Battle         = 11  -- 出战伙伴转化属性组id
VarCfg.Att_Partner_Assist         = 12  -- 助战伙伴转化属性组id

VarCfg.Attr_Pet_Battle            = 101 -- 已获得宠物转化属性组id
VarCfg.Attr_QuickEquipItem        = 102 -- 快捷装备道具转化属性组id
VarCfg.Attr_ZZ                    = 103 -- 转职属性




VarCfg.Attr_GM_Invincible = 999999 -- GM无敌属性组id

-------------------------------------行会int变量占用--------------------------------------------------
--1：行会等级
--2：行会入会战力限制
--3：行会图标编号 1-8
return VarCfg
