---------------------------------------------------------------------
-- 被动模板 CustomPassiveTemplate.lua

-- 1.静态属性模板（static）：
-- 在角色登录 / 重载、切换被动 / 刷新属性 时执行刷新，用于计算长期生效、可缓存的静态属性，如攻击百分比加成、暴击 +5%、各种非实时触发、非瞬时效果
-- 这些静态属性会被合并进 s（静态属性累积缓存 PassiveManager._actorStatic ），在其他模板和伤害公式中参与计算。

-- 2.事件型模板（fn）：事件发生时瞬间执行的效果模板，如受到攻击触发吸血、被击中时提高怒气

-- 3.参数说明
-- cfg	被动/气功表一行参数数据（如 Param、概率等）
-- ctx	是一次技能执行期间 传递下来的动态参数表，在跑伤害公式前创建，之后写入伤害、飘字、buff 时长 等动态的参数

---------------------------------------------------------------------
local _T = {}
local customFuncs = require("Envir/SkillFormula/Custom/CustomFuncs.lua")
local mountHHlist = require("Envir/QuestDiary/game_config/cfgcsv/MountHuanHua.lua")
local wuxun_skill_data = require("Envir/QuestDiary/game_config/cfgcsv/wuxun_skill_data.lua")
local rand, floor, max, min = math.random, math.floor, math.max, math.min
---------------------------------------------------------------------
-- 怒气能量模板
---------------------------------------------------------------------
-- 被动触发加怒气
-- Param2=每次增加值
-- Param3=时间秒(到时间后触发指定逻辑，如刺客5分钟不涨怒连击点清零)
_T.RAGE_ADD = {
	fn = function(cfg)
		local prob = tonumber(cfg.BaseProb) or 1
		local base = tonumber(cfg.Param2) or 0
		local dur = tonumber(cfg.Param3) or 0
		local mask = cfg.EventMask
		return function(att, tar, sid, ctx)
			if rand() >= prob then
				return
			end
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			if s.RAGE.lock then
				return
			end

			-- 概率清怒气
            local clearnqzpct = abil(tar, 111)
			if clearnqzpct > 0 and math.random(1,10000) <= clearnqzpct then
				setbuffabil(att, 100, 4, "=", 0)
				return	
			end

			local pct = (s.RAGE and s.RAGE.addpct) or 0
			local incRage = floor(base * (1 + pct) + 0.5)
			local attrPct = abil(att, 112) or 0
			incRage = incRage + math.floor(1000*attrPct/10000)
			if incRage <= 0 then
				return
			end
			

			local objType = ctx.tarPL
			if mask == "ATTACK" then
				objType = ctx.attPL
			end
			customFuncs.addRageAndCheckFull(att, incRage, dur, objType)
		end
	end,
}
-- 满怒Buff属性
-- Param1 =BuffID Param2=属性 Param3=buff基础时间
_T.RAGE_FULL = {
	fn = function(cfg)
		local buffId = tonumber(cfg.Param1) or 0
		local baseDur = tonumber(cfg.Param3) or 0
		local baseList = customFuncs.parseAttrList(cfg.Param2 or "") or {}
		-- dump(baseList, "RAGE_FULL baseList")
		if buffId <= 0 or baseDur <= 0 or #baseList <= 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			local s = PassiveManager._actorStatic[att] or {}
			s.RAGE.lock = true
			local extraPct = (s.QG and s.QG.kfwp) or 0
			local plusDur = (s.BUFFDUR and s.BUFFDUR[buffId]) or 0
			local keepSec = baseDur + plusDur
			addbuff(att, buffId, keepSec)
			for _, info in ipairs(baseList) do
				local incValue = floor(info.value * (1 + extraPct) + 0.5)
				setbuffabil(att, buffId, info.attrId, "=", incValue, keepSec)
			end
		end
	end,
}
-- 怒气buff结束
_T.RAGE_BUFF_END = {
	fn = function(cfg)
		--先按单ID处理
		local buffId = tonumber(cfg.BuffIds) or 0
		if buffId <= 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if ctx.buffId ~= buffId then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			s.RAGE.lock = false
			setbuffabil(att, 100, 4, "=", 0)
		end
	end,
}
-- 受击增怒百分比累加
-- Param2 叠加百分比
_T.RAGE_HIT_ADD = {
	static = function(cfg, s)
		local inc = tonumber(cfg.Param2) or 0
		if inc == 0 then
			return
		end
		
		s.RAGE = s.RAGE or {}
		s.RAGE.addpct = (s.RAGE.addpct or 0) + inc -- 叠加
	end,
}
-- 概率增加怒气值
-- Param2=增加的怒值量（这里默认怒气上限1000，我们按1%算=10）
_T.RAGE_POINT_ADD = {
	fn = function(cfg)
		local prob = tonumber(cfg.BaseProb) or 0 -- 触发概率
		local incRage = tonumber(cfg.Param2) or 10 -- 增加怒值
		local dur = tonumber(cfg.Param3) or 0
		if prob <= 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			if s.RAGE.lock then
				return
			end
			if rand() >= prob then
				return
			end
			customFuncs.addRageAndCheckFull(att, incRage, dur)
		end
	end,
}
-- 刺客满怒加连击点
_T.COMBO_FROM_FRAGE = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		if comboId <= 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			setbuffabil(att, 100, 4, "=", 0)
			local curCombo = currabil(att, comboId)
			local maxCombo = abil(att, comboId)
			if curCombo < maxCombo then
				changeabil(att, comboId, "+", 1)
			end
		end
	end,
}
-- 技能命中直接获得怒气珠
-- Param1=获得怒气珠数量（默认1）
_T.COMBO_FROM_SKILL = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local comboNum = tonumber(cfg.Param2) or 1
		local dur = tonumber(cfg.Param3) or 300
		local dmg = tonumber(cfg.Param4) or 0
		if comboId <= 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			local curCombo = currabil(att, comboId)
			local maxCombo = 5
			if curCombo < maxCombo then
				sendmsg(att, 9, "释放武功- 获得连击点x " .. comboNum)
				changeabil(att, comboId, "+", comboNum)
			end
			setbufftime(att, 100, "=", dur)
			ctx.setDamage(dmg)
		end
	end,
}
---------------------------------------------------------------------
-- 规定时间无新怒气则连击点清零
---------------------------------------------------------------------
_T.COMBO_CLEAR = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		if comboId <= 0 then
			return function() end
		end
		-- print("刺客无怒气清连击点模板加载")
		return function(att, tar, sid, ctx)
			changeabil(att, comboId, "=", 0)
		end
	end,
}
---------------------------------------------------------------------
-- buff类模板
---------------------------------------------------------------------
-- 调整buff持续时间
-- Param1=buff列表
-- Param2=持续时间
_T.BUFF_DUR_ADD = {
	fn = function(cfg)
		local incSec = tonumber(cfg.Param2) or 0
		if incSec == 0 then
			return
		end
		local buffIdSet = customFuncs.parseIdStr(cfg.BuffIds or "", true)
		return function(_att, tar, sid, ctx)
			local bid = ctx.buffId
			if bid and buffIdSet[bid] then
				ctx.buff_addDur = (ctx.buff_addDur or 0) + incSec
			end
		end
	end,
	-- 静态型写进s.BUFFDUR
	static = function(cfg, s)
		local incSec = tonumber(cfg.Param2) or 0
		if incSec == 0 then
			return
		end
		s.__buff_dur_handled = s.__buff_dur_handled or {}
		if s.__buff_dur_handled[cfg.ID] then
			return -- 已处理跳过
		end
		s.__buff_dur_handled[cfg.ID] = true
		for id in string.gmatch(cfg.Param1 or "", "([^#]+)") do
			local buffId = tonumber(id)
			if buffId then
				s.BUFFDUR = s.BUFFDUR or {}
				s.BUFFDUR[buffId] = (s.BUFFDUR[buffId] or 0) + incSec
				-- print(buffId, s.BUFFDUR[buffId])
				-- print(('[BUFF_DUR_ADD-STATIC] id=%d  +%.2fs'):format(buffId, incSec))
			end
		end
	end,
}

