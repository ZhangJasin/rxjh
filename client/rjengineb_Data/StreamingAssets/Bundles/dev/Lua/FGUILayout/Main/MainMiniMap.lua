local BaseFGUILayout = requireFGUI("BaseFGUILayout")
-- local MainMiniMapEx = require("FGUILayer/Main/MainMiniMapEx")
local MainMiniMap = class("MainMiniMap", BaseFGUILayout)

local ACTOR_POS_Z_DEFAULT = 0
local ACTOR_POS_Z_MONSTER = 1
local ACTOR_POS_Z_PLAYER_N = 2
local ACTOR_POS_Z_PLAYER_G = 3
local ACTOR_POS_Z_PLAYER_E = 4

function MainMiniMap:Create()
	self._ui = FGUI:ui_delegate(FGUI:GetChild(self.component, "CompMIniMap"))
    self._mapUI = FGUI:ui_delegate(self._ui.Comp_Map)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Main)

    self._tracePoint = FGUIFunction:BindClass(self._mapUI.Node_tracePoint, "TracePoint/TracePointBox")
    self._tracePoint:Create("Main", "MiniMapTracePointItem", handler(self, self.CalcMiniMapPos), 15)

    self._actorPoints = {}
    self._actorCounts = {}
    self._actorPosIDs = {}

    self._npcPoints = {}
    self._linkPoints = {}
    self._teamPoints = {}

    self._limitSizeW, self._limitSizeH = FGUI:getSize(self._ui.Comp_Map)
    self._minimapW, self._minimapH = 0, 0
	self._sizeW = 1
	self._sizeH = 1
    self._offsetX = 0
    self._offsetY = 0
    self._mapAble = true
    self._loadSuccess = false

    self._myUid = SL:GetValue("USER_ID")

    self._updateActorMap = {}

    self:UpdateMiniMapSize()

    FGUI:setOnClickEvent(self._ui.Comp_Map, handler(self, self.OnOpenMiniMap))
    FGUI:setOnClickEvent(self._ui.Btn_route, handler(self, self.OnOpenMapRoute))
    FGUI:setOnClickEvent(self._ui.Btn_rank, handler(self, self.OnOpenRank))
    FGUI:setOnClickEvent(self._ui.Btn_setting, handler(self, self.OnOpenSetting))
end

function MainMiniMap:Enter()
	self:RegisterEvent()
    self:InitAdapt()

    self:UpdateMapData()

    self._tracePoint:Enter()
    self:UpdateMiniMap()
    self:UpdateMapState()
    self:UpdateMapName()
    self:UpdatePlayerPos()
    self:UpdateFindPath()
    self:UpdatePlayerRotate()
    self:UpdateMapRoute()

    self:InitActorPoints()
    self:UpdateMapPoints()
end

function MainMiniMap:Exit()
    self._tracePoint:Exit()
	self:RemoveEvent()
    table.clear(self._updateActorMap)
    if self._updateTimer then
        SL:UnSchedule(self._updateTimer)
        self._updateTimer = nil
    end
    if self.scheduleId then
		SL:UnSchedule(self.scheduleId)
		self.scheduleId = nil
	end
end

function MainMiniMap:Destroy()
    self._tracePoint:Destroy()
    self._ui = nil
    Pool.Destroy("Main", "MiniMapPoint", false)
end


--------------------------------------------------------

function MainMiniMap:UpdatePointsTimer()
    if self._mapAble then
        if not self._updateTimer then
            self._updateTimer = SL:Schedule(handler(self, self.UpdateActorPoints), 0.1)
        end
    else
        if self._updateTimer then
            SL:UnSchedule(self._updateTimer)
            self._updateTimer = nil
        end
    end
end

function MainMiniMap:UpdateMapData()
    local offset = SL:GetValue("MINIMAP_OFFSET")
	self._offsetX = offset[1]
	self._offsetY = offset[2]
    self._mapAble = SL:GetValue("MINIMAP_ABLE")
    FGUI:setVisible(self._ui.Comp_Map, self._mapAble)
    self:UpdatePointsTimer()
end

