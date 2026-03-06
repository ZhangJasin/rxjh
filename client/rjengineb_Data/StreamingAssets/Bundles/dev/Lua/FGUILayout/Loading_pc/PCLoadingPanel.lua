local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCLoadingPanel = class("PCLoadingPanel", BaseFGUILayout)

function PCLoadingPanel:Create()
    self.callback = nil
	self._ui = FGUI:ui_delegate(self.component)
end

function PCLoadingPanel:Enter(data)
    self._data = data

    self:SetBackGround()
    self:RegisterEvent()

    -- 触发loading加载完成事件
    SL:onLUAEvent(LUA_EVENT_LOADING_ONENTER)
end

function PCLoadingPanel:Exit()
	self:RemoveEvent()
end

function PCLoadingPanel:Destroy()
    self._ui = nil	
end

function PCLoadingPanel:SetBackGround()
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")

    -- 背景图自适应宽高
    local ui_loadingBg = self._ui["bg_loading"]
    FGUI:GLoader_setUrl(ui_loadingBg, "ui://ImageBG/loadingBg")

    -- 进度条尺寸
    local ui_loadingBar = self._ui["bar_loading"]
    local barBgSizeW, barBgSizeH = FGUI:getSize(ui_loadingBar)
    FGUI:setSize(ui_loadingBar, barBgSizeW , barBgSizeH)
    self:SetPercent(1)

    -- 提示文本
    local sTips = FGUIFunction:GetRadomLoadingTips()
    FGUI:GTextField_setText(self._ui["text_tips"], sTips)

    -- 是否隐藏进度条等
    if self._data and self._data.hideProgress then
        self:HideLoadingPercent()
    else
        self:ShowLoadingPercent()
    end
end 

function PCLoadingPanel:SetPercent(percent)
    local ui_loadingBar = self._ui["bar_loading"]
    FGUI:GProgressBar_setValue(ui_loadingBar, percent)
end

function PCLoadingPanel:SetLoadingSuccess(callback)
    self._callback = callback
end

function PCLoadingPanel:ShowLoadingPercent()
    FGUI:setVisible(self._ui["bar_loading"], true)
    FGUI:setVisible(self._ui["text_tips"], true)
end

function PCLoadingPanel:HideLoadingPercent()
    FGUI:setVisible(self._ui["bar_loading"], false)
    FGUI:setVisible(self._ui["text_tips"], false)
end

-----------------------------------注册事件--------------------------------------
function PCLoadingPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_LOADING_SET_PERCENT, "PCLoadingPanel", handler(self, self.SetPercent))
end

function PCLoadingPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_LOADING_SET_PERCENT, "PCLoadingPanel")
end

return PCLoadingPanel