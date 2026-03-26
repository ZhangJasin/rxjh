local config = { 
	[1] = { 
		ID=1,
		Name="龙猫",
		grade=1,
		mount_icon="pet_000",
		Cost = {
			[1] = 2701,
			[2] = 1,
		},
		Model=900001,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 50,
			},
			[2] = {
				[1] = 2,
				[2] = 50,
			},
			[3] = {
				[1] = 115,
				[2] = 20,
			},
		},
		buffID = {
			[1] = 110017,
		},
		BuffDesc="风驰Lv.1：永久提升角色移动速度<font color='#00FF00'>5%</font>",
		Condition=1,
	},
	[2] = { 
		ID=2,
		Name="雪翼雕",
		grade=1,
		mount_icon="pet_001",
		Cost = {
			[1] = 2704,
			[2] = 1,
		},
		Model=900004,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 50,
			},
			[2] = {
				[1] = 2,
				[2] = 50,
			},
			[3] = {
				[1] = 69,
				[2] = 10,
			},
		},
		BuffDesc="庇佑Lv.1：角色受到攻击时几率触发庇佑，提升<font color='#00FF00'>3%</font>防御力，持续10秒",
		Condition=1,
		PassiveAttachCond=301,
		PassiveName="庇护Lv1",
		BaseProb="80",
		Param2="110020",
	},
	[3] = { 
		ID=3,
		Name="白猫",
		grade=1,
		mount_icon="pet_002",
		Cost = {
			[1] = 2707,
			[2] = 1,
		},
		Model=900007,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 50,
			},
			[2] = {
				[1] = 2,
				[2] = 50,
			},
			[3] = {
				[1] = 69,
				[2] = 10,
			},
		},
		BuffDesc="治愈Lv.1：永久提升角色药品恢复效果<font color='#00FF00'>5%</font>",
		Condition=1,
		PassiveAttachCond=201,
		PassiveName="治愈Lv1",
		Param1="6",
		Param2="0.05",
	},
	[4] = { 
		ID=4,
		Name="冰翼",
		grade=1,
		mount_icon="pet_003",
		Cost = {
			[1] = 2710,
			[2] = 1,
		},
		Model=900010,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 50,
			},
			[2] = {
				[1] = 2,
				[2] = 50,
			},
			[3] = {
				[1] = 23,
				[2] = 10,
			},
		},
		buffID = {
			[1] = 110026,
		},
		BuffDesc="收割Lv.1：永久提升角色最大生命值<font color='#00FF00'>5%</font>，每击杀一只怪物回复角色<font color='#00FF00'>5%</font>生命值与内力值",
		Condition=1,
		PassiveAttachCond=1,
		PassiveName="收割Lv1",
		Param2="1#500|2#500",
	},
	[5] = { 
		ID=5,
		Name="小女巫",
		grade=1,
		mount_icon="pet_004",
		Cost = {
			[1] = 2713,
			[2] = 1,
		},
		Model=900013,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 30,
			},
			[2] = {
				[1] = 2,
				[2] = 30,
			},
			[3] = {
				[1] = 115,
				[2] = 10,
			},
		},
		Condition=1,
	},
	[6] = { 
		ID=6,
		Name="小白兔",
		grade=1,
		mount_icon="pet_005",
		Cost = {
			[1] = 2715,
			[2] = 1,
		},
		Model=900015,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 30,
			},
			[2] = {
				[1] = 2,
				[2] = 30,
			},
			[3] = {
				[1] = 115,
				[2] = 10,
			},
		},
		buffID = {
			[1] = 110038,
		},
		BuffDesc="影之舞Lv.1：永久提升角色会心伤害减免<font color='#00FF00'>6%</font>，血量低于50%</font>时触发影之舞，武功闪避提升<font color='#00FF00'>100%</font>，持续2秒，冷却60秒",
		Condition=1,
		PassiveAttachCond=501,
		PassiveName="影之舞lv1",
		BaseProb="50",
		Param2="110038",
		Param3="60",
		Param4="2",
	},
	[7] = { 
		ID=7,
		Name="追风豹",
		grade=1,
		mount_icon="pet_006",
		Cost = {
			[1] = 2718,
			[2] = 1,
		},
		Model=900018,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 100,
			},
			[2] = {
				[1] = 2,
				[2] = 100,
			},
			[3] = {
				[1] = 23,
				[2] = 20,
			},
			[4] = {
				[1] = 115,
				[2] = 30,
			},
		},
		Condition=1,
	},
	[8] = { 
		ID=8,
		Name="霸天虎",
		grade=1,
		mount_icon="pet_007",
		Cost = {
			[1] = 2721,
			[2] = 1,
		},
		Model=900021,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 88,
			},
			[2] = {
				[1] = 2,
				[2] = 88,
			},
			[3] = {
				[1] = 23,
				[2] = 18,
			},
			[4] = {
				[1] = 115,
				[2] = 18,
			},
		},
		Condition=1,
	},
	[9] = { 
		ID=9,
		Name="青龙",
		grade=1,
		mount_icon="pet_008",
		Cost = {
			[1] = 2724,
			[2] = 1,
		},
		Model=900024,
		ClassID = {
			[1] = {
				[1] = 1,
				[2] = 108,
			},
			[2] = {
				[1] = 2,
				[2] = 108,
			},
			[3] = {
				[1] = 23,
				[2] = 28,
			},
			[4] = {
				[1] = 115,
				[2] = 58,
			},
		},
		buffID = {
			[1] = 110032,
		},
		BuffDesc="神龙庇佑Lv.1：永久提升角色会心伤害<font color='#00FF00'>8%</font>，血量低于25%时触发神龙庇佑，无敌3秒，冷却90秒",
		Condition=1,
		PassiveAttachCond=401,
		PassiveName="神龙庇佑Lv1",
		BaseProb="25",
		Param2="110035",
		Param3="90",
		Param4="3",
	},
}
return config