function MainMiniMap:InitAdapt()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local safeL, safeR, safeB, safeT = SL:GetValue("SCREEN_SAFE_AREA_RATIO")
    FGUI:setSize(self.component, screenW - safeR - safeL, screenH - safeB - safeT)
    FGUI:setPosition(self.component, safeL, safeT)
end

function MainMiniMap:UpdateMapState()
    local Text_state = self._ui.Text_state
    local route = SL:GetValue("MAP_ROUTE_IDX") or 1
    if SL:GetValue("MAP_IS_IN_SAFE_AREA") then
        FGUI:GTextField_setText(Text_state, string.format(GET_STRING(40040016), route))
        FGUI:GTextField_setColor(Text_state, "#00ff00")
    else
        FGUI:GTextField_setText(Text_state, string.format(GET_STRING(40040017), route))
        FGUI:GTextField_setColor(Text_state, "#ff0000")
    end
end

function MainMiniMap:UpdateMapName()
    FGUI:GTextField_setText(self._ui.Text_mapName, SL:GetValue("MAP_NAME") or "404")
end

function MainMiniMap:UpdateMapRoute()
    local lines = SL:GetValue("MAP_INFO_ROUTES", SL:GetValue("MAP_ID"))

    local ctl = FGUI:getController(self._ui.nativeUI, "showRoute")
    FGUI:Controller_setSelectedIndex(ctl, lines and 0 or 1)

    self:UpdateMapState()
end

function MainMiniMap:UpdatePlayerPos()
    local x, y = SL:GetValue("MAP_PLAYER_POS")
    local mapX = math.floor(x)
    local mapY = math.floor(y)
    FGUI:GTextField_setText(self._ui.Text_pos, string.format("%s:%s", mapX, mapY))
    self:UpdateMiniMapPos()
end

function MainMiniMap:UpdateMiniMap(x, y)
    if not self._mapAble then return end
    local path = SL:GetValue("MINIMAP_FILE")
	if self._currentPath == path then
		self:UpdateMiniMapPos(x, y)
		return
	end
		
    self._currentPath = path
    self._loadSuccess = false
    FGUI:GLoader_setUrl(self._mapUI.Loader_map,"")
    FGUI:GLoader_setUrl(self._mapUI.Loader_map, path, function(result)
        if not result then return end
        self._loadSuccess = true
        self:UpdateMiniMapSize()
    end)
end

function MainMiniMap:UpdateMiniMapSize()
    if self._loadSuccess then
        self._minimapW, self._minimapH = FGUI:getSize(self._mapUI.Loader_map)
        local mapCameraSize = SL:GetValue("MINIMAP_CAMERA_SIZE")
        self._sizeW = self._minimapW / self._minimapH * mapCameraSize
        self._sizeH = mapCameraSize
    else
        self._minimapW, self._minimapH = 1000, 1000
        self._sizeW, self._sizeH = 400, 400
    end
    --位置计算变化,重置下所有点的显示位置
    self:UpdateMiniMapPos()
    self:UpdateMapPoints()
    self:ClearActorPoints()
    self:UpdateActorPoints()
    self._tracePoint:UpdateMapPoints()
end


function MainMiniMap:UpdateMiniMapPos(x, y)
    if not self._mapAble then return false end
    local worldX, worldZ
	if x and y then
		worldX = x
		worldZ = y
	else
		worldX, worldZ = SL:GetValue("MAP_PLAYER_POS")
	end
    
    -- calc MiniMap
	local minimapX = -worldX / self._sizeW * self._minimapW
	local minimapY = -worldZ / self._sizeH * self._minimapH
    minimapX = minimapX + self._limitSizeW/2 + self._offsetX / self._sizeW * self._minimapW
    minimapY = -self._minimapH - minimapY + self._limitSizeH/2 - self._offsetY / self._sizeH * self._minimapH
    minimapX = math.max(minimapX, -(self._minimapW - self._limitSizeW))
    minimapX = math.min(minimapX, 0)
    minimapY = math.max(minimapY, -(self._minimapH - self._limitSizeH))
    minimapY = math.min(minimapY, 0)
    FGUI:setPosition(self._mapUI.Group_map, minimapX, minimapY)

    -- calc PlayerPos
    local targetX, targetY = self:CalcMainPlayerMiniMapPos(worldX, worldZ)
    FGUI:setPosition(self._mapUI.Image_player, targetX, targetY)

    self._tracePoint:UpdateSquareLimitSize()
