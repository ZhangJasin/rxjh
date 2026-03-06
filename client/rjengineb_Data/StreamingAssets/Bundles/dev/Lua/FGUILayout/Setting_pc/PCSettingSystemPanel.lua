local PCSettingPageBase = requireFGUILayout("Setting_pc/PCSettingPageBase")
local PCSettingSystemPanel = class("PCSettingSystemPanel", PCSettingPageBase)

function PCSettingSystemPanel:Enter()
    PCSettingSystemPanel.super.Enter(self)
    self._packageName = "Setting_pc"
    self.qualityHandler = {
        [1] = {
            sign_url = "ui://"..self._packageName.."/quality_sign_middle",
            icon_url = "ui://"..self._packageName.."/quality_m",
            quality = EPerformanceQuality.Low,
            isQuality = function(quality)
                return quality <= EPerformanceQuality.Low
            end
        },
        [2] = {
            sign_url = "ui://"..self._packageName.."/quality_sign_high",
            icon_url = "ui://"..self._packageName.."/quality",
            quality = EPerformanceQuality.High,
            isQuality = function(quality)
                return quality >= EPerformanceQuality.Middle
            end
        }
    }

    if not self.component then
        release_log_traceback("ERROR PCSettingSystemPanel component is nil. packageName:"..self._packageName)
        return
    end
    self._ui = FGUI:ui_delegate(self.component)
    self._ui_system = FGUI:ui_delegate(self._ui.base_setting_component)
    self._slider_model_limit = self:GetComponentFormOptionItem("slider_model_limit")
    self._slider_camera_distance = self:GetComponentFormOptionItem("slider_distance")
    self._slider_fix_limit = self:GetComponentFormOptionItem("slider_fix_limit")
    self._slider_ui_scale = self:GetComponentFormOptionItem("slider_ui_scale")
    self._slider_bgm = self:GetComponentFormOptionItem("slider_bgm")
    self._slider_sound = self:GetComponentFormOptionItem("slider_sound")
    self:InitData()
    self:InitEvent()

    self:RefresPlayerInfo()
    self:Init_Quality()
    self:Init_HighFrameRate()
    self:Init_VSyncEnable()
    self:Init_AutoECO()
    self:Init_AASetting()
	self:Init_MsaaQuality()
    self:Init_RotateCameraOfLeftKey()
    self:Init_Fog()
    self:Init_PlayerCount()
    self:Init_CameraDistance()
    self:Init_FixLimit()
    self:Init_UIScale()
    self:Init_BGM()
    self:Init_Sound()
    self:Init_PolicyUI()

    SL:ComponentAttach(SLDefine.SUIComponentTable.SettingSystem, self._ui.Node_attach)
end

function PCSettingSystemPanel:Exit()
    SL:ComponentDetach(SLDefine.SUIComponentTable.SettingSystem)

    PCSettingSystemPanel.super.Exit(self)
end

function PCSettingSystemPanel.Create()
    return PCSettingSystemPanel.new()
end

function PCSettingSystemPanel:InitData()
    self._ui_width_standard = 1024
    self._max_ui_scale = math.max(1, SL:GetValue("SCREEN_REAL_WIDTH") / self._ui_width_standard)
    self._max_ui_scale = math.round(self._max_ui_scale * 10)
    self._max_ui_scale = self._max_ui_scale / 10
end

