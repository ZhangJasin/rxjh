local CommonItemTipBase = requireFGUILayout("Common/CommonItemTipBase")
local CommonItemTip = class("CommonItemTip", CommonItemTipBase)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
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

function CommonItemTip:Enter(data)
	self.super.Enter(self,data)
	self:RefreshBtnState(data)
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
		for k, v in pairs(	self._buttons) do								--需要判断一下是否点击到当前界面的按钮上
			if FGUI:GetContainer(v) == p then
				return false
			end
		end

		if self:CheckListEnable() then
			if FGUI:GetContainer(self.Content)  == p then
				return false
			end
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
		btnCfg.func(itemData)
		self:CloseTip()
	end)

end
function CommonItemTip:RefreshBtnState(data)
	local itemData = data.itemData
	local hideBtn = data and data.hideButtons
	local isEquip = ItemUtil:IsEquip(itemData)
	local canUse = SL:CheckItemUseNeed(itemData)
	local addBtnMap = {}
	local  showSplit = SL:GetValue("GAME_DATA","ItemSplit") == 1
	for i = 1, #self._buttons do
		local btnCfgType = -1
		if not hideBtn then
			local npcIndex = SL:GetValue("STORAGE_NPC_INDEX")
			local isOpen = FGUI:CheckOpen( "Bag", "StoragePanel") or FGUI:CheckOpen( "Bag_pc", "PCStoragePanel")
			local isTradeOpen = FGUI:CheckOpen("Trade", "TradeMain")
			local isStorageExOpen = FGUI:CheckOpen("Bag", "StorageExPanel") or FGUI:CheckOpen("Bag_pc", "PCStorageExPanel")
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
			else

				-- 使用道具
				if data and data.from == ItemFrom.BAG  and canUse  then
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

		self:SetBtnInfo(i, itemData, btnCfgType)
		addBtnMap[btnCfgType] = 1
	end
end

return CommonItemTip