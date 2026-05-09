mountMain = {}
local filname = "mountMain"
local mountlist = require("Envir/QuestDiary/game_config/cfgcsv/Mount.lua")
local mountHHlist = require("Envir/QuestDiary/game_config/cfgcsv/MountHuanHua.lua")
local SpiritualBeast = require("Envir/QuestDiary/game_config/cfgcsv/SpiritualBeast.lua")
local SysConstant = require("Envir/QuestDiary/game_config/cfgcsv/SysConstant.lua")
local petlist = require("Envir/QuestDiary/game_config/cfgcsv/Pet.lua")
local petHHlist = require("Envir/QuestDiary/game_config/cfgcsv/PetHuanhua.lua")

-- 灵兽属性转化比例配置表
local PetLevelRateConfig = {
    { 1,  10, 0.03 }, { 11, 20, 0.04 }, { 21, 30, 0.05 }, { 31, 40, 0.06 },
    { 41, 50, 0.08 }, { 51, 60, 0.10 }, { 61, 70, 0.12 }, { 71, 80, 0.15 },
    { 81, 90, 0.18 }, { 91, 100, 0.18 }, { 101, 110, 0.18 },
}

local PetBuffId = 110044
local PetSkillBuffId = 110045
local HuanhuaBuffId = 110047
local MountBuffId = 110015
local MountHuanhuaBuffId = 110016
local MountBattleSkillBuffId = 110046
local ExpAttrId = 12

-- ================= 工具函数 (减少重复代码) =================

-- 根据等级获取灵兽转化比例
local function getPetAttrRateByLevel(level)
    for _, config in ipairs(PetLevelRateConfig) do
        if level >= config[1] and level <= config[2] then return config[3] end
    end
    return PetLevelRateConfig[1][3]
end

-- 统一的道具检查与扣除函数（兼容单/多消耗格式）
local function CheckAndCostItems(actor, costs)
    if not costs then return false, "配置错误" end
    local isMultiCost = (type(costs[1]) == "table")

    if isMultiCost then
        for i = 1, #costs do
            if bagitemcount(actor, tonumber(costs[i][1])) < tonumber(costs[i][2]) then
                return false, "材料不足"
            end
        end
        for i = 1, #costs do
            delItemNum(actor, tonumber(costs[i][1]), tonumber(costs[i][2]))
        end
    else
        local itemId = tonumber(costs[1])
        local num = tonumber(costs[2])
        if bagitemcount(actor, itemId) < num then
            return false, "材料不足" .. num .. "个"
        end
        delItemNum(actor, itemId, num)
    end
    return true
end

-- 统一同步灵兽图标到客户端 UI
local function SyncPetIconToClient(actor, isHide)
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"

    if isHide then
        Message.sendmsgEx(actor, methodName, "setPetInfo", { type = "red", max = 1, now = 1 })
        return
    end

    local icon = "pet_000"
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
    local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)

    if petTakeId and petTakeId > 0 and petTakeId ~= petBaseId then
        for _, v in pairs(petHHlist) do
            if v.Model == petTakeId and v.mount_icon then
                icon = v.mount_icon
                break
            end
        end
    end
    Message.sendmsgEx(actor, methodName, "setPetInfo", { type = "red", max = 10000, now = 10000, icon = icon })
end

-- 统一同步灵兽按钮状态（出战/召回）
local function SyncPetBtnStatus(actor, customStatus)
    local isPetChuzhan = customStatus or (gethumvar(actor, VarCfg.U_Pet_IS_SET) or 0)
    local isPetJh = gethumvar(actor, VarCfg.U_All_Pet_star) or 0
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = isPetChuzhan,
        isPetJh = isPetJh > 0 and 1 or 0,
        allJieshu = isPetJh
    })
end

-- ================= 灵兽核心属性与 BUFF =================

function mountMain.getPetAttrByLevel(level)
    local result = {}
    if petlist[level] and petlist[level].ClassID then
        for _, classData in ipairs(petlist[level].ClassID) do
            result[tonumber(classData[1])] = tonumber(classData[2])
        end
    end
    return result
