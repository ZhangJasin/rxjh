local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MiniMapPanel = class("MiniMapPanel", BaseFGUILayout)

local LINK_TYPE_FROM				= 1
local LINK_TYPE_TO					= 2

local RIGHT_TYPE_NPC				= 1
local RIGHT_TYPE_MONSTER			= 2

local POINT_TYPE_LINK				= 1 -- 传送点
local POINT_TYPE_NPC				= 2 -- NPC
local POINT_TYPE_MONSTER			= 3 -- 怪物
local POINT_TYPE_BOSS				= 4 -- Boss
local POINT_TYPE_FRIEND				= 5 -- 友方
local POINT_TYPE_PLAYER				= 6 -- 玩家

local insert = table.insert

local RightItemData = class("RightItemData")
function RightItemData:ctor(type, url, render, isType)
	self.__type = type
	self._url = url
	self._render = render
	self._isType = isType or false
	self._enable = false
	self._data = nil
end

function MiniMapPanel:Create()
	self._ui				= FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
	if SL:GetValue("IS_PC_OPER_MODE") then
        self._packageName = "MiniMap_pc"
    else
        self._packageName = "MiniMap"
    end
	self._tracePoint = FGUIFunction:BindClass(self._ui("mapComponent", "node_tracePoint"), "TracePoint/TracePointBox")
	self._tracePoint:Create(self._packageName, "map_trace_point_item", handler(self, self.CalcMiniMapPos), 0)
	self._map_loader		= FGUI:getChildByName(self._ui.mapComponent, "map_loader")
	self.Graph_line			= FGUI:getChildByName(self._ui.mapComponent, "graph_line")
	self._node_player		= FGUI:getChildByName(self._ui.mapComponent, "node_player")
	self._node_point		= FGUI:getChildByName(self._ui.mapComponent, "node_point")
	self._node_info			= FGUI:getChildByName(self._ui.mapComponent, "node_info")
	self._targetPoint		= FGUI:getChildByName(self._ui.mapComponent, "targetPoint")
	FGUI:setVisible(self._targetPoint, false)
	self:InitData()
	self:InitEvent()
end 

function MiniMapPanel:Enter()
	self:RegisterEvent()
	MiniMapPanelObj = self
	FGUI:GComponent_ClearLine(self.Graph_line)
	self._mapCfg = {} -- 地图数据(左侧列表)
	local now_mapId = SL:GetValue("MAP_ID")
	self:RefreshLeftList(now_mapId)
	self:ChangeMap(now_mapId)
	self._tracePoint:Enter()
	SL:ComponentAttach(SLDefine.SUIComponentTable.MiniMap, self._ui.Node_attach)
end

function MiniMapPanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.MiniMap)
	self._tracePoint:Exit()
	if self.scheduleId then
		SL:UnSchedule(self.scheduleId)
		self.scheduleId = nil
	end
	if self._timeDownSign then
		SL:UnSchedule(self._timeDownSign)
		self._timeDownSign = nil
	end
	self:RemoveEvent()
end

function MiniMapPanel:Destroy()
	self._tracePoint:Destroy()
end

function MiniMapPanel:OnClose()
	self.super.Close(self)
end

function MiniMapPanel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_MINIMAP_MONSTER, "MiniMapPanel", handler(self, self.OnUpdateMonsterInfo))

	SL:RegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MiniMapPanel", handler(self, self.OnMapChange))
	SL:RegisterLUAEvent(LUA_EVENT_CHANGE_LIGHT, "MiniMapPanel", handler(self, self.OnChangeLight))

	SL:RegisterLUAEvent(LUA_EVENT_FIND_PATH_BEGAIN, "MiniMapPanel", handler(self, self.FindPathBegin))
    SL:RegisterLUAEvent(LUA_EVENT_FIND_PATH_EMD, "MiniMapPanel", handler(self, self.FindPathEnd))

	SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_PROCESS, "MiniMapPanel", handler(self, self.OnPlayerAction))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_COMPLETE, "MiniMapPanel", handler(self, self.OnPlayerAction))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_DIRECTION_CHANGE, "MiniMapPanel", handler(self, self.OnPlayerRotate))

	SL:RegisterLUAEvent(LUA_EVENT_ACTOR_IN_OF_VIEW, "MiniMapPanel", handler(self, self.OnActorInOfView))
    SL:RegisterLUAEvent(LUA_EVENT_ACTOR_OUT_OF_VIEW, "MiniMapPanel", handler(self, self.OnActorOutOfView))
    SL:RegisterLUAEvent(LUA_EVENT_NET_PLAYER_DIE, "MiniMapPanel", handler(self, self.OnActorDie))
    SL:RegisterLUAEvent(LUA_EVENT_MONSTER_DIE, "MiniMapPanel", handler(self, self.OnActorDie))
    SL:RegisterLUAEvent(LUA_EVENT_NET_PLAYER_REVIVE, "MiniMapPanel", handler(self, self.OnActorRevive))
    SL:RegisterLUAEvent(LUA_EVENT_MONSTER_REVIVE, "MiniMapPanel", handler(self, self.OnActorRevive))
	SL:RegisterLUAEvent(LUA_EVENT_NET_PLAYER_ACTION_COMPLETE, "MiniMapPanel", handler(self, self.OnActorAction))
	
	SL:RegisterLUAEvent(LUA_EVENT_USE_TRANSMIT, "MiniMapPanel", handler(self, self.OnReceiveUseTransfer))
end

function MiniMapPanel:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_MINIMAP_MONSTER, "MiniMapPanel")

	SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MiniMapPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_LIGHT, "MiniMapPanel")

	SL:UnRegisterLUAEvent(LUA_EVENT_FIND_PATH_BEGAIN, "MiniMapPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_FIND_PATH_EMD, "MiniMapPanel")

	SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_PROCESS, "MiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_COMPLETE, "MiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_DIRECTION_CHANGE, "MiniMapPanel")

	SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_IN_OF_VIEW, "MiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_OUT_OF_VIEW, "MiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NET_PLAYER_DIE, "MiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_MONSTER_DIE, "MiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NET_PLAYER_REVIVE, "MiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_MONSTER_REVIVE, "MiniMapPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_NET_PLAYER_ACTION_COMPLETE, "MiniMapPanel")

	SL:UnRegisterLUAEvent(LUA_EVENT_USE_TRANSMIT, "MiniMapPanel")
