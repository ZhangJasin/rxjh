local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorStoragePanel = class("VisitorStoragePanel", BaseFGUILayout)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
SL:RequireFile("FGUILayout/Bag/BagCell")

function VisitorStoragePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
	self.firstEnter = true
	self._disableCellDoubleClick = true

	self:InitData()
	self:InitView()
end

function VisitorStoragePanel:Enter(data)
	if data then
		self.fromPanel = data.fromPanel
	end
	self:RefreshData()
	self.firstEnter = false
	self.bagPanel:Enter({ disableCellDoubleClick = self._disableCellDoubleClick} )
	SL:ComponentAttach(SLDefine.SUIComponentTable.VisitorStorage, self._ui.Node_attach)
end

function VisitorStoragePanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.VisitorStorage)
	self.bagPanel:Exit()
end

function VisitorStoragePanel:Destroy()
	self:CleanItemViewCache()
	self.bagPanel:CleanItem()
end

function VisitorStoragePanel:Close()
	self.super.Close(self)
	if self.fromPanel and  self.fromPanel == 1 then
		FGUI:Open("Bag","VisitorPlayerInfoPanel",1)
	end
end

function VisitorStoragePanel:ListViewStorageCellRenderer(idx, item)
	local index = self:GetStorageDataIndex(idx + 1)
	self:UnLockStorageCell(index)
	self:UpdateCellViewByIndexId(item,index)
end
function VisitorStoragePanel:InitView()

	FGUI:GList_itemRenderer(self._ui.List_Cell, handler(self, self.ListViewStorageCellRenderer))
	FGUI:GList_addOnClickItemEvent(self._ui.List_Cell, function(context)
		local childIdx = FGUI:GetChildIndex(self._ui.List_Cell, context.data)
		local index = FGUI:GList_childIndexToItemIndex(self._ui.List_Cell, childIdx)
		self:ClickCellEvent(index)
	end)
	FGUI:GList_setVirtual(self._ui.List_Cell)

	self.cacheStorageCell = BagCell.new(0,nil,true)

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


	if not self.bagPanel then
		self.bagPanel = FGUI:CreateObject(self._ui.BagNode, "Bag", "VisitorBagPanel", true)
	end
end

local packageItemViewCache = {}
function VisitorStoragePanel:CleanItemViewCache()
	for k, v in pairs(packageItemViewCache) do
		if v then
			ItemUtil:ItemShow_Release(v)
		end
	end
	packageItemViewCache = { }
end

function VisitorStoragePanel:UpdateCellViewByIndexId(itemView,index)
	local storageData = self:GetCurShowStorageCellData(index)
	self:UpdateCellView(itemView,storageData)
end

function VisitorStoragePanel:UpdateCellView(itemView,bagData)
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

function VisitorStoragePanel:ListViewFilterRenderer(idx, item)
	FGUI:GButton_setTitle(item,self.FilterText[idx + 1])
end

function VisitorStoragePanel:GetStorageDataIndex(index)
	return   (self._selectGroup -1 ) * self._Row * self._Col +index
end

function VisitorStoragePanel:CheckIndexInPage(index)
	return   index <=  self._pageTotalCell * self._selectGroup and index >self._pageTotalCell * (self._selectGroup -1 )
end

function VisitorStoragePanel:GetCurShowStorageCellData(index)
	if not self:CheckIndexInPage(index) then
		return
	end
	return self._storageCells[index]
end
function VisitorStoragePanel:InitData()

	self._Row                = 6
	local value 			 = SL:GetValue("GAME_DATA", "StoragePageCnt")
	self._Col                = math.ceil(value / self._Row)
	self._pageTotalCell = value

	self._selectGroup   = 1         -- 当前页数
	self._selectType    = 1			-- 筛选

	self:InitStorageItems()
end

function VisitorStoragePanel:RefreshData()
	if not self.firstEnter then
		self:UpdateStoragePositionData()
		self:RefreshPage()
	end
end

function VisitorStoragePanel:InitStorageItems()
    local totalCount = SL:GetValue("VISITOR_STORAGE_MAX_SIZE")
	local openCount  = SL:GetValue("VISITOR_STORAGE_OPEN_SIZE")

	self._storageCells= {}
	local allData = self:GetAllStorageData()
	-- show size
	self._totalPage = math.ceil(totalCount / (self._Row * self._Col))

	for i, data in pairs(allData) do
		local index = 0
		if data then
			index = SL:GetValue("VISITOR_STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
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

function VisitorStoragePanel:UpdateStoragePositionData()
    local totalCount =  SL:GetValue("VISITOR_STORAGE_MAX_SIZE")
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
			index = SL:GetValue("VISITOR_STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
		end
		if index > 0 then
			self._storageCells[index]:SetItem(data)
		end
	end
end

function VisitorStoragePanel:GetSelectPage()
	return self._selectGroup
end

function VisitorStoragePanel:SelectPage(index)
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
function VisitorStoragePanel:RefreshPage(index)
	index =index or  self._selectGroup
	FGUI:GList_setNumItems(self._ui.List_Cell, self._pageTotalCell)
end

function VisitorStoragePanel:ClickCellEvent(idx)
	local  index = self:GetStorageDataIndex(idx + 1)
	local storageCellData = self:GetCurShowStorageCellData(index)
	storageCellData:ClickCellEvent()
end

-- 获取仓库所有数据
function VisitorStoragePanel:GetAllStorageData()
    return SL:GetValue("VISITOR_STORAGE_DATA")
end

-- 显示当前数量
function VisitorStoragePanel:RefreshPageNum()
	local openCount =  SL:GetValue("VISITOR_STORAGE_OPEN_SIZE")

	local cur_count = 0
	local allData = self:GetAllStorageData()
	local min_index = self._pageTotalCell * (self._selectGroup - 1)
	local max_index = self._pageTotalCell * (self._selectGroup)
	for i, data in pairs(allData) do
		if data then
			local index = SL:GetValue("VISITOR_STORAGE_POS_MARK_BY_MAKEINDEX", data.MakeIndex) or 0
			if min_index < index and index <= max_index then
				cur_count = cur_count + 1
			end
		end
	end
	
	local color = cur_count < self._pageTotalCell and "#FFFFFF" or "#FF0000"
	if self._ui.text_count then
		local curPageNum = openCount - self._pageTotalCell * (self._selectGroup - 1)
		if curPageNum > self._pageTotalCell then
			curPageNum = self._pageTotalCell
		end
		FGUI:GTextField_setText(self._ui.text_count,string.format("[color=%s]%s/%s[/color]",color,cur_count,curPageNum >=0 and curPageNum or 0))
	end
end


function VisitorStoragePanel:UnLockStorageCell(newIndex)
	local openCount =  SL:GetValue("VISITOR_STORAGE_OPEN_SIZE")
	if not newIndex or newIndex > openCount then
		return
	end

	local viewIndex = newIndex
	if viewIndex > 0 then
		self._storageCells[newIndex]:SetCellLock(false)
	end
end


return VisitorStoragePanel
