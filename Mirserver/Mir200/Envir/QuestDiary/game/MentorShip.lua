MentorShip = {}
local filname = "MentorShip"
local MasterApprenticeShip = require("Envir/QuestDiary/game_config/cfgcsv/MasterApprenticeShip.lua")
local Master_and_apprentice = require("Envir/QuestDiary/game_config/cfgcsv/Master_and_apprentice.lua")
local mentorShipMon = require("Envir/QuestDiary/game_config/cfgcsv/mentorShipMon.lua")
local needLevel = require("Envir/QuestDiary/game_config/Level.lua")
local StoreData = require("Envir/QuestDiary/game_config/Store.lua")
local SkillUpgrade = require("Envir/QuestDiary/game_config/SkillUpgrade.lua")
function seledata(v, fb)
    if v ~= nil then
        return v
    end
    return fb
end

function MentorShip.getMasterList(actor, data)
    local getNum = 2
    if data == "*" then
        getNum = 2
    else
        getNum = 300
    end
    local allMasterList = custgetvarbyname(0, "master", getNum)
    local resultList = {}
    if allMasterList then
        for userId, v in pairs(allMasterList) do
            local user = json2tbl(v)
            if v and tonumber(userId) ~= tonumber(userid(actor)) and (string.find(user.UserName, data) or data == "*") then
                resultList[userId] = user
            end
        end
    end
    Message.sendmsgEx(actor, "FindMentorPanel", "OnRecvMentorList", resultList)
end

--成为师傅
function MentorShip.applyToMaster(actor, data)
    local myRelation = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
    if myRelation ~= "" then
        myRelation = json2tbl(myRelation)
        if #myRelation.apprentice == 3 then
            return sendmsg(actor, 9, "徒弟已满")
        end
    end
    local newObj = data
    local userId = userid(actor)
    local masterInfo = {
        UserID = userId,
        UserName = username(userId),
        GuildName = targetinfo(userId, "GUILDNAME"), --行会名字
        AvatarID = targetinfo(userId, "AVATARID"),
        PhotoframeID = targetinfo(userId, "PHOTOFRAMEID"),
        Job = job(userId),
        Level = level(userId),
        Sex = gender(userId),
        MapName = targetinfo(userId, "MAPTITLE"),
        PublishGender = seledata(data.gender, (seledata(gender(userId), "保密"))),
        PublishOnline = data.online,
        PublishMap = data.map, -- 当前城市名字
        bodyId = data.bodyId,
        headId = data.headId,
        weaponId = data.rWeapon,
        wingId = data.wingId,
        faceId = data.faceId,
        goodEvilid = targetinfo(userId, "GOODEVILID")
    }
    defcustvar(0, userId, "master", 1)
    sefcustvar(0, userId, "master", tbl2json(masterInfo))
end

--成为徒弟
function MentorShip.applyToApprentice(actor, data)
    local myRelation = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
    if myRelation ~= "" then
        myRelation = json2tbl(myRelation)
        if myRelation.myMaster and myRelation.myMaster.UserID then
            return sendmsg(actor, 9, "已有师傅")
        end
    end
    --判断出师次数
    local myChuShiCount = getcustvar("11_" .. userid(actor) .. "_" .. "t_ChuShiCount")
    myChuShiCount = (myChuShiCount == "") and 0 or tonumber(myChuShiCount)
    local maxChuShiTimes = tonumber(MasterApprenticeShip["max_chushi_times"].VALUE)
    if myChuShiCount >= maxChuShiTimes then
        return sendmsg(actor, 9, "出师次数已达上限，无法发布寻师信息")
    end

    local newObj = data
    local userId = userid(actor)
    local masterInfo = {
        UserID = userId,
        UserName = username(userId),
        GuildName = targetinfo(userId, "GUILDNAME"), --行会名字
        AvatarID = targetinfo(userId, "AVATARID"),
        PhotoframeID = targetinfo(userId, "PHOTOFRAMEID"),
        Job = job(userId),
        Level = level(userId),
        Sex = gender(userId),
        MapName = targetinfo(userId, "MAPTITLE"),
        PublishGender = seledata(data.gender, (seledata(gender(userId), "保密"))),
        PublishOnline = data.online,
        PublishMap = data.map, -- 当前城市名字
        bodyId = data.bodyId,
        headId = data.headId,
        weaponId = data.rWeapon,
        wingId = data.wingId,
        faceId = data.faceId,
        goodEvilid = targetinfo(userId, "GOODEVILID")
    }
    defcustvar(0, userId, "quanApparence", 1)
    sefcustvar(0, userId, "quanApparence", tbl2json(masterInfo))
end

