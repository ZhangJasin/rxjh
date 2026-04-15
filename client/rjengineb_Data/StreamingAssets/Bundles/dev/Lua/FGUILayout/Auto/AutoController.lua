AutoController = class("AutoController")
AutoController.TIMER_INTERVAL = 0.1
AutoController.STATE_SYNC_INTERVAL = 1  -- 状态同步间隔(秒)
local mFloor = math.floor
local mRandom = math.random
local mAbs = math.abs

function AutoController.main()
    AutoController:Init()
end

function AutoController:Init()
    self._fightState = false
    self._outFightTime = 0
    self._stateSyncTime = 0
    self:TimerBegan()
    SL:RegisterLUAEvent(LUA_EVENT_FIGHT, "AutoController",handler(self,self.OnFightState))
    SL:RegisterLUAEvent(LUA_EVENT_NET_PLAYER_ACTION_COMPLETE, "AutoController",handler(self,self.OnPlayerActionComplete))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_COMPLETE, "AutoController",handler(self,self.OnPlayerActionComplete))
end

function AutoController:OnPlayerActionComplete(actorID, act)
    local moveData = SL:GetValue("MOVE_POS")
    if SL:CheckIsMoveAction(act) 
        and (moveData and moveData.skillID and moveData.targetID
        and (moveData.targetID == actorID or SL:GetValue("ACTOR_IS_MAINPLAYER", actorID))) then 
        local skillID = moveData.skillID
        local targetID = moveData.targetID
        local mainPlayerID = SL:GetValue("MAIN_PLAYER_ID")
        local sX = SL:GetValue("ACTOR_POSITION_X",mainPlayerID)
        local sY = SL:GetValue("ACTOR_POSITION_Y",mainPlayerID)
        local sZ = SL:GetValue("ACTOR_POSITION_Z",mainPlayerID)
        local dX = SL:GetValue("ACTOR_POSITION_X", targetID)
        local dY = SL:GetValue("ACTOR_POSITION_Y", targetID)
        local dZ = SL:GetValue("ACTOR_POSITION_Z", targetID)
        local tX, tY, tZ = SL:FindBestSkillPos(skillID, sX, sY, sZ, dX, dY, dZ)
        if sX == tX or sZ == tZ or sY == tY then
            SL:RequestLaunchSkill(skillID, nil, nil, true)
        end
    end
end

function AutoController:OnFightState()
    if not SL:GetValue("BATTLE_IS_FIGHT_STATE") then 
        SL:SetValue("BATTLE_IS_FIGHT_STATE", true)
        self._fightState = true
        SLBridge:onLUAEvent(LUA_EVENT_FIGHT_BEGIN)
    end
    self._outFightTime = 0
end

function AutoController:TimerBegan()
    if not self._timerID then
        local function callback()
            self:Tick( self.TIMER_INTERVAL )
        end
        self._timerID = SL:Schedule( callback, self.TIMER_INTERVAL )
    end
end

function AutoController:Tick(delta)
    -- 定期同步真实状态,避免状态丢失
    self._stateSyncTime = self._stateSyncTime + delta
    if self._stateSyncTime >= self.STATE_SYNC_INTERVAL then
        self._stateSyncTime = 0
        self:SyncFightState()
    end

    -- 保留原有的超时机制,但作为辅助手段
    if self._fightState then
        self._outFightTime = self._outFightTime + delta
        -- 延长超时时间到15秒,给状态同步留出时间
        if self._outFightTime >= 15 then
            self._fightState = false
            self._outFightTime = 0
            -- 只在确实不在战斗时才触发退出事件
            local realFightState = SL:GetValue("BATTLE_IS_FIGHT_STATE")
            if not realFightState then
                SL:SetValue("BATTLE_IS_FIGHT_STATE", false)
                SLBridge:onLUAEvent(LUA_EVENT_FIGHT_END)
            else
                -- 引擎状态仍在战斗,重置超时
                self._fightState = true
                self._outFightTime = 0
            end
        end
    end
end

-- 同步引擎真实状态
function AutoController:SyncFightState()
    local realFightState = SL:GetValue("BATTLE_IS_FIGHT_STATE")
    local isAFK = SL:GetValue("BATTLE_IS_AFK")
    
    -- 如果引擎状态和控制器状态不一致,以引擎为准
    if realFightState and not self._fightState then
        -- 引擎显示在战斗,但控制器不在,需要同步
        self._fightState = true
        self._outFightTime = 0
    elseif not realFightState and self._fightState and not isAFK then
        -- 引擎显示不在战斗且不在挂机,控制器在战斗,需要退出
        self._fightState = false
        self._outFightTime = 0
        SL:SetValue("BATTLE_IS_FIGHT_STATE", false)
        SLBridge:onLUAEvent(LUA_EVENT_FIGHT_END)
    end