function PCSettingSystemPanel:Init_PolicyUI()
    -- body
    local policyCustomData  = SL:GetValue("GAME_CUSTOM_DATA", "agreementUrl") or {} -- 协议数据地址
    -- 配置和按钮匹配
    local agreementUrlIdxs = {
        [1] = 3,
        [2] = 1,
        [3] = 2,
        [4] = 4
    }
    self.mPolicyCustomData = {}
    for i,v in ipairs(policyCustomData) do
        local idx = agreementUrlIdxs[i]
        self.mPolicyCustomData[idx] = v and v.url
    end
    
    local showDeleteAccount = tonumber(SL:GetValue("GAME_CUSTOM_DATA", "showInnerDeleteAccount")) == 1  -- 注销账号显示开关

    local icpFilingDesc = SL:GetValue("GAME_CUSTOM_DATA", "icpFilingDesc") -- ICP备案号
    local icpFilingUrl  = SL:GetValue("GAME_CUSTOM_DATA", "icpFilingUrl")  -- ICP备案号地址

    local showICP = false
    if icpFilingUrl and icpFilingUrl ~= "" and icpFilingDesc and icpFilingDesc ~= ""  then
        showICP = true
        FGUI:GRichTextField_setText(self._ui.icp_desc, string.format(GET_STRING(80000305), icpFilingDesc))

        -- local btnICPWidth = FGUI:getWidth(self._ui.btnICP)
        local icpDescWidth = FGUI:GRichTextField_getTextWidth(self._ui.icp_desc)
        -- FGUI:setPositionX(self._ui.btnICP, icpDescWidth + btnICPWidth / 2)
    end

    FGUI:setVisible(self._ui.icp_desc, showICP == true)
    -- FGUI:setVisible(self._ui.btnICP, showICP == true)
end

function PCSettingSystemPanel:InitEvent()
    FGUI:GList_addOnClickItemEvent(self._ui_system.quality_list, handler(self, self.OnClickQualityBtn))
    FGUI:GButton_setOnChangedCallback(self._ui_system.switch_high_frame, handler(self, self.OnSwitchHighFrame))
    FGUI:GButton_setOnChangedCallback(self._ui_system.switch_vsync_count, handler(self, self.OnSwitchVSyncEnable))
    FGUI:GSlider_addOnChanged(self._ui_system.switch_ECO, handler(self, self.OnSwitchAutoECO))
    FGUI:setOnClickEvent(self._ui_system.btn_help_eco, handler(self, self.OnClickHelpEcoBtn))
    FGUI:GSlider_addOnChanged(self._slider_model_limit, handler(self, self.OnChange_PlayerCount))
    FGUI:GSlider_addOnChanged(self._slider_camera_distance, handler(self, self.OnChange_CameraDistance))
    FGUI:GSlider_addOnChanged(self._slider_fix_limit, handler(self, self.OnChange_FixLimit))
    FGUI:GSlider_addOnChanged(self._slider_ui_scale, handler(self, self.OnChange_UIScale))
    FGUI:GSlider_addOnGripTouchEnd(self._slider_ui_scale, handler(self, self.OnUIScaleDragEnd))
    FGUI:addOnClickEvent(self._slider_ui_scale, handler(self, self.OnUIScaleClick))
    FGUI:addOnClickEvent(self._ui_system.ui_scale_btn, handler(self, self.OnClickApplyBtn))
    FGUI:GSlider_addOnChanged(self._slider_bgm, handler(self, self.OnChange_BGMValue))
    FGUI:GSlider_addOnChanged(self._slider_sound, handler(self, self.OnChange_SoundValue))

    FGUI:addOnClickEvent(self._ui.btn_redeem_code, handler(self, self.OnClickRedeemCodeBtn))
    FGUI:addOnClickEvent(self._ui.btnPrivacyPolicy, handler(self, self.OnClickPrivacyPolicyBtn))
    FGUI:addOnClickEvent(self._ui.btnChildrenPrivacyPolicy, handler(self, self.OnClickChildrenPrivacyPolicyBtn))
    FGUI:addOnClickEvent(self._ui.btnTermsOfService, handler(self, self.OnClickTermsOfServiceBtn))
    FGUI:addOnClickEvent(self._ui.btnThirdPartyDataSharing, handler(self, self.OnClickThirdPartyDataSharingBtn))
    FGUI:addOnClickEvent(self._ui.btnContactSupport, handler(self, self.OnClickContactSupportBtn))
    FGUI:addOnClickEvent(self._ui.btnDeleteAccount, handler(self, self.OnClicknDeleteAccountBtn))

    FGUI:addOnClickEvent(self._ui.btnSwitchCharacter, handler(self, self.OnClickSwitchCharacterBtn))
    FGUI:addOnClickEvent(self._ui.btnBackToLogin, handler(self, self.OnClickBackToLoginBtn))
    FGUI:addOnClickEvent(self._ui.btnOutBlock, handler(self, self.OnClickDisengageBtn))

    -- FGUI:addOnClickEvent(self._ui.btnICP, handler(self, self.OnClickICPBtn))
    FGUI:GRichTextField_addOnLinkClickEvent(self._ui.icp_desc, handler(self, self.OnClickICPBtn))
    if self._ui.btn_copy then
        FGUI:addOnClickEvent(self._ui.btn_copy, handler(self, self.CopyUserId))
    end
