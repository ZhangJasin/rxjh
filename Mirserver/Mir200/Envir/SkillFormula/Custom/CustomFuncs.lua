local CustomFuncs = {}

-- 配置表 用户会需求改放置路径 统一开在这加载
CustomFuncs.config = {
	buffs 			 = require("Envir/QuestDiary/game_config/Buff.lua"),
	skill_upgrades   = require("Envir/QuestDiary/game_config/SkillUpgrade.lua"),
	skill_effects	 = require("Envir/QuestDiary/game_config/SkillEffect.lua"),
	qigong 			 = require("Envir/QuestDiary/game_config/SkillQiGong.lua"),
	qigong_levels 	 = require("Envir/QuestDiary/game_config/SkillQiGongSub.lua"),
}

-- 本地初始化
local PassiveManager = PassiveManager
local _actorStatic = PassiveManager and PassiveManager._actorStatic
local setbuffabil = setbuffabil
local CustomConst = CustomConst
local RAGE_BUFF_ID = CustomConst.BuffId.RAGE
local FRAGE_MASK   = CustomConst.EventMask.FRAGE
local PLAYER_OBJ   = CustomConst.EventObject.PLAYER
local RAGE_MAX = 1000

-- 如何自定义函数示例
-- 在公式中可写 example(param1, param2) 调用
function CustomFuncs.example(param1, param2)
	-- print(param1, param2)
end

function CustomFuncs.getinfo(param1, param2)
	-- print(param1, param2)
end


-- 例子：比如在伤害公式计算完所有伤害后，想做吸血属性, 公式中funcs.steal(e)
-- 简单举例 A(80)为攻击者吸血属性 
function CustomFuncs.steal(env)
	-- local inc = math.floor(env.damage * env.A(80)/10000 + 0.5)
	-- changeabil(env.attacker, 1, "+", inc)
	-- sendattackeffectnum(env.attacker, 2, inc) -- 特殊：吸血时单独播回血飘字
	local xixuezhi = env.A(114)
	if xixuezhi > 0 then
        changeabil(env.attacker, 1, "+", xixuezhi)
		sendattackeffectnum(env.attacker, 2, xixuezhi) -- 特殊：吸血时单独播回血飘字
    end
end

---------------------------------------------------------------------
-- 一些工具函数 （误删改 框架和模板可能有用到）
---------------------------------------------------------------------
-- 日志打印
function CustomFuncs.log(level, fmtStr, ...)
	local mgrLevel = (CustomConst.Log and CustomConst.Log.MANAGER) or 0
	if mgrLevel >= level then
		-- print(string.format(fmtStr, ...))
	end
end

-- 将如 "1#2|3#4" 的字符串解析
-- str 要解析的字符串

