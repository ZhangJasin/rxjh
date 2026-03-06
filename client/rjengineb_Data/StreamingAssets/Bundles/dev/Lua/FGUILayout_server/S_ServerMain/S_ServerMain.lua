local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local S_ServerMainEx = require("FGUILayer/S_ServerMainEx")
local S_ServerMain = class("S_ServerMain", S_ServerMainEx)

function S_ServerMain:Refresh()
	self._ui = FGUI:ui_delegate(self.component)
	self.super:Create()

	self._tipsData = {}
	self._isLogin           = false
	self._autoLogin 		= false
	self._selectSubModKey	= nil
	self._subModData       	= {}   
	self._subModKey_Idx 	= {} 	--Idx值对应_subModData的key值
    self.handler_onClickModuleEvent = handler(self, self.OnClickModulesEvent)
	self._announceShowFlag  = {}
	
	self:UpdateAutoLogin()

	
	FGUI:GList_itemRenderer(self._ui.List_tips, handler(self, self.List_tipsRender))
	FGUI:GList_itemRenderer(self._ui.ListView_modules, handler(self, self.List_modulesRender))
	FGUI:setOnClickEvent(self._ui.Button_launch, handler(self, self.OnLaunchModule))
	FGUI:setOnClickEvent(self._ui.Btn_change_server, handler(self, self.OnShowServers))
	FGUI:setOnClickEvent(self._ui.Button_logout, handler(self, self.OnLogout))
	FGUI:setOnClickEvent(self._ui.Button_announce, handler(self, self.OnShowAnnounce))
	FGUI:setOnClickEvent(self._ui.Button_fix, handler(self, self.OnFix))
	FGUI:setOnClickEvent(self._ui.Image_age_tips, handler(self, self.OnShowAgeTips))
	FGUI:setOnClickEvent(self._ui.btn_white_list, handler(self, self.OnClickWhite))
	FGUI:setOnClickEvent(self._ui.btn_develop, handler(self, self.OnClickDevelop))
	FGUI:setVisible(self._ui.btn_develop, SL:GetValue("DEVELOP_MODE"))

	local shiwan = global.L_GameEnvManager:GetEnvDataByKey("shiwan")
	if  shiwan and tonumber(shiwan) == 1 then
		FGUI:setTouchEnabled(self._ui.Btn_change_server, false)
	end
	
	FGUI:GButton_setOnChangedCallback(self._ui.CheckBox_agreement, handler(self, self.OnAgreementChange))
	
	self:InitVersion()
	self:InitModules()

	self:RegisterEvent()
	self:UpdateLogo()
	self:UpdateSelectServer()
	self:UpdateSelectVisible()

	self:CheckAutoLogin()
	self:SelectDefaultModule()
	if SL:GetValue("LOGIN_SUCCESS") then
		self:OnLoginSuccess()
	end
	SL:PlayBGMByPath()
end

function S_ServerMain:Exit()
	self:RemoveEvent()
	self:OnHideServers()
	self:OnHideAnnounce()
	self:OnHideAgreement()
    self._ui = nil	
	self._tipsData = nil
end

function S_ServerMain:Destroy()

end

function S_ServerMain:InitVersion()
	local channelID      = SL:GetValue("CHANNEL_ID")
	local urlSuffix      = SL:GetValue("URL_SUFFIX")

	local localLaunchVersion 	= SL:GetValue("LAUNCHER_LOCAL_VERSION")
	local cacheLaunchVersion   	= SL:GetValue("LAUNCHER_CACHE_VERSION")

	local localFGUIVersion 		= SL:GetValue("FGUI_LOCAL_VERSION")
	local cacheFGUIVersion 		= SL:GetValue("FGUI_CACHE_VERSION")

	local localServerVersion 	= SL:GetValue("SERVER_LOCAL_VERSION")
	local cacheServerVersion 	= SL:GetValue("SERVER_CACHE_VERSION")

	local localGMServerVersion 	= SL:GetValue("GM_SERVER_LOCAL_VERSION")
    local cacheGMServerVersion 	= SL:GetValue("GM_SERVER_CACHE_VERSION")

	local appVersion = SL:GetValue("APP_VERSION")
    local verStr = string.format("%s AppV(%s) ResV(%s(%s/%s)(%s/%s)(%s/%s)(%s/%s))", 
		channelID, appVersion, 
		urlSuffix, localLaunchVersion, cacheLaunchVersion,
		localFGUIVersion, cacheFGUIVersion, 
		localServerVersion, cacheServerVersion, 
		localGMServerVersion, cacheGMServerVersion)
	FGUI:GTextField_setText(self._ui["Text_version"], verStr)