end

-- 画质 -------------------------------------------------------------------------
function PCSettingSystemPanel:Init_Quality()
    local quality_ui = self._ui_system.quality_list
    local recommendQuality = SL:GetValue("SETTING_RECOMMEND_QUALITY")

    for i = 1, FGUI:GList_getNumItems(quality_ui), 1 do
        local itemIndex = FGUI:GList_childIndexToItemIndex(quality_ui, i-1)
        local item = FGUI:GetChildAt(quality_ui,itemIndex)
        local info = self.qualityHandler[i]
        local sign = FGUI:GetChild(item, "quality_sign")
        FGUI:GLoader_setUrl(sign, info.sign_url)
        local icon = FGUI:GetChild(item, "icon")
        FGUI:GLoader_setUrl(icon, info.icon_url)
        local recommend = FGUI:GetChild(item, "quality_recommend")
        FGUI:setVisible(recommend, info.isQuality(recommendQuality))
    end
    
    self:Refresh_Quality()
end

function PCSettingSystemPanel:OnClickQualityBtn(context)
    local childIdx = FGUI:GetChildIndex(self._ui_system.quality_list, context.data)
	local index = FGUI:GList_childIndexToItemIndex(self._ui_system.quality_list, childIdx) + 1
    local handler = self.qualityHandler[index]
    local quality = handler.quality
    if SL:GetValue("SETTING_QUALITY") == quality then return end
    local reload=global.ConstantConfig["ScreenReload"] and global.ConstantConfig["ScreenReload"] ~= 0
    SL:SetValue("SETTING_QUALITY", quality)
    self:Refresh_Quality()
    self:Refresh_PlayerCount()
    self:Refresh_AASetting()
    self:Refresh_Fog()
end

function PCSettingSystemPanel:Refresh_Quality()
    local quality = SL:GetValue("SETTING_QUALITY")
    local quality_ui = self._ui_system.quality_list
    for i = 1, FGUI:GList_getNumItems(quality_ui), 1 do
        local itemIndex = FGUI:GList_childIndexToItemIndex(quality_ui, i-1)
        local item = FGUI:GetChildAt(quality_ui,itemIndex)
        local info = self.qualityHandler[i]
        FGUI:GButton_setSelected(item, info.isQuality(quality))
    end
end

-- 高帧率 -------------------------------------------------------------------------
function PCSettingSystemPanel:Init_HighFrameRate()
    local isHighFrame = SL:GetValue("SETTING_HIGH_FRAME_RATE")
    FGUI:GButton_setSelected(self._ui_system.switch_high_frame, isHighFrame)
end

function PCSettingSystemPanel:OnSwitchHighFrame()
    local isHighFrame = FGUI:GButton_getSelected(self._ui_system.switch_high_frame)
    if isHighFrame == SL:GetValue("SETTING_HIGH_FRAME_RATE") then
        return
    end
    if not global.isWindows and isHighFrame == true then
        local data = {}
        data.str = GET_STRING(80000231)
        data.btnDesc = {GET_STRING(1002), GET_STRING(1000)}
        data.callback = function(tag)
            if tag == 1 then
                SL:SetValue("SETTING_HIGH_FRAME_RATE", isHighFrame)
            else
                self:Init_HighFrameRate()
            end
        end
        SL:OpenCommonDialog(data)
    else
        SL:SetValue("SETTING_HIGH_FRAME_RATE", isHighFrame)
    end
end

-- 垂直同步 -------------------------------------------------------------------------
function PCSettingSystemPanel:Init_VSyncEnable()
    local vSyncEnable = SL:GetValue("SETTING_VSYNC_ENABLE")
    FGUI:GButton_setSelected(self._ui_system.switch_vsync_count, vSyncEnable)
