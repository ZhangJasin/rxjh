local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local StoragePanel = class("StoragePanel", BaseFGUILayout)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
SL:RequireFile("FGUILayout/Bag/BagCell")

function StoragePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
	self.firstEnter = true
	self._disableCellDoubleClick = true

	self:InitData()
	self:InitView()
end

function StoragePanel:Enter(data)
	if data then
		self.fromPanel = data.fromPanel
	end
	FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA", "BagMoneyList"))
	self:RegisterEvent()
	self:RefreshData()
	self.firstEnter = false
	self.bagPanel:Enter({ disableCellDoubleClick = self._disableCellDoubleClick} )
	SL:ComponentAttach(SLDefine.SUIComponentTable.Storage, self._ui.Node_attach)
end

function StoragePanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.Storage)

	FGUIFunction:HideTopCurrency()
	self:UnRegisterEvent()
	self.bagPanel:Exit()
end

function StoragePanel:Destroy()
	self:CleanItemViewCache()
	self.bagPanel:CleanItem()
end

function StoragePanel:Close()
	self.super.Close(self)
	if self.fromPanel and  self.fromPanel == 1 then
		FGUI:Open("Bag","PlayerInfoPanel",1)
	end
end

function StoragePanel:ListViewStorageCellRenderer(idx, item)
	local index = self:GetStorageDataIndex(idx + 1)
	self:UnLockStorageCell(index)
	self:UpdateCellViewByIndexId(item,index)
