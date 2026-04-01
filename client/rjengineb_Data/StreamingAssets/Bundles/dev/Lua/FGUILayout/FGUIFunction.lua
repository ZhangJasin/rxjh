FGUIFunction = {}
local ssplit = string.split
local mFloor = math.floor
local mRandom = math.random
local mAbs = math.abs
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")


function FGUIFunction:BindClass(component, classPath)
    classPath = "FGUILayout/" .. classPath
    local ok, mod = pcall(require, classPath)
    if not ok then
        release_log(string.format("[FGUI Error] require %s Fail", classPath))
        return
    else
        local classObj = mod.new(component)
        classObj.component = component
        return classObj
    end
end

--- 设置点击空白区域关闭界面
--- @description 需注意UI底图片穿透问题
--- @param panel table 界面对象
function FGUIFunction:SetCloseUIWhenClickOutside(panel)
    if not panel then return end
    local component = panel.component
    local obj = FGUI:CreateObject(component, "component", "Layout")
    if not component or not obj then return end
    local w, h = FGUI:getSize(component)
    FGUI:SetChildIndex(component, obj, 0)
    FGUI:setSize(obj, w, h)
    FGUI:addRelation(obj, component, "Size")
    FGUI:setOnClickEvent(obj, handler(panel, panel.Close))
end

--------------------------------------------物品/装备 相关---------------------------------------------------

-- 触发 与身上装备比较
function FGUIFunction:CompareEquipOnBody(equipData, autoUse)
    -- 装备数据
    if not equipData then
        return false
    end

    -- 是否装备类型
    local isEquip = SL:GetValue("ITEMTYPE", equipData) == SL:GetValue("ITEMTYPE_ENUM").Equip
    if not isEquip then
        return false
    end

    -- 能否穿戴
    local canUse = SL:CheckItemUseNeed(equipData)
    if not canUse then
        return false
    end

    -- 通过stdmode 获取装备位
    local posList = SL:GetValue("EQUIP_POSLIST_BY_STDMODE", equipData.StdMode)
    if not posList or next(posList) == nil then
        return false
    end

    local myPower = FGUIFunction:GetEquipPower(equipData) -- 当前装备战力

    -- 比较身上装备
    local targetData = nil
    local targetMinPower = 0 -- 身上穿戴最小战力
    local targetMinPos = nil -- 身上穿戴最小战力位置
    for i, pos in ipairs(posList) do
        targetData = SL:GetValue("EQUIP_DATA_BY_POS", pos)
        if not targetData then
            return true, pos -- 身上没有穿戴（优先对比左手）
        end

        local targetPower = FGUIFunction:GetEquipPower(targetData)  -- 身上装备战力
        if targetMinPower == 0 or targetPower < targetMinPower then -- 拿到身上穿戴最小战力
            targetMinPower = targetPower
            targetMinPos = pos
        end
    end

    if targetMinPower < myPower then
        return true, targetMinPos
    end

    if targetMinPos and not autoUse then -- 强制替换
        return false, targetMinPos
    end

    return false
end

-- 触发 与身上装备比较 [背包提升箭头使用]
--[[
    返回 param1(boolean), param2(boolean), param3(boolean)
    param1为true时:                             绿色箭头  （满足穿戴条件，对比全战力）
    param1为false、param2为true时:              黄色箭头  （满足所有穿戴条件, 仅对比基础属性战力）
    param1、param2都为false, param3为true时:    蓝色箭头  （满足部分穿戴条件, 仅对比基础属性战力）
    否则不显示提升箭头.
]]
function FGUIFunction:CompareEquipUpShowOnBody(equipData)
    -- 装备数据
    if not equipData then
        return false
    end

    -- 是否装备类型
    local isEquip = SL:GetValue("ITEMTYPE", equipData) == SL:GetValue("ITEMTYPE_ENUM").Equip
    if not isEquip then
        return false
    end

    -- 满足部分穿戴条件
    local canEquipBase = ItemUtil:CheckBaseCanEquip(equipData)
    if not canEquipBase then
        return false
    end

    -- 满足穿戴条件
    local canEquip = SL:CheckItemUseNeed(equipData)

    -- 通过stdmode 获取装备位
    local posList = SL:GetValue("EQUIP_POSLIST_BY_STDMODE", equipData.StdMode)
    if not posList or next(posList) == nil then
        return false
    end

    local myPower = FGUIFunction:GetEquipPower(equipData)     -- 当前装备战力
    local myDefense = FGUIFunction:GetEquipDefense(equipData) -- 当前装备防御力

    -- 满足所有穿戴条件, 对比全战力和防御力
    if canEquip then
        -- 比较身上装备
        local targetData = nil
        local targetMinPower = 0   -- 身上穿戴最小战力
        local targetMinDefense = 0 -- 身上穿戴最小防御力
        for i, pos in ipairs(posList) do
            targetData = SL:GetValue("EQUIP_DATA_BY_POS", pos)
            if not targetData then -- 身上没有穿戴
                return true
            end

            local targetPower = FGUIFunction:GetEquipPower(targetData)     -- 身上装备战力
            local targetDefense = FGUIFunction:GetEquipDefense(targetData) -- 身上装备防御力

            if targetMinPower == 0 or targetPower < targetMinPower then    -- 拿到身上穿戴最小战力
                targetMinPower = targetPower
            end

            if targetMinDefense == 0 or targetDefense < targetMinDefense then -- 拿到身上穿戴最小防御力
                targetMinDefense = targetDefense
            end
        end

        -- 如果新装备的战力或防御力高于身上装备，显示提升箭头
        if targetMinPower < myPower or targetMinDefense < myDefense then
            return true
        end
    end

    myPower = FGUIFunction:GetEquipBasePower(equipData)               -- 当前装备基础战力
    local myBaseDefense = FGUIFunction:GetEquipBaseDefense(equipData) -- 当前装备基础防御力

    -- 比较身上装备基础战力和基础防御力
    local targetData = nil
    local targetMinPower = 0   -- 身上穿戴最小基础战力
    local targetMinDefense = 0 -- 身上穿戴最小基础防御力
    for i, pos in ipairs(posList) do
        targetData = SL:GetValue("EQUIP_DATA_BY_POS", pos)
        if not targetData then -- 身上没有穿戴
            return false, canEquip, canEquipBase
        end

        local targetPower = FGUIFunction:GetEquipBasePower(targetData)     -- 身上装备基础战力
        local targetDefense = FGUIFunction:GetEquipBaseDefense(targetData) -- 身上装备基础防御力

        if targetMinPower == 0 or targetPower < targetMinPower then        -- 拿到身上穿戴最小基础战力
            targetMinPower = targetPower
        end

        if targetMinDefense == 0 or targetDefense < targetMinDefense then -- 拿到身上穿戴最小基础防御力
            targetMinDefense = targetDefense
        end
    end

    -- 如果新装备的基础战力或基础防御力高于身上装备，显示对应箭头
    if targetMinPower < myPower or targetMinDefense < myBaseDefense then
        return false, canEquip, canEquipBase
    end

    return false
end

-- 解析装备基础属性
function FGUIFunction:ParseItemBaseAtt(attStr, job)
    local attList = {}
    if not attStr or attStr == "" or attStr == "0" or attStr == 0 then
        return attList
    end
    local attArray = SL:Split(attStr, "|")
    local myJob = job or SL:GetValue("JOB")
    for k, v in ipairs(attArray) do
        local attData = SL:Split(v, "#")
        local needJob = tonumber(attData[1])
        local attId = tonumber(attData[2])
        local attValue = tonumber(attData[3])
        if (needJob == 0 or needJob == myJob) and attId and attValue then
            table.insert(attList, {
                id = attId,
                value = attValue
            })
        end
    end
    return attList
end

-- 获取装备合并属性列表 [基础属性 + 附加属性]
function FGUIFunction:GetEquipCombineAttList(item, job, needAllAttr)
    local attList = {}
    if not item then
        return attList
    end

    local myJob = job or SL:GetValue("JOB")

    local newList = {}
    local tbaseAttList = SL:Split(item.Attribute or "", "|")
    for i = 1, #tbaseAttList do
        if tbaseAttList[i] and string.len(tbaseAttList[i]) > 0 then
            local dataTab = SL:Split(tbaseAttList[i], "#")
            local needJob = tonumber(dataTab[1])
            local attId = tonumber(dataTab[2])
            local attValue = tonumber(dataTab[3])
            if (needJob == 0 or needJob == myJob) and attId and attValue then
                if not newList[attId] then
                    newList[attId] = attValue
                else
                    newList[attId] = newList[attId] + attValue
                end
            end
        end
    end

    -- 附加属性
    local exAttList = item.ValuesEx or {}
    local isExAdd = {}
    for _, data in ipairs(exAttList) do
        if data.AttId and data.Value then
            if not newList[data.AttId] then
                newList[data.AttId] = data.Value
            else
                newList[data.AttId] = newList[data.AttId] + data.Value
            end
            isExAdd[data.AttId] = true
        end
    end

    if needAllAttr then
        -- 自定义属性
        local exAbil = item.ExAbil or {}
        for p, d in pairs(exAbil.abil or {}) do
            local group = d.i or 0
            for _, v in ipairs(d.v or {}) do
                local color   = v[1] or 0
                local attId   = v[2] or 0   -- 属性ID 绑定表
                local value   = v[3] or 0   -- 属性值
                local percent = v[4] or 0
                if value > 0 then
                    if not newList[attId] then
                        newList[attId] = value
                    else
                        newList[attId] = newList[attId] + value
                    end
                end
            end
        end

        -- 宝石镶嵌属性
        local inlaysAttr = item.Inlays or {}
        for i, param in ipairs(inlaysAttr) do
            local itemId = param.id
            local multiple = param.c > 0 and param.c or 1
            local exAddValue = param.v
            if itemId and itemId > 0 then
                local itemCfg = SL:GetValue("ITEM_DATA", itemId)
                if itemCfg then
                    local itemAttList = SL:Split(itemCfg.Attribute or "", "|")
                    for i = 1, #itemAttList do
                        if itemAttList[i] and string.len(itemAttList[i]) > 0 then
                            local dataTab = SL:Split(itemAttList[i], "#")
                            local needJob = tonumber(dataTab[1])
                            local attId = tonumber(dataTab[2])
                            local attValue = tonumber(dataTab[3])
                            if (needJob == 0 or needJob == myJob) and attId and attValue then
                                if not newList[attId] then
                                    newList[attId] = attValue * multiple + exAddValue
                                else
                                    newList[attId] = newList[attId] + attValue * multiple + exAddValue
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for k, v in pairs(newList) do
        table.insert(attList, {
            id = k,
            value = v or 0,
            exAdd = isExAdd[k]
        })
    end

    return attList
