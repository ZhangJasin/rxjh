mountMain = {}
local filname = "mountMain"
local mountlist = require("Envir/QuestDiary/game_config/cfgcsv/Mount.lua")
local mountHHlist = require(
    "Envir/QuestDiary/game_config/cfgcsv/MountHuanHua.lua")
local SpiritualBeast = require(
    "Envir/QuestDiary/game_config/cfgcsv/SpiritualBeast.lua")
local SysConstant = require(
    "Envir/QuestDiary/game_config/cfgcsv/SysConstant.lua")

-- �������ñ��������ṹһ�£�
local petlist = require("Envir/QuestDiary/game_config/cfgcsv/Pet.lua")
local petHHlist = require("Envir/QuestDiary/game_config/cfgcsv/PetHuanhua.lua")

-- ��������ת���������ñ�����ȼ����ݣ�
-- ��ʽ��{minLevel, maxLevel, rate}  ��ʾ minLevel-maxLevel �ȼ���ʹ�� rate ת������
local PetLevelRateConfig = {
    { 1,   10,  0.03 }, -- 1-10�� 3%
    { 11,  20,  0.04 }, -- 11-20�� 4%
    { 21,  30,  0.05 }, -- 21-30�� 5%
    { 31,  40,  0.06 }, -- 31-40�� 6%
    { 41,  50,  0.08 }, -- 41-50�� 8%
    { 51,  60,  0.10 }, -- 51-60�� 10%
    { 61,  70,  0.12 }, -- 61-70�� 12%
    { 71,  80,  0.15 }, -- 71-80�� 15%
    { 81,  90,  0.18 }, -- 81-90�� 18%
    { 91,  100, 0.18 }, -- 91-100�� 21%
    { 101, 110, 0.18 }, -- 101-110�� 25%
}

-- ���ݵȼ���ȡת������
local function getPetAttrRateByLevel(level)
    for _, config in ipairs(PetLevelRateConfig) do
        if level >= config[1] and level <= config[2] then
            return config[3]
        end
    end
    -- Ĭ�Ϸ�����͵�����
    return PetLevelRateConfig[1][3]
end

-- ����buff����
-- 110044: ���޳�ս���ԣ����޻������ԡ�10%��
-- 110045: ���޻û�ս�����ܣ���� BattleSkill_Value �̶�ֵ��
-- 110047: ���޻û����ԣ���� ClassID �̶�ֵ��
local PetBuffId = 110044
local PetSkillBuffId = 110045
local HuanhuaBuffId = 110047

-- ����buff����
-- 110015: ���Ｄ��/�������ԣ����̶�ֵ��+ ��ս���ԣ��ƶ��ٶ�+10%��
-- 110016: ����û����ԣ���� ClassID �̶�ֵ��
-- 110046: �����ս�û������ BattleSkill �̶�ֵ��
local MountBuffId = 110015
local MountHuanhuaBuffId = 110016
local MountBattleSkillBuffId = 110046

-- ����ӳ�����ID(��ֱ�,10000=100%)
local ExpAttrId = 12

-- ===== �µ����޹��ܣ�������ṹһ�£�=====

-- ��ȡ�����������
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

-- ��ȡ���޻û�����
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

-- ��ȡ���޻û���ս����������
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

-- ����/�������޻û�ս������buff
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

-- ��ȡ����û���ս����������
function mountMain.getMountBattleSkillAttr(actor)
    local mountTakeId = gethumvar(actor, VarCfg.U_Mount_Take_Id)
    if not mountTakeId or mountTakeId == 0 then
        return {}
    end

    local battleAttr = {}
    -- ���ҵ�ǰ�û�ģ�Ͷ�Ӧ���������
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

-- ����/��������û�ս������buff
function mountMain.updateMountBattleSkillBuff(actor)
    -- ������ɵ�battle skill buff
    delbuff(actor, MountBattleSkillBuffId)

    local battleAttr = mountMain.getMountBattleSkillAttr(actor)

    if next(battleAttr) then
        -- �����buff
        addbuff(actor, MountBattleSkillBuffId)
        -- ����������
        for attrId, attrValue in pairs(battleAttr) do
            setbuffabil(actor, MountBattleSkillBuffId, tonumber(attrId), "=", tonumber(attrValue))
        end
    end
end

-- �������ޱ�������ԣ���������Ը������޳��
function mountMain.setPetAttr(actor)
    local allstar = gethumvar(actor, VarCfg.U_All_Pet_star)
    if not allstar or allstar == 0 then
        print("setPetAttr: ����δ����")
        return
    end

    local mark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if not mark or mark == "" then
        print("setPetAttr: û���ٻ����ޣ���������������")
        print("�������������Ų�1111")
        -- ��ʹû���ٻ����ޣ���Ȼ������������
        mountMain.updatePetAttrBuff(actor)
        return
    end

    local petidx = getpetidx(actor, mark)
    if not petidx then
        print("setPetAttr: ���޲����ڣ���������������")
        print("�������������Ų�2222")
        mountMain.updatePetAttrBuff(actor)
        return
    end

    -- ��ȡ���޵ȼ�����
    local petAttr = mountMain.getPetAttrByLevel(allstar)

    -- ��ȡ�û�����
    local hhAttr = mountMain.getPetHHAttr(actor)

    -- �ϲ����ԣ��������� + �û����ԣ�
    for attrId, attrValue in pairs(hhAttr) do
        if petAttr[attrId] then
            petAttr[attrId] = petAttr[attrId] + attrValue
        else
            petAttr[attrId] = attrValue
        end
    end

    -- �������Ե����޳���
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

    -- ������Ϣ���¿ͻ�����ʾ
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"
    Message.sendmsgEx(actor, methodName, "setPetInfo", {
        type = "red",
        max = max,
        now = now,
        icon = 0
    })

    -- ������������
    mountMain.updatePetAttrBuff(actor)
    print("setPetAttr: ���������������")
end

