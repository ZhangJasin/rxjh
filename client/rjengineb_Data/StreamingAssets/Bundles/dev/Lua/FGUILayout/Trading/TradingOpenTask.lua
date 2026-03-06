local TradingOpenTask = class("TradingOpenTask")
function TradingOpenTask:ctor()

end

function TradingOpenTask:InitData()
	global.TradingBagPanelDatas.rows_per_page = 6 -- 每页显示的背包装备行数 这个数据需要自己配置 默认官方 6 个
	global.TradingBagPanelDatas.cols_per_page = 6 -- 每页显示的背包装备列数 这个数据需要自己配置 默认官方 6 个
end

function TradingOpenTask:Enter()
	-- 交易行 官方截图需要打开的默认页面，因为你们可能二次修改代码结构，务必保证截图的时候不要报错，
	-- 如果代码接口不一致没办法兼容可以删除部分页面，通过SL:AddTradingCustomCaptureTaskLua自定义截图api接口操作
	local str = SL:GetMetaValue("TRADING_BANK_TYPE") and "" or "_images" --勿删，下面参数position用来区分九九交易行和盒子交易行
	global.TradingOpenTaskDatas  = {}
	global.TradingOpenTaskDatas = {
		{
		-- 状态页（equip）首页图
			open = function(itemdata)
				self:InitData() -- 勿删 勿删 勿删 务必手动改下背包装备视图行数和列数 官方默认 6*6 的显示一页
				FGUI:Open("Bag", "PlayerInfoPanel", itemdata)
			end,
			close = function()
				FGUI:Close("Bag", "PlayerInfoPanel")
			end,
			extent = { typeCapture = 1, index = 2, home = 1, packagename = "Bag", componentName = "PlayerInfoPanel" },
			position = "equip"..str
		},
		
		{
		-- 状态页（equip）
			open = function(itemdata)
				FGUI:Open("Bag", "PlayerInfoPanel", itemdata)
			end,
			close = function()
				FGUI:Close("Bag", "PlayerInfoPanel")
			end,
			extent = { typeCapture = 1, index = 2, packagename = "Bag", componentName = "PlayerInfoPanel" },
			position = "equip"..str
		},

		-- 装备页（equip）
		{
			open = function(itemdata)
				FGUI:Open("Bag", "PlayerInfoPanel", itemdata)
			end,
			close = function()
				FGUI:Close("Bag", "PlayerInfoPanel")
			end,
			extent = { typeCapture = 1, index = 1, packagename = "Bag", componentName = "PlayerInfoPanel" },
			position = "equip"..str
		},

		-- 状态（status）
		{
			open = function(itemdata) 
				FGUI:Open("Bag", "PlayerInfoPanel", itemdata) 
			end,
			close = function() 
				FGUI:Close("Bag", "PlayerInfoPanel") 
			end,
			extent = { typeCapture = 1, index = 2, packagename = "Bag", componentName = "PlayerInfoPanel" },
			position = "status"..str
		},
		-- 状态 滑动到底页内容（status）
		{
			open = function(itemdata) 
				FGUI:Open("Bag", "PlayerInfoPanel", itemdata) 
			end,
			close = function() 
				FGUI:Close("Bag", "PlayerInfoPanel")
			end,
			extent = { typeCapture = 1, index = 2, tradingIndex = 2, packagename = "Bag", componentName = "PlayerInfoPanel" },
			position = "status"..str
		},

		-- 背包（bag）
		{
			open = function(itemdata) 
				FGUI:Open("Bag", "PlayerInfoPanel", itemdata) 
			end,
			close = function() 
				FGUI:Close("Bag", "PlayerInfoPanel") 
			end,
			extent = { typeCapture = 1, index = 1, bag = 1, packagename = "Bag", componentName = "PlayerInfoPanel" },
			position = "bag"..str
		},

		-- 背包（bag）货币
		{
			open = function(itemdata) 
				FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA", "BagMoneyList"))
			end,
			close = function() 
				FGUIFunction:HideTopCurrency()
			end,
			extent = { typeCapture = 1, index = 1, bag = 1, packagename = "TopCurrency", componentName = "TopCurrencyPanel" },
			position = "bag"..str
		},

		-- 属性 / 排行榜（attribute）
		{
			open = function(itemdata) 
				FGUI:Open("Rank", "RankPanel", itemdata) 
			end,
			close = function() 
				FGUI:Close("Rank", "RankPanel") 
			end,
			extent = { typeCapture = 1, packagename = "Rank", componentName = "RankPanel" },
			position = "attribute"..str
		},

		-- 四个技能主面板（SkillFramePanel）
		-- 职业武功
		{
			open = function(itemdata) 
				FGUI:Open("Skill", "SkillFramePanel", itemdata) 
			end,
			close = function()
				FGUI:Close("Skill", "SkillFramePanel")
			end,
			extent = { typeCapture = 1, index = 1, packagename = "Skill", componentName = "SkillFramePanel" },
			position = "skill"..str
		},

		-- 通用武功
		{
			open = function(itemdata) 
				FGUI:Open("Skill", "SkillFramePanel", itemdata) 
			end,
			close = function()
				FGUI:Close("Skill", "SkillFramePanel")
			end,
			extent = { typeCapture = 1, index = 1, tradingIndex = 1, packagename = "Skill", componentName = "SkillFramePanel" },
			position = "skill"..str
		},

		-- 通用气功
		{
			open = function(itemdata) 
				FGUI:Open("Skill", "SkillFramePanel", itemdata) 
			end,
			close = function()
				FGUI:Close("Skill", "SkillFramePanel")
			end,
			extent = { typeCapture = 1, index = 2, packagename = "Skill", componentName = "SkillFramePanel" },
			position = "skill"..str
		},

		-- 登封气功
		{
			open = function(itemdata) 
				FGUI:Open("Skill", "SkillFramePanel", itemdata) 
			end,
			close = function()
				FGUI:Close("Skill", "SkillFramePanel")
			end,
			extent = { typeCapture = 1, index = 2, tradingIndex = 1, packagename = "Skill", componentName = "SkillFramePanel" },
			position = "skill"..str
		},

		-- 仓库（warehouse）
		{
			open = function(itemdata)
				itemdata.fromPanel = 1
				FGUI:Open("Bag", "StoragePanel", itemdata)
			end,
			close = function() 
				FGUI:Close("Bag", "StoragePanel")
			end,
			extent = { typeCapture = 1, packagename = "Bag", componentName = "StoragePanel" },
			position = "warehouse"..str
		},

		-- 额外仓库（warehouse）
		{
			open = function(itemdata) 
				FGUI:Open("Bag", "StorageExPanel", itemdata)
			end,
			close = function()
				FGUI:Close("Bag", "StorageExPanel")
				FGUI:Close("Bag", "PlayerInfoPanel")
			end,
			extent = { typeCapture = 1, packagename = "Bag", componentName = "StorageExPanel" },
			position = "warehouse"..str
		}
	}

end

function TradingOpenTask:Exit()
end

return  TradingOpenTask.new()