end

function PCSettingSystemPanel:OnSwitchVSyncEnable()
    local vSyncEnable = FGUI:GButton_getSelected(self._ui_system.switch_vsync_count)
    if vSyncEnable == SL:GetValue("SETTING_VSYNC_ENABLE") then
        return
    end
    SL:SetValue("SETTING_VSYNC_ENABLE", vSyncEnable)
end

-- 省电模式 -------------------------------------------------------------------------
function PCSettingSystemPanel:Init_AutoECO()
    local enable = SL:GetValue("SETTING_AUTO_ECO")
    FGUI:GButton_setSelected(self._ui_system.switch_ECO, enable)
end

function PCSettingSystemPanel:OnSwitchAutoECO()
    local enable = FGUI:GButton_getSelected(self._ui_system.switch_ECO)
    if enable == SL:GetValue("SETTING_AUTO_ECO") then
        return
    end
    if enable == true then
        local data = {}
        data.str = string.format(GET_STRING(80000230), SL:GetValue("AUTO_ECO_MODE_TIME")/60)
        data.btnDesc = {GET_STRING(1002), GET_STRING(1000)}
        data.callback = function(tag)
            if tag == 1 then
                SL:SetValue("SETTING_AUTO_ECO", enable)
            else
                self:Init_AutoECO()
            end
        end
        SL:OpenCommonDialog(data)
    else 
        SL:SetValue("SETTING_AUTO_ECO", enable)
    end
end

function PCSettingSystemPanel:OnClickHelpEcoBtn()
    local data = {}
    data.title = GET_STRING(80000250)
    data.str = string.format(GET_STRING(80000251), SL:GetValue("AUTO_ECO_MODE_TIME")/60)
    SL:OpenCommonHelpDialog(data)
end

function PCSettingSystemPanel:Init_AASetting()
    self:Refresh_AASetting()
    FGUI:GButton_setOnChangedCallback(self._ui_system.switch_aasetting, handler(self, self.OnAASettingChanged))
end

function PCSettingSystemPanel:Refresh_AASetting()
    local enable = SL:GetValue("SETTING_PIPELINE_ANITI")
    FGUI:GButton_setSelected(self._ui_system.switch_aasetting, enable)
end

function PCSettingSystemPanel:OnAASettingChanged(context)
    local enable = FGUI:GButton_getSelected(context.sender)
    SL:SetValue("SETTING_PIPELINE_ANITI", enable)
end

function PCSettingSystemPanel:Init_MsaaQuality()
    if not SL:GetValue("PLATFORM_WINDOWS") then
        FGUI:setVisible(self._ui_system.text_msaaQuality, false)
        FGUI:setVisible(self._ui_system.comboBox_msaaQuality, false)
        return
    end
    self:Refresh_MsaaQuality()
    FGUI:GComboBox_setOnChangeCallback(self._ui_system.comboBox_msaaQuality, handler(self, self.OnMsaaQualityChanged))
end

function PCSettingSystemPanel:Init_RotateCameraOfLeftKey()
    FGUI:GButton_setOnChangedCallback(self._ui_system.switch_rotateCameraOfLeftKey, handler(self, self.OnRotateCameraOfLeftKeyChanged))
    FGUI:GButton_setSelected(self._ui_system.switch_rotateCameraOfLeftKey, SL:GetValue("SETTING_ROTATE_CAMERA_OF_LEFT_KEY"))
end

function PCSettingSystemPanel:OnRotateCameraOfLeftKeyChanged(context)
    local enable = FGUI:GButton_getSelected(self._ui_system.switch_rotateCameraOfLeftKey)
    SL:SetValue("SETTING_ROTATE_CAMERA_OF_LEFT_KEY", enable)
end

function PCSettingSystemPanel:Refresh_MsaaQuality()
    local level = SL:GetValue("SETTING_MSAA_QUALITY")
    FGUI:GComboBox_setSelectedIndex(self._ui_system.comboBox_msaaQuality, level)
end