end

function mountMain.getPetHHAttr(actor)
    local ycList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))
    local hhsxListStr = {}
    if not ycList or not next(ycList) then return hhsxListStr end

    for name, grade in pairs(ycList) do
        for _, petHH in ipairs(petHHlist) do
            if petHH.Name == name and petHH.grade == grade and petHH.ClassID then
                for _, classData in ipairs(petHH.ClassID) do
                    local attrId = tonumber(classData[1])
                    local attrValue = tonumber(classData[2])
                    hhsxListStr[attrId] = (hhsxListStr[attrId] or 0) + attrValue
                end
            end
        end
    end
    return hhsxListStr
end

function mountMain.getPetBattleSkillAttr(actor)
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
    if not petTakeId or petTakeId == 0 then return {} end

    local battleAttr = {}
    for _, petHH in ipairs(petHHlist) do
        if petHH.Model == petTakeId then
            local skillType = petHH.BattleSkill_Type
            local skillValue = petHH.BattleSkill_Value
            if skillType and skillValue then
                if type(skillType) == "table" then
                    for idx = 1, #skillType do
                        battleAttr[tonumber(skillType[idx])] = tonumber(skillValue[idx])
                    end
                else
                    battleAttr[tonumber(skillType)] = tonumber(skillValue)
                end
            end
            break
        end
    end
    return battleAttr
end

function mountMain.updatePetBattleSkillBuff(actor)
    delbuff(actor, PetSkillBuffId)
    local isPetSet = gethumvar(actor, VarCfg.U_Pet_IS_SET)
    if not isPetSet or tonumber(isPetSet) ~= 1 then return end

    local battleAttr = mountMain.getPetBattleSkillAttr(actor)
    if next(battleAttr) then
        addbuff(actor, PetSkillBuffId)
        for attrId, attrValue in pairs(battleAttr) do
            setbuffabil(actor, PetSkillBuffId, tonumber(attrId), "=", tonumber(attrValue))
        end
    end
end

function mountMain.updatePetAttrBuff(actor)
    local allstar = gethumvar(actor, VarCfg.U_All_Pet_star)
    if not allstar or allstar == 0 then
        delbuff(actor, PetBuffId)
        delbuff(actor, HuanhuaBuffId)
        return
    end

    local isBattle = gethumvar(actor, VarCfg.U_Pet_IS_SET)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    local hhAttr = mountMain.getPetHHAttr(actor)

    delbuff(actor, HuanhuaBuffId)
    delbuff(actor, PetBuffId)

    -- 设置幻化属性 (休息和出战都有)
    if next(hhAttr) then
        addbuff(actor, HuanhuaBuffId)
        for attrId, attrValue in pairs(hhAttr) do
            setbuffabil(actor, HuanhuaBuffId, tonumber(attrId), "=", tonumber(attrValue))
        end
    end

    -- 只有出战时设置基础属性
    if isBattle and isBattle == 1 and petMark and petMark ~= "" then
        addbuff(actor, PetBuffId)
        local petAttr = mountMain.getPetAttrByLevel(allstar)
        local attrRate = getPetAttrRateByLevel(allstar)
        for attrId, attrValue in pairs(petAttr) do
            local finalValue = math.ceil(attrValue * attrRate)
            setbuffabil(actor, PetBuffId, tonumber(attrId), "=", finalValue)
        end
    end
end

function mountMain.setPetAttr(actor)
    local allstar = gethumvar(actor, VarCfg.U_All_Pet_star)
    if not allstar or allstar == 0 then return end

    local mark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if not mark or mark == "" then
        mountMain.updatePetAttrBuff(actor)
        return
    end

    local petidx = getpetidx(actor, mark)
    if not petidx then
        mountMain.updatePetAttrBuff(actor)
        return
    end

    local petAttr = mountMain.getPetAttrByLevel(allstar)
    local hhAttr = mountMain.getPetHHAttr(actor)

    for attrId, attrValue in pairs(hhAttr) do
        petAttr[attrId] = (petAttr[attrId] or 0) + attrValue
    end

    for z, x in pairs(petAttr) do
        setscriptabilvalue(petidx, z, "=", x)
        recalcabilitys(petidx)
        changeabil(petidx, z, "=", x)
    end
    mountMain.updatePetAttrBuff(actor)
