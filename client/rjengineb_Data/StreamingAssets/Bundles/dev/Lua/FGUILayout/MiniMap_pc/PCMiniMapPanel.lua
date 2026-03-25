local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCMiniMapPanel = class("PCMiniMapPanel", BaseFGUILayout)

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

function PCMiniMapPanel:Create()
	self._ui				= FGUI:ui_delegate(self.component)
	FGUIFunction:setWindowDrag(self.component, self._ui.bg)
	self._packageName = "MiniMap_pc"
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

function PCMiniMapPanel:Enter()
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

function PCMiniMapPanel:Exit()
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

function PCMiniMapPanel:Destroy()
	self._tracePoint:Destroy()
end

function PCMiniMapPanel:OnClose()
	self.super.Close(self)
end

function PCMiniMapPanel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_MINIMAP_MONSTER, "PCMiniMapPanel", handler(self, self.OnUpdateMonsterInfo))

	SL:RegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "PCMiniMapPanel", handler(self, self.OnMapChange))
	SL:RegisterLUAEvent(LUA_EVENT_CHANGE_LIGHT, "PCMiniMapPanel", handler(self, self.OnChangeLight))

	SL:RegisterLUAEvent(LUA_EVENT_FIND_PATH_BEGAIN, "PCMiniMapPanel", handler(self, self.FindPathBegin))
    SL:RegisterLUAEvent(LUA_EVENT_FIND_PATH_EMD, "PCMiniMapPanel", handler(self, self.FindPathEnd))

	SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_PROCESS, "PCMiniMapPanel", handler(self, self.OnPlayerAction))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_COMPLETE, "PCMiniMapPanel", handler(self, self.OnPlayerAction))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_DIRECTION_CHANGE, "PCMiniMapPanel", handler(self, self.OnPlayerRotate))

	SL:RegisterLUAEvent(LUA_EVENT_ACTOR_IN_OF_VIEW, "PCMiniMapPanel", handler(self, self.OnActorInOfView))
    SL:RegisterLUAEvent(LUA_EVENT_ACTOR_OUT_OF_VIEW, "PCMiniMapPanel", handler(self, self.OnActorOutOfView))
    SL:RegisterLUAEvent(LUA_EVENT_NET_PLAYER_DIE, "PCMiniMapPanel", handler(self, self.OnActorDie))
    SL:RegisterLUAEvent(LUA_EVENT_MONSTER_DIE, "PCMiniMapPanel", handler(self, self.OnActorDie))
    SL:RegisterLUAEvent(LUA_EVENT_NET_PLAYER_REVIVE, "PCMiniMapPanel", handler(self, self.OnActorRevive))
    SL:RegisterLUAEvent(LUA_EVENT_MONSTER_REVIVE, "PCMiniMapPanel", handler(self, self.OnActorRevive))
	SL:RegisterLUAEvent(LUA_EVENT_NET_PLAYER_ACTION_COMPLETE, "PCMiniMapPanel", handler(self, self.OnActorAction))
	
	SL:RegisterLUAEvent(LUA_EVENT_USE_TRANSMIT, "PCMiniMapPanel", handler(self, self.OnReceiveUseTransfer))
end

function PCMiniMapPanel:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_MINIMAP_MONSTER, "PCMiniMapPanel")

	SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "PCMiniMapPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_LIGHT, "PCMiniMapPanel")

	SL:UnRegisterLUAEvent(LUA_EVENT_FIND_PATH_BEGAIN, "PCMiniMapPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_FIND_PATH_EMD, "PCMiniMapPanel")

	SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_PROCESS, "PCMiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_COMPLETE, "PCMiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_DIRECTION_CHANGE, "PCMiniMapPanel")

	SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_IN_OF_VIEW, "PCMiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_OUT_OF_VIEW, "PCMiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NET_PLAYER_DIE, "PCMiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_MONSTER_DIE, "PCMiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NET_PLAYER_REVIVE, "PCMiniMapPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_MONSTER_REVIVE, "PCMiniMapPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_NET_PLAYER_ACTION_COMPLETE, "PCMiniMapPanel")

	SL:UnRegisterLUAEvent(LUA_EVENT_USE_TRANSMIT, "PCMiniMapPanel")
end

function PCMiniMapPanel:InitData()
	-- 关闭按钮
	self.handler_clickCloseBtn				= handler(self, self.OnClose)
	self.handler_OnLoadMapFileSuccess		= handler(self, self.OnLoadMapFileSuccess)

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

	self._uiSizeW, self._uiSizeH = FGUI:getSize(self._ui.mapComponent)
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

