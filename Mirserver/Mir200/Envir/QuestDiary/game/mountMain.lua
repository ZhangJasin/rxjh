mountMain = {}
local filname = "mountMain"
local mountlist = require("Envir/QuestDiary/game_config/cfgcsv/Mount.lua")
local mountHHlist = require(
                        "Envir/QuestDiary/game_config/cfgcsv/MountHuanHua.lua")
local SpiritualBeast = require(
                           "Envir/QuestDiary/game_config/cfgcsv/SpiritualBeast.lua")
local SysConstant = require(
                        "Envir/QuestDiary/game_config/cfgcsv/SysConstant.lua")

-- 灵兽配置表（与坐骑结构一致）
local petlist = require("Envir/QuestDiary/game_config/cfgcsv/Pet.lua")
local petHHlist = require("Envir/QuestDiary/game_config/cfgcsv/PetHuanhua.lua")

-- 灵兽额外加成比例(出战灵兽给予人物10%属性)
local PetExtraRate = {attrRate = 0.1}

-- 灵兽buff配置
local PetBuffId = 110044
local BattlePetBuffId = 110045

-- 经验加成属性ID(万分比,10000=100%)
local ExpAttrId = 12

-- ===== 新的灵兽功能（与坐骑结构一致）=====

-- 获取灵兽配表属性
function mountMain.getPetAttrByLevel(level)
    local result = {}
    if petlist[level] and petlist[level].ClassID then
        local classIds = petlist[level].ClassID
        for b = 1, #classIds do
            local attrId = tonumber(classIds[b][1])
            local attrValue = tonumber(classIds[b][2])
            result[attrId] = attrValue
        end
    end
    return result
end

