local BagRecycleViewModel = class("BagRecycleViewModel")
local BagRecycleConditionModel = requireFGUILayout("Bag/BagRecycleConditionModel")

function BagRecycleViewModel:ctor()
	-- self:InitRecycleCondition()
end

function BagRecycleViewModel:InitRecycleCondition()
	self.lvConditionModels = {}
	self.checkLvConditionGroups = {}
	self.equipConditionModels = {}
	self.checkEquipConditionGroups = {}
	self.otherConditionModels = {}
	self.checkOtherConditionGroups = {}
	local cacheData = self:GetBagRecycleData()
	if not cacheData or #cacheData == 0 then
		if SL:GetValue("U",8) == 1 then
			self.checkLevel = true
		else
			self.checkLevel = false
		end
	else
		self.checkLevel = cacheData["checkLevel"] and cacheData["checkLevel"] == 1
	end

	self.moneyResDic = {}
	local  recycleCfg = requireGameConfig("Recycle")
	local allSellIds = SL:GetValue("T", 19)
	if allSellIds == 0 or allSellIds == "" then
		allSellIds = {}
	else
		allSellIds = SL:JsonDecode(allSellIds)
	end
	if recycleCfg then
		for k, v in ipairs(recycleCfg) do
			v.Default = allSellIds[v.Name] or 0
			local model = {}
			local targetList
			local targetGroups
			if v.Type == 0 then
				model = BagRecycleConditionModel.new(v)
				targetList = self.lvConditionModels
				targetGroups = self.checkLvConditionGroups

			elseif v.Type == 1 then
				model = BagRecycleConditionModel.new(v)
				targetList = self.equipConditionModels
				targetGroups = self.checkEquipConditionGroups

			elseif v.Type == 2 then
				model = BagRecycleConditionModel.new(v)
				targetList = self.otherConditionModels
				targetGroups = self.checkOtherConditionGroups
			end

			if targetList then
				table.insert(targetList,model)
			end

			if targetGroups then
				local groups = targetGroups[v.ConditionType]
				if not groups then
					groups = {}
				end
				table.insert(groups,model)
				targetGroups[v.ConditionType] = groups
			end

			if model then
				if not cacheData or #cacheData == 0 then
					model.isSelect = v.Default == 1
				else
					model.isSelect = cacheData[tostring(v.ID)] and cacheData[tostring(v.ID)] == 1
				end
			end
		end
	end
	self.SelectMakeIndexToPos = {}
end

function BagRecycleViewModel:Bind(viewComponent)
	self.viewComponent = viewComponent
end
function BagRecycleViewModel:UnBind()
	self.viewComponent = nil
end
function BagRecycleViewModel:Enter()
	self:RegisterEvent()
	self:RefreshData()
end

function BagRecycleViewModel:Exit()
	self:SaveBagRecycleData(self:GetJsonData())
	self:UnRegisterEvent()
end


function BagRecycleViewModel:RefreshData()
	self:RefreshSelectItemsByConditions()
end

function BagRecycleViewModel:ToggleAllLv()
	self.checkLevel = not self.checkLevel
end

function BagRecycleViewModel:GetSelectMakeIndexToPos()
	return self.SelectMakeIndexToPos
end

function BagRecycleViewModel:GetTabCheckBoxModel(index)
	if index == 0 then
		return self.equipConditionModels
	else
		return self.otherConditionModels
	end
end

function BagRecycleViewModel:GetLvCheckBoxModel()
	return self.lvConditionModels
end

function BagRecycleViewModel:CheckConditions(itemCfg,conditionGroups)
	local existValid = false
	for k, v in pairs(conditionGroups) do
		if v then
			for i = 1, #v do
				local conditionModel = v[i]
				if conditionModel then
					local valid = conditionModel:CheckItemValid(itemCfg)
					if valid then
						existValid = true
						-- 只要物品符合任何一个被选中的条件，就返回true
						if conditionModel.isSelect then
							return true
						end
					end
				end
			end

		end
	end
	return false
end

function BagRecycleViewModel:RefreshSelectItemsByConditions()
	local bagData = SL:GetValue("BAG_SORT_POS_DATA_DIC")
	self.SelectMakeIndexToPos = {}
	self.moneyResDic = {}
	for k, v in pairs(bagData) do
		if k > 0 and v then
			local itemCfg =  SL:GetValue("ITEM_DATA", v.Index or v.ID)
			if itemCfg and itemCfg.recycle and itemCfg.recycle ~= "" then
				local itemSelect = false
				-- 检查等级条件（如果开启）
				if self.checkLevel then
					itemSelect = self:CheckConditions(itemCfg,self.checkLvConditionGroups)
				end

				-- 检查装备条件
				local equipSelect = self:CheckConditions(itemCfg,self.checkEquipConditionGroups)

				-- 如果等级筛选开启，需要同时满足等级和装备条件
				-- 如果等级筛选未开启，只需要满足装备条件
				if self.checkLevel then
					itemSelect = itemSelect and equipSelect
				else
					itemSelect = equipSelect
				end

				local otherSelect = self:CheckConditions(itemCfg,self.checkOtherConditionGroups)
				local finalSelect = itemSelect or otherSelect
				SL:onLUAEvent(LUA_EVENT_BAG_RECYCLE_SELECT, {isSelect = finalSelect ,selectList= { {MakeIndex = v.MakeIndex,pos = k,ID =v.Index,cnt = v.OverLap or 1}},updateMoney = false } )
			end
		end
	end
	if self.viewComponent then
		self.viewComponent:UpdateMoney()
	end