end

----------------------------------Point-----------------------------------------


function MainMiniMap:InitActorPoints()
    if not self._mapAble then return end
    local playerList, nPlayer = SL:GetValue("FIND_IN_VIEW_PLAYER_LIST")
    for i = 1, nPlayer do
        self:UpdatePlayerPoint(playerList[i])
    end
    local monsterList, nMonster = SL:GetValue("FIND_IN_VIEW_MONSTER_LIST", true, true)
    for i = 1, nMonster do
        self:UpdateMonsterPoint(monsterList[i])
    end
end

function MainMiniMap:UpdatePlayerPoint(actorId)
    if self._myUid == actorId then
        self:UpdatePlayerPos()
        self:UpdateMiniMap()
        return
    end
    if SL:GetValue("TEAM_IS_MEMBER", actorId) then
        self:UpdateTeamMemberPoint(actorId)
        return
    end

    local styleIdx = 0
    local z
    local goodEvil = SL:GetValue("ACTOR_GOODEVILID", actorId)
    if goodEvil == SLDefine.GOODEVIL_TYPE.GOOD then
        z = ACTOR_POS_Z_PLAYER_G
        styleIdx = 5
    elseif goodEvil == SLDefine.GOODEVIL_TYPE.EVIL then
        z = ACTOR_POS_Z_PLAYER_E
        styleIdx = 6
    else
        z = ACTOR_POS_Z_PLAYER_N
        styleIdx = 7
    end

    local oldPosID = self._actorPosIDs[actorId]
    local newPosID = self:GetActorPointPosID(actorId, z)
    if oldPosID == newPosID then return end--位置未变动
    self:RmvActorPoint(actorId)
    if not self._mapAble then return end
    if newPosID ~= 0 then
        self:AddActorPoint(actorId, styleIdx, newPosID)
    end
end

function MainMiniMap:UpdateMonsterPoint(actorId)
    local config_id = SL:GetValue("ACTOR_TYPE_INDEX", actorId)
    if SL:GetValue("MONSTER_IS_HIDE_POINT", config_id) then return end

    local oldPosID = self._actorPosIDs[actorId]
    local newPosID = self:GetActorPointPosID(actorId, ACTOR_POS_Z_MONSTER)
    if oldPosID == newPosID then return end--位置未变动
    self:RmvActorPoint(actorId)
    
    -- 自己的宝宝不显示
    if SL:GetValue("ACTOR_MASTER_ID", actorId) == self._myUid then return end
    if not self._mapAble then return end

    if newPosID ~= 0 then
        self:AddActorPoint(actorId, 1, newPosID)
    end
end

function MainMiniMap:UpdateActorPoint(actorId)
    if SL:GetValue("ACTOR_IS_MONSTER", actorId) then
        self:UpdateMonsterPoint(actorId)
    elseif SL:GetValue("ACTOR_IS_PLAYER", actorId) then
        self:UpdatePlayerPoint(actorId)
    end
end

function MainMiniMap:ClearActorPoints()
    table.clear(self._actorCounts)
    table.clear(self._actorPosIDs)
    for posID, actorPoint in pairs(self._actorPoints) do
        Pool.Release("Main", "MiniMapPoint", actorPoint, false)
    end
    table.clear(self._actorPoints)
    for actorId, actorPoint in pairs(self._teamPoints) do
        Pool.Release("Main", "MiniMapPoint", actorPoint, false)
    end
    table.clear(self._teamPoints)
end

function MainMiniMap:AddActorPoint(actorId, styleIdx, posID)
    posID = posID or self:GetActorPointPosID(actorId)
    local actorPoint = self._actorPoints[posID]
    if actorPoint then
        local count = self._actorCounts[posID]
        if not count then
            self._actorCounts[posID] = 1
        else
            self._actorCounts[posID] = count + 1
        end
        self._actorPosIDs[actorId] = posID
    else
        actorPoint = Pool.Get("Main", "MiniMapPoint", self._mapUI.Node_actors)
        self._actorCounts[posID] = 1
        self._actorPosIDs[actorId] = posID
        self._actorPoints[posID] = actorPoint
        self:UpdateActorPointState(actorPoint, styleIdx)
        self:UpdateActorPointPosition(actorId, actorPoint)
    end
