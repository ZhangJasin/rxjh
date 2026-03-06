local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainFindTarget = class("MainFindTarget", BaseFGUILayout)

local SHOW_PLAYER = 1
local SHOW_MONSTER = 2
local SHOW_ATTACKER = 3

local SORT_NONE = 0
local SORT_DISTANCE = 1     --距离排序
local SORT_BOSS_SIGN = 2    --BossSign排序
local SORT_DAMAGE = 3       --伤害排序

local sort_distance = function(a, b) return a.dis < b.dis end
local sort_bossSign = function(a, b) return a.sign > b.sign end
local sort_damage = function(a, b) 
    local aDamage = SL:GetMainPlayerSuffer(a.id) or 0
    local bDamage = SL:GetMainPlayerSuffer(b.id) or 0
    return aDamage > bDamage
end

local SORT_FUNC_MAP = {
    [SORT_DISTANCE] = sort_distance,
    [SORT_BOSS_SIGN] = sort_bossSign,
    [SORT_DAMAGE] = sort_damage,
}

function MainFindTarget:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.FindTarget)

    self._showIndex = SHOW_PLAYER
    self._actors = {}
    self._actorMap = {}
    self._damageCacheMap = {}
    self._count = 0
    self._wait = false
    self._dirty = false
    self._myUID = SL:GetValue("USER_ID")
    self._items = {}    -- actorId: itemUI
    self._itemUIs = {}  -- itemId: itemUI
    self._sort = 1      -- 排序规则
    self._sortType = SORT_NONE
    self._sortFunc = SORT_FUNC_MAP[self._sortType]
    self._stateCtl = FGUI:getController(self.component, "state")
    
    self._refreshHandler = handler(self, self.ResetWait)

    self.mainPlayerX, self.mainPlayerY, self.mainPlayerZ = 0, 0, 0
    
    FGUI:setOnClickEvent(self._ui.Button_close, handler(self, self.Close))
    FGUI:setOnClickEvent(self._ui.Button_type1, handler(self, self.OnShowActors, SHOW_PLAYER))
    FGUI:setOnClickEvent(self._ui.Button_type2, handler(self, self.OnShowActors, SHOW_MONSTER))
    FGUI:setOnClickEvent(self._ui.Button_type3, handler(self, self.OnShowActors, SHOW_ATTACKER))
    FGUI:setOnClickEvent(self._ui.Button_sort1, handler(self, self.OnChangeSort, 1))
    FGUI:setOnClickEvent(self._ui.Button_sort2, handler(self, self.OnChangeSort, 2))
    
    FGUI:GList_setVirtual(self._ui.ListTarget, false)
    FGUI:GList_itemRenderer(self._ui.ListTarget, handler(self, self.OnListTargetRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.ListTarget, handler(self, self.OnClickListTarget))

    self:UpdateButtonType()
    self:UpdateSortButton()
end

function MainFindTarget:Enter()
	self:RegisterEvent()

    self:InitAdapt()
    self:InitActors(true)
    self:InitShowType()
end

function MainFindTarget:Exit()
	self:RemoveEvent()
    self:StopUpdateDistance()
    self:StopUpdateAttacker()
end

function MainFindTarget:Destroy()
    self._ui = nil	
    self._stateCtl = nil
end

-----------------------------------------------------------------------------

function MainFindTarget:InitAdapt()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local safeL, safeR, safeB, safeT = SL:GetValue("SCREEN_SAFE_AREA_RATIO")
    FGUI:setSize(self.component, screenW - safeR - safeL, screenH - safeB - safeT)
    FGUI:setPosition(self.component, safeL, safeT)
end

function MainFindTarget:InitShowType()
    if self._showIndex == SHOW_ATTACKER then
        self:StartUpdateAttacker()
    end
    if self._sortType == SORT_DISTANCE then
        self:StartUpdateDistance()
    end
end

function MainFindTarget:UpdateButtonType()
    if self._showIndex == SHOW_PLAYER then
        FGUI:GButton_setSelected(self._ui.Button_type1, true)
        FGUI:GButton_setSelected(self._ui.Button_type2, false)
        FGUI:GButton_setSelected(self._ui.Button_type3, false)
    elseif self._showIndex == SHOW_MONSTER then
        FGUI:GButton_setSelected(self._ui.Button_type1, false)
        FGUI:GButton_setSelected(self._ui.Button_type2, true)
        FGUI:GButton_setSelected(self._ui.Button_type3, false)
    elseif self._showIndex == SHOW_ATTACKER then
        FGUI:GButton_setSelected(self._ui.Button_type1, false)
        FGUI:GButton_setSelected(self._ui.Button_type2, false)
        FGUI:GButton_setSelected(self._ui.Button_type3, true)
    end
end

function MainFindTarget:UpdateSortButton()
    FGUI:GButton_setSelected(self._ui.Button_sort1, self._sort == 1)
    FGUI:GButton_setSelected(self._ui.Button_sort2, self._sort == 2)
end

function MainFindTarget:InitActors(refreshAtOnce)
    self._count = 0
    table.clear(self._actors)
    table.clear(self._actorMap)
    if self._showIndex == SHOW_PLAYER then
        local actors, len = SL:GetValue("FIND_IN_VIEW_PLAYER_LIST", true, true)        
        for k, actorId in pairs(actors) do
            self:AddPlayerActor(actorId)
        end
    elseif self._showIndex == SHOW_MONSTER then
        local actors, len = SL:GetValue("FIND_IN_VIEW_MONSTER_LIST", true, true)
        for k, actorId in pairs(actors) do
            self:AddMonsterActor(actorId)
        end
    elseif self._showIndex == SHOW_ATTACKER then
        table.clear(self._damageCacheMap)
        local actorMap = SL:GetMainPlayerSuffers()
        for actorId, damage in pairs(actorMap) do
            self:AddAttackerActor(actorId, damage)
        end
    end
    if self._sortFunc then
        self:UpdateSort()
    end
    self:RefreshList(refreshAtOnce)
end

function MainFindTarget:UpdateAttackerActors()
    table.clear(self._damageCacheMap)
    local refresh = false
    local actorMap = SL:GetMainPlayerSuffers()
    for actorId, data in pairs(self._actorMap) do
        if not actorMap[actorId] then
            refresh = self:RemoveActor(actorId) or refresh
        end
    end
    for actorId, damage in pairs(actorMap) do
        if SL:GetValue("ACTOR_IN_VIEW", actorId) then
            refresh = self:AddAttackerActor(actorId, damage) or refresh
        end
    end
    if refresh then
        if self._sortFunc then
            self:UpdateSort()
        end
        self:RefreshList(false)
    end
end

function MainFindTarget:OnListTargetRenderer(index, item)
    local data = self._actors[index + 1]
    if not data then return end
    local actorId = data.id
    if not actorId then return end

    local itemId = FGUI:GetID(item)
    
    local itemUI = self._itemUIs[itemId]
    if not itemUI then
        itemUI = FGUI:ui_delegate(item)
        self._itemUIs[itemId] = itemUI
    end
    FGUI:setVisible(itemUI.Image_Select, actorId == SL:GetValue("SELECT_TARGET_ID"))
    self._items[actorId] = itemUI
    FGUI:SetIntData(item, index)

    if self._showIndex == SHOW_PLAYER or self._showIndex == SHOW_ATTACKER then
        FGUIFunction:SetCommonPlayerFrame(itemUI.Head, data.headData)
    elseif self._showIndex == SHOW_MONSTER then
        FGUI:GLoader_setUrl(itemUI("Head", "Image_head"), data.icon, nil, true)
        FGUI:GLoader_setUrl(itemUI("Head", "Image_headFrame"), "")
    end
    -- if self._showIndex == SHOW_ATTACKER then
    --     FGUI:GTextField_setText(itemUI.Text_value, data.damage)
    -- else
    --     FGUI:GTextField_setText(itemUI.Text_value, "")
    -- end
    
    FGUI:GTextField_setText(itemUI.Text_level, data.level)
    local hp = data.hp or SL:GetValue("ACTOR_HP", actorId)
    local maxHp = data.maxHp or SL:GetValue("ACTOR_MAXHP", actorId)
    FGUI:GProgressBar_setValue(itemUI.ProgressBar_hp, hp / maxHp * 100)
    FGUIFunction:ScrollText_setString(itemUI.Label_name, data.name, 1, 0)
end

function MainFindTarget:OnShowActors(showType)
    if self._showIndex == showType then return end
    if self._showIndex == SHOW_ATTACKER then
        self:StopUpdateAttacker()
    end
    self._showIndex = showType
    if showType == SHOW_ATTACKER then
        self:StartUpdateAttacker()
    end
    FGUI:Controller_setSelectedIndex(self._stateCtl, self._showIndex - 1)
    self:UpdateButtonType()
    self:SetSort(1)
    self:InitActors(true)
end

function MainFindTarget:StartUpdateAttacker()
    if self._attackerUpdateTimer then return end
    if not self._handlerUpdateAttackerActors then
        self._handlerUpdateAttackerActors = handler(self, self.UpdateAttackerActors)
    end
    self._attackerUpdateTimer = SL:Schedule(self._handlerUpdateAttackerActors, 1)
end

function MainFindTarget:StopUpdateAttacker()
    if not self._attackerUpdateTimer then return end
    SL:UnSchedule(self._attackerUpdateTimer)
    self._attackerUpdateTimer = nil
end

function MainFindTarget:StartUpdateDistance()
    if self._distanceUpdateTimer then return end
    if not self._handlerUpdateActorsDistance then
        self._handlerUpdateActorsDistance = handler(self, self.UpdateActorsDistance)
    end
    self._distanceUpdateTimer = SL:Schedule(self._handlerUpdateActorsDistance, 1)
end

function MainFindTarget:StopUpdateDistance()
    if not self._distanceUpdateTimer then return end
    SL:UnSchedule(self._distanceUpdateTimer)
    self._distanceUpdateTimer = nil
end

function MainFindTarget:OnChangeSort(index)
    self:SetSort(index)
end

function MainFindTarget:SetSort(index)
    if self._sort == index then return end
    self._sort = index
    if self._sortType == SORT_DISTANCE then
        self:StopUpdateDistance()
    end
    if index == 1 then
        self._sortType = SORT_NONE
    elseif index == 2 then
        if self._showIndex == SHOW_PLAYER then
            self._sortType = SORT_DISTANCE
            self:UpdateActorsDistance()
        elseif self._showIndex == SHOW_MONSTER then
            self._sortType = SORT_BOSS_SIGN
        elseif self._showIndex == SHOW_ATTACKER then
            self._sortType = SORT_DAMAGE
        else
            self._sortType = SORT_NONE
        end
    end
    if self._sortType == SORT_DISTANCE then
        self:StartUpdateDistance()
    end
    self._sortFunc = SORT_FUNC_MAP[self._sortType]
    self:UpdateSortButton()
end


function MainFindTarget:OnClickListTarget(context)
    local item = context.data
    if not item then return end
    local index = FGUI:GetIntData(item)
    if not index then return end
    local actorData = self._actors[index + 1]
    local actorId = actorData.id
    if not actorId then return end

    if not SL:GetValue("ACTOR_IN_VIEW", actorId) then
        SL:ShowSystemTips(GET_STRING(40070101))
        return
    end

    -- 目标为玩家时,主玩家或目标有一人在安全区,就不开启自动战斗
    if not (SL:GetValue("ACTOR_IS_PLAYER", actorId) and 
        (SL:GetValue("ACTOR_IN_SAFE_ZONE", actorId) or 
        SL:GetValue("ACTOR_IN_SAFE_ZONE", actorId))) then

        local isAFK = SL:GetValue("BATTLE_IS_AFK")
        if not isAFK then
            SL:SetValue("BATTLE_AFK_BEGIN")
        end
    end
    SL:SetValue("SELECT_TARGET_ID", actorId)
end

function MainFindTarget:ResetWait()
    self._wait = false
    if self._dirty then
        self:RefreshList(false)
    end
end

function MainFindTarget:RefreshList(atOnce)
    if (not atOnce) and self._wait then
        self._dirty = true
        return 
    end
    self._wait = true
    self._dirty = false
    table.clear(self._items)
    FGUI:GList_setNumItems(self._ui.ListTarget, self._count)

    SL:ScheduleOnce(self._refreshHandler, 1)
end

function MainFindTarget:GetActorDistance(actorID)
    local x, y, z = SL:GetValue("ACTOR_POSITION", actorID)
    local dis = (self.mainPlayerX - x) ^ 2 + (self.mainPlayerZ - z) ^ 2
    return dis
end

function MainFindTarget:UpdateActorsDistance()
    self.mainPlayerX, self.mainPlayerY, self.mainPlayerZ = SL:GetValue("ACTOR_POSITION")
    local actors = self._actors
    for k, v in pairs(actors) do
        v.dis = self:GetActorDistance(v.id)
    end
    self:UpdateSort()
    self:RefreshList(true)
end

function MainFindTarget:AddPlayerActor(actorId)
    if not actorId then return false end
    if self._myUID == actorId then return false end
    if not SL:GetValue("ACTOR_IS_ENEMY", actorId) then return false end
    local count = self._count + 1
    self._count = count
    local dis = 99999999
    if self._sortType == SORT_DISTANCE then
        dis = self:GetActorDistance(actorId)
    end

    local data = {
        id = actorId, 
        dis = dis,
        name = FGUIFunction:GetServerName(SL:GetValue("ACTOR_NAME", actorId)),
        level = SL:GetValue("ACTOR_LEVEL", actorId),
        headData = {
            Job = SL:GetValue("ACTOR_JOB_ID", actorId),
            Sex = SL:GetValue("ACTOR_SEX", actorId),
            AvatarID = SL:GetValue("ACTOR_AVATAR", actorId),
            FrameID = SL:GetValue("ACTOR_AVATAR_FRAME", actorId),
        }
    }
    self._actors[count] = data
    self._actorMap[actorId] = data
    return true
end

function MainFindTarget:AddMonsterActor(actorId)
    if not actorId then return false end
    if not SL:GetValue("ACTOR_IS_ENEMY", actorId) then return false end
    local count = self._count + 1
    self._count = count
    local typeIndex = SL:GetValue("ACTOR_TYPE_INDEX", actorId)
    local dis = 99999999
    if self._sortType == SORT_DISTANCE then
        dis = self:GetActorDistance(actorId)
    end
    local data = {
        id = actorId, 
        dis = dis,
        name = SL:GetValue("ACTOR_NAME", actorId),
        level = SL:GetValue("MONSTER_LEVEL", actorId),
        sign = SL:GetValue("MONSTER_BOSS_SIGN", typeIndex),
        icon = SL:GetValue("MONSTER_ICON", typeIndex) or "",
    }

    self._actors[count] = data
    self._actorMap[actorId] = data
    return true
end

function MainFindTarget:AddAttackerActor(actorId, damage)
    if not actorId then return false end
    damage = damage or SL:GetMainPlayerSuffer(actorId)
    if damage <= 0 then return false end
    local masterID = SL:GetValue("ACTOR_MASTER_ID", actorId)
    if masterID and masterID ~= 0 then
        --将宠物/召唤物伤害累加到玩家身上
        actorId = masterID
        local data = self._actorMap[actorId]
        if not data then 
            local cacheDamage = self._damageCacheMap[actorId] or 0
            self._damageCacheMap[actorId] = cacheDamage + damage
            return false
        else
            data.damage = data.damage + damage
            return true
        end
    end
    if not SL:GetValue("ACTOR_IS_PLAYER", actorId) then return end
    
    local cacheDamage = self._damageCacheMap[actorId] or 0
    self._damageCacheMap[actorId] = nil
    local data = self._actorMap[actorId]
    if not data then
        local count = self._count + 1
        self._count = count
        local dis = 99999999
        if self._sortType == SORT_DISTANCE then
            dis = self:GetActorDistance(actorId)
        end
        data = {
            id = actorId, 
            dis = dis, 
            damage = cacheDamage + damage,
            name = FGUIFunction:GetServerName(SL:GetValue("ACTOR_NAME", actorId)),
            level = SL:GetValue("ACTOR_LEVEL", actorId),
            headData = {
                Job = SL:GetValue("ACTOR_JOB_ID", actorId),
                Sex = SL:GetValue("ACTOR_SEX", actorId),
                AvatarID = SL:GetValue("ACTOR_AVATAR", actorId),
                FrameID = SL:GetValue("ACTOR_AVATAR_FRAME", actorId),
            }
        }
        self._actors[count] = data
        self._actorMap[actorId] = data
    else
        data.damage = cacheDamage + damage
    end
    data.hp = SL:GetValue("ACTOR_HP", actorId)
    data.maxHp = SL:GetValue("ACTOR_MAXHP", actorId)
    return true
end

function MainFindTarget:UpdateSort()
    if not self._sortFunc then return end
    local targetID = SL:GetValue("SELECT_TARGET_ID")
    local targetIdx = nil
    local targetData = nil
    if targetID then
        for k, v in pairs(self._actors) do
            if v.id == targetID then
                targetIdx = k
                targetData = v
                table.remove(self._actors, targetIdx)
                break
            end
        end
    end
    table.sort(self._actors, self._sortFunc)
    if targetIdx and targetData then
        table.insert(self._actors, targetIdx, targetData)
    end
end


--------------------------------------------------------

function MainFindTarget:OnPKStateChange()
    if self._showIndex ~= SHOW_PLAYER then return end
    self:InitActors()
end

function MainFindTarget:OnActorInOfView(actorId)
    if self._actorMap[actorId] then return end
    if self._showIndex == SHOW_PLAYER then
        if SL:GetValue("ACTOR_IS_PLAYER", actorId) then
            if not self:AddPlayerActor(actorId) then return end
        end
    elseif self._showIndex == SHOW_MONSTER then
        if SL:GetValue("ACTOR_IS_MONSTER", actorId) then
            if not self:AddMonsterActor(actorId) then return end
        end
    elseif self._showIndex == SHOW_ATTACKER then
        if not self:AddAttackerActor(actorId) then return end
    end
    self:UpdateSort()
    self:RefreshList(false)
end

function MainFindTarget:OnActorOutOfView(actorId)
    if not self._actorMap[actorId] then return end
    if self._showIndex == SHOW_ATTACKER then return end--攻击者 保留显示,不直接移除
    if self:RemoveActor(actorId) then
        self:RefreshList(false)
    end
end

function MainFindTarget:RemoveActor(actorId)
    for k, data in pairs(self._actors) do
        if actorId == data.id then
            table.remove(self._actors, k)
            self._count = self._count - 1
            self._actorMap[actorId] = nil
            return true
        end
    end
    return false
end

function MainFindTarget:OnRefreshActorHP(actorId)
    local actorData = self._actorMap[actorId]
    if not actorData then return end
    local itemUI = self._items[actorId]
    if not itemUI then return end
    local hp = SL:GetValue("ACTOR_HP", actorId)
    local maxHp = SL:GetValue("ACTOR_MAXHP", actorId)
    if actorData.hp then
        actorData.hp = hp
    end
    if actorData.maxHp then
        actorData.maxHp = maxHp
    end
    FGUI:GProgressBar_setValue(itemUI.ProgressBar_hp, hp / maxHp * 100)
end

function MainFindTarget:OnRefreshActorHead(actorId, data)
    if not self._showIndex == SHOW_PLAYER then return end
    local actorData = self._actorMap[actorId]
    if not actorData then return end
    if not SL:GetValue("ACTOR_IN_VIEW", actorId) then return end
    local itemUI = self._items[actorId]
    if not itemUI then return end
    local headData = data.headData
    if not headData then return end
    headData.Job = SL:GetValue("ACTOR_JOB_ID", actorId)
    headData.Sex = SL:GetValue("ACTOR_SEX", actorId)
    headData.AvatarID = SL:GetValue("ACTOR_AVATAR", actorId)
    headData.FrameID = SL:GetValue("ACTOR_AVATAR_FRAME", actorId)
    FGUIFunction:SetCommonPlayerFrame(itemUI.Head, data.headData)
end

function MainFindTarget:OnTargetChange(data)
    local targetID = data.targetID
    for actorId, itemUI in pairs(self._items) do
        FGUI:setVisible(itemUI.Image_Select, actorId == targetID)
    end
end

function MainFindTarget:OnHpChange()
    if self._showIndex ~= SHOW_ATTACKER then return end
    self:UpdateAttackerActors(false)
end

-----------------------------------注册事件--------------------------------------
function MainFindTarget:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE, "MainFindTarget", handler(self, self.OnRefreshActorHead))
    SL:RegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE, "MainFindTarget", handler(self, self.OnRefreshActorHead))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA, "MainFindTarget", handler(self, self.OnRefreshActorHead))
    SL:RegisterLUAEvent(LUA_EVENT_ACTOR_REFRESH_HP, "MainFindTarget", handler(self, self.OnRefreshActorHP))
    SL:RegisterLUAEvent(LUA_EVENT_ACTOR_IN_OF_VIEW, "MainFindTarget", handler(self, self.OnActorInOfView))
    SL:RegisterLUAEvent(LUA_EVENT_ACTOR_OUT_OF_VIEW, "MainFindTarget", handler(self, self.OnActorOutOfView))
    SL:RegisterLUAEvent(LUA_EVENT_PKSTATE_CHANGE, "MainFindTarget", handler(self, self.OnPKStateChange))
    SL:RegisterLUAEvent(LUA_EVENT_TARGET_CAHNGE, "MainFindTarget", handler(self, self.OnTargetChange))
    SL:RegisterLUAEvent(LUA_EVENT_HP_CHANGE, "MainFindTarget", handler(self, self.OnHpChange))
end

function MainFindTarget:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATAR_CHANGE, "MainFindTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_AVATARFRAME_CHANGE, "MainFindTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_CUSTOMDATA, "MainFindTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_REFRESH_HP, "MainFindTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_IN_OF_VIEW, "MainFindTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_ACTOR_OUT_OF_VIEW, "MainFindTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_PKSTATE_CHANGE, "MainFindTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_TARGET_CAHNGE, "MainFindTarget")
    SL:UnRegisterLUAEvent(LUA_EVENT_HP_CHANGE, "MainFindTarget")
end


return MainFindTarget