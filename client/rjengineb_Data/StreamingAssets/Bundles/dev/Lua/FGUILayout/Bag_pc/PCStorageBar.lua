
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCStorageBar = class("PCStorageBar", BaseFGUILayout)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
SL:RequireFile("FGUILayout/Bag_pc/PCBagCell")
function PCStorageBar:Create()
    self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:setWindowDrag(self.component, self._ui.bg)
    self:InitData()
	self:InitView()
end

function PCStorageBar:Enter()
	-- PCEquipBar居中放
	local width = SL:GetValue("SCREEN_WIDTH")
	local height = SL:GetValue("SCREEN_HEIGHT")
	local pcStorageBar_w = 272
	local pcEquipBar_W = 349


	FGUI:setPosition(self.component,width/2 - (pcStorageBar_w + pcEquipBar_W)/2,height/2)
    self:RegisterEvent()
    self:RefreshData()
	FGUI:Open("Bag_pc","PCEquipBar",nil,FGUI_LAYER.NORMAL,{fullScreen = false})
end

function PCStorageBar:Exit()
    self:UnRegisterEvent()
	FGUI:Close("Bag_pc","PCEquipBar")
end

function PCStorageBar:Destroy()
	self:CleanItemViewCache()
end

function PCStorageBar:Close()
	self.super.Close(self)
end

function PCStorageBar:ListViewStorageCellRenderer(idx, item)
	local index = self:GetStorageDataIndex(idx + 1)
	self:UnLockStorageCell(index)
	self:UpdateCellViewByIndexId(item,index)
end

function PCStorageBar:InitView()
	FGUI:GList_itemRenderer(self._ui.list_storage, handler(self, self.ListViewStorageCellRenderer))
	FGUI:GList_setVirtual(self._ui.list_storage)

	self.cacheStorageCell = PCBagCell.new(0,nil,true)
	FGUI:setOnClickEvent(self._ui.btn_sort,function (eventData)
    	FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)
		SL:RequestRefreshStoragePos(self._selectGroup)
	end)

	FGUI:setOnClickEvent(self._ui.btn_close,handler(self,self.Close))
    FGUI:setOnClickEvent(self._ui.btn_prev,handler(self,self.PagePrevClicked))
    FGUI:setOnClickEvent(self._ui.btn_next,handler(self,self.PageNextClicked))
end