-- �����������Լӳɵ�����
-- �������
-- 1. buff 110044 - ���޳�ս���� = ���޻������� �� 10%
-- 2. buff 110047 - ���޻û����� = ��� ClassID �̶�ֵ����ϢʱҲ�У�
-- ע�⣺110045 �� updatePetBattleSkillBuff ���ã���� BattleSkill_Value �̶�ֵ��
function mountMain.updatePetAttrBuff(actor)
    print("mountMain.updatePetAttrBuff")
    local allstar = gethumvar(actor, VarCfg.U_All_Pet_star)
    print("allstar", allstar)
    if not allstar or allstar == 0 then
        -- δ�������ޣ�ɾ�����buff
        delbuff(actor, PetBuffId)
        delbuff(actor, HuanhuaBuffId)
        return
    end
    print("updatePetAttrBuff: ��ʼִ��")

    -- ��������Ƿ��ս
    local isBattle = gethumvar(actor, VarCfg.U_Pet_IS_SET)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    dump(isBattle)
    dump(petMark)

    -- ��ȡ�û�����
    local hhAttr = mountMain.getPetHHAttr(actor)
    print("��ȡ�û�����")
    dump(hhAttr)

    -- ���û���ٻ����ޣ���Ϣ״̬��
    if not isBattle or isBattle == 0 or not petMark or petMark == "" then
        delbuff(actor, PetBuffId)
        print("������Ϣ״̬")
        -- ��Ϣʱֻ���ûû����Ե� buff 110047
        if next(hhAttr) then
            print("next(hhAttr)")
            delbuff(actor, HuanhuaBuffId)
            addbuff(actor, HuanhuaBuffId)
            for attrId, attrValue in pairs(hhAttr) do
                setbuffabil(actor, HuanhuaBuffId, tonumber(attrId), "=", tonumber(attrValue))
            end
            print("updatePetAttrBuff: ������Ϣ�����ûû����Ե� buff", HuanhuaBuffId)
        else
            delbuff(actor, HuanhuaBuffId)
        end
        return
    end

    -- ��ս״̬��������������

    -- �������޻������ԡ��ȼ������� buff 110044
    delbuff(actor, PetBuffId)
    addbuff(actor, PetBuffId)
    local petAttr = mountMain.getPetAttrByLevel(allstar)
    local attrRate = getPetAttrRateByLevel(allstar)
    for attrId, attrValue in pairs(petAttr) do
        local finalValue = math.ceil(attrValue * attrRate)
        setbuffabil(actor, PetBuffId, tonumber(attrId), "=", finalValue)
    end

    -- ��սʱҲ����û����Ե� buff 110047
    if next(hhAttr) then
        delbuff(actor, HuanhuaBuffId)
        addbuff(actor, HuanhuaBuffId)
        for attrId, attrValue in pairs(hhAttr) do
            setbuffabil(actor, HuanhuaBuffId, tonumber(attrId), "=", tonumber(attrValue))
        end
        print("updatePetAttrBuff: ���޳�ս���������ޡ�10%�� buff", PetBuffId, "���û����Ե� buff", HuanhuaBuffId)
    else
        delbuff(actor, HuanhuaBuffId)
    end
    -- ע�⣺110045 �û�ս�������� updatePetBattleSkillBuff ��������
end

