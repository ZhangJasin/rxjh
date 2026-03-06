AutoFindTarget = class("AutoFindTarget")

local function squLen(x, y)
    return x * x + y * y
end

function AutoFindTarget:FindTarget(range, findFriend, isAFK)
    self._targetVec = self._targetVec or {}
    local targetID = nil
    self._targetVecCount = 0
    self._range = range
    self._findFriend = findFriend
    self._isAFK = isAFK

    local findTargetMode = SL:GetValue("SETTING_FIND_TARGET_MODE")
    if findTargetMode == SLDefine.FIND_TARGET_MODE.PRIORITY_MONSTER then--优先怪物
        self:FindMonster()
        if self._targetVecCount == 0 then
            self:FindPlayer()
        end
        targetID = self:FindNearestTarget()
    elseif findTargetMode == SLDefine.FIND_TARGET_MODE.PRIORITY_PLAYER then--优先玩家
        self:FindPlayer()
        if self._targetVecCount == 0 then
            self:FindMonster()
        end
        targetID = self:FindNearestTarget()
    elseif findTargetMode == SLDefine.FIND_TARGET_MODE.ONLY_PLAYER then --只找玩家
        self:FindPlayer()
        targetID = self:FindNearestTarget()
    end

    if targetID then
        SL:SetValue("SELECT_TARGET_ID", targetID, SLDefine.SELECT_TARGET.SYSTEM)
    end
end

function AutoFindTarget:FindNearestTarget()
    if self._targetVecCount == 0 then
        return nil
    end

    local cost = SLDefine.MAX_CONST
    local pX,pZ = SL:GetValue("MAP_PLAYER_POS")
    local nearestTargetID = nil
    local targetID = nil
    local targetX = nil
    local targetZ = nil
    for i = 1, self._targetVecCount do
        targetID = self._targetVec[i]
        targetX = SL:GetValue("ACTOR_POSITION_X", targetID)
        targetZ = SL:GetValue("ACTOR_POSITION_Z", targetID)
        local len = squLen(targetX - pX, targetZ - pZ)
        if len < cost then
            nearestTargetID = targetID
            cost = len
        end
    end

    return nearestTargetID, cost
end

function AutoFindTarget:FilterTarget(targetVec)
    if not targetVec then 
        return
    end
    for _, targetID in pairs(targetVec) do
        repeat
            if self._findFriend then
                if FGUIFunction:CheckIsFriendByID(targetID) 
                    and self:CheckRange(targetID) 
                    and SL:GetValue("ACTOR_IS_CAN_SELECT", targetID)
                    then
                        self._targetVecCount = self._targetVecCount + 1
                        self._targetVec[self._targetVecCount] = targetID
                end
            else
                if self:CheckAttack(targetID) 
                    and self:CheckRange(targetID) 
                    and SL:GetValue("ACTOR_IS_CAN_SELECT", targetID)
                    then
                        self._targetVecCount = self._targetVecCount + 1
                        self._targetVec[self._targetVecCount] = targetID
                end
            end
        until true
    end
end

function AutoFindTarget:FindPlayer()
    --有要寻找的类型的怪
    local isTargetSet = false
    local targetIndex = SL:GetValue("AUTO_TARGET_INDEX")
    if targetIndex then 
        if type(targetIndex) == "table" then  
            if next(targetIndex) then
                isTargetSet = true
            end
        else 
            isTargetSet = true
        end
    end

    if isTargetSet then 
        return
    end
    
    local playerVec = SL:GetValue("FIND_IN_VIEW_PLAYER_LIST", true)
    self:FilterTarget(playerVec)
end

function AutoFindTarget:FindMonster()
    --有要寻找的类型的怪
    local isTargetSet = false
    local targetIndex = SL:GetValue("AUTO_TARGET_INDEX")
    if targetIndex then 
        if type(targetIndex) == "table" then  
            if next(targetIndex) then
                isTargetSet = true
            end
        else 
            isTargetSet = true
        end
    end

    local monsterVec = nil
    if isTargetSet then 
        -- 筛选所有能自动攻击的怪物
        -- 先找目标类型怪物
        if type(targetIndex) == "number" then
            monsterVec = SL:GetValue("FIND_IN_VIEW_MONSTER_LIST_BY_TYPEINDEX", targetIndex, true, true)
        elseif type(targetIndex) == "table" then
            monsterVec = SL:GetValue("FIND_IN_VIEW_MONSTER_LIST_BY_TYPEINDEX_TABLE", targetIndex, true, true)
        end
        if #monsterVec <= 0  then
            monsterVec = SL:GetValue("FIND_IN_VIEW_MONSTER_LIST")
        end
    else 
        monsterVec = SL:GetValue("FIND_IN_VIEW_MONSTER_LIST")
    end
    
    self:FilterTarget(monsterVec)
end

function AutoFindTarget:CheckRange(targetID)
    if self._isAFK then 
        if SL:GetValue("SETTING_AUTO_FIGHT_RANGE_ENABLE") == 1 then 
            local targetX = SL:GetValue("ACTOR_POSITION_X", targetID)
            local targetZ = SL:GetValue("ACTOR_POSITION_Z", targetID)
            return SL:GetValue("CHECK_IN_AUTO_ATK_RANGE", targetX, targetZ)
        end 
    end
    
    if self._range then 
        local distance = SL:GetValue("TARGET_DISTANCE_FROM_ME",targetID)
        return distance <= self._range 
    end
    
    return true
end

--检测能否攻击 
function AutoFindTarget:CheckAttack(targetID)
    if not SL:GetValue("TARGET_ATTACK_ENABLE",targetID) then 
        return false
    end
    --不选有主人的
    if SL:GetValue("ACTOR_HAVE_MASTER",targetID) then 
        return false
    end

    if self._isAFK then 
        --不抢怪
        if SL:GetValue("SETTING_AVOID_CONFLICT_TARGET") then
            --归属
            local ownerID = SL:GetValue("ACTOR_OWNER_ID", targetID) 
            -- 不是我的归属 && 不是队友的归属
            if ownerID and not (ownerID == SL:GetValue("MAIN_PLAYER_ID") or SL:GetValue("TEAM_IS_MEMBER", ownerID))  then
                return false
            end
        end
    end
    --
    return true
end
