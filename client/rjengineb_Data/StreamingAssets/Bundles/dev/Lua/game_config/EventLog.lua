local config = { 
	[1] = { 
		EventId=1,
		EventStr="%s创建了行会",
		EventGroup=1,
		EventMaxCnt=100,
	},
	[2] = { 
		EventId=2,
		EventStr="%s加入了行会",
		EventGroup=1,
		EventMaxCnt=100,
	},
	[3] = { 
		EventId=3,
		EventStr="%s退出了行会",
		EventGroup=1,
		EventMaxCnt=100,
	},
	[4] = { 
		EventId=4,
		EventStr="%s将%s职位调整为%s",
		EventGroup=1,
		EventMaxCnt=100,
	},
	[5] = { 
		EventId=5,
		EventStr="%s被%s踢出了行会",
		EventGroup=1,
		EventMaxCnt=100,
	},
	[6] = { 
		EventId=6,
		EventStr="%s捐献了%s贡献值",
		EventGroup=1,
		EventMaxCnt=100,
	},
	[7] = { 
		EventId=7,
		EventStr="行会等级提升到%s",
		EventGroup=1,
		EventMaxCnt=100,
	},
}
return config
