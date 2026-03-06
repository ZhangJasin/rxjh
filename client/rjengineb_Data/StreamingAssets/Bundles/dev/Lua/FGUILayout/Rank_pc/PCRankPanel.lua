local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCRankPanel = class("PCRankPanel", BaseFGUILayout)

local ALL_DATA = {
	[1] = {id = 0, name = "全部"}
}

local CAMP_DATA = {
	[1] = {id = 1, name = "正派", camp = 1},
	[2] = {id = 2, name = "邪派", camp = 2}
}

local JOB_DATA = {
	[1] = {id = 1, name = "弓手", job = 1},
	[2] = {id = 2, name = "枪客", job = 2},
	[3] = {id = 3, name = "刺客", job = 3},
	[4] = {id = 4, name = "医生", job = 4},
	[5] = {id = 5, name = "刀客", job = 5},
	[6] = {id = 6, name = "剑客", job = 6},
}

local RANK_INFO = {
	[1] = {id = 1, name = "玩家名称", key = "Name"},
	[2] = {id = 2, name = "行会名称", key = "GuildName"},
	[3] = {id = 3, name = "在线状态", key = "Online"},
}

local VIEW_INDEX = 4

function PCRankPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	--FGUI:SetCloseUIWhenClickOutside(self)
	FGUIFunction:setWindowDrag(self.component, self._ui.bg)
	self:InitData()
	self:InitEvent()
end 

function PCRankPanel:Enter()
    self:RegisterEvent()
	SL:ComponentAttach(SLDefine.SUIComponentTable.Rank, self._ui.Node_attach)
end

function PCRankPanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.Rank)
	self._selectCamp = 0
	self._selectJob = 0
    self._selectUserID = nil
	self._index = 0

	self:RemoveEvent()
	self.super.Close(self)
end

function PCRankPanel:InitData()
	self._rankGroup = SL:GetValue("RANK_GROUP_LIST")
	self._selectGroupID = 1
	self._selectMenuID = 0
    self._selectUserID = nil
	self._rankList = {}
	self._rankConfig = {}
	self._rankTypeList = {}
	self._rankInfo = {}
	self._index = 0
end

function PCRankPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Exit))
	FGUI:setOnClickEvent(self._ui.btn_arrow, handler(self, self.OnClickBtnArrow))

	self.rootTreeNode = FGUI:GTree_getRootNode(self._ui.tree_list)
	self.parent = {}
	self.child = {}
	for i, group in ipairs(self._rankGroup) do 
		-- parent
        self.parent[i] = FGUI:GTreeNode_Create("ui://vccyhmfwitlam", true)
		FGUI:GTreeNode_addChild(self.rootTreeNode, self.parent[i])
		FGUI:GTreeNode_setExpanded(self.parent[i], true)

		local parentCell = FGUI:GTreeNode_getCell(self.parent[i])
		local text_normal = FGUI:GetChild(parentCell, "text_normal")
		local text_select = FGUI:GetChild(parentCell, "text_select")
		FGUI:GTextField_setText(text_normal, group[1].NameType)
		FGUI:GTextField_setText(text_select, group[1].NameType)

		FGUI:addOnClickMultipleEvent(parentCell, function()
			local isExpanded = FGUI:GTreeNode_getExpanded(self.parent[i])
			FGUI:GButton_setSelected(parentCell, isExpanded)
		end)  

		-- child      
		for j, menu in ipairs(group) do 
			if not self.child[i] then 
				self.child[i] = {}
			end 
			self.child[i][j] = FGUI:GTreeNode_Create("ui://vccyhmfwid4uy", false)
			FGUI:GTreeNode_addChild(self.parent[i], self.child[i][j])
			local childCell = FGUI:GTreeNode_getCell(self.child[i][j])
			local text_normal = FGUI:GetChild(childCell, "text_n")
			local text_select = FGUI:GetChild(childCell, "text_s")
			FGUI:GTextField_setText(text_normal, menu.Name)
			FGUI:GTextField_setText(text_select, menu.Name)

			FGUI:addOnClickMultipleEvent(childCell, function()
				FGUI:GButton_setSelected(parentCell, true)

				self:SelectGroup(i)
				self:SelectMenu(j)
				self:SelectType()
			end)  

			if i == 1 and j == 1 then 
				FGUI:GButton_setSelected(parentCell, true)
				FGUI:GButton_setSelected(childCell, true)
			end 
		end 
	end 

	self:SelectGroup(1)
	self:SelectMenu(1)
	self:SelectType()

	-- type list 
	for i = 1, #ALL_DATA do 
		table.insert(self._rankTypeList, ALL_DATA[i])
	end 
	FGUI:GList_itemRenderer(self._ui.list_type, handler(self, self.ItemRendererType))
    FGUI:GList_addOnClickItemEvent(self._ui.list_type, handler(self, self.OnClickItemType))
    FGUI:GList_setNumItems(self._ui.list_type, #self._rankTypeList)
    FGUI:GList_setSelectedIndex(self._ui.list_type, 0)

	-- title 
	FGUI:GList_itemRenderer(self._ui.list_title, handler(self, self.ItemRendererTitle))
    FGUI:GList_setNumItems(self._ui.list_title, #self._rankInfo)

	-- rank 
	FGUI:GList_itemRenderer(self._ui.list_rank, handler(self, self.ItemRendererRank))
    FGUI:GList_addOnClickItemEvent(self._ui.list_rank, handler(self, self.OnClickItemRank))
end

function PCRankPanel:SelectGroup(selectIdx)
	self._selectUserID = nil
	self._selectGroupID = selectIdx
end

function PCRankPanel:SelectMenu(selectIdx)
	self._selectUserID = nil
	self._selectMenuID = self._rankGroup[self._selectGroupID][selectIdx].nId
end

function PCRankPanel:SelectType()
	self:RefreshTypeList()
	self:RefreshTextTitleList()
end

-- rank type
function PCRankPanel:RefreshTypeList()
    FGUI:GList_setNumItems(self._ui.list_type, 0)

	if not self._selectGroupID then 
		return 
	end 

	if not self._selectMenuID then 
		return 
	end 

	self._rankConfig = SL:GetValue("RANK_CONFIG_BY_ID", self._selectMenuID)
	if not self._rankConfig then 
		return 
	end 

	table.clear(self._rankTypeList)

	for i = 1, #ALL_DATA do 
		table.insert(self._rankTypeList, ALL_DATA[i])
	end 

	if self._rankConfig.Camp == 1 then 
		for i = 1, #CAMP_DATA do 
			table.insert(self._rankTypeList, CAMP_DATA[i])
		end 
	end 

	if self._rankConfig.AllJob == 1 then 
		for i = 1, #JOB_DATA do 
			table.insert(self._rankTypeList, JOB_DATA[i])
		end 
	end 	

    FGUI:GList_setNumItems(self._ui.list_type, #self._rankTypeList)
    FGUI:GList_setSelectedIndex(self._ui.list_type, 0)
	SL:RequestRankListByRankID(self._selectMenuID, 0, 0)
end

function PCRankPanel:ItemRendererType(idx, item)
	local index = idx + 1
	local data = self._rankTypeList[index]
	if not data then 
		return 
	end 

    local text_normal = FGUI:GetChild(item, "text_normal")
    local text_select = FGUI:GetChild(item, "text_select")
    FGUI:GTextField_setText(text_normal, data.name)
    FGUI:GTextField_setText(text_select, data.name)
end

function PCRankPanel:OnClickItemType(context)
	local idx = FGUI:GList_getSelectedIndex(self._ui.list_type)
    FGUI:GList_setSelectedIndex(self._ui.list_type, idx)

	local index = idx + 1
	local data = self._rankTypeList[index]
	if not data then 
		return 
	end 

	self._selectCamp = 0
	self._selectJob = 0
	if data.camp then 
		self._selectCamp = data.camp
	end 

	if data.job then 
		self._selectJob = data.job
	end 

	SL:RequestRankListByRankID(self._selectMenuID, self._selectCamp, self._selectJob)
end

-- text title
function PCRankPanel:RefreshTextTitleList()
	if not self._selectGroupID then 
		return 
	end 

	if not self._selectMenuID then 
		return 
	end 

	local config = SL:GetValue("RANK_CONFIG_BY_ID", self._selectMenuID)
	if not config then 
		return 
	end 

	table.clear(self._rankInfo)

	if config.PlayerName == 1 then 
		table.insert(self._rankInfo, RANK_INFO[1])
	end 

	if config.GuildNames == 1 then 
		table.insert(self._rankInfo, RANK_INFO[2])
	end 
	
	if config.State == 1 then 
		table.insert(self._rankInfo, RANK_INFO[3])
	end 

	if config.AddCusVarName then 
		local nameList = string.split(config.AddCusVarName, "#")
		for i = 1, #nameList do 
			local data = {id = i, name = nameList[i], key = "Param"..i}
			table.insert(self._rankInfo, data)
		end 
	end 

    FGUI:GList_setNumItems(self._ui.list_title, #self._rankInfo)

	self._index = 0
	FGUI:setRotation(self._ui.btn_arrow, 0)
	FGUI:stopAllActions(self._ui.btn_arrow)
	if #self._rankInfo > VIEW_INDEX then 
		FGUI:setVisible(self._ui.btn_arrow, true)
		local acBlink = FGUI:ActionBlink(1, 3)
		FGUI:runAction(self._ui.btn_arrow, acBlink)
	else 
		FGUI:setVisible(self._ui.btn_arrow, false)
	end
end

function PCRankPanel:ItemRendererTitle(idx, item)
	local index = idx + 1
	local data = self._rankInfo[index]
	if not data then 
		return 
	end 

    local text_value = FGUI:GetChild(item, "text_value")
    FGUI:GTextField_setText(text_value, data.name)
end

function PCRankPanel:OnResponseRankData(menuID)
	if self._selectMenuID ~= menuID then
        return
    end

	table.clear(self._rankList)
	self._rankList = SL:GetValue("RANK_DATA_BY_RANK_ID", menuID)
    FGUI:GList_setNumItems(self._ui.list_rank, #self._rankList)
	FGUI:GList_setSelectedIndex(self._ui.list_rank, 0)

	local rankData = self._rankList[1]
	if rankData then 
		self._selectUserID = tonumber(rankData.UserID)
	end

	self:ShowMyRank()
end

function PCRankPanel:ItemRendererRank(idx, item)
	local img_rank = FGUI:GetChild(item, "img_rank")
	local text_rank = FGUI:GetChild(item, "text_rank")
	local list_value = FGUI:GetChild(item, "list_value")

	local rank = idx + 1
	local data = self._rankList[rank]
	if not data then 
		return 
	end

	if rank <= 3 then     
		FGUI:GTextField_setText(text_rank, "")
		FGUI:setVisible(img_rank, true)
		FGUI:GLoader_setUrl(img_rank, string.format("ui://Rank_pc/rank_icon%s", rank))
	else 
		FGUI:GTextField_setText(text_rank, rank)
		FGUI:setVisible(img_rank, false)
	end 

	-- text value
	FGUI:GList_itemRenderer(list_value, function(idx, item)
		local text_value = FGUI:GetChild(item, "text_value")
		local index = idx + 1
		local key = self._rankInfo[index].key
		if key == "Name" then     
			FGUI:GTextField_setText(text_value, data.Name)
		elseif key == "GuildName" then 
			FGUI:GTextField_setText(text_value, data.GuildName == "" and "-" or data.GuildName)
		elseif key == "Online" then     
			FGUI:GTextField_setText(text_value, data.Online == 1 and GET_STRING(2007) or GET_STRING(2008))
		elseif key == "Param1" then     
			FGUI:GTextField_setText(text_value, data.Param1 == "" and "-" or data.Param1)
		elseif key == "Param2" then     
			FGUI:GTextField_setText(text_value, data.Param2 == "" and "-" or data.Param2)
		elseif key == "Param3" then     
			FGUI:GTextField_setText(text_value, data.Param3 == "" and "-" or data.Param3)
		end 
	end)
    FGUI:GList_setNumItems(list_value, #self._rankInfo)
end

function PCRankPanel:OnClickItemRank(context)
	local selectIdx = FGUI:GList_getSelectedIndex(self._ui.list_rank) + 1
	local rankData = self._rankList[selectIdx]
	if rankData then 
		self._selectUserID = tonumber(self._rankList[selectIdx].UserID)
		local myUID = SL:GetValue("USER_ID")
		if self._selectUserID == myUID then 
			return 
		end 
		
        local data = {
            targetId = self._selectUserID,
            TipsType = SL:GetValue("DOCKTYPE_NENUM").Func_Player_Rank,
        }
		FGUIFunction:RequestPlayerDataAndSetTipType(data)
	end
end

function PCRankPanel:ShowMyRank()
	local myLevel = SL:GetValue("LEVEL")
	local myJob = SL:GetValue("JOB")
	local mySex = SL:GetValue("SEX")
	local myName = SL:GetValue("USER_NAME")
	local myGuild = SL:GetValue("GUILD_USER_INFO")
	local playerUserId = SL:GetValue("USER_ID")

	local myData = nil
    local rankList = SL:GetValue("RANK_DATA_BY_RANK_ID", self._selectMenuID)
    for _, v in ipairs(rankList) do
        local userId = tonumber(v.UserID)
        if playerUserId == userId then 
			myData = v
            break
        end 
    end

	if not myData then 
		FGUI:GTextField_setText(self._ui.text_myRank, GET_STRING(60007001))
    	FGUI:GList_setNumItems(self._ui.list_self, 0)
		return 
	end 

	FGUI:GTextField_setText(self._ui.text_myRank, myData.Rank)
	FGUI:GList_itemRenderer(self._ui.list_self, function(idx, item)
		local text_value = FGUI:GetChild(item, "text_value")
		local index = idx + 1
		local key = self._rankInfo[index].key
		if key == "Name" then     
			FGUI:GTextField_setText(text_value, myData.Name)
		elseif key == "GuildName" then 
			FGUI:GTextField_setText(text_value, myData.GuildName == "" and "-" or myData.GuildName)
		elseif key == "Online" then     
			FGUI:GTextField_setText(text_value, myData.Online == 1 and GET_STRING(2007) or GET_STRING(2008))
		elseif key == "Param1" then     
			FGUI:GTextField_setText(text_value, myData.Param1 == "" and "-" or myData.Param1)
		elseif key == "Param2" then     
			FGUI:GTextField_setText(text_value, myData.Param2 == "" and "-" or myData.Param2)
		elseif key == "Param3" then     
			FGUI:GTextField_setText(text_value, myData.Param3 == "" and "-" or myData.Param3)
		end 
	end)
    FGUI:GList_setNumItems(self._ui.list_self, #self._rankInfo)
end

function PCRankPanel:OnClickBtnArrow(context)
	local max_index = #self._rankInfo
	if max_index <= VIEW_INDEX then 
		return 
	end 

	local rotation = FGUI:getRotation(context.sender) 
	if rotation == 0 then 
		self._index = self._index + VIEW_INDEX
		if self._index >= max_index - VIEW_INDEX then 
			self._index = max_index - VIEW_INDEX
			FGUI:setRotation(context.sender, 180)
		end 
	elseif rotation == 180 then 
		self._index = self._index - VIEW_INDEX
		if self._index <= 0 then 
			self._index = 0
			FGUI:setRotation(context.sender, 0)
		end 
	end 

	FGUI:GList_ScrollToView(self._ui.list_title, self._index, true, true)

	local children = FGUI:GetChildren(self._ui.list_rank)
	if not children or not next(children) then 
		return 
	end 
	for i = 1, #children do  
		local list_value = FGUI:GetChild(children[i], "list_value")
		FGUI:GList_ScrollToView(list_value, self._index, true, true)
	end 

	local myChildren = FGUI:GetChildren(self._ui.list_self)
	if not myChildren or not next(myChildren) then 
		return 
	end 
	FGUI:GList_ScrollToView(self._ui.list_self, self._index, true, true)
end

function PCRankPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_RANK_DATA_UPDATE, "PCRankPanel", handler(self, self.OnResponseRankData))
end

function PCRankPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_RANK_DATA_UPDATE, "PCRankPanel")
end

return PCRankPanel