--申请拜师
function MentorShip.ApplyMentor(actor, data)
    dump(data)
    --当前我的师徒关系
    local getMasterAndAppr = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
    if getMasterAndAppr == "" then
        getMasterAndAppr = {
            myMaster = nil,
            apprentice = {}
        }
    else
        getMasterAndAppr = json2tbl(getMasterAndAppr)
    end
    if getMasterAndAppr.myMaster and getMasterAndAppr.myMaster.UserID then
        --有师傅了
        sendmsg(actor, 9, "[color=#ff0000]已有师傅，无法申请[/color]")
        return
    end

    --判断出师次数
    local myChuShiCount = getcustvar("11_" .. userid(actor) .. "_" .. "t_ChuShiCount")
    myChuShiCount = (myChuShiCount == "") and 0 or tonumber(myChuShiCount)
    local maxChuShiTimes = tonumber(MasterApprenticeShip["max_chushi_times"].VALUE)
    if myChuShiCount >= maxChuShiTimes then
        sendmsg(actor, 9, "[color=#ff0000]出师次数已达上限，无法再次拜师[/color]")
        return
    end

    --是否能拜师判断
    local myLv = level(actor)
    local targetData = data
    local targetLv = targetData.Level
    if (targetLv - myLv) < tonumber(MasterApprenticeShip["min_apply"].VALUE) then
        sendmsg(actor, 9, "[color=#ff0000]因等级原因无法结成师徒[/color]")
        return
    end
    --去除拜师职业限制
    --if job(actor) ~= targetData.Job then
    --    sendmsg(actor, 9, "[color=#ff0000]因职业原因无法结成师徒[/color]")
    --    return
    --end
    if tonumber(targetinfo(actor, "GOODEVILID")) > 0 then
        if targetinfo(actor, "GOODEVILID") ~= targetData.goodEvilid then
            sendmsg(actor, 9, "[color=#ff0000]因阵营原因无法结成师徒[/color]")
            return
        end
    end
    --可以拜师
    --目标的申请拜师列表
    local ApprApplyList = getcustvar("11_" .. data.UserID .. "_" .. "t_ApprApplyList")
    if ApprApplyList == "" then
        ApprApplyList = {}
    else
        ApprApplyList = json2tbl(ApprApplyList)
    end
    local isCan = true
    for i = 1, #ApprApplyList do
        if tonumber(ApprApplyList[i].UserID) == tonumber(userid(actor)) then
            sendmsg(actor, 9, "[color=#ff0000]已向该玩家发送申请[/color]")
            isCan = false
            break
        end
    end
    if isCan then
        sendmsg(actor, 9, "[color=#ff0000]申请已发送[/color]")
        local myInfo = {
            UserID = userid(actor),
            UserName = username(actor),
            GuildName = targetinfo(actor, "GUILDNAME"), --行会名字
            AvatarID = targetinfo(actor, "AVATARID"),
            PhotoframeID = targetinfo(actor, "PHOTOFRAMEID"),
            Job = job(actor),
            Level = level(actor),
            Sex = gender(actor),
            zsLevel = targetinfo(actor, 'RELEVEL'),
            GOODEVILID = targetinfo(actor, "GOODEVILID")
        }
        ApprApplyList[#ApprApplyList + 1] = myInfo
        --师傅的徒弟申请列表
        defcustvar(11, data.UserID, 't_ApprApplyList', 1)
        sefcustvar(11, data.UserID, 't_ApprApplyList', tbl2json(ApprApplyList))
        Message.sendmsgEx(data.UserID, "MentorShipMain", "addApplyBubble")
    end
end

--申请收徒
function MentorShip.ApplyApprentice(actor, data)
    dump(data)
    local getMasterAndAppr = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
    if getMasterAndAppr == "" then
        getMasterAndAppr = {
            myMaster = nil,
            apprentice = {}
        }
    else
        getMasterAndAppr = json2tbl(getMasterAndAppr)
    end
    if #getMasterAndAppr.apprentice >= 3 then
        sendmsg(actor, 9, "[color=#ff0000]徒弟已满，无法申请[/color]")
        return
    end
    --是否能收徒判断
    local myLv = level(actor)
    local targetData = data
    local targetLv = targetData.Level
    if (myLv - targetLv) < tonumber(MasterApprenticeShip["min_apply"].VALUE) then
        sendmsg(actor, 9, "[color=#ff0000]因等级原因无法结成师徒[/color]")
        return
    end
    --去除拜师职业限制
    --if job(actor) ~= targetData.Job then
    --    sendmsg(actor, 9, "[color=#ff0000]因职业原因无法结成师徒[/color]")
    --    return
    --end
    if tonumber(targetData.goodEvilid) > 0 then
        if targetinfo(actor, "GOODEVILID") ~= targetData.goodEvilid then
            sendmsg(actor, 9, "[color=#ff0000]因阵营原因无法结成师徒[/color]")
            return
        end
    end
    --可以收徒
    --目标的申请收徒列表
    local MentorApplyList = getcustvar("11_" .. data.UserID .. "_" .. "t_MentorApplyList")
    if MentorApplyList == "" then
        MentorApplyList = {}
    else
        MentorApplyList = json2tbl(MentorApplyList)
    end
    local isCan = true
    for i = 1, #MentorApplyList do
        if tonumber(MentorApplyList[i].UserID) == tonumber(userid(actor)) then
            sendmsg(actor, 9, "[color=#ff0000]已向该玩家发送申请[/color]")
            isCan = false
            break
        end
    end
    if isCan then
        sendmsg(actor, 9, "[color=#ff0000]申请已发送[/color]")
        local myInfo = {
            UserID = userid(actor),
            UserName = username(actor),
            GuildName = targetinfo(actor, "GUILDNAME"), --行会名字
            AvatarID = targetinfo(actor, "AVATARID"),
            PhotoframeID = targetinfo(actor, "PHOTOFRAMEID"),
            Job = job(actor),
            Level = level(actor),
            Sex = gender(actor),
            zsLevel = targetinfo(actor, 'RELEVEL'),
            GOODEVILID = targetinfo(actor, "GOODEVILID")
        }
        MentorApplyList[#MentorApplyList + 1] = myInfo
        --徒弟的师傅申请列表
        defcustvar(11, data.UserID, 't_MentorApplyList', 1)
        sefcustvar(11, data.UserID, 't_MentorApplyList', tbl2json(MentorApplyList))
        Message.sendmsgEx(data.UserID, "MentorShipMain", "addApplyBubble")
    end
end

function MentorShip.getApprenticeList(actor, data)
    local getNum = 2
    if data == "*" then
        getNum = 2
    else
        getNum = 300
    end
    local allApparenceList = custgetvarbyname(0, "quanApparence", getNum)
    local resultList = {}
    if allApparenceList then
        for userId, v in pairs(allApparenceList) do
            local user = json2tbl(v)
            if v and tonumber(userId) ~= tonumber(userid(actor)) and (string.find(user.UserName, data) or data == "*") then
                resultList[userId] = user
            end
        end
    end
    Message.sendmsgEx(actor, "FindApprenticePanel", "OnRecvApprenticeList", resultList)
end

function MentorShip.GetApplyList(actor, data)
    --mode 1 申请收徒列表 2 申请拜师列表
    local result = {}
    if tonumber(data) == 1 then
        result = getcustvar("11_" .. userid(actor) .. "_" .. "t_MentorApplyList")
    end
    if tonumber(data) == 2 then
        result = getcustvar("11_" .. userid(actor) .. "_" .. "t_ApprApplyList")
    end
    if tonumber(data) == 3 then
        local result1 = getcustvar("11_" .. userid(actor) .. "_" .. "t_MentorApplyList")
        local result2 = getcustvar("11_" .. userid(actor) .. "_" .. "t_ApprApplyList")
        if result1 == "" then
            result1 = {}
        else
            result1 = json2tbl(result1)
        end
        if result2 == "" then
            result2 = {}
        else
            result2 = json2tbl(result2)
        end
        ---申请收徒
        for i = 1, #result1 do
            result1[i].todoType = 2
            table.insert(result, result1[i])
        end
        --申请拜师
        for w = 1, #result2 do
            result2[w].todoType = 1
            table.insert(result, result2[w])
        end
    end
    if tonumber(data) == 3 then
        Message.sendmsgEx(actor, "MyShipApplyLists", "setList", result)
    else
        if result == "" then
            result = {}
        else
            result = json2tbl(result)
        end
        Message.sendmsgEx(actor, "ShipApplyLists", "setList", result)
    end
end

function MentorShip.doOper(actor, data)
    local mode = data.mode
    local status = data.status
    local targetData = data.targetData
    local myInfo = {
        UserID = userid(actor),
        UserName = username(actor),
        GuildName = targetinfo(actor, "GUILDNAME"), --行会名字
        AvatarID = targetinfo(actor, "AVATARID"),
        PhotoframeID = targetinfo(actor, "PHOTOFRAMEID"),
        Job = job(actor),
        Level = level(actor),
        Sex = gender(actor),
        zsLevel = targetinfo(actor, 'RELEVEL'),
        goodEvilid = targetinfo(actor, "GOODEVILID")
    }
    --我的师徒关系
    local myRelation = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
    --申请成为我的徒弟的师徒关系
    local targetRelation = getcustvar("11_" .. targetData.UserID .. "_" .. "t_MasterAndApprt")
    --全局徒弟列表
    local allApprenticeList = custgetvarbyname(0, "quanApparence", 1)
    if myRelation == "" then
        myRelation = {
            myMaster = {},
            apprentice = {},
            applyRemoveMyAppliction = {},
            applyRemoveMyMaster = nil,
            applyRemoveMyMasterById = nil
        }
    else
        myRelation = json2tbl(myRelation)
    end
    if targetRelation == "" then
        targetRelation = {
            myMaster = {},
            apprentice = {},
            applyRemoveMyAppliction = {},
            applyRemoveMyMaster = nil,
            applyRemoveMyMasterById = nil
        }
    else
        targetRelation = json2tbl(targetRelation)
    end
    --申请收徒
    if mode == 1 then
        --操作是否成为我的师傅
        if status == 1 then
            if myRelation.myMaster and myRelation.myMaster.UserID then
                sendmsg(actor, 9, "[color=#ff0000]已有师傅，无法再拜师[/color]")
                return
            else
                myRelation.myMaster = targetData
            end
            if #targetRelation.apprentice >= 3 then
                sendmsg(actor, 9, "[color=#ff0000]对方徒弟已满[/color]")
                return
            else
                targetRelation.apprentice[#targetRelation.apprentice + 1] = myInfo
                --移除徒弟列表
                sefcustvar(0, userid(actor), "quanApparence", nil)
            end
            if #targetRelation.apprentice == 3 then
                --徒弟收满了，删掉师徒列表
                sefcustvar(0, targetData.UserID, "master", nil)
            end
        end
        --删掉这条申请记录
        local result = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "t_MentorApplyList"))
        local which = 0
        for i = 1, #result do
            if result[i].UserID == targetData.UserID then
                which = i
            end
        end
        table.remove(result, which)
        defcustvar(11, userid(actor), 't_MentorApplyList', 1)
        sefcustvar(11, userid(actor), 't_MentorApplyList', tbl2json(result))
        --设置自己的师徒关系
        defcustvar(11, userid(actor), 't_MasterAndApprt', 1)
        sefcustvar(11, userid(actor), 't_MasterAndApprt', tbl2json(myRelation))
        --设置师傅的师徒关系
        defcustvar(11, targetData.UserID, 't_MasterAndApprt', 1)
        sefcustvar(11, targetData.UserID, 't_MasterAndApprt', tbl2json(targetRelation))
        --初始化徒弟任务进度
        MentorShip.setApprenticeTask(actor, userid(actor))
        MentorShip.GetMyRelation(targetData.UserID, 'MentorShipMain')
    end
    --申请拜师
    if mode == 2 then
        --操作是否成为我的徒弟
        if status == 1 then
            --通过
            if #myRelation.apprentice == 3 then
                --徒弟已满，无法再收
                sendmsg(actor, 9, "[color=#ff0000]徒弟已满，无法再收新徒弟[/color]")
                return
            else
                myRelation.apprentice[#myRelation.apprentice + 1] = targetData
            end
            if targetRelation.myMaster and targetRelation.myMaster.UserID then
                sendmsg(actor, 9, "[color=#ff0000]对方已有师傅[/color]")
                return
            else
                targetRelation.myMaster = myInfo
                --移除徒弟列表
                sefcustvar(0, targetData.UserID, "quanApparence", nil)
            end
        end
        if #myRelation.apprentice == 3 then
            --徒弟收满了，删掉师徒列表
            sefcustvar(0, targetData.UserID, "master", nil)
        end
        --删掉这条申请记录
        local result = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "t_ApprApplyList"))
        local which = 0
        for i = 1, #result do
            if result[i].UserID == targetData.UserID then
                which = i
            end
        end
        table.remove(result, which)
        defcustvar(11, userid(actor), 't_ApprApplyList', 1)
        sefcustvar(11, userid(actor), 't_ApprApplyList', tbl2json(result))
        --设置自己的师徒关系
        defcustvar(11, userid(actor), 't_MasterAndApprt', 1)
        sefcustvar(11, userid(actor), 't_MasterAndApprt', tbl2json(myRelation))
        --设置徒弟的师徒关系
        defcustvar(11, targetData.UserID, 't_MasterAndApprt', 1)
        sefcustvar(11, targetData.UserID, 't_MasterAndApprt', tbl2json(targetRelation))

        --初始化徒弟任务进度
        MentorShip.setApprenticeTask(actor, targetData.UserID)
        MentorShip.GetMyRelation(actor, 'MentorShipMain')
        if data.fromPanel == 'MyShipApplyLists' then
        else
            MentorShip.GetApplyList(actor, 2)
        end
    end
    if data.fromPanel == 'MyShipApplyLists' then
        MentorShip.GetApplyList(actor, 3)
    elseif mode == 1 then
        MentorShip.GetApplyList(actor, 1)
    elseif mode == 2 then
        MentorShip.GetApplyList(actor, 2)
    end
end

