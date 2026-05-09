local config = { 
	[1] = { 
		ID=1,
		task_name="完成30个任务",
		type=1,
		task_target=5,
		task_target_param="*",
		task_target_num=30,
	},
	[2] = { 
		ID=2,
		task_name="拜师3天后",
		type=1,
		task_target=3,
		task_target_param="*",
		task_target_num=3,
	},
	[3] = { 
		ID=3,
		task_name="师徒组队挑战任意BOSS1个[每日]",
		type=2,
		task_desc="师徒组队挑战任意BOSS1个",
		erveyday_reset=1,
		task_target=10,
		task_target_param="1",
		task_target_num=1,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[4] = { 
		ID=4,
		task_name="师徒组队完成副本1次[每日]",
		type=2,
		task_desc="每日完成师徒副本1次",
		erveyday_reset=1,
		task_target=10,
		task_target_param="2",
		task_target_num=1,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[5] = { 
		ID=5,
		task_name="完成2次BOSS狩猎",
		type=2,
		task_desc="完成2次BOSS狩猎",
		task_target=10,
		task_target_param = {
			[1] = 5,
			[2] = 7,
		},
		task_target_num=2,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[6] = { 
		ID=6,
		task_name="累计完成10次BOSS狩猎",
		type=2,
		task_desc="累计完成10次BOSS狩猎",
		task_target=5,
		task_target_param = {
			[1] = 5,
			[2] = 7,
		},
		task_target_num=10,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[7] = { 
		ID=7,
		task_name="累计完成5次门派捐献任务",
		type=2,
		task_desc="累计完成5次门派捐献任务",
		task_target=5,
		task_target_param = {
			[1] = 5,
			[2] = 5,
		},
		task_target_num=5,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[8] = { 
		ID=8,
		task_name="累计完成10次门派捐献任务",
		type=2,
		task_desc="累计完成10次门派捐献任务",
		task_target=5,
		task_target_param = {
			[1] = 5,
			[2] = 5,
		},
		task_target_num=10,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[9] = { 
		ID=9,
		task_name="徒弟等级到达40级",
		type=2,
		task_desc="徒弟等级到达40级",
		task_target=6,
		task_target_param="*",
		task_target_num=40,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[10] = { 
		ID=10,
		task_name="徒弟等级到达50级",
		type=2,
		task_desc="徒弟等级到达50级",
		task_target=1,
		task_target_param="*",
		task_target_num=50,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[11] = { 
		ID=11,
		task_name="任意宠物升至2阶",
		type=2,
		task_desc="任意宠物升至2阶",
		task_target=5,
		task_target_param = {
			[1] = 6,
			[2] = 4,
		},
		task_target_num=2,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[12] = { 
		ID=12,
		task_name="任意宠物升至4阶",
		type=2,
		task_desc="任意宠物升至3阶",
		task_target=6,
		task_target_param = {
			[1] = 1,
			[2] = 3,
		},
		task_target_num=3,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[13] = { 
		ID=13,
		task_name="任意坐骑升至2阶",
		type=2,
		task_desc="任意坐骑升至2阶",
		task_target=4,
		task_target_param = {
			[1] = {
				[1] = 3,
				[2] = 1,
			},
			[2] = {
				[1] = 4,
				[2] = 10,
			},
		},
		task_target_num=2,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[14] = { 
		ID=14,
		task_name="任意坐骑升至4阶",
		type=2,
		task_desc="任意坐骑升至3阶",
		task_target=6,
		task_target_param = {
			[1] = 2,
			[2] = 3,
		},
		task_target_num=3,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[15] = { 
		ID=15,
		task_name="任意1个气功升至20级",
		type=2,
		task_desc="任意1个气功升至20级",
		task_target=4,
		task_target_param = {
			[1] = 1,
			[2] = 20,
		},
		task_target_num=20,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[16] = { 
		ID=16,
		task_name="任意2个气功升至20级",
		type=2,
		task_desc="任意2个气功升至20级",
		task_target=1,
		task_target_param="*",
		task_target_num=20,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[17] = { 
		ID=17,
		task_name="累计击杀100只怪物",
		type=2,
		task_desc="累计击杀100只怪物",
		task_target=7,
		task_target_param = {
			[1] = 7,
			[2] = "*",
		},
		task_target_num=100,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[18] = { 
		ID=18,
		task_name="累计击杀500只怪",
		type=2,
		task_desc="累计击杀500只怪",
		task_target=7,
		task_target_param = {
			[1] = 7,
			[2] = "*",
		},
		task_target_num=500,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[19] = { 
		ID=19,
		task_name="累计强化任意装备2次",
		type=2,
		task_desc="累计强化任意装备2次",
		task_target=5,
		task_target_param = {
			[1] = 4,
			[2] = 2,
		},
		task_target_num=2,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
			[2] = {
				[1] = 2,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
			[2] = {
				[1] = 2,
				[2] = 1,
			},
		},
	},
	[20] = { 
		ID=20,
		task_name="穿戴任意1件强化+8的装备",
		type=2,
		task_desc="穿戴任意1件强化+8的装备",
		task_target=5,
		task_target_param = {
			[1] = 4,
			[2] = 1,
		},
		task_target_num=1,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[21] = { 
		ID=21,
		task_name="累计完成30次BOSS狩猎",
		type=2,
		task_desc="累计完成30次BOSS狩猎",
		task_target=7,
		task_target_param = {
			[1] = 5,
			[2] = 7,
		},
		task_target_num=30,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[22] = { 
		ID=22,
		task_name="累计完成30次门派捐献任务",
		type=2,
		task_desc="累计完成30次门派捐献任务",
		task_target=8,
		task_target_param = {
			[1] = 5,
			[2] = 5,
		},
		task_target_num=30,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[23] = { 
		ID=23,
		task_name="徒弟等级到达60级",
		type=2,
		task_desc="徒弟等级到达60级",
		task_target=1,
		task_target_param="*",
		task_target_num=60,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[24] = { 
		ID=24,
		task_name="任意宠物升至6阶",
		type=2,
		task_desc="任意宠物升至5阶",
		task_target=6,
		task_target_param = {
			[1] = 1,
			[2] = 5,
		},
		task_target_num=5,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[25] = { 
		ID=25,
		task_name="任意坐骑升至6阶",
		type=2,
		task_desc="任意坐骑升至5阶",
		task_target=6,
		task_target_param = {
			[1] = 2,
			[2] = 5,
		},
		task_target_num=5,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[26] = { 
		ID=26,
		task_name="任意3个气功升至20级",
		type=2,
		task_desc="任意3个气功升至20级",
		task_target=1,
		task_target_param="*",
		task_target_num=20,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[27] = { 
		ID=27,
		task_name="累计击杀1000只怪",
		type=2,
		task_desc="累计击杀1000只怪",
		task_target=7,
		task_target_param = {
			[1] = {
				[1] = "*",
				[2] = "*",
			},
		},
		task_target_num=1000,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
			[2] = {
				[1] = 2,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
			[2] = {
				[1] = 2,
				[2] = 1,
			},
		},
	},
	[28] = { 
		ID=28,
		task_name="累计击杀1000只怪",
		type=2,
		task_desc="累计击杀1000只怪",
		task_target=7,
		task_target_param = {
			[1] = {
				[1] = "*",
				[2] = "*",
			},
		},
		task_target_num=1000,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
			[2] = {
				[1] = 2,
				[2] = 1,
			},
		},
		task_reward_1 = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
			[2] = {
				[1] = 2,
				[2] = 1,
			},
		},
	},
}
return config
