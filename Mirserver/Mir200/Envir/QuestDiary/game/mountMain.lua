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

-- 灵兽属性转化比例配置表（按等级阶梯）
-- 格式：{minLevel, maxLevel, rate}  表示 minLevel-maxLevel 等级段使用 rate 转化比例
local PetLevelRateConfig = {
    { 1,   10,  0.03 }, -- 1-10级 3%
    { 11,  20,  0.04 }, -- 11-20级 4%
    { 21,  30,  0.05 }, -- 21-30级 5%
    { 31,  40,  0.06 }, -- 31-40级 6%
    { 41,  50,  0.08 }, -- 41-50级 8%
    { 51,  60,  0.10 }, -- 51-60级 10%
    { 61,  70,  0.12 }, -- 61-70级 12%
    { 71,  80,  0.15 }, -- 71-80级 15%
    { 81,  90,  0.18 }, -- 81-90级 18%
    { 91,  100, 0.18 }, -- 91-100级 21%
    { 101, 110, 0.18 }, -- 101-110级 25%
}

-- 根据等级获取转化比例
local function getPetAttrRateByLevel(level)
    for _, config in ipairs(PetLevelRateConfig) do
        if level >= config[1] and level <= config[2] then
            return config[3]
        end
    end
    -- 默认返回最低档比例
    return PetLevelRateConfig[1][3]
end

-- 灵兽buff配置
-- 110044: 灵兽出战属性（灵兽基础属性×10%）
-- 110045: 灵兽幻化战斗技能（配表 BattleSkill_Value 固定值）
-- 110047: 灵兽幻化属性（配表 ClassID 固定值）
local PetBuffId = 110044
local PetSkillBuffId = 110045
local HuanhuaBuffId = 110047

