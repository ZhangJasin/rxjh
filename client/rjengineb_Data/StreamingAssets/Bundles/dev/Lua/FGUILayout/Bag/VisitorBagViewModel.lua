local VisitorBagViewModel = class("VisitorBagViewModel")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function VisitorBagViewModel:ctor()
	self:InitData()
	self._disableCellDoubleClick = false
end

function VisitorBagViewModel:Bind(viewComponent)
	self.viewComponent = viewComponent
end
function VisitorBagViewModel:UnBind()
	self.viewComponent = nil
end
function VisitorBagViewModel:Enter(data)
	if data then
		self._disableCellDoubleClick = data.disableCellDoubleClick
	else
		self._disableCellDoubleClick = false
	end
	self:RefreshData()
end

function VisitorBagViewModel:Exit()
	
end

function VisitorBagViewModel:RefreshData()
	self:UpdateBagPosition(true)
end
function VisitorBagViewModel:CalculateShowCount()
	local openCount = SL:GetValue("VISITOR_BAG_OPEN_SIZE") -- 背包可用格子数
	local totalCount = SL:GetValue("VISITOR_BAG_MAX_SIZE") -- 背包最大格子数
	local extra = openCount % self._BagRow
	local showCnt = openCount
	showCnt = showCnt + self._BagRow * 2 - extra
	return math.min(totalCount,showCnt)
end

function VisitorBagViewModel:InitData()
	self._BagRow        = 6
	self.selectType    = 1         -- 选中的类型
	self._bagCells      = {}        -- 物品节点
	self:InitBagItems()
end

function VisitorBagViewModel:InitBagItems()
	self._bagCells = {}			--所有的bagcell
	self._bagCellTypeDic = {}	--用于筛选的dic,存放bagcell索引
	self._bagCellTypeIndexToViewDic = {}	--用于筛选的dic,存放bagcell index to viewIndex 的索引
	-- show size
	local openCount = SL:GetValue("VISITOR_BAG_OPEN_SIZE") -- 背包可用格子数
	local showCount = self:CalculateShowCount() -- 客户端显示格子数
	local totalCount = SL:GetValue("VISITOR_BAG_MAX_SIZE")-- 背包最大格子数
	local allData = self:GetAllBagData()
	self.itemCnt = 0
	for i, data in pairs(allData) do
		local index = 0
		if data then
			index = SL:GetValue("VISITOR_BAG_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
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

function VisitorBagViewModel:GetAllBagData()
	local bagData = SL:GetValue("VISITOR_BAG_DATA")
	return bagData
end

function VisitorBagViewModel:GetBagCellByIndex(index)
	return  self._bagCells[index]
end
--通过viewIndex获取选择筛选页签之后的要显示的bagData
function VisitorBagViewModel:GetCurShowBagCellData(viewIndex)
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

function VisitorBagViewModel:GetCurShowBagCellDataAndViewIndexByPos(pos)
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

function VisitorBagViewModel:GetItemFilterType(v)
	return ItemUtil:GetItemFilterType(v)
end

--获取pos和MakeIndex映射的dic
function VisitorBagViewModel:GetPosMakeIndexList()
	local bagData = SL:GetValue("VISITOR_BAG_SORT_POS_MAKEINDEX_DATA")
	return bagData
end

function VisitorBagViewModel:DivideItem()
	self._bagCellTypeDic = {}
	local allDataWithPos =self:GetPosMakeIndexList()
	for k, v in ipairs(allDataWithPos) do
		if k > 0 and v then
			local itemData =  SL:GetValue("VISITOR_BAG_DATA_BY_MAKEINDEX",v)
			if itemData then
				self:AddCellDataToTypeDic(k,itemData)
			end
		end
	end
end

function VisitorBagViewModel:AddCellDataToTypeDic(newPos,itemData,checkEmpty)
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

function VisitorBagViewModel:GetCellDataPosInTypeDic(itemData)
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

function VisitorBagViewModel:DelCellDataToTypeDic(itemData)
	local bagCellData,viewIndex,realType,pos =self:GetCellDataPosInTypeDic(itemData)
	if bagCellData and viewIndex > 0 then
		self._bagCellTypeDic[realType][viewIndex] = -1
		self._bagCellTypeIndexToViewDic[realType][pos] = nil
		return bagCellData,viewIndex,realType
	end
end

function VisitorBagViewModel:UpdateBagPosition(enter)
	local totalCount = SL:GetValue("VISITOR_BAG_MAX_SIZE")-- 背包最大格子数
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
			index = SL:GetValue("VISITOR_BAG_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
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

function VisitorBagViewModel:AddBagItem(data)
	local newIndex = SL:GetValue("VISITOR_BAG_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
	local openCount = SL:GetValue("VISITOR_BAG_OPEN_SIZE")-- 背包可用格子数
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

function VisitorBagViewModel:DeleteBagItem(data)
	local viewIndex = -1
	local bagCellData = nil
	local realType = -1

	if self.selectType == 1 then
		for i = 1, #self._bagCells do
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

function VisitorBagViewModel:OnUpdateBagItem(data)
	local newIndex = SL:GetValue("VISITOR_BAG_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
	local bagCell = self._bagCells[newIndex]
	local viewIndex = newIndex
	if self.selectType > 1 then
		bagCell,viewIndex = self:GetCellDataPosInTypeDic(data)
	end
	local thisItemData = SL:GetValue("VISITOR_BAG_DATA_BY_MAKEINDEX", data.MakeIndex)
	if bagCell and thisItemData and viewIndex > 0 then
		bagCell:SetItem(thisItemData)
		if self.viewComponent then
			self.viewComponent:UpdateCellViewByViewId(viewIndex,viewIndex)
		end
	end
end

function VisitorBagViewModel:CheckUnLockBagCell(newIndex)
	local openCount = SL:GetValue("VISITOR_BAG_OPEN_SIZE")--背包可用格子数
	if not newIndex or newIndex > openCount then
		return
	end
	self._bagCells[newIndex]:SetCellLock(false)

end

function VisitorBagViewModel:UpdateBagSize(addSize)
	local totalCount = SL:GetValue("VISITOR_BAG_MAX_SIZE")-- 背包最大格子数
	local openCount = SL:GetValue("VISITOR_BAG_OPEN_SIZE") --背包可用格子数

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


function VisitorBagViewModel:RefreshCurPageBagCell()
	if self.viewComponent then
		self.viewComponent:RefreshCurPageBagCell()
		self.viewComponent:RefreshPageNum()
	end
end
function VisitorBagViewModel:RecycleSelectCell(data)
	if not FGUI:CheckOpen("VisitorBagViewModel", "BagRecyclePanel") or (not data) then
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

function VisitorBagViewModel:GetViewIndexByMakeIndex(MakeIndex)
	local newIndex = SL:GetValue("VISITOR_BAG_POS_MARK_BY_MAKEINDEX", MakeIndex) or 0
	local itemData =  SL:GetValue("VISITOR_BAG_DATA_BY_MAKEINDEX",MakeIndex)
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

return  VisitorBagViewModel.new()