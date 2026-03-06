local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local OutBlockPanel = class("OutBlockPanel", BaseFGUILayout)

function OutBlockPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
	FGUI:setVisible(self.component, false)

	self:InitData()
end 

function OutBlockPanel:OnClose()
    self:Close()
end

function OutBlockPanel:InitData()
	self._init = false
	self._time = (SL:GetValue("GAME_DATA", "OutBlockTime") or 10000) / 1000
	self._isShow = false
end

function OutBlockPanel:Enter()
	self:InitOutBlockUI()
end 

function OutBlockPanel:InitOutBlockUI()
    if not self._init then
        self._init = true
		SL:RegisterLUAEvent(LUA_EVENT_OUTBLOCK_RESULT, "OutBlockPanel", handler(self, self.OnResult))
    end

    local data = {}
    data.str = string.format(GET_STRING(40041001), self._time)
    data.title = GET_STRING(40041000)
    data.btnDesc = { GET_STRING(1001), GET_STRING(1000) }
    data.callback = function(bType)
        if bType == 1 then
            SL:RequestOutBlockStart()
        elseif bType == 2 then 
            self:OnClose()
        end
    end
    SL:OpenCommonDialog(data)
end

function OutBlockPanel:StartProgress()
    if not self._isShow then return end

    self:ClearTransferEffect()
    local targetID = SL:GetValue("USER_ID")
    self._refID = SL:Fx3D_Create(targetID, 9000003, 1)

	FGUI:GTextField_setText(self._ui.Text_desc, GET_STRING(40041002))
    FGUI:GProgressBar_setValue(self._ui.Progress_bar, 1)


    local startTime = SL:GetValue("TIME")
    local needTime = self._time
    local endTime = startTime + needTime
    local function callback()
        local curTime = SL:GetValue("TIME")
        local percent = math.min(100, math.ceil(100 * (curTime - startTime) / needTime))
		FGUI:GProgressBar_setValue(self._ui.Progress_bar, percent)

        -- 时间到
        if curTime >= endTime then
            if self._timer then 
                SL:UnSchedule(self._timer)
                self._timer = nil
            end
            self:HideOutBlock()
        end
    end
    self._timer = SL:Schedule( callback, 0.01)
end 

function OutBlockPanel:ClearTransferEffect()
    if self._refID then
        SL:Fx3D_Recycle(self._refID)
        self._refID = nil
    end
end

function OutBlockPanel:ShowOutBlock()
    if self._isShow then return end
    self._isShow = true

	FGUI:setVisible(self.component, true)
    self:StartProgress()
	self:RegisterEvent()
end


function OutBlockPanel:HideOutBlock()
    if not self._isShow then return end
    self._isShow = false

    FGUI:GProgressBar_setValue(self._ui.Progress_bar, 1)

    self:RemoveEvent()

    self:ClearTransferEffect()
    
	self:OnClose()
end


--服务器通知
function OutBlockPanel:OnResult(code)
    if code == 0 then
        self:ShowOutBlock()
    elseif code == 1 then
        self:HideOutBlock()
    end
end

function OutBlockPanel:OnBreak()
    SL:RequestOutBlockBreak()
    self:HideOutBlock()
end

-----------------------------------注册事件--------------------------------------
function OutBlockPanel:RegisterEvent()
    SL:RegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "OutBlockPanel", handler(self, self.OnBreak))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_BEGIN, "OutBlockPanel", handler(self, self.OnBreak))
    SL:RegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_PROCESS, "OutBlockPanel", handler(self, self.OnBreak))
    -- SL:RegisterLUAEvent(LUA_EVENT_THROW_DAMAGE, "OutBlockPanel", handler(self, self.OnBreak))
end

function OutBlockPanel:RemoveEvent()
    SL:UnRegisterLUAEvent(LUA_EVENT_CHANGE_SCENE, "OutBlockPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_BEGIN, "OutBlockPanel")
    SL:UnRegisterLUAEvent(LUA_EVENT_PLAYER_ACTION_PROCESS, "OutBlockPanel")
    -- SL:UnRegisterLUAEvent(LUA_EVENT_THROW_DAMAGE, "OutBlockPanel")
end

return OutBlockPanel