-- ����������������������ͬ�Ľṹ��
function mountMain.petShengji(actor)
    local nowlv = gethumvar(actor, VarCfg.U_All_Pet_star)
    local nextlv = nowlv + 1
    print("=== ��������/���� ===")
    print("��ǰ�ȼ�:", nowlv, "��һ�ȼ�:", nextlv, "��ߵȼ�:", #petlist)
    if nextlv > #petlist then
        print("�Ѵﵽ��ߵȼ�")
        sendmsg(actor, 9, "�Ѵﵽ��ߵȼ�")
        return
    end

    if not petlist[nextlv] or not petlist[nextlv].ClassID then
        print("petShengji: ��һ�����ò�����, nextlv:", nextlv)
        sendmsg(actor, 9, "���ô���")
        return
    end

    if not petlist[nowlv] or not petlist[nowlv].Cost then
        print("petShengji: ��ǰ�����ò�����, nowlv:", nowlv)
        sendmsg(actor, 9, "���ô���")
        return
    end

    local classIds = petlist[nextlv].ClassID
    local costs = petlist[nowlv].Cost

    -- ֧�ֶ����ĸ�ʽ��2801^40|3958^5
    -- ����Ƿ��Ƕ������ĸ�ʽ��costs[1] �� table ������ number
    local isMultiCost = (type(costs[1]) == "table")

    if isMultiCost then
        -- �������ĸ�ʽ��{[1] = {[1] = itemId, [2] = num}, [2] = {[1] = itemId, [2] = num}}
        print("��⵽�������ĸ�ʽ")
        local allEnough = true
        local lackItems = {}
        for i = 1, #costs do
            local itemId = tonumber(costs[i][1])
            local num = tonumber(costs[i][2])
            local haveCount = bagitemcount(actor, itemId)
            print("����" .. i .. " ID:", itemId, "��Ҫ:", num, "ӵ��:", haveCount)
            if haveCount < num then
                allEnough = false
                table.insert(lackItems, { id = itemId, need = num, have = haveCount })
            end
        end

        if not allEnough then
            print("����ϲ���")
            local msg = "���ϲ���"
            if #lackItems > 0 then
                msg = "���ϲ���"
            end
            sendmsg(actor, 9, msg)
            return
        end

        -- �۳����в���
        print("���ϳ���,��ʼ�۳����в���")
        for i = 1, #costs do
            local itemId = tonumber(costs[i][1])
            local num = tonumber(costs[i][2])
            delItemNum(actor, itemId, num)
            print("�۳�����" .. i .. " ID:", itemId, "����:", num)
        end
    else
        -- �����ĸ�ʽ�����ݾ����ݣ�
        local itemId = tonumber(costs[1])
        local num = tonumber(costs[2])

        print("����ID:", itemId, "��Ҫ����:", num, "ӵ������:", bagitemcount(actor, itemId))

        if bagitemcount(actor, itemId) < num then
            print("���ϲ���")
            sendmsg(actor, 9, "���ϲ���" .. num .. "��")
            return
        end

        print("���ϳ���,��ʼ����/����")
        delItemNum(actor, itemId, num)
    end
    -- 0��9��(Level=9) �� 0��10��(Level=10)����������
    -- 0��10��(Level=10) �� 1��1��(Level=11)����ף���������Ϊ1
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

        -- �״μ���ʱ���Զ������һ���û�����ѣ�
        local firstHH = petHHlist[1]
        if firstHH then
            local ycList = {}
            ycList[firstHH.Name] = firstHH.grade
            sethumvar(actor, VarCfg.T_PetHuanHua, tbl2json(ycList))
            -- ���ûû����
            sethumvar(actor, VarCfg.U_Pet_Take_Id, firstHH.Model)
            sethumvar(actor, VarCfg.U_Pet_IS_HH, 1)
            changeappear(actor, 5, firstHH.Model)
            -- ע�⣺�û������� updatePetAttrBuff ͳһ��������ﲻ��Ҫ��������
            -- ��ӻû�buff
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

    -- �������߼�һ�£�ֱ�Ӵ洢�����ĵȼ����ͻ���ͨ��������ʾ����������
    sethumvar(actor, VarCfg.U_All_Pet_star, nextlv)
    print("�������޵ȼ�:", nextlv)

    -- �������ޱ�������ԣ���������Ը������ޣ��������������ԣ�
    mountMain.setPetAttr(actor)
    -- �������޻û�ս������buff
    mountMain.updatePetBattleSkillBuff(actor)
    -- ������������buff����Ϣʱ���ûû����Ե� buff 110047��
    mountMain.updatePetAttrBuff(actor)

    local petBaseId = petlist[nextlv].Model
    print("���޻���ģ��ID:", petBaseId)

    -- ��ǰģ���Ƿ�û�
    if gethumvar(actor, VarCfg.U_Pet_IS_HH) == 0 then
        sethumvar(actor, VarCfg.U_Pet_Take_Id, petBaseId)
        print("�������޵�ǰʹ��ģ��:", petBaseId)
    end
    sethumvar(actor, VarCfg.U_Pet_Base_ID, petBaseId)
    print("�������޻���ģ��:", petBaseId)

    -- ע�⣺���޼��Ӧ�øı�������ۣ�
    -- �������ֻ��������ƣ����ϵͳһ��

    -- �������������¼������ϵͳ���룩
    local allPets = { pet = nextlv }
    GameEvent.push(EventCfg.onPetLevel, actor, allPets)

    -- ����ǰ����ʾ������updateLSView��Ϣ���ϵͳ���룩
    -- ������һ�£����������ĵȼ�
    print("����������Ϣ���ͻ���,�ȼ�:", nextlv)

    -- ��������Ƿ��лû�����������ͻû�ģ��ID
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
    -- ͬʱ����updatePetZQ��Ϣ���ּ�����
    Message.sendmsgEx(actor, "mountMain", "updatePetZQ", {
        lv = nextlv,
        petBaseId = petBaseId,
        showPetModelId = showPetModelId
    })

    -- ����petUpdateBtn��Ϣ���°�ť״̬
    -- ����ˣ�U_Pet_IS_SET = 0 ��ʾ��Ϣ��1 ��ʾ��ս
    -- �ͻ��ˣ�isPetChuzhan = 0 ��ʾ��Ϣ����ʾ"��ս"��ť����1 ��ʾ��ս����ʾ"�ٻ�"��ť��
    -- ֱ�Ӵ��ݷ����ֵ������Ҫת��
    local isPetChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET) or 0
    local isPetJh = gethumvar(actor, VarCfg.U_All_Pet_star)
    print("����petUpdateBtn��Ϣ��U_Pet_IS_SET=", isPetChuzhan, "isPetJh=", isPetJh)
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = isPetChuzhan,
        isPetJh = isPetJh
    })

    -- ��������¶�������ͼ�ֻ꣨������ʱ���£�����ʱ�����£�
    -- ע�⣺ֻ���ѳ�ս״̬�²Ÿ���ͼ��
    local serverChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET) or 0
    if serverChuzhan == 1 then -- ֻ�г�ս״̬�Ÿ���ͼ��
        local isPc = clientflag(actor) == 1
        local methodName = isPc and "PCMainPlayer" or "MainPlayer"
        local icon = "pet_000"
        local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
        local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
        -- ʹ�� v.Model ���ң����¼ʱ����һ�£�
        if petTakeId and petTakeId > 0 then
            for _, v in pairs(petHHlist) do
                if v.Model == petTakeId and v.mount_icon then
                    icon = v.mount_icon
                    print("��������ͼ�꣬�ҵ�icon:", icon)
                    break
                end
            end
        end
        print("��������setPetInfo��icon:", icon)
        Message.sendmsgEx(actor, methodName, "setPetInfo", {
            type = "red",
            max = 10000,
            now = 10000,
            icon = icon
        })
    end
end

-- ���޻û�����
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
            sendmsg(actor, 9, "������ϲ���" .. num .. "��")
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
        sendmsg(actor, 9, "����ʧ��")
    end
end

-- ��ɾ���ɵ����޻û�buff
function mountMain.setPetHHBuff(actor, oldbuffList, newBuffList, isCancel)
    if tonumber(isCancel) == 0 then
        for b = 1, #oldbuffList do delbuff(actor, oldbuffList[b]) end
        for c = 1, #newBuffList do addbuff(actor, newBuffList[c]) end
    else
        -- ȡ���û�
        for b = 1, #oldbuffList do delbuff(actor, oldbuffList[b]) end
    end
end

-- ��������ģ�ͣ���������ͬ�Ľṹ��
function mountMain.setPetModel(actor, data)
    print("=== setPetModel ������ ===")
    print("data:", type(data), data)
    -- {"�û�����"=�û�Ʒ��}
    local allhhList = {}
    local basePetId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
    print("basePetId:", basePetId, "petTakeId:", petTakeId)
    local oldPetTakeId = petTakeId
    local bdid = 0
    local isCancel = 0
    local oldbuffList = {}
    local newBuffList = {}

    print("�ж�: petTakeId:", petTakeId, "== data.mountId:", data.mountId, "?", petTakeId == data.mountId)
    if petTakeId == data.mountId then
        -- ȡ���û�
        print("ִ��ȡ���û�")
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
        -- �û�
        print("ִ�лû�")
        allhhList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))
        if gethumvar(actor, VarCfg.U_Pet_IS_HH) == 1 then
            -- ԭ���Ѿ��лû���
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
    -- ���õ�ǰ��ʾ��ģ��ID
    sethumvar(actor, VarCfg.U_Pet_Now_Model, petTakeId)

    -- ��������Ѿ���ս����Ҫ�ٻ��������ٻ������ϵͳ���룩
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if petMark and petMark ~= "" then
        print("�û�ʱ�����ѳ�ս���ٻز������ٻ�")
        -- ����ɾ���ɳ��ﲢ�������
        unrecallpet(actor, petMark)
        delpet(actor, petMark)
        -- ����ɵ�mark
        sethumvar(actor, VarCfg.T_Pet_Mark, "")
        -- ǿ��ʹ����ģ��ID�����ٻ�
        sethumvar(actor, VarCfg.U_Pet_Take_Id, petTakeId)
        -- �����ٻ�
        mountMain.recallpet(actor)
    end
    -- ���¼��㲢Ӧ��������������
    mountMain.updatePetAttrBuff(actor)
    -- �������޻û�ս������buff
    mountMain.updatePetBattleSkillBuff(actor)
    -- ��ȡ�����Ѽ�������޻û�����
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

    -- ��������ѳ�ս������setPetInfo��Ϣ���¶�������ͼ��
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if petMark and petMark ~= "" then
        local isPc = clientflag(actor) == 1
        local methodName = isPc and "PCMainPlayer" or "MainPlayer"
        -- �����ȡ���û�(isCancel=1)��û���µĻû���ʹ��Ĭ��ͼ��
        local icon = "pet_000"
        -- ����Ƿ�����Ч�û�
        if isCancel == 0 and petTakeId and petTakeId > 0 then
            local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
            if petTakeId ~= petBaseId then
                for _, v in pairs(petHHlist) do
                    if v.Model == petTakeId and v.mount_icon then
                        icon = v.mount_icon
                        print("�û��л�����¶���ͼ��(�û�):", icon)
                        break
                    end
                end
            end
        else
            print("�û��л�����¶���ͼ��(Ĭ��)")
        end
        Message.sendmsgEx(actor, methodName, "setPetInfo", {
            type = "red",
            max = 10000,
            now = 10000,
            icon = icon
        })
    end
