local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local StallCreatePanel = class("StallCreatePanel", BaseFGUILayout)
--摆摊创建界面

function StallCreatePanel:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:SetCloseUIWhenClickOutside(self)
	FGUI:setOnClickEvent(self._ui.btn_cancel, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_sure, handler(self, self.OnClickSureEvent))
end

function StallCreatePanel:Enter()
    self:RegisterEvent()
	local default_name = string.format(GET_STRING(90010020), SL:GetValue("USER_NAME"))
	FGUI:GTextField_setText(self._ui.textInput_name, default_name)
end

function StallCreatePanel:Exit()
	self:RemoveEvent()
	FGUI:Close("Stall", "StallMain")
end

function StallCreatePanel:Close()
	self.super.Close(self)
end

-- 确定
function StallCreatePanel:OnClickSureEvent()
	local range = SL:GetValue("GAME_DATA", "BaiTanRadius") or 1
	-- 附近是否已经有摊位了
	local viewNpcList = SL:GetValue("FIND_IN_VIEW_NPC_LIST") or {}
	for _,actorId in ipairs(viewNpcList) do
		local dis = SL:GetValue("TARGET_DISTANCE_FROM_ME", actorId)
		if dis < range then
			SL:ShowSystemTips(GET_STRING(90010027))
			return false
		end
	end
	local stall_name = FGUI:GTextField_getText(self._ui.textInput_name)
	if not stall_name or string.len(stall_name) == 0 then
		SL:ShowSystemTips(GET_STRING(90010015))
		return
	end

	local pos_x = SL:GetValue("X")
	local pos_y = SL:GetValue("Y")
	local pos_z = SL:GetValue("Z")
	SL:RequestCreateStall(stall_name, pos_x, pos_y, pos_z)
end

-- 摆摊创建成功
function StallCreatePanel:OnCreateStallSuccess(data)
	self:Close()
	FGUIFunction:OpenStallProductUI(data)
end

function StallCreatePanel:OnCreateStallFail(errorType)
	if errorType == -1 then
        -- 已有店铺
        SL:ShowSystemTips(GET_STRING(90010008))
    elseif errorType == -2 then
        SL:ShowSystemTips(GET_STRING(90010009))
	elseif errorType == -3 then
		SL:ShowSystemTips(GET_STRING(90010027))
	elseif errorType == -4 then
		SL:ShowSystemTips(GET_STRING(90010035))
	end
end


function StallCreatePanel:RegisterEvent()
   	SL:RegisterLUAEvent(LUA_EVENT_STALL_CREATE_SUCCESS, "StallCreatePanel", handler(self, self.OnCreateStallSuccess))
	SL:RegisterLUAEvent(LUA_EVENT_STALL_CREATE_FAIL, "StallCreatePanel", handler(self, self.OnCreateStallFail))
end

function StallCreatePanel:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_CREATE_SUCCESS, "StallCreatePanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_CREATE_FAIL, "StallCreatePanel")
end

return StallCreatePanel