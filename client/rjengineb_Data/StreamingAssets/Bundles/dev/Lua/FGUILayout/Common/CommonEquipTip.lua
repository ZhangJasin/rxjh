local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CommonEquipTip = class("CommonEquipTip", BaseFGUILayout)
SL:RequireFile("FGUILayout/Common/EquipTipViewModel")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
--[[
	data.from           --从哪个界面打开Tip,用于逻辑判断SL:GetValue("ITEMFROMUI_ENUM")
	data.itemData		--物品数据
    data.hideCompare    --如果是装备，判断否隐藏装备比较
]]
local fashion_jihuo            =  require("game_config/cfgcsv/fashion_jihuo")    -- 时装激活表 ItemTipsDesc

function CommonEquipTip:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)

	self._buttons = {self._ui.Btn1,self._ui.Btn2 }
	self._viewList = {self._ui.Pop1,self._ui.Pop2,self._ui.Pop3}

	self.stageClickHandler = handler(self, self.StageClickEvent)

	self.STAGE_EVENT_EQUIP_TIP = "STAGE_EVENT_EQUIP_TIP"

	self._originListSize = {FGUI:getSize(FGUI:GetChild(self._ui.Pop1, "Content"))}
	
	self._ui.bg = self._ui.Pops --截图节点禁止删除
	
	self._purchaseBtnKeys = {"btn_add", "btn_sub", "btn_m_min", "btn_m_max", "btn_purchase"}

	-- FGUI:setOnClickEvent(self._ui.Mask, handler(self, self.Close))
end

