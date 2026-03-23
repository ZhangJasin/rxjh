local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TreasurePanel = class("TreasurePanel", BaseFGUILayout)
local TreasureStoreItem = SL:RequireFile("FGUILayout/TreasureShop/TreasureStoreItem")

-- 初始化
function TreasurePanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:SetCloseUIWhenClickOutside(self)

    self:InitData()
    self:GetAllFGuiData()
    self:InitClickEvent()
    self:InitUI()
end

function TreasurePanel:InitData()
    self._group = 0                                                         -- 当前StoreGroup中group字段
    self._page = -1                                                         -- 当前页(store表BtLeafType)
    self._cur_cT = 1                                                       -- 当前货币类型      
    self._pageValues = SL:GetValue("NPC_STORE_PAGES_BY_GROUP",self._group)  -- storeGroup表中PagesName
    self._costFilterListData = {}                                           -- 货币list的数据
    self._current_storeData = {}                                            -- 最终显示的商品信息
end


-- 获取所有需要用组件和控制器
function TreasurePanel:GetAllFGuiData()
    -- 主面板右边页签
    self.costFilterList = self._ui.costFilterList
    self.pageList = self._ui.pageList
    self.storeList = self._ui.storeList
    self.ctrl_isHaveStore = FGUI:getController(self.component,"isHaveStore")
end

function TreasurePanel:InitUI()
    -- 商品List
    FGUI:GList_setVirtual(self.storeList)
    FGUI:GList_itemRenderer(self.storeList,handler(self,self.StoreListItemRenderer))
    FGUI:GList_setDefaultItem(self.storeList,"ui://p8mjxubrcym74q")
    FGUI:GList_addOnClickItemEvent(self.storeList, handler(self, self.OnClickStoreItem))

    -- costFilter
    FGUI:GList_itemRenderer(self.costFilterList,handler(self,self.CostFilterItemRender))
    FGUI:GList_setDefaultItem(self.costFilterList,"ui://p8mjxubrseb1v6o")
    FGUI:GList_addOnClickItemEvent(self.costFilterList, handler(self, self.CostFilterItemClick))

    -- page
    FGUI:GList_itemRenderer(self.pageList,handler(self,self.PageItemRender))
    FGUI:GList_setDefaultItem(self.pageList,"ui://p8mjxubrbxaz3q")
    FGUI:GList_addOnClickItemEvent(self.pageList, handler(self, self.PageItemClick))

    -- 从配置获取显示的按钮信息  刷新4个按钮
    FGUI:GList_setNumItems(self.pageList,table.count(self._pageValues))
end

function TreasurePanel:PageItemRender(idx,cell)
    local index = idx + 1
    local btn_name = FGUI:GetChild(cell,"btn_name")
    local pageNames = SL:GetValue("NPC_STORE_PAGENAMES_BY_GROUPID",0) or {}
    local arrPageNames = string.split(pageNames,"#")

    -- 设置按钮名字
    if btn_name then
        FGUI:GTextField_setText(btn_name,arrPageNames[index])
    end
end

function TreasurePanel:CostFilterItemRender(idx,cell)
    local index = idx + 1
    local title = FGUI:GetChild(cell,"title")
    if title then
        FGUI:GTextField_setText(title,SL:GetValue("ITEM_DATA",self._costFilterListData[index]).Name)
    end
end

-- 商品的Item
function TreasurePanel:StoreListItemRenderer(idx,item)
    local data = {}
    data = self._current_storeData[idx + 1]
    TreasureStoreItem:RefreshItemIcon(item,data)
end

-- 左边页签选中状态
function TreasurePanel:CheckSelectedPageItem(listComp,idx)
    if not listComp then
        return
    end

    local count = FGUI:GetChildCount(listComp)
    for index = 0,count - 1 do
        local comp = FGUI:GetChildAt(listComp,index)
        local controller = FGUI:getController(comp,"isSelected")
        controller.selectedIndex = index == idx and 0 or 1
    end
end

-- 左边页签按钮点击
function TreasurePanel:PageItemClick(eventData)
	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
    local idx = FGUI:GetChildIndex(self.pageList,eventData.data)
    self:RefreshCostListByPage(idx + 1)
end

-- 刷新钱币列表
function TreasurePanel:RefreshCostListByPage(page)
    self._page = page
    -- 选中货币按钮
    self:CheckSelectedPageItem(self.pageList, page - 1)
    self._costFilterListData = SL:GetValue("NPC_STORE_DATA_BY_GB",self._group
                                                                 ,self._pageValues[self._page])
    FGUI:GList_setNumItems(self.costFilterList,table.count(self._costFilterListData))
    if table.count(self._costFilterListData) > 0 then
        self:RefreshStoreData(self._cur_cT)
    end