function PCMiniMapPanel:InitEvent()
	FGUI:setOnClickEvent(self._ui.btn_close, self.handler_clickCloseBtn)

	FGUI:GList_itemRenderer(self._ui.list_left, self.handler_leftItemRender)
	FGUI:GList_addOnClickItemEvent(self._ui.list_left, self.handler_clickLinkPoint)

	FGUI:GList_itemRenderer(self._ui.list_right, self.handler_rightItemRender)
	FGUI:GList_addOnClickItemEvent(self._ui.list_right, self.handler_clickRightItem)

	FGUI:setOnClickEvent(self._ui.mapComponent, handler(self, self.OnClickMap))
	FGUI:setOnClickEvent(self._ui.btn_monster, handler(self, self.OnClickMonsterType))
	FGUI:setOnClickEvent(self._ui.btn_npc, handler(self, self.OnClickNpcType))
	FGUI:GButton_setOnChangedCallback(self._ui.tog_boss, handler(self, self.OnSwitchBossFilter))
	FGUI:GButton_setOnChangedCallback(self._ui.tog_monster, handler(self, self.OnSwitchMonsterFilter))
	FGUI:GButton_setOnChangedCallback(self._ui.tog_link, handler(self, self.OnSwitchLinkFilter))
	if  global.isEditor or (global.isWindows and global.isDebugBuild) then
		FGUI:setOnClickEvent(self._ui.btn_debug,function()
			FGUI:Open(self._packageName, "PCMiniMapDebugPanel", nil, FGUI_LAYER.NOTICE, {classPath = "FGUILayout/MiniMap_pc/PCMiniMapDebugPanel"})
		end)
	else
		FGUI:setVisible(self._ui.btn_debug, false)
	end