function CommonEquipTip:InitEquipData(data)
	local itemData  = data.itemData
	local isCompare = false
	self._curItemID = itemData and itemData.ID

	local extData = {
		from = data.from,
		buyParam = data.buyParam
	}
	self._viewModelList = {EquipTipViewModel.new(1, itemData, extData)}
	local diffEquips = nil
	if not data.hideCompare and data.from == ItemFrom.BAG then
		diffEquips = FGUIFunction:GetDiffEquip(itemData)
		if diffEquips and #diffEquips > 0 then
			isCompare = true
		end

		if isCompare then
			for i = 1, #diffEquips do
				local extData = {
					isCompare = true
				}
				table.insert(self._viewModelList, EquipTipViewModel.new(#self._viewModelList + 1, diffEquips[i], extData))
			end
		end
	end

	for i = 1, #self._viewList do
		local viewModel = self._viewModelList[i]
		if viewModel then
			viewModel:UpdateCellView(self._viewList[i], self._originListSize)
		end
		if i > 1 then
			FGUI:setVisible(self._viewList[i], viewModel ~= nil)
		end
	end

end

function CommonEquipTip:Enter(data)
	--if SL:GetValue("IS_PC_OPER_MODE") then
		FGUI:StageEvent_AddListener(self.STAGE_EVENT_EQUIP_TIP,self.stageClickHandler)
	--end
	self:InitEquipData(data)
	self:InitTipPos()
	self:RefreshBtnState(data)
end

function CommonEquipTip:InitTipPos()
	self._scrollList = {}

	local pops = self._ui.Pops
	for i = 1, #self._viewList do
		local view = self._viewList[i]
		if FGUI:getVisible(view) then
			local contentList = FGUI:GetChild(view, "Content")
			FGUI:GList_resizeToFit(contentList)
			local pWid, pHei = FGUI:getSize(self._ui["Pop" .. i])
			local screenH = SL:GetMetaValue("SCREEN_HEIGHT")

			local subH = 0
			local addH = nil
			local maxH = screenH - 100
			local canScroll = false
			local previewModel = FGUI:GetChild(view, "PreviewModel")
			local purchasePanel = FGUI:GetChild(view, "panel_purchase")
			-- 有预览页统一按预览页高度 / 有购买框也按预览页高度
			if FGUI:getVisible(previewModel) or FGUI:getVisible(purchasePanel) then
				local preWid, preHei = FGUI:getSize(previewModel)
				maxH = preHei + 4
				if pHei < maxH then
					addH = maxH - pHei
				end
			end
			if pHei > maxH then
				subH = pHei - maxH
				canScroll = true
				self._scrollList[i] = true
			end
			local contentW, contentH = FGUI:getSize(contentList)
			local maxContentWid = self._viewModelList[i] and self._viewModelList[i]:GetContentMaxWidth()
			FGUI:setSize(contentList, SL:GetEvenNum(maxContentWid), addH and SL:GetEvenNum(contentH + addH) or SL:GetEvenNum(contentH - subH))

			local scrollPane = FGUI:GetScrollPane(contentList)
			if scrollPane then
				FGUI:ScrollPane_setTouchEffect(scrollPane, canScroll)
			end

			-- FGUI:setTouchEnabled(contentList, canScroll)
			FGUI:setTouchEnabled(contentList, true)

		end
	end

	FGUI:GGroup_EnsureBoundsCorrect(pops)
	FGUI:Stage_ForceUpdate()
end
function CommonEquipTip:Exit()
	--if SL:GetValue("IS_PC_OPER_MODE") then
		FGUI:StageEvent_RemoveListener(self.STAGE_EVENT_EQUIP_TIP)
	--end
end

function CommonEquipTip:StageClickEvent(data)
	-- print("点击了界面")
	if data.eventName == self.STAGE_EVENT_EQUIP_TIP then
		local tapClose = true
		local eventInitiator = FGUI:EventContext_getInitiator(data.eventData)
		if eventInitiator then
			-- 检查是否点击到Shape对象上  新增
            local mt = getmetatable(eventInitiator)
			if not SL:GetValue("IS_PC_OPER_MODE") then
    			if mt and mt.__name == "FairyGUI.Shape" then  -- 点击tips界外才关闭界面
					tapClose = true
				else
					tapClose = false
				end	
			end
			local  p = FGUI:GetParent(eventInitiator)
			for k, v in pairs(	self._buttons) do								--需要判断一下是否点击到当前界面的按钮上
				if FGUI:GetContainer(v) == p then
					tapClose = false
					break
				end
			end

			if tapClose then
				for i, state in pairs(self._scrollList) do
					local contentList = self._viewModelList[i] and self._viewModelList[i]._content
					if contentList and FGUI:GetContainer(contentList) == p then
						tapClose = false
						break
					end
				end

				for k, v in ipairs(self._viewModelList) do
					local autoSwitchPanel = v and v._autoSwitchPanel
					if autoSwitchPanel and FGUI:getVisible(autoSwitchPanel) then
						local checkBox = FGUI:GetChild(autoSwitchPanel, "checkBox_auto")
						if FGUI:GetContainer(checkBox) == eventInitiator then
							tapClose = false
							break
						end
					end

					local purchasePanel = v._ui.panel_purchase
					local pRoot = v._purchasePanel
					if purchasePanel and FGUI:getVisible(purchasePanel) and pRoot then
						for i = 1, #self._purchaseBtnKeys do
							local btnKey = self._purchaseBtnKeys[i]
							local btn = pRoot._ui[btnKey]
							if btn and FGUI:GetContainer(btn) == eventInitiator then
								tapClose = false
								break
							end
						end
						if tapClose then
							if pRoot._countInput and pRoot._countInput.inputTextField == eventInitiator then
								tapClose = false
							end
						end
					end
				end
			end
			-- print("点击了界面上的其他地方tapClose",tostring(tapClose))
		end
		if tapClose then
			self:Close()
		end
	end
end

function CommonEquipTip:Close()
	self.super.Close(self)
end

function CommonEquipTip:CloseTip()
	self:Close()
end


function CommonEquipTip:SetBtnInfo(btnIndex, itemData, btnCfgType)
	local button =self._buttons[btnIndex]
	FGUI:setVisible(button, btnCfgType ~= -1)
	if  btnCfgType ~= -1 then
		local btnCfg =  ItemTips.GetBtnCfg(btnCfgType)
		FGUI:GButton_setTitle(button, btnCfg.btnName)
		FGUI:setOnClickEvent(button, function()
			btnCfg.func(itemData)
			self:CloseTip()
		end)
	end

end
function CommonEquipTip:RefreshBtnState(data)
	local itemData = data.itemData
	local addBtnMap = {}
	local hideBtn = data and data.hideButtons

	for i = 1, #self._buttons do
		local btnCfgType = -1
		-- 丢弃道具
		if not hideBtn then
			local npcIndex = SL:GetValue("STORAGE_NPC_INDEX")
			local isOpen = FGUI:CheckOpen("Bag", "StoragePanel")
			local isTradeOpen = FGUI:CheckOpen("Trade", "TradeMain")
			local isStorageExOpen = FGUI:CheckOpen("Bag", "StorageExPanel")
			local isStallOpen = FGUI:CheckOpen("Stall", "StallProduct")
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

				local isJianDIng = false
        		local itemConfig = itemData.ExAbil	
        		if itemConfig and itemConfig.abil[1] then
        		    isJianDIng = true
        		end
				-- dump(itemData.StdMode,"itemData.StdMode")
				-- 装备佩戴  可穿戴装备显示穿戴
				if itemData.StdMode and itemData.StdMode >= 71 and itemData.StdMode <= 74 and not isJianDIng then
					-- 武勋鉴定按钮
					if data and data.from == ItemFrom.BAG and not addBtnMap[21] then
						btnCfgType = 21
					end
				elseif itemData.StdMode and data and data.from == ItemFrom.BAG  and not addBtnMap[2] then
					btnCfgType = 2
				end
				-- 拆分按钮,暂时不需要
				--if data.from == ItemFrom.BAG  and canUse and itemData.OverLap and itemData.OverLap > 1 and not addBtnMap[2] then
				--	btnCfgType = 3
				--end

				-- 丢弃道具
				if data.from == ItemFrom.BAG and not addBtnMap[6] then
					btnCfgType = 6
				end
				-- 卸下按钮
				if data.from == ItemFrom.PALYER_EQUIP and not addBtnMap[7]then
					btnCfgType = 7
				end
			end

			addBtnMap[btnCfgType] = 1
		end
		-- 时装隐藏按钮
		if itemData.StdMode == 54 or  itemData.StdMode == 65 or itemData.StdMode == 66 then
			btnCfgType = -1
		end
		self:SetBtnInfo(i, itemData, btnCfgType)
	end
	-- 打开宠物界面按钮显示特殊处理
	if data.petType and data.petMark and data.petType == 1 then 
		itemData.petMark = data.petMark	
		itemData.petEquipMakeIndex = data.petEquipMakeIndex
		self:SetBtnInfo(1, itemData, 23)  -- 宠物装备脱下
		self:SetBtnInfo(2, itemData, 25)  -- 宠物装备提升
	elseif data.petType and data.petMark and data.petType == 2 then
		itemData.petMark = data.petMark	
		itemData.petEquipMakeIndex = data.petEquipMakeIndex	
		self:SetBtnInfo(1, itemData, 24)  -- 宠物装备穿戴
		self:SetBtnInfo(2, itemData, 25)  -- 宠物装备提升
	end

end

return CommonEquipTip