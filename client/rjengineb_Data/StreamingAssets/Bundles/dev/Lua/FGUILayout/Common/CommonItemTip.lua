local CommonItemTipBase = requireFGUILayout("Common/CommonItemTipBase")
local CommonItemTip = class("CommonItemTip", CommonItemTipBase)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ObtainListData           =  require("game_config/cfgcsv/Obtain")          --获取来源

-- 回城符道具ID列表
local BACK_CITY_ITEM_IDS = { 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140 }

-- 检查是否为回城符
function CommonItemTip:CheckIsBackCityItem(itemID)
    for i = 1, #BACK_CITY_ITEM_IDS do
        if BACK_CITY_ITEM_IDS[i] == itemID then
            return true
        end
    end
    return false
end
--[[
	data.from           --从哪个界面打开Tip,用于逻辑判断SL:GetValue("ITEMFROMUI_ENUM")
	data.itemData		--物品数据
    data.hideCompare    --如果是装备，判断否隐藏装备比较
]]

function CommonItemTip:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)

	self._buttons = {self._ui.Btn1,self._ui.Btn2,self._ui.Btn3 }

	self._ui.bg = self._ui.Pop --截图节点禁止删除
end

--按钮默认 794 351
function CommonItemTip:Enter(data)
	self.super.Enter(self,data)
	self._itemData = data.itemData
	self:RefreshBtnState(data)
	FGUI:setVisible(self._ui.ObtainList,false)
	-- self.baseBtnXY = FGUI:getPosition(self._ui.Pop)
	-- local pw,ph = FGUI:getPosition(self._ui.Pop)、
	-- local tWid2, tHei2 = FGUI:getSize(self._ui.Pop) 
	-- self.btnsX = tWid2 + pw - 4
	-- FGUI:setPosition(self._ui.btns,self.btnsX,351)
end

function CommonItemTip:Exit()
	self.super.Exit(self)
end

function CommonItemTip:Close()
	self.super.Close(self)
end

function CommonItemTip:CloseTip()
	self:Close()
end

function CommonItemTip:CheckInitiatorIsButton(data)
	local eventInitiator = FGUI:EventContext_getInitiator(data.eventData)
	if eventInitiator then
		local  p = FGUI:GetParent(eventInitiator)
		for k, v in pairs(self._buttons) do								--需要判断一下是否点击到当前界面的按钮上
			if FGUI:GetContainer(v) == p then
				return false
			end
		end

		if self:CheckListEnable() then
			if FGUI:GetContainer(self.Content)  == p then
				return false
			end
		end

		if FGUI:getVisible(self._ui.panel_auto_switch) then
			if FGUI:GetContainer(self._ui.checkBox_auto) == eventInitiator then
				return false
			end
		end
		if FGUI:GetContainer(self._ui.list) == p then
			return false
		end
	end
	return true
end

function CommonItemTip:SetBtnInfo(btnIndex, itemData, btnCfgType)
	local button =self._buttons[btnIndex]
	FGUI:setVisible(button, btnCfgType ~= -1)
	local btnCfg =  ItemTips.GetBtnCfg(btnCfgType)
	FGUI:GButton_setTitle(button, btnCfg.btnName)

	FGUI:setOnClickEvent(button, function()
		if btnCfg.btnName == "获取" then
			self:showObtainList()
		else
		btnCfg.func(itemData)
		self:CloseTip()
		end
	end)