-- 坐骑buff配置
-- 110015: 坐骑激活/升级属性（配表固定值）+ 出战属性（移动速度+10%）
-- 110016: 坐骑幻化属性（配表 ClassID 固定值）
-- 110046: 坐骑出战幻化（配表 BattleSkill 固定值）
local MountBuffId = 110015
local MountHuanhuaBuffId = 110016
local MountBattleSkillBuffId = 110046

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
    if not ycList or not next(ycList) then
        return hhsxListStr
    end
    for l, v in pairs(ycList) do
        if l then
            local jhhhlist = {}
            for e = 1, #petHHlist do
                if petHHlist[e] and petHHlist[e].Name == l and petHHlist[e].grade == v then
                    jhhhlist[#jhhhlist + 1] = petHHlist[e]
                end
            end
            for r = 1, #jhhhlist do
                local classIds = jhhhlist[r].ClassID
                if classIds then
                    for b = 1, #classIds do
                        if classIds[b] then
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
        end
    end
    return hhsxListStr
end

-- 获取灵兽幻化的战斗技能属性
function mountMain.getPetBattleSkillAttr(actor)
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
    if not petTakeId or petTakeId == 0 then
        return {}
    end

    local battleAttr = {}
    for i = 1, #petHHlist do
        if petHHlist[i].Model == petTakeId then
            local skillType = petHHlist[i].BattleSkill_Type
            local skillValue = petHHlist[i].BattleSkill_Value

            if skillType and skillValue then
                if type(skillType) == "table" then
                    for idx = 1, #skillType do
                        local attrId = tonumber(skillType[idx])
                        local attrValue = tonumber(skillValue[idx])
                        if attrId and attrValue then
                            battleAttr[attrId] = attrValue
                        end
                    end
                else
                    local attrId = tonumber(skillType)
                    local attrValue = tonumber(skillValue)
                    if attrId and attrValue then
                        battleAttr[attrId] = attrValue
                    end
                end
            end
            break
        end
    end
    return battleAttr
end

-- 设置/更新灵兽幻化战斗技能buff
function mountMain.updatePetBattleSkillBuff(actor)
    delbuff(actor, PetSkillBuffId)
    local battleAttr = mountMain.getPetBattleSkillAttr(actor)

    if next(battleAttr) then
        addbuff(actor, PetSkillBuffId)
        for attrId, attrValue in pairs(battleAttr) do
            setbuffabil(actor, PetSkillBuffId, tonumber(attrId), "=", tonumber(attrValue))
        end
    end
end

-- 获取坐骑幻化的战斗技能属性
function mountMain.getMountBattleSkillAttr(actor)
    local mountTakeId = gethumvar(actor, VarCfg.U_Mount_Take_Id)
    if not mountTakeId or mountTakeId == 0 then
        return {}
    end

    local battleAttr = {}
    -- 查找当前幻化模型对应的配表数据
    for i = 1, #mountHHlist do
        if mountHHlist[i].Model == mountTakeId then
            local skillType = mountHHlist[i].BattleSkill_Type
            local skillValue = mountHHlist[i].BattleSkill_Value

            if skillType and skillValue then
                if type(skillType) == "table" then
                    for idx = 1, #skillType do
                        local attrId = tonumber(skillType[idx])
                        local attrValue = tonumber(skillValue[idx])
                        if attrId and attrValue then
                            battleAttr[attrId] = attrValue
                        end
                    end
                else
                    local attrId = tonumber(skillType)
                    local attrValue = tonumber(skillValue)
                    if attrId and attrValue then
                        battleAttr[attrId] = attrValue
                    end
                end
            end
            break
        end
    end
    return battleAttr
end

-- 设置/更新坐骑幻化战斗技能buff
function mountMain.updateMountBattleSkillBuff(actor)
    -- 先清除旧的battle skill buff
    delbuff(actor, MountBattleSkillBuffId)

    local battleAttr = mountMain.getMountBattleSkillAttr(actor)

    if next(battleAttr) then
        -- 先添加buff
        addbuff(actor, MountBattleSkillBuffId)
        -- 再设置属性
        for attrId, attrValue in pairs(battleAttr) do
            setbuffabil(actor, MountBattleSkillBuffId, tonumber(attrId), "=", tonumber(attrValue))
        end
    end
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
        print("灵兽升级定点排查1111")
        -- 即使没有召唤灵兽，仍然更新人物属性
        mountMain.updatePetAttrBuff(actor)
        return
    end

    local petidx = getpetidx(actor, mark)
    if not petidx then
        print("setPetAttr: 灵兽不存在，仅设置人物属性")
        print("灵兽升级定点排查2222")
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

-- 更新灵兽属性加成到人物
-- 计算规则：
-- 1. buff 110044 - 灵兽出战属性 = 灵兽基础属性 × 10%
-- 2. buff 110047 - 灵兽幻化属性 = 配表 ClassID 固定值（休息时也有）
-- 注意：110045 由 updatePetBattleSkillBuff 设置（配表 BattleSkill_Value 固定值）
function mountMain.updatePetAttrBuff(actor)
    print("mountMain.updatePetAttrBuff")
    local allstar = gethumvar(actor, VarCfg.U_All_Pet_star)
    print("allstar", allstar)
    if not allstar or allstar == 0 then
        -- 未激活灵兽，删除相关buff
        delbuff(actor, PetBuffId)
        delbuff(actor, HuanhuaBuffId)
        return
    end
    print("updatePetAttrBuff: 开始执行")

    -- 检查灵兽是否出战
    local isBattle = gethumvar(actor, VarCfg.U_Pet_IS_SET)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    dump(isBattle)
    dump(petMark)

    -- 获取幻化属性
    local hhAttr = mountMain.getPetHHAttr(actor)
    print("获取幻化属性")
    dump(hhAttr)

    -- 如果没有召唤灵兽（休息状态）
    if not isBattle or isBattle == 0 or not petMark or petMark == "" then
        delbuff(actor, PetBuffId)
        print("灵兽休息状态")
        -- 休息时只设置幻化属性到 buff 110047
        if next(hhAttr) then
            print("next(hhAttr)")
            delbuff(actor, HuanhuaBuffId)
            addbuff(actor, HuanhuaBuffId)
            for attrId, attrValue in pairs(hhAttr) do
                setbuffabil(actor, HuanhuaBuffId, tonumber(attrId), "=", tonumber(attrValue))
            end
            print("updatePetAttrBuff: 灵兽休息，设置幻化属性到 buff", HuanhuaBuffId)
        else
            delbuff(actor, HuanhuaBuffId)
        end
        return
    end

    -- 出战状态：设置所有属性

    -- 设置灵兽基础属性×等级比例到 buff 110044
    delbuff(actor, PetBuffId)
    addbuff(actor, PetBuffId)
    local petAttr = mountMain.getPetAttrByLevel(allstar)
    local attrRate = getPetAttrRateByLevel(allstar)
    for attrId, attrValue in pairs(petAttr) do
        local finalValue = math.ceil(attrValue * attrRate)
        setbuffabil(actor, PetBuffId, tonumber(attrId), "=", finalValue)
    end

    -- 出战时也保留幻化属性到 buff 110047
    if next(hhAttr) then
        delbuff(actor, HuanhuaBuffId)
        addbuff(actor, HuanhuaBuffId)
        for attrId, attrValue in pairs(hhAttr) do
            setbuffabil(actor, HuanhuaBuffId, tonumber(attrId), "=", tonumber(attrValue))
        end
        print("updatePetAttrBuff: 灵兽出战，设置灵兽×10%到 buff", PetBuffId, "，幻化属性到 buff", HuanhuaBuffId)
    else
        delbuff(actor, HuanhuaBuffId)
    end
    -- 注意：110045 幻化战斗技能由 updatePetBattleSkillBuff 单独管理
end

-- 灵兽升级（与坐骑升级相同的结构）
function mountMain.petShengji(actor)
    local nowlv = gethumvar(actor, VarCfg.U_All_Pet_star)
    local nextlv = nowlv + 1
    print("=== 灵兽升级/激活 ===")
    print("当前等级:", nowlv, "下一等级:", nextlv, "最高等级:", #petlist)
    if nextlv > #petlist then
        print("已达到最高等级")
        sendmsg(actor, 9, "已达到最高等级")
        return
    end

    if not petlist[nextlv] or not petlist[nextlv].ClassID then
        print("petShengji: 下一级配置不存在, nextlv:", nextlv)
        sendmsg(actor, 9, "配置错误")
        return
    end

    if not petlist[nowlv] or not petlist[nowlv].Cost then
        print("petShengji: 当前级配置不存在, nowlv:", nowlv)
        sendmsg(actor, 9, "配置错误")
        return
    end

    local classIds = petlist[nextlv].ClassID
    local costs = petlist[nowlv].Cost

    -- 支持多消耗格式：2801^40|3958^5
    -- 检查是否是多重消耗格式：costs[1] 是 table 而不是 number
    local isMultiCost = (type(costs[1]) == "table")

    if isMultiCost then
        -- 多重消耗格式：{[1] = {[1] = itemId, [2] = num}, [2] = {[1] = itemId, [2] = num}}
        print("检测到多重消耗格式")
        local allEnough = true
        local lackItems = {}
        for i = 1, #costs do
            local itemId = tonumber(costs[i][1])
            local num = tonumber(costs[i][2])
            local haveCount = bagitemcount(actor, itemId)
            print("材料" .. i .. " ID:", itemId, "需要:", num, "拥有:", haveCount)
            if haveCount < num then
                allEnough = false
                table.insert(lackItems, { id = itemId, need = num, have = haveCount })
            end
        end

        if not allEnough then
            print("多材料不足")
            local msg = "材料不足"
            if #lackItems > 0 then
                msg = "材料不足"
            end
            sendmsg(actor, 9, msg)
            return
        end

        -- 扣除所有材料
        print("材料充足,开始扣除所有材料")
        for i = 1, #costs do
            local itemId = tonumber(costs[i][1])
            local num = tonumber(costs[i][2])
            delItemNum(actor, itemId, num)
            print("扣除材料" .. i .. " ID:", itemId, "数量:", num)
        end
    else
        -- 单消耗格式（兼容旧数据）
        local itemId = tonumber(costs[1])
        local num = tonumber(costs[2])

        print("材料ID:", itemId, "需要数量:", num, "拥有数量:", bagitemcount(actor, itemId))

        if bagitemcount(actor, itemId) < num then
            print("材料不足")
            sendmsg(actor, 9, "材料不足" .. num .. "个")
            return
        end

        print("材料充足,开始升级/激活")
        delItemNum(actor, itemId, num)
    end
    -- 0阶9星(Level=9) → 0阶10星(Level=10)：正常升星
    -- 0阶10星(Level=10) → 1阶1星(Level=11)：跨阶，重置星星为1
    local nowLevel = 0
    local nextLevel = 0
    if petlist[nowlv] and petlist[nowlv].Level then
        nowLevel = petlist[nowlv].Level
    end
    if petlist[nextlv] and petlist[nextlv].Level then
        nextLevel = petlist[nextlv].Level
    end

    local isShengjie = (nowLevel % 10 == 0 and nextLevel == nowLevel + 1)

    if nowlv == 0 then
        sethumvar(actor, VarCfg.T_PetHuanHua, tbl2json({}))
        sethumvar(actor, VarCfg.U_All_Pet_star, 1)
        sethumvar(actor, VarCfg.U_Pet_IS_SET, 0)
        sethumvar(actor, VarCfg.U_Pet_IS_HH, 0)

        -- 首次激活时，自动激活第一个幻化（免费）
        local firstHH = petHHlist[1]
        if firstHH then
            local ycList = {}
            ycList[firstHH.Name] = firstHH.grade
            sethumvar(actor, VarCfg.T_PetHuanHua, tbl2json(ycList))
            -- 设置幻化外观
            sethumvar(actor, VarCfg.U_Pet_Take_Id, firstHH.Model)
            sethumvar(actor, VarCfg.U_Pet_IS_HH, 1)
            changeappear(actor, 5, firstHH.Model)
            -- 注意：幻化属性由 updatePetAttrBuff 统一管理，这里不需要单独设置
            -- 添加幻化buff
            if firstHH.buffID then
                for b = 1, #firstHH.buffID do
                    addbuff(actor, firstHH.buffID[b])
                end
            end
            Message.sendmsgEx(actor, "mountMain", "updatePetHHmodel", {
                ycList = ycList,
                name = firstHH.Name,
                grade = firstHH.grade,
                petHHid = firstHH.Model
            })
        end
    end

    -- 与坐骑逻辑一致：直接存储完整的等级，客户端通过计算显示阶数和星星
    sethumvar(actor, VarCfg.U_All_Pet_star, nextlv)
    print("设置灵兽等级:", nextlv)

    -- 设置灵兽本身的属性（将配表属性赋予灵兽，并设置人物属性）
    mountMain.setPetAttr(actor)
    -- 更新灵兽幻化战斗技能buff
    mountMain.updatePetBattleSkillBuff(actor)
    -- 更新灵兽属性buff（休息时设置幻化属性到 buff 110047）
    mountMain.updatePetAttrBuff(actor)

    local petBaseId = petlist[nextlv].Model
    print("灵兽基础模型ID:", petBaseId)

    -- 当前模型是否幻化
    if gethumvar(actor, VarCfg.U_Pet_IS_HH) == 0 then
        sethumvar(actor, VarCfg.U_Pet_Take_Id, petBaseId)
        print("设置灵兽当前使用模型:", petBaseId)
    end
    sethumvar(actor, VarCfg.U_Pet_Base_ID, petBaseId)
    print("设置灵兽基础模型:", petBaseId)

    -- 注意：灵兽激活不应该改变人物外观！
    -- 人物外观只由坐骑控制，与旧系统一致

    -- 触发灵兽升级事件（与旧系统对齐）
    local allPets = { pet = nextlv }
    GameEvent.push(EventCfg.onPetLevel, actor, allPets)

    -- 更新前端显示（发送updateLSView消息与旧系统对齐）
    -- 与坐骑一致：发送完整的等级
    print("发送升级消息到客户端,等级:", nextlv)

    -- 检查灵兽是否有幻化，如果有则发送幻化模型ID
    local showPetModelId = 0
    local isPetHH = gethumvar(actor, VarCfg.U_Pet_IS_HH)
    if isPetHH and isPetHH == 1 then
        showPetModelId = gethumvar(actor, VarCfg.U_Pet_Take_Id) or 0
    end

    Message.sendmsgEx(actor, "mountMain", "updateLSView", {
        lv = nextlv,
        petBaseId = petBaseId,
        name = "pet",
        showPetModelId = showPetModelId
    })
    -- 同时发送updatePetZQ消息保持兼容性
    Message.sendmsgEx(actor, "mountMain", "updatePetZQ", {
        lv = nextlv,
        petBaseId = petBaseId,
        showPetModelId = showPetModelId
    })

    -- 发送petUpdateBtn消息更新按钮状态
    -- 服务端：U_Pet_IS_SET = 0 表示休息，1 表示出战
    -- 客户端：isPetChuzhan = 0 表示休息（显示"出战"按钮），1 表示出战（显示"召回"按钮）
    -- 直接传递服务端值，不需要转换
    local isPetChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET) or 0
    local isPetJh = gethumvar(actor, VarCfg.U_All_Pet_star)
    print("发送petUpdateBtn消息：U_Pet_IS_SET=", isPetChuzhan, "isPetJh=", isPetJh)
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = isPetChuzhan,
        isPetJh = isPetJh
    })

    -- 升级后更新顶部灵兽图标（只在升级时更新，激活时不更新）
    -- 注意：只在已出战状态下才更新图标
    local serverChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET) or 0
    if serverChuzhan == 1 then -- 只有出战状态才更新图标
        local isPc = clientflag(actor) == 1
        local methodName = isPc and "PCMainPlayer" or "MainPlayer"
        local icon = "pet_000"
        local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
        local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
        -- 使用 v.Model 查找（与登录时保持一致）
        if petTakeId and petTakeId > 0 then
            for _, v in pairs(petHHlist) do
                if v.Model == petTakeId and v.mount_icon then
                    icon = v.mount_icon
                    print("升级更新图标，找到icon:", icon)
                    break
                end
            end
        end
        print("升级发送setPetInfo，icon:", icon)
        Message.sendmsgEx(actor, methodName, "setPetInfo", {
            type = "red",
            max = 10000,
            now = 10000,
            icon = icon
        })
    end