end
function AutoController:StateBegin(actCompleted)
    --跟随状态
    if self:CheckFollowState() then 
        return true
    end

    --锁定状态
    if self:CheckLaunchLockSkill() then
        return true
    end

    -----挂机---------------

    -- 用户有输入
    if self:CheckAllInput() then 
        return true
    end
	--安全区 判断。。
    if SL:GetValue("GAME_DATA", "AFKSafeAreaIdle") == 1 then 
        if self:CheckSafeZone() then
            return true
        end
    end

    --自动拾取
    if SL:GetValue("GAME_DATA", "ForcedPickUp") == 1 
        and SL:GetValue("GAME_DATA", "PickMode") ~= 1 then 
        if self:CheckAutoFindDropItem() then
            return true
        end
    end

    --自动找目标
    if self:CheckAutoFindTarget(actCompleted) then
        return true
    end

    -- 自动释放技能
    if self:CheckLaunchAutoSkill() then
        return true
    end

    -- 周围无怪返回挂机点
    if self:CheckBackToAfkPoint(actCompleted) then
        return true
    end

    -- 随机寻路
    if self:CheckSearchMonsterMove(actCompleted) then
        return true
    end
end

function AutoController:CheckSafeZone()
    if not SL:GetValue("BATTLE_IS_AFK") then
        return false
    end

    if SL:GetValue("ACTOR_IN_SAFE_ZONE") then 
        return true
    end
end

function AutoController:CheckFollowState()
    -- 跟随状态
    if not SL:GetValue("BATTLE_IS_FOLLOW_STATE") then 
        return false
    end

    if SL:GetValue("MAP_CURRENT_MOVE_TYPE") == SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_FOLLOW then 
        return false
    end

    local targetID = SL:GetValue("FOLLOW_ID")
    repeat
        local sX = SL:GetValue("ACTOR_POSITION_X") 
        local sY = SL:GetValue("ACTOR_POSITION_Y") 
        local sZ = SL:GetValue("ACTOR_POSITION_Z") 
        local dX = SL:GetValue("ACTOR_POSITION_X", targetID) 
        local dZ = SL:GetValue("ACTOR_POSITION_Z", targetID) 
        local distance = SL:CalcDistance(sX, sZ, dX, dZ)

        local distanceMin = SL:GetValue("FOLLOW_MIN_DISTANCE") 
        local followMode = SL:GetValue("FOLLOW_MODE") 
        local block = false
        local resX = sX
        local resY = sY
        local resZ = sZ
        local isFind = false
        local dir = SL:GetValue("ACTOR_DIR", targetID) 
        local eastDir = SL:ConvertToEastDir(dir)
        if distance > distanceMin then
            if followMode == SLDefine.FOLLOW_MODE.RANDOM_POINT_BEHIND_TARGET then --随机跟随目标后面
                for i = 1, 15 do
                    resX, resZ = self:RandomPointBehindTarget(dX, dZ, eastDir, distanceMin)
                    block = SL:GetValue("MAP_IS_BLOCK",resX, resY, resZ) 
                    if not block then 
                        isFind = true 
                        break
                    end
                end
            elseif followMode == SLDefine.FOLLOW_MODE.POINT_BEHIND_TARGET then --跟屁股后面
                for i = distanceMin, 1, -1 do
                    resX, resZ = self:PointBehindTarget(dX, dZ, eastDir, i)
                    block = SL:GetValue("MAP_IS_BLOCK",resX, resY, resZ) 
                    if not block then 
                        isFind = true 
                        break
                    end
                end
            end
            
            if isFind then 
                SL:SetMetaValue("AUTO_INPUT_MOVE", SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_FOLLOW, resX, resY, resZ)
            end
        end
    until true
    return true
end

-- 用于生成目标后方圆内的随机点
function AutoController:RandomPointBehindTarget(targetX, targetY, angle, radius)
    local radiusMin = 0.5
    local radiusMax = math.max(1, radius) 
    -- 确定目标后方的角度范围，假设后方角度范围是 facingAngle + π ± π/2
    local facingAngle = angle / 360 * math.pi * 2
    local minAngle = facingAngle + math.pi - math.pi / 6
    local maxAngle = facingAngle + math.pi + math.pi / 6

    -- 随机生成一个在后方角度范围内的极角
    local theta = minAngle + mRandom() * (maxAngle - minAngle)
    local r = radiusMin + mRandom() * (radiusMax - radiusMin)

    -- 将极坐标转换为直角坐标
    local x = targetX + r * math.cos(theta)
    local y = targetY + r * math.sin(theta)

    return x, y
