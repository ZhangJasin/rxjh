local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCBagPanel = class("PCBagPanel", BaseFGUILayout)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
SL:RequireFile("FGUILayout/Bag_pc/PCBagCell")

local FilterText = {}

function PCBagPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self.packageItemViewCache = {}
	self.cdMaskCache = {}
	-- 鼠标是否进入父界面
	self.bagRecycleViewModel = requireFGUILayout("Bag_pc/PCBagRecycleViewModel")
	self.bagViewModel = requireFGUILayout("Bag_pc/PCBagViewModel")
	self:InitView()
end

function PCBagPanel:Enter(data)
	self.bagViewModel:Bind(self)
	self.bagViewModel:Enter(data)
	-- FGUI:ScrollPane_scrollTop(FGUI:GetScrollPane(self._ui.List_Cell), false)
	SL:ComponentAttach(SLDefine.SUIComponentTable.PlayerInfoBag, self._ui.Node_attach)
	FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.BagGuideFunc,handler(self,self.GetGuideItem))
end

function PCBagPanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.PlayerInfoBag)
	self.bagViewModel:Exit()
	self.bagViewModel:UnBind(self)
	FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.BagGuideFunc)
end

function PCBagPanel:CleanItem()
	self:CleanItemViewCache()
end

function PCBagPanel:InitView()
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

	self.cacheBagCell = PCBagCell.new(0,nil,true)
end

function PCBagPanel:CleanItemViewCache()
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

function PCBagPanel:UpdateCellViewByViewIdAndBagData(viewIndex,bagData)
	local targetView = self:GetCurPageBagCellView(viewIndex)
	if targetView then
		self:UpdateCellView(targetView,bagData)
	end
end

function PCBagPanel:UpdateCellViewByViewId(viewIndex,index)
	local targetView = self:GetCurPageBagCellView(viewIndex)
	if targetView then
		self:UpdateCellViewByIndexId(targetView,index)
	end
end
function PCBagPanel:UpdateCellViewByIndexId(itemView,index)
	local bagData = self:GetCurShowBagCellData(index)
	self:UpdateCellView(itemView,bagData)
end

function PCBagPanel:OnDelayClickEnd()
    self.clickDelay = false
end

function PCBagPanel:onCellDropEvent(itemView,eventData)
	self.clickDelay = true
	SL:ScheduleOnce(handler(self, self.OnDelayClickEnd, nil, true), 0.1)
	local childIdx = FGUI:GetChildIndex(self._ui.List_Cell, itemView)
	local endPos = FGUI:GList_childIndexToItemIndex(self._ui.List_Cell, childIdx)
	-- 左键
	if eventData.inputEvent.button == 0 and
        eventData.data and 
        eventData.data.makeIndex then
		-- 在第一个页签里换位置
		if eventData.data.from and eventData.data.from == ItemFrom.BAG then
			if eventData.data.dragStartSelectPage 
				and eventData.data.dragStartSelectPage == 1 -- 开始拖拽的页签
				and self.bagViewModel.selectType == 1 then	-- 结束拖拽的页签(保证数据都在第一个页签里,防止滚轮操作)
				self.bagViewModel:ExChangeTwoPos(eventData.data.makeIndex,endPos + 1)
			end
			return
		end
		-- 装备从身上拖到背包里脱装备
		if eventData.data.from and eventData.data.from == ItemFrom.PALYER_EQUIP then
			local equipData = SL:GetValue("EQUIP_DATA_BY_MAKEINDEX",eventData.data.makeIndex)
			if self.bagViewModel.selectType == 1 then
				-- 判断放置位置是否有物品(有物品则自动放置)
				local bagCellData = self.bagViewModel:GetCurShowBagCellData(endPos + 1)
				if not bagCellData:GetItemData() then
					Bag.setWillDragToPos(eventData.data.makeIndex,endPos + 1)
				end
			end
			if equipData then
				SL:TakeOffPlayerEquip(equipData)
			end
			return
		end

		-- 从仓库拖入背包
		if eventData.data.from and eventData.data.from == ItemFrom.STORAGE then
			if self.bagViewModel.selectType == 1 then
				-- 判断放置位置是否有物品(有物品则自动放置)
				local bagCellData = self.bagViewModel:GetCurShowBagCellData(endPos + 1)
				if not bagCellData:GetItemData() then
					Bag.setWillDragToPos(eventData.data.makeIndex,endPos + 1)
				end
			end

			local storageData = SL:GetValue("STORAGE_DATA_BY_MAKEINDEX",eventData.data.makeIndex)
			if storageData then
				SL:RequestPutOutStorageData(storageData)
			end
			return
		end

		-- 从面对面交易拖入背包
		if eventData.data.from and eventData.data.from == ItemFrom.TRADE then
			local isMyLock = SL:GetValue("TRADE_MY_STATUS") == 1
			local isTargetLock = SL:GetValue("TRADE_TARGET_STATUS") == 1
			if isMyLock or isTargetLock then
				SL:ShowSystemTips(GET_STRING(90180031))
				return
			end
			SL:RemoveItemFromTrade(eventData.data.makeIndex)
		end
	end
end

