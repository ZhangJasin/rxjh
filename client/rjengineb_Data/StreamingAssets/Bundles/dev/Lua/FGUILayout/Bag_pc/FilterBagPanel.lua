SL:RequireFile("FGUILayout/Bag/BagCell")
local BagPanel = requireFGUILayout("Bag/BagPanel")
local FilterBagPanel = class("FilterBagPanel", BagPanel)
local FilterBagViewModel = requireFGUILayout("Bag/FilterBagViewModel")

function FilterBagPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self.packageItemViewCache = {}
	self.cdMaskCache = {}
	self.bagViewModel = FilterBagViewModel.new()
	self:InitView()
end

function FilterBagPanel:Enter(data)
	self.bagViewModel:Bind(self)
	self.bagViewModel:Enter()
	FGUI:ScrollPane_scrollTop(FGUI:GetScrollPane(self._ui.List_Cell), false)
	self.showFilter = data.filterType
	self:SelectFilter(self.showFilter)
end

function FilterBagPanel:Exit()
	self.bagViewModel:Exit()
	self.bagViewModel:UnBind(self)
end

function FilterBagPanel:InitView()
	FGUI:GList_itemRenderer(self._ui.List_Cell, handler(self, self.ListViewBagCellRenderer))
	FGUI:GList_setVirtual(self._ui.List_Cell)
	FGUI:GList_addOnClickItemEvent(self._ui.List_Cell, function(context)
		local childIdx = FGUI:GetChildIndex(self._ui.List_Cell, context.data)
		local index = FGUI:GList_childIndexToItemIndex(self._ui.List_Cell, childIdx)
		self:ClickCellEvent(index)
	end)

	self.cacheBagCell = BagCell.new(0,nil,true)
end

function FilterBagPanel:ResetFilter(index)
	self:SelectFilter(index)
end

function FilterBagPanel:SelectFilter(index)
	self.bagViewModel:SelectFilter(self.showFilter)
	if index > 1 then
		self:DivideItem()
	end
	self:RefreshCurPageBagCell()
end

function FilterBagPanel:RefreshPageNum()

end

return FilterBagPanel