local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local BagPanel = class("BagPanel", BaseFGUILayout)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
SL:RequireFile("FGUILayout/Bag/BagCell")

local FilterText = {}

function BagPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	self.packageItemViewCache = {}
	self.cdMaskCache = {}
	self.bagViewModel = requireFGUILayout("Bag/BagViewModel")
	self:InitView()

end

function BagPanel:Enter(data)
	self.bagViewModel:Bind(self)
	self.bagViewModel:Enter(data)
	FGUI:ScrollPane_scrollTop(FGUI:GetScrollPane(self._ui.List_Cell), false)

	SL:ComponentAttach(SLDefine.SUIComponentTable.PlayerInfoBag, self._ui.Node_attach)

	FGUIFunction:RegisterGuideData(FGUIDefine.GuideDataKey.BagGuideFunc,handler(self,self.GetGuideItem))

	------------交易行截图begin----------
	local typeCapture = global.TradingCaptureDatas and global.TradingCaptureDatas.typeCapture
	if type(typeCapture) == "number" and typeCapture == 2 then
		SL:ScheduleOnce(function ()
			local ITEM_WIDTH  	= 64 	-- 每个格子的宽度
			local ITEM_HEIGHT 	= 64 	-- 每个格子的高度
			local GAP_Y 	  	= 12  	-- 格子之间的垂直行间距
			
			global.TradingBagPanelDatas = global.TradingBagPanelDatas or {}

			local rows = (type(global.TradingBagPanelDatas.rows_per_page) == "number" and global.TradingBagPanelDatas.rows_per_page > 0) and global.TradingBagPanelDatas.rows_per_page or 6
			local cols = (type(global.TradingBagPanelDatas.cols_per_page) == "number" and global.TradingBagPanelDatas.cols_per_page > 0) and global.TradingBagPanelDatas.cols_per_page or 6
			global.TradingBagPanelDatas.rows_per_page = rows
			global.TradingBagPanelDatas.cols_per_page = cols
		
			GAP_Y = FGUI:GList_getLineGap(self._ui.List_Cell)
			ITEM_WIDTH,ITEM_HEIGHT  = FGUI:GList_getDefaultItemSize(self._ui.List_Cell)
			local ROW_HEIGHT 		= ITEM_HEIGHT + GAP_Y
			local scrollPane 		= FGUI:GetScrollPane(self._ui.List_Cell)
			local currentPosY   	= FGUI:ScrollPane_getPosY(scrollPane)

			local index = global.TradingBagPanelDatas.index or 1
			global.TradingBagPanelDatas.index = index

			local nextPosY = currentPosY + global.TradingBagPanelDatas.rows_per_page * ROW_HEIGHT * index
			FGUI:ScrollPane_setPosY(scrollPane, nextPosY)
			global.TradingBagPanelDatas.index = global.TradingBagPanelDatas.index + 1
		end,0.2)
	end
	------------交易行截图end----------
end

function BagPanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.PlayerInfoBag)

	self.bagViewModel:Exit()
	self.bagViewModel:UnBind(self)
	FGUIFunction:UnRegisterGuideData(FGUIDefine.GuideDataKey.BagGuideFunc)
end

function BagPanel:CleanItem()
	self:CleanItemViewCache()
end


function BagPanel:InitView()

	local configValue = SL:GetValue("GAME_DATA", "BackpackTab")
	local arrayNameTable = string.split(configValue, "|")
	FilterText = arrayNameTable

	FGUI:setOnClickEvent(self._ui.BtnSort,function ()
		SL:RequestRefreshBagPos()
	end)

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


function BagPanel:CleanItemViewCache()
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

function BagPanel:UpdateCellViewByViewIdAndBagData(viewIndex,bagData)
	local targetView = self:GetCurPageBagCellView(viewIndex)
	if targetView then
		self:UpdateCellView(targetView,bagData)
	end
end

function BagPanel:UpdateCellViewByViewId(viewIndex,index)
	local targetView = self:GetCurPageBagCellView(viewIndex)
	if targetView then
		self:UpdateCellViewByIndexId(targetView,index)
	end
end
function BagPanel:UpdateCellViewByIndexId(itemView,index)
	local bagData = self:GetCurShowBagCellData(index)
	self:UpdateCellView(itemView,bagData)
end

function BagPanel:UpdateCellView(itemView,bagData)
	if not bagData then
		self.cacheBagCell:CopyData(bagData,false)
		bagData = self.cacheBagCell
	end
	local itemData = BagCell.UpdateCellView(itemView,bagData)
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