end

-- 生成特殊属性上下限ID
function FGUIFunction:GetMergeAttId(attTab)
    if attTab and next(attTab) then
        return attTab[1] * 10000 + attTab[2]
    end
end

-- Tips 获取属性展示数据
function FGUIFunction:GetAttShowData(data, job, extraParam)
    local attList = {}
    if not data or data == "" or data == "0" or data == 0 then
        return attList
    end
    extraParam = extraParam or {}

    if type(data) == "string" then    -- 表配置属性
        attList = FGUIFunction:ParseItemBaseAtt(data, job)
    elseif type(data) == "table" then -- 装备数据
        attList = FGUIFunction:GetEquipCombineAttList(data, job)
    end

    local newList = {}
    for i, att in ipairs(attList) do
        local attId = att.id
        local attValue = att.value
        local exAdd = att.exAdd
        local config = SL:GetValue("ATTR_CONFIG", att.id)
        if config then
            local showAttId = attId
            local isMinAtt = false
            local mergeAtts = FGUIDefine.MergeAttConfig[attId]
            if mergeAtts then
                if attId == FGUIDefine.SpecialAttType.Min_ATK or attId == FGUIDefine.SpecialAttType.Max_ATK then
                    config = SL:GetValue("ATTR_CONFIG", FGUIDefine.SpecialAttType.ATK)
                end
                showAttId = FGUIFunction:GetMergeAttId(mergeAtts) or showAttId
                if attId == mergeAtts[1] then
                    isMinAtt = true
                end
            end
            local showColor = config.Color
            if exAdd then
                showColor = config.Excolor or 180
            end
            local percent = 0
            if extraParam.multiple and extraParam.multiple > 0 then
                attValue = attValue * extraParam.multiple
            end
            if config.Type == 1 then -- 万分比除100
                attValue = string.format("%.0f", attValue / 100)
                if extraParam.extraAdd and extraParam.extraAdd > 0 then
                    extraParam.extraAdd = string.format("%.0f", extraParam.extraAdd / 100)
                end
                percent = 1
            end

            if not newList[showAttId] then
                newList[showAttId]       = {}
                newList[showAttId].id    = showAttId
                newList[showAttId].min   = isMinAtt and attValue or 0
                newList[showAttId].max   = not isMinAtt and attValue or 0
                newList[showAttId].name  = config.Name
                newList[showAttId].color = showColor
                newList[showAttId].sort  = config.Sort
            else
                newList[showAttId].min = (isMinAtt and attValue or 0) + newList[showAttId].min
                newList[showAttId].max = (not isMinAtt and attValue or 0) + newList[showAttId].max
            end
            if isMinAtt then
                newList[showAttId].isMerge = true
            end
            local value = ""
            if newList[showAttId].isMerge then
                value = string.format("%s-%s", newList[showAttId].min, newList[showAttId].max)
            else
                value = newList[showAttId].max
            end
            if extraParam.extraAdd and tonumber(extraParam.extraAdd) > 0 then
                value = string.format("%s+%s", value, extraParam.extraAdd)
            end
            newList[showAttId].value = value .. (percent > 0 and "%" or "")
        end
    end

    --
    local baseAttrShow = {}
    for id, v in pairs(newList) do
        table.insert(baseAttrShow, v)
    end

    table.sort(baseAttrShow, function(a, b)
        if a.sort and b.sort then
            return a.sort < b.sort
        else
            return a.id < b.id
        end
    end)

    return baseAttrShow
end

-- 获取战力（综合判断AttScore中的属性，按优先级计算）
function FGUIFunction:GetEquipPower(item)
    if not item then
        return 0
    end
    
    local totalPower = 0
    local job = SL:GetValue("JOB")
    local allAttList = FGUIFunction:GetEquipCombineAttList(item, job, true)
    
    -- 存储各个属性的值，用于综合计算
    local attValues = {}
    
    -- 先收集所有属性值
    for i, data in ipairs(allAttList) do
        local id = data.id
        local value = data.value
        attValues[id] = (attValues[id] or 0) + value
    end
    
    -- 根据AttScore表中的属性优先级进行综合计算
    -- 优先判断的属性：攻速(5)、命中(50)、攻击力(23)
    -- 其次判断的属性：最小攻击力(21)、最大攻击力(22)、武功攻击力(53)
    -- 其他攻击相关属性：会心几率(57)、会心伤害(58)、忽视防御(62)等
    
    -- 1. 攻击力 (ID: 23) - 最重要的攻击属性
    local attackPower = attValues[23] or 0
    if attackPower > 0 then
        -- 攻击力权重最高，直接乘以权重系数
        totalPower = totalPower + attackPower * 1.5
    end
    
    -- 2. 命中 (ID: 50) - 第二重要的属性
    local hitPower = attValues[50] or 0
    if hitPower > 0 then
        -- 命中权重较高
        totalPower = totalPower + hitPower * 1.2
    end
    
    -- 3. 攻速 (ID: 5) - 重要属性
    local attackSpeedPower = attValues[5] or 0
    if attackSpeedPower > 0 then
        -- 攻速通常以百分比形式存在，需要特殊处理
        -- 假设攻速每1%增加0.5战力
        totalPower = totalPower + attackPower * 0.5
    end
    
    -- 4. 武功攻击力 (ID: 53) - 武功相关攻击属性
    local skillAttackPower = attValues[53] or 0
    if skillAttackPower > 0 then
        -- 武功攻击力权重为1.0
        totalPower = totalPower + skillAttackPower * 1.0
    end
    
    -- 5. 最小攻击力 (ID: 21) 和 最大攻击力 (ID: 22)
    local minAttackPower = attValues[21] or 0
    local maxAttackPower = attValues[22] or 0
    
    if minAttackPower > 0 or maxAttackPower > 0 then
        -- 取平均值作为攻击力参考，权重为1.0
        local avgAttackPower = (minAttackPower + maxAttackPower) / 2
        totalPower = totalPower + avgAttackPower * 1.0
    end
    
    -- 6. 其他攻击相关属性（按重要性递减顺序）
    -- 会心几率 (ID: 57)
    local critChancePower = attValues[57] or 0
    if critChancePower > 0 then
        -- 会心几率每1%增加0.3战力
        totalPower = totalPower + critChancePower * 0.3
    end
    
    -- 会心伤害 (ID: 58)
    local critDamagePower = attValues[58] or 0
    if critDamagePower > 0 then
        -- 会心伤害每1%增加0.4战力
        totalPower = totalPower + critDamagePower * 0.4
    end
    
    -- 忽视防御 (ID: 62)
    local ignoreDefensePower = attValues[62] or 0
    if ignoreDefensePower > 0 then
        -- 忽视防御每1%增加0.6战力
        totalPower = totalPower + ignoreDefensePower * 0.6
    end
    
    -- 将总战力四舍五入到整数
    totalPower = math.floor(totalPower + 0.5)
    
    return totalPower
end

-- 获取防御力
function FGUIFunction:GetEquipDefense(item)
    if not item then
        return 0
    end

    local defense = 0

    local job = SL:GetValue("JOB")
    local allAttList = FGUIFunction:GetEquipCombineAttList(item, job, true)

    -- 防御相关属性ID：52(防御), 54(武功防御), 56(对怪防御), 69(对怪武防)
    local defenseAttIds = { 52, 54, 56, 69 }
    local defenseAttMap = {}
    for _, attId in ipairs(defenseAttIds) do
        defenseAttMap[attId] = true
    end

    for i, data in ipairs(allAttList) do
        local id = data.id
        local value = data.value

        -- 如果是防御属性，直接累加数值
        if defenseAttMap[id] then
            defense = defense + value
        end
    end

    return defense
end

-- 获取基础战力
function FGUIFunction:GetEquipBasePower(item)
    if not item then
        return 0
    end

    local attList = {}
    local myJob = SL:GetValue("JOB")
    local power = 0

    local tbaseAttList = SL:Split(item.Attribute or "", "|")
    for i = 1, #tbaseAttList do
        if tbaseAttList[i] and string.len(tbaseAttList[i]) > 0 then
            local dataTab = SL:Split(tbaseAttList[i], "#")
            local needJob = tonumber(dataTab[1])
            local attId = tonumber(dataTab[2])
            local attValue = tonumber(dataTab[3])
            if (needJob == 0 or needJob == myJob) and attId and attValue then
                table.insert(attList, {
                    id = attId,
                    value = attValue
                })
            end
        end
    end

    for i, data in ipairs(attList) do
        local id = data.id
        local value = data.value
        local config = id and SL:GetMetaValue("ITEM_ATTR_POWER_CONFIG", id)
        if config then
            local powerKey = string.format("power%s", myJob)
            local powerValue = config[powerKey] and (math.floor(value / config.value) * config[powerKey]) or 0
            power = power + powerValue
        end
    end

    return power
end

-- 获取基础防御力
function FGUIFunction:GetEquipBaseDefense(item)
    if not item then
        return 0
    end

    local attList = {}
    local myJob = SL:GetValue("JOB")
    local defense = 0

    local tbaseAttList = SL:Split(item.Attribute or "", "|")
    for i = 1, #tbaseAttList do
        if tbaseAttList[i] and string.len(tbaseAttList[i]) > 0 then
            local dataTab = SL:Split(tbaseAttList[i], "#")
            local needJob = tonumber(dataTab[1])
            local attId = tonumber(dataTab[2])
            local attValue = tonumber(dataTab[3])
            if (needJob == 0 or needJob == myJob) and attId and attValue then
                table.insert(attList, {
                    id = attId,
                    value = attValue
                })
            end
        end
    end

    -- 防御相关属性ID：52(防御), 54(武功防御), 56(对怪防御), 69(对怪武防)
    local defenseAttIds = { 52, 54, 56, 69 }
    local defenseAttMap = {}
    for _, attId in ipairs(defenseAttIds) do
        defenseAttMap[attId] = true
    end

    for i, data in ipairs(attList) do
        local id = data.id
        local value = data.value

        -- 如果是防御属性，直接累加数值
        if defenseAttMap[id] then
            defense = defense + value
        end
    end

    return defense
end

