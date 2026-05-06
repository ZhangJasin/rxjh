local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local StorageExPanel = class("StorageExPanel", BaseFGUILayout)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
SL:RequireFile("FGUILayout/Bag/BagCell")

function StorageExPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self._storageId = 0
	self._curClassifyId = 0
	self._bagCells = {}
	self._storageCells = {}
	self._slot_slotInfo_map = {} -- 仓库 槽位 槽位信息映射
	self._infoKey_slot_map = {}

	self._ui.bagCellList = FGUI:GetChild(self._ui.view_bag, "List_Cell")

	self.handler_storageItemRenderer = handler(self, self.ListViewStorageCellRenderer)
	self.handler_bagItemRenderer = handler(self, self.OnBagListItemRenderer)
	self.handler_bagItemClick = handler(self, self.ClickBagCellEvent)
	self.handler_storageItemClick = handler(self, self.ClickStorageCellEvent)
	FGUI:SetCloseUIWhenClickOutside(self)
	FGUI:setOnClickEvent(self._ui.BtnClose, handler(self, self.Close))
	-- 仓库列表显示
	FGUI:GList_itemRenderer(self._ui.List_Cell, self.handler_storageItemRenderer)
	FGUI:GList_addOnClickItemEvent(self._ui.List_Cell, self.handler_storageItemClick)
	FGUI:GList_setVirtual(self._ui.List_Cell)

	--背包列表显示
	FGUI:GList_itemRenderer(self._ui.bagCellList, self.handler_bagItemRenderer)
	FGUI:GList_addOnClickItemEvent(self._ui.bagCellList, self.handler_bagItemClick)
	FGUI:GList_setVirtual(self._ui.bagCellList)


	-- 分类选中变化回调设置
	FGUI:GComboBox_setOnChangeCallback(self._ui.checkbox_type, handler(self, self.OnComboBoxValueChange))

	--快速存取
	self.cSelect = FGUI:getController(self._ui.CheckBox, "isSelect")
	FGUI:setOnClickEvent(self._ui.CheckBox,function ()
		local fastSave = SL:GetValue("STORAGE_FAST_SAVE")
		fastSave = not fastSave
		self:SetFastSaveState(fastSave)
	end)

end

function StorageExPanel:Enter(storageId)
	self:RegisterEvent()
	if type(storageId) == "table" then
		self._storageId = 1
	else
		self._storageId = storageId or 0
	end
	-- 设置当前打开的附加仓库id
	SL:SetValue("STORAGE_EX_CURRENT_STORAGE_ID", self._storageId)
	SL:RequestQueryStorageExItems()
	-- 获取附加仓库分类名称
	local classifyNameList = clone(SL:GetValue("STORAGE_EX_CLASSIFY_NAME_LIST", self._storageId)) or {}
	table.insert(classifyNameList,1, GET_STRING(1088))
	FGUI:GComboBox_setItems(self._ui.checkbox_type, classifyNameList)
	self:OnRefreshBag()
	self._curClassifyId = 0
	FGUI:GComboBox_setSelectedIndex(self._ui.checkbox_type, self._curClassifyId)
	FGUI:GTextField_setText(self._ui.Title, SL:GetValue("STORAGE_EX_NAME", self._storageId))
	
	self:SetFastSaveState(SL:GetValue("STORAGE_FAST_SAVE"))
end


function StorageExPanel:Exit()
	self:UnRegisterEvent()
	self:ClearData()
	FGUI:Open("Bag","PlayerInfoPanel",1)
end

function StorageExPanel:Destroy()
	self:CleanItemViewCache()
end

function StorageExPanel:Close()
	self.super.Close(self)
end

function StorageExPanel:ClearData()
	self._storageId = 0
	self._curClassifyId = 0
	self._bagCells = {}
	self._storageCells = {}
	self._slot_slotInfo_map = {} -- 仓库 槽位 槽位信息映射
	self._infoKey_slot_map = {}
end

-- 分类选中变化回调
function StorageExPanel:OnComboBoxValueChange()
	local idx = FGUI:GComboBox_getSelectedIndex(self._ui.checkbox_type)
	if idx == 0 then
		-- 全部
		self:OnRefreshStorageExData(0)
		self._curClassifyId = 0
	else
		local idList = SL:GetValue("STORAGE_EX_CLASSIFY_ID_LIST", self._storageId) or {}
		local subType = idList[idx]
		self._curClassifyId = subType
		self:OnRefreshStorageExData(subType)
	end
