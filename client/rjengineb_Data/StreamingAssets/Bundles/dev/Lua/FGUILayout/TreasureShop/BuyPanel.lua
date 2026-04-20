local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local BuyPanel = class("BuyPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local limitBuyKind = {
    [1] = GET_STRING(30000057),     --每日限购
    [2] = GET_STRING(30000058),     --每周限购
    [3] = GET_STRING(30000059),     --永久限购
    [4] = GET_STRING(30000080),     --每月限购
}

function BuyPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self.cache_icon_item_list = {}
    self.cache_money_item_list = {}

    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitUI()
end

function BuyPanel:GetAllFGuiData()
    self.list_buy = self._ui.list_buy
    self.ctrl_isHaveStore = FGUI:getController(self.component,"isHaveStore")
end

function BuyPanel:InitOnClickEvent()
end

function BuyPanel:RefreshDataAndList()
    self.storeData = SL:GetValue("NPC_STORE_DATA_BY_GROUPID",self.groupID)
    self.storeData = self:SortStoreItem(self.storeData)
    local nums = table.nums(self.storeData)
    FGUI:Controller_setSelectedIndex(self.ctrl_isHaveStore, nums > 0 and 1 or 0)
    FGUI:GList_setNumItems(self.list_buy,nums)
end

function BuyPanel:InitUI()
    FGUI:GList_itemRenderer(self.list_buy,handler(self,self.BuyItemRender))
    FGUI:GList_setVirtual(self.list_buy)
    FGUI:GList_addOnClickItemEvent(self.list_buy,handler(self,self.BuyItemClicked))
end

function BuyPanel:CleanItemCache()
    for k,v in pairs(self.cache_icon_item_list) do
        if v then 
            ItemUtil:ItemShow_Release(v)
        end
    end

    for k,v in pairs(self.cache_money_item_list) do
        if v then 
            ItemUtil:ItemShow_Release(v)
        end
    end

    self.cache_icon_item_list = {}
    self.cache_money_item_list = {}
end

function BuyPanel:BuyItemRender(idx, item)
    local data = self.storeData[ idx + 1 ]
    if data then
        local itemData = SL:GetValue("ITEM_DATA",data.Itemid)
        -- 名字
        local s_text_name = FGUI:GetChild(item,"s_text_name")
        FGUIFunction:ScrollText_setString(s_text_name, itemData.Name,0.5, 0)
        -- 限购
        local s_text_des = FGUI:GetChild(item,"s_text_des")
        local leftCount = 100000
        if data.Limitbuy then
            local arr = string.split(data.Limitbuy,"#")
            local count = tonumber(arr[2])
            leftCount = count
            if data.BuyCount then
                leftCount = count - data.BuyCount
            end

            if leftCount <= 0 then
                FGUIFunction:ScrollText_setString(s_text_des, string.format(limitBuyKind[tonumber(arr[1])],0),0.5, 0)
            else
                FGUIFunction:ScrollText_setString(s_text_des, string.format(limitBuyKind[tonumber(arr[1])],leftCount),0.5, 0)
            end
        else
            FGUIFunction:ScrollText_setString(s_text_des, GET_STRING(30000056),0.5, 0,{strokeColor = "#000000",strokeSize = 1})
        end

        -- 当金额不足时
        local isMoneyEnough,costType = SL:GetValue("NPC_STORE_GET_ENOUGH_COSTTYPE",data.Costtype,data.Nowprice)
		local costArr = string.split(data.Costtype,"#")
        local text_cost_count = FGUI:GetChild(item,"text_cost_count")
        FGUI:GTextField_setText(text_cost_count, SL:GetThousandSepString(data.Nowprice))
        if not isMoneyEnough then
            FGUI:GTextField_setColor(text_cost_count,"#FF0000")
        else
            FGUI:GTextField_setColor(text_cost_count,"#FFF7D1")
        end

        local id = FGUI:GetID(item)
        local node_item = FGUI:GetChild(item,"node_item")
        local cache_icon_item = self.cache_icon_item_list[id]
        if cache_icon_item then
            ItemUtil:ItemShow_Release(cache_icon_item)
        end
        self.cache_icon_item_list[id] = ItemUtil:ItemShow_Create(itemData,node_item,{disableClick = false,OverLap = data.Quantity})
        self.cache_icon_item_list[id]:UpdateCountVisible(false)


        local node_money = FGUI:GetChild(item,"node_money")
        local cache_money_item = self.cache_money_item_list[id]
        if cache_money_item then
            ItemUtil:ItemShow_Release(cache_money_item)
        end

        itemData = SL:GetValue("ITEM_DATA",tonumber(costArr[1]))
        self.cache_money_item_list[id] = ItemUtil:ItemShow_Create(itemData,node_money,{disableClick = false})
        self.cache_money_item_list[id]:UpdateIsShowLock()
        self.cache_money_item_list[id]:UpdateItemGradeIsShow(false)
    end