-- 获取灵兽幻化属性
function mountMain.getPetHHAttr(actor)
    local ycList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))
    local hhsxListStr = {}
    for l, v in pairs(ycList) do
        if l then
            local jhhhlist = {}
            for e = 1, #petHHlist do
                if petHHlist[e].Name == l and petHHlist[e].grade == v then
                    jhhhlist[#jhhhlist + 1] = petHHlist[e]
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
    return hhsxListStr
end

-- 设置灵兽本身的属性（将配表属性赋予灵兽宠物）
function mountMain.setPetAttr(actor)
    local allstar = gethumvar(actor, VarCfg.U_All_Pet_star)
    if not allstar or allstar == 0 then
        print("setPetAttr: 灵兽未激活")
        return
    end
    
    local mark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if not mark or mark == "" then
        print("setPetAttr: 没有召唤灵兽，仅设置人物属性")
        -- 即使没有召唤灵兽，仍然更新人物属性
        mountMain.updatePetAttrBuff(actor)
        return
    end
    
    local petidx = getpetidx(actor, mark)
    if not petidx then
        print("setPetAttr: 灵兽不存在，仅设置人物属性")
        mountMain.updatePetAttrBuff(actor)
        return
    end
    
    -- 获取灵兽等级属性
    local petAttr = mountMain.getPetAttrByLevel(allstar)
    
    -- 获取幻化属性
    local hhAttr = mountMain.getPetHHAttr(actor)
    
    -- 合并属性（灵兽属性 + 幻化属性）
    for attrId, attrValue in pairs(hhAttr) do
        if petAttr[attrId] then
            petAttr[attrId] = petAttr[attrId] + attrValue
        else
            petAttr[attrId] = attrValue
        end
    end
    
    -- 设置属性到灵兽宠物
    local max = 0
    local now = 0
    for z, x in pairs(petAttr) do
        setscriptabilvalue(petidx, z, "=", x)
        recalcabilitys(petidx)
        changeabil(petidx, z, "=", x)
        if z == 1 then
            max = x
            now = x
        end
    end
    
    -- 发送消息更新客户端显示
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"
    Message.sendmsgEx(actor, methodName, "setPetInfo", {
        type = "red",
        max = max,
        now = now,
        icon = 0
    })
    
    -- 设置人物属性
    mountMain.updatePetAttrBuff(actor)
    print("setPetAttr: 灵兽属性设置完成")
end

-- 更新灵兽属性加成到人物（仅在灵兽出战状态下，给予灵兽10%属性）
function mountMain.updatePetAttrBuff(actor)
    local allstar = gethumvar(actor, VarCfg.U_All_Pet_star)
    if not allstar or allstar == 0 then
        delbuff(actor, PetBuffId)
        return
    end

    -- 检查灵兽是否出战（U_Pet_IS_SET 或检查宠物mark）
    local isBattle = gethumvar(actor, VarCfg.U_Pet_IS_SET)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    
    -- 如果没有召唤灵兽，则不给予人物属性
    if not isBattle or isBattle == 0 or not petMark or petMark == "" then
        delbuff(actor, PetBuffId)
        print("updatePetAttrBuff: 灵兽未出战，不给予人物属性")
        return
    end

    -- 先清除buff再添加
    delbuff(actor, PetBuffId)
    addbuff(actor, PetBuffId)

    -- 获取灵兽等级属性
    local petAttr = mountMain.getPetAttrByLevel(allstar)
    
    -- 获取幻化属性并累加
    local hhAttr = mountMain.getPetHHAttr(actor)
    for attrId, attrValue in pairs(hhAttr) do
        if petAttr[attrId] then
            petAttr[attrId] = petAttr[attrId] + attrValue
        else
            petAttr[attrId] = attrValue
        end
    end

    -- 应用灵兽10%属性到人物（仅在出战状态下）
    local attrRate = PetExtraRate.attrRate
    for attrId, attrValue in pairs(petAttr) do
        local finalValue = math.ceil(attrValue * attrRate)
        setbuffabil(actor, PetBuffId, tonumber(attrId), "=", finalValue)
    end
    
    print("updatePetAttrBuff: 灵兽已出战，给予人物" .. (attrRate * 100) .. "%属性")
end

-- 灵兽升级（与坐骑升级相同的结构）
function mountMain.petShengji(actor)
    local nowlv = gethumvar(actor, VarCfg.U_All_Pet_star)
    local nextlv = nowlv + 1
    print("=== 灵兽升级/激活 ===")
    print("当前等级:", nowlv, "下一等级:", nextlv, "最高等级:", #petlist)
    if nextlv > #petlist then
        print("已达到最高等级")
        return
    end

    if not petlist[nextlv] or not petlist[nextlv].ClassID then
        print("petShengji: 下一级配置不存在, nextlv:", nextlv)
        return
    end

    if not petlist[nowlv] or not petlist[nowlv].Cost then
        print("petShengji: 当前级配置不存在, nowlv:", nowlv)
        return
    end

    local classIds = petlist[nextlv].ClassID
    local costs = petlist[nowlv].Cost
    local itemId = tonumber(costs[1])
    local num = tonumber(costs[2])

    print("材料ID:", itemId, "需要数量:", num, "拥有数量:", bagitemcount(actor, itemId))

    if bagitemcount(actor, itemId) < num then
        print("材料不足")
        sendmsg(actor, 9, "材料不足" .. num .. "个")
        return
    end

    print("材料充足,开始升级/激活")
    if nowlv == 0 then -- 激活
        print("首次激活灵兽")
        sethumvar(actor, VarCfg.T_PetHuanHua, tbl2json({}))
        sethumvar(actor, VarCfg.U_All_Pet_star, 1)
        -- 设置为休息状态（1表示休息/未出战，0表示出战）
        sethumvar(actor, VarCfg.U_Pet_IS_SET, 1)
        print("设置激活状态完成")
    end

    delItemNum(actor, itemId, num)
    sethumvar(actor, VarCfg.U_All_Pet_star, nextlv)

    -- 设置灵兽本身的属性（将配表属性赋予灵兽，并设置人物属性）
    mountMain.setPetAttr(actor)

    local petBaseId = petlist[nextlv].Model
    print("灵兽基础模型ID:", petBaseId)

    -- 当前模型是否幻化
    if gethumvar(actor, VarCfg.U_Pet_IS_HH) == 0 then
        sethumvar(actor, VarCfg.U_Pet_Take_Id, petBaseId)
        print("设置灵兽当前使用模型:", petBaseId)
    end
    sethumvar(actor, VarCfg.U_Pet_Base_ID, petBaseId)
    print("设置灵兽基础模型:", petBaseId)

    -- 激活时设置灵兽外观
    if nowlv == 0 then
        local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
        if petTakeId and petTakeId > 0 then
            changeappear(actor, 5, petTakeId)
            print("激活时设置灵兽外观:", petTakeId)
        end
    end

    -- 触发灵兽升级事件（与旧系统对齐）
    local allPets = {pet = nextlv}
    GameEvent.push(EventCfg.onPetLevel, actor, allPets)

    -- 更新前端显示（发送updateLSView消息与旧系统对齐）
    print("发送升级消息到客户端,等级:", nextlv)
    Message.sendmsgEx(actor, "mountMain", "updateLSView", {
        lv = nextlv,
        petBaseId = petBaseId,
        name = "pet"
    })
    -- 同时发送updatePetZQ消息保持兼容性
    Message.sendmsgEx(actor, "mountMain", "updatePetZQ", {
        lv = nextlv,
        petBaseId = petBaseId
    })
    
    -- 发送petUpdateBtn消息更新按钮状态（激活后为休息状态，显示"出战"）
    local isPetChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET)
    local isPetJh = gethumvar(actor, VarCfg.U_All_Pet_star)
    print("发送petUpdateBtn消息：isPetChuzhan=", isPetChuzhan, "isPetJh=", isPetJh)
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = isPetChuzhan,
        isPetJh = isPetJh
    })
    
    print("升级完成")