end

function MiniMapPanel:InitData()
	-- 关闭按钮
	self.handler_clickCloseBtn				= handler(self, self.OnClose)

	-- 左边列表Render
	self.handler_leftItemRender				= handler(self, self.LeftItemRender)
	-- 点击左边列表Item
	self.handler_clickLinkPoint				= handler(self, self.OnClickMapItem)

	-- 右边列表Render
	self.handler_rightItemRender			= handler(self, self.RightItemRender)
	-- 点击右边列表Item
	self.handler_clickRightItem				= handler(self, self.OnClickRightItem)
	-- 点击Monster Item
	self.handler_clickMonsterItem			= handler(self, self.OnClickMonsterItem)
	-- 点击item的传送按钮
	self.handler_clickTransmitBtn			= handler(self, self.OnClickTransmitBtn)
	-- 刷新Boss复活倒计时
	self.handler_updateTimeDown				= handler(self, self.PointProcressorBossUpdateTimeDown)

	self._mapSizeW, self._mapSizeH = FGUI:getSize(self._map_loader)
	self._pointHandlers = 
	{
		[POINT_TYPE_LINK] = {
			["__type"] = POINT_TYPE_LINK,
			["_icon"] = "map_point_icon",
			["_processor"] = handler(self, self.PointProcessor_Link),
			["_name_bg"] = "map_point_name_bg",
			["_name"] = "map_point_name_default",
		},
		[POINT_TYPE_NPC] = {
			["__type"] = POINT_TYPE_NPC,
			["_icon"] = "map_point_icon",
			["_processor"] = handler(self, self.PointProcessor_Npc),
			["_name_bg"] = "map_point_name_bg",
			["_name"] = "map_point_name_npc",
		},
		[POINT_TYPE_MONSTER] = {
			["__type"] = POINT_TYPE_MONSTER,
			["_icon"] = "map_point_icon",
			["_processor"] = handler(self, self.PointProcessor_Monster),
			["_name_bg"] = "map_point_name_bg_monster",
			["_name"] = "map_point_name_monster",
		},
		[POINT_TYPE_BOSS] = {
			["__type"] = POINT_TYPE_BOSS,
			["_icon"] = "map_point_icon_boss",
			["_processor"] = handler(self, self.PointProcessor_Boss),
			["_name_bg"] = "map_point_name_bg_boss",
			["_name"] = "map_point_name_boss",
		},
		[POINT_TYPE_FRIEND] = {
			["__type"] = POINT_TYPE_FRIEND,
			["_icon"] = "map_point_icon",
			["_name_bg"] = "map_point_name_bg",
			["_name"] = "map_point_name_friend",
		},
	}

	self._pointFilter = {
		[POINT_TYPE_LINK] = true,
		[POINT_TYPE_NPC] = true,
		[POINT_TYPE_MONSTER] = true,
		[POINT_TYPE_BOSS] = true,
		[POINT_TYPE_FRIEND] = true,
		[POINT_TYPE_PLAYER] = true,
	}
	
	self._elements = {}
	self._elementPool = {}
end

function MiniMapPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, self.handler_clickCloseBtn)

	FGUI:GList_itemRenderer(self._ui.list_left, self.handler_leftItemRender)
	FGUI:GList_addOnClickItemEvent(self._ui.list_left, self.handler_clickLinkPoint)

	FGUI:GList_itemRenderer(self._ui.list_right, self.handler_rightItemRender)
	FGUI:GList_addOnClickItemEvent(self._ui.list_right, self.handler_clickRightItem)

	FGUI:setOnClickEvent(self._ui.mapComponent, handler(self, self.OnClickMap))
	-- FGUI:setOnClickEvent(self._ui.btn_transmit, handler(self, self.OnClickTransmitButton))
	FGUI:setOnClickEvent(self._ui.btn_monster, handler(self, self.OnClickMonsterType))
	FGUI:setOnClickEvent(self._ui.btn_npc, handler(self, self.OnClickNpcType))
	FGUI:GButton_setOnChangedCallback(self._ui.tog_boss, handler(self, self.OnSwitchBossFilter))
	FGUI:GButton_setOnChangedCallback(self._ui.tog_monster, handler(self, self.OnSwitchMonsterFilter))
	FGUI:GButton_setOnChangedCallback(self._ui.tog_link, handler(self, self.OnSwitchLinkFilter))
	if  global.isEditor or (global.isWindows and global.isDebugBuild) then
		FGUI:setOnClickEvent(self._ui.btn_debug,function()
			FGUI:Open(self._packageName, "MiniMapDebugPanel", nil, FGUI_LAYER.NOTICE, {classPath = "FGUILayout/MiniMap/MiniMapDebugPanel"})
		end)
	else
		FGUI:setVisible(self._ui.btn_debug, false)
	end
end
-- BEGIN 左列表 =====================================================
-- 二级列表数据结构
--[[
数据结构示例：
{
    { type = "group", name = "野外", isOpen = true, children = {
        { type = "item", mapId = 1, mapName = "泫勃派" },
        { type = "item", mapId = 2, mapName = "银杏谷" }
    }},
    { type = "group", name = "副本", isOpen = false, children = {
        { type = "item", mapId = 3, mapName = "牛洞" }
    }}
}
]]

