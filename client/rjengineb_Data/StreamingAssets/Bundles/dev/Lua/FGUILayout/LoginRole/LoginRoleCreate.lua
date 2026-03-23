local LoginRoleBase = require("FGUILayout/LoginRole/LoginRoleBase")
local LoginRoleCreate = class("LoginRoleCreate", LoginRoleBase)

local maxNameLength = SL:GetValue("GAME_DATA", "NameLengthMax") or 7 -- 玩家最长名字长度
local roleConfig = requireGameConfig("Class")

local roleAttrRadarMap = {
	{0.53,0.39,0.76,0.87,0.74},
	{0.6,0.72,0.47,0.71,0.89},
	{0.51,0.38,0.5,0.8,0.46},
	{0.47,0.9,0.61,0.71,0.49},
	{0.87,0.58,0.93,0.66,0.62},
	{0.6,0.71,0.53,0.78,0.76},
}

local classCount = 6
function LoginRoleCreate:Create()
	self.super.Create(self)
    if SL:GetValue("IS_PC_OPER_MODE") then
        self._packageName = "LoginRole_pc"
    else
        self._packageName = "LoginRole"
    end
	self._ui = FGUI:ui_delegate(self.component)
	self._colorAttribute = SL:ConvertHexStrToColor("#9B6516")
	self._colorAttribute.a = 0.7
	FGUI:GTextInput_setMaxLength(self._ui.textInput_name, maxNameLength)

	
	self.handler_roleListRenderer = handler(self, self.OnRoleListRenderer)
	self.handler_roleListClickEvent = handler(self, self.OnRoleListClickEvent)

	-- 职业
	FGUI:GList_itemRenderer(self._ui.list_job_select, self.handler_roleListRenderer)
	FGUI:GList_setNumItems(self._ui.list_job_select, classCount)
	FGUI:GList_addOnClickItemEvent(self._ui.list_job_select, self.handler_roleListClickEvent)		

	-- 性别选择
	FGUI:setOnClickEvent(self._ui.btn_sex_0, function ()
		self:SelectSex(0)
	end)
	FGUI:setOnClickEvent(self._ui.btn_sex_1, function ()
		self:SelectSex(1)
	end)
		
	-- 随机名字
    FGUI:setOnClickEvent(self._ui.btn_random_name, handler(self, self.RequestRandomName))
	-- 创建角色
	FGUI:setOnClickEvent(self._ui.btn_create_role, handler(self, self.OnClickCreateButton))
	-- 上一步
	FGUI:setOnClickEvent(self._ui.btn_pre, handler(self, self.OpenSelectRolePanel))
end

-- 切换任务雷达
function LoginRoleCreate:refreshRoleAttributeRadar(jobIdx)
	self._ui.graphic_Attribute.shape:DrawRegularPolygon(5,2,
		self._colorAttribute , -- Color centerColor
		self._colorAttribute ,	--lineColor
		self._colorAttribute , -- fillColor
		-18.61,
		roleAttrRadarMap[tonumber(jobIdx)])
end

function LoginRoleCreate:Enter()
	self.super.Enter(self)
	LoginRoleCreate:InitSceneCamera()
	LoginRoleBase.FitstEntry = false
	self:RegisterEvent()
	
	self._curSelectIndex = nil
	self._lastSelectIndex = nil
	self._createJob = nil
	self._createSex = nil
	
	local defaultJob = 1
	self:SelectRoleItem(defaultJob)
	
	-- 默认请求随机名字
	if self._createJob and self._createSex then
		self:RequestRandomName()
	end
end

function LoginRoleCreate:InitSceneCamera()
	LoginScene.SetRolePosition(5.75, 0.36, -9.71)
	LoginScene.SetCamerPosition(5.75, 0, -9.71)
	SL:InitCreateSceneCamera()
end

function LoginRoleCreate:Exit()
	self.super.Exit(self)
	self:UnRegisterEvent()
	SL:ClearCreateSceneModel(self.modelEntity)
end

-- 职业列表刷新
function LoginRoleCreate:OnRoleListRenderer(idx, item)
	local jobIdx = idx + 1	
	self:RefreshRoleItemDisplay(idx, item)
	FGUI:GButton_setIcon(FGUI:GetChild(item, "icon_select"), string.format(self.jobSelectPath, jobIdx))
	FGUI:GButton_setIcon(FGUI:GetChild(item, "icon_unselect"), string.format(self.jobUnselectPath, jobIdx))
	FGUI:GButton_setTitle(item, roleConfig[jobIdx].ClassName)
end