function PCBagPanel:UpdateCellView(itemView,bagData)
	if not bagData then
		self.cacheBagCell:CopyData(bagData,false)
		bagData = self.cacheBagCell
	end
	local itemData = PCBagCell.UpdateCellView(itemView,bagData)
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
		FGUI:setOnDropEvent(itemView,handler(self,self.onCellDropEvent,itemView))
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
		FGUIFunction:CloseItemTips()
		local touchId = FGUI:InputEvent_getTouchId(eventData)
		local data = {
			type = FGUIDefine.PCQuickType.Item,
			itemIndex = itemData.Index,
			makeIndex = itemData.MakeIndex,
			from = ItemFrom.BAG,
			dragStartSelectPage = self.bagViewModel.selectType, -- 页签判断防止滚轮操作
		}
		
		-- 1.使用原图,尺寸可能偏大
		FGUI:DragDropManager_startDrag(itemContentView.component,"ui://public_pc/CommonItem",data,touchId,FGUIFunction.CloseBagCheckDragView)
		FGUIFunction:OpenBagCheckDragView()
		local commmonItem = FGUI:GLoader_getComponent(FGUI:DragDropManager_getDragAgent())
		ItemUtil:SetItemIconByItemID(commmonItem,itemData.Index)
		ItemUtil:UpdateItemGradeByItemID(commmonItem,itemData.Index)
	end)

	FGUI:setOnRightClickEvent(itemContentView.component,function(eventData)
		if self.clickDelay then return end
		FGUIFunction:CloseItemTips()
		-- 组合键alt + 右键
		if eventData.inputEvent.alt and  itemData.OverLap > 1 then
			local uiData = {}
			uiData.itemData = itemData
			uiData.maxNum = itemData.OverLap
			uiData.title = GET_STRING(30000300)
			uiData.btnNames = {GET_STRING(30000300)}
			uiData.btnClicked = function(isOK,num)
			    if isOK == 1 then
			        if num > 0 then
			            SL:RequestSplitItem(itemData, num)
			        end
			        FGUI:Close("Common_pc", "PCCommonItemSplitDialog")
			    elseif isOK == 2 then
			        FGUI:Close("Common_pc", "PCCommonItemSplitDialog")
			    end
			end
			FGUIFunction:OpenItemSplitPop(uiData)
		else
			self:RightClickEvent(index)
		end
	end)
end

function PCBagPanel:ListViewBagCellRenderer(idx, item)
	self:UpdateCellViewByIndexId(item,idx + 1)
end

function PCBagPanel:ListViewFilterRenderer(idx, item)
	FGUI:GButton_setTitle(item,FilterText[idx])
end

function PCBagPanel:GetCurPageBagCellView(viewIdx)
	if viewIdx > 0 then
		local childIdx = FGUI:GList_itemIndexToChildIndex(self._ui.List_Cell, viewIdx-1)
		local childNum = FGUI:GetChildCount(self._ui.List_Cell)
		if childIdx >= 0 and childIdx < childNum then
			return FGUI:GetChildAt(self._ui.List_Cell,childIdx)
		end
	end
end

function PCBagPanel:GetCurShowBagCellData(index)
	local bagData = self.bagViewModel:GetCurShowBagCellData(index)
	if not bagData then
		self.cacheBagCell:CopyData(self.bagViewModel:GetBagCellByIndex(index),false)
		bagData = self.cacheBagCell
	end
	return bagData
end

function PCBagPanel:RightClickEvent(idx)
	local bagData = self:GetCurShowBagCellData(idx + 1)
	if bagData then
		bagData:RightClickCell()
	end
	
	if self.clickCellCB and bagData then
		self.clickCellCB(bagData)
	end
end

function PCBagPanel:RollOverEvent(idx)
	local bagData = self:GetCurShowBagCellData(idx + 1)
	if bagData then
		bagData:RollOverCell()
	end
end

function PCBagPanel:RollOutEvent(idx)
	local bagData = self:GetCurShowBagCellData(idx + 1)
	if bagData then
		bagData:RollOutCell()
	end
end

function PCBagPanel:SetClickCellCallBack(callback)
	self.clickCellCB = callback
end

function PCBagPanel:GetBagDataIndex(index)
	return  index
end

function PCBagPanel:DivideItem()
	self.bagViewModel:DivideItem()
end

--viewIndex的格子该渲染itemData
function PCBagPanel:AddCellDataToTypeDic(newPos,itemData,checkEmpty)
	return self.bagViewModel:AddCellDataToTypeDic(newPos,itemData,checkEmpty)
end

function PCBagPanel:GetCellDataPosInTypeDic(itemData)
	self.bagViewModel:GetCellDataPosInTypeDic(itemData)
end

function PCBagPanel:SelectFilter(index)
	self.bagViewModel.selectType = index
	if index > 1 then
		self:DivideItem()
	end
	self:RefreshCurPageBagCell()
	FGUI:GList_scrollToView(self._ui.List_Cell,0,true,true)
end

function PCBagPanel:ResetFilter(index)
	local obj = FGUI:GetChildAt(self._ui.List_Filter,index - 1)
	FGUI:GButton_FireClick(obj,false,true)
end

function PCBagPanel:RefreshCurPageBagCell()
	local showCnt = self.bagViewModel:CalculateShowCount()
	FGUI:GList_setNumItems(self._ui.List_Cell, showCnt)
end

function PCBagPanel:RefreshPageNum()
	local itemCnt = self.bagViewModel.itemCnt
	local openCnt = SL:GetValue("BAG_OPEN_SIZE")
	local color = itemCnt < openCnt and "#FFFFFF" or "#FF0000"
	if self._ui.Num then
		FGUI:GTextField_setText(self._ui.Num,string.format("[color=%s]%s/%s[/color]",color,itemCnt,openCnt))
	end
end

function PCBagPanel:GetGuideItem(makeIndex)
	local vIdx = self.bagViewModel:GetViewIndexByMakeIndex(makeIndex)
	return self:GetCurPageBagCellView(vIdx)
end

return PCBagPanel