local PCBagViewModelForHS = class("PCBagViewModelForHS")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

SL:RequireFile("FGUILayout/Bag_pc/PCBagCellForHS")

function PCBagViewModelForHS:ctor()
	self:InitData()
	self._disableCellDoubleClick = false
	self._itemUse = true
end

function PCBagViewModelForHS:Bind(viewComponent)
	self.viewComponent = viewComponent
end
function PCBagViewModelForHS:UnBind()
	self.viewComponent = nil
end
function PCBagViewModelForHS:Enter(data)
	if data then
		self._disableCellDoubleClick = data.disableCellDoubleClick
	else
		self._disableCellDoubleClick = false
	end

	if data and data.itemUse ~= nil then
		self._itemUse = data.itemUse
	end

	self:RegisterEvent()
	self:RefreshData()
end

function PCBagViewModelForHS:Exit()
	self:UnRegisterEvent()
end

function PCBagViewModelForHS:RefreshData()
	self:UpdateBagPosition(true)
end
function PCBagViewModelForHS:CalculateShowCount()
	local openCount = SL:GetValue("BAG_OPEN_SIZE") -- 开启的格子数
	local totalCount = SL:GetValue("BAG_MAX_SIZE")
	local extra = openCount % self._BagRow
	local showCnt = openCount
	showCnt = showCnt + self._BagRow * 2 - extra
	return math.min(totalCount,showCnt)
end

function PCBagViewModelForHS:InitData()
	self._BagRow        = 6
	self.selectType    = 1         -- 选中的类型
	self._bagCells      = {}        -- 物品节点
	self:InitBagItems()
end