end

-- 灵兽幻化激活
function mountMain.petHuanhuajihuo(actor, postData)
    if not postData then
        return
    end

    local name = postData.Name
    local grade = postData.grade
    local data = nil

    for i = 1, #petHHlist do
        if tostring(petHHlist[i].Name) == tostring(name) and tonumber(petHHlist[i].grade) == tonumber(grade) then
            data = petHHlist[i]
            break
        end
    end

    if data then
        local costs = data.Cost
        local itemId = tonumber(costs[1])
        local num = tonumber(costs[2])

        if getItemNum(actor, itemId) < num then
            sendmsg(actor, 9, "激活材料不足" .. num .. "个")
        else
            local ycList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))

            delItemNum(actor, itemId, num)

            ycList[data.Name] = grade
            sethumvar(actor, VarCfg.T_PetHuanHua, tbl2json(ycList))

            local petHHid = gethumvar(actor, VarCfg.U_Pet_Take_Id)
            if gethumvar(actor, VarCfg.U_Pet_IS_HH) == 1 then
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

            mountMain.updatePetAttrBuff(actor)
            mountMain.updatePetBattleSkillBuff(actor)

            sethumvar(actor, VarCfg.U_Pet_IS_HH, 1)
            Message.sendmsgEx(actor, "mountMain", "updatePetHHmodel", {
                ycList = ycList,
                name = name,
                grade = grade,
                petHHid = petHHid
            })
        end
    else
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
    print("=== setPetModel 被调用 ===")
    print("data:", type(data), data)
    -- {"幻化名字"=幻化品阶}
    local allhhList = {}
    local basePetId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
    print("basePetId:", basePetId, "petTakeId:", petTakeId)
    local oldPetTakeId = petTakeId
    local bdid = 0
    local isCancel = 0
    local oldbuffList = {}
    local newBuffList = {}

    print("判断: petTakeId:", petTakeId, "== data.mountId:", data.mountId, "?", petTakeId == data.mountId)
    if petTakeId == data.mountId then
        -- 取消幻化
        print("执行取消幻化")
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
        print("执行幻化")
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
    -- 设置当前显示的模型ID
    sethumvar(actor, VarCfg.U_Pet_Now_Model, petTakeId)

    -- 如果灵兽已经出战，需要召回再重新召唤（与旧系统对齐）
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if petMark and petMark ~= "" then
        print("幻化时灵兽已出战，召回并重新召唤")
        -- 彻底删除旧宠物并重新添加
        unrecallpet(actor, petMark)
        delpet(actor, petMark)
        -- 清除旧的mark
        sethumvar(actor, VarCfg.T_Pet_Mark, "")
        -- 强制使用新模型ID重新召唤
        sethumvar(actor, VarCfg.U_Pet_Take_Id, petTakeId)
        -- 重新召唤
        mountMain.recallpet(actor)
    end
    -- 重新计算并应用所有灵兽属性
    mountMain.updatePetAttrBuff(actor)
    -- 更新灵兽幻化战斗技能buff
    mountMain.updatePetBattleSkillBuff(actor)
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

    -- 如果灵兽已出战，发送setPetInfo消息更新顶部灵兽图标
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if petMark and petMark ~= "" then
        local isPc = clientflag(actor) == 1
        local methodName = isPc and "PCMainPlayer" or "MainPlayer"
        -- 如果是取消幻化(isCancel=1)或没有新的幻化，使用默认图标
        local icon = "pet_000"
        -- 检查是否有有效幻化
        if isCancel == 0 and petTakeId and petTakeId > 0 then
            local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
            if petTakeId ~= petBaseId then
                for _, v in pairs(petHHlist) do
                    if v.Model == petTakeId and v.mount_icon then
                        icon = v.mount_icon
                        print("幻化切换后更新顶部图标(幻化):", icon)
                        break
                    end
                end
            end
        else
            print("幻化切换后更新顶部图标(默认)")
        end
        Message.sendmsgEx(actor, methodName, "setPetInfo", {
            type = "red",
            max = 10000,
            now = 10000,
            icon = icon
        })
    end
