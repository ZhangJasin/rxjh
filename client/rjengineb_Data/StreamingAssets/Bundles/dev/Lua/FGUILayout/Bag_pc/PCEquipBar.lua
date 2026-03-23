local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCEquipBar = class("PCEquipBar", BaseFGUILayout)
local EQUIP_POS_COUNT = 13
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

function PCEquipBar:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUIFunction:setWindowDrag(self.component, self._ui.bg)
	self.bagViewModel = FGUIFunction:BindClass(self,"Bag_pc/PCBagViewModel")
    self:GetAllFGuiData()
    self:InitOnClickEvent()
    self:InitData()
    self:InitUI()
end

function PCEquipBar:GetAllFGuiData()
    self.btn_close = self._ui.btn_close
    self.btn_cloakSwitch = self._ui.btn_cloakSwitch
    self.btn_sort = self._ui.btn_sort
	self.btn_storage = self._ui.btn_storage
    self.list_bag = self._ui.list_bag

    self.pos12 = self._ui.pos12 -- 弓箭手专有装备格
	self.pos1 = self._ui.pos1

	self.ctl_clothKind = FGUI:getController(self.btn_cloakSwitch,"clothKind")
	-- 获取武器槽位的控制器
    self.ctrl_equipPosDI = FGUI:getController(self.pos1,"equipPosDI")
end

function PCEquipBar:InitData()
    self.equipMentSlots = {}
    -- 保存对应位置的ROOT后续操作频率高
    for index = 0,EQUIP_POS_COUNT do
        self.equipMentSlots[index] = self._ui["pos" .. (index+1)]
        FGUI:setOnDropEvent(self.equipMentSlots[index],handler(self,self.DropOnEquipSlot,index))
    end

    self.equipMentObjList = {}
    self.packageItemViewCache = {}
	self.cdMaskCache = {}
end

function PCEquipBar:RefreshCurPageBagCell()
	local showCnt = self.bagViewModel:CalculateShowCount(8)
	FGUI:GList_setNumItems(self._ui.list_bag, showCnt)
end

function PCEquipBar:CleanItemViewCache()
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

function PCEquipBar:UpdateCellViewByViewIdAndBagData(viewIndex,bagData)
	local targetView = self:GetCurPageBagCellView(viewIndex)
	if targetView then
		self:UpdateCellView(targetView,bagData)
	end
end

function PCEquipBar:GetCurPageBagCellView(viewIdx)
	if viewIdx > 0 then
		local childIdx = FGUI:GList_itemIndexToChildIndex(self.list_bag, viewIdx-1)
		local childNum = FGUI:GetChildCount(self.list_bag)
		if childIdx >= 0 and childIdx < childNum then
			return FGUI:GetChildAt(self.list_bag,childIdx)
		end
	end
end


-- 拖拽放置装备
function PCEquipBar:DropOnEquipSlot(index,eventData)
	self.clickDelay = true
    SL:ScheduleOnce(handler(self, self.OnDelayClickEnd, nil, true), 0.1)
    if eventData and 
        eventData.data and 
        eventData.data.makeIndex then

        if eventData.data.from and eventData.data.from == ItemFrom.BAG then 
            local itemData = SL:GetValue("BAG_DATA_BY_MAKEINDEX",eventData.data.makeIndex)
            if itemData then
                SL:TakeOnPlayerEquip(itemData,index)
            end
        end
    end
end

function PCEquipBar:OnDelayClickEnd()
    self.clickDelay = false
end