function CustomFuncs.splitParamList(str, pairSep, kvSep)
    local list = {}
    if type(str) ~= "string" or str == "" then
        return list
    end
    pairSep = pairSep or "|"   -- 组与组之间的分隔符
    kvSep   = kvSep   or "#"   -- 组内 key/value 的分隔符
    for seg in string.gmatch(str, "[^" .. pairSep .. "]+") do
        local aStr, bStr = seg:match("^([^" .. kvSep .. "]+)%" .. kvSep .. "([^" .. kvSep .. "]+)$")
        if aStr and bStr then
            local a = tonumber(aStr)
            local b = tonumber(bStr)
            if a and b then
                list[#list + 1] = { a, b }
            else
			end
        end
    end
    return list
end

function CustomFuncs.parseAttrList(str)
    local ret = {}
    if type(str) ~= "string" or str == "" then
        return ret
    end
    local paramList = CustomFuncs.splitParamList(str)
	for _, kv in ipairs(paramList) do
		local aid   = kv[1]
		local value = kv[2]
		if aid ~= nil and value ~= nil and value ~= 0 then
			ret[#ret + 1] = {
				attrId = aid,
				value  = value,
			}
		end
	end
    return ret
end

-- 将如 "1#2|3,4;5 6" 的字符串解析为列表或集合
-- str 要解析的字符串
-- asSet boolean 是否返回set形式（值-true）
function CustomFuncs.parseIdStr(str, asSet)
	local ret = {}
	if type(str) ~= "string" or str == "" then
		return ret
	end

	for idStr in string.gmatch(str, "[^#|,;%s]+") do
		local n = tonumber(idStr)
		if n then
			if asSet then
				ret[n] = true
			else
				ret[#ret + 1] = n
			end
		else
			-- print(string.format("[parseIdStr] 非法ID项: '%s' (from string: %s)", idStr, str))
		end
	end
	return ret
end

-- 判断指定职业串是否包含当前职业
-- jobStr 事件表配置的JobReq列，比如 "1|2|5"
-- myJob 当前对象的的职业ID
function CustomFuncs.jobAllowed(jobStr, myJob)
	if not jobStr or jobStr == "0" then
		return true
	end
	local allowSet = CustomFuncs.parseIdStr(jobStr, true)
	return allowSet[myJob] == true
end

-- 对玩家及其队友执行回调
-- cb回调函数 cb(teammateId)
function CustomFuncs.foreachTeammate(actor, cb)
	cb(actor) -- 自己
	local gid = targetinfo(actor, "GROUPID")
	if not gid or gid <= 0 then
		return
	end

	-- 成员列表格式 "id1#id2#..."
	local memberStr = groupinfo(gid .. "_5")
	if type(memberStr) ~= "string" or memberStr == "" then
		return
	end

	for id in memberStr:gmatch("[^#]+") do
		local pid = tonumber(id)
		if pid and pid ~= actor then
			cb(pid)
		end
	end
end

function CustomFuncs.parseBuffConfig()
	local buffs = CustomFuncs.config.buffs
	local typeCfg = {}
	for _, buff in pairs(buffs) do
        if type(buff.BuffType) == "number" and buff.BuffType > 0 then
            if not typeCfg[buff.BuffType] then
                typeCfg[buff.BuffType] = {}
            end
            local list = typeCfg[buff.BuffType]
            list[#list + 1] = buff
        end
	end
	for _, list in pairs(typeCfg) do
		table.sort(list, function(a, b)
			return a.ID > b.ID
		end)
	end
	CustomFuncs.config.buffTypeMap = typeCfg
end

function CustomFuncs.getBuffsByType(typeId)
	if not CustomFuncs.config.buffTypeMap then
		CustomFuncs.parseBuffConfig()
	end
	return CustomFuncs.config.buffTypeMap[typeId] or {}
end

function CustomFuncs.getSkillsByType(typeId) end

-- 把 "11#12#type(101)" 展开为 set（用于筛选）
function CustomFuncs.expandBuffIdsToSet(str, context)
	local set = {}
	str = tostring(str or "")
	for token in string.gmatch(str, "[^#]+") do
		token = token:match("^%s*(.-)%s*$")
		if token ~= "" then
			local id = tonumber(token)
			if id then
				set[id] = true
			else
                local typeId = token:match("^[Tt][Yy][Pp][Ee]%s*[%(:=]%s*(%d+)%s*%)$")
                if typeId then
                    typeId = tonumber(typeId)
                    local list = context == "BUFF" and CustomFuncs.getBuffsByType(typeId) or
                                    context == "SKILL" and CustomFuncs.getSkillsByType(typeId)
                    for _, item in ipairs(list or {}) do
                        if item.ID then
                            set[item.ID] = true
                        end
                    end
				end
			end
		end
	end
	return set
end

---------------------------------------------------------------------
-- 怒气逻辑
---------------------------------------------------------------------
-- 给玩家增加怒气并检测是否满怒，未满怒则更新怒气Buff值，满怒则触发对应事件
-- incRage 增加的怒气值
-- dur 怒气Buff持续时间
-- isPlayer是否玩家（只有玩家才真正存怒气）
function CustomFuncs.addRageAndCheckFull(actor, incRage, dur, isPlayer)
	-- CustomFuncs.log(1, "[AddRage] actor=%s  incRage=%s", tostring(actor), tostring(incRage))
	if isPlayer == false or incRage <= 0 then
		return
	end

    local s = PassiveManager._actorStatic[actor] or {}
    if s.RAGE.lock then return end

	local cur = abil(actor, 4)
	local maxv = 1000
	local new = cur + incRage
	-- CustomFuncs.log(1, "[AddRage] cur=%d  max=%d  new=%d", cur, maxv, new)
	if new >= maxv then
		-- CustomFuncs.log(1, "[AddRage] 满怒 -> 触发 FRAGE 事件")
		local job = job(actor)
		if job == 3 then
			local curCombo = currabil(actor, 74)
			-- 刺客满怒不锁定怒气，满连击点锁定
			if curCombo >= abil(actor, 74) then
				-- CustomFuncs.log(1, "[AddRage] 刺客满连击点，锁定怒气")
				s.RAGE.lock = true
			else
				s.RAGE.lock = false
			end
		else
			-- 其他职业满怒锁定怒气
			s.RAGE.lock = true
		end
        PassiveManager:handleEvent(actor, actor, CustomConst.EventMask.FRAGE, CustomConst.EventObject.PLAYER, 0, {})
		if s.RAGE.lock then
			setbuffabil(actor, CustomConst.BuffId.RAGE, 4, "=", maxv, dur)
		end
        
	else
		setbuffabil(actor, CustomConst.BuffId.RAGE, 4, "+", incRage, dur)
	end
end


return CustomFuncs