function PCSettingSystemPanel:OnMsaaQualityChanged(context)
    local level = FGUI:GComboBox_getSelectedIndex(context.sender)
    if SL:GetValue("SETTING_MSAA_QUALITY") == level then
        return
    end
    SL:SetValue("SETTING_MSAA_QUALITY", level)
end

function PCSettingSystemPanel:Init_Fog()
    self:Refresh_Fog()
    FGUI:GButton_setOnChangedCallback(self._ui_system.switch_fog, handler(self, self.OnFogChanged))
end

function PCSettingSystemPanel:Refresh_Fog()
    local enable = SL:GetValue("SETTING_FOG")
    FGUI:GButton_setSelected(self._ui_system.switch_fog, enable)
end

function PCSettingSystemPanel:OnFogChanged(context)
    local enable = FGUI:GButton_getSelected(self._ui_system.switch_fog)
    SL:SetValue("SETTING_FOG", enable)
end

-- 同屏人数 -------------------------------------------------------------------------
function PCSettingSystemPanel:Init_PlayerCount()
    local min = 1
    FGUI:GSlider_setMin(self._slider_model_limit, min)
    FGUI:GSlider_setWholeNumbers(self._slider_model_limit, true)
    self:Refresh_PlayerCount()
end

function PCSettingSystemPanel:Refresh_PlayerCount()
    local defaultDisplaySettings = C_DefaultGameSettings.PerformanceConfig[global.ModelQuality]
    local max = defaultDisplaySettings.maxVisiblePlayers
    FGUI:GSlider_setMax(self._slider_model_limit, max)
    local count = SL:GetValue("SETTING_VISIBLE_MAX_MODEL")
    count = math.min(max, count)
    FGUI:GSlider_setValue(self._slider_model_limit, count)
    self:OnChange_PlayerCount()
end

function PCSettingSystemPanel:OnChange_PlayerCount()
    local count = FGUI:GSlider_getValue(self._slider_model_limit)
    FGUI:GTextField_setText(self._ui_system.model_limit_value, string.format("%.0f", count))
    if count == SL:GetValue("SETTING_VISIBLE_MAX_MODEL") then
        return
    end
    SL:SetValue("SETTING_VISIBLE_MAX_MODEL", count)
end

-- 相机距离 -------------------------------------------------------------------------
function PCSettingSystemPanel:Init_CameraDistance()
    local min = SL:GetValue("CAMERA_DISTANCE_MIN")
    local max = SL:GetValue("CAMERA_DISTANCE_MAX")
    FGUI:GSlider_setMin(self._slider_camera_distance, min)
    FGUI:GSlider_setMax(self._slider_camera_distance, max)
    local distance = SL:GetValue("CAMERA_DISTANCE")
    FGUI:GSlider_setValue(self._slider_camera_distance, distance)
    self:OnChange_CameraDistance()
end

function PCSettingSystemPanel:OnChange_CameraDistance()
    local distance = FGUI:GSlider_getValue(self._slider_camera_distance)
    local min = SL:GetValue("CAMERA_DISTANCE_MIN")
    local max = SL:GetValue("CAMERA_DISTANCE_MAX")
    local step = (max - min) / 3
    if distance < min + step then
        FGUI:GTextField_setText(self._ui_system.distance_value, GET_STRING(80000205))
    elseif distance < min + step * 2 then
        FGUI:GTextField_setText(self._ui_system.distance_value, GET_STRING(80000206))
    else
        FGUI:GTextField_setText(self._ui_system.distance_value, GET_STRING(80000207))
    end
    if math.abs(SL:GetValue("CAMERA_DISTANCE") - distance) < Mathf.Epsilon then
        return
    end
    SL:SetValue("CAMERA_DISTANCE", distance)
end

-- 同屏特效 ---------------------------------------------------------------------
function PCSettingSystemPanel:Init_FixLimit()
    local defaultDisplaySettings = C_DefaultGameSettings.PerformanceConfig[global.ModelQuality]
    local max = defaultDisplaySettings.maxVisibleFix
    FGUI:GSlider_setMax(self._slider_fix_limit, max)
    FGUI:GSlider_setWholeNumbers(self._slider_fix_limit, true)
    local count = SL:GetValue("SETTING_VISIBAL_MAX_FIX")
    count = math.min(max, count)
    FGUI:GSlider_setValue(self._slider_fix_limit, count)
    FGUI:GTextField_setText(self._ui_system.fix_limit_value, string.format("%.0f", count))
