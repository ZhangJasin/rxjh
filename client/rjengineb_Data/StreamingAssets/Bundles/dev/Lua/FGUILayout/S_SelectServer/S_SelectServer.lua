local CountOfPage = 200

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local S_SelectServer = class("S_SelectServer", BaseFGUILayout)

local JOB_NAME_STRING_TABLE = {"弓手", "枪客", "刺客", "医师", "刀客", "剑客"}

function S_SelectServer:Create()
	self._uiRoot = FGUI:GetChild(self.component, "Root")
    self._ui = FGUI:ui_delegate( self._uiRoot)
	self._roleInfos      = SL:GetValue("ROLE_CACHE_INFO")

	self._serverGroups   = {} -- 所有服务器组数据(含我的服务器)
	

	self._isWhiteList    = SL:GetValue("IS_WHITE_LIST")
	self._lastSrvID      = SL:GetValue("LAST_SERVER_ID")
	self.handler_onClickGroupServer = handler(self, self.OnClickGroupItemEvent)
	self.handler_onClickSubServer = handler(self, self.OnClickSubItemEvent)
	self.handler_onGroupRenderer = handler(self, self.OnGroupServerItemRenderer)
	self.handler_onSubRenderer = handler(self, self.OnSubServerItemRenderer)

	self:InitServerData()
	
	local mask = FGUI:GetChild(self.component, "Mask")
	FGUI:setOnClickEvent(mask, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_refresh, handler(self, self.QueryServerList))
	FGUI:GList_itemRenderer(self._ui["list_left"], self.handler_onGroupRenderer)
	FGUI:GList_itemRenderer(self._ui["list_right"], self.handler_onSubRenderer)
	FGUI:GList_addOnClickItemEvent(self._ui["list_left"], self.handler_onClickGroupServer)
	FGUI:GList_addOnClickItemEvent(self._ui["list_right"], self.handler_onClickSubServer)
end

function S_SelectServer:Enter()
	self:RegisterEvent()
	self._selectGroupIdx = 0
	local lastIsWhiteList = self._isWhiteList
	self._isWhiteList = SL:GetValue("IS_WHITE_LIST")
	if lastIsWhiteList ~= self._isWhiteList then
		self:InitServerData()
	end
	self:InitGUI()
	self:QueryServerList()
end
function S_SelectServer:Exit()
	self._selectGroupIdx = nil
	self:RemoveEvent()
end
function S_SelectServer:Destroy()

	self._layoutRoleTemp = nil

	self._serverGroups = nil

	self._parent = nil
	self._ui = nil
end