-- Tips获取不同装备对比
function FGUIFunction:GetDiffEquip(itemData)
    local posList = itemData and SL:GetValue("EQUIP_POSLIST_BY_STDMODE", itemData.StdMode)
    local equipList = {}
    if posList then
        for _, pos in pairs(posList) do
            local equip = SL:GetValue("EQUIP_DATA_BY_POS", pos)
            if equip and next(equip) and equip.MakeIndex ~= itemData.MakeIndex then
                table.insert(equipList, equip)
            end
        end
    end
    return equipList
end

------------------------------------------------------------------------------------------------------------
-- 更换loading背景图路径
function FGUIFunction:GetLoadingBackGroundByKey(key)
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")

    local bgName = nil
    local bgPath = "ImageBG/%s"

    local sData = SL:GetValue("GAME_DATA", key)
    if sData and string.len(sData) > 0 then
        local tData = ssplit(sData, "|")
        local isRandom = tonumber(tData[2]) or 0
        local tName = ssplit(tData[1], "#")
        if tName and next(tName) then
            bgName = tName[1]
            if isRandom == 1 then
                local random = math.random(1, #tName)
                bgName = tName[random]
            end
        end
        bgPath = string.format(bgPath, bgName)
    end

    if not SL:IsFileExist(bgPath) then
        bgPath = "ImageBG/login_1"
        if screenW < screenH then
            bgPath = "ImageBG/login_1_p"
        end
    end

    return bgPath
end

-- 更换切换地图场景背景图路径
function FGUIFunction:GetMapSceneBackGroud(data)
    local mapCfg = SL:GetValue("MAP_INFO_CONFIG", data.name)
    local bgName = mapCfg and mapCfg.LoadingScene or data.name
    local bgPath = string.format("ImageBG/%s", bgName)
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    if screenW < screenH then
        bgPath = string.format("ImageBG/%s_p", bgName)
    end

    if not SL:IsFileExist(bgPath) then
        bgPath = FGUIFunction:GetLoadingBackGroundByKey("loadingScene")
    end

    return bgPath
end

-- 获取背景图文本提示(对应权重 LoadingTips表里配置)
function FGUIFunction:GetRadomLoadingTips()
    local sum = 0
    local tRandom = {}
    local config = SL:GetValue("LOADING_TIPS_CONFIG")
    for i, cfg in ipairs(config) do
        local id = cfg.ID
        local weight = cfg.Weight
        sum = sum + weight
        tRandom[id] = sum
    end

    local num = math.random(1, sum)
    for id, random in ipairs(tRandom) do
        if num <= random then
            local config = SL:GetValue("LOADING_TIPS_CONFIG_BY_ID", id)
            if config then
                return config.Tips
            end
        end
    end

    return ""
end

-- 技能蓝耗是否足够
function FGUIFunction:CheckSkillEnoughMP(skillID)
    local cost = SL:GetValue("SKILL_MP_COST_BY_ID", skillID)
    return cost <= SL:GetValue("MP")
end

function FGUIFunction:CheckAbleToLaunch(skillID)
    --[[
        1: able
        -1: not learned
        -2: is cd
        -3: not enough mana
        -4: buff not allowed
        -5: not enough arrow
        -6: not Wear weapon
    ]]

    -- 是否学习
    if not SL:GetValue("SKILL_DATA_BY_ID", skillID) then
        return -1
    end

    -- cd
    if SL:GetValue("SKILL_CHECK_IS_CD", skillID) then
        return -2
    end

    -- 蓝耗
    if not FGUIFunction:CheckSkillEnoughMP(skillID) then
        return -3
    end

    -- buff
    if SL:GetValue("BUFF_CHECK_FORBID_SKILL", skillID) then
        return -4
    end

    -- not enough arrow
    if not FGUIFunction:CheckSkillEnoughArrow(skillID) then
        return -5
    end

    -- not Wear weapon
    if not FGUIFunction:CheckSkillWearWeapon(skillID) then
        return -6
    end

    return 1
end

--是否穿戴武器
function FGUIFunction:CheckSkillWearWeapon(skillID)
    local isNormalAttack = SL:GetValue("SKILL_CHECK_IS_ATTACK", skillID)
    if not isNormalAttack then
        local isNeedWeapon = SL:GetValue("SKILL_CHECK_IS_NEED_WEAPON", skillID)
        if isNeedWeapon then
            local pos = 0
            local equipData = SL:GetValue("EQUIP_DATA_BY_POS", pos)
            if equipData then
                return true
            else
                return false
            end
        else
            return true
        end
    else
        return true
    end
end

--是否有足够的箭头
function FGUIFunction:CheckSkillEnoughArrow(skillID)
    local cost = SL:GetValue("SKILL_ARROW_COST_BY_ID", skillID)
    if cost and cost > 0 then
        local pos = SL:GetValue("GAME_DATA", "Arrow_equipment") or 11
        local equipData = SL:GetValue("EQUIP_DATA_BY_POS", pos)
        if not equipData then
            return false
        else
            return equipData.OverLap >= cost
        end
    else
        return true
    end
end

--鼠标移动触发
function FGUIFunction:MouseMove(pos)
    if pos then
        SL:SetValue("USER_INPUT_MOVE", pos.x, pos.z)
    else
        FGUIFunction:FindPathFailTips()
    end
end

--寻路失败提示 该区域不可达
function FGUIFunction:FindPathFailTips()
    -- if FGUIFunction._findPathFailTipsSchedule then
    --     return
    -- end
    -- SL:ShowSystemTips(SL:GetValue("I18N_STRING", 20000000))
    -- FGUIFunction._findPathFailTipsSchedule = SL:ScheduleOnce(function()
    --     FGUIFunction._findPathFailTipsSchedule = nil
    -- end, 3)
end

--检查物品限时 超时
function FGUIFunction:CheckItemLimitTime(item)
    local startTime = item.startTime
    local totalTime = item.totalTime
    if not startTime or not totalTime then
        return false
    end

    local isLimit = false

    local leftTime = totalTime - (SL:GetValue("SERVER_TIME") - startTime)
    if leftTime <= 0 then
        local function jumpToBuy(iType)
            if iType == 1 then
                SL:OpenNPCStoreUI(1, 1, false)
            end
        end

        isLimit = true
        local data = {}
        data.str = string.format(GET_STRING(80000312), "#ff0000", item.Name)
        data.btnDesc = { GET_STRING(1002), GET_STRING(1000) }
        data.callback = jumpToBuy
        SL:OpenCommonDialog(data)
    end

    return isLimit
end

function FGUIFunction:OpenBag(page)
    if not page then
        page = 1
    end

    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Bag_pc", "PCPlayerInfoPanel", page)
    else
        FGUI:Open("Bag", "PlayerInfoPanel", page)
    end
end

-- page:1:属性栏,2:称号栏
function FGUIFunction:OpenPCBarRoot(page)
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Bag_pc", "PCBarRootPanel", page)
    else
        print("非pc环境调用pc方法")
    end
end

-- 显示tips
-- parent:参照父节点
-- showText:显示的文本
function FGUIFunction:OpenAttrTips(showText, parent)
    local data = {}
    data.showText = showText
    data.parent = parent
    FGUI:Open("Common", "CommonAttrTip", data)
end

-- 背包排序方法 (需要 返回数组)
function FGUIFunction:GetBagSortFunction(a, b)
    local itemClassA = a.ItemType or 9999
    local itemClassB = b.ItemType or 9999
    if itemClassA == itemClassB then
        if a.Index == b.Index then
            return a.OverLap > b.OverLap
        end
        return a.Index < b.Index
    end
    return itemClassA < itemClassB
end

-- 仓库排序方法 (需要 返回数组)
function FGUIFunction:GetStorageSortFunction(a, b)
    local itemClassA = a.ItemType or 9999
    local itemClassB = b.ItemType or 9999
    if itemClassA == itemClassB then
        if a.Index == b.Index then
            return a.OverLap > b.OverLap
        else
            return a.Index < b.Index
        end
    else
        return itemClassA < itemClassB
    end
end

-- 请求仓库存储,
-- [[
-- posData:{from,to,page}
-- from{ITEMFROMUI_ENUM,index} 请求取出界面和位置索引，
-- to{ITEMFROMUI_ENUM,index} 存放界面和位置索引
-- ]]
function FGUIFunction:RequestSaveItemToNpcStorageInCurPage(data, posData)
    data.selectPage = SL:GetValue("STORAGE_SELECT_PAGE") or 0
    SL:RequestSaveItemToNpcStorage(data, posData)
end

-- 获取头像资源路径
-- avatar:自定义头像值
-- 玩家自定义头像路径 "ui://PlayerIcon/avatar_[avatar].png"
-- job:职业
-- sex:性别
function FGUIFunction:GetAvatarUrl(avatar, job, sex)
    -- 玩家头像
    if not avatar or avatar == 0 then
        if not job then job = SL:GetValue("JOB") end
        if not sex then sex = SL:GetValue("SEX") end
        return string.format("ui://PlayerIcon/main_avatar%s_%s", job, sex)
    end

    -- 自定义头像
    return string.format("ui://PlayerIcon/avatar_%s", avatar)
end

-- 获取头像框资源路径
function FGUIFunction:GetAvatarFrameUrl(avatarFrame)
    return "ui://AvatarFrame/frame_" .. (avatarFrame or 0)
end

-- 获取称号icon路径
function FGUIFunction:GetTitleIconURL(icon)
    if string.isNullOrEmpty(icon) then
        return ""
    end
    return "ui://TitleIcon/" .. icon
end

-- 获取聊天框气泡资源路径
function FGUIFunction:GetChatFrameUrl(chatFrame)
    if not chatFrame then
        chatFrame = 0
    end
    return string.format("ui://public/ChatFrame_%s", chatFrame)
end

-- 获取职业资源路径
function FGUIFunction:GetJobUrl(job)
    if not job or job == 0 then
        return ""
    end
    return string.format("%savatarjob_%s", global.MMO.PATH_RES_PLAYER_ICON, job)
end

-- 检测掉落物自动拾取
function FGUIFunction:CheckDropItemAutoPick(actorID)
    local mainPlayerID = SL:GetValue("USER_ID")

    --丢弃者是自己
    if SL:GetValue("DROPITEM_DISCARDER_ID", actorID) == mainPlayerID then
        return false
    end

    --不拾取别人丢弃的
    if SL:GetValue("BATTLE_IS_AFK") then
        if SL:GetValue("SETTING_IGNORE_DROP_BY_PLAYER") then
            local discarderID = SL:GetValue("DROPITEM_DISCARDER_ID", actorID)
            if discarderID then
                return false
            end
        end
    end

    --背包满 非金币
    if SL:GetValue("BAG_IS_FULL", false) and SL:GetValue("ITEM_INDEX_BY_ACTOR_ID", actorID) ~= 0 then
        return false
    end

    --是否可拾取道具
    if not SL:GetValue("ACTOR_IS_PICK_ITEM", actorID) then
        return false
    end

    --自动拾取开关是否打开
    local typeIndex = SL:GetValue("ACTOR_TYPE_INDEX", actorID)
    if not SL:GetValue("ITEM_CAN_AUTO_PICK", typeIndex) then
        return false
    end

    --掉落类型
    local ownerID = SL:GetValue("ACTOR_OWNER_ID", actorID)
    local dropType = SL:GetValue("DROPITEM_DROPTYPE", actorID)
    if dropType == SLDefine.DROP_TYPE.DEFAULT
        or dropType == SLDefine.DROP_TYPE.FREEDOM
        or dropType == SLDefine.DROP_TYPE.PERSONAL then
        if ownerID and ownerID ~= mainPlayerID then
            return false
        end
    elseif dropType == SLDefine.DROP_TYPE.TEAM then
        local teamID = SL:GetValue("TEAM_ID")
        if ownerID and ownerID ~= teamID then
            return false
        end
    elseif dropType == SLDefine.DROP_TYPE.GUILD then
        local guildID = SL:GetValue("GUILD_ID")
        if ownerID and ownerID ~= guildID then
            return false
        end
    end
    return true
end

-- 检测掉落物手动拾取
function FGUIFunction:CheckDropItemPick(actorID)
    --背包满 非金币
    if SL:GetValue("BAG_IS_FULL", true) then
        if SL:GetValue("ITEM_INDEX_BY_ACTOR_ID", actorID) ~= 0 then
            return false, SLDefine.PICKUP_FAIL_TYPE.BAG_FULL
        end
    end

    return true
end

-- 掉落物触发 返回 模型 、特效 是否显示
function FGUIFunction:DropIsShow(actorID)
    return true, true
end

-- 技能施法开始
function FGUIFunction:OnSkillLaunch(launcherID, skillID, targetID, dir, dstX, dstY, dstZ)
end

local allChannelList = nil
-- 获取显示的频道, 传入需额外隐藏的频道
function FGUIFunction:GetShowChannels(...)
    if not allChannelList then
        local CHANNEL                   = SLDefine.CHAT_CHANNEL
        local allChannel                = {}
        allChannel[CHANNEL.Common]      = { id = CHANNEL.Common, str = SL:GetValue("I18N_STRING", 40000001) }
        allChannel[CHANNEL.World]       = { id = CHANNEL.World, str = SL:GetValue("I18N_STRING", 40000013) }
        allChannel[CHANNEL.ServerAll]   = { id = CHANNEL.ServerAll, str = SL:GetValue("I18N_STRING", 40000014) }
        allChannel[CHANNEL.Near]        = { id = CHANNEL.Near, str = SL:GetValue("I18N_STRING", 40000007) }
        allChannel[CHANNEL.System]      = { id = CHANNEL.System, str = SL:GetValue("I18N_STRING", 40000002) }
        allChannel[CHANNEL.Team]        = { id = CHANNEL.Team, str = SL:GetValue("I18N_STRING", 40000006) }
        allChannel[CHANNEL.Guild]       = { id = CHANNEL.Guild, str = SL:GetValue("I18N_STRING", 40000005) }
        allChannel[CHANNEL.Server]      = { id = CHANNEL.Server, str = SL:GetValue("I18N_STRING", 40000011) }
        allChannel[CHANNEL.ServerGroup] = { id = CHANNEL.ServerGroup, str = SL:GetValue("I18N_STRING", 40000012) }
        allChannel[CHANNEL.Trade]       = { id = CHANNEL.Trade, str = SL:GetValue("I18N_STRING", 40000015) }

        --移除不显示的频道
        local showChannelData           = SL:GetValue("GAME_DATA", "MobileChannelShow")
        local showList                  = {}
        if showChannelData then
            local list = ssplit(showChannelData, "#")
            for i, idStr in ipairs(list) do
                local id = tonumber(idStr)
                if allChannel[id] then
                    table.insert(showList, allChannel[id])
                end
            end
        end
        allChannelList = showList
    end
    local len = select("#", ...)
    if len <= 0 then return allChannelList end
    local list = {}
    local hideChannels = { ... }
    local hideMap = {}
    for k, v in pairs(hideChannels) do
        hideMap[v] = true
    end
    for k, v in pairs(allChannelList) do
        if not hideMap[v.id] then
            table.insert(list, v)
        end
    end
    return list
end

function FGUIFunction:GetPickItemFxUIEndPos()
    return FGUIFunction.PickItemFxUIEndPosX, FGUIFunction.PickItemFxUIEndPosY
end

function FGUIFunction:SetPickItemFxUIEndPos(x, y)
    FGUIFunction.PickItemFxUIEndPosX = x
    FGUIFunction.PickItemFxUIEndPosY = y
end

--移动触发
function FGUIFunction:OnUserInputMove(data)
end

--释放技能触发
function FGUIFunction:OnUserInputLaunch(skillID, launchDir, launchPos)
end

--[[
-- component结构参照public/common/CommonPlayerFrame
-- 头像路径:FGUI工程下PlayerIcon包下
-- 头像框路径:FGUI工程下AvatarFrame包下
-- param参数
-- component:结构参照public/common/CommonPlayerFrame结构
-- data:{
    -- AvatarID
    -- Job
    -- Sex
    -- FrameID
-- }
-- 框路径 "ui://AvatarFrame/s[frame].png"
-- 玩家头像路径 "ui://PlayerIcon/main_avatar[job]_[sex].png"
-- 玩家自定义头像路径 "ui://PlayerIcon/avatar_[AvatarID].png"
--]]
function FGUIFunction:SetCommonPlayerFrame(component, data, clickCallBack)
    if not component then
        return
    end

    local Image_head = FGUI:GetChild(component, "Image_head")
    if not Image_head then
        return
    end

    local Image_headFrame = FGUI:GetChild(component, "Image_headFrame")
    if not Image_headFrame then
        return
    end

    local headPath = FGUIFunction:GetAvatarUrl(data.AvatarID, data.Job or 0, data.Sex or 0)
    FGUI:GLoader_setUrl(Image_head, headPath, nil, true)

    -- 添加点击事件
    if clickCallBack then
        FGUI:setOnClickEvent(Image_head, function()
            clickCallBack()
        end)
    end

    FGUI:GLoader_setUrl(Image_headFrame, FGUIFunction:GetAvatarFrameUrl(data.FrameID or 0), nil, true)
end

-- 临时用创建Item对象
function FGUIFunction:ItemShow_Create(callBack)
    FGUI:CreateObjectAsync("public", "CommonItem", callBack)
end

-- 滚动文本Label 设置内容
-- defaultAlign:不滚动时文本显示方式 0左对齐 1居中 2右对齐
-- extData
---   strokeColor:描边颜色
---   strokeSize:描边大小
function FGUIFunction:ScrollText_setString(scrollText, str, speed, defaultAlign, extData)
    if not scrollText then return end
    local title = FGUI:GetChild(scrollText, "title")
    FGUI:GLabel_setTitle(scrollText, str)
    FGUI:stopAllActions(title)
    if str == "" then return end
    local titleW = FGUI:getWidth(title)
    local scrollW = FGUI:getWidth(scrollText)
    local dis = titleW - scrollW
    if dis > 0 then
        -- 滚动
        FGUI:setPositionX(title, 0)
        local time = dis / 20 * (speed or 1)
        FGUI:runAction(title,
            FGUI:ActionRepeatForever(
                FGUI:ActionSequence(
                    FGUI:ActionDelayTime(1),
                    FGUI:ActionMoveBy(time, -dis, 0),
                    FGUI:ActionDelayTime(1),
                    FGUI:ActionMoveTo(0, 0, 0)
                )))
    else
        --不滚动
        if defaultAlign == 2 then     --右对齐
            FGUI:setPositionX(title, -dis)
        elseif defaultAlign == 1 then --居中
            FGUI:setPositionX(title, -dis / 2)
        else                          --左对齐
            FGUI:setPositionX(title, 0)
        end
    end

    if extData then
        if extData.strokeColor and extData.strokeSize then
            FGUI:GTextField_setStrokeColor(title, extData.strokeColor)
            FGUI:GTextField_setStroke(title, extData.strokeSize)
        end
    end
end

function FGUIFunction:PosIsInRectWidget(widget, eventData)
    if not widget then
        SL:PrintEx("[Error] widget is nil")
        return false
    end

    if not eventData then
        SL:PrintEx("[Error] eventData is nil")
        return false
    end


    local posX, posY = FGUI:getTouchPosition(eventData)
    local width, height = FGUI:getSize(widget)
    local widgetX, widgetY = FGUI:getWorldPosition(widget)
    if posX >= widgetX and posX <= widgetX + width
        and posY >= widgetY and posY <= widgetY + height then
        return true
    end

    return false
end

function FGUIFunction:AdaptNotch(component)
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local safeL, safeR, safeB, safeT = SL:GetValue("SCREEN_SAFE_AREA_RATIO")
    FGUI:setSize(component, screenW - safeR - safeL, screenH - safeB - safeT)
    FGUI:setPosition(component, safeL, safeT)
end

----------------------------------------------------------------------------------------------------------
-- 打开行会
function FGUIFunction:OpenGuildAutoUI()
    if SL:GetValue("GUILD_IS_JOINED") then
        FGUIFunction:OpenGuildMainFrameUI(1)
    else
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Open("Guild_pc", "PCGuildJoinList")
        else
            FGUI:Open("Guild", "GuildJoinList")
        end
    end
end

-- 关闭行会
function FGUIFunction:CloseGuildAutoUI()
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Close("Guild_pc", "PCGuildMainPanel")
        FGUI:Close("Guild_pc", "PCGuildJoinList")
    else
        FGUI:Close("Guild", "GuildMainPanel")
        FGUI:Close("Guild", "GuildJoinList")
    end
end

function FGUIFunction:IsGuildOpen()
    if SL:GetValue("IS_PC_OPER_MODE") then
        return FGUI:CheckOpen("Guild_pc", "PCGuildMainPanel") or FGUI:CheckOpen("Guild_pc", "PCGuildJoinList")
    else
        return FGUI:CheckOpen("Guild", "GuildMainPanel") or FGUI:CheckOpen("Guild", "GuildJoinList")
    end
end

-- 打开行会主页
function FGUIFunction:OpenGuildMainFrameUI(page)
    if not SL:GetValue("GUILD_IS_JOINED") then
        ShowSystemTips(GET_STRING(10003033))
        return
    end
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Guild_pc", "PCGuildMainPanel", page)
    else
        FGUI:Open("Guild", "GuildMainPanel", page)
    end
end

-- 打开玩家信息查看弹窗
function FGUIFunction:OpenFuncDockTips(data)
    if not data then
        return
    end

    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("FuncDock_pc", "PCFuncDockTip", data)
    else
        FGUI:Open("FuncDock", "FuncDockTip", data)
    end
end

-- 打开登录创角
function FGUIFunction:OpenLoginRoleUI()
    local roleData = SL:GetValue("LOGIN_DATA")
    if #roleData > 0 then
        -- 进入选角
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Open("LoginRole_pc", "LoginRoleSelect", nil, nil, { classPath = "FGUILayout/LoginRole/LoginRoleSelect" })
        else
            FGUI:Open("LoginRole", "LoginRoleSelect")
        end
    else
        -- 进入创角
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Open("LoginRole_pc", "LoginRoleCreate", nil, nil, { classPath = "FGUILayout/LoginRole/LoginRoleCreate" })
        else
            FGUI:Open("LoginRole", "LoginRoleCreate")
        end
    end
    local DataTrackProxy = global.Facade:retrieveProxy(global.ProxyTable.DataTrackProxy)
    DataTrackProxy:OnEnterCreateRolePage()
end

-- 打开摆摊商品浏览界面
function FGUIFunction:OpenStallProductUI(data)
    local isSelf = tostring(SL:GetValue("USER_ID")) == data.Userid
    -- 背包需在商品界面之前打开
    if isSelf then
        FGUIFunction:OpenSimpleBagUI("Stall", "StallProduct")
    else
        if FGUI:CheckOpen("Bag_pc", "PCSimpleBagPanel") then
            FGUI:Close("Bag_pc", "PCSimpleBagPanel")
        end

        if FGUI:CheckOpen("Bag", "SimpleBagPanel") then
            FGUI:Close("Bag", "SimpleBagPanel")
        end
    end
    data.isSelf = isSelf
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Stall_pc", "PCStallProduct", data)
    else
        FGUI:Open("Stall", "StallProduct", data)
    end
end

-- 打开简单背包(填入sourcePackageName 和 sourceComponentName，关闭的时候会把source页面也关了)
function FGUIFunction:OpenSimpleBagUI(sourcePackageName, sourceComponentName)
    local data = {}
    if sourcePackageName and sourceComponentName then
        data.packageName = sourcePackageName
        data.componentName = sourceComponentName
    end
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Bag_pc", "PCSimpleBagPanel", data)
    else
        FGUI:Open("Bag", "SimpleBagPanel", data)
    end
end

--组队
function FGUIFunction:OpenTeamFrameUI(page)
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    if isPC then
        FGUI:Open("Team", "PCTeamPanel", page)
    else
        FGUI:Open("Team", "TeamPanel", page)
    end
end

-- 智能组队界面
function FGUIFunction:OpenTeamAutoUI()
    local hasTeam = SL:GetValue("TEAM_COUNT") > 0
    if not hasTeam then
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Open("Team_pc", "PCTeamNearPanel")
        else
            FGUI:Open("Team", "TeamNearPanel")
        end
    else
        if SL:GetValue("IS_PC_OPER_MODE") then
            FGUI:Open("Team_pc", "PCTeamPanel")
        else
            FGUI:Open("Team", "TeamPanel")
        end
    end
end

function FGUIFunction:CloseTeamAutoUI()
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Close("Team_pc", "PCTeamPanel")
        FGUI:Close("Team_pc", "PCTeamNearPanel")
    else
        FGUI:Close("Team", "TeamPanel")
        FGUI:Close("Team", "TeamNearPanel")
    end
end

function FGUIFunction:CheckTeamAutoIsOpen()
    if SL:GetValue("IS_PC_OPER_MODE") then
        return FGUI:CheckOpen("Team_pc", "PCTeamPanel") or FGUI:CheckOpen("Team_pc", "PCTeamNearPanel")
    else
        return FGUI:CheckOpen("Team", "TeamPanel") or FGUI:CheckOpen("Team", "TeamNearPanel")
    end
end

--[[
	data.from           --从哪个界面打开Tip,用于逻辑判断SL:GetValue("ITEMFROMUI_ENUM")
	data.itemData		--物品数据
    data.hideCompare    --如果是装备，判断否隐藏装备比较
    data.hideButtons    --如果是道具，判断否隐藏使用拆分等按钮
    data.buyParam       -- 购买框参数 table
]]
-- 道具装备tips
function FGUIFunction:OpenItemTips(data)
    SL:RequireFile("FGUILayout/Common/ItemTips")
    ItemTips.ShowTip(data)
end

function FGUIFunction:CloseItemTips()
    if ItemTips then
        ItemTips.CloseItemTips()
    end
end

function FGUIFunction:OpenGuideUI(task)
    FGUI:Open("Guide", "GuideLayer", task, FGUI_LAYER.NOTICE)
end

function FGUIFunction:HideGuideUI()
    SLBridge:onLUAEvent(LUA_EVENT_GUIDE_HIDE)
end

-- 打开NPC商店
function FGUIFunction:OpenNCPStorePanel(groupId)
    FGUI:Open("TreasureShop", "NPCStorePanel", groupId)
end

-- 打开公共数字输入页面 data.title:标题 data.maxNum:最大数量 callback_yes:确认后回调 callback_no:取消后回调
function FGUIFunction:OpenCommonNumberInputPanel(data)
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Common_pc", "PCCommonNumberInput", data)
    else
        FGUI:Open("Common", "CommonNumberInput", data)
    end
end

function FGUIFunction:OpenCommonItemSplitDialog(data)
    if not data then
        SL:printEx("data is null")
        return
    end

    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Common_pc", "PCCommonItemSplitDialog", data)
    else
        FGUI:Open("Common", "CommonItemSplitDialog", data)
    end
end

-- 道具拆分弹窗
function FGUIFunction:OpenItemSplitPop(itemData)
    local BagProxy = global.Facade:retrieveProxy(global.ProxyTable.BagProxy)
    local isFull = BagProxy:CheckIsOverload()
    if isFull then
        SL:onLUAEvent(LUA_EVENT_BAG_IS_FULL)
        return
    end
    FGUIFunction:OpenCommonItemSplitDialog(itemData)
end

function FGUIFunction:DropItem(itemData)
    local data = {}
    data.title = GET_STRING(1003)
    data.str = string.format(GET_STRING(60005006), itemData.Name)
    data.btnDesc = { GET_STRING(1001), GET_STRING(1000) }
    data.title = GET_STRING(1003)
    data.callback = function(btn)
        if btn == 1 then
            SL:RequestDropItem(itemData, itemData.OverLap and itemData.OverLap or 1)
        end
    end
    SL:OpenCommonDialog(data)
end

--是否友方
function FGUIFunction:CheckIsFriendByID(targetID)
    -- player & monster, only!!!!
    if false == SL:GetValue("ACTOR_IS_PLAYER", targetID)
        and false == SL:GetValue("ACTOR_IS_MONSTER", targetID) then
        return false
    end

    -- dead || born
    if SL:GetValue("ACTOR_IS_DIE", targetID) then
        return false
    end

    -- hp 0
    if SL:GetValue("ACTOR_HP", targetID) <= 0 then
        return false
    end

    -- 采集物
    if SL:GetValue("ACTOR_IS_COLLECTION", targetID) then
        return false
    end

    -- 是敌人
    if SL:GetValue("ACTOR_IS_ENEMY", targetID) then
        return false
    end

    return true
end

function FGUIFunction:FindAutoLaunchSkill()
    local scheme = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_SELECT")
    local skills = SL:GetValue("SETTING_FIGHT_JOB_SKILL", scheme)
    --0:循环释放 1:冷却释放
    local mode = SL:GetValue("SETTING_FIGHT_JOB_SKILL_RELEASE_MODEL")
    local skillID = -1
    if mode == 1 then --1:冷却释放
        self._lastScheme = nil
        self._autoSkillIndex = nil
        for i, v in ipairs(skills) do
            if v ~= -1 and FGUIFunction:CheckAbleToLaunch(v) == 1 then
                skillID = v
                break
            end
        end
    else --0:循环释放
        local lastScheme = self._lastScheme
        if lastScheme ~= scheme then
            self._autoSkillIndex = 1
            self._lastScheme = scheme
        end

        local index = self._autoSkillIndex
        for i = 1, #skills do
            local trySkillID = skills[index]
            if trySkillID ~= -1 and FGUIFunction:CheckAbleToLaunch(trySkillID) == 1 then
                skillID = trySkillID
            end
            index = index + 1
            if index > #skills then
                index = 1
            end
            if skillID ~= -1 then
                self._autoSkillIndex = index
                break
            end
        end
    end

    if skillID == -1 then
        local baseSkillID = FGUIFunction:AutoGetRandomBaseSkillID()
        if FGUIFunction:CheckAbleToLaunch(baseSkillID) == 1 then
            skillID = baseSkillID
        end
    end

    --替换脚本技能
    if skillID ~= -1 then
        local scriptSkillID = SL:GetValue("SKILL_SCRIPT_REPLACE_ID", skillID)
        if scriptSkillID then
            if FGUIFunction:CheckAbleToLaunch(scriptSkillID) == 1 then
                skillID = scriptSkillID
            end
        end
    end
    return skillID
end

function FGUIFunction:FindRobotRestoreSkill()
    local curSkillID = nil
    local targetID = nil
    --恢复类
    local selfSkillID = SL:GetValue("SETTING_LHA_RELEASE_SKILL_ID")
    if selfSkillID and selfSkillID > 0 then
        local restoreValue = SL:GetValue("SETTING_LHA_RELEASE_SKILL_LIMIT")
        local hp = SL:GetValue("HP")
        local maxhp = SL:GetValue("MAXHP")
        if hp < maxhp * restoreValue / 100 then
            targetID = SL:GetValue("USER_ID")
            curSkillID = selfSkillID
        end
    end
    if not targetID then
        local teamSkillID = SL:GetValue("SETTING_TLHA_RELEASE_SKILL_ID")
        local teamID = SL:GetValue("TEAM_ID")
        if teamSkillID and teamSkillID > 0 and teamID > 0 then
            local restoreValue = SL:GetValue("SETTING_TLHA_RELEASE_SKILL_LIMIT")
            local members = SL:GetValue("TEAM_MEMBER_LIST")
            for _, member in ipairs(members) do
                local actorID = member.UserID
                local hp = SL:GetValue("ACTOR_HP", actorID)
                local maxhp = SL:GetValue("ACTOR_MAXHP", actorID)
                local isInView = SL:GetValue("ACTOR_IN_VIEW", actorID)
                if isInView and hp > 0 and hp < maxhp * restoreValue / 100 then
                    targetID = actorID
                    curSkillID = teamSkillID
                    break
                end
            end
        end
    end

    return curSkillID, targetID
end

function FGUIFunction:FindRobotAddStateSkill()
    local curSkillID = nil
    local targetID = SL:GetValue("USER_ID")
    --加状态
    local helpSkills = SL:GetValue("SETTING_FIGHT_HELP_SKILL_NORMALIZED")
    for _, skillID in ipairs(helpSkills) do
        if skillID ~= -1 then
            if FGUIFunction:CheckAbleToLaunch(skillID) == 1
                and SL:GetValue("SKILL_CHECK_IS_BUFF_MAGIC", skillID) then
                local buffIDS = SL:GetValue("SKILL_BUFFID_BY_ID", skillID)
                if buffIDS and #buffIDS > 0 then
                    for _, buffID in ipairs(buffIDS) do
                        if not SL:GetValue("ACTOR_HAS_ONE_BUFF", targetID, buffID) then
                            curSkillID = skillID
                            break
                        end
                    end

                    --给队友加
                    if not curSkillID
                        and SL:GetValue("ACTOR_TEAM_STATE", targetID)
                        and SL:GetValue("SKILL_CHECK_IS_FIND_FRIEND", skillID) then
                        local member = SL:GetValue("TEAM_MEMBER_LIST", targetID)
                        for k, v in pairs(member) do
                            if v.UserID and v.UserID ~= targetID then
                                for _, buffID in ipairs(buffIDS) do
                                    if SL:GetValue("ACTOR_IN_VIEW", v.UserID)
                                        and not SL:GetValue("ACTOR_HAS_ONE_BUFF", v.UserID, buffID) then
                                        curSkillID = skillID
                                        targetID = v.UserID
                                        break
                                    end
                                end
                            end
                            if curSkillID then
                                break
                            end
                        end
                    end
                end
            end
        end
        if curSkillID then
            break
        end
    end
    return curSkillID, targetID
end

function FGUIFunction:FindRobotLaunchSkill()
    local skillID, targetID
    repeat
        --恢复
        skillID, targetID = FGUIFunction:FindRobotRestoreSkill()
        if skillID and targetID then
            break
        end

        --buff
        skillID, targetID = FGUIFunction:FindRobotAddStateSkill()
        if skillID and targetID then
            break
        end
    until true

    local RJFirendAttackMode = SL:GetValue("GAME_DATA", "RJFirendAttackMode")
    if RJFirendAttackMode == 0 then
        if targetID and not FGUIFunction:CheckIsFriendByID(targetID) then
            return nil
        end
    end
    return skillID, targetID
end

function FGUIFunction:FindLockLaunchSkill()
    -- 只释放普攻
    local skillID = FGUIFunction:AutoGetRandomBaseSkillID()
    return skillID
end

--根据有无武器获取随机普攻技能id
function FGUIFunction:AutoGetRandomBaseSkillID()
    local equipPos = SL:GetValue("EQUIP_POS_BY_STDMODE", SLDefine.STDMODE_TYPE.WEAPON)
    local equipData = SL:GetValue("EQUIP_DATA_BY_POS", equipPos)
    local skills = nil
    if equipData then
        skills = SL:GetValue("SKILL_HAVE_WEAPON_BASIC")
    else
        skills = SL:GetValue("SKILL_NONE_WEAPON_BASIC")
    end

    return skills[math.random(#skills)]
end

-- 打开预加载界面
function FGUIFunction:OpenPreLoadPanel()
    if not FGUI:CheckOpen("PreLoad", "PreLoadPanel") then
        FGUI:Open("PreLoad", "PreLoadPanel")
    end
end

-- 关闭预加载界面
function FGUIFunction:ClosePreLoadPanel()
    if FGUI:CheckOpen("PreLoad", "PreLoadPanel") then
        FGUI:Close("PreLoad", "PreLoadPanel")
    end
end

-- 打开顶部货币列表
function FGUIFunction:ShowTopCurrency(idStr)
    if not TopCurrency then return end
    TopCurrency.Show(idStr)
end

-- 关闭顶部货币列表
function FGUIFunction:HideTopCurrency()
    if not TopCurrency then return end
    TopCurrency.Hide()
end

-- 打开背包拖拽校验页面
function FGUIFunction:OpenBagCheckDragView()
    PCBagOnDragDrop.Show()
end

-- 打开背包拖拽校验页面
function FGUIFunction:CloseBagCheckDragView()
    PCBagOnDragDrop.Hide()
end

-- 检测简易condition是否满足 格式: id 、[id] 、[id1]&[id2]|[id3]
function FGUIFunction:CheckSimpleCondition(simpleStr)
    if not simpleStr or simpleStr == "" then return true end
    local str = simpleStr
    if tonumber(simpleStr) then
        str = "[" .. simpleStr .. "]"
    end
    return SL:GetValue("CONDITION_BY_STRING", str)
end

local npcTalkDis
function FGUIFunction:CheckNpcTalkDistance(npcId)
    if not npcTalkDis then
        npcTalkDis = SL:GetValue("GAME_DATA", "NpcTalkBubble") or 3
    end
    local dis = SL:GetValue("TARGET_DISTANCE_FROM_ME", npcId)
    if dis <= npcTalkDis then
        return true
    end
    -- SL:ShowSystemTips()
    return false
end

--随机移动
function FGUIFunction:GetRandomMovePos()
    -- 找一个随机位置
    local range       = 0
    local sX          = mFloor(SL:GetValue("ACTOR_MAP_X"))
    local sY          = mFloor(SL:GetValue("ACTOR_MAP_Y"))
    local sZ          = mFloor(SL:GetValue("ACTOR_MAP_Z"))

    local mapWidth    = SL:GetValue("MAP_WIDTH")
    local mapHeight   = SL:GetValue("MAP_HEIGHT")
    local minR        = math.ceil(math.min(mapWidth, mapHeight) / 2) --取地图较小边的一半 防止地图过小 傻太久
    range             = math.min(50, minR)

    local randomCount = 5
    for i = 1, randomCount do
        local dX = mRandom(mFloor(sX - range), mFloor(sX + range))
        local dZ = mRandom(mFloor(sZ - range), mFloor(sZ + range))
        local dY = SL:GetValue("MAP_Y", dX, dZ)
        if dY > sY + 2 then
            dY = sY
        end
        if (mAbs(dX - sX) >= 7 or mAbs(dZ - sZ) >= 7) then
            local isBlock = SL:GetValue("MAP_IS_BLOCK", dX, dY, dZ)
            if not isBlock then
                return dX, dY, dZ
            end
        end
    end
    return nil
end

function FGUIFunction:GetFaceIDBySex(sex, classConfig)
    if not sex or not classConfig then
        SL:printEx("参数为空")
        return
    end

    if not classConfig.InitModel or not classConfig.InitModel[4] or not classConfig.InitModel[5] then
        SL:printEx("classConfig.InitModel或classConfig.InitModel[4]或classConfig.InitModel[5]为空")
        return
    end

    return (sex == global.MMO.ACTOR_PLAYER_SEX_M) and classConfig.InitModel[4] or classConfig.InitModel[5]
end

-- 施法前 目标检测和选择  返回值是否检测通过
function FGUIFunction:CheckOrFindTarget(skillID, launchType)
    local userRange   = SL:GetValue("SKILL_FIND_TARGET_DISTANCE", skillID)
    local systemRange = SL:GetValue("GAME_DATA", "LAUNCH_TARGET_RANGE_SYSTEM")
    local findRange   = launchType == SLDefine.LAUNCH_TYPE.USER and userRange or systemRange

    if SL:GetValue("SKILL_IS_NEED_FIND_TARGET", skillID) then
        local isFriendSkill = SL:GetValue("SKILL_CHECK_IS_FIND_FRIEND", skillID)
        -- auto select monster
        if not SL:GetValue("SELECT_TARGET_ID") then
            if isFriendSkill then
                local selfID = SL:GetValue("USER_ID")
                SL:SetValue("SELECT_TARGET_ID", selfID, SLDefine.SELECT_TARGET.SYSTEM)
            else
                AutoFindTarget:FindTarget(findRange, isFriendSkill)
                -- auto select player
                if not SL:GetValue("SELECT_TARGET_ID") then
                    SL:ChangeSelectTarget(global.MMO.ACTOR_PLAYER, findRange, false, false)
                end
                if not SL:GetValue("SELECT_TARGET_ID") then
                    SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10002003))
                    return false
                end
            end
        else
            if isFriendSkill then
                local pkMode = SL:GetValue("PKMODE")
                if pkMode == SLDefine.PKMODE.ALL then --全体
                    --全体不管敌方友方
                else
                    local RJFirendAttackMode = SL:GetValue("GAME_DATA", "RJFirendAttackMode")
                    if RJFirendAttackMode == 0 then
                        if not FGUIFunction:CheckIsFriendByID(SL:GetValue("SELECT_TARGET_ID")) then
                            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10002005))
                            return false
                        end
                    else
                        return true
                    end
                end
            else
                -- 不可攻击
                local canAttack, errCode = SL:GetValue("TARGET_ATTACK_ENABLE", SL:GetValue("SELECT_TARGET_ID"))
                if not canAttack then
                    if errCode == SLDefine.ATTACK_TARGET_ERROR_CODE.IN_SAFE_ZONE then
                        SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10002007))
                    elseif errCode == SLDefine.ATTACK_TARGET_ERROR_CODE.NOT_ENEMY then
                        local pkMode = SL:GetValue("PKMODE")
                        if pkMode == SLDefine.PKMODE.PEACE then --和平
                            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10002008))
                        else                                    --友方不可攻击
                            SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10002009))
                        end
                    elseif errCode == global.MMO.ATTACK_TARGET_FIND_TARGET_MODE_ERROR then --选目标模式错误
                        SL:SetValue("SELECT_TARGET_ID", nil)
                    end
                    return false
                end
            end
            -- 距离太远
            local targetID = SL:GetValue("SELECT_TARGET_ID")
            if targetID and findRange then
                if SL:GetValue("TARGET_DISTANCE_FROM_ME", targetID) > findRange then
                    SL:ShowSystemTips(SL:GetValue("I18N_STRING", 10002006))
                    return false
                end
            end
        end
    end

    return true