--初始化进度
function MentorShip.setApprenticeTask(actor, userId)
    local taskProgressList = {}
    local gxdTask = {}
    for i = 1, #Master_and_apprentice do
        local ID = Master_and_apprentice[i].ID
        if Master_and_apprentice[i].type == 2 then
            taskProgressList['' .. ID] = {
                num = 0,
                status = 0
            }
        end
        if Master_and_apprentice[i].type == 3 then
            gxdTask['' .. ID] = {
                num = 0,
                status = 0
            }
        end
    end
    local today = year(actor) .. "年" .. month(actor) .. "月" .. day(actor) .. "日"
    taskProgressList['bondDate'] = today
    taskProgressList['finishTask'] = 0
    taskProgressList['bondDateTimes'] = math.floor(utcint64now() / 1000)
    taskProgressList['skillList'] = {}
    taskProgressList['progressLv'] = 5
    taskProgressList['progressPer'] = 0
    defcustvar(11, userId, 't_ApprenticeTaskPro', 1)
    sefcustvar(11, userId, 't_ApprenticeTaskPro', tbl2json(taskProgressList))
    defcustvar(11, userId, 't_ApprenticeGxdTask', 1)
    sefcustvar(11, userId, 't_ApprenticeGxdTask', tbl2json(gxdTask))
    MentorShip.GetMyRelation(userId, 'MentorShipMain', userId)
end

--更新新加的任务
function MentorShip.addNewTask(userId)
    local taskProgressList = getcustvar("11_" .. userId .. "_" .. "t_ApprenticeTaskPro")
    local gxdTask = getcustvar("11_" .. userId .. "_" .. "t_ApprenticeGxdTask")
    if taskProgressList and taskProgressList ~= "" then
        taskProgressList = json2tbl(taskProgressList)
    else
        taskProgressList = {}
    end
    if gxdTask and gxdTask ~= "" then
        gxdTask = json2tbl(gxdTask)
    else
        gxdTask = {}
    end
    for i = 1, #Master_and_apprentice do
        local ID = Master_and_apprentice[i].ID
        if taskProgressList['' .. ID] then
        else
            if Master_and_apprentice[i].type == 2 then
                taskProgressList['' .. ID] = {
                    num = 0,
                    status = 0
                }
            end
        end
        if gxdTask['' .. ID] then
        else
            if Master_and_apprentice[i].type == 3 then
                gxdTask['' .. ID] = {
                    num = 0,
                    status = 0
                }
            end
        end
    end
    defcustvar(11, userId, 't_ApprenticeTaskPro', 1)
    defcustvar(11, userId, 't_ApprenticeGxdTask', 1)
    sefcustvar(11, userId, 't_ApprenticeTaskPro', tbl2json(taskProgressList))
    sefcustvar(11, userId, 't_ApprenticeGxdTask', tbl2json(gxdTask))
end

--获取徒弟对应的数据
function MentorShip.getApprenticeInfo(actor, data)
    local myRelation = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
    if myRelation == "" then
        myRelation = {
            myMaster = nil,
            apprentice = {},
            applyRemoveMyMaster = nil,
            applyRemoveMyMasterById = nil,
            applyRemoveMyAppliction = {}
        }
    else
        myRelation = json2tbl(myRelation)
    end
    local newResult = {
        myUserId = userid(actor),
        myMaster = nil,
        apprentice = {},
        taskProgressList = {},
        applyRemoveMyMaster = nil,
        applyRemoveMyMasterById = nil,
        applyRemoveMyAppliction = {}
    }
    if myRelation.myMaster and myRelation.myMaster.UserID then
        myRelation.myMaster.IsOnline = checkstate(myRelation.myMaster.UserID, 2)
        newResult.myMaster = myRelation.myMaster
        newResult.applyRemoveMyMaster = myRelation.applyRemoveMyMaster
        newResult.applyRemoveMyMasterById = myRelation.applyRemoveMyMasterById
    end
    if #myRelation.apprentice > 0 then
        for i = 1, #myRelation.apprentice do
            local apprentice = myRelation.apprentice[i]
            apprentice.IsOnline = checkstate(apprentice.UserID, 2)
            if apprentice.IsOnline then
                --更新人物数据
                apprentice = MentorShip.updateData(apprentice.UserID)
                apprentice.IsOnline = true
            end
            table.insert(newResult.apprentice, apprentice)
        end
    end
    --我和徒弟的解除关系数据
    newResult.applyRemoveMyAppliction = myRelation.applyRemoveMyAppliction
    newResult.applyRemoveMyMaster = myRelation.applyRemoveMyMaster
    newResult.applyRemoveMyMasterById = myRelation.applyRemoveMyMasterById
    local taskProgressList = json2tbl(getcustvar("11_" .. data.UserID .. "_" .. "t_ApprenticeTaskPro"))
    newResult.taskProgressList = taskProgressList
    newResult.taskProgressList.UserID = data.UserID
    local gxdTask = json2tbl(getcustvar("11_" .. data.UserID .. "_" .. "t_ApprenticeGxdTask"))
    newResult.gxdTask = gxdTask
    Message.sendmsgEx(actor, data.fromPanel, "resetData", newResult)
end

--更新数据
function MentorShip.updateData(UserID)
    UserID = tonumber(UserID)
    local myRelation = json2tbl(getcustvar("11_" .. UserID .. "_" .. "t_MasterAndApprt"))
    local myInfo = {
        UserID = UserID,
        UserName = username(UserID),
        GuildName = targetinfo(UserID, "GUILDNAME"), --行会名字
        AvatarID = targetinfo(UserID, "AVATARID"),
        PhotoframeID = targetinfo(UserID, "PHOTOFRAMEID"),
        Job = job(UserID),
        Level = level(UserID),
        Sex = gender(UserID),
        zsLevel = targetinfo(UserID, 'RELEVEL'),
        goodEvilid = targetinfo(UserID, "GOODEVILID")
    }
    if myRelation.myMaster and myRelation.myMaster.UserID then
        --更新我师傅那边的数据
        local masterInfo = json2tbl(getcustvar("11_" .. myRelation.myMaster.UserID .. "_" .. "t_MasterAndApprt"))
        for i = 1, #masterInfo.apprentice do
            if tonumber(masterInfo.apprentice[i].UserID) == tonumber(UserID) then
                masterInfo.apprentice[i] = myInfo
            end
        end
        sefcustvar(11, myRelation.myMaster.UserID, 't_MasterAndApprt', tbl2json(masterInfo))
    end
    if #myRelation.apprentice > 0 then
        --更新我徒弟那边的数据
        for w = 1, #myRelation.apprentice do
            local apprenticeId = myRelation.apprentice[w].UserID
            local apprenticeInfo = json2tbl(getcustvar("11_" .. apprenticeId .. "_" .. "t_MasterAndApprt"))
            apprenticeInfo.myMaster = myInfo
            sefcustvar(11, apprenticeId, 't_MasterAndApprt', tbl2json(apprenticeInfo))
        end
    end
    return myInfo
end

--师徒关系
function MentorShip.GetMyRelation(actor, fromPanel, targetId)
    local myRelation = ""
    if targetId then
        myRelation = getcustvar("11_" .. targetId .. "_" .. "t_MasterAndApprt")
    else
        myRelation = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
    end

    if myRelation ~= "" then
        myRelation = json2tbl(myRelation)
    else
        myRelation = {
            myMaster = nil,
            apprentice = {},
            applyRemoveMyMaster = nil,
            applyRemoveMyMasterById = nil,
            applyRemoveMyAppliction = {}
        }
    end
    local newResult = {
        myUserId = userid(actor),
        myMaster = nil,
        apprentice = {},
        taskProgressList = {},
        applyRemoveMyMaster = nil,
        applyRemoveMyMasterById = nil,
        applyRemoveMyAppliction = {},
        chushiCount = 0,
    }

    --出师次数
    local queryUserId = targetId or userid(actor)
    local myChuShiCount = getcustvar("11_" .. queryUserId .. "_" .. "t_ChuShiCount")
    newResult.chushiCount = (myChuShiCount == "") and 0 or tonumber(myChuShiCount)

    local baseUserId = nil
    if myRelation.myMaster and myRelation.myMaster.UserID then
        myRelation.myMaster.IsOnline = checkstate(myRelation.myMaster.UserID, 2)
        if myRelation.myMaster.IsOnline then
            myRelation.myMaster = MentorShip.updateData(myRelation.myMaster.UserID)
            myRelation.myMaster.IsOnline = true
        end
        newResult.myMaster = myRelation.myMaster
        baseUserId = userid(actor)
    end
    if #myRelation.apprentice > 0 then
        for i = 1, #myRelation.apprentice do
            local apprentice = myRelation.apprentice[i]
            apprentice.IsOnline = checkstate(apprentice.UserID, 2)
            if apprentice.IsOnline then
                apprentice = MentorShip.updateData(apprentice.UserID)
                apprentice.IsOnline = true
            end
            table.insert(newResult.apprentice, apprentice)
        end
        if baseUserId then
        else
            baseUserId = myRelation.apprentice[1].UserID
        end
    end
    --我和徒弟的解除关系数据
    newResult.applyRemoveMyAppliction = myRelation.applyRemoveMyAppliction
    newResult.applyRemoveMyMaster = myRelation.applyRemoveMyMaster
    newResult.applyRemoveMyMasterById = myRelation.applyRemoveMyMasterById
    if baseUserId then
        --更新新增的任务
        MentorShip.addNewTask(baseUserId)
        local taskProgressList = json2tbl(getcustvar("11_" .. baseUserId .. "_" .. "t_ApprenticeTaskPro"))
        local gxdTask = json2tbl(getcustvar("11_" .. baseUserId .. "_" .. "t_ApprenticeGxdTask"))
        newResult.taskProgressList = taskProgressList
        newResult.taskProgressList.UserID = baseUserId
        newResult.gxdTask = gxdTask
    end
    Message.sendmsgEx(actor, fromPanel, "setData", newResult)
    if targetId then
        Message.sendmsgEx(targetId, fromPanel, "setData", newResult)
    end
