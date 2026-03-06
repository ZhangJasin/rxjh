local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local NetReconnectPanel = class("NetReconnectPanel", BaseFGUILayout)

function NetReconnectPanel:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:GetAllFGuiData()
    self:InitClickEvent()
end

function NetReconnectPanel:GetAllFGuiData()
    -- 当前阶段控制器
    self.c_current_stage = FGUI:getController(self.component,"curStage")
    self.btn_reconnect = self._ui.btn_reconnect
    self.btn_return_login = self._ui.btn_return_login
    self.richText_content = self._ui.richText_content
end

function NetReconnectPanel:InitClickEvent()
    FGUI:setOnClickEvent(self.btn_reconnect,handler(self,self.BtnReconnectClicked))
    FGUI:setOnClickEvent(self.btn_return_login,handler(self,self.BtnReturnLoginClicked))
end

function NetReconnectPanel:BtnReconnectClicked()
    self:OnClose()
    SL:RequestGameReconnect()
end

function NetReconnectPanel:BtnReturnLoginClicked()
    self:OnClose()
    SL:RestartGame()
end

function NetReconnectPanel:Enter()
    self:InitUI()
end

function NetReconnectPanel:InitUI()
    local time = SL:GetValue("RECONNECT_TRY_COUNT")--重连次数
    if time >= 5 then
        self.c_current_stage.selectedIndex = 2
        --不再重连
        FGUI:GTextField_setText(self.richText_content,GET_STRING(10000006))
    else
        self.c_current_stage.selectedIndex = 0
        local time = 10
        local function updateTime()
            local timeStr = string.format(GET_STRING(10000005), time)
            if time <= 0 then
                self:OnClose()
                SL:RequestGameReconnect()
                return
            end

            FGUI:GTextField_setText(self.richText_content,timeStr)
            time = time - 1
        end
        self:StopTimer()
        self._timer = SL:Schedule(updateTime, 1)
        updateTime()
    end
end

function NetReconnectPanel:OnClose()
    self.super.Close(self)
end

function NetReconnectPanel:StopTimer()
    if self._timer then
        SL:UnSchedule(self._timer)
        self._timer = nil
    end
end

function NetReconnectPanel:Exit()
    self:StopTimer()
end

function NetReconnectPanel:Destroy()
end

return NetReconnectPanel