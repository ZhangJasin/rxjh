local config = { 
	["Num_Daily_RewardTask"] = { 
		ID="Num_Daily_RewardTask",
		Value="10",
		Dec="每日默认门派任务次数",
	},
	["Num_DailyRefresh_RewardTask"] = { 
		ID="Num_DailyRefresh_RewardTask",
		Value="3",
		Dec="每日免费刷新门派任务次数",
	},
	["Num_DailyRefresh_Time"] = { 
		ID="Num_DailyRefresh_Time",
		Value="6",
		Dec="每日悬赏次数刷新时间（24小时计数）",
	},
	["ID_EmptyBountyTask"] = { 
		ID="ID_EmptyBountyTask",
		Value="400000",
		Dec="空置的悬赏任务ID",
	},
	["MIN_Reward_LV"] = { 
		ID="MIN_Reward_LV",
		Value="30",
		Dec="空置的悬赏任务等级要求",
	},
	["PET_Resurre_CD"] = { 
		ID="PET_Resurre_CD",
		Value="30",
		Dec="宠物复活冷却时间",
	},
	["MIN_LoopTask_LV"] = { 
		ID="MIN_LoopTask_LV",
		Value="20",
		Dec="最低跑环等级",
	},
	["Boss_Open_LV"] = { 
		ID="Boss_Open_LV",
		Value="35",
		Dec="boss悬赏开启等级",
	},
	["Boss_Chall_Count"] = { 
		ID="Boss_Chall_Count",
		Value="5",
		Dec="单个BOSS每日挑战次数",
	},
	["Boss_Chall_Num"] = { 
		ID="Boss_Chall_Num",
		Value="8",
		Dec="玩家BOSS池数量",
	},
	["Boss_Chall_Time"] = { 
		ID="Boss_Chall_Time",
		Value="300",
		Dec="BOSS挑战时间(S)",
	},
	["Boss_Chall_Exit_Time"] = { 
		ID="Boss_Chall_Exit_Time",
		Value="60",
		Dec="BOSS退出时间(S)",
	},
	["Boss_Day_Free_Count"] = { 
		ID="Boss_Day_Free_Count",
		Value="2",
		Dec="boss悬赏每日免费挑战次数",
	},
	["Boss_Day_MAX_Count"] = { 
		ID="Boss_Day_MAX_Count",
		Value="20",
		Dec="boss悬赏每日最大挑战次数",
	},
	["MIN_Apprentice_ZS"] = { 
		ID="MIN_Apprentice_ZS",
		Value="20",
		Dec="最低人物等级可收徒",
	},
	["MIN_Apprentice_LV"] = { 
		ID="MIN_Apprentice_LV",
		Value="2",
		Dec="最低转职等级可收徒",
	},
	["MIN_Master_ZS"] = { 
		ID="MIN_Master_ZS",
		Value="10",
		Dec="最低人物等级可拜师",
	},
	["MIN_Master_LV"] = { 
		ID="MIN_Master_LV",
		Value="1",
		Dec="最低转职等级可拜师",
	},
	["FuHunStone_HuTi"] = { 
		ID="FuHunStone_HuTi",
		Value="100",
		Dec="中级奇玉石(护体)效果参数配置，本次伤害的百分比转化为内力",
	},
	["FuHunStone_HunYuan"] = { 
		ID="FuHunStone_HunYuan",
		Value="50",
		Dec="中级奇玉石(混元)效果参数配置，本次受到攻击伤害降低百分比",
	},
	["FuHunStone_YiXing"] = { 
		ID="FuHunStone_YiXing",
		Value="3",
		Dec="中级奇玉石(移星)效果参数配置，躲避该时间内全部攻击（单位：秒）",
	},
	["FuHunStone_FenNu"] = { 
		ID="FuHunStone_FenNu",
		Value="200",
		Dec="中级奇玉石(愤怒)效果参数配置，本次攻击伤害提高百分比",
	},
	["FuHunStone_FuChou"] = { 
		ID="FuHunStone_FuChou",
		Value="33",
		Dec="中级奇玉石(复仇)效果参数配置，减少目标百分比的生命值（对普通怪物）",
	},
	["FuHunStone_QiYuan"] = { 
		ID="FuHunStone_QiYuan",
		Value="2",
		Dec="中级奇玉石(奇缘)效果参数配置，击杀怪物有概率获得经验倍率",
	},
	["Activity_LoginBuQian"] = { 
		ID="Activity_LoginBuQian",
		Value="9#30",
		Dec="热血币*30",
	},
	["JiangHuLu_Buy"] = { 
		ID="JiangHuLu_Buy",
		Value="小有名气·壹",
		Dec="江湖录购买此礼包后不再限制购买超值礼包条件",
	},
	["Reward_JoinZhenYing"] = { 
		ID="Reward_JoinZhenYing",
		Value = {
			[1] = {
				[1] = 5,
				[2] = 100,
			},
			[2] = {
				[1] = 17,
				[2] = 5000,
			},
			[3] = {
				[1] = 1,
				[2] = 10000,
			},
		},
	},
	["DailyNum_SectDonate"] = { 
		ID="DailyNum_SectDonate",
		Value="5",
	},
	["SectDonate_Currency_Num1"] = { 
		ID="SectDonate_Currency_Num1",
		Value = {
			[1] = 1,
			[2] = 1000000,
			[3] = 50,
		},
	},
	["SectDonate_Currency_Num2"] = { 
		ID="SectDonate_Currency_Num2",
		Value = {
			[1] = 2,
			[2] = 5,
			[3] = 200,
		},
	},
	["Recommend_Qigong"] = { 
		ID="Recommend_Qigong",
		Value="1",
		Dec="推荐气功功能   0关闭1开启",
	},
	["AttScoreBuff_Ratio_113"] = { 
		ID="AttScoreBuff_Ratio_113",
		Value = {
			[1] = 5,
			[2] = 5,
		},
	},
	["Cultivation_Time"] = { 
		ID="Cultivation_Time",
		Value="1800",
		Dec="飞升修炼门票每张增加时间单位秒",
	},
	["OffLineGame_Time"] = { 
		ID="OffLineGame_Time",
		Value="5",
		Dec="离线收益最大时长，单位分钟",
	},
}
return config