end

function MentorShip.getMySkillList(actor)
    local skillList = getallskillid(actor)
    Message.sendmsgEx(actor, "MentorShipTeach", "setMySkillList", skillList)
end

function MentorShip.addSkillToApplication(actor, skillinfo)
    local UserID = skillinfo.UserId
    local selectIndex = skillinfo.setSkillIndex
    local taskProgressList = json2tbl(getcustvar("11_" .. UserID .. "_" .. "t_ApprenticeTaskPro"))
    local oldSkill = {}
    taskProgressList['skillList']['' .. selectIndex] = {
        skillId = skillinfo.SkillId,
        level = skillinfo.Level,
    }
    defcustvar(11, UserID, 't_ApprenticeTaskPro', 1)
    sefcustvar(11, UserID, 't_ApprenticeTaskPro', tbl2json(taskProgressList))
    --加新技能
    addskill(UserID, skillinfo.SkillId, skillinfo.Level)
    local data = {
        UserID = UserID,
        fromPanel = "MentorShipTeach"
    }
    MentorShip.getApprenticeInfo(actor, data)
end

function MentorShip.setApplicationSkill(actor, userId, skillInfo)
    --给徒弟加新技能
    --判断徒弟是否已经自己学习技能
    local isCan = getmagicinfo(actor, tonumber(skillInfo.skillId), 6) == 1 -- 获取角色技能是否已学习
    if isCan then
    else
        addskill(userId, skillInfo.skillId, skillInfo.level)
    end
end

function MentorShip.changeCheckBox(actor, data)
    sethumvar(actor, VarCfg.U_IsShowDialog, data)
end

function MentorShip.applyRemove(actor, data)
    --  data.UserID  目标对象id
    local myRelation = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt"))
    -- dump(myRelation)
    local masterUserId = nil
    local applictionUserId = nil
    local targetUserId = nil
    local sendWhich = 'showTimeOut'
    local masterId = nil
    if tonumber(data.type) == 1 then
        --解除我和我师傅的
        applictionUserId = userid(actor)
        masterUserId = myRelation.myMaster.UserID
        targetUserId = myRelation.myMaster.UserID
        masterId = myRelation.myMaster.UserID
        -- 目标解除关系列表
        local targetRelation = json2tbl(getcustvar("11_" .. targetUserId .. "_" .. "t_MasterAndApprt"))
        --如果已经在倒计时，直接解除
        if myRelation.applyRemoveMyMaster then
            sendWhich = 'refushAll'
            MentorShip.breakShip(masterId, applictionUserId)
        else
            myRelation.applyRemoveMyMaster = utcint64now() --记录时间 24小时解除
            myRelation.applyRemoveMyMasterById = userid(actor)
            --师傅那边的徒弟解除情况
            targetRelation.applyRemoveMyAppliction["" .. applictionUserId] = {
                date = utcint64now(),
                byUserId = userid(actor)
            }
            if checkstate(targetUserId, 2) then
                Message.sendmsgEx(targetUserId, "MentorShipMain", "addBubble")
            else
                --发邮件
                sendmail(targetUserId, 1, "解除师徒通知", "解除师徒通知")
            end
            sefcustvar(11, userid(actor), 't_MasterAndApprt', tbl2json(myRelation))
            sefcustvar(11, targetUserId, 't_MasterAndApprt', tbl2json(targetRelation))
        end
    else
        masterUserId = userid(actor)
        applictionUserId = data.UserID
        targetUserId = data.UserID
        masterId = userid(actor)
        local targetRelation = json2tbl(getcustvar("11_" .. targetUserId .. "_" .. "t_MasterAndApprt"))
        --解除我和徒弟的
        if myRelation.applyRemoveMyAppliction["" .. data.UserID] then
            sendWhich = 'refushAll'
            MentorShip.breakShip(masterId, applictionUserId)
        else
            myRelation.applyRemoveMyAppliction["" .. data.UserID] = {
                date = utcint64now(),
                byUserId = userid(actor)
            }
            --徒弟的师傅解除时间
            targetRelation.applyRemoveMyMaster = utcint64now() --记录时间 24小时解除
            targetRelation.applyRemoveMyMasterById = userid(actor)
            if checkstate(targetUserId, 2) then
                Message.sendmsgEx(targetUserId, "MentorShipMain", "addBubble")
            else
                --发邮件
                sendmail(targetUserId, 1, "解除师徒通知", "解除师徒通知")
            end
            sefcustvar(11, userid(actor), 't_MasterAndApprt', tbl2json(myRelation))
            sefcustvar(11, targetUserId, 't_MasterAndApprt', tbl2json(targetRelation))
        end
    end
    if sendWhich == 'showTimeOut' then
        Message.sendmsgEx(actor, "MentorShipMain", "showTimeOut", {
            masterUserId = masterUserId,
            applictionUserId = applictionUserId,
            date = utcint64now(),
            byUserId = userid(actor)
        })
        --1 我的师傅  0 我的徒弟
        MentorShip.todoAddBreak(actor, targetUserId, data.type)
        if data.type == 1 then
            addtimerex(actor, 201, 1000, 86400, "@ontimer201", "")
        else
            addtimerex(actor, 200, 1000, 86400, "@ontimer200", "")
        end
    end
end

function MentorShip.cancelApplyBreak(actor, data)
    --申请人取消了
    local myRelation = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt"))
    local masterUserId = nil
    local applictionUserId = nil
    local targetUserId = nil
    local sendWhich = 'showTimeOut'
    if data.type == 1 then
        --取消我和我师傅的
        applictionUserId = userid(actor)
        masterUserId = myRelation.myMaster.UserID
        targetUserId = myRelation.myMaster.UserID
        local targetRelation = json2tbl(getcustvar("11_" .. masterUserId .. "_" .. "t_MasterAndApprt"))
        myRelation.applyRemoveMyMaster = nil
        myRelation.applyRemoveMyMasterById = nil
        --师傅那边的徒弟解除情况
        targetRelation.applyRemoveMyAppliction["" .. applictionUserId] = nil
        sefcustvar(11, userid(actor), 't_MasterAndApprt', tbl2json(myRelation))
        sefcustvar(11, targetUserId, 't_MasterAndApprt', tbl2json(targetRelation))
    else
        masterUserId = userid(actor)
        applictionUserId = data.UserID
        targetUserId = data.UserID
        local targetRelation = json2tbl(getcustvar("11_" .. applictionUserId .. "_" .. "t_MasterAndApprt"))
        myRelation.applyRemoveMyAppliction["" .. data.UserID] = nil
        --徒弟的师傅解除时间
        targetRelation.applyRemoveMyMaster = nil
        targetRelation.applyRemoveMyMasterById = nil
        sefcustvar(11, userid(actor), 't_MasterAndApprt', tbl2json(myRelation))
        sefcustvar(11, targetUserId, 't_MasterAndApprt', tbl2json(targetRelation))
    end
    MentorShip.getApprenticeInfo(actor, { fromPanel = "MentorShipMain", UserID = applictionUserId })

    MentorShip.todoDelBreakApply(masterUserId, applictionUserId)
    MentorShip.todoDelBreakApply(applictionUserId, masterUserId)
end

function MentorShip.clearThisRelationship(actor, data)
    -- {masterUserId = data.masterUserId,applictionUserId = data.applictionUserId}
    local masterInfo = json2tbl(getcustvar("11_" .. data.masterUserId .. "_" .. "t_MasterAndApprt"))
    local applictionInfo = json2tbl(getcustvar("11_" .. data.applictionUserId .. "_" .. "t_MasterAndApprt"))
    --徒弟的师傅删除
    applictionInfo.myMaster = nil
    --师傅的徒弟删除
    local which = nil
    for i = 1, #masterInfo.apprentice do
        if data.applictionUserId == myRelation.apprentice[i] then
            table.remove(masterInfo.apprentice, i)
        end
    end
    sefcustvar(11, data.masterUserId, 't_MasterAndApprt', tbl2json(myRelation))
    sefcustvar(11, data.applictionUserId, 't_MasterAndApprt', tbl2json(targetRelation))
    Message.sendmsgEx(actor, "MentorShipMain", "resetDateView")
end

--定时器解除我和我的徒弟
function g_ontimer200(actor, obj, id)
    --24小时定时解除
    local myRelation = json2tbl(getcustvar("11_" .. userid(obj) .. "_" .. "t_MasterAndApprt"))
    local isNext = true
    for userId, v in pairs(myRelation.applyRemoveMyAppliction) do
        if v then
            local t = utcint64now() - v.date
            if t >= 86400 * 1000 then
                -- if t >= 60 * 1000 then --本地跑暂定60秒
                isNext = false
                MentorShip.breakShip(tonumber(userid(obj)), tonumber(userId))
            end
        else
            isNext = false
        end
    end
    if not isNext then
        disabletimer(obj, 200)
    end
end

