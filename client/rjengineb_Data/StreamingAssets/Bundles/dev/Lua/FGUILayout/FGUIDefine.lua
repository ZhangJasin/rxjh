--FGUI界面层级定义,可增加自定义
FGUI_LAYER = {
	BG = 1,
	NORMAL  = 1000,
	NOTICE  = 10000,
	LOADING = 15000,
	TOP     = 20000,
}

FGUIDefine = {}

-- 主界面层级顺序
FGUIDefine.MainOrder = {
	Drop = 0,
	Main = 1,
	PCMainChat = 2,
	PCMainTeam = 3,

	SUI = 10,
	TracePoint = 11,
	PickItem = 12,
	FindTarget = 99,
}


------------------------------------------------------------------------------------------------------------------------
-- 设置面板
FGUIDefine.SettingPage = {
	System			= 1,
	Fight			= 2,
	Display			= 3,
	AutoFight		= 4,
	KeyBoard		= 5,
}

-- 好友
FGUIDefine.FriendPage = {
	Recent			= 1,
	Friend			= 2,
	Enemy			= 3,
	Black			= 4,
}

-- 好友操作
FGUIDefine.FriendOpreate = {
	Add				= 1,
	Apply			= 2,
}

-- 组队
FGUIDefine.TeamPage = {
	MyTeam			= 1,
	NearPlayer		= 2,
	NearTeam		= 3,
	ApplyList		= 4,
}

--提示气泡 样式类型
--根据Main/ButtonBubbleTip 控制器配置
FGUIDefine.BubbleTipType = {
	Chat = 0,
	Mail = 1,
	Bag = 2,
	Friend = 3,
	Guild = 4,
	Team = 5,
}

---------------------------------------------------------------------------
-- 特殊属性ID
FGUIDefine.SpecialAttType = {
	Min_ATK			= 21,
	Max_ATK			= 22,
	ATK				= 23,
}
local specialAttTab = FGUIDefine.SpecialAttType

-- 合并显示属性 
FGUIDefine.MergeAttConfig = {
	[specialAttTab.Min_ATK]		= {specialAttTab.Min_ATK, specialAttTab.Max_ATK},
    [specialAttTab.Max_ATK]		= {specialAttTab.Min_ATK, specialAttTab.Max_ATK},
}

-- 物品规则
local itemArticleType = {
    TYPE_DROP                               = 1,    -- 禁止丢弃
    TYPE_TRADE                              = 2,    -- 禁止交易
    TYPE_STORAGE_STORE                      = 3,    -- 禁止存仓库
    TYPE_FIX                                = 4,    -- 禁止修理
    TYPE_SELL                               = 5,    -- 禁止出售
    TYPE_DIE_NOT_DROP                       = 6,    -- 禁止爆出
    TYPE_DROP_HIDE                          = 7,    -- 丢弃消失
    TYPE_DIE_DROP                           = 8,    -- 死亡必爆
    TYPE_TRADE_AUCTION                      = 9,    -- 禁止拍卖 [摆摊和上架拍卖行、交易行]
	TYPE_STALL								= 10,	-- 禁止摆摊
}
FGUIDefine.ItemArticleType = itemArticleType


FGUIDefine.GuideDataKey = {
	SUIRoot 			= 1,
	ChatHideFunc 		= 2,
	BagGuideFunc 		= 3,
	MissionGuideFunc 	= 4,
	SkillGuideFunc 		= 5,
}

FGUIDefine.TeamPickType = {
	Freedom 			= 0,	--自由分配
	Random 				= 1,	--随机分配
	Sequence 			= 2,	--顺序分配
	Learder 			= 3,	--队长分配
}

FGUIDefine.PCQuickType = {
	Item 				= 0,
	Skill 				= 1,
}

FGUIDefine.SkillTipOp = {
	Set 				= 0,	--配置
	Study 				= 1,	--修炼
	Upgrade 			= 2,	--升级
	Close 				= 3,	--关闭
}

-- 仅限pc背包绑定PCBagViewModel使用
FGUIDefine.BindParentView = {
	PCBagPanel = 1, 					-- 背包
	PCEquipBar = 2, 					-- 小版背包
	PCStoragePanel = 3, 				-- 仓库
	PCTradeMain = 4, 					-- 交易
	PCStallMain = 5,					-- 摆摊
}

FGUIDefine.DelayClickTime = 0.2