end
-- BEGIN 左列表 =====================================================
-- 刷新左边的列表
function PCMiniMapPanel:RefreshLeftList(now_mapId)
	self._mapId = now_mapId

	local allInfo = SL:GetValue("MAP_ALL_INFO_CONFIG")
	for _, v in pairs(allInfo) do
		if v.MapType == 1 then
			table.insert(self._mapCfg, v)
		end
	end
	table.sort(self._mapCfg, function(a, b)
		return (a.Sort or 0) < (b.Sort or 0)
	end)
	local selectIdx = 0
	local idx = 0
	for i, v in ipairs(self._mapCfg) do
		if v.MapId == now_mapId then
			selectIdx = i - 1
		end
	end
	FGUI:GList_setNumItems(self._ui.list_left, #self._mapCfg)
	if selectIdx then
		FGUI:GList_setSelectedIndex(self._ui.list_left, selectIdx)
	end
end

-- 刷新左Item
function PCMiniMapPanel:LeftItemRender(idx, item)
	local data = self._mapCfg[idx + 1]
	FGUI:GButton_setTitle(item, data.MapName)
end

-- 点击传送点item
function PCMiniMapPanel:OnClickMapItem(context)
	local childIdx = FGUI:GetChildIndex(self._ui.list_left, context.data)
	local index = FGUI:GList_childIndexToItemIndex(self._ui.list_left, childIdx)
	local data = self._mapCfg[index + 1]
	if self._mapId == data.MapId then
		return
	end
	self:ChangeMap(data.MapId)
end
-- END 左列表 =====================================================

-- 当地图变化
function PCMiniMapPanel:ChangeMap(mapId)
	self._mapId				= mapId
	self._isCurMap			= SL:GetValue("MAP_ID") == mapId
	local offset 			= SL:GetValue("MINIMAP_OFFSET", self._mapId)
	self._offsetX			= offset[1]
	self._offsetY			= offset[2]
	self._tempDatas			= nil
	self._timeDownInfos		= {}
	self._actorPoints		= {}
	self._elementsForType 	= {}
	if self._timeDownSign then
		SL:UnSchedule(self._timeDownSign)
		self._timeDownSign = nil
	end

	FGUI:GLoader_setUrl(self._map_loader, "")
	FGUI:GLoader_setUrl(self._map_loader, SL:GetValue("MINIMAP_FILE", self._mapId), self.handler_OnLoadMapFileSuccess)
	FGUI:GTextField_setText(self._ui.mapName_Text, SL:GetValue("MAP_NAME", self._mapId) or "")
end

-- 当灯光变化
function PCMiniMapPanel:OnChangeLight()
	if not self._isCurMap then
		return
	end
	FGUI:GLoader_setUrl(self._map_loader, "")
	FGUI:GLoader_setUrl(self._map_loader, SL:GetValue("MINIMAP_FILE", self._mapId), self.handler_OnLoadMapFileSuccess)
end

function PCMiniMapPanel:OnLoadMapFileSuccess()
	local img = FGUI:GLoader_getImage(self._map_loader)
	local texture = img.texture
	local width = texture.width
	local height = texture.height

	-- 计算宽高比
	local imageRatio = width / height
	local uiRatio = self._uiSizeW/self._uiSizeH

	if imageRatio > uiRatio then
		self._mapSizeW = self._uiSizeH*imageRatio
		self._mapSizeH = self._uiSizeH
	else
		self._mapSizeW = self._uiSizeW
		self._mapSizeH = self._uiSizeW/imageRatio
	end
	FGUI:setSize(self._map_loader, self._mapSizeW, self._mapSizeH)

    local mapCameraSize		= SL:GetValue("MINIMAP_CAMERA_SIZE", self._mapId)
    self._mapParamX			= self._mapSizeW / self._mapSizeH * mapCameraSize
    self._mapParamY			= mapCameraSize
	self._pointPlayer		= nil
	self:RecycleElement()
	-- 小地图怪物数据请求
	SL:RequestMiniMapMonsters(self._mapId)
	self:CreatePlayerPoint()
	self:RefreshRightList()
	self:RefreshPoints()
	self:UpdateFindPath()
	self:InitActorPoints()
	self._tracePoint:SetMapID(self._mapId)
end

function PCMiniMapPanel:OnMapChange()
	self._isCurMap = SL:GetValue("MAP_ID") == self._mapId
	self:CreatePlayerPoint()
	self:OnChangeLight()
	self:UpdateFindPath()
end

-- BEGIN 右列表 =====================================================
-- 刷新右边的列表
function PCMiniMapPanel:RefreshRightList()
	self:OnClickMonsterType()
end

-- 设置右边列表类型
function PCMiniMapPanel:SetRightListType(type)
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
function PCMiniMapPanel:GetRightListType()
	return self._rightListType
end

-- 选择怪物
function PCMiniMapPanel:OnClickMonsterType()
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
function PCMiniMapPanel:OnClickNpcType()
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
function PCMiniMapPanel:RightItemRender(idx, item)
	local info = self._tempDatas[idx + 1]
	if self._rightListType == RIGHT_TYPE_NPC then
		self:RightItemRender_NPC(info, item, idx)
	elseif self._rightListType == RIGHT_TYPE_MONSTER then
		self:RightItemRender_Monster(info, item, idx)
	end
end

-- 刷新右Item的NPC列表
function PCMiniMapPanel:RightItemRender_NPC(info, item, idx)
	local scrollText = FGUI:GetChild(item, "name")
	FGUIFunction:ScrollText_setString(scrollText, info.MapRightName, 1, 0)
	FGUI:GTextField_setColor(FGUI:GetChild(scrollText, "title"),"#00FF00")
	local level_text = FGUI:GetChild(item, "level")
	FGUI:GTextField_setText(level_text, "")
	local btn_transmit = FGUI:GetChild(item, "btn_transmit")
	FGUI:SetIntData(btn_transmit, idx)
	FGUI:addOnClickEvent(btn_transmit, self.handler_clickTransmitBtn)
end

-- 刷新右Item的Monster列表
function PCMiniMapPanel:RightItemRender_Monster(info, item, idx)
	local scrollText = FGUI:GetChild(item, "name")
	FGUIFunction:ScrollText_setString(scrollText, SL:GetValue("MONSTER_BOSS_NAME", info.MonId), 1, 0)
	FGUI:GButton_setTitle(item,SL:GetValue("MONSTER_BOSS_NAME", info.MonId))
	if SL:GetValue("MONSTER_BOSS_SIGN", info.MonId) > 0 then
		FGUI:GTextField_setColor(FGUI:GetChild(scrollText, "title"),"#FF0000")
	else
		FGUI:GTextField_setColor(FGUI:GetChild(scrollText, "title"),"#FFFFFF")
	end
	local level_text = FGUI:GetChild(item, "level")
	FGUI:GTextField_setText(level_text, string.format("Lv.%s",tostring(SL:GetValue("MONSTER_LEVEL", info.MonId))))
	local btn_transmit = FGUI:GetChild(item, "btn_transmit")
	FGUI:SetIntData(btn_transmit, idx)
	FGUI:addOnClickEvent(btn_transmit, self.handler_clickTransmitBtn)
end

function PCMiniMapPanel:OnClickTransmitBtn(context)
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

function PCMiniMapPanel:OnClickRightItem(context)
	if self._rightListType == RIGHT_TYPE_NPC then
		self:OnClickNpcItem(context)
	elseif self._rightListType == RIGHT_TYPE_MONSTER then
		self:OnClickMonsterItem(context)
	end
end

-- 点击NPC列表Item
function PCMiniMapPanel:OnClickNpcItem(context)
	local childIdx = FGUI:GetChildIndex(context.sender, context.data)
	local idx = FGUI:GList_childIndexToItemIndex(context.sender, childIdx) + 1
	local data = self._tempDatas[idx]
	if (not data.X) or (not data.Y) then return end
	
	SL:SetValue("BATTLE_AUTO_MOVE_BEGIN", self._mapId, data.X, data.Y,{type = SLDefine.AUTO_TARGET_TYPE.FIND_NPC})  
end

-- 点击Monster列表Item
function PCMiniMapPanel:OnClickMonsterItem(context)
	local childIdx = FGUI:GetChildIndex(context.sender, context.data)
	local idx = FGUI:GList_childIndexToItemIndex(context.sender, childIdx) + 1
	local data = self._tempDatas[idx]
	if (not data.X) or (not data.Y) then return end
	SL:SetValue("BATTLE_AUTO_MOVE_BEGIN", self._mapId, data.X, data.Y, {type = SLDefine.AUTO_TARGET_TYPE.FIND_MONSTER})
end
-- END 右列表 =====================================================

-- BEGIN Point =====================================================
function PCMiniMapPanel:RefreshPoints()
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

function PCMiniMapPanel:CreatePoint(type, config, x, y)
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

function PCMiniMapPanel:CreatePointElement(parent, name, x, y, type)
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

    self:RoundPointPosition(element, x, y)
    FGUI:addRelation(element, self._map_loader, "Center_Center", true)
    FGUI:addRelation(element, self._map_loader, "Middle_Middle", true)
	parent:SetChildIndex(element, FGUI:GetChildCount(parent)-1)
	FGUI:setVisible(element, self._pointFilter[type])
    return element
end


-- 刷新传送点Point
function PCMiniMapPanel:PointProcessor_Link(config, icon, name_bg, name)
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
function PCMiniMapPanel:PointProcessor_Npc(config, icon, name_bg, name)
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
function PCMiniMapPanel:PointProcessor_Monster(config, icon, name_bg, name)
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
function PCMiniMapPanel:PointProcessor_Boss(config, icon, name_bg, name)
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
function PCMiniMapPanel:PointProcressorBossInitTimeDown(info)
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
function PCMiniMapPanel:PointProcressorBossUpdateTimeDown()
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

function PCMiniMapPanel:AotoSetPointNameBgWidth(name, name_bg)
	local nameText = FGUI:GLabel_getTextField(name)
	local w = FGUI:getWidth(nameText) + 30
	w = math.max(w, 74)
	if name_bg then
		FGUI:setWidth(name_bg, w)
	end
end

-- 格式化时间
function PCMiniMapPanel:FormatTime(time)
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
function PCMiniMapPanel:OnUpdateMonsterInfo()
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

function PCMiniMapPanel:OnSwitchBossFilter(context)
	local enable = FGUI:GButton_getSelected(context.sender)
	self._pointFilter[POINT_TYPE_BOSS] = enable
	self:RefreshPointsVisiable(POINT_TYPE_BOSS)
end

function PCMiniMapPanel:OnSwitchMonsterFilter(context)
	local enable = FGUI:GButton_getSelected(context.sender)
	self._pointFilter[POINT_TYPE_MONSTER] = enable
	self:RefreshPointsVisiable(POINT_TYPE_MONSTER)
end

function PCMiniMapPanel:OnSwitchLinkFilter(context)
	local enable = FGUI:GButton_getSelected(context.sender)
	self._pointFilter[POINT_TYPE_LINK] = enable
	self:RefreshPointsVisiable(POINT_TYPE_LINK)
end

function PCMiniMapPanel:RefreshPointsVisiable(type)
	local enable = self._pointFilter[type]
	local list = self._elementsForType[type]
	if not list then
		return
	end
	for _, element in pairs(list) do
		FGUI:setVisible(element, enable)
	end
end

function PCMiniMapPanel:CalcMiniMapPos(actorX, actorZ)
    local posX = (actorX - self._offsetX) / self._mapParamX * self._mapSizeW
	local posY = (1 - (actorZ - self._offsetY) / self._mapParamY) * self._mapSizeH
    return posX, posY
end

function PCMiniMapPanel:RecycleElement()
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

function PCMiniMapPanel:RecycleSingleElement(element, url)
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
function PCMiniMapPanel:OnClickMap(context)
	local tX, tY = FGUI:getTouchPosition(context)
	local x, y = FGUI:WorldToLocal(self._ui.mapComponent, tX, tY)
	
	local scrollPane = FGUI:GetScrollPane(self._ui.mapComponent)
	x = x + FGUI:ScrollPane_getPosX(scrollPane)
	y = y + FGUI:ScrollPane_getPosY(scrollPane)

	local actorX, actorZ = self:GetActorPosition(x, y)
	SL:SetValue("BATTLE_AUTO_MOVE_BEGIN", self._mapId, actorX, actorZ, nil, SLDefine.AUTO_MOVE_TO_DEST_FROM.MINIMAP)
end

function PCMiniMapPanel:GetActorPosition(posX, posY)
	local actorX = posX / self._mapSizeW * self._mapParamX + self._offsetX
	local actorZ = (1 - posY / self._mapSizeH) * self._mapParamY + self._offsetY
    return actorX, actorZ
end
-- END Map UI =====================================================

-- BEGIN Player=====================================================
function PCMiniMapPanel:CreatePlayerPoint()
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


function PCMiniMapPanel:OnPlayerAction(actorID, act)
	if not self._isCurMap then
		return
	end
    if SL:CheckIsMoveAction(act) then
        self:UpdatePlayerPos()
    end
end

function PCMiniMapPanel:UpdatePlayerPos()
	if not self._isCurMap then
		return
	end
	local x, z = SL:GetValue("MAP_PLAYER_POS")
	local posX, posY = self:CalcMiniMapPos(x, z)
	FGUI:setPosition(self._pointPlayer, posX, posY)
	FGUI:InvalidateBatchingState(self._pointPlayer)
end

function PCMiniMapPanel:OnPlayerRotate(dir)
	if not self._isCurMap then
		return
	end
	FGUI:setRotation(self._pointPlayer, dir)
end

-- END Player=====================================================

-- BEGIN 队友=====================================================
function PCMiniMapPanel:InitActorPoints()
	local playerList, nPlayer = global.playerManager:FindPlayerIDInCurrViewField()
    for i = 1, nPlayer do
        self:AddActorPoint(playerList[i])
    end
end
function PCMiniMapPanel:OnActorInOfView(actorId)
    if SL:GetValue("ACTOR_IS_MAINPLAYER", actorId) then
        self:UpdatePlayerPos()
    else
        self:AddActorPoint(actorId)
    end
end

function PCMiniMapPanel:OnActorOutOfView(actorId)
    self:RmvActorPoint(actorId)
end

function PCMiniMapPanel:OnActorDie(actorId)
    self:RmvActorPoint(actorId)
end

function PCMiniMapPanel:OnActorRevive(actorId)
    self:AddActorPoint(actorId)
end

function PCMiniMapPanel:OnActorAction(actorID, act)
    if SL:CheckIsMoveAction(act) then
        self:UpdateActorPoint(actorID)
    end
end

function PCMiniMapPanel:AddActorPoint(actorId)
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
	handler = {icon = icon, name = name, info = info}
	self._actorPoints[actorId] = handler
end

function PCMiniMapPanel:UpdateActorPoint(actorId)
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

function PCMiniMapPanel:RmvActorPoint(actorId)
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
function PCMiniMapPanel:UpdateFindPath()
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

function PCMiniMapPanel:FindPathBegin()
	if not self._isCurMap then
		self:ClearPath()
		return
	end

	if self.scheduleId == nil then
		self.scheduleId = SL:Schedule(function()
			self:ShowFindPathLine()
		end, 0.2)
	end
end

function PCMiniMapPanel:ShowFindPathLine()
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

function PCMiniMapPanel:FindPathEnd()
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

function PCMiniMapPanel:ClearPath()
	FGUI:GComponent_ClearLine(self.Graph_line)
	if self.scheduleId then
		SL:UnSchedule(self.scheduleId)
		self.scheduleId = nil
	end
	FGUI:setVisible(self._targetPoint, false)
end

---------------------------------------------------

function PCMiniMapPanel:OnReceiveUseTransfer()
	print("服务器收到 使用传送符")
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

function PCMiniMapPanel:RoundPointPosition(element, x, y)
	local w, h = FGUI:getSize(element)
	x = x - w/2
	y = y - h/2
	x = math.round(x)
	y = math.round(y)
	FGUI:setPosition(element, x, y)
end
return PCMiniMapPanel