end

function MainMiniMap:RmvActorPoint(actorId)
    local posID = self._actorPosIDs[actorId]
    if not posID then return end
    self._actorPosIDs[actorId] = nil
    local count = self._actorCounts[posID]
    if not count then return end
    count = count - 1
    self._actorCounts[posID] = count
    if count > 0 then return end
    self._actorCounts[posID] = nil
    local actorPoint = self._actorPoints[posID]
    if not actorPoint then return end
	FGUI:setPosition(actorPoint, -5000, -5000)
    self._actorPoints[posID] = nil
    Pool.Release("Main", "MiniMapPoint", actorPoint, false)
end

function MainMiniMap:UpdateTeamMemberPoint(actorId)
    local actorPoint = self._teamPoints[actorId]
    if not actorPoint then
        self:AddTeamMemberPoint(actorId)
        return
    end
    self:UpdateActorPointPosition(actorId, actorPoint)
    self:UpdateActorRotate(actorId, actorPoint)
end

function MainMiniMap:AddTeamMemberPoint(actorId)
    local actorPoint = self._teamPoints[actorId]
    if actorPoint then return end
    actorPoint = Pool.Get("Main", "MiniMapPoint", self._mapUI.Node_team)
    self._teamPoints[actorId] = actorPoint
    self:UpdateActorPointState(actorPoint, 4)
    self:UpdateActorPointPosition(actorId, actorPoint)
    self:UpdateActorRotate(actorId, actorPoint)
end

function MainMiniMap:RmvTeamMemberPoint(actorId)
    local actorPoint = self._teamPoints[actorId]
    if not actorPoint then return end
    self._teamPoints[actorId] = nil
    FGUI:setRotation(actorPoint, 0)
    FGUI:setPosition(actorPoint, -5000, -5000)
    Pool.Release("Main", "MiniMapPoint", actorPoint, false)
end

function MainMiniMap:UpdateActorPointState(actorPoint, styleIdx)
    local controller = FGUI:getController(actorPoint, "style")
    FGUI:Controller_setSelectedIndex(controller, styleIdx)
end

function MainMiniMap:UpdateActorPointPosition(actorId, actorPoint)
    local mapX = SL:GetValue("ACTOR_MAP_X", actorId)
	local mapY = SL:GetValue("ACTOR_MAP_Z", actorId)
	local miniMapPosX, miniMapPosY = self:CalcMiniMapPos(mapX, mapY)
	FGUI:setPosition(actorPoint, miniMapPosX, miniMapPosY)
end

function MainMiniMap:GetActorPointPosID(actorId, z)
    local px = SL:GetValue("ACTOR_MAP_X", actorId)
    local py = SL:GetValue("ACTOR_MAP_Z", actorId)
    if px == 0 and py == 0 then return 0 end
    if not z then 
        if SL:GetValue("ACTOR_IS_PLAYER", actorId) then
            local goodEvil = SL:GetValue("ACTOR_GOODEVILID", actorId)
            if goodEvil == SLDefine.GOODEVIL_TYPE.GOOD then
                z = ACTOR_POS_Z_PLAYER_G
            elseif goodEvil == SLDefine.GOODEVIL_TYPE.EVIL then
                z = ACTOR_POS_Z_PLAYER_E
            else
                z = ACTOR_POS_Z_PLAYER_N
            end
        elseif SL:GetValue("ACTOR_IS_MONSTER", actorId) then
            z = ACTOR_POS_Z_MONSTER
        else
            z = ACTOR_POS_Z_DEFAULT
        end
    end
    local posID = z * 10000000000 + py * 65536 + px
    return posID
end