end

-- 灵兽幻化激活（与坐骑幻化相同的结构）
function mountMain.petHuanhuajihuo(actor, postData)
    print("=== 灵兽幻化激活 ===")
    print("客户端数据:", type(postData), postData)
    
    if not postData then
        print("postData 为空！")
        return
    end
    
    local name = postData.Name  -- 应该使用 Name 字段，而不是 idx
    local grade = postData.grade
    local data = nil
    print("查找: Name=" .. name .. ", grade=" .. grade)
    print("petHHlist 总数:", #petHHlist)
    
    for i = 1, #petHHlist do
        if petHHlist[i].Name == name and tonumber(petHHlist[i].grade) == tonumber(grade) then
            data = petHHlist[i]
            print("找到匹配数据:", data)
            break
        end
    end

    if data then
        local classid = data.ClassID -- 属性
        local costs = data.Cost -- 消耗
        local itemId = tonumber(costs[1])
        local num = tonumber(costs[2])

        print("材料ID:", itemId, "需要数量:", num, "拥有数量:", getItemNum(actor, itemId))

        if getItemNum(actor, itemId) < num then
            sendmsg(actor, 9, "激活材料不足" .. num .. "个")
        else
            local ycList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))
            delItemNum(actor, itemId, num)
            ycList[data.Name] = grade
            sethumvar(actor, VarCfg.T_PetHuanHua, tbl2json(ycList))

            local petHHid = gethumvar(actor, VarCfg.U_Pet_Take_Id)
            -- 升级前的幻化模型id
            if gethumvar(actor, VarCfg.U_Pet_IS_HH) == 1 then
                -- 当前已经幻化了
                local oldHHModelId = 0
                local newHHModelId = 0
                for i = 1, #petHHlist do
                    if petHHlist[i].Name == name and petHHlist[i].grade == grade - 1 then
                        oldHHModelId = petHHlist[i].Model
                    end
                    if petHHlist[i].Name == name and petHHlist[i].grade == grade then
                        newHHModelId = petHHlist[i].Model
                    end
                end
                if tonumber(oldHHModelId) == petHHid then
                    petHHid = newHHModelId
                    sethumvar(actor, VarCfg.U_Pet_Take_Id, newHHModelId)
                end
            end

            -- 计算幻化属性
            local hhsxListStr = {}
            for l, v in pairs(ycList) do
                if l then
                    local jhhhlist = {}
                    for e = 1, #petHHlist do
                        if petHHlist[e].Name == l and petHHlist[e].grade == v then
                            jhhhlist[#jhhhlist + 1] = petHHlist[e]
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

            -- 重新计算并应用所有灵兽属性（与旧系统对齐）
            mountMain.updatePetAttrBuff(actor)

            -- 更新前端
            Message.sendmsgEx(actor, "mountMain", "updatePetHHmodel", {
                ycList = ycList,
                name = name,
                grade = grade,
                petHHid = petHHid
            })
            print("灵兽幻化激活成功")
        end
    else
        print("未找到匹配的灵兽幻化数据")
        sendmsg(actor, 9, "激活失败")
    end
end

-- 先删除旧的灵兽幻化buff
function mountMain.setPetHHBuff(actor, oldbuffList, newBuffList, isCancel)
    if tonumber(isCancel) == 0 then
        for b = 1, #oldbuffList do delbuff(actor, oldbuffList[b]) end
        for c = 1, #newBuffList do addbuff(actor, newBuffList[c]) end
    else
        -- 取消幻化
        for b = 1, #oldbuffList do delbuff(actor, oldbuffList[b]) end
    end
end

-- 灵兽设置模型（与坐骑相同的结构）
function mountMain.setPetModel(actor, data)
    -- {"幻化名字"=幻化品阶}
    local allhhList = {}
    local basePetId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
    local oldPetTakeId = petTakeId
    local bdid = 0
    local isCancel = 0
    local oldbuffList = {}
    local newBuffList = {}

    if petTakeId == data.mountId then
        -- 取消幻化
        isCancel = 1
        petTakeId = basePetId
        allhhList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))
        for i = 1, #petHHlist do
            if petHHlist[i].Model == data.mountId and
                allhhList[petHHlist[i].Name] == petHHlist[i].grade then
                if petHHlist[i].buffID then
                    oldbuffList = petHHlist[i].buffID
                end
            end
        end
        sethumvar(actor, VarCfg.U_Pet_IS_HH, 0)
        sethumvar(actor, VarCfg.U_Pet_Passive, 0)
    else
        -- 幻化
        allhhList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))
        if gethumvar(actor, VarCfg.U_Pet_IS_HH) == 1 then
            -- 原来已经有幻化了
            for i = 1, #petHHlist do
                if petHHlist[i].Model == gethumvar(actor, VarCfg.U_Pet_Take_Id) and
                    allhhList[petHHlist[i].Name] == petHHlist[i].grade then
                    if petHHlist[i].buffID then
                        oldbuffList = petHHlist[i].buffID
                    end
                end
            end
        end
        for i = 1, #petHHlist do
            if petHHlist[i].Model == data.mountId then
                bdid = petHHlist[i].PassiveAttachCond
            end
            if petHHlist[i].Model == data.mountId and
                allhhList[petHHlist[i].Name] == petHHlist[i].grade then
                if petHHlist[i].buffID then
                    newBuffList = petHHlist[i].buffID
                end
            end
        end
        petTakeId = data.mountId
        sethumvar(actor, VarCfg.U_Pet_IS_HH, 1)
        sethumvar(actor, VarCfg.U_Pet_Passive, bdid)
    end

    mountMain.setPetHHBuff(actor, oldbuffList, newBuffList, isCancel)
    sethumvar(actor, VarCfg.U_Pet_Take_Id, petTakeId)
    -- 更新灵兽外观显示
    changeappear(actor, 5, petTakeId)
    -- 重新计算并应用所有灵兽属性
    mountMain.updatePetAttrBuff(actor)
    -- 获取所有已激活的灵兽幻化数据
    local allPetsHHData = {}
    for k, v in pairs(allhhList) do
        for i = 1, #petHHlist do
            if petHHlist[i].Name == k and petHHlist[i].grade == v then
                allPetsHHData[petHHlist[i].Model] = petHHlist[i]
            end
        end
    end
    
    Message.sendmsgEx(actor, "mountMain", "updatePetModelResult", {
        allPetsHHData = allPetsHHData,
        showPetModelId = petTakeId,
        petHHid = petTakeId,
        isCancel = isCancel,
        oldModelId = oldPetTakeId
    })