end

-- ===== 坐骑功能（保留原有功能）=====

function mountMain.openshow(actor, data)
    Message.sendmsgEx(actor, "mountMain", "Open", {})

    -- 发送petUpdateBtn消息更新按钮状态
    -- 服务端：U_Pet_IS_SET = 1 表示出战，0 表示休息
    -- 客户端：isPetChuzhan = 0 表示已召唤（显示召回），1 表示未召唤（显示出战）
    -- 需要转换：客户端值 = 1 - 服务端值
    local serverChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET) or 0
    local isPetChuzhan = 1 - serverChuzhan -- 转换
    local isPetJh = gethumvar(actor, VarCfg.U_All_Pet_star) or 0
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = isPetChuzhan,
        isPetJh = isPetJh > 0 and 1 or 0,
        allJieshu = isPetJh
    })

    -- 如果灵兽已出战，发送setPetInfo消息更新顶部灵兽图标
    if serverChuzhan == 1 then
        local isPc = clientflag(actor) == 1
        local methodName = isPc and "PCMainPlayer" or "MainPlayer"
        -- 如果有幻化则使用幻化图标，否则使用默认图标
        local icon = "pet_000"
        local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
        local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
        if petTakeId and petTakeId > 0 and petTakeId ~= petBaseId then
            for _, v in pairs(petHHlist) do
                -- 使用 Model 字段匹配（U_Pet_Take_Id 存储的是 Model 值）
                if v.Model == petTakeId and v.mount_icon then
                    icon = v.mount_icon
                    print("上线恢复灵兽顶部图标(幻化):", icon)
                    break
                end
            end
        else
            print("上线恢复灵兽顶部图标(默认)")
        end
        Message.sendmsgEx(actor, methodName, "setPetInfo", {
            type = "red",
            max = 10000,
            now = 10000,
            icon = icon
        })
    end
end