end

function mountMain.refreshAllPetBuffs(actor)
    mountMain.setPetAttr(actor)
    mountMain.updatePetAttrBuff(actor)
    mountMain.updatePetBattleSkillBuff(actor)
end

-- ================= 灵兽升级与幻化 =================

function mountMain.petShengji(actor)
    local nowlv = gethumvar(actor, VarCfg.U_All_Pet_star) or 0
    local nextlv = nowlv + 1
    if nextlv > #petlist then return sendmsg(actor, 9, "已达到最高等级") end

    local success, errMsg = CheckAndCostItems(actor, petlist[nowlv].Cost)
    if not success then return sendmsg(actor, 9, errMsg) end

    if nowlv == 0 then
        sethumvar(actor, VarCfg.T_PetHuanHua, tbl2json({}))
        sethumvar(actor, VarCfg.U_All_Pet_star, 1)
        sethumvar(actor, VarCfg.U_Pet_IS_SET, 0)
        sethumvar(actor, VarCfg.U_Pet_IS_HH, 0)

        local firstHH = petHHlist[1]
        if firstHH then
            local ycList = { [firstHH.Name] = firstHH.grade }
            sethumvar(actor, VarCfg.T_PetHuanHua, tbl2json(ycList))
            sethumvar(actor, VarCfg.U_Pet_Take_Id, firstHH.Model)
            sethumvar(actor, VarCfg.U_Pet_IS_HH, 1)
            changeappear(actor, 5, firstHH.Model)
            if firstHH.buffID then
                for _, bId in ipairs(firstHH.buffID) do addbuff(actor, bId) end
            end
            Message.sendmsgEx(actor, "mountMain", "updatePetHHmodel", {
                ycList = ycList, name = firstHH.Name, grade = firstHH.grade, petHHid = firstHH.Model
            })
        end
    end

    sethumvar(actor, VarCfg.U_All_Pet_star, nextlv)
    mountMain.refreshAllPetBuffs(actor)

    local petBaseId = petlist[nextlv].Model
    if gethumvar(actor, VarCfg.U_Pet_IS_HH) == 0 then
        sethumvar(actor, VarCfg.U_Pet_Take_Id, petBaseId)
    end
    sethumvar(actor, VarCfg.U_Pet_Base_ID, petBaseId)

    GameEvent.push(EventCfg.onPetLevel, actor)

    local showPetModelId = (gethumvar(actor, VarCfg.U_Pet_IS_HH) == 1) and (gethumvar(actor, VarCfg.U_Pet_Take_Id) or 0) or
        0

    Message.sendmsgEx(actor, "mountMain", "updateLSView",
        { lv = nextlv, petBaseId = petBaseId, name = "pet", showPetModelId = showPetModelId })
    Message.sendmsgEx(actor, "mountMain", "updatePetZQ",
        { lv = nextlv, petBaseId = petBaseId, showPetModelId = showPetModelId })

    SyncPetBtnStatus(actor)
    if gethumvar(actor, VarCfg.U_Pet_IS_SET) == 1 then SyncPetIconToClient(actor, false) end
end

function mountMain.lsjihuo(actor, data)
    local nowlv = gethumvar(actor, VarCfg.U_All_Pet_star)
    if nowlv > 0 then return sendmsg(actor, 9, "已激活") end
    mountMain.petShengji(actor)
end

function mountMain.levelUp(actor, data)
    local nowlv = gethumvar(actor, VarCfg.U_All_Pet_star)
    if not nowlv or nowlv == 0 then return sendmsg(actor, 9, "请先激活灵兽") end
    mountMain.petShengji(actor)
end

