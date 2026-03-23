local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCExChangeBuyPanel = class("PCExChangeBuyPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

--- 界面被创建时调用
function PCExChangeBuyPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self:GetAllFGuiData()
	self:InitClickEvent()
	self:InitData()
	self:InitView()
end

function PCExChangeBuyPanel:GetAllFGuiData()
	self.list_filter = self._ui.list_filter
	self.list_data = self._ui.list_data
	self.btn_refresh = self._ui.btn_refresh
	self.btn_collection = self._ui.btn_collection
	self.btn_search = self._ui.btn_search
	self.btn_return = self._ui.btn_return
	self.btn_clear_search = self._ui.btn_clear_search
	self.input_search = self._ui.input_search
	self.filter_money = self._ui.filter_money
	self.loading = FGUI:GetTransition(self.component, "loading")

	self.loading = FGUI:GetTransition(self.component, "loading")
	self.ctrl_loading = FGUI:getController(self.component, "isShowloading")
	self.ctrl_isHaveResult = FGUI:getController(self.component, "isHaveResult")
	self.ctrl_itemType = FGUI:getController(self.component, "itemType")
	self.ctrl_isHaveSearchKey = FGUI:getController(self.component,"isHaveSearchKey")
end

function PCExChangeBuyPanel:InitClickEvent()
	FGUI:GList_itemRenderer(self.list_data, handler(self, self.ListDataItemRender))
	FGUI:GList_setVirtual(self.list_data)

	FGUI:setOnClickEvent(self.btn_return, handler(self, self.BtnReturnClicked))
	FGUI:setOnClickEvent(self.btn_search, handler(self, self.BtnSearchClicked))
	FGUI:setOnClickEvent(self.btn_clear_search, handler(self, self.BtnClearSearchClicked))
	FGUI:setOnClickEvent(self.btn_collection, handler(self, self.BtnCollectionClicked))
	FGUI:setOnClickEvent(self.btn_refresh, handler(self, self.BtnrefreshClicked))

	FGUI:GTextInput_addOnChanged(self.input_search,handler(self,self.InputSearchChanged))
	FGUI:GComboBox_setOnChangeCallback(self.filter_money, handler(self, self.ComBoxMoneyFilter))
end

function PCExChangeBuyPanel:InitData()
	self._itemType = -1
	self._itemShowList = {}
	self._treeData = SL:GetValue("PAIMAI_TREE_FILTER_DATA")
	self._mainPageNames = self._treeData.mainPageNames
	self._groupSets = self._treeData.groupSets
	self._nPage = self._groupSets[1]
	self._curReqItemIndex = nil
	self._costNameList = {}
	self._showDataList = {} -- 最终显示的data列表
	self._sendTimer = nil
    self._cur_send_handler = nil
    self._optQueue = {}
end

function PCExChangeBuyPanel:InitView()
	self:InitListFilter()
end

-- 刷新过滤结果
function PCExChangeBuyPanel:InitListFilter()
	self.rootTreeNode = FGUI:GTree_getRootNode(self.list_filter)
	for _key, _value in ipairs(self._treeData.tree) do
		local isHasChild = type(_value) ~= "number"
		local parent = FGUI:GTreeNode_Create("ui://ExChange_pc/item_listleft_parent", isHasChild)
		FGUI:GTreeNode_addChild(self.rootTreeNode, parent)
		local comp = FGUI:GTreeNode_getCell(parent)
		FGUI:addOnClickMultipleEvent(
			comp, function()
				self._nPage = self._groupSets[_key]
				self:RequestItemSummyInfo()
			end
		)
		FGUI:getController(comp, "isHasChild").selectedIndex = isHasChild and 1 or 0
		local text_title = FGUI:GetChild(comp, "text_content")
		FGUI:GTextField_setText(text_title, self._mainPageNames[_key])
		FGUI:GTreeNode_setExpanded(parent, true)
		if _value and isHasChild then
			for _nPage, _value_ in pairs(_value) do
				local child = FGUI:GTreeNode_Create("ui://ExChange_pc/item_listleft_child", false)
				FGUI:GTreeNode_addChild(parent, child)
				local compChild = FGUI:GTreeNode_getCell(child)
				local text_content = FGUI:GetChild(compChild, "text_content")
				FGUI:GTextField_setText(text_content, _value_)
				FGUI:addOnClickMultipleEvent(
					compChild, function()
						self._nPage = tostring(_nPage)
						self:RequestItemSummyInfo()
					end
				)
			end
		end
	end
end

function PCExChangeBuyPanel:InputSearchChanged()
	local str = FGUI:GTextInput_getText(self.input_search)
	local str = string.trim(str)
	FGUI:Controller_setSelectedIndex(self.ctrl_isHaveSearchKey,string.isNullOrEmpty(str) and 1 or 0)
end

function PCExChangeBuyPanel:ComBoxMoneyFilter()
	if self._itemType ~= 1 then
		return
	end

	self:RefreshAllItemOrderData()
end

function PCExChangeBuyPanel:CheckMoneyFilter(costID)
	if not costID then
		return false
	end

	if not self._costNameList or not next(self._costNameList) then
		return false
	end

	local key = FGUI:GComboBox_getSelectedIndex(self.filter_money)
	if not key then
		return false
	end

	local curSelectKey = self._costNameList[key]
	-- 所有货币
	if curSelectKey == -1 then
		return true
	end

	return curSelectKey == tonumber(costID)
end

-- 刷新combox显示
function PCExChangeBuyPanel:RefreshItemMoneyFilter()
	if self._itemType ~= 1 then
		return
	end

	self._costNameList = {}
	local costNames = {}
	table.insert(costNames, GET_STRING(32000013))
	self._costNameList[0] = -1
	for k, v in pairs(SL:GetCostFilterList()) do
		local moneyData = SL:GetValue("ITEM_DATA", tonumber(k))
		table.insert(self._costNameList, tonumber(k))
		table.insert(costNames, moneyData.Name)
	end

	FGUI:GComboBox_setVisibleItemCount(self.filter_money, table.nums(costNames) + 1)
	FGUI:GComboBox_setItems(self.filter_money, costNames)
end

function PCExChangeBuyPanel:ClearData()
	self._itemType = -1
	self._nPage = self._groupSets[1]
	self._curReqItemIndex = nil
end

function PCExChangeBuyPanel:ListDataItemRender(idx, item)
	local itemRoot = FGUI:GetChild(item, "itemRoot")
	local iconMoney1 = FGUI:GetChild(item, "iconMoney1")
	local text_price_jingJia = FGUI:GetChild(item, "text_price_jingJia")
	local btn_buy = FGUI:GetChild(item, "btn_buy")
	local text_name = FGUI:GetChild(item, "text_name")
	local target_collection = FGUI:GetChild(item, "target_collection")
	local text_sell_count = FGUI:GetChild(item, "text_sell_count")
	-- 是否收藏
	local ctrl_isCollected = FGUI:getController(item, "isCollected")
	-- 是否显示收藏
	local ctrl_isCanCollected = FGUI:getController(item, "isCanCollected")
	-- itemType的类型
	local ctrl_itemType = FGUI:getController(item, "itemType")
	-- 设置itemType类型
	FGUI:Controller_setSelectedIndex(ctrl_itemType, self._itemType)
	-- 是否显示收藏
	FGUI:Controller_setSelectedIndex(ctrl_isCanCollected, self._itemType == 0 and 0 or 1)
	-- 隐藏货币图标
	FGUI:setVisible(iconMoney1, self._itemType == 1 and true or false)

	local id = FGUI:GetID(item)
	if self._itemShowList[id] then
		ItemUtil:ItemShow_Release(self._itemShowList[id])
	end

	local data = self._showDataList[idx + 1]
	if data then
		-- 是否被收藏
		FGUI:Controller_setSelectedIndex(
			ctrl_isCollected, SL:GetValue("EXCHANGE_COLLECT_LIST")[data.index] == 1 and 0 or 1
		)
		-- 去购买操作
		FGUI:setOnClickEvent(
			btn_buy, function()
				if self._itemType == 0 then -- 汇总展示和收藏
					-- 去请求详细
					self._curReqItemIndex = data.index
					self:RequestExItemAllOrder()
				elseif self._itemType == 1 then -- 分拆展示
					-- 去购买物品
					self:BuyItemData(data)
				elseif self._itemType == 2 then -- 收藏列表
					self._curReqItemIndex = data.index
					self:RequestExItemAllOrder()
				end
			end
		)

		-- 收藏操作
		FGUI:setOnClickEvent(
			target_collection, function()
				if SL:GetValue("EXCHANGE_COLLECT_LIST")[data.index] then
					self:RequestExCollectItem(1, data.index)
				else
					self:RequestExCollectItem(0, data.index)
				end
			end
		)

		if self._itemType == 0 then -- 汇总展示
			-- 收藏按钮
			self._itemShowList[id] = ItemUtil:ItemShow_Create(data.itemData, itemRoot)
			-- 数量显示
			FGUI:GTextField_setText(text_sell_count, data.count)
			-- 物品名称
			FGUI:GTextField_setText(text_name, data.itemName or "")
			-- 数量显示
			FGUIFunction:ScrollText_setString(text_price_jingJia, data.loprice or "", 1, 1)
		elseif self._itemType == 1 then -- 详细挂单显示
			if not self:CheckMoneyFilter(data.type) then
				FGUI:setVisible(item, false)
				return
			else
				FGUI:setVisible(item, true)
			end
			-- 物品名字
			FGUI:GTextField_setText(text_name, data.itemName or "")
			-- 物品数量
			FGUI:GTextField_setText(text_sell_count, data.useritem.OverLap)
			-- 价格
			FGUIFunction:ScrollText_setString(text_price_jingJia, data.price or "", 1, 1)
			self._itemShowList[id] = ItemUtil:ItemShow_Create(data.useritem, itemRoot)
			local moneyData = SL:GetValue("ITEM_DATA", data.type)
			ItemUtil:RefreshItemUIByData(iconMoney1, moneyData)
			ItemUtil:SetItemCountVisible(iconMoney1, false)
			ItemUtil:SetItemGradeVisible(iconMoney1, false)
		elseif self._itemType == 2 then -- 收藏列表
			self._itemShowList[id] = ItemUtil:ItemShow_Create(data.itemData, itemRoot)
			-- 物品名字
			FGUI:GTextField_setText(text_name, data.itemName or "")
		end
	end
end

-- 购买物品
function PCExChangeBuyPanel:BuyItemData(data)
	local enterData = {}
	enterData.maxNum = data.useritem.OverLap
	enterData.price = data.price
	enterData.costType = data.type
	enterData.itemName = SL:GetValue("ITEM_DATA", data.index).Name or ""
	enterData.itemData = data.useritem
	enterData.makeIndex = data.useritem.MakeIndex
	enterData.ok = function(makeIndex, price, count)
		local curMoney = tonumber(SL:GetValue("MONEY", data.type))
		local moneyData = SL:GetValue("ITEM_DATA", data.type)
		if curMoney < price * count then
			SL:ShowSystemTips(string.format(GET_STRING(32000009), moneyData.Name or ""))
			return
		end

		SL:RequestExBuyItem(makeIndex, price, count)
	end

	FGUI:Open("ExChange_pc", "PCExChangeBuyDialog", enterData)
end

-- 清理cache
function PCExChangeBuyPanel:CleanCache()
	for k, v in pairs(self._itemShowList) do
		if v then
			ItemUtil:ItemShow_Release(v)
		end
	end

	self._itemShowList = {}
    self._optQueue = {}
end

-- 刷新按钮点击
function PCExChangeBuyPanel:BtnrefreshClicked()
	if self._itemType == 0 then
		self:RequestItemSummyInfo()
	elseif self._itemType == 1 then
		self:RequestExItemAllOrder()
	elseif self._itemType == 2 then
		self:RequestExCollectItem(2)
	end
end

-- 搜索
function PCExChangeBuyPanel:BtnSearchClicked()
	self:SearchData()
end

-- 按钮返回点击
function PCExChangeBuyPanel:BtnReturnClicked()
    if self._optQueue and self._optQueue[1] and self._optQueue[1].callback then
        self._optQueue[1].callback()
    end
end

-- 搜索数据
function PCExChangeBuyPanel:SearchData()
	self.keyword = FGUI:GTextInput_getText(self.input_search)
	-- 搜索内容是否合法
	if string.isNullOrEmpty(self.keyword) then
		return
	end

	self.keyword = string.trim(self.keyword)
	self:RefreshListView()
end

function PCExChangeBuyPanel:SearchFilter(name)
	self.keyword = FGUI:GTextInput_getText(self.input_search)
	-- 搜索内容是否合法
	if string.isNullOrEmpty(self.keyword) then
		return true
	end

	self.keyword = string.trim(self.keyword)
	if string.isNullOrEmpty(name) then
		return true
	end

	if string.isNullOrEmpty(self.keyword) then
		return true
	end

	if string.match(name, self.keyword) then
		return true
	end
	return false
end

-- 过滤数据
function PCExChangeBuyPanel:FilterData()
	self._showDataList = {}
	if not self._list_dataSource or not next(self._list_dataSource) then
		return
	end

	for k, v in pairs(self._list_dataSource) do
		if v and v.itemName then
			if self:SearchFilter(v.itemName) then -- 过滤搜索
				if self._itemType == 1 then -- 模式1下过滤货币
					if v and v.type and self:CheckMoneyFilter(v.type) then
						table.insert(self._showDataList, v)
					end
				else
					table.insert(self._showDataList, v)
				end
			end
		end
	end
end
-- 刷新列表
function PCExChangeBuyPanel:RefreshListView()
    FGUI:setVisible(self.btn_return,self._itemType ~= 0)
	self:RefreshItemMoneyFilter()
	self:FilterData()
	local len = table.nums(self._showDataList)
	FGUI:GList_setNumItems(self.list_data, len)
	FGUI:Controller_setSelectedIndex(self.ctrl_itemType, self._itemType)
	FGUI:Controller_setSelectedIndex(self.ctrl_isHaveResult, len == 0 and 0 or 1)
end

-- 清除搜索
function PCExChangeBuyPanel:BtnClearSearchClicked()
	FGUI:GTextInput_setText(self.input_search, "")
	self.keyword = nil
	FGUI:Controller_setSelectedIndex(self.ctrl_isHaveSearchKey,1)
	self:RefreshListView()
end

function PCExChangeBuyPanel:BtnCollectionClicked()
	self:RefreshCollectData()
end

--- 界面打开时调用
function PCExChangeBuyPanel:Enter(data)
	self:StartTimer()
	self:RegisterEvent()
	self:InitUI()
	self:RequestExCollectItem(2)
end

-- 初始化UI显示
function PCExChangeBuyPanel:InitUI()
	FGUI:GTextInput_setText(self.input_search,"")
	FGUI:Controller_setSelectedIndex(self.ctrl_isHaveSearchKey,1)

	FGUI:Controller_setSelectedIndex(self.ctrl_loading,1)
end


--- 界面关闭时调用
function PCExChangeBuyPanel:Exit()
	self:UnRegisterEvent()
	self:CleanCache()
	self:ClearData()
	self:EndTimer()
	self:PlayerLoadingActionBySwitch(false)
end

-- 开启定时器
function PCExChangeBuyPanel:StartTimer()
	self:EndTimer()
	self._sendTimer = SL:Schedule(handler(self,self.SendHandler),0.2)
end

-- 请求句柄
function PCExChangeBuyPanel:SendHandler()
	if not self._cur_send_handler then
		return
	end

	self._cur_send_handler()
	self._cur_send_handler = nil
end

-- 关闭定时器
function PCExChangeBuyPanel:EndTimer()
	if self._sendTimer then
		SL:UnSchedule(self._sendTimer)
	end

    self._sendTimer = nil
end

----------------------------------------------------请求------------------------------------------------------------------------------

-- 请求物品汇总信息
function PCExChangeBuyPanel:RequestItemSummyInfo()
	if string.isNullOrEmpty(self._nPage) then
		return
	end

    local nPage = self._nPage
    local callBack = function()
        SL:RequestExItemSummyInfo(nPage)
    end
    self._cur_send_handler = callBack
    self:PushOptInQueue(callBack,0)
end

-- 请求某个物品的所有挂单
function PCExChangeBuyPanel:RequestExItemAllOrder()
	if not self._curReqItemIndex then
		return
	end

    local callBack = function()
        local _curReqItemIndex = self._curReqItemIndex
        SL:RequestExItemAllOrder(_curReqItemIndex)
    end

    self._cur_send_handler = callBack
    self:PushOptInQueue(callBack,1)
end

-- 收藏相关操作
function PCExChangeBuyPanel:RequestExCollectItem(opt,itemID)
	if not opt then
		return
	end

    local collectFromItemType = self.itemType
    local callBack = function()
        SL:RequestExCollectItem(opt, itemID, collectFromItemType)
    end
    self._cur_send_handler = callBack
    if opt == 2 then
        self:PushOptInQueue(callBack,2)
    end
end

function PCExChangeBuyPanel:PushOptInQueue(callback,opt)
    local len = table.nums(self._optQueue)
    local data = {}
    data.callback = callback
    data.opt = opt
    if len < 2 then
        if len == 0 then
            self._optQueue[1] = data
        elseif len == 1 then
            local front = self._optQueue[1]
            if front.opt == opt then
                self._optQueue[1] = data
            else
                self._optQueue[2] = data
            end
        end
    else
        if self._optQueue[2].opt == opt then
            self._optQueue[2] = data
        else
            self._optQueue[1] = self._optQueue[2]
            self._optQueue[2] = data
        end
    end
end
----------------------------------------------------请求-------------------------------------------------------------------------------
----------------------------------------------------LUAEVENT---------------------------------------------------------------------------

function PCExChangeBuyPanel:PlayerLoadingActionBySwitch(open)
	self.ctrl_loading.selectedIndex = open and 0 or 1
	if open == true then
		if FGUI:Transition_getIsPlaying(self.loading) then
			FGUI:Transition_setPaused(self.loading,true)
		end

		FGUI:Transition_play(self.loading,nil,-1)
	else
        self.ctrl_loading.selectedIndex = 1
		if FGUI:Transition_getIsPlaying(self.loading) then
			FGUI:Transition_setPaused(self.loading,true)
		end
	end
end

-- 更新汇总数据
function PCExChangeBuyPanel:RefreshAllItemSummyData()
	self._itemType = 0
	self._list_dataSource = SL:GetValue("EXCHANGE_SUMMARY_DATA")
	self:RefreshListView()
end

-- 更新物品所有的挂单数据
function PCExChangeBuyPanel:RefreshAllItemOrderData()
	self._itemType = 1
	self._list_dataSource = SL:GetValue("EXCHANGE_ITEM_ALL_ORDER")
	self:RefreshListView()
end

-- 更新收藏数据
function PCExChangeBuyPanel:RefreshCollectData()
	self._itemType = 2
	self._list_dataSource = {}
	for k, v in pairs(SL:GetValue("EXCHANGE_COLLECT_LIST")) do
		local itemData = SL:GetValue("ITEM_DATA", k)
		local data = {}
		data.itemData = itemData
		data.itemName = itemData.Name or ""
		data.index = itemData.ID
		table.insert(self._list_dataSource, data)
	end
	self:RefreshListView()
end

function PCExChangeBuyPanel:BuyTips(recog)
	if not recog then
		return
	end
	if recog == -1 then
		SL:ShowSystemTips(GET_STRING(30000082))
	elseif recog == -2 then
		SL:ShowSystemTips(GET_STRING(30000083))
	elseif recog == -3 then
		SL:ShowSystemTips(GET_STRING(32000014))
	elseif recog == -4 then
		SL:ShowSystemTips(GET_STRING(30000085))
	elseif recog == -5 then
		SL:ShowSystemTips(GET_STRING(30000086))
	elseif recog == -6 then
		SL:ShowSystemTips(GET_STRING(30000087))
	elseif recog == -7 then
		SL:ShowSystemTips(GET_STRING(30000088))
	elseif recog == 1 then
		SL:ShowSystemTips(GET_STRING(30000089))
	elseif recog == 2 then
		SL:ShowSystemTips(GET_STRING(30000090))
	else
		SL:ShowSystemTips(GET_STRING(30000091) .. recog)
	end
end

function PCExChangeBuyPanel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_EXCHANGE_SUM_DATA_UPDATE, "PCExChangeBuyPanel", handler(self, self.RefreshAllItemSummyData))
	SL:RegisterLUAEvent(LUA_EVENT_EXCHANGE_ITEM_ALL_ORDER, "PCExChangeBuyPanel", handler(self, self.RefreshAllItemOrderData))
	SL:RegisterLUAEvent(LUA_EVENT_EXCHANGE_COLLECTS_UPDATE, "PCExChangeBuyPanel", handler(self, self.RefreshCollectData))
	SL:RegisterLUAEvent(LUA_EVENT_EXCHANGE_BUY_FAIL_TIPS, "PCExChangeBuyPanel", handler(self, self.BuyTips))
	SL:RegisterLUAEvent(LUA_EVENT_EXCHANGE_BUY_RESULT, "PCExChangeBuyPanel", handler(self, self.BuyTips))
	SL:RegisterLUAEvent(LUA_EVENT_EXCHANGE_LOADING_UPDATE, "PCExChangeBuyPanel", handler(self, self.PlayerLoadingActionBySwitch))
end

function PCExChangeBuyPanel:UnRegisterEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_SUM_DATA_UPDATE, "PCExChangeBuyPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_ITEM_ALL_ORDER, "PCExChangeBuyPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_COLLECTS_UPDATE, "PCExChangeBuyPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_BUY_FAIL_TIPS, "PCExChangeBuyPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_BUY_RESULT, "PCExChangeBuyPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_EXCHANGE_LOADING_UPDATE, "PCExChangeBuyPanel")
end

return PCExChangeBuyPanel
