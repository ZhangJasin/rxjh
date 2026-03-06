local config = { 
	[1] = { 
		nId=1,
		sName="好友",
		nMaxMember=5,
		sTrigger="@sFriend",
		nDisAction=0,
		bNeedAgree=1,
		arrMutex="{2}",
		bSave=1,
	},
	[2] = { 
		nId=2,
		sName="黑名单",
		nMaxMember=5,
		sTrigger="@sBlack",
		nDisAction=1,
		bNeedAgree=0,
		arrMutex="{1}",
		bSave=1,
	},
	[3] = { 
		nId=3,
		sName="临时关系",
		nMaxMember=10,
		sTrigger="@sTempRelation",
		sCondition=10001,
		nDisAction=0,
		bNeedAgree=1,
		bSave=0,
	},
}
return config