function mountMain.petHuanhuajihuo(actor, postData)
    if not postData then return end
    local name, grade, data = postData.Name, postData.grade, nil

    for _, v in ipairs(petHHlist) do
        if v.Name == name and tonumber(v.grade) == tonumber(grade) then
            data = v; break
        end
    end

    if not data then return sendmsg(actor, 9, "激活失败") end

    local success, errMsg = CheckAndCostItems(actor, data.Cost)
    if not success then return sendmsg(actor, 9, errMsg) end

    local ycList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))
    ycList[data.Name] = grade
    sethumvar(actor, VarCfg.T_PetHuanHua, tbl2json(ycList))

    local petHHid = gethumvar(actor, VarCfg.U_Pet_Take_Id)
    if gethumvar(actor, VarCfg.U_Pet_IS_HH) == 1 then
        for _, v in ipairs(petHHlist) do
            if v.Name == name and v.grade == grade then
                petHHid = v.Model
                sethumvar(actor, VarCfg.U_Pet_Take_Id, petHHid)
            end
        end
    end

    mountMain.refreshAllPetBuffs(actor)
    sethumvar(actor, VarCfg.U_Pet_IS_HH, 1)

    Message.sendmsgEx(actor, "mountMain", "updatePetHHmodel", {
        ycList = ycList, name = name, grade = grade, petHHid = petHHid
    })
end

function mountMain.setPetModel(actor, data)
    local allhhList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))
    local basePetId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
    local oldPetTakeId = petTakeId
    local isCancel = (petTakeId == data.mountId) and 1 or 0
    local oldbuffList, newBuffList = {}, {}

    if gethumvar(actor, VarCfg.U_Pet_IS_HH) == 1 then
        for _, v in ipairs(petHHlist) do
            if v.Model == oldPetTakeId and allhhList[v.Name] == v.grade and v.buffID then
                oldbuffList = v.buffID
            end
        end
    end

    if isCancel == 1 then
        petTakeId = basePetId
        sethumvar(actor, VarCfg.U_Pet_IS_HH, 0)
        sethumvar(actor, VarCfg.U_Pet_Passive, 0)
    else
        for _, v in ipairs(petHHlist) do
            if v.Model == data.mountId then
                sethumvar(actor, VarCfg.U_Pet_Passive, v.PassiveAttachCond or 0)
                if allhhList[v.Name] == v.grade and v.buffID then
                    newBuffList = v.buffID
                end
            end
        end
        petTakeId = data.mountId
        sethumvar(actor, VarCfg.U_Pet_IS_HH, 1)
    end

    for _, bId in ipairs(oldbuffList) do delbuff(actor, bId) end
    if isCancel == 0 then
        for _, bId in ipairs(newBuffList) do addbuff(actor, bId) end
    end

    sethumvar(actor, VarCfg.U_Pet_Take_Id, petTakeId)
    sethumvar(actor, VarCfg.U_Pet_Now_Model, petTakeId)

    local isBattle = gethumvar(actor, VarCfg.U_Pet_IS_SET)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)

    if isBattle == 1 and petMark and petMark ~= "" then
        unrecallpet(actor, petMark)
        delpet(actor, petMark)
        sethumvar(actor, VarCfg.T_Pet_Mark, "")
        mountMain.recallpet(actor)
    end

    mountMain.refreshAllPetBuffs(actor)

    local allPetsHHData = {}
    for k, v in pairs(allhhList) do
        for _, hh in ipairs(petHHlist) do
            if hh.Name == k and hh.grade == v then allPetsHHData[hh.Model] = hh end
        end
    end

    Message.sendmsgEx(actor, "mountMain", "updatePetModelResult", {
        allPetsHHData = allPetsHHData,
        showPetModelId = petTakeId,
        petHHid = petTakeId,
        isCancel = isCancel,
        oldModelId = oldPetTakeId
    })

    if isBattle == 1 then SyncPetIconToClient(actor, false) end
end

-- ================= 灵兽出战/召回逻辑 =================

