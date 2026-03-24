local LoginRoleBase = require("FGUILayout/LoginRole/LoginRoleBase")
local LoginRoleSelect = class("LoginRoleSelect", LoginRoleBase)

-- 入场
local ANIM_IN			= 1
-- 离场
local ANIM_OUT			= 2
-- 入场idle
local ANIM_IN_IDLE		= 3
-- 离场idle
local ANIM_OUT_IDLE		= 4

function LoginRoleSelect:Create()
	self.super.Create(self)
    if SL:GetValue("IS_PC_OPER_MODE") then
        self._packageName = "LoginRole_pc"
    else
        self._packageName = "LoginRole"
    end
	self._ui = FGUI:ui_delegate(self.component)
	self.handler_roleListRenderer = handler(self, self.OnRoleListRenderer)
	self.handler_roleListClickEvent = handler(self, self.OnClickRoleListEvent)
	self.handler_onPlayAnimationComplate = handler(self, self.OnPlayAnimationComplete)

	-- 服务器名
	FGUI:GTextField_setText(self._ui.text_server_name, SL:GetValue("SERVER_NAME"))
	-- 角色列表
    local list = self._ui["list_role"]
	FGUI:GList_itemRenderer(list, self.handler_roleListRenderer)
	FGUI:GList_addOnClickItemEvent(list, self.handler_roleListClickEvent)	

	-- 返回
	FGUI:setOnClickEvent(self._ui.btn_back, function ()
		local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
		if  shiwan and tonumber(shiwan) == 1 then
			return
		end
		self:Close()
		SL:RestartGame()
	end)

	-- 开始游戏
	FGUI:setOnClickEvent(self._ui.btn_enter, function ()
		--试玩 自动进入游戏
		local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
		if  shiwan and tonumber(shiwan) == 1 then
			SL:RequestEnterGame()
			return
		end
		if not self._index or self._index < 1 or not self._rolesData or not next(self._rolesData) then
			self:OpenCreateRolePanel()
		else
			local roles = SL:GetValue("LOGIN_DATA") or {}
			if roles and roles[self._index] and ( roles[self._index].LockChar == 1 or roles[self._index].LockChar == 3) then
				SL:ShowSystemTips(GET_STRING(10001037))--角色已被冻结
			else
				SL:RequestEnterGame()
			end
		end
	end)

	FGUI:setOnClickEvent(self._ui.btn_delete_role, handler(self, self.DeleteRole))

	-- 取回角色
	if self._ui.btn_retrieve_role then
			FGUI:setOnClickEvent(self._ui.btn_retrieve_role, function ()
			local roles = SL:GetValue("LOGIN_DATA") or {}
			if  roles[self._index] and ( roles[self._index].LockChar == 1 or roles[self._index].LockChar == 3) then
				--当前如果被锁 直接取回
				local roleid = tostring(SL:GetValue("USER_ID"))
				local uid    = tostring(SL:GetValue("UID"))
				local gameid = tostring(SL:GetValue("GAME_ID"))
				SL:ShowBoxBackToView(roleid, uid, gameid)
			end
		end)
	end
	
	--试玩 自动进入游戏
	SL:ScheduleOnce(function()
		local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
		if  shiwan and tonumber(shiwan) == 1 then
			SL:RequestEnterGame()
			return
		end
	end, 1)

end

function LoginRoleSelect:Enter()
	self.super.Enter(self)
	self:RegisterEvent()
	LoginRoleSelect:InitSceneCamera()
	LoginRoleBase.FitstEntry = false
	self._removeFlag = false
	self._index = nil
	self._rolesData = {}
	self._models = {}
	self._playAnimTimer = {}
	self._playAnimationQueue = Queue.new()
	self:InitRoles()
end

function LoginRoleSelect:InitSceneCamera()
	LoginScene.SetRolePosition(0, 0.07, -9.71)
	LoginScene.SetCamerPosition(0, 0, -9.71)
	SL:InitCreateSceneCamera()
end

function LoginRoleSelect:Exit()
	self.super.Exit(self)
	self:UnRegisterEvent()
	if not self._models then
		return
	end
	for _, model in pairs(self._models) do
		SL:ClearCreateSceneModel(model)
	end
	self._models 				= nil
	self._playAnimationQueue 	= nil
	self._removeFlag			= false
	for _, timer in pairs(self._playAnimTimer) do
		SL:UnSchedule(timer)
	end
end