end

function FGUIFunction:AutoMove(mapID, x, y, route)
    route = tonumber(route)
    if route then
        SL:RegisterLUAEvent(LUA_EVENT_AUTO_MOVE_END, "FGUIFunction_AutoMove", function()
            SL:UnRegisterLUAEvent(LUA_EVENT_AUTO_MOVE_END, "FGUIFunction_AutoMove")
            --检查走到目标点后切换分线
            local curX, curZ = SL:GetValue("X"), SL:GetValue("Z")
            if math.abs(x - curX) <= 1 and math.abs(y - curZ) <= 1 then
                local curRoute = SL:GetValue("MAP_ROUTE_IDX")
                if curRoute ~= route then
                    SL:RequestMapRouteSwitch(route)
                end
            end
        end)
    end
    SL:SetValue("BATTLE_AUTO_MOVE_BEGIN", mapID, x, y)
end

local _guideData = {}
-- 注册用于引导的节点或数据(Txt引导使用)
function FGUIFunction:RegisterGuideData(key, data)
    _guideData[key] = data
end

function FGUIFunction:UnRegisterGuideData(key)
    _guideData[key] = nil
end

function FGUIFunction:GetGuideData(key)
    return _guideData[key]
end

function FGUIFunction:LaunchSkill(skillId)
    if not skillId then return end
    local isNormal = SL:GetValue("SKILL_CHECK_IS_ATTACK", skillId)
    if isNormal then
        skillId = FGUIFunction:AutoGetRandomBaseSkillID()
    end

    local scriptSkillID = SL:GetValue("SKILL_SCRIPT_REPLACE_ID", skillId)
    if scriptSkillID then
        if self:CheckLaunchSkill(scriptSkillID, false) then
            skillId = scriptSkillID
        end
    end

    if not self:CheckLaunchSkill(skillId, true) then
        return
    end
    SL:RequestLaunchSkill(skillId)
