local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local VisitorBagPanel = class("VisitorBagPanel", BaseFGUILayout)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
SL:RequireFile("FGUILayout/Bag/BagCell")

local FilterText = {}

function VisitorBagPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self.packageItemViewCache = {}
	self.cdMaskCache = {}
	self.bagViewModel = requireFGUILayout("Bag/VisitorBagViewModel")
	self:InitView()

end

function VisitorBagPanel:Enter(data)
	self.bagViewModel:Bind(self)
	self.bagViewModel:Enter(data)
	FGUI:ScrollPane_scrollTop(FGUI:GetScrollPane(self._ui.List_Cell), false)

	SL:ComponentAttach(SLDefine.SUIComponentTable.VisitorPlayerInfoBag, self._ui.Node_attach)

	FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.BagGuideFunc,handler(self,self.GetGuideItem))
end

function VisitorBagPanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.VisitorPlayerInfoBag)

	self.bagViewModel:Exit()
	self.bagViewModel:UnBind(self)
	FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.BagGuideFunc)
end

function VisitorBagPanel:CleanItem()
	self:CleanItemViewCache()
end

function VisitorBagPanel:InitView()

	local configValue = SL:GetValue("GAME_DATA", "BackpackTab")
	local arrayNameTable = string.split(configValue, "|")
	FilterText = arrayNameTable

	FGUI:GList_itemRenderer(self._ui.List_Cell, handler(self, self.ListViewBagCellRenderer))
	FGUI:GList_setVirtual(self._ui.List_Cell)
	FGUI:GList_itemRenderer(self._ui.List_Filter, handler(self, self.ListViewFilterRenderer))
	FGUI:GList_addOnClickItemEvent(self._ui.List_Cell, function(context)
		local childIdx = FGUI:GetChildIndex(self._ui.List_Cell, context.data)
		local index = FGUI:GList_childIndexToItemIndex(self._ui.List_Cell, childIdx)
		self:ClickCellEvent(index)
	end)
	FGUI:GList_addOnClickItemEvent(self._ui.List_Filter, function(context)
		local index = FGUI:GetChildIndex(self._ui.List_Filter, context.data) + 1
		self:SelectFilter(index)
	end)

	local filterCnt = FGUI:GList_getNumItems(self._ui.List_Filter)
	for i = 1, filterCnt do
		local obj = FGUI:GetChildAt(self._ui.List_Filter,i - 1)
		self:ListViewFilterRenderer(i,obj)
		if i == 1 then
			FGUI:GButton_FireClick(obj,false,true)
		end
	end

	self.cacheBagCell = BagCell.new(0,nil,true)
end


function VisitorBagPanel:CleanItemViewCache()
	for k, v in pairs(self.packageItemViewCache) do
		if v then
			ItemUtil:ItemShow_Release(v)
		end
	end
	self.packageItemViewCache = { }

	for k,v in pairs(self.cdMaskCache) do
		if v then
			v:Clean()
			v = nil
		end
	end
	self.cdMaskCache = {}
end

function VisitorBagPanel:UpdateCellViewByViewIdAndBagData(viewIndex,bagData)
	local targetView = self:GetCurPageBagCellView(viewIndex)
	if targetView then
		self:UpdateCellView(targetView,bagData)
	end
end

function VisitorBagPanel:UpdateCellViewByViewId(viewIndex,index)
	local targetView = self:GetCurPageBagCellView(viewIndex)
	if targetView then
		self:UpdateCellViewByIndexId(targetView,index)
	end
end
function VisitorBagPanel:UpdateCellViewByIndexId(itemView,index)
	local bagData = self:GetCurShowBagCellData(index)
	self:UpdateCellView(itemView,bagData)
end