end

-- ===== ���﹦�ܣ�����ԭ�й��ܣ�=====

function mountMain.openshow(actor, data)
    Message.sendmsgEx(actor, "mountMain", "Open", {})

    -- ����petUpdateBtn��Ϣ���°�ť״̬
    -- ����ˣ�U_Pet_IS_SET = 1 ��ʾ��ս��0 ��ʾ��Ϣ
    -- �ͻ��ˣ�isPetChuzhan = 0 ��ʾ���ٻ�����ʾ�ٻأ���1 ��ʾδ�ٻ�����ʾ��ս��
    -- ��Ҫת�����ͻ���ֵ = 1 - �����ֵ
    local serverChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET) or 0
    local isPetChuzhan = 1 - serverChuzhan -- ת��
    local isPetJh = gethumvar(actor, VarCfg.U_All_Pet_star) or 0
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = isPetChuzhan,
        isPetJh = isPetJh > 0 and 1 or 0,
        allJieshu = isPetJh
    })

    -- ��������ѳ�ս������setPetInfo��Ϣ���¶�������ͼ��
    if serverChuzhan == 1 then
        local isPc = clientflag(actor) == 1
        local methodName = isPc and "PCMainPlayer" or "MainPlayer"
        -- ����лû���ʹ�ûû�ͼ�꣬����ʹ��Ĭ��ͼ��
        local icon = "pet_000"
        local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)
        local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
        if petTakeId and petTakeId > 0 and petTakeId ~= petBaseId then
            for _, v in pairs(petHHlist) do
                -- ʹ�� Model �ֶ�ƥ�䣨U_Pet_Take_Id �洢���� Model ֵ��
                if v.Model == petTakeId and v.mount_icon then
                    icon = v.mount_icon
                    print("���߻ָ����޶���ͼ��(�û�):", icon)
                    break
                end
            end
        else
            print("���߻ָ����޶���ͼ��(Ĭ��)")
        end
        Message.sendmsgEx(actor, methodName, "setPetInfo", {
            type = "red",
            max = 10000,
            now = 10000,
            icon = icon
        })
    end
end