end

function PCSettingSystemPanel:OnChange_FixLimit(context)
    local value = FGUI:GSlider_getValue(context.sender)
    SL:SetValue("SETTING_VISIBAL_MAX_FIX", value)
    FGUI:GTextField_setText(self._ui_system.fix_limit_value, string.format("%.0f", value))
end

function PCSettingSystemPanel:Init_UIScale(context)
    FGUI:GSlider_setMax(self._slider_ui_scale, self._max_ui_scale * 10)
    FGUI:GSlider_setMin(self._slider_ui_scale, 10)
    FGUI:GSlider_setWholeNumbers(self._slider_ui_scale, true)
    local scale = SL:GetValue("SETTING_UI_SCALE")
    scale = math.min(self._max_ui_scale, scale)
    scale = math.max(1, scale)
    FGUI:GSlider_setValue(self._slider_ui_scale, scale*10)
    FGUI:GTextField_setText(self._ui_system.ui_scale_value, string.format("%.1f", scale))
    FGUI:setVisible(self._ui_system.ui_scale_btn, false)
    if SL:GetValue("SCREEN_REAL_WIDTH") <= self._ui_width_standard then
        FGUI:setVisible(self._ui_system.slider_ui_scale, false)
        FGUI:setVisible(self._ui_system.ui_scale_value, false) 
    end
    self._ui_scale_changed = false
end

function PCSettingSystemPanel:OnChange_UIScale(context)
    local value = FGUI:GSlider_getValue(context.sender) / 10
    FGUI:GTextField_setText(self._ui_system.ui_scale_value, string.format("%.1f", value))
    if FGUI:getVisible(self._ui_system.ui_scale_btn) then
        FGUI:setVisible(self._ui_system.ui_scale_btn, false)    
    end
    self._ui_scale_changed = true
end

function PCSettingSystemPanel:OnUIScaleClick(context)
    if self._ui_scale_changed then
        FGUI:setVisible(self._ui_system.ui_scale_btn, true)
    end
end

function PCSettingSystemPanel:OnUIScaleDragEnd(context)
    if self._ui_scale_changed then
        FGUI:setVisible(self._ui_system.ui_scale_btn, true)
    end
end

function PCSettingSystemPanel:OnClickApplyBtn(context)
    local value = FGUI:GSlider_getValue(self._slider_ui_scale) / 10
    SL:SetValue("SETTING_UI_SCALE", value)
    FGUI:setVisible(self._ui_system.ui_scale_btn, false)
    self._ui_scale_changed = false
end

-- 音乐 -------------------------------------------------------------------------
function PCSettingSystemPanel:Init_BGM()
    local value = SL:GetValue("SETTING_VOLUME_BGM")
    FGUI:GSlider_setValue(self._slider_bgm, value)
    FGUI:GTextField_setText(self._ui_system.bgm_value, string.format("%.0f", value))
end
function PCSettingSystemPanel:OnChange_BGMValue(context)
    local value = FGUI:GSlider_getValue(context.sender)
    SL:SetValue("SETTING_VOLUME_BGM", value)
    FGUI:GTextField_setText(self._ui_system.bgm_value, string.format("%.0f", value))
end

-- 音效 -------------------------------------------------------------------------
function PCSettingSystemPanel:Init_Sound()
    local value = SL:GetValue("SETTING_VOLUME_SOUND")
    FGUI:GSlider_setValue(self._slider_sound, value)
    FGUI:GTextField_setText(self._ui_system.sound_value, string.format("%.0f", value))
end
function PCSettingSystemPanel:OnChange_SoundValue(context)
    local value = FGUI:GSlider_getValue(context.sender)
    SL:SetValue("SETTING_VOLUME_SOUND", value)
    FGUI:GTextField_setText(self._ui_system.sound_value, string.format("%.0f", value))
end

-- 礼包兑换
function PCSettingSystemPanel:OnClickRedeemCodeBtn(context)
    FGUI:Open("Setting_pc", "PCSettingRedeemCodePanel")