function MainMiniMap:UpdateMapPoints()
    self:ClearPoints(self._npcPoints)
    self:ClearPoints(self._linkPoints)

    if not self._mapAble then return end

    local mapId = SL:GetValue("MAP_ID")
    if not mapId then return end
    
    --npc
    local list = SL:GetValue("NPC_LIST", mapId)
    local idx = 0
    for k, v in pairs(list) do
        if v and not SL:GetValue("NPC_IS_HIDE_POINT", v.ID) then
            idx = idx + 1
            local x, y = self:CalcMiniMapPos(v.X, v.Y)
            local actorPoint = Pool.Get("Main", "MiniMapPoint", self._mapUI.Node_npc)
            FGUI:setPosition(actorPoint, x, y)
            self:UpdateActorPointState(actorPoint, 3)
            self._npcPoints[idx] = actorPoint
        end
    end

    -----------------------------------------------------------------------------
    --link
    local idx = 0
    local createLinkPoint = function(posStr)
        if not posStr then return end
        local posInfo = string.split(posStr, "#")
        if not posInfo then return end
        local x = posInfo[1] and tonumber(posInfo[1]) or nil
        local y = posInfo[2] and tonumber(posInfo[2]) or nil
        if x and y then
            local x, y = self:CalcMiniMapPos(x, y)
            local actorPoint = Pool.Get("Main", "MiniMapPoint", self._mapUI.Node_link)
            FGUI:setPosition(actorPoint, x, y)
            self:UpdateActorPointState(actorPoint, 2)
            self._linkPoints[idx] = actorPoint
        end
    end
    --mapFrom
    local list = SL:GetValue("LINK_POINTS_MAPFROM", mapId)
    for k, v in pairs(list) do
        if v and not SL:GetValue("LINK_IS_HIDE_POINT", v.ID) then
            idx = idx + 1
            local posStr = v.PosiFrom
            createLinkPoint(posStr)
        end
    end
    --mapTo
    local list = SL:GetValue("LINK_POINTS_MAPTO", mapId)
    for k, v in pairs(list) do
        if v and not SL:GetValue("LINK_IS_HIDE_POINT", v.ID) then
            idx = idx + 1
            local posStr = v.PosiTo
            createLinkPoint(posStr)
        end
    end
end

function MainMiniMap:ClearPoints(points)
    local cells = points
    if #cells <= 0 then return end
    for k, cell in pairs(cells) do
        FGUI:setPosition(cell, -5000, -5000)
        Pool.Release("Main", "MiniMapPoint", cell, false)
    end
    table.clear(points)
end

function MainMiniMap:CalcMainPlayerMiniMapPos(x, y)
	local targetX   = self._limitSizeW/2
	local targetY   = self._limitSizeH/2
	local minimapX, minimapY = self:CalcMiniMapPos(x, y)

	-- 校正X
	if minimapX < self._limitSizeW/2 then
		targetX = minimapX
	elseif minimapX > self._minimapW - self._limitSizeW/2 then
		targetX = self._limitSizeW - (self._minimapW - minimapX)
	end

	-- 校正Y
	if minimapY < self._limitSizeH/2 then
		targetY = minimapY
	elseif minimapY > self._minimapH - self._limitSizeH/2 then
		targetY = self._limitSizeH - (self._minimapH - minimapY)
	end
	return targetX, targetY
end

function MainMiniMap:CalcMiniMapPos(actorX, actorZ)
	local minimapX  = (actorX - self._offsetX) / self._sizeW * self._minimapW
	local minimapY  = self._minimapH - (actorZ - self._offsetY) / self._sizeH * self._minimapH
	return minimapX, minimapY
end

function MainMiniMap:UpdatePlayerRotate(dir)
    FGUI:setRotation(self._mapUI.Image_player, (dir or SL:GetValue("ROTATION")) + 90)
end

function MainMiniMap:UpdateActorRotate(actorId, actorPoint)
    local r = SL:GetValue("ACTOR_DIR", actorId) or 0
    FGUI:setRotation(actorPoint, r + 90)
end

