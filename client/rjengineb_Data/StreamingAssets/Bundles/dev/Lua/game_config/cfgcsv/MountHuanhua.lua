local config = { 
	[1] = { 
		ID=1,
		Name="乌龙驹",
		grade=1,
		mount_icon="zuoji_000",
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
		BuffDesc="\n\n骑乘[color=#645967]乌龙驹[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]10%[/color]",
		Condition=1,
		tips="激活坐骑幻化可以改变坐骑外观，\n同时获得额外的属性加成。\n通过消耗道具激活幻化效果，\n让你的坐骑更加炫酷",
		BattleSkill_Type="9",
		BattleSkill_Value="1000",
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
		BuffDesc="\n\n骑乘[color=#645967]铁甲犀牛[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]15%[/color]",
		Condition=1,
		BattleSkill_Type="9",
		BattleSkill_Value="1500",
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
		BuffDesc="\n\n骑乘[color=#645967]追风豹[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]20%[/color]",
		Condition=1,
		BattleSkill_Type="9",
		BattleSkill_Value="2000",
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
		BuffDesc="\n\n骑乘[color=#645967]霸天虎[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]25%[/color]",
		Condition=1,
		BattleSkill_Type="9",
		BattleSkill_Value="2500",
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
		BuffDesc="\n\n骑乘[color=#645967]青木神龙[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]30%[/color]",
		Condition=1,
		BattleSkill_Type="9",
		BattleSkill_Value="3000",
	},
	[6] = { 
		ID=6,
		Name="乌龙驹",
		grade=2,
		mount_icon="zuoji_000",
		Cost = {
			[1] = 4034,
			[2] = 30,
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
		BuffDesc="\n\n骑乘[color=#34963c]乌龙驹[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]10%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="1000",
	},
	[7] = { 
		ID=7,
		Name="铁甲犀牛",
		grade=2,
		mount_icon="zuoji_002",
		Cost = {
			[1] = 4035,
			[2] = 30,
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
		BuffDesc="\n\n骑乘[color=#34963c]铁甲犀牛[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]15%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="1500",
	},
	[8] = { 
		ID=8,
		Name="追风豹",
		grade=2,
		mount_icon="zuoji_001",
		Cost = {
			[1] = 3969,
			[2] = 30,
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
		BuffDesc="\n\n骑乘[color=#34963c]追风豹[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]20%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="2000",
	},
	[9] = { 
		ID=9,
		Name="霸天虎",
		grade=2,
		mount_icon="zuoji_005",
		Cost = {
			[1] = 4036,
			[2] = 30,
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
		BuffDesc="\n\n骑乘[color=#34963c]霸天虎[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]25%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="2500",
	},
	[10] = { 
		ID=10,
		Name="青木神龙",
		grade=2,
		mount_icon="zuoji_009",
		Cost = {
			[1] = 4037,
			[2] = 30,
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
		BuffDesc="\n\n骑乘[color=#34963c]青木神龙[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]30%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="3000",
	},
	[11] = { 
		ID=11,
		Name="乌龙驹",
		grade=3,
		mount_icon="zuoji_000",
		Cost = {
			[1] = 4034,
			[2] = 60,
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
		BuffDesc="\n\n骑乘[color=#9226b2]乌龙驹[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]15%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="1500",
	},
	[12] = { 
		ID=12,
		Name="铁甲犀牛",
		grade=3,
		mount_icon="zuoji_002",
		Cost = {
			[1] = 4035,
			[2] = 60,
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
		BuffDesc="\n\n骑乘[color=#9226b2]铁甲犀牛[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]20%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="2000",
	},
	[13] = { 
		ID=13,
		Name="追风豹",
		grade=3,
		mount_icon="zuoji_001",
		Cost = {
			[1] = 3969,
			[2] = 60,
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
		BuffDesc="\n\n骑乘[color=#9226b2]追风豹[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]25%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="2500",
	},
	[14] = { 
		ID=14,
		Name="霸天虎",
		grade=3,
		mount_icon="zuoji_005",
		Cost = {
			[1] = 4036,
			[2] = 60,
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
		BuffDesc="\n\n骑乘[color=#9226b2]霸天虎[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]30%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="3000",
	},
	[15] = { 
		ID=15,
		Name="青木神龙",
		grade=3,
		mount_icon="zuoji_009",
		Cost = {
			[1] = 4037,
			[2] = 60,
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
		BuffDesc="\n\n骑乘[color=#9226b2]青木神龙[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]40%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="4000",
	},
	[16] = { 
		ID=16,
		Name="乌龙驹",
		grade=4,
		mount_icon="zuoji_000",
		Cost = {
			[1] = 4034,
			[2] = 100,
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
		BuffDesc="\n\n骑乘[color=#aa2736]乌龙驹[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]15%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="1500",
	},
	[17] = { 
		ID=17,
		Name="铁甲犀牛",
		grade=4,
		mount_icon="zuoji_002",
		Cost = {
			[1] = 4035,
			[2] = 100,
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
		BuffDesc="\n\n骑乘[color=#aa2736]铁甲犀牛[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]20%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="2000",
	},
	[18] = { 
		ID=18,
		Name="追风豹",
		grade=4,
		mount_icon="zuoji_001",
		Cost = {
			[1] = 3969,
			[2] = 100,
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
		BuffDesc="\n\n骑乘[color=#aa2736]追风豹[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]25%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="2500",
	},
	[19] = { 
		ID=19,
		Name="霸天虎",
		grade=4,
		mount_icon="zuoji_005",
		Cost = {
			[1] = 4036,
			[2] = 100,
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
		BuffDesc="\n\n骑乘[color=#aa2736]霸天虎[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]30%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="3000",
	},
	[20] = { 
		ID=20,
		Name="青木神龙",
		grade=4,
		mount_icon="zuoji_009",
		Cost = {
			[1] = 4037,
			[2] = 100,
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
		BuffDesc="\n\n骑乘[color=#aa2736]青木神龙[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]40%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="4000",
	},
	[21] = { 
		ID=21,
		Name="乌龙驹",
		grade=5,
		mount_icon="zuoji_000",
		Cost = {
			[1] = 4034,
			[2] = 150,
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
		BuffDesc="\n\n骑乘[color=#c56d20]乌龙驹[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]20%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="2000",
	},
	[22] = { 
		ID=22,
		Name="铁甲犀牛",
		grade=5,
		mount_icon="zuoji_002",
		Cost = {
			[1] = 4035,
			[2] = 150,
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
		BuffDesc="\n\n骑乘[color=#c56d20]铁甲犀牛[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]25%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="2500",
	},
	[23] = { 
		ID=23,
		Name="追风豹",
		grade=5,
		mount_icon="zuoji_001",
		Cost = {
			[1] = 3969,
			[2] = 150,
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
		BuffDesc="\n\n骑乘[color=#c56d20]追风豹[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]30%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="3000",
	},
	[24] = { 
		ID=24,
		Name="霸天虎",
		grade=5,
		mount_icon="zuoji_005",
		Cost = {
			[1] = 4036,
			[2] = 150,
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
		BuffDesc="\n\n骑乘[color=#c56d20]霸天虎[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]40%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="4000",
	},
	[25] = { 
		ID=25,
		Name="青木神龙",
		grade=5,
		mount_icon="zuoji_009",
		Cost = {
			[1] = 4037,
			[2] = 150,
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
		BuffDesc="\n\n骑乘[color=#c56d20]青木神龙[/color]时[color=#5c5140]移动速度[/color]增加[color=#099613]50%[/color]",
		BattleSkill_Type="9",
		BattleSkill_Value="5000",
	},
}
return config
