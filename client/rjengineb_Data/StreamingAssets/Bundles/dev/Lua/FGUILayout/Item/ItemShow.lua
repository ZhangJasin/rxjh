local ItemBase = SL:RequireFile("FGUILayout/Item/ItemBase")
local ItemShow = class("ItemShow",ItemBase)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function ItemShow:ctor(component,data)
    self.super:ctor(component)
    if data then
        self:UpdateUIByData(data)
    end
end

-- 更新UI
function ItemShow:UpdateUI(extData)
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
    self:UpdateIsShowLock()
    self:AddEffectToItem()
    self:UpdateItemTipInAndOut()
end

-- 更新数据
function ItemShow:UpdateUIByData(data,extData)
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

-- 数量是否显示
function ItemShow:UpdateCountVisible(isShow)
    self:UpdateItemCounts(isShow)
end

-- 品质框是否显示
function ItemShow:UpdateGradeIsShow(isShow)
    self:UpdateItemGradeIsShow(isShow)
end

-- 是否显示锁(根据ID过滤)
function ItemShow:UpdateIsShowLock()
    ItemUtil:UpdateIsShowLockByItemID(self._component,self._itemData)
end

-- 是否显示锁直接控制
function ItemShow:SetLockedIsShow(isShow)
    ItemUtil:SetLockedIsShow(self._component,isShow)
end

-- 是否置灰ICON
function ItemShow:SetIconGray(isGray)
    ItemUtil:SetIconGray(self._component,isGray)
end

-- 是否显示CD
function ItemShow:UpdateCD()
    local endTime =  SL:GetValue("ITEM_CD_ENDTIME",self._itemData.ID)
    local useTime = SL:GetValue("ITEM_CD_USETIME",self._itemData.ID)
    if self.cdEndTime  == endTime then
        return
    end

    self.cdEndTime = endTime
    local timeDis
    if self.cdEndTime then
        timeDis = self.cdEndTime - SL:GetValue("SERVER_TIME")
    end
    
    if self.cdMask then
        self.cdMask:Clean()
        if timeDis <= 0 then
            return
        end
        self.cdMask:UpdateTime(timeDis,self.cdEndTime - useTime)
        self.cdMask:DoCD()
    else
        self.cdMask = SL:CreateCDMask(self._component,timeDis,self.cdEndTime - useTime,1,true,true)
    end
end

return ItemShow