end

-- 附加仓库ItemRenderer刷新
function StorageExPanel:ListViewStorageCellRenderer(idx, item)
	local openCount = SL:GetValue("STORAGE_EX_OPEN_SIZE", self._storageId)
	local index = idx + 1
	if index > 0 and index <= openCount then
		self._storageCells[index]:SetCellLock(false)
	end
	local storageData = self._storageCells[index]
	self:UpdateCellView(item ,storageData)
end

-- 刷新背包数据
function StorageExPanel:OnRefreshBag()
	-- 筛选属于当前附加仓库的物品显示
	local storageBagData = {}	-- 存储当前仓库需要显示的物品
	local allBagData = SL:GetValue("BAG_DATA")
	local openCount = SL:GetValue("BAG_OPEN_SIZE")
	local totalCount = SL:GetValue("BAG_MAX_SIZE")
	local cnt = 1
	for _, data in pairs(allBagData) do
		local itemData = SL:GetValue("ITEM_DATA", data.Index)
		if itemData and itemData.AddWare == self._storageId then
			storageBagData[cnt] = data
			cnt = cnt + 1
		end
	end
	local index = 1
	for _, data in pairs(storageBagData) do
		self._bagCells[index] = BagCell.new(index,data,false) 
		index = index + 1
	end

	for i = 1, totalCount do
		local cell = self._bagCells[i]
		if not cell then
			if i <= openCount then
				self._bagCells[i] = BagCell.new(i,nil,false)
			else
				self._bagCells[i] = BagCell.new(i,nil,true)
			end
		end
	end

	FGUI:GList_setNumItems(FGUI:GetChild(self._ui.view_bag, "List_Cell"), totalCount)
end

-- 背包部分ItemRenderer刷新
function StorageExPanel:OnBagListItemRenderer(idx, item)
	local bagData = self._bagCells[idx + 1]
	self:UpdateCellView(item ,bagData)
end

-- 放入物品
function StorageExPanel:ClickBagCellEvent(context)
	local childIdx = FGUI:GetChildIndex(self._ui.bagCellList, context.data)
	local index = FGUI:GList_childIndexToItemIndex(self._ui.bagCellList, childIdx)
	local bagCell = self._bagCells[index + 1]
	local fastSave = SL:GetValue("STORAGE_FAST_SAVE")
	if fastSave then
		if SL:GetValue("STORAGE_EX_IS_FULL", self._storageId) then
			SL:ShowSystemTips(GET_STRING(60010006))
			return
		end
		bagCell:SetTipEnable(false)
		local itemData = bagCell._itemData
		if not itemData then return end
		if itemData.OverLap > 1 then
			-- 弹出数量输入
			local data = {}
			data.title = GET_STRING(90010006)
			data.maxNum = itemData.OverLap
			data.callback_yes = function (input)
				local num = tonumber(input)
				if num and num > 0 then
					SL:RequestAddItemToStorageEx(itemData.MakeIndex, num)
				end          
			end
			FGUIFunction:OpenCommonNumberInputPanel(data)
		else
			-- 放入附加仓库
			SL:RequestAddItemToStorageEx(itemData.MakeIndex, 1)
		end

	else
		bagCell:SetTipEnable(true)
		bagCell:ClickCellEvent()
	end
end

-- 仓库是否有空槽位，有则返回第一个空槽的index
function StorageExPanel:GetStorageEmptySlotIndex()
    if not self._slot_slotInfo_map then return nil end
    local openCount = SL:GetValue("STORAGE_EX_OPEN_SIZE", self._storageId)
    for index = 1, openCount do
        if self._slot_slotInfo_map[index] == nil then
            return index
        end
    end

    return nil
end

-- 背包是否有空槽
function StorageExPanel:GetBagEmptySlotIndex()
	if not self._bagCells then return nil end
	local openCount = SL:GetValue("BAG_OPEN_SIZE")
	for index = 1, openCount do
		local cell = self._bagCells[index]
		if cell._itemId == 0 then
			return index
		end
	end
	return nil
end

