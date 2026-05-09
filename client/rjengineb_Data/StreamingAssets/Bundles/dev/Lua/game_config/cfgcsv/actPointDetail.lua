local config = { 
	[1] = { 
		idx=1,
		dec="完成一次门派捐献",
		openUI=1,
		limitTimes=5,
		point=2,
	},
	[2] = { 
		idx=2,
		dec="完成一次门派任务",
		openUI=1,
		limitTimes=5,
		point=5,
	},
	[3] = { 
		idx=3,
		dec="装备强化一次",
		limitTimes=2,
		point=5,
	},
	[4] = { 
		idx=4,
		dec="击杀任意一次BOSS",
		limitTimes=5,
		point=10,
	},
	[5] = { 
		idx=5,
		dec="商店任意消费一次",
		limitTimes=1,
		point=10,
	},
	[6] = { 
		idx=6,
		dec="完成一次BOSS狩猎",
		openUI=2,
		limitTimes=5,
		point=5,
	},
	[7] = { 
		idx=7,
		dec="消耗银两50万",
		limitTimes=1,
		point=10,
	},
	[8] = { 
		idx=8,
		dec="击杀500只怪物",
		limitTimes=1,
		point=20,
	},
}
return config