--定时器解除我和我的师傅,只限制在点击按钮使用
function g_ontimer201(actor, obj, id)
    --24小时定时解除
    local myRelation = json2tbl(getcustvar("11_" .. userid(obj) .. "_" .. "t_MasterAndApprt"))
    local masterRelation = json2tbl(getcustvar("11_" .. myRelation.myMaster.UserID .. "_" .. "t_MasterAndApprt"))
    local isNext = true
    for userId, v in pairs(masterRelation.applyRemoveMyAppliction) do
        if masterRelation.applyRemoveMyAppliction["" .. userid(obj)] then
            local t = utcint64now() - v.date
            if t >= 86400 * 1000 then
                -- if t >= 60 * 1000 then --本地跑暂定60秒
                isNext = false
                MentorShip.breakShip(tonumber(myRelation.myMaster.UserID), userid(obj))
            end
        else
            isNext = false
        end
    end
    if not isNext then
        disabletimer(obj, 201)
    end
end

--师傅id 徒弟id
function MentorShip.breakShip(masterId, targetId, isSend)
    -- print("开始解除师徒关系",masterId,targetId)
    masterId = tonumber(masterId)
    targetId = tonumber(targetId)
    local myRelation = json2tbl(getcustvar("11_" .. masterId .. "_" .. "t_MasterAndApprt"))
    local targetRelation = json2tbl(getcustvar("11_" .. targetId .. "_" .. "t_MasterAndApprt"))
    local taskProgressList = json2tbl(getcustvar("11_" .. targetId .. "_" .. "t_ApprenticeTaskPro"))
    for w = 1, #myRelation['apprentice'] do
        -- dump(myRelation['apprentice'][w])
        -- print(#myRelation['apprentice'],"====================",myRelation['apprentice'][w])
        if myRelation['apprentice'][w] and tonumber(myRelation['apprentice'][w].UserID) == tonumber(targetId) then
            myRelation.applyRemoveMyAppliction["" .. targetId] = nil
            table.remove(myRelation['apprentice'], w)
            targetRelation.myMaster = nil
            targetRelation.applyRemoveMyMaster = nil
            targetRelation.applyRemoveMyMasterById = nil
            local masterGiveSkill = taskProgressList['skillList']
            for key, v in pairs(masterGiveSkill) do
                local ConditionId = SkillUpgrade[v.skillId][v.level].ConditionId
                if not condition(tonumber(targetId), ConditionId) then
                    delskill(tonumber(targetId), v.skillId)
                end
            end
        end
    end
    sefcustvar(11, tonumber(targetId), 't_ApprenticeTaskPro', nil)
    sefcustvar(11, tonumber(targetId), 't_MasterAndApprt', tbl2json(targetRelation))

    MentorShip.GetMyRelation(targetId, 'MentorShipMain')
    MentorShip.GetMyRelation(targetId, 'MentorShipTeach')

    sefcustvar(11, masterId, 't_MasterAndApprt', tbl2json(myRelation))

    MentorShip.GetMyRelation(masterId, 'MentorShipMain')
    MentorShip.GetMyRelation(masterId, 'MentorShipTeach')
    if not isSend then
        MentorShip.todoDelBreakApply(targetId, masterId)
        MentorShip.todoDelBreakApply(masterId, targetId)
    end
end

--徒弟领取任务奖励
function MentorShip.receive(actor, data)
    local task_reward = {}
    for i = 1, #Master_and_apprentice do
        if Master_and_apprentice[i].ID == data.taskId then
            task_reward = Master_and_apprentice[i].task_reward
        end
    end
    -- dump(task_reward)
    local itemJson = {}
    for i = 1, #task_reward do
        itemJson[task_reward[i][1]] = task_reward[i][2]
    end
    giveItmeByList(actor, itemJson)
    local taskProgressList = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "t_ApprenticeTaskPro"))
    taskProgressList['' .. data.taskId].status = 1
    taskProgressList.finishTask = taskProgressList.finishTask + 1
    sefcustvar(11, userid(actor), 't_ApprenticeTaskPro', tbl2json(taskProgressList))
    MentorShip.getApprenticeInfo(actor, { fromPanel = data.fromPanel, UserID = userid(actor) })
end

--徒弟转职次数任务
function MentorShip.changeRelevel(actor)
    local zsLevel = targetinfo(actor, 'RELEVEL')
    MentorShipChangTask(actor, 2, "*", zsLevel)
end

-- 服务端安全校验：判断是否满足出师条件
function MentorShip.CheckChuShiCondition(taskProgressList)
    local isCan = true
    for i = 1, #Master_and_apprentice do
        local task = Master_and_apprentice[i]
        if task.type == 1 then
            if task.task_target == 3 then
                local currentTime = math.floor(utcint64now() / 1000)
                local bondTime = taskProgressList.bondDateTimes or 0
                local days = math.floor((currentTime - bondTime) / 86400)
                if days < task.task_target_num then
                    isCan = false
                    break
                end
            end

            if task.task_target == 5 then
                local finishTask = taskProgressList.finishTask or 0
                if finishTask < task.task_target_num then
                    isCan = false
                    break
                end
            end
        end
    end
    return isCan
end

function MentorShip.chushi(actor, data)
    -- dump(data)
    --徒弟出师
    local apparenceId = tonumber(data.UserID)
    --校验
    local taskProgressStr = getcustvar("11_" .. apparenceId .. "_" .. "t_ApprenticeTaskPro")
    if taskProgressStr == "" then
        sendmsg(actor, 9, "[color=#ff0000]徒弟数据异常，无法出师[/color]")
        return
    end
    local taskProgressList = json2tbl(taskProgressStr)
    if not MentorShip.CheckChuShiCondition(taskProgressList) then
        sendmsg(actor, 9, "[color=#ff0000]出师条件未满足，非法请求！[/color]")
        return
    end

    local apparenceIdRelation = json2tbl(getcustvar("11_" .. apparenceId .. "_" .. "t_MasterAndApprt"))
    local masterId = apparenceIdRelation.myMaster.UserID
    apparenceIdRelation.myMaster = nil
    apparenceIdRelation.applyRemoveMyMaster = nil
    apparenceIdRelation.applyRemoveMyMasterById = nil
    --徒弟的师傅的关系
    local masterRelation = json2tbl(getcustvar("11_" .. masterId .. "_" .. "t_MasterAndApprt"))
    masterRelation.applyRemoveMyAppliction["" .. apparenceId] = nil
    -- dump(masterRelation)
    local which = 0
    for i = 1, #masterRelation.apprentice do
        if tonumber(masterRelation.apprentice[i].UserID) == apparenceId then
            which = i
        end
    end
    table.remove(masterRelation.apprentice, which)
    if (masterRelation.myMaster and masterRelation.myMaster.UserId) or #masterRelation.apprentice > 0 then
        --有师傅或者徒弟
        sefcustvar(11, masterId, 't_MasterAndApprt', tbl2json(masterRelation))
    else
        sefcustvar(11, masterId, 't_MasterAndApprt', nil)
    end

    if #apparenceIdRelation.apprentice > 0 then
        --还有徒弟
        sefcustvar(11, apparenceId, 't_MasterAndApprt', tbl2json(apparenceIdRelation))
    else
        sefcustvar(11, apparenceId, 't_MasterAndApprt', nil)
    end
    sendmail(apparenceId, 1, "师徒系统", "恭喜你出师了", MasterApprenticeShip["master_award"].VALUE .. "#1#3", 86400)
    sendmail(masterId, 1, "师徒系统", "恭喜你的徒弟出师了", MasterApprenticeShip["apparenice_award"].VALUE .. "#1#3", 86400)

    --出师次数
    local myChuShiCount = getcustvar("11_" .. apparenceId .. "_" .. "t_ChuShiCount")
    myChuShiCount = (myChuShiCount == "") and 0 or tonumber(myChuShiCount)
    myChuShiCount = myChuShiCount + 1

    defcustvar(11, apparenceId, 't_ChuShiCount', 1)
    sefcustvar(11, apparenceId, 't_ChuShiCount', myChuShiCount)

    local taskProgressList = json2tbl(getcustvar("11_" .. apparenceId .. "_" .. "t_ApprenticeTaskPro"))
    --删掉剩下师傅给过的技能
    local masterGiveSkill = taskProgressList['skillList']
    for _, v in pairs(taskProgressList['skillList']) do
        local ConditionId = SkillUpgrade[v.skillId][v.level].ConditionId
        if condition(apparenceId, ConditionId) then
            --符合的在升级的时候已经删过了
        else
            --删除不符合学习的师傅给的技能
            delskill(apparenceId, v.skillId)
        end
    end
    taskProgressList['skillList'] = {}
    --清除徒弟数据
    sefcustvar(11, apparenceId, 't_ApprenticeTaskPro', nil)
    sefcustvar(11, apparenceId, 't_ApprenticeGxdTask', nil)

    MentorShip.GetMyRelation(actor, "MentorShipMain")
end

