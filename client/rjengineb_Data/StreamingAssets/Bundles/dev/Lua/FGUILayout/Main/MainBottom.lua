local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local MainBottom = class("MainBottom", BaseFGUILayout)

function MainBottom:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Main)

    self._miniChat = FGUIFunction:BindClass(self.component, "Main/MainMiniChat")
    self._miniChat:Create()

    self._checkAll = false

    self._bubbleTipsData = {}
    self._bubbleTipsCells = {}

    self._loadingFile = {}

    self._isAutoFight = false
    self._isAutoMove = false

    self._skillAutoModeNames = {}

    self._ctrl_cameraMode = FGUI:getController(self._ui.Btn_cameraMode, "cameraMode")
    FGUI:UIModel_addFx(self._ui.Graph_autoFight, 1001010, true, nil, nil, Vector3(0.3, 0.3, 0.3))
    FGUI:UIModel_pause(self._ui.Graph_autoFight)
    FGUI:setVisible(self._ui.Graph_autoFight, self._isAutoFight)
    FGUI:setVisible(self._ui.Image_autoMove, self._isAutoMove)

	FGUI:setOnClickEvent(self._ui.Btn_friend, handler(self, self.OnFriend))
    FGUI:setOnClickEvent(self._ui.Btn_mail, handler(self, self.OnMail))
    FGUI:setOnClickEvent(self._ui.Btn_stall, handler(self, self.OnStall))
	FGUI:setOnClickEvent(self._ui.Btn_auto, handler(self, self.OnAuto))
    FGUI:setOnClickEvent(self._ui.Btn_cameraMode, handler(self, self.BtnCameraChangeClick))
    FGUI:setOnClickEvent(self._ui.Btn_updateTip, handler(self, self.BtnUpdateTip))

    FGUI:GComboBox_setOnChangeCallback(self._ui.ComboBox_autoMode1, handler(self, self.OnAutoMode1Change))
    FGUI:GComboBox_setOnChangeCallback(self._ui.ComboBox_autoMode2, handler(self, self.OnAutoMode2Change))
    
    FGUI:setVisible(self._ui.Btn_updateTip, false)
    

    FGUI:setVisible(self._ui.ProgressBar_preLoad, false)

end

function MainBottom:Enter()
    self._miniChat:Enter()
	self:RegisterEvent()

    self:InitAdapt()
	self:OnRefreshPropertyShow()
	self:OnRefreshNetShow()
    self:UpdateAutoButton()
    self:UpdateAutoState()
    self:InitBubbleTips()
    self:OnRefreshCameraBtn()

	self:UpdateTime()
	self._timer = SL:Schedule(handler(self, self.UpdateTime), 1)

    self:UpdateAutoModeTouchEnable()
    self:UpdateAutoMode1Datas()
    self:UpdateAutoMode2Datas()
    self:UpdateAutoMode2()

    -- 启动状态同步
    self:ScheduleStateSync()

    -- debug
    self:InitDebugInfo()
    self:UpdateDebugInfo()
end

function MainBottom:Exit()
    self._miniChat:Exit()
	if self._timer then
		SL:UnSchedule(self._timer)
		self._timer = nil
	end
    self:UnscheduleStateSync()
    self:ClearBubbleTips()
	self:RemoveEvent()

    if self._updateDebugSchedule then
        SL:UnSchedule(self._updateDebugSchedule)
		self._updateDebugSchedule = nil
    end
end

function MainBottom:Destroy()
    self._miniChat:Destroy()
    self._ui = nil
end

function MainBottom:InitAdapt()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    local safeL, safeR, safeB, safeT = SL:GetValue("SCREEN_SAFE_AREA_RATIO")

    if safeR > 0 then
        self._imgRightBgRawW = self._imgRightBgRawW or FGUI:getWidth(self._ui.Image_rightBg)
        FGUI:setWidth(self._ui.Image_rightBg, safeR + self._imgRightBgRawW)
    end
    if safeL > 0 then
        self._imgLeftBgRawW = self._imgLeftBgRawW or FGUI:getWidth(self._ui.Image_leftBg)
        FGUI:setWidth(self._ui.Image_leftBg, safeL + self._imgLeftBgRawW)
    end

    FGUI:setSize(self.component, screenW - safeR - safeL, screenH - safeB - safeT)
    FGUI:setPosition(self.component, safeL, safeT)
end