-- 职业列表点击事件
function LoginRoleCreate:OnRoleListClickEvent(context)
	local item = context.data
	local index = FGUI:GetChildIndex(self._ui.list_job_select, item)
	local jobIdx = index + 1
	self:SelectRoleItem(jobIdx)
end

-- 请求随机名字
function LoginRoleCreate:RequestRandomName()
	SL:RequestRandomRoleName(self._createJob, self._createSex)
end

-- 选择职业
function LoginRoleCreate:SelectRoleItem(jobIdx)
	self._createJob = jobIdx
	local itemIndex = jobIdx - 1
	self._lastSelectIndex = self._curSelectIndex
	self._curSelectIndex = itemIndex
	FGUI:GList_setSelectedIndex(self._ui.list_job_select, 	self._curSelectIndex)
	local sex = (self._createSex == nil) and (roleConfig[jobIdx].DefaultGender or 0) or self._createSex
	self:SelectSex(sex)
	FGUI:GLoader_setUrl(self._ui.loader_job, string.format(self.jobTextPath, jobIdx))
	self:refreshRoleAttributeRadar(jobIdx)
	local classConfig = SL:GetValue("ROLE_CLASS_CONFIG", self._createJob)
	if classConfig then
		FGUI:GTextField_setText(self._ui.text_introduce, classConfig.Desc)
	end
end

function LoginRoleCreate:UpdateRoleModel(data)
	local classConfig = SL:GetValue("ROLE_CLASS_CONFIG", data.job)
	local uiTouch = self._ui["panel_touch"]
	SL:ClearCreateSceneModel(self.modelEntity)
	if classConfig then
		local tModel = classConfig.InitModel
		local bodyId = tModel[1]
		local headId = tModel[2]
		local rWeapon = tModel[3]
		local faceId = FGUIFunction:GetFaceIDBySex(data.sex,classConfig)

		local modelCallback = function()
			self:SetModelRotate(uiTouch)
			SL:SetCreateSceneModelTransform(self.modelEntity)
			if classConfig.ShowSkill and classConfig.ShowSkill > 0 then
				SL:CreateSceneModelDoSkillAnim(self.modelEntity, classConfig.ShowSkill)
			end
		end
		local modelData = {}
		modelData.sex = data.sex
		modelData.job = data.job
		modelData.bodyId = bodyId
		modelData.rWeapon = rWeapon
		if data.job == global.MMO.ACTOR_PLAYER_JOB_3 then
			modelData.lWeapon = rWeapon
		end
		modelData.headId = headId
		modelData.faceId = faceId
		self.modelEntity = SL:CreatePlayerModel(nil, modelData, modelCallback)
	end
end

-- 选择性别
function LoginRoleCreate:SelectSex(sex)
	self._createSex = sex
	for i = 0, 1 do
		local childName = "btn_sex_"..i
		local effect = self._ui(childName, "select_effect")
		FGUI:setVisible(effect, sex == i)
	end

	local data = {}
	data.job = self._createJob
	data.sex = sex
	self:UpdateRoleModel(data)
end

-- 刷新角色选择item的显示样式
function LoginRoleCreate:RefreshRoleItemDisplay(itemIndex, item)
end

-- 点击创建角色
function LoginRoleCreate:OnClickCreateButton()
	local input = FGUI:GTextField_getText(self._ui.textInput_name)
	if string.len(input) == 0 then
		SL:ShowSystemTips(GET_STRING(10001009))
		return
	end

	-- 屏蔽数字
	for i = 0, 10 do
		local _, endPos = string.find(input, tostring(i))
		if endPos then
			SL:ShowSystemTips(GET_STRING(10001027))
			return
		end
	end

	local createJob = self._createJob
	local createSex = self._createSex
	SL:RequestCreateRole(input, createJob, createSex)
end

function LoginRoleCreate:Close()
	self.super.Close(self)
end

function LoginRoleCreate:OnResponseRandomName(name)
	FGUI:GTextField_setText(self._ui.textInput_name, name)
end

function LoginRoleCreate:OnCreateRoleSuccess()
	SL:RequestEnterGame()
end

function LoginRoleCreate:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_LOGIN_ROLE_RANDOM_NAME, "LoginRoleCreat", handler(self, self.OnResponseRandomName))
	SL:RegisterLUAEvent(LUA_EVENT_CREATE_SUCCESS, "LoginRoleCreat", handler(self, self.OnCreateRoleSuccess))
end

function LoginRoleCreate:UnRegisterEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_LOGIN_ROLE_RANDOM_NAME, "LoginRoleCreat")
	SL:UnRegisterLUAEvent(LUA_EVENT_CREATE_SUCCESS, "LoginRoleCreat")
end

return LoginRoleCreate