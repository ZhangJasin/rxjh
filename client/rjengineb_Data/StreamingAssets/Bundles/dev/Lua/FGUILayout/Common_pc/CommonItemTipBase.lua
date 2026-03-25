local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CommonItemTipBase = class("CommonItemTipBase", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
--[[
	data.from           --从哪个界面打开Tip,用于逻辑判断SL:GetValue("ITEMFROMUI_ENUM")
	data.itemData		--物品数据
    data.hideCompare    --如果是装备，判断否隐藏装备比较
]]


function CommonItemTipBase:Create()
	self._ui = FGUI:ui_delegate(self.component)
	--对应
	self.textList = {}
	self.Content = self._ui.Content
	self.textList[1] = self._ui.Content:GetChild("Desc")
	self.textList[2] = self._ui.Content:GetChild("BaseAttr")
	self.textList[13] = self._ui.Content:GetChild("BaseAttr")
	self.textList[14] = self._ui.Content:GetChild("GetWay")
	self.textList[17] = self._ui.Content:GetChild("Level")
	self.textList[20] = self._ui.Content:GetChild("MoneyNum")
	self.textList[21] = self._ui.Content:GetChild("MoneyNum")
	self.textList[25] = self._ui.Content:GetChild("DuraNum")
	self.textList[26] = self._ui.Content:GetChild("DuraNum")
    self.textList[27] = self._ui.Content:GetChild("QigongLv")

	self.stageClickHandler = handler(self, self.StageClickEvent)

	self.STAGE_EVENT_COMMON_TIP = "STAGE_EVENT_COMMON_TIP"

	self.onChangeAutoSwitchHandler = handler(self, self.OnChangeAutoSwitchEvent)
end

function CommonItemTipBase:Enter(data)
	self._curItemID = data and data.itemData and data.itemData.ID
	self:RefreshItemView(data)
	self:InitAutoSwitchPanel(data.from == SL:GetValue("ITEMFROMUI_ENUM").BAG)
	self:InitTipPos()
	FGUI:StageEvent_AddListener(self.STAGE_EVENT_COMMON_TIP,self.stageClickHandler)
end

function CommonItemTipBase:Exit()
	FGUI:StageEvent_RemoveListener(self.STAGE_EVENT_COMMON_TIP)
end

function CommonItemTipBase:InitAutoSwitchPanel(isShow)
	FGUI:setVisible(self._ui.panel_auto_switch, isShow)
	if isShow and self._curItemID then
		local autoCheckBox = FGUI:GetChild(self._ui.panel_auto_switch, "checkBox_auto")
		FGUI:GButton_setSelected(autoCheckBox, FGUIFunction:GetQuickUseItemShow(self._curItemID))
		FGUI:setOnClickEvent(autoCheckBox, self.onChangeAutoSwitchHandler)
	end
end

function CommonItemTipBase:OnChangeAutoSwitchEvent()
	local isSelected = FGUI:GButton_getSelected(self._ui.checkBox_auto)
	SL:SetQuickUseItemShow(self._curItemID, isSelected)
end

function CommonItemTipBase:InitTipPos()
	local pops = self._ui.Pop
	self.scrollList = false
	FGUI:GList_resizeToFit(self._ui.Content)
	FGUI:GGroup_EnsureBoundsCorrect(pops)

	local  pw,ph = FGUI:getSize(self._ui.Pop)
	local sh = SL:GetMetaValue("SCREEN_HEIGHT")


	local subH = 0
	if ph + 100 >= sh then
		subH =ph - sh + 100
		self.scrollList = true
	end
	local  cw,ch = FGUI:getSize(self._ui.Content)
	FGUI:setSize(self._ui.Content, cw, ch - subH)
	FGUI:GGroup_EnsureBoundsCorrect(pops)

	local  s = FGUI:GetScrollPane(self._ui.Content)
	if s then
		FGUI:ScrollPane_setTouchEffect(s,subH > 0)
	end
	FGUI:setTouchEnabled(self._ui.Content, subH > 0)
end

function CommonItemTipBase:StageClickEvent(data)
	if data.eventName == self.STAGE_EVENT_COMMON_TIP then
		local tapClose = true
		tapClose = self:CheckInitiatorIsButton(data)
		if tapClose then
			self:Close()
		end
	end
end

function CommonItemTipBase:CheckListEnable()
	return self.scrollList
end

function CommonItemTipBase:RefreshItemView(data)
	local itemData = data.itemData
	itemData.isShowCount = false
	ItemUtil:RefreshItemUIByData(self._ui.CommonItem,itemData)
	ItemUtil:UpdateIsShowLockByItemID(self._ui.CommonItem,itemData)
	ItemUtil:SetItemSubScriptByItemID(self._ui.CommonItem,itemData.ID)
	local nameColor = itemData.Color and SL:GetColorByStyleId(itemData.Color) or "#FFFFFF"
	FGUI:GTextField_setText(self._ui.Name,itemData.Name)
    FGUI:GTextField_setColor(self._ui.Name, nameColor)

	local groupId = itemData.TipsGroupId or 7
	local groupCfg = SL:GetValue("ITEMTIPS_GROUP_CONFIG", groupId)
	for k, v in pairs(self.textList) do
		FGUI:setVisible(v, false)
	end
	for i, module in ipairs(groupCfg.Module) do
		local moduleCfg = SL:GetValue("ITEMTIPS_MODULE_CONFIG", module)
		local showModuleName = moduleCfg and moduleCfg.NameShow == 1
		local textContent = self.textList[module]
		if textContent then
			FGUI:setVisible(textContent, true)
			if module == 1 then										--描述
				local desc = itemData.Desc
				if desc and string.len(desc) > 0 then
					FGUI:GTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
				else
					FGUI:GTextField_setText(textContent, "")
				end
			end

			if module == 2 or module == 13 then									--基础属性
				local attr = self:GetShowAttData(itemData)
				if attr and string.len(attr) > 0 then
					FGUI:GTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, attr) or attr)
				else
					FGUI:setVisible(textContent, false)
				end
			end
			if module == 14 then									--出处
				local config = SL:GetValue("ITEM_DATA", itemData.Index or itemData.ID)
				if config and config.GetWayInfo  then
					local pathInfo = config.GetWayInfo or ""
					if pathInfo and string.len(pathInfo) > 0 then
						FGUI:GTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, pathInfo) or pathInfo)
					else
						FGUI:setVisible(textContent, false)
					end
				else
					SL:Print("config or config.GetWayInfo is nil",itemData.Index or itemData.ID)
					FGUI:setVisible(textContent, false)
				end
			end
			if module == 17 then									 -- 等级
                local canUse = ItemUtil:CheckNeedLevel(itemData)
                local color = canUse and "#FFFFFF" or "#FF0000"
                local desc = itemData.NeedLevel
                desc = string.format("[color=%s]%s[/color]", color, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
                if desc and string.len(desc) > 0 then
                    FGUI:GRichTextField_setText(textContent, desc)
                end
            end
			if module == 20 or module == 21 then
				local moneyIds =string.split(moduleCfg.ValuesEx,"#")
				local str = ""
				if moneyIds and #moneyIds > 0 then
					local itemName = SL:GetValue("ITEM_NAME", tonumber(moneyIds[1]))
					local  cnt = SL:GetValue("MONEY", moneyIds[1])
					str = str .. string.format("[color=#FF0000]%s：%s[/color]", itemName, cnt)
					for j = 2, #moneyIds do
						itemName = SL:GetValue("ITEM_NAME", tonumber(moneyIds[j]))
						cnt = SL:GetValue("MONEY", moneyIds[j])
						str = str .. string.format("\n[color=#FF0000]%s：%s[/color]", itemName, cnt)
					end
				end
				str = showModuleName and string.format("%s%s", moduleCfg.Name, str) or str
				FGUI:GTextField_setText(textContent, str)
			end
			if module == 25 or module == 26 then
				if itemData.Dura then
					FGUI:GTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, itemData.Dura) or itemData.Dura)
				end
			end

			if module == 27 then
                local qigongId = itemData.nQiGongId
                local qigongLv = itemData.nQiGongLv
                if qigongId and qigongLv then
                    local name = qigongId == 0 and "全部气功" or SL:GetValue("SKILL_QIGONG_NAME_BY_ID", qigongId)
                    local desc = string.format("%s等级：+%s", name or "", qigongLv)
                    FGUI:GRichTextField_setText(textContent, string.format("[color=%s]%s[/color]", "#A4E0F5", showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc))
                else
                    FGUI:setVisible(textContent, false)
                end
            end

		end
	end
end

local extraParam = {}
function CommonItemTipBase:GetShowAttData(itemData)
	local pos = SL:GetValue("EQUIP_POS_BY_STDMODE", itemData.StdMode)
	local showAttStr = ""
	extraParam.multiple = itemData.Star
	local attData = FGUIFunction:GetAttShowData(itemData.Attribute, nil, extraParam)

	local addNewLine = 0
	for _, att in pairs(attData) do
		local name = att.name or ""
		local value = att.value
		if addNewLine == 1 then
			showAttStr = showAttStr.. '\n'
		end
		showAttStr = string.format("%s[color=%s]%s：%s[/color]", showAttStr, SL:GetColorByStyleId(att.color or 255), name, value)
		addNewLine = 1
	end

	return showAttStr
end
return CommonItemTipBase