-- 更新坐骑增加属性
-- 计算规则：
-- 1. buff 110015 - 坐骑激活/升级属性（配表固定值）+ 出战属性（移动速度+10%）
-- 2. buff 110016 - 坐骑幻化属性（配表 ClassID 固定值）
-- 3. buff 110046 - 坐骑出战幻化（配表 BattleSkill 固定值，由 updateMountBattleSkillBuff 管理）
function mountMain.updateMountAttrBuff(actor)
    print("updateMountAttrBuff: 函数被调用")
    local allstar = gethumvar(actor, VarCfg.U_All_Mount_star)
    print("updateMountAttrBuff: allstar =", allstar)
    if not allstar or allstar == 0 then
        -- 未激活坐骑，删除相关buff
        delbuff(actor, MountBuffId)
        delbuff(actor, MountHuanhuaBuffId)
        return
    end

    -- 检查坐骑是否已激活
    local isMountActive = gethumvar(actor, VarCfg.U_Mount_IS_SET)
    print("updateMountAttrBuff: isMountActive =", isMountActive)

    if not isMountActive or isMountActive == 0 then
        -- 坐骑未激活
        delbuff(actor, MountBuffId)
        delbuff(actor, MountHuanhuaBuffId)
        return
    end

    -- 清除旧buff
    delbuff(actor, MountBuffId)
    delbuff(actor, MountHuanhuaBuffId)

    -- 添加buff
    addbuff(actor, MountBuffId)
    addbuff(actor, MountHuanhuaBuffId)

    -- 1. 设置坐骑激活/升级属性到 buff 110015
    if mountlist[allstar] and mountlist[allstar].ClassID then
        local classIds = mountlist[allstar].ClassID
        for b = 1, #classIds do
            setbuffabil(actor, MountBuffId, tonumber(classIds[b][1]), "=", tonumber(classIds[b][2]))
        end
    end

    -- 2. 设置出战属性（移动速度+10%，属性ID 140）
    -- 万分比，1000 = 10%
    setbuffabil(actor, MountBuffId, 140, "+", 1000)

    -- 3. 设置坐骑幻化属性到 buff 110016（累加多个幻化的属性）
    local ycListJson = gethumvar(actor, VarCfg.T_MountHuanHua)
    local ycList = json2tbl(ycListJson)

    -- 先收集所有幻化属性到临时表
    local totalAttr = {}
    for l, v in pairs(ycList) do
        for e = 1, #mountHHlist do
            if mountHHlist[e].Name == l and mountHHlist[e].grade == v then
                local classIds = mountHHlist[e].ClassID
                if classIds then
                    for b = 1, #classIds do
                        local attrId = tonumber(classIds[b][1])
                        local attrValue = tonumber(classIds[b][2])
                        if attrId and attrValue then
                            totalAttr[attrId] = (totalAttr[attrId] or 0) + attrValue
                        end
                    end
                end
            end
        end
    end

    -- 然后一次性设置所有属性
    for attrId, attrValue in pairs(totalAttr) do
        setbuffabil(actor, MountHuanhuaBuffId, attrId, "=", attrValue)
    end
    print("updateMountAttrBuff: 幻化属性设置完成, 属性数量 =", #totalAttr)
end

-- 兼容旧函数
function mountMain.addsx(actor)
    mountMain.updateMountAttrBuff(actor)
end

function mountMain.shengji(actor)
    local nowlv = gethumvar(actor, VarCfg.U_All_Mount_star) or 0
    local nextlv = nowlv + 1
    if nextlv > #mountlist then return end
    if not mountlist[nextlv] or not mountlist[nextlv].ClassID then
        print("shengji: 下一级配置不存在, nextlv:", nextlv)
        return
    end
    if not mountlist[nowlv] or not mountlist[nowlv].Cost then
        print("shengji: 当前级配置不存在, nowlv:", nowlv)
        return
    end
    local classIds = mountlist[nextlv].ClassID
    local costs = mountlist[nowlv].Cost

    -- 支持多消耗格式：itemId^num|itemId2^num2
    -- 检查是否是多重消耗格式：costs[1] 是 table 而不是 number
    local isMultiCost = (type(costs[1]) == "table")

    if isMultiCost then
        -- 多重消耗格式
        local allEnough = true
        for i = 1, #costs do
            local itemId = tonumber(costs[i][1])
            local num = tonumber(costs[i][2])
            if bagitemcount(actor, itemId) < num then
                allEnough = false
                break
            end
        end

        if not allEnough then
            sendmsg(actor, 9, "材料不足")
            return
        end

        -- 扣除所有材料
        for i = 1, #costs do
            local itemId = tonumber(costs[i][1])
            local num = tonumber(costs[i][2])
            delItemNum(actor, itemId, num)
            print("坐骑升级扣除材料" .. i .. " ID:", itemId, "数量:", num)
        end
    else
        -- 单消耗格式（兼容旧数据）
        local itemId = tonumber(costs[1])
        local num = tonumber(costs[2])
        if bagitemcount(actor, itemId) < num then
            sendmsg(actor, 9, "材料不足" .. num .. "个")
            return
        end
        delItemNum(actor, itemId, num)
    end

    if nowlv == 0 then -- 激活
        sethumvar(actor, VarCfg.T_MountHuanHua, tbl2json({}))
        sethumvar(actor, VarCfg.U_All_Mount_star, 1)
        sethumvar(actor, VarCfg.U_Mount_IS_SET, 1)

        -- 首次激活时，自动激活第一个幻化（免费）
        local firstHH = mountHHlist[1]
        if firstHH then
            local ycList = {}
            ycList[firstHH.Name] = firstHH.grade
            sethumvar(actor, VarCfg.T_MountHuanHua, tbl2json(ycList))
            -- 设置幻化外观
            sethumvar(actor, VarCfg.U_Mount_Take_Id, firstHH.Model)
            sethumvar(actor, VarCfg.U_Mount_IS_HH, 1)
            changeappear(actor, 5, firstHH.Model)
            -- 添加幻化buff
            if firstHH.buffID then
                for b = 1, #firstHH.buffID do
                    addbuff(actor, firstHH.buffID[b])
                end
            end
            Message.sendmsgEx(actor, "mountMain", "updateHHmodel", {
                ycList = ycList,
                name = firstHH.Name,
                grade = firstHH.grade,
                mountHHid = firstHH.Model
            })
        end
    end

    sethumvar(actor, VarCfg.U_All_Mount_star, nextlv)
    local mountBaseId = mountlist[nextlv].Model
    -- 当前模型是否幻化
    if gethumvar(actor, VarCfg.U_Mount_IS_HH) == 0 then
        changeappear(actor, 5, mountBaseId)
        sethumvar(actor, VarCfg.U_Mount_Take_Id, mountBaseId)
    end
    sethumvar(actor, VarCfg.U_Mount_Base_ID, mountBaseId)
    Message.sendmsgEx(actor, "mountMain", "updateZQ",
        { lv = nextlv, mountBaseId = mountBaseId })
    MentorShipChangTask(actor, 6, 1, nextlv)
    print("shengji: nowlv =", nowlv, "nextlv =", nextlv)
    -- 统一更新坐骑属性buff
    mountMain.updateMountAttrBuff(actor)
    -- 更新坐骑幻化战斗技能buff
    mountMain.updateMountBattleSkillBuff(actor)
    -- 同步更新灵兽属性buff（确保不影响灵兽属性）
    mountMain.updatePetAttrBuff(actor)
    mountMain.updatePetBattleSkillBuff(actor)
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
        local name = data.Name       -- 名字
        local classid = data.ClassID -- 属性
        local costs = data.Cost      -- 消耗
        local grade = data.grade     -- 激活的阶数

        -- 支持多消耗格式
        local isMultiCost = (type(costs[1]) == "table")

        if isMultiCost then
            -- 多重消耗格式
            local allEnough = true
            for i = 1, #costs do
                local itemId = tonumber(costs[i][1])
                local num = tonumber(costs[i][2])
                if getItemNum(actor, itemId) < num then
                    allEnough = false
                    break
                end
            end

            if not allEnough then
                sendmsg(actor, 9, "激活材料不足")
                return
            end

            -- 扣除所有材料
            for i = 1, #costs do
                local itemId = tonumber(costs[i][1])
                local num = tonumber(costs[i][2])
                delItemNum(actor, itemId, num)
            end
        else
            -- 单消耗格式（兼容旧数据）
            local itemId = tonumber(costs[1])
            local num = tonumber(costs[2])
            if getItemNum(actor, itemId) < num then
                sendmsg(actor, 9, "激活材料不足" .. num .. "个")
                return
            end
            delItemNum(actor, itemId, num)
        end

        local ycList = json2tbl(gethumvar(actor, VarCfg.T_MountHuanHua))
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
        -- 统一更新坐骑属性buff
        mountMain.updateMountAttrBuff(actor)
        -- 同步更新灵兽属性buff（确保不影响灵兽属性）
        mountMain.updatePetAttrBuff(actor)
        mountMain.updatePetBattleSkillBuff(actor)
        Message.sendmsgEx(actor, "mountMain", "updateHHmodel", {
            ycList = ycList,
            name = name,
            grade = grade,
            mountHHid = mountHHid
        })
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
    -- 统一更新坐骑属性buff（包括幻化属性）
    mountMain.updateMountAttrBuff(actor)
    -- 更新坐骑幻化战斗技能buff
    mountMain.updateMountBattleSkillBuff(actor)
    -- 同步更新灵兽属性buff（确保不影响灵兽属性）
    mountMain.updatePetAttrBuff(actor)
    mountMain.updatePetBattleSkillBuff(actor)
    Message.sendmsgEx(actor, "mountMain", "UpdateHHBtnName", {
        mountHHid = mountTakeId,
        isCancel = isCancel,
        oldModelId = oldMountTakeId
    })
end

function mountMain.chuzhan(actor, data)
    -- 坐骑出战限制：需要达到一阶才能出战
    local mountStar = gethumvar(actor, VarCfg.U_All_Mount_star)
    if not mountStar or mountStar == 0 then
        sendmsg(actor, 9, "请先激活坐骑")
        return
    end
    if mountStar < 11 then
        sendmsg(actor, 9, "坐骑未达一阶，无法上阵出战")
        return
    end

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
    -- 同步更新灵兽属性buff（确保不影响灵兽属性）
    mountMain.updatePetAttrBuff(actor)
    mountMain.updatePetBattleSkillBuff(actor)
    Message.sendmsgEx(actor, "mountMain", "updateBtnName",
        { status = horsestate(actor) })
end

function mountMain.jihuo(actor) sendmsg(actor, 9, "请先激活坐骑") end

function mountMain.lsJihuo(actor) sendmsg(actor, 9, "请先激活灵兽") end

-- ===== 旧灵兽功能已废弃，以下函数已由新结构替代 =====
-- 说明：旧的灵兽激活、召唤、收回等功能已被新的灵兽结构替代
-- 新结构使用与坐骑相同的星星/阶数系统和幻化系统
-- 如果需要使用旧功能，请取消注释并调整相关调用

-- 灵兽激活/升级接口
function mountMain.lsjihuo(actor, data)
    local nowlv = gethumvar(actor, VarCfg.U_All_Pet_star)

    if nowlv > 0 then
        return sendmsg(actor, 9, "已激活")
    end

    -- 检查激活是否需要消耗（兼容多消耗格式）
    local costs = petlist[0].Cost
    if costs then
        local isMultiCost = (type(costs[1]) == "table")

        if isMultiCost then
            -- 多重消耗：检查所有材料是否足够
            local allEnough = true
            for i = 1, #costs do
                local itemId = tonumber(costs[i][1])
                local num = tonumber(costs[i][2])
                if bagitemcount(actor, itemId) < num then
                    allEnough = false
                    break
                end
            end

            if not allEnough then
                return sendmsg(actor, 9, "激活材料不足")
            end

            -- 扣除所有材料
            for i = 1, #costs do
                local itemId = tonumber(costs[i][1])
                local num = tonumber(costs[i][2])
                delItemNum(actor, itemId, num)
            end
        else
            -- 单消耗格式（兼容旧数据）
            local itemId = tonumber(costs[1])
            local num = tonumber(costs[2])
            if bagitemcount(actor, itemId) < num then
                return sendmsg(actor, 9, "激活材料不足" .. num .. "个")
            end
            delItemNum(actor, itemId, num)
        end
    end

    mountMain.petShengji(actor)

    -- 发送updateLSView和level消息
    local newLv = gethumvar(actor, VarCfg.U_All_Pet_star)
    print("=== lsjihuo 发送消息, newLv:", newLv)
    Message.sendmsgEx(actor, "mountMain", "updateLSView", {
        name = "pet",
        lv = newLv
    })
    Message.sendmsgEx(actor, "mountMain", "level", {
        lv = newLv,
        Name = "pet"
    })
    print("=== lsjihuo 完成 ===")
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

    -- 灵兽出战限制：需要达到一阶才能出战
    if isActivated < 11 then
        sendmsg(actor, 9, "灵兽未达一阶，无法上阵出战")
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
    -- 清除灵兽死亡复活定时器
    disabletimer(actor, 49)

    local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)

    if not petBaseId or petBaseId == 0 then
        petBaseId = 900001
    end

    if not petTakeId or petTakeId == 0 then
        petTakeId = petBaseId
    end

    -- 获取灵兽怪物ID
    local monsterId = 80001

    -- 检查是否是幻化形态
    local isHuanhua = false
    local petTakeIdNum = tonumber(petTakeId)
    local petBaseIdNum = tonumber(petBaseId)

    -- 从 petTakeId 匹配 PetHuanhua 获取灵兽名称
    local petName = nil
    if petTakeIdNum and petTakeIdNum > 0 then
        for _, hhData in pairs(petHHlist) do
            if tonumber(hhData.Model) == petTakeIdNum then
                petName = hhData.Name
                break
            end
        end
    end

    -- 获取当前幻化等级
    local currentHHGrade = 0
    if petName then
        local ycList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))
        if ycList and ycList[petName] then
            currentHHGrade = tonumber(ycList[petName]) or 0
        end
    end

    -- 优先用 Name + grade 匹配，获取对应等级的怪物ID
    if petName and currentHHGrade > 0 then
        for _, hhData in pairs(petHHlist) do
            if hhData.Name == petName and tonumber(hhData.grade) == currentHHGrade then
                monsterId = hhData.Monster_ID
                isHuanhua = true
                break
            end
        end
    end

    -- 如果没匹配到，用 petTakeId 降级匹配 Model
    if not isHuanhua and petTakeIdNum and petTakeIdNum > 0 then
        for _, hhData in pairs(petHHlist) do
            if tonumber(hhData.Model) == petTakeIdNum and hhData.Monster_ID then
                monsterId = hhData.Monster_ID
                isHuanhua = true
                break
            end
        end
    end

    -- 如果不是幻化形态，从Pet配置表中获取
    if not isHuanhua and petBaseId then
        for i = 0, 10 do
            if petlist[i] and petlist[i].Model and tonumber(petlist[i].Model) == petBaseIdNum then
                monsterId = tonumber(petlist[i].Monster_ID) or 80001
                break
            end
        end
    end

    sethumvar(actor, VarCfg.U_Pet_Now_Model, petTakeId)

    -- 检查是否已有宠物mark，如果没有则先添加宠物
    local existingMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    local mark = existingMark

    -- 检查宠物是否已经在场上
    local petIdx = getpetidx(actor, mark)

    if mark and mark ~= "" and petIdx then
        -- 宠物已经在场上，不需要再次添加
    else
        -- mark不存在或宠物已不在场上，需要重新添加
        mark = addpet(actor, monsterId)
        if not mark or mark == "" then
            sendmsg(actor, 9, "添加灵兽失败")
            return
        end
        -- 保存宠物信息到 T_Pet_Mark
        sethumvar(actor, VarCfg.T_Pet_Mark, mark)
    end

    -- 从变量中获取mark确保有效
    mark = gethumvar(actor, VarCfg.T_Pet_Mark)

    -- 召唤灵兽
    recallpet(actor, mark)
    -- 设置出战状态
    sethumvar(actor, VarCfg.U_Pet_IS_SET, 1)

    -- 设置攻击模式（2=跟随主人攻击）
    setpetrelax(actor, mark, 2)

    -- 设置灵兽属性
    mountMain.setPetAttr(actor)

    -- 更新人物属性buff
    mountMain.updatePetAttrBuff(actor)
    -- 更新灵兽幻化战斗技能buff
    mountMain.updatePetBattleSkillBuff(actor)

    -- 发送召回结果消息给客户端
    local isPetChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET) or 0
    Message.sendmsgEx(actor, "mountMain", "recallpetResult", {
        showPetModelId = petTakeId,
        selectViewPetId = petBaseId,
        isPetChuzhan = isPetChuzhan
    })

    -- 发送setPetInfo消息更新顶部灵兽图标
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"
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
    Message.sendmsgEx(actor, methodName, "setPetInfo", {
        type = "red",
        max = 10000,
        now = 10000,
        icon = icon
    })

    -- 发送petUpdateBtn消息更新按钮状态
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = isPetChuzhan,
        isPetJh = gethumvar(actor, VarCfg.U_All_Pet_star) > 0 and 1 or 0,
        allJieshu = gethumvar(actor, VarCfg.U_All_Pet_star)
    })