function PCEquipBar:UpdateCellView(itemView,bagData)
    if not bagData then
        return
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

    FGUI:setOnDropEvent(itemView,handler(self,self.onCellDropEvent,itemView))
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
	local childIdx = FGUI:GetChildIndex(self.list_bag, itemView)
	local index = FGUI:GList_childIndexToItemIndex(self.list_bag, childIdx)
	
	FGUI:setOnClickEvent(self.packageItemViewCache[id].component, function(eventData)
		if self.clickDelay then return end
		local touchId = FGUI:InputEvent_getTouchId(eventData)
		local data = {
			type = FGUIDefine.PCQuickType.Item,
			itemIndex = itemData.Index,
			makeIndex = itemData.MakeIndex,
			from = ItemFrom.BAG,
		}

		-- 1.使用原图,尺寸可能偏大
		FGUI:DragDropManager_startDrag(itemContentView.component,"ui://public_pc/CommonItem", data, touchId,FGUIFunction.CloseBagCheckDragView)
		FGUIFunction:OpenBagCheckDragView()
		local commmonItem = FGUI:GLoader_getComponent(FGUI:DragDropManager_getDragAgent())
		ItemUtil:RefreshItemUIByData(commmonItem,itemData)
	end)

	FGUI:setOnRightClickEvent(self.packageItemViewCache[id].component,function(eventData)
		if self.clickDelay then return end
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

-- 背包槽
function PCEquipBar:onCellDropEvent(itemView,eventData)
	self.clickDelay = true
	SL:ScheduleOnce(handler(self, self.OnDelayClickEnd, nil, true), 0.1)
	local childIdx = FGUI:GetChildIndex(self.list_bag, itemView)
	local endPos = FGUI:GList_childIndexToItemIndex(self.list_bag, childIdx)
	if FGUI:InputEvent_getButton(eventData) == 0 and
        eventData.data and 
        eventData.data.makeIndex then
		-- 在第一个页签里换位置
		if eventData.data.from and eventData.data.from == ItemFrom.BAG then
			self.bagViewModel:ExChangeTwoPos(eventData.data.makeIndex,endPos + 1)
			return
		end
		-- 装备从身上拖到背包里脱装备
		if eventData.data.from and eventData.data.from == ItemFrom.PALYER_EQUIP then
			local equipData = SL:GetValue("EQUIP_DATA_BY_MAKEINDEX",eventData.data.makeIndex)
			if self.bagViewModel.selectType == 1 then
				-- 判断放置位置是否有物品(有物品则自动放置)
				if not self.bagViewModel:GetCurShowBagCellData(endPos + 1) then
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
	end
end

function PCEquipBar:UpdateCellViewByViewId(viewIndex,index)
	local targetView = self:GetCurPageBagCellView(viewIndex)
	if targetView then
		self:UpdateCellViewByIndexId(targetView,index)
	end
end

function PCEquipBar:InitOnClickEvent()
    FGUI:setOnClickEvent(self.btn_cloakSwitch,handler(self,self.BtnCloakSwitchClicked))
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_sort,handler(self,self.BtnSortClicked))
	FGUI:setOnClickEvent(self.btn_storage,handler(self,self.BtnStorageClicked))
end

function PCEquipBar:BtnSortClicked()
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	SL:RequestRefreshBagPos()
end