end
function StoragePanel:InitView()

	FGUI:GList_itemRenderer(self._ui.List_Cell, handler(self, self.ListViewStorageCellRenderer))
	FGUI:GList_addOnClickItemEvent(self._ui.List_Cell, function(context)
		local childIdx = FGUI:GetChildIndex(self._ui.List_Cell, context.data)
		local index = FGUI:GList_childIndexToItemIndex(self._ui.List_Cell, childIdx)
		self:ClickCellEvent(index)
	end)
	FGUI:GList_setVirtual(self._ui.List_Cell)

	self.cacheStorageCell = BagCell.new(0,nil,true)
	FGUI:setOnClickEvent(self._ui.BtnSort,function ()
		SL:RequestRefreshStoragePos(self._selectGroup)
	end)


	FGUI:setOnClickEvent(self._ui.BtnBagSort,function ()
		SL:RequestRefreshBagPos()
	end)

	FGUI:setOnClickEvent(self._ui.BtnClose,function ()
		self:Close()
	end)

	FGUI:GList_addOnClickItemEvent(self._ui.List_Filter, function(context)
		local index = FGUI:GetChildIndex(self._ui.List_Filter, context.data) + 1
		self:SelectPage(index)
	end)
	FGUI:GList_itemRenderer(self._ui.List_Filter, handler(self, self.ListViewFilterRenderer))

	FGUI:GList_setNumItems(self._ui.List_Filter, #self.FilterText)
	local obj = FGUI:GetChildAt(self._ui.List_Filter,0)
	FGUI:GButton_FireClick(obj,false,true)


	--快速存取
	self.cSelect = FGUI:getController(self._ui.CheckBox, "isSelect")
	FGUI:setOnClickEvent(self._ui.CheckBox,function ()
		local fastSave = SL:GetValue("STORAGE_FAST_SAVE")
		fastSave = not fastSave
		self:SetFastSaveState(fastSave)
	end)

	self:SetFastSaveState(SL:GetValue("STORAGE_FAST_SAVE"))

	if not self.bagPanel then
		self.bagPanel = FGUI:CreateObject(self._ui.BagNode, "Bag", "BagPanel", true)
	end
end

function StoragePanel:SetFastSaveState(fastSave)
	SL:SetValue("STORAGE_FAST_SAVE",fastSave)
	FGUI:Controller_setSelectedIndex(self.cSelect, fastSave and 0 or 1)
end

local packageItemViewCache = {}
function StoragePanel:CleanItemViewCache()
	for k, v in pairs(packageItemViewCache) do
		if v then
			ItemUtil:ItemShow_Release(v)
		end
	end
	packageItemViewCache = { }
end

function StoragePanel:UpdateCellViewByViewIdAndStorageData(viewIndex,storageData)
	local targetView = self:GetCurPageStorageCellView(viewIndex)
	if targetView then
		self:UpdateCellView(targetView,storageData)
	end
end

function StoragePanel:UpdateCellViewByViewId(viewIndex,index)
	local targetView = self:GetCurPageStorageCellView(viewIndex)
	if targetView then
		self:UpdateCellViewByIndexId(targetView,index)
	end
end
function StoragePanel:UpdateCellViewByIndexId(itemView,index)
	local storageData = self:GetCurShowStorageCellData(index)
	self:UpdateCellView(itemView,storageData)
end

function StoragePanel:UpdateCellView(itemView,bagData)
	if not bagData then
		return
	end
	local itemData = BagCell.UpdateCellView(itemView,bagData)
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

function StoragePanel:ListViewFilterRenderer(idx, item)
	FGUI:GButton_setTitle(item,self.FilterText[idx + 1])
end

function StoragePanel:GetCurPageStorageCellView(index)
	if index <=  self._pageTotalCell * self._selectGroup and index >self._pageTotalCell * (self._selectGroup -1 ) then
		local viewIdx = (index - 1) % self._pageTotalCell + 1
		if viewIdx > 0 then
			local childIdx = FGUI:GList_itemIndexToChildIndex(self._ui.List_Cell, viewIdx-1)
			local childNum = FGUI:GetChildCount(self._ui.List_Cell)

			if childIdx >= 0 and childIdx < childNum then
				return FGUI:GetChildAt(self._ui.List_Cell,childIdx)
			end
		end
	end
end

function StoragePanel:GetStorageDataIndex(index)
	return   (self._selectGroup -1 ) * self._pageTotalCell +index
end

function StoragePanel:CheckIndexInPage(index)
	return   index <=  self._pageTotalCell * self._selectGroup and index >self._pageTotalCell * (self._selectGroup -1 )
end

function StoragePanel:GetCurShowStorageCellData(index)
	if not self:CheckIndexInPage(index) then
		return
	end
	return self._storageCells[index]
end
function StoragePanel:InitData()
	local value 			 = SL:GetValue("GAME_DATA", "StoragePageCnt")
	self._pageTotalCell 	 = value
	self._selectGroup   	 = 1         -- 当前页数
	self._selectType    	 = 1			-- 筛选
	self:InitStorageItems()
end

function StoragePanel:RefreshData()
	if not self.firstEnter then
		self:UpdateStoragePositionData()
		self:RefreshPage()
	end
end

function StoragePanel:UpdateStorageSize(addSize)
	local totalCount = SL:GetValue("STORAGE_MAX_SIZE")
	local openCount = SL:GetValue("STORAGE_OPEN_SIZE")
	if addSize and addSize > 0 then
		local maxCnt = openCount < totalCount and openCount or totalCount
		for i = openCount - addSize, maxCnt do
			self:UnLockStorageCell(i)
		end
		self:RefreshPage()
	end
end

function StoragePanel:InitStorageItems()
	self._storageCells= {}
	local allData = self:GetAllStorageData()
	-- show size
	local openCount = SL:GetValue("STORAGE_OPEN_SIZE") -- 开启的格子数
	local totalCount = SL:GetValue("STORAGE_MAX_SIZE") -- 服务端最大格子数
	self._totalPage = math.ceil(totalCount / self._pageTotalCell)

	for i, data in pairs(allData) do
		local index = 0
		if data then
			index = SL:GetValue("STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
		end
		if index > 0 then
			self._storageCells[index] = BagCell.new(index,data,false,ItemFrom.STORAGE)
		end

	end
	for i = 1, totalCount do
		local cell = self._storageCells[i]
		if not cell then
			if i <= openCount then
				self._storageCells[i] = BagCell.new(i,nil,false,ItemFrom.STORAGE)
			else
				self._storageCells[i] = BagCell.new(i,nil,true,ItemFrom.STORAGE)
			end
		end
		self._storageCells[i]:SetDoubleClickDisable(self._disableCellDoubleClick)
	end

	self.FilterText = {}
	for i = 1, self._totalPage do
		self.FilterText[i] = GET_STRING(60003007)..GET_STRING(5000 + i)
	end

end

function StoragePanel:UpdateStoragePositionData()
	local totalCount = SL:GetValue("STORAGE_MAX_SIZE")
	for i = 1, totalCount do
		local cell = self._storageCells[i]
		if cell then
			self._storageCells[i]:SetItem(nil)
			self._storageCells[i]:SetDoubleClickDisable(self._disableCellDoubleClick)
		end
	end

	local allData = self:GetAllStorageData()
	for i, data in pairs(allData) do
		local index = 0
		if data then
			index = SL:GetValue("STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
		end
		if index > 0 then
			self._storageCells[index]:SetItem(data)
		end
	end
end

function StoragePanel:UpdateStoragePosition()
	self:UpdateStoragePositionData()
	self:SelectPage(self._selectGroup)
end

function StoragePanel:GetSelectPage()
	return self._selectGroup
end

function StoragePanel:SelectPage(index)
	if index == 0 then
		return
	end
	if index > self._totalPage then
		return
	end
	self._selectGroup = index
	SL:SetValue("STORAGE_SELECT_PAGE",index)
	self:RefreshPage(index)
	self:RefreshPageNum()
end
function StoragePanel:RefreshPage(index)
	index =index or  self._selectGroup
	FGUI:GList_setNumItems(self._ui.List_Cell, self._pageTotalCell)
end

function StoragePanel:ClickCellEvent(idx)
	local  index = self:GetStorageDataIndex(idx + 1)
	local storageCellData = self:GetCurShowStorageCellData(index)
	storageCellData:ClickCellEvent()
end



-- 获取仓库所有数据
function StoragePanel:GetAllStorageData()
	local storageData = SL:GetValue("STORAGE_DATA")
	return storageData
end

function StoragePanel:AddStorageItem(data)
	local newIndex = SL:GetValue("STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex)
	local openCount = SL:GetValue("STORAGE_OPEN_SIZE")
	if not newIndex or newIndex > openCount then
		return
	end

	local viewIndex = newIndex
	self._storageCells[newIndex]:SetItem(data)
	if viewIndex > 0 then
		self:UpdateCellViewByViewId(viewIndex,newIndex)
		self:RefreshPageNum()
	end
end

-- 显示当前数量
function StoragePanel:RefreshPageNum()
	local cur_count = 0
	local allData = self:GetAllStorageData()
	local min_index = self._pageTotalCell * (self._selectGroup - 1)
	local max_index = self._pageTotalCell * (self._selectGroup)
	for i, data in pairs(allData) do
		if data then
			local index = SL:GetValue("STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
			if min_index < index and index <= max_index then
				cur_count = cur_count + 1
			end
		end
	end
	
	local color = cur_count < self._pageTotalCell and "#FFFFFF" or "#FF0000"
	if self._ui.text_count then
		local curPageNum = SL:GetValue("STORAGE_OPEN_SIZE") - self._pageTotalCell * (self._selectGroup - 1)
		if curPageNum > self._pageTotalCell then
			curPageNum = self._pageTotalCell
		end
		FGUI:GTextField_setText(self._ui.text_count,string.format("[color=%s]%s/%s[/color]",color,cur_count,curPageNum >=0 and curPageNum or 0))
	end
end


function StoragePanel:UnLockStorageCell(newIndex)
	local openCount = SL:GetValue("STORAGE_OPEN_SIZE")
	if not newIndex or newIndex > openCount then
		return
	end

	local viewIndex = newIndex
	if viewIndex > 0 then
		self._storageCells[newIndex]:SetCellLock(false)
	end
end


function StoragePanel:DeleteStorageItem(data)

	local viewIndex = -1
	local storageCellData = nil
	if self._selectType == 1 then
		for i = 1, #self._storageCells do			--事件传过来时数据已经删除了，不能用SL:GetValue("STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex) 获取位置
			storageCellData =  self._storageCells[i]
			local itemData = storageCellData:GetItemData()
			if itemData and itemData.MakeIndex == data.MakeIndex then
				viewIndex = i
				break
			end
		end
	end
	if storageCellData and viewIndex ~= -1 then
		storageCellData:SetItem(nil)
		self:UpdateCellViewByViewIdAndStorageData(viewIndex,storageCellData)
		self:RefreshPageNum()
	end
end

function StoragePanel:OnUpdateStorageItem(data)
	if not data or not next(data) then
		return
	end
	local newIndex = SL:GetValue("STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex)
	local thisItemData = SL:GetValue("STORAGE_DATA_BY_MAKEINDEX", data.MakeIndex)
	local storageCell = self._storageCells[newIndex]
	local viewIndex = newIndex

	if storageCell and thisItemData and viewIndex > 0 then
		storageCell:SetItem(thisItemData)
		self:UpdateCellViewByViewId(viewIndex,newIndex)
		self:RefreshPageNum()
	end
end

function StoragePanel:BagCellClickEvent(bagItem)
	local fastSave = SL:GetValue("STORAGE_FAST_SAVE")
	if bagItem._itemData and fastSave then
		if bagItem.from == ItemFrom.BAG then
			FGUIFunction:RequestSaveItemToNpcStorageInCurPage(bagItem._itemData)
		elseif bagItem.from == ItemFrom.STORAGE then
			SL:RequestPutOutStorageData(bagItem._itemData)
		end
		bagItem:SetTipEnable(false)
	end
end
--------------------------- 注册事件 -----------------------------
function StoragePanel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_UPDATE_LIST, "Storage",  handler(self,self.UpdateStoragePosition))
	SL:RegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_ADD, "Storage",  handler(self,self.AddStorageItem))
	SL:RegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_DEL, "Storage",  handler(self,self.DeleteStorageItem))
	SL:RegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_UPDATE, "Storage",  handler(self,self.OnUpdateStorageItem))
	SL:RegisterLUAEvent(LUA_EVENT_STORAGE_CELL_UNLOCK, "Storage",  handler(self,self.UpdateStorageSize))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "Storage",  handler(self,self.BagCellClickEvent))
end

function StoragePanel:UnRegisterEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_UPDATE_LIST, "Storage")
	SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_ADD, "Storage")
	SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_DEL, "Storage")
	SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_UPDATE, "Storage")
	SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_CELL_UNLOCK, "Storage")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "Storage")
end


return StoragePanel
