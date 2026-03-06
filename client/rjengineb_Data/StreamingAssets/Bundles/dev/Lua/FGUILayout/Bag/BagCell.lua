BagCell = class("BagCell")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local DOUBLE_CLICK_INTERVAL = 0.2
function BagCell.UpdateCellView(itemView,bagData)

    FGUI:setVisible(FGUI:GetChild(itemView, "Lock"), 	bagData._isLock)
    if FGUI:CheckOpen("Bag", "BagRecyclePanel") then
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

function BagCell:ctor(index,itemInstanceData,lock,from)
    self._index = index
    self:SetItem(itemInstanceData)
    self._isLock = lock
    self.from = from or 1
    self.showTip = true
    self.recycleSelect = false
    self._disableDoubleClick = false
end

function BagCell:RefreshData(itemInstanceData)
    self:SetItem(itemInstanceData)
end

function BagCell:SetDoubleClickDisable(enable)
    self._disableDoubleClick = enable
end

function BagCell:SetItem(itemInstanceData)
    self._itemId = itemInstanceData and itemInstanceData.Index or 0
    self._itemData = itemInstanceData
    if not itemInstanceData then
        self:SetRecycleSelect(false)
    end
end

function BagCell:SetCellLock(isLock)
    self._isLock = isLock
end

function BagCell:SetRecycleSelect(recycleSelect)
    self.recycleSelect = self._itemData and recycleSelect or false
end

function BagCell:SetTipEnable(showTip)
    self.showTip = showTip
end

function BagCell:DefaultClickItemEvent()

    SL:onLUAEvent(LUA_EVENT_BAG_CELL_CLICK, self)
    if self.showTip then
        local  tipData = self:GetTipData()
        if tipData then
            FGUIFunction:OpenItemTips(tipData)
        end
    end
    self.showTip = true
end

function BagCell:DoubleClickItemEvent()
    SL:onLUAEvent(LUA_EVENT_BAG_CELL_DOUBLE_CLICK, self)
end
function BagCell:ClickItemEvent()
    if self._itemData then
        if not self._disableDoubleClick then
            if self._scheduleID then
                --双击
                SL:UnSchedule(self._scheduleID)
                self._scheduleID = nil
                self:DoubleClickItemEvent();
                return
            end
            self._scheduleID = SL:ScheduleOnce(function()
                self._scheduleID = nil
                self:DefaultClickItemEvent()
            end,DOUBLE_CLICK_INTERVAL)
        else
            self:DefaultClickItemEvent()
        end
    end
end
function BagCell:ClickCellEvent()
    if  self._isLock then
        print("ClickCell isLock")
    else
        self:ClickItemEvent()
    end
end

function BagCell:GetTipData()
    if  not self._itemId or  self._itemId == 0 then
        return nil
    end
    local data = {}
    data.itemData = self._itemData
    data.from = self.from
    return data
end


function BagCell:GetItemData()
    return self._itemData
end

function BagCell:GetRecycleSelect()
    return self.recycleSelect
end

function BagCell:GetDragIcon()
    return ItemUtil:GetIconResPathByItemID(self._itemData.ID)
end

function BagCell:CopyData(bagCell,copyItem)
    if copyItem then
        self:SetItem(bagCell._itemData)
        self.recycleSelect = bagCell.recycleSelect
    else
        self:SetItem(nil)
    end
    self._index = bagCell._index
    self._isLock = bagCell._isLock
    self.from = bagCell.from

end


