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

	self.JGSConditionModels = {}
	self.checkJGSConditionGroups = {}

	self.HYSConditionModels = {}
	self.checkHYSConditionGroups = {}

	self.RXSConditionModels = {}
	self.checkRXSConditionGroups = {}

	self.HYJGSConditionModels = {}
	self.checkHYJGSConditionGroups = {}

	self.BPHYSConditionModels = {}
	self.checkBPHYSConditionGroups = {}

	local cacheData = self:GetBagRecycleData()
	if not cacheData or #cacheData == 0 then
		if SL:GetValue("U", 8) == 1 then
			self.checkLevel = true
		else
			self.checkLevel = false
		end
	else
		self.checkLevel = cacheData["checkLevel"] and cacheData["checkLevel"] == 1
	end

	self.moneyResDic = {}
	local recycleCfg = requireGameConfig("Recycle")
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
			elseif v.Type == 3 then
				model = BagRecycleConditionModel.new(v)
				targetList = self.JGSConditionModels
				targetGroups = self.checkJGSConditionGroups
			elseif v.Type == 4 then
				model = BagRecycleConditionModel.new(v)
				targetList = self.HYSConditionModels
				targetGroups = self.checkHYSConditionGroups
			elseif v.Type == 5 then
				model = BagRecycleConditionModel.new(v)
				targetList = self.RXSConditionModels
				targetGroups = self.checkRXSConditionGroups
			elseif v.Type == 6 then
				model = BagRecycleConditionModel.new(v)
				targetList = self.HYJGSConditionModels
				targetGroups = self.checkHYJGSConditionGroups
			elseif v.Type == 7 then
				model = BagRecycleConditionModel.new(v)
				targetList = self.BPHYSConditionModels
				targetGroups = self.checkBPHYSConditionGroups
			end

			if targetList then
				table.insert(targetList, model)
			end

			if targetGroups then
				local groups = targetGroups[v.ConditionType]
				if not groups then
					groups = {}
				end
				table.insert(groups, model)
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

function BagRecycleViewModel:GetJGSCheckBoxModel()
	return self.JGSConditionModels
end

function BagRecycleViewModel:GetHYSCheckBoxModel()
	return self.HYSConditionModels
end

function BagRecycleViewModel:GetRXSCheckBoxModel()
	return self.RXSConditionModels
end

function BagRecycleViewModel:GetHYJGSCheckBoxModel()
	return self.HYJGSConditionModels
end

function BagRecycleViewModel:GetBPHYSCheckBoxModel()
	return self.BPHYSConditionModels
end

function BagRecycleViewModel:CheckConditions(itemCfg, conditionGroups)
	--dump(conditionGroups)
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

function BagRecycleViewModel:CheckStoneConditions(stoneId, bagDataCfg, conditionGroups)
	local existValid = false
	for k, v in pairs(conditionGroups) do
		if v then
			for i = 1, #v do
				local conditionModel = v[i]
				if conditionModel then
					--print("conditionModel")
					local valid = conditionModel:CheckStoneValid(stoneId, bagDataCfg)
					--dump(valid)
					if valid then
						existValid = true
						-- 只要物品符合任何一个被选中的条件，就返回true
						if conditionModel.isSelect then
							--dump(conditionModel.isSelect)
							--print("stoneId", stoneId)
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
			local itemCfg = SL:GetValue("ITEM_DATA", v.Index or v.ID)
			-- 获取鉴定属性名称（用于判断是否为石头类道具）
			local attrName = v and v.ExAbil and v.ExAbil.abil and v.ExAbil.abil[1] and v.ExAbil.abil[1].t

			-- 判定准入：物品本身可回收 OR 带有鉴定属性的石头
			if itemCfg and ((itemCfg.recycle and itemCfg.recycle ~= "") or (attrName and attrName == "[鉴定属性]")) then
				local itemSelect = false
				local matchedStoneModel = nil -- 用于记录匹配成功的石头模型

				-- 1. 检查装备类条件（受 checkLevel 总开关影响）
				local lvMatch = false
				if self.checkLevel then
					lvMatch = self:CheckConditions(itemCfg, self.checkLvConditionGroups)
				end
				local equipMatch = self:CheckConditions(itemCfg, self.checkEquipConditionGroups)

				if self.checkLevel then
					itemSelect = lvMatch and equipMatch
				else
					itemSelect = equipMatch
				end

				-- 2. 检查各类石头条件（金刚石、寒玉石等）
				-- 只有带有鉴定属性的物品才进行石头判定
				if attrName and v.ExAbil.abil[1].v and v.ExAbil.abil[1].v[1] then
					local stoneId = v.Index or v.ID
					local bagAttrData = v.ExAbil.abil[1].v[1]

					-- 按优先级依次匹配各个石头组，并返回匹配到的 Model
					matchedStoneModel = self:CheckStoneConditionsReturnModel(stoneId, bagAttrData,
						self.checkJGSConditionGroups)
					if not matchedStoneModel then
						matchedStoneModel = self:CheckStoneConditionsReturnModel(stoneId, bagAttrData,
							self.checkHYSConditionGroups)
					end
					if not matchedStoneModel then
						matchedStoneModel = self:CheckStoneConditionsReturnModel(stoneId, bagAttrData,
							self.checkRXSConditionGroups)
					end
					if not matchedStoneModel then
						matchedStoneModel = self:CheckStoneConditionsReturnModel(stoneId, bagAttrData,
							self.checkHYJGSConditionGroups)
					end
					if not matchedStoneModel then
						matchedStoneModel = self:CheckStoneConditionsReturnModel(stoneId, bagAttrData,
							self.checkBPHYSConditionGroups)
					end
				end

				-- 3. 综合最终选中状态
				-- 只要满足 (装备/等级) OR (匹配到已勾选的石头模型) 即可
				local finalSelect = itemSelect or (matchedStoneModel ~= nil)

				-- 4. 派发延迟改变事件，将 matchedStoneModel 传入 selectList 供 CalculateMoney 使用
				SL:onLUAEvent(LUA_EVENT_BAG_ITEM_CHANGE_DELAY, {
					isSelect = finalSelect,
					selectList = { {
						MakeIndex = v.MakeIndex,
						pos = k,
						ID = v.Index,
						cnt = v.OverLap or 1,
						stoneModel = matchedStoneModel -- 携带模型数据用于计算价格
					} },
					updateMoney = false
				})
			end
		end
	end

	if self.viewComponent then
		self.viewComponent:UpdateMoney()
	end