end

-- ===== 坐骑功能（保留原有功能）=====

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
function mountMain.lsJihuo(actor) sendmsg(actor, 9, "请先激活灵兽") end

-- ===== 旧灵兽功能已废弃，以下函数已由新结构替代 =====
-- 说明：旧的灵兽激活、召唤、收回等功能已被新的灵兽结构替代
-- 新结构使用与坐骑相同的星星/阶数系统和幻化系统
-- 如果需要使用旧功能，请取消注释并调整相关调用

-- 灵兽激活/升级接口（与旧系统对齐）
function mountMain.lsjihuo(actor, data)
    -- data.itemId = 激活材料ID
    local nowlv = gethumvar(actor, VarCfg.U_All_Pet_star)

    if nowlv > 0 then
        return sendmsg(actor, 9, "已激活")
    end

    mountMain.petShengji(actor)
end

-- function mountMain.getPetAttr(actor, modelId)
--     -- 旧的灵兽获取属性逻辑已由 mountMain.updatePetAttrBuff 替代
-- end

-- function mountMain.updatePetModel(actor, data)
--     -- 旧的灵兽更新模型逻辑已由 mountMain.setPetModel 替代
-- end

-- function mountMain.recallpet(actor, data, isNow, isLoginZH)
--     -- 旧的灵兽召唤逻辑需要根据实际情况重新实现
-- end