-- 取出物品
function StorageExPanel:ClickStorageCellEvent(context)
	local childIdx = FGUI:GetChildIndex(self._ui.List_Cell, context.data)
	local index = FGUI:GList_childIndexToItemIndex(self._ui.List_Cell, childIdx)
	local storageCell = self._storageCells[index + 1]
	local fastSave = SL:GetValue("STORAGE_FAST_SAVE")
	if fastSave then
		storageCell:SetTipEnable(false)
		local slotInfo = storageCell._itemData
		if not slotInfo then return end
		if slotInfo.OverLap > 1 then
			-- 弹出数量输入
			local data = {}
			data.title = GET_STRING(90010006)
			data.maxNum = slotInfo.OverLap
			data.callback_yes = function (input)
				local num = tonumber(input)
				if num and num > 0 then
					SL:RequestRemoveItemFromStorageEx(slotInfo.Index, num, slotInfo.Params[1], slotInfo.Params[2])	
				end          
			end
			FGUIFunction:OpenCommonNumberInputPanel(data)
		else
			SL:RequestRemoveItemFromStorageEx(slotInfo.Index, 1, slotInfo.Params[1], slotInfo.Params[2])	
		end
		
	else
		storageCell:SetTipEnable(true)
		storageCell:ClickCellEvent()
	end
	
end

local packageItemViewCache = {}
function StorageExPanel:CleanItemViewCache()
	for k, v in pairs(packageItemViewCache) do
		if v then
			ItemUtil:ItemShow_Release(v)
		end
	end
	packageItemViewCache = { }
end


function StorageExPanel:UpdateCellView(itemView, bagData)
	if not bagData then
		return
	end
	local itemData = BagCell.UpdateCellView(itemView, bagData)
	if not itemData then
		return
	end
	itemData.isShowCount = true
	local id = FGUI:GetID(itemView)
	local cacheItem = packageItemViewCache[id]
	if cacheItem then
		ItemUtil:ItemShow_Release(cacheItem)
	end
	local content = FGUI:GetChild(itemView,"ContentItem")
	local itemContentView =ItemUtil:ItemShow_Create(itemData,content,{disableClick = true})
	packageItemViewCache[id] = itemContentView
end


-- 更新整个仓库页面
function StorageExPanel:OnRefreshStorageExData(classify)
	local classifyId = classify or 0
	local allData = SL:GetValue("STORAGE_EX_DATA", self._storageId, classifyId) or {}
	self._slot_slotInfo_map = {}
	self._infoKey_slot_map = {}
	self._storageCells = {}
	local cnt = 1
	for index, data in pairs(allData) do
		self._slot_slotInfo_map[cnt] = data
		self._infoKey_slot_map[data.Flag] = cnt
		local itemData = self:ConvertData(data)	
		self._storageCells[cnt] = BagCell.new(cnt, itemData,false,ItemFrom.STORAGE_EX)
		cnt = cnt + 1
	end

	local openCount = SL:GetValue("STORAGE_EX_OPEN_SIZE", self._storageId)
	local totalCount = SL:GetValue("STORAGE_EX_TOTAL_SIZE", self._storageId)

	for i = 1, totalCount do
		local cell = self._storageCells[i]
		if not cell then
			if i <= openCount then
				self._storageCells[i] = BagCell.new(i,nil,false,ItemFrom.STORAGE_EX)
			else
				self._storageCells[i] = BagCell.new(i,nil,true,ItemFrom.STORAGE_EX)
			end
		end
	end
	FGUI:GList_setNumItems(self._ui.List_Cell, totalCount)
end

-- 将槽位信息转化为道具信息用于显示
function StorageExPanel:ConvertData(slotInfo)
	local itemData = clone(SL:GetValue("ITEM_DATA", slotInfo.Index))
	itemData.Index = slotInfo.Index
	itemData.Params = slotInfo.Params
	itemData.OverLap = slotInfo.OverLap
	itemData.Bind = slotInfo.Params[1]
	itemData.Star = slotInfo.Params[2]
	return itemData
end

function StorageExPanel:SetFastSaveState(fastSave)
	SL:SetValue("STORAGE_FAST_SAVE",fastSave)
	FGUI:Controller_setSelectedIndex(self.cSelect, fastSave and 1 or 0)
end



