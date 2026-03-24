mountMain = {}
local filname = "mountMain"
local mountlist = require("Envir/QuestDiary/game_config/cfgcsv/Mount.lua")
local mountHHlist = require(
                        "Envir/QuestDiary/game_config/cfgcsv/MountHuanHua.lua")
local SpiritualBeast = require(
                           "Envir/QuestDiary/game_config/cfgcsv/SpiritualBeast.lua")
local SysConstant = require(
                        "Envir/QuestDiary/game_config/cfgcsv/SysConstant.lua")

local PetAddRateConfig = {}
for i, v in pairs(SpiritualBeast) do
    if v.Actor_Attr and v.Exp_Attr then
        PetAddRateConfig[v.ID] = {attrRate = v.Actor_Attr, expRate = v.Exp_Attr}
    end
end

-- 灵兽额外加成比例(出战灵兽)
local PetExtraRate = {attrRate = 0.03}

-- 灵兽buff配置
local PetBuffId = 110044

-- 经验加成属性ID(万分比,10000=100%)
local ExpAttrId = 12

-- 更新灵兽属性加成到人物
function mountMain.updatePetAttrBuff(actor)
    local allPets = gethumvar(actor, VarCfg.T_Pets)
    if allPets == "" or not allPets then
        delbuff(actor, PetBuffId)
        return
    end

    allPets = json2tbl(allPets)

    -- 计算所有已激活灵兽的属性总和
    local totalAttr = {}
    local totalExpRate = 0

    -- 当前出战的灵兽ID
    local takeBaseId = gethumvar(actor, VarCfg.U_PETS_Take_Base) or 0

    for petId, level in pairs(allPets) do
        -- 查找对应的灵兽数据(根据名称找到本体或幻化)
        local petData = nil
        for k, v in pairs(SpiritualBeast) do
            if v.Pet_Name == petId then
                petData = v
                break
            end
        end

        if petData and level > 0 then
            -- 获取该灵兽的当前属性
            local petAttr = mountMain.getSinglePetAttr(petData, level)
            local rateConfig = PetAddRateConfig[petData.ID] or
                                   {attrRate = 0.02, expRate = 0.02}

            -- 计算属性加成比例
            local attrRate = rateConfig.attrRate

            -- 如果是当前出战的灵兽,增加额外加成
            if tonumber(takeBaseId) == petData.ID then
                attrRate = attrRate + PetExtraRate.attrRate
            end

            -- 累加属性加成到总和
            for attrId, attrValue in pairs(petAttr) do
                if attrId ~= "icon" then
                    if totalAttr[attrId] then
                        totalAttr[attrId] =
                            totalAttr[attrId] + attrValue * attrRate
                    else
                        totalAttr[attrId] = attrValue * attrRate
                    end
                end
            end

            -- 累加经验加成(万分比)
            totalExpRate = totalExpRate + rateConfig.expRate * 10000
        end
    end

    -- 如果有灵兽属性,添加buff
    if next(totalAttr) ~= nil or totalExpRate > 0 then
        -- 先确保buff存在
        if not hasbuff(actor, PetBuffId) then addbuff(actor, PetBuffId) end
        -- 添加经验加成属性到属性表
        if totalExpRate > 0 then
            totalAttr[ExpAttrId] = math.ceil(totalExpRate)
        end
        -- 应用所有属性到buff(包括经验加成)
        for attrId, attrValue in pairs(totalAttr) do
            setbuffabil(actor, PetBuffId, tonumber(attrId), "=",
                        math.ceil(attrValue))
        end
    else
        delbuff(actor, PetBuffId)
    end
end

-- 获取单个灵兽的属性(不含幻化加成)
function mountMain.getSinglePetAttr(petData, level)
    local result = {}

    if tonumber(petData.Pet_Type) == 1 then
        -- 本体属性
        for i = 1, #petData.BasePet_ProType do
            local proType = petData.BasePet_ProType[i]
            local proNum = petData.BasePet_ProNum[i]
            local growRatio = petData.BasePet_GrowRatio[level] or 0

            local attrValue = proNum + proNum * growRatio

            if result[proType] then
                result[proType] = result[proType] + attrValue
            else
                result[proType] = attrValue
            end
        end
    elseif tonumber(petData.Pet_Type) == 2 then
        -- 幻化激活属性
        for i = 1, #petData.CoverPet_ActiveProType do
            local proType = petData.CoverPet_ActiveProType[i]
            local proNum = petData.CoverPet_ActiveProNum[i]

            if result[proType] then
                result[proType] = result[proType] + proNum
            else
                result[proType] = proNum
            end
        end
    end

    return result