-- ����������������
-- �������
-- 1. buff 110015 - ���Ｄ��/�������ԣ����̶�ֵ��+ ��ս���ԣ��ƶ��ٶ�+10%��
-- 2. buff 110016 - ����û����ԣ���� ClassID �̶�ֵ��
-- 3. buff 110046 - �����ս�û������ BattleSkill �̶�ֵ���� updateMountBattleSkillBuff �����
function mountMain.updateMountAttrBuff(actor)
    print("updateMountAttrBuff: ����������")
    local allstar = gethumvar(actor, VarCfg.U_All_Mount_star)
    print("updateMountAttrBuff: allstar =", allstar)
    if not allstar or allstar == 0 then
        -- δ�������ɾ�����buff
        delbuff(actor, MountBuffId)
        delbuff(actor, MountHuanhuaBuffId)
        return
    end

    -- ��������Ƿ��Ѽ���
    local isMountActive = gethumvar(actor, VarCfg.U_Mount_IS_SET)
    print("updateMountAttrBuff: isMountActive =", isMountActive)

    if not isMountActive or isMountActive == 0 then
        -- ����δ����
        delbuff(actor, MountBuffId)
        delbuff(actor, MountHuanhuaBuffId)
        return
    end

    -- �����buff
    delbuff(actor, MountBuffId)
    delbuff(actor, MountHuanhuaBuffId)

    -- ���buff
    addbuff(actor, MountBuffId)
    addbuff(actor, MountHuanhuaBuffId)

    -- 1. �������Ｄ��/�������Ե� buff 110015
    if mountlist[allstar] and mountlist[allstar].ClassID then
        local classIds = mountlist[allstar].ClassID
        for b = 1, #classIds do
            setbuffabil(actor, MountBuffId, tonumber(classIds[b][1]), "=", tonumber(classIds[b][2]))
        end
    end

    -- 2. ���ó�ս���ԣ��ƶ��ٶ�+10%������ID 140��
    -- ��ֱȣ�1000 = 10%
    setbuffabil(actor, MountBuffId, 140, "+", 1000)

    -- 3. ��������û����Ե� buff 110016���ۼӶ���û������ԣ�
    local ycListJson = gethumvar(actor, VarCfg.T_MountHuanHua)
    local ycList = json2tbl(ycListJson)

    -- ���ռ����лû����Ե���ʱ��
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

    -- Ȼ��һ����������������
    for attrId, attrValue in pairs(totalAttr) do
        setbuffabil(actor, MountHuanhuaBuffId, attrId, "=", attrValue)
    end
    print("updateMountAttrBuff: �û������������, �������� =", #totalAttr)
end

-- ���ݾɺ���
function mountMain.addsx(actor)
    mountMain.updateMountAttrBuff(actor)
end

function mountMain.shengji(actor)
    local nowlv = gethumvar(actor, VarCfg.U_All_Mount_star) or 0
    local nextlv = nowlv + 1
    if nextlv > #mountlist then return end
    if not mountlist[nextlv] or not mountlist[nextlv].ClassID then
        print("shengji: ��һ�����ò�����, nextlv:", nextlv)
        return
    end
    if not mountlist[nowlv] or not mountlist[nowlv].Cost then
        print("shengji: ��ǰ�����ò�����, nowlv:", nowlv)
        return
    end
    local classIds = mountlist[nextlv].ClassID
    local costs = mountlist[nowlv].Cost

    -- ֧�ֶ����ĸ�ʽ��itemId^num|itemId2^num2
    -- ����Ƿ��Ƕ������ĸ�ʽ��costs[1] �� table ������ number
    local isMultiCost = (type(costs[1]) == "table")

    if isMultiCost then
        -- �������ĸ�ʽ
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
            sendmsg(actor, 9, "���ϲ���")
            return
        end

        -- �۳����в���
        for i = 1, #costs do
            local itemId = tonumber(costs[i][1])
            local num = tonumber(costs[i][2])
            delItemNum(actor, itemId, num)
            print("���������۳�����" .. i .. " ID:", itemId, "����:", num)
        end
    else
        -- �����ĸ�ʽ�����ݾ����ݣ�
        local itemId = tonumber(costs[1])
        local num = tonumber(costs[2])
        if bagitemcount(actor, itemId) < num then
            sendmsg(actor, 9, "���ϲ���" .. num .. "��")
            return
        end
        delItemNum(actor, itemId, num)
    end

    if nowlv == 0 then -- ����
        sethumvar(actor, VarCfg.T_MountHuanHua, tbl2json({}))
        sethumvar(actor, VarCfg.U_All_Mount_star, 1)
        sethumvar(actor, VarCfg.U_Mount_IS_SET, 1)

        -- �״μ���ʱ���Զ������һ���û�����ѣ�
        local firstHH = mountHHlist[1]
        if firstHH then
            local ycList = {}
            ycList[firstHH.Name] = firstHH.grade
            sethumvar(actor, VarCfg.T_MountHuanHua, tbl2json(ycList))
            -- ���ûû����
            sethumvar(actor, VarCfg.U_Mount_Take_Id, firstHH.Model)
            sethumvar(actor, VarCfg.U_Mount_IS_HH, 1)
            changeappear(actor, 5, firstHH.Model)
            -- ��ӻû�buff
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
    -- ��ǰģ���Ƿ�û�
    if gethumvar(actor, VarCfg.U_Mount_IS_HH) == 0 then
        changeappear(actor, 5, mountBaseId)
        sethumvar(actor, VarCfg.U_Mount_Take_Id, mountBaseId)
    end
    sethumvar(actor, VarCfg.U_Mount_Base_ID, mountBaseId)
    Message.sendmsgEx(actor, "mountMain", "updateZQ",
        { lv = nextlv, mountBaseId = mountBaseId })
    MentorShipChangTask(actor, 6, 1, nextlv)
    print("shengji: nowlv =", nowlv, "nextlv =", nextlv)
    -- ͳһ������������buff
    mountMain.updateMountAttrBuff(actor)
    -- ��������û�ս������buff
    mountMain.updateMountBattleSkillBuff(actor)
    -- ͬ��������������buff��ȷ����Ӱ���������ԣ�
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
        local name = data.Name       -- ����
        local classid = data.ClassID -- ����
        local costs = data.Cost      -- ����
        local grade = data.grade     -- ����Ľ���

        -- ֧�ֶ����ĸ�ʽ
        local isMultiCost = (type(costs[1]) == "table")

        if isMultiCost then
            -- �������ĸ�ʽ
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
                sendmsg(actor, 9, "������ϲ���")
                return
            end

            -- �۳����в���
            for i = 1, #costs do
                local itemId = tonumber(costs[i][1])
                local num = tonumber(costs[i][2])
                delItemNum(actor, itemId, num)
            end
        else
            -- �����ĸ�ʽ�����ݾ����ݣ�
            local itemId = tonumber(costs[1])
            local num = tonumber(costs[2])
            if getItemNum(actor, itemId) < num then
                sendmsg(actor, 9, "������ϲ���" .. num .. "��")
                return
            end
            delItemNum(actor, itemId, num)
        end

        local ycList = json2tbl(gethumvar(actor, VarCfg.T_MountHuanHua))
        ycList[data.Name] = grade
        sethumvar(actor, VarCfg.T_MountHuanHua, tbl2json(ycList))
        local hhsxListStr = {}
        local mountHHid = gethumvar(actor, VarCfg.U_Mount_Take_Id)
        -- ����ǰ�Ļû�ģ��id
        if gethumvar(actor, VarCfg.U_Mount_IS_HH) == 1 then
            -- ��ǰ�Ѿ��û���
            -- �����û�֮ǰ�����Ƿ�ǰ����
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
                -- ��
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
        -- ͳһ������������buff
        mountMain.updateMountAttrBuff(actor)
        -- ͬ��������������buff��ȷ����Ӱ���������ԣ�
        mountMain.updatePetAttrBuff(actor)
        mountMain.updatePetBattleSkillBuff(actor)
        Message.sendmsgEx(actor, "mountMain", "updateHHmodel", {
            ycList = ycList,
            name = name,
            grade = grade,
            mountHHid = mountHHid
        })
    else
        sendmsg(actor, 9, "����ʧ��")
    end
end

-- ��ɾ���ɵĻû�buff
function mountMain.setMountHHBuff(actor, oldbuffList, newBuffList, isCancel)
    if tonumber(isCancel) == 0 then
        for b = 1, #oldbuffList do delbuff(actor, oldbuffList[b]) end
        for c = 1, #newBuffList do addbuff(actor, newBuffList[c]) end
    else
        -- ȡ���û�
        for b = 1, #oldbuffList do delbuff(actor, oldbuffList[b]) end
    end
end

function mountMain.setModel(actor, data)
    -- {"�û�����"=�û�Ʒ��}
    local allhhList = {}
    local baseMountId = gethumvar(actor, VarCfg.U_Mount_Base_ID)
    local mountTakeId = gethumvar(actor, VarCfg.U_Mount_Take_Id)
    local oldMountTakeId = mountTakeId
    local bdid = 0
    local isCancel = 0
    local oldbuffList = {}
    local newBuffList = {}
    if mountTakeId == data.mountId then
        -- ȡ���û�
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
        -- �û�
        allhhList = json2tbl(gethumvar(actor, VarCfg.T_MountHuanHua))
        if gethumvar(actor, VarCfg.U_Mount_IS_HH) == 1 then
            -- ԭ���Ѿ��лû���
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
    -- ͳһ������������buff�������û����ԣ�
    mountMain.updateMountAttrBuff(actor)
    -- ��������û�ս������buff
    mountMain.updateMountBattleSkillBuff(actor)
    -- ͬ��������������buff��ȷ����Ӱ���������ԣ�
    mountMain.updatePetAttrBuff(actor)
    mountMain.updatePetBattleSkillBuff(actor)
    Message.sendmsgEx(actor, "mountMain", "UpdateHHBtnName", {
        mountHHid = mountTakeId,
        isCancel = isCancel,
        oldModelId = oldMountTakeId
    })
end

function mountMain.chuzhan(actor, data)
    -- �����ս���ƣ���Ҫ�ﵽһ�ײ��ܳ�ս
    local mountStar = gethumvar(actor, VarCfg.U_All_Mount_star)
    if not mountStar or mountStar == 0 then
        sendmsg(actor, 9, "���ȼ�������")
        return
    end
    if mountStar < 11 then
        sendmsg(actor, 9, "����δ��һ�ף��޷������ս")
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
    -- ͬ��������������buff��ȷ����Ӱ���������ԣ�
    mountMain.updatePetAttrBuff(actor)
    mountMain.updatePetBattleSkillBuff(actor)
    Message.sendmsgEx(actor, "mountMain", "updateBtnName",
        { status = horsestate(actor) })
end

function mountMain.jihuo(actor) sendmsg(actor, 9, "���ȼ�������") end

function mountMain.lsJihuo(actor) sendmsg(actor, 9, "���ȼ�������") end

-- ===== �����޹����ѷ��������º��������½ṹ��� =====
-- ˵�����ɵ����޼���ٻ����ջصȹ����ѱ��µ����޽ṹ���
-- �½ṹʹ����������ͬ������/����ϵͳ�ͻû�ϵͳ
-- �����Ҫʹ�þɹ��ܣ���ȡ��ע�Ͳ�������ص���

-- ���޼���/�����ӿ�
function mountMain.lsjihuo(actor, data)
    local nowlv = gethumvar(actor, VarCfg.U_All_Pet_star)

    if nowlv > 0 then
        return sendmsg(actor, 9, "�Ѽ���")
    end

    -- ��鼤���Ƿ���Ҫ���ģ����ݶ����ĸ�ʽ��
    local costs = petlist[0].Cost
    if costs then
        local isMultiCost = (type(costs[1]) == "table")

        if isMultiCost then
            -- �������ģ�������в����Ƿ��㹻
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
                return sendmsg(actor, 9, "������ϲ���")
            end

            -- �۳����в���
            for i = 1, #costs do
                local itemId = tonumber(costs[i][1])
                local num = tonumber(costs[i][2])
                delItemNum(actor, itemId, num)
            end
        else
            -- �����ĸ�ʽ�����ݾ����ݣ�
            local itemId = tonumber(costs[1])
            local num = tonumber(costs[2])
            if bagitemcount(actor, itemId) < num then
                return sendmsg(actor, 9, "������ϲ���" .. num .. "��")
            end
            delItemNum(actor, itemId, num)
        end
    end

    mountMain.petShengji(actor)

    -- ����updateLSView��level��Ϣ
    local newLv = gethumvar(actor, VarCfg.U_All_Pet_star)
    print("=== lsjihuo ������Ϣ, newLv:", newLv)
    Message.sendmsgEx(actor, "mountMain", "updateLSView", {
        name = "pet",
        lv = newLv
    })
    Message.sendmsgEx(actor, "mountMain", "level", {
        lv = newLv,
        Name = "pet"
    })
    print("=== lsjihuo ��� ===")
end

-- function mountMain.getPetAttr(actor, modelId)
--     -- �ɵ����޻�ȡ�����߼����� mountMain.updatePetAttrBuff ���
-- end

-- function mountMain.updatePetModel(actor, data)
--     -- �ɵ����޸���ģ���߼����� mountMain.setPetModel ���
-- end

-- function mountMain.recallpet(actor, data, isNow, isLoginZH)
--     -- �ɵ������ٻ��߼���Ҫ����ʵ���������ʵ��
-- end

-- function mountMain.resurre(actor)
--     -- �ɵ����޸����߼���Ҫ����ʵ���������ʵ��
-- end

-- function mountMain.unrecallpet(actor, data, playerDie, isLoginZH)
--     -- �ɵ������ջ��߼���Ҫ����ʵ���������ʵ��
-- end

-- function mountMain.setPetAttr(actor, isShowDie)
--     -- �ɵ��������������߼������½ṹ���
-- end

-- ===== ���޳�ս/�ٻع��� =====
-- ���޳�ս/�ٻ���ں���
function mountMain.petChuzhan(actor)
    print("=== ���޳�ս/�ٻ� ===")
    -- �� U_All_Pet_star �ж��Ƿ񼤻>0��ʾ�Ѽ��
    local isActivated = gethumvar(actor, VarCfg.U_All_Pet_star)
    if not isActivated or isActivated == 0 then
        sendmsg(actor, 9, "���ȼ�������")
        return
    end

    -- ���޳�ս���ƣ���Ҫ�ﵽһ�ײ��ܳ�ս
    if isActivated < 11 then
        sendmsg(actor, 9, "����δ��һ�ף��޷������ս")
        return
    end

    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    if petMark and petMark ~= "" then
        -- �����ѳ�ս��ִ���ٻ�
        print("�����ѳ�ս��ִ���ٻ�")
        mountMain.unrecallpet(actor)
    else
        -- ����δ��ս��ִ���ٻ�
        print("����δ��ս��ִ���ٻ�")
        mountMain.recallpet(actor)
    end
end

-- �ٻ����ޣ���ս��
function mountMain.recallpet(actor)
    -- ��������������ʱ��
    disabletimer(actor, 49)

    local petBaseId = gethumvar(actor, VarCfg.U_Pet_Base_ID)
    local petTakeId = gethumvar(actor, VarCfg.U_Pet_Take_Id)

    if not petBaseId or petBaseId == 0 then
        petBaseId = 900001
    end

    if not petTakeId or petTakeId == 0 then
        petTakeId = petBaseId
    end

    -- ��ȡ���޹���ID
    local monsterId = 80001

    -- ����Ƿ��ǻû���̬
    local isHuanhua = false
    local petTakeIdNum = tonumber(petTakeId)
    local petBaseIdNum = tonumber(petBaseId)

    -- �� petTakeId ƥ�� PetHuanhua ��ȡ��������
    local petName = nil
    if petTakeIdNum and petTakeIdNum > 0 then
        for _, hhData in pairs(petHHlist) do
            if tonumber(hhData.Model) == petTakeIdNum then
                petName = hhData.Name
                break
            end
        end
    end

    -- ��ȡ��ǰ�û��ȼ�
    local currentHHGrade = 0
    if petName then
        local ycList = json2tbl(gethumvar(actor, VarCfg.T_PetHuanHua))
        if ycList and ycList[petName] then
            currentHHGrade = tonumber(ycList[petName]) or 0
        end
    end

    -- ������ Name + grade ƥ�䣬��ȡ��Ӧ�ȼ��Ĺ���ID
    if petName and currentHHGrade > 0 then
        for _, hhData in pairs(petHHlist) do
            if hhData.Name == petName and tonumber(hhData.grade) == currentHHGrade then
                monsterId = hhData.Monster_ID
                isHuanhua = true
                break
            end
        end
    end

    -- ���ûƥ�䵽���� petTakeId ����ƥ�� Model
    if not isHuanhua and petTakeIdNum and petTakeIdNum > 0 then
        for _, hhData in pairs(petHHlist) do
            if tonumber(hhData.Model) == petTakeIdNum and hhData.Monster_ID then
                monsterId = hhData.Monster_ID
                isHuanhua = true
                break
            end
        end
    end

    -- ������ǻû���̬����Pet���ñ��л�ȡ
    if not isHuanhua and petBaseId then
        for i = 0, 10 do
            if petlist[i] and petlist[i].Model and tonumber(petlist[i].Model) == petBaseIdNum then
                monsterId = tonumber(petlist[i].Monster_ID) or 80001
                break
            end
        end
    end

    sethumvar(actor, VarCfg.U_Pet_Now_Model, petTakeId)

    -- ����Ƿ����г���mark�����û��������ӳ���
    local existingMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    local mark = existingMark

    -- �������Ƿ��Ѿ��ڳ���
    local petIdx = getpetidx(actor, mark)

    if mark and mark ~= "" and petIdx then
        -- �����Ѿ��ڳ��ϣ�����Ҫ�ٴ����
    else
        -- mark�����ڻ�����Ѳ��ڳ��ϣ���Ҫ�������
        mark = addpet(actor, monsterId)
        if not mark or mark == "" then
            sendmsg(actor, 9, "�������ʧ��")
            return
        end
        -- ���������Ϣ�� T_Pet_Mark
        sethumvar(actor, VarCfg.T_Pet_Mark, mark)
    end

    -- �ӱ����л�ȡmarkȷ����Ч
    mark = gethumvar(actor, VarCfg.T_Pet_Mark)

    -- �ٻ�����
    recallpet(actor, mark)
    -- ���ó�ս״̬
    sethumvar(actor, VarCfg.U_Pet_IS_SET, 1)

    -- ���ù���ģʽ��2=�������˹�����
    setpetrelax(actor, mark, 2)

    -- ������������
    mountMain.setPetAttr(actor)

    -- ������������buff
    mountMain.updatePetAttrBuff(actor)
    -- �������޻û�ս������buff
    mountMain.updatePetBattleSkillBuff(actor)

    -- �����ٻؽ����Ϣ���ͻ���
    local isPetChuzhan = gethumvar(actor, VarCfg.U_Pet_IS_SET) or 0
    Message.sendmsgEx(actor, "mountMain", "recallpetResult", {
        showPetModelId = petTakeId,
        selectViewPetId = petBaseId,
        isPetChuzhan = isPetChuzhan
    })

    -- ����setPetInfo��Ϣ���¶�������ͼ��
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

    -- ����petUpdateBtn��Ϣ���°�ť״̬
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = isPetChuzhan,
        isPetJh = (tonumber(gethumvar(actor, VarCfg.U_All_Pet_star)) or 0) > 0 and 1 or 0,
        allJieshu = gethumvar(actor, VarCfg.U_All_Pet_star)
    })
