local MentorShipPageBase = requireFGUILayout("MentorShip/MentorShipPageBase")
local MentorShipMain = class("MentorShipMain", MentorShipPageBase)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local Store = requireFGUILayout("MentorShip/MentorShipData")

local MasterApprenticeShip = require("game_config/cfgcsv/MasterApprenticeShip")
local MentorApplicationTask = requireFGUILayout("MentorShip/MentorApplicationTask")
local config = require("game_config/cfgcsv/Master_and_apprentice")


-- 与服务端交互使用
local CODE = {
	ERROR = 0,
	SNAPSHOT = 101,
	TASKS = 102,
	CLAIM_OK = 103,
	GRADUATE_OK = 104,
	PUSH_TASK = 201,
	PUSH_STATUS = 202,
}

local AVATOR_DATA = {}

function MentorShipMain.Create()
	return MentorShipMain.new()
end

function MentorShipMain:Enter()
	self:RegisterEvent()
	MentorShipMain.super.Enter(self)
	self._ui = FGUI:ui_delegate(self.component)
	self._store = Store.Get()
	self.MentorApplicationTask = MentorApplicationTask.Get()
	self._net = self._store.net
	self._op = self._store.op
	MentorShipMain.CCUI = self
	self._store:GetMyRelation('MentorShipMain')
	self:InitData()
	self:InitEvent()
	self:InitPage()
	self.rightController = FGUI:getController(self.component, "RightState")
	self:_RegisterNet()
	self._store:NetSend(self._op.GET_STATUS, 0, 0, nil)
	self:RefreshAll()
end

function MentorShipMain:Exit()
	self:_UnregisterNet()
	self:RemoveEvent()
	MentorShipMain.CCUI = nil
	MentorShipMain.super.Exit(self)
end

function MentorShipMain:InitData()
	self._hasRelation = false
	self._relationId = 0
	--我的师傅
	self._mentorInfo = nil
	--我的师徒
	self._apprenticeList = {}
	self.alMyRelationship = {}
	self._taskList = self.MentorApplicationTask:applictionTask() or {}
	self.setOutList = self.MentorApplicationTask:setOut() or {}
	self._apprenticeMax = MasterApprenticeShip["max_apparenice_num"].VALUE
	--选择右边信息
	self.selectWhich = 0
	--右边信息类型 1自己的 2 徒弟的
	self.rightInfoType = 0
	--右边显示数据
	self.taskProgressList = {}
	self._emptyMentorCond = {
		{
			text = "角色等级需达到" .. MasterApprenticeShip["min_apply_master_lv"].VALUE .. "级",
			check = function()
				return (SL:GetValue("LEVEL") or 1) >= tonumber(MasterApprenticeShip["min_apply_master_lv"].VALUE)
			end,
		},
		{
			text = "角色转职等级需达到" .. MasterApprenticeShip["min_apply_master_zs"].VALUE .. "级",
			check = function()
				return (SL:GetValue("RELEVEL") or 1) >= tonumber(MasterApprenticeShip["min_apply_master_zs"].VALUE)
			end,
		},
		{
			text = "角色出师次数小于" .. MasterApprenticeShip["max_chushi_times"].VALUE .. "次",
			check = function()
				print("判断出师次数")
				print(self.chushiCount)
				print(MasterApprenticeShip["max_chushi_times"].VALUE)
				return (self.chushiCount or 0) < tonumber(MasterApprenticeShip["max_chushi_times"].VALUE)
			end,
		},
		--仅展示条件
		{
			text = "等级低于师父5级以上",
			check = function()
				return true
			end,
		},
		{
			text = "师徒同一阵营",
			check = function()
				return true
			end,
		},
		{
			text = "师父数量小于1个",
			check = function()
				return self._mentorInfo == nil
			end,
		},
	}
	self._emptyApprenticeCond = {
		{
			text = "角色等级需达到" .. MasterApprenticeShip["min_apply_apparenice_lv"].VALUE .. "级",
			check = function()
				return (SL:GetValue("LEVEL") or 1) >= tonumber(MasterApprenticeShip["min_apply_apparenice_lv"].VALUE)
			end,
		},
		{
			text = "角色转职等级需达到" .. MasterApprenticeShip["min_apply_apparenice_zs"].VALUE .. "级",
			check = function()
				return (SL:GetValue("RELEVEL")) >= tonumber(MasterApprenticeShip["min_apply_apparenice_zs"].VALUE)
			end,
		},
		{
			text = "徒弟数量小于3个",
			check = function()
				return #self._apprenticeList < self._apprenticeMax
			end,
		},
		--仅展示条件
		{
			text = "等级高于徒弟5级以上",
			check = function()
				return true
			end,
		},
		{
			text = "师徒同一阵营",
			check = function()
				return true
			end,
		},
	}
	self._emptyMentorIntro = {
		{ text = "完成规定任务可获普通奖励", itemId = tonumber(MasterApprenticeShip["master_award"].VALUE) },
		{ text = "完成更多任务可获杰出奖励", itemId = tonumber(MasterApprenticeShip["master_award_high"].VALUE) },
	}
	self._emptyApprenticeIntro = {
		{ text = "完成规定任务可获普通奖励", itemId = tonumber(MasterApprenticeShip["apparenice_award"].VALUE) },
		{ text = "完成更多任务可获杰出奖励", itemId = tonumber(MasterApprenticeShip["apparenice_award_high"].VALUE) },
	}