end

-- 收回灵兽
function mountMain.unrecallpet(actor, petMark)
    -- 如果没有传入petMark，则从变量获取
    if not petMark then
        petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    end

    if not petMark or petMark == "" then
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

    -- 更新人物属性buff
    mountMain.updatePetAttrBuff(actor)
    -- 更新灵兽幻化战斗技能buff
    mountMain.updatePetBattleSkillBuff(actor)

    -- 发送收回结果消息给客户端
    Message.sendmsgEx(actor, "mountMain", "unrecallpetResult")

    -- 发送setPetInfo消息隐藏顶部灵兽图标
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"
    Message.sendmsgEx(actor, methodName, "setPetInfo", {
        type = "red",
        max = 1,
        now = 1
    })

    -- 发送petUpdateBtn消息更新按钮状态
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = 0,
        isPetJh = gethumvar(actor, VarCfg.U_All_Pet_star) > 0 and 1 or 0,
        allJieshu = gethumvar(actor, VarCfg.U_All_Pet_star)
    })
end

-- 灵兽复活
function mountMain.resurre(actor)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)

    if not petMark or petMark == "" then
        return
    end

    -- 复活宠物
    realivepet(actor, petMark)

    -- 重新召唤灵兽
    mountMain.recallpet(actor)

    -- 确保设置出战状态
    sethumvar(actor, VarCfg.U_Pet_IS_SET, 1)

    -- 设置属性
    mountMain.setPetAttr(actor)
    mountMain.updatePetAttrBuff(actor)

    -- 发送setPetInfo消息更新顶部灵兽图标
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"
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
    Message.sendmsgEx(actor, methodName, "setPetInfo", {
        type = "red",
        max = 10000,
        now = 10000,
        icon = icon
    })

    -- 发送petUpdateBtn消息更新按钮状态
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = 1,
        isPetJh = gethumvar(actor, VarCfg.U_All_Pet_star) > 0 and 1 or 0,
        allJieshu = gethumvar(actor, VarCfg.U_All_Pet_star)
    })
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
        return sendmsg(actor, 9, "配置错误")
    end

    local costs = petlist[nowlv].Cost

    -- 支持多消耗格式：2801^40|3958^5
    -- 检查是否是多重消耗格式：costs[1] 是 table 而不是 number
    local isMultiCost = (type(costs[1]) == "table")

    if isMultiCost then
        -- 多重消耗格式：{[1] = {[1] = itemId, [2] = num}, [2] = {[1] = itemId, [2] = num}}
        local allEnough = true
        for i = 1, #costs do
            local itemId = tonumber(costs[i][1])
            local num = tonumber(costs[i][2])
            if bagitemcount(actor, itemId) < num then
                allEnough = false
                break
            end
        end

        if not allEnough then
            return sendmsg(actor, 9, "材料不足")
        end
    else
        -- 单消耗格式（兼容旧数据）
        local itemId = tonumber(costs[1])
        local num = tonumber(costs[2])

        if bagitemcount(actor, itemId) < num then
            return sendmsg(actor, 9, "材料不足" .. num .. "个")
        end
    end

    -- 调用petShengji处理升级逻辑（petShengji内部会扣除材料）
    mountMain.petShengji(actor)

    -- 发送level消息与旧系统对齐
    local newLv = gethumvar(actor, VarCfg.U_All_Pet_star)
    -- 先发送updateLSView初始化allPetsActive表
    local allPets = { ["pet"] = newLv }
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
    local isActivated = gethumvar(actor, VarCfg.U_All_Pet_star)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)

    if isActivated and isActivated > 0 and (not petMark or petMark == "") then
        mountMain.recallpet(actor)
    end
