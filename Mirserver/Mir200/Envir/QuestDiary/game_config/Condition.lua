local config = { 
	[1] = { 
		Condition="<$LEVEL> >= 1",
	},
	[3] = { 
		Condition="<$LEVEL> >= 3",
	},
	[5] = { 
		Condition="<$LEVEL> >= 5",
	},
	[10] = { 
		Condition="<$LEVEL> >= 10",
	},
	[15] = { 
		Condition="<$LEVEL> >= 15",
	},
	[20] = { 
		Condition="<$LEVEL> >= 20",
	},
	[25] = { 
		Condition="<$LEVEL> >= 25",
	},
	[30] = { 
		Condition="<$LEVEL> >= 30",
	},
	[35] = { 
		Condition="<$LEVEL> >= 35",
	},
	[40] = { 
		Condition="<$LEVEL> >= 40",
	},
	[45] = { 
		Condition="<$LEVEL> >= 45",
	},
	[50] = { 
		Condition="<$LEVEL> >= 50",
	},
	[55] = { 
		Condition="<$LEVEL> >= 55",
	},
	[60] = { 
		Condition="<$LEVEL> >= 60",
	},
	[64] = { 
		Condition="<$LEVEL> >= 64",
	},
	[65] = { 
		Condition="<$LEVEL> >= 65",
	},
	[68] = { 
		Condition="<$LEVEL> >= 68",
	},
	[70] = { 
		Condition="<$LEVEL> >= 70",
	},
	[71] = { 
		Condition="<$LEVEL> >= 71",
	},
	[74] = { 
		Condition="<$LEVEL> >= 74",
	},
	[75] = { 
		Condition="<$LEVEL> >= 75",
	},
	[77] = { 
		Condition="<$LEVEL> >= 77",
	},
	[80] = { 
		Condition="<$LEVEL> >= 80",
	},
	[84] = { 
		Condition="<$LEVEL> >= 84",
	},
	[85] = { 
		Condition="<$LEVEL> >= 85",
	},
	[88] = { 
		Condition="<$LEVEL> >= 88",
	},
	[90] = { 
		Condition="<$LEVEL> >= 90",
	},
	[91] = { 
		Condition="<$LEVEL> >= 91",
	},
	[94] = { 
		Condition="<$LEVEL> >= 94",
	},
	[95] = { 
		Condition="<$LEVEL> >= 95",
	},
	[97] = { 
		Condition="<$LEVEL> >= 97",
	},
	[100] = { 
		Condition="<$LEVEL> >= 100",
	},
	[104] = { 
		Condition="<$LEVEL> >= 104",
	},
	[105] = { 
		Condition="<$LEVEL> >= 105",
	},
	[108] = { 
		Condition="<$LEVEL> >= 108",
	},
	[110] = { 
		Condition="<$LEVEL> >= 110",
	},
	[115] = { 
		Condition="<$LEVEL> >= 115",
	},
	[120] = { 
		Condition="<$LEVEL> >= 120",
	},
	[125] = { 
		Condition="<$LEVEL> >= 125",
	},
	[130] = { 
		Condition="<$LEVEL> >= 130",
	},
	[135] = { 
		Condition="<$LEVEL> >= 135",
	},
	[140] = { 
		Condition="<$LEVEL> >= 140",
	},
	[145] = { 
		Condition="<$LEVEL> >= 145",
	},
	[150] = { 
		Condition="<$LEVEL> >= 150",
	},
	[160] = { 
		Condition="<$LEVEL> >= 160",
	},
	[10001] = { 
		Condition="<$LEVEL> >= 26|<$ABIL_1> < 9000",
	},
	[10002] = { 
		Condition="[1] | <$YEAR> == 2025",
	},
	[10003] = { 
		Condition="<$USERNAME> EQU Ãû×Ö",
	},
	[20001] = { 
		Condition="<$str(T10)> == 123",
	},
	[20002] = { 
		Condition="<T10#VIPµÈ¼¶> == 10",
	},
	[30001] = { 
		Condition="<$KFDAY> >= 100",
	},
	[40001] = { 
		Condition="<$LEVEL> >= 10 & <$LEVEL> < 30",
	},
	[40002] = { 
		Condition="<$LEVEL> >= 30",
	},
	[50001] = { 
		Condition="<$RANDOM_5> == 1",
	},
	[50002] = { 
		Condition="<$RANDOM_4> == 1",
	},
	[50003] = { 
		Condition="<$RANDOM_3> == 1",
	},
	[50004] = { 
		Condition="<$RANDOM_2> == 1",
	},
	[50005] = { 
		Condition="<$RANDOM_1> == 0",
	},
	[50006] = { 
		Condition="<$RANDOM_6> == 1",
	},
	[61000] = { 
		Condition="<$JOB> == 1",
	},
	[61001] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 1 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 0",
	},
	[61002] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 10 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 1",
	},
	[61003] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 1",
	},
	[61004] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 2",
	},
	[61005] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 3",
	},
	[61006] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 4",
	},
	[61007] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 5",
	},
	[61008] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 6",
	},
	[61009] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 7",
	},
	[61010] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 8",
	},
	[61011] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 9",
	},
	[61012] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 1",
	},
	[61013] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 2",
	},
	[61014] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 3",
	},
	[61015] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 4",
	},
	[61016] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 5",
	},
	[61017] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 6",
	},
	[61018] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 7",
	},
	[61019] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 8",
	},
	[61020] = { 
		Condition="<$JOB> == 1 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 9",
	},
	[62000] = { 
		Condition="<$JOB> == 2",
	},
	[62001] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 1 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 0",
	},
	[62002] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 10 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 1",
	},
	[62003] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 1",
	},
	[62004] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 2",
	},
	[62005] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 3",
	},
	[62006] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 4",
	},
	[62007] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 5",
	},
	[62008] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 6",
	},
	[62009] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 7",
	},
	[62010] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 8",
	},
	[62011] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 9",
	},
	[62012] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 1",
	},
	[62013] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 2",
	},
	[62014] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 3",
	},
	[62015] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 4",
	},
	[62016] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 5",
	},
	[62017] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 6",
	},
	[62018] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 7",
	},
	[62019] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 8",
	},
	[62020] = { 
		Condition="<$JOB> == 2 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 9",
	},
	[63000] = { 
		Condition="<$JOB> == 3",
	},
	[63001] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 1 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 0",
	},
	[63002] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 10 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 1",
	},
	[63003] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 1",
	},
	[63004] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 2",
	},
	[63005] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 3",
	},
	[63006] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 4",
	},
	[63007] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 5",
	},
	[63008] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 6",
	},
	[63009] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 7",
	},
	[63010] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 8",
	},
	[63011] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 9",
	},
	[63012] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 1",
	},
	[63013] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 2",
	},
	[63014] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 3",
	},
	[63015] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 4",
	},
	[63016] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 5",
	},
	[63017] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 6",
	},
	[63018] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 7",
	},
	[63019] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 8",
	},
	[63020] = { 
		Condition="<$JOB> == 3 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 9",
	},
	[64000] = { 
		Condition="<$JOB> == 4",
	},
	[64001] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 1 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 0",
	},
	[64002] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 10 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 1",
	},
	[64003] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 1",
	},
	[64004] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 2",
	},
	[64005] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 3",
	},
	[64006] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 4",
	},
	[64007] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 5",
	},
	[64008] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 6",
	},
	[64009] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 7",
	},
	[64010] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 8",
	},
	[64011] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 9",
	},
	[64012] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 1",
	},
	[64013] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 2",
	},
	[64014] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 3",
	},
	[64015] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 4",
	},
	[64016] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 5",
	},
	[64017] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 6",
	},
	[64018] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 7",
	},
	[64019] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 8",
	},
	[64020] = { 
		Condition="<$JOB> == 4 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 9",
	},
	[65000] = { 
		Condition="<$JOB> == 5",
	},
	[65001] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 1 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 0",
	},
	[65002] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 10 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 1",
	},
	[65003] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 1",
	},
	[65004] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 2",
	},
	[65005] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 3",
	},
	[65006] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 4",
	},
	[65007] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 5",
	},
	[65008] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 6",
	},
	[65009] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 7",
	},
	[65010] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 8",
	},
	[65011] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 9",
	},
	[65012] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 1",
	},
	[65013] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 2",
	},
	[65014] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 3",
	},
	[65015] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 4",
	},
	[65016] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 5",
	},
	[65017] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 6",
	},
	[65018] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 7",
	},
	[65019] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 8",
	},
	[65020] = { 
		Condition="<$JOB> == 5 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 9",
	},
	[66000] = { 
		Condition="<$JOB> == 6",
	},
	[66001] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 1 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 0",
	},
	[66002] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 10 & <$TARGETINFO(GOODEVILID)> == 0 & <$RELEVEL> >= 1",
	},
	[66003] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 1",
	},
	[66004] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 2",
	},
	[66005] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 3",
	},
	[66006] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 4",
	},
	[66007] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 5",
	},
	[66008] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 6",
	},
	[66009] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 7",
	},
	[66010] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 8",
	},
	[66011] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 1 & <$RELEVEL> >= 9",
	},
	[66012] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 35 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 1",
	},
	[66013] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 60 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 2",
	},
	[66014] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 80 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 3",
	},
	[66015] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 100 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 4",
	},
	[66016] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 115 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 5",
	},
	[66017] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 120 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 6",
	},
	[66018] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 130 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 7",
	},
	[66019] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 140 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 8",
	},
	[66020] = { 
		Condition="<$JOB> == 6 & <$LEVEL> >= 150 & <$TARGETINFO(GOODEVILID)> == 2 & <$RELEVEL> >= 9",
	},
}
return config