end

--限制3s内不再提示
local skillTipTimer1 = nil
local skillTipTimer2 = nil
local skillTipTimer3 = nil
local function clearSkillTipCD1()
    skillTipTimer1 = nil
end
local function clearSkillTipCD2()
    skillTipTimer2 = nil
end
local function clearSkillTipCD3()
    skillTipTimer3 = nil
end
function FGUIFunction:CheckLaunchSkill(skillId, tips)
    if not FGUIFunction:CheckSkillWearWeapon(skillId) then
        if tips then
            if not skillTipTimer1 then
                SL:AddChatMsg(SLDefine.CHAT_CHANNEL.System, SL:GetValue("I18N_STRING", 10002011))
                skillTipTimer1 = SL:ScheduleOnce(clearSkillTipCD1, 3)
            end
        end
        return false
    end

    if not FGUIFunction:CheckSkillEnoughArrow(skillId) then
        if tips then
            if not skillTipTimer2 then
                SL:AddChatMsg(SLDefine.CHAT_CHANNEL.System, SL:GetValue("I18N_STRING", 10002010))
                skillTipTimer2 = SL:ScheduleOnce(clearSkillTipCD2, 3)
            end
        end
        return false
    end

    if not FGUIFunction:CheckSkillEnoughMP(skillId) then
        if tips then
            if not skillTipTimer3 then
                SL:AddChatMsg(SLDefine.CHAT_CHANNEL.System, SL:GetValue("I18N_STRING", 10002002))
                skillTipTimer3 = SL:ScheduleOnce(clearSkillTipCD3, 3)
            end
        end
        return false
    end
    return true