end

-- �ջ�����
function mountMain.unrecallpet(actor, petMark)
    -- ���û�д���petMark����ӱ�����ȡ
    if not petMark then
        petMark = gethumvar(actor, VarCfg.T_Pet_Mark)
    end

    if not petMark or petMark == "" then
        return
    end

    -- �������޸��ʱ��
    disabletimer(actor, 49)

    -- �ջ�����
    unrecallpet(actor, petMark)

    -- �������mark
    sethumvar(actor, VarCfg.T_Pet_Mark, "")
    -- ������Ϣ״̬
    sethumvar(actor, VarCfg.U_Pet_IS_SET, 0)

    -- ������������buff
    mountMain.updatePetAttrBuff(actor)
    -- �������޻û�ս������buff
    mountMain.updatePetBattleSkillBuff(actor)

    -- �����ջؽ����Ϣ���ͻ���
    Message.sendmsgEx(actor, "mountMain", "unrecallpetResult")

    -- ����setPetInfo��Ϣ���ض�������ͼ��
    local isPc = clientflag(actor) == 1
    local methodName = isPc and "PCMainPlayer" or "MainPlayer"
    Message.sendmsgEx(actor, methodName, "setPetInfo", {
        type = "red",
        max = 1,
        now = 1
    })

    -- ����petUpdateBtn��Ϣ���°�ť״̬
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = 0,
        isPetJh = (tonumber(gethumvar(actor, VarCfg.U_All_Pet_star)) or 0) > 0 and 1 or 0,
        allJieshu = gethumvar(actor, VarCfg.U_All_Pet_star)
    })
