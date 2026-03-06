local config = { 
	[1] = { 
		ID=1,
		PackageName ="Bag",
		ComponentName="BagRecyclePanel",
		Desc="回收",
		Func="Open",
	},
	[2] = { 
		ID=2,
		PackageName ="Mount",
		ComponentName="mountMain",
		Desc="坐骑",
		Func="Open",
	},
	[3] = { 
		ID=3,
		PackageName ="FactionWar",
		ComponentName="FactionWarPanel",
		Desc="门派战",
		Func="Open",
	},
	[4] = { 
		ID=4,
		PackageName ="TreasureShop",
		ComponentName="TreasurePanel",
		Desc="百宝阁",
		Func="RequestGroupData",
	},
	[5] = { 
		ID=5,
		PackageName ="Auction",
		ComponentName="AuctionRootPanel",
		Desc="拍卖行",
		Func="Open",
	},
	[6] = { 
		ID=6,
		PackageName ="Apanl",
		ComponentName="BossFuBenPanl",
		Desc="副本BOSS",
		Func="Open",
	},
	[7] = { 
		ID=7,
		PackageName ="PersonFuBen",
		ComponentName="PersonFuBenPanel",
		Desc="产出副本",
		Func="Open",
	},
	[8] = { 
		ID=8,
		PackageName ="Stall",
		ComponentName="StallMain",
		Desc="摆摊",
		Func="Open",
	},
}
return config