end

function BagRecycleViewModel:GetJsonData()
	local data = {}
	data["checkLevel"] = self.checkLevel and 1 or 0
	for i, v in ipairs(self.lvConditionModels) do
		if v and v.cfg and v.cfg.ID then
			data[v.cfg.ID] =  v.isSelect and 1 or 0
		end
	end
	for i, v in ipairs(self.equipConditionModels) do
		if v and v.cfg and v.cfg.ID then
			data[v.cfg.ID] =  v.isSelect and 1 or 0
		end
	end
	for i, v in ipairs(self.otherConditionModels) do
		if v and v.cfg and v.cfg.ID then
			data[v.cfg.ID] =  v.isSelect and 1 or 0
		end
	end

	return SL:JsonEncode(data)
end

function BagRecycleViewModel:SaveBagRecycleData(data)
	local flag = SL:GetValue("USER_ID") or "errorName"
	SL:SetLocalString("BagRecycle"..flag, data)
end


function BagRecycleViewModel:GetBagRecycleData()
	local flag = SL:GetValue("USER_ID") or "errorName"
	local j = SL:GetLocalString("BagRecycle"..flag)
	local data = {}

	if j and j ~= "" then
		data = SL:JsonDecode(j)
	end
	return data
end


function BagRecycleViewModel:RecycleSelectCell(data)
	local isSelect = data.isSelect
	local selectList = data.selectList

	for i = 1, #selectList do
		local selectData = selectList[i]
		self:CalculateMoney(isSelect,selectData)
		self.SelectMakeIndexToPos[selectData.MakeIndex] = isSelect and selectList[i] or nil
	end
	if data.updateMoney then
		if self.viewComponent then
			self.viewComponent:UpdateMoney()
		end
	end
end

function BagRecycleViewModel:BagRecycleNewCheckCond(itemCfg,conditionGroups)
	local existValid = false
	for k, v in pairs(conditionGroups) do
		if v then
			for i = 1, #v do
				local conditionModel = v[i]
				if conditionModel then
					existValid = conditionModel:CheckItemValid(itemCfg)
				end
			end
		end
	end
	return existValid
end
function BagRecycleViewModel:RecycleSelectItems()
	local recycItemList = {}
	-- if  SL._DEBUG then
		local cnt = 0
		for k, v in pairs(self.SelectMakeIndexToPos) do
			-- print("RecycleSelectItems",k,SL:JsonEncode(v))
			if k and v then
				cnt = cnt +1
				table.insert(recycItemList,{makeIndex = v.MakeIndex,itemId = v.ID})
			end
		end
		-- print(cnt)
	-- end
	BagRecycleViewModelUI.CCUI = self
	ssrMessage:sendmsgEx("bag", "sellAll",recycItemList) 
	-- SL:RequestRecycleItems(self.SelectMakeIndexToPos)
end
function BagRecycleViewModel:updateView()
	self = BagRecycleViewModelUI.CCUI
	self:RefreshSelectItemsByConditions()
	self.viewComponent:UpdateMoney()
end

function BagRecycleViewModel:GetMoneyResDic()
	return self.moneyResDic
end
function BagRecycleViewModel:CalculateMoney(isSelect,selectData)
	if selectData then
		local cfg = SL:GetValue("ITEM_DATA", selectData.ID)
		if cfg and cfg.recycle then
			local moneyStr = string.split(cfg.recycle, "|")
			if moneyStr then
				for i = 1, #moneyStr do
					local moneyData = string.split(moneyStr[i], "#")
					if moneyData then

						local moneyId = tonumber(moneyData[1])
						local moneyNum = tonumber(moneyData[2])
						local sum = self.moneyResDic[moneyId] or 0
						local curSelectItemData = self.SelectMakeIndexToPos[selectData.MakeIndex]
						if isSelect then
							if not curSelectItemData then
								sum = sum + moneyNum*selectData.cnt
							end
						else
							if  curSelectItemData then
								sum =  sum - moneyNum*selectData.cnt
							end
						end

						self.moneyResDic[moneyId] = sum
					end
				end
			end
		end
	end
end

function BagRecycleViewModel:BagCellClickEvent(bagItem)
	if  FGUI:CheckOpen("Bag", "BagRecyclePanel")then
		bagItem:SetTipEnable(false)
		local itemCfg = SL:GetValue("ITEM_DATA", bagItem._itemData.Index)
		if itemCfg then
			if not itemCfg.recycle or itemCfg.recycle == "" then
				ShowSystemTips(GET_STRING(60003006))
				return
			end
		end

		SL:onLUAEvent(LUA_EVENT_BAG_RECYCLE_SELECT, {isSelect = not bagItem.recycleSelect ,selectList= { {MakeIndex = bagItem._itemData.MakeIndex,pos = bagItem._index,ID = bagItem._itemData.Index,cnt = bagItem._itemData.OverLap or 1}} ,updateMoney = true} )
	end
end



function BagRecycleViewModel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_BAG_RECYCLE_SELECT, "BagRecycleViewModel",  handler(self,self.RecycleSelectCell))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_RECOVERY_UPDATE, "BagRecycleViewModel",  handler(self,self.RefreshSelectItemsByConditions))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "BagRecycleViewModel",  handler(self,self.BagCellClickEvent))
end


function BagRecycleViewModel:UnRegisterEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_RECYCLE_SELECT, "BagRecycleViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_RECOVERY_UPDATE, "BagRecycleViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "BagRecycleViewModel")
end

return  BagRecycleViewModel.new()