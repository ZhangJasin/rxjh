PCBagCell = class("PCBagCell")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local DOUBLE_CLICK_INTERVAL = 0.2
function PCBagCell.UpdateCellView(itemView,bagData)
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

function PCBagCell:ctor(index,itemInstanceData,lock,from)
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

function PCBagCell:RefreshData(itemInstanceData)
    self:SetItem(itemInstanceData)
end

function PCBagCell:SetDoubleClickDisable(enable)
    self._disableDoubleClick = enable
end

function PCBagCell:SetItem(itemInstanceData)
    self._itemId = itemInstanceData and itemInstanceData.Index or 0
    self._itemData = itemInstanceData
    if not itemInstanceData then
        self:SetRecycleSelect(false)
    end
end

function PCBagCell:SetCellLock(isLock)
    self._isLock = isLock
end

function PCBagCell:SetRecycleSelect(recycleSelect)
    self.recycleSelect = self._itemData and recycleSelect or false
end

function PCBagCell:SetTipEnable(showTip)
    self.showTip = showTip
end

function PCBagCell:SetUseItemEnable(isUse)
    self.useItem = isUse
end

function PCBagCell:RollOverCell()
    if self.showTip then
        local tipData = self:GetTipData()
        if tipData then
            FGUIFunction:OpenItemTips(tipData)
        end
    end

end

function PCBagCell:RollOutCell()
    FGUIFunction:CloseItemTips()
end

function PCBagCell:GetTipData()
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
function PCBagCell:RightClickCell()
    if self._isLock then
        return
    end

    if self.useItem then
        if self._itemData then
            SL:RequestUseItem(self._itemData)
        end
    end
    -- pc端右键操作
    SL:onLUAEvent(LUA_EVENT_BAG_CELL_CLICK, self)
end

function PCBagCell:GetItemData()
    return self._itemData
end

function PCBagCell:GetRecycleSelect()
    return self.recycleSelect
end

function PCBagCell:GetDragIcon()
    return ItemUtil:GetIconResPathByItemID(self._itemData.ID)
end

function PCBagCell:CopyData(PCbagCell,copyItem)
    if copyItem then
        self:SetItem(PCbagCell._itemData)
        self.recycleSelect = PCbagCell.recycleSelect
    else
        self:SetItem(nil)
    end
    self._index = PCbagCell._index
    self._isLock = PCbagCell._isLock
    self.from = PCbagCell.from
end