end

function MentorShipMain:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_find_mentor, handler(self, self.OnClickFindMentor))
	FGUI:setOnClickEvent(self._ui.btn_find_apprentice, handler(self, self.OnClickFindApprentice))
	FGUI:setOnClickEvent(self._ui.btn_break, handler(self, self.OnClickBreak))

	FGUI:setOnClickEvent(self._ui.btn_cancel, handler(self, self.OnclickCancelBreak))

	FGUI:setOnClickEvent(self._ui.btn_applylist, handler(self, self.Onbtn_applylist))

	FGUI:GList_itemRenderer(self._ui.list_mentor, handler(self, self.RenderMentorSlot))
	FGUI:GList_itemRenderer(self._ui.list_apprentice, handler(self, self.RenderApprenticeSlot))
	FGUI:GList_itemRenderer(self._ui.list_tasks, handler(self, self.RenderTaskItem))
	FGUI:GList_itemRenderer(self._ui.list_graduate, handler(self, self.RenderSetOut))

	if self._ui.rtext_go then
		FGUI:GRichTextField_setUBBEnabled(self._ui.rtext_go, true)
		FGUI:GRichTextField_setText(self._ui.rtext_go, "[color=#28FAF0][url=go]前往仪式[/url][/color]")
		FGUI:GRichTextField_addOnLinkClickEvent(self._ui.rtext_go, handler(self, self.onClickChuShi))
	end
	if self._ui.rtext_reward then
		FGUI:GRichTextField_setUBBEnabled(self._ui.rtext_reward, true)
		FGUI:GRichTextField_setText(self._ui.rtext_reward, "[color=#28FAF0][url=go]出师奖励[/url][/color]")
		FGUI:GRichTextField_addOnLinkClickEvent(self._ui.rtext_reward, handler(self, self.onClickReward))
	end

	FGUI:GList_itemRenderer(self._ui.list_mentor_cond, handler(self, self.RenderMentorCondItem))
	FGUI:GList_itemRenderer(self._ui.list_apprentice_cond, handler(self, self.RenderApprenticeCondItem))
	FGUI:GList_itemRenderer(self._ui.list_mentor_intro, handler(self, self.RenderMentorIntroItem))
	FGUI:GList_itemRenderer(self._ui.list_apprentice_intro, handler(self, self.RenderApprenticeIntroItem))

	--测试数据
	FGUI:GRichTextField_setUBBEnabled(self._ui.rtext_done, true)
	FGUI:GRichTextField_setText(self._ui.rtext_done, "[color=#28FAF0][url=go]一键完成[/url][/color]")
	FGUI:GRichTextField_addOnLinkClickEvent(self._ui.rtext_done, function()
		print("测试完成所有任务")
		ssrMessage:sendmsgEx("MentorShip", "TestCompleteAllTasks")
	end)
end

function MentorShipMain:InitPage()
	FGUI:GList_setNumItems(self._ui.list_mentor, 1)
	FGUI:GList_setNumItems(self._ui.list_apprentice, self._apprenticeMax)
end

function MentorShipMain:resetDateView()
	self = MentorShipMain.CCUI
	self._store:GetMyRelation('MentorShipMain')
end

local function SetSlotFilled(item, filled)
	local frame = FGUI:GetChild(item, "frame")
	local btn_add = FGUI:GetChild(item, "btn_add")
	FGUI:setVisible(frame, filled)
	FGUI:setVisible(btn_add, not filled)
end
function MentorShipMain:setData(data)
	print("MentorShipMain:setData")
	--dump(data)
	if MentorShipMain.CCUI then
		self = MentorShipMain.CCUI
		self.alMyRelationship = data
		--我的师傅
		self._mentorInfo = data.myMaster
		--我的师徒
		self._apprenticeList = data.apprentice or {}
		self.taskProgressList = data.taskProgressList or {}
		--我的出师次数
		self.chushiCount = data.chushiCount or 0
		--我的徒弟的解除关系数据
		self.applyRemoveMyAppliction = data.applyRemoveMyAppliction
		self.applyRemoveMyMasterById = data.applyRemoveMyMasterById
		self.applyRemoveMyMaster = data.applyRemoveMyMaster
		self.myUserId = data.myUserId
		print("重新加载师徒关系")
		self._hasRelation = false
		self:RefreshAll()
	end
end

function MentorShipMain:resetData(data)
	self = MentorShipMain.CCUI
	self.alMyRelationship = data
	--我的徒弟的解除关系数据
	self.applyRemoveMyAppliction = data.applyRemoveMyAppliction
	self.applyRemoveMyMasterById = data.applyRemoveMyMasterById
	self.applyRemoveMyMaster = data.applyRemoveMyMaster
	self.taskProgressList = data.taskProgressList
	self._hasRelation = true
	self:RefreshAll()
end

