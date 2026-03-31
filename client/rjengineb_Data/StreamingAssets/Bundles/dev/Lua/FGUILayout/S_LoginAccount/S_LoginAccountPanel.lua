local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local S_LoginAccountPanel = class("S_LoginAccountPanel", BaseFGUILayout)

function S_LoginAccountPanel:Refresh()
	self._loginType = 1
	self:InitGUI()
end

function S_LoginAccountPanel:InitGUI()
	self._ui = FGUI:ui_delegate(self.component)
    self:FillCurrent()

	 --登录按钮
	FGUI:setOnClickEvent(self._ui["btn_confirm"], function ()
		self:RequestLogin()
	end)
end

function S_LoginAccountPanel:OnClose()
	self.super.Close(self)
end

function S_LoginAccountPanel:RequestLogin()
	if self._requestDelay then
		return false
	end
	self._requestDelay = true
	SL:ScheduleOnce(function()
		self._requestDelay = false
	end, 1)


	local username = FGUI:GTextField_getText(self._ui["TextField_account"])
	local password = FGUI:GTextField_getText(self._ui["TextField_password"])
	username = string.trim(username)
	password = string.trim(password)
	password = string.gsub(password, "\n", "")
	if string.len(username) <= 0 or string.len(password) <= 0 then
		print("没输入账号密码")
		return nil
	end

	self._loginType = 1
	if self._loginType == 1 then
		-- 登录
		local data = {}
		data.type = self._loginType
		data.username = username
		data.password = password
		global.S_LoginAccountManager:RequestLoginAdmin(data)
	else
	end
end

function S_LoginAccountPanel:FillCurrent()
    local manager = global.S_LoginAccountManager
    local username = manager:GetUsername()
    local password = manager:GetPassword()

    if username and password then
        FGUI:GTextField_setText(self._ui["TextField_account"], username)
        if CS.UnityEngine.Debug.isDebugBuild then
            FGUI:GTextField_setText(self._ui["TextField_password"], password)
        end
    end
end


return S_LoginAccountPanel