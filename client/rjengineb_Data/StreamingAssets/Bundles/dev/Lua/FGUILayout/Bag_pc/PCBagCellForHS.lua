PCBagCellForHS = class("PCBagCellForHS")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local DOUBLE_CLICK_INTERVAL = 0.2
function PCBagCellForHS.UpdateCellView(itemView,bagData)
    FGUI:setVisible(FGUI:GetChild(itemView, "Lock"), bagData._isLock)
    if FGUI:CheckOpen("Bag_pc", "BagRecyclePanel") then
        FGUI:setVisible(FGUI:GetChild(itemView, "RecycleSelect"),bagData.recycleSelect)
    else
        FGUI:setVisible(FGUI:GetChild(itemView, "RecycleSelect"),false)
    end

    local  c = FGUI:getController(itemView,"BagItemType")
    if not bagData._itemId or bagData._itemId == 0 then
        FGUI:Controller_setSelectedIndex(c,0)
        return
    end
    local itemData = bagData._itemData
    if not bagData._itemData then
        FGUI:Controller_setSelectedIndex(c,0)
        return
    end

    FGUI:Controller_setSelectedIndex(c,1)

    return itemData
end

function PCBagCellForHS:ctor(index,itemInstanceData,lock,from)
    self._index = index
    self:SetItem(itemInstanceData)
    self._isLock = lock
    self.from = from or 1
    self.showTip = true
    self.recycleSelect = false
    self._disableDoubleClick = false
    -- 使用或者穿戴
    self.useItem = true
end

function PCBagCellForHS:RefreshData(itemInstanceData)
    self:SetItem(itemInstanceData)
end

function PCBagCellForHS:SetDoubleClickDisable(enable)
    self._disableDoubleClick = enable
end

function PCBagCellForHS:SetItem(itemInstanceData)
    self._itemId = itemInstanceData and itemInstanceData.Index or 0
    self._itemData = itemInstanceData
    if not itemInstanceData then
        self:SetRecycleSelect(false)
    end
end

function PCBagCellForHS:SetCellLock(isLock)
    self._isLock = isLock
end

function PCBagCellForHS:SetRecycleSelect(recycleSelect)
    self.recycleSelect = self._itemData and recycleSelect or false
end

function PCBagCellForHS:SetTipEnable(showTip)
    self.showTip = showTip
end

function PCBagCellForHS:SetUseItemEnable(isUse)
    self.useItem = isUse
end

function PCBagCellForHS:RollOverCell()
    if self.showTip then
        local tipData = self:GetTipData()
        if tipData then
            FGUIFunction:OpenItemTips(tipData)
        end
    end

end

function PCBagCellForHS:RollOutCell()
    FGUIFunction:CloseItemTips()
end

function PCBagCellForHS:GetTipData()
    if not self._itemId or  self._itemId == 0 then
        return nil
    end
    local data = {}
    data.itemData = self._itemData
    data.from = self.from
    data.hideButtons = true
    return data
end

-- 右键点击cell
function PCBagCellForHS:RightClickCell()
    if  FGUI:CheckOpen("Bag_pc", "BagRecyclePanel") then
        return SL:onLUAEvent(LUA_EVENT_BAG_CELL_CLICK, self)
	end
end
function PCBagCellForHS:ClickCellEvent()
    if  FGUI:CheckOpen("Bag_pc", "BagRecyclePanel") then
        return SL:onLUAEvent(LUA_EVENT_BAG_CELL_CLICK, self)
	end
end

function PCBagCellForHS:GetItemData()
    return self._itemData
end

function PCBagCellForHS:GetRecycleSelect()
    return self.recycleSelect
end

function PCBagCellForHS:GetDragIcon()
    return ItemUtil:GetIconResPathByItemID(self._itemData.ID)
end

function PCBagCellForHS:CopyData(PCBagCellForHS,copyItem)
    if copyItem then
        self:SetItem(PCBagCellForHS._itemData)
        self.recycleSelect = PCBagCellForHS.recycleSelect
    else
        self:SetItem(nil)
    end
    self._index = PCBagCellForHS._index
    self._isLock = PCBagCellForHS._isLock
    self.from = PCBagCellForHS.from
end