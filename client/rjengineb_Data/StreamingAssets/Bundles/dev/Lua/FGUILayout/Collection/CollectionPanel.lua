local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CollectionPanel = class("CollectionPanel", BaseFGUILayout)

function CollectionPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    local scale = isPC and 0.5 or 0.7
    FGUI:setScale(self._ui.Progress_bar, scale, scale)

    local fontSize = isPC and 12 or 20
    FGUI:GTextField_setFontSize(self._ui.Text_desc, fontSize)
end 

function CollectionPanel:Enter(time)
	self._time = time
	self:StartProgress()
end 

function CollectionPanel:Exit()
    self:EndProgress()
end

function CollectionPanel:StartProgress()
    if self._isShow then 
        return 
    end 
    self._isShow = true

    self:ClearTransferEffect()
    local targetID = SL:GetValue("USER_ID")
    self._refID = SL:Fx3D_Create(targetID, 9000003, 1)
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
            self:EndProgress()
        end
    end
    self._timer = SL:Schedule( callback, 0.01)
end 

function CollectionPanel:ClearTransferEffect()
    if self._refID then
        SL:Fx3D_Recycle(self._refID)
        self._refID = nil
    end
end

function CollectionPanel:EndProgress()
    if not self._isShow then 
        return 
    end
    self._isShow = false

    if self._timer then 
        SL:UnSchedule(self._timer)
        self._timer = nil
    end
    
    FGUI:GProgressBar_setValue(self._ui.Progress_bar, 1)

    self:ClearTransferEffect()
    
    self:Close()
end

return CollectionPanel