-- 添加限时buff
_T.BUFF_TEMP = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		local buffId = tonumber(cfg.Param1) or 0
		local attrId = tonumber(cfg.Param2) or 0
		local rawInc = tonumber(cfg.Param3) or 0
		local baseSec = tonumber(cfg.Param4) or 3

		if prob <= 0 or buffId <= 0 or attrId <= 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if rand() >= prob then
				return
			end
			setbuffabil(att, buffId, attrId, "=", rawInc, baseSec)
			if piaoZi > 0 then
				ctx.pzQigong = piaoZi -- 播气功飘字
			end
		end
	end,
}

---------------------------------------------------------------------
-- 静态加成类模板  记录到角色身上s，持续跟随角色，重新挂/卸被动才会重置
---------------------------------------------------------------------
-- 提高伤害
-- Param1 : 主键 记录到静态加成表QG， incDamage=额外增伤  pctDamage=百分比增伤
-- Param2 : 加成值（0.3代表 +30%， 120代表 +120 等数值）
_T.DMG_ADD = {
	static = function(cfg, s)
		local key = cfg.Param1 ~= "" and cfg.Param1 or "incDamage"
		local inc = tonumber(cfg.Param2) or 0
		if inc == 0 then
			return
		end
		s.QG = s.QG or {}
		s.QG[key] = (s.QG[key] or 0) + inc * 2
	end,
}

-- 提高对武功的闪避率  -赞未使用 目前直接配置属性加入公式来实现
-- Param2 = 百分比加成
_T.WG_DODGE_PCT = {
	static = function(cfg, s)
		local inc = tonumber(cfg.Param2) or 0
		if inc == 0 then
			return
		end
		s.QG = s.QG or {}
		-- 存到表键 wgdodge，供公式读取
		s.QG.wgdodge = (s.QG.wgdodge or 0) + inc
	end,
}

-- 提高武功伤害百分比
-- Param1 =自定义键（默认 "wgpct"）
-- Param2 =加成百分比 (0.12 = +12%)
_T.DMG_WG_PCT = {
	static = function(cfg, s)
		local key = cfg.Param1 ~= "" and cfg.Param1 or "wgpct"
		local inc = tonumber(cfg.Param2) or 0
		if inc == 0 then
			return
		end
		s.QG = s.QG or {}
		s.QG[key] = (s.QG[key] or 0) + inc
	end,
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		local pct = tonumber(cfg.Param1) or 0
		if prob <= 0 or pct <= 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			if not ctx.is_skill then
				return
			end
			if rand() >= prob then
				return
			end
			ctx.wgpct = (ctx.wgpct or 0) + pct
			if piaoZi > 0 then
				ctx.pzQigong = piaoZi -- 播气功飘字
			end
		end
	end,
}

-- 增加必杀一击概率
-- Param2 = 概率增量
_T.BISHA_PROB_ADD = {
	static = function(cfg, s)
		local inc = tonumber(cfg.Param2) or 0
		if inc == 0 then
			return
		end
		s.PROB = s.PROB or {}
		s.PROB.bisha = (s.PROB.bisha or 0) + inc
	end,
}

-- 提升无坚不摧触发率
-- Param2=概率增量 Param3=无视防御增量
_T.JOB_INC_WJBC = {
	static = function(cfg, s)
		local extraProb = tonumber(cfg.Param2) or 0
		local ignorePct = tonumber(cfg.Param3) or 0
		if extraProb == 0 and ignorePct == 0 then
			return
		end

		s.PROB = s.PROB or {}
		s.PROB.wjbc = (s.PROB.wjbc or 0) + extraProb
		s.CUSTOM = s.CUSTOM or {}
		s.CUSTOM.wjbc_ignore = (s.CUSTOM.wjbc_ignore or 0) + ignorePct
	end,
}

-- 增加对怪物的百分比伤害
-- Param1 主键 写入QG，默认 aoeDamage
-- Param2 加成百分比
_T.DMG_AOE_PVE = {
	static = function(cfg, s)
		local key = cfg.Param1 ~= "" and cfg.Param1 or "aoeDamage"
		local inc = tonumber(cfg.Param2) or 0
		if inc == 0 then
			return
		end
		s.QG = s.QG or {}
		s.QG[key] = (s.QG[key] or 0) + inc
	end,
}

-- 增加对怪物的固定伤害（属性ID 165）
-- 每增加1点属性165，攻击怪物时伤害增加1点
-- Param1 主键 写入QG，默认 pveFlatDamage
-- Param2 固定伤害加成值（默认1:1比例）
_T.DMG_PVE_FLAT = {
	static = function(cfg, s)
		local key = cfg.Param1 ~= "" and cfg.Param1 or "pveFlatDamage"
		local inc = tonumber(cfg.Param2) or 1
		if inc == 0 then
			return
		end
		s.QG = s.QG or {}
		s.QG[key] = (s.QG[key] or 0) + inc
	end,
}

-- 提高狂风万破威力
-- Param2 =加成值（以 0.5 表示 +50%）
_T.KFWP_PCT_ADD = {
	static = function(cfg, s)
		local inc = tonumber(cfg.Param2) or 0
		if inc == 0 then
			return
		end
		s.QG = s.QG or {}
		-- 累加到 kfwp, RAGE_FULL 模板会读这个字段
		s.QG.kfwp = (s.QG.kfwp or 0) + inc
	end,
}