end
function CommonItemTip:RefreshBtnState(data)
	local itemData = data.itemData
	local hideBtn = data and data.hideButtons
	local isEquip = ItemUtil:IsEquip(itemData)
	local canUse = SL:CheckItemUseNeed(itemData)
	local addBtnMap = {}
	local  showSplit = SL:GetValue("GAME_DATA","ItemSplit") == 1
	FGUI:setVisible(self._ui.Btn4 , false)
	
	-- 检查是否为回城符
	local isBackCityItem = self:CheckIsBackCityItem(itemData.ID)
	
	for i = 1, #self._buttons do
		local btnCfgType = -1
		if not hideBtn then
			local npcIndex = SL:GetValue("STORAGE_NPC_INDEX")
			local isOpen = FGUI:CheckOpen( "Bag", "StoragePanel") or FGUI:CheckOpen( "Bag_pc", "PCStoragePanel")
			local isTradeOpen = FGUI:CheckOpen("Trade", "TradeMain") or FGUI:CheckOpen("Trade", "PCTradeMain")
			local isStorageExOpen = FGUI:CheckOpen("Bag", "StorageExPanel") or FGUI:CheckOpen("Bag_pc", "PCStorageExPanel")
			local isStallOpen = FGUI:CheckOpen("Stall", "StallProduct") or FGUI:CheckOpen("Stall", "PCStallProduct")
			if isOpen and npcIndex then
				-- 放入仓库

				if data.from == ItemFrom.BAG and npcIndex and isOpen and not addBtnMap[4] then
					btnCfgType = 4
				end

				-- 取出仓库
				if data.from == ItemFrom.STORAGE and npcIndex and isOpen and not addBtnMap[5] then
					btnCfgType = 5
				end
			elseif isTradeOpen then
				-- 放入面对面交易
				if data.from == ItemFrom.TRADE and not addBtnMap[9] then
					btnCfgType = 9
				end
			elseif isStorageExOpen then
				--附加仓库
				if data.from == ItemFrom.BAG and not addBtnMap[10] then
					btnCfgType = 10
				elseif data.from == ItemFrom.STORAGE_EX and not addBtnMap[11] then
					btnCfgType = 11
				end
			elseif isStallOpen then
				if data.from == ItemFrom.BAG and not addBtnMap[12] then
					btnCfgType = 12
				end
			else
				-- 使用道具(回城符除外)
				if data and data.from == ItemFrom.BAG  and canUse and not isBackCityItem then
					if isEquip  then
						if not addBtnMap[2] then
							btnCfgType = 2
						end
					else
						if not addBtnMap[1] then
							btnCfgType = 1
						end
					end
				end
				-- 拆分按钮
				if data.from == ItemFrom.BAG and itemData.OverLap and showSplit and itemData.OverLap > 1 and not addBtnMap[3] then
					btnCfgType = 3
				end
				-- 丢弃
				if data.from == ItemFrom.BAG and not addBtnMap[6] then
					btnCfgType = 6
				end

				--可装备道具的卸下
				if data.from == ItemFrom.PALYER_EQUIP and not addBtnMap[7]then
					btnCfgType = 7
				end
			end
		end
		if i == 4  then
			btnCfgType = 22
		end
		self:SetBtnInfo(i, itemData, btnCfgType)
		addBtnMap[btnCfgType] = 1
	end
end

function CommonItemTip:showObtainList()
	if FGUI:getVisible(self._ui.ObtainList) then
		FGUI:setVisible(self._ui.ObtainList,false)
		-- FGUI:setPosition(self._ui.btns,self.btnsX,351)
		return 
	else
		FGUI:setVisible(self._ui.ObtainList,true)
	end
    -- local obtainNameTxt =  FGUI:GetChild(self.component, "obtainName")
    -- FGUI:GTextField_setText(obtainNameTxt, "获取途径")
	-- local tWid2, tHei2 = FGUI:getSize(self._ui.Pop) 
	-- FGUI:setHeight(self._ui.ObtainList, tHei2)
	-- FGUI:setHeight(self._ui.list, tHei2- 55 )
	-- FGUI:setPosition(self._ui.btns,self.btnsX + 228,351)
	-- local pw,ph = FGUI:getPosition(self._ui.Pop)
	-- FGUI:setPosition(self._ui.ObtainList,self.btnsX,ph)
    local dataconfig = SL:GetValue("ITEM_DATA",tonumber(self._itemData.ID))
    local getWayInfoList = SL:Split(dataconfig.GetWayInfo, "|")
    local obtainList = {}
    for i=1,#ObtainListData do
        local data = ObtainListData[i]
        for w=1,#getWayInfoList do
            if tonumber(getWayInfoList[w]) == tonumber(data.ID) then
                table.insert(obtainList,data)
            end
        end
    end
	local obtainNameTxt =  FGUI:GetChild(self._ui.ObtainList, "obtainName")
    FGUI:GTextField_setText(obtainNameTxt, "获取途径")
	local list = FGUI:GetChild(self._ui.ObtainList,"list")
    FGUI:GList_itemRenderer(list, function(idx,item)
    -- FGUI:GList_itemRenderer(self._ui.list, function(idx,item)
        local text = FGUI:GetChild(item,"text")
        local data = obtainList[idx+1]
        FGUI:GTextField_setText(text,data.Desc)
        FGUI:setOnClickEvent(item,function() 
            --关掉tip
			dump("点击了")
			-- FGUI:CloseTop()
            self:CloseTip()
            if data.Func=="Open" then
                FGUI:Open(data.PackageName,data.ComponentName)
            elseif data.Func == "RequestGroupData" then
                SL:RequestGroupData(0)
            end  
        end)
    end)

    FGUI:GList_setNumItems(list, #obtainList)
end

return CommonItemTip