end

-- 设置窗口可以被拖动，可传入可拖动区域
function FGUIFunction:setWindowDrag(component, dragArea)
    if dragArea == nil then
        local onDragStart = function(context)
            -- 拖动界面设置为顶部显示
            FGUI:setSortingOrder(component, 1)
            FGUI:setSortingOrder(component, 0)
        end
        FGUI:setDragable(component, true)
        FGUI:setOnDragStartEvent(component, onDragStart)
    else
        local onDragStart = function(context)
            -- 取消源拖动，防止dragArea本身被拖动
            FGUI:EventContext_preventDefault(context)
            FGUI:StartDrag(component, FGUI:InputEvent_getTouchId(context))
            -- 拖动界面设置为顶部显示
            FGUI:setSortingOrder(component, 1)
            FGUI:setSortingOrder(component, 0)
        end
        FGUI:setDragable(dragArea, true)
        FGUI:setOnDragStartEvent(dragArea, onDragStart)
    end
end

function FGUIFunction:SwitchPanel(packageName, componentName, initData, layer, ext)
    if FGUI:CheckOpen(packageName, componentName) then
        FGUI:Close(packageName, componentName)
    else
        FGUI:Open(packageName, componentName, initData, layer, ext)
    end
end

-- 通过服务器名字(kxxx_name)获取区服名字([xxx服]name)
local kuaFuName, kuaFuColor = nil, nil
function FGUIFunction:GetServerName(serverNameStr, nameColor)
    if not kuaFuColor then
        kuaFuColor = "#FFFFFF"
        local KuafuPrefix = SL:GetValue("GAME_DATA", "KuafuPrefix_UI")
        if KuafuPrefix and KuafuPrefix ~= "" then
            local strs = string.split(KuafuPrefix, "#")
            kuaFuColor = "#" .. strs[1]
            kuaFuName = strs[2]
            if kuaFuName == "" then kuaFuName = nil end
        end
    end
    local name = nil
    local serverName = kuaFuName
    local serverNames = string.split(serverNameStr, "_")
    local nameStr2 = serverNames[2]
    if nameStr2 then
        name = nameStr2
        local serverStr = serverNames[1]
        local serverId = stringUTF8Sub(serverStr, 2)
        if SL:GetValue("SERVER_ID") == serverId then
            --同区不显示前缀
            if nameColor then
                return string.format("[color=%s]%s[/color]", nameColor, name)
            else
                return name
            end
        end
        if not kuaFuName then
            serverName = SL:GetValue("SERVER_NAME_BY_ID", serverId)
            if serverName == "" then
                serverName = serverStr
            end
            serverName = string.format("[%s]", serverName)
        end
        if nameColor then
            return string.format("[color=%s]%s[/color][color=%s]%s[/color]", kuaFuColor, serverName, nameColor, name)
        else
            return string.format("[color=%s]%s[/color]%s", kuaFuColor, serverName, name)
        end
    else
        if nameColor then
            return string.format("[color=%s]%s[/color]", nameColor, serverNameStr)
        else
            return serverNameStr
        end
    end