-- 提高超必杀伤害百分比
-- Param2 =增加伤害百分比
_T.DMG_CBS_PCT = {
	static = function(cfg, s)
		local inc = tonumber(cfg.Param2) or 0
		if inc == 0 then
			return
		end
		s.MUL = s.MUL or {}
		s.MUL.cbs_inc = (s.MUL.cbs_inc or 0) + inc -- 叠加百分比
	end,
}

-- 提高超必杀触发概率
-- Param1 =职业限制 ； Param2 =概率增量
_T.PROB_CBS_ADD = {
	static = function(cfg, s, actor)
		local jobReq = tonumber(cfg.Param1) or 0
		local inc = tonumber(cfg.Param2) or 0
		if jobReq ~= 0 and job(actor) ~= jobReq then
			return
		end
		if inc == 0 then
			return
		end

		s.PROB = s.PROB or {}
		s.PROB.cbs = (s.PROB.cbs or 0) + inc -- 累加
	end,
}

-- 提高治疗加成
-- Param1 =加成key 记录到静态加成表QG， heal=额外治疗  healpct=百分比治疗
-- Param2 =加成值（0.3代表 +30%， 120代表 +120 等数值）
_T.HEAL_ADD = {
	static = function(cfg, s)
		local key = cfg.Param1 ~= "" and cfg.Param1 or "heal"
		local inc = tonumber(cfg.Param2) or 0
		if inc == 0 then
			return
		end
		s.QG = s.QG or {}
		s.QG[key] = (s.QG[key] or 0) + inc
	end,
}

-- Buff额外增益修正 (按ID)
_T.BUFF_BONUS = {
	static = function(cfg, s)
		local pct = tonumber(cfg.Param2) or 0
		if pct == 0 then
			return
		end
		local tbl = customFuncs.parseIdStr(cfg.Param1 or "")
		if #tbl == 0 then
			return
		end

		s.BUFF_BONUS = s.BUFF_BONUS or {}
		for _, pid in ipairs(tbl) do
			s.BUFF_BONUS[pid] = (s.BUFF_BONUS[pid] or 0) + pct
		end
	end,
}

-- Buff额外增益修正 (按BuffType批量)
_T.BUFF_BONUS_TYPE = {
	static = function(cfg, s)
		local pct = tonumber(cfg.Param2) or 0
		if pct == 0 then
			return
		end
		local types = customFuncs.parseIdStr(cfg.Param1 or "")
		if #types == 0 then
			return
		end
		s.BUFF_BONUS = s.BUFF_BONUS or {}
		for _, buffType in ipairs(types) do
			local tbl = customFuncs.getBuffsByType(buffType)
			if #tbl > 0 then
				for _, buffCfg in ipairs(tbl) do
					local pid = buffCfg.ID
					s.BUFF_BONUS[pid] = (s.BUFF_BONUS[pid] or 0) + pct
				end
			end
		end
	end,
}

-- 动态提升使用物品的Buff效果
_T.BUFF_BONUS_TYPE_DYN = {
	fn = function(cfg)
		local attrId = tonumber(cfg.Param3) or 0
		local cap = tonumber(cfg.Param4) or 0
		if attrId <= 0 then
			return function() end
		end
		local buffIdSet = customFuncs.expandBuffIdsToSet(cfg.BuffIds, "BUFF")
		return function(att, tar, sid, ctx)
			local bid = ctx and ctx.buffId
			if not (bid and buffIdSet[bid]) then
				return
			end

			local attrValue = (abil(tar, attrId) or 0)
			if cap > 0 and attrValue > cap then
				attrValue = cap
			end
			if attrValue == 0 then
				return
			end

			local stored = tonumber(getbuffcustdata(tar, bid)) or 0
			local newVal = stored + attrValue / 10000
			setbuffcustdata(tar, bid, tostring(newVal))
		end
	end,
}

-- 九天真气Buff额外增益修正
-- Param2=增益系数(如 0.10 代表 +10%)
---------------------------------------------------------------------
_T.JOB_JTZQ = {
	static = function(cfg, s, actor)
        local key = "heal"
        local inc = tonumber(cfg.Param3) or 0
        if inc ~= 0 then
            s.QG = s.QG or {}
            s.QG[key] = (s.QG[key] or 0) + inc
        end

		local extraPct = tonumber(cfg.Param2) or 0
		if extraPct <= 0 then return end

		s.BUFF_ABIL = s.BUFF_ABIL or {}
		local buffIdSet = customFuncs.expandBuffIdsToSet(cfg.BuffIds, "BUFF")
        for bid, _ in pairs(buffIdSet) do
            if not s.BUFF_ABIL[bid] then
                local paramStr = customFuncs.config.buffs[bid].Param or ""
                local attrs = {}
                for _, pair in ipairs(customFuncs.parseAttrList(paramStr)) do
                    attrs[pair.attrId] = pair.value
                end
                s.BUFF_ABIL[bid] = {
                    attrs = attrs,   -- buff 的原始属性
                    pct   = 0,       -- 静态百分比
                }
            end
            s.BUFF_ABIL[bid].pct = s.BUFF_ABIL[bid].pct + extraPct
        end
	end,

    fn = function(cfg)
        local addPct = 0     -- 临时测试 动态额外百分比 按需自定义调整
        return function(att, tar, skillId, ctx)
            ctx.buffPct = (ctx.buffPct or 0) + addPct
        end
    end
}

-- 刺客被动 概率不扣连击点
_T.COMBO_IGNORE = {
	static = function(cfg, s)
		local inc = tonumber(cfg.Param2) or 0
		if inc == 0 then
			return
		end
		s.PROB = s.PROB or {}
		-- 存到表键 combo_ignore
		s.PROB.combo_ignore = (s.PROB.combo_ignore or 0) + inc
	end,
}

---------------------------------------------------------------------
-- 动态加成类模板   临时记录到ctx 在每次技能/普攻结算时构造并传入模板、公式表
---------------------------------------------------------------------
-- 动态伤害加成百分比
-- Param2 = 伤害加成百分比
_T.DMG_PADD = {
	fn = function(cfg)
		local prob = tonumber(cfg.BaseProb) or 0
		local inc = tonumber(cfg.Param2) or 0
		return function(att, tar, sid, ctx)
			local p = prob
			if rand() < p then
				ctx.pctDamage = (ctx.pctDamage or 0) + inc
			end
		end
	end,
}

