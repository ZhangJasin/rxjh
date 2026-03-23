local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local GuildApplySetting = class("GuildApplySetting", BaseFGUILayout)

function GuildApplySetting:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:SetCloseUIWhenClickOutside(self)
	self._curLimitLevel = 1
	self._autoLevel = nil --自动申请需要的等级
	FGUI:setOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.mask, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_sub, handler(self, self.SubLevelLimit))
	FGUI:setOnClickEvent(self._ui.btn_add, handler(self, self.AddLevelLimit))
	FGUI:setOnClickEvent(self._ui.btn_yes, handler(self, self.OnClickYesButton))
	FGUI:GTextInput_addOnChanged(self._ui.textInput_level, handler(self, self.OnLevelInputChange))
end

function GuildApplySetting:Enter()
    self:RegisterEvent()
	self._curLimitLevel = SL:GetValue("GUILD_JOIN_LEVEL_LIMIT")
	FGUI:GRichTextField_setText(self._ui.textInput_level, tostring(self._curLimitLevel))
	self:RefreshAutoApproveDisplay()
end

function GuildApplySetting:Exit()
	self:RemoveEvent()
end

function GuildApplySetting:Close()
	self.super.Close(self)
end

function GuildApplySetting:OnLevelInputChange()
	local input = tonumber(FGUI:GTextField_getText(self._ui.textInput_level))
	if input then
		self._curLimitLevel  = input
	else
		self._curLimitLevel = 1
		FGUI:GTextInput_setText(self._ui.textInput_level, self._curLimitLevel)
	end
end

-- 点击确认
function GuildApplySetting:OnClickYesButton(eventData)
    FGUI:delayTouchEnabled(eventData.sender, FGUIDefine.DelayClickTime)

	-- 自动申请设置
	local isAutoApprove = FGUI:GButton_getSelected(self._ui.btn_auto_approve)
	local curAutoApprove = SL:GetValue("GUILD_AUTO_APPROVE_APPLY")
	-- 等级需求设置
	local levelLimit = SL:GetValue("GUILD_JOIN_LEVEL_LIMIT")
	if isAutoApprove ~= curAutoApprove or levelLimit ~= self._curLimitLevel then
		if isAutoApprove then
			SL:RequestGuildApproveAutoApply(self._curLimitLevel)
		else
			SL:RequestGuildRejectAutoApply(self._curLimitLevel)
		end
	end
	self:Close()
end

function GuildApplySetting:AddLevelLimit()
	self._curLimitLevel = self._curLimitLevel + 1
	FGUI:GRichTextField_setText(self._ui.textInput_level, tostring(self._curLimitLevel))
end

function GuildApplySetting:SubLevelLimit()
	self._curLimitLevel = self._curLimitLevel - 1
	if self._curLimitLevel < 1 then
		self._curLimitLevel = 1
	end

	FGUI:GRichTextField_setText(self._ui.textInput_level, tostring(self._curLimitLevel))
end

-- 刷新自动申请显示
function GuildApplySetting:RefreshAutoApproveDisplay()
	local isAutoApprove = SL:GetValue("GUILD_AUTO_APPROVE_APPLY")
	FGUI:GButton_setSelected(self._ui.btn_auto_approve, isAutoApprove)
end


function GuildApplySetting:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_GUILD_AUTO_JOIN, "GuildApplySetting", handler(self, self.RefreshAutoApproveDisplay))
end

function GuildApplySetting:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_GUILD_AUTO_JOIN, "GuildApplySetting")
end

return GuildApplySetting