function PCStorageBar:PagePrevClicked(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    if self._selectGroup == 1 then
        return
    end

    self._selectGroup = self._selectGroup  - 1
    self:SelectPage(self._selectGroup)
end

function PCStorageBar:PageNextClicked(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    if self._selectGroup == self._totalPage then
        return
    end

    self._selectGroup = self._selectGroup  + 1
    self:SelectPage(self._selectGroup)
end


local packageItemViewCache = {}
function PCStorageBar:CleanItemViewCache()
	for k, v in pairs(packageItemViewCache) do
		if v then
			ItemUtil:ItemShow_Release(v)
		end
	end
	packageItemViewCache = { }
end

function PCStorageBar:UpdateCellViewByViewIdAndStorageData(viewIndex,storageData)
	local targetView = self:GetCurPageStorageCellView(viewIndex)
	if targetView then
		self:UpdateCellView(targetView,storageData)
	end
end

function PCStorageBar:UpdateCellViewByViewId(viewIndex,index)
	local targetView = self:GetCurPageStorageCellView(viewIndex)
	if targetView then
		self:UpdateCellViewByIndexId(targetView,index)
	end
end
function PCStorageBar:UpdateCellViewByIndexId(itemView,index)
	local storageData = self:GetCurShowStorageCellData(index)
	self:UpdateCellView(itemView,storageData)
end

function PCStorageBar:UpdateCellView(itemView,bagData)
	if not bagData then
		return
	end

	FGUI:setOnDropEvent(itemView,handler(self,self.onCellDropEvent,itemView))
	
	local itemData = PCBagCell.UpdateCellView(itemView,bagData)
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

	local childIdx = FGUI:GetChildIndex(self._ui.list_storage, itemView)
	local index = FGUI:GList_childIndexToItemIndex(self._ui.list_storage, childIdx)
	FGUI:setOnRightClickEvent(packageItemViewCache[id].component,function()
		if self.clickDelay then return end
		self:RightClickEvent(index)
	end)

	FGUI:setOnRollOverEvent(itemContentView.component, function()
		self:RollOverEvent(index)
	end)

    FGUI:setOnRollOutEvent(itemContentView.component, function()
		self:RollOutEvent(index)
	end)

	FGUI:setOnClickEvent(itemContentView.component, function(eventData)
		if self.clickDelay then return end
		local touchId = FGUI:InputEvent_getTouchId(eventData)
		local data = {
			itemIndex = itemData.Index,
			makeIndex = itemData.MakeIndex,
			from = ItemFrom.STORAGE,
			dragStartSelectPage = self._selectGroup,-- 第一个仓库里开始拖动
		}
		
		-- 1.使用原图,尺寸可能偏大
		FGUI:DragDropManager_startDrag(itemContentView.component,"ui://public_pc/CommonItem", data, touchId,FGUIFunction.CloseBagCheckDragView)
		FGUIFunction:OpenBagCheckDragView()
		local commmonItem = FGUI:GLoader_getComponent(FGUI:DragDropManager_getDragAgent())
		ItemUtil:RefreshItemUIByData(commmonItem,itemData)
	end)
end

function PCStorageBar:onCellDropEvent(itemView,eventData)
	self.clickDelay = true
	SL:ScheduleOnce(handler(self, self.OnDelayClickEnd, nil, true), 0.1)
	local childIdx = FGUI:GetChildIndex(self._ui.list_storage, itemView)
	local endPos = FGUI:GList_childIndexToItemIndex(self._ui.list_storage, childIdx)
	if FGUI:InputEvent_getButton(eventData) == 0 and
		eventData.data and 
		eventData.data.makeIndex then
		-- 来源仓库
		if eventData.data.from and eventData.data.from == ItemFrom.STORAGE then
			if eventData.data.dragStartSelectPage and 
				eventData.data.dragStartSelectPage == self._selectGroup then
				-- 换位置
				local endIndex = self:GetStorageDataIndex(endPos + 1)
				local startIndex = SL:GetValue("STORAGE_POS_MARK_BY_MAKEINDEX", eventData.data.makeIndex)
				if not startIndex then
					return
				end

				if endIndex == startIndex then
					return
				end

				SL:SetValue("STORAGE_EXCHANGE_TWO_POS",startIndex,endIndex)
				self:UpdateCellViewByViewIdAndStorageData(startIndex,self:GetCurShowStorageCellData(startIndex))
				self:UpdateCellViewByViewIdAndStorageData(endIndex,self:GetCurShowStorageCellData(endIndex))
			end
			return
		end

		-- 来源背包
		if eventData.data.from and eventData.data.from == ItemFrom.BAG then
			-- 存仓操作
			local index = self:GetStorageDataIndex(endPos + 1)
			local storageData = self:GetCurShowStorageCellData(index)
			local dragItemData = SL:GetValue("BAG_DATA_BY_MAKEINDEX",eventData.data.makeIndex)
			-- 终点位置没有物品
			if not storageData:GetItemData() then
				local posData = {}
				posData.selectPage = self._selectGroup
				SL:Print("拖拽位置无东西，存指定位置")
				posData.from = {ItemFrom.BAG}
				posData.to = {ItemFrom.STORAGE,index}

				if dragItemData then
					FGUIFunction:RequestSaveItemToNpcStorageInCurPage(dragItemData,posData)
				end
			else
				if dragItemData then
					FGUIFunction:RequestSaveItemToNpcStorageInCurPage(dragItemData)
				end
			end

			return
		end
	end
end

function PCStorageBar:OnDelayClickEnd()
    self.clickDelay = false
end

function PCStorageBar:RollOverEvent(idx)
	local index = self:GetStorageDataIndex(idx + 1)
	local storageCellData = self:GetCurShowStorageCellData(index)
	if storageCellData then
		storageCellData:RollOverCell()
	end
end

function PCStorageBar:RollOutEvent(idx)
	local index = self:GetStorageDataIndex(idx + 1)
	local storageCellData = self:GetCurShowStorageCellData(index)
	if storageCellData then
		storageCellData:RollOutCell()
	end
end
function PCStorageBar:RightClickEvent(idx)
	local index = self:GetStorageDataIndex(idx + 1)
	local storageCellData = self:GetCurShowStorageCellData(index)
	if storageCellData then
		storageCellData:RightClickCell()
	end
end
function PCStorageBar:GetCurPageStorageCellView(index)
	if index <=  self._pageTotalCell * self._selectGroup and index >self._pageTotalCell * (self._selectGroup -1 ) then
		local viewIdx = (index - 1) % self._pageTotalCell + 1
		if viewIdx > 0 then
			local childIdx = FGUI:GList_itemIndexToChildIndex(self._ui.list_storage, viewIdx-1)
			local childNum = FGUI:GetChildCount(self._ui.list_storage)

			if childIdx >= 0 and childIdx < childNum then
				return FGUI:GetChildAt(self._ui.list_storage,childIdx)
			end
		end
	end
end

function PCStorageBar:GetStorageDataIndex(index)
	return   (self._selectGroup -1 ) * self._Row * self._Col +index
end

function PCStorageBar:CheckIndexInPage(index)
	return   index <=  self._pageTotalCell * self._selectGroup and index >self._pageTotalCell * (self._selectGroup -1 )
end

function PCStorageBar:GetCurShowStorageCellData(index)
	if not self:CheckIndexInPage(index) then
		return
	end
	return self._storageCells[index]
end

function PCStorageBar:RefreshPageCount()
	local cur_count = 0
	local allData = self:GetAllStorageData()
	local min_index = self._pageTotalCell * (self._selectGroup-1)
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

function PCStorageBar:InitData()
	-- 6行，仓库每页大小是6x8=48
	self._Row 				 = 6
	local value 			 = SL:GetValue("GAME_DATA", "StoragePageCnt")
	self._Col                = math.ceil(value / self._Row)
	self._pageTotalCell      = value
	self._selectGroup        = 1         -- 当前页数
	self:InitStorageItems()
end

function PCStorageBar:RefreshData()
    self:UpdateStoragePositionData()
	self:SelectPage(self._selectGroup)
    self:RefreshPage()
end

function PCStorageBar:UpdateStorageSize(addSize)
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

function PCStorageBar:InitStorageItems()
	self._storageCells= {}
	local allData = self:GetAllStorageData()
	-- show size
	local openCount = SL:GetValue("STORAGE_OPEN_SIZE") -- 开启的格子数
	local showCount = openCount
	local totalCount = SL:GetValue("STORAGE_MAX_SIZE") -- 服务端最大格子数
	self._totalPage = math.ceil(totalCount / (self._Row * self._Col))

	for i, data in pairs(allData) do
		local index = 0
		if data then
			index = SL:GetValue("STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
		end
		if index > 0 then
			self._storageCells[index] = PCBagCell.new(index,data,false,ItemFrom.STORAGE)
		end
	end
	for i = 1, totalCount do
		local cell = self._storageCells[i]
		if not cell then
			if i <= openCount then
				self._storageCells[i] = PCBagCell.new(i,nil,false,ItemFrom.STORAGE)
			else
				self._storageCells[i] = PCBagCell.new(i,nil,true,ItemFrom.STORAGE)
			end
		end
		self._storageCells[i]:SetDoubleClickDisable(self._disableCellDoubleClick)
		self._storageCells[i]:SetUseItemEnable(false)
	end

	self.FilterText = {}
	for i = 1, self._totalPage do
		self.FilterText[i] = GET_STRING(60003007)..GET_STRING(5000 + i)
	end

end

function PCStorageBar:UpdateStoragePositionData()
	local totalCount = SL:GetValue("STORAGE_MAX_SIZE")
	for i = 1, totalCount do
		local cell = self._storageCells[i]
		if cell then
			self._storageCells[i]:SetItem(nil)
			self._storageCells[i]:SetDoubleClickDisable(self._disableCellDoubleClick)
			self._storageCells[i]:SetUseItemEnable(false)
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

function PCStorageBar:UpdateStoragePosition()
	self:UpdateStoragePositionData()
	self:SelectPage(self._selectGroup)
end

function PCStorageBar:SelectPage(index)
	self._selectGroup = index
	SL:SetValue("STORAGE_SELECT_PAGE",index)
	self:RefreshPage(index)
	self:RefreshPageCount()
    self:RefreshPageNum()
end

-- 刷新页码
function PCStorageBar:RefreshPageNum()
    FGUI:GTextField_setText(self._ui.text_page,self._selectGroup.."/"..self._totalPage)
end

function PCStorageBar:RefreshPage(index)
	index = index or  self._selectGroup
	FGUI:GList_setNumItems(self._ui.list_storage, self._pageTotalCell)
end

-- 获取仓库所有数据
function PCStorageBar:GetAllStorageData()
	local storageData = SL:GetValue("STORAGE_DATA")
	return storageData
end

function PCStorageBar:AddStorageItem(data)
	local newIndex = SL:GetValue("STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex)
	local openCount = SL:GetValue("STORAGE_OPEN_SIZE")
	if not newIndex or newIndex > openCount then
		return
	end

	local viewIndex = newIndex
	self._storageCells[newIndex]:SetItem(data)
	if viewIndex > 0 then
		self:UpdateCellViewByViewId(viewIndex,newIndex)
		self:RefreshPageCount()
	end
end

function PCStorageBar:UnLockStorageCell(newIndex)
	local openCount = SL:GetValue("STORAGE_OPEN_SIZE")
	if not newIndex or newIndex > openCount then
		return
	end

	local viewIndex = newIndex
	if viewIndex > 0 then
		self._storageCells[newIndex]:SetCellLock(false)
	end
end



function PCStorageBar:DeleteStorageItem(data)
	local viewIndex = -1
	local storageCellData = nil
    for i = 1, #self._storageCells do			--事件传过来时数据已经删除了，不能用SL:GetValue("STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex) 获取位置
        storageCellData =  self._storageCells[i]
        local itemData = storageCellData:GetItemData()
        if itemData and itemData.MakeIndex == data.MakeIndex then
            viewIndex = i
            break
        end
    end

	if storageCellData and viewIndex ~= -1 then
		storageCellData:SetItem(nil)
		self:UpdateCellViewByViewIdAndStorageData(viewIndex,storageCellData)
		self:RefreshPageCount()
	end
end

function PCStorageBar:OnUpdateStorageItem(data)
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
		self:RefreshPageCount()
	end
end

function PCStorageBar:BagCellClickEvent(bagItem)
	if bagItem._itemData then
		if bagItem.from == ItemFrom.BAG then
			FGUIFunction:RequestSaveItemToNpcStorageInCurPage(bagItem._itemData)
		elseif bagItem.from == ItemFrom.STORAGE then
			SL:RequestPutOutStorageData(bagItem._itemData)
		end
		bagItem:SetTipEnable(false)
	end
end

function PCStorageBar:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_UPDATE_LIST, "PCStorageBar",  handler(self,self.UpdateStoragePosition))
	SL:RegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_ADD, "PCStorageBar",  handler(self,self.AddStorageItem))
	SL:RegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_DEL, "PCStorageBar",  handler(self,self.DeleteStorageItem))
	SL:RegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_UPDATE, "PCStorageBar",  handler(self,self.OnUpdateStorageItem))
	SL:RegisterLUAEvent(LUA_EVENT_STORAGE_CELL_UNLOCK, "PCStorageBar",  handler(self,self.UpdateStorageSize))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "PCStorageBar",  handler(self,self.BagCellClickEvent))
end


function PCStorageBar:UnRegisterEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_UPDATE_LIST, "PCStorageBar")
	SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_ADD, "PCStorageBar")
	SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_DEL, "PCStorageBar")
	SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_ITEM_UPDATE, "PCStorageBar")
	SL:UnRegisterLUAEvent(LUA_EVENT_STORAGE_CELL_UNLOCK, "PCStorageBar")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "PCStorageBar")
end


return PCStorageBar