-- 仓库物品发生变化
-- info.Index   道具id
-- info.OverLap   数量
-- info.Params 物品标记信息数组，第0位：绑定属性值 第1位:宝石层数
function StorageExPanel:OnStorageExItemChange(info, classifyId)
	if self._curClassifyId ~= 0 and self._curClassifyId ~= classifyId then
		return
	end

	local count = info.OverLap 
	local key = info.Flag
    local slotIndex = self._infoKey_slot_map[key]
    local slotInfo = nil
         
    if slotIndex then
        -- 已经存在
        if count == 0 then
            -- 数量为0，移除物品
            self._slot_slotInfo_map[slotIndex] = nil
            self._infoKey_slot_map[key] = nil
        else
            -- 更新数量
            self._slot_slotInfo_map[slotIndex].OverLap = count
            slotInfo = self._slot_slotInfo_map[slotIndex]
        end
    elseif count ~= 0 then
        -- 不存在，新增物品
        slotIndex = self:GetStorageEmptySlotIndex()
        if not slotIndex then return end
        slotInfo = {}
        slotInfo.Index = info.Index
        slotInfo.OverLap = count
        slotInfo.Params = info.Params
        self._infoKey_slot_map[key] = slotIndex
        self._slot_slotInfo_map[slotIndex] = slotInfo
    else
        return
    end

	local storageData = self._storageCells[slotIndex]
	if not storageData then return end
	local itemData = nil
	if slotInfo then
		itemData = self:ConvertData(slotInfo)
	end
	
	storageData:RefreshData(itemData)
	
	local item = self:GetItemByItemIndex(self._ui.List_Cell, slotIndex)
	if item then
		self:UpdateCellView(item, storageData)
	end
end

-- 增加背包物品
function StorageExPanel:AddBagItem(data)
	local newIndex = SL:GetValue("BAG_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
	local openCount = SL:GetValue("BAG_OPEN_SIZE")
	if not newIndex or newIndex > openCount then
		return
	end
	-- 判断物品是否属于当前仓库
	local itemData = SL:GetValue("ITEM_DATA", data.Index)
	if not itemData then return end
	if itemData.AddWare ~= self._storageId then return end

	local emptyIndex = self:GetBagEmptySlotIndex()
	if not emptyIndex then return end
	local bagData = self._bagCells[emptyIndex]
	bagData:SetItem(data)
	local item = self:GetItemByItemIndex(self._ui.bagCellList, emptyIndex)
	if item then
		self:UpdateCellView(item, bagData)
	end
end

-- 删除背包物品
function StorageExPanel:DeleteBagItem(data)
	local index, bagData = self:GetBagItemByMakeIndex(data.MakeIndex)
	if not index or not bagData then return end
	bagData:SetItem(nil)

	local item = self:GetItemByItemIndex(self._ui.bagCellList, index)
	if item then
		self:UpdateCellView(item, bagData)
	end
end

-- 刷新背包物品
function StorageExPanel:OnUpdateBagItem(data)
	local index, bagData = self:GetBagItemByMakeIndex(data.MakeIndex)
	local thisItemData = SL:GetValue("BAG_DATA_BY_MAKEINDEX", data.MakeIndex)
	if not index or not bagData or not thisItemData then return end
	bagData:SetItem(thisItemData)
	local item = self:GetItemByItemIndex(self._ui.bagCellList, index)
	if item then
		self:UpdateCellView(item, bagData)
	end
end

function StorageExPanel:GetItemByItemIndex(GList,index)
	local childIndex = FGUI:GList_itemIndexToChildIndex(GList, index - 1)
	local childNum = FGUI:GetChildCount(GList)
	if childIndex >= 0 and childIndex < childNum then
		return FGUI:GetChildAt(GList, childIndex)
	end
	return nil
end

function StorageExPanel:GetBagItemByMakeIndex(MakeIndex)
	for index, bagData in pairs(self._bagCells) do
		if bagData._itemData and bagData._itemData.MakeIndex == MakeIndex then
			return index, bagData 		
		end
	end
	return nil
end





--------------------------- 注册事件 -----------------------------
function StorageExPanel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_STORAGE_EX_ALL_DATA, "StorageExPanel",  handler(self,self.OnRefreshStorageExData))
	SL:RegisterLUAEvent(LUA_EVENT_STORAGE_EX_ITEM_CHANGE, "StorageExPanel",  handler(self,self.OnStorageExItemChange))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_ADD, "StorageExPanel",  handler(self,self.AddBagItem))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_DEL, "StorageExPanel",  handler(self,self.DeleteBagItem))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE, "StorageExPanel",  handler(self,self.OnUpdateBagItem))
end

function StorageExPanel:UnRegisterEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_EX_ALL_DATA, "StorageExPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_EX_ITEM_CHANGE, "StorageExPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_ADD, "StorageExPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_DEL, "StorageExPanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE, "StorageExPanel")
end


return StorageExPanel