function PCBagViewModelForHS:InitBagItems()
	self._bagCells = {}			--所有的bagcell
	self._bagCellTypeDic = {}	--用于筛选的dic,存放bagcell索引
	self._bagCellTypeIndexToViewDic = {}	--用于筛选的dic,存放bagcell index to viewIndex 的索引
	-- show size
	local openCount = SL:GetValue("BAG_OPEN_SIZE") -- 开启的格子数
	local showCount = self:CalculateShowCount() -- 客户端显示格子数
	local totalCount = SL:GetValue("BAG_MAX_SIZE")
	local allData = self:GetAllBagData()
	self.itemCnt = 0
	for i, data in pairs(allData) do
		local index = 0
		if data then
			index = SL:GetValue("BAG_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
		end
		if index > 0 then
			self._bagCells[index] = PCBagCellForHS.new(index,data,false)
			self.itemCnt = self.itemCnt + 1
		end

	end
	for i = 1, totalCount do
		local cell = self._bagCells[i]
		if not cell then
			if i <= openCount then
				self._bagCells[i] = PCBagCellForHS.new(i,nil,false)
			else
				self._bagCells[i] = PCBagCellForHS.new(i,nil,true)
			end
		end
	end
end

function PCBagViewModelForHS:GetAllBagData()
	local bagData = SL:GetValue("BAG_DATA")
	return bagData
end

function PCBagViewModelForHS:GetBagCellByIndex(index)
	return  self._bagCells[index]
end

function PCBagViewModelForHS:ExChangeTwoPos(dragMakeIndex,newPos)
	if not SL:GetValue("IS_PC_OPER_MODE") then
		return
	end

	if not dragMakeIndex or not newPos then
		return
	end

	if self.selectType == 1 then
		local dragStartStartViewIndex = SL:GetValue("BAG_POS_MARK_BY_MAKEINDEX",dragMakeIndex)
		if dragStartStartViewIndex and dragStartStartViewIndex == newPos then
			return
		end
		
		if self._bagCells[dragStartStartViewIndex] and self._bagCells[newPos] then
			self._bagCells[dragStartStartViewIndex],self._bagCells[newPos] = self._bagCells[newPos],self._bagCells[dragStartStartViewIndex]
			SL:SetValue("BAG_EXCHANGE_TWO_ITEM_POS",dragStartStartViewIndex,newPos)
			SL:Print("数据交换成功")
		end
	end
end

--通过viewIndex获取选择筛选页签之后的要显示的bagData
function PCBagViewModelForHS:GetCurShowBagCellData(viewIndex)
	if self.selectType == 1 then
		return  self._bagCells[viewIndex]
	else
		local bagCellByType = self._bagCellTypeDic[ self.selectType]
		local bagCellIndex

		if bagCellByType then
			bagCellIndex = self._bagCellTypeDic[ self.selectType][viewIndex]
		end
		if bagCellIndex and bagCellIndex > -1 then
			return self._bagCells[bagCellIndex]
		end
	end
end

function PCBagViewModelForHS:GetCurShowBagCellDataAndViewIndexByPos(pos)
	local index =  pos
	local viewIndex =  pos
	local res = nil
	if self.selectType == 1 then
		res = self._bagCells[index]
	else
		local bagCellByType = self._bagCellTypeDic[ self.selectType]
		local bagViewIndex

		if bagCellByType then
			bagViewIndex = self._bagCellTypeIndexToViewDic[self.selectType][pos]
		end
		if bagViewIndex and bagViewIndex > -1 then
			res = self._bagCells[index]
			viewIndex = bagViewIndex
		end
	end
	return res,viewIndex
end

function PCBagViewModelForHS:GetItemFilterType(v)
	return ItemUtil:GetItemFilterType(v)
end

--获取pos和MakeIndex映射的dic
function PCBagViewModelForHS:GetPosMakeIndexList()
	local bagData = SL:GetValue("BAG_SORT_POS_MAKEINDEX_DATA")
	return bagData
end

function PCBagViewModelForHS:DivideItem()
	self._bagCellTypeDic = {}
	local allDataWithPos =self:GetPosMakeIndexList()
	for k, v in ipairs(allDataWithPos) do
		if k > 0 and v then
			local itemData =  SL:GetValue("BAG_DATA_BY_MAKEINDEX",v)
			if itemData then
				self:AddCellDataToTypeDic(k,itemData)
			end
		end
	end
end

function PCBagViewModelForHS:AddCellDataToTypeDic(newPos,itemData,checkEmpty)
	local realType = self:GetItemFilterType(itemData)
	if not self._bagCellTypeDic[realType] then
		self._bagCellTypeDic[realType] = {}
	end
	if not self._bagCellTypeIndexToViewDic[realType] then
		self._bagCellTypeIndexToViewDic[realType] = {}
	end
	local viewIndex = -1
	if checkEmpty then
		for i = 1,  #self._bagCellTypeDic[realType] do
			if self._bagCellTypeDic[realType][i] == -1 then
				self._bagCellTypeDic[realType][i] = newPos
				self._bagCellTypeIndexToViewDic[realType][newPos] = i
				viewIndex = i
				break
			end
		end
	end
	if viewIndex == -1 then
		viewIndex = #self._bagCellTypeDic[realType] + 1
		self._bagCellTypeDic[realType][viewIndex] = newPos
		self._bagCellTypeIndexToViewDic[realType][newPos] = viewIndex
	end
	if realType == self.selectType then
		return viewIndex
	else
		return -1
	end
end

function PCBagViewModelForHS:GetCellDataPosInTypeDic(itemData)
	local realType = self:GetItemFilterType(itemData)
	if not self._bagCellTypeDic[realType] then
		self._bagCellTypeDic[realType] = {}
	end
	if not self._bagCellTypeIndexToViewDic[realType] then
		self._bagCellTypeIndexToViewDic[realType] = {}
	end
	local l = #self._bagCellTypeDic[realType]
	for i = 1, l do
		local  pos = self._bagCellTypeDic[realType][i]
		if pos and pos > -1 then
			local bagCellData =  self._bagCells[pos]
			local data = bagCellData:GetItemData()
			if data and itemData.MakeIndex == data.MakeIndex then
				return bagCellData,i,realType,pos
			end
		end
	end
end

function PCBagViewModelForHS:DelCellDataToTypeDic(itemData)
	local bagCellData,viewIndex,realType,pos =self:GetCellDataPosInTypeDic(itemData)
	if bagCellData and viewIndex > 0 then
		self._bagCellTypeDic[realType][viewIndex] = -1
		self._bagCellTypeIndexToViewDic[realType][pos] = nil
		return bagCellData,viewIndex,realType
	end
end

function PCBagViewModelForHS:UpdateBagPosition(enter)
	local totalCount = SL:GetValue("BAG_MAX_SIZE")
	for i = 1, totalCount do
		local cell = self._bagCells[i]
		if cell then
			self._bagCells[i]:SetItem(nil)
			self._bagCells[i]:SetDoubleClickDisable(self._disableCellDoubleClick)
			self._bagCells[i]:SetUseItemEnable(self._itemUse)
		end
		self:CheckUnLockBagCell(i)
	end
	self.itemCnt = 0
	local allData = self:GetAllBagData()
	for i, data in pairs(allData) do
		local index = 0
		if data then
			index = SL:GetValue("BAG_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
		end
		if index > 0 then
			self.itemCnt = self.itemCnt + 1
			self._bagCells[index]:SetItem(data)
		end
	end

	-- 兼容两种面板
	if self.viewComponent then
		if self.viewComponent.ResetFilter then
			self.viewComponent:ResetFilter(enter and 1 or self.selectType)
		end

		if self.viewComponent.RefreshPageNum then
			self.viewComponent:RefreshPageNum()
		end
	end
end

function PCBagViewModelForHS:AddBagItem(data)
	local newIndex = SL:GetValue("BAG_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
	local openCount = SL:GetValue("BAG_OPEN_SIZE")
	self.itemCnt = self.itemCnt + 1
	if not newIndex or newIndex > openCount then
		return
	end

	local viewIndex = newIndex
	if self.selectType > 1 then
		viewIndex = self:AddCellDataToTypeDic(newIndex,data,true)
	end

	self._bagCells[newIndex]:SetItem(data)

	if viewIndex > 0 then
		local  bagCellData =  self:GetCurShowBagCellData(viewIndex)
		if bagCellData then
			bagCellData:SetItem(data)
		end

		if self.viewComponent and self.viewComponent.UpdateCellViewByViewId then
			self.viewComponent:UpdateCellViewByViewId(viewIndex,viewIndex)
		end
	end
	if self.viewComponent and self.viewComponent.RefreshPageNum then
		self.viewComponent:RefreshPageNum()
	end
end

function PCBagViewModelForHS:DeleteBagItem(data)
	local viewIndex = -1
	local bagCellData = nil
	local realType = -1

	if self.selectType == 1 then
		for i = 1, #self._bagCells do			--事件传过来时数据已经删除了,不能用SL:GetValue("BAG_POS_MARK_BY_MAKEINDEX", data.MakeIndex) 获取位置
			bagCellData =  self._bagCells[i]
			local itemData = bagCellData:GetItemData()
			if itemData and itemData.MakeIndex == data.MakeIndex then
				viewIndex = i
				break
			end
		end
	else
		bagCellData,viewIndex,realType = self:DelCellDataToTypeDic(data)
	end

	if bagCellData and viewIndex ~= -1 then
		bagCellData:SetItem(nil)
		if (self.selectType == 1 or realType == self.selectType) then
			if self.viewComponent then
				self.viewComponent:UpdateCellViewByViewIdAndBagData(viewIndex,bagCellData)
			end
		end
	end
	self.itemCnt = self.itemCnt - 1
	if self.viewComponent then
		if self.viewComponent.RefreshPageNum then
			self.viewComponent:RefreshPageNum()
		end
	end
end

function PCBagViewModelForHS:OnUpdateBagItem(data)
	local newIndex = SL:GetValue("BAG_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
	local bagCell = self._bagCells[newIndex]
	local viewIndex = newIndex
	if self.selectType > 1 then
		bagCell,viewIndex = self:GetCellDataPosInTypeDic(data)
	end
	local thisItemData = SL:GetValue("BAG_DATA_BY_MAKEINDEX", data.MakeIndex)
	if bagCell and thisItemData and viewIndex > 0 then
		bagCell:SetItem(thisItemData)
		if self.viewComponent then
			self.viewComponent:UpdateCellViewByViewId(viewIndex,viewIndex)
		end
	end
end

function PCBagViewModelForHS:CheckUnLockBagCell(newIndex)
	local openCount = SL:GetValue("BAG_OPEN_SIZE")
	if not newIndex or newIndex > openCount then
		return
	end
	self._bagCells[newIndex]:SetCellLock(false)

end

function PCBagViewModelForHS:UpdateBagSize(addSize)
	local totalCount = SL:GetValue("BAG_MAX_SIZE")
	local openCount = SL:GetValue("BAG_OPEN_SIZE")

	if addSize and addSize > 0 then
		local maxCnt = openCount < totalCount and openCount or totalCount
		for i = openCount - addSize, maxCnt do
			self:CheckUnLockBagCell(i)
		end
		if self.viewComponent then
			self:RefreshCurPageBagCell()
		end
	end
end


function PCBagViewModelForHS:RefreshCurPageBagCell()
	if self.viewComponent then
		if self.viewComponent.RefreshCurPageBagCell then
			self.viewComponent:RefreshCurPageBagCell()
		end

		if self.viewComponent.RefreshPageNum then
			self.viewComponent:RefreshPageNum()
		end
	end
end
function PCBagViewModelForHS:RecycleSelectCell(data)
	if not FGUI:CheckOpen("Bag_pc", "BagRecyclePanel") or (not data) then
		return
	end

	local isSelect = data.isSelect
	local selectList = data.selectList

	for i = 1, #selectList do
		local index = selectList[i].pos
		self._bagCells[index]:SetRecycleSelect(isSelect)
		local  res,viewIndex = self:GetCurShowBagCellDataAndViewIndexByPos(index)
		if res and viewIndex and viewIndex > 0 and self.viewComponent then
			self.viewComponent:UpdateCellViewByViewIdAndBagData(viewIndex,res)
		end
	end

end

function PCBagViewModelForHS:GetViewIndexByMakeIndex(MakeIndex)
	local newIndex = SL:GetValue("BAG_POS_MARK_BY_MAKEINDEX", MakeIndex) or 0
	local itemData =  SL:GetValue("BAG_DATA_BY_MAKEINDEX",MakeIndex)
	local viewIndex = -1
	if itemData then
		if self.selectType > 1  then
			local bagCell;
			bagCell,viewIndex = self:GetCellDataPosInTypeDic(itemData)
		else
			viewIndex = newIndex
		end
	end
	return viewIndex
end

--------------------------- 注册事件 -----------------------------
function PCBagViewModelForHS:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE_LIST, "PCBagViewModelForHS",  handler(self,self.UpdateBagPosition))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_ADD, "PCBagViewModelForHS",  handler(self,self.AddBagItem))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_DEL, "PCBagViewModelForHS",  handler(self,self.DeleteBagItem))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE, "PCBagViewModelForHS",  handler(self,self.OnUpdateBagItem))
	--SL:RegisterLUAEvent(LUA_EVENT_BAG_RECOVERY_UPDATE, "PCBagViewModelForHS", handler(self, self.OnUpdateBagRecovery))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_CELL_UNLOCK, "PCBagViewModelForHS",  handler(self,self.UpdateBagSize))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_CHANGE_DELAY, "PCBagViewModelForHS",  handler(self,self.RecycleSelectCell))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_REFRESH_PAGE, "PCBagViewModelForHS",  handler(self,self.RefreshCurPageBagCell))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_CD, "PCBagViewModelForHS",  handler(self,self.RefreshCurPageBagCell))
	SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_ADD,"PCBagViewModelForHS",handler(self,self.RefreshCurPageBagCell))
	SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_DEL,"PCBagViewModelForHS",handler(self,self.RefreshCurPageBagCell))
	SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_UPDATE,"PCBagViewModelForHS",handler(self,self.RefreshCurPageBagCell))
end

function PCBagViewModelForHS:UnRegisterEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE_LIST, "PCBagViewModelForHS")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_ADD, "PCBagViewModelForHS")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_DEL, "PCBagViewModelForHS")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE, "PCBagViewModelForHS")
	--SL:UnRegisterLUAEvent(LUA_EVENT_BAG_RECOVERY_UPDATE, "PCBagViewModelForHS")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_CELL_UNLOCK, "PCBagViewModelForHS")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_CHANGE_DELAY, "PCBagViewModelForHS")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_REFRESH_PAGE, "PCBagViewModelForHS")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_CD, "PCBagViewModelForHS")
	SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_ADD, "PCBagViewModelForHS")
	SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_DEL, "PCBagViewModelForHS")
	SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_UPDATE, "PCBagViewModelForHS")
end


return  PCBagViewModelForHS.new()