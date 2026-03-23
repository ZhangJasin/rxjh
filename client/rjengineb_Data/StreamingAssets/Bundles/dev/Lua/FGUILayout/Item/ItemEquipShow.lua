local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemEquipShow = class("ItemEquipShow",ItemShow)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function ItemEquipShow:ctor(component,data)
    self.super:ctor(component)
    self.ctrl_arrowType = FGUI:getController(component,"arrowType")
    self:SetArrowByIndex(3)
    if data then
        self:UpdateUIByData(data)
    end
end

function ItemEquipShow:SetArrowByIndex(index)
    if not self.ctrl_arrowType then
       return
    end
    
    self.ctrl_arrowType.selectedIndex = index
end

function ItemEquipShow:UpdateUI(extData)
    self:UpdateItemConfig(extData)
    self:UpdateIcon()
    self:UpdateItemGrade()
    self:UpdateItemCounts()
    self:UpdateItemClick(extData)
    self:UpdateSubscript()
    self:UpdateItemStar()
    self:SetCountTextFontColor()
    self:SetCountTextOutLine()
    self:SetBgVisbleByExtDataConfig()
    self:CheckArrowIsShow()
    self:UpdateIsShowLock()
    self:AddEffectToItem()
    self:UpdateItemTipInAndOut()
end

function ItemEquipShow:UpdateUIByData(data,extData)
    if not data then
       return
    end

    self._itemData = data
    -- 服务器数据(服务器数据会带Index)
    if self._itemData.Index then
        self._itemData.ID = self._itemData.Index
        if self._itemData.OverLap then
            if not extData then
                extData = {}
                extData.OverLap = self._itemData.OverLap
            else
                extData.OverLap = self._itemData.OverLap
            end
        end
    end

    self:UpdateUI(extData)
end

-- 是否显示锁(根据ID过滤)
function ItemShow:UpdateIsShowLock()
    ItemUtil:UpdateIsShowLockByItemID(self._component,self._itemData)
end

function ItemEquipShow:hideArrow()
    self:SetArrowByIndex(3)
end

function ItemEquipShow:CheckArrowIsShow()

    if not self._itemData then
        return
    end

    -- 装备在身上不显示
    if SL:CheckItemIsFromPlayerEquip(self._itemData.MakeIndex) then
        self:SetArrowByIndex(3)
        return
    end

    local param1,param2,param3 = FGUIFunction:CompareEquipUpShowOnBody(self._itemData)
    if param1 == true then
        self:SetArrowByIndex(0) -- 绿色
    elseif param1 == false and param2 == false and param3 == true then
        self:SetArrowByIndex(1) -- 蓝色
    elseif param1 == false and param2 == true then
        self:SetArrowByIndex(2) -- 黄色
    else
        self:SetArrowByIndex(3)
    end
end

return ItemEquipShow