function S_SelectServer:InitGUI()
	self:InitServerGroup()
	-- 默认选择我的角色,无数据则选择第二个
	local myServers = self._serverGroups[1]
	local group2 = self._serverGroups[2]
	if (myServers and myServers.items and #myServers.items > 0) or (not group2) then
		FGUI:GList_setSelectedIndex(self._ui["list_left"], 0)
		self:SelectGroup(1, true)
	else
		FGUI:GList_setSelectedIndex(self._ui["list_left"], 1)
		self:SelectGroup(2, true)
	end

	if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:setScale( self._uiRoot , 0.75, 0.75)
    else
        FGUI:setScale( self._uiRoot , 1, 1)
    end
end

function S_SelectServer:QueryServerList()
	SL:onLUAEvent(LUA_EVENT_QUERY_SERVER_LIST)
end

-- 区服列表刷新
function S_SelectServer:OnGroupServerItemRenderer(index, item)
	local data = self._serverGroups[index + 1]
	FGUI:GButton_setTitle(item, data.name)
end

function S_SelectServer:OnClickGroupItemEvent(context)
	local selectIdx = FGUI:GList_getSelectedIndex(self._ui["list_left"]) + 1
	self:SelectGroup(selectIdx)
end

-- 子服务器Item刷新
function S_SelectServer:OnSubServerItemRenderer(idx, item)
	local servers = self._serverGroups[self._selectGroupIdx]
	if not servers then return end

	local server = servers.items[idx + 1]
	if not server then return end

	-- 服务器名
	local suffix = ""
	if server.state == 5 then
		suffix = SL:GetValue("I18N_STRING", 13)
	end
	-- 白名单显示服务器id
	if self._isWhiteList then
		suffix = suffix .. string.format("(%s)", server.serverId)
	end
	local serverName = server.serverName .. suffix

	-- 服务器状态
	local statePath
	if server.state == 1 then
		-- 新服 绿色
		statePath = "ui://S_SelectServer/icon_server_green"
	elseif server.state == 2 then
		-- 普通 绿色
		statePath = "ui://S_SelectServer/icon_server_green"
	elseif server.state == 3 then
		-- 爆满
		statePath = "ui://S_SelectServer/icon_server_red"
	elseif server.state == 4 then
		-- 维护
		statePath = "ui://S_SelectServer/icon_server_grey"
	elseif server.state == 5 then
		-- 隐藏服 隐藏字
		statePath = "ui://S_SelectServer/icon_server_grey"
	else
		statePath = "ui://S_SelectServer/icon_server_green"
	end

	local shorPreLogin = self._lastSrvID == server.serverId -- 上次登陆
	FGUI:GButton_setIcon(item, statePath)
	FGUI:GButton_setTitle(item, serverName)

	-- 角色信息
	local roleInfo = self._roleInfos[tostring(server.serverId)]

	if roleInfo and roleInfo.roles and #roleInfo.roles > 0 then
		local roles = roleInfo.roles

		table.sort(roles, function(role1, role2)
			return role1.level > role2.level
		end)

		local roleData = roles[1]
		if roleData then		
			local jobName = JOB_NAME_STRING_TABLE[roleData.job]
			if jobName and roleData.level then
				local str = string.format("%s\n[color=#ffffff][size=20]%s  Lv.%s[/size][/color]", serverName, jobName, roleData.level)
				FGUI:GButton_setTitle(item, str)
			end		
		end
	end
end

function S_SelectServer:OnClickSubItemEvent(context)
	local item = context.data
	local idx = FGUI:GetChildIndex(self._ui["list_right"], item)
	local servers = self._serverGroups[self._selectGroupIdx]
	if not servers then return end
		
	local server = servers.items[idx + 1]
	if not server then return end

	--选中服务器
	-- 维护，且不是白名单
	if server.state == 4 and (not self._isWhiteList) then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING", 9))
		return nil
	end

	-- 隐藏服给提醒
	if server.state == 5 then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING", 12))
	end

	SL:onLUAEvent(LUA_EVENT_SELECT_SERVER, server)
	self:Close()
end

function S_SelectServer:InitMyRolesData()
	-- 已登录服务器
	local roleInfos               = self._roleInfos
	local items                   = {}
	local item                    = {}
	local servers                 = SL:GetValue("MY_SERVERS")
	item.index                    = 1
	item.name                     = SL:GetValue("I18N_STRING", 32)
	item.items                    = items
	self._serverGroups[1] = item
	-- 最后登录区服排前面
	table.sort(servers, function(a, b)
		if not a or not b then return false end
		if a.serverId == self._lastSrvID and b.serverId ~= self._lastSrvID then
			 return true 
		elseif a.serverId ~= self._lastSrvID and b.serverId == self._lastSrvID	then
			return false
		else
			return false
		end
	end)
	-- 筛选有角色信息的服务器
	for k, serverData in pairs(servers) do
		if serverData and serverData.serverId then
			local serverId = serverData.serverId
			local roleInfo = roleInfos[tostring(serverId)]
			if roleInfo and roleInfo.roles and #roleInfo.roles > 0 then
				table.insert(items, serverData)
			end
		end
	end
end

function S_SelectServer:InitServerData()
	local srvData      = SL:GetValue("SERVER_DATA")

	local groupCount   = 1 -- 1预留给我的角色
	local serverGroups = self._serverGroups
	local srvlist      = SL:GetValue("ALL_SERVERS")

	self:InitMyRolesData()
	-- 组
	-- 先tag为key，方便快速存储，再使用table.sort
	-- 服务器列表倒序遍历
	-- 问题1，没配置tag
	-- 问题2，配置tag但是不存在该tag组
	-- normalsrvlist 剩余正常列表

	-- hash
	local groupSrvlist = {}
	if srvData.srvgroup and type(srvData.srvgroup) == "table" then
		for i, v in ipairs(srvData.srvgroup) do
			groupSrvlist[v.tag] = { index = i, name = v.name, tag = v.tag, items = {} }
		end
	end
	-- 筛选出组列表和普通列表
	local normalsrvlist = {}
	for i, v in ipairs(srvlist) do
		local srvitem = v
		if srvitem.tag and groupSrvlist[srvitem.tag] then
			table.insert(groupSrvlist[srvitem.tag].items, srvitem)
		else
			table.insert(normalsrvlist, srvitem)
		end
	end
	-- 排序
	groupSrvlist = SL:HashToSortArray(groupSrvlist, function(a, b)
		return a.index < b.index
	end)

	for i, v in ipairs(groupSrvlist) do
		if #v.items > 0 then
			groupCount               = groupCount + 1
			local item               = {}
			item.index               = groupCount
			item.name                = v.name
			item.items               = v.items
			serverGroups[groupCount] = item
		end
	end

	-- 正常区服
	local pageCount = math.ceil(#normalsrvlist / CountOfPage)
	local function calcServersByPage(page)
		local begin = (page - 1) * CountOfPage + 1
		local ended = begin + CountOfPage - 1

		local servers = {}
		for i = begin, ended do
			table.insert(servers, normalsrvlist[i])
		end
		return servers
	end
	for page = pageCount, 1, -1 do
		local items              = calcServersByPage(page)

		groupCount               = groupCount + 1
		local item               = {}
		item.index               = groupCount
		item.name                = string.format(SL:GetValue("I18N_STRING", 11), (page - 1) * CountOfPage + 1,
			(page - 1) * CountOfPage + #items)
		item.items               = items
		serverGroups[groupCount] = item
	end

	self:InitGUI()
end

function S_SelectServer:InitServerGroup()
	local num = #self._serverGroups
	FGUI:GList_setNumItems(self._ui["list_left"], num)
end

function S_SelectServer:SelectGroup(idx, isForce)
	if not isForce and self._selectGroupIdx == idx then return end
	self._selectGroupIdx = idx
	self:UpdateDetailServerView()
end

function S_SelectServer:UpdateDetailServerView()
	local serverDatas = self._serverGroups[self._selectGroupIdx]
	if not serverDatas then return end
	FGUI:GList_setNumItems(self._ui["list_right"], #serverDatas.items)
end


-- 是否可以请求服务器列表改变
function S_SelectServer:OnQueryServerListAbleChange(isAble)
	FGUI:GButton_setBright(self._ui.btn_refresh, isAble)
end

-----------------------------------注册事件--------------------------------------
function S_SelectServer:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_CUSTOMDATA_CHANGE, "SelectServer", handler(self, self.InitServerData))
	SL:RegisterLUAEvent(LUA_EVENT_QUERY_SERVER_ABLE_CHANGE, "SelectServer", handler(self, self.OnQueryServerListAbleChange))
	SL:RegisterLUAEvent(LUA_EVENT_ROLEINFO_CHANGE, "SelectServer", handler(self, self.InitServerData))
	
end

function S_SelectServer:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_CUSTOMDATA_CHANGE, "SelectServer")
	SL:UnRegisterLUAEvent(LUA_EVENT_QUERY_SERVER_ABLE_CHANGE, "SelectServer")
	SL:UnRegisterLUAEvent(LUA_EVENT_ROLEINFO_CHANGE, "SelectServer")
end

return S_SelectServer