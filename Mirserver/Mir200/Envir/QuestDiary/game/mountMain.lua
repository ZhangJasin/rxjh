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

-- 灵兽额外加成比例(出战灵兽)
local PetExtraRate = {attrRate = 0.03}

-- 灵兽buff配置
local PetBuffId = 110044
local BattlePetBuffId = 110045

-- 经验加成属性ID(万分比,10000=100%)
local ExpAttrId = 12

-- ===== 新的灵兽功能（与坐骑结构一致）=====

-- 更新灵兽属性加成到人物（与坐骑结构一致）
function mountMain.updatePetAttrBuff(actor)
    local allstar = gethumvar(actor, VarCfg.U_All_Pet_star)
    if not allstar or allstar == 0 then
        delbuff(actor, PetBuffId)
        return
    end

    -- 灵兽星星属性（与坐骑相同的结构）
    if petlist[allstar] and petlist[allstar].ClassID then
        local classIds = petlist[allstar].ClassID
        for b = 1, #classIds do
            setbuffabil(actor, PetBuffId, tonumber(classIds[b][1]), "=",
                        tonumber(classIds[b][2]))
        end
    end

    -- 灵兽幻化属性（与坐骑相同的结构）
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

    -- 应用幻化属性
    for g, h in pairs(hhsxListStr) do
        setbuffabil(actor, PetBuffId, tonumber(g), "=", tonumber(h))
    end
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

    local classIds = petlist[nextlv].ClassID
    local costs = petlist[nowlv].Cost
    local itemId = tonumber(costs[1])
    local num = tonumber(costs[2])

    print("材料ID:", itemId, "需要数量:", num, "拥有数量:", bagitemcount(actor, itemId))

    if bagitemcount(actor, itemId) < num then
        print("材料不足")
        sendmsg(actor, 9, "材料不足" .. num .. "个")
    else
        print("材料充足,开始升级/激活")
        if nowlv == 0 then -- 激活
            print("首次激活灵兽")
            sethumvar(actor, VarCfg.T_PetHuanHua, tbl2json({}))
            sethumvar(actor, VarCfg.U_All_Pet_star, 1)
            sethumvar(actor, VarCfg.U_Pet_IS_SET, 1)
            print("设置激活状态完成")
        end

        -- 添加属性buff
        for b = 1, #classIds do
            setbuffabil(actor, PetBuffId, tonumber(classIds[b][1]), "=",
                        tonumber(classIds[b][2]))
        end

        delItemNum(actor, itemId, num)
        sethumvar(actor, VarCfg.U_All_Pet_star, nextlv)

        local petBaseId = petlist[nextlv].Model
        print("灵兽基础模型ID:", petBaseId)

        -- 当前模型是否幻化
        if gethumvar(actor, VarCfg.U_Pet_IS_HH) == 0 then
            sethumvar(actor, VarCfg.U_Pet_Take_Id, petBaseId)
            print("设置灵兽当前使用模型:", petBaseId)
        end
        sethumvar(actor, VarCfg.U_Pet_Base_ID, petBaseId)
        print("设置灵兽基础模型:", petBaseId)

        -- 更新前端显示
        print("发送升级消息到客户端,等级:", nextlv)
        Message.sendmsgEx(actor, "mountMain", "updatePetZQ", {
            lv = nextlv,
            petBaseId = petBaseId
        })
        print("升级完成")
    end
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

            -- 应用幻化属性
            for g, h in pairs(hhsxListStr) do
                setbuffabil(actor, PetBuffId, tonumber(g), "=", tonumber(h))
            end

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

-- 灵兽激活/升级接口
function mountMain.lsjihuo(actor, data)
    -- data.itemId = 激活材料ID
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

-- 灵兽升级接口
function mountMain.levelUp(actor, data)
    -- data.name = 灵兽名字, data.maxLv = 最大等级, data.itemId = 材料ID
    mountMain.petShengji(actor)
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
    -- 兼容旧变量和新变量
    local oldBase = gethumvar(actor, VarCfg.U_PETS_Take_Base)
    local newBase = gethumvar(actor, VarCfg.U_Pet_Base_ID)
    if oldBase > 0 or newBase > 0 then
        local btid = newBase > 0 and newBase or oldBase
        mountMain.recallpet(actor, {btid = btid})
    end
end, mountMain)

-- 角色登录时更新灵兽属性buff
GameEvent.add(EventCfg.onLogin,
              function(actor) mountMain.updatePetAttrBuff(actor) end, mountMain)

Message.RegisterNetMsg(ssrNetMsgCfg.mountMain, mountMain)

return mountMain
