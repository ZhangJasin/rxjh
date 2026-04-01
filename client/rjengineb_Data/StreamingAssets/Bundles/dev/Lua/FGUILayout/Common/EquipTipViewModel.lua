EquipTipViewModel = class("EquipTipViewModel")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local CommonPurchaseItemPop = requireFGUILayout("Common/CommonPurchaseItemPop")

local EQUIP_POS_COUNT = 13
local TITLE_SCALE = 0.5
local MODEL_SCALE = SL:GetValue("IS_PC_OPER_MODE") and 0.8 or  1.2

local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

local attrConfigs = SL:GetValue("ATTR_CONFIGS")
local wuxun_jianding_attr      =  require("game_config/cfgcsv/wuxun_jianding_attr")        -- 武勋属性数据
local wuxun_skill_data         =  require("game_config/cfgcsv/wuxun_skill_data")           -- 武勋技能数据
local wuxun_level_data         =  require("game_config/cfgcsv/wuxun_level_data")           -- 武勋等级数据
local wuxun_zhujie_data        =  require("game_config/cfgcsv/wuxun_zhujie_data")          -- 武勋铸阶数据
local ObtainListData           =  require("game_config/cfgcsv/Obtain")          --获取来源

function EquipTipViewModel:ctor(index, itemInstanceData, extData)
    self._index = index
    self._maxContentWid = 0
    self._extData = extData
    self:SetItem(itemInstanceData)

	self.onChangeAutoSwitchHandler = handler(self, self.OnChangeAutoSwitchEvent)
end

function EquipTipViewModel:SetItem(itemInstanceData)
    self._itemId =  0
    if itemInstanceData.Index then
        self._itemId = itemInstanceData.Index
    elseif itemInstanceData.ID then
        self._itemId = itemInstanceData.ID
    end
    self.itemConfig= SL:GetValue("ITEM_DATA", self._itemId)
    self._itemData = itemInstanceData
    -- dump(self._itemData)
    self._lookPlayer = false    -- todo
end

function EquipTipViewModel:InitAutoSwitchPanel(isShow)
    self._autoSwitchPanel = self._ui.panel_auto_switch
    if not self._autoSwitchPanel then
        return
    end
    if SL:GetValue("IS_PC_OPER_MODE") then
		isShow = false
	end
	FGUI:setVisible(self._autoSwitchPanel, isShow)
	if isShow and self._itemId then
		local autoCheckBox = FGUI:GetChild(self._autoSwitchPanel, "checkBox_auto")
		FGUI:GButton_setSelected(autoCheckBox, FGUIFunction:GetQuickUseItemShow(self._itemId))
		FGUI:setOnClickEvent(autoCheckBox, self.onChangeAutoSwitchHandler)
	end
end

function EquipTipViewModel:OnChangeAutoSwitchEvent()
	local isSelected = FGUI:GButton_getSelected(self._ui.checkBox_auto)
	SL:SetQuickUseItemShow(self._itemId, isSelected)
end

function EquipTipViewModel:InitItemPurchasePanel(buyParam)
	local isShow = false
	if buyParam and next(buyParam) then
		buyParam.itemID = self._itemId
		isShow = true
	end
    if SL:GetValue("IS_PC_OPER_MODE") then
		isShow = false
	end
    self._purchasePanel = FGUIFunction:BindClass(self._ui.panel_purchase, "Common/CommonPurchaseItemPop")
	self._purchasePanel:Create()
	self._purchasePanel:Enter(buyParam)

	FGUI:setVisible(self._ui.panel_purchase, isShow)
end