end

function BuyPanel:SortStoreItem(list)
    -- 筛选出限购已经卖完的物品
    local storeSoldOut = {}
    local storeOther = {}
    table.sort(list,function(a,b) return a.Index < b.Index end)
    for k,data in pairs(list) do
        if data then
            if data.Limitbuy and data.BuyCount then
                local arr = string.split(data.Limitbuy,"#")
                local limitCount = tonumber(arr[2])
                if limitCount - data.BuyCount == 0 then
                    storeSoldOut[#storeSoldOut + 1] = data
                else
                    storeOther[#storeOther + 1] = data
                end
            else
                storeOther[#storeOther + 1] = data
            end
        end
    end

    table.merge(storeOther,storeSoldOut)
    return storeOther
end

function BuyPanel:BuyItemClicked(eventData)
    local _data = {}
    _data.hideCompare = true
    _data.hideButtons = true
    _data.buyParam = {}
    _data.buyParam.purchaseType = self.groupID

    local childIdx = FGUI:GetChildIndex(self.list_buy, eventData.data)
    local idx = FGUI:GList_childIndexToItemIndex(self.list_buy, childIdx)
    local data = {}
    data = self.storeData[idx + 1]
    _data.itemData = SL:GetValue("ITEM_DATA", data.Itemid)
    local leftCount = -1
    if data.Limitbuy then
        local count = tonumber(string.split(data.Limitbuy,"#")[2])
        leftCount = count
        _data.buyParam.buyCount = count
        if data.BuyCount then
            leftCount = count - data.BuyCount
            _data.buyParam.curBuyCount = data.BuyCount
        end
    end

    _data.buyParam.storeId = data.ID
    local isEnoughMoney,costType,currentTotalMoney = SL:GetValue("NPC_STORE_GET_ENOUGH_COSTTYPE",data.Costtype,data.Nowprice)

    _data.buyParam.coinId = data.Costtype
    _data.buyParam.price = data.Nowprice
	local totalMoney = SL:GetValue("NPC_STORTE_GET_TOTAL_MONEY_BY_COSTTYPE",data.Costtype)
    local minCount = 1
    local maxCount = math.floor(totalMoney/data.Nowprice)
    if data.OnceCount then
        local onceCountArray = string.split(data.OnceCount,"#")
        minCount = tonumber(onceCountArray[1]) or 1
        maxCount = math.min(maxCount,tonumber(onceCountArray[2]))
    end
    
    -- 最小购买数量
    _data.buyParam.minNum = minCount
    if leftCount > 0 then
        maxCount = math.min(maxCount,leftCount)
    end

    -- 醉倒购买数量
    _data.buyParam.maxNum = maxCount
    FGUIFunction:OpenItemTips(_data)
end

function BuyPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_NPCSTORE_UPDATE, "BuyPanel", handler(self, self.RefreshDataAndList))
    SL:RegisterLUAEvent(LUA_EVENT_NPCSTORE_BUY, "BuyPanel", handler(self, self.RefreshDataAndList))
    
end

function BuyPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_NPCSTORE_UPDATE, "BuyPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_NPCSTORE_BUY, "BuyPanel")
end

function BuyPanel:Enter(groupID)
    if groupID then
        self.groupID = groupID
    end

    self:RegisterEvent()
    -- 请求最新的商店的group数据
    SL:RequestGroupData(self.groupID)

    FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.BuyGuide,self._ui)
end

function BuyPanel:Exit()
    self:RemoveEvent()

    FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.BuyGuide)
end

return BuyPanel