-- 刷新左边的列表（二级栏结构）
function MiniMapPanel:RefreshLeftList(now_mapId)
	self._mapId = now_mapId

	local allInfo = SL:GetValue("MAP_ALL_INFO_CONFIG")
	-- 按MapType分组
	local groupMap = {}
	for _, v in pairs(allInfo) do
		-- 过滤掉MapType为""、0和1的数据
		local mapTypeNum = tonumber(v.MapType)
		if v.MapType and v.MapType ~= "" and mapTypeNum ~= 0 and mapTypeNum ~= 1 then
			local groupName = tostring(v.MapType)
			if not groupMap[groupName] then
				-- 首次出现该MapType时，创建分组
				groupMap[groupName] = {
					type = "group",
					name = groupName,  -- 一级分类名称就是MapType的值
					sort = v.Sort or 0,
					isOpen = false,
					children = {}
				}
			end
			-- 将该地图添加到二级分类列表中
			table.insert(groupMap[groupName].children, {
				type = "item",
				mapId = v.MapId,
				mapName = v.MapName,
				sort = v.Sort or 0
			})
		end
	end

	-- 转换为数组并排序（只保留有子项的分组）
	self._leftGroupList = {}
	for _, group in pairs(groupMap) do
		-- 跳过无子项的空分组
		if #group.children > 0 then
			-- 对组内子项按Sort排序
			table.sort(group.children, function(a, b)
				return (a.sort or 0) < (b.sort or 0)
			end)
			-- 更新组的sort为子项中最小的sort
			group.sort = group.children[1].sort
			table.insert(self._leftGroupList, group)
		end
	end
	-- 对分组按Sort排序
	table.sort(self._leftGroupList, function(a, b)
		return (a.sort or 0) < (b.sort or 0)
	end)

	-- 第一步：标记当前地图所在组为展开状态
	for i, group in ipairs(self._leftGroupList) do
		group.isOpen = false  -- 先全部折叠
		for _, child in ipairs(group.children) do
			if child.mapId == now_mapId then
				group.isOpen = true  -- 展开包含当前地图的组
				break
			end
		end
	end

	-- 第二步：计算总行数（只统计展开组的子项）
	local totalRows = 0
	for i, group in ipairs(self._leftGroupList) do
		totalRows = totalRows + 1  -- 组标题行
		if group.isOpen then
			totalRows = totalRows + #group.children  -- 只统计展开组的子项
		end
	end

	-- 设置列表项数量
	FGUI:GList_setNumItems(self._ui.list_left, totalRows)

	-- 设置选中当前地图
	self:_setSelectedMap(now_mapId)
end

-- 设置选中当前地图
function MiniMapPanel:_setSelectedMap(now_mapId)
	local rowIdx = 0
	for i, group in ipairs(self._leftGroupList) do
		rowIdx = rowIdx + 1  -- 组标题行
		if group.isOpen then
			for j, child in ipairs(group.children) do
				rowIdx = rowIdx + 1  -- 子项行
				if child.mapId == now_mapId then
					FGUI:GList_setSelectedIndex(self._ui.list_left, rowIdx - 1)
					return
				end
			end
		end
	end
end

-- 刷新左Item（二级列表渲染）
function MiniMapPanel:LeftItemRender(idx, item)
	-- 计算当前行对应的组和子项
	local rowIdx = 0
	for i, group in ipairs(self._leftGroupList) do
		rowIdx = rowIdx + 1  -- 组标题行
		if rowIdx - 1 == idx then
			-- 这是组标题行
			self:_renderGroupItem(item, group)
			return
		end
		if group.isOpen then
			for j, child in ipairs(group.children) do
				rowIdx = rowIdx + 1  -- 子项行
				if rowIdx - 1 == idx then
					-- 这是子项行
					self:_renderChildItem(item, child, group.name)
					return
				end
			end
		end
	end
	-- idx 超出范围时，清空item内容
	FGUI:GButton_setTitle(item, "")
	local title = FGUI:getChildByName(item, "title")
	if title then
		FGUI:GTextField_setText(title, "")
	end
	local arrow = FGUI:getChildByName(item, "arrow")
	if arrow then
		FGUI:setVisible(arrow, false)
	end
end

-- 渲染组标题行
function MiniMapPanel:_renderGroupItem(item, group)
	-- 使用Button的title属性设置标题
	FGUI:GButton_setTitle(item, group.name)
	-- 设置一级分类字号为20
	local title = FGUI:getChildByName(item, "title")
	if title then
		FGUI:GTextField_setFontSize(title, 20)
	end
	-- 获取arrow控件用于显示展开/折叠状态
	local arrow = FGUI:getChildByName(item, "arrow")
	if arrow then
		-- 空数据（无子项）时隐藏arrow
		if #group.children == 0 then
			FGUI:setVisible(arrow, false)
		else
			FGUI:setVisible(arrow, true)  -- 确保arrow可见（组件复用时可能处于隐藏状态）
			if group.isOpen then
				FGUI:setRotation(arrow, 90)  -- 展开状态，箭头向下
			else
				FGUI:setRotation(arrow, 0)   -- 折叠状态，箭头向右
			end
		end
	end
end

-- 渲染子项行
function MiniMapPanel:_renderChildItem(item, child, groupName)
	-- 使用Button的title属性设置标题
	FGUI:GButton_setTitle(item, child.mapName)
	-- 获取title控件并设置小一号字号
	local title = FGUI:getChildByName(item, "title")
	if title then
		FGUI:GTextField_setFontSize(title, 16)  -- 二级分类字号小一号
	end
	-- 隐藏arrow控件
	local arrow = FGUI:getChildByName(item, "arrow")
	if arrow then
		FGUI:setVisible(arrow, false)
	end
end

-- 点击传送点item
function MiniMapPanel:OnClickMapItem(context)
	local childIdx = FGUI:GetChildIndex(self._ui.list_left, context.data)
	local index = FGUI:GList_childIndexToItemIndex(self._ui.list_left, childIdx)

	-- 根据index查找对应的数据
	local info = self:_getInfoByIndex(index)
	if not info then return end

	if info.type == "group" then
		-- 点击的是组标题，切换展开/折叠状态
		self:_toggleGroup(info.groupName)
	elseif info.type == "item" then
		-- 点击的是子项，切换地图
		if self._mapId ~= info.mapId then
			self:ChangeMap(info.mapId)
		end
	end
end

-- 根据index查找对应的组/子项信息
function MiniMapPanel:_getInfoByIndex(index)
	local rowIdx = 0
	for i, group in ipairs(self._leftGroupList) do
		rowIdx = rowIdx + 1  -- 组标题行
		if rowIdx - 1 == index then
			return { type = "group", groupName = group.name }
		end
		if group.isOpen then
			for j, child in ipairs(group.children) do
				rowIdx = rowIdx + 1  -- 子项行
				if rowIdx - 1 == index then
					return { type = "item", mapId = child.mapId, mapName = child.mapName }
				end
			end
		end
	end
	return nil
end

