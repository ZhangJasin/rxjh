local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CdMask = class("CDMask", BaseFGUILayout)

function CdMask:Create()
    self.super.Create(self)
	self._ui                            = FGUI:ui_delegate(self.component)
    self._loader_image                  = self._ui.loader_image
    self._schedule                      = nil
    self._controller                    = FGUI:getController(self.component,"Sharp")
    self._text_cd                       = self._ui.text_cd
    self._doTimeDis                     = 0
    self._totalTimeDis                  = 0
end

function CdMask:DoCD()
    local interval = 0.1
    local endTime = SL:GetValue("TIME") + self._doTimeDis
    local callPerOneSecond = function()
        if SL:GetValue("TIME") >= endTime then
            self:Clean()
        else
            FGUI:GLoader_setFillAmount(self._loader_image, self._doTimeDis/self._totalTimeDis)
            FGUI:GTextField_setText(self._text_cd,string.format("%.1f",self._doTimeDis))
        end
        self._doTimeDis = endTime - SL:GetValue("TIME")
    end
    
    callPerOneSecond()
    self._schedule = SL:Schedule(callPerOneSecond,0.1)
end

function CdMask:InitUI(parent,time,timeTotal,kind,isShowTime)
    if not parent then
        SL:PrintEx("[ERROR] parent is nil")
        return
    end

    local width,height = FGUI:getSize(parent)
    FGUI:setSize(self.component,width,height)
    if kind == 1 then   -- 圆形
        self._controller.selectedIndex = 0
    elseif kind == 2 then   --方形
        self._controller.selectedIndex = 1
    end

    FGUI:setVisible(self._text_cd,isShowTime)
    self._doTimeDis = time
    self._totalTimeDis = timeTotal
end

function CdMask:UpdateTime(timeDis,timeTotal)
    if not timeDis or timeDis <=0 then
        SL:PrintEx("[ERROR] timeDis <= 0 ")
        return
    end
    self._doTimeDis = timeDis
    self._totalTimeDis = timeTotal
end

function CdMask:Clean()
    if self._schedule then
        SL:UnSchedule(self._schedule)
        self._schedule = nil
    end
    
    FGUI:GLoader_setFillAmount(self._loader_image, 0)
    FGUI:GTextField_setText(self._text_cd,"")
end

function CdMask:Destory()
    self:Clean()
end

return CdMask