end

-- 通过服务器名字kxxx_name/狂牛(kxxx_name)获取区服名字和前缀用于hud 返回 名字， 类型 ，前缀/图标， 颜色/偏移x ，偏移Y
local hudType, hudKuaFuName, hudKuaFuColor, hudKuaFuIconOffsetX, hudKuaFuIconOffsetY = nil, nil, nil, nil, nil
function FGUIFunction:GetHudServerName(serverNameStr, actorID)
    --1类型是前缀  2 图片
    if not hudType then
        local KuafuPrefix = SL:GetValue("GAME_DATA", "KuafuPrefix")
        if KuafuPrefix and KuafuPrefix ~= "" then
            local strs = string.split(KuafuPrefix, "#")
            hudType = strs[1]
            hudKuaFuName = strs[2]
            if hudType == "" then hudType = "1" end
            if hudType == "1" then
                local hudKuaFuColorHex = "#" .. (strs[3] or "FFFFFF")
                hudKuaFuColor = SL:ConvertHexStrToColor(hudKuaFuColorHex)
            end
            if hudKuaFuName == "" then hudKuaFuName = nil end

            if hudType == "2" and not hudKuaFuName then hudType = "1" end

            if hudType == "2" then
                hudKuaFuIconOffsetX = tonumber(strs[3]) or 0
                hudKuaFuIconOffsetY = tonumber(strs[4]) or 0
                hudKuaFuIconOffsetX = hudKuaFuIconOffsetX * 0.01
                hudKuaFuIconOffsetY = hudKuaFuIconOffsetY * 0.01
            end
        end
    end
    local mainPlayerMainServerID = SL:GetValue("ACTOR_MAIN_SERVER_ID")
    local actorMainServerID = SL:GetValue("ACTOR_MAIN_SERVER_ID", actorID)
    local isSameMainServer = false
    if mainPlayerMainServerID == actorMainServerID then
        isSameMainServer = true
    end
    local getKuaFuParam = function(serverStr, name)
        if isSameMainServer then
            --同主服不显示前缀
            return name
        end
        local param3 = hudType == "2" and hudKuaFuIconOffsetX or (hudKuaFuColor or Color.white)
        return name, tonumber(hudType) or 1, hudKuaFuName or serverStr, param3, hudKuaFuIconOffsetY
    end
    if hudType then --有配置
        local name1, serverStr, name3 = string.match(serverNameStr, "(.*%()(.*)_(.*)")
        if name1 then
            local name = name1 .. name3
            return getKuaFuParam(serverStr, name)
        else
            local serverNames = string.split(serverNameStr, "_")
            local nameStr2 = serverNames[2]
            if nameStr2 then
                name1 = nameStr2
                serverStr = serverNames[1]
                return getKuaFuParam(serverStr, name1)
            else
                return serverNameStr
            end
        end
    else --无配置
        if isSameMainServer then
            local name1, serverStr, name3 = string.match(serverNameStr, "(.*%()(.*)_(.*)")
            if name1 then
                local name = name1 .. name3
                return name
            else
                local serverNames = string.split(serverNameStr, "_")
                local nameStr2 = serverNames[2]
                if nameStr2 then
                    return nameStr2
                else
                    return serverNameStr
                end
            end
        else
            return serverNameStr
        end
    end
end