end

-- 辅助函数：查找并返回匹配且已勾选的石头模型
function BagRecycleViewModel:CheckStoneConditionsReturnModel(stoneId, bagDataCfg, conditionGroups)
	for k, v in pairs(conditionGroups) do
		if v then
			for i = 1, #v do
				local conditionModel = v[i]
				-- 必须物理匹配且玩家在界面上勾选了该项
				if conditionModel and conditionModel.isSelect then
					if conditionModel:CheckStoneValid(stoneId, bagDataCfg) then
						return conditionModel
					end
				end
			end
		end
	end
	return nil
end

function BagRecycleViewModel:GetJsonData()
	local data = {}
	-- 保存等级过滤总开关状态
	data["checkLevel"] = self.checkLevel and 1 or 0

	-- 辅助闭包：遍历模型列表并记录选中状态
	local function collectSelectData(modelList)
		if not modelList then return end
		for i, v in ipairs(modelList) do
			if v and v.cfg and v.cfg.ID then
				data[tostring(v.cfg.ID)] = v.isSelect and 1 or 0
			end
		end
	end

	-- 1. 保存基础页签模型 (等级、装备、其他)
	collectSelectData(self.lvConditionModels)
	collectSelectData(self.equipConditionModels)
	collectSelectData(self.otherConditionModels)

	-- 2. 保存新增的石头类模型 (确保这部分数据下次打开也能还原)
	collectSelectData(self.JGSConditionModels)
	collectSelectData(self.HYSConditionModels)
	collectSelectData(self.RXSConditionModels)
	collectSelectData(self.HYJGSConditionModels)
	collectSelectData(self.BPHYSConditionModels)

	return SL:JsonEncode(data)
end

function BagRecycleViewModel:SaveBagRecycleData(data)
	local flag = SL:GetValue("USER_ID") or "errorName"
	SL:SetLocalString("BagRecycle" .. flag, data)
end

function BagRecycleViewModel:GetBagRecycleData()
	local flag = SL:GetValue("USER_ID") or "errorName"
	local j = SL:GetLocalString("BagRecycle" .. flag)
	local data = {}

	if j and j ~= "" then
		data = SL:JsonDecode(j)
	end
	return data
end

function BagRecycleViewModel:RecycleSelectCell(data)
	if not data then
		return
	end
	local isSelect = data.isSelect
	local selectList = data.selectList

	for i = 1, #selectList do
		local selectData = selectList[i]
		self:CalculateMoney(isSelect, selectData)
		self.SelectMakeIndexToPos[selectData.MakeIndex] = isSelect and selectList[i] or nil
	end
	if data.updateMoney then
		if self.viewComponent then
			self.viewComponent:UpdateMoney()
		end
	end
end

function BagRecycleViewModel:BagRecycleNewCheckCond(itemCfg, conditionGroups)
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
			cnt = cnt + 1
			table.insert(recycItemList, { makeIndex = v.MakeIndex, itemId = v.ID })
		end
	end
	-- print(cnt)
	-- end
	if BagRecycleViewModelUI then
		BagRecycleViewModelUI.CCUI = self
	end

	ssrMessage:sendmsgEx("bag", "sellAll", recycItemList)
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

