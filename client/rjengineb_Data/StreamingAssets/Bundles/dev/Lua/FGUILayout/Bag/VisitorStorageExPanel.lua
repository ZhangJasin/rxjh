local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorStorageExPanel = class("VisitorStorageExPanel", BaseFGUILayout)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
SL:RequireFile("FGUILayout/Bag/BagCell")

function VisitorStorageExPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self._storageId = 0
	self._bagCells = {}
	self._storageCells = {}
	self._slot_slotInfo_map = {} -- 仓库 槽位 槽位信息映射
	self._infoKey_slot_map = {}

	self._ui.bagCellList = FGUI:GetChild(self._ui.view_bag, "List_Cell")
	self.handler_storageItemRenderer = handler(self, self.ListViewStorageCellRenderer)
	FGUI:SetCloseUIWhenClickOutside(self)
	FGUI:setOnClickEvent(self._ui.BtnClose, handler(self, self.Close))
	-- 仓库列表显示
	FGUI:GList_itemRenderer(self._ui.List_Cell, self.handler_storageItemRenderer)
	FGUI:GList_setVirtual(self._ui.List_Cell)
end

function VisitorStorageExPanel:Enter()
	self._storageId = 1
	self:OnRefreshStorageExData(0)
	FGUI:GTextField_setText(self._ui.Title, SL:GetValue("STORAGE_EX_NAME", self._storageId)) --附加仓库名字 从表里面读的
end

function VisitorStorageExPanel:Exit()
	self:ClearData()
	FGUI:Open("Bag","VisitorPlayerInfoPanel",1)
end

function VisitorStorageExPanel:Destroy()
	self:CleanItemViewCache()
end

function VisitorStorageExPanel:Close()
	self.super.Close(self)
end

function VisitorStorageExPanel:ClearData()
	self._storageId = 0
	self._bagCells = {}
	self._storageCells = {}
	self._slot_slotInfo_map = {} -- 仓库 槽位 槽位信息映射
	self._infoKey_slot_map = {}
end

-- 附加仓库ItemRenderer刷新
function VisitorStorageExPanel:ListViewStorageCellRenderer(idx, item)
	local openCount = SL:GetValue("VISITOR_STORAGE_EX_OPEN_SIZE", self._storageId)
	local index = idx + 1
	if index > 0 and index <= openCount then
		self._storageCells[index]:SetCellLock(false)
	end
	local storageData = self._storageCells[index]
	self:UpdateCellView(item ,storageData)
end

local packageItemViewCache = {}
function VisitorStorageExPanel:CleanItemViewCache()
	for k, v in pairs(packageItemViewCache) do
		if v then
			ItemUtil:ItemShow_Release(v)
		end
	end
	packageItemViewCache = { }
end


function VisitorStorageExPanel:UpdateCellView(itemView, bagData)
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
function VisitorStorageExPanel:OnRefreshStorageExData(classify)
	local classifyId = classify or 0

	local allData = SL:GetValue("VISITOR_STORAGE_EX_DATA", self._storageId, classifyId) or {} --不需要分类

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

	local openCount = SL:GetValue("VISITOR_STORAGE_EX_OPEN_SIZE", self._storageId)
	local totalCount =  SL:GetValue("VISITOR_STORAGE_EX_TOTAL_SIZE", self._storageId)
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
function VisitorStorageExPanel:ConvertData(slotInfo)
	local itemData = clone(SL:GetValue("ITEM_DATA", slotInfo.Index))
	itemData.Index = slotInfo.Index
	itemData.Params = slotInfo.Params
	itemData.OverLap = slotInfo.OverLap
	itemData.Bind = slotInfo.Params[1]
	itemData.Star = slotInfo.Params[2]
	return itemData
end

return VisitorStorageExPanel