end, mountMain)

-- 角色登录完成时处理坐骑和灵兽
GameEvent.add(EventCfg.onLoginEnd, function(actor)
    local mountIsSet = tonumber(gethumvar(actor, VarCfg.U_Mount_IS_SET))
    local mountStatus = tonumber(gethumvar(actor, VarCfg.U_Mount_Status))
    local mountTakeId = gethumvar(actor, VarCfg.U_Mount_Take_Id)
    local mountTakeIdNum = tonumber(mountTakeId)
    local currentHorseState = horsestate(actor)

    if mountIsSet and mountIsSet == 1 and mountStatus == 1 and mountTakeIdNum and mountTakeIdNum > 0 then
        changeappear(actor, 5, mountTakeIdNum)

        if currentHorseState == 0 then
            updownhorser(actor)
        end

        local baseSpeed = scriptabil(actor, 9)
        if horsestate(actor) == 0 then
            setscriptabilvalue(actor, 9, "=", baseSpeed - 5000)
        else
            setscriptabilvalue(actor, 9, "=", baseSpeed + 5000)
        end
        mountMain.updateMountAttrBuff(actor)
        mountMain.updateMountBattleSkillBuff(actor)
        mountMain.updatePetAttrBuff(actor)
        mountMain.updatePetBattleSkillBuff(actor)
    end

    mountMain.updatePetAttrBuff(actor)
    mountMain.updatePetBattleSkillBuff(actor)
    mountMain.updateMountBattleSkillBuff(actor)

    local isActivated = gethumvar(actor, VarCfg.U_All_Pet_star)
    local isChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)

    if isActivated and isActivated > 0 and isChuzhan == 1 then
        local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
        local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)

        if not petBaseId or petBaseId == 0 then
            petBaseId = 900001
        end
        if not petTakeId or petTakeId == 0 then
            petTakeId = petBaseId
        end

        local monsterId = 80001
        local petTakeIdNum = tonumber(petTakeId)
        if petTakeIdNum and petTakeIdNum > 0 then
            for _, hhData in pairs(petHHlist) do
                if tonumber(hhData.Model) == petTakeIdNum and hhData.Monster_ID then
                    monsterId = hhData.Monster_ID
                    break
                end
            end
        end

        local oldMark = gethumvar(actor, VarCfg.T_Pet_Mark)
        local mark = oldMark
        if oldMark and oldMark ~= "" and getpetidx(actor, oldMark) then
        else
            mark = addpet(actor, monsterId)
            if mark and mark ~= "" then
                sethumvar(actor, VarCfg.T_Pet_Mark, mark)
            else
                return
            end
        end

        disabletimer(actor, 49)
        recallpet(actor, mark)
        setpetrelax(actor, mark, 2)
        mountMain.setPetAttr(actor)
        mountMain.updatePetAttrBuff(actor)
        mountMain.updatePetBattleSkillBuff(actor)

        local isPetHH = gethumvar(actor, VarCfg.U_Pet_IS_HH)
        local mountStatusNow = tonumber(gethumvar(actor, VarCfg.U_Mount_Status))
        if isPetHH and isPetHH == 1 and petTakeId and petTakeId > 0 then
            if mountStatusNow == 1 then
            else
                changeappear(actor, 5, petTakeId)
            end
        end

        local isPc = clientflag(actor) == 1
        local methodName = isPc and "PCMainPlayer" or "MainPlayer"
        local icon = "pet_000"
        if petTakeId and petTakeId > 0 and petTakeId ~= petBaseId then
            for _, v in pairs(petHHlist) do
                if v.Model == petTakeId and v.mount_icon then
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
        Message.sendmsgEx(actor, "mountMain", "recallpetResult", {
            showPetModelId = petTakeId,
            selectViewPetId = petBaseId,
            isPetChuzhan = 1
        })
    end
