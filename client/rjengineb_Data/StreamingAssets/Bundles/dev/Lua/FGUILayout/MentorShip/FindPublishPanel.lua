local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local Store = requireFGUILayout("MentorShip/MentorShipData")
local FindPublishPanel = class("FindPublishPanel", BaseFGUILayout)

local defaultcfg = {
	gender = { "保密", "男", "女" },
	online = { "全天", "白天", "夜间", "工作日", "周末" },
	map = { "保密", "长安城", "建邺城", "洛阳", "敦煌" },
	gexing = { "江湖新人", "彻夜不眠", "阳光少年", "气若幽兰", "玩世不恭" },
}

local function getChild(root, name)
	return FGUI:GetChild(root, name)
end
local function setLabelText(node, txt)
	FGUI:GTextField_setText(node, (txt == nil) and "" or tostring(txt))
end

function FindPublishPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
	self._store = Store.Get()
	self:InitData()
	self:InitEvent()
	self:InitPage()
	self:RegisterEvent()
	SL:RequestLookPlayer(tonumber(SL:GetValue("USER_ID")),nil,666)
end

function FindPublishPanel:Enter(data)
	self._mode = (data and tonumber(data.mode)) or 1

	self:LoadCache()

	if self._ui.list_left then
		FGUI:GList_itemRenderer(self._ui.list_left, handler(self, self.LeftRenderer))
		FGUI:GList_setNumItems(self._ui.list_left, #self._cats)
		FGUI:GList_setSelectedIndex(self._ui.list_left, self._leftIndex - 1)
		FGUI:GList_addOnClickItemEvent(self._ui.list_left, handler(self, self.OnClickLeftItem))
	end

	if self._ui.list_right then
		FGUI:GList_itemRenderer(self._ui.list_right, handler(self, self.RightRenderer))
		FGUI:GList_addOnClickItemEvent(self._ui.list_right, handler(self, self.OnClickRightItem))
	end

	self:RefreshRight()
end

function FindPublishPanel:Exit() 
	self:RemoveEvent()
end

function FindPublishPanel:InitData()
	self._cats = {
		{ title = "我的性别", key = "gender", options = defaultcfg.gender, default = "保密" },
		{ title = "在线时段", key = "online", options = defaultcfg.online, default = "全天" },
		{ title = "所在地区", key = "map", options = defaultcfg.map, default = "保密" },
		{ title = "个性签名", key = "gexing", options = defaultcfg.gexing, default = "保密" },
	}
	self._sel = { gender = "保密", online = "全天", map = "保密", gexing = "保密" }
	self._leftIndex = 1
	self._cacheKey = { [1] = "MENTOR_PUBLISH_CACHE_APP", [2] = "MENTOR_PUBLISH_CACHE_MASTER" }
	self.modelInfo = {}
end

function FindPublishPanel:InitEvent()
	if self._ui.btn_close then
		FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	end
	if self._ui.btn_publish then
		FGUI:setOnClickEvent(self._ui.btn_publish, handler(self, self.OnClickPublish))
	end
	if self._ui.btn_refresh then
		FGUI:setOnClickEvent(self._ui.btn_refresh, handler(self, self.OnClickRefresh))
	end
end

function FindPublishPanel:InitPage()
	if self._ui.list_left then
		FGUI:GList_setNumItems(self._ui.list_left, 0)
	end
	if self._ui.list_right then
		FGUI:GList_setNumItems(self._ui.list_right, 0)
	end
end

function FindPublishPanel:CacheKey()
	return self._cacheKey[self._mode]
end

function FindPublishPanel:LoadCache()
	local cache = SL:GetValue(self:CacheKey()) or {}
	for _, c in ipairs(self._cats) do
		local v = cache[c.key]
		if v ~= nil then
			self._sel[c.key] = v
		end
	end
end

function FindPublishPanel:SaveCache()
	local out = {}
	for _, c in ipairs(self._cats) do
		out[c.key] = self._sel[c.key]
	end
	SL:SetValue(self:CacheKey(), out)
end

-- 左侧
function FindPublishPanel:LeftRenderer(idx, item)
	local c = self._cats[idx + 1]
	setLabelText(getChild(item, "text_title"), c.title)
	setLabelText(getChild(item, "text_info"), tostring(self._sel[c.key] or c.default or ""))
end
function FindPublishPanel:OnClickLeftItem()
	self._leftIndex = (FGUI:GList_getSelectedIndex(self._ui.list_left) or 0) + 1
	self:RefreshRight()
end

-- 右侧
function FindPublishPanel:RightRenderer(idx, item)
	local c = self._cats[self._leftIndex] or { options = {} }
	local opt = (c.options or {})[idx + 1]
	setLabelText(getChild(item, "text_info"), tostring(opt or ""))
	local selected = tostring(self._sel[c.key]) == tostring(opt)
	FGUI:GButton_setSelected(item, selected)
end
function FindPublishPanel:OnClickRightItem()
	local idx = FGUI:GList_getSelectedIndex(self._ui.list_right)
	local c = self._cats[self._leftIndex] or { key = "", options = {} }
	local opt = (c.options or {})[(idx or 0) + 1]
	if opt == nil then
		return
	end
	self._sel[c.key] = opt
	FGUI:GList_setNumItems(self._ui.list_left, #self._cats)
	FGUI:GList_setSelectedIndex(self._ui.list_left, self._leftIndex - 1)
	self:RefreshRight()
end
function FindPublishPanel:RefreshRight()
	local c = self._cats[self._leftIndex] or { options = {} }
	FGUI:GList_setNumItems(self._ui.list_right, #(c.options or {}))
	local selIdx = 0
	for i, v in ipairs(c.options or {}) do
		if tostring(v) == tostring(self._sel[c.key]) then
			selIdx = i - 1
			break
		end
	end
	FGUI:GList_ScrollToView(self._ui.list_right, selIdx, true, true)
end

-- 发布
function FindPublishPanel:OnClickPublish(data)
	self:SaveCache()
	local payload = {
		role = (self._mode == 1) and "mentor" or "apprentice",
		gender = tostring(self._sel.gender or "保密"),
		online = tostring(self._sel.online or "全天"),
		map = tostring(self._sel.map or "保密"),
		sign = tostring(self._sel.gexing or "保密"),
		ts = os.time(),
		bodyId = self.modelInfo.bodyId,
		headId = self.modelInfo.headId,
        weaponId = self.modelInfo.rWeapon,
        wingId = self.modelInfo.wingId,
		faceId = self.modelInfo.faceId,
	}
	if self._mode == 1 then
		--成为师傅
		ssrMessage:sendmsgEx("MentorShip", "applyToMaster",payload)
	else
		--成为徒弟
		ssrMessage:sendmsgEx("MentorShip", "applyToApprentice",payload)
	end
	self._store:ShowTips("已发布")
	self:Close()
end

function FindPublishPanel:OnClickRefresh()
	self:LoadCache()
	FGUI:GList_setNumItems(self._ui.list_left, #self._cats)
	FGUI:GList_setSelectedIndex(self._ui.list_left, self._leftIndex - 1)
	self:RefreshRight()
end

function FindPublishPanel:getMyModeInfo()
	local lookSex = SL:GetValue("L.M.SEX")
    local lookJob = SL:GetValue("L.M.JOB")
    local classConfig = SL:GetValue("ROLE_CLASS_CONFIG", lookJob)
    if classConfig then 
		faceId = FGUIFunction:GetFaceIDBySex(lookSex,classConfig)
    end 
	local modelData = SL:GetValue("L.M.PLAYER_MODEL")
	self.modelInfo = {
		bodyId = modelData.bodyId,
		headId = modelData.headId,
        weaponId = modelData.rWeapon,
        wingId = modelData.wingId,
		faceId = faceId,
	}
	dump(self.modelInfo)
end

function FindPublishPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_RESPONSE_LOOK_PLAYER_INFO, "FindPublishPanel", handler(self, self.getMyModeInfo))    
end
function FindPublishPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_RESPONSE_LOOK_PLAYER_INFO, "FindPublishPanel")
end
return FindPublishPanel
