local PCTreasureStoreItem = {}
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local limitBuyKind = {
    [1] = GET_STRING(30000001),     --每日限购
    [2] = GET_STRING(30000012),     --每周限购
    [3] = GET_STRING(30000011),     --永久限购
    [4] = GET_STRING(30000079),     --每月限购
}

function PCTreasureStoreItem:RefreshItemIcon(item,data)
    local text_name = FGUI:GetChild(item,"text_name")
    local commonItem = FGUI:GetChild(item,"commonItem")
    local text_xiangou = FGUI:GetChild(item,"text_xiangou")
    local isXianGouController = FGUI:getController(item,"isXianGou")
    local com_cost = FGUI:GetChild(item,"com_money")
    local text_count = FGUI:GetChild(com_cost,"text_count")
    local loader_costIcon = FGUI:GetChild(com_cost,"loader_costIcon")

    isXianGouController.selectedIndex = data.Limitbuy and 0 or 1
    local leftCount = 100000
    if data.Limitbuy then
        local arr = string.split(data.Limitbuy,"#")
        local count = tonumber(arr[2])
        leftCount = count
        if data.BuyCount then
            leftCount = count - data.BuyCount
        end
   
        if leftCount <= 0 then
            FGUI:GTextField_setColor(text_xiangou,"#FF0000")
            FGUI:GTextField_setText(text_xiangou,string.format(limitBuyKind[tonumber(arr[1])],0))
        else
            FGUI:GTextField_setColor(text_xiangou,"#FFF7D1")
            FGUI:GTextField_setText(text_xiangou,string.format(limitBuyKind[tonumber(arr[1])],leftCount))
        end
    end

    -- 当金额不足时
    local isMoneyEnough,costType = SL:GetValue("NPC_STORE_GET_ENOUGH_COSTTYPE",data.Costtype,data.Nowprice)
    local costArr = string.split(data.Costtype,"#")
    if not isMoneyEnough then
        -- FGUI:GTextField_setColor(text_count,"#FF0000")
    else
        FGUI:GTextField_setColor(text_count,"#FFF7D1")
    end

    FGUI:GTextField_setText(text_name,data.Desc)
    FGUI:GTextField_setText(text_count,SL:GetThousandSepString(data.Nowprice))

    -- 货币类型
    local path = ItemUtil:GetIconResPathByItemID(SL:GetValue("ITEM_DATA", tonumber(costArr[1])).ID)
    FGUI:GLoader_setUrl(loader_costIcon,path)

    -- 商品ICON
    ItemUtil:RefreshItemUIByData(commonItem,SL:GetValue("ITEM_DATA", data.Itemid))
    -- ItemUtil:AddItemClick(commonItem,SL:GetValue("ITEM_DATA", data.Itemid))
    ItemUtil:SetItemSubScriptByItemID(commonItem,data.Itemid)
    data.OverLap = data.Quantity
    data.isShowCount = data.Quantity > 1
    ItemUtil:SetItemCountByItemData(commonItem,data)
    ItemUtil:UpdateIsShowLockByItemID(commonItem,data)

    FGUI:setOnRollOverEvent(commonItem, function()
        local tipData = {}
        tipData.itemData =  SL:GetValue("ITEM_DATA", data.Itemid)
        tipData.hideCompare = true
        tipData.hideButtons = true
        FGUIFunction:OpenItemTips(tipData)
	end)

    FGUI:setOnRollOutEvent(commonItem, function()
        FGUIFunction:CloseItemTips()
	end)
end






return PCTreasureStoreItem