end

-- 用于生成目标后面的点
function AutoController:PointBehindTarget(targetX, targetY, angle, radius)
    local facingAngle = angle / 360 * math.pi * 2 + math.pi
    local x = targetX + radius * math.cos(facingAngle)
    local y = targetY + radius * math.sin(facingAngle)
    return x, y
end


function AutoController:CheckAllInput()
    if SL:GetValue("BATTLE_IS_USER_INPUT")   then 
        return true
    end
end

function AutoController:CheckAutoFindDropItem()
    if not SL:GetValue("BATTLE_IS_AFK") then
        return false
    end

    if not SL:GetValue("SETTING_GLOBAL_AUTO_PICKUP_EN") then
        return false
    end

    if SL:GetValue("MAP_CURRENT_MOVE_TYPE") == SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_FINDITEM then 
        return true
    end

    if not SL:GetValue("PICK_ITEM_ABLE") 
        or SL:GetValue("AUTO_TARGET_TYPE") == SLDefine.AUTO_TARGET_TYPE.FIND_NPC
        or SL:GetValue("AUTO_TARGET_TYPE") == SLDefine.AUTO_TARGET_TYPE.FIND_COLLECTION
        then
        return false
    end 

    -- auto find & move to drop item
    if nil == SL:GetValue("PICK_ITEM_ID")  then
        AutoFindDropItem:FindItems(true)
    end
    
    local pickItemID = SL:GetValue("PICK_ITEM_ID")
    if pickItemID then
        local beginTime = SL:GetValue("PICK_BEGIN_TIME")
        if beginTime then  
            if SL:GetValue("SERVER_TIME") - beginTime > 5 then 
                SL:SetValue("DROPITEM_IS_PICK_TIMEOUT", pickItemID, true)
                SL:SetValue("PICK_ITEM_ID", nil)
                SL:SetValue("PICK_BEGIN_TIME", nil)
            end
        elseif SL:GetValue("MAP_CURRENT_MOVE_TYPE") ~= SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_FINDITEM then
            local pMapX = mFloor(SL:GetValue("ACTOR_MAP_X"))
            local pMapY = mFloor(SL:GetValue("ACTOR_MAP_Y"))
            local pMapZ = mFloor(SL:GetValue("ACTOR_MAP_Z")) 
            local targetX = SL:GetValue("ACTOR_MAP_X", pickItemID)
            local targetY = SL:GetValue("ACTOR_MAP_Y", pickItemID)
            local targetZ = SL:GetValue("ACTOR_MAP_Z", pickItemID)
            
            if not (targetX == pMapX and targetZ == pMapZ and targetY == pMapY) then
                SL:SetValue("AUTO_INPUT_MOVE",SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_FINDITEM,  targetX, targetY, targetZ)
            end
            SL:SetValue("PICK_BEGIN_TIME", SL:GetValue("SERVER_TIME"))
        end
        return true
    end
    
    return false
end

function AutoController:CheckAutoFindTarget(actCompleted)
    if not SL:ActionIsIdle(actCompleted) then
        return false
    end

    if not SL:GetValue("BATTLE_IS_AFK") then
        return false
    end

    if SL:GetValue("BATTLE_IS_AUTO_MOVE") and SL:GetValue("MAP_CURRENT_MOVE_TYPE") ~= SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_AFK then
        return false
    end

    local targetID = SL:GetValue("SELECT_TARGET_ID")
    if targetID == SL:GetValue("USER_ID") then
        targetID = nil
    end

    if targetID then
        return false
    end

    --反击对象
    local hateId = SL:GetValue("HATE_ID")
    if hateId and SL:GetValue("ACTOR_IN_VIEW", hateId) then 
        SL:SetValue("SELECT_TARGET_ID", hateId)
        return
    end
    
    -- 1.find current target
    local targetType = SL:GetValue("AUTO_TARGET_TYPE") 
    if SLDefine.AUTO_TARGET_TYPE.FIND_MONSTER == targetType or SLDefine.AUTO_TARGET_TYPE.FIND_PLAYER == targetType then
        AutoFindTarget:FindTarget(nil, nil, true)
    end

    if not SL:GetValue("SELECT_TARGET_ID") then
        SLBridge:onLUAEvent(LUA_EVENT_AFK_NOT_FIND_TARGET)
    end
    return false
end