-- 流星三矢
-- Param1 = 三连射技能ID
_T.JOB_SANLIAN = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = 1
		local skillId = tonumber(cfg.Param1) or 0
		return function(att, tar, sid, ctx)
			if not ctx.is_normal then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local p = prob + (s.PROB.sanlian or 0)
			if rand() < p and skillId > 0 then
				scriptspellskill(att, sid, skillId, 60, 1, 1, 1)
				ctx.pctDamage = (ctx.pctDamage or 0) + 0.15
				if piaoZi > 0 then
					-- ctx.pzQigong = piaoZi    -- 播气功飘字
				end
			end
		end
	end,
}

-- 必杀一击 1.5× 伤害
_T.JOB_BISHA = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.Param2) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		return function(att, tar, sid, ctx)
			if not ctx.is_normal then
				return
			end
			local critProbBase = max(0.10, min(0.90, (ctx.A(57) - ctx.D(59)) / 10000))
			local extraCrit = (ctx.A(58) or 0) / 10000
			local p = prob + critProbBase
			if rand() < p then
				-- print("触发必杀")
				ctx.mul = 1.5 + extraCrit
				ctx.pzDamage = CustomConst.AttackPiaoZi.BISHA
				if piaoZi > 0 then
					ctx.pzExtra = 10021 -- 播会心一击飘字
				end
			end
		end
	end,
}

-- 心神凝聚 2x 伤害  超必杀
_T.JOB_XINSHEN = {
	fn = function(cfg)
		local prob = tonumber(cfg.BaseProb) or 0
		local baseMul = tonumber(cfg.Param2) or 2
		return function(att, tar, sid, ctx)
			if not ctx.is_normal then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local p = prob + (s.PROB and s.PROB.cbs or 0)
			-- print("心神凝聚触发概率:", p)
			if rand() < p then
    			local inc = (s.MUL and s.MUL.cbs_inc) or 0
    			ctx.mul = (ctx.mul > 0 or 1) * (baseMul * (1 + inc))  -- 这里写错
    			ctx.pzDamage = CustomConst.AttackPiaoZi.XINSHEN
			end
		end
	end,
}

-- 无名
_T.JOB_WMJS = {
	fn = function(cfg)
		local base = tonumber(cfg.BaseProb) or 0
		local inc = tonumber(cfg.Param2) or 0
		return function(att, tar, sid, ctx)
			if not ctx.is_normal then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local p = base + (s.PROB and s.PROB.wmjs or 0)
			if rand() < p then
				local mul = (ctx.mul > 0) and ctx.mul or 1
    			ctx.mul = mul * (1 + inc)
			end
		end
	end,
}

-- 致命绝杀
_T.JOB_ZMJS = {
	-- EventMask: ATTACK_BF
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		local incMul = tonumber(cfg.Param2) or 1
		return function(att, tar, sid, ctx)
			if not ctx.is_normal then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local p = prob + (s.PROB and s.PROB.zmjs or 0)
			if rand() < p then
				if piaoZi > 0 then
					ctx.pzQigong = piaoZi -- 播气功飘字
				end
				ctx.exMul = (ctx.exMul or 0) + incMul
			end
		end
	end,
}

-- 概率触发连打 Param1=连打技能ID
_T.JOB_LIANDA = {
	fn = function(cfg)
		local prob = tonumber(cfg.BaseProb) or 0
		local skillId = tonumber(cfg.Param1) or 0 -- 触发时要放出的技能
		return function(att, tar, sid, ctx)
			if not ctx.is_normal then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local p = prob + (s.PROB.lianda or 0)
			if rand() < p and skillId > 0 then
				scriptspellskill(att, sid, skillId, 60, 1, 1, 1) -- 下次释放替换
			end
		end
	end,
}

-- 被击时攻转化防;
_T.DEF_BY_ATK = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		local buffId = tonumber(cfg.Param1) or 0
		local defAttrId = tonumber(cfg.Param2) or 0
		local attAttrId = tonumber(cfg.Param3) or 23
		local ratio = tonumber(cfg.Param4) or 0
		local dur = tonumber(cfg.Param5) or 10
		if prob <= 0 or buffId <= 0 or ratio <= 0 or defAttrId <= 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if ctx.damage and ctx.damage > 0 and rand() < prob then
				local atkVal = (ctx.D and ctx.D(attAttrId)) or 0
				local incDef = floor(atkVal * ratio + 0.5)
				if incDef > 0 then
					setbuffabil(att, buffId, defAttrId, "=", incDef, dur)
					if piaoZi > 0 then
						ctx.pzQigong = piaoZi -- 播气功飘字
					end
				end
			end
		end
	end,
}

-- 概率触发 提高伤害(对方防御额外转化最终伤害)
_T.DMG_BY_DEF = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		local defAttrId = tonumber(cfg.Param1) or 0
		local Pct = tonumber(cfg.Param2) or 0.2

		if prob <= 0 or defAttrId <= 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if rand() < prob then
				local tarDef = ctx.D(defAttrId) or 0
				local incDamage = floor(tarDef * Pct + 0.5)
				-- if incDamage <= 0 then return end   --对方无防御要不要判断自行决定
				ctx.damage = (ctx.damage or 0) + incDamage
				if piaoZi > 0 then
					ctx.pzQigong = piaoZi -- 播气功飘字
				end
			end
		end
	end,
}

-- 概率触发 提高伤害(攻击额外转化最终伤害)
-- Param1=攻击属性ID Param2=比例
_T.DMG_BY_ATK = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		local AttrId = tonumber(cfg.Param1) or 0
		local Pct = tonumber(cfg.Param2) or 0

		if prob <= 0 or AttrId <= 0 or Pct <= 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if rand() >= prob then
				return
			end

			local attVal = ctx.A(AttrId) or 0
			local incDamage = floor(attVal * Pct + 0.5)
			if incDamage <= 0 then
				return
			end
			ctx.damage = (ctx.damage or 0) + incDamage
			if piaoZi > 0 then
				ctx.pzQigong = piaoZi -- 播气功飘字
			end
		end
	end,
}

-- 概率触发 提高伤害(武功攻击额外转化最终伤害)
-- Param1=武功攻击属性ID Param2=比例
_T.DMG_BY_WG = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		local AttrId = tonumber(cfg.Param1) or 0
		local Pct = tonumber(cfg.Param2) or 0
		if prob <= 0 or AttrId <= 0 or Pct <= 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			if not ctx.is_skill then
				return
			end
			if ctx.damage <= 0 then
				return
			end
			if rand() >= prob then
				return
			end
			local incDamage = floor(ctx.damage * Pct + 0.5)
			ctx.damage = ctx.damage + incDamage
			if piaoZi > 0 then
				ctx.pzQigong = piaoZi -- 播气功飘字
			end
		end
	end,
}