end

function S_ServerMain:InitModules()
	self._subModData = SL:GetValue("ALL_SUBMODS")
	local num = #self._subModData
	if num <= 1 then
		FGUI:GList_setNumItems(self._ui.ListView_modules, num)
		FGUI:setVisible(self._ui.ListView_modules, false)
		return
	end

	FGUI:GList_setNumItems(self._ui.ListView_modules, num)

	FGUI:GList_addOnClickItemEvent(self._ui.ListView_modules, self.handler_onClickModuleEvent)

	FGUI:GList_setSelectedIndex(self._ui.ListView_modules, 0)
end


function S_ServerMain:RefreshServerList()
	SL:onLUAEvent(LUA_EVENT_QUERY_SERVER_LIST)
end

function S_ServerMain:OnClickModulesEvent(context)
	local idx = FGUI:GList_getSelectedIndex(self._ui.ListView_modules) + 1
	local data = self._subModData[idx]
	self:SelectModuleData(data)
end

function S_ServerMain:List_modulesRender(idx, item)
	local data = self._subModData[idx + 1]
	local key = SL:GetValue("SUBMOD_KEY", data)
	self._subModKey_Idx[key] = idx + 1
	local subMod = data.subMod
	FGUI:GButton_setTitle(item, subMod.name)
end

function S_ServerMain:List_tipsRender(idx, item)
	local content = self._tipsData[idx + 1]
	FGUI:GRichTextField_setText(item, content)
	FGUI:GRichTextField_addOnLinkClickEvent(item, function (context)
		local url = context.data
		self:OnRichTextOpenUrl(url)
	end)
end

function S_ServerMain:OnUpdateSelectModule(key)
	if self._selectSubModKey == key then return end
	
	local dataIdx = self._subModKey_Idx[key]
	local itemIdx = dataIdx - 1
	
	FGUI:GList_setSelectedIndex(self._ui.ListView_modules, itemIdx)
		
	
	self:UpdateAutoLogin()
	self:UpdateSelectVisible()
	self:CheckAutoLogin()
end

function S_ServerMain:UpdateSelectVisible()
	local isInit = SL:GetValue("IS_INIT_GAME_CUSTOM_DATA")
	if isInit then 
		local visible = not self._autoLogin
		FGUI:setVisible(self._ui.Layout_server, visible)
	end
end

function S_ServerMain:UpdateSelectServer()
	local Image_server_state = self._ui("Btn_change_server", "icon_server_state")
	local selectedServer = SL:GetValue("SELECT_SERVER")
	if not selectedServer then
		--无选择服务器
		-- FGUI:setVisible(self._ui.Layout_server, false)
		FGUI:GButton_setTitle(self._ui.Btn_change_server, SL:GetValue("I18N_STRING", 5))
		return
	end

	-- 服务器名
	local statePath
	if selectedServer.state == 1 then
		-- 新服 绿色
		statePath = "ui://S_ServerMain/icon_green"
	elseif selectedServer.state == 2 then
		-- 普通 绿色
		statePath = "ui://S_ServerMain/icon_green"
	elseif selectedServer.state == 3 then
		-- 爆满
		statePath = "ui://S_ServerMain/icon_red"
	elseif selectedServer.state == 4 then
		-- 维护
		statePath = "ui://S_ServerMain/icon_grey"
	elseif selectedServer.state == 5 then
		-- 隐藏服 隐藏字
		statePath = "ui://S_ServerMain/icon_grey"
	else
		statePath = "ui://S_ServerMain/icon_green"
	end

	local suffix = ""
	if selectedServer.state == 5 then
		suffix = SL:GetValue("I18N_STRING", 13)
	end
	local new = ""
	if selectedServer.state == 1 then
		new = SL:GetValue("I18N_STRING", 33)
	end
	local name = new .. selectedServer.serverName ..  suffix
	FGUI:setVisible(self._ui.Layout_server, true)
	FGUI:setVisible(self._ui.Btn_change_server, true)
	FGUI:setVisible(Image_server_state, true)
	FGUI:GButton_setTitle(self._ui.Btn_change_server, name)
	FGUI:GLoader_setUrl(Image_server_state, statePath)