end

--应用灵兽出战技能
--根据灵兽等级(1级、30级、70级)应用技能一(属性附加)和技能二(技能ID)
function mountMain.applyPetBattleSkills(actor, petId, petLevel)
    --查找灵兽数据
    local petData = nil
    for k, v in pairs(SpiritualBeast) do
        if v.ID == petId then
            petData = v
            break
        end
    end

    if not petData then
        return
    end

    --确定技能等级
    local skillLevel = 0
    if petLevel >= 70 then
        skillLevel = 3
    elseif petLevel >= 30 then
        skillLevel = 2
    elseif petLevel >= 1 then
        skillLevel = 1
    end

    if skillLevel == 0 then
        return
    end

    --应用技能一:属性附加(出战即附加给人物)
    local attrTypeField = "BattleSkill1_Level" .. skillLevel .. "_AttrType"
    local attrValueField = "BattleSkill1_Level" .. skillLevel .. "_AttrValue"

    if petData[attrTypeField] and petData[attrValueField] then
        local attrTypes = petData[attrTypeField]
        local attrValues = petData[attrValueField]

        for i = 1, #attrTypes do
            local attrId = tonumber(attrTypes[i])
            local attrValue = tonumber(attrValues[i])
            if attrId and attrValue then
                --通过110044 buff附加属性
                setbuffabil(actor, PetBuffId, attrId, "=", attrValue)
            end
        end
    end

    --应用技能二:技能ID给人物
    local skillIdField = "BattleSkill2_Level" .. skillLevel .. "_ID"
    if petData[skillIdField] and petData[skillIdField] ~= "" then
        local skillId = petData[skillIdField]
        --TODO: 这里需要根据实际系统实现技能ID的应用方式
        --例如: addskill(actor, skillId) 或其他技能系统API
        --临时方案: 可以将技能ID存储到玩家变量中,由技能系统读取
        --sethumvar(actor, "U_PetBattleSkillID", skillId)
    end
end

--清除灵兽出战技能效果
function mountMain.clearPetBattleSkills(actor)
    --清除技能ID
    --sethumvar(actor, "U_PetBattleSkillID", "")

    --技能一的属性通过110044 buff管理,在updatePetAttrBuff中会重新计算
    --这里不需要单独清除,因为收回时会重新计算buff
end

function mountMain.openshow(actor, data)
    Message.sendmsgEx(actor, "mountMain", "Open", {})
