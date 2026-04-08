local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local BagRecyclePanel = class("BagRecyclePanel", BaseFGUILayout)
local ItemMoney = SL:RequireFile("FGUILayout/Item/ItemMoney")

local moneyId = { 1, 9 }
function BagRecyclePanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
	self._bagPanel = FGUIFunction:BindClass(self._ui.BagPanel, "Bag/BagPanel")
	self._bagPanel:Create()
	self.bagRecycleViewModel = requireFGUILayout("Bag/BagRecycleViewModel")
	self.AutoPick = SL:GetValue("U", 6)
	self.AutoSell = SL:GetValue("U", 7)
	self.FiliterLv = SL:GetValue("U", 8)
	self.bagRecycleViewModel:InitRecycleCondition()
	self:InitData()
	self:InitView()
end

function BagRecyclePanel:Enter()
	self:RegisterEvent()
	self._bagPanel:Enter({ disableCellDoubleClick = true })
	self:RefreshData()
	self.bagRecycleViewModel:Enter()
	self:ShowLevelDetail(false)
	SL:ComponentAttach(SLDefine.SUIComponentTable.BagRecycle, self._ui.Node_attach)
end

function BagRecyclePanel:Exit()
	SL:ComponentDetach(SLDefine.SUIComponentTable.BagRecycle)

	self:UnRegisterEvent()
	self._bagPanel:Exit()
	self.bagRecycleViewModel:Exit()
	self:ShowLevelDetail(false)

	SL:onLUAEvent(LUA_EVENT_BAG_REFRESH_PAGE)
end

function BagRecyclePanel:Destroy()
	self.bagRecycleViewModel:UnBind(self)
	self._bagPanel:CleanItem()
end