end

function S_ServerMain:UpdateAutoLogin()
	self._autoLogin = false
	local showServer = SL:GetValue("FORCE_SHOW_SERVER")
	if not showServer then--未标记强制显示选服
		local auto = false
		if auto then--自动进入开启
			local selectedServer = SL:GetValue("SELECT_SERVER")
			if selectedServer then
				if selectedServer.state ~= 4 and selectedServer.state ~= 5 then
					--默认服务器状态正常
					self._autoLogin = true
				end
			end
		end
	end
end



function S_ServerMain:UpdateLogo()
	local modInfo = SL:GetValue("SUBMOD_INFO")
	if not modInfo then
		FGUI:setVisible(self._ui.Image_logo, false)
		FGUI:setVisible(self._ui.Image_logo_mini, false)
		return
	end
    local logoInfo      = modInfo.logo
    local logoInfoMini  = modInfo.logo_mini

	-- logo
	if logoInfo and logoInfo.name and logoInfo.url and logoInfo.name ~= "" and logoInfo.url ~= "" then
		local url = logoInfo.url
		local fileName = logoInfo.name
		FGUI:setVisible(self._ui.Image_logo, true)
		FGUI:GLoader_setHttpUrl(self._ui.Image_logo, url)
	else
		FGUI:setVisible(self._ui.Image_logo, false)
	end

	-- logo mini
	if logoInfoMini and logoInfoMini.name and logoInfoMini.url and logoInfoMini.name ~= "" and logoInfoMini.url ~= "" then
		local url = logoInfoMini.url
		local fileName = logoInfoMini.name
		FGUI:setVisible(self._ui.Image_logo_mini, true)
		FGUI:GLoader_setHttpUrl(self._ui.Image_logo_mini, url)
	else
		FGUI:setVisible(self._ui.Image_logo_mini, false)
	end
end