end

-- ���޸���
function mountMain.resurre(actor)
    local petMark = gethumvar(actor, VarCfg.T_Pet_Mark)

    if not petMark or petMark == "" then
        return
    end

    -- �������
    realivepet(actor, petMark)

    -- �����ٻ�����
    mountMain.recallpet(actor)

    -- ȷ�����ó�ս״̬
    sethumvar(actor, VarCfg.U_Pet_IS_SET, 1)

    -- ��������
    mountMain.setPetAttr(actor)
    mountMain.updatePetAttrBuff(actor)

    -- ����setPetInfo��Ϣ���¶�������ͼ��
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

    -- ����petUpdateBtn��Ϣ���°�ť״̬
    Message.sendmsgEx(actor, "mountMain", "petUpdateBtn", {
        isPetChuzhan = 1,
        isPetJh = (tonumber(gethumvar(actor, VarCfg.U_All_Pet_star)) or 0) > 0 and 1 or 0,
        allJieshu = gethumvar(actor, VarCfg.U_All_Pet_star)
    })
end

-- ���������ӿڣ����ϵͳ���룩
function mountMain.levelUp(actor, data)
    -- data.name = ��������, data.maxLv = ���ȼ�, data.itemId = ����ID
    local nowlv = gethumvar(actor, VarCfg.U_All_Pet_star)

    if not nowlv or nowlv == 0 then
        return sendmsg(actor, 9, "���ȼ�������")
    end

    local nextlv = nowlv + 1

    if nextlv > #petlist then
        return sendmsg(actor, 9, "������")
    end

    if not petlist[nowlv] or not petlist[nowlv].Cost then
        return sendmsg(actor, 9, "���ô���")
    end

    local costs = petlist[nowlv].Cost

    -- ֧�ֶ����ĸ�ʽ��2801^40|3958^5
    -- ����Ƿ��Ƕ������ĸ�ʽ��costs[1] �� table ������ number
    local isMultiCost = (type(costs[1]) == "table")

    if isMultiCost then
        -- �������ĸ�ʽ��{[1] = {[1] = itemId, [2] = num}, [2] = {[1] = itemId, [2] = num}}
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
            return sendmsg(actor, 9, "���ϲ���")
        end
    else
        -- �����ĸ�ʽ�����ݾ����ݣ�
        local itemId = tonumber(costs[1])
        local num = tonumber(costs[2])

        if bagitemcount(actor, itemId) < num then
            return sendmsg(actor, 9, "���ϲ���" .. num .. "��")
        end
    end

    -- ����petShengji���������߼���petShengji�ڲ���۳����ϣ�
    mountMain.petShengji(actor)

    -- ����level��Ϣ���ϵͳ����
    local newLv = gethumvar(actor, VarCfg.U_All_Pet_star)
    -- �ȷ���updateLSView��ʼ��allPetsActive��
    local allPets = { ["pet"] = newLv }
    Message.sendmsgEx(actor, "mountMain", "updateLSView", {
        allPets = allPets,
        name = "pet",
        lv = newLv
    })
    -- �ٷ���level��Ϣ
    Message.sendmsgEx(actor, "mountMain", "level", {
        lv = newLv,
        Name = "pet"
    })

    -- ��������
    if newLv >= 10 then
        MentorShipChangTask(actor, 6, 1)
    end
