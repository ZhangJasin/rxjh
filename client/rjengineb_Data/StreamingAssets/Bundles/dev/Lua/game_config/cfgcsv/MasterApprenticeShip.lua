local config = { 
	["min_apply_master_lv"] = { 
		ID="min_apply_master_lv",
		VALUE=10,
		Dec="最低申请拜师等级",
	},
	["min_apply_master_zs"] = { 
		ID="min_apply_master_zs",
		VALUE=1,
		Dec="最低申请拜师转职",
	},
	["min_apply_apparenice_lv"] = { 
		ID="min_apply_apparenice_lv",
		VALUE=20,
		Dec="最低申请收徒等级",
	},
	["min_apply_apparenice_zs"] = { 
		ID="min_apply_apparenice_zs",
		VALUE=2,
		Dec="最低申请收徒转职",
	},
	["min_apply"] = { 
		ID="min_apply",
		VALUE=20,
		Dec="最低相差等级可申请拜师或者收徒",
	},
	["master_award"] = { 
		ID="master_award",
		VALUE=2401,
		Dec="师傅出师奖励普通",
	},
	["apparenice_award"] = { 
		ID="apparenice_award",
		VALUE=2402,
		Dec="徒弟出师奖励普通",
	},
	["master_award_high"] = { 
		ID="master_award_high",
		VALUE=2403,
		Dec="师傅出师奖励高级",
	},
	["apparenice_award_high"] = { 
		ID="apparenice_award_high",
		VALUE=2404,
		Dec="徒弟出师奖励高级",
	},
	["max_apparenice_num"] = { 
		ID="max_apparenice_num",
		VALUE=3,
		Dec="最多徒弟数量",
	},
	["max_show_master"] = { 
		ID="max_show_master",
		VALUE=3,
		Dec="寻找师傅列表显示最多数量",
	},
	["max_show_apparenice"] = { 
		ID="max_show_apparenice",
		VALUE=3,
		Dec="寻找徒弟列表显示最多数量",
	},
}
return config