function EquipTipViewModel:UpdateCellView(itemView, originListSize)
    self._ui = FGUI:ui_delegate(itemView)
    
    self._itemData.isShowCount = false
	ItemUtil:RefreshItemUIByData(self._ui.CommonEquip, self._itemData)
    ItemUtil:SetEquipArrowType(self._ui.CommonEquip, 3)
    
    self:InitAutoSwitchPanel(self._extData and self._extData.from == ItemFrom.BAG or false)
    self:UpdateGradeShow(FGUI:getController(itemView, "grade"))

    self._previewPanel = self._ui.PreviewModel
    FGUI:setVisible(self._previewPanel, false)

    self:InitItemPurchasePanel(self._extData and self._extData.buyParam)

    self._content = self._ui.Content
    self.textList = {}
    self.titleLabelList = {}
    self.textList[1] = FGUI:GetChild(self._content, "Tip")
    self.textList[2] = FGUI:GetChild(self._content, "BaseAttr")
    self.textList[3] = FGUI:GetChild(self._content, "CustomAttr")
    self.textList[4] = FGUI:GetChild(self._content, "Suitex")
    self.textList[11] = FGUI:GetChild(self._content, "Condition")
    self.textList[14] = FGUI:GetChild(self._content, "Obtain")    -- 获取
    self.textList[18] = FGUI:GetChild(self._content, "Quality")
    self.textList[23] = FGUI:GetChild(self._content, "InlaysAttr")
    self.textList[27] = FGUI:GetChild(self._content, "QigongLv")

    self.textList[101] = FGUI:GetChild(self._content, "CustomAttr")  -- 武勋改
    self.titleLabelList[2] = FGUI:GetChild(self._content, "BaseAttrTitle")
    self.titleLabelList[3] = FGUI:GetChild(self._content, "CustomAttrTitle")
    self.titleLabelList[4] = FGUI:GetChild(self._content, "SuitexTitle")
    self.titleLabelList[23] = FGUI:GetChild(self._content, "InlaysAttrTitle")
    
    -- Top
	self._topContent = self._ui.TopContent
    self.textList[15] = FGUI:GetChild(self._topContent, "Job")
    self.textList[16] = FGUI:GetChild(self._topContent, "Ms")
	self.textList[17] = FGUI:GetChild(self._topContent, "Level")
    self.textList[19] = FGUI:GetChild(self._topContent, "Zy")
    self.textList[22] = FGUI:GetChild(self._topContent, "Sex")
    self.textList[24] = FGUI:GetChild(self._topContent, "EquipType")

    -- 清除武勋添加组件
    self:ClearWuXunAttr(itemView)
    self:ClearWuXunSkill(itemView)
    -- FGUI:setVisible(self._ui.ObtainList,false)
    -- 还原初始大小
    if originListSize then
        -- dump("每次重置了")
        FGUI:setSize(self._content, originListSize[1], originListSize[2])
    end
    local equipped = FGUI:GetChild(itemView, "TextEquip")
    if equipped then
        FGUI:setVisible(equipped, self._index > 1)
    end
    local itemData = self.itemConfig
    local nameTxt =  FGUI:GetChild(itemView, "Name")
    local nameColor = self._itemData.Color and SL:GetColorByStyleId(self._itemData.Color) or "#FFFFFF"
    FGUI:GTextField_setText(nameTxt, self._itemData.Name)
    FGUI:GTextField_setColor(nameTxt, nameColor)

    local groupId = itemData.TipsGroupId or 7
    local groupCfg = SL:GetValue("ITEMTIPS_GROUP_CONFIG", groupId)
    if groupCfg.Preview and groupCfg.Preview == 1 then
        self:UpdatePreViewModel()
    end

    for k, v in pairs(self.textList) do
        FGUI:setVisible(v, false)
    end
    for k, v in pairs(self.titleLabelList) do
        FGUI:setVisible(v, false)
    end

    local maxContentWid = FGUI:getSize(self._content)
    -- FGUI:setWidth(itemView, originListSize[1])
    local showTexts = {}
    FGUI:setVisible(self._ui.ObtainList,false)
    for i, module in ipairs(groupCfg.Module) do
        local moduleCfg = SL:GetValue("ITEMTIPS_MODULE_CONFIG", module)
        local showModuleName = moduleCfg and moduleCfg.NameShow == 1
        local textContent = self.textList[module]
        local titleLabel = self.titleLabelList[module]
        local conditionData = {}
        if textContent then
            
            FGUI:setVisible(textContent, true)
            if module == 1 then										--描述
                local desc = itemData.Desc
                if desc and string.len(desc) > 0 then
                    FGUI:GTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if module == 2 then										--基础属性
                local desc = self:GetShowAttData(self._itemData)
                if desc and string.len(desc) > 0 then
                    FGUI:GTextField_setText(textContent, desc)
                    if showModuleName and titleLabel then
                        FGUI:setVisible(titleLabel, true)
                        FGUI:GTextField_setText(FGUI:GetChild(titleLabel, "title"), moduleCfg.Name)
                    end
                else
                    FGUI:setVisible(textContent, false)
                end
            end
  
            if module == 3 then                                     -- 自定义属性
                local desc = self:GetCustomAttrStr()
                if desc and string.len(desc) > 0 then
                    FGUI:GTextField_setText(textContent, desc)
                    if showModuleName and titleLabel then
                        FGUI:setVisible(titleLabel, true)
                        FGUI:GTextField_setText(FGUI:GetChild(titleLabel, "title"), moduleCfg.Name)
                    end
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if module == 4 then                                    -- 套装
                local desc = self:GetSuitData(itemData)
                if desc and string.len(desc) > 0 then
                    FGUI:GTextField_setText(textContent, string.format("[color=#FFFFFF]%s[/color]", desc))
                    if showModuleName and titleLabel then
                        FGUI:setVisible(titleLabel, true)
                        FGUI:GTextField_setText(FGUI:GetChild(titleLabel, "title"), moduleCfg.Name)
                    end
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if module == 11 then                                    -- 条件
                local conditionStr = self:GetConditionStr()
                if conditionStr and string.len(conditionStr) > 0 then
                    FGUI:GTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, conditionStr) or conditionStr)
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if module == 15 then									 --职业
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
                        jobStr = string.format("[color=%s]%s[/color]","#FFFFFF", showModuleName and string.format("%s%s", moduleCfg.Name, jobStr) or jobStr)
                    end
                end
                FGUI:GTextField_setText(textContent, jobStr)
            end

            if module == 16 then									 --名声
                if not conditionData.TransferName or not conditionData.TransferLV then
                    conditionData = self:GetTransferData(itemData)
                end
                conditionData.TransferName = conditionData.TransferName or "1"
                conditionData.TransferLV = conditionData.TransferLV or 0

                local color = ItemUtil:CheckTransferLV(itemData) and "#FFFFFF" or "#FF0000"
                local desc = string.format("%s%s", conditionData.TransferName, string.format(SL:GetValue("I18N_STRING", 70000101), SL:GetValue("I18N_STRING", 5000 + conditionData.TransferLV)))
                FGUI:GTextField_setText(textContent, string.format("[color=%s]%s[/color]", color, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc))
            end

            if module == 17 then									 --等级
                local canUse = ItemUtil:CheckNeedLevel(itemData)
                local color = canUse and "#FFFFFF" or "#FF0000"
                local desc = itemData.NeedLevel
                desc = string.format("[color=%s]%s[/color]", color, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
                if desc and string.len(desc) > 0 then
                    FGUI:GTextField_setText(textContent, desc)
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if module == 18 then									 --品级
                local desc = SL:GetValue("ITEM_GRADE_NAME", itemData.Grade or 0)
                desc = showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc
                local color = SL:GetValue("ITEM_GRADE_COLOR", itemData.Grade or 0)
                if desc and string.len(desc) > 0 then
                    FGUI:GTextField_setText(textContent, string.format("[color=%s]%s[/color]", color, desc))
                else
                    FGUI:setVisible(textContent, false)
                end
            end
            
            if module == 19 then									 --阵营
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

            if module == 22 then									 --性别
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

            if module == 23 then                                    -- 宝石镶嵌
                local desc = self:GetGemInlaysAttStr(itemData)
                if desc and string.len(desc) > 0 then
                    FGUI:GTextField_setText(textContent, desc)
                    if showModuleName and titleLabel then
                        FGUI:setVisible(titleLabel, true)
                        FGUI:GTextField_setText(FGUI:GetChild(titleLabel, "title"), moduleCfg.Name)
                    end
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if module == 24 then                                    -- 装置
                local equipTypeName = itemData.StdName or ""
                FGUI:GTextField_setText(textContent, string.format("[color=%s]%s[/color]", "#FFFFFF", showModuleName and string.format("%s%s", moduleCfg.Name, equipTypeName) or equipTypeName))
            end

            if module == 27 then                                    -- 气功等级
                local desc = self:GetQigongLvStr(itemData, showModuleName and moduleCfg.Name)
                if desc and string.len(desc) > 0 then
                    FGUI:GTextField_setText(textContent, desc)
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            ---- 101  武勋属性
            if module == 101 then                                     -- 武勋属性
                -- 武勋鉴定
                local attrstr = self:GetWuXunAttrStr(textContent,itemView,originListSize)
                FGUI:GRichTextField_setText(textContent, attrstr)
            end
             if module == 14 then                                     -- 获取
                local textTitle = FGUI:GetChild(textContent, "title")
                FGUI:GRichTextField_setAlign(textTitle, 2)
                FGUI:GRichTextField_setText(textContent, string.format("[color=%s]%s[/color]", "#FFFF00", "获取    "))
                FGUI:setOnClickEvent(textContent,function() 
                    self:getObtainList(itemView,tWid, tHei)
                end)
            end
            if titleLabel and FGUI:getVisible(titleLabel) and self:CheckNotInTopView(module) then
                -- 自行计算
                local labelWid = FGUI:getSize(FGUI:GetChild(titleLabel, "title")) + 2 * FGUI:getSize(FGUI:GetChild(titleLabel, "n1")) + 2 * 10
                maxContentWid = math.max(maxContentWid, labelWid)
            end

            if FGUI:getVisible(textContent) and self:CheckNotInTopView(module) then
                local tWid = FGUI:getSize(FGUI:GetChild(textContent, "title"))
                maxContentWid = math.max(maxContentWid, tWid)
                showTexts[#showTexts + 1] = textContent
            end
        end

    end
    self._maxContentWid = maxContentWid
    -- for i = 1, #showTexts do
    --     local tWid, tHei = FGUI:getSize(showTexts[i])
    --     FGUI:setSize(showTexts[i], self._maxContentWid, tHei)
    -- end
end

function EquipTipViewModel:getObtainList(itemView,tWid, tHei)
    if FGUI:getVisible(self._ui.ObtainList) then
		FGUI:setVisible(self._ui.ObtainList,false)
        return 
	else
		FGUI:setVisible(self._ui.ObtainList,true)
	end
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
        local text = FGUI:GetChild(item,"text")
        local data = obtainList[idx+1]
        FGUI:GTextField_setText(text,data.Desc)
        -- print(isOpen,isTradeOpen,isStorageExOpen,isTipOpen)
        FGUI:setOnClickEvent(item,function() 
            --关掉tip
            FGUI:Close("Common", "CommonEquipTip")
            -- FGUI:CloseTop(FGUI_LAYER.NORMAL)

            if data.Func=="Open" then
                FGUI:Open(data.PackageName,data.ComponentName)
            elseif data.Func == "RequestGroupData" then
                SL:RequestGroupData(0)
            end  
        end)
    end)
    FGUI:GList_setNumItems(list, #obtainList)
end
function EquipTipViewModel:UpdateGradeShow(gradeController)
    if not self.itemConfig or not self.itemConfig.Grade then
        return
    end

    if not gradeController then
        return
    end
    
    gradeController.selectedIndex = self.itemConfig.Grade
end

function EquipTipViewModel:UpdatePreViewModel()
    self._previewModelRoot = FGUI:GetChild(self._previewPanel, "model_root")
    FGUI:UIModel_clear(self._previewModelRoot)

    local featureData = SL:GetValue("FEATURE")
    local modelID = self._itemData and self._itemData.Model
    if not featureData or not modelID then
        return
    end

    local pos = SL:GetValue("EQUIP_POS_BY_STDMODE", self._itemData.StdMode)
    if not pos then
        return
    end

    local appearPos = SL:GetValue("APPEAR_POS_BY_EQUIP_POS", pos)
    if not appearPos or appearPos == -1 then
        return
    end
    
    local sex = SL:GetValue("SEX")
    local job = SL:GetValue("JOB")

    local cSex = self._itemData and self._itemData.Gender or 0
    -- 性别不同不显示预览
    if sex ~= cSex then
        return
    end

    local bodyId = nil
    local weaponId = nil
    local helmetId = nil
	local faceId = nil
    local classConfig = SL:GetValue("ROLE_CLASS_CONFIG", job)
    if classConfig then
        bodyId = classConfig.InitModel[1]
        helmetId = classConfig.InitModel[2]
        weaponId = classConfig.InitModel[3]
		faceId = FGUIFunction:GetFaceIDBySex(sex, classConfig)
    end

    local extData = {}
    extData.sex = sex
    extData.job = job
    extData.bodyId = featureData.clothID or bodyId
    extData.weaponId = featureData.weaponID or weaponId
    extData.faceId = featureData.faceID or faceId
    extData.wingId = featureData.wingID
    extData.helmetId = featureData.helmetID or helmetId
	
    extData.leftFxId = featureData.leftFxID
    extData.rightFxId = featureData.rightFxID
    extData.chestFxId = featureData.chestFxID
    extData.headFxId = featureData.headFxID
    extData.wingFxId = featureData.wingFxID

    if appearPos == 0 then  -- 衣服
        extData.bodyId = modelID
    elseif appearPos == 2 then  -- 武器
        extData.weaponId = modelID
    elseif appearPos == 3 then  -- 翅膀
        extData.wingId = modelID
    elseif appearPos == 4 then  -- 头饰
        extData.helmetId = modelID
    elseif appearPos == 5 then  -- 坐骑 
    end

    FGUI:setVisible(self._previewPanel, true)
    FGUI:UIModel_setObjectEulerAngles(self._previewModelRoot, nil, 0, 0, 0)

    if not self._modelIndex then
        self._modelIndex = FGUI:UIModel_addCharacterModel(self._previewModelRoot, extData, Vector3.New(0,0,0), nil, Vector3.New(MODEL_SCALE,MODEL_SCALE,MODEL_SCALE))
        FGUI:UIModel_setModelCallback(self._previewModelRoot, function(index)
            FGUI:UIModel_playAnimation(self._previewModelRoot, index, global.MMO.ANIM_IDLE, nil, 0)
        end)
    end

end

function EquipTipViewModel:CheckNotInTopView(module)
    if module == 15 or module == 16 or module == 17 or module == 19 or module == 22 or module == 24 then
        return false
    end
    return true
end

function EquipTipViewModel:GetContentMaxWidth()
    return self._maxContentWid
end

function EquipTipViewModel:GetShowAttStr(data, extraParam)

    if not data then
        return
    end
    local showAttStr = ""
    local attData = FGUIFunction:GetAttShowData(data, nil, extraParam)

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
function EquipTipViewModel:GetShowAttData(itemData)
    local pos = SL:GetValue("EQUIP_POS_BY_STDMODE", itemData.StdMode)
    if not pos then
        return nil
    end
    return self:GetShowAttStr(itemData)
end

local extraParam = {}
function EquipTipViewModel:GetShowAttStrByInlayParam(param)
    local attrStr = nil
    if not param then
        return attrStr
    end

    local itemId = param.id
    extraParam.multiple = param.c
    extraParam.extraAdd = param.v
    if itemId and itemId > 0 then
        local itemCfg = SL:GetValue("ITEM_DATA", itemId)
        -- + 镶嵌宝石的气功等级
        local qigongStr = self:GetQigongLvStr(itemCfg)
        if itemCfg and itemCfg.ItemType == SL:GetValue("ITEMTYPE_ENUM").Equip then
            attrStr = self:GetShowAttStr(itemCfg.Attribute, extraParam)
        end
        if qigongStr and string.len(qigongStr) > 0 then
            attrStr = string.format("%s%s%s", qigongStr, attrStr and string.len(attrStr) > 0 and "\n" or "", attrStr or "")
        end
    end

    return attrStr
end

function EquipTipViewModel:GetGemInlaysAttStr(itemData)
    local str = ""
    local stoneNum = itemData.SyntheticStone
    local attrList = {}
    if self._itemData then
        attrList = self._itemData.Inlays or {}
    end
    local extraParam = {}
    if not stoneNum then    -- 未配置仅显示镶嵌属性
        local att
        for i, param in ipairs(attrList) do
            local attrStr = self:GetShowAttStrByInlayParam(param)
            if attrStr and string.len(attrStr) > 0 then
                str = string.format("%s%s%s", i ~= 1 and "\n" or "", str, attrStr)
            end
        end
    else
        local itemConfig = self._itemData.ExAbil
        local yhcnum = 0
        if itemConfig and itemConfig.abil[3] then
            local title = itemConfig.abil[3]['t']
            local attList = itemConfig.abil[3]['v']
            yhcnum = #attList
            local pos = 0
            local suitStr = ""
            if title ~= "" then
                title = ""
                -- if suitStr ~= "" then
                --     suitStr = suitStr.."\n"
                -- end
                -- suitStr = suitStr..string.format("[color=#FDF2DC]%s[/color]", ""..title.."")
                local group = itemConfig.abil[3].i or 0
                local attList = {}
                for _, v in ipairs(itemConfig.abil[3].v or {}) do
                    local color     = v[1] or 0
                    local attId     = v[2] or 0     -- 属性ID 绑定表
                    local value     = v[3] or 0     -- 属性值
                    local percent   = v[4] or 0
                    local customId  = v[5]
                    local pos       = v[6]          -- 自定义显示位置
                    if value and value > 0 then    
                        attList[pos] = attList[pos] or {}
                        table.insert(
                            attList[pos],
                            {color = color, attId = attId, value = value, percent = percent, pos = pos, customId = customId}
                        )
                    end
                end
                attList = SL:HashToSortArray(attList, function(a, b)
                    return a[1].pos < b[1].pos
                end)
                for k, v in ipairs(attList or {}) do
                    local customId = v[1] and v[1].customId or 0
                    local customDesc = SL:GetMetaValue("ITEMTIPS_CUSTOM_DESC", customId)
                    local color = 0
                    local attr = ""
                    for i, a in ipairs(v) do
                        local attConfig = SL:GetMetaValue("ATTR_CONFIG", a.attId)
                        if not attConfig then
                            attConfig = {}
                        end
                        local value = a.value
                        local color = a.color
                        local percent = a.percent
                        local colorHex = color > 0 and SL:GetValue("COLOR_BY_ID", color)
                        if attConfig.Type == 1 then -- 万分比除100
                            value = tonumber(string.format("%.0f", value / 100))
                            percent = 1
                        end
                        if customDesc then
                            local desc = value .. (percent > 0 and "%%" or "")
                            customDesc = string.gsub(customDesc, "%%s", desc, 1)
                            if colorHex then
                                if string.find(customDesc, "%[color=(.-)%]") then
                                    customDesc = string.gsub(customDesc, "%[color=(.-)%]", string.format("[color=%s]", colorHex))
                                else
                                    customDesc = string.format("[color=%s]%s[/color]", colorHex, customDesc)
                                end
                            end
                        else
                            local name = attConfig.Name
                            local attColor = attConfig.Color and SL:GetValue("COLOR_BY_ID", attConfig.Color)
                            local showColor = colorHex or attColor or "#FFFFFF"
                            local lineStr = string.len(attr) > 0 and "\n" or ""
                            attr = string.format("%s%s[color=%s]%s：+%s%s[/color]", attr, lineStr, showColor, name, value, percent > 0 and "%" or "")
                        end
                    end
                    attr = customDesc or attr
                    if attr and attr ~= "" then
                        suitStr = string.format("%s%s%s", suitStr, suitStr ~= "" and "\n" or "", attr)
                    end
                end
                str = suitStr..str
            end
        end
        for i = yhcnum+1, stoneNum do
            local attrStr = "[color=#666666][合成石]：可合成[/color]"
            local param = attrList[i] or {}
            attrStr = self:GetShowAttStrByInlayParam(param) or attrStr
            str = string.format("%s%s%s", str, i ~= 1 and "\n" or "", attrStr)
        end
    end

    return str
end

function EquipTipViewModel:GetTransferData(itemConfig)

    local conditionData = {}
    if itemConfig then
        local  config = SL:GetMetaValue("TRANSFER_CONFIG_BY_ID", itemConfig.TransferID)
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

---------------------------------------------------------------------------
-- 套装
function EquipTipViewModel:GetSuitData(itemConfig)
    local suitids = itemConfig and itemConfig.suitid
    if suitids and string.len(suitids) > 0 then
        local suitArry = string.split(suitids, "#")
        local suitStr = self:GetSuitDesc(suitArry) or ""
        return suitStr
    end
end

-- 获取职业匹配的属性描述
local function getJobDesc(desc, job)
    if not desc or desc == "" then
        return
    end
    local str = ""
    local descs = string.split(desc or "", "&")
    for i, v in ipairs(descs) do
        local strs = string.split(v, "#")
        if strs[2] then
            local jobId = tonumber(strs[1])
            if jobId == 3 or (job and jobId == job) then
                str = str .. (strs[2] or "")
            end
        else
            str = str .. (strs[1] or "")
        end
    end
    return str
end

-- 解析颜色规则  未获得颜色/获得颜色   无则使用第一个未获得颜色
local function getShowColorAndStr(txtStr, colorIdx)
    txtStr = string.gsub(txtStr or "", "<br>", "\n")
    local colorStr = ""
    local showStr = ""
    local txtArray = string.split(txtStr or "", "|")
    if #txtArray > 1 then
        colorStr = txtArray[1] or ""
        for i = 2, #txtArray do
            showStr = showStr .. (txtArray[i] or "")
        end
    else
        showStr = txtStr
    end
    colorIdx = colorIdx or 1
    local colorArry = string.split(colorStr or "", "/")
    if #colorArry <= 1 then
        table.insert(colorArry, 1, 249)
    end
    return tonumber(colorArry[colorIdx]) or tonumber(colorArry[1]), showStr
end

-- 检测部位是否存在相应的装备
local function checkEquipMeet(suitConfig, pos, isLookPlayer)
    local meet = false
    local equip = nil
    local equipName = nil
    local equipStdMode = nil
    local isHighLevel = false
    if not isLookPlayer then
        equip = SL:GetValue("EQUIP_DATA_BY_POS", pos)
    else
        equip = SL:GetValue("L.M.EQUIP_DATA", pos)
    end
    local equipSuit = nil
    if equip and equip.suitid and string.len(equip.suitid) > 0 then
        equipSuit = equip.suitid
    end
    if equipSuit then
        local equipSuitArray = string.split(equipSuit, "#")
        for i, v in ipairs(equipSuitArray) do
            if v and string.len(v) > 0 then
                local posSuitConfig = SL:GetValue("SUITEX_CONFIG", tonumber(v))
                if posSuitConfig and posSuitConfig.suittype == suitConfig.suittype and
                    posSuitConfig.level >= suitConfig.level then
                    meet = true
                    equipName = equip.originName or equip.Name
                    isHighLevel = posSuitConfig.level > suitConfig.level
                    equipStdMode = equip.StdMode
                    break
                end
            end
        end
    end
    return meet, equipName, isHighLevel, equipStdMode
end

function EquipTipViewModel:GetSuitDescStr(id, needEquipShow, lowMeetEquipNameMap)
    local suitConfig = SL:GetValue("SUITEX_CONFIG", tonumber(id))
    if not suitConfig or not next(suitConfig) then
        return
    end

    local posCheckSwitch = tonumber(SL:GetValue("GAME_DATA", "suitCheckPos")) == 1 --做个开关， 是由装备位还是装备名作为检测key（默认是装备名）
    local suitDescStr = ""
    local showEquipStr = ""
    
    local suitCount = suitConfig.num
    local suitType = suitConfig.suittype
    local isDistinct = suitConfig.Distinct == 1 -- 去重
    local meetCount = 0
    local lowMeetDesStr = nil
    local lowMeetEquipShow = {}
    if suitConfig.desc and suitConfig.desc ~= "" then  -- 套装无描述不显示
        local showArray = string.split(suitConfig.equipshow or "", "|")
        local showColorStr = ""
        local equipShowStr = showArray[1] or ""
        if #showArray > 1 then
            showColorStr = showArray[1] or ""
            if showColorStr and showColorStr ~= "" then
                showColorStr = showColorStr .. "|"
            end
            equipShowStr = showArray[2] or ""
        end
        local equipShowList = string.split(equipShowStr or "", "#")
        local equipPosList = string.split(suitConfig.equipid or "", "#")
        local meetEquipShow = {}
        local tempMeetEquipShowCount = {}
        local highMeetEquipNameMap = {}
        local meetPosMap = {}

        for i, pos in ipairs(equipPosList) do
            pos = tonumber(pos)
            if pos then
                local meet, equipName, isHighLevel, equipStdMode = checkEquipMeet(suitConfig, pos, self._lookPlayer)
                if meet then
                    local stdPosList = equipStdMode and SL:GetValue("EQUIP_POSLIST_BY_STDMODE", equipStdMode) or {}
                    local needAdd = true
                    if isDistinct and #stdPosList > 1 then
                        for index = 1, #stdPosList do
                            if stdPosList[index] and meetPosMap[stdPosList[index]] then   -- 已有去重, 不计数
                                needAdd = false
                                break
                            end
                        end
                    end
                    if needAdd then
                        meetCount = meetCount + 1
                    end
                    if isHighLevel then
                        highMeetEquipNameMap[pos] = equipName
                    end
                end
                if not suitConfig.num then
                    suitCount = suitCount + 1
                end

                if equipName then
                    local meetKey = posCheckSwitch and i or equipName -- 是用下标做key或者道具名
                    meetEquipShow[meetKey] = meet
                    if meet then
                        tempMeetEquipShowCount[meetKey] = (tempMeetEquipShowCount[meetKey] or 0) + 1
                        meetPosMap[pos] = true
                    end
                end
            end
        end

        -- 不满足当前套装 查找低级套装
        if meetCount < suitCount and suitType then
            local suitConfigs = SL:GetValue("SUITEX_CONFIGS_BY_TYPE", suitType)
            table.sort(suitConfigs, function(a, b)
                return a.level > b.level
            end)
            for i, v in ipairs(suitConfigs) do
                if v.num == suitCount then
                    local tEquipPosList = string.split(v.equipid or "", "#")
                    local tMeetCount = 0
                    local tSuitCount = v.num
                    lowMeetEquipShow = {}
                    local tDistinct = v.Distinct

                    for i, pos in ipairs(tEquipPosList) do
                        pos = tonumber(pos)
                        if pos then
                            local meet, equipName, isHighLevel, equipStdMode = checkEquipMeet(v, pos, self._lookPlayer)
                            if meet then
                                local equipPosList = equipStdMode and SL:GetValue("EQUIP_POSLIST_BY_STDMODE", equipStdMode) or {}
                                local needAdd = true
                                if tDistinct == 1 and #equipPosList > 1 then
                                    for index = 1, #equipPosList do
                                        if equipPosList[index] and lowMeetEquipShow[equipPosList[index]] then   -- 已有去重, 不计数
                                            needAdd = false
                                            break
                                        end
                                    end
                                end
                                if needAdd then
                                    tMeetCount = tMeetCount + 1
                                end
                            end
                            if not v.num then
                                tSuitCount = tSuitCount + 1
                            end
                            
                            if equipName then
                                lowMeetEquipShow[pos] = equipName
                            end
                        end
                    end

                    if tMeetCount >= tSuitCount then
                        lowMeetDesStr = v.desc
                        meetCount = tSuitCount
                        break
                    end
                end
            end
        end

        if needEquipShow then
            local showEquipStrList = {}
            local lastEquipPos = nil
            local lastEquipShowStr = nil
            for i, showStr in ipairs(equipShowList) do
                if showStr and showStr ~= "" then
                    local equipShowStr = showStr
                    local meetKey = posCheckSwitch and i or showStr -- 是用下标做key或者道具名
                    local meet = meetEquipShow[meetKey]
                    local pos = tonumber(equipPosList[i])

                    local posList = {}
                    table.insert(posList, pos)
                    if lastEquipShowStr == equipShowStr and lastEquipPos then
                        if meet and tempMeetEquipShowCount[meetKey] then
                            tempMeetEquipShowCount[meetKey] = tempMeetEquipShowCount[meetKey] + 1
                        end
                        table.remove(showEquipStrList)
                        table.insert(posList, lastEquipPos)
                    end

                    if tempMeetEquipShowCount[meetKey] then
                        if meet and tempMeetEquipShowCount[meetKey] <= 0 then
                            meet = false
                        end
                        tempMeetEquipShowCount[meetKey] = tempMeetEquipShowCount[meetKey] - 1
                    end

                    if next(posList) and not meet then
                        for i = 1, #posList do
                            local checkPos = tonumber(posList[i])
                            if highMeetEquipNameMap and highMeetEquipNameMap[checkPos] then
                                showStr = highMeetEquipNameMap[checkPos]
                                meet = true
                                break
                            elseif lowMeetDesStr and lowMeetEquipShow[checkPos] then
                                showStr = lowMeetEquipShow[checkPos]
                                meet = true
                                break
                            elseif lowMeetEquipNameMap and lowMeetEquipNameMap[checkPos] then
                                showStr = lowMeetEquipNameMap[checkPos]
                                meet = true
                                break
                            end
                        end
                    end

                    showStr = showColorStr .. showStr
                    local color, nameStr = getShowColorAndStr(showStr, meet and 2 or 1)
                    local colorHex = SL:GetValue("COLOR_BY_ID", color)
                    local showStrFormat = ""
                    if #showEquipStrList % 3  == 0 then
                        showStrFormat = string.format("[color=%s]%s[/color]\n", colorHex, nameStr)
                    else
                        showStrFormat = string.format("[color=%s]%s[/color]   ", colorHex, nameStr)
                    end
                    table.insert(showEquipStrList, showStrFormat)
                    lastEquipPos = pos
                    lastEquipShowStr = equipShowStr
                end
            end

            if next(showEquipStrList) then
                showEquipStr = table.concat(showEquipStrList)
            end
        end


        local job = self._lookPlayer and SL:GetValue("L.M.JOB") or SL:GetValue("JOB")
        local descStr = getJobDesc(lowMeetDesStr or suitConfig.desc, job)
        if descStr and string.len(descStr) > 0 then
            local color, showDescStr = getShowColorAndStr(descStr, meetCount >= suitCount and 2 or 1)
            local colorHex = SL:GetValue("COLOR_BY_ID", color)
            local showDescStrFormat = string.format("[color=%s]%s[/color]", colorHex, showDescStr)
            suitDescStr = string.format("%s%s", suitDescStr, showDescStrFormat)
        end
    end

    return string.len(suitDescStr) > 0 and suitDescStr, meetCount, string.len(showEquipStr) > 0 and showEquipStr, lowMeetDesStr and lowMeetEquipShow or nil
end

function EquipTipViewModel:GetSuitDesc(suitArray)
    local suitTypeList = {}
    for i = 1, #suitArray do
        local suitId = tonumber(suitArray[i])
        if suitId then
            local suitConfig = SL:GetValue("SUITEX_CONFIG", suitId)
            if suitConfig and next(suitConfig) then
                local suitType = suitConfig.suittype
                local curLevel = suitConfig.level
                local configs = SL:GetValue("SUITEX_CONFIGS_BY_TYPE", suitType) or {}
                for k, config in ipairs(configs) do
                    if config.level and curLevel and config.level <= curLevel then
                        if not suitTypeList[suitType] then
                            suitTypeList[suitType] = {}
                        end
                        table.insert(suitTypeList[suitType], config)
                    end
                end
            end
        end
    end
    local typeKeys = table.keys(suitTypeList)
    table.sort(typeKeys)
    local showDescStr = ""
    for i = 1, #typeKeys do
        local type = typeKeys[i]
        local typeList = suitTypeList[type]
        table.sort(typeList, function(a, b)
            return a.level < b.level
        end)
        local maxMeetCount = 0
        local equipShowStr = nil
        local lowMeetEquipMap = {}
        local suitStr = ""
        for i, config in ipairs(typeList) do
            local suitDescStr, meetCount, showEquipStr, lowMeetEquipShow = self:GetSuitDescStr(config.suitid, i == #typeList, lowMeetEquipMap)
            if suitDescStr then
                maxMeetCount = math.max(meetCount, maxMeetCount)
                suitStr = string.format("%s%s%s", suitStr, suitStr ~= "" and "\n" or "", suitDescStr)
            end
            if showEquipStr then
                equipShowStr = showEquipStr
            end
            if lowMeetEquipShow and next(lowMeetEquipShow) then
                for pos, equipName in pairs(lowMeetEquipShow) do
                    lowMeetEquipMap[pos] = equipName
                end
            end
        end
        local mostSuitConfig = typeList[#typeList]
        local titleStr = mostSuitConfig.name or ""
        local suitCount = mostSuitConfig.num
        if titleStr and string.len(titleStr) > 0 then
            local color, showTitle = getShowColorAndStr(titleStr, maxMeetCount >= suitCount and 2 or 1)
            local colorHex = SL:GetValue("COLOR_BY_ID", color)
            local mCount = maxMeetCount > suitCount and suitCount or maxMeetCount
            local showTitleFormat =
                string.format(
                "[color=%s]%s (%s/%s)[/color]\n",
                colorHex,
                showTitle,
                mCount,
                suitCount
            )
            suitStr = string.format("%s%s%s", showTitleFormat, equipShowStr and (equipShowStr .. "\n") or "", suitStr)
        end
        showDescStr = string.format("%s%s%s", showDescStr, showDescStr ~= "" and "\n\n" or "", suitStr)
    end

    return string.len(showDescStr) > 0 and showDescStr
end

---------------------------------------------------------------------------
-- 自定义属性
function EquipTipViewModel:GetCustomAttrStr()
    local exAbil = self._itemData and self._itemData.ExAbil
    if not exAbil or exAbil == "" or not next(exAbil) then
        return ""
    end

    local customStr = ""
    for p, d in pairs(exAbil.abil or {}) do
        if d.t and not string.find(d.t,"合成石") then  -- 合成石特殊处理  不在这里显示
            local isShowTitle = true
            if (not d.t or d.t == "") then
                isShowTitle = false
            end

            if isShowTitle then
                local title = d.t
                local color = d.c
                local colorHex = color and color > 0 and SL:GetValue("COLOR_BY_ID", color)
                customStr = string.format("%s%s%s", customStr, customStr ~= "" and "\n" or "", colorHex and string.format("[color=%s]%s[/color]", colorHex, title) or title)
            end
        
            local group = d.i or 0
            local attList = {}
            for _, v in ipairs(d.v or {}) do
                local color     = v[1] or 0
                local attId     = v[2] or 0     -- 属性ID 绑定表
                local value     = v[3] or 0     -- 属性值
                local percent   = v[4] or 0
                local customId  = v[5]
                local pos       = v[6]          -- 自定义显示位置
                if value and value > 0 then    
                    attList[pos] = attList[pos] or {}
                    table.insert(
                        attList[pos],
                        {color = color, attId = attId, value = value, percent = percent, pos = pos, customId = customId}
                    )
                end
            end
            attList = SL:HashToSortArray(attList, function(a, b)
                return a[1].pos < b[1].pos
            end)
        
            for k, v in ipairs(attList or {}) do
                local customId = v[1] and v[1].customId or 0
                local customDesc = SL:GetMetaValue("ITEMTIPS_CUSTOM_DESC", customId)
                local color = 0
                local attr = ""
                for i, a in ipairs(v) do
                    local attConfig = SL:GetMetaValue("ATTR_CONFIG", a.attId)
                    if not attConfig then
                        attConfig = {}
                    end
                    local value = a.value
                    local color = a.color
                    local percent = a.percent
                    local colorHex = color > 0 and SL:GetValue("COLOR_BY_ID", color)
                    if attConfig.Type == 1 then -- 万分比除100
                        value = tonumber(string.format("%.0f", value / 100))
                        percent = 1
                    end
                    if customDesc then
                        local desc = value .. (percent > 0 and "%%" or "")
                        customDesc = string.gsub(customDesc, "%%s", desc, 1)
                        if colorHex then
                            if string.find(customDesc, "%[color=(.-)%]") then
                                customDesc = string.gsub(customDesc, "%[color=(.-)%]", string.format("[color=%s]", colorHex))
                            else
                                customDesc = string.format("[color=%s]%s[/color]", colorHex, customDesc)
                            end
                        end
                    else
                        local name = attConfig.Name
                        local attColor = attConfig.Color and SL:GetValue("COLOR_BY_ID", attConfig.Color)
                        local showColor = colorHex or attColor or "#FFFFFF"
                        local lineStr = string.len(attr) > 0 and "\n" or ""
                        attr = string.format("%s%s[color=%s]%s：+%s%s[/color]", attr, lineStr, showColor, name, value, percent > 0 and "%" or "")
                    end
                end

                attr = customDesc or attr
                if attr and attr ~= "" then
                    customStr = string.format("%s%s%s", customStr, customStr ~= "" and "\n" or "", attr)
                end
            end
        end
    end

    return customStr
end

-- 清除武勋范围按钮对象
function EquipTipViewModel:ClearWuXunAttr(itemView)
    if not WuXunOBJ_cfg[itemView] then
        WuXunOBJ_cfg[itemView] = {}
    end
    -- dump(itemView)
    -- 武勋属性范围界面
    if WuXunOBJ_cfg[itemView] and WuXunOBJ_cfg[itemView][1] then
        FGUI:RemoveFromParent(WuXunOBJ_cfg[itemView][1], true)
        WuXunOBJ_cfg[itemView][1] = nil
    end
    if WuXunOBJ_cfg[itemView] and WuXunOBJ_cfg[itemView][2] then
        FGUI:RemoveFromParent(WuXunOBJ_cfg[itemView][2], true)
        WuXunOBJ_cfg[itemView][2] = nil
    end
end

-- 清除武勋技能按钮对象
function EquipTipViewModel:ClearWuXunSkill(itemView)
    if not WuXunOBJ_cfg[itemView] then
        WuXunOBJ_cfg[itemView] = {}
    end
    if WuXunOBJ_cfg[itemView] and WuXunOBJ_cfg[itemView][3] then
        for i=1,#WuXunOBJ_cfg[itemView][3] do
            FGUI:RemoveFromParent(WuXunOBJ_cfg[itemView][3][i], true)
        end
        WuXunOBJ_cfg[itemView][3] = nil
    end
    WuXunOBJ_cfg[itemView][3] = {}
end

-- 武勋属性
function EquipTipViewModel:GetWuXunAttrStr(textContent,itemView,originListSize)
    self:ClearWuXunAttr(itemView)
    -- 武勋属性范围面板
    -- if self.btnWuXunAttrPanl then
	--     FGUI:RemoveFromParent(self.btnWuXunAttrPanl, true)
	-- end
    self.btnWuXunAttrPanl =  FGUI:CreateObject(itemView, "A_Right", "wuxun_tips_attr",false)
	FGUI:setPositionX(self.btnWuXunAttrPanl,150)
	FGUI:setPositionY(self.btnWuXunAttrPanl, 0)
    FGUI:setVisible(self.btnWuXunAttrPanl, false)

    -- 武勋属性范围按钮
    -- if self.btnWuXunAttr then
	--     FGUI:RemoveFromParent(self.btnWuXunAttr, true)
	-- end
    self.btnWuXunAttr =  FGUI:CreateObject(textContent, "A_Right", "btn_wxattr",false)
	FGUI:setPositionX(self.btnWuXunAttr,270)
	FGUI:setPositionY(self.btnWuXunAttr, 0)
    FGUI:setOnClickEvent(self.btnWuXunAttr, function ()
        if FGUI:getVisible(self.btnWuXunAttrPanl) then
            FGUI:setVisible(self.btnWuXunAttrPanl, false)
        else
            FGUI:setVisible(self.btnWuXunAttrPanl, true)
        end
    end)
    WuXunOBJ_cfg[itemView][1] = self.btnWuXunAttrPanl
    WuXunOBJ_cfg[itemView][2] = self.btnWuXunAttr
    -- 武勋属性范围列表
    self.wxpanlattrList = FGUI:GetChild(self.btnWuXunAttrPanl, "attrlist")
    FGUI:GList_itemRenderer(self.wxpanlattrList, handler(self, self.Listwxpanlattr))
    FGUI:GList_setDefaultItem(self.wxpanlattrList, "ui://h3jungk0rg4i1j")
    FGUI:GList_setVirtual(self.wxpanlattrList)
    FGUI:GList_setNumItems(self.wxpanlattrList,  #wuxun_jianding_attr[self._itemData.ID])

    -- 武勋属性
    local attrAtr = ""
    -- 武勋鉴定属性
    local wxjdAttr = self:WuXunJianDingAttr()
    -- 武勋转印属性
    local wxzyAttr = self:WuXunZhuanYinAttr()
    -- 武勋技能
    local wxskillAttr = self:WuXunSkillData(textContent,itemView,originListSize)
    if wxjdAttr ~= "" then
        attrAtr = attrAtr..wxjdAttr.."\n"
    end
    if wxzyAttr ~= "" then
        attrAtr = attrAtr..wxzyAttr.."\n"
    end
    if wxskillAttr ~= "" then
        attrAtr = attrAtr..wxskillAttr.."\n"
    end
    return attrAtr
end
-- 武勋属性范围列表
function EquipTipViewModel:Listwxpanlattr(idx,item)      
    local minValue = wuxun_jianding_attr[self._itemData.ID][idx+1]['AttScoreStageList'][1][1]
    local maxValue = wuxun_jianding_attr[self._itemData.ID][idx+1]['AttScoreStageList'][#wuxun_jianding_attr[self._itemData.ID][idx+1]['AttScoreStageList']][2]
    local attrid = wuxun_jianding_attr[self._itemData.ID][idx+1]['attrid']
    local name = attrConfigs[attrid]['Name']..""
    local type = attrConfigs[attrid]['Type'] or 0 -- 0 数值 1 万分比
    if type == 1 then
        minValue = string.format("%.0f", minValue / 100) .. "%"
        maxValue = string.format("%.0f", maxValue / 100) .. "%"
    end
    local value = minValue .. " - " .. maxValue
    local n0 = FGUI:GetChild(item,"n0")
    local n4 = FGUI:GetChild(item,"n4")
    FGUI:GTextField_setText(n0, name)
    FGUI:GTextField_setText(n4, value)
end
-- 武勋鉴定属性
function EquipTipViewModel:WuXunJianDingAttr()
    local exAbil = self._itemData and self._itemData.ExAbil
    -- 武勋鉴定
    local itemConfig = self._itemData.ExAbil
    local str = string.format("[color=#FDF2DC]%s[/color]", "[武勋附加属性]").."\n"
    
    if itemConfig and itemConfig.abil[1] then
        local attList = itemConfig.abil[1]['v']
        local pos = 0
        local suitStr = ""
        local group = itemConfig.abil[1].i or 0
        local attList = {}
        for _, v in ipairs(itemConfig.abil[1].v or {}) do
            local color     = v[1] or 0
            local attId     = v[2] or 0     -- 属性ID 绑定表
            local value     = v[3] or 0     -- 属性值
            local percent   = v[4] or 0
            local customId  = v[5]
            local pos       = v[6]          -- 自定义显示位置
            if value and value > 0 then    
                attList[pos] = attList[pos] or {}
                table.insert(
                    attList[pos],
                    {color = color, attId = attId, value = value, percent = percent, pos = pos, customId = customId}
                )
            end
        end
        attList = SL:HashToSortArray(attList, function(a, b)
            return a[1].pos < b[1].pos
        end)
        for k, v in ipairs(attList or {}) do
            local customId = v[1] and v[1].customId or 0
            local customDesc = SL:GetMetaValue("ITEMTIPS_CUSTOM_DESC", customId)
            local color = 0
            local attr = ""
            for i, a in ipairs(v) do
                local attConfig = SL:GetMetaValue("ATTR_CONFIG", a.attId)
                if not attConfig then
                    attConfig = {}
                end
                local value = a.value
                local color = a.color
                local percent = a.percent
                local colorHex = color > 0 and SL:GetValue("COLOR_BY_ID", color)
                if attConfig.Type == 1 then -- 万分比除100
                    value = tonumber(string.format("%.0f", value / 100))
                    percent = 1
                end
                if customDesc then
                    local desc = value .. (percent > 0 and "%%" or "")
                    customDesc = string.gsub(customDesc, "%%s", desc, 1)
                    if colorHex then
                        if string.find(customDesc, "%[color=(.-)%]") then
                            customDesc = string.gsub(customDesc, "%[color=(.-)%]", string.format("[color=%s]", colorHex))
                        else
                            customDesc = string.format("[color=%s]%s[/color]", colorHex, customDesc)
                        end
                    end
                else
                    local name = attConfig.Name
                    local attColor = attConfig.Color and SL:GetValue("COLOR_BY_ID", attConfig.Color)
                    local showColor = colorHex or attColor or "#FFFFFF"
                    local lineStr = string.len(attr) > 0 and "\n" or ""
                    attr = string.format("%s%s[color=%s]%s：+%s%s[/color]", attr, lineStr, showColor, name, value, percent > 0 and "%" or "")
                end
            end
            attr = customDesc or attr
            if attr and attr ~= "" then
                suitStr = string.format("%s%s%s", suitStr, suitStr ~= "" and "\n" or "", attr)
            end
        end
        str = str..suitStr
    else
        str = str .. "[color=#ff0000]未鉴定[/color]"
    end

    return str
end

-- 武勋转印属性
function EquipTipViewModel:WuXunZhuanYinAttr()
    local exAbil = self._itemData and self._itemData.ExAbil
    -- 武勋铸阶等级 武勋转印等级
    self.zjLv = 0
    if self._itemData.Values then
        for j = 1, #self._itemData.Values do
            if self._itemData.Values[j]['Id'] == 2 then  
                self.zjLv = self._itemData.Values[j]['Value']
            end 
        end
    end
    -- 当前铸阶等级可转印条数
    self.limitZyNum = wuxun_zhujie_data[self._itemData.ID][self.zjLv] and (wuxun_zhujie_data[self._itemData.ID][self.zjLv]['zhuanyin'] or 0) or 0  
    -- print("武勋铸阶等级", self.zjLv, "可转印条数", self.limitZyNum," 物品id",self._itemData.ID)
    -- 武勋转印
    local itemConfig = self._itemData.ExAbil
    local str = ""
    local attStrList = {}
    if itemConfig and itemConfig.abil[2] then
        local attList = itemConfig.abil[2]['v']
        local pos = 0
        local suitStr = ""
        local group = itemConfig.abil[2].i or 0
        -- dump(attList,"attList1")
        local attList = {}
        for _, v in ipairs(itemConfig.abil[2].v or {}) do
            local color     = v[1] or 0
            local attId     = v[2] or 0     -- 属性ID 绑定表
            local value     = v[3] or 0     -- 属性值
            local percent   = v[4] or 0
            local customId  = v[5]
            local pos       = v[7]          -- 自定义显示位置
            if value and value > 0 then    
                attList[pos] = attList[pos] or {}
                table.insert(
                    attList[pos],
                    {color = color, attId = attId, value = value, percent = percent, pos = pos, customId = customId}
                )
            end
        end
        attList = SL:HashToSortArray(attList, function(a, b)
            return a[1].pos < b[1].pos
        end)
        -- dump(attList,"attList2")
        for i=1,self.limitZyNum do
            attStrList[i] = "[color=#00ff00]可转印[/color]"
        end
        for k, v in ipairs(attList or {}) do
            local customId = v[1] and v[1].customId or 0
            local customDesc = SL:GetMetaValue("ITEMTIPS_CUSTOM_DESC", customId)
            local color = 0
            local indexpos = 0
            local attr = ""
            for i, a in ipairs(v) do
                local attConfig = SL:GetMetaValue("ATTR_CONFIG", a.attId)
                if not attConfig then
                    attConfig = {}
                end
                local value = a.value
                local color = a.color
                local percent = a.percent
                indexpos = a.pos
                local colorHex = color > 0 and SL:GetValue("COLOR_BY_ID", color)
                if attConfig.Type == 1 then -- 万分比除100
                    value = tonumber(string.format("%.0f", value / 100))
                    percent = 1
                end
                if customDesc then
                    local desc = value .. (percent > 0 and "%%" or "")
                    customDesc = string.gsub(customDesc, "%%s", desc, 1)
                    if colorHex then
                        if string.find(customDesc, "%[color=(.-)%]") then
                            customDesc = string.gsub(customDesc, "%[color=(.-)%]", string.format("[color=%s]", colorHex))
                        else
                            customDesc = string.format("[color=%s]%s[/color]", colorHex, customDesc)
                        end
                    end
                else
                    local name = attConfig.Name
                    local attColor = attConfig.Color and SL:GetValue("COLOR_BY_ID", attConfig.Color)
                    local showColor = colorHex or attColor or "#FFFFFF"
                    local lineStr = string.len(attr) > 0 and "\n" or ""
                    attr = string.format("%s%s[color=%s]%s：+%s%s[/color]", attr, lineStr, showColor, name, value, percent > 0 and "%" or "")
                end
            end
            attr = customDesc or attr
             if indexpos <= self.limitZyNum then
                attStrList[indexpos] = attr
             end
        end
    end
    for i=1,#attStrList do
        str = (str ~= "" and str.."\n" or "") .. attStrList[i]
    end
    return str
end



-- 武勋技能
function EquipTipViewModel:WuXunSkillData(textContent,itemView,originListSize)
    self:ClearWuXunSkill(itemView)
    -- 武勋鉴定
    local itemConfig = self._itemData.ExAbil
    local str = string.format("[color=#FDF2DC]%s[/color]", "[武勋技能]").."\n\n\n\n"

    -- 获取武勋装备铸阶等级列表
    self:GetWuXunEquipLevel()
    local isPC = SL:GetValue("IS_PC_OPER_MODE") or false    
    for i=1,#wuxun_skill_data do
        self['btnWXSkill'..i] =  FGUI:CreateObject(textContent, "A_Right", "btn_wuxun_skill",false)
	    
        
        if isPC then 
            FGUI:setPositionX(self['btnWXSkill'..i],-54+59*i)
	        FGUI:setPositionY(self['btnWXSkill'..i], 54+self.limitZyNum*17)
            FGUI:setScale(self['btnWXSkill'..i], 0.6,0.6)
        else
            FGUI:setPositionX(self['btnWXSkill'..i],-64+79*i)
	        FGUI:setPositionY(self['btnWXSkill'..i], 93+self.limitZyNum*31)
        end 
        WuXunOBJ_cfg[itemView][3][i] = self['btnWXSkill'..i]
        -- 武勋技能名
        local name = FGUI:GetChild(self['btnWXSkill'..i], "n2")
        FGUI:GTextField_setText(name, wuxun_skill_data[i]['SkillName'])
        -- 武勋技能图标
        local icon = FGUI:GetChild(self['btnWXSkill'..i], "Image_icon")
        local skillicon = wuxun_skill_data[i] and wuxun_skill_data[i]['SkillIcon'] or 0
        FGUI:GLoader_setUrl(icon,"ui://A_Right/"..skillicon)
        -- 武勋技能组件
        local needJS = wuxun_skill_data[i]['needlv'] or 0       -- 需求铸阶等级 全套装备最低铸阶等级
        local curJSNum =  0       
        for k , v in pairs(self.WuXunZhuJieTab) do              -- 当前达到铸阶等级的装备数量
            if k >= needJS then
                curJSNum = curJSNum + v
            end
        end
        -- 武勋技能条件展示 图标置灰
        local jsfont = FGUI:GetChild(self['btnWXSkill'..i], "n6")
        if curJSNum >= #wuxun_skill_data then
            FGUI:setGrey(icon, false)
            FGUI:setVisible(jsfont, false)
        else
            FGUI:setGrey(icon, true)
            FGUI:setVisible(jsfont, true)
            FGUI:GRichTextField_setText(jsfont, needJS.."阶\n("..curJSNum.."/"..#wuxun_skill_data..")")
        end
        -- 武勋组件点击切换时间
        FGUI:setOnClickEvent(self['btnWXSkill'..i],function()
            -- print("武勋组件点击切换时间")
            -- 重构技能描述相关
            self.CurSelectWXSkill = i
            -- self:UpdateCellView(itemView, originListSize)
            local attrAtr = ""
            -- 武勋鉴定属性
            local wxjdAttr = self:WuXunJianDingAttr()
            -- 武勋转印属性
            local wxzyAttr = self:WuXunZhuanYinAttr()
            -- 武勋技能
            local wxskillAttr = self:WuXunSkillData(textContent,itemView,originListSize)
            if wxjdAttr ~= "" then
                attrAtr = attrAtr..wxjdAttr.."\n"
            end
            if wxzyAttr ~= "" then
                attrAtr = attrAtr..wxzyAttr.."\n"
            end
            if wxskillAttr ~= "" then
                attrAtr = attrAtr..wxskillAttr.."\n"
            end
            FGUI:GRichTextField_setText(textContent, attrAtr)
            -- 选中框
            for j = 1,#WuXunOBJ_cfg[itemView][3] do
                local Contro = FGUI:getController(WuXunOBJ_cfg[itemView][3][j],"suo")
                if self['btnWXSkill'..i] == WuXunOBJ_cfg[itemView][3][j] then
                    FGUI:Controller_setSelectedIndex(Contro,1)
                else
                    FGUI:Controller_setSelectedIndex(Contro,0)
                end
            end
        end)
        -- 默认展示第一个
        if i == 1 then
            local Contro = FGUI:getController(self['btnWXSkill'..i],"suo")
            FGUI:Controller_setSelectedIndex(Contro,1)
        end
    end
    
    -- 武勋技能描述
    str = str .. wuxun_skill_data[self.CurSelectWXSkill or 1]['SkillDesc']

    return str
end
-- 获取武勋装备铸阶等级
function EquipTipViewModel:GetWuXunEquipLevel()
    self.WuXunZhuJieTab = {}
    local equippos =  wuxun_level_data[1]['WuXun_EquipPos'] or {}
    for i = 1, #equippos do
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", equippos[i])
        if equipData then
            local zjLv = 0
            for j = 1, #equipData.Values do
                if equipData.Values[j]['Id'] == 2 then  
                    zjLv = equipData.Values[j]['Value']
                    self.WuXunZhuJieTab[zjLv] = (self.WuXunZhuJieTab[zjLv] or 0) + 1
                end 
            end
        end
    end
end


--自定义属性
-- function EquipTipViewModel:GetZDYData(itemConfig)
--     --dump(itemConfig)
--     --for i=1,#itemConfig.abil do
--     --    print(itemConfig.abil[i]['i'])
--     --    print(itemConfig.abil[i]['v'])
--     --    dump(itemConfig.abil[i]['v'])
--     --end
--     --装备强化
--     local suitStr = ""
--     if itemConfig.abil[1] then
--         local title = itemConfig.abil[1]['t']
--         local qhtab = itemConfig.abil[1]['v']
--         local pos = 0
--         if title ~= "" then
--             suitStr = suitStr..string.format("\n[color=#ff0000]%s[/color]", "["..title.."]")
--             -- dump(attrConfigs)
--             -- dump(qhtab)
--             for i=1,#qhtab do
--                 --print(qhtab[i][2].."  "..qhtab[i][3])
--                 local name = attrConfigs[qhtab[i][2]]['Name'].."："
--                 suitStr = suitStr..string.format("\n[color=#00ff00]%s[/color]%s", name, qhtab[i][3])
--             end
--         end
--     end
--     --装备赋予
--     if itemConfig.abil[2] then
--         local title = itemConfig.abil[2]['t']
--         local qhtab = itemConfig.abil[2]['v']
--         local pos = 0
--         if title ~= "" then
--             suitStr = suitStr..string.format("\n[color=#ff0000]%s[/color]", "["..title.."]")
--             for i=1,#qhtab do
--                 local name = attrConfigs[qhtab[i][2]]['Name'].."："
--                 suitStr = suitStr..string.format("\n[color=#00ff00]%s[/color]%s", name, qhtab[i][3])
--             end
--         end
--     end
--     --装备觉醒
--     if itemConfig.abil[4] then
--         local title = itemConfig.abil[4]['t']
--         local qhtab = itemConfig.abil[4]['v']
--         local pos = 0
--         if title ~= "" then
--             suitStr = suitStr..string.format("\n[color=#ff0000]%s[/color]", "["..title.."]")
--             for i=1,#qhtab do
--                 local name = attrConfigs[qhtab[i][2]]['Name'].."："
--                 suitStr = suitStr..string.format("\n[color=#00ff00]%s[/color]%s", name, qhtab[i][3])
--             end
--         end
--     end
--     --装备附魂
--     dump(itemConfig)
--     if itemConfig.abil[5] then
--         local title = itemConfig.abil[5]['t']
--         local qhtab = itemConfig.abil[5]['v']
--         local pos = 0
--         if title ~= "" then
--             suitStr = suitStr..string.format("\n[color=#ff0000]%s[/color]", "["..title.."]")
--             for i=1,#qhtab do
--                 local name = attrConfigs[qhtab[i][2]]['Name'].."："
--                 suitStr = suitStr..string.format("\n[color=#00ff00]%s[/color]%s", name, qhtab[i][3])
--             end
--         end
--     end
--     --dump(suitStr)
--     return suitStr
--     -- if suitids and string.len(suitids) > 0 then
--     --     local suitArry = string.split(suitids, "#")
--     --     local pos = 0
--     --     local suitStr = ""
--     --     for k, v in ipairs(suitArry) do
--     --         local id = v and tonumber(v)
--     --         local tSuitStr = id and self:GetSuitDesc(id)
--     --         if tSuitStr then
--     --             pos = pos + 1
--     --             tSuitStr = string.gsub(tSuitStr, "\n$", "")
--     --             suitStr = string.format("%s%s%s", suitStr, pos ~= 1 and "\n" or "", tSuitStr)
--     --         end
--     --     end
--     --     if string.len(suitStr) > 0 then
--     --         local titleName = string.format("%s：", moduleName or "套装属性")
--     --         local titleColor = SL:GetValue("COLOR_BY_ID", 154)
--     --         suitStr = string.format("[color=%s]%s[/color]\n%s", titleColor, titleName, suitStr)
--     --     end

--     --     return suitStr
--     -- end
-- end
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- 条件 &
function EquipTipViewModel:GetConditionStrByID(conditionId)
    local conditionShowStr = ""
    local showStr = SL:GetValue("CONDITION_TIPS", conditionId)
    local showStrList = SL:Split(showStr or "", "&")
    local conditionContentList = SL:Split(SL:GetValue("CONDITION_CONTENT", conditionId) or "", "&")
    for i = 1, #showStrList do
        local tShowStr = showStrList[i]
        if tShowStr and string.len(tShowStr) > 0 then
            local checkCondition = SL:GetValue("CONDITION_BY_STRING", conditionContentList[i] or "")
            tShowStr = string.format("[color=%s]%s[/color]", checkCondition and "#00FF00" or "#FF0000", tShowStr)
            conditionShowStr = string.format("%s%s%s", conditionShowStr, conditionShowStr ~= "" and "\n" or "", tShowStr)
        end
    end
    return conditionShowStr
end

function EquipTipViewModel:GetConditionStr()
    local itemData = self._itemData
    if not itemData.ConditionId then
        return nil
    end
    local conditionShowStr = ""
    if tonumber(itemData.ConditionId) then
        conditionShowStr = self:GetConditionStrByID(tonumber(itemData.ConditionId))
    elseif string.len(itemData.ConditionId) > 0 then
        local data = SL:Split(itemData.ConditionId, "&")
        for i = 1, #data do
            local t = data[i]
            if tonumber(t) then
                local tShowStr = self:GetConditionStrByID(tonumber(t))
                conditionShowStr = string.format("%s%s%s", conditionShowStr, conditionShowStr ~= "" and "\n" or "", tShowStr)
            else
                local _, __, id = string.find(t, "%[(%d+)%]")
                if id and tonumber(id) then
                    local tShowStr = self:GetConditionStrByID(tonumber(id))
                    conditionShowStr = string.format("%s%s%s", conditionShowStr, conditionShowStr ~= "" and "\n" or "", tShowStr)
                end 
            end
        end
    end

    return conditionShowStr
end

---------------------------------------------------------------------------
-- 气功等级
function EquipTipViewModel:GetQigongLvStr(itemData, moduleName)
    local qigongId = itemData.nQiGongId
    local qigongLv = itemData.nQiGongLv
    local desc = ""
    if qigongId and qigongLv then
        local name = qigongId == 0 and "全部气功" or SL:GetValue("SKILL_QIGONG_NAME_BY_ID", qigongId)
        desc = string.format("%s等级：+%s", name or "", qigongLv)
        desc = string.format("[color=%s]%s[/color]", "#A4E0F5", moduleName and string.format("%s%s", moduleName, desc) or desc)
    end
    return desc
end