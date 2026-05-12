local MentorShipData = {}
MentorShipData.__index = MentorShipData

local __inst = nil
function MentorShipData.Get()
	if not __inst then
		__inst = setmetatable({
			hasRelation = false
		}, MentorShipData)
	end
	return __inst
end

-- 固定协议/操作码
MentorShipData.net = {
	REQ = 91020101, -- MA_REQ
	RSP = 91020102, -- MA_RSP
}
MentorShipData.rel = {
	REQ = 91029901, -- REL_REQ
	RSP = 91029902, -- REL_RSP
}

MentorShipData.op = {
	GET_STATUS = 1,
	GET_TASKS = 2,
	CLAIM = 3,
	GRADUATE = 4,

	PUBLISH = 98,
}

-- 关系操作
MentorShipData.rel_op = {
	SNAPSHOT = 1,
	SEARCH = 2,
	APPLY = 3,
	ACCEPT = 4,
	REJECT = 5,
	REMOVE = 6,
}

-- 关系类型
MentorShipData.rel_type = {
	MENTOR = 1, -- 师徒
	-- 如需：MARRIAGE=2, ENEMY=3, BLACK=4
}

----------------------------------------------------------------
function MentorShipData:NetSend(p1, p2, p3, str)
	SL:SendNetMsg(self.net.REQ, p1 or 0, p2 or 0, p3 or 0, str)
end

function MentorShipData:NetSendREL(p1, p2, p3, str)
	SL:SendNetMsg(self.rel.REQ, p1 or 0, p2 or 0, p3 or 0, str)
end

----------------------------------------------------------------
-- 列表/申请
----------------------------------------------------------------
function MentorShipData:RequestFindMentorList(opts)
	--师傅列表
	local searchAll = opts or "*"
	ssrMessage:sendmsgEx("MentorShip", "getMasterList",searchAll)
end

function MentorShipData:RequestFindApprenticeList(opts)
	--徒弟列表
	local searchAll = opts or "*"
	ssrMessage:sendmsgEx("MentorShip", "getApprenticeList",searchAll)
end

function MentorShipData:ApplyMentor(data)
	--申请拜师
	ssrMessage:sendmsgEx("MentorShip", "ApplyMentor",data)
end

function MentorShipData:ApplyApprentice(data)
	--申请收徒
	ssrMessage:sendmsgEx("MentorShip", "ApplyApprentice",data)
end

function MentorShipData:GetApplyList(mode)
	--申请列表  1 成为我的徒弟是申请列表 2 成为我的师傅的列表
	ssrMessage:sendmsgEx("MentorShip", "GetApplyList",mode)
end
--我的师徒关系
function MentorShipData:GetMyRelation(fromPanel)
	ssrMessage:sendmsgEx("MentorShip", "GetMyRelation",fromPanel)
end
--我的所有技能id
function MentorShipData:getMySkillList()
	ssrMessage:sendmsgEx("MentorShip", "getMySkillList")
end
-- 师徒玩法
function MentorShipData:ReqStatus()
	self:NetSend(self.op.GET_STATUS, 0, 0, nil)
end
function MentorShipData:ReqTasks(partnerId)
	self:NetSend(self.op.GET_TASKS, tonumber(partnerId) or 0, 0, nil)
end
function MentorShipData:Claim(partnerId, taskId, tier)
	local opt = self:JsonEncode({ tier = tostring(tier or "normal") })
	self:NetSend(self.op.CLAIM, tonumber(partnerId) or 0, tonumber(taskId) or 0, opt)
end
function MentorShipData:Graduate(partnerId)
	self:NetSend(self.op.GRADUATE, tonumber(partnerId) or 0, 0, nil)
end

-- 事件派发
function MentorShipData:FireFindMentorUpdate(payload)
	SL:onLUAEvent(self.events.FindMentorUpdate, payload)
end
function MentorShipData:FireFindApprenticeUpdate(payload)
	SL:onLUAEvent(self.events.findApprenticeUpdate, payload)
end

----------------------------------------------------------------
-- 通用
----------------------------------------------------------------
function MentorShipData:ShowTips(msg)
	SL:ShowSystemTips(tostring(msg or ""))
end
function MentorShipData:JsonDecode(s)
	return SL:JsonDecode(s)
end
function MentorShipData:JsonEncode(t)
	return SL:JsonEncode(t or {})
end

return MentorShipData