function mountMain.petChuzhan(actor)
    local isActivated = gethumvar(actor, VarCfg.U_All_Pet_star)
    if not isActivated or isActivated < 11 then
        return sendmsg(actor, 9, isActivated == 0 and "请先激活灵兽" or "灵兽未达一阶，无法上阵出战")
    end

    if gethumvar(actor, VarCfg.U_Pet_IS_SET) == 1 then
        mountMain.unrecallpet(actor)
    else
        mountMain.recallpet(actor)
        GameEvent.push(EventCfg.onPetZhan, actor)
    end
end

function mountMain.recallpet(actor)
    disabletimer(actor, 49)
    local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID) or 900001
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id) or petBaseId
    local monsterId = 80001

    local isHuanhua = false
    local petName, currentHHGrade = nil, 0
    for _, v in ipairs(petHHlist) do
        if v.Model == petTakeId then
            petName = v.Name; break
        end
    end

    if petName then
        local ycList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))
        currentHHGrade = tonumber(ycList[petName]) or 0
        for _, v in ipairs(petHHlist) do
            if v.Name == petName and tonumber(v.grade) == currentHHGrade then
                monsterId = v.Monster_ID; isHuanhua = true; break
            end
        end
    end

    if not isHuanhua then
        for i = 0, 10 do
            if petlist[i] and tonumber(petlist[i].Model) == tonumber(petBaseId) then
                monsterId = tonumber(petlist[i].Monster_ID) or 80001; break
            end
        end
    end

    local mark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if not mark or mark == "" then
        mark = addpet(actor, monsterId)
        if not mark or mark == "" then return sendmsg(actor, 9, "添加灵兽失败") end
        sethumvar(actor, VarCfg.T_Pet_Mark, mark)
    end

    recallpet(actor, mark)
    sethumvar(actor, VarCfg.U_Pet_IS_SET, 1)
    setpetrelax(actor, mark, 2)

    mountMain.refreshAllPetBuffs(actor)

    Message.sendmsgEx(actor, "mountMain", "recallpetResult", {
        showPetModelId = petTakeId, selectViewPetId = petBaseId, isPetChuzhan = 1
    })

    SyncPetIconToClient(actor, false)
    SyncPetBtnStatus(actor)
end

function mountMain.unrecallpet(actor, petMark)
    petMark = petMark or gethumvar(actor, VarCfg.T_Pet_Mark)
    if not petMark or petMark == "" then return end

    local petDieTime = tonumber(gethumvar(actor, VarCfg.U_Pet_Die_Time))
    if petDieTime and petDieTime > 1 then
        return sendmsg(actor, 9, string.format("灵兽已死亡，请%s秒复活后再召回", petDieTime))
    end

    disabletimer(actor, 49)
    unrecallpet(actor, petMark)
    sethumvar(actor, VarCfg.U_Pet_IS_SET, 0)

    mountMain.refreshAllPetBuffs(actor)

    Message.sendmsgEx(actor, "mountMain", "unrecallpetResult")
    SyncPetIconToClient(actor, true)
    SyncPetBtnStatus(actor)
end

function mountMain.resurre(actor)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if not petMark or petMark == "" then return end

    realivepet(actor, petMark)
    mountMain.recallpet(actor)
end

-- ================= 坐骑核心功能 =================

function mountMain.getMountBattleSkillAttr(actor)
    local mountTakeId = gethumvar(actor, VarCfg.U_Mount_Take_Id)
    if not mountTakeId or mountTakeId == 0 then return {} end

    local battleAttr = {}
    for _, v in ipairs(mountHHlist) do
        if v.Model == mountTakeId then
            local skillType = v.BattleSkill_Type
            local skillValue = v.BattleSkill_Value
            if type(skillType) == "table" then
                for idx = 1, #skillType do battleAttr[tonumber(skillType[idx])] = tonumber(skillValue[idx]) end
            else
                battleAttr[tonumber(skillType)] = tonumber(skillValue)
            end
            break
        end
    end
    return battleAttr
end