-- function mountMain.resurre(actor)
--     -- 旧的灵兽复活逻辑需要根据实际情况重新实现
-- end

-- function mountMain.unrecallpet(actor, data, playerDie, isLoginZH)
--     -- 旧的灵兽收回逻辑需要根据实际情况重新实现
-- end

-- function mountMain.setPetAttr(actor, isShowDie)
--     -- 旧的灵兽设置属性逻辑已由新结构替代
-- end

-- ===== 灵兽出战/召回功能 =====
-- 灵兽出战/召回入口函数
function mountMain.petChuzhan(actor)
    print("=== 灵兽出战/召回 ===")
    -- 用 U_All_Pet_star 判断是否激活（>0表示已激活）
    local isActivated = gethumvar(actor, VarCfg.U_All_Pet_star)
    if not isActivated or isActivated == 0 then
        sendmsg(actor, 9, "请先激活灵兽")
        return
    end

    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if petMark and petMark ~= "" then
        -- 灵兽已出战，执行召回
        print("灵兽已出战，执行召回")
        mountMain.unrecallpet(actor)
    else
        -- 灵兽未出战，执行召唤
        print("灵兽未出战，执行召唤")
        mountMain.recallpet(actor)
    end
end

-- 召唤灵兽（出战）
function mountMain.recallpet(actor)
    print("=== 召唤灵兽 ===")
    -- 清除灵兽死亡复活定时器
    disabletimer(actor, 49)
    
    local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)

    if not petBaseId or petBaseId == 0 then
        -- 如果没有设置基础ID，使用默认模型
        petBaseId = 900001
    end

    if not petTakeId or petTakeId == 0 then
        petTakeId = petBaseId
    end

    print("召唤灵兽，BaseId:", petBaseId, "TakeId:", petTakeId)

    -- 检查是否已有宠物mark，如果没有则先添加宠物
    local existingMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    local mark = existingMark
    
    -- 检查宠物是否已经在场上（通过getpetidx检查）
    if mark and mark ~= "" and getpetidx(actor, mark) then
        -- 宠物已经在场上，不需要再次添加
        print("灵兽已在场上，跳过添加")
    elseif not mark or mark == "" then
        -- 先添加宠物
        print("添加灵兽到列表")
        mark = addpet(actor, 80001)
        if not mark or mark == "" then
            print("添加灵兽失败")
            sendmsg(actor, 9, "添加灵兽失败")
            return
        end
        print("添加灵兽成功, mark:", mark)
        
        -- 保存宠物信息到 T_Pet_Mark
        sethumvar(actor, VarCfg.T_Pet_Mark, mark)
    end

    -- 从变量中获取mark确保有效
    mark = gethumvar(actor, VarCfg.T_Pet_Mark)
    print("使用本地mark:", mark)

    -- 召唤灵兽
    print("调用系统recallpet...")
    recallpet(actor, mark)
    print("系统recallpet执行完成")
    -- 设置出战状态
    sethumvar(actor, VarCfg.U_Pet_IS_SET, 1)

    -- 设置攻击模式（2=跟随主人攻击）
    setpetrelax(actor, mark, 2)

    -- 设置灵兽属性
    mountMain.setPetAttr(actor)

    -- 更新人物属性buff（出战状态下给予10%属性）
    mountMain.updatePetAttrBuff(actor)

    -- 更新灵兽外观显示
    changeappear(actor, 5, petTakeId)

    -- 发送召回结果消息给客户端
    Message.sendmsgEx(actor, "mountMain", "recallpetResult", {
        showPetModelId = petTakeId,
        selectViewPetId = petBaseId
    })
    
    -- 发送setPetInfo消息更新顶部灵兽图标（与旧系统对齐）
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"
    local max = 10000
    local now = 10000
    -- 从petHHlist配表获取icon，如果没有幻化则用默认图标
    local icon = "pet_000"
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
    if petTakeId and petTakeId > 0 then
        for _, v in pairs(petHHlist) do
            if v.ID == petTakeId and v.mount_icon then
                icon = v.mount_icon
                break
            end
        end
    end
    Message.sendmsgEx(actor, methodName, "setPetInfo", {
        type = "red",
        max = max,
        now = now,
        icon = icon
    })

    -- 发送petUpdateBtn消息更新按钮状态
    print("发送petUpdateBtn消息: isPetChuzhan=0")
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = 0,  -- 0=出战状态
        isPetJh = gethumvar(actor, VarCfg.U_All_Pet_star) > 0 and 1 or 0,
        allJieshu = gethumvar(actor, VarCfg.U_All_Pet_star)
    })
    print("petUpdateBtn消息已发送")

    print("召唤灵兽完成")