function MentorShipMain:RenderMentorSlot(idx, item)
	local data = self._mentorInfo
	local vatar = FGUI:GetChild(item, "avator")
	local icon_job = FGUI:GetChild(item, "icon_job")
	local text_name = FGUI:GetChild(item, "text_name")
	local text_lv = FGUI:GetChild(item, "text_level")
	local text_st = FGUI:GetChild(item, "text_state")
	local btn_add = FGUI:GetChild(item, "btn_add")
	local btn_info = FGUI:GetChild(item, "btn_info")

	if data then
		FGUI:GTextField_setText(text_name, data.UserName or "--")
		FGUI:GTextField_setText(text_lv, "Lv." .. tostring(data.Level or 1))
		local online = (data.IsOnline ~= nil) and data.IsOnline or data.online
		FGUI:GTextField_setText(text_st, online and "在线" or "离线")
		FGUI:GTextField_setColor(text_st, online and "#41E63D" or "#5D6E74")
		local targetID = data.UserID
		if icon_job then
			FGUI:GLoader_setUrl(icon_job, FGUIFunction:GetJobUrl(data.Job))
		end
		if vatar then
			if FGUIFunction.ClearCommonPlayerFrame then
				FGUIFunction:ClearCommonPlayerFrame(vatar)
			end
			AVATOR_DATA.AvatarID = data.AvatarID
			AVATOR_DATA.Job = data.Job
			AVATOR_DATA.Sex = data.Sex
			AVATOR_DATA.FrameID = data.PhotoframeID
			FGUIFunction:SetCommonPlayerFrame(vatar, AVATOR_DATA)
		end
		SetSlotFilled(item, true)
		if btn_info then
			FGUI:setOnClickEvent(btn_info, function()
				local dockEnum = (SL and SL.GetValue and SL:GetValue("DOCKTYPE_NENUM")) or {}
				FGUIFunction:OpenFuncDockTips({
					targetId = tonumber(targetID),
					AvatarID = data.AvatarID,
					Job = data.Job,
					Sex = data.Sex,
					targetName = data.UserName,
					Level = data.Level,
					GuildName = data.GuildName,
					TipsType = isTeamMember and SL:GetValue("DOCKTYPE_NENUM").Func_Team or
						SL:GetValue("DOCKTYPE_NENUM").Func_Near_Player,
					FrameID = data.PhotoframeID
				})
			end)
		end
		FGUI:setOnClickEvent(item, function()
			self.selectWhich   = idx
			self.rightInfoType = 1
			self:selectedItem(item)
			ssrMessage:sendmsgEx("MentorShip", "getApprenticeInfo",
				{ UserID = self.myUserId, fromPanel = 'MentorShipMain' })
		end)
	else
		FGUI:GTextField_setText(text_name, "")
		FGUI:GTextField_setText(text_lv, "")
		FGUI:GTextField_setText(text_st, "")
		if icon_job then
			FGUI:GLoader_setUrl(icon_job, "")
		end
		if vatar and FGUIFunction.ClearCommonPlayerFrame then
			FGUIFunction:ClearCommonPlayerFrame(vatar)
		end
		SetSlotFilled(item, false)
		if btn_add then
			FGUI:setOnClickEvent(btn_add, handler(self, self.OnClickFindMentor))
		end
	end
end

function MentorShipMain:RenderApprenticeSlot(idx, item)
	local data = self._apprenticeList[idx + 1]
	local vatar = FGUI:GetChild(item, "avator")
	local icon_job = FGUI:GetChild(item, "icon_job")
	local text_name = FGUI:GetChild(item, "text_name")
	local text_lv = FGUI:GetChild(item, "text_level")
	local text_st = FGUI:GetChild(item, "text_state")
	local btn_add = FGUI:GetChild(item, "btn_add")
	local btn_info = FGUI:GetChild(item, "btn_info")
	if data then
		FGUI:GTextField_setText(text_name, data.UserName or "--")
		FGUI:GTextField_setText(text_lv, "Lv." .. tostring(data.Level or 1))
		local online = (data.IsOnline ~= nil) and data.IsOnline or data.online
		FGUI:GTextField_setText(text_st, online and "在线" or "离线")
		FGUI:GTextField_setColor(text_st, online and "#41E63D" or "#5D6E74")
		local targetID = data.UserID
		if icon_job then
			FGUI:GLoader_setUrl(icon_job, FGUIFunction:GetJobUrl(data.Job))
		end
		if vatar then
			if FGUIFunction.ClearCommonPlayerFrame then
				FGUIFunction:ClearCommonPlayerFrame(vatar)
			end
			AVATOR_DATA.AvatarID = data.AvatarID
			AVATOR_DATA.Job = data.Job
			AVATOR_DATA.Sex = data.Sex
			AVATOR_DATA.FrameID = data.PhotoframeID
			FGUIFunction:SetCommonPlayerFrame(vatar, AVATOR_DATA)
		end
		SetSlotFilled(item, true)
		if btn_info then
			FGUI:setOnClickEvent(btn_info, function()
				local dockEnum = (SL and SL.GetValue and SL:GetValue("DOCKTYPE_NENUM")) or {}
				FGUIFunction:OpenFuncDockTips({
					targetId = tonumber(targetID),
					AvatarID = data.AvatarID,
					Job = data.Job,
					Sex = data.Sex,
					targetName = data.UserName,
					Level = data.Level,
					GuildName = data.GuildName,
					TipsType = isTeamMember and SL:GetValue("DOCKTYPE_NENUM").Func_Team or
						SL:GetValue("DOCKTYPE_NENUM").Func_Near_Player,
					FrameID = data.PhotoframeID
				})
			end)
		end
		FGUI:setOnClickEvent(item, function()
			self.selectWhich   = idx
			self.rightInfoType = 2
			self:selectedItem(item)
			ssrMessage:sendmsgEx("MentorShip", "getApprenticeInfo", { UserID = targetID, fromPanel = 'MentorShipMain' })
		end)
	else
		FGUI:GTextField_setText(text_name, "")
		FGUI:GTextField_setText(text_lv, "")
		FGUI:GTextField_setText(text_st, "")
		if icon_job then
			FGUI:GLoader_setUrl(icon_job, "")
		end
		if vatar and FGUIFunction.ClearCommonPlayerFrame then
			FGUIFunction:ClearCommonPlayerFrame(vatar)
		end
		SetSlotFilled(item, false)
		if btn_add then
			FGUI:setOnClickEvent(btn_add, handler(self, self.OnClickFindApprentice))
		end
	end