function MainBottom:OnRefreshPropertyShow()
    local curExp = SL:GetValue("EXP") or 0
	local maxExp = SL:GetValue("MAXEXP")
    maxExp = maxExp > 0 and maxExp or 1
    local expPer = math.floor(curExp / maxExp * 100)
    FGUI:GProgressBar_setValue(self._ui.ProgressBar_exp, expPer)
end

function MainBottom:OnRefreshNetShow()
	-- 网络类型 -1:未识别 0:wifi 1:蜂窝
	local netType = SL:GetValue("NET_TYPE")
    if netType == 0 then
		FGUI:setVisible(self._ui.Img_wifi, true)
    else
        FGUI:setVisible(self._ui.Img_wifi, false)
    end
end

function MainBottom:OnRefreshBubbleTips(data)
    if data.status then
        self:AddBubbleTips(data)
    else
        self:RmvBubbleTips(data)
    end
end

function MainBottom:UpdateTime()
	local date = os.date("*t", SL:GetValue("SERVER_TIME"))
	-- local timeStr = string.format("%02d:%02d:%02d", date.hour, date.min, date.sec)
	local timeStr = string.format("%02d:%02d", date.hour, date.min)
	FGUI:GTextField_setText(self._ui.Text_time, timeStr)

    self:UpdateProgress()
end

function MainBottom:InitDebugInfo()
    if not SL._DEBUG then
        return 
    end

    -- 默认隐藏调试信息
    local function ShowOrHideVisible()
		self:SetDebugInfo(not FGUI:getVisible(self._ui.Debug_Text))
    end
    SL:AddKeyboardEvent("KEY_F12", "MainBottom", ShowOrHideVisible)
	
	self:SetDebugInfo(false)
end

function MainBottom:SetDebugInfo(visible)
	FGUI:setVisible(self._ui.Debug_Text, visible)
	if visible then
		self._updateDebugSchedule = SL:Schedule(handler(self, self.UpdateDebugInfo), 0.01)
	else
		if self._updateDebugSchedule then
			SL:UnSchedule(self._updateDebugSchedule)
			self._updateDebugSchedule = nil
		end
	end
end

function MainBottom:UpdateDebugInfo()
    if not SL._DEBUG then
        return 
    end
    local uid = SL:GetValue("USER_ID")
    if not uid then 
        return 
    end
    local name = SL:GetValue("ACTOR_NAME", uid) 
    if not name then 
        return 
    end
    local x = SL:GetValue("ACTOR_POSITION_X", uid) or 0
    local y = SL:GetValue("ACTOR_POSITION_Y", uid) or 0
    local z = SL:GetValue("ACTOR_POSITION_Z", uid) or 0
    local d = SL:GetValue("ACTOR_DIR", uid) or 0

    local MapName           = SL:GetValue("MAP_NAME")
    local distanceToTarget  = 0
    local targetID          = SL:GetValue("SELECT_TARGET_ID")
    local targetX = 0
    local targetY = 0
    local targetZ = 0
    if targetID then
        targetX = SL:GetValue("ACTOR_POSITION_X", targetID)
        targetY = SL:GetValue("ACTOR_POSITION_Y", targetID)
        targetZ = SL:GetValue("ACTOR_POSITION_Z", targetID)
        distanceToTarget = math.sqrt((targetX - x) ^ 2 + (targetZ - z) ^ 2)
    end
    local speed     = 1/(SL:GetValue("ACTOR_MOVE_STEP_TIME", uid) or 1)
    local mapWidth  = SL:GetValue("MAP_WIDTH") or 0
    local mapHeight = SL:GetValue("MAP_HEIGHT") or 0


    local mapY = SL:GetValue("MAP_Y",x, z) or 0
    local str       = string.format(
    "地图:%s X:%.2f Y:%.2f Z:%.2f \n方向:%s 移速:%.2fm/s 距目标:%.2f \n目标:X:%.2f Y:%.2f Z:%.2f \n地图宽度:%s , 地图高度:%s  地图Y:%.2f",
        MapName, x, y, z, d, speed, distanceToTarget, targetX, targetY, targetZ, mapWidth, mapHeight, mapY)
    FGUI:GTextField_setText(self._ui.Debug_Text, str)
end


function MainBottom:OnFriend()
    FGUI:Open("Friend", "FriendPanel", FGUIDefine.FriendPage.Recent)