end

-- 货币列表按钮点击
function TreasurePanel:CostFilterItemClick(eventData)
    local idx = FGUI:GetChildIndex(self.costFilterList,eventData.data)
    self:RefreshStoreData(idx + 1)
end

-- 刷新商品
function TreasurePanel:RefreshStoreData(index)
    self._cur_cT = index
    self:CheckSelectedPageItem(self.costFilterList,index - 1)
    self._current_storeData = SL:GetValue("NPC_STORE_DATA_BY_GBC",self._group ,
                                            self._pageValues[self._page],
                                            self._costFilterListData[self._cur_cT])
    self._current_storeData = self:SortStoreItem(self._current_storeData)

    FGUI:Controller_setSelectedIndex(self.ctrl_isHaveStore,table.nums(self._current_storeData) > 0 and 1 or 0)
    FGUI:GList_setNumItems(self.storeList,table.count(self._current_storeData))
end

-- 商品Item点击
function TreasurePanel:OnClickStoreItem(eventData)
    local _data = {}
    _data.hideCompare = true
    _data.hideButtons = true
    _data.buyParam = {}
    _data.buyParam.purchaseType = 0 -- groupID

    local data = {}
    local idx = FGUI:GetChildIndex(self.storeList, eventData.data)
    data = self._current_storeData[idx + 1]
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
    
    -- 商品ID
    _data.buyParam.storeId = data.ID

    local isMoneyEnough,costType,currentMoney = SL:GetValue("NPC_STORE_GET_ENOUGH_COSTTYPE",data.Costtype,data.Nowprice)
    local costTypeName = SL:GetValue("ITEM_DATA",costType).Name

    _data.buyParam.coinId = data.Costtype
    _data.buyParam.price = data.Nowprice
    local minCount = 0
	
	-- 获取所有货币的总和
	local totalMoney = SL:GetValue("NPC_STORTE_GET_TOTAL_MONEY_BY_COSTTYPE",data.Costtype)
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

-- 排序物品
function TreasurePanel:SortStoreItem(list)
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

-- 获取商店配表
function TreasurePanel:RefreshData()
    -- 配置表读取
    self._costFilterListData = {}
    self._current_storeData = {}
    FGUI:GList_setNumItems(self.pageList,table.count(self._pages))
end

function TreasurePanel:RefreshStore(group)
    -- 成功
    self:CheckSelectedPageItem(self.pageList,self._page-1)
    self._costFilterListData = SL:GetValue("NPC_STORE_DATA_BY_GB",self._group ,self._pageValues[self._page])
    FGUI:GList_setNumItems(self.costFilterList,table.count(self._costFilterListData))
    if table.count(self._costFilterListData) > 0 then
        self:RefreshStoreData(self._cur_cT)
    end
end

-- 购买成功返回
function TreasurePanel:RefreshBuyRep(data)
    if data then
        if data.isSuccess ~= 1 then
            SL:ShowSystemTips(GET_STRING(30000039))
            return
        end

        self:RefreshStoreListView()
    end
end

function TreasurePanel:RefreshStoreListView()
    self:RefreshStoreData(self._cur_cT)
end

function TreasurePanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_NPCSTORE_UPDATE, "Treasure", handler(self, self.RepStoreDataUpdate))
    SL:RegisterLUAEvent(LUA_EVENT_NPCSTORE_BUY, "Treasure", handler(self, self.RefreshBuyRep))
end

function TreasurePanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_NPCSTORE_UPDATE, "Treasure")
    SL:UnRegisterLUAEvent(LUA_EVENT_NPCSTORE_BUY, "Treasure")
end

-- 面板所有按钮点击事件注册
function TreasurePanel:InitClickEvent()
    FGUI:setOnClickEvent(self._ui.btn_close,handler(self,self.OnClose))
end

-- 进入
function TreasurePanel:Enter(page)
    -- 显示货币
    FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA","TreasureMoneyList"))
    if not page then
        page = 1
    end

    self._page = page
    -- 注册监听
    self:RegisterEvent()
    self:RefreshCostListByPage(self._page)
    SL:ComponentAttach(SLDefine.SUIComponentTable.Treasure, self._ui.Node_attach)
end

-- 服务器返回数据
function TreasurePanel:RepStoreDataUpdate()
    if table.count(self._pageValues) >= 1 then
        self:RefreshCostListByPage(self._page)
    end
end

function TreasurePanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.Treasure)
    self:RemoveEvent()
    FGUIFunction:HideTopCurrency()
end

-- 关闭面板
function TreasurePanel:OnClose()
    self.super.Close(self)
end

-- 销毁
function TreasurePanel:Destroy()
end

return TreasurePanel