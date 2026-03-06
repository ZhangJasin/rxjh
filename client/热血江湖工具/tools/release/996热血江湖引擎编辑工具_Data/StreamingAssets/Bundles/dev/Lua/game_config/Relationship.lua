local config = { 
	[1] = { 
		nId=1,
		sName="好友",
		nMaxMember=5,
		arrMutex="{2}",
		nShow=1,
	},
	[2] = { 
		nId=2,
		sName="黑名单",
		nMaxMember=5,
		arrMutex="{1}",
		nShow=1,
	},
	[3] = { 
		nId=3,
		sName="临时关系",
		nMaxMember=10,
		nShow=1,
	},
}
return config