-- 切换组的展开/折叠状态
function MiniMapPanel:_toggleGroup(groupName)
	for i, group in ipairs(self._leftGroupList) do
		if group.name == groupName then
			local wasOpen = group.isOpen
			group.isOpen = not group.isOpen
			-- 重新计算总行数
			local totalRows = 0
			for _, g in ipairs(self._leftGroupList) do
				totalRows = totalRows + 1
				if g.isOpen then
					totalRows = totalRows + #g.children
				end
			end
			FGUI:GList_setNumItems(self._ui.list_left, totalRows)
			-- 展开时默认选中第一个子项
			if group.isOpen and not wasOpen and #group.children > 0 then
				local firstChild = group.children[1]
				-- 计算第一个子项在列表中的索引
				local firstChildIndex = 0
				for idx, g in ipairs(self._leftGroupList) do
					firstChildIndex = firstChildIndex + 1  -- 组标题行
					if g == group then
						firstChildIndex = firstChildIndex + 1  -- 第一个子项行
						break
					end
					if g.isOpen then
						firstChildIndex = firstChildIndex + #g.children
					end
				end
				FGUI:GList_setSelectedIndex(self._ui.list_left, firstChildIndex - 1)
				-- 切换地图
				if self._mapId ~= firstChild.mapId then
					self:ChangeMap(firstChild.mapId)
				end
			end
			return
		end
	end
end
-- END 左列表 =====================================================

-- 当地图变化
function MiniMapPanel:ChangeMap(mapId)
	self._mapId				= mapId
	self._isCurMap			= SL:GetValue("MAP_ID") == mapId
	local offset 			= SL:GetValue("MINIMAP_OFFSET", self._mapId)
	self._offsetX			= offset[1]
	self._offsetY			= offset[2]
    local mapCameraSize		= SL:GetValue("MINIMAP_CAMERA_SIZE", self._mapId)
    self._mapParamX			= self._mapSizeW / self._mapSizeH * mapCameraSize
    self._mapParamY			= mapCameraSize
	self._tempDatas			= nil
	self._timeDownInfos		= {}
	self._actorPoints		= {}
	self._elementsForType 	= {}
	if self._timeDownSign then
		SL:UnSchedule(self._timeDownSign)
		self._timeDownSign = nil
	end

	self:RecycleElement()
	-- 小地图怪物数据请求
	SL:RequestMiniMapMonsters(self._mapId)
	FGUI:GLoader_setUrl(self._map_loader, SL:GetValue("MINIMAP_FILE", self._mapId))
	FGUI:GTextField_setText(self._ui.mapName_Text, SL:GetValue("MAP_NAME", self._mapId) or "")

	self._pointPlayer		= nil
	self:CreatePlayerPoint()
	self:RefreshRightList()
	self:RefreshPoints()
	self:UpdateFindPath()
	self:InitActorPoints()
end

-- 当灯光变化
function MiniMapPanel:OnChangeLight()
	if not self._isCurMap then
		return
	end
	FGUI:GLoader_setUrl(self._map_loader, SL:GetValue("MINIMAP_FILE", self._mapId))
end

function MiniMapPanel:OnMapChange()
	self._isCurMap = SL:GetValue("MAP_ID") == self._mapId
	self:CreatePlayerPoint()
	self:OnChangeLight()
	self:UpdateFindPath()
end

-- BEGIN 右列表 =====================================================
-- 刷新右边的列表
function MiniMapPanel:RefreshRightList()
	self:OnClickMonsterType()
end

-- 设置右边列表类型
function MiniMapPanel:SetRightListType(type)
	self._rightListType = type
	if self._rightListType == RIGHT_TYPE_NPC then
		FGUI:GButton_setSelected(self._ui.btn_monster, false)
		FGUI:GButton_setSelected(self._ui.btn_npc, true)
	elseif self._rightListType == RIGHT_TYPE_MONSTER then
		FGUI:GButton_setSelected(self._ui.btn_monster, true)
		FGUI:GButton_setSelected(self._ui.btn_npc, false)
	end
end

-- 获取右边列表类型
function MiniMapPanel:GetRightListType()
	return self._rightListType
end

