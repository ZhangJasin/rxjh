local config = { 
	[1] = { 
		ID=1,
		Name="乌龙驹",
		grade=1,
		mount_icon="zuoji_000",
		Cost = {
			[1] = 2401,
			[2] = 1,
		},
		Model=800001,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 10,
			},
			[2] = {
				[1] = 56,
				[2] = 2,
			},
		},
		BuffDesc="骑乘时移动速度增加2%",
		Condition=1,
		tips="激活坐骑幻化可以改变坐骑外观，\n同时获得额外的属性加成。\n通过消耗道具激活幻化效果，\n让你的坐骑更加炫酷",
		BattleSkill_Type="9",
		BattleSkill_Value="200",
	},
	[2] = { 
		ID=2,
		Name="铁甲犀牛",
		grade=1,
		mount_icon="zuoji_002",
		Cost = {
			[1] = 2403,
			[2] = 1,
		},
		Model=800003,
		ClassID = {
			[1] = {
				[1] = 52,
				[2] = 4,
			},
			[2] = {
				[1] = 54,
				[2] = 8,
			},
		},
		BuffDesc="骑乘时移动速度增加4%",
		Condition=1,
		BattleSkill_Type="9",
		BattleSkill_Value="400",
	},
	[3] = { 
		ID=3,
		Name="追风豹",
		grade=1,
		mount_icon="zuoji_001",
		Cost = {
			[1] = 2402,
			[2] = 1,
		},
		Model=800002,
		ClassID = {
			[1] = {
				[1] = 23,
				[2] = 4,
			},
			[2] = {
				[1] = 9,
				[2] = 200,
			},
		},
		BuffDesc="骑乘时移动速度增加6%",
		Condition=1,
		BattleSkill_Type="9",
		BattleSkill_Value="600",
	},
	[4] = { 
		ID=4,
		Name="霸天虎",
		grade=1,
		mount_icon="zuoji_005",
		Cost = {
			[1] = 2406,
			[2] = 1,
		},
		Model=800006,
		ClassID = {
			[1] = {
				[1] = 23,
				[2] = 4,
			},
			[2] = {
				[1] = 109,
				[2] = 4,
			},
		},
		BuffDesc="骑乘时移动速度增加8%",
		Condition=1,
		BattleSkill_Type="9",
		BattleSkill_Value="800",
	},
	[5] = { 
		ID=5,
		Name="青木神龙",
		grade=1,
		mount_icon="zuoji_009",
		Cost = {
			[1] = 2410,
			[2] = 1,
		},
		Model=800010,
		ClassID = {
			[1] = {
				[1] = 107,
				[2] = 500,
			},
			[2] = {
				[1] = 57,
				[2] = 100,
			},
		},
		BuffDesc="骑乘时移动速度增加10%",
		Condition=1,
		BattleSkill_Type="9",
		BattleSkill_Value="1000",
	},
	[6] = { 
		ID=6,
		Name="乌龙驹",
		grade=2,
		mount_icon="zuoji_000",
		Cost = {
			[1] = 2401,
			[2] = 1,
		},
		Model=800001,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 30,
			},
			[2] = {
				[1] = 56,
				[2] = 5,
			},
		},
		BuffDesc="骑乘时移动速度增加4%",
		BattleSkill_Type="9",
		BattleSkill_Value="400",
	},
	[7] = { 
		ID=7,
		Name="铁甲犀牛",
		grade=2,
		mount_icon="zuoji_002",
		Cost = {
			[1] = 2403,
			[2] = 1,
		},
		Model=800013,
		ClassID = {
			[1] = {
				[1] = 52,
				[2] = 8,
			},
			[2] = {
				[1] = 54,
				[2] = 16,
			},
		},
		BuffDesc="骑乘时移动速度增加8%",
		BattleSkill_Type="9",
		BattleSkill_Value="800",
	},
	[8] = { 
		ID=8,
		Name="追风豹",
		grade=2,
		mount_icon="zuoji_001",
		Cost = {
			[1] = 2402,
			[2] = 1,
		},
		Model=800002,
		ClassID = {
			[1] = {
				[1] = 23,
				[2] = 8,
			},
			[2] = {
				[1] = 9,
				[2] = 400,
			},
		},
		BuffDesc="骑乘时移动速度增加12%",
		BattleSkill_Type="9",
		BattleSkill_Value="1200",
	},
	[9] = { 
		ID=9,
		Name="霸天虎",
		grade=2,
		mount_icon="zuoji_005",
		Cost = {
			[1] = 2406,
			[2] = 1,
		},
		Model=800006,
		ClassID = {
			[1] = {
				[1] = 23,
				[2] = 8,
			},
			[2] = {
				[1] = 109,
				[2] = 8,
			},
		},
		BuffDesc="骑乘时移动速度增加16%",
		BattleSkill_Type="9",
		BattleSkill_Value="1600",
	},
	[10] = { 
		ID=10,
		Name="青木神龙",
		grade=2,
		mount_icon="zuoji_009",
		Cost = {
			[1] = 2410,
			[2] = 1,
		},
		Model=800010,
		ClassID = {
			[1] = {
				[1] = 107,
				[2] = 800,
			},
			[2] = {
				[1] = 57,
				[2] = 200,
			},
		},
		BuffDesc="骑乘时移动速度增加20%",
		BattleSkill_Type="9",
		BattleSkill_Value="2000",
	},
	[11] = { 
		ID=11,
		Name="乌龙驹",
		grade=3,
		mount_icon="zuoji_000",
		Cost = {
			[1] = 2401,
			[2] = 1,
		},
		Model=800011,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 50,
			},
			[2] = {
				[1] = 56,
				[2] = 8,
			},
		},
		BuffDesc="骑乘时移动速度增加6%",
		BattleSkill_Type="9",
		BattleSkill_Value="600",
	},
	[12] = { 
		ID=12,
		Name="铁甲犀牛",
		grade=3,
		mount_icon="zuoji_002",
		Cost = {
			[1] = 2403,
			[2] = 1,
		},
		Model=800023,
		ClassID = {
			[1] = {
				[1] = 52,
				[2] = 15,
			},
			[2] = {
				[1] = 54,
				[2] = 25,
			},
		},
		BuffDesc="骑乘时移动速度增加12%",
		BattleSkill_Type="9",
		BattleSkill_Value="1200",
	},
	[13] = { 
		ID=13,
		Name="追风豹",
		grade=3,
		mount_icon="zuoji_001",
		Cost = {
			[1] = 2402,
			[2] = 1,
		},
		Model=800012,
		ClassID = {
			[1] = {
				[1] = 23,
				[2] = 15,
			},
			[2] = {
				[1] = 9,
				[2] = 700,
			},
		},
		BuffDesc="骑乘时移动速度增加18%",
		BattleSkill_Type="9",
		BattleSkill_Value="1800",
	},
	[14] = { 
		ID=14,
		Name="霸天虎",
		grade=3,
		mount_icon="zuoji_005",
		Cost = {
			[1] = 2406,
			[2] = 1,
		},
		Model=800016,
		ClassID = {
			[1] = {
				[1] = 23,
				[2] = 15,
			},
			[2] = {
				[1] = 109,
				[2] = 15,
			},
		},
		BuffDesc="骑乘时移动速度增加24%",
		BattleSkill_Type="9",
		BattleSkill_Value="2400",
	},
	[15] = { 
		ID=15,
		Name="青木神龙",
		grade=3,
		mount_icon="zuoji_009",
		Cost = {
			[1] = 2410,
			[2] = 1,
		},
		Model=800020,
		ClassID = {
			[1] = {
				[1] = 107,
				[2] = 1100,
			},
			[2] = {
				[1] = 57,
				[2] = 300,
			},
		},
		BuffDesc="骑乘时移动速度增加30%",
		BattleSkill_Type="9",
		BattleSkill_Value="3000",
	},
	[16] = { 
		ID=16,
		Name="乌龙驹",
		grade=4,
		mount_icon="zuoji_000",
		Cost = {
			[1] = 2401,
			[2] = 1,
		},
		Model=800011,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 70,
			},
			[2] = {
				[1] = 56,
				[2] = 14,
			},
		},
		BuffDesc="骑乘时移动速度增加8%",
		BattleSkill_Type="9",
		BattleSkill_Value="800",
	},
	[17] = { 
		ID=17,
		Name="铁甲犀牛",
		grade=4,
		mount_icon="zuoji_002",
		Cost = {
			[1] = 2403,
			[2] = 1,
		},
		Model=800023,
		ClassID = {
			[1] = {
				[1] = 52,
				[2] = 25,
			},
			[2] = {
				[1] = 54,
				[2] = 35,
			},
		},
		BuffDesc="骑乘时移动速度增加16%",
		BattleSkill_Type="9",
		BattleSkill_Value="1600",
	},
	[18] = { 
		ID=18,
		Name="追风豹",
		grade=4,
		mount_icon="zuoji_001",
		Cost = {
			[1] = 2402,
			[2] = 1,
		},
		Model=800012,
		ClassID = {
			[1] = {
				[1] = 23,
				[2] = 25,
			},
			[2] = {
				[1] = 9,
				[2] = 1000,
			},
		},
		BuffDesc="骑乘时移动速度增加24%",
		BattleSkill_Type="9",
		BattleSkill_Value="2400",
	},
	[19] = { 
		ID=19,
		Name="霸天虎",
		grade=4,
		mount_icon="zuoji_005",
		Cost = {
			[1] = 2406,
			[2] = 1,
		},
		Model=800016,
		ClassID = {
			[1] = {
				[1] = 23,
				[2] = 25,
			},
			[2] = {
				[1] = 109,
				[2] = 25,
			},
		},
		BuffDesc="骑乘时移动速度增加32%",
		BattleSkill_Type="9",
		BattleSkill_Value="3200",
	},
	[20] = { 
		ID=20,
		Name="青木神龙",
		grade=4,
		mount_icon="zuoji_009",
		Cost = {
			[1] = 2410,
			[2] = 1,
		},
		Model=800020,
		ClassID = {
			[1] = {
				[1] = 107,
				[2] = 1500,
			},
			[2] = {
				[1] = 57,
				[2] = 400,
			},
		},
		BuffDesc="骑乘时移动速度增加40%",
		BattleSkill_Type="9",
		BattleSkill_Value="4000",
	},
	[21] = { 
		ID=21,
		Name="乌龙驹",
		grade=5,
		mount_icon="zuoji_000",
		Cost = {
			[1] = 2401,
			[2] = 1,
		},
		Model=800021,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 100,
			},
			[2] = {
				[1] = 56,
				[2] = 20,
			},
		},
		BuffDesc="骑乘时移动速度增加10%",
		BattleSkill_Type="9",
		BattleSkill_Value="1000",
	},
	[22] = { 
		ID=22,
		Name="铁甲犀牛",
		grade=5,
		mount_icon="zuoji_002",
		Cost = {
			[1] = 2403,
			[2] = 1,
		},
		Model=800023,
		ClassID = {
			[1] = {
				[1] = 52,
				[2] = 40,
			},
			[2] = {
				[1] = 54,
				[2] = 50,
			},
		},
		BuffDesc="骑乘时移动速度增加20%",
		BattleSkill_Type="9",
		BattleSkill_Value="2000",
	},
	[23] = { 
		ID=23,
		Name="追风豹",
		grade=5,
		mount_icon="zuoji_001",
		Cost = {
			[1] = 2402,
			[2] = 1,
		},
		Model=800022,
		ClassID = {
			[1] = {
				[1] = 23,
				[2] = 40,
			},
			[2] = {
				[1] = 9,
				[2] = 1500,
			},
		},
		BuffDesc="骑乘时移动速度增加30%",
		BattleSkill_Type="9",
		BattleSkill_Value="3000",
	},
	[24] = { 
		ID=24,
		Name="霸天虎",
		grade=5,
		mount_icon="zuoji_005",
		Cost = {
			[1] = 2406,
			[2] = 1,
		},
		Model=800026,
		ClassID = {
			[1] = {
				[1] = 23,
				[2] = 40,
			},
			[2] = {
				[1] = 109,
				[2] = 40,
			},
		},
		BuffDesc="骑乘时移动速度增加40%",
		BattleSkill_Type="9",
		BattleSkill_Value="4000",
	},
	[25] = { 
		ID=25,
		Name="青木神龙",
		grade=5,
		mount_icon="zuoji_009",
		Cost = {
			[1] = 2410,
			[2] = 1,
		},
		Model=800030,
		ClassID = {
			[1] = {
				[1] = 107,
				[2] = 2000,
			},
			[2] = {
				[1] = 57,
				[2] = 500,
			},
		},
		BuffDesc="骑乘时移动速度增加50%",
		BattleSkill_Type="9",
		BattleSkill_Value="5000",
	},
}
return config