function mountMain.updateMountBattleSkillBuff(actor)
    delbuff(actor, MountBattleSkillBuffId)
    local mountStatus = gethumvar(actor, VarCfg.U_Mount_Status)
    if not mountStatus or tonumber(mountStatus) ~= 1 then return end

    local battleAttr = mountMain.getMountBattleSkillAttr(actor)
    if next(battleAttr) then
        addbuff(actor, MountBattleSkillBuffId)
        for attrId, attrValue in pairs(battleAttr) do
            setbuffabil(actor, MountBattleSkillBuffId, tonumber(attrId), "=", tonumber(attrValue))
        end
    end
end

function mountMain.updateMountAttrBuff(actor)
    local allstar = gethumvar(actor, VarCfg.U_All_Mount_star)
    local isMountActive = gethumvar(actor, VarCfg.U_Mount_IS_SET)

    delbuff(actor, MountBuffId)
    delbuff(actor, MountHuanhuaBuffId)

    if not allstar or allstar == 0 or not isMountActive or isMountActive == 0 then return end

    addbuff(actor, MountBuffId)
    addbuff(actor, MountHuanhuaBuffId)

    if mountlist[allstar] and mountlist[allstar].ClassID then
        for _, classData in ipairs(mountlist[allstar].ClassID) do
            setbuffabil(actor, MountBuffId, tonumber(classData[1]), "=", tonumber(classData[2]))
        end
    end

    local ycList = json2tbl(gethumvar(actor, VarCfg.T_MountHuanHua))
    local totalAttr = {}
    for name, grade in pairs(ycList) do
        for _, hhData in ipairs(mountHHlist) do
            if hhData.Name == name and hhData.grade == grade and hhData.ClassID then
                for _, classData in ipairs(hhData.ClassID) do
                    local attrId, attrValue = tonumber(classData[1]), tonumber(classData[2])
                    totalAttr[attrId] = (totalAttr[attrId] or 0) + attrValue
                end
            end
        end
    end

    for attrId, attrValue in pairs(totalAttr) do
        setbuffabil(actor, MountHuanhuaBuffId, attrId, "=", attrValue)
    end
end

function mountMain.refreshAllMountBuffs(actor)
    mountMain.updateMountAttrBuff(actor)
    mountMain.updateMountBattleSkillBuff(actor)
end

function mountMain.addsx(actor) mountMain.refreshAllMountBuffs(actor) end

function mountMain.shengji(actor)
    local nowlv = gethumvar(actor, VarCfg.U_All_Mount_star) or 0
    local nextlv = nowlv + 1
    if nextlv > #mountlist then return end

    local success, errMsg = CheckAndCostItems(actor, mountlist[nowlv].Cost)
    if not success then return sendmsg(actor, 9, errMsg) end

    if nowlv == 0 then
        sethumvar(actor, VarCfg.T_MountHuanHua, tbl2json({}))
        sethumvar(actor, VarCfg.U_All_Mount_star, 1)
        sethumvar(actor, VarCfg.U_Mount_IS_SET, 1)

        local firstHH = mountHHlist[1]
        if firstHH then
            local ycList = { [firstHH.Name] = firstHH.grade }
            sethumvar(actor, VarCfg.T_MountHuanHua, tbl2json(ycList))
            sethumvar(actor, VarCfg.U_Mount_Take_Id, firstHH.Model)
            sethumvar(actor, VarCfg.U_Mount_IS_HH, 1)
            changeappear(actor, 5, firstHH.Model)
            if firstHH.buffID then
                for _, bId in ipairs(firstHH.buffID) do addbuff(actor, bId) end
            end
            Message.sendmsgEx(actor, "mountMain", "updateHHmodel", {
                ycList = ycList, name = firstHH.Name, grade = firstHH.grade, mountHHid = firstHH.Model
            })
        end
    end

    sethumvar(actor, VarCfg.U_All_Mount_star, nextlv)
    local mountBaseId = mountlist[nextlv].Model
    if gethumvar(actor, VarCfg.U_Mount_IS_HH) == 0 then
        changeappear(actor, 5, mountBaseId)
        sethumvar(actor, VarCfg.U_Mount_Take_Id, mountBaseId)
    end
    sethumvar(actor, VarCfg.U_Mount_Base_ID, mountBaseId)

    mountMain.refreshAllMountBuffs(actor)

    Message.sendmsgEx(actor, "mountMain", "updateZQ", { lv = nextlv, mountBaseId = mountBaseId })
    MentorShipChangTask(actor, 6, 1, nextlv)
    GameEvent.push(EventCfg.onMountLv, actor)