end

function MentorShipMain:selectedItem(item)
	local itemList = FGUI:GetChildren(self._ui.list_mentor)
	if #itemList > 0 then
		for i = 1, #itemList do
			local controller = FGUI:getController(itemList[i], "isSelect")
			FGUI:Controller_setSelectedIndex(controller, 0)
		end
	end
	local itemList2 = FGUI:GetChildren(self._ui.list_apprentice)
	if #itemList2 > 0 then
		for i = 1, #itemList2 do
			local controller = FGUI:getController(itemList2[i], "isSelect")
			FGUI:Controller_setSelectedIndex(controller, 0)
		end
	end
	local selectcontroller = FGUI:getController(item, "isSelect")
	FGUI:Controller_setSelectedIndex(selectcontroller, 1)
end

function MentorShipMain:RenderMentorCondItem(idx, item)
	local data = self._emptyMentorCond[idx + 1]
	local text = FGUI:GetChild(item, "text_cond")
	local ok = data.check()
	FGUI:GTextField_setText(text, data.text)
	FGUI:GTextField_setColor(text, ok and "#2E8432" or "#372A08")
end

function MentorShipMain:RenderApprenticeCondItem(idx, item)
	local data = self._emptyApprenticeCond[idx + 1]
	local text = FGUI:GetChild(item, "text_cond")
	local ok = data.check()
	FGUI:GTextField_setText(text, data.text)
	FGUI:GTextField_setColor(text, ok and "#2E8432" or "#372A08")
end

local function __RenderIntroLine(data, item)
	local text = FGUI:GetChild(item, "text_task")
	FGUI:GTextField_setText(text, (type(data) == "table") and data.text or tostring(data))
	local xls = SL:GetMetaValue("ITEM_DATA", data.itemId)
	if xls then
		local grade = xls.Grade or 0
		local img_bg = FGUI:GetChild(item, "img_bg")
		if img_bg then
			FGUI:GImage_setTexture(img_bg, "ui://public/icon_item" .. tostring(grade or 0), false)
		end
		local commonItem = FGUI:GetChild(item, "commonItem")
		if commonItem then
			ItemUtil:RefreshItemUIByData(commonItem, SL:GetValue("ITEM_DATA", xls.ID))
			ItemUtil:AddItemClick(commonItem, SL:GetValue("ITEM_DATA", xls.ID))
		end
	end
end

function MentorShipMain:RenderMentorIntroItem(idx, item)
	__RenderIntroLine(self._emptyMentorIntro[idx + 1], item)
end

function MentorShipMain:RenderApprenticeIntroItem(idx, item)
	__RenderIntroLine(self._emptyApprenticeIntro[idx + 1], item)
end