local MAX_UPDATE_ACTOR = 10 --每次最大更新数量
function MainMiniMap:UpdateActorPoints()
    if not self._mapAble then return end
    local map = self._updateActorMap
    for actorId, actorPoint in pairs(self._teamPoints) do
        map[actorId] = true
        self:UpdateTeamMemberPoint(actorId)
    end
    local playerList, nPlayer = SL:GetValue("FIND_IN_VIEW_PLAYER_LIST")
    local monsterList, nMonster = SL:GetValue("FIND_IN_VIEW_MONSTER_LIST", true, true)
    local count = 0
    for i = 1, nPlayer do
        local actorId = playerList[i]
        if not map[actorId] then
            map[actorId] = true
            count = count + 1
            self:UpdatePlayerPoint(actorId)
            if count > MAX_UPDATE_ACTOR then return end
        end
    end
    for i = 1, nMonster do
        local actorId = monsterList[i]
        if not map[actorId] then
            map[actorId] = true
            count = count + 1
            self:UpdateMonsterPoint(actorId)
            if count > MAX_UPDATE_ACTOR then return end
        end
    end
    table.clear(map)
end

----------------------------------------寻路-------------------------------------
function MainMiniMap:UpdateFindPath()
	local size = SL:GetValue("MAP_PATH_SIZE")
	if size >= 1 then
		self:FindPathBegin()
	else
		self:FindPathEnd()
	end
end

function MainMiniMap:FindPathBegin()
	local moveType = SL:GetValue("MAP_CURRENT_MOVE_TYPE")
	if moveType == SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_AUTOMOVE or 
        moveType == SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_AFK or
        moveType == SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_OTHER then
		if self.scheduleId == nil then
			self.scheduleId = SL:Schedule(function()
				self:ShowFindPathLine()
			end, 0.2)
		end
	end
end

function MainMiniMap:ShowFindPathLine()
	local points = SL:GetValue("MAP_PATH_POINTS")
	local size = SL:GetValue("MAP_PATH_SIZE")
    local playerX, playerZ = SL:GetValue("MAP_PLAYER_POS")
    local pathIdx = SL:GetValue("MAP_CURRENT_PATH_INDEX")
	if size >= 1 then
	-- local dis = math.abs(points[1].x - playerX) + math.abs(points[1].z - playerZ)
	-- if size > 1 or dis > 1 then
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
        FGUI:GComponent_DrawLine(self._mapUI.Node_line, "ui://Main/point_green", 8, t)
	-- end
	end
end

function MainMiniMap:FindPathEnd()
	local size = SL:GetValue("MAP_PATH_SIZE")
	if size <= 0 then
        FGUI:GComponent_ClearLine(self._mapUI.Node_line)
	end
	if self.scheduleId then
		SL:UnSchedule(self.scheduleId)
		self.scheduleId = nil
	end
end

---------------------------------------------------

function MainMiniMap:OnOpenMiniMap()
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("MiniMap_pc", "MiniMapPanel", nil, nil, {classPath = "FGUILayout/MiniMap/MiniMapPanel"})
    else
        FGUI:Open("MiniMap", "MiniMapPanel")
    end
end

function MainMiniMap:OnOpenMapRoute()
    FGUI:Open("MapRoute", "MapRoutePanel")
end

function MainMiniMap:OnOpenRank()
    FGUI:Open("Rank", "RankPanel")
end

function MainMiniMap:OnOpenSetting()
    FGUI:Open("Setting", "SettingPanel")
end

function MainMiniMap:OnChangeMap(data)
    local x = data and data.x or nil
    local z = data and data.z or nil
    self:UpdateMapData()

    self:UpdateMapState()
    self:UpdateMapName()
    self:UpdatePlayerPos()
    self:UpdateMiniMap(x, z)
    self:UpdateFindPath()
    self:UpdateMapRoute()

    self:InitActorPoints()
    self:UpdateMapPoints()
end

function MainMiniMap:OnPlayerAction(actorID, act)
    if SL:CheckIsMoveAction(act) then
        self:UpdatePlayerPos()
        self:UpdateMiniMapPos()
    end
end

function MainMiniMap:OnActorInOfView(actorId)
    if SL:GetValue("ACTOR_IS_MONSTER", actorId) then
        self:UpdateMonsterPoint(actorId)
    elseif SL:GetValue("ACTOR_IS_PLAYER", actorId) then
        self:UpdatePlayerPoint(actorId)
    end