end

function mountMain.huanhuajihuo(actor, postData)
    local data = nil
    for _, v in ipairs(mountHHlist) do
        if v.Name == mountHHlist[postData.idx].Name and tonumber(v.grade) == tonumber(postData.grade) then
            data = v; break
        end
    end

    if not data then return sendmsg(actor, 9, "激活失败") end

    local success, errMsg = CheckAndCostItems(actor, data.Cost)
    if not success then return sendmsg(actor, 9, errMsg) end

    local ycList = json2tbl(gethumvar(actor, VarCfg.T_MountHuanHua))
    ycList[data.Name] = data.grade
    sethumvar(actor, VarCfg.T_MountHuanHua, tbl2json(ycList))

    local mountHHid = gethumvar(actor, VarCfg.U_Mount_Take_Id)
    if gethumvar(actor, VarCfg.U_Mount_IS_HH) == 1 then
        for _, v in ipairs(mountHHlist) do
            if v.Name == data.Name and v.grade == data.grade then
                mountHHid = v.Model
                sethumvar(actor, VarCfg.U_Mount_Take_Id, mountHHid)
                changeappear(actor, 5, mountHHid)
            end
        end
    end

    mountMain.refreshAllMountBuffs(actor)

    Message.sendmsgEx(actor, "mountMain", "updateHHmodel", {
        ycList = ycList, name = data.Name, grade = data.grade, mountHHid = mountHHid
    })
end

function mountMain.setModel(actor, data)
    local allhhList = json2tbl(gethumvar(actor, VarCfg.T_MountHuanHua))
    local baseMountId = gethumvar(actor, VarCfg.U_Mount_Base_ID)
    local mountTakeId = gethumvar(actor, VarCfg.U_Mount_Take_Id)
    local oldMountTakeId = mountTakeId
    local isCancel = (mountTakeId == data.mountId) and 1 or 0
    local oldbuffList, newBuffList = {}, {}

    if gethumvar(actor, VarCfg.U_Mount_IS_HH) == 1 then
        for _, v in ipairs(mountHHlist) do
            if v.Model == oldMountTakeId and allhhList[v.Name] == v.grade and v.buffID then
                oldbuffList = v.buffID
            end
        end
    end

    if isCancel == 1 then
        mountTakeId = baseMountId
        sethumvar(actor, VarCfg.U_Mount_IS_HH, 0)
        sethumvar(actor, VarCfg.U_Mount_Passive, 0)
    else
        for _, v in ipairs(mountHHlist) do
            if v.Model == data.mountId then
                sethumvar(actor, VarCfg.U_Mount_Passive, v.PassiveAttachCond or 0)
                if allhhList[v.Name] == v.grade and v.buffID then
                    newBuffList = v.buffID
                end
            end
        end
        mountTakeId = data.mountId
        sethumvar(actor, VarCfg.U_Mount_IS_HH, 1)
    end

    for _, bId in ipairs(oldbuffList) do delbuff(actor, bId) end
    if isCancel == 0 then
        for _, bId in ipairs(newBuffList) do addbuff(actor, bId) end
    end

    PassiveManager:onVarChanged(actor, "U33")
    sethumvar(actor, VarCfg.U_Mount_Take_Id, mountTakeId)
    changeappear(actor, 5, mountTakeId)

    mountMain.refreshAllMountBuffs(actor)

    Message.sendmsgEx(actor, "mountMain", "UpdateHHBtnName", {
        mountHHid = mountTakeId, isCancel = isCancel, oldModelId = oldMountTakeId
    })
end

