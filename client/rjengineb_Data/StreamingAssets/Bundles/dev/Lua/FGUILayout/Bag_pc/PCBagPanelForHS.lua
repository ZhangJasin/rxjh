local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCBagPanelForHS = class("PCBagPanelForHS", BaseFGUILayout)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

SL:RequireFile("FGUILayout/Bag_pc/PCBagCellForHS")

local FilterText = {}

function PCBagPanelForHS:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self.packageItemViewCache = {}
	self.cdMaskCache = {}
	-- 鼠标是否进入父界面
	self.bagRecycleViewModel = requireFGUILayout("Bag_pc/BagRecycleViewModel")
	self.bagViewModel = requireFGUILayout("Bag_pc/PCBagViewModelForHS")
	self:InitView()
end

function PCBagPanelForHS:Enter(data)
	self.bagViewModel:Bind(self)
	self.bagViewModel:Enter(data)
	-- FGUI:ScrollPane_scrollTop(FGUI:GetScrollPane(self._ui.List_Cell), false)
	SL:ComponentAttach(SLDefine.SUIComponentTable.PlayerInfoBag, self._ui.Node_attach)
	FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.BagGuideFunc,handler(self,self.GetGuideItem))
end

function PCBagPanelForHS:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.PlayerInfoBag)
	self.bagViewModel:Exit()
	self.bagViewModel:UnBind(self)
	FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.BagGuideFunc)
end

function PCBagPanelForHS:CleanItem()
	self:CleanItemViewCache()
end

function PCBagPanelForHS:InitView()
	local configValue = SL:GetValue("GAME_DATA", "BackpackTab")
	local arrayNameTable = string.split(configValue, "|")
	FilterText = arrayNameTable

	FGUI:setOnClickEvent(self._ui.BtnSort,function ()
		SL:RequestRefreshBagPos()
	end)

	FGUI:GList_itemRenderer(self._ui.List_Cell, handler(self, self.ListViewBagCellRenderer))
	FGUI:GList_setVirtual(self._ui.List_Cell)
	FGUI:GList_itemRenderer(self._ui.List_Filter, handler(self, self.ListViewFilterRenderer))
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

	self.cacheBagCell = PCBagCellForHS.new(0,nil,true)
end

function PCBagPanelForHS:CleanItemViewCache()
	for k, v in pairs(self.packageItemViewCache) do
		if v then
			ItemUtil:ItemShow_Release(v)
		end
	end
	self.packageItemViewCache = {}

	for k,v in pairs(self.cdMaskCache) do
		if v then
			v:Clean()
			v = nil
		end
	end
	self.cdMaskCache = {}
end

function PCBagPanelForHS:UpdateCellViewByViewIdAndBagData(viewIndex,bagData)
	local targetView = self:GetCurPageBagCellView(viewIndex)
	if targetView then
		self:UpdateCellView(targetView,bagData)
	end
end

function PCBagPanelForHS:UpdateCellViewByViewId(viewIndex,index)
	local targetView = self:GetCurPageBagCellView(viewIndex)
	if targetView then
		self:UpdateCellViewByIndexId(targetView,index)
	end
end
function PCBagPanelForHS:UpdateCellViewByIndexId(itemView,index)
	local bagData = self:GetCurShowBagCellData(index)
	self:UpdateCellView(itemView,bagData)
end

function PCBagPanelForHS:OnDelayClickEnd()
    self.clickDelay = false
end

function PCBagPanelForHS:onCellDropEvent(itemView,eventData)
	self.clickDelay = true
	SL:ScheduleOnce(handler(self, self.OnDelayClickEnd, nil, true), 0.1)
	local childIdx = FGUI:GetChildIndex(self._ui.List_Cell, itemView)
	local endPos = FGUI:GList_childIndexToItemIndex(self._ui.List_Cell, childIdx)
	-- 左键
end