-- 概率触发 反伤
_T.DMG_FS = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local ratio = tonumber(cfg.Param2) or 0
		local probMonster = tonumber(cfg.Param3) or 0
		local probPlayer = tonumber(cfg.Param4) or 0
		if probMonster <= 0 and probPlayer <= 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			if not ctx.damage or ctx.damage <= 0 then
				return
			end
			local isPlayer = ctx.attPL
			local prob = isPlayer and probPlayer or probMonster
			if rand() < prob then
				local damageFs = floor(ctx.damage * ratio + 0.5)
				if damageFs <= 0 then
					return
				end
				sethitter(tar, att) 
				changeabil(tar, 1, "-", damageFs)
				sendattackeffectnum(tar, 1, damageFs, nil, nil, att) -- 特殊：反伤时单独播飘字
				if piaoZi > 0 then
					ctx.pzQigong, ctx.pzAtt, ctx.pzTar = piaoZi, att, tar
				end
				-- sendmsg(att, 9, string.format("反伤触发，对 %s 造成 %d 伤害", tostring(tar), damageFs))
			end
		end
	end,
}

-- 闪避后提高伤害，把对手闪避帧伤害 × 比例存到跨帧，留我方下一次攻击时叠加到最终伤害
-- Param2 = 比例；可选 Param3 = 上限
_T.DMG_BY_DODGE = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local ratio = tonumber(cfg.Param2) or 0
		local cap = tonumber(cfg.Param3) or 0 -- 可选上限
		return function(att, tar, sid, ctx)
			-- 这里的 att = 闪避者（防守方），tar = 本次攻击者
			local base = tonumber(ctx.curDamage) or 0
			if base <= 0 or ratio <= 0 then
				return
			end
			local inc = floor(base * ratio + 0.5)
			if cap > 0 and inc > cap then
				inc = cap
			end
			if inc <= 0 then
				return
			end
			BattleManager._carryDamage[att] = inc
			if piaoZi > 0 then
				ctx.pzQigong = piaoZi
			end
		end
	end,
}

-- 把跨帧携带伤害加到最终伤害
_T.DMG_CARRY = {
	fn = function(cfg)
		return function(att, tar, sid, ctx)
			local extra = BattleManager._carryDamage[att]
			if not extra or extra <= 0 then
				return
			end
			ctx.damage = (ctx.damage or 0) + extra
			-- 用一次就清
			BattleManager._carryDamage[att] = nil
		end
	end,
}

-- 对怪固定伤害加成（属性ID 165）
-- 每增加1点属性165，攻击怪物时伤害增加1点
-- 仅在攻击怪物时生效
-- Param1 = 属性ID（默认165）
-- Param2 = 伤害系数（默认1，即1点属性=1点伤害）
_T.DMG_PVE_FLAT_FN = {
	fn = function(cfg)
		local attrId = tonumber(cfg.Param1) or 165
		local ratio = tonumber(cfg.Param2) or 1
		return function(att, tar, sid, ctx)
			-- ctx.attPL: true=攻击者是玩家, false=攻击者是怪物
			-- 当玩家攻击怪物时生效，攻击者是怪物时不生效
			if not ctx.attPL then
				return  -- 攻击者是怪物，不触发
			end

			-- 获取攻击者的对怪伤害属性
			local pveAttr = abil(att, attrId) or 0
			if pveAttr <= 0 then
				return
			end

			-- 计算追加伤害
			local pveDamage = math.floor(pveAttr * ratio + 0.5)
			if pveDamage <= 0 then
				return
			end

			-- 追加固定伤害到最终伤害
			ctx.damage = (ctx.damage or 0) + pveDamage
		end
	end,
}


-- 狂意护体 全队怒气和防御 两段概率
_T.JOB_KYHT = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		local ragePct = tonumber(cfg.Param2) or 0
		local defProb = tonumber(cfg.Param3) or 0
		local defPct = tonumber(cfg.Param4) or 0
		local dur = tonumber(cfg.Param5) or 180
		return function(att, tar, sid, ctx)
			local hasPiaoZi = false
			-- 怒气提升
			if ragePct > 0 and rand() < prob then
				customFuncs.addRageAndCheckFull(tar, ragePct * 1000, CustomConst.EventObject)
				hasPiaoZi = true
			end
			-- 防御提升
			if defPct > 0 and rand() < defProb then
				setbuffabil(tar, 402, 106, "=", defPct, dur)
				hasPiaoZi = true
			end
			-- 如果任一效果生效，则播放飘字
			if hasPiaoZi and piaoZi > 0 then
				ctx.pzQigong = piaoZi
			end
		end
	end,
}

-- 无中生有
-- Param2=最终伤害加成
-- 禁止条件：若自身已带 狂意护体Buff 则不触发
_T.JOB_WZSY = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		local incPct = tonumber(cfg.Param2) or 0.20
		return function(att, tar, sid, ctx)
			if hasbuff(att, 402) then
				return
			end
			if rand() < prob then
				if piaoZi > 0 then
					ctx.pzQigong = piaoZi -- 播气功飘字
				end
				ctx.finalMul = (ctx.finalMul or 1) + incPct
			end
		end
	end,
}

--  概率追加目标防御 × pct
--  Param1    = 目标防御的属性 ID（默认 51）
--  Param2    = 伤害系数 pct   （0.20 = 20%）
--  （可选）Param3 = 额外概率加成，走static叠到 s.PROB.defDamage
_T.EXTRA_DEF_DMG = {
	fn = function(cfg)
		local prob = tonumber(cfg.BaseProb) or 0
		local defId = tonumber(cfg.Param1) or 51
		local pct = tonumber(cfg.Param2) or 0.20 -- 20 %
		return function(att, tar, sid, ctx)
			if not tar then
				return
			end -- 理论上必有目标
			-- 计算最终概率 = 基础 + 静态加成
			local s = PassiveManager._actorStatic[att] or {}
			local extraProb = (s.PROB and s.PROB.defDamage) or 0
			local p = prob + extraProb
			if rand() >= p then
				return
			end
			-- 读取目标防御并算追加伤害
			local defRaw = ctx.D(defId) or 0
			local extra = defRaw * pct
			-- 写入动态桶，公式末行相加
			ctx.damage = (ctx.damage or 0) + extra
		end
	end,
}

-- 怒意之吼 概率触发，最终伤害追加Param2
-- Param2 =伤害加成比例
_T.DMG_FINAL_PCT = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		local incPct = tonumber(cfg.Param2) or 0.20
		return function(att, tar, sid, ctx)
			if rand() < prob then
				if piaoZi > 0 then
					ctx.pzQigong = piaoZi -- 播气功飘字
				end
				ctx.finalMul = (ctx.finalMul or 0) + incPct
			end
		end
	end,
}