function MentorShip.finishGxdTask(actor, data)
    local myGxdTask = json2tbl(getcustvar("11_" .. data.UserID .. "_" .. "t_ApprenticeGxdTask"))
    local taskProgressList = json2tbl(getcustvar("11_" .. data.UserID .. "_" .. "t_ApprenticeTaskPro"))
    myGxdTask['' .. data.taskID].status = 1
    local task_reward = {}
    local gxd = taskProgressList['progressPer']
    for i = 1, #Master_and_apprentice do
        if Master_and_apprentice[i].ID == data.taskID then
            task_reward = Master_and_apprentice[i].task_reward
            gxd = Master_and_apprentice[i].gxd_progress + gxd
        end
    end
    local itemJson = {}
    for i = 1, #task_reward do
        itemJson[task_reward[i][1]] = task_reward[i][2]
    end
    local js = math.floor(gxd / 100)
    taskProgressList['progressLv'] = taskProgressList['progressLv'] - js
    if taskProgressList['progressLv'] < 1 then
        taskProgressList['progressLv'] = 1
        taskProgressList['progressPer'] = 100
    else
        taskProgressList['progressPer'] = gxd - 100 * js
    end
    if taskProgressList['progressLv'] == 5 then
        sethumvar(actor, VarCfg.T_Skilll_BL, 40)
    end
    if taskProgressList['progressLv'] == 4 then
        sethumvar(actor, VarCfg.T_Skilll_BL, 50)
    end
    if taskProgressList['progressLv'] == 3 then
        sethumvar(actor, VarCfg.T_Skilll_BL, 60)
    end
    if taskProgressList['progressLv'] == 2 then
        sethumvar(actor, VarCfg.T_Skilll_BL, 60)
    end
    if taskProgressList['progressLv'] == 1 then
        sethumvar(actor, VarCfg.T_Skilll_BL, 70)
    end
    giveItmeByList(actor, itemJson)
    sefcustvar(11, data.UserID, 't_ApprenticeGxdTask', tbl2json(myGxdTask))

    sefcustvar(11, data.UserID, 't_ApprenticeTaskPro', tbl2json(taskProgressList))

    MentorShip.getApprenticeInfo(actor, { fromPanel = 'MentorShipTeach', UserID = data.UserID })
end

--徒弟上线，增加师傅给的技能
function MentorShip.addApparenticeSkill(actor)
    local myApparenticeInfo = getcustvar("11_" .. userid(actor) .. "_" .. "t_ApprenticeTaskPro")
    if myApparenticeInfo then
        myApparenticeInfo = json2tbl(myApparenticeInfo)
        local skillList = myApparenticeInfo['skillList']
        for _, skillinfo in pairs(skillList) do
            local ConditionId = SkillUpgrade[skillinfo.skillId][skillinfo.level].ConditionId
            if condition(actor, ConditionId) then
            else
                if getmagicinfo(actor, skillinfo.skillId, 6) == 0 then
                    addskill(actor, skillinfo.skillId, skillinfo.level)
                end
            end
        end
    end
end

--徒弟升级 师傅获得经验
function MentorShip.appareniceLevelUp(actor, lv)
    local myRelation = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
    if myRelation ~= "" then
        myRelation = json2tbl(myRelation)
        if myRelation.myMaster and myRelation.myMaster.UserID then
            local masterUserId = myRelation.myMaster.UserID
            local myMasterData = getcustvar("11_" .. masterUserId .. "_" .. "t_MyApprenticeLevelUp")
            -- dump(myMasterData)
            if myMasterData ~= "" then
                myMasterData = json2tbl(myMasterData)
            else
                myMasterData = {}
            end
            -- dump(myMasterData)
            table.insert(myMasterData, lv)
            sefcustvar(11, masterUserId, 't_MyApprenticeLevelUp', tbl2json(myMasterData))
            local taskProgressList = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "t_ApprenticeTaskPro"))
            local masterGiveSkill = taskProgressList['skillList']
            for key, v in pairs(masterGiveSkill) do
                local ConditionId = SkillUpgrade[v.skillId][v.level].ConditionId
                if condition(actor, ConditionId) then
                    delskill(actor, v.skillId)
                end
            end
        end
    end
end

function MentorShip.addExpByData(actor)
    local myMasterData = getcustvar("11_" .. userid(actor) .. "_" .. "t_MyApprenticeLevelUp")
    if myMasterData == '' then
        myMasterData = {}
    else
        myMasterData = json2tbl(myMasterData)
    end
    local myLv = level(actor)
    for i = 1, #myMasterData do
        local difflv = myLv - myMasterData[i]
        local Exp = needLevel[myMasterData[i]].Exp * 0.01
        local giveExp = 0
        if 20 < difflv and difflv <= 30 then
            giveExp = Exp * 1
        end
        if 30 < difflv and difflv <= 40 then
            giveExp = Exp * 0.5
        end
        if 40 < difflv and difflv <= 50 then
            giveExp = Exp * 0.25
        end
        if 50 < difflv and difflv <= 60 then
            giveExp = Exp * 0.125
        end
        if 60 < difflv and difflv <= 70 then
            giveExp = Exp * 0.0625
        end
        if 70 < difflv then
            giveExp = Exp * 0.03125
        end
        changeexp(actor, "+", math.floor(giveExp))
    end
    if #myMasterData > 0 then
        sefcustvar(11, userid(actor), 't_MyApprenticeLevelUp', 1)
        defcustvar(11, userid(actor), 't_MyApprenticeLevelUp', nil)
        sendmsg(actor, 9, "获得徒弟升级馈赠经验奖励")
    end
end

function MentorShip.ChangeGoodevil(actor)
    local myRelation = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
    local myGoodevil = targetinfo(actor, "GOODEVILID")
    if myRelation == "" then
    else
        myRelation = json2tbl(myRelation)
        if myRelation.myMaster and myRelation.myMaster.UserId then
            local masterUserId = myRelation.myMaster.UserId
            local myMasterEvil = myRelation.myMaster.GOODEVILID
            local masterRelation = json2tbl(getcustvar("11_" .. masterUserId .. "_" .. "t_MasterAndApprt"))
            --阵营不一致，清除师徒关系
            if myMasterEvil ~= myGoodevil then
                myRelation.myMaster = nil
                myRelation.applyRemoveMyMaster = nil
                myRelation.applyRemoveMyMasterById = nil
                masterRelation.applyRemoveMyAppliction["" .. userid(actor)] = nil
                local which = 0
                for i = 1, #masterRelation.apprentice do
                    if masterRelation.apprentice[i].UserId == userid(actor) then
                        which = i
                    end
                end
                table.remove(masterRelation.apprentice, which)
                sefcustvar(11, masterUserId, 't_MasterAndApprt', 1)
                defcustvar(11, masterUserId, 't_MasterAndApprt', tbl2json(masterRelation))
                --徒弟删掉师傅给的技能
                local taskProgressList = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "t_ApprenticeTaskPro"))
                for _, v in pairs(taskProgressList['skillList']) do
                    delskill(actor, v.skillId)
                end
                taskProgressList['skillList'] = {}
                sefcustvar(11, userid(actor), 't_MasterAndApprt', 1)
                defcustvar(11, userid(actor), 't_MasterAndApprt', tbl2json(taskProgressList))
            end
        end
    end
end

function MentorShip.toInvitation(actor, data)
    for i = 1, #data.dataList do
        local user = data.dataList[i]
        sethumvar(user.UserID, VarCfg.U_fuben_start, utcint64now())
        data.myUserId = user.UserID
        data.dsqsj = utcint64now()
        Message.sendmsgEx(user.UserID, "Invitation", "setView", data)
    end
end

function MentorShip.agreeJoin(actor, data)
    local newData = data
    for i = 1, #data do
        if tonumber(data[i].UserID) == tonumber(userid(actor)) then
            newData[i].isAgreeStatus = 1
        end
    end
    for i = 1, #newData do
        Message.sendmsgEx(tonumber(newData[i].UserID), "Invitation", "resetView", newData)
    end
end

function MentorShip.notAgreeJoin(actor, data)
    local newData = data
    local num = 0
    for i = 1, #data do
        if tonumber(data[i].UserID) == tonumber(userid(actor)) then
            newData[i].isAgreeStatus = 2
        end
        if tonumber(newData[i].isAgreeStatus) == 2 then
            num = num + 1
        end
    end
    if num == #newData - 1 then
        for i = 1, #newData do
            Message.sendmsgEx(tonumber(newData[i].UserID), "Invitation", "cloaseInvitation")
        end
        return
    end
    for i = 1, #newData do
        Message.sendmsgEx(tonumber(newData[i].UserID), "Invitation", "resetView", newData)
    end
end

function MentorShip.closeAllInvitation(actor, data)
    for i = 1, #data do
        Message.sendmsgEx(tonumber(newData[i].data), "Invitation", "cloaseInvitation")
    end
end

function MentorShip.getMinAppraLv(userList)
    local minLV = 999
    for i = 1, #userList do
        if level(userList[i].UserID) <= minLV then
            minLV = level(userList[i].UserID)
        end
    end
    return minLV
end