function MentorShipMain:RenderTaskItem(idx, item)
	--local data = self._taskList[idx + 1]
	local data = self._showTaskList and self._showTaskList[idx + 1]
	--dump(data)
	-- dump(self.taskProgressList)
	if data and self.taskProgressList["" .. data.ID] then
		local task_name = FGUI:GetChild(item, "task_name")
		local task_progress = FGUI:GetChild(item, "task_progress")
		local task_status = FGUI:GetChild(item, "task_status")
		local thisProgress = tonumber(self.taskProgressList["" .. data.ID].num)
		local gonow = FGUI:GetChild(item, "gonow")
		local receive = FGUI:GetChild(item, "receive")
		local finishedText = FGUI:GetChild(item, "task_finishText")
		local fbstatus = FGUI:getController(item, "fbStatus")
		local nowState = FGUI:Controller_getSelectedIndex(fbstatus)
		local whoCont = FGUI:getController(item, "isMasterShowFinish")

		local tudi = FGUI:GetChild(item, "tudi")
		local shifu = FGUI:GetChild(item, "shifu")

		if self.rightInfoType == 1 then
			--我是徒弟
			FGUI:Controller_setSelectedIndex(whoCont, 0)
		else
			--我是师傅
			FGUI:Controller_setSelectedIndex(whoCont, 1)
		end

		local function parseRewardTable(rewardTable)
			if type(rewardTable) ~= "table" or next(rewardTable) == nil then
				return "无奖励"
			end
			local resultStr = ""
			for i, v in ipairs(rewardTable) do
				if type(v) == "table" and #v >= 2 then
					local itemId = tonumber(v[1])
					local itemNum = tonumber(v[2])
					local itemName = SL:GetMetaValue("ITEM_NAME", itemId) or "未知道具"
					if resultStr ~= "" then
						resultStr = resultStr .. "、"
					end
					resultStr = resultStr .. itemName .. "*" .. itemNum
				end
			end
			return resultStr ~= "" and resultStr or "无奖励"
		end
		local tudiRewardCfg = data.task_reward
		local shifuRewardCfg = data.task_reward_1
		local tudiStr = string.format("徒弟：%s", parseRewardTable(tudiRewardCfg))
		FGUI:GTextField_setText(tudi, tudiStr)

		local shifuStr = string.format("师傅：%s", parseRewardTable(shifuRewardCfg))
		FGUI:GTextField_setText(shifu, shifuStr)

		FGUI:GTextField_setText(task_name, data.task_name)
		local bg = FGUI:GetChild(item, "bg")
		FGUI:GTextField_setText(task_progress, thisProgress .. "/" .. data.task_target_num)
		FGUI:setVisible(gonow, false)
		FGUI:setVisible(finishedText, true)
		if self.taskProgressList["" .. data.ID].status == 1 then
			--已领取
			FGUI:Controller_setSelectedIndex(fbstatus, 3)
		else
			if self.rightInfoType == 1 then
				--我是徒弟
				if thisProgress >= data.task_target_num then
					--已完成目标
					FGUI:Controller_setSelectedIndex(fbstatus, 2)
				else
					FGUI:Controller_setSelectedIndex(fbstatus, 0)
				end
			else
				--我是师傅
				if thisProgress >= data.task_target_num then
					--已完成目标
					FGUI:Controller_setSelectedIndex(fbstatus, 2)
				else
					FGUI:Controller_setSelectedIndex(fbstatus, 0)
					if data.erveyday_reset == 1 then
						-- if nowState == 0 then
						--未开始
						FGUI:setVisible(gonow, true)
						FGUI:setVisible(finishedText, false)
						-- end
					end
				end
			end
			-- if self.rightInfoType == 1 then
			-- 	--我是徒弟
			-- 	FGUI:setVisible(task_status,true)
			-- else
			-- 	--显示我是师傅，我的徒弟的信息
			--每日任务 进副本

			-- end

			FGUI:SetIntData(item, idx)
			if thisProgress >= data.task_target_num then
				--已完成目标
				FGUI:Controller_setSelectedIndex(fbstatus, 2)
			elseif thisProgress == 0 then
				FGUI:Controller_setSelectedIndex(fbstatus, 0)
			else
				FGUI:Controller_setSelectedIndex(fbstatus, 1)
			end
			FGUI:setOnClickEvent(gonow, function(index, item)
				self:onClickGoto(data)
			end)
			FGUI:setOnClickEvent(receive, function(index, item)
				--只有徒弟可以领取
				if self.rightInfoType == 1 then
					ssrMessage:sendmsgEx("MentorShip", "receive", { taskId = data.ID, fromPanel = "MentorShipMain" })
				end
			end)
		end
		if idx % 2 == 1 then
			FGUI:setVisible(bg, true)
		else
			FGUI:setVisible(bg, false)
		end
	end
end

function MentorShipMain:onClickGoto(data)
	--dump(data)
	local postData = {
		task = data,
		myUserId = self.alMyRelationship.myUserId,
		apparenice = self._apprenticeList,
		type = "MentorShipMain",
		initiator = {
			UserID = self.alMyRelationship.myUserId,
			UserName = SL:GetValue("ACTOR_NAME", myUserId),
			Level = SL:GetValue("ACTOR_LEVEL", myUserId),
			AvatarID = SL:GetValue("ACTOR_AVATAR", myUserId),
			Job = SL:GetValue("JOB"),
			Sex = SL:GetValue("ACTOR_SEX", myUserId),
			FrameID = SL:GetValue("ACTOR_AVATAR_FRAME", myUserId),
			IsOnline = true,
			isMaster = true,
		}
	}
	FGUI:Open('MentorShip', 'Invitation', postData)
end

function MentorShipMain:RenderSetOut(idx, item)
	local data = self.setOutList[idx + 1]
	local text_cond = FGUI:GetChild(item, "text_cond")
	local str = ""
	if data.task_target == 1 then
		str = data.task_name ..
			"    " .. SL:GetValue("ACTOR_LEVEL", self.taskProgressList.UserID) .. "/" .. data.task_target_num
	end
	if data.task_target == 5 then
		str = data.task_name .. "    " .. self.taskProgressList.finishTask .. "/" .. data.task_target_num
	end
	if data.task_target == 3 then
		local servetDate = SL:GetValue("SERVER_TIME")
		local times      = servetDate - self.taskProgressList.bondDateTimes
		local days       = math.floor(times / 86400)
		str              = data.task_name .. "    " .. days .. "/" .. data.task_target_num
	end
	FGUI:GTextField_setText(text_cond, str)
	FGUI:SetIntData(item, idx)