end

function PCSettingSystemPanel:RefresPlayerInfo()
    FGUI:GTextField_setText(self._ui.name_value,SL:GetValue("USER_NAME"))
    FGUI:GTextField_setText(self._ui.level_value,SL:GetValue("LEVEL"))
    local faction = SL:GetValue("GOODEVILID")
    if SLDefine.CAMP_TYPE.GOOD == faction then
        FGUI:GTextField_setText(self._ui.faction_value, GET_STRING(80000255))
    elseif SLDefine.CAMP_TYPE.EVIL == faction then
        FGUI:GTextField_setText(self._ui.faction_value, GET_STRING(80000256))
    else
        FGUI:GTextField_setText(self._ui.faction_value, GET_STRING(80000254))
    end
    FGUI:GTextField_setText(self._ui.transfer_value,SL:GetValue("RELEVEL"))
    FGUI:GTextField_setText(self._ui.server_value,SL:GetValue("SERVER_NAME"))
    FGUI:GTextField_setText(self._ui.actor_value,SL:GetValue("USER_ID"))
    local data = 
    {
        AvatarID = SL:GetValue("AVATAR"),
        Job = SL:GetValue("JOB"),
        Sex = SL:GetValue("SEX"),
        FrameID = SL:GetValue("AVATAR_FRAME_DATA")
    }
    FGUIFunction:SetCommonPlayerFrame(self._ui.player_frame, data)
end

function PCSettingSystemPanel:CopyUserId(context)
    local userId = SL:GetValue("USER_ID")
    SL:SetValue("CLIPBOARD_TEXT", userId, function(result)
        if result then
            SL:ShowSystemTips("复制成功")
        else
            SL:ShowSystemTips("复制失败")
        end
    end)
end

local PolicyType = {
    PrivacyPolicy           = 1,
    ChildrenPrivacyPolicy   = 2,
    TermsOfService          = 3,
    ThirdPartyDataSharing   = 4
}

function PCSettingSystemPanel:ShowPolicyContent(showUrl, paramData)
    if not showUrl or showUrl == "" then
        return
    end

    if self.mRequestContenting then
        return
    end

    if not paramData then
        paramData = {}
    end

    self.mRequestContenting = true
    SL:HTTPRequestGet(showUrl, function(success,response)
        if success and response and string.len(response) > 0 then
            SL:CloseCommonHelpDialog()
            local data = {}
            data.title = paramData.title or ""
            data.str = response
            data.linkCallback = paramData.linkCallback
            data.btnCallback = paramData.btnCallback
            data.notClose = paramData.notClose
            data.btnDesc = paramData.btnDesc
            data.callback = function(bType, custom)
                self.mRequestContenting = false
            end
            SL:OpenCommonHelpDialog(data)
            self.mRequestContenting = false
        end
    end)
end

