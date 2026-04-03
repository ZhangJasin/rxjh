

local MentorShipPageBase = requireFGUILayout("MentorShip/MentorShipPageBase")
local MentorShipTeach = class("MentorShipTeach", MentorShipPageBase)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local Store = requireFGUILayout("MentorShip/MentorShipData")
local SysConstant = require("game_config/cfgcsv/SysConstant")
local MentorApplicationTask = requireFGUILayout("MentorShip/MentorApplicationTask")

function MentorShipTeach.Create()
	return MentorShipTeach.new()
end
local AVATOR_DATA = {}
function MentorShipTeach:Enter()
	MentorShipTeach.super.Enter(self)
	self._ui = FGUI:ui_delegate(self.component)
	self._store = Store.Get()
	self.MentorApplicationTask = MentorApplicationTask.Get()
	self._store:GetMyRelation('MentorShipTeach')
	self._gxdList = self.MentorApplicationTask:gxdTask()
	self.rightController = FGUI:getController(self.component, "who")
	self.showController = FGUI:getController(self.component,"isHave")

	MentorShipTeach.CCUI = self
	self:RegisterEvent()
	self:InitData()
	self:InitEvent()
end

function MentorShipTeach:Exit()
	self:RemoveEvent()
	MentorShipTeach.super.Exit(self)
end

function MentorShipTeach:InitData()
	self._hasRelation = false
	self._relationId = 0
	--我的师傅
	self._mentorInfo = nil
	--我的师徒
	self._apprenticeList = {}
	--选择哪个徒弟 userId
	--点击了哪个
	self.selectWhich = 0
	-- 1显示我自己的，2显示我的徒弟
	self.rightInfoType = nil
	--右边显示数据
	self.rightData = {}
	self.skillList = {}
	--给第几个技能设置
	self.setSkillIndex = 0
	--贡献度任务进度
	self.gxdTask = {}
end

function MentorShipTeach:InitEvent()
	FGUI:GList_itemRenderer(self._ui.list_mentor, handler(self, self.RenderMentorSlot))
	FGUI:GList_itemRenderer(self._ui.list_apprentice, handler(self, self.RenderApprenticeSlot))
	FGUI:setOnClickEvent(self._ui.btn_applylist,handler(self,self.Onbtn_applylist))
end

local function SetSlotFilled(item, filled)
	local frame = FGUI:GetChild(item, "frame")
	local btn_add = FGUI:GetChild(item, "btn_add")
	FGUI:setVisible(frame, filled)
	FGUI:setVisible(btn_add, not filled)
end
function MentorShipTeach:Onbtn_applylist()
	FGUI:Open("MentorShip", "MyShipApplyLists","MentorShipTeach")
end
function MentorShipTeach:setData(data)
	if MentorShipTeach.CCUI then
		self = MentorShipTeach.CCUI
		--我的师傅
		self._mentorInfo = data.myMaster or nil
		--我的师徒
		self._apprenticeList = data.apprentice or {}
		--默认第一个
		self.rightInfoType = nil
		if self._mentorInfo then
			self.rightInfoType = 1
		elseif #self._apprenticeList > 0 then
			self.rightInfoType = 2
			self.selectWhich = 1
		end
		self.selectTaskListBtn = 1
		self.rightInfo = data.taskProgressList
		self.attrList = data.attrList
		self.gxdTask = data.gxdTask
		--显示我的技能
		if self.rightInfoType then
			FGUI:Controller_setSelectedIndex(self.showController,1)
			self:RefreshAll()
			self:baseSelectedItem()
		else
			FGUI:Controller_setSelectedIndex(self.showController,0)
		end
	end
end

