local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCStallCreatePanel = class("PCStallCreatePanel", BaseFGUILayout)
--摆摊创建界面

function PCStallCreatePanel:Create()
	self.super.Create(self)
	self._ui = FGUI:ui_delegate(self.component)
	FGUIFunction:setWindowDrag(self.component, self._ui.bg)
	FGUI:setOnClickEvent(self._ui.btn_cancel, handler(self, self.Close))
	FGUI:setOnClickEvent(self._ui.btn_sure, handler(self, self.OnClickSureEvent))
end

function PCStallCreatePanel:Enter()
    self:RegisterEvent()
	local default_name = string.format(GET_STRING(90010020), SL:GetValue("USER_NAME"))
	FGUI:GTextField_setText(self._ui.textInput_name, default_name)
end

function PCStallCreatePanel:Exit()
	self:RemoveEvent()
	FGUI:Close("Stall", "StallMain")
end

function PCStallCreatePanel:Close()
	self.super.Close(self)
end

-- 确定
function PCStallCreatePanel:OnClickSureEvent()
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
function PCStallCreatePanel:OnCreateStallSuccess(data)
	self:Close()
	FGUIFunction:OpenStallProductUI(data)
end

function PCStallCreatePanel:OnCreateStallFail(errorType)
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


function PCStallCreatePanel:RegisterEvent()
   	SL:RegisterLUAEvent(LUA_EVENT_STALL_CREATE_SUCCESS, "PCStallCreatePanel", handler(self, self.OnCreateStallSuccess))
	SL:RegisterLUAEvent(LUA_EVENT_STALL_CREATE_FAIL, "PCStallCreatePanel", handler(self, self.OnCreateStallFail))
end

function PCStallCreatePanel:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_CREATE_SUCCESS, "PCStallCreatePanel")
	SL:UnRegisterLUAEvent(LUA_EVENT_STALL_CREATE_FAIL, "PCStallCreatePanel")
end

return PCStallCreatePanel