end, mountMain)

GameEvent.add(EventCfg.onNewHuman, function(actor)
    giveitem(actor, "灵兽召唤符（乌龙驹）#999")
    --giveitem(actor, "灵兽召唤符（追风豹）#999")
    --giveitem(actor, "灵兽召唤符（铁甲犀牛）#999")
    --giveitem(actor, "灵兽召唤符（黑豹）#999")
    --giveitem(actor, "灵兽召唤符（雪豹）#999")
    --giveitem(actor, "灵兽召唤符（霸天虎）#999")
    --giveitem(actor, "灵兽召唤符（烈焰狮）#999")
    --giveitem(actor, "灵兽召唤符（飓风狂狼）#999")
    --giveitem(actor, "灵兽召唤符（松狮犬）#999")
    --giveitem(actor, "灵兽召唤符（青木神龙）#999")
    giveitem(actor, "龙猫#2")
    giveitem(actor, "企鹅#2")
    giveitem(actor, "稻草人#2")
    giveitem(actor, "小白兔#2")
    giveitem(actor, "蟠龙#2")
    giveitem(actor, "坐骑升星石#9999")
    giveitem(actor, "灵宠升级彩蛋#9999")

    --giveitem(actor, "混元金刚石（攻击）#5")
    --giveitem(actor, "冰魄寒玉石（防御）#5")
    --giveitem(actor, "热血石（狂神降世）#1")
    --giveitem(actor, "热血石（转攻为守）#1")
    --giveitem(actor, "金刚石（攻击）#5")
    --giveitem(actor, "寒玉石（武防）#5")
    --giveitem(actor, "51003#2")
    --giveitem(actor, "51005#2")
    --giveitem(actor, "34001#2")
end, mountMain)

Message.RegisterNetMsg(ssrNetMsgCfg.mountMain, mountMain)

return mountMain