function MentorShip.mapMoveAll(actor, data)
    --师徒副本校验
    for i = 1, #data.users do
        local checkUserId = tonumber(data.users[i].UserID)
        if not checkstate(checkUserId, 2) then
            sendmsg(actor, 9, "[color=#ff0000]玩家[" .. (data.users[i].UserName or "未知") .. "]已离线，副本开启失败！[/color]")
            --防止死锁
            Message.sendmsgEx(actor, "Invitation", "cloaseInvitation")
            return
        end

        local fubenInfo = MentorShip.getMyfubenInfo(checkUserId)
        if fubenInfo ~= 0 then
            local currentMapId = targetinfo(checkUserId, "NEWMAP")
            if tostring(currentMapId) == tostring(fubenInfo.mapID) then
                sendmsg(actor, 9, "[color=#ff0000]玩家[" .. (data.users[i].UserName or "未知") .. "]已在副本中，无法重复进入！[/color]")
                --防止死锁
                Message.sendmsgEx(actor, "Invitation", "cloaseInvitation")
                return
            end
        end
    end

    local newMapId = math.random(1, 100)
    local userList = {}
    for i = 1, #data.users do
        newMapId = newMapId .. data.users[i].UserID
        table.insert(userList, data.users[i].UserID)
    end
    local monidx = 0
    local bossidx = 0
    local minLV = MentorShip.getMinAppraLv(data.users)
    for i = 1, #mentorShipMon do
        if minLV >= mentorShipMon[i].apprenticeLv then
            monidx = mentorShipMon[i].monidx
            bossidx = mentorShipMon[i].bossidx
        end
    end
    local StopTime = 600 + math.floor(utcint64now() / 1000) --秒
    local newObj = {
        mapID = newMapId,
        userList = userList,
        monidx = monidx,
        bossidx = bossidx,
        masterid = userid(actor),
        taskType = tonumber(data.taskType),
        StopTime = StopTime
    }
    local MyMentorShip_fuben = gethumvar(actor, VarCfg.T_MyMentorShip_fuben)
    if MyMentorShip_fuben == "" then
        MyMentorShip_fuben = {
            [1] = {}, --已经参加的杀怪副本徒弟ids
            [2] = {}  --已经参加的杀BOSS副本徒弟ids
        }
    else
        MyMentorShip_fuben = json2tbl(MyMentorShip_fuben)
    end
    MentorShip.CreatFuBenMap(216, newMapId, monidx)
    exitgroup(actor)
    creategroup(actor)
    local GROUPID = targetinfo(actor, "GROUPID")
    defcustvar(12, newMapId, "killnum", 1)
    sefcustvar(12, newMapId, "killnum", 0)
    defcustvar(12, newMapId, "groupID", 1)
    sefcustvar(12, newMapId, "groupID", GROUPID)
    for i = 1, #data.users do
        local UserID = tonumber(data.users[i].UserID)
        --记录徒弟已经进入副本次数
        if tonumber(UserID) == tonumber(userid(actor)) then
        else
            exitgroup(UserID)
            joingroup(UserID, userid(actor), 1)
            if tonumber(data.taskType) == 1 then
                --杀怪数量副本
                MyMentorShip_fuben[1][#MyMentorShip_fuben[1] + 1] = UserID
            else
                --BOSS副本
                MyMentorShip_fuben[2][#MyMentorShip_fuben[2] + 1] = UserID
            end
        end
        defcustvar(12, UserID, "mentorShipFuben", 1)
        sefcustvar(12, UserID, "mentorShipFuben", tbl2json(newObj))
        sethumvar(UserID, VarCfg.S_FuBen_Var_PlayerPosition,
            tbl2json({ targetinfo(actor, "NEWMAP"), targetinfo(actor, "X"), targetinfo(actor, "Y") })) -- 记录进入前位置信息
        mapmove(UserID, newMapId, 36, 37, 2)                                                           -- 传送进副本
        Message.sendmsgEx(UserID, "Invitation", "moveResult")
        Message.sendmsgEx(UserID, "MainMission", "EnterFuben",
            { isEnter = true, info = { killnum = 0, killtype = data.taskType, StopTime = StopTime } })
    end
    local monname = moninfo(monidx .. "_NAME") or ""
    local bossname = moninfo(bossidx .. "_NAME") or ""
    mongenex(newMapId, 73, 37, 15, monname, 20, -1, 0)   -- 刷怪
    mongenex(newMapId, 150, 37, 15, monname, 20, -1, 0)  -- 刷怪
    mongenex(newMapId, 73, 76, 15, monname, 20, -1, 0)   -- 刷怪
    mongenex(newMapId, 150, 76, 15, monname, 20, -1, 0)  -- 刷怪
    mongenex(newMapId, 73, 115, 15, monname, 20, -1, 0)  -- 刷怪
    mongenex(newMapId, 111, 115, 15, monname, 20, -1, 0) -- 刷怪
    if tonumber(data.taskType) == 1 then
        --杀怪数量副本
        mongenex(newMapId, 150, 115, 15, monname, 20, -1, 0) -- 刷怪
    else
        --BOSS副本
        mongenex(newMapId, 150, 115, 3, bossname, 1, -1, 0) -- 刷怪
    end

    sethumvar(actor, VarCfg.T_MyMentorShip_fuben, tbl2json(MyMentorShip_fuben))
end

function MentorShip.CreatFuBenMap(mapid, newMapId, monidx)
    if checkmirrormap(newMapId) then
        delmirrormap(newMapId) -- 销毁之前创建的副本地图
    end
    local monname = moninfo(monidx .. "_NAME") or ""
    if not addmirrormap(mapid, newMapId, monname .. "副本", 600, "101", 1, 209, 280) then
        sendmsg(actor, 9, "创建失败！重新创建")
        return
    end
end

function MentorShip.timeOutEnd(actor, data)
    if tonumber(data.num) == #data.users - 1 then
        MentorShip.mapMoveAll(actor, data.users)
        return
    end
    for i = 1, #data.users do
        Message.sendmsgEx(tonumber(data.users[i].UserID), "Invitation", "timeEnd")
    end
end

function MentorShip.todoDelBreakApply(myUserID, targetId)
    myUserID = tonumber(myUserID)
    targetId = tonumber(targetId)
    local targetBreakApplyList = getcustvar("11_" .. targetId .. "_" .. "T_MyMentorShip_Break")
    if targetBreakApplyList and targetBreakApplyList ~= "" then
        targetBreakApplyList = json2tbl(targetBreakApplyList)
    else
        targetBreakApplyList = {}
    end
    --删除关系
    for i = 1, #targetBreakApplyList do
        if tonumber(targetBreakApplyList[i].UserID) == tonumber(myUserID) then
            table.remove(targetBreakApplyList, i)
            break
        end
    end
    sefcustvar(11, targetId, 'T_MyMentorShip_Break', tbl2json(targetBreakApplyList))
end

-- which 1 我的师傅  0 我的徒弟
function MentorShip.todoAddBreak(actor, targetId, which)
    targetId = tonumber(targetId)
    local targetBreakApplyList = getcustvar("11_" .. targetId .. "_" .. "T_MyMentorShip_Break")
    if targetBreakApplyList and targetBreakApplyList ~= "" then
        targetBreakApplyList = json2tbl(targetBreakApplyList)
    else
        targetBreakApplyList = {}
    end
    --增加关系
    local myInfo = {
        --0我是师傅 1我是徒弟
        who = tonumber(which),
        UserID = userid(actor),
        UserName = username(actor)
    }
    targetBreakApplyList[#targetBreakApplyList + 1] = myInfo
    defcustvar(11, targetId, 'T_MyMentorShip_Break', 1)
    sefcustvar(11, targetId, 'T_MyMentorShip_Break', tbl2json(targetBreakApplyList))
end

function MentorShip.getAllMyBraskApply(actor)
    local myBreakApplyList = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "T_MyMentorShip_Break"))
    Message.sendmsgEx(actor, "MentorShipPanel", "initBreakEvent", myBreakApplyList)
end

function MentorShip.notAgreeBreak(actor, targetId)
    local myBreakApplyList = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "T_MyMentorShip_Break"))
    local index = 0
    for i = 1, #myBreakApplyList do
        if tonumber(myBreakApplyList[i].UserID) == tonumber(targetId) then
            index = i
        end
    end
    if index > 0 then
        table.remove(myBreakApplyList, index)
    end
    sefcustvar(11, targetId, 'T_MyMentorShip_Break', tbl2json(myBreakApplyList))
    Message.sendmsgEx(actor, "MentorShipPanel", "initBreakEvent", myBreakApplyList)
end

function MentorShip.getMyfubenInfo(actor)
    local mentorShipFuben = getcustvar("12_" .. userid(actor) .. "_" .. "mentorShipFuben")
    if mentorShipFuben == "" then
        return 0
    else
        return json2tbl(mentorShipFuben)
    end
end

-- 离开副本地图，是否需要销毁副本
function MentorShip.LeaveFuBenMap(actor)
    local mentorShipFuben = MentorShip.getMyfubenInfo(actor)
    if mentorShipFuben ~= 0 and checkmirrormap(mentorShipFuben.mapID) then
        -- print("下线后副本里还有",getmap(mentorShipFuben.mapID, "*" , "*" , "*", 1, "*"))
        if getmap(mentorShipFuben.mapID, "*", "*", "*", 1, "*") == 0 then
            MentorShip.clearEveryOne(actor)
            delmirrormap(mentorShipFuben.mapID) -- 销毁之前创建的副本地图
        end
    end
end

function MentorShip.finishFuben(actor)
    MentorShip.clearEveryOne(actor)
    local mentorShipFuben = MentorShip.getMyfubenInfo(actor)
    for i = 1, #mentorShipFuben.userList do
        mapmove(mentorShipFuben.userList[i], "101", 209, 280, 1)
    end
    sefcustvar(12, newMapId, "killnum", nil)
end

function MentorShip.clearEveryOne(actor)
    local mentorShipFuben = MentorShip.getMyfubenInfo(actor)
    if mentorShipFuben ~= 0 then
        local userList = mentorShipFuben.userList
        for i = 1, #userList do
            sefcustvar(12, userList[i], "mentorShipFuben", nil)
        end
    end
end

function MentorShip.goOutFuben(actor)
    MentorShip.LeaveFuBenMap(actor)
    sefcustvar(12, userid(actor), "mentorShipFuben", nil)
    mapmove(actor, "101", 209, 280, 1)
end