end

-- 收回灵兽
function mountMain.unrecallpet(actor, petMark)
    print("=== 收回灵兽 ===")
    -- 如果没有传入petMark，则从变量获取
    if not petMark then
        petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    end

    if not petMark or petMark == "" then
        print("没有出战的灵兽")
        return
    end

    -- 禁用灵兽复活定时器
    disabletimer(actor, 49)
    
    -- 收回灵兽
    unrecallpet(actor, petMark)

    -- 清除灵兽mark
    sethumvar(actor, VarCfg.T_Pet_Mark, "")
    -- 设置休息状态
    sethumvar(actor, VarCfg.U_Pet_IS_SET, 0)

    -- 清除人物属性buff
    delbuff(actor, PetBuffId)

    -- 发送收回结果消息给客户端
    Message.sendmsgEx(actor, "mountMain", "unrecallpetResult")

    -- 发送setPetInfo消息清除顶部灵兽图标（与旧系统对齐）
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"
    Message.sendmsgEx(actor, methodName, "setPetInfo", {
        type = "red",
        max = 1,
        now = 1
    })

    -- 发送petUpdateBtn消息更新按钮状态
    print("发送petUpdateBtn消息: isPetChuzhan=1")
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = 1,  -- 1=休息状态
        isPetJh = gethumvar(actor, VarCfg.U_All_Pet_star) > 0 and 1 or 0,
        allJieshu = gethumvar(actor, VarCfg.U_All_Pet_star)
    })
    print("petUpdateBtn消息已发送")

    print("收回灵兽完成")
end

-- 灵兽复活
function mountMain.resurre(actor)
    print("=== 灵兽复活 ===")
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    
    if not petMark or petMark == "" then
        print("没有灵兽需要复活")
        return
    end
    
    -- 复活宠物
    realivepet(actor, petMark)
    
    -- 重新召唤灵兽
    recallpet(actor, petMark)
    setpetrelax(actor, petMark, 2)
    
    -- 设置属性
    mountMain.setPetAttr(actor)
    mountMain.updatePetAttrBuff(actor)
    
    print("灵兽复活完成")
end

-- 灵兽升级接口（与旧系统对齐）
function mountMain.levelUp(actor, data)
    -- data.name = 灵兽名字, data.maxLv = 最大等级, data.itemId = 材料ID
    local nowlv = gethumvar(actor, VarCfg.U_All_Pet_star)
    
    if not nowlv or nowlv == 0 then
        return sendmsg(actor, 9, "请先激活灵兽")
    end
    
    local nextlv = nowlv + 1

    if nextlv > #petlist then
        return sendmsg(actor, 9, "已满级")
    end

    if not petlist[nowlv] or not petlist[nowlv].Cost then
        print("levelUp: 等级配置不存在, nowlv:", nowlv)
        return sendmsg(actor, 9, "配置错误")
    end

    local costs = petlist[nowlv].Cost
    local itemId = tonumber(costs[1])
    local num = tonumber(costs[2])

    if bagitemcount(actor, itemId) < num then
        return sendmsg(actor, 9, "材料不足" .. num .. "个")
    end

    -- 调用petShengji处理升级逻辑
    mountMain.petShengji(actor)

    -- 发送level消息与旧系统对齐
    local newLv = gethumvar(actor, VarCfg.U_All_Pet_star)
    -- 先发送updateLSView初始化allPetsActive表
    local allPets = {["pet"] = newLv}
    Message.sendmsgEx(actor, "mountMain", "updateLSView", {
        allPets = allPets,
        name = "pet",
        lv = newLv
    })
    -- 再发送level消息
    Message.sendmsgEx(actor, "mountMain", "level", {
        lv = newLv,
        Name = "pet"
    })

    -- 培养任务
    if newLv >= 10 then
        MentorShipChangTask(actor, 6, 1)
    end