function LoginRoleSelect:InitRoles()
	-- 初始化角色选择
	local list = self._ui["list_role"]
	self._rolesData = SL:GetValue("LOGIN_DATA")
	-- 加载模型
	self:LoadRoleModes(self._index)
	self._index = -1
	local myRole = SL:GetValue("LOGIN_SELECTED_ROLE")
	FGUI:GList_setNumItems(list, #self._rolesData >=4 and 4 or #self._rolesData + 1)
	if myRole then
		FGUI:GList_setSelectedIndex(list, myRole.index - 1)
		self:SelectRole(myRole.index, true)
	elseif #self._rolesData > 0 then
		FGUI:GList_setSelectedIndex(list, 0)
		self:SelectRole(1, true)
	end
	self._removeFlag = false
	
	self:LoadRoleData()
end

function LoginRoleSelect:LoadRoleModes(nowSelect)
	if self._removeFlag then
		for _, model in pairs(self._models) do
			SL:ClearCreateSceneModel(model)
		end
		self._models 				= {}
		for _, timer in pairs(self._playAnimTimer) do
			SL:UnSchedule(timer)
		end
		self._playAnimTimer = {}
	end
	
	for idx, data in pairs(self._rolesData) do
		local model = self:ShowRoleModel(idx, data)
		if model then
			self._models[idx] = model
		end
	end
end

-- 角色列表显示控制
function LoginRoleSelect:OnRoleListRenderer(idx, item)
	local data = self._rolesData[idx + 1]
	local loaderFill = FGUI:GetChild(item, "component")
	local componentFill = FGUI:GLoader_getComponent(loaderFill)
	-- 头像	
	local iconAvatar = FGUI:GetChild(componentFill, "icon_avatar")
	iconAvatar = FGUI:GetChild(iconAvatar, "icon")
	-- 职业图标
	local iconJob = FGUI:GetChild(componentFill, "icon_job")
	FGUI:setVisible(iconJob, data ~= nil)
	-- 名称
	local textName = FGUI:GetChild(componentFill, "text_name")
	FGUI:setVisible(textName, data ~= nil)
	-- 等级
	local textLevel = FGUI:GetChild(componentFill, "text_level")
	FGUI:setVisible(textLevel, data ~= nil)
	-- 创建文本
	local textCreate = FGUI:GetChild(componentFill, "text_create")
	FGUI:setVisible(textCreate, data == nil)

	if data then			
		local iconPath = FGUIFunction:GetAvatarUrl(data.customFeathure.avatar, data.job, data.sex)
		FGUI:GLoader_setFill(iconAvatar, 1)
		FGUI:GLoader_setUrl(iconAvatar, iconPath, nil, true)		
		FGUI:GLoader_setUrl(iconJob, string.format(self.jobSelectPath, data.job))
		FGUI:GTextField_setText(textName, data.name)	
		FGUI:GTextField_setText(textLevel, string.format("LV.%s", data.level))
	else
		FGUI:GLoader_setFill(iconAvatar, 0)
		FGUI:GLoader_setUrl(iconAvatar, "ui://"..self._packageName.."/icon_add")	
	end
end

-- 点击角色列表事件
function LoginRoleSelect:OnClickRoleListEvent(context)
	local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
	if  shiwan and tonumber(shiwan) == 1 then
		return
	end
	local selectIdx = FGUI:GList_getSelectedIndex(self._ui["list_role"])
	local roleIdx = selectIdx + 1
	if roleIdx > #self._rolesData then
		self:OpenCreateRolePanel()
	else
		self:SelectRole(selectIdx + 1)
	end	
end

function LoginRoleSelect:SelectRole(index, isInit)
	if self._index == index then
		return false
	end
	
	local roles = SL:GetValue("LOGIN_DATA") or {}
	local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
	if  shiwan and tonumber(shiwan) == 1 then
		index = 1
	else
		if  roles[index] and ( roles[index].LockChar == 1 or roles[index].LockChar == 3) then
			if not isInit then
				SL:ShowSystemTips(GET_STRING(10001037))--角色已被冻结
			end
		end
	end
	local lastSelect = self._index
	self:SetItemSelectVisible(lastSelect, false)
	self:SetItemSelectVisible(index, true)
	self._index = index
	SL:SetValue("LOGIN_SELECTED_ROLE", roles[index])
	if not global.OtherTradingBank then
		if  roles[index] and ( roles[index].LockChar == 1 or roles[index].LockChar == 3) then
			if self._ui.btn_retrieve_role and self.lebelBox then
				FGUI:setVisible(self._ui.btn_retrieve_role,true)
				FGUI:setVisible(self.lebelBox,true)
			end
		else
			if self._ui.btn_retrieve_role and self.lebelBox then
				FGUI:setVisible(self._ui.btn_retrieve_role,false)
				FGUI:setVisible(self.lebelBox,false)
			end
		end
	end
	
	self._playAnimationQueue:clear()
	if isInit then
		self._playAnimationQueue:push({index = index, isIn = true})
		return
	end

	if lastSelect >=0 then
		self:PlayAnimation(lastSelect, ANIM_OUT)
		self._playAnimationQueue:push({index = index, isIn = true})
	else
		self:PlayAnimation(index, ANIM_IN)
	end
end

function LoginRoleSelect:SetItemSelectVisible(idx, visible)
	if not idx or idx < 0 then
		return
	end
	local list = self._ui["list_role"]
	local childIndex = FGUI:GList_itemIndexToChildIndex(list, idx - 1)
	local item = FGUI:GetChildAt(list, childIndex)
	if not item then
		return
	end
	local loaderFill = FGUI:GetChild(item, "component")
	local componentFill = FGUI:GLoader_getComponent(loaderFill)
	local icon_select_effect = FGUI:GetChild(componentFill, "icon_select_effect")
	FGUI:setVisible(icon_select_effect, visible)

	local controller = FGUI:getController(item, "button")
	if visible then
		if controller.selectedPage ~= 'down' then
			controller.selectedPage = 'down'
		end
	else
		if controller.selectedPage ~= 'up' then
			controller.selectedPage = 'up'
		end
	end
end

function LoginRoleSelect:LoadRoleData()
    local loadFunc = function ()
        local loginProxy = global.Facade:retrieveProxy(global.ProxyTable.LoginProxy)
        local roleData = loginProxy:GetRoles()

		local screenW = SL:GetValue("SCREEN_WIDTH")
		local screenH = SL:GetValue("SCREEN_HEIGHT")
		local height = -screenH/2+80
		if global.OtherTradingBank then
			for i, v in ipairs(roleData) do
				local comp = FGUI:CreateObject(self._ui["Node_lock"], self._packageName, "RoleLockText")
				FGUI:setPosition(comp, 0, height)
				local label = FGUI:GetChild(comp, "text_lock1")
				FGUI:GTextInput_setText(label, "")
				local Widgetheight = self:CreateShowWidget(v, i, label)
				height = height + Widgetheight
			end
		else
			local comp = FGUI:CreateObject(self._ui["Node_lock"], self._packageName, "RoleLockText")
			FGUI:setPosition(comp, 0, height)
			self.lebelBox = FGUI:GetChild(comp, "text_lock1")
			FGUI:setVisible(self.lebelBox,false)
			FGUI:GTextInput_setText(self.lebelBox, "")
			FGUI:GTextInput_setText(self.lebelBox, string.format("%s", GET_STRING(600000810)))
			if self._ui.btn_retrieve_role then
				FGUI:setPosition(self._ui.btn_retrieve_role, screenW/2-80, 160)
			end
			local roles = SL:GetValue("LOGIN_DATA") or {}
			if  roles[self._index] and ( roles[self._index].LockChar == 1 or roles[self._index].LockChar == 3) then
				if self._ui.btn_retrieve_role and self.lebelBox then
					FGUI:setVisible(self._ui.btn_retrieve_role,true)
					FGUI:setVisible(self.lebelBox,true)
				end
			end
		end
		
    end
    loadFunc()
end

function LoginRoleSelect:CreateShowWidget(RoleData, index, textTarget)
	local height = 0
    if RoleData.LockChar and ( RoleData.LockChar == 1 or  RoleData.LockChar == 3 ) then
		dump("锁定")
		height = 50
		local descID = 600000850
		FGUI:GTextInput_setText(textTarget, string.format("%s%s", GET_STRING(600000799 + index), GET_STRING(descID)))
		SL:ShowBackToView()
    elseif RoleData.newChar and RoleData.newChar == 1 then
		height = 50
		FGUI:GTextInput_setText(textTarget, string.format("%s%s", GET_STRING(600000799 + index), GET_STRING(600000809)))
    end
	return height
end

function LoginRoleSelect:ShowRoleModel(index, data)
    local classConfig = SL:GetValue("ROLE_CLASS_CONFIG", data.job)
    local roleInfo = SL:GetValue("LOGIN_DATA")[data.index]
	local roleFeature = SL:GetValue("LOGIN_ROLE_FEATURE", roleInfo)
    if roleFeature then
	
        -- 如果id为默认值0或nil，则尝试用初始模型
        if classConfig then
            roleFeature.bodyId = roleFeature.bodyId or classConfig.InitModel[1]
            roleFeature.headId = roleFeature.headId or classConfig.InitModel[2]
			if not roleFeature.faceId then
				local sex = data.sex or 0
				roleFeature.faceId =  FGUIFunction:GetFaceIDBySex(sex,classConfig)
			end
            -- roleFeature.rWeapon = roleFeature.rWeapon or classConfig.WeaponID
			-- if data.job == global.MMO.ACTOR_PLAYER_JOB_3 then
			-- 	roleFeature.lWeapon = roleFeature.rWeapon
			-- end
        end
		
        local modelCallback = function()
			self:PlayAnimation(index, ANIM_OUT_IDLE, 0)
        end
		local onClickModel = function()
			self:SelectRole(index)
		end
        roleFeature.sex = data.sex
        roleFeature.job = data.job
		roleFeature.rWeapon = nil
		roleFeature.lWeapon = nil
        local model = SL:CreateSceneModel(roleFeature, modelCallback, onClickModel, "LoginRoleSelect_"..tostring(index))
		
		SL:SetCreateSceneModelTransform(model)
		return model
	end
	return nil
end

function LoginRoleSelect:PlayAnimation(idx, an, fadeLength)
    if idx < 1 then
        return
    end
    local timer = self._playAnimTimer[an]
    if timer then
        SL:UnSchedule(timer)
		self._playAnimTimer[an] = nil
    end
    local animLength = -1
    if an == ANIM_IN then
        animLength = SL:CreateSceneModePlayInAnim(self._models[idx], idx, fadeLength)
    elseif an == ANIM_OUT then
        animLength = SL:CreateSceneModePlayOutAnim(self._models[idx], idx, fadeLength)
		animLength = 0.01
	elseif an == ANIM_IN_IDLE then
		animLength = SL:CreateSceneModePlayInIdleAnim(self._models[idx], idx, fadeLength)
		animLength = -1
    elseif an == ANIM_OUT_IDLE then
        animLength = SL:CreateSceneModePlayOutIdleAnim(self._models[idx], idx, fadeLength)
		animLength = 0.3
    end
	if animLength and animLength > 0 then
		timer = SL:ScheduleOnce(function ()
			self._playAnimTimer[an] = nil
			self.handler_onPlayAnimationComplate()
		end, animLength)
		self._playAnimTimer[an] = timer
	end
end

function LoginRoleSelect:OnPlayAnimationComplete()
	if self._playAnimationQueue:size() > 0 then
		local info = self._playAnimationQueue:pop()
		if info.isIn then
			self:PlayAnimation(info.index, ANIM_IN)
		else
			self:PlayAnimation(info.index, ANIM_OUT)
		end
	else
	end
end

-- 删除角色
function LoginRoleSelect:DeleteRole()
	local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
	if  shiwan and tonumber(shiwan) == 1 then
		return
	end

	local index = self._index
    local roles = SL:GetValue("LOGIN_DATA")
    local roleInfo = roles[index]
    if not index or index < 1 or not roleInfo then
        return
    end

	--角色冻结
	if roles and roles[self._index] and ( roles[self._index].LockChar == 1 or roles[self._index].LockChar == 3) then
		SL:ShowSystemTips(GET_STRING(10001037))--角色已被冻结
		return
	end

    local function callback(bType)
        if bType == 1 then
			self._removeFlag = true
			self._index = -1
            SL:RequestDeleteRole(roleInfo.roleid)
        end
    end
    local data = {}
    data.str = string.format(GET_STRING(10001011), roles[index].name)
    data.btnDesc = {GET_STRING(1001), GET_STRING(1000)}
    data.callback = callback
    SL:OpenCommonDialog(data)
end

function LoginRoleSelect:Close()
	self.super.Close(self)
end

function LoginRoleSelect:OnUpdateRoles()
	self:InitRoles()
end

function LoginRoleSelect:OnRefreshSelectRole()
	local roles = SL:GetValue("LOGIN_DATA") or {}
    if roles[self._index] and (roles[self._index].LockChar == 1 or roles[self._index].LockChar == 3) then
		self._index =- 1
		SL:ShowSystemTips(GET_STRING(10001037))
		return 
    end
	SL:SetValue("LOGIN_SELECTED_ROLE", roles[self._index])
end

function LoginRoleSelect:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_LOGIN_ROLE_UPDATE, "LoginRoleSelect", handler(self, self.OnUpdateRoles))
	SL:RegisterLUAEvent(LUA_EVENT_LOGIN_ROLE_REFRESH_SELECT, "LoginRoleSelect", handler(self, self.OnRefreshSelectRole))
end

function LoginRoleSelect:UnRegisterEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_LOGIN_ROLE_UPDATE, "LoginRoleSelect")
	SL:UnRegisterLUAEvent(LUA_EVENT_LOGIN_ROLE_REFRESH_SELECT, "LoginRoleSelect")
end

return LoginRoleSelect