end
-- 更新坐骑增加属性
function mountMain.addsx(actor)
    -- 坐骑星星属性
    local allstar = gethumvar(actor, VarCfg.U_All_Mount_star)
    local zqzsz = {}
    local classIds = mountlist[allstar].ClassID
    for b = 1, #classIds do
        setbuffabil(actor, 110015, tonumber(classIds[b][1]), "=",
                    tonumber(classIds[b][2]))
    end
    -- 坐骑幻化属性
    local ycList = json2tbl(gethumvar(actor, VarCfg.T_MountHuanHua))
    local hhsxListStr = {}
    for l, v in pairs(ycList) do
        if l then
            local jhhhlist = {}
            for e = 1, #mountHHlist do
                if mountHHlist[e].Name == l and mountHHlist[e].grade == v then
                    jhhhlist[#jhhhlist + 1] = mountHHlist[e]
                end
            end
            for r = 1, #jhhhlist do
                local classIds = jhhhlist[r].ClassID
                for b = 1, #classIds do
                    if hhsxListStr[classIds[b][1]] then
                        hhsxListStr[classIds[b][1]] =
                            hhsxListStr[classIds[b][1]] + classIds[b][2]
                    else
                        hhsxListStr[classIds[b][1]] = classIds[b][2]
                    end
                end
            end
        end
    end
    for g, h in pairs(hhsxListStr) do
        setbuffabil(actor, 110016, tonumber(g), "=", tonumber(h))
    end
end
function mountMain.shengji(actor)
    local nowlv = gethumvar(actor, VarCfg.U_All_Mount_star)
    local nextlv = nowlv + 1
    if nextlv > #mountlist then return end
    local classIds = mountlist[nextlv].ClassID
    local costs = mountlist[nowlv].Cost
    local itemId = tonumber(costs[1])
    local num = tonumber(costs[2])
    if bagitemcount(actor, itemId) < num then
        sendmsg(actor, 9, "材料不足" .. num .. "个")
    else
        if nowlv == 0 then -- 激活
            sethumvar(actor, VarCfg.T_MountHuanHua, tbl2json({}))
            sethumvar(actor, VarCfg.U_All_Mount_star, 1)
            sethumvar(actor, VarCfg.U_Mount_IS_SET, 1)
        end
        for b = 1, #classIds do
            setbuffabil(actor, 110015, tonumber(classIds[b][1]), "=",
                        tonumber(classIds[b][2]))
        end
        delItemNum(actor, itemId, num)
        sethumvar(actor, VarCfg.U_All_Mount_star, nextlv)
        local mountBaseId = mountlist[nextlv].Model
        -- 当前模型是否幻化
        if gethumvar(actor, VarCfg.U_Mount_IS_HH) == 0 then
            changeappear(actor, 5, mountBaseId)
            sethumvar(actor, VarCfg.U_Mount_Take_Id, mountBaseId)
        end
        sethumvar(actor, VarCfg.U_Mount_Base_ID, mountBaseId)
        Message.sendmsgEx(actor, "mountMain", "updateZQ",
                          {lv = nextlv, mountBaseId = mountBaseId})
        MentorShipChangTask(actor, 6, 1, nextlv)
    end
end

function getHHData(idx, grade)
    local name = mountHHlist[idx].Name
    local data = nil
    for i = 1, #mountHHlist do
        if mountHHlist[i].Name == name and tonumber(mountHHlist[i].grade) ==
            tonumber(grade) then
            data = mountHHlist[i]
            break
        end
    end
    return data
end

function mountMain.huanhuajihuo(actor, postData)
    local data = getHHData(postData.idx, postData.grade)
    if data then
        local name = data.Name -- 名字
        local classid = data.ClassID -- 属性
        local costs = data.Cost -- 消耗
        local grade = data.grade -- 激活的阶数
        local itemId = tonumber(costs[1])
        local num = tonumber(costs[2])
        if getItemNum(actor, itemId) < num then
            sendmsg(actor, 9, "激活材料不足" .. num .. "个")
        else
            local ycList = json2tbl(gethumvar(actor, VarCfg.T_MountHuanHua))
            delItemNum(actor, itemId, num)
            ycList[data.Name] = grade
            sethumvar(actor, VarCfg.T_MountHuanHua, tbl2json(ycList))
            local hhsxListStr = {}
            local mountHHid = gethumvar(actor, VarCfg.U_Mount_Take_Id)
            -- 升级前的幻化模型id
            if gethumvar(actor, VarCfg.U_Mount_IS_HH) == 1 then
                -- 当前已经幻化了
                -- 升级幻化之前外型是否当前外型
                local oldHHModelId = 0
                local newHHModelId = 0
                for i = 1, #mountHHlist do
                    if mountHHlist[i].Name == name and mountHHlist[i].grade ==
                        grade - 1 then
                        oldHHModelId = mountHHlist[i].Model
                    end
                    if mountHHlist[i].Name == name and mountHHlist[i].grade ==
                        grade then
                        newHHModelId = mountHHlist[i].Model
                    end
                end
                if tonumber(oldHHModelId) == mountHHid then
                    -- 是
                    mountHHid = newHHModelId
                    sethumvar(actor, VarCfg.U_Mount_Take_Id, newHHModelId)
                    changeappear(actor, 5, newHHModelId)
                end
            end
            for l, v in pairs(ycList) do
                if l then
                    local jhhhlist = {}
                    for e = 1, #mountHHlist do
                        if mountHHlist[e].Name == l and mountHHlist[e].grade ==
                            v then
                            jhhhlist[#jhhhlist + 1] = mountHHlist[e]
                        end
                    end
                    for r = 1, #jhhhlist do
                        local classIds = jhhhlist[r].ClassID
                        for b = 1, #classIds do
                            if hhsxListStr[classIds[b][1]] then
                                hhsxListStr[classIds[b][1]] =
                                    hhsxListStr[classIds[b][1]] + classIds[b][2]
                            else
                                hhsxListStr[classIds[b][1]] = classIds[b][2]
                            end
                        end
                    end
                end
            end
            for g, h in pairs(hhsxListStr) do
                setbuffabil(actor, 110016, tonumber(g), "=", tonumber(h))
            end
            Message.sendmsgEx(actor, "mountMain", "updateHHmodel", {
                ycList = ycList,
                name = name,
                grade = grade,
                mountHHid = mountHHid
            })
        end
    else
        sendmsg(actor, 9, "激活失败")
    end
end
-- 先删除旧的幻化buff
function mountMain.setMountHHBuff(actor, oldbuffList, newBuffList, isCancel)
    if tonumber(isCancel) == 0 then
        for b = 1, #oldbuffList do delbuff(actor, oldbuffList[b]) end
        for c = 1, #newBuffList do addbuff(actor, newBuffList[c]) end
    else
        -- 取消幻化
        for b = 1, #oldbuffList do delbuff(actor, oldbuffList[b]) end
    end
end
function mountMain.setModel(actor, data)
    -- {"幻化名字"=幻化品阶}
    local allhhList = {}
    local baseMountId = gethumvar(actor, VarCfg.U_Mount_Base_ID)
    local mountTakeId = gethumvar(actor, VarCfg.U_Mount_Take_Id)
    local oldMountTakeId = mountTakeId
    local bdid = 0
    local isCancel = 0
    local oldbuffList = {}
    local newBuffList = {}
    if mountTakeId == data.mountId then
        -- 取消幻化
        isCancel = 1
        mountTakeId = baseMountId
        allhhList = json2tbl(gethumvar(actor, VarCfg.T_MountHuanHua))
        for i = 1, #mountHHlist do
            if mountHHlist[i].Model == data.mountId and
                allhhList[mountHHlist[i].Name] == mountHHlist[i].grade then
                if mountHHlist[i].buffID then
                    oldbuffList = mountHHlist[i].buffID
                end

            end
        end
        sethumvar(actor, VarCfg.U_Mount_IS_HH, 0)
        sethumvar(actor, VarCfg.U_Mount_Passive, 0)
    else
        -- 幻化
        allhhList = json2tbl(gethumvar(actor, VarCfg.T_MountHuanHua))
        if gethumvar(actor, VarCfg.U_Mount_IS_HH) == 1 then
            -- 原来已经有幻化了
            for i = 1, #mountHHlist do
                if mountHHlist[i].Model ==
                    gethumvar(actor, VarCfg.U_Mount_Take_Id) and
                    allhhList[mountHHlist[i].Name] == mountHHlist[i].grade then
                    if mountHHlist[i].buffID then
                        oldbuffList = mountHHlist[i].buffID
                    end
                end
            end
        end
        for i = 1, #mountHHlist do
            if mountHHlist[i].Model == data.mountId then
                bdid = mountHHlist[i].PassiveAttachCond
            end
            if mountHHlist[i].Model == data.mountId and
                allhhList[mountHHlist[i].Name] == mountHHlist[i].grade then
                if mountHHlist[i].buffID then
                    newBuffList = mountHHlist[i].buffID
                end
            end
        end
        mountTakeId = data.mountId
        sethumvar(actor, VarCfg.U_Mount_IS_HH, 1)
        sethumvar(actor, VarCfg.U_Mount_Passive, bdid)
    end
    mountMain.setMountHHBuff(actor, oldbuffList, newBuffList, isCancel)
    PassiveManager:onVarChanged(actor, "U33")
    sethumvar(actor, VarCfg.U_Mount_Take_Id, mountTakeId)
    changeappear(actor, 5, mountTakeId)
    Message.sendmsgEx(actor, "mountMain", "UpdateHHBtnName", {
        mountHHid = mountTakeId,
        isCancel = isCancel,
        oldModelId = oldMountTakeId
    })
end
function mountMain.chuzhan(actor, data)
    local nowStatus = horsestate(actor)
    local mountId = gethumvar(actor, VarCfg.U_Mount_Take_Id)
    changeappear(actor, 5, mountId)
    updownhorser(actor)
    local baseSpeed = scriptabil(actor, 9)
    if horsestate(actor) == 0 then
        setscriptabilvalue(actor, 9, "=", baseSpeed - 5000)
    else
        setscriptabilvalue(actor, 9, "=", baseSpeed + 5000)
    end
    sethumvar(actor, VarCfg.U_Mount_Status, horsestate(actor))
    Message.sendmsgEx(actor, "mountMain", "updateBtnName",
                      {status = horsestate(actor)})
end
function mountMain.jihuo(actor) sendmsg(actor, 9, "请先激活坐骑") end
-- 灵兽激活 本体 幻化
function mountMain.lsjihuo(actor, data)
    local itemData = getDataByItemId(data.itemId)
    local allPets = gethumvar(actor, VarCfg.T_Pets)
    local allPetsHHData = gethumvar(actor, VarCfg.T_PETS_Take_Id)
    if getItemNum(actor, data.itemId) < 1 then
        sendmsg(actor, 9, "激活材料不足")
        return
    end
    delItemNum(actor, data.itemId, 1)
    if allPets == "" then
        allPets = {}
    else
        allPets = json2tbl(allPets)
    end
    if allPets[itemData.Pet_Name] then
        return sendmsg(actor, 9, "已激活")
        -- allPets[itemData.Pet_Name] = 1
    else
        allPets[itemData.Pet_Name] = 1
    end
    if allPetsHHData == "" then
        allPetsHHData = {}
    else
        allPetsHHData = json2tbl(allPetsHHData)
    end
    -- 激活的是本体
    if tonumber(itemData.Pet_Type) == 1 then
        allPetsHHData["" .. itemData.ID] = itemData.Pet_Lego
        sethumvar(actor, VarCfg.T_PETS_Take_Id, tbl2json(allPetsHHData))
    end
    sethumvar(actor, VarCfg.T_Pets, tbl2json(allPets))
    GameEvent.push(EventCfg.onPetLevel, actor, allPets) -- 宠物升级事件
    -- 新增一个宠物mark
    -- print("新增")
    -- 激活的是幻化，当前有出战宠物直接修改属性
    mountMain.setPetAttr(actor, 0)
    mountMain.addPetToList(actor, itemData.Monster_ID, itemData.Pet_Lego)
    -- 更新灵兽属性buff
    mountMain.updatePetAttrBuff(actor)
    Message.sendmsgEx(actor, "mountMain", "updateLSView",
                      {allPets = allPets, name = itemData.Pet_Name})
end

function mountMain.getPetAttr(actor, modelId)
    -- print("============getPetAttr",modelId)
    local allPets = gethumvar(actor, VarCfg.T_Pets)
    if allPets == "" then
        allPets = {}
    else
        allPets = json2tbl(allPets)
    end
    local result = {}
    local isAddBt = false
    local btid = 0
    for a, v in pairs(SpiritualBeast) do
        if allPets[v.Pet_Name] and allPets[v.Pet_Name] > 0 then

            -- 所有幻化激活属性
            -- 幻化激活属性
            if tonumber(v.Pet_Type) == 2 then
                for i = 1, #v.CoverPet_ActiveProType do
                    if result[v.CoverPet_ActiveProType[i]] then
                        result[v.CoverPet_ActiveProType[i]] =
                            result[v.CoverPet_ActiveProType[i]] +
                                v.CoverPet_ActiveProNum[i]
                    else
                        result[v.CoverPet_ActiveProType[i]] =
                            v.CoverPet_ActiveProNum[i]
                    end
                end
            end
        end
        if v.Pet_Lego == modelId then
            -- 召唤的是本体
            if tonumber(v.Pet_Type) == 1 then
                isAddBt = false
                local bl = allPets[v.Pet_Name]
                for i = 1, #v.BasePet_ProType do
                    if result[v.BasePet_ProType[i]] then
                        result[v.BasePet_ProType[i]] =
                            result[v.BasePet_ProType[i]] + v.BasePet_ProNum[i] +
                                v.BasePet_ProNum[i] * v.BasePet_GrowRatio[bl]
                    else
                        result[v.BasePet_ProType[i]] =
                            v.BasePet_ProNum[i] + v.BasePet_ProNum[i] *
                                v.BasePet_GrowRatio[bl]
                    end
                end
                -- 召唤的是幻化，要加上本体属性
            else
                isAddBt = true
                btid = v.CoverPet_ID
                for i = 1, #v.CoverPet_CoverProType do
                    if result[v.CoverPet_CoverProType[i]] then
                        result[v.CoverPet_CoverProType[i]] =
                            result[v.CoverPet_CoverProType[i]] +
                                v.CoverPet_CoverProNum[i]
                    else
                        result[v.CoverPet_CoverProType[i]] =
                            v.CoverPet_CoverProNum[i]
                    end
                end
            end
            result.icon = v.Pet_Icon
        end
    end
    -- modelid 是幻化id，增加对应本体属性
    if isAddBt then
        local btData = SpiritualBeast[btid]
        local bl = allPets[btData.Pet_Name]
        for i = 1, #btData.BasePet_ProType do
            if result[btData.BasePet_ProType[i]] then
                result[btData.BasePet_ProType[i]] =
                    result[btData.BasePet_ProType[i]] + btData.BasePet_ProNum[i] *
                        (btData.BasePet_GrowRatio[bl] + 1)
            else
                result[btData.BasePet_ProType[i]] =
                    btData.BasePet_ProNum[i] *
                        (btData.BasePet_GrowRatio[bl] + 1)
            end
        end
    end
    return result
end
function getDataByItemId(itemId)
    local data = {}
    for i, v in pairs(SpiritualBeast) do
        if tonumber(v.Pet_ACTIVE) == tonumber(itemId) then
            data = v
            break
        end
    end
    return data
end
-- 点击幻化 幻化中
function mountMain.updatePetModel(actor, data)
    -- id 本体id,modelid 模型id btmodelId 本体模型id
    local allPetsHHData = json2tbl(gethumvar(actor, VarCfg.T_PETS_Take_Id))
    if data.modelid == allPetsHHData["" .. data.id] then
        -- 取消幻化，显示本体
        -- print("取消幻化")
        allPetsHHData["" .. data.id] = data.btmodelId
    else
        -- 幻化
        -- print("幻化")
        allPetsHHData["" .. data.id] = data.modelid
    end
    sethumvar(actor, VarCfg.T_PETS_Take_Id, tbl2json(allPetsHHData))
    -- 当前已召唤宝宝
    if gethumvar(actor, VarCfg.U_PETS_Take_Base) == data.id then
        -- print("当前已有召唤宠物", data.id)
        mountMain.unrecallpet(actor)
        mountMain.recallpet(actor, {btid = data.id})
    end
    Message.sendmsgEx(actor, "mountMain", "updatePetModelResult", {
        allPetsHHData = allPetsHHData,
        showPetModelId = allPetsHHData["" .. data.id]
    })
end

-- 新建宠物,
function mountMain.addPetToList(actor, monsterId, modelId)
    local mark = addpet(actor, monsterId)
    if not mark then return end
    local newPet = {
        mark = mark,
        monsterId = monsterId,
        modelId = modelId,
        isDie = false,
        dieTime = 0
    }
    local t = json2tbl(gethumvar(actor, VarCfg.T_TAKE_PET)) or {}
    table.insert(t, newPet)
    sethumvar(actor, VarCfg.T_TAKE_PET, tbl2json(t))
end

-- 召唤宠物
function mountMain.recallpet(actor, data, isNow, isLoginZH)
    mountMain.unrecallpet(actor, "", "", isLoginZH)
    local hasPet = json2tbl(gethumvar(actor, VarCfg.T_TAKE_PET)) or {}
    local allPetsHHData = json2tbl(gethumvar(actor, VarCfg.T_PETS_Take_Id))
    -- 当前本体的显示模型
    local modelid = allPetsHHData["" .. data.btid]
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"
    for i = 1, #hasPet do
        if hasPet[i].modelId == modelid then
            local mark = hasPet[i].mark
            if gethumvar(actor, VarCfg.U_UserItemLSHH) > 0 then
                mark = gethumvar(actor, VarCfg.T_UserItemLSHHMark)
            end
            sethumvar(actor, VarCfg.U_PETS_NOW_MODEL, modelid)
            sethumvar(actor, VarCfg.U_PETS_Take_Base, data.btid)
            local dieTime = utcint64now() - hasPet[i].dieTime
            local isShowDie = 0
            if hasPet[i].isDie then
                if isNow then
                    realivepet(actor, mark)
                    hasPet[i].isDie = false
                    hasPet[i].dieTime = 0
                    sethumvar(actor, VarCfg.T_TAKE_PET, tbl2json(hasPet))
                    recallpet(actor, mark)
                    sethumvar(actor, VarCfg.T_PET_MARK, mark)
                    -- 攻击模式 1-跟随 2-跟随主人攻击，3-自由攻击，4-休息
                    setpetrelax(actor, mark, 2)
                else
                    if tonumber(dieTime) >=
                        tonumber(SysConstant["PET_Resurre_CD"].Value) * 1000 then
                        realivepet(actor, mark)
                        hasPet[i].isDie = false
                        hasPet[i].dieTime = 0
                        sethumvar(actor, VarCfg.T_TAKE_PET, tbl2json(hasPet))
                        recallpet(actor, mark)
                        sethumvar(actor, VarCfg.T_PET_MARK, mark)
                        -- 攻击模式 1-跟随 2-跟随主人攻击，3-自由攻击，4-休息
                        setpetrelax(actor, mark, 2)
                    else
                        -- print("死了未复活",hasPet[i].dieTime)
                        Message.sendmsgEx(actor, methodName, "petResurrec",
                                          hasPet[i].dieTime)
                        isShowDie = 2
                    end
                end
            else
                disabletimer(actor, 49)
                -- realivepet(actor, mark)
                recallpet(actor, mark)
                sethumvar(actor, VarCfg.T_PET_MARK, mark)
                -- 攻击模式 1-跟随 2-跟随主人攻击，3-自由攻击，4-休息
                setpetrelax(actor, mark, 2)
            end
            -- 设置属性
            mountMain.setPetAttr(actor, isShowDie)
            -- 更新灵兽属性buff(出战灵兽有额外加成)
            mountMain.updatePetAttrBuff(actor)

            -- 应用灵兽出战技能
            local allPets = json2tbl(gethumvar(actor, VarCfg.T_Pets))
            local petId = tonumber(data.btid)
            if allPets and allPets[petId] then
                local petLevel = tonumber(allPets[petId]) or 0
                mountMain.applyPetBattleSkills(actor, petId, petLevel)
            end

            if data.isNeedBack and data.isNeedBack == 1 then
                Message.sendmsgEx(actor, "mountMain", "recallpetResukt", {
                    showPetModelId = modelid,
                    selectViewPetId = data.btid
                })
            end
            if isLoginZH and tonumber(isLoginZH) == 1 then
            else
                GameEvent.push(EventCfg.onChangStatusLS, actor)
            end
        end
    end
end
-- 复活宠物
function mountMain.resurre(actor)
    local mark = gethumvar(actor, VarCfg.T_PET_MARK)
    local petidx = getpetidx(actor, mark)
    local hasPet = json2tbl(gethumvar(actor, VarCfg.T_TAKE_PET))
    for i = 1, #hasPet do
        if hasPet[i].mark == mark then
            hasPet[i].isDie = false
            hasPet[i].dieTime = 0
            sethumvar(actor, VarCfg.T_TAKE_PET, tbl2json(hasPet))
        end
    end
    -- 复活后召唤宠物
    realivepet(actor, mark)
    recallpet(actor, mark)
    setpetrelax(actor, mark, 2)
    mountMain.setPetAttr(actor, 0)
    -- 更新灵兽属性buff(宠物复活出战)
    mountMain.updatePetAttrBuff(actor)
end
-- 收回宠物
function mountMain.unrecallpet(actor, data, playerDie, isLoginZH)
    -- print("=====================",playerDie)
    disabletimer(actor, 49)
    local perIcon = nil
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"
    local hasPet = json2tbl(gethumvar(actor, VarCfg.T_TAKE_PET)) or {}
    if isLoginZH and tonumber(isLoginZH) == 1 then return end
    if playerDie then
        -- print("true")
        for i = 1, #hasPet do
            if hasPet[i].modelId == gethumvar(actor, VarCfg.U_PETS_NOW_MODEL) then
                local mark = hasPet[i].mark
                if gethumvar(actor, VarCfg.U_UserItemLSHH) > 0 then
                    mark = gethumvar(actor, VarCfg.T_UserItemLSHHMark)
                end
                unrecallpet(actor, mark)
                Message.sendmsgEx(actor, methodName, "setPetInfo",
                                  {type = "red", max = 1, now = 1})
            end
        end
    else
        -- print("false")
        for i = 1, #hasPet do
            if hasPet[i].modelId == gethumvar(actor, VarCfg.U_PETS_NOW_MODEL) then
                sethumvar(actor, VarCfg.U_PETS_NOW_MODEL, 0)
                sethumvar(actor, VarCfg.U_PETS_Take_Base, 0)
                local mark = hasPet[i].mark
                if gethumvar(actor, VarCfg.U_UserItemLSHH) > 0 then
                    mark = gethumvar(actor, VarCfg.T_UserItemLSHHMark)
                end
                unrecallpet(actor, mark)
                sethumvar(actor, VarCfg.T_PET_MARK, "")
                Message.sendmsgEx(actor, methodName, "setPetInfo",
                                  {type = "red", max = 1, now = 1})
                GameEvent.push(EventCfg.onChangStatusLS, actor)
                -- 更新灵兽属性buff(收回宠物,出战状态改变)
                mountMain.updatePetAttrBuff(actor)

                -- 清除灵兽出战技能效果
                mountMain.clearPetBattleSkills(actor)

                if data and data.isNeedBack == 1 then
                    Message.sendmsgEx(actor, "mountMain", "unrecallpetResult")
                end
            end
        end
    end
end

function mountMain.fhpet(actor)
    local btid = gethumvar(actor, VarCfg.U_PETS_Take_Base)
    mountMain.recallpet(actor, {btid = btid}, true)
end

-- 设置宠物属性
function mountMain.setPetAttr(actor, isShowDie)
    local mark = gethumvar(actor, VarCfg.T_PET_MARK)
    local petidx = getpetidx(actor, mark)
    local modelid = gethumvar(actor, VarCfg.U_PETS_NOW_MODEL)
    -- 设置属性
    local allAttr = mountMain.getPetAttr(actor, modelid)
    -- dump(allAttr)
    local max = 0
    local now = 0
    for z, x in pairs(allAttr) do
        setscriptabilvalue(petidx, z, "=", x)
        recalcabilitys(petidx)
        changeabil(petidx, z, "=", x)
        if z == 1 then
            max = x
            now = x
            -- max = 10000
            -- now = 10000
        end
    end
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"
    if tonumber(isShowDie) == 2 then
        now = 0
    else
        Message.sendmsgEx(actor, methodName, "petResurrec", 0)
    end
    Message.sendmsgEx(actor, methodName, "setPetInfo",
                      {type = "red", max = max, now = now, icon = allAttr.icon})
end

-- 升级
function mountMain.levelUp(actor, data)
    local hasPet = json2tbl(gethumvar(actor, VarCfg.T_Pets))
    if hasPet[data.name] == data.maxLv then
        return sendmsg(actor, 9, "已满级")
    else
        if bagitemcount(actor, data.itemId) < data.num then
            return sendmsg(actor, 9, "材料不足" .. data.num .. "个")
        end
        delItemNum(actor, data.itemId, data.num)
        hasPet[data.name] = hasPet[data.name] + 1
        sethumvar(actor, VarCfg.T_Pets, tbl2json(hasPet))
        mountMain.setPetAttr(actor)
        -- 更新灵兽属性buff
        mountMain.updatePetAttrBuff(actor)
        GameEvent.push(EventCfg.onPetLevel, actor, hasPet) -- 宠物升级事件
        Message.sendmsgEx(actor, "mountMain", "level",
                          {lv = hasPet[data.name], Pet_Name = data.name})
        if hasPet[data.name] >= 10 then
            -- 培养 6  坐骑 1
            MentorShipChangTask(actor, 6, 1)
        end
    end
end

GameEvent.add(EventCfg.onPlayDie, function(actor, target)
    if gethumvar(actor, VarCfg.U_PETS_Take_Base) > 0 then
        mountMain.unrecallpet(actor, "", true)
    end
end, mountMain)
GameEvent.add(EventCfg.onPlayRealive, function(actor)
    if gethumvar(actor, VarCfg.U_PETS_Take_Base) > 0 then
        local btid = gethumvar(actor, VarCfg.U_PETS_Take_Base)
        mountMain.recallpet(actor, {btid = btid})
    end
end, mountMain)

-- 角色登录时更新灵兽属性buff
GameEvent.add(EventCfg.onLogin,
              function(actor) mountMain.updatePetAttrBuff(actor) end, mountMain)

Message.RegisterNetMsg(ssrNetMsgCfg.mountMain, mountMain)

return mountMain
