EquipTipViewModel = class("EquipTipViewModel")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function EquipTipViewModel:ctor(index,itemInstanceData)
    self._index = index
    self._maxContentWid = 0
    self:SetItem(itemInstanceData)
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
    self._lookPlayer = false    -- todo
end

function EquipTipViewModel:UpdateCellView(itemView, originListSize)
    self._ui = FGUI:ui_delegate(itemView)
    self._content = self._ui.Content
    self.textList = {}
    self.textList[1] = FGUI:GetChild(self._content, "Tip")
    self.textList[2] = FGUI:GetChild(self._content, "BaseAttr")
    self.textList[3] = FGUI:GetChild(self._content, "CustomAttr")
    self.textList[4] = FGUI:GetChild(self._content, "Suitex")
    self.textList[11] = FGUI:GetChild(self._content, "Condition")
    self.textList[15] = FGUI:GetChild(self._content, "Job")
    self.textList[16] = FGUI:GetChild(self._content, "Ms")
    self.textList[17] = FGUI:GetChild(self._content, "Level")
    self.textList[18] = FGUI:GetChild(self._content, "Quality")
    self.textList[19] = FGUI:GetChild(self._content, "Zy")
    self.textList[22] = FGUI:GetChild(self._content, "Sex")
    self.textList[23] = FGUI:GetChild(self._content, "InlaysAttr")
    self.textList[24] = FGUI:GetChild(self._content, "EquipType")
    self.textList[27] = FGUI:GetChild(self._content, "QigongLv")

    -- 还原初始大小
    if originListSize then
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
    for k, v in pairs(self.textList) do
        FGUI:setVisible(v, false)
    end

    local maxContentWid = FGUI:getSize(self._content)
    local showTexts = {}
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
                    FGUI:GRichTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if module == 2 then										--基础属性
                local desc = self:GetShowAttData(self._itemData)
                if desc and string.len(desc) > 0 then
                    FGUI:GRichTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if module == 3 then                                     -- 自定义属性
                local desc = self:GetCustomAttrStr()
                if desc and string.len(desc) > 0 then
                    FGUI:GRichTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if module == 4 then                                    -- 套装
                local desc = self:GetSuitData(itemData)
                if desc and string.len(desc) > 0 then
                    FGUI:GRichTextField_setText(textContent, string.format("[color=#FFFFFF]%s[/color]", showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc))
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if module == 11 then                                    -- 条件
                local conditionStr = self:GetConditionStr()
                if conditionStr and string.len(conditionStr) > 0 then
                    FGUI:GRichTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, conditionStr) or conditionStr)
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
                FGUI:GRichTextField_setText(textContent, jobStr)
            end

            if module == 16 then									 --名声
                if not conditionData.TransferName or not conditionData.TransferLV then
                    conditionData = self:GetTransferData(itemData)
                end
                conditionData.TransferName = conditionData.TransferName or "1"
                conditionData.TransferLV = conditionData.TransferLV or 0

                local color = ItemUtil:CheckTransferLV(itemData) and "#FFFFFF" or "#FF0000"
                local desc = conditionData.TransferName --string.format("%s%s", conditionData.TransferName, string.format(SL:GetValue("I18N_STRING", 70000101), SL:GetValue("I18N_STRING", 5000 + conditionData.TransferLV)))
                FGUI:GRichTextField_setText(textContent, string.format("[color=%s]%s[/color]", color, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc))
            end

            if module == 17 then									 --等级
                local canUse = ItemUtil:CheckNeedLevel(itemData)
                local color = canUse and "#FFFFFF" or "#FF0000"
                local desc = itemData.NeedLevel
                desc = string.format("[color=%s]%s[/color]", color, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
                if desc and string.len(desc) > 0 then
                    FGUI:GRichTextField_setText(textContent, desc)
                end
            end

            if module == 18 then									 --品级
                local desc = SL:GetValue("ITEM_GRADE_NAME", itemData.Grade or 0)
                desc = showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc
                local color = SL:GetValue("ITEM_GRADE_COLOR", itemData.Grade or 0)
                if desc and string.len(desc) > 0 then
                    FGUI:GRichTextField_setText(textContent, string.format("[color=%s]%s[/color]", color, desc))
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
                    FGUI:GRichTextField_setText(textContent, string.format("[color=%s]%s[/color]", color, desc))
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
                FGUI:GRichTextField_setText(textContent,sexStr)
            end

            if module == 23 then                                    -- 宝石镶嵌
                local desc = self:GetGemInlaysAttStr(itemData)
                if desc and string.len(desc) > 0 then
                    FGUI:GRichTextField_setText(textContent, showModuleName and string.format("%s%s", moduleCfg.Name, desc) or desc)
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if module == 24 then                                    -- 装置
                local equipTypeName = itemData.StdName or ""
                FGUI:GRichTextField_setText(textContent, string.format("[color=%s]%s[/color]", "#FFFFFF", showModuleName and string.format("%s%s", moduleCfg.Name, equipTypeName) or equipTypeName))
            end

            if module == 27 then                                    -- 气功等级
                local desc = self:GetQigongLvStr(itemData, showModuleName and moduleCfg.Name)
                if desc and string.len(desc) > 0 then
                    FGUI:GRichTextField_setText(textContent, desc)
                else
                    FGUI:setVisible(textContent, false)
                end
            end

            if FGUI:getVisible(textContent) then
                local tWid = FGUI:getSize(FGUI:GetChild(textContent, "title"))
                maxContentWid = math.max(maxContentWid, tWid)
                showTexts[#showTexts + 1] = textContent
            end
        end

    end

    self._maxContentWid = maxContentWid

    for i = 1, #showTexts do
        local tWid, tHei = FGUI:getSize(showTexts[i])
        FGUI:setSize(showTexts[i], self._maxContentWid, tHei)
    end
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
        showAttStr = string.format("%s[color=%s]%s：%s[/color]", showAttStr, SL:GetColorByStyleId(att.color or 255), name, value)
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
        for i = 1, stoneNum do
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
                    local showStrFormat = string.format("[color=%s]%s[/color]\n", colorHex, nameStr)
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
                    value = string.format("%.1f", value / 100)
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

    return customStr
end

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