function BagRecyclePanel:InitView()
	FGUI:setOnClickEvent(self._ui.BtnClose, function()
		self:CloseBagUI()
	end)

	FGUI:GList_addOnClickItemEvent(self._ui.List_Tab, function(context)
		local idx = FGUI:GetChildIndex(self._ui.List_Tab, context.data)
		self:ClickTabEvent(idx)
	end)

	FGUI:GList_addOnClickItemEvent(self._ui.List_CheckBox, function(context)
		local idx = FGUI:GetChildIndex(self._ui.List_CheckBox, context.data)
		self:ClickCheckBoxEvent(idx)
	end)

	FGUI:setOnClickEvent(self._ui.CheckBoxTotalLv, function()
		self:ClickCheckBoxTotalLvEvent()
	end)

	FGUI:setOnClickEvent(self._ui.Btn_LvDetail, function()
		self:ShowLevelDetail(true)
	end)

	FGUI:setOnClickEvent(self._ui.BtnDetailClose, function()
		self:ShowLevelDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.MaskLv, function()
		self:ShowLevelDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.BtnDetailClose1, function()
		self:ShowJGSDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.MaskLv1, function()
		self:ShowJGSDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.BtnDetailClose2, function()
		self:ShowHYSDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.MaskLv2, function()
		self:ShowHYSDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.BtnDetailClose3, function()
		self:ShowRXSDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.MaskLv3, function()
		self:ShowRXSDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.BtnDetailClose4, function()
		self:ShowHYJGSDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.MaskLv4, function()
		self:ShowHYJGSDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.BtnDetailClose5, function()
		self:ShowBPHYSDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.MaskLv5, function()
		self:ShowBPHYSDetail(false)
	end)

	FGUI:setOnClickEvent(self._ui.BtnSell, function()
		self:ClickBtnSellEvent()
	end)

	FGUI:setOnClickEvent(self._ui.AutoSell, function()
		self:ClickAutoSellEvent()
	end)

	FGUI:setOnClickEvent(self._ui.AutoPick, function()
		self:ClickAutoPickEvent()
	end)

	FGUI:GList_addOnClickItemEvent(self._ui.List_LvCheckBox, function(context)
		local idx = FGUI:GetChildIndex(self._ui.List_LvCheckBox, context.data)
		self:ClickLvCheckBoxEvent(idx)
	end)

	FGUI:GList_itemRenderer(self._ui.List_CheckBox, handler(self, self.ListCheckBoxRenderer))
	FGUI:GList_itemRenderer(self._ui.List_LvCheckBox, handler(self, self.ListLvCheckBoxRenderer))

	FGUI:GList_setNumItems(self._ui.List_LvCheckBox, #self.selectLvCheckBoxes)

	--金刚石
	FGUI:GList_itemRenderer(self._ui.List_JGSCheckBox, handler(self, self.ListJGSCheckBoxRenderer))
	FGUI:GList_setNumItems(self._ui.List_JGSCheckBox, #self.selectJGSCheckBoxes)
	--寒玉石
	FGUI:GList_itemRenderer(self._ui.List_HYSCheckBox, handler(self, self.ListHYSCheckBoxRenderer))
	FGUI:GList_setNumItems(self._ui.List_HYSCheckBox, #self.selectHYSCheckBoxes)
	--热血石
	FGUI:GList_itemRenderer(self._ui.List_RXSCheckBox, handler(self, self.ListRXSCheckBoxRenderer))
	FGUI:GList_setNumItems(self._ui.List_RXSCheckBox, #self.selectRXSCheckBoxes)
	--混元金刚石
	FGUI:GList_itemRenderer(self._ui.List_HYJGSCheckBox, handler(self, self.ListHYJGSCheckBoxRenderer))
	FGUI:GList_setNumItems(self._ui.List_HYJGSCheckBox, #self.selectHYJGSCheckBoxes)
	--冰魄寒玉石
	FGUI:GList_itemRenderer(self._ui.List_BPHYSCheckBox, handler(self, self.ListBPHYSCheckBoxRenderer))
	FGUI:GList_setNumItems(self._ui.List_BPHYSCheckBox, #self.selectBPHYSCheckBoxes)

	self.moneyComponents = {}
	for i = 1, #moneyId do
		local itemCfg = SL:GetValue("ITEM_DATA", moneyId[i])
		if itemCfg then
			ItemMoney.new(self._ui["MoneyIcon" .. i], itemCfg)
		end
		self.moneyComponents[i] = { textObj = self._ui["MoneyText" .. i] }
	end
	local autoPick = FGUI:getController(self._ui.AutoPick, "isSelect")
	FGUI:Controller_setSelectedIndex(autoPick, self.AutoPick)

	local autoSell = FGUI:getController(self._ui.AutoSell, "isSelect")
	FGUI:Controller_setSelectedIndex(autoSell, self.AutoSell)

	local cSelect = FGUI:getController(self._ui.CheckBoxTotalLv, "isSelect")
	FGUI:Controller_setSelectedIndex(cSelect, self.FiliterLv)
	self.bagRecycleViewModel:RefreshSelectItemsByConditions()
end

function BagRecyclePanel:ListCheckBoxRenderer(idx, item)
	local cModel = self.selectCheckBoxes[idx + 1]
	if cModel then
		local textTitle = FGUI:GetChild(item, "title")
		if textTitle then
			FGUI:GTextField_setUnderline(textTitle, self.selectTab == 1)
			FGUI:addOnClickEvent(textTitle, function()
				if cModel:GetCheckBoxName() == "金刚石" then
					self:ShowJGSDetail(true)
				elseif cModel:GetCheckBoxName() == "寒玉石" then
					self:ShowHYSDetail(true)
				elseif cModel:GetCheckBoxName() == "热血石" then
					self:ShowRXSDetail(true)
				elseif cModel:GetCheckBoxName() == "混元金刚石" then
					self:ShowHYJGSDetail(true)
				elseif cModel:GetCheckBoxName() == "冰魄寒玉石" then
					self:ShowBPHYSDetail(true)
				end
			end)
		end
		FGUI:GButton_setTitle(item, cModel:GetCheckBoxName())
		local cSelect = FGUI:getController(item, "isSelect")
		FGUI:Controller_setSelectedIndex(cSelect, cModel.isSelect and 1 or 0)

		ssrMessage:sendmsgEx("bag", "setCheckBox",
			{ boxName = cModel:GetCheckBoxName(), status = cModel.isSelect and 1 or 0 })
	end
end

function BagRecyclePanel:ListLvCheckBoxRenderer(idx, item)
	local cModel = self.selectLvCheckBoxes[idx + 1]
	if cModel then
		FGUI:GButton_setTitle(item, cModel:GetCheckBoxName())
		local cSelect = FGUI:getController(item, "isSelect")
		FGUI:Controller_setSelectedIndex(cSelect, cModel.isSelect and 1 or 0)
		ssrMessage:sendmsgEx("bag", "setCheckBox",
			{ boxName = cModel:GetCheckBoxName(), status = cModel.isSelect and 1 or 0 })
	end
end

function BagRecyclePanel:ListJGSCheckBoxRenderer(idx, item)
	local cModel = self.selectJGSCheckBoxes[idx + 1]
	if cModel then
		FGUI:GButton_setTitle(item, cModel:GetCheckBoxName())
		--local cSelect = FGUI:getController(item, "isSelect")
		--FGUI:Controller_setSelectedIndex(cSelect, cModel.isSelect and 1 or 0)
		--ssrMessage:sendmsgEx("bag", "setCheckBox",
		--	{ boxName = cModel:GetCheckBoxName(), status = cModel.isSelect and 1 or 0 })
	end
end

function BagRecyclePanel:ListHYSCheckBoxRenderer(idx, item)
	local cModel = self.selectHYSCheckBoxes[idx + 1]
	if cModel then
		FGUI:GButton_setTitle(item, cModel:GetCheckBoxName())
		--local cSelect = FGUI:getController(item, "isSelect")
		--FGUI:Controller_setSelectedIndex(cSelect, cModel.isSelect and 1 or 0)
		--ssrMessage:sendmsgEx("bag", "setCheckBox",
		--	{ boxName = cModel:GetCheckBoxName(), status = cModel.isSelect and 1 or 0 })
	end
end

function BagRecyclePanel:ListRXSCheckBoxRenderer(idx, item)
	local cModel = self.selectRXSCheckBoxes[idx + 1]
	if cModel then
		FGUI:GButton_setTitle(item, cModel:GetCheckBoxName())
		--local cSelect = FGUI:getController(item, "isSelect")
		--FGUI:Controller_setSelectedIndex(cSelect, cModel.isSelect and 1 or 0)
		--ssrMessage:sendmsgEx("bag", "setCheckBox",
		--	{ boxName = cModel:GetCheckBoxName(), status = cModel.isSelect and 1 or 0 })
	end
end

function BagRecyclePanel:ListHYJGSCheckBoxRenderer(idx, item)
	local cModel = self.selectHYJGSCheckBoxes[idx + 1]
	if cModel then
		FGUI:GButton_setTitle(item, cModel:GetCheckBoxName())
		--local cSelect = FGUI:getController(item, "isSelect")
		--FGUI:Controller_setSelectedIndex(cSelect, cModel.isSelect and 1 or 0)
		--ssrMessage:sendmsgEx("bag", "setCheckBox",
		--	{ boxName = cModel:GetCheckBoxName(), status = cModel.isSelect and 1 or 0 })
	end
end

function BagRecyclePanel:ListBPHYSCheckBoxRenderer(idx, item)
	local cModel = self.selectBPHYSCheckBoxes[idx + 1]
	if cModel then
		FGUI:GButton_setTitle(item, cModel:GetCheckBoxName())
		--local cSelect = FGUI:getController(item, "isSelect")
		--FGUI:Controller_setSelectedIndex(cSelect, cModel.isSelect and 1 or 0)
		--ssrMessage:sendmsgEx("bag", "setCheckBox",
		--	{ boxName = cModel:GetCheckBoxName(), status = cModel.isSelect and 1 or 0 })
	end
end

function BagRecyclePanel:InitData()
	self.selectTab = 1
	self.selectCheckBoxes = {}
	self.bagRecycleViewModel:Bind(self)
	self.selectLvCheckBoxes = self.bagRecycleViewModel:GetLvCheckBoxModel()
	self.selectJGSCheckBoxes = self.bagRecycleViewModel:GetJGSCheckBoxModel()
	self.selectHYSCheckBoxes = self.bagRecycleViewModel:GetHYSCheckBoxModel()
	self.selectRXSCheckBoxes = self.bagRecycleViewModel:GetRXSCheckBoxModel()
	self.selectHYJGSCheckBoxes = self.bagRecycleViewModel:GetHYJGSCheckBoxModel()
	self.selectBPHYSCheckBoxes = self.bagRecycleViewModel:GetBPHYSCheckBoxModel()
end

function BagRecyclePanel:RefreshData()
	FGUI:GButton_FireClick(FGUI:GetChildAt(self._ui.List_Tab, 0), false, true)
end

function BagRecyclePanel:CloseBagUI()
	self:Close()
end

function BagRecyclePanel:ClickTabEvent(idx)
	self.selectTab = idx
	self.selectCheckBoxes = self.bagRecycleViewModel:GetTabCheckBoxModel(idx)
	FGUI:GList_setNumItems(self._ui.List_CheckBox, #self.selectCheckBoxes)
end

function BagRecyclePanel:ClickCheckBoxEvent(idx)
	local cModel = self.selectCheckBoxes[idx + 1]
	if cModel then
		cModel:Toggle()
	end
	self:ListCheckBoxRenderer(idx, FGUI:GetChildAt(self._ui.List_CheckBox, idx))
	self.bagRecycleViewModel:RefreshSelectItemsByConditions()
end

function BagRecyclePanel:ClickLvCheckBoxEvent(idx)
	local cModel = self.selectLvCheckBoxes[idx + 1]
	if cModel then
		cModel:Toggle()
	end
	self:ListLvCheckBoxRenderer(idx, FGUI:GetChildAt(self._ui.List_LvCheckBox, idx))
	self.bagRecycleViewModel:RefreshSelectItemsByConditions()
end

function BagRecyclePanel:ClickCheckBoxTotalLvEvent()
	self.bagRecycleViewModel:ToggleAllLv()
	local cSelect = FGUI:getController(self._ui.CheckBoxTotalLv, "isSelect")
	FGUI:Controller_setSelectedIndex(cSelect, self.bagRecycleViewModel.checkLevel and 1 or 0)
	ssrMessage:sendmsgEx("bag", "setFilterLv", self.bagRecycleViewModel.checkLevel and 1 or 0)
	self.bagRecycleViewModel:RefreshSelectItemsByConditions()
end

function BagRecyclePanel:ShowLevelDetail(state)
	FGUI:setVisible(self._ui.LvDetail, state)
end

function BagRecyclePanel:ShowJGSDetail(state)
	FGUI:setVisible(self._ui.JGSDetail, state)
end

function BagRecyclePanel:ShowHYSDetail(state)
	FGUI:setVisible(self._ui.HYSDetail, state)
end

function BagRecyclePanel:ShowRXSDetail(state)
	FGUI:setVisible(self._ui.RXSDetail, state)
end

function BagRecyclePanel:ShowHYJGSDetail(state)
	FGUI:setVisible(self._ui.HYJGSDetail, state)
end

function BagRecyclePanel:ShowBPHYSDetail(state)
	FGUI:setVisible(self._ui.BPHYSDetail, state)
end

function BagRecyclePanel:UpdateMoney()
	local data = self.bagRecycleViewModel:GetMoneyResDic()

	if data then
		for i = 1, #moneyId do
			local mNum = data[moneyId[i]] or 0
			if self.moneyComponents[i].textObj then
				local playerData = SL:GetValue("LOGIN_SELECTED_ROLE")
				local jc = SL:GetValue("ACTOR_MAX_ABIL_BY_ID", playerData.UserID, 118)
				if not jc then
					jc = 0
				end
				local newStr = mNum
				if i == 1 then
					newStr = mNum .. '<font color="#00ff00">(+' .. math.floor(tonumber(mNum * jc / 10000)) .. ')</font>'
				end
				FGUI:GTextField_setText(self.moneyComponents[i].textObj, newStr)
			end
		end
	end
end

function BagRecyclePanel:ClickBtnSellEvent()
	self.bagRecycleViewModel:RecycleSelectItems()
end

function BagRecyclePanel:ClickAutoSellEvent()
	local cSelect = FGUI:getController(self._ui.AutoSell, "isSelect")
	if self.AutoSell == 0 then
		self.AutoSell = 1
	else
		self.AutoSell = 0
	end
	FGUI:Controller_setSelectedIndex(cSelect, self.AutoSell)
	ssrMessage:sendmsgEx("bag", "setAutoSell", self.AutoSell)
end

function BagRecyclePanel:ClickAutoPickEvent()
	local cSelect = FGUI:getController(self._ui.AutoPick, "isSelect")
	if self.AutoPick == 0 then
		self.AutoPick = 1
	else
		self.AutoPick = 0
	end
	FGUI:Controller_setSelectedIndex(cSelect, self.AutoPick)
	ssrMessage:sendmsgEx("bag", "setAutoPick", self.AutoPick)
end

--------------------------- 注册事件 -----------------------------
function BagRecyclePanel:RegisterEvent()

end

function BagRecyclePanel:UnRegisterEvent()

end

return BagRecyclePanel
