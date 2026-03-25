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
local attrConfigs = SL:GetValue("ATTR_CONFIGS")
local fashion_jihuo  =  require("game_config/cfgcsv/fashion_jihuo")    -- 时装激活表 ItemTipsDesc
local ItemTipsDesc  =  require("game_config/cfgcsv/ItemTipsDesc")      -- 自定义物品描述
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
	self._purchasePanel:Exit()
	if SL:GetValue("IS_PC_OPER_MODE") then
		FGUI:StageEvent_RemoveListener(self.STAGE_EVENT_COMMON_TIP)
	end
end

function CommonItemTipBase:InitAutoSwitchPanel(isShow)
	if SL:GetValue("IS_PC_OPER_MODE") then
		isShow = false
	end
	FGUI:setVisible(self._ui.panel_auto_switch, isShow)
	if isShow and self._curItemID then
		local autoCheckBox = FGUI:GetChild(self._ui.panel_auto_switch, "checkBox_auto")
		-- FGUI:GButton_setSelected(autoCheckBox, SL:GetQuickUseItemShow(self._curItemID))
		FGUI:setOnClickEvent(autoCheckBox, self.onChangeAutoSwitchHandler)
	end
end

function CommonItemTipBase:OnChangeAutoSwitchEvent()
	local isSelected = FGUI:GButton_getSelected(self._ui.checkBox_auto)
	SL:SetQuickUseItemShow(self._curItemID, isSelected)
end

function CommonItemTipBase:InitItemPurchasePanel(buyParam)
	local isShow = false
	if buyParam and next(buyParam) then
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
	local nameStr = itemData.Name
	if itemData.Dura and itemData.Dura > 0 and itemData.DuraMax then
		-- dump(itemData)
		local duraStr = "\n持久度：" .. math.floor(itemData.Dura/1000) .. "/" .. math.floor(itemData.DuraMax/1000)
		duraStr = string.format("[color=%s]%s[/color]","#00ff00",duraStr)
		duraStr = string.format("[size=%s]%s[/size]",20,duraStr)
		nameStr = nameStr .. duraStr
	end 
	FGUI:GTextField_setLineSpacing(self._ui.Name, 10)
	FGUI:GTextField_setUBBEnabled(self._ui.Name, true)
	FGUI:GTextField_setText(self._ui.Name,nameStr)
    FGUI:GTextField_setColor(self._ui.Name, nameColor)

	local groupId = itemData.TipsGroupId or 7
	local groupCfg = SL:GetValue("ITEMTIPS_GROUP_CONFIG", groupId)
	for k, v in pairs(self.textList) do
		FGUI:setVisible(v, false)
	end
	self._buttons = {self._ui.Btn1,self._ui.Btn2,self._ui.Btn3}
	for i, module in ipairs(groupCfg.Module) do
		local moduleCfg = SL:GetValue("ITEMTIPS_MODULE_CONFIG", module)
		local showModuleName = moduleCfg and moduleCfg.NameShow == 1
		local textContent = self.textList[module]
		local conditionData = {}
		if textContent then
			FGUI:setVisible(textContent, true)
			if module == 1 then										--描述
				local desc = itemData.Desc
				if itemData.ExAbil then
                    local desc2 = self:GetZDYData(itemData.ID,itemData.ExAbil)
					-- print(desc2)
                    -- FGUI:GTextField_setText(self.textList[23], string.format("[color=%s]%s[/color]","#FFFFFF",desc))
					if ItemTipsDesc[itemData.ID] then
						desc = self:GetZDYDesc(itemData)
					end
					if desc then
                    	desc = desc2..desc
					else
						desc = desc2
					end
					-- print(desc)
                end
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
				-- local config = SL:GetValue("ITEM_DATA", itemData.Index or itemData.ID)
				-- if config and config.GetWayInfo  then
				-- 	local pathInfo = config.GetWayInfo or ""
				-- 	if pathInfo and string.len(pathInfo) > 0 then
				-- 		FGUI:GTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, pathInfo) or pathInfo)
				-- 	else
				-- 		FGUI:setVisible(textContent, false)
				-- 	end
				-- else
				-- 	SL:Print("config or config.GetWayInfo is nil",itemData.Index or itemData.ID)
				-- 	FGUI:setVisible(textContent, false)
				-- end
				self._buttons = {self._ui.Btn1,self._ui.Btn2,self._ui.Btn3,self._ui.Btn4 }
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
                local desc = string.format("%s%s", conditionData.TransferName, string.format(SL:GetValue("I18N_STRING", 70000101), SL:GetValue("I18N_STRING", 5000 + conditionData.TransferLV)))
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
                if sex and sex >= 0 then
                    color = sex == mySex and "#FFFFFF" or "#FF0000"
                    sexTypeStr = SL:GetValue("I18N_STRING", 60003004 + sex)
                else
                    sexTypeStr = ""
                end
                sexStr = string.format("[color=%s]%s[/color]", color, showModuleName and string.format("%s%s", moduleCfg.Name, sexTypeStr) or sexTypeStr)
                FGUI:GTextField_setText(textContent,sexStr)
            end

			if module == 24 then                                    -- 装置
                local equipTypeName = itemData.StdName or ""
                FGUI:GTextField_setText(textContent, string.format("[color=%s]%s[/color]", "#FFFFFF", showModuleName and string.format("%s%s", moduleCfg.Name, equipTypeName) or equipTypeName))
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
                    FGUI:GTextField_setText(textContent, string.format("[color=%s]%s[/color]", "#A4E0F5", showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc))
                else
                    FGUI:setVisible(textContent, false)
                end
            end
			
		end
	end
	
	if self.itemFashionShow then
		FGUI:RemoveFromParent(self.itemFashionShow, true)
		self.itemFashionShow = nil
	end
	if fashion_jihuo[itemData.ID] then
		local fashionID,type,fashionName = fashion_jihuo[itemData.ID]['Anicount'],fashion_jihuo[itemData.ID]['type'],fashion_jihuo[itemData.ID]['equipname']
		self:addFashionShow(fashionID,type,fashionName)
	end