end
function MainBottom:OnMail()
    FGUI:Open("Mail", "MailPanel")
end
function MainBottom:OnStall()
    FGUI:Open("Stall", "StallMain")
end

function MainBottom:OnSettingInit()
    self:UpdateAutoModeTouchEnable()
    self:UpdateAutoMode1Datas()
    self:UpdateAutoMode2Datas() 
end

function MainBottom:OnSettingChange(id, value)
    if id == SLDefine.SETTINGID.SETTING_IDX_MAIN_SKILL_SCHEME_SHOW then
        self:UpdateAutoModeTouchEnable()
    elseif id == SLDefine.SETTINGID.SETTING_IDX_FIGHT_JOB_SKILL_SCHEME_SELECT then
        self:UpdateAutoMode1()
    elseif id == SLDefine.SETTINGID.SETTING_IDX_FIGHT_JOB_SKILL then
        self:UpdateAutoMode1Datas()
    end
end

-------------------------------自动战斗模式----------------------------------

function MainBottom:UpdateAutoMode1Datas()
    local count = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME_COUNT")
    if count == 0 then 
        local defaultName = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME", 0)
        self._skillAutoModeNames[1] = defaultName
    else 
        for i = 1, count do
            self._skillAutoModeNames[i] = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_NAME", i - 1)
        end
    end 
    FGUI:GComboBox_setItems(self._ui.ComboBox_autoMode1, self._skillAutoModeNames)
    self:UpdateAutoMode1()
end

function MainBottom:UpdateAutoMode2Datas()
    self._mode2Datas = {
        "气功方案1",
        "气功方案2",
    }
    FGUI:GComboBox_setItems(self._ui.ComboBox_autoMode2, self._mode2Datas)
    self:UpdateAutoMode2()
end

function MainBottom:UpdateAutoMode1()
    local scheme = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_SELECT")
    FGUI:GTextField_setText(self._ui.Text_autoMode1, self._skillAutoModeNames[scheme + 1] or "")
end

function MainBottom:UpdateAutoMode2()
    -- local mode = SL:GetValue("SETTING_AUTO_FIGHT_RANGE_ENABLE")
    -- if not mode then return end
    -- local mode1Name = self._mode1Datas[mode + 1]
    -- FGUI:GTextField_setText(self._ui.Text_autoMode1, mode1Name)
    -- FGUI:GTextField_setText(self._ui.Text_autoMode2, self._mode2Datas[1])
end

function MainBottom:UpdateAutoModeTouchEnable()
    local value = SL:GetValue("SETTING_MAIN_SKILL_SCHEME_SHOW")
    local touchEnable = value == 1 or value == true
    FGUI:setTouchEnabled(self._ui.ComboBox_autoMode1, touchEnable)
    FGUI:setTouchEnabled(self._ui.ComboBox_autoMode2, touchEnable)
end

function MainBottom:OnAutoMode1Change(context)
    local idx = FGUI:GComboBox_getSelectedIndex(self._ui.ComboBox_autoMode1)
    if idx == -1 then return end
    local lastIdx = SL:GetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_SELECT")
    SL:SetValue("SETTING_FIGHT_JOB_SKILL_SCHEME_SELECT", idx)
    SL:SetSchemeKeys(lastIdx, idx)
end
function MainBottom:OnAutoMode2Change(context)
    local idx = FGUI:GComboBox_getSelectedIndex(self._ui.ComboBox_autoMode2)
    if idx == -1 then return end
    local data = self._mode2Datas[idx + 1]
    FGUI:GTextField_setText(self._ui.Text_autoMode2, data)
end


--------------------------- 气泡栏 -----------------------------

function MainBottom:InitBubbleTips()
    local datas = SL:GetValue("BUBBLE_TIPS")
    for k, data in pairs(datas) do
        self:AddBubbleTips(data)
    end
end

function MainBottom:ClearBubbleTips()
    local datas = {}
    for k, data in pairs(self._bubbleTipsData) do
        table.insert(datas, data)
    end
    for k, data in pairs(datas) do
        self:RmvBubbleTips(data)
    end
end

function MainBottom:AddBubbleTips(data)
    if self._bubbleTipsData[data.id] then
        self._bubbleTipsData[data.id] = data
        return false
    end
    self._bubbleTipsData[data.id] = data
    local cell = self:CreateBubbleTipsCell(data)
    self._bubbleTipsCells[data.id] = cell

    self:PlayBubbleTipEffects()
    SL:PlaySound(50004)