-- 吸收打击值回血
-- Param2=比例
_T.HP_BY_DMG = {
	fn = function(cfg)
		local piaoZi = tonumber(cfg.PiaoZi) or 0
		local prob = tonumber(cfg.BaseProb) or 0
		local ratio = tonumber(cfg.Param2) or 0
		if prob <= 0 or ratio <= 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			if not (ctx and ctx.damage and ctx.damage > 0) then
				return
			end
			if rand() >= prob then
				return
			end
			local inc = floor(ctx.damage * ratio + 0.5)
			if inc <= 0 then
				return
			end
			if piaoZi > 0 then
				ctx.pzQigong = piaoZi -- 播气功飘字
			end
			changeabil(att, 1, "+", inc)
			sendattackeffectnum(att, 2, inc) -- 特殊：吸血时单独播回血飘字
			sendmsg(att, 9, string.format("吸收打击值回血 +%d", inc))
		end
	end,
}

-- 无坚不摧
-- Param1=减防buffId Param2=防御属性id Param3=减防比例 Param4=秒数
_T.JOB_WJBC = {
	fn = function(cfg)
		local prob = tonumber(cfg.BaseProb) or 0
		local buffId = tonumber(cfg.Param1) or 0
		local attrId = tonumber(cfg.Param2) or 0
		local ratio = tonumber(cfg.Param3) or 0
		local dur = tonumber(cfg.Param4) or 10 --默认10秒
		if prob <= 0 or buffId <= 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			local s = PassiveManager._actorStatic[att] or {}
			local probBonus = (s.PROB and s.PROB.wjbc) or 0
			local ignoreAdd = (s.CUSTOM and s.CUSTOM.wjbc_ignore) or 0

			local finalProb = max(0, min(1, prob + probBonus))
			local finalRatio = max(0, ratio + ignoreAdd)
			if rand() >= finalProb then
				return
			end
			if hasbuff(tar, buffId) then
				setbufftime(tar, buffId, "=", dur)
				return
			end
			local defVal = ctx.D(attrId)
			local inc = floor(defVal * finalRatio + 0.5)
			if inc <= 0 then
				return
			end
			setbuffabil(tar, buffId, attrId, "-", inc, dur)
			sendmsg(att, 9, string.format("无坚不摧：-%d 防御 (%.1f%%)", inc, finalRatio * 100))
		end
	end,
}

---------------------------------------------------------------------
-- 释放技能效果模板
---------------------------------------------------------------------
-- buff结束时，减少超必杀触发概率
-- BuffIds 减少超必杀触发概率的 Buff 
-- Param2  减少概率值
_T.CK_DEL_CBS = {
	fn = function(cfg)
		local buffList = (cfg.BuffIds) or {}
		local buffTab = customFuncs.parseIdStr(buffList or "") or {}
		local buffValueList = (cfg.Param2) or {}
		local buffValueTab = customFuncs.parseIdStr(buffValueList or "") or {}
		if #buffTab <= 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			for i=1,#buffTab do
				local buffId = buffTab[i]
				if ctx.buffId == buffId then
					local s = PassiveManager._actorStatic[att] or {}
					if s.PROB and s.PROB.cbs then
						s.PROB.cbs = s.PROB.cbs - (tonumber(buffValueTab[i]) or 0)
						if s.PROB.cbs < 0 then
							s.PROB.cbs = 0
						end
					end
					break
				end
			end
		end
	end,
}

-- 刺客 金鸡独立 武功技能
_T.CK_JJDL = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 猛虎隐林 武功技能
_T.CK_MHYL = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local delhpPct = tonumber(cfg.Param3) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					local delhp = floor(ctx.damage * delhpPct / 100)
					delhp = delhp > 0 and delhp or 1
					setbuffcustdata(bobj, bid, "" .. delhp)
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 拨草寻蛇 武功技能
_T.CK_BCXS = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				addbuff(bobj, bid, buffdur)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}

-- 刺客 流云突刺 武功技能
_T.CK_LYTC = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 聚气凝神 武功技能
_T.CK_JQNS = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local delhpPct = tonumber(cfg.Param3) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					local delhp = floor(ctx.damage * delhpPct / 100)
					delhp = delhp > 0 and delhp or 1
					setbuffcustdata(bobj, bid, "" .. delhp)
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 御剑飞虹 武功技能
_T.CK_YJFH = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				addbuff(bobj, bid, buffdur)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}

-- 刺客 回风拂柳 武功技能
_T.CK_HFFL = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 半月穿云 武功技能
_T.CK_BYCY = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local delhpPct = tonumber(cfg.Param3) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					local delhp = floor(ctx.damage * delhpPct / 100)
					delhp = delhp > 0 and delhp or 1
					setbuffcustdata(bobj, bid, "" .. delhp)
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 雨打飞花 武功技能
_T.CK_YDFH = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				addbuff(bobj, bid, buffdur)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}

-- 刺客 白鹤亮翅 武功技能
_T.CK_BHLC = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 白鹤独立 武功技能
_T.CK_BHDL = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local delhpPct = tonumber(cfg.Param3) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					local delhp = floor(ctx.damage * delhpPct / 100)
					delhp = delhp > 0 and delhp or 1
					setbuffcustdata(bobj, bid, "" .. delhp)
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 冷鹤守梅 武功技能
_T.CK_LHSM = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				addbuff(bobj, bid, buffdur)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}

-- 刺客 风卷残云 武功技能
_T.CK_FJCY = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 风雨泰山 武功技能
_T.CK_FYTS = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local delhpPct = tonumber(cfg.Param3) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					local delhp = floor(ctx.damage * delhpPct / 100)
					delhp = delhp > 0 and delhp or 1
					setbuffcustdata(bobj, bid, "" .. delhp)
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 疾风落叶 武功技能
_T.CK_JFLY = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				addbuff(bobj, bid, buffdur)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}

-- 刺客 地动惊天 武功技能
_T.CK_DDJT = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 咫尺天涯 武功技能
_T.CK_ZZTY = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local delhpPct = tonumber(cfg.Param3) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					local delhp = floor(ctx.damage * delhpPct / 100)
					delhp = delhp > 0 and delhp or 1
					setbuffcustdata(bobj, bid, "" .. delhp)
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 遮天蔽日 武功技能
_T.CK_ZTBR = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				addbuff(bobj, bid, buffdur)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}

-- 刺客 碧海潮生 武功技能
_T.CK_BHCS = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end
		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 黯然消魂 武功技能
