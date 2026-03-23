local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CommonItemTipBase = class("CommonItemTipBase", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local CommonPurchaseItemPop = requireFGUILayout("Common/CommonPurchaseItemPop")

--[[
	data.from           --从哪个界面打开Tip,用于逻辑判断SL:GetValue("ITEMFROMUI_ENUM")
	data.itemData		--物品数据
    data.hideCompare    --如果是装备，判断否隐藏装备比较
	data.buyParam		-- 购买相关参数, 有则显示购买框 
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
	self.textList[20] = self._ui.Content:GetChild("MoneyNum")
	self.textList[21] = self._ui.Content:GetChild("MoneyNum")
	self.textList[25] = self._ui.Content:GetChild("DuraNum")
	self.textList[26] = self._ui.Content:GetChild("DuraNum")
    self.textList[27] = self._ui.Content:GetChild("QigongLv")
    self.textList[28] = self._ui.Content:GetChild("CurNum")
    self.textList[29] = self._ui.Content:GetChild("LimitTime")

	-- Top
	self._topContent = self._ui.TopContent
	self.textList[17] = FGUI:GetChild(self._topContent, "Level")
    self.textList[15] = FGUI:GetChild(self._topContent, "Job")
    self.textList[16] = FGUI:GetChild(self._topContent, "Ms")
    self.textList[19] = FGUI:GetChild(self._topContent, "Zy")
    self.textList[22] = FGUI:GetChild(self._topContent, "Sex")
    self.textList[24] = FGUI:GetChild(self._topContent, "EquipType")

	self.stageClickHandler = handler(self, self.StageClickEvent)

	self.STAGE_EVENT_COMMON_TIP = "STAGE_EVENT_COMMON_TIP"

	self.onChangeAutoSwitchHandler = handler(self, self.OnChangeAutoSwitchEvent)

	self._purchaseBtnKeys = {"btn_add", "btn_sub", "btn_m_min", "btn_m_max", "btn_purchase"}

	FGUI:setOnClickEvent(self._ui.Mask, handler(self, self.Close))

	self._purchasePanel = FGUIFunction:BindClass(self._ui.panel_purchase, "Common/CommonPurchaseItemPop")
	self._purchasePanel:Create()
end

function CommonItemTipBase:Enter(data)
	self._curItemID = data and data.itemData and data.itemData.ID
	self:RefreshItemView(data)
	self:InitAutoSwitchPanel(data.from == SL:GetValue("ITEMFROMUI_ENUM").BAG)
	self:InitItemPurchasePanel(data and data.buyParam)
	self:InitTipPos()
	if SL:GetValue("IS_PC_OPER_MODE") then
		FGUI:StageEvent_AddListener(self.STAGE_EVENT_COMMON_TIP, self.stageClickHandler)
	end
end

function CommonItemTipBase:Exit()
	if self.textList[29] then
		FGUI:stopAllActions(self.textList[29])
	end
	self._purchasePanel:Exit()
	if SL:GetValue("IS_PC_OPER_MODE") then
		FGUI:StageEvent_RemoveListener(self.STAGE_EVENT_COMMON_TIP)
	end
end

function CommonItemTipBase:InitAutoSwitchPanel(isShow)
	if SL:GetValue("IS_PC_OPER_MODE") then
		isShow = false
	end
	local repeatSwitch = SL:GetValue("SETTING_QUICKWINDOW_NOT_REPEATED_SHOW")
    if isShow and repeatSwitch then
        isShow = false
    end
	FGUI:setVisible(self._ui.panel_auto_switch, isShow)
	if isShow and self._curItemID then
		local autoCheckBox = FGUI:GetChild(self._ui.panel_auto_switch, "checkBox_auto")
		FGUI:GButton_setSelected(autoCheckBox, FGUIFunction:GetQuickUseItemShow(self._curItemID))
		FGUI:setOnClickEvent(autoCheckBox, self.onChangeAutoSwitchHandler)
	end
end

function CommonItemTipBase:OnChangeAutoSwitchEvent()
	local isSelected = FGUI:GButton_getSelected(self._ui.checkBox_auto)
	FGUIFunction:SetQuickUseItemShow(self._curItemID, isSelected)
end

function CommonItemTipBase:InitItemPurchasePanel(buyParam)
	local isShow = false
	if buyParam and next(buyParam) and (buyParam.storeId or buyParam.customBuy) then
		buyParam.itemID = self._curItemID
		isShow = true
	end
	if SL:GetValue("IS_PC_OPER_MODE") then
		isShow = false
	end
	self._purchasePanel:Enter(buyParam)

	FGUI:setVisible(self._ui.panel_purchase, isShow)
end

function CommonItemTipBase:InitTipPos()
	local pops = self._ui.Pop
	self.scrollList = false
	FGUI:GList_resizeToFit(self._ui.Content)
	FGUI:GGroup_EnsureBoundsCorrect(pops)
	FGUI:GGroup_EnsureBoundsCorrect(self._ui.PopI)

	local  pw,ph = FGUI:getSize(self._ui.Pop)
	local sh = SL:GetMetaValue("SCREEN_HEIGHT")


	local subH = 0
	if ph + 100 >= sh then
		subH =ph - sh + 100
		self.scrollList = true
	end
	local  cw,ch = FGUI:getSize(self._ui.Content)
	FGUI:setSize(self._ui.Content, SL:GetEvenNum(cw), SL:GetEvenNum(ch - subH))
	FGUI:GGroup_EnsureBoundsCorrect(pops)
	FGUI:GGroup_EnsureBoundsCorrect(self._ui.PopI)

	local  s = FGUI:GetScrollPane(self._ui.Content)
	if s then
		FGUI:ScrollPane_setTouchEffect(s,subH > 0)
	end
	FGUI:setTouchEnabled(self._ui.Content, subH > 0)
end

function CommonItemTipBase:StageClickEvent(data)
	local eventInitiator = FGUI:EventContext_getInitiator(data.eventData)
	if data.eventName == self.STAGE_EVENT_COMMON_TIP then
		local tapClose = true
		if eventInitiator then
			local purchasePanel = self._ui.panel_purchase
			local pRoot = self._purchasePanel
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
		if tapClose then
			tapClose = self:CheckInitiatorIsButton(data)
		end
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

	local gradeController = FGUI:getController(self.component, "grade")
	if itemData.Grade and gradeController then
		gradeController.selectedIndex = itemData.Grade
	end

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
		local conditionData = {}
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
			if module == 15 then									 -- 职业
                if not conditionData.job then
                    conditionData = self:GetTransferData(itemData)
                end

                local jobStr = ""
                if conditionData.job and string.len(conditionData.job) > 0 then
                    local color = ItemUtil:CheckJob(itemData) and "#FFFFFF" or "#FF0000"
                    jobStr = string.format("[color=%s]%s[/color]", color, showModuleName and string.format("%s%s", moduleCfg.Name, conditionData.job) or conditionData.job)
                else
                    if conditionData.jobId and  conditionData.jobId == 0 then
                        jobStr = SL:GetValue("I18N_STRING", 70000104)
                        jobStr = string.format("[color=%s]%s[/color]", "#FFFFFF", showModuleName and string.format("%s%s", moduleCfg.Name, jobStr) or jobStr)
                    end
                end
                FGUI:GTextField_setText(textContent, jobStr)
            end

            if module == 16 then									 -- 名声
                if not conditionData.TransferName or not conditionData.TransferLV then
                    conditionData = self:GetTransferData(itemData)
                end
                conditionData.TransferName = conditionData.TransferName or "1"
                conditionData.TransferLV = conditionData.TransferLV or 0

                local color = ItemUtil:CheckTransferLV(itemData) and "#FFFFFF" or "#FF0000"
                local desc = conditionData.TransferName
                FGUI:GTextField_setText(textContent, string.format("[color=%s]%s[/color]", color, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc))
            end
		
			if module == 17 then									 -- 等级
                local canUse = ItemUtil:CheckNeedLevel(itemData)
                local color = canUse and "#FFFFFF" or "#FF0000"
                local desc = itemData.NeedLevel
                desc = string.format("[color=%s]%s[/color]", color, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
                if desc and string.len(desc) > 0 then
                    FGUI:GTextField_setText(textContent, desc)
                end
            end
			if module == 19 then									 -- 阵营
                if not conditionData.TransferZy then
                    conditionData = self:GetTransferData(itemData)
                end
                if conditionData.TransferZy then
                    local color = "#FFFFFF"
                    if conditionData.TransferZy > 0 then
                        color = ItemUtil:CheckTransferCamp(itemData) and "#FFFFFF" or "#FF0000"
                    end
                    local desc = SL:GetValue("I18N_STRING", 70000104 + conditionData.TransferZy)
                    desc = showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc
                    FGUI:GTextField_setText(textContent, string.format("[color=%s]%s[/color]", color, desc))
                else
                    FGUI:setVisible(textContent, false)
                end
            end

			if module == 20 or module == 21 then
				local moneyIds =string.split(moduleCfg.ValuesEx,"#")
				local str = ""
				if moneyIds and #moneyIds > 0 then
					local itemName = SL:GetValue("ITEM_NAME", tonumber(moneyIds[1]))
					local cnt = SL:GetThousandSepString(SL:GetValue("MONEY", moneyIds[1]))
					str = str .. string.format("[color=#FF0000]%s：%s[/color]", itemName, cnt)
					for j = 2, #moneyIds do
						itemName = SL:GetValue("ITEM_NAME", tonumber(moneyIds[j]))
						cnt = SL:GetThousandSepString(SL:GetValue("MONEY", moneyIds[j]))
						str = str .. string.format("\n[color=#FF0000]%s：%s[/color]", itemName, cnt)
					end
				end
				str = showModuleName and string.format("%s%s", moduleCfg.Name, str) or str
				FGUI:GTextField_setText(textContent, str)
			end

			if module == 22 then									 -- 性别
                local sex = itemData.Gender or 0
                local mySex = SL:GetValue("SEX")
                local sexStr = ""
                local sexTypeStr = ""
                local color = "#FFFFFF"
                if sex and sex >= 0 and sex <= 1 then
                    color = sex == mySex and "#FFFFFF" or "#FF0000"
                    sexTypeStr = SL:GetValue("I18N_STRING", 60003004 + sex)
                elseif sex == 2 then    -- 通用
                    sexTypeStr = SL:GetValue("I18N_STRING", 70000104)
                end
                sexStr = string.format("[color=%s]%s[/color]", color, showModuleName and string.format("%s%s", moduleCfg.Name, sexTypeStr) or sexTypeStr)
                FGUI:GTextField_setText(textContent,sexStr)
            end

			if module == 24 then                                    -- 装置
                local equipTypeName = itemData.StdName or ""
                FGUI:GTextField_setText(textContent, string.format("[color=%s]%s[/color]", "#FFFFFF", showModuleName and string.format("%s%s", moduleCfg.Name, equipTypeName) or equipTypeName))
            end

			if module == 25 or module == 26 then
				local duraV = itemData.Dura or itemData.DuraMax
				if duraV then
					FGUI:GTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, duraV) or duraV)
				else
					FGUI:setVisible(textContent, false)
				end
			end

			if module == 27 then
                local qigongId = itemData.nQiGongId
                local qigongLv = itemData.nQiGongLv
                if qigongId and qigongLv then
                    local name = qigongId == 0 and "全部气功" or SL:GetValue("SKILL_QIGONG_NAME_BY_ID", qigongId)
                    local desc = string.format("%s等级：+%s", name or "", qigongLv)
                    FGUI:GTextField_setText(textContent, string.format("[color=%s]%s[/color]", "#A4E0F5", showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc))
                else
                    FGUI:setVisible(textContent, false)
                end
            end

			if module == 28 then                                    -- 数量显示
                local num = SL:GetThousandSepString(SL:GetValue("ITEM_COUNT", self._curItemID))
                local desc = showModuleName and string.format("%s%s", moduleCfg.Name, num) or num
                FGUI:GTextField_setText(textContent, desc)
            end

			if module == 29 then
                local desc, needCountDown = self:GetLimitTimeStr(itemData)
                if desc and string.len(desc) > 0 then
                    FGUI:GTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
					if needCountDown then
						FGUI:stopAllActions(textContent)
						SL:schedule(textContent, function()
							local desc = self:GetLimitTimeStr(itemData)
                    		FGUI:GTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
						end, 1)
					end
                else
                    FGUI:setVisible(textContent, false)
                end
            end
		end
	end

	self:ReorderContentList(groupCfg.Module)
end

-- 重新排序子控件
function CommonItemTipBase:ReorderContentList(orderList)
	if not orderList or #orderList <= 0 then
		return
	end
    local contentList = self._ui.Content

	local orderIndex = 0
    for i = 1, #orderList do
		local moduleId = orderList[i]
        local child = self.textList[moduleId]
		local childIndex = child and FGUI:GetChildIndex(contentList, child)
		local childValid = childIndex and childIndex ~= -1
        if childValid then
            FGUI:SetChildIndex(contentList, child, orderIndex)
			orderIndex = orderIndex + 1
        end
    end
end

function CommonItemTipBase:GetTransferData(itemConfig)
    local conditionData = {}
    if itemConfig and itemConfig.TransferID then
        local config = SL:GetMetaValue("TRANSFER_CONFIG_BY_ID", itemConfig.TransferID)
        if config then
            conditionData.job =  SL:GetMetaValue("JOB_NAME_BY_ID", config.ClassID)
            conditionData.jobId = config.ClassID
            conditionData.TransferZy = config.Type or 0
            conditionData.TransferLV =  config.TransferLV or 0
            conditionData.TransferName= config.TransferName or ""
        end
    end

    return conditionData
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

---------------------------------------------------------------------------
-- 限时时间显示
function CommonItemTipBase:GetLimitTimeStr(itemData)
    local str = ""
    if not itemData then
        return str
    end
    local limitType = itemData.CutDownType
    if not limitType then
        return str
    end
    
    local startTime = itemData.startTime
    local totalTime = itemData.totalTime
    if startTime == 0 and totalTime == 0 then
        return str
    end

	local needCountDown = false
    if limitType == 1 then  -- 获得后开始计时(离线也计算时间)
		local endTime = startTime + totalTime
        local date = os.date("*t", endTime)
        str = string.format("[color=#fd392f]%d/%02d/%02d %02d:%02d:%02d到期[/color]", date.year, date.month, date.day, date.hour, date.min, date.sec)
    
    elseif limitType == 2 then -- 获得后开始计时(离线不会计算时间)
        local remainTime = math.max(totalTime - (SL:GetValue("SERVER_TIME") - startTime), 0)
        str = string.format("[color=#fabf33]%s[/color]", SL:SecondToHMS(remainTime, true))
		needCountDown = true

    elseif limitType == 4 then -- 穿戴后开始计时
        local isEquip = itemData.MakeIndex and SL:GetValue("EQUIP_DATA_BY_MAKEINDEX", itemData.MakeIndex)
        local remainTime = totalTime
        if isEquip then
            remainTime = math.max(totalTime - (SL:GetValue("SERVER_TIME") - startTime), 0)
			needCountDown = true
        end
        str = string.format("[color=#fabf33]%s[/color]", SL:SecondToHMS(remainTime, true))
    end

    -- 手机端字号20
    if str and string.len(str) > 0 and not SL:GetValue("IS_PC_OPER_MODE") then
        str = string.format("[size=20]%s[/size]", str)
    end

    return str, needCountDown
end

return CommonItemTipBase