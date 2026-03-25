local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemBase = class("ItemBase")
local _PetEquipPos = {           -- 宠物装备位置
    ["灵兽利爪"]  = 0,    
    ["灵兽护具"]  = 1,    
    ["灵兽系带"]  = 2,    
    ["灵兽兽环"]  = 3,    
}
local DOUBLE_CLICK_INTERVAL = 0.2
function ItemBase:ctor(component)
    self:Init(component)
    self:CleanData()
end

function ItemBase:Init(component)
    self._component  = component
end
-- 处理数据
function ItemBase:CleanData()
    self._hideTip                                           = false
    self._itemTipData                                       = nil
    self._clickCallback                                     = nil
    self._doubleClickCallback                               = nil
    self._countFontColor                                    = nil
    self._countOutlineColor                                 = nil
    self._countOutlineSize                                  = nil
    self._bgVisible                                         = true
    self._itemCount                                         = 1
    self._isShowCount                                       = false
end

-- 清理定时器
function ItemBase:CleanSchedule()
    if self._scheduleID then        --双击定时器
        SL:UnSchedule(self._scheduleID)
    end
    self._scheduleID = nil
end

-- 清理点击回调
function ItemBase:CleanClickCallBack()
    FGUI:setOnClickEvent(self._component,nil)
    FGUI:setOnRightClickEvent(self._component,nil)
    FGUI:setOnRollOverEvent(self._component,nil)
    FGUI:setOnRollOutEvent(self._component,nil)
end

-- 回池操作初始化
function ItemBase:Clean()
    self:CleanData()
    self:CleanSchedule()
    self:CleanClickCallBack()
end

--extData参数
--extData.hideTip 是否隐藏默认的Tip
--extData.itemTipData table类型，对应ItemTips.ShowTip传入的参数
--extData.clickCallback 单击事件回调
--extData.doubleClickCallback 双击事件回调
--extData.countFontColor 数量字体颜色
--extData.CountOutlineColor 数量字体描边
--extData.bgVisible 背景隐藏
--extData.OverLap 道具数量
function ItemBase:UpdateItemConfig(extData)
    if not extData then
        return
    end
    self._hideTip = extData.hideTip

    if extData.itemTipData then
        self._itemTipData = extData.itemTipData
    end

    if extData.clickCallback then
        self._clickCallback = extData.clickCallback
    end

    if extData.doubleClickCallback then
        self._doubleClickCallback = extData.doubleClickCallback
    end

    if extData.countFontColor then
        self._countFontColor = extData.countFontColor
    end

    if extData.CountOutlineColor then
        self._countOutlineColor = extData.CountOutlineColor
        self._countOutlineSize = extData.CountOutlinesize or 1
    end

    self._bgVisible = extData.bgVisible == nil and true or extData.bgVisible

    if extData.OverLap then
        self._itemCount = extData.OverLap
    end
end

function ItemBase:RefreshItemUIByData()
    self:UpdateIcon()
    self:UpdateItemGrade()
    self:UpdateItemCounts()
    self:SetItemSubScriptByItemID()
    local isequip = SL:GetValue("BAG_ITEM_IS_EQUIP", self._itemData, itemData.ID)
    if isequip or _PetEquipPos[self._itemData.StdName] then
        ItemUtil:SetEquipQHByItemData(self._component,self._itemData)  --装备强化
    else
        -- 清理合成点显示
        ItemUtil:ClearHCDShow(self._component)
    end
end

-- 是否显示数量
function ItemBase:UpdateItemCounts(p_isShow)
    local text_count = FGUI:GetChild(self._component, "Text_count")
    if not text_count then
        return
    end

    if p_isShow ~= nil then
        ItemUtil:SetItemCountVisible(self._component, p_isShow)
        ItemUtil:UpdateItemCount(text_count, self._itemCount)
    else
        local isShow = self._itemCount and self._itemCount > 1
        ItemUtil:SetItemCountVisible(self._component, isShow)
        ItemUtil:UpdateItemCount(text_count, self._itemCount)
    end
end

function ItemBase:UpdateIcon()
    ItemUtil:SetItemIconByItemID(self._component,self._itemData.ID)
end

function ItemBase:UpdateItemGrade()
    ItemUtil:UpdateItemGradeByItemID(self._component,self._itemData.ID)
end

-- 显示Subscript文本内容
function ItemBase:UpdateSubscript()
    ItemUtil:SetItemSubScriptByItemID(self._component,self._itemData.ID)
    local isequip = SL:GetValue("BAG_ITEM_IS_EQUIP", self._itemData, self._itemData.ID)
    if isequip or _PetEquipPos[self._itemData.StdName] then
        ItemUtil:SetEquipQHByItemData(self._component,self._itemData)
    else
        -- 清理合成点显示
        ItemUtil:ClearHCDShow(self._component)
    end
    
end

function ItemBase:UpdateItemStar()
    ItemUtil:SetItemStarByItemData(self._component, self._itemData)
end

function ItemBase:DefaultEvent(context)
    if  self._clickCallback then
        self._clickCallback(context)
    end
    if not self._hideTip then
        self:ShowTips()
    end
end

function ItemBase:ShowTips()
    local tipData = self._itemTipData or {}
    tipData.itemData = self._itemData
    FGUIFunction:OpenItemTips(tipData)
end

function ItemBase:OnClickEvent(context)
    if self._doubleClickCallback then
        if self._scheduleID then
            --双击
            SL:UnSchedule(self._scheduleID)
            self._scheduleID = nil
            self._doubleClickCallback(context)
            return
        end
        self._scheduleID = SL:ScheduleOnce(function()
            self._scheduleID = nil
            self:DefaultEvent(context)
        end,DOUBLE_CLICK_INTERVAL)
    else
        self:DefaultEvent(context)
    end
end

function ItemBase:UpdateItemClick(extData)
    if extData and extData.disableClick then
        self:RemoveItemClick()
        return
    end
    self:AddItemClick()
end


function ItemBase:AddItemClick()
    FGUI:setOnClickEvent(self._component,handler(self, self.OnClickEvent))
end

function ItemBase:addClickEvent(callback)
    self._clickCallback = callback
end

function ItemBase:addDoubleClickEvent(callback)
    self._doubleClickCallback = callback
end

function ItemBase:RemoveItemClick()
    ItemUtil:RemoveItemClick(self._component)
end

function ItemBase:UpdateItemGradeIsShow(isShow)
    ItemUtil:SetItemGradeVisible(self._component,isShow)
end

function ItemBase:SetIconGray(isGray)
    ItemUtil:SetIconGray(self._component,isGray)
end


-- 设置数量字体的颜色
function ItemBase:SetCountTextFontColor()
    if not self._countFontColor then
        return
    end
    ItemUtil:SetCountTextFontColor(self._component,self._countFontColor)
end

-- 设置数量字体的颜色
function ItemBase:SetCountTextOutLine()
    if not self._countOutlineColor then
        return
    end

    ItemUtil:SetCountTextOutLine(self._component,self._countOutlineColor,self._countOutlineSize)
end

-- 根据配置是否显示背景
function ItemBase:SetBgVisbleByExtDataConfig()
    self:UpdateItemGradeIsShow(self._bgVisible)
end


return ItemBase