function S_ServerMain:UpdateTips()
	table.clear(self._tipsData)
	local hideCopyright = SL:GetValue("GAME_CUSTOM_DATA", "hideCopyright")
	hideCopyright = (tonumber(hideCopyright) == 1)
	if not hideCopyright then
		local copyright1 = SL:GetValue("GAME_CUSTOM_DATA", "copyright1") or ""
		local copyright2 = SL:GetValue("GAME_CUSTOM_DATA", "copyright2") or ""
		table.insert(self._tipsData, copyright1)
		table.insert(self._tipsData, copyright2)
	end

	-- 健康游戏内容
	local healthtips = SL:GetValue("GAME_CUSTOM_DATA", "healthtips")
	if healthtips then
		table.insert(self._tipsData, healthtips)
	end

	-- 适龄提醒
	local agetips = SL:GetValue("GAME_CUSTOM_DATA", "agetips")
	if agetips then
		table.insert(self._tipsData, agetips)
	end

	-- 账号安全提醒
	local authtips = SL:GetValue("GAME_CUSTOM_DATA", "authtips")
	if authtips then
		table.insert(self._tipsData, authtips)
	end

	local agetipsImage = SL:GetValue("GAME_CUSTOM_DATA", "agetipsImage")
	if agetipsImage then
		-- 显示
		if tostring(agetipsImage.visible) == "1" then
			FGUI:setVisible(self._ui.Image_age_tips, true)
		end

		-- 图标
		if agetipsImage.name and agetipsImage.url and agetipsImage.name ~= "" and agetipsImage.url ~= "" then
			local url = agetipsImage.url
			local fileName = agetipsImage.name
			FGUI:GLoader_setHttpUrl(self._ui.Image_age_tips, url)
		end
	end

	FGUI:GList_setNumItems(self._ui["List_tips"], #self._tipsData)
end



function S_ServerMain:OnRichTextOpenUrl(url)
	if (not url) or url == "" then return end
	SL:OpenUrl(url)
end

function S_ServerMain:OnShowServers()
	FGUI:Open("S_SelectServer", "S_SelectServer")
end

function S_ServerMain:OnHideServers()
    FGUI:Close("S_SelectServer", "S_SelectServer")
end

-- 切换账号/返回盒子
function S_ServerMain:OnLogout()
	SL:Logout()
end

function S_ServerMain:OnShowAnnounce()
	FGUI:Open("S_Announce", "S_Announce")
end

function S_ServerMain:OnHideAnnounce()
	FGUI:Close("S_Announce", "S_Announce")
end

function S_ServerMain:OnFix()
	local function callback( aType, custom )
		if aType == 2 then
			SL:FixGame()
		end
	end
	local tipsData      = {}
	tipsData.str        = SL:GetValue("I18N_STRING", 24)
	tipsData.btnDesc    = {SL:GetValue("I18N_STRING", 26), SL:GetValue("I18N_STRING", 22)}
	tipsData.callback   = callback
	SL:OpenCommonDialog(tipsData)
end

function S_ServerMain:OnShowAgreement()
    local agreement = SL:GetValue("GAME_CUSTOM_DATA", "agreement")
	self:OnShowContent(1, agreement)
end

function S_ServerMain:OnShowContent(type, content, title)
	FGUI:Open("S_Agreement", "S_Agreement", {type = type, content = content, title = title})
end

function S_ServerMain:OnHideAgreement()
	FGUI:Close("S_Agreement", "S_Agreement")
end

-- 适龄提醒
function S_ServerMain:OnShowAgeTips()
	local agetipsImage = SL:GetValue("GAME_CUSTOM_DATA", "agetipsImage")
	if agetipsImage then
		-- 跳转链接
		if agetipsImage.hyperlink and agetipsImage.hyperlink ~= "" then
			SL:OpenUrl(agetipsImage.hyperlink)

		elseif agetipsImage.clickTips and agetipsImage.clickTips ~= "" then
			self:OnShowContent(2, agetipsImage.clickTips, SL:GetValue("I18N_STRING", 34))
		end
	end
end

function S_ServerMain:OnAgreementChange()
    local isSelect = FGUI:GButton_getSelected(self._ui["CheckBox_agreement"])
	SL:SetValue("AGREEMENT_CACHE_STATE", isSelect and 1 or 0)
end

-- 更新用户协议勾选
function S_ServerMain:UpdateAgreement()
    local function urlCB(url)
		local isInsideShow = tonumber(SL:GetValue("GAME_CUSTOM_DATA", "showInside")) == 1
		SL:release_print("agreement url", url)
        if url == "" or url == nil then return end
        if isInsideShow then
            -- 用户协议内容
            local function httpCB(success, response, webRequest)
                SL:HideLoadingBar()
				SL:release_print("response:", string.len(response))
				self:OnShowContent(2, response)
            end
            -- debug
            if url and string.len(url) > 0 then
                SL:HTTPRequestGet(url, httpCB)
                SL:ShowLoadingBar(3)
            end
        else
            SL:OpenUrl(url)
        end
    end

    -- 隐私协议内容
	local str = SL:GetValue("GAME_CUSTOM_DATA", "agreementB")
	if not str or str == "" then
		-- 无内容不显示,并默认勾选
		FGUI:setVisible(self._ui.CheckBox_agreement, false)
		FGUI:setVisible(self._ui.RichText_agreement, false)
		FGUI:GButton_setSelected(self._ui.CheckBox_agreement, true)
	else
		FGUI:setVisible(self._ui.CheckBox_agreement, true)
		FGUI:setVisible(self._ui.RichText_agreement, true)
		FGUI:GRichTextField_setText(self._ui.RichText_agreement, str)
		FGUI:GRichTextField_addOnLinkClickEvent(self._ui.RichText_agreement, function (context)
			local url = context.data
			urlCB(url)
		end)

        -- 隐私协议自动勾选，后台可控制自动不勾选
        local discardAgreementBSwitch = SL:GetValue("GAME_CUSTOM_DATA", "discardAgreementBSwitch") == 1
        local selectStatus = discardAgreementBSwitch and 0 or SL:GetValue("AGREEMENT_CACHE_STATE")
        FGUI:GButton_setSelected(self._ui["CheckBox_agreement"], selectStatus == 1)
	end
end

-- 账号登入成功触发
function S_ServerMain:OnLoginSuccess()
	self._isLogin = true
end

--选中区服
function S_ServerMain:OnSelectServer(server)
	SL:SetValue("SELECT_SERVER", server)

	self:UpdateSelectServer()
end

function S_ServerMain:OnUpdateModServers(isReview)
	self:UpdateTips()
	self:UpdateLogo()
	self:UpdateAgreement()
	self:UpdateSelectServer()

	-- auto login
	self:CheckAutoLogin()
end

function S_ServerMain:CheckAutoLogin()
	if not self._autoLogin then return false end
	local selectedServer = SL:GetValue("SELECT_SERVER")
	if not selectedServer then return false end
	SL:SetValue("FORCE_SHOW_SERVER", false)
	SL:SetValue("IS_AUTO_LOGIN", true)
	self:LaunchModule()
	return true
end

function S_ServerMain:OnLaunchModule()
	-- 点击间隔
	SL:ShowLoadingBar(2)

	-- 未勾选用户协议
    if FGUI:getVisible(self._ui["CheckBox_agreement"]) and not FGUI:GButton_getSelected(self._ui["CheckBox_agreement"]) then
		SL:ShowSystemTips(SL:GetValue("I18N_STRING", 6))
		return
	end

	SL:SetValue("FORCE_SHOW_SERVER", false)
	SL:SetValue("IS_AUTO_LOGIN", false)
	self:LaunchModule()
end

function S_ServerMain:OnResponseAnnounce()
	local currSubModID = SL:GetValue("CURRENT_SUBMOD_ID")
	if not currSubModID then
		return
	end
    -- 自动展示公告
    local serverData = SL:GetValue("SERVER_DATA")
	if serverData and serverData.announce and not self._announceShowFlag[currSubModID] then
        self._announceShowFlag[currSubModID] = true
		self:OnShowAnnounce()
	end
end

-- 区服自定义数据改变/初始化
function S_ServerMain:OnCustomDataChange()
	self:UpdateAutoLogin()
	self:UpdateSelectVisible()
	self:CheckAutoLogin()
	self:UpdateTips()
	self:UpdateAgreement()
end


function S_ServerMain:QueryServerList()
	self:RequestModSrvlist()
end

-----------------------------------注册事件--------------------------------------
function S_ServerMain:RegisterEvent()
	SL:RegisterLUAEvent(LUA_EVENT_ANNOUNCE_CHANGE, "ServerMain", handler(self, self.OnResponseAnnounce))
	SL:RegisterLUAEvent(LUA_EVENT_CUSTOMDATA_CHANGE, "ServerMain", handler(self, self.OnCustomDataChange))
	SL:RegisterLUAEvent(LUA_EVENT_LOGIN_SUCCESS, "ServerMain", handler(self, self.OnLoginSuccess))
	SL:RegisterLUAEvent(LUA_EVENT_SELECT_SERVER, "ServerMain", handler(self, self.OnSelectServer))
	SL:RegisterLUAEvent(LUA_EVENT_QUERY_SERVER_LIST, "ServerMain", handler(self, self.QueryServerList))
end

function S_ServerMain:RemoveEvent()
	SL:UnRegisterLUAEvent(LUA_EVENT_ANNOUNCE_CHANGE, "ServerMain")
	SL:UnRegisterLUAEvent(LUA_EVENT_CUSTOMDATA_CHANGE, "ServerMain")
	SL:UnRegisterLUAEvent(LUA_EVENT_LOGIN_SUCCESS, "ServerMain")
	SL:UnRegisterLUAEvent(LUA_EVENT_SELECT_SERVER, "ServerMain")
	SL:UnRegisterLUAEvent(LUA_EVENT_QUERY_SERVER_LIST, "ServerMain")
end


return S_ServerMain