-- 选择怪物
function MiniMapPanel:OnClickMonsterType()
	self:SetRightListType(RIGHT_TYPE_MONSTER)
	local list = SL:GetValue("MON_GEN_LIST", self._mapId)
	local monList = {}
	for _, v in pairs(list) do
		if v.DisplayControl == 1 then
			insert(monList, v)
		end
	end
	table.sort(monList, function(a, b)
		return SL:GetValue("MONSTER_LEVEL", a.MonId) < SL:GetValue("MONSTER_LEVEL", b.MonId)
	end)
	self._tempDatas = monList

	FGUI:GList_setNumItems(self._ui.list_right, 0)
	FGUI:GList_setNumItems(self._ui.list_right, #self._tempDatas)
end

-- 选择Npc
function MiniMapPanel:OnClickNpcType()
	self:SetRightListType(RIGHT_TYPE_NPC)
	local list = SL:GetValue("NPC_LIST", self._mapId)
	local npcList = {}
	for _, v in pairs(list) do
		if v and SL:GetValue("NPC_IS_MATCH_CONDITION", v.ID) and v.MapRightName then
			insert(npcList, v)
		end
	end
	self._tempDatas = npcList 

	FGUI:GList_setNumItems(self._ui.list_right, 0)
	FGUI:GList_setNumItems(self._ui.list_right, #self._tempDatas)
end

-- 刷新右Item
function MiniMapPanel:RightItemRender(idx, item)
	local info = self._tempDatas[idx + 1]
	if self._rightListType == RIGHT_TYPE_NPC then
		self:RightItemRender_NPC(info, item, idx)
	elseif self._rightListType == RIGHT_TYPE_MONSTER then
		self:RightItemRender_Monster(info, item, idx)
	end
end

-- 刷新右Item的NPC列表
function MiniMapPanel:RightItemRender_NPC(info, item, idx)
	local scrollText = FGUI:GetChild(item, "title")
	FGUI:GTextField_setText(scrollText, info.MapRightName, 1, 0)
	FGUI:GTextField_setColor(scrollText,"#00FF00")
	local level_text = FGUI:GetChild(item, "level")
	FGUI:GTextField_setText(level_text, "")
	local btn_transmit = FGUI:GetChild(item, "btn_transmit")
	FGUI:SetIntData(btn_transmit, idx)
	FGUI:addOnClickEvent(btn_transmit, self.handler_clickTransmitBtn)
end

-- 刷新右Item的Monster列表
function MiniMapPanel:RightItemRender_Monster(info, item, idx)
	local title = FGUI:GetChild(item, "title")
	FGUI:GTextField_setText(title, SL:GetValue("MONSTER_BOSS_NAME", info.MonId))
	FGUI:GButton_setTitle(item, SL:GetValue("MONSTER_BOSS_NAME", info.MonId))
	if SL:GetValue("MONSTER_BOSS_SIGN", info.MonId) > 0 then
		FGUI:GTextField_setColor(title, "#FF0000")
	else
		FGUI:GTextField_setColor(title, "#FFFFFF")
	end
	local level_text = FGUI:GetChild(item, "level")
	FGUI:GTextField_setText(level_text, string.format("Lv.%s", tostring(SL:GetValue("MONSTER_LEVEL", info.MonId))))
	local btn_transmit = FGUI:GetChild(item, "btn_transmit")
	FGUI:SetIntData(btn_transmit, idx)
	FGUI:addOnClickEvent(btn_transmit, self.handler_clickTransmitBtn)
end

function MiniMapPanel:OnClickTransmitBtn(context)
	FGUI:EventContext_stopPropagation(context)

	local idx = FGUI:GetIntData(context.sender)
	local info = self._tempDatas[idx + 1]
	ssrMessage:sendmsgEx("moveItem", "move",{{self._mapId, info.X, info.Y}})
	if self._rightListType == RIGHT_TYPE_NPC then
		if (not info.X) or (not info.Y) then return end
		SL:RequestUseTransfer(self._mapId, info.X, info.Y)
	elseif self._rightListType == RIGHT_TYPE_MONSTER then
		if (not info.X) or (not info.Y) then return end
		SL:RequestUseTransfer(self._mapId, info.X, info.Y)
	end
end

function MiniMapPanel:OnClickRightItem(context)
	if self._rightListType == RIGHT_TYPE_NPC then
		self:OnClickNpcItem(context)
	elseif self._rightListType == RIGHT_TYPE_MONSTER then
		self:OnClickMonsterItem(context)
	end
end

-- 点击NPC列表Item
function MiniMapPanel:OnClickNpcItem(context)
	local childIdx = FGUI:GetChildIndex(context.sender, context.data)
	local idx = FGUI:GList_childIndexToItemIndex(context.sender, childIdx) + 1
	local data = self._tempDatas[idx]
	if (not data.X) or (not data.Y) then return end
	
	SL:SetValue("BATTLE_AUTO_MOVE_BEGIN", self._mapId, data.X, data.Y,{type = SLDefine.AUTO_TARGET_TYPE.FIND_NPC})  
end

-- 点击Monster列表Item
function MiniMapPanel:OnClickMonsterItem(context)
	local childIdx = FGUI:GetChildIndex(context.sender, context.data)
	local idx = FGUI:GList_childIndexToItemIndex(context.sender, childIdx) + 1
	local data = self._tempDatas[idx]
	if (not data.X) or (not data.Y) then return end
	SL:SetValue("BATTLE_AUTO_MOVE_BEGIN", self._mapId, data.X, data.Y, {type = SLDefine.AUTO_TARGET_TYPE.FIND_MONSTER})
end
-- END 右列表 =====================================================

-- BEGIN Point =====================================================
function MiniMapPanel:RefreshPoints()
	local createLinkPoint = function(posStr, config)
		if not posStr then return end
		local posInfo = string.split(posStr, "#")
		local x = posInfo[1] and tonumber(posInfo[1]) or nil
		local y = posInfo[2] and tonumber(posInfo[2]) or nil
		self:CreatePoint(POINT_TYPE_LINK, config, x, y)
	end

	local from_list = SL:GetValue("LINK_POINTS_MAPFROM", self._mapId)
	for _, v in pairs(from_list) do
		v.__type = LINK_TYPE_FROM
		createLinkPoint(v.PosiFrom, v)
	end

	local to_list = SL:GetValue("LINK_POINTS_MAPTO", self._mapId)
	for _, v in pairs(to_list) do
		v.__type = LINK_TYPE_TO
		createLinkPoint(v.PosiTo, v)
	end

	local npc_list = SL:GetValue("NPC_LIST", self._mapId)
	for _, v in ipairs(npc_list) do
		if v and SL:GetValue("NPC_IS_MATCH_CONDITION", v.ID) then
			self:CreatePoint(POINT_TYPE_NPC, v, v.X, v.Y)
		end
	end

	local monster_list = SL:GetValue("MON_GEN_LIST", self._mapId)
	for _, v in ipairs(monster_list) do
		if v and v.DisplayControl == 1 then
			local type = POINT_TYPE_MONSTER
			if SL:GetValue("MONSTER_BOSS_SIGN", v.MonId) == 3 then
				type = POINT_TYPE_BOSS
			end
			self:CreatePoint(type, v, v.X, v.Y)
		end
	end
end

function MiniMapPanel:CreatePoint(type, config, x, y)
    if (not x) or (not y) then
        return
    end

    local handler = self._pointHandlers[type]
    if not handler then
        return
    end
    local posX, posY = self:CalcMiniMapPos(x, y)
    local icon = self:CreatePointElement(self._node_point, handler._icon, posX, posY, type)
    local name_bg = self:CreatePointElement(self._node_info, handler._name_bg, posX, posY, type)
    local name = self:CreatePointElement(self._node_info, handler._name, posX, posY, type)
    handler._processor(config, icon, name_bg, name)
end

function MiniMapPanel:CreatePointElement(parent, name, x, y, type)
    if not name then return end
	
	-- 
	local element = nil
	local queue = self._elementPool[name]
	if queue and queue:size() > 0 then
		element = queue:pop()
		FGUI:setVisible(element, true)
	else
		element = FGUI:CreateObject(parent, self._packageName, name)
	end
	local list = self._elements[name]
	if not list then
		list = {}
		self._elements[name] = list
	end
	insert(list, element)

	local list = self._elementsForType[type]
	if not list then
		list = {}
		self._elementsForType[type] = list
	end
	insert(list, element)

    FGUI:setPosition(element, x, y)
    FGUI:addRelation(element, self._map_loader, "Center_Center", true)
    FGUI:addRelation(element, self._map_loader, "Middle_Middle", true)
	parent:SetChildIndex(element, FGUI:GetChildCount(parent)-1)
	FGUI:setVisible(element, self._pointFilter[type])
    return element
end


-- 刷新传送点Point
function MiniMapPanel:PointProcessor_Link(config, icon, name_bg, name)
	FGUI:GLabel_setIcon(icon, "ui://"..self._packageName.."/point_link")
	local str = ""
	if config.__type == LINK_TYPE_FROM then
		str = config.NameTo
	elseif config.__type == LINK_TYPE_TO then
		str = config.NameFrom
	end
	FGUI:GLabel_setTitle(name, str)
	self:AotoSetPointNameBgWidth(name, name_bg)
end

-- 刷新NPC Point
function MiniMapPanel:PointProcessor_Npc(config, icon, name_bg, name)
	FGUI:GLabel_setIcon(icon, "ui://"..self._packageName.."/point_npc")
	local emptyName = config.NameScene == nil or string.len(config.NameScene) == 0
	if emptyName then
		if name_bg then
			FGUI:setVisible(name_bg, false)
		end
		if name then
			FGUI:setVisible(name, false)
		end
	else
		FGUI:GLabel_setTitle(name, config.NameScene)
		self:AotoSetPointNameBgWidth(name, name_bg)
	end
end

-- 刷新怪物 Point
function MiniMapPanel:PointProcessor_Monster(config, icon, name_bg, name)
	FGUI:GLabel_setIcon(icon, "ui://"..self._packageName.."/point_monster")
	local namestr = SL:GetValue("MONSTER_BOSS_NAME", config.MonId)
	local lv = SL:GetValue("MONSTER_LEVEL", config.MonId)
	FGUI:GLabel_setTitle(name, string.format("Lv.%s%s",tostring(lv), namestr))
	self:AotoSetPointNameBgWidth(name, name_bg)
	local color
	local bossSign = SL:GetValue("MONSTER_BOSS_SIGN", config.MonId)
	local bossLevel = SL:GetValue("MONSTER_LEVEL", config.MonId) or 0
	local playerLevel = SL:GetValue("LEVEL")
	if bossSign and bossSign > 0 then
		color = "#FF0000"
	elseif bossLevel > playerLevel  then
		color = "#FF0000"
	elseif bossLevel < playerLevel then
		color = "#00FF00"
	else
		color = "#FFFFFF"
	end
	FGUI:GLabel_setTitleColor(name, color)
end

-- 刷新怪物 Point
function MiniMapPanel:PointProcessor_Boss(config, icon, name_bg, name)
	FGUI:GLabel_setIcon(icon, "ui://"..self._packageName.."/point_boss1")
	local namestr = SL:GetValue("MONSTER_BOSS_NAME", config.MonId)
	local lv = SL:GetValue("MONSTER_LEVEL", config.MonId)
	FGUI:GLabel_setTitle(name, string.format("Lv.%s%s",tostring(lv), namestr))
	self:AotoSetPointNameBgWidth(name, name_bg)
	local color
	local bossSign = SL:GetValue("MONSTER_BOSS_SIGN", config.MonId)
	local bossLevel = SL:GetValue("MONSTER_LEVEL", config.MonId) or 0
	local playerLevel = SL:GetValue("LEVEL")
	if bossSign and bossSign > 0 then
		color = "#FF0000"
	elseif bossLevel > playerLevel  then
		color = "#FF0000"
	elseif bossLevel < playerLevel then
		color = "#00FF00"
	else
		color = "#FFFFFF"
	end
	FGUI:GLabel_setTitleColor(name, color)
end

-- 初始化Boss 复活倒计时
function MiniMapPanel:PointProcressorBossInitTimeDown(info)
	local color
	local bossSign = SL:GetValue("MONSTER_BOSS_SIGN", info.config.MonId)
	local bossLevel = SL:GetValue("MONSTER_LEVEL", info.config.MonId) or 0
	local playerLevel = SL:GetValue("LEVEL")
	if bossSign and bossSign > 0 then
		color = "#FF0000"
	elseif bossLevel > playerLevel  then
		color = "#FF0000"
	elseif bossLevel < playerLevel then
		color = "#00FF00"
	else
		color = "#FFFFFF"
	end
	FGUI:GLabel_setTitleColor(info.point, color)
	local time = info.endTime - SL:GetValue("SERVER_TIME")
	FGUI:GLabel_setTitle(info.point, self:FormatTime(time))
end

-- 刷新Boss复活倒计时
function MiniMapPanel:PointProcressorBossUpdateTimeDown()
	for i = #self._timeDownInfos, 1, -1 do
		local info = self._timeDownInfos[i]	
		local time = info.endTime - SL:GetValue("SERVER_TIME")
		if time > 0 then
			FGUI:GLabel_setTitle(info.point, self:FormatTime(time))
		else
			FGUI:setVisible(info.point, false)
			table.remove(self._timeDownInfos,i)
		end
	end
end

function MiniMapPanel:AotoSetPointNameBgWidth(name, name_bg)
	local nameText = FGUI:GLabel_getTextField(name)
	local w = FGUI:getWidth(nameText) + 30
	w = math.max(w, 74)
	if name_bg then
		FGUI:setWidth(name_bg, w)
	end
end

-- 格式化时间
function MiniMapPanel:FormatTime(time)
    if not time or time < 0 then
        return "00:00:00"
    end
    local totalSeconds = math.floor(time)
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = math.floor(totalSeconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- 当怪物信息更新
function MiniMapPanel:OnUpdateMonsterInfo()
	local monster_list = SL:GetValue("MON_GEN_LIST", self._mapId)
	for _, v in ipairs(monster_list) do
		if v and v.DisplayControl == 1 then
			local data = SL:GetValue("MINIMAP_MONSTER_DATA_FOR_ID",v.ID, v.MonId)
			if data and data.time > 0 then
				local type = POINT_TYPE_MONSTER
				if SL:GetValue("MONSTER_BOSS_SIGN", v.MonId) == 3 then
					type = POINT_TYPE_BOSS
				end
				local info = {}
				info.endTime = data.endTime
				info.data = data
				info.config = v
				local posX, posY = self:CalcMiniMapPos(v.X, v.Y)
				local point = self:CreatePointElement(self._node_info, "map_point_timedown_boss", posX, posY, type)
				info.point = point
				self:PointProcressorBossInitTimeDown(info)
				table.insert(self._timeDownInfos, info)
			end
		end
	end
	if self._timeDownSign then
		SL:UnSchedule(self._timeDownSign)
		self._timeDownSign = nil
	end
	if next(self._timeDownInfos) then
		self._timeDownSign = SL:Schedule(self.handler_updateTimeDown, 1)
	end
end

function MiniMapPanel:OnSwitchBossFilter(context)
	local enable = FGUI:GButton_getSelected(context.sender)
	self._pointFilter[POINT_TYPE_BOSS] = enable
	self:RefreshPointsVisiable(POINT_TYPE_BOSS)
end

function MiniMapPanel:OnSwitchMonsterFilter(context)
	local enable = FGUI:GButton_getSelected(context.sender)
	self._pointFilter[POINT_TYPE_MONSTER] = enable
	self:RefreshPointsVisiable(POINT_TYPE_MONSTER)
end

function MiniMapPanel:OnSwitchLinkFilter(context)
	local enable = FGUI:GButton_getSelected(context.sender)
	self._pointFilter[POINT_TYPE_LINK] = enable
	self:RefreshPointsVisiable(POINT_TYPE_LINK)
end

function MiniMapPanel:RefreshPointsVisiable(type)
	local enable = self._pointFilter[type]
	local list = self._elementsForType[type]
	if not list then
		return
	end
	for _, element in pairs(list) do
		FGUI:setVisible(element, enable)
	end
end

function MiniMapPanel:CalcMiniMapPos(actorX, actorZ)
    local posX = (actorX - self._offsetX) / self._mapParamX * self._mapSizeW
	local posY = (1 - (actorZ - self._offsetY) / self._mapParamY) * self._mapSizeH
    return posX, posY
end

function MiniMapPanel:RecycleElement()
	for url, list in pairs(self._elements) do
		local queue = self._elementPool[url]
		if not queue then
			queue = Queue.new()
			self._elementPool[url] = queue
		end
		for _, element in ipairs(list) do
			FGUI:setVisible(element)
			queue:push(element)
		end
		table.clear(list)
	end
end

function MiniMapPanel:RecycleSingleElement(element, url)
	local queue = self._elementPool[url]
	if not queue then
		queue = Queue.new()
		self._elementPool[url] = queue
	end
	local list = self._elements[url]
	for i, v in ipairs(list) do
		if v == element then
			FGUI:setVisible(element)
			queue:push(element)
			break
		end
	end
end
-- END Point =====================================================

-- BEGIN Map UI =====================================================
function MiniMapPanel:OnClickMap(context)
	local tX, tY = FGUI:getTouchPosition(context)
	local x, y = FGUI:WorldToLocal(self._ui.mapComponent, tX, tY)
	
	local actorX, actorZ = self:GetActorPosition(x, y)
	SL:SetValue("BATTLE_AUTO_MOVE_BEGIN", self._mapId, actorX, actorZ, nil, SLDefine.AUTO_MOVE_TO_DEST_FROM.MINIMAP)
end

function MiniMapPanel:GetActorPosition(posX, posY)
	local actorX = posX / self._mapSizeW * self._mapParamX + self._offsetX
	local actorZ = (1 - posY / self._mapSizeH) * self._mapParamY + self._offsetY
    return actorX, actorZ
end
-- END Map UI =====================================================

-- BEGIN Player=====================================================
function MiniMapPanel:CreatePlayerPoint()
	if not self._isCurMap then
		if self._pointPlayer then
			FGUI:setVisible(self._pointPlayer, false)	
		end
		return
	end
	
	local x, z = SL:GetValue("MAP_PLAYER_POS")
	local posX, posY = self:CalcMiniMapPos(x, z)
	if not self._pointPlayer then
		self._pointPlayer = self:CreatePointElement(self._node_player, "map_point_player", posX, posY, POINT_TYPE_PLAYER)
	end
	local dir = SL:GetValue("ROTATION")
	FGUI:setVisible(self._pointPlayer, true)
	FGUI:setRotation(self._pointPlayer, dir)
	self:UpdatePlayerPos()
end


function MiniMapPanel:OnPlayerAction(actorID, act)
	if not self._isCurMap then
		return
	end
    if SL:CheckIsMoveAction(act) then
        self:UpdatePlayerPos()
    end
end

function MiniMapPanel:UpdatePlayerPos()
	if not self._isCurMap then
		return
	end
	local x, z = SL:GetValue("MAP_PLAYER_POS")
	local posX, posY = self:CalcMiniMapPos(x, z)
	FGUI:setPosition(self._pointPlayer, posX, posY)
	FGUI:InvalidateBatchingState(self._pointPlayer)
end

function MiniMapPanel:OnPlayerRotate(dir)
	if not self._isCurMap then
		return
	end
	FGUI:setRotation(self._pointPlayer, dir)
end

-- END Player=====================================================

-- BEGIN 队友=====================================================
function MiniMapPanel:InitActorPoints()
	local playerList, nPlayer = global.playerManager:FindPlayerIDInCurrViewField()
    for i = 1, nPlayer do
        self:AddActorPoint(playerList[i])
    end
end
function MiniMapPanel:OnActorInOfView(actorId)
    if SL:GetValue("ACTOR_IS_MAINPLAYER", actorId) then
        self:UpdatePlayerPos()
    else
        self:AddActorPoint(actorId)
    end
end

function MiniMapPanel:OnActorOutOfView(actorId)
    self:RmvActorPoint(actorId)
end

function MiniMapPanel:OnActorDie(actorId)
    self:RmvActorPoint(actorId)
end

function MiniMapPanel:OnActorRevive(actorId)
    self:AddActorPoint(actorId)
end

function MiniMapPanel:OnActorAction(actorID, act)
    if SL:CheckIsMoveAction(act) then
        self:UpdateActorPoint(actorID)
    end
end

function MiniMapPanel:AddActorPoint(actorId)
	-- 死亡
    if SL:GetValue("ACTOR_IS_DIE", actorId) then
        self:RmvActorPoint(actorId)
		return
    end

	if SL:CheckIsMainPlayerByID(actorId) then
        self:UpdatePlayerPos()
        return
    end

	-- 自己的宝宝不显示
    if SL:CheckIsMainPlayerByID(SL:GetValue("ACTOR_MASTER_ID", actorId)) then
        return
    end

	-- 如果不是友方
	if not SL:GetValue("TEAM_IS_MEMBER", actorId) then
		return
	end

	local handler = self._actorPoints[actorId]
	if handler then
		self:UpdateActorPoint(actorId)
		return
	end
	
    local info = self._pointHandlers[POINT_TYPE_FRIEND]
    if not info then
        return
    end
	local x = SL:GetValue("ACTOR_MAP_X", actorId)
    local y = SL:GetValue("ACTOR_MAP_Z", actorId)
    local posX, posY = self:CalcMiniMapPos(x, y)
    local icon = self:CreatePointElement(self._node_point, info._icon, posX, posY, POINT_TYPE_FRIEND)
    local name = self:CreatePointElement(self._node_info, info._name, posX, posY, POINT_TYPE_FRIEND)
	FGUI:GLabel_setIcon(icon, "ui://"..self._packageName.."/point_npc")
	local actorName = SL:GetValue("ACTOR_NAME", actorId)
	actorName = FGUIFunction:GetServerName(actorName)
	FGUI:GLabel_setTitle(name, actorName)
	-- self:AotoSetPointNameBgWidth(name, name_bg)
	handler = {icon = icon, name = name, info = info}
	self._actorPoints[actorId] = handler
end

function MiniMapPanel:UpdateActorPoint(actorId)
	local handler = self._actorPoints[actorId]
	if not handler then
		return
	end
	local x = SL:GetValue("ACTOR_MAP_X", actorId)
    local y = SL:GetValue("ACTOR_MAP_Z", actorId)
	local posX, posY = self:CalcMiniMapPos(x, y)
	FGUI:setPosition(handler.icon, posX, posY)
	FGUI:setPosition(handler.name, posX, posY)
end

function MiniMapPanel:RmvActorPoint(actorId)
	local handler = self._actorPoints[actorId]
	if not handler then
		return
	end
	self:RecycleSingleElement(handler.icon, handler.info._icon)
	self:RecycleSingleElement(handler.name, handler.info._name)
	self._actorPoints[actorId] = nil
end
-- END 队友=====================================================
----------------------------------------寻路-------------------------------------
function MiniMapPanel:UpdateFindPath()
	if not self._isCurMap then
		self:ClearPath()
		return
	end
	local size = SL:GetValue("MAP_PATH_SIZE")
	if size >= 1 then
		self:FindPathBegin()
	else
		self:FindPathEnd()
	end
end

function MiniMapPanel:FindPathBegin()
	if not self._isCurMap then
		self:ClearPath()
		return
	end
	-- local moveType = SL:GetValue("MAP_CURRENT_MOVE_TYPE")
	-- if moveType == SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_AUTOMOVE or 
    --     moveType == SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_AFK or
    --     moveType == SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_OTHER then
		if self.scheduleId == nil then
			self.scheduleId = SL:Schedule(function()
				self:ShowFindPathLine()
			end, 0.2)
		end
	-- end
end

function MiniMapPanel:ShowFindPathLine()
	if not self._isCurMap then
		self:ClearPath()
		return
	end
	local points = SL:GetValue("MAP_PATH_POINTS")
	local size = SL:GetValue("MAP_PATH_SIZE")
    local playerX, playerZ = SL:GetValue("MAP_PLAYER_POS")
    local pathIdx = SL:GetValue("MAP_CURRENT_PATH_INDEX")
	if size >= 1 then
		local t = {}
        local len = 0
		local x = 0
		local y = 0
		for i = size, pathIdx - 1, -1 do
			local p = points[i]
			if p then
				x, y = self:CalcMiniMapPos(p.x, p.z)
				t[len + 1] = x
                t[len + 2] = y
                len = len + 2
			end
		end
		local x, y = self:CalcMiniMapPos(playerX, playerZ)
        t[len + 1] = x
        t[len + 2] = y
        len = len + 2
		FGUI:GComponent_DrawLine(self.Graph_line, "ui://"..self._packageName.."/point_npc", 8, t)

		if SL:GetValue("GAME_DATA", "PathfindingCoordinates") == 1 then
			local point = points[size]
			if point then
				FGUI:GLabel_setTitle(self._targetPoint, string.format("(%0.0f,%0.0f)", point.x, point.z))
				local x, y = self:CalcMiniMapPos(point.x, point.z)
				FGUI:setPosition(self._targetPoint, x, y)
				FGUI:setVisible(self._targetPoint, true)
			end
		end
	end

end

function MiniMapPanel:FindPathEnd()
	local size = SL:GetValue("MAP_PATH_SIZE")
	if size <= 0 then
        FGUI:GComponent_ClearLine(self.Graph_line)
	end
	if self.scheduleId then
		SL:UnSchedule(self.scheduleId)
		self.scheduleId = nil
	end
	FGUI:setVisible(self._targetPoint, false)
end

function MiniMapPanel:ClearPath()
	FGUI:GComponent_ClearLine(self.Graph_line)
	if self.scheduleId then
		SL:UnSchedule(self.scheduleId)
		self.scheduleId = nil
	end
	FGUI:setVisible(self._targetPoint, false)
end

---------------------------------------------------

function MiniMapPanel:OnReceiveUseTransfer()
	-- print("服务器收到 使用传送符")
	SL:SetValue("BATTLE_AUTO_MOVE_END")
	SL:SetValue("BATTLE_AFK_END")
	
	-- 检查当前任务的task_turntype是否为1，如果是则开启自动挂机
	local taskDeliverData = require("FGUILayout/A_TaskDeliver/taskDeliverData")
	local taskID = taskDeliverData:GetTaskID()
	if taskID then
		local Task_cfg = require("game_config/cfgcsv/Task")
		local taskTurnType = Task_cfg[taskID]['task_turntype']
		if taskTurnType and taskTurnType == 1 then
			SL:SetValue("BATTLE_AFK_BEGIN")
		end
	end
end
return MiniMapPanel