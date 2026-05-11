MentorShipTask = {}
local filname = "MentorShipTask"

-- 添加好友数
function MentorShipTask.onAddFriend(actor)
    if MentorShipTask.isHasMasterOrApparenice(actor) then
        MentorShipChangTask(actor, 5, 4)
    end
end

function MentorShipTask.onLevelUp(actor, lv, beforeLv)
    if MentorShipTask.isHasMasterOrApparenice(actor) then
        MentorShipChangTask(actor, 1, "*", lv)
    end
end

function MentorShipTask.onClickNpc(actor, npcid)
    if MentorShipTask.isHasMasterOrApparenice(actor) then
        MentorShipChangTask(actor, 5, 6)
    end
end

function MentorShipTask.onKillMon(actor, mon, mapid, monidx)
    if MentorShipTask.isHasMasterOrApparenice(actor) then
        MentorShipChangTask(actor, 7, mapid, monidx)
        local monCfg = Monster_cfg[monidx]
        if monCfg and monCfg.BossSign == 3 then
            local isMentorTeam = false
            local myTeamId = tonumber(targetinfo(actor, "GROUPID")) or 0
            if myTeamId > 0 then
                local myRelationStr = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
                if myRelationStr and myRelationStr ~= "" then
                    local relation = json2tbl(myRelationStr)
                    if relation.myMaster and relation.myMaster.UserID then
                        local masterId = tonumber(relation.myMaster.UserID)
                        if checkstate(masterId, 2) then
                            local masterTeamId = tonumber(targetinfo(masterId, "GROUPID")) or 0
                            if myTeamId == masterTeamId then
                                isMentorTeam = true
                            end
                        end
                    end
                    if isMentorTeam then
                        MentorShipChangTask(actor, 18, "*", 1)
                    end
                end
            end
        end
    end
end

function MentorShipTask.isHasMasterOrApparenice(actor)
    local myRelation = getcustvar("11_" .. userid(actor) .. "_" .. "t_MasterAndApprt")
    -- dump(myRelation)
    if myRelation == "" or myRelation == 0 or myRelation == nil then
        return false
    else
        myRelation = json2tbl(myRelation)
        if myRelation.myMaster and myRelation.myMaster.UserID then
            return true
        else
            return false
        end
    end
end

function MentorShipTask.updatePickItem(actor, itemID)
    MentorShipChangTask(actor, 4, { 1 }, { itemId = itemID, num = 1 })
end

function MentorShipTask.updateMakeItem(actor, makeid)
    linkitembymakeindex(actor, makeid)
    local NeedLevel = linkitem(actor, "NeedLevel")
    local GRADE = linkitem(actor, "GRADE")
    MentorShipChangTask(actor, 4, { 3, 4 }, { ["Grade"] = GRADE, ["NeedLevel"] = NeedLevel, num = 1 })
end

GameEvent.add(EventCfg.onAddFriendSelf, function(actor, param1)                -- 添加好友
    MentorShipTask.onAddFriend(param1)
end, MentorShipTask)                                                           -- 同意好友成功触发  param1 申请人ID

GameEvent.add(EventCfg.onPlayLevelUp, function(actor, cur_level, before_level) -- 升级触发
    MentorShipTask.onLevelUp(actor, cur_level, before_level)
end, MentorShipTask)

GameEvent.add(EventCfg.onClicknpc, function(actor, npcid) -- 点击NPC触发
    MentorShipTask.onClickNpc(actor, npcid)
end, MentorShipTask)

GameEvent.add(EventCfg.onKillMon, function(actor, mon, mapid, monidx) --杀怪触发
    MentorShipTask.onKillMon(actor, mon, mapid, monidx)
end, MentorShipTask)

GameEvent.add(EventCfg.updateMakeItem, function(actor, makeid)
    MentorShipTask.updateMakeItem(actor, makeid)
end, MentorShipTask)

GameEvent.add(EventCfg.onPickUpItemEX, function(actor, makeid, itemid)
    MentorShipTask.updatePickItem(actor, itemid)
end, MentorShipTask)

return MentorShipTask
