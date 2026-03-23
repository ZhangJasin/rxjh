local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCGuildCreatePopup = class("PCGuildCreatePopup", BaseFGUILayout)
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")

function PCGuildCreatePopup:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)
	self._costs = {}

	-- 关闭
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.mask, handler(self, self.Close))
	-- 取消
	FGUI:setOnClickEvent(self._ui.btn_cancel, handler(self, self.Close))
	-- 创建
	FGUI:setOnClickEvent(self._ui.btn_create, handler(self, self.OnClickCreateGuildEvent))
	FGUI:GList_itemRenderer(self._ui.list_condition, handler(self, self.OnConditionItemRenderer))
end

function PCGuildCreatePopup:Enter()
	self._isValid = true
    self:RegisterEvent()
	self._costs = SL:GetValue("GUILD_CREATE_COST")
	FGUI:GList_setNumItems(self._ui.list_condition, #self._costs)
	local defaultTips = SL:GetValue("GAME_DATA", "SectPrecautions") or ""
	FGUI:GTextField_setText(self._ui.input_notice, defaultTips)
	FGUI:GTextField_setText(self._ui.input_name, "")
	-- 和谐
	self:InitM2RandGuildName()
end

function PCGuildCreatePopup:Exit()
	self:RemoveEvent()
	self._isValid = false
end

function PCGuildCreatePopup:Close()
	self.super.Close(self)
end

function PCGuildCreatePopup:InitM2RandGuildName()
	-- 请求随机行会名
	if SL:GetValue("M2_FORBID_EDIT", false) then
		print("InitM2RandGuildName", SL:GetValue("M2_FORBID_EDIT", false) )
		SL:RequestRandGuildName(function(guildName)
			if self._isValid then
				FGUI:GTextField_setText(self._ui.input_name, guildName)
			end
		end)
	end
end

-- 创建行会点击事件
function PCGuildCreatePopup:OnClickCreateGuildEvent(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	-- 判断是否满足条件
	local canCreate = true
	local itemId = nil
	for _,v in ipairs(self._costs) do
		local ownerCount =  SL:GetValue("ITEM_COUNT", v.id)
		if ownerCount < v.num then
			canCreate = false
			itemId = v.id
			break
		end
	end

	if canCreate then
		local inputName = FGUI:GTextField_getText(self._ui.input_name)
		inputName = string.trim(inputName)
		local defaultAnnounce = SL:GetValue("GAME_DATA", "announce") or ""
		SL:RequestGuildCreate(inputName, defaultAnnounce)
	else
		local itemData = SL:GetValue("ITEM_DATA", itemId)
		if not itemData then
			return
		end
		SL:ShowSystemTips(string.format(GET_STRING(10003001), itemData.Name))
	end
end

-- 创建行会响应
function PCGuildCreatePopup:OnGuildCreateRes()
    -- 关闭行会创建界面
	FGUI:Close("Guild_pc", "PCGuildJoinList")
    -- 显示行会主界面
    FGUIFunction:OpenGuildMainFrameUI(1)
	self:Close()
end

-- 创建条件列表刷新
function PCGuildCreatePopup:OnConditionItemRenderer(idx, item)
	local cost = self._costs[idx + 1]
	local itemData = SL:GetValue("ITEM_DATA", cost.id)
	if not itemData then
		FGUI:setVisible(item, false)
		return
	end

	FGUI:GLabel_setTitle(item, SL:GetThousandSepString(cost.num))
	local color = SL:GetValue("ITEM_COUNT", cost.id) >= cost.num and "#ffffff" or "#FF0000"
	FGUI:GLabel_setTitleColor(item, color)
	local icon_item = FGUI:GetChild(item, "icon_item")
	local item_show = ItemShow.new(icon_item,itemData)
	item_show:UpdateItemClick()
	item_show:UpdateCountVisible(false)
	item_show:UpdateGradeIsShow(false)
end


function PCGuildCreatePopup:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_CREATE, "PCGuildCreatePopup", handler(self, self.OnGuildCreateRes))
end

function PCGuildCreatePopup:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_CREATE, "PCGuildCreatePopup")
end

return PCGuildCreatePopup