function PCBagPanelForHS:UpdateCellView(itemView,bagData)
	if not bagData then
		self.cacheBagCell:CopyData(bagData,false)
		bagData = self.cacheBagCell
	end
	local itemData = PCBagCellForHS.UpdateCellView(itemView,bagData)
    local uid = FGUI:GetID(itemView)
	if self.cdMaskCache[uid] then
		self.cdMaskCache[uid]:Clean()
	end

	if bagData._itemId then
		local endTime = SL:GetValue("ITEM_CD_ENDTIME",bagData._itemId)
		local useTime = SL:GetValue("ITEM_CD_USETIME",bagData._itemId)
		if endTime and useTime then
			local timeDisTotal = endTime - useTime
			local timeDis = endTime - SL:GetValue("SERVER_TIME")
			if timeDis > 0 then
				if not self.cdMaskCache[uid] then
					self.cdMaskCache[uid] = SL:CreateCDMask(itemView,timeDis,timeDisTotal,1,false,true)
				else
					self.cdMaskCache[uid]:UpdateTime(timeDis,timeDisTotal)
					self.cdMaskCache[uid]:DoCD()
				end
			end
		end
	end
	-- 只在第一个页签拖拽有意义
	if self.bagViewModel.selectType == 1 then
		-- FGUI:setOnDropEvent(itemView,handler(self,self.onCellDropEvent,itemView))
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
	local itemContentView =ItemUtil:ItemShow_Create(itemData,content,{disableClick = true})
	self.packageItemViewCache[id] = itemContentView	
	local childIdx = FGUI:GetChildIndex(self._ui.List_Cell, itemView)
	local index = FGUI:GList_childIndexToItemIndex(self._ui.List_Cell, childIdx)

	FGUI:setOnRollOverEvent(itemContentView.component, function()
		if FGUI:DragDropManager_getDragging() then
			return
		end
		self:RollOverEvent(index)
	end)

    FGUI:setOnRollOutEvent(itemContentView.component, function()
		if FGUI:DragDropManager_getDragging() then
			return
		end
		self:RollOutEvent(index)
	end)

	FGUI:setOnClickEvent(itemContentView.component, function(eventData)
		if self.clickDelay then return end
		-- 回收界面左键点击选中/取消选中
		if FGUI:CheckOpen("Bag_pc", "BagRecyclePanel") then
			FGUIFunction:CloseItemTips()
			local bagData = self:GetCurShowBagCellData(index + 1)
			if bagData then
				SL:onLUAEvent(LUA_EVENT_BAG_CELL_CLICK, bagData)
			end
		end
	end)

	FGUI:setOnRightClickEvent(itemContentView.component,function(eventData)
		if self.clickDelay then return end
		FGUIFunction:CloseItemTips()
		self:RightClickEvent(index)
	end)
end

function PCBagPanelForHS:ListViewBagCellRenderer(idx, item)
	self:UpdateCellViewByIndexId(item,idx + 1)
end

function PCBagPanelForHS:ListViewFilterRenderer(idx, item)
	FGUI:GButton_setTitle(item,FilterText[idx])
end

function PCBagPanelForHS:GetCurPageBagCellView(viewIdx)
	if viewIdx > 0 then
		local childIdx = FGUI:GList_itemIndexToChildIndex(self._ui.List_Cell, viewIdx-1)
		local childNum = FGUI:GetChildCount(self._ui.List_Cell)
		if childIdx >= 0 and childIdx < childNum then
			return FGUI:GetChildAt(self._ui.List_Cell,childIdx)
		end
	end
end

function PCBagPanelForHS:GetCurShowBagCellData(index)
	local bagData = self.bagViewModel:GetCurShowBagCellData(index)
	if not bagData then
		self.cacheBagCell:CopyData(self.bagViewModel:GetBagCellByIndex(index),false)
		bagData = self.cacheBagCell
	end
	return bagData
end

function PCBagPanelForHS:RightClickEvent(idx)
	local bagData = self:GetCurShowBagCellData(idx + 1)
	if bagData then
		bagData:RightClickCell()
	end
end

function PCBagPanelForHS:RollOverEvent(idx)
	local bagData = self:GetCurShowBagCellData(idx + 1)
	if bagData then
		bagData:RollOverCell()
	end
end

function PCBagPanelForHS:RollOutEvent(idx)
	local bagData = self:GetCurShowBagCellData(idx + 1)
	if bagData then
		bagData:RollOutCell()
	end
end

function PCBagPanelForHS:SetClickCellCallBack(callback)
	self.clickCellCB = callback
end

function PCBagPanelForHS:GetBagDataIndex(index)
	return  index
end

function PCBagPanelForHS:DivideItem()
	self.bagViewModel:DivideItem()
end

--viewIndex的格子该渲染itemData
function PCBagPanelForHS:AddCellDataToTypeDic(newPos,itemData,checkEmpty)
	return self.bagViewModel:AddCellDataToTypeDic(newPos,itemData,checkEmpty)
end

function PCBagPanelForHS:GetCellDataPosInTypeDic(itemData)
	self.bagViewModel:GetCellDataPosInTypeDic(itemData)
end

function PCBagPanelForHS:SelectFilter(index)
	self.bagViewModel.selectType = index
	if index > 1 then
		self:DivideItem()
	end
	self:RefreshCurPageBagCell()
	FGUI:GList_scrollToView(self._ui.List_Cell,0,true,true)
end

function PCBagPanelForHS:ResetFilter(index)
	local obj = FGUI:GetChildAt(self._ui.List_Filter,index - 1)
	FGUI:GButton_FireClick(obj,false,true)
end

function PCBagPanelForHS:RefreshCurPageBagCell()
	local showCnt = self.bagViewModel:CalculateShowCount()
	FGUI:GList_setNumItems(self._ui.List_Cell, showCnt)
end

function PCBagPanelForHS:RefreshPageNum()
	local itemCnt = self.bagViewModel.itemCnt
	local openCnt = SL:GetValue("BAG_OPEN_SIZE")
	local color = itemCnt < openCnt and "#FFFFFF" or "#FF0000"
	if self._ui.Num then
		FGUI:GTextField_setText(self._ui.Num,string.format("[color=%s]%s/%s[/color]",color,itemCnt,openCnt))
	end
end

function PCBagPanelForHS:GetGuideItem(makeIndex)
	local vIdx = self.bagViewModel:GetViewIndexByMakeIndex(makeIndex)
	return self:GetCurPageBagCellView(vIdx)
end

return PCBagPanelForHS