end

function MainBottom:RmvBubbleTips(data)
    if not self._bubbleTipsData[data.id] then
        return false
    end
    self._bubbleTipsData[data.id] = nil
    local cell = self._bubbleTipsCells[data.id]
    if cell then
        local trans = FGUI:GetTransition(cell, "effect")
        FGUI:Transition_stop(trans)
        self._bubbleTipsCells[data.id] = nil
        FGUI:GList_removeChildToPool(self._ui.List_bubbleTip, cell)
    end

    if data.timer then
        SL:UnSchedule(data.timer)
        data.timer = nil
    end
end

-- 重新排列多个特效播放效果
function MainBottom:PlayBubbleTipEffects()
    local num = FGUI:GList_getNumItems(self._ui.List_bubbleTip)
    local len = num - 1
    for i = 0, len do
        local cell = FGUI:GetChildAt(self._ui.List_bubbleTip, i)
        local trans = FGUI:GetTransition(cell, "effect")
        FGUI:Transition_stop(trans)
        FGUI:Transition_play(trans, nil, -1, 0)
    end
end

-- 气泡cell
function MainBottom:CreateBubbleTipsCell(data)
    local id = data.id
    if data.time then
        data.endTime = data.time + SL:GetValue("SERVER_TIME")
    end

    local cell = FGUI:GList_addItemFromPool(self._ui.List_bubbleTip)
    FGUI:setLocalZOrder(cell, id)
    local ctl = FGUI:getController(cell, "type")
    FGUI:Controller_setSelectedIndex(ctl, data.type)

    FGUI:setOnClickEvent(cell, function()
        if data.callback then
            data.callback()
        end
    end)

    -- 时间
    local function callback()
        local remaining = data.endTime - SL:GetValue("SERVER_TIME")
        FGUI:GButton_setTitle(cell, remaining)

        if remaining <= 0 then
            if data.timer then
                SL:UnSchedule(data.timer)
                data.timer = nil
            end
            FGUI:GButton_setTitle(cell, "")
            if data.timeOverCB then
                data.timeOverCB()
            end
        end
    end

    if data.endTime then
        if data.timer then
            SL:UnSchedule(data.timer)
            data.timer = nil
        end
        data.timer = SL:Schedule(callback, 1)
        callback()
    else
        FGUI:GButton_setTitle(cell, "")
    end

    local imgEffetc = FGUI:GetChild(cell, "Image_effect")
    FGUI:setAlpha(imgEffetc, 0)
    return cell
end

-- 获取气泡按钮方法
-- function MainBottom:GetBubbleButtonByID(id)
--     for i, cell in pairs(self._bubbleTipsCells) do
--         if cell.id == id then
--             return cell.cell
--         end
--     end
--     return nil
-- end
-----------------------------------Auto------------------------------------
function MainBottom:OnAutoMoveBegin(data)
    self:UpdateAutoState(nil, true)
end
function MainBottom:OnAutoMoveEnd()
    self:UpdateAutoState(nil, false)
end
function MainBottom:OnFightBegin()
    self:UpdateAutoState(true, nil)
end
function MainBottom:OnFightEnd()
    self:UpdateAutoState(false, nil)
end

function MainBottom:OnRefreshCameraBtn()
    self._ctrl_cameraMode.selectedIndex = SL:GetValue("CAMERA_MODE_FROM_LOCAL")-1
end
function MainBottom:UpdateAutoState(isAutoFight, isAutoMove)
    if isAutoFight == nil then
        -- 综合判断:战斗状态 + 挂机状态才是真正的自动战斗
        local battleState = SL:GetValue("BATTLE_IS_FIGHT_STATE") or false
        local afkState = SL:GetValue("BATTLE_IS_AFK") or false
        isAutoFight = battleState and afkState
    end
    if self._isAutoFight ~= isAutoFight then
        self._isAutoFight = isAutoFight
        if isAutoFight then
            FGUI:setVisible(self._ui.Graph_autoFight, true)
            FGUI:UIModel_resume(self._ui.Graph_autoFight)
        else
            FGUI:UIModel_pause(self._ui.Graph_autoFight)
            FGUI:setVisible(self._ui.Graph_autoFight, false)
        end
    end
    if isAutoFight then isAutoMove = false end
    if isAutoMove == nil then
        isAutoMove = SL:GetValue("BATTLE_IS_AUTO_MOVE")
    end
    if self._isAutoMove ~= isAutoMove then
        self._isAutoMove = isAutoMove
        FGUI:setVisible(self._ui.Image_autoMove, isAutoMove)
    end
