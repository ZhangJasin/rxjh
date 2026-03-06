local GuideTask = class("GuideTask")

function GuideTask:ctor(data--[[,config]])
    self._data = data
    self._mainID = nil
    self._uiID = nil
    self._ssrWidget = nil
    self._desc = nil
    self._clickCallback = nil
    self._showType = 1
    self._mainType = nil        -- 主界面
    self._hideMask = false      -- 禁止蒙版
    self._arrDir = 1
    self._isForce = true
    self._fireWidgetClick = false
    self._autoExecute    =  -1
    if data then
        self._mainID          = tonumber(data.id)
        self._uiID            = data.param
        self._ssrWidget       = data.guideWidget
        self._desc            = data.guideDesc
        self._clickCallback   = data.clickCB
        self._showType        = data.showType
        self._mainType        = tonumber(data.mainIdx)
        if data.isForce then
            self._isForce     = data.isForce
        end
        self._hideMask        = data.hideMask
        self._arrDir          = data.dir or 1                --maskObj相对于指引框的位置 1 Left 2 UpperLeft 3 Up 4 UpperRight 5 Right 6 LowerRight 7 Down 8 LowerLeft
        self._maskGraph       = data.maskGraph or 0          --0 圆形 1 矩形
        self._fireWidgetClick = data.fireWidgetClick         --点击背景是否触发guideWidget的Click事件
        self._autoExecute     = data.autoExecute or -1       --自动执行引导任务时间
        self._autoExecuteTick = data.autoExecuteTick         --自动执行引导任务回调
    end
            
    self._widget = nil
    self._parent = nil
    self._position  = nil
    self._active = true
end

function GuideTask:GetWidget()
    return self._widget
end

function GuideTask:GetParent()
    return self._parent
end

function GuideTask:GetConfig()
    return self._data
end

function GuideTask:GetAutoExecuteTime()
    return self._autoExecute
end

function GuideTask:AutoExecuteTaskTick(curTime)
    if self._autoExecuteTick then
        self._autoExecuteTick(curTime)
    end
end

function GuideTask:IsForce()
    return self._isForce
end

function GuideTask:Enter( ... )
    if not self._active then return end
    FGUIFunction:OpenGuideUI(self)
end

function GuideTask:IsActive()
    return self._active
end

function GuideTask:Exit()
    FGUIFunction:HideGuideUI()
    self._active = false
end

function GuideTask:Destroy( ... )
    FGUI:Close("Guide", "GuideLayer")
    self._active = false
    self._widget = nil
    self._parent = nil
end

return GuideTask
