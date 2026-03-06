local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CommonEquipTip = class("CommonEquipTip", BaseFGUILayout)
SL:RequireFile("FGUILayout/Common/EquipTipViewModel")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
--[[
	data.from           --从哪个界面打开Tip,用于逻辑判断SL:GetValue("ITEMFROMUI_ENUM")
	data.itemData		--物品数据
    data.hideCompare    --如果是装备，判断否隐藏装备比较
]]


function CommonEquipTip:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)

	self._buttons = {self._ui.Btn1,self._ui.Btn2 }
	self._viewList = {self._ui.Pop1,self._ui.Pop2,self._ui.Pop3}

	self.stageClickHandler = handler(self, self.StageClickEvent)

	self.STAGE_EVENT_EQUIP_TIP = "STAGE_EVENT_EQUIP_TIP"

	self._originListSize = {FGUI:getSize(FGUI:GetChild(self._ui.Pop1, "Content"))}

	self._ui.bg = self._ui.Pops --截图节点禁止删除
end

function CommonEquipTip:InitEquipData(data)
	local itemData  = data.itemData
	local isCompare = false

	self._viewModelList = {EquipTipViewModel.new(1,itemData)}
	local diffEquips = nil
	if not data.hideCompare and data.from == ItemFrom.BAG then
		diffEquips = FGUIFunction:GetDiffEquip(itemData)
		if diffEquips and #diffEquips > 0 then
			isCompare = true
		end

		if isCompare then
			for i = 1, #diffEquips do
				table.insert(self._viewModelList ,EquipTipViewModel.new(#self._viewModelList + 1,diffEquips[i]))
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
	FGUI:StageEvent_AddListener(self.STAGE_EVENT_EQUIP_TIP,self.stageClickHandler)
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
			local maxH = screenH - 100
			local canScroll = false
			if pHei > maxH then
				subH = pHei - maxH
				canScroll = true
				self._scrollList[i] = true
			end
			local contentW, contentH = FGUI:getSize(contentList)
			local maxContentWid = self._viewModelList[i] and self._viewModelList[i]:GetContentMaxWidth()
			FGUI:setSize(contentList, maxContentWid, contentH - subH)

			local scrollPane = FGUI:GetScrollPane(contentList)
			if scrollPane then
				FGUI:ScrollPane_setTouchEffect(scrollPane, canScroll)
			end

			FGUI:setTouchEnabled(contentList, canScroll)


		end
	end

	FGUI:GGroup_EnsureBoundsCorrect(pops)
	FGUI:Stage_ForceUpdate()
end
function CommonEquipTip:Exit()
	FGUI:StageEvent_RemoveListener(self.STAGE_EVENT_EQUIP_TIP)
end

function CommonEquipTip:StageClickEvent(data)
	if data.eventName == self.STAGE_EVENT_EQUIP_TIP then
		local tapClose = true
		local eventInitiator = FGUI:EventContext_getInitiator(data.eventData)
		if eventInitiator then
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
			end
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
				-- 装备佩戴
				if data and data.from == ItemFrom.BAG  and not addBtnMap[2] then
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
		self:SetBtnInfo(i, itemData, btnCfgType)
	end
end

return CommonEquipTip