end



function BagPanel:ListViewBagCellRenderer(idx, item)
	self:UpdateCellViewByIndexId(item,idx + 1)
end

function BagPanel:ListViewFilterRenderer(idx, item)
	FGUI:GButton_setTitle(item,FilterText[idx])
end

function BagPanel:GetCurPageBagCellView(viewIdx)
	if viewIdx > 0 then
		local childIdx = FGUI:GList_itemIndexToChildIndex(self._ui.List_Cell, viewIdx-1)
		local childNum = FGUI:GetChildCount(self._ui.List_Cell)
		if childIdx >= 0 and childIdx < childNum then
			return FGUI:GetChildAt(self._ui.List_Cell,childIdx)
		end
	end
end


function BagPanel:GetCurShowBagCellData(index)
	local bagData = self.bagViewModel:GetCurShowBagCellData(index)
	if not bagData then
		self.cacheBagCell:CopyData(self.bagViewModel:GetBagCellByIndex(index),false)
		bagData = self.cacheBagCell
	end
	return bagData
end


function BagPanel:ClickCellEvent(idx)
	local bagData = self:GetCurShowBagCellData(idx + 1)
	bagData:ClickCellEvent()
	if self.clickCellCB then
		self.clickCellCB(bagData)
	end
end

function BagPanel:SetClickCellCallBack(callback)
	self.clickCellCB = callback
end

function BagPanel:GetBagDataIndex(index)
	return   index
end

function BagPanel:DivideItem()
	self.bagViewModel:DivideItem()
end

--viewIndex的格子该渲染itemData
function BagPanel:AddCellDataToTypeDic(newPos,itemData,checkEmpty)
	return self.bagViewModel:AddCellDataToTypeDic(newPos,itemData,checkEmpty)
end

function BagPanel:GetCellDataPosInTypeDic(itemData)
	self.bagViewModel:GetCellDataPosInTypeDic(itemData)
end

function BagPanel:SelectFilter(index)
	self.bagViewModel.selectType = index
	if index > 1 then
		self:DivideItem()
	end

	self:RefreshCurPageBagCell()
	FGUI:GList_scrollToView(self._ui.List_Cell,0,true,true)
end

function BagPanel:ResetFilter(index)
	local obj = FGUI:GetChildAt(self._ui.List_Filter,index - 1)
	FGUI:GButton_FireClick(obj,false,true)
end

function BagPanel:RefreshCurPageBagCell()
	local showCnt = self.bagViewModel:CalculateShowCount()
	FGUI:GList_setNumItems(self._ui.List_Cell, showCnt)
end


function BagPanel:RefreshPageNum()
	local itemCnt = self.bagViewModel.itemCnt
	local openCnt = SL:GetValue("BAG_OPEN_SIZE")
	local color = itemCnt < openCnt and "#FFFFFF" or "#FF0000"
	if self._ui.Num then
		FGUI:GTextField_setText(self._ui.Num,string.format("[color=%s]%s/%s[/color]",color,itemCnt,openCnt))
	end
	------------交易行截图begin----------
	local typeCapture = global.TradingCaptureDatas and global.TradingCaptureDatas.typeCapture
	if type(typeCapture) == "number" then
		global.TradingBagPanelDatas = global.TradingBagPanelDatas or {}
		global.TradingBagPanelDatas.itemCnt = (itemCnt == 0) and 1 or itemCnt

		local rows = (type(global.TradingBagPanelDatas.rows_per_page) == "number" and global.TradingBagPanelDatas.rows_per_page > 0) and global.TradingBagPanelDatas.rows_per_page or 6
		local cols = (type(global.TradingBagPanelDatas.cols_per_page) == "number" and global.TradingBagPanelDatas.cols_per_page > 0) and global.TradingBagPanelDatas.cols_per_page or 6
		global.TradingBagPanelDatas.rows_per_page = rows
		global.TradingBagPanelDatas.cols_per_page = cols

		global.TradingBagPanelDatas.totalIndex = (itemCnt == 0) and 1 or math.ceil(itemCnt/(rows*cols))
	end
	------------交易行截图end----------
end

function BagPanel:GetGuideItem(makeIndex)
	local vIdx = self.bagViewModel:GetViewIndexByMakeIndex(makeIndex)
	return self:GetCurPageBagCellView(vIdx)
end

return BagPanel