-- 隐私协议
function PCSettingSystemPanel:OnClickPrivacyPolicyBtn(context)
    local showUrl = self.mPolicyCustomData[PolicyType.PrivacyPolicy]
    if not showUrl or showUrl == "" then
        return
    end
    local clickPolicys = {}

    local isCancel = true  --是否撤回取消隐私协议
    local paramData = {}
    paramData.notClose = true
    paramData.btnDesc = GET_STRING(100000001)
    paramData.title = GET_STRING(80000301)
    local linkCallback = function(url)
        if self.mRequestContenting then
            return
        end
        isCancel = false
        table.insert(clickPolicys, url)
        paramData.btnDesc = GET_STRING(1001)
        self:ShowPolicyContent(url, paramData)
    end

    local btnCallback = function()
        if isCancel then
            -- 调用撤回隐私协议
            local callback = function(bType, custom)
                if 1 == bType then
                    SL:RevokePrivatePolicy()
                end
            end

            local data = {}
            data.str = GET_STRING(100000004)
            data.btnDesc = {GET_STRING(100000001), GET_STRING(1000)}
            data.callback = callback
            SL:OpenCommonDialog(data)
            return
        end

        local removeURL = table.remove(clickPolicys)
        local lastURL = clickPolicys[#clickPolicys]
        local data = {}
        if lastURL then
            paramData.btnDesc = GET_STRING(1001)
        else
            isCancel = true
            lastURL = showUrl
            paramData.btnDesc = GET_STRING(100000001)
        end
        self:ShowPolicyContent(lastURL, paramData)
    end
    paramData.linkCallback = linkCallback
    paramData.btnCallback = btnCallback

    self:ShowPolicyContent(showUrl, paramData)
end
-- 儿童隐私协议
function PCSettingSystemPanel:OnClickChildrenPrivacyPolicyBtn(context)
    local showUrl = self.mPolicyCustomData[PolicyType.ChildrenPrivacyPolicy]
    if not showUrl or showUrl == "" then
        return
    end
    local paramData = {}
    paramData.title = GET_STRING(80000302)
    self:ShowPolicyContent(showUrl, paramData)
end
-- 用户协议
function PCSettingSystemPanel:OnClickTermsOfServiceBtn(context)
    local showUrl = self.mPolicyCustomData[PolicyType.TermsOfService]
    if not showUrl or showUrl == "" then
        return
    end
    local paramData = {}
    paramData.title = GET_STRING(80000303)
    self:ShowPolicyContent(showUrl, paramData)
end
-- 第三方共享
function PCSettingSystemPanel:OnClickThirdPartyDataSharingBtn(context)
    local showUrl = self.mPolicyCustomData[PolicyType.ThirdPartyDataSharing]
    if not showUrl or showUrl == "" then
        return
    end
    local paramData = {}
    paramData.title = GET_STRING(80000304)
    self:ShowPolicyContent(showUrl, paramData)
end
-- 联系客服
function PCSettingSystemPanel:OnClickContactSupportBtn()
    SL:OpenSDKKeFu()
end
-- 注销账号
function PCSettingSystemPanel:OnClicknDeleteAccountBtn(context)
    local callback = function(bType, custom)
        if 1 == bType then
            SL:DeletaAccount(context)
        end
    end

    local data = {}
    data.str = GET_STRING(100000003)
    data.btnDesc = {GET_STRING(100000002), GET_STRING(1000)}
    data.callback = callback
    SL:OpenCommonDialog(data)
end

-- 切换账号
function PCSettingSystemPanel:OnClickSwitchCharacterBtn(context)
    local data = {}
    data.str = GET_STRING(80000209)
    data.btnDesc = {GET_STRING(1002), GET_STRING(1000)}
    data.callback = function(tag)
        if tag == 1 then
            SL:ForceLeaveWorld()
        end
    end
	SL:OpenCommonDialog(data)
end

-- 返回登录
function PCSettingSystemPanel:OnClickBackToLoginBtn(context)
    local data = {}
    data.str = GET_STRING(80000208)
    data.btnDesc = {GET_STRING(1002), GET_STRING(1000)}
    data.callback = function(tag)
        if tag == 1 then
            RestartGame()
        end
    end
	SL:OpenCommonDialog(data)
end

-- 打开ICP
function PCSettingSystemPanel:OnClickICPBtn(context)
    -- body
    local info = context.data
    if info == 'openICP' then
        SL:OpenICPURL()
    end
end

-- 脱离卡死
function PCSettingSystemPanel:OnClickDisengageBtn(context)
    FGUI:Close("Setting_pc", "PCSettingPanel")
    FGUI:Open("OutBlock", "OutBlockPanel")
end
-- Common Function -------------------------------------------------------------------------
function PCSettingSystemPanel:ResetSwitch(widget, enable)
    if FGUI:GButton_getSelected(widget) == enable then
        return
    end
    local transition = FGUI:GetTransition(widget, (enable == true) and "open" or "close")
    local time = FGUI:Transition_getTotalDuration(transition)
    FGUI:Transition_play(transition, nil, nil, nil, time)
    FGUI:GButton_setSelected(widget, enable)
end

function PCSettingSystemPanel:GetComponentFormOptionItem(name)
    local loader = FGUI:GetChild(self._ui_system[name], "icon")
    return FGUI:GLoader_getComponent(loader)
end
return PCSettingSystemPanel