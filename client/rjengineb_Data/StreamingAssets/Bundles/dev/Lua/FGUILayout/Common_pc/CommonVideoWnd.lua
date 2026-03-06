local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CommonVideoWnd = class("CommonVideoWnd", BaseFGUILayout)

function CommonVideoWnd:Create()
    self.super.Create(self)
    self._ui = FGUI:ui_delegate(self.component)
end

function CommonVideoWnd:Enter(data)
    local url = data.url
    self.closeCB = data.closeCB
    self._video = FGUI:Video_showVideo(self._ui.Node_Video, url,true)
    FGUI:setOnClickEvent(self._ui.Button_Close,function ()
        self:Close()
    end)
end

function CommonVideoWnd:Exit()
    if self.closeCB then
        self.closeCB()
    end
end

function CommonVideoWnd:Close()
    self.super.Close(self)
    FGUI:Video_close(self._video)
end

return CommonVideoWnd
