local config = {
	[1] = {
		idx=1,
		btnfont="无损原地复活！",
		xhitem_arr = {
			[1] = 5,
			[2] = 5,
		},
		hpmp_arr = {
			[1] = 100,
			[2] = 100,
		},
		title="复活方式",
		realive=120,
		realivefont="%s秒后自动复活",
	},
	[2] = {
		idx=2,
		btnfont="原地复活（丢失%s%%经验！）",
		exp=1,
		xhitem_arr = {
			[1] = 17,
			[2] = 500,
		},
		hpmp_arr = {
			[1] = 100,
			[2] = 100,
		},
	},
	[3] = {
		idx=3,
		btnfont="回城满血复活（丢失%s%%经验！）",
		exp=1,
		hpmp_arr = {
			[1] = 100,
			[2] = 100,
		},
	},
}
return config