end

-- function mountMain.addPetToList(actor, monsterId, modelId)
--     -- 旧的添加灵兽到列表逻辑需要根据实际情况重新实现
-- end

-- function mountMain.fhpet(actor)
--     -- 旧的灵符返还逻辑需要根据实际情况重新实现
-- end

-- function mountMain.applyPetBattleSkills(actor, petId, petLevel)
--     -- 旧的灵兽出战技能逻辑需要根据实际情况重新实现
-- end

-- function mountMain.clearPetBattleSkills(actor)
--     -- 旧的清除灵兽出战技能逻辑需要根据实际情况重新实现
-- end

-- ===== 游戏事件注册 =====

GameEvent.add(EventCfg.onPlayDie, function(actor, target)
    -- 兼容旧变量和新变量
    local oldBase = gethumvar(actor, VarCfg.U_PETS_Take_Base)
    local newBase = gethumvar(actor, VarCfg.U_Pet_Base_ID)
    if oldBase > 0 or newBase > 0 then
        mountMain.unrecallpet(actor, "", true)
    end
end, mountMain)
GameEvent.add(EventCfg.onPlayRealive, function(actor)
    print("=== 玩家复活，处理灵兽 ===")
    -- 检查灵兽是否已激活
    local isActivated = gethumvar(actor, VarCfg.U_All_Pet_star)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    
    print("复活检查：isActivated=", isActivated, "petMark=", petMark)
    
    -- 如果灵兽已激活且不在场上，则自动召唤
    if isActivated and isActivated > 0 and (not petMark or petMark == "") then
        print("灵兽已激活，自动召唤")
        mountMain.recallpet(actor)
    end
end, mountMain)

-- 角色登录完成时处理灵兽
GameEvent.add(EventCfg.onLoginEnd, function(actor)
    print("=== 登录完成处理灵兽 ===")
    -- 更新灵兽属性buff
    mountMain.updatePetAttrBuff(actor)
    
    -- 检查是否需要自动召唤灵兽
    local isActivated = gethumvar(actor, VarCfg.U_All_Pet_star)
    local isChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    
    print("登录检查：isActivated=", isActivated, "isChuzhan=", isChuzhan, "petMark=", petMark)
    
    -- 如果灵兽已激活且之前处于出战状态（isChuzhan=1），则自动召唤
    if isActivated and isActivated > 0 and isChuzhan == 1 then
        print("灵兽之前处于出战状态，登录自动召唤")
        -- 自动召唤灵兽
        local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
        local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
        
        if not petBaseId or petBaseId == 0 then
            petBaseId = 900001
        end
        if not petTakeId or petTakeId == 0 then
            petTakeId = petBaseId
        end
        
        -- 添加宠物并召唤
        local mark = addpet(actor, 80001)
        if mark and mark ~= "" then
            print("登录自动召唤灵兽成功，mark:", mark)
            sethumvar(actor, VarCfg.T_Pet_Mark, mark)
            sethumvar(actor, VarCfg.U_Pet_IS_SET, 1)
            -- 清除灵兽死亡复活定时器
            disabletimer(actor, 49)
            recallpet(actor, mark)
            setpetrelax(actor, mark, 2)
            mountMain.setPetAttr(actor)
            mountMain.updatePetAttrBuff(actor)
            changeappear(actor, 5, petTakeId)
            
            -- 发送setPetInfo消息更新顶部灵兽图标
            local isPc = clientflag(actor) == 1
            local methodName = isPc and "PCMainPlayer" or "MainPlayer"
            local icon = "pet_000"
            if petTakeId and petTakeId > 0 then
                for _, v in pairs(petHHlist) do
                    if v.ID == petTakeId and v.mount_icon then
                        icon = v.mount_icon
                        break
                    end
                end
            end
            Message.sendmsgEx(actor, methodName, "setPetInfo", {
                type = "red",
                max = 10000,
                now = 10000,
                icon = icon
            })
            
            print("登录自动召唤灵兽完成")
        else
            print("登录自动召唤灵兽失败")
        end
    end
end, mountMain)

Message.RegisterNetMsg(ssrNetMsgCfg.mountMain, mountMain)

return mountMain