end

function CommonItemTipBase:addFashionShow(fashionID,type,fashionName)  -- 添加时装道具使用预览
	
	self.itemFashionShow =  FGUI:CreateObject(self._ui.CommonItem, "A_Right", "fashion_itemshow",false)
	FGUI:setSortingOrder(self.itemFashionShow, 99998)

	FGUI:setPositionX(self.itemFashionShow, -225)
	FGUI:setPositionY(self.itemFashionShow, -26)
	local modelobj = FGUI:GetChild(self.itemFashionShow,"graph_fashion_role")
    self._ItemFashionModel = self:UIModel_Bind(modelobj)
	-- FGUI:UIModel_setObjectEulerAngles(self._ItemFashionModel, nil, 0, 0, 0)

    local bodyId = nil
    local weaponId = nil
    local helmetId = nil
	local faceId = nil
    local Sex = SL:GetValue("SEX")
	if string.find(fashionName,"男") then
		Sex = 0
	elseif string.find(fashionName,"女") then
		Sex = 1
	end
    local Job = SL:GetValue("JOB")
    local modelData = SL:GetValue("FEATURE")
    if modelData then 
		local extData = {}
		extData.sex = Sex
		extData.job = Job
		extData.bodyId   = modelData.clothID == 0 and bodyId or modelData.clothID
		extData.helmetId = modelData.helmetID == 0 and helmetId or modelData.helmetID
        extData.weaponId = modelData.weaponID == 0 and weaponId or modelData.weaponID
		extData.faceId   = modelData.faceID == 0 and weaponId or modelData.faceID
        if type == 1 then           -- 披风界面
            extData.bodyId = fashionID
        elseif type == 2 then      -- 幻武界面
            extData.weaponId = fashionID
        elseif type == 3 then       -- 头饰界面
            extData.helmetId = fashionID
        end
        self._FashionModelIndex = FGUI:UIModel_addCharacterModel(self._ItemFashionModel, extData, Vector3.New(0, 0, -1), nil,Vector3.one * 1)
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
		if name == "气功等级" then
			showAttStr = string.format("%s[color=%s]%s+%s[/color]", showAttStr, SL:GetColorByStyleId(att.color or 255), name, value)
		else
			showAttStr = string.format("%s[color=%s]%s：%s[/color]", showAttStr, SL:GetColorByStyleId(att.color or 255), name, value)
		end
		addNewLine = 1
	end

	return showAttStr
end
local enterbag_cfg   =  require("game_config/cfgcsv/enterbag")
--自定义属性
function CommonItemTipBase:GetZDYData(itemID,itemConfig)
    -- for i=1,#itemConfig.abil do
    --    print(itemConfig.abil[i]['i'])
    --    print(itemConfig.abil[i]['v'])
    --    dump(itemConfig.abil[i]['v'])
    -- end
    --鉴定
    local suitStr = ""
    if itemConfig.abil[1] then
        local title = itemConfig.abil[1]['t']
        local qhtab = itemConfig.abil[1]['v']
        local pos = 0
        if title ~= "" then
            suitStr = suitStr..string.format("\n[color=#ff0000]%s[/color]", ""..title.."")
			suitStr = suitStr.."\n"
            -- dump(attrConfigs)
            -- dump(qhtab)
            for i=1,#qhtab do
            	local attId     = qhtab[i][2] or 0     -- 属性ID 绑定表
            	local value     = qhtab[i][3] or 0     -- 属性值
                local name = attrConfigs[attId]['Name']..""
				local color     = attrConfigs[attId]['Color'] or 0  -- 属性颜色
				local colorHex = color > 0 and SL:GetValue("COLOR_BY_ID", color)
				local percent   = attrConfigs[attId]['Type'] or 0   -- 是否是百分比
				if percent == 1 then
					value = string.format("%.1f", value / 100) * 10 / 10   .. "%"
				end
				if name == "气功等级" then
					suitStr = suitStr..string.format("[color="..colorHex.."]%s+%s[/color]", name, value)
				else
					suitStr = suitStr..string.format("[color="..colorHex.."]%s：%s[/color]", name, value)
				end
                
				suitStr = suitStr.."\n"
            end
        end
    end
    return suitStr
end
--自定义描述
function CommonItemTipBase:GetZDYDesc(itemData)
    --鉴定
	local Str = ""
	if ItemTipsDesc[itemData.ID]['Dec_FuHunItem'] then
		Str = ItemTipsDesc[itemData.ID]['Dec_FuHunItem']
	end
	local value = 0
    if itemData.ExAbil and itemData.ExAbil.abil and string.find(itemData.ExAbil.abil[1]['t'],"鉴定属性") then
		local attId     = itemData.ExAbil.abil[1]['v'][1][2] or 0     -- 属性ID 绑定表
		local percent   = attrConfigs[attId]['Type'] or 0   -- 是否是百分比
		value = itemData.ExAbil.abil[1]['v'][1][3]
		if percent == 1 then
			value = string.format("%.1f", value / 100) * 10 / 10
		end
        
    end
	Str = string.format("[color=#00ff00]"..Str.."[/color]", value)
	Str = Str
    return Str
end

return CommonItemTipBase