function PCEquipBar:BtnStorageClicked(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	FGUI:Open("Bag_pc","PCStorageBar")
end


function PCEquipBar:Refresh()
    self:RefreshCurPageBagCell()
end

function PCEquipBar:InitUI()
    FGUI:GList_itemRenderer(self.list_bag,handler(self,self.ListViewBagCellRenderer))
	FGUI:GList_setVirtual(self.list_bag)
end

function PCEquipBar:ListViewBagCellRenderer(idx,item)
    self:UpdateCellViewByIndexId(item,idx + 1)
end

function PCEquipBar:UpdateCellViewByIndexId(itemView,index)
	local bagData = self:GetCurShowBagCellData(index)
	self:UpdateCellView(itemView,bagData)
end

function PCEquipBar:GetCurShowBagCellData(index)
	local bagData = self.bagViewModel:GetCurShowBagCellData(index)
	if not bagData then
		self.cacheBagCell:CopyData(self.bagViewModel:GetBagCellByIndex(index),false)
		bagData = self.cacheBagCell
	end
	return bagData
end

function PCEquipBar:BtnCloakSwitchClicked(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

    SL:RequestOperateIsOpenFashion(not SL:GetValue("SETTING_GET_IS_SHOW_FASHION"))
end

function PCEquipBar:ReleaseAllEquipItem()
    for k,v in pairs(self.equipMentObjList) do
        if v then
            ItemUtil:ItemShow_Release(v)
        end
    end
    self.equipMentObjList = {}
end

function PCEquipBar:RefreshScheme()
    self:RefreshBtnCloakSwitch()
    self:ReleaseAllEquipItem()
    self:RefreshEquipCheck()
    self:RefreshEquipByPos()
end

-- 弓手职业才显示
function PCEquipBar:RefreshEquipCheck()
    -- 弓手职业才显示
    FGUI:setVisible(self.pos12,SL:GetValue("JOB") == global.MMO.ACTOR_PLAYER_JOB_1)
    -- 查看fgui控制器equipPosDI设置(图标对应职业)
    FGUI:Controller_setSelectedIndex(self.ctrl_equipPosDI,11 + SL:GetValue("JOB"))
end

-- 刷新方案周边的装备
function PCEquipBar:RefreshEquipByPos()
    local bodyEquips = SL:GetValue("EQUIP_POS_DATAS")
    for pos, makeindex in pairs(bodyEquips) do
        local equipData = SL:GetValue("EQUIP_DATA_BY_MAKEINDEX", makeindex)
        if equipData then
            local pos = equipData.Where
            if self.equipMentObjList[pos] then
                ItemUtil:ItemShow_Release(self.equipMentObjList[pos])
            end

            local parent = self.equipMentSlots[pos]
            if parent then
                self.equipMentObjList[pos] = ItemUtil:ItemShow_Create(equipData,parent,
                {
                    itemTipData = {from = ItemFrom.PALYER_EQUIP},
                    OverLap = equipData.OverLap,
					disableClick = true,
                })

				local currentItem = self.equipMentObjList[pos]
				if currentItem and currentItem.component then
					FGUI:setOnRightClickEvent(currentItem.component,function()
						if self.isDraging then return end
						SL:TakeOffPlayerEquip(equipData)
					end)

					FGUI:setOnClickEvent(currentItem.component, function(eventData)
						if self.clickDelay then return end
						local touchId = FGUI:InputEvent_getTouchId(eventData)
						local data = {
							itemIndex = equipData.Index,
							makeIndex = equipData.MakeIndex,
							from = ItemFrom.PALYER_EQUIP
						}
						
						-- 1.使用原图,尺寸可能偏大
						FGUI:DragDropManager_startDrag(currentItem.component,"ui://public_pc/CommonItem", data, touchId,FGUIFunction.CloseBagCheckDragView)
						FGUIFunction:OpenBagCheckDragView()
						local commmonItem = FGUI:GLoader_getComponent(FGUI:DragDropManager_getDragAgent())
						ItemUtil:RefreshItemUIByData(commmonItem,equipData)
	        		end)
				end
            end
        end
    end
end

function PCEquipBar:RefreshBtnCloakSwitch()
    self.ctl_clothKind.selectedIndex = SL:GetValue("SETTING_GET_IS_SHOW_FASHION") and 1 or 0
end

function PCEquipBar:OnClose()
    self.super.Close(self)
	FGUI:Close("Bag_pc","PCStorageBar")
end

function PCEquipBar:UpdateSetting(param1)
    if SLDefine.SETTINGID.SETTING_IDX_OPEN_FASHION ~= param1 then
        return
    end

    self:RefreshScheme()
end

function PCEquipBar:Enter()
	local width = SL:GetValue("SCREEN_WIDTH")
	local height = SL:GetValue("SCREEN_HEIGHT")
	FGUI:setPosition(self.component,width/2,height/2)
	self.bagViewModel:Enter({bindParentView = FGUIDefine.BindParentView.PCEquipBar})
    self:RegisterEvent()  
    FGUIFunction:ShowTopCurrency(SL:GetValue("GAME_DATA","BagMoneyList"))
    self:RefreshScheme()
end

function PCEquipBar:Exit()
    self.bagViewModel:Exit()
    self:RemoveEvent()
    self:CleanItemViewCache()
    FGUIFunction:HideTopCurrency()
end

function PCEquipBar:RightClickEvent(idx)
	local bagData = self:GetCurShowBagCellData(idx + 1)
	if bagData then
		bagData:RightClickCell()
	end

	if self.clickCellCB and bagData then
		self.clickCellCB(bagData)
	end
end

function PCEquipBar:Destroy()
end

function PCEquipBar:RegisterEvent()
    -- 装备更新
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE_LIST, "PCEquipBar",handler(self, self.RefreshCurPageBagCell))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_BODY_UPDATE, "PCEquipBar",handler(self, self.RefreshScheme))
    SL:RegisterLUAEvent(LUA_EVENT_TAKE_OFF_EQUIP_SUCCESS,"PCEquipBar",handler(self, self.RefreshScheme))
    SL:RegisterLUAEvent(LUA_EVENT_TAKE_ON_EQUIP_SUCCESS,"PCEquipBar",handler(self, self.RefreshScheme))
    SL:RegisterLUAEvent(LUA_EVENT_SETTING_CAHNGE, "PCEquipBar",handler(self, self.UpdateSetting))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_DEL,"PCEquipBar",handler(self,self.RefreshScheme))
	SL:RegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_ADD,"PCEquipBar",handler(self,self.RefreshScheme))
end

--移除事件
function PCEquipBar:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_UPDATE_LIST,"PCEquipBar")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_BODY_UPDATE,"PCEquipBar")
    SL:UnRegisterLUAEvent(LUA_EVENT_TAKE_ON_EQUIP_SUCCESS,"PCEquipBar")
    SL:UnRegisterLUAEvent(LUA_EVENT_TAKE_OFF_EQUIP_SUCCESS,"PCEquipBar")
    SL:UnRegisterLUAEvent(LUA_EVENT_SETTING_CAHNGE,"PCEquipBar")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_DEL,"PCEquipBar")
	SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_EQUIP_ADD,"PCEquipBar")
end

return PCEquipBar