end

function MentorShipMain:RefreshAll()
	--dump(self._taskList)
	if self._hasRelation then
		--过滤已完成任务
		self._showTaskList = {}
		if self._taskList then
			for i = 1, #self._taskList do
				local taskData = self._taskList[i]
				local prog = self.taskProgressList and self.taskProgressList["" .. taskData.ID]
				if not prog or prog.status ~= 1 or taskData.erveyday_reset == 1 then
					table.insert(self._showTaskList, taskData)
				end
			end
		end

		FGUI:GList_setNumItems(self._ui.list_mentor, 1)
		FGUI:GList_setNumItems(self._ui.list_tasks, #self._showTaskList)
		FGUI:GList_setNumItems(self._ui.list_graduate, #self.setOutList)
		FGUI:GList_setNumItems(self._ui.list_apprentice, 3)
		self:setRightInfo()
	else
		self._showTaskList = {}
		FGUI:GList_setNumItems(self._ui.list_mentor, 1)
		FGUI:GList_setNumItems(self._ui.list_apprentice, self._apprenticeMax or 3)
		FGUI:GList_setNumItems(self._ui.list_tasks, 0)
		FGUI:GList_setNumItems(self._ui.list_graduate, 0)
	end
	local showEmpty = not self._hasRelation
	local text = "未出师徒弟 " .. (#self._apprenticeList) .. "/3"
	FGUI:GTextField_setText(self._ui.text_count, text)
	FGUI:GList_setNumItems(self._ui.list_mentor_cond, showEmpty and #self._emptyMentorCond or 0)
	FGUI:GList_setNumItems(self._ui.list_apprentice_cond, showEmpty and #self._emptyApprenticeCond or 0)
	FGUI:GList_setNumItems(self._ui.list_mentor_intro, showEmpty and #self._emptyMentorIntro or 0)
	FGUI:GList_setNumItems(self._ui.list_apprentice_intro, showEmpty and #self._emptyApprenticeIntro or 0)
	FGUI:Controller_setSelectedIndex(self.rightController, self._hasRelation and 1 or 0)
end

function MentorShipMain:setApprenticeTask(data)
	self = MentorShipMain.CCUI
	self.taskProgressList = data.taskProgressList
	self:RefreshAll()
end

function MentorShipMain:setRightInfo()
	FGUI:GTextField_setText(self._ui.text_bond_date, "于" .. self.taskProgressList.bondDate .. "结为师徒")
	if self.dsqjc then
		SL:UnSchedule(self.dsqjc)
		FGUI:setVisible(self._ui.btn_break, true)
		FGUI:setVisible(self._ui.btn_cancel, false)
		FGUI:setVisible(self._ui.timeout, false)
	end
	if self.rightInfoType == 1 then
		--我的师傅
		-- dump(self.applyRemoveMyMaster)
		if self.applyRemoveMyMaster then
			--解除关系倒计时
			local breakData = {
				byUserId = self.applyRemoveMyMasterById,
				date = self.applyRemoveMyMaster
			}
			self:showTimeOut(breakData)
		end
	else
		--我的徒弟
		-- dump(self.taskProgressList.UserID)
		-- dump(self.applyRemoveMyAppliction[""..self.taskProgressList.UserID])
		if self.applyRemoveMyAppliction["" .. self.taskProgressList.UserID] then
			--解除关系倒计时
			local breakData = {
				byUserId = self.applyRemoveMyAppliction["" .. self.taskProgressList.UserID].byUserId,
				date = self.applyRemoveMyAppliction["" .. self.taskProgressList.UserID].date
			}
			self:showTimeOut(breakData)
		end
	end
end

function MentorShipMain:onClickChuShi()
	-- self.setOutList
	local isCan = true
	for i = 1, #self.setOutList do
		local task = self.setOutList[i]
		--等级要求
		local item = FGUI:GetChildAt(self._ui.list_graduate, i - 1)
		local cont = FGUI:getController(item, "isShowTips")
		if task.task_target == 1 then
			if SL:GetValue("ACTOR_LEVEL", self.taskProgressList.UserID) < task.task_target_num then
				isCan = false
				FGUI:Controller_setSelectedIndex(cont, 1)
				FGUI:setSize(item, 526, 48)
			else
				FGUI:Controller_setSelectedIndex(cont, 0)
				FGUI:setSize(item, 526, 24)
			end
		end
		if task.task_target == 3 then
			local servetDate = SL:GetValue("SERVER_TIME")
			local times      = servetDate - self.taskProgressList.bondDateTimes
			local days       = math.floor(times / 86400)
			if days < task.task_target_num then
				isCan = false
				FGUI:Controller_setSelectedIndex(cont, 1)
				FGUI:setSize(item, 526, 48)
			else
				FGUI:Controller_setSelectedIndex(cont, 0)
				FGUI:setSize(item, 526, 24)
			end
		end
		if task.task_target == 5 then
			if self.taskProgressList.finishTask < task.task_target_num then
				isCan = false
				FGUI:Controller_setSelectedIndex(cont, 1)
				FGUI:setSize(item, 526, 48)
			else
				FGUI:Controller_setSelectedIndex(cont, 0)
				FGUI:setSize(item, 526, 24)
			end
		end
	end
	--if isCan then
	ssrMessage:sendmsgEx("MentorShip", "chushi", { UserID = self.taskProgressList.UserID })
	--end
end

function MentorShipMain:OnClickFindMentor()
	print("MentorShipMain:OnClickFindMentor()")
	--判断当前是否满足
	for i = 1, #self._emptyMentorCond do
		local cond = self._emptyMentorCond[i]
		if not cond.check() then
			SL:ShowSystemTips("拜师条件不满足，无法拜师")
			return
		end
	end
	FGUI:Open("MentorShip", "FindMentorPanel")
end

function MentorShipMain:OnClickFindApprentice()
	--判断当前是否满足
	for i = 1, #self._emptyApprenticeCond do
		local cond = self._emptyApprenticeCond[i]
		if not cond.check() then
			SL:ShowSystemTips("师徒条件不满足，无法收徒")
			return
		end
	end
	FGUI:Open("MentorShip", "FindApprenticePanel")
end

function MentorShipMain:Onbtn_applylist()
	FGUI:Open("MentorShip", "MyShipApplyLists", "MentorShipMain")
end

function MentorShipMain:onClickReward()
	print("dianjijiangli")
	FGUI:setVisible(self._ui.chushijl, true)
	local btn_close = FGUI:GetChild(self._ui.chushijl, "btn_close")
	local Mask = FGUI:GetChild(self._ui.chushijl, "Mask")
	FGUI:setOnClickEvent(btn_close, function()
		--关闭
		FGUI:setVisible(self._ui.chushijl, false)
	end)
	FGUI:setOnClickEvent(Mask, function()
		--关闭
		FGUI:setVisible(self._ui.chushijl, false)
	end)
	local iconItem = FGUI:GetChild(self._ui.chushijl, "masterBox")
	local iconItem1 = FGUI:GetChild(self._ui.chushijl, "appriceBox")
	local itemData = SL:GetValue("ITEM_DATA", tonumber(MasterApprenticeShip['master_award'].VALUE))
	local itemData1 = SL:GetValue("ITEM_DATA", tonumber(MasterApprenticeShip['apparenice_award'].VALUE))
	--师傅奖励
	local extData = {}
	extData.hideTip = false          --是否隐藏默认的Tip
	extData.itemTipData = itemData   --table类型，对应ItemTips.ShowTip传入的参数
	extData.clickCallback = false    --单击事件回调
	extData.doubleClickCallback = false --双击事件回调
	extData.bgVisible = true         --背景隐藏
	ItemUtil:ItemShow_Create(itemData, iconItem, extData)
	--徒弟奖励
	local extData1 = {}
	extData1.hideTip = false          --是否隐藏默认的Tip
	extData1.itemTipData = itemData1  --table类型，对应ItemTips.ShowTip传入的参数
	extData1.clickCallback = false    --单击事件回调
	extData1.doubleClickCallback = false --双击事件回调
	extData1.bgVisible = true         --背景隐藏
	ItemUtil:ItemShow_Create(itemData1, iconItem1, extData1)
end

function MentorShipMain:OnClickBreak()
	print("点击OnClickBreak")
	--FGUI:Open("MentorShip", "breakRelationship", { type = self.rightInfoType, UserID = self.taskProgressList.UserID })
	local isShowDialog = SL:GetValue("T", 94)
	dump(isShowDialog)
	if isShowDialog == "" then
		FGUI:setVisible(self._ui.dialog, true)
	end
	local agree = FGUI:GetChild(self._ui.dialog, "btn_green")
	local btn_close = FGUI:GetChild(self._ui.dialog, "btn_close")
	local btn_red = FGUI:GetChild(self._ui.dialog, "btn_red")
	local Mask = FGUI:GetChild(self._ui.dialog, "Mask")
	local checkBox = FGUI:GetChild(self._ui.dialog, "checkBox")
	FGUI:setOnClickEvent(agree, function()
		--同意解除
		FGUI:setVisible(self._ui.dialog, false)
		ssrMessage:sendmsgEx("MentorShip", "applyRemove",
			{ type = self.rightInfoType, UserID = self.taskProgressList.UserID })
	end)
	-- 0 不勾 1勾
	FGUI:setOnClickEvent(checkBox, function()
		local isSelect = FGUI:getController(checkBox, "isSelect")
		local nowSelect = FGUI:Controller_getSelectedIndex(isSelect)
		FGUI:Controller_setSelectedIndex(isSelect, nowSelect == 0 and 1 or 0)
	end)
	FGUI:setOnClickEvent(btn_close, function()
		--同意解除
		FGUI:setVisible(self._ui.dialog, false)
	end)
	FGUI:setOnClickEvent(btn_red, function()
		--关闭
		FGUI:setVisible(self._ui.dialog, false)
	end)
	FGUI:setOnClickEvent(Mask, function()
		--关闭
		FGUI:setVisible(self._ui.dialog, false)
	end)
end

function MentorShipMain:OnclickCancelBreak()
	print("点击解除关系")
	if self.dsqjc then
		SL:UnSchedule(self.dsqjc)
	end
	ssrMessage:sendmsgEx("MentorShip", "cancelApplyBreak",
		{ type = self.rightInfoType, UserID = self.taskProgressList.UserID })
end

function MentorShipMain:showTimeOut(data)
	self = MentorShipMainUI.CCUI
	--师徒操作解除的
	if data.date then
		--解除关系中
		--加个倒计时
		if self.dsqjc then
			SL:UnSchedule(self.dsqjc)
		end
		self.time = data.date
		local function realivedjs()
			local times = SL:GetValue("SERVER_TIME") * 1000 - self.time
			local Second = 86400 - math.floor(times / 1000)
			local hour = math.floor(Second / 3600)
			local minutes = math.floor((Second - hour * 3600) / 60)
			if Second > 0 then
				FGUI:GTextField_setText(self._ui.timeout, "将于" .. hour .. "小时" .. minutes .. "分后解除")
				FGUI:setVisible(self._ui.timeout, true)
				if data.byUserId == self.myUserId then
					FGUI:setVisible(self._ui.btn_cancel, true)
					FGUI:setVisible(self._ui.btn_break, false)
				else
					FGUI:setVisible(self._ui.btn_break, true)
					FGUI:setVisible(self._ui.btn_cancel, false)
				end
			else
				SL:UnSchedule(self.dsqjc)
				FGUI:setVisible(self._ui.btn_break, true)
				FGUI:setVisible(self._ui.btn_cancel, false)
				FGUI:setVisible(self._ui.timeout, false)
				FGUI:setVisible(self._ui.dialog, false)
				ssrMessage:sendmsgEx("MentorShip", "clearThisRelationship",
					{ masterUserId = data.masterUserId, applictionUserId = data.applictionUserId })
			end
		end
		self.dsqjc = SL:Schedule(realivedjs, 1)
	else
		FGUI:setVisible(self._ui.btn_break, true)
		FGUI:setVisible(self._ui.btn_cancel, false)
		FGUI:setVisible(self._ui.timeout, false)
	end
end

function MentorShipMain:OnClickGraduate()
	self._store:NetSend(self._op.GRADUATE, self._relationId or 0, 0, nil)
end

function MentorShipMain:_OnNet(msgID, code, _, _, str)
	if msgID ~= self._net.RSP then
		return
	end
	if code == CODE.ERROR then
		self._store:ShowTips(str or "操作失败")
		return
	end
	if code == CODE.SNAPSHOT then
		local snap = self._store:JsonDecode(str or "{}") or {}
		local mentor = snap.mentor
		self._mentorInfo = mentor or nil
		self._apprenticeList = snap.apprentices or snap.apprs or {}
		self._taskList = snap.tasks or {}
		self._relationId = (mentor and (mentor.relation_id or mentor.relationId)) or 0
		self._hasRelation = (mentor ~= nil)
		self:RefreshAll()
		return
	end
	if code == CODE.PUSH_TASK or code == CODE.PUSH_STATUS then
		self._store:NetSend(self._op.GET_STATUS, 0, 0, nil)
		return
	end
	if code == CODE.CLAIM_OK then
		self._store:ShowTips("领取成功")
		self._store:NetSend(self._op.GET_STATUS, 0, 0, nil)
		return
	end
	if code == CODE.GRADUATE_OK then
		self._store:ShowTips("出师成功")
		self._store:NetSend(self._op.GET_STATUS, 0, 0, nil)
		return
	end
end

function MentorShipMain:_RegisterNet()
	self._netCB = self._netCB or function(msgID, p1, p2, p3, str)
		self:_OnNet(msgID, p1, p2, p3, str)
	end
	SL:RegisterNetMsg(self._net.RSP, self._netCB)
end

function MentorShipMain:_UnregisterNet()
	SL:UnRegisterNetMsg(self._net.RSP)
end

function MentorShipMain:onTransferComplete()
	ssrMessage:sendmsgEx("MentorShip", "changeRelevel")
end

function MentorShipMain:addBubble()
	local function callback()
		FGUI:Open("MentorShip", "MentorShipPanel", { openBrearList = true }, FGUI_LAYER.NORMAL,
			{ fullScreen = false, destroyTime = 1 })
		SL:DelBubbleTips(203000)
	end
	SL:AddBubbleTips(203000, "ui://zj419n3dbrvzv7v", callback)
end

function MentorShipMain:addApplyBubble()
	local function callback()
		FGUI:Open("MentorShip", "MyShipApplyLists", "addApplyBubble")
		SL:DelBubbleTips(203001)
	end
	SL:AddBubbleTips(203001, "ui://zj419n3dbrvzv7v", callback)
end

-----------------------------------注册事件--------------------------------------
function MentorShipMain:RegisterEvent()
	-- SL:RegisterLUAEvent(LUA_EVENT_TRANSFER_SUCCEED, "MentorShipMain", handler(self, self.onTransferComplete))
end

function MentorShipMain:RemoveEvent()
	-- SL:UnRegisterLUAEvent(LUA_EVENT_TRANSFER_SUCCEED, "MentorShipMain")
end

return MentorShipMain