function mountMain.chuzhan(actor, data)
    local mountStar = gethumvar(actor, VarCfg.U_All_Mount_star)
    if not mountStar or mountStar < 11 then
        return sendmsg(actor, 9, mountStar == 0 and "请先激活坐骑" or "坐骑未达一阶，无法上阵出战")
    end

    changeappear(actor, 5, gethumvar(actor, VarCfg.U_Mount_Take_Id))
    updownhorser(actor)
    sethumvar(actor, VarCfg.U_Mount_Status, horsestate(actor))

    mountMain.refreshAllMountBuffs(actor)

    Message.sendmsgEx(actor, "mountMain", "updateBtnName", { status = horsestate(actor) })
    GameEvent.push(EventCfg.onMountZhan, actor)
end

function mountMain.openshow(actor, data)
    Message.sendmsgEx(actor, "mountMain", "Open", {})

    local serverChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET) or 0
    SyncPetBtnStatus(actor, 1 - serverChuzhan)
    if serverChuzhan == 1 then SyncPetIconToClient(actor, false) end
end

-- ================= 事件注册 =================

GameEvent.add(EventCfg.onPlayDie, function(actor, target)
    local newBase = gethumvar(actor, VarCfg.U_Pet_Base_ID)
    if newBase and newBase > 0 then
        mountMain.unrecallpet(actor)
    end
end, mountMain)

GameEvent.add(EventCfg.onPlayRealive, function(actor)
    if (gethumvar(actor, VarCfg.U_All_Pet_star) or 0) > 0 and gethumvar(actor, VarCfg.U_Pet_IS_SET) == 1 then
        mountMain.recallpet(actor)
    end
end, mountMain)

GameEvent.add(EventCfg.onLoginEnd, function(actor)
    local petDieTime = tonumber(gethumvar(actor, VarCfg.U_Pet_Die_Time))
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if petDieTime and petDieTime > 1 and petMark and petMark ~= "" then
        addtimerex(actor, 49, 1000, petDieTime, "@ontimer49", "")
        local isPc = clientflag(actor) == 1
        Message.sendmsgEx(actor, isPc and "PCMainPlayer" or "MainPlayer", "petResurrec", utcint64now())
        mountMain.refreshAllPetBuffs(actor)
        return
    end

    local mountIsSet = tonumber(gethumvar(actor, VarCfg.U_Mount_IS_SET))
    local mountStatus = tonumber(gethumvar(actor, VarCfg.U_Mount_Status))
    local mountTakeIdNum = tonumber(gethumvar(actor, VarCfg.U_Mount_Take_Id))

    if mountIsSet == 1 and mountStatus == 1 and mountTakeIdNum and mountTakeIdNum > 0 then
        changeappear(actor, 5, mountTakeIdNum)
        if horsestate(actor) == 0 then updownhorser(actor) end
        mountMain.refreshAllMountBuffs(actor)
    end

    mountMain.refreshAllPetBuffs(actor)

    if (gethumvar(actor, VarCfg.U_All_Pet_star) or 0) > 0 and gethumvar(actor, VarCfg.U_Pet_IS_SET) == 1 then
        disabletimer(actor, 49)
        local monsterId = 80001
        local petTakeId = tonumber(gethumvar(actor, VarCfg.U_Pet_Take_Id))

        if petTakeId and petTakeId > 0 then
            for _, v in ipairs(petHHlist) do
                if v.Model == petTakeId and v.Monster_ID then
                    monsterId = v.Monster_ID; break
                end
            end
        end

        local mark = gethumvar(actor, VarCfg.T_Pet_Mark)
        if not mark or mark == "" or not getpetidx(actor, mark) then
            mark = addpet(actor, monsterId)
            if not mark or mark == "" then return end
            sethumvar(actor, VarCfg.T_Pet_Mark, mark)
        end

        recallpet(actor, mark)
        setpetrelax(actor, mark, 2)
        mountMain.refreshAllPetBuffs(actor)
        SyncPetIconToClient(actor, false)
    end
end, mountMain)

Message.RegisterNetMsg(ssrNetMsgCfg.mountMain, mountMain)

return mountMain