_T.CK_ARXH = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local delhpPct = tonumber(cfg.Param3) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				local bufftime = buffdur
				if s.BUFFDUR and s.BUFFDUR[bid] then
					bufftime = bufftime + s.BUFFDUR[bid] 
				end
				addbuff(bobj, bid, bufftime)
				if CustomConst.LisAbilAutoBuffs[bid] then
					local delhp = floor(ctx.damage * delhpPct / 100)
					delhp = delhp > 0 and delhp or 1
					setbuffcustdata(bobj, bid, "" .. delhp)
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}
-- 刺客 万流归宗 武功技能
_T.CK_WLGZ = {
	fn = function(cfg)
		local comboId = tonumber(cfg.Param1) or 0
		local buffdur = tonumber(cfg.Param5) or 1
		local buffIds = customFuncs.parseIdStr(cfg.Param2 or "") or {}
		local CBSProb = tonumber(cfg.Param3)/100 or 0
		local buffObjs = customFuncs.parseIdStr(cfg.Param4 or "") or {}
		if comboId <= 0 or #buffIds == 0 or #buffObjs == 0 then
			return function() end
		end

		return function(att, tar, sid, ctx)
			if not (ctx.damage and ctx.damage > 0) then
				return
			end
			local s = PassiveManager._actorStatic[att] or {}
			local freeProb = (s.PROB and s.PROB.combo_ignore) or 0
			local curCombo = currabil(att, comboId)
			if curCombo < 1 then
				return
			end
			-- 判断目标是否已存在 buff，存在则不再重复添加
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				if hasbuff(bobj, bid) then
					return
				end
			end
			s.PROB = s.PROB or {}
			s.PROB.cbs = (s.PROB.cbs or 0) + CBSProb -- 增加超必杀触发概率
			-- 判定免费放 rand() < freeProb 则免费，不消耗
			if rand() >= freeProb then
				changeabil(att, comboId, "-", 1)
			end
			-- 给目标上 buff 并写自定义数据
			for _, bid in ipairs(buffIds) do
				local bobj = buffObjs[_] == 1 and att or tar
				addbuff(bobj, bid, buffdur)
				if CustomConst.LisAbilAutoBuffs[bid] then
					setbuffcustdata(bobj, bid, floor(ctx.damage))
				end
			end
			s.RAGE.lock = false -- 解除怒气锁定
		end
	end,
}



------------------以下为师父传授技能模块

-- 师父传授技能威力倍率：Param1=变量名（如"U100"），Param2=倍率系数
_T.SKILL_MENTOR_TEACH = {
  fn = function(cfg)
      local varName = tostring(cfg.Param1 or "")
      local ratio   = tonumber(cfg.Param2) or 0  -- 每点变量换算成的倍率
      if varName == "" or ratio == 0 then
          return function() end
      end
      return function(att, tar, sid, ctx)
          local raw = gethumvar(att, varName)
          local varValue   = tonumber(raw) or 0
          if varValue <= 0 then return end
          -- 写入 ctx.powerRatio（DamageFn.xls 会读取）
          ctx.powerRatio = (ctx.powerRatio or 0) + varValue * ratio
      end
  end,
}