function FGUIFunction:FormatFeatureAndCustomStr(serverStr)
    local res = {}
    if string.isNullOrEmpty(serverStr) then
        return res
    end

    local tFeathure = string.split(serverStr, "|")
    local feathure = {}
    local extFeathure = {}
    local customFeathure = {}
    local index = 0
    local tData = string.split(tFeathure[1], ",")
    for k = 1, #tData do
        feathure[index] = tonumber(tData[k])
        index = index + 1
    end

    index = 0
    tData = string.split(tFeathure[2], ",")
    for k = 1, #tData do
        extFeathure[index] = tonumber(tData[k])
        index = index + 1
    end
    if tFeathure[3] then
        index = 0
        tData = string.split(tFeathure[3], ",")
        customFeathure.chatFrame = tonumber(tData[1] or "0")
        customFeathure.avatar = tonumber(tData[2] or "0")
        customFeathure.avatarFrame = tonumber(tData[3] or "0")
    end

    local function ZeroToNil(num)
        if num == 0 then
            return nil
        end
        return num
    end

    res.bodyId = ZeroToNil(tonumber(feathure[global.MMO.APPEAR_TYPE_CLOTH]))
    res.rWeapon = ZeroToNil(tonumber(feathure[global.MMO.APPEAR_TYPE_WEAPON]))
    res.wingId = ZeroToNil(tonumber(feathure[global.MMO.APPEAR_TYPE_WINGS]))
    res.headId = ZeroToNil(tonumber(feathure[global.MMO.APPEAR_TYPE_HEAD]))
    res.faceId = ZeroToNil(tonumber(feathure[global.MMO.APPEAR_TYPE_FACE]))

    res.leftFxId = ZeroToNil(tonumber(extFeathure[global.MMO.EXT_APPEAR_TYPE_LFX]))
    res.rightFxId = ZeroToNil(tonumber(extFeathure[global.MMO.EXT_APPEAR_TYPE_RFX]))
    res.chestFxId = ZeroToNil(tonumber(extFeathure[global.MMO.EXT_APPEAR_TYPE_CHEST_FX]))
    res.headFxId = ZeroToNil(tonumber(extFeathure[global.MMO.EXT_APPEAR_TYPE_HEAD_FX]))
    res.wingFxId = ZeroToNil(tonumber(extFeathure[global.MMO.EXT_APPEAR_TYPE_WING_FX]))

    res.helmetColor = ZeroToNil(tonumber(extFeathure[global.MMO.EXT_APPEAR_TYPE_HELMET_COLOR]))
    return res
end

function FGUIFunction:LookRankPlayerInfo(data)
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("FuncDock_pc", "PCFuncDockNewTip", data)
    else
        FGUI:Open("FuncDock", "FuncDockNewTip", data)
    end
    FuncDock.setOpenData(nil)
end

function FGUIFunction:RequestPlayerDataAndSetTipType(data)
    if not data or not next(data) then
        return
    end

    if data.targetId and data.TipsType then
        FuncDock.setOpenData(data)
        SL:RequestQueryPlayerInfoNew(data.targetId)
    end
end

-- 快捷使用Tips
function FGUIFunction:OpenQuickUseTips(data)
    local isOpen = SL:GetValue("GAME_DATA", "QuickUseTipsShow") == 1

    if not isOpen then
        return
    end

    -- 总开关 所有重复显示
    local repeatSwitch = SL:GetValue("SETTING_QUICKWINDOW_NOT_REPEATED_SHOW")
    if repeatSwitch then
        local isSaved = FGUIFunction:GetAllQuickUseItemShow(data.ID)
        if isSaved then
            return
        end
        FGUIFunction:SetAllQuickUseItemShow(data.ID, true)
    else
        -- 开关 单个物品重复显示
        local isSaved = FGUIFunction:GetQuickUseItemShow(data.ID)
        if isSaved then
            return
        end
    end

    local ItemUseProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemUseProxy)
    local isUseCd = ItemUseProxy:CheckIsCD(data.Index)
    if isUseCd then
        return
    end

    local BuffProxy = global.Facade:retrieveProxy(global.ProxyTable.BuffProxy)
    local isForbidUse = BuffProxy:CheckForbidUseItem(data.Index)
    if isForbidUse then
        return
    end

    local itemConfig = SL:GetValue("ITEM_DATA", data.Index)
    if not itemConfig then
        return
    end

    if itemConfig.ConditionId then
        if not FGUIFunction:CheckSimpleCondition(itemConfig.ConditionId) then
            return
        end
    end

    local isPC = SL:GetValue("IS_PC_OPER_MODE")

    -- 是否装备类型
    local isEquip = SL:GetValue("ITEMTYPE", data) == SL:GetValue("ITEMTYPE_ENUM").Equip
    if not isEquip then
        local canUse = ItemUtil:CheckItemCanUse(data)
        if not canUse then
            return
        end
        local config = SL:GetValue("ITEM_DATA", data.Index)
        if config.QuickUse == 1 then
            if isPC then
                FGUI:Open("QuickUseTips_pc", "PCQuickUseTips", data, FGUI_LAYER.NORMAL)
            else
                FGUI:Open("QuickUseTips", "QuickUseTips", data, FGUI_LAYER.NORMAL)
            end
        end
    else
        local isGood = FGUIFunction:CompareEquipOnBody(data)
        if isGood then
            if isPC then
                FGUI:Open("QuickUseTips_pc", "PCQuickUseTips", data, FGUI_LAYER.NORMAL)
            else
                FGUI:Open("QuickUseTips", "QuickUseTips", data, FGUI_LAYER.NORMAL)
            end
        end
    end
end

-- 快捷使用 检测背包
function FGUIFunction:CheckBagQuickUse(data)
    local param1, param2, param3 = FGUIFunction:CompareEquipUpShowOnBody(data)
    -- print("检测背包", param1, param2, param3)
    if param1 == true then     -- 变绿色 才检测
        FGUIFunction:OpenQuickUseTips(data)
    end
    -- local bagData = SL:GetValue("BAG_DATA")
    -- for _, data in pairs(bagData) do
    --     SL:dump(data, "背包数据")
    --     local param1,param2,param3 = FGUIFunction:CompareEquipUpShowOnBody(data)
    --     if param1 == true then -- 变绿色 才检测
    --         FGUIFunction:OpenQuickUseTips(data)
    --     end
    -- end
end

-- 单个物品 不再重复
local itemShow = {}
function FGUIFunction:SetQuickUseItemShow(itemID, bShow)
    if not itemID then return end
    itemShow[tostring(itemID)] = bShow
    SET_CLOUD_STORAGE_DATA("QUICK_USE_ITEMS_SHOW", itemShow)
end

function FGUIFunction:GetQuickUseItemShow(itemID)
    if not itemID then return end
    local items = GET_CLOUD_STORAGE_DATA("QUICK_USE_ITEMS_SHOW")
    if items and items[tostring(itemID)] then
        return true
    end

    return false
end

-- 所有物品 不再重复
local itemAllShow = {}
function FGUIFunction:SetAllQuickUseItemShow(itemID, bShow)
    if not itemID then return end
    itemAllShow[tostring(itemID)] = bShow
    SET_CLOUD_STORAGE_DATA("ALL_QUICK_USE_ITEMS_SHOW", itemAllShow)
end

function FGUIFunction:GetAllQuickUseItemShow(itemID)
    if not itemID then return end
    local items = GET_CLOUD_STORAGE_DATA("ALL_QUICK_USE_ITEMS_SHOW")
    if items and items[tostring(itemID)] then
        return true
    end

    return false
end

--打开技能提示
-- ext:扩展参数 (posX=nil, posY=nil, anchorX=0, anchorY=0, callBack=nil, showBtn=false)
function FGUIFunction:ShowSkillTip(SkillID, SkillLevel, ext)
    local data = ext or {}
    data.id = SkillID
    data.level = SkillLevel
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Open("Common_pc", "PCSkillTip", data, FGUI_LAYER.NOTICE,
            { classPath = "FGUILayout/Common/SkillTip", fullScreen = false })
    else
        FGUI:Open("Common", "SkillTip", data)
    end
end

--关闭技能提示
function FGUIFunction:HideSkillTip()
    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:Close("Common_pc", "PCSkillTip")
    else
        FGUI:Close("Common", "SkillTip")
    end
end

--设置节点坐标,始终全部显示在屏幕内
-- safeArea: 是否考虑安全距离(刘海屏等适配相关)
function FGUIFunction:SetSafePosition(widget, x, y, safeArea)
    local parent = FGUI:GetParent(widget)
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local lx, ty, rx, by = 0, 0, screenW, screenH
    if safeArea then
        local safeL, safeR, safeB, safeT = SL:GetValue("SCREEN_SAFE_AREA_RATIO")
        lx = lx + safeL
        rx = rx - safeR
    end
    lx, ty = FGUI:WorldToLocal(parent, lx, ty, true)
    rx, by = FGUI:WorldToLocal(parent, rx, by, true)
    local minX, minY, maxX, maxY
    local w, h = FGUI:getSize(widget)
    local asAnchor = FGUI:getAsAnchor(widget)
    if asAnchor then
        local anchorX, anchorY = FGUI:getAnchorPoint(widget)
        minX = x - anchorX * w
        minY = y - anchorY * h
    else
        minX, minY = x, y
    end
    maxX = minX + w
    maxY = minY + h
    if minX < lx then
        x = x - (minX - lx)
    elseif maxX > rx then
        x = x - (maxX - rx)
    end
    if minY < ty then
        y = y - (minY - ty)
    elseif maxY > by then
        y = y - (maxY - by)
    end
    FGUI:setPosition(widget, x, y)
end

-- func(itemID)必须得调用不然掉落物不消失
function FGUIFunction:ShowDropItemFlyAnimation(itemID, masterID, func)
    local x = SL:GetValue("ACTOR_POSITION_X", masterID)
    local y = SL:GetValue("ACTOR_POSITION_Y", masterID)
    local z = SL:GetValue("ACTOR_POSITION_Z", masterID)
    local itemX = SL:GetValue("ACTOR_POSITION_X", itemID)
    local itemY = SL:GetValue("ACTOR_POSITION_Y", itemID)
    local itemZ = SL:GetValue("ACTOR_POSITION_Z", itemID)
    local durX = x - itemX
    local durY = y - itemY
    local durZ = z - itemZ
    local flyActionTime = 0
    local flyAction = nil
    flyAction = SL:Schedule(function(dt)
        flyActionTime = flyActionTime + dt
        if flyActionTime <= 0.3 then
            local scale = 1 + flyActionTime
            SL:SetValue("DROPITEM_SCALE", itemID, scale, scale, scale)
        elseif flyActionTime <= 0.8 then
        elseif flyActionTime <= 1.3 then
            local percent = (flyActionTime - 0.8) / 0.5
            local scale = 1.3 - percent * 1.2
            SL:SetValue("DROPITEM_SCALE", itemID, scale, scale, scale)
            local xx = itemX + durX * percent
            local yy = itemY + durY * percent
            local zz = itemZ + durZ * percent
            SL:SetValue("DROPITEM_POSITION", itemID, xx, yy, zz)
        else
            func(itemID)
            SL:UnSchedule(flyAction)
        end
    end, 0)
end