function VisitorBagPanel:UpdateCellView(itemView,bagData)
	if not bagData then
		self.cacheBagCell:CopyData(bagData,false)
		bagData = self.cacheBagCell
	end
	local itemData = BagCell.UpdateCellView(itemView,bagData)
    local uid = FGUI:GetID(itemView)
	if self.cdMaskCache[uid] then
		self.cdMaskCache[uid]:Clean()
	end

	if not itemData then
		return
	end
	itemData.isShowCount = true
	local id = FGUI:GetID(itemView)
	local cacheItem = self.packageItemViewCache[id]
	if cacheItem then
		ItemUtil:ItemShow_Release(cacheItem)
	end
	local content = FGUI:GetChild(itemView,"ContentItem")
	local itemContentView =ItemUtil:ItemShow_Create(itemData,content,{disableClick = false})
	self.packageItemViewCache[id] = itemContentView

end

function VisitorBagPanel:ListViewBagCellRenderer(idx, item)
	self:UpdateCellViewByIndexId(item,idx + 1)
end

function VisitorBagPanel:ListViewFilterRenderer(idx, item)
	FGUI:GButton_setTitle(item,FilterText[idx])
end

function VisitorBagPanel:GetCurPageBagCellView(viewIdx)
	if viewIdx > 0 then
		local childIdx = FGUI:GList_itemIndexToChildIndex(self._ui.List_Cell, viewIdx-1)
		local childNum = FGUI:GetChildCount(self._ui.List_Cell)
		if childIdx >= 0 and childIdx < childNum then
			return FGUI:GetChildAt(self._ui.List_Cell,childIdx)
		end
	end
end

function VisitorBagPanel:GetCurShowBagCellData(index)
	local bagData = self.bagViewModel:GetCurShowBagCellData(index)
	if not bagData then
		self.cacheBagCell:CopyData(self.bagViewModel:GetBagCellByIndex(index),false)
		bagData = self.cacheBagCell
	end
	return bagData
end

function VisitorBagPanel:ClickCellEvent(idx)
	local bagData = self:GetCurShowBagCellData(idx + 1)
	bagData:ClickCellEvent()
	if self.clickCellCB then
		self.clickCellCB(bagData)
	end
end

function VisitorBagPanel:SetClickCellCallBack(callback)
	self.clickCellCB = callback
end

function VisitorBagPanel:GetBagDataIndex(index)
	return   index
end

function VisitorBagPanel:DivideItem()
	self.bagViewModel:DivideItem()
end

--viewIndex的格子该渲染itemData
function VisitorBagPanel:AddCellDataToTypeDic(newPos,itemData,checkEmpty)
	return self.bagViewModel:AddCellDataToTypeDic(newPos,itemData,checkEmpty)
end

function VisitorBagPanel:GetCellDataPosInTypeDic(itemData)
	self.bagViewModel:GetCellDataPosInTypeDic(itemData)
end

function VisitorBagPanel:SelectFilter(index)
	self.bagViewModel.selectType = index
	if index > 1 then
		self:DivideItem()
	end

	self:RefreshCurPageBagCell()
	FGUI:GList_scrollToView(self._ui.List_Cell,0,true,true)
end

function VisitorBagPanel:ResetFilter(index)
	local obj = FGUI:GetChildAt(self._ui.List_Filter,index - 1)
	FGUI:GButton_FireClick(obj,false,true)
end

function VisitorBagPanel:RefreshCurPageBagCell()
	local showCnt = self.bagViewModel:CalculateShowCount()
	FGUI:GList_setNumItems(self._ui.List_Cell, showCnt)
end


function VisitorBagPanel:RefreshPageNum()
	local itemCnt = self.bagViewModel.itemCnt
	local openCnt = SL:GetValue("VISITOR_BAG_OPEN_SIZE")--背包可用格子数
	local color = itemCnt < openCnt and "#FFFFFF" or "#FF0000"
	if self._ui.Num then
		FGUI:GTextField_setText(self._ui.Num,string.format("[color=%s]%s/%s[/color]",color,itemCnt,openCnt))
	end
end

function VisitorBagPanel:GetGuideItem(makeIndex)
	local vIdx = self.bagViewModel:GetViewIndexByMakeIndex(makeIndex)
	return self:GetCurPageBagCellView(vIdx)
end

return VisitorBagPanel