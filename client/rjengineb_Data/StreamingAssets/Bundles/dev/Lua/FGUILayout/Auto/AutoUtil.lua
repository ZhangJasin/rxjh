local AutoUtil = class('AutoUtil')
local mAbs = math.abs
local mMin = math.min
-- 四周是否有足够的敌人（人物）
function AutoUtil.CheckIsEnoughEnemyPlayer(targetID, count, distance)
    local enoughCount = tonumber(count) or 3
    local count = 0
    local actors, actorNums = SL:GetValue("FIND_IN_VIEW_PLAYER_LIST")
    local pMapX = SL:GetValue("ACTOR_MAP_X", targetID)
    local pMapY = SL:GetValue("ACTOR_MAP_Y", targetID)
    distance    = distance or 2 -- 多少格之内

    for i = 1, actorNums do
        local actorID = actors[i]
        if actorID and not SL:GetValue("ACTOR_IS_HUMAN", actorID) then
            local actorMapX = SL:GetValue("ACTOR_MAP_X", actorID)
            local actorMapY = SL:GetValue("ACTOR_MAP_Y", actorID)
            
            if mAbs(actorMapX - pMapX) <= distance and mAbs(actorMapY - pMapY) <= distance and SL:GetValue("ACTOR_IS_ENEMY", actorID) then
                count = count + 1
            end
            if count >= enoughCount then
                return true
            end
        end
    end
    
    return false
end

-- 四周是否有足够的红名（人物）
function AutoUtil.CheckIsEnoughPKPlayer(targetID, count, distance)
    local enoughCount = tonumber(count) or 3
    local count = 0
    local actors, actorNums = SL:GetValue("FIND_IN_VIEW_PLAYER_LIST")
    local pMapX = SL:GetValue("ACTOR_MAP_X", targetID)
    local pMapY = SL:GetValue("ACTOR_MAP_Y", targetID)
    distance    = distance or 2 -- 多少格之内

    for i = 1, actorNums do
        local actorID = actors[i]
        if actorID and not SL:GetValue("ACTOR_IS_HUMAN", actorID) then
            local actorMapX = SL:GetValue("ACTOR_MAP_X", actorID)
            local actorMapY = SL:GetValue("ACTOR_MAP_Y", actorID)
            
            if mAbs(actorMapX - pMapX) <= distance and mAbs(actorMapY - pMapY) <= distance and SL:GetValue("ACTOR_PKVALUE", actorID) > 0 then
                count = count + 1
            end
            if count >= enoughCount then
                return true
            end
        end
    end
    
    return false
end

-- 四周是否有足够的敌人（人物）取最近的
function AutoUtil.CheckIsEnoughEnemyNearerPlayer(targetID, count, distance)
    local enoughCount = tonumber(count) or 3
    local count = 0
    local actors, actorNums = SL:GetValue("FIND_IN_VIEW_PLAYER_LIST")
    local pMapX = SL:GetValue("ACTOR_MAP_X", targetID)
    local pMapY = SL:GetValue("ACTOR_MAP_Y", targetID)
    distance    = distance or 2 -- 多少格之内
    local actorID = nil
    local min = 9999
    for i = 1, actorNums do
        local actorID = actors[i]
        if actorID and not SL:GetValue("ACTOR_IS_HUMAN", actorID) then
            local actorMapX = SL:GetValue("ACTOR_MAP_X", actorID)
            local actorMapY = SL:GetValue("ACTOR_MAP_Y", actorID)
            local disX = mAbs(actorMapX - pMapX)
            local disY = mAbs(actorMapY - pMapY)
            if disX <= distance and disY <= distance and SL:GetValue("ACTOR_IS_ENEMY", actorID) then
                count = count + 1
                local disMin = mMin(disX, disY)
                if disMin < min then 
                    min = disMin
                    actorID = actorID
                end
            end
        end
    end
    if count >= enoughCount then
        return true, actorID
    end
    return false
end
return AutoUtil
