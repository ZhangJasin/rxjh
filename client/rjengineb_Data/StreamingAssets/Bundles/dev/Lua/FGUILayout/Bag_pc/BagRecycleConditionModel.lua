local BagRecycleConditionModel = class("BagRecycleConditionModel")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function BagRecycleConditionModel:ctor(cfg)
    self.isSelect = false
    self.cfg = cfg
end

function BagRecycleConditionModel:Toggle()
    self.isSelect = not self.isSelect

end

function BagRecycleConditionModel:GetCheckBoxName()
    return self.cfg and self.cfg.Name or ""
end

function BagRecycleConditionModel:CheckItemValid(itemCfg)
    local itemType = self:GetItemType(itemCfg)
    local typeValid = self:CheckItemTypeValid(itemType)
    if typeValid then
        if self.cfg.ConditionType == 1 then
            local lvValid = self:CheckItemNeedLevelValid(itemCfg)
            return lvValid
        elseif self.cfg.ConditionType == 2 then
            local gradeValid = self:CheckItemGradeValid(itemCfg)
            return gradeValid
        elseif self.cfg.ConditionType == 3 then
            local jewelryValid = self:CheckItemJewelryValid(itemCfg)
            return jewelryValid
        elseif self.cfg.ConditionType == 4 then
            local jobValid = not ItemUtil:CheckJob(itemCfg)
            return jobValid
        elseif self.cfg.ConditionType == 5 then
            local upperLvValid = self:CheckUpperLvValid(itemCfg)
            return upperLvValid
        elseif self.cfg.ConditionType == 6 then
            local MedValid = self:CheckMedValid(itemCfg)
            return MedValid
        end
    end
    return false
end
function BagRecycleConditionModel:CheckItemTypeValid(itemType)
    for i = 1, #self.cfg.Effect do
        if self.cfg.Effect[i] == itemType then
            return true
        end
    end
end

function BagRecycleConditionModel:CheckItemNeedLevelValid(itemCfg)
    local minLv = self.cfg.Condition[1]
    local maxLv = self.cfg.Condition[2]
    return itemCfg.NeedLevel > minLv and itemCfg.NeedLevel <= maxLv
end

function BagRecycleConditionModel:CheckItemGradeValid(itemCfg)
    local g = self.cfg.Condition
    local res = itemCfg.Grade or 0
    return res == g
end

function BagRecycleConditionModel:CheckItemJewelryValid(itemCfg)

    for i = 1, #self.cfg.Condition do
        if itemCfg.StdMode == self.cfg.Condition[i] then
            return true
        end
    end
end
function BagRecycleConditionModel:CheckUpperLvValid(itemCfg)
    return itemCfg.NeedLevel > SL:GetValue("LEVEL")
end
function BagRecycleConditionModel:CheckMedValid(itemCfg)
    for i = 1, #self.cfg.Condition do
        if itemCfg.ID == self.cfg.Condition[i] then
            return true
        end
    end
end

function BagRecycleConditionModel:CheckStoneValid(stoneId, bagDataCfg)
    if self.cfg.StoneId == stoneId then
        if self.cfg.ConditionType == 8 then
            --dump(bagDataCfg)
            for i, v in ipairs(self.cfg.Condition) do
                if v and v[1] and bagDataCfg[2] and bagDataCfg[3] then
                    if v[1] == bagDataCfg[2] and v[2] == bagDataCfg[3] then
                        --print("找到", stoneId)
                        --print(bagDataCfg[2])
                        --print(bagDataCfg[3])
                        return true
                    end
                end
            end
        elseif self.cfg.ConditionType == 9 then
            if stoneId == self.cfg.Condition then
                return true
            end
        end
    end
    return false
end

function BagRecycleConditionModel:GetItemType(itemCfg)
    if ItemUtil:IsEquip(itemCfg) then
        return 1
    else
        return 2
    end
end
return  BagRecycleConditionModel