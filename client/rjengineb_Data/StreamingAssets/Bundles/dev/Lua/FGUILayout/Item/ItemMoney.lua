local ItemBase = SL:RequireFile("FGUILayout/Item/ItemBase")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemMoney = class("ItemMoney",ItemBase)

function ItemMoney:ctor(component,data)
    self.super.ctor(self,component)
    self._itemData = data
    self:UpdateUI(false)
end

function ItemMoney:UpdateItemData(data)
    if data then
        self._itemData = data
    end
    self:UpdateUI(false)
end

function ItemMoney:UpdateUI(isShow)
    self:UpdateIcon()
    self:UpdateItemGrade()
    self:UpdateItemCounts()
    self:UpdateItemGradeIsShow(isShow)
    self:UpdateItemClick()
end

function ItemMoney:UpdateIsShowLock()
    ItemUtil:UpdateIsShowLockByItemID(self.component,self._itemData)
end

return ItemMoney