--mode 2 我的师傅 1 我的徒弟
function MentorShip.agreeBreak(actor, data)
    local targetId = tonumber(data.targetId)
    local mode = tonumber(data.mode)
    disabletimer(actor, 200)
    disabletimer(targetId, 201)
    local masterId = nil
    local appareniceId = nil
    local myRelation = json2tbl(getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt"))
    if mode == 2 then
        masterId = myRelation.myMaster.UserID
        appareniceId = userid(actor)
    else
        masterId = userid(actor)
        appareniceId = targetId
    end
    --解除师徒关系
    MentorShip.todoDelBreakApply(appareniceId, masterId)
    MentorShip.todoDelBreakApply(masterId, appareniceId)

    MentorShip.breakShip(masterId, appareniceId, true)
    -- local myBreakApplyList = json2tbl(getcustvar("11_"..userid(actor).."_".."T_MyMentorShip_Break"))
    Message.sendmsgEx(actor, "MentorShipPanel", "applyResult")
end

function MentorShip.addKillNum(actor, monidx)
    local mentorShipFuben = MentorShip.getMyfubenInfo(actor)
    if mentorShipFuben ~= 0 then
        local userList = mentorShipFuben.userList
        local killnum = getcustvar("12_" .. mentorShipFuben.mapID .. "_" .. "killnum")
        killnum = tonumber(killnum) + 1
        sefcustvar(12, mentorShipFuben.mapID, "killnum", killnum)
        for i = 1, #userList do
            if tonumber(userList[i]) ~= tonumber(mentorShipFuben.masterid)
                and checkstate(tonumber(userList[i]), 2)
                and tonumber(targetinfo(tonumber(userList[i]), "NEWMAP")) == tonumber(mentorShipFuben.mapID) then
                if tonumber(mentorShipFuben.taskType) == 1 then
                    MentorShipChangTask(userList[i], 10, 1)
                else
                    if tonumber(mentorShipFuben.bossidx) == tonumber(monidx) then
                        MentorShipChangTask(userList[i], 10, 2)
                    end
                end
            end
            Message.sendmsgEx(userList[i], "MainMission", "ShowMentorShipInfo",
                { killnum = killnum, killtype = mentorShipFuben.taskType })
        end
    end
end

--count  ID
function MentorShip.buy(actor, postData)
    local myShowBuyTime = gethumvar(actor, VarCfg.T_MentorShipShopBuyTime)
    if myShowBuyTime == "" then
        myShowBuyTime = {}
    else
        myShowBuyTime = json2tbl(myShowBuyTime)
    end
    if StoreData[tonumber(postData.ID)] then
        local data = StoreData[tonumber(postData.ID)]
        local num = money(actor, 21)
        if MentorShip.isCanBuy(actor, postData.count, data.Itemid, postData.ID) then
            local total = tonumber(postData.count) * tonumber(data.Nowprice)
            if num < total then
                return sendmsg(actor, 9, "师徒币不足")
            end
            delItemNum(actor, 21, total)
            local itemJson = {}
            itemJson[tonumber(data.Itemid)] = tonumber(postData.count)
            giveItmeByList(actor, itemJson)
            sendmsg(actor, 9, "购买成功")
            if myShowBuyTime["" .. data.Itemid] then
                myShowBuyTime["" .. data.Itemid] = tonumber(myShowBuyTime["" .. data.Itemid]) + tonumber(postData.count)
            else
                myShowBuyTime["" .. data.Itemid] = tonumber(postData.count)
            end
            sethumvar(actor, VarCfg.T_MentorShipShopBuyTime, tbl2json(myShowBuyTime))
            Message.sendmsgEx(actor, "MentorShipShop", "updateView")
        end
    else
        sendmsg(actor, 9, "道具不存在")
    end
end

function MentorShip.isCanBuy(actor, count, ItemID, excelID)
    local myShowBuyTime = gethumvar(actor, VarCfg.T_MentorShipShopBuyTime)
    if myShowBuyTime == "" then
        myShowBuyTime = {}
    else
        myShowBuyTime = json2tbl(myShowBuyTime)
    end
    local itemInfo = StoreData[tonumber(excelID)]
    local isCanBuy = true
    if itemInfo.Limitbuy and myShowBuyTime["" .. ItemID] then
        local Limitbuy = string.split(itemInfo.Limitbuy, "#")
        if myShowBuyTime["" .. ItemID] >= tonumber(Limitbuy[2]) then
            isCanBuy = false
            sendmsg(actor, 9, "超出可购买最大数量")
        else
            if myShowBuyTime["" .. ItemID] + tonumber(count) > tonumber(Limitbuy[2]) then
                isCanBuy = false
                sendmsg(actor, 9, "超出可购买最大数量")
            end
        end
    end
    return isCanBuy
end

GameEvent.add(EventCfg.onPlayLevelUp, function(actor, lv, oldlv)
    MentorShip.appareniceLevelUp(actor, oldlv)
end, MentorShip)

-- 退出游戏事件，离开副本地图
GameEvent.add(EventCfg.onExitGame, function(actor)
    MentorShip.LeaveFuBenMap(actor)
end, MentorShip)

GameEvent.add(EventCfg.onLogin, function(actor)
    --上线了
    --是否拥有副本id
    local mentorShipFuben = MentorShip.getMyfubenInfo(actor)
    if mentorShipFuben ~= 0 then
        local mapid = mentorShipFuben.mapID
        if mapid and checkmirrormap(mapid) then
            --传进副本
            exitgroup(actor)
            mapmove(actor, mapid, 36, 37, 2) -- 传送进副本
            local killnum = getcustvar("12_" .. mapid .. "_" .. "killnum")
            Message.sendmsgEx(actor, "MainMission", "EnterFuben",
                { isEnter = true, info = { killnum = killnum, killtype = mentorShipFuben.taskType, StopTime = mentorShipFuben.StopTime } })
            -- dump(mapUserList)
            local groupID = getcustvar("12_" .. mapid .. "_" .. "groupID")
            local dzID = groupinfo(groupID .. "_1")
            joingroup(actor, dzID, 1)
        end
    end
end, MentorShip)
--离开队伍触发
GameEvent.add(EventCfg.onLeaveGroup, function(actor)
    local mentorShipFuben = MentorShip.getMyfubenInfo(actor)
    if mentorShipFuben ~= 0 then
        local mapid = mentorShipFuben.mapID
        if mapid then
            Message.sendmsgEx(actor, "MainMission", "EnterFuben", { isEnter = false, info = {} })
            sefcustvar(12, userid(actor), "mentorShipFuben", nil)
            mapmove(actor, "101", 209, 280, 1)
        end
    end
end, MentorShip)

--每次登录 是否有师徒解除申请
GameEvent.add(EventCfg.onLogin, function(actor)
    local targetRelation = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
    if targetRelation == "" then
    else
        targetRelation = json2tbl(targetRelation)
        local isHaveApply = false
        for UserID, v in pairs(targetRelation.applyRemoveMyAppliction) do
            if UserID and v then
                isHaveApply = true
            end
        end
        if isHaveApply then
            --我和我的徒弟有解除申请
            addtimerex(actor, 201, 1000, 86400, "@ontimer201", "")
        end
        if targetRelation.applyRemoveMyMasterById and targetRelation.applyRemoveMyMaster then
            --我和师傅的解除申请
            addtimerex(actor, 200, 1000, 86400, "@ontimer200", "")
        end
    end
end, MentorShip)

-- 怪物死亡触发，计算击杀数量
GameEvent.add(EventCfg.onKillMon, function(actor, mon, mapid, monidx)
    local mentorShipFuben = MentorShip.getMyfubenInfo(actor)
    if mentorShipFuben ~= 0 then
        if mapid == mentorShipFuben.mapID then
            MentorShip.addKillNum(actor, monidx)
        end
    end
end, MentorShip)

-- 跨天登录触发，重置副本挑战次数
GameEvent.add(EventCfg.onResetday, function(actor)
    sethumvar(actor, VarCfg.T_MyMentorShip_fuben, "")
    --每日任务重置
    local gxdTask = {}
    for i = 1, #Master_and_apprentice do
        local ID = Master_and_apprentice[i].ID
        if Master_and_apprentice[i].type == 3 then
            gxdTask['' .. ID] = {
                num = 0,
                status = 0
            }
        end
    end
    sefcustvar(11, userid(actor), 't_ApprenticeGxdTask', tbl2json(gxdTask))
    local myShowBuyTime = gethumvar(actor, VarCfg.T_MentorShipShopBuyTime)
    if myShowBuyTime == "" then
        myShowBuyTime = {}
    else
        myShowBuyTime = json2tbl(myShowBuyTime)
    end
    for i = 1, #StoreData do
        if StoreData[i].BtLeafType == 69 and StoreData[i].Limitbuy then
            --师徒商店
            local which = tonumber(string.split(Limitbuy, "#")[1])
            local ItemID = StoreData[i].Itemid
            --每日限购
            if which == 1 then
                if myShowBuyTime["" .. ItemID] then
                    myShowBuyTime["" .. ItemID] = 0
                end
            end
            --每周限购
            if which == 2 then
                -- 0-6  周日-周六
                local weekday_num = tonumber(os.date("%w"))
                if weekday_num == 1 then
                    if myShowBuyTime["" .. ItemID] then
                        myShowBuyTime["" .. ItemID] = 0
                    end
                end
            end
            --永远限购
            if which == 3 then
            end
            --每月限购
            if which == 4 then
                if day(actor) == 1 then
                    if myShowBuyTime["" .. ItemID] then
                        myShowBuyTime["" .. ItemID] = 0
                    end
                end
            end
        end
    end
    sethumvar(actor, VarCfg.T_MentorShipShopBuyTime, tbl2json(myShowBuyTime))
end, MentorShip)

Message.RegisterNetMsg(ssrNetMsgCfg.MentorShip, MentorShip)
return MentorShip
