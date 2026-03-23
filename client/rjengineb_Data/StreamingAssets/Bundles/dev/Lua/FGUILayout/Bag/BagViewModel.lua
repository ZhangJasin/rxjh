local BagViewModel = class("BagViewModel")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function BagViewModel:ctor()
	self:InitData()
	self._disableCellDoubleClick = false
end

function BagViewModel:Bind(viewComponent)
	self.viewComponent = viewComponent
end
function BagViewModel:UnBind()
	self.viewComponent = nil
end
function BagViewModel:Enter(data)
	if data then
		self._disableCellDoubleClick = data.disableCellDoubleClick
	else
		self._disableCellDoubleClick = false
	end
	self:RegisterEvent()
	self:RefreshData()
end

function BagViewModel:Exit()
	self:UnRegisterEvent()
end

function BagViewModel:RefreshData()
	self:UpdateBagPosition(true)
end
function BagViewModel:CalculateShowCount()
	local openCount = SL:GetValue("BAG_OPEN_SIZE") -- 开启的格子数
	local totalCount = SL:GetValue("BAG_MAX_SIZE")
	local extra = openCount % self._BagRow
	local showCnt = openCount
	showCnt = showCnt + self._BagRow * 2 - extra
	return math.min(totalCount,showCnt)
end

function BagViewModel:InitData()
	self._BagRow        = 6
	self.selectType    = 1         -- 选中的类型
	self._bagCells      = {}        -- 物品节点
	self:InitBagItems()
end

function BagViewModel:InitBagItems()
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
			self._bagCells[index] = BagCell.new(index,data,false)
			self.itemCnt = self.itemCnt + 1
		end

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
	-- empty and lock
end

function BagViewModel:GetAllBagData()
	local bagData = SL:GetValue("BAG_DATA")
	return bagData
end

function BagViewModel:GetBagCellByIndex(index)
	return  self._bagCells[index]
end
--通过viewIndex获取选择筛选页签之后的要显示的bagData
function BagViewModel:GetCurShowBagCellData(viewIndex)
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

function BagViewModel:GetCurShowBagCellDataAndViewIndexByPos(pos)
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

function BagViewModel:GetItemFilterType(v)
	return ItemUtil:GetItemFilterType(v)
end

--获取pos和MakeIndex映射的dic
function BagViewModel:GetPosMakeIndexList()
	local bagData = SL:GetValue("BAG_SORT_POS_MAKEINDEX_DATA")
	return bagData
end

function BagViewModel:DivideItem()
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

function BagViewModel:AddCellDataToTypeDic(newPos,itemData,checkEmpty)
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

function BagViewModel:GetCellDataPosInTypeDic(itemData)
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

function BagViewModel:DelCellDataToTypeDic(itemData)
	local bagCellData,viewIndex,realType,pos =self:GetCellDataPosInTypeDic(itemData)
	if bagCellData and viewIndex > 0 then
		self._bagCellTypeDic[realType][viewIndex] = -1
		self._bagCellTypeIndexToViewDic[realType][pos] = nil
		return bagCellData,viewIndex,realType
	end
end

function BagViewModel:UpdateBagPosition(enter)
	local totalCount = SL:GetValue("BAG_MAX_SIZE")
	for i = 1, totalCount do
		local cell = self._bagCells[i]
		if cell then
			self._bagCells[i]:SetItem(nil)
			self._bagCells[i]:SetDoubleClickDisable(self._disableCellDoubleClick)
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

	if self.viewComponent then
		self.viewComponent:ResetFilter(enter and 1 or self.selectType)
		self.viewComponent:RefreshPageNum()
	end
end

function BagViewModel:AddBagItem(data)
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

		if self.viewComponent then
			self.viewComponent:UpdateCellViewByViewId(viewIndex,viewIndex)
		end
	end
	if self.viewComponent then
		self.viewComponent:RefreshPageNum()
	end
end

function BagViewModel:DeleteBagItem(data)
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
		self.viewComponent:RefreshPageNum()
	end
end

function BagViewModel:OnUpdateBagItem(data)
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

function BagViewModel:CheckUnLockBagCell(newIndex)
	local openCount = SL:GetValue("BAG_OPEN_SIZE")
	if not newIndex or newIndex > openCount then
		return
	end
	self._bagCells[newIndex]:SetCellLock(false)

end

function BagViewModel:UpdateBagSize(addSize)
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


function BagViewModel:RefreshCurPageBagCell()
	if self.viewComponent then
		self.viewComponent:RefreshCurPageBagCell()
		self.viewComponent:RefreshPageNum()
	end
end
function BagViewModel:RecycleSelectCell(data)
	if not FGUI:CheckOpen("Bag", "BagRecyclePanel") or (not data) then
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

function BagViewModel:GetViewIndexByMakeIndex(MakeIndex)
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
function BagViewModel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE_LIST, "BagViewModel",  handler(self,self.UpdateBagPosition))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_ADD, "BagViewModel",  handler(self,self.AddBagItem))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_DEL, "BagViewModel",  handler(self,self.DeleteBagItem))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE, "BagViewModel",  handler(self,self.OnUpdateBagItem))
	--SL:RegisterLUAEvent(LUA_EVENT_BAG_RECOVERY_UPDATE, "BagViewModel", handler(self, self.OnUpdateBagRecovery))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_CELL_UNLOCK, "BagViewModel",  handler(self,self.UpdateBagSize))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_CHANGE_DELAY, "BagViewModel",  handler(self,self.RecycleSelectCell))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_REFRESH_PAGE, "BagViewModel",  handler(self,self.RefreshCurPageBagCell))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_CD, "BagViewModel",  handler(self,self.RefreshCurPageBagCell))
	SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_ADD,"BagViewModel",handler(self,self.RefreshCurPageBagCell))
	SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_DEL,"BagViewModel",handler(self,self.RefreshCurPageBagCell))
	SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_UPDATE,"BagViewModel",handler(self,self.RefreshCurPageBagCell))
end

function BagViewModel:UnRegisterEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE_LIST, "BagViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_ADD, "BagViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_DEL, "BagViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE, "BagViewModel")
	--SL:UnRegisterLUAEvent(LUA_EVENT_BAG_RECOVERY_UPDATE, "BagViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_CELL_UNLOCK, "BagViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_CHANGE_DELAY, "BagViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_REFRESH_PAGE, "BagViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_CD, "BagViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_ADD, "BagViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_DEL, "BagViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_UPDATE, "BagViewModel")
end


return  BagViewModel.new()