end

-- 定期同步状态,确保指示图状态与引擎一致
function MainBottom:ScheduleStateSync()
    if not self._stateSyncTimer then
        self._stateSyncTimer = SL:Schedule(handler(self, self.SyncAutoState), 1)
    end
end

function MainBottom:UnscheduleStateSync()
    if self._stateSyncTimer then
        SL:UnSchedule(self._stateSyncTimer)
        self._stateSyncTimer = nil
    end
end

function MainBottom:SyncAutoState()
    self:UpdateAutoState()
end

function MainBottom:OnVersionUpdate(platform, resourceType, pushType, extend)
    --platform平台 0.全部 1.ios 2.安卓  3.pc 4.h5
    --resourceType资源类型 0.全部 1.dev 2.dev_assets 3.dev_server 
    --pushType更新类型 0.软提示  1.强更 
    --extend自定义
    print(platform, resourceType, pushType, extend,"OnVersionUpdate__")
    if platform == 1 then 
        if not SL:GetValue("PLATFORM_IOS")  then
            return 
        end
    elseif platform == 2 then 
        if not SL:GetValue("PLATFORM_ANDROID")  then
            return 
        end
    elseif platform == 3 then 
        if not SL:GetValue("PLATFORM_WINDOWS")  then
            return 
        end
    elseif platform == 4 then 
        if not SL:GetValue("PLATFORM_WEB")  then
            return 
        end
    end
    if pushType == 1 then
        local callFunc = function (btnIndex)
            SL:RestartGame()
        end
        local data = {}
        data.str = SL:GetValue("I18N_STRING", 20000214)
        data.btnDesc = {SL:GetValue("I18N_STRING", 20000213)}
        data.maskClose = false
        data.callback = callFunc
        SL:OpenCommonDialog(data)
    else 
        FGUI:setVisible(self._ui.Btn_updateTip, true)
    end
end

function MainBottom:BtnUpdateTip()
    local callFunc = function (btnIndex)
        if btnIndex == 1 then 
            SL:RestartGame()
        end
    end
    local data = {}
    data.str = SL:GetValue("I18N_STRING", 20000211)
    data.btnDesc = {SL:GetValue("I18N_STRING", 20000213),SL:GetValue("I18N_STRING", 20000212)}
    data.maskClose = false
    data.callback = callFunc
    SL:OpenCommonDialog(data)
end

function MainBottom:BtnCameraChangeClick()
    FGUI:Open("ChangeCamera","ChangeCamera")
end

-----------------------------------Auto------------------------------------

function MainBottom:OnAuto()
    local isAFK = SL:GetValue("BATTLE_IS_AFK")
    if not isAFK then
        SL:SetValue("BATTLE_AFK_BEGIN")
    else
        SL:SetValue("BATTLE_AFK_END")
    end
end
function MainBottom:OnAFKBegin()
    self:UpdateAutoButton(true)
end
function MainBottom:OnAFKEnd()
    self:UpdateAutoButton(false)
end
function MainBottom:UpdateAutoButton(isAFK)
    if isAFK == nil then
        isAFK = SL:GetValue("BATTLE_IS_AFK")
    end
    local controller = FGUI:getController(self._ui.Btn_auto, "state")
    FGUI:Controller_setSelectedIndex(controller, isAFK and 1 or 0)
end

---------------------------------------------------------------------------
-- 预加载开始
function MainBottom:OnPreLoadStart(key)
	table.insert(self._loadingFile, key)
    FGUI:setVisible(self._ui.ProgressBar_preLoad, true)
	self:UpdateProgress()
end

-- 预加载结束
function MainBottom:OnPreLoadEnd(key)
    if not self._loadingFile or not next(self._loadingFile) then
        FGUI:setVisible(self._ui.ProgressBar_preLoad, false)
        return
    end
    local idx = -1
    for i, v in ipairs(self._loadingFile) do
        if key == v then
            idx = i
            break
        end
    end
    if idx > -1 then
        table.remove(self._loadingFile, idx)
    end
    if not next(self._loadingFile) then
        FGUI:setVisible(self._ui.ProgressBar_preLoad, false)
        return
    end
	self:UpdateProgress()
