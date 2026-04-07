local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local LoginRoleRestore = class("LoginRoleRestore", BaseFGUILayout)

local roleConfig = requireGameConfig("Class")
function LoginRoleRestore:Create()
    if SL:GetValue("IS_PC_OPER_MODE") then
        self._packageName = "LoginRole_pc"
    else
        self._packageName = "LoginRole"
    end
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:SetCloseUIWhenClickOutside(self)
	self:InitData()
	self:InitEvent()
end

function LoginRoleRestore:InitData()
    self._selectIndex = -1
end

function LoginRoleRestore:InitEvent()
    FGUI:addOnClickEvent(self._ui.btn_close, handler(self, self.Close))
	FGUI:GList_itemRenderer(self._ui.role_list, handler(self, self.RoleItemRenderer))
    FGUI:GList_addOnClickItemEvent(self._ui.role_list, handler(self, self.OnClickRoleItem))
    FGUI:addOnClickEvent(self._ui.restore_btn, handler(self, self.OnClickRestoreBtn))
end

function LoginRoleRestore:Enter(userdata)
    self:RegisterEvent()
    self._selectIndex = -1
    local list = self._ui.role_list
	self._rolesData = SL:GetValue("LOGIN_RESTORE_DATA")
    FGUI:GList_setNumItems(list, 0)
    FGUI:GList_setNumItems(list, #self._rolesData)
end

function LoginRoleRestore:RoleItemRenderer(index, item)
	FGUI:SetIntData(item, index)
	local data = self._rolesData[index + 1]
	local playerFram = FGUI:GetChild(item,"playerFram")
	local playerName = FGUI:GetChild(item,"playerName")
	local job = FGUI:GetChild(item,"job")
	local playerLevel = FGUI:GetChild(item,"playerLevel")
	FGUI:GTextField_setText(playerName, data.uname)
	FGUI:GTextField_setText(playerLevel, data.ulevel)

	local avatarJob = data.ujob or 0
	local avatarSex = data.usex or data.sex or 0
	local avatarPath = FGUIFunction:GetAvatarUrl(0, avatarJob, avatarSex)

	-- 设置头像
	local imageHead = FGUI:GetChild(playerFram, "Image_head")
	if imageHead then
		FGUI:GLoader_setFill(imageHead, 1)
		FGUI:GLoader_setUrl(imageHead, avatarPath, nil, true)
	end

	local classConfig = roleConfig[avatarJob]
	if classConfig then
		FGUI:GTextField_setText(job, classConfig.ClassName)
	end
end

function LoginRoleRestore:OnClickRoleItem(context)
    self._selectIndex = FGUI:GetIntData(context.data)
end

function LoginRoleRestore:OnClickRestoreBtn()
    if self._selectIndex < 0 then
        return
    end
	local data = self._rolesData[self._selectIndex + 1]
    if data then
        SL:RequestRestoreRole(data)
        self:Close()
    end
end

function LoginRoleRestore:Exit()
    self:RemoveEvent()
end

function LoginRoleRestore:OnClose()
    self.super.Close(self)
end

function LoginRoleRestore:Destroy()
end

function LoginRoleRestore:RegisterEvent()
    -- SL:RegisterLUAEvent(LUA_EVENT_LOGIN_ROLE_RESTORE_REFRESH, "LoginRoleRestore", handler(self, self.OnRestoreRoleInfoRefresh))
end

function LoginRoleRestore:RemoveEvent()
    -- SL:UnRegisterLUAEvent(LUA_EVENT_LOGIN_ROLE_RESTORE_REFRESH, "LoginRoleRestore")
end

return LoginRoleRestore