function BagRecycleViewModel:CalculateMoney(isSelect, selectData)
	if not selectData then return end

	local moneyStr = ""
	local itemCfg = SL:GetValue("ITEM_DATA", selectData.ID)

	-- 优先级 1：如果有匹配的石头模型，使用配置表 Recycle.lua 中的 sell 价格
	if selectData.stoneModel and selectData.stoneModel.cfg and selectData.stoneModel.cfg.sell then
		moneyStr = selectData.stoneModel.cfg.sell
		-- 优先级 2：使用物品表 Item.lua 中的 recycle 价格
	elseif itemCfg and itemCfg.recycle and itemCfg.recycle ~= "" then
		moneyStr = itemCfg.recycle
	end

	if moneyStr ~= "" then
		local moneyGroups = string.split(moneyStr, "|")
		for i = 1, #moneyGroups do
			local moneyData = string.split(moneyGroups[i], "#")
			if #moneyData >= 2 then
				local moneyId = tonumber(moneyData[1])
				local moneyNum = tonumber(moneyData[2])
				local sum = self.moneyResDic[moneyId] or 0

				local curSelectItemData = self.SelectMakeIndexToPos[selectData.MakeIndex]
				if isSelect then
					if not curSelectItemData then
						sum = sum + moneyNum * selectData.cnt
					end
				else
					if curSelectItemData then
						sum = sum - moneyNum * selectData.cnt
					end
				end
				self.moneyResDic[moneyId] = sum
			end
		end
	end
end

function BagRecycleViewModel:BagCellClickEvent(bagItem)
	if FGUI:CheckOpen("Bag", "BagRecyclePanel") then
		bagItem:SetTipEnable(false)
		local itemCfg = SL:GetValue("ITEM_DATA", bagItem._itemData.Index)
		local attrName = bagItem._itemData and bagItem._itemData.ExAbil and bagItem._itemData.ExAbil.abil and bagItem._itemData.ExAbil.abil[1] and bagItem._itemData.ExAbil.abil[1].t
		if itemCfg and not ((itemCfg.recycle and itemCfg.recycle ~= "") or (attrName and attrName == "[鉴定属性]")) then
			ShowSystemTips(GET_STRING(60003006))
			return
		end

		-- 如果是石头类道具，需要匹配石头模型以计算价格
		local matchedStoneModel = nil
		if attrName and attrName == "[鉴定属性]" and bagItem._itemData.ExAbil.abil[1].v and bagItem._itemData.ExAbil.abil[1].v[1] then
			local stoneId = bagItem._itemData.Index
			local bagAttrData = bagItem._itemData.ExAbil.abil[1].v[1]
			-- 手动点击不需要检查条件是否勾选，只要物理匹配即可获取价格
			local allStoneGroups = { self.checkJGSConditionGroups, self.checkHYSConditionGroups, self.checkRXSConditionGroups, self.checkHYJGSConditionGroups, self.checkBPHYSConditionGroups }
			for _, group in ipairs(allStoneGroups) do
				for _, v in pairs(group) do
					if v then
						for i = 1, #v do
							local conditionModel = v[i]
							if conditionModel and conditionModel:CheckStoneValid(stoneId, bagAttrData) then
								matchedStoneModel = conditionModel
								break
							end
						end
					end
					if matchedStoneModel then break end
				end
				if matchedStoneModel then break end
			end
		end

		SL:onLUAEvent(LUA_EVENT_BAG_ITEM_CHANGE_DELAY,
			{ isSelect = not bagItem.recycleSelect, selectList = { { MakeIndex = bagItem._itemData.MakeIndex, pos = bagItem._index, ID = bagItem._itemData.Index, cnt = bagItem._itemData.OverLap or 1, stoneModel = matchedStoneModel } }, updateMoney = true })
	end
end

function BagRecycleViewModel:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_BAG_ITEM_CHANGE_DELAY, "BagRecycleViewModel", handler(self, self.RecycleSelectCell))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_RECOVERY_UPDATE, "BagRecycleViewModel",
		handler(self, self.RefreshSelectItemsByConditions))
	SL:RegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "BagRecycleViewModel", handler(self, self.BagCellClickEvent))
end

function BagRecycleViewModel:UnRegisterEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_ITEM_CHANGE_DELAY, "BagRecycleViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_RECOVERY_UPDATE, "BagRecycleViewModel")
	SL:UnRegisterLUAEvent(LUA_EVENT_BAG_CELL_CLICK, "BagRecycleViewModel")
end

return BagRecycleViewModel.new()