------------------以下为坐骑被动技能模块
--坐骑被动收割
_T.MOUNT_SG = {
    fn = function(cfg)
        -- print("加载被动收割")
        return function(att, tar, sid, ctx)
            local params = ""
            for i = 1,#mountHHlist do
                local item = mountHHlist[i]
                if tonumber(item.PassiveAttachCond) == tonumber(gethumvar(att,"U33")) then
                    params = item.Param2
                end
            end
            local attrs = {}
            for _, pair in ipairs(customFuncs.parseAttrList(params)) do
                attrs[pair.attrId] = pair.value
            end
            if currabil(tar,1) - ctx.damage <=0 then
                for i,v in ipairs(attrs) do
                    changeabil(att, tonumber(i), "+", math.floor(abil(att,tonumber(i))*v/10000))
                end
            end
        end
    end
}
--坐骑被动治愈
_T.MOUNT_ZY = {
    static = function(cfg, s)
        -- print("加载被动治愈")
        local params = {}
        for i = 1,#mountHHlist do
            local item = mountHHlist[i]
            if tonumber(item.PassiveAttachCond) == tonumber(cfg.Param1) then
                params = item
            end
        end
        local pct = tonumber(params.Param2) or 0
        if pct == 0 then return end
        local types = customFuncs.parseIdStr(params.Param1 or "")
        if #types == 0 then return end
        s.BUFF_BONUS = s.BUFF_BONUS or {}
        for _, buffType in ipairs(types) do
            local tbl = customFuncs.getBuffsByType(buffType)
            -- print('tbl',#tbl)
            if #tbl > 0 then
                for _, buffCfg in ipairs(tbl) do
                    local pid = buffCfg.ID
                    -- print('pid',pid)
                    s.BUFF_BONUS[pid] = (s.BUFF_BONUS[pid] or 0) + pct
                end
            end
        end
    end
}
--坐骑被动庇佑
_T.MOUNT_BY = {
    fn = function(cfg)
        -- print("坐骑被动庇佑")
        return function(att, tar, sid, ctx)
            local params = {}
            for i = 1,#mountHHlist do
                local item = mountHHlist[i]
                if tonumber(item.PassiveAttachCond) == tonumber(gethumvar(att,"U33")) then
                    params = item
                end
            end
            local gl = math.random(1,100)
            if gl <= tonumber(params.BaseProb) then
                -- sendmsg(att,9,'概率触发了庇佑')
                addbuff(att,tonumber(params.Param2))
            end
        end
    end
}
--坐骑被动神龙庇佑
_T.MOUNT_SLBY = {
    fn = function(cfg)
        -- print("加载神龙庇佑")
        return function(att, tar, sid, ctx)
            local params = {}
            for i = 1,#mountHHlist do
                local item = mountHHlist[i]
                if tonumber(item.PassiveAttachCond) == tonumber(gethumvar(att,"U33")) then
                    params = item
                end
            end
            local slbycd = gethumvar(att,"U47")
            local nowHp = currabil(att,1)
            local maxHp = abil(att,1)
            -- print("当前血量",nowHp,"最大血量",maxHp,"倒计时",slbycd)
            if (nowHp / maxHp) <= (tonumber(params.BaseProb)/100) and slbycd <= 0 then
                -- print(params.Param3,tonumber(params.Param4),tonumber(params.Param2))
                sendmsg(att,9,'低于'..tonumber(params.BaseProb)..'%血量触发神龙庇佑')
                sethumvar(att,VarCfg.U_SLBYCD, tonumber(params.Param3))
                addbuff(att,tonumber(params.Param2),tonumber(params.Param4))
                addtimerex(att, 47, 1000, params.Param3,"@ontimer47","")
            end
        end
    end
}
--坐骑被动影之舞
_T.MOUNT_YZW = {
    fn = function(cfg)
        return function(att, tar, sid, ctx)
            local params = {}
            for i = 1,#mountHHlist do
                local item = mountHHlist[i]
                if tonumber(item.PassiveAttachCond) == tonumber(gethumvar(att,"U33")) then
                    params = item
                end
            end
            local yzwcd = gethumvar(att,"U48")
            local nowHp = currabil(att,1)
            local maxHp = abil(att,1)
            if (nowHp / maxHp) <= (tonumber(params.BaseProb)/100) and yzwcd <= 0  then
                sendmsg(att,9,'低于'..tonumber(params.BaseProb)..'%血量触发影之舞')
                sethumvar(att,VarCfg.U_YZWCD,params.Param3)
                addbuff(att,tonumber(params.Param2),tonumber(params.Param4))
                addtimerex(att, 48, 1000, params.Param3,"@ontimer48","")
            end
        end
    end
}

------------------以下为武勋被动技能模块
-- 武勋   闪避身法
_T.WuXun_Skill1 = {
    fn = function(cfg)
        local prob     = tonumber(wuxun_skill_data[1].BaseProb) or 0
        local cd       = tonumber(wuxun_skill_data[1].CD) or 0
        local buffid   = tonumber(wuxun_skill_data[1].buffid) or 0
        local time    = tonumber(wuxun_skill_data[1].Param1) or 0
        local value     = tonumber(wuxun_skill_data[1].Param2) or 0
        return function(att, tar, sid, ctx)
            if not isplayer(tar) or math.random(1,100) > prob then return end
            local Damage_SkillCD_List = gethumvar(att,VarCfg.T_Damage_SkillCD_List) == "" and {} or json2tbl(gethumvar(att,VarCfg.T_Damage_SkillCD_List))
            local lastcd = Damage_SkillCD_List['WuXun_Skill1'] or 0
            if lastcd > os.time() then return end
            -- sendmsg(att,6,'触发了武勋【闪避身法】')
            -- dump(Damage_SkillCD_List,"Damage_SkillCD_List1")
            Damage_SkillCD_List['WuXun_Skill1'] = os.time()+cd
            -- dump(Damage_SkillCD_List,"Damage_SkillCD_List2")
            sethumvar(att,VarCfg.T_Damage_SkillCD_List,tbl2json(Damage_SkillCD_List))
            addbuff(att,buffid,time,1,att,{[127]=value*100})
        end
    end
}
-- 武勋   狂怒身法
_T.WuXun_Skill2 = {
    fn = function(cfg)
        local prob     = tonumber(wuxun_skill_data[2].BaseProb) or 0
        local cd       = tonumber(wuxun_skill_data[2].CD) or 0
        local buffid   = tonumber(wuxun_skill_data[2].buffid) or 0
        local time    = tonumber(wuxun_skill_data[2].Param1) or 0
        local value     = tonumber(wuxun_skill_data[2].Param2) or 0
        return function(att, tar, sid, ctx)
            if not isplayer(tar) or math.random(1,100) > prob then return end
            local Damage_SkillCD_List = gethumvar(att,VarCfg.T_Damage_SkillCD_List) == "" and {} or json2tbl(gethumvar(att,VarCfg.T_Damage_SkillCD_List))
            local lastcd = Damage_SkillCD_List['WuXun_Skill2'] or 0
            if lastcd > os.time() then return end
            -- sendmsg(att,6,'触发了武勋【狂怒身法】')
            Damage_SkillCD_List['WuXun_Skill2'] = os.time()+cd
            sethumvar(att,VarCfg.T_Damage_SkillCD_List,tbl2json(Damage_SkillCD_List))
            addbuff(att,buffid,time,1,att,{[128]=value*100})
        end
    end
}
-- 武勋   疾走身法
_T.WuXun_Skill3 = {
    fn = function(cfg)
        local prob     = tonumber(wuxun_skill_data[3].BaseProb) or 0
        local cd       = tonumber(wuxun_skill_data[3].CD) or 0
        local buffid   = tonumber(wuxun_skill_data[3].buffid) or 0
        local time    = tonumber(wuxun_skill_data[3].Param1) or 0
        local value     = tonumber(wuxun_skill_data[3].Param2) or 0
        return function(att, tar, sid, ctx)
            if not isplayer(tar) or math.random(1,100) > prob then return end
            local Damage_SkillCD_List = gethumvar(att,VarCfg.T_Damage_SkillCD_List) == "" and {} or json2tbl(gethumvar(att,VarCfg.T_Damage_SkillCD_List))
            local lastcd = Damage_SkillCD_List['WuXun_Skill3'] or 0
            if lastcd > os.time() then return end
            -- sendmsg(att,6,'触发了武勋【疾走身法】')
            Damage_SkillCD_List['WuXun_Skill3'] = os.time()+cd
            sethumvar(att,VarCfg.T_Damage_SkillCD_List,tbl2json(Damage_SkillCD_List))
            addbuff(att,buffid,time,1,att,{[9]=value*100})
        end
    end
}
-- 武勋   眩晕身法
_T.WuXun_Skill4 = {
    fn = function(cfg)
        local buffid   = tonumber(wuxun_skill_data[4].buffid) or 0
        local prob     = tonumber(wuxun_skill_data[4].BaseProb) or 0
        local cd       = tonumber(wuxun_skill_data[4].CD) or 0
        local time    = tonumber(wuxun_skill_data[4].Param1) or 0
        return function(att, tar, sid, ctx)
            if not isplayer(tar) or math.random(1,100) > prob then return end
            local Damage_SkillCD_List = gethumvar(att,VarCfg.T_Damage_SkillCD_List) == "" and {} or json2tbl(gethumvar(att,VarCfg.T_Damage_SkillCD_List))
            local lastcd = Damage_SkillCD_List['WuXun_Skill4'] or 0
            if lastcd > os.time() then return end
            -- sendmsg(att,6,'触发了武勋【眩晕身法】')
            -- sendmsg(tar,6,'你已被眩晕')
            Damage_SkillCD_List['WuXun_Skill4'] = os.time()+cd
            addbuff(tar,buffid,time)
        end
    end
}

---------------------------------------------------------------------
-- 一些自定义伤害计算  攻击前出发
---------------------------------------------------------------------
_T.ATTACK_BF_Damage = {
    fn = function(cfg)
        return function(att, tar, sid, ctx)

        end
    end
}
---------------------------------------------------------------------
-- 一些自定义伤害计算  攻击伤害后出发
---------------------------------------------------------------------
_T.ATTACK_Damage = {
    
    fn = function(cfg)
        return function(att, tar, sid, ctx)
            
        end
    end
}

return _T