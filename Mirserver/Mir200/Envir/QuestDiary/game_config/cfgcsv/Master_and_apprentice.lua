local config = { 
	[1] = { 
		ID=1,
		task_name="等级达到30级",
		type=1,
		task_target=1,
		task_target_param="*",
		task_target_num=30,
	},
	[2] = { 
		ID=2,
		task_name="完成5个任务",
		type=1,
		task_target=5,
		task_target_param="*",
		task_target_num=1,
	},
	[3] = { 
		ID=3,
		task_name="拜师14天后",
		type=1,
		task_target=3,
		task_target_param="*",
		task_target_num=0,
	},
	[4] = { 
		ID=4,
		task_name="每日组队击杀怪物100个",
		type=2,
		gxd_progress=100,
		task_desc="每日击杀怪物100只",
		erveyday_reset=1,
		task_target=10,
		task_target_param="1",
		task_target_num=100,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[5] = { 
		ID=5,
		task_name="每日完成师徒副本1次",
		type=2,
		gxd_progress=100,
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
	},
	[6] = { 
		ID=6,
		task_name="累计获得50W银两",
		type=2,
		task_target=9,
		task_target_param="1",
		task_target_num=500000,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[7] = { 
		ID=7,
		task_name="累计完成10次悬赏任务",
		type=2,
		task_target=5,
		task_target_param="7",
		task_target_num=10,
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
	},
	[8] = { 
		ID=8,
		task_name="达到4转",
		type=2,
		task_desc="达到4转",
		task_target=2,
		task_target_param="*",
		task_target_num=4,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[9] = { 
		ID=9,
		task_name="任意宠物升到10星",
		type=2,
		task_desc="任意宠物升到10星",
		task_target=6,
		task_target_param="1",
		task_target_num=10,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[10] = { 
		ID=10,
		task_name="拥有2个好友",
		type=2,
		task_desc="拥有2个好友",
		task_target=5,
		task_target_param="4",
		task_target_num=2,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[11] = { 
		ID=11,
		task_name="打造1件10级以上品阶1的装备",
		type=2,
		task_desc="打造1件10级以上品阶1的装备",
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
		task_target_num=1,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[12] = { 
		ID=12,
		task_name="击杀怪物获得铁锤10把",
		type=3,
		gxd_progress=250,
		task_desc="获得任意10把",
		task_target=4,
		task_target_param = {
			[1] = {
				[1] = 1,
				[2] = "*",
			},
		},
		task_target_num=10,
		task_reward = {
			[1] = {
				[1] = 1,
				[2] = 1,
			},
		},
	},
	[13] = { 
		ID=13,
		task_name="击杀怪物",
		type=3,
		gxd_progress=150,
		task_desc="击杀怪物50只",
		task_target=7,
		task_target_param = {
			[1] = {
				[1] = "*",
				[2] = "*",
			},
		},
		task_target_num=50,
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
	},
}
return config
