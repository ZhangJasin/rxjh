AutoFindDropItem = class("AutoFindDropItem")

local function diffLen(x, y)
    return math.max(math.abs(x), math.abs(y))
end

function AutoFindDropItem:FindItems(isAFK)
    self._isAFK = isAFK
    local pMapX = math.floor(SL:GetValue("ACTOR_MAP_X"))
    local pMapY = math.floor(SL:GetValue("ACTOR_MAP_Y"))
    local pMapZ = math.floor(SL:GetValue("ACTOR_MAP_Z"))
    -- find target
    local targetID = nil
    local targets = {}
    local pickLen = nil
    local currPickLen = 0
    local targetCount = 0
    local targetRange = SL:GetValue("GAME_DATA", "FindRange_DropItem") 
    local dropItemIDVec, dropItemCount = SL:GetValue("FIND_DROP_ITEM_LIST_SORT_BY_RANGE", pMapX, pMapZ, targetRange)
    for i = 1, dropItemCount do
        local dropItemID = dropItemIDVec[i]
        if self:IsPickable(dropItemID) then
            -- for random pick nearest item
            local diffX = SL:GetValue("ACTOR_MAP_X", dropItemID) - pMapX
            local diffZ = SL:GetValue("ACTOR_MAP_Z", dropItemID) - pMapZ
            currPickLen = diffLen(diffX, diffZ)
            if pickLen then
                if currPickLen > pickLen then
                    break
                end
            end

            pickLen              = currPickLen
            targetCount          = targetCount + 1
            targets[targetCount] = dropItemID
        end
    end

    -- random drop item
    if targetCount > 0 then
        local targetIndex = Random(targetCount)
        targetID = targets[targetIndex]
    end

    if targetID then
        local targetX = SL:GetValue("ACTOR_MAP_X", targetID)
        local targetZ = SL:GetValue("ACTOR_MAP_Z", targetID)
        local targetY = SL:GetValue("MAP_Y", targetX, targetZ)
        -- record pick item ID
        SL:SetValue("PICK_ITEM_ID", targetID)
        if not (targetX == pMapX and targetZ == pMapZ and targetY == pMapY) then
            SL:SetValue("AUTO_INPUT_MOVE",SLDefine.INPUT_MOVETYPE.INPUT_MOVE_TYPE_FINDITEM,  targetX, targetY, targetZ)
        end
        SL:SetValue("PICK_BEGIN_TIME", SL:GetValue("SERVER_TIME"))
    else
        -- oh, can't find drop
        SL:SetValue("PICK_ITEM_ID", nil)
        SL:SetValue("PICK_ITEM_ABLE", false)
        SL:SetValue("PICK_BEGIN_TIME", nil)
    end
end

function AutoFindDropItem:IsPickable(dropItemID)
    if not dropItemID then
        return false
    end

    -- check pick state
    if not SL:GetValue("DROPITEM_PICK_MARK", dropItemID) then
        return false
    end

    if self._isAFK then 
        if SL:GetValue("DROPITEM_IS_PICK_TIMEOUT", dropItemID) then 
            return false
        end
        --范围挂机 只拾取范围内的物品
        if SL:GetValue("SETTING_AUTO_FIGHT_RANGE_ENABLE") then 
            local targetX = SL:GetValue("ACTOR_POSITION_X", dropItemID)
            local targetZ = SL:GetValue("ACTOR_POSITION_Z", dropItemID)
            if not SL:GetValue("CHECK_IN_AUTO_ATK_RANGE", targetX, targetZ) then 
                return false
            end
        end 
    end

    if self._isAFK then 
        -- check owner
        if not FGUIFunction:CheckDropItemAutoPick(dropItemID) then
            return false
        end
    else 
        if FGUIFunction.CheckDropItemPick then 
            local res, failCode = FGUIFunction:CheckDropItemPick(dropItemID) 
            if not res then 
                return res, failCode
            end
        end
    end
    return true
end