function MentorShipTeach:resetData(data)
	self = MentorShipTeach.CCUI
	self.rightInfo = data.taskProgressList
	self.attrList = data.attrList
	self.showAttrList = {}
	self.gxdTask = data.gxdTask
	local skillNum = 1
	if self.rightInfo.progressLv == 1 then
		skillNum = 3 
	elseif self.rightInfo.progressLv <= 3 then
		skillNum = 2 
	end
    if self.rightInfoType == 1 then
		FGUI:GList_setNumItems(self._ui.getSkill, skillNum)
		FGUI:GList_setNumItems(self._ui.taskList, #self._gxdList)
		FGUI:GTextField_setText(self._ui.wdgxd, self.rightInfo.progressLv)
		FGUI:GProgressBar_setValue(self._ui.gxdjd, self.rightInfo.progressPer)
		local text = FGUI:GetChild(self._ui.gxdjd,"text")
		FGUI:GTextField_setText(text, self.rightInfo.progressPer.."%")
	else
		FGUI:GList_setNumItems(self._ui.giveSkillList, skillNum)
		FGUI:GTextField_setText(self._ui.gxdlv, self.rightInfo.progressLv)
		FGUI:GProgressBar_setValue(self._ui.gxdjdt, self.rightInfo.progressPer)
		local text = FGUI:GetChild(self._ui.gxdjdt,"text")
		FGUI:GTextField_setText(text, self.rightInfo.progressPer.."%")
	end
	self:setBottomTaskInfo(actor,self._gxdList[self.selectTaskListBtn])
	SL:RequestLookPlayer(tonumber(self.rightInfo.UserID),nil,666)
	self:setRightInfo()
end

function MentorShipTeach:RenderMentorSlot(idx, item)
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
					TipsType = isTeamMember and SL:GetValue("DOCKTYPE_NENUM").Func_Team or SL:GetValue("DOCKTYPE_NENUM").Func_Near_Player,
					FrameID = data.PhotoframeID
				})
			end)
		end
		FGUI:setOnClickEvent(item, function()
			self.selectWhich  = idx
			self.rightInfoType =  1
			self:selectedItem(item)
			ssrMessage:sendmsgEx("MentorShip", "getApprenticeInfo",{UserID = self.myUserId ,fromPanel = 'MentorShipTeach'})
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

function MentorShipTeach:selectedItem(item)
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

function MentorShipTeach:baseSelectedItem()
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
	if self._mentorInfo then
		local selectcontroller = FGUI:getController(itemList[1], "isSelect")
		FGUI:Controller_setSelectedIndex(selectcontroller, 1)
	elseif #self._apprenticeList > 0 then
		local selectcontroller = FGUI:getController(itemList2[1], "isSelect")
		FGUI:Controller_setSelectedIndex(selectcontroller, 1)
	end
end

function MentorShipTeach:RenderApprenticeSlot(idx, item)
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
					TipsType = isTeamMember and SL:GetValue("DOCKTYPE_NENUM").Func_Team or SL:GetValue("DOCKTYPE_NENUM").Func_Near_Player,
					FrameID = data.PhotoframeID
				})
			end)
		end
		FGUI:setOnClickEvent(item, function()
			self.selectWhich  = idx+1
			self.rightInfoType =  2
			self:selectedItem(item)
			ssrMessage:sendmsgEx("MentorShip", "getApprenticeInfo",{UserID = targetID ,fromPanel = 'MentorShipTeach'})
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

function MentorShipTeach:RefreshAll()
	FGUI:GList_setNumItems(self._ui.list_mentor, self._mentorInfo and 1 or 0)
	FGUI:GList_setNumItems(self._ui.list_apprentice, #self._apprenticeList)
	local text = "未出师徒弟 "..(#self._apprenticeList).."/3"
	FGUI:GTextField_setText(self._ui.text_count,text)
	self.setRightInfo()
end

function MentorShipTeach:setRightInfo()
	self = MentorShipTeach.CCUI
	print("渲染右边数据了")
	--是否有师傅或者徒弟
	FGUI:Controller_setSelectedIndex(self.rightController, self.rightInfoType == 1  and 0 or 1)
		if self.rightInfoType == 1 then
			--有师傅 我是徒弟
			-- self.rightInfo = self._mentorInfo
			local giveSkillList = self.rightInfo.skillList	
			FGUI:GList_itemRenderer(self._ui.getSkill, function(idx,item)
				local thisSkillInfo = nil
				for i,v in pairs(giveSkillList) do
					if idx+1 == tonumber(i) then
						thisSkillInfo = v
					end
				end
				if thisSkillInfo then
					--配了技能
					local icon = FGUI:GetChild(item,"icon")
					local name = FGUI:GetChild(item,"title")
					local skillName = SL:GetValue("SKILL_NAME_BY_ID", thisSkillInfo.skillId)
					FGUI:GTextField_setText(name, skillName)
					local path = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", thisSkillInfo.skillId)
					FGUI:GLoader_setUrl(icon, path, nil, true)
				end
			end)
			local skillNum = 1
			if self.rightInfo.progressLv == 1 then
				skillNum = 3 
			elseif self.rightInfo.progressLv <= 3 then
				skillNum = 2 
			end
			FGUI:GList_setNumItems(self._ui.getSkill, skillNum)
			FGUI:GTextField_setText(self._ui.wdgxd, self.rightInfo.progressLv)
			FGUI:GProgressBar_setValue(self._ui.gxdjd, self.rightInfo.progressPer)
			local text = FGUI:GetChild(self._ui.gxdjd,"text")
			FGUI:GTextField_setText(text, self.rightInfo.progressPer)
			FGUI:GList_itemRenderer(self._ui.taskList,function(idx,item)
				local taskName = FGUI:GetChild(item,"n0")
				local task = self._gxdList[idx+1]
				FGUI:GTextField_setText(taskName, task.task_name)
				local status = FGUI:getController(item,"status")
				if self.gxdTask[''..task.ID] and self.gxdTask[''..task.ID].num == task.task_target_num then
					if self.gxdTask[''..task.ID].status == 1 then
						FGUI:Controller_setSelectedIndex(status,1)
					else
						FGUI:Controller_setSelectedIndex(status,2)
					end
				else
					btnState = 0
					FGUI:Controller_setSelectedIndex(status,0)
				end
				local btn = FGUI:GetChild(item,"gotodo")
				FGUI:setOnClickEvent(btn, function()
					--去完成
				end)
				FGUI:setOnClickEvent(item, function()
					--去完成
					self.selectTaskListBtn = idx+1
					self:setBottomTaskInfo(actor,self._gxdList[idx+1])
				end)
			end)
			FGUI:GList_setNumItems(self._ui.taskList, #self._gxdList)
			self:setBottomTaskInfo(actor,self._gxdList[self.selectTaskListBtn])
		else
			if self.selectWhich then
				--有徒弟 我是师傅
				-- self.rightInfo = self._apprenticeList[self.selectWhich]
				SL:RequestLookPlayer(tonumber(self.rightInfo.UserID),true,666)
				self:setMySkillList()
				local giveSkillList = self.rightInfo.skillList	
				FGUI:GList_itemRenderer(self._ui.giveSkillList, function(idx,item)
					local thisSkillInfo = nil
					local icon = FGUI:GetChild(item,"icon")
					local name = FGUI:GetChild(item,"title")
					FGUI:GLoader_setUrl(icon, "", nil, true)
					FGUI:GTextField_setText(name, "")
					for i,v in pairs(giveSkillList) do
						if idx+1 == tonumber(i) then
							thisSkillInfo = v
						end
					end
					--已经传过的技能不能重新传
					if thisSkillInfo then
						--配了技能
						local skillName = SL:GetValue("SKILL_NAME_BY_ID", thisSkillInfo.skillId)
						FGUI:GTextField_setText(name, skillName)
						local path = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", thisSkillInfo.skillId)
						FGUI:GLoader_setUrl(icon, path, nil, true)
					else
						FGUI:setOnClickEvent(item, function()
							self.setSkillIndex = idx + 1
							FGUI:setVisible(self._ui.setSkillView,true)
						end)
					end
				end)

				local skillNum = 1
				if self.rightInfo.progressLv == 1 then
					skillNum = 3 
				elseif self.rightInfo.progressLv <= 3 then
					skillNum = 2 
				end
				FGUI:GList_setNumItems(self._ui.giveSkillList, skillNum)
				FGUI:GTextField_setText(self._ui.gxdlv, self.rightInfo.progressLv)
				FGUI:GProgressBar_setValue(self._ui.gxdjdt, self.rightInfo.progressPer)
				local text = FGUI:GetChild(self._ui.gxdjdt,"text")
				FGUI:GTextField_setText(text, self.rightInfo.progressPer)
			end
		end
end

function MentorShipTeach:setBottomTaskInfo(actor,data)
	-- dump(data)
	-- dump(self.gxdTask)
	FGUI:GTextField_setText(self._ui.select_task_name, "任务："..data.task_name)
	FGUI:GTextField_setText(self._ui.sxtj, "所需条件："..data.task_desc)
	FGUI:GTextField_setText(self._ui.rwjd, "任务进度:"..self.gxdTask[''..data.ID].num.."/"..data.task_target_num )
	local jl = data.task_reward
	local str = "奖励: "
	for i=1,#jl do
		local itemNmae = SL:GetValue("ITEM_NAME",jl[i][1])
		str = str..itemNmae.." x "..jl[i][2]
	end
	FGUI:GTextField_setText(self._ui.jiangli, str)
	local controller = FGUI:getController(self.component,"taskDesc")
	if self.gxdTask[''..data.ID].num == data.task_target_num then
		
		if self.gxdTask[''..data.ID].status == 0 then
			FGUI:Controller_setSelectedIndex(controller,2)
		else
			FGUI:Controller_setSelectedIndex(controller,1)
		end
	else
		FGUI:Controller_setSelectedIndex(controller,0)
	end
	FGUI:setOnClickEvent(self._ui.lingqu, function()
		ssrMessage:sendmsgEx("MentorShip", "finishGxdTask",{UserID = self.rightInfo.UserID,taskID = data.ID})
	end)
end

function MentorShipTeach:setMySkillList()
	local myjob = SL:GetValue("JOB")
	local myGoodEvil = SL:GetValue("GOODEVILID")
	local myAllSkillList = SL:GetValue("SKILL_WUGONG_TYPE_BY_GOODEVIL", myjob, 1, myGoodEvil)
	local zsLevel = self._apprenticeList[self.selectWhich].zsLevel
	local skillList = myAllSkillList[zsLevel+1]
	self.skillList = {}
	for i,v in pairs(skillList) do
		local isLearned = SL:GetValue("SKILL_IS_LEARNED", v.SkillID)
		if isLearned then
			local skill = SL:GetValue("SKILL_DATA_BY_ID", v.SkillID)
			local isGive = true
			for e,r in pairs(self.rightInfo.skillList) do
				if r.skillId == v.SkillID then
					isGive = false
				end
			end
			if isGive then
				table.insert(self.skillList,skill)
			end
		end
	end	
	self.list_skill= FGUI:GetChild(self._ui.setSkillView,"list_skill")
	local closeSkill = FGUI:GetChild(self._ui.setSkillView,"close_skill")
	FGUI:setOnClickEvent(closeSkill, function()
		FGUI:setVisible(self._ui.setSkillView,false)
	end)
	FGUI:GList_itemRenderer(self.list_skill, function (idx,item)
		local skillInfo = self.skillList[idx+1]
		if skillInfo then
			local icon = FGUI:GetChild(item,"skill_icon")
			local name = FGUI:GetChild(item,"text_name")
			local skillName = SL:GetValue("SKILL_NAME_BY_ID", skillInfo.SkillId)
			FGUI:GTextField_setText(name, skillName)
			local path = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", skillInfo.SkillId)
			FGUI:GLoader_setUrl(icon, path, nil, true)
			FGUI:setOnClickEvent(item, function()
				self:setTip(skillInfo)
			end)
		end
	end)
	FGUI:GList_setNumItems(self.list_skill, #self.skillList)
end
function MentorShipTeach:setTip(skillInfo)
	local tips = FGUI:GetChild(self._ui.setSkillView,"skillTip")
	local SkillID = skillInfo.SkillId
	local SkillLevel = skillInfo.Level
	if not SkillID and SkillLevel then 
        return
    end 
    local skillConfig = SL:GetValue("SKILL_UPGRADE_CONFIG_BY_ID_LEVEL", SkillID, SkillLevel)
    -- icon 
    local path = SL:GetValue("SKILL_SQUARE_ICON_PATH_BY_ID", SkillID)
	local skillIcon = FGUI:GetChild(tips,"skill_icon")
    FGUI:GLoader_setUrl(skillIcon, path, nil, true) 
    -- name
	local textName = FGUI:GetChild(tips,"text_name")
    local name = SL:GetValue("SKILL_UP_NAME_BY_ID", SkillID, SkillLevel)
    FGUI:GTextField_setText(textName, name)
    -- condition 
	local condition = FGUI:GetChild(tips,"text_condition")
    local sTips = SL:GetValue("CONDITION_TIPS", skillConfig.ConditionId)
    FGUI:GRichTextField_setText(condition, sTips)
	local list_cost = FGUI:GetChild(tips,"list_cost")
    -- cost
    if skillConfig.Cost then 
		local _costList = {}
        local sp = string.split(skillConfig.Cost, "|")
        for i = 1, #sp do 
            local data = {}
            local sp2 = string.split(sp[i], "#")
            data.id = tonumber(sp2[1])
            data.count = tonumber(sp2[2])
            table.insert(_costList, data)
        end 
        FGUI:GList_itemRenderer(list_cost, function(idx, item)
            local index = idx + 1
            local data = _costList[index]
            if not data then 
                return 
            end  

            local text_cost = FGUI:GetChild(item, "text_cost")
            local itemName = SL:GetValue("ITEM_NAME", data.id)
            local myCount = SL:GetValue("ITEM_COUNT", data.id)
            local needCount = data.count   
            local color = myCount >= needCount and "#00FF00" or "#FF0000"
            FGUI:GTextField_setText(text_cost, string.format(GET_STRING(60012007), itemName, color, needCount))
        end)
        FGUI:GList_setNumItems(list_cost, #_costList)
    end
    -- desc
	local text_desc = FGUI:GetChild(tips,"text_desc")
    local desc = SL:GetValue("SKILL_UP_DESC_BY_ID", SkillID, SkillLevel)
    FGUI:GRichTextField_setText(text_desc, desc)
    -- weili
	local text_weili = FGUI:GetChild(tips,"text_weili") 
    FGUI:GTextField_setText(text_weili, string.format(GET_STRING(60012004), skillConfig.Power or 0))
    -- att   
    local skillcost = skillConfig.SkillCost
    if skillcost then 
        if tonumber(skillcost[1]) == 0 then 
            local attData = SL:GetValue("ATTR_CONFIG", tonumber(skillcost[2]))
            if attData then 
				local text_neili = FGUI:GetChild(tips,"text_neili")
                FGUI:GTextField_setText(text_neili, string.format(GET_STRING(60012005), attData.Name, tonumber(skillcost[3])))
            end 
        end 
    end
    -- cd
    local skillCfg = SL:GetValue("SKILL_CONFIG_BY_SKILL_ID", SkillID)
    if skillCfg then 
		local text_cd = FGUI:GetChild(tips,"text_cd") 
        FGUI:GTextField_setText(text_cd, string.format(GET_STRING(60012006), skillCfg.CD * 0.001 or 0))
    end
	FGUI:setVisible(tips,true)
	local mask = FGUI:GetChild(tips,"mask")
	FGUI:setOnClickEvent(mask, function()
		FGUI:setVisible(tips,false)
	end)
	local pzbtn = FGUI:GetChild(tips,"btn_pz")
	FGUI:setOnClickEvent(pzbtn, function()
		--选择了技能，给徒弟加技能
		skillInfo.UserId = self.rightInfo.UserID
		skillInfo.setSkillIndex = self.setSkillIndex
		ssrMessage:sendmsgEx("MentorShip", "addSkillToApplication",skillInfo)
		FGUI:setVisible(tips,false)
		FGUI:setVisible(self._ui.setSkillView,false)
	end)
end

function MentorShipTeach:RefreshView()
	self.showAttrList = {}
	local data = SL:GetValue("L.M.PLAYER_DATA")
    if not data or not next(data) then
        return
    end
	for k,v in pairs(data.Abil) do
        local cfg = SL:GetValue("ATTR_CONFIG",v.id)
        if cfg then
            if v.id ~= SLDefine.ATTRIBUTE.HP and v.id ~= SLDefine.ATTRIBUTE.MP
                and v.id ~= SLDefine.ATTRIBUTE.LEVEL and v.id ~= SLDefine.ATTRIBUTE.EXP
                and v.id ~= SLDefine.ATTRIBUTE.ANGER and cfg.Isshow == 1 and cfg.Attribute == 0 then
				local data = v
				if not cfg.Name then
					SL:PrintEx("[ERROR] attscore["..v.id.."]没有属性名字")
				end
				data.Name = cfg.Name or GET_STRING(30000054)
				data.Sort = cfg.Sort
				data.Desc = cfg.Desc
				data.ShowValue = data.maxValue
				if cfg.Type == 1 then
					data.ShowValue = string.format("%.0f%%", data.maxValue / 100)
				elseif cfg.Type == 0 then
				else
					SL:PrintEx("未知属性ID = "..v.id.."属性Type" .. cfg.Type)
				end
				table.insert(self.showAttrList,data)
			end
        end
    end
	table.sort(self.showAttrList,function(a,b)
        if a.Sort and b.Sort then
            return a.Sort < b.Sort
        end
    end)
    local itemHeight = 32
    local lines = math.ceil(#self.showAttrList/1)
    FGUI:GList_setLineCount(self._ui.attrList, lines)
    FGUI:GList_itemRenderer(self._ui.attrList,handler(self,self.AttrItemRender))
    FGUI:GList_setNumItems(self._ui.attrList, #self.showAttrList)
	--徒弟模型
	self:ClearModel()
	self._model = FGUI:UIModel_Bind(self._ui.model)
	FGUI:UIModel_setObjectEulerAngles(self._model, nil, 0, 0, 0)

    local bodyId = nil
    local weaponId = nil
    local helmetId = nil
	local faceId = nil
    local lookSex = SL:GetValue("L.M.SEX")
    local lookJob = SL:GetValue("L.M.JOB")
    local classConfig = SL:GetValue("ROLE_CLASS_CONFIG", lookJob)
    if classConfig then 
		faceId = FGUIFunction:GetFaceIDBySex(lookSex,classConfig)
    end 
    
    local modelData = SL:GetValue("L.M.PLAYER_MODEL")
    if modelData then 
		local extData = {}
		extData.sex = lookSex
		extData.job = lookJob
		extData.bodyId = modelData.bodyId == 0 and bodyId or modelData.bodyId
		extData.helmetId = modelData.headId == 0 and helmetId or modelData.headId
        extData.weaponId = modelData.rWeapon == 0 and weaponId or modelData.rWeapon
        extData.wingId = modelData.wingId or 0
		extData.faceId = faceId
		-- dump(extData)
        self._modelIndex = FGUI:UIModel_addCharacterModel(self._model, extData, Vector3.New(0,0,0))
    end
    FGUI:UIModel_setModelCallback(self._model, function(index)
        FGUI:UIModel_playAnimation(self._model, index, "Idle", nil, 0)
    end)
end
function MentorShipTeach:ClearModel()
    if self._model then
        FGUI:UIModel_Unbind(self._model)
    end
end
function MentorShipTeach:AttrItemRender(idx, item)
    local attrData = self.showAttrList[idx+1]
    self:SetValueInText(item,attrData.Name,attrData.ShowValue,attrData.Desc)
end

function MentorShipTeach:SetValueInText(component,attrName,attValue,showStr)
    local mask = FGUI:GetChild(component,"mask")
    local attrNameComp = FGUI:GetChild(component,"text_name_attr")
    local textScroll = FGUI:GetChild(component,"text_value_attr")
    FGUI:GTextField_setText(attrNameComp,attrName)
    FGUI:GTextField_setText(textScroll,attValue)
    if not string.isNullOrEmpty(showStr) and mask then
        FGUI:setOnClickEvent(mask,function(eventData)
            FGUIFunction:OpenAttrTips(showStr,mask)
        end)
    end
end

function MentorShipTeach:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_RESPONSE_LOOK_PLAYER_INFO, "MentorShipTeach", handler(self, self.RefreshView))   
end

function MentorShipTeach:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_RESPONSE_LOOK_PLAYER_INFO, "MentorShipTeach")
end
return MentorShipTeach