end

function MainBottom:UpdateProgress()
	if not self._loadingFile or not next(self._loadingFile) then
		FGUI:GProgressBar_setValue(self._ui.ProgressBar_preLoad, 0)
		return
	end
	
	local totalP = 0
	for i, key in ipairs(self._loadingFile) do
		local progress = SL:GetValue("PRELOAD_PROGRESS", key)
		totalP = totalP + progress
	end
	local P = totalP / #self._loadingFile * 100
	FGUI:GProgressBar_setValue(self._ui.ProgressBar_preLoad, P)
end

-----------------------------------注册事件--------------------------------------
function MainBottom:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "MainBottom", handler(self, self.OnRefreshPropertyShow))
	SL:RegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "MainBottom", handler(self, self.OnRefreshPropertyShow))
    SL:RegisterLUAEvent(LUA_EVENT_EXP_CHANGE, "MainBottom", handler(self, self.OnRefreshPropertyShow))
	SL:RegisterLUAEvent(LUA_EVENT_NET_CHANGE, "MainBottom", handler(self, self.OnRefreshNetShow))
    SL:RegisterLUAEvent(LUA_EVENT_BUBBLETIPS_STATUS_CHANGE, "MainBottom", handler(self, self.OnRefreshBubbleTips))
    SL:RegisterLUAEvent(LUA_EVENT_AUTO_MOVE_BEGIN, "MainBottom", handler(self, self.OnAutoMoveBegin))
    SL:RegisterLUAEvent(LUA_EVENT_AUTO_MOVE_END, "MainBottom", handler(self, self.OnAutoMoveEnd))
    SL:RegisterLUAEvent(LUA_EVENT_FIGHT_BEGIN, "MainBottom", handler(self, self.OnFightBegin))
    SL:RegisterLUAEvent(LUA_EVENT_FIGHT_END, "MainBottom", handler(self, self.OnFightEnd))
    SL:RegisterLUAEvent(LUA_EVENT_CAMERA_DATA_SAVE_SUCESS,"MainBottom", handler(self,self.OnRefreshCameraBtn))
    SL:RegisterLUAEvent(LUA_EVENT_VERSION_UPDATE,"MainBottom", handler(self,self.OnVersionUpdate))
    SL:RegisterLUAEvent(LUA_EVENT_PRELOAD_START, "MainBottom", handler(self, self.OnPreLoadStart))
	SL:RegisterLUAEvent(LUA_EVENT_PRELOAD_END, "MainBottom", handler(self, self.OnPreLoadEnd))
    SL:RegisterLUAEvent(LUA_EVENT_AFK_BEGIN, "MainBottom", handler(self, self.OnAFKBegin))
    SL:RegisterLUAEvent(LUA_EVENT_AFK_END, "MainBottom", handler(self, self.OnAFKEnd))
    SL:RegisterLUAEvent(LUA_EVENT_SETTING_INIT, "MainBottom", handler(self, self.OnSettingInit))
    SL:RegisterLUAEvent(LUA_EVENT_SETTING_CAHNGE, "MainBottom", handler(self, self.OnSettingChange))
end

function MainBottom:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_ROLE_PROPERTY_INITED, "MainBottom")
	SL:UnRegisterLUAEvent(LUA_EVENT_LEVEL_CHANGE, "MainBottom")
	SL:UnRegisterLUAEvent(LUA_EVENT_EXP_CHANGE, "MainBottom")
	SL:UnRegisterLUAEvent(LUA_EVENT_NET_CHANGE, "MainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_BUBBLETIPS_STATUS_CHANGE, "MainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_AUTO_MOVE_BEGIN, "MainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_AUTO_MOVE_END, "MainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_FIGHT_BEGIN, "MainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_FIGHT_END, "MainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_CAMERA_DATA_SAVE_SUCESS, "MainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_VERSION_UPDATE, "MainBottom")
  	SL:UnRegisterLUAEvent(LUA_EVENT_PRELOAD_START, "MainBottom")
	SL:UnRegisterLUAEvent(LUA_EVENT_PRELOAD_END, "MainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_AFK_BEGIN, "MainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_AFK_END, "MainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_SETTING_INIT, "MainBottom")
    SL:UnRegisterLUAEvent(LUA_EVENT_SETTING_CAHNGE, "MainBottom")
end


return MainBottom