end

-- function mountMain.addPetToList(actor, monsterId, modelId)
--     -- �ɵ�������޵��б��߼���Ҫ����ʵ���������ʵ��
-- end

-- function mountMain.fhpet(actor)
--     -- �ɵ���������߼���Ҫ����ʵ���������ʵ��
-- end

-- function mountMain.applyPetBattleSkills(actor, petId, petLevel)
--     -- �ɵ����޳�ս�����߼���Ҫ����ʵ���������ʵ��
-- end

-- function mountMain.clearPetBattleSkills(actor)
--     -- �ɵ�������޳�ս�����߼���Ҫ����ʵ���������ʵ��
-- end

-- ===== ��Ϸ�¼�ע�� =====

GameEvent.add(EventCfg.onPlayDie, function(actor, target)
    -- ���ݾɱ������±���
    local oldBase = tonumber(gethumvar(actor, VarCfg.U_PETS_Take_Base)) or 0
    local newBase = tonumber(gethumvar(actor, VarCfg.U_Pet_Base_ID)) or 0
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

-- ��ɫ��¼���ʱ�������������
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
<<<<<<< HEAD
    giveitem(actor, "�����ٻ����������ԣ�#999")
    --giveitem(actor, "�����ٻ�����׷�籪��#999")
    --giveitem(actor, "�����ٻ���������Ϭţ��#999")
    --giveitem(actor, "�����ٻ������ڱ���#999")
    --giveitem(actor, "�����ٻ�����ѩ����#999")
    --giveitem(actor, "�����ٻ��������컢��#999")
    --giveitem(actor, "�����ٻ���������ʨ��#999")
    --giveitem(actor, "�����ٻ�����쫷����ǣ�#999")
    --giveitem(actor, "�����ٻ�������ʨȮ��#999")
    --giveitem(actor, "�����ٻ�������ľ������#999")
    giveitem(actor, "��è#10")
    giveitem(actor, "����#10")
    giveitem(actor, "������#10")
    giveitem(actor, "С����#2")
    giveitem(actor, "����#2")
    giveitem(actor, "��������ʯ#9999")
    giveitem(actor, "���������ʵ�#9999")
=======
    giveitem(actor, "�����ٻ����������ԣ�#999")
    --giveitem(actor, "�����ٻ�����׷�籪��#999")
    --giveitem(actor, "�����ٻ���������Ϭţ��#999")
    --giveitem(actor, "�����ٻ������ڱ���#999")
    --giveitem(actor, "�����ٻ�����ѩ����#999")
    --giveitem(actor, "�����ٻ��������컢��#999")
    --giveitem(actor, "�����ٻ���������ʨ��#999")
    --giveitem(actor, "�����ٻ�����쫷���ǣ�#999")
    --giveitem(actor, "�����ٻ�������ʨȮ��#999")
    --giveitem(actor, "�����ٻ�������ľ������#999")
    giveitem(actor, "��è#10")
    giveitem(actor, "���#10")
    giveitem(actor, "������#10")
    giveitem(actor, "С����#2")
    giveitem(actor, "���#2")
    giveitem(actor, "��������ʯ#9999")
    giveitem(actor, "��������ʵ�#9999")
>>>>>>> eb9803c7 (调整复活按钮)

    --giveitem(actor, "��Ԫ���ʯ��������#5")
    --giveitem(actor, "���Ǻ���ʯ��������#5")
    --giveitem(actor, "��Ѫʯ����������#1")
    --giveitem(actor, "��Ѫʯ��ת��Ϊ�أ�#1")
    --giveitem(actor, "���ʯ��������#5")
    --giveitem(actor, "����ʯ�������#5")
    --giveitem(actor, "51003#2")
    --giveitem(actor, "51005#2")
    --giveitem(actor, "34001#2")
end, mountMain)

Message.RegisterNetMsg(ssrNetMsgCfg.mountMain, mountMain)

return mountMain