function AutoController:CheckLaunchAutoSkill()
    if not SL:GetValue("BATTLE_IS_AFK") then
        return false
    end

    if SL:GetValue("LAUNCH_SKILL_ID") then
        return false
    end

    if not SL:GetValue("SELECT_TARGET_ID") then
        return false
    end

    local targetID = SL:GetValue("SELECT_TARGET_ID")
    if not SL:GetValue("TARGET_ATTACK_ENABLE", targetID) then
        SL:SetValue("SELECT_TARGET_ID", nil, SLDefine.SELECT_TARGET.SYSTEM)
        return false
    end

    --是否在挂机范围 反击除外
    if SL:GetValue("SETTING_AUTO_FIGHT_RANGE_ENABLE") then 
        local targetX = SL:GetValue("ACTOR_POSITION_X", targetID)
        local targetZ = SL:GetValue("ACTOR_POSITION_Z", targetID)
        if not SL:GetValue("CHECK_IN_AUTO_ATK_RANGE", targetX, targetZ) and not SL:GetValue("HATE_ID") == targetID  then 
            SL:SetValue("SELECT_TARGET_ID", nil, SLDefine.SELECT_TARGET.SYSTEM)
            return false
        end
    end 

    -- 挂机目标死亡，原地等待xx时间，为了等掉落物
    if SL:GetValue("AFK_TARGET_DEATH") then
        return true
    end

    -- 自动战斗技能必须有目标
    local targetID = SL:GetValue("SELECT_TARGET_ID")

    local mainPlayerX = SL:GetValue("X") 
    local mainPlayerZ = SL:GetValue("Z") 
    local launchX = SL:GetValue("ACTOR_MAP_X", targetID) 
    local launchY = SL:GetValue("ACTOR_MAP_Y", targetID) 
    local launchZ = SL:GetValue("ACTOR_MAP_Z", targetID) 
    local launchDir = SL:CalcNorthDirByPos(mainPlayerX, mainPlayerZ, launchX, launchZ)
    -- 自动释放技能
    local skillID = FGUIFunction:FindAutoLaunchSkill()
    if skillID and skillID ~= -1 then
        SL:SetValue("AUTO_INPUT_LAUNCH", skillID, launchX, launchY, launchZ, launchDir)
        return true
    end

    return false
end

function AutoController:CheckLaunchLockSkill()
    if not SL:GetValue("BATTLE_IS_AUTO_LOCK_STATE") then
        return false
    end

    if SL:GetValue("LAUNCH_SKILL_ID") then
        return false
    end

    if not SL:GetValue("SELECT_TARGET_ID") then
        return false
    end

    local targetID = SL:GetValue("SELECT_TARGET_ID")
    if not SL:GetValue("TARGET_ATTACK_ENABLE", targetID) then
        SL:SetValue("SELECT_TARGET_ID", nil, SLDefine.SELECT_TARGET.SYSTEM)
        return false
    end

    -- 找到技能
    local skillID = FGUIFunction:FindLockLaunchSkill()
    if not skillID then
        return false
    end
    
    -- 释放
    SL:SetValue("AUTO_INPUT_LAUNCH", skillID)

    return true
end

function AutoController:CheckBackToAfkPoint(actCompleted)
    if not SL:GetValue("BATTLE_IS_AFK") then
        return false
    end

    if not SL:ActionIsIdle(actCompleted) then
        return false
    end

    if SL:GetValue("SELECT_TARGET_ID") then
        return false
    end

    if SL:GetValue("SETTING_AUTO_FIGHT_RANGE_ENABLE") ~= 1 then 
        return 
    end
    local x,y,z = SL:GetValue("AUTO_FIGHT_ORIGIN_POSITION")
    SL:SetMetaValue("AUTO_INPUT_MOVE", SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_AFK, x, y, z)
end

function AutoController:CheckSearchMonsterMove(actCompleted)
    if actCompleted ~= SLDefine.MODEL_ACTION_NAME.ACTION_IDLE 
        and actCompleted ~= SLDefine.MODEL_ACTION_NAME.ACTION_IDLE2 then
        return false
    end

    if not SL:GetValue("BATTLE_IS_AFK") then
        return false
    end

    if SL:GetValue("SELECT_TARGET_ID") then
        return false
    end

    if SL:GetValue("MAP_CURRENT_MOVE_TYPE") == SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_AFK then
        return false
    end

    if SL:GetValue("SETTING_AUTO_FIGHT_RANGE_ENABLE") ~= 0 then 
        return 
    end

    local dX, dY, dZ = FGUIFunction:GetRandomMovePos()
    if dX and dY and dZ then 
        SL:SetValue("BATTLE_IS_AUTO_SEARCH_STATE", true)
        SL:SetValue("AUTO_INPUT_MOVE", SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_AFK, dX, dY, dZ)
    end
    return false
end