end
function MainMiniMap:OnActorOutOfView(actorId)
    if SL:GetValue("ACTOR_IS_MONSTER", actorId) then
        self:RmvActorPoint(actorId)
    elseif SL:GetValue("ACTOR_IS_PLAYER", actorId) then
        if SL:GetValue("TEAM_IS_MEMBER", actorId) then
            self:RmvTeamMemberPoint(actorId)
        end
        self:RmvActorPoint(actorId)
    end
end
function MainMiniMap:OnMonsterDie(actorId)
    self:RmvActorPoint(actorId)
end
function MainMiniMap:OnMonsterRevive(actorId)
    self:UpdateMonsterPoint(actorId)
end

function MainMiniMap:OnTeamMemberUpdate()
    local memberList = SL:GetValue("TEAM_MEMBER_LIST")
    local memberMap = {}
    for k, v in pairs(memberList) do
        if v.UserID ~= self._myUid then
            memberMap[v.UserID] = true
        end
    end
    for userId, point in pairs(self._teamPoints) do
        if not memberMap[userId] then
            self:RmvTeamMemberPoint(userId)
            self:UpdateActorPoint(userId)
        end
    end
    for userId, v in pairs(memberMap) do
        if SL:GetValue("ACTOR_IN_VIEW", userId) then
            self:RmvActorPoint(userId)
            self:AddTeamMemberPoint(userId)
        end
    end
end


-----------------------------------注册事件--------------------------------------
function MainMiniMap:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_MAP_STATE_CHANGE, "MainMiniMap", handler(self, self.UpdateMapState))
    SL:RegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MainMiniMap", handler(self, self.OnChangeMap))
    SL:RegisterLUAEvent(LUA_EVENT_FIND_PATH_BEGAIN, "MainMiniMap", handler(self, self.FindPathBegin))
    SL:RegisterLUAEvent(LUA_EVENT_FIND_PATH_EMD, "MainMiniMap", handler(self, self.FindPathEnd))

    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_DIRECTION_CHANGE, "MainMiniMap", handler(self, self.UpdatePlayerRotate))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_MAPPOS_CHANGE, "MainMiniMap", handler(self, self.UpdatePlayerPos))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_PROCESS, "MainMiniMap", handler(self, self.OnPlayerAction))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_COMPLETE, "MainMiniMap", handler(self, self.OnPlayerAction))

    SL:RegisterLUAEvent(LUA_EVENT_ACTOR_IN_OF_VIEW, "MainMiniMap", handler(self, self.OnActorInOfView))
    SL:RegisterLUAEvent(LUA_EVENT_ACTOR_OUT_OF_VIEW, "MainMiniMap", handler(self, self.OnActorOutOfView))
    SL:RegisterLUAEvent(LUA_EVENT_MONSTER_DIE, "MainMiniMap", handler(self, self.OnMonsterDie))
    SL:RegisterLUAEvent(LUA_EVENT_MONSTER_REVIVE, "MainMiniMap", handler(self, self.OnMonsterRevive))

    SL:RegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "MainMiniMap", handler(self, self.OnTeamMemberUpdate))
end

function MainMiniMap:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_MAP_STATE_CHANGE, "MainMiniMap")
    SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "MainMiniMap")
    SL:UnRegisterLUAEvent(LUA_EVENT_FIND_PATH_BEGAIN, "MainMiniMap")
    SL:UnRegisterLUAEvent(LUA_EVENT_FIND_PATH_EMD, "MainMiniMap")

    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_DIRECTION_CHANGE, "MainMiniMap")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_MAPPOS_CHANGE, "MainMiniMap")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_PROCESS, "MainMiniMap")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_COMPLETE, "MainMiniMap")
    
    SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_IN_OF_VIEW, "MainMiniMap")
    SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_OUT_OF_VIEW, "MainMiniMap")
    SL:UnRegisterLUAEvent(LUA_EVENT_MONSTER_DIE, "MainMiniMap")
    SL:UnRegisterLUAEvent(LUA_EVENT_MONSTER_REVIVE, "MainMiniMap")

    SL:UnRegisterLUAEvent(LUA_EVENT_TEAM_